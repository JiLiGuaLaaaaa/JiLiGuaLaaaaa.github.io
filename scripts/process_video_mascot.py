from __future__ import annotations

from pathlib import Path

import imageio.v3 as iio
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
VIDEO_SRC = ROOT / "生成指定动作视频 (2).mp4"
OUT = ROOT / "public" / "images" / "video-mascot"

CANVAS = (720, 640)
BASELINE = 624
SOURCE_ROI = (150, 0, 1130, 720)
TARGET_WIDTH = 680
PREVIEW_CELL = (188, 182)

LOOK_FRAME_IDS = {
    "center": 130,
    "up": 95,
    "down": 50,
    "left": 70,
    "down-left": 65,
    "up-left": 85,
}
BLINK_FRAME_IDS = {
    "open": 130,
    "half-1": 125,
    "half-2": 105,
    "closed": 115,
    "open-2": 130,
}
# Browser pointer angles: 0 right, 90 down, 180 left, 270 up.
# These are real source-video frames; right-side angles are mirrored from them.
LOOK_ANGLE_FRAME_IDS = {
    90: 50,
    100: 55,
    110: 60,
    120: 65,
    130: 65,
    140: 65,
    150: 70,
    160: 70,
    170: 70,
    180: 70,
    190: 75,
    200: 85,
    210: 85,
    220: 90,
    230: 95,
    240: 95,
    250: 95,
    260: 95,
    270: 95,
}
WAVE_FRAME_IDS = [150, 155, 160, 165, 170, 180, 200, 230]
LOOK_ANGLE_STEP = 10
BLINK_FACE_PATCH = (205, 238, 515, 392)


def load_video_frames(frame_ids: set[int]) -> dict[int, Image.Image]:
    if not VIDEO_SRC.exists():
        raise FileNotFoundError(f"missing source video: {VIDEO_SRC}")

    frames: dict[int, Image.Image] = {}
    last_id = max(frame_ids)
    for index, frame in enumerate(iio.imiter(VIDEO_SRC)):
        if index in frame_ids:
            frames[index] = Image.fromarray(frame).convert("RGB")
        if index >= last_id:
            break

    missing = sorted(frame_ids - frames.keys())
    if missing:
        raise RuntimeError(f"missing video frames: {missing}")
    return frames


def sample_green(rgb: np.ndarray) -> np.ndarray:
    r = rgb[..., 0].astype(np.int16)
    g = rgb[..., 1].astype(np.int16)
    b = rgb[..., 2].astype(np.int16)
    green = (g > 90) & (g > r + 20) & (g > b + 20)
    if not np.any(green):
        return np.array([115, 194, 82], dtype=np.uint8)
    return np.median(rgb[green], axis=0).astype(np.uint8)


def erase_watermark_zones(rgb: np.ndarray) -> np.ndarray:
    clean = rgb.copy()
    key = sample_green(clean)
    h, w = clean.shape[:2]
    clean[0:150, 0:360] = key
    clean[0:145, w - 360 : w] = key
    zones = [
        (w - 330, h - 130, w, h),
    ]
    for x1, y1, x2, y2 in zones:
        region = clean[y1:y2, x1:x2]
        data = region.astype(np.int16)
        r = data[..., 0]
        g = data[..., 1]
        b = data[..., 2]
        bright_neutral = (r > 145) & (g > 145) & (b > 145) & ((np.maximum.reduce([r, g, b]) - np.minimum.reduce([r, g, b])) < 58)
        pale_text = (r > 120) & (g > 135) & (b > 105) & ((r + g + b) > 440)
        neutral_text_edge = (r > 70) & (g > 70) & (b > 70) & ((np.maximum.reduce([r, g, b]) - np.minimum.reduce([r, g, b])) < 72)
        mask = bright_neutral | pale_text | neutral_text_edge
        region[mask] = key
    return clean


def green_to_alpha(image: Image.Image) -> Image.Image:
    rgb = np.asarray(image.convert("RGB"), dtype=np.uint8)
    rgb = erase_watermark_zones(rgb)
    data = rgb.astype(np.float32)
    r = data[..., 0]
    g = data[..., 1]
    b = data[..., 2]

    green_delta = np.minimum(g - r, g - b)
    key_strength = np.clip((green_delta - 8.0) / 54.0, 0.0, 1.0)
    green_level = np.clip((g - 76.0) / 92.0, 0.0, 1.0)
    alpha = (1.0 - key_strength * green_level) * 255.0
    alpha[(g > 95) & (green_delta > 42)] = 0
    skin = (r > 138) & (g > 78) & (b > 58) & (r > b + 18) & (g > b + 8) & (g < r + 48)
    alpha[skin] = np.maximum(alpha[skin], 248)
    alpha = np.clip(alpha, 0, 255).astype(np.uint8)

    alpha_image = Image.fromarray(alpha, "L")
    alpha_image = alpha_image.filter(ImageFilter.GaussianBlur(0.45))
    alpha = np.array(alpha_image, dtype=np.uint8)
    alpha[alpha < 26] = 0

    spill = (alpha > 0) & (g > r + 2) & (g > b + 2)
    spill_amount = np.clip((g - np.maximum(r, b) - 2.0) / 82.0, 0.0, 1.0)
    edge_spill = spill & (alpha < 252)
    alpha = alpha.copy()
    alpha[edge_spill] = np.clip(alpha[edge_spill] * (1.0 - spill_amount[edge_spill] * 0.82), 0, 255).astype(np.uint8)
    alpha[skin] = np.maximum(alpha[skin], 248)
    neutral_green = np.maximum(r, b) * 0.92 + np.minimum(r, b) * 0.08
    data[..., 1] = np.where(spill, np.minimum(g, neutral_green + 1), g)

    rgba = np.dstack([np.clip(data, 0, 255).astype(np.uint8), alpha])
    return Image.fromarray(rgba, "RGBA")


def alpha_bbox(image: Image.Image, threshold: int = 8) -> tuple[int, int, int, int]:
    mask = image.getchannel("A").point(lambda value: 255 if value > threshold else 0)
    bbox = mask.getbbox()
    if not bbox:
        raise ValueError("empty alpha frame")
    return bbox


def keep_main_subject(image: Image.Image, *, alpha_threshold: int = 8) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    visited = np.zeros((height, width), dtype=bool)
    components: list[tuple[int, int, int, int, int, list[tuple[int, int]]]] = []

    for y in range(height):
        for x in range(width):
            if visited[y, x]:
                continue
            visited[y, x] = True
            if pixels[x, y][3] <= alpha_threshold:
                continue

            stack = [(x, y)]
            coords: list[tuple[int, int]] = []
            min_x = max_x = x
            min_y = max_y = y
            while stack:
                cx, cy = stack.pop()
                if pixels[cx, cy][3] <= alpha_threshold:
                    continue
                coords.append((cx, cy))
                min_x = min(min_x, cx)
                max_x = max(max_x, cx)
                min_y = min(min_y, cy)
                max_y = max(max_y, cy)
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < width and 0 <= ny < height and not visited[ny, nx]:
                        visited[ny, nx] = True
                        stack.append((nx, ny))

            if coords:
                components.append((len(coords), min_x, min_y, max_x, max_y, coords))

    if not components:
        return rgba

    center_x = width / 2
    baseline_weight = height * 0.62

    def score(component: tuple[int, int, int, int, int, list[tuple[int, int]]]) -> float:
        area, min_x, min_y, max_x, max_y, _coords = component
        component_center_x = (min_x + max_x) / 2
        component_center_y = (min_y + max_y) / 2
        center_penalty = abs(component_center_x - center_x) * 4 + abs(component_center_y - baseline_weight)
        return area - center_penalty

    keep_index = max(range(len(components)), key=lambda index: score(components[index]))
    for index, (_area, _min_x, _min_y, _max_x, _max_y, coords) in enumerate(components):
        if index == keep_index:
            continue
        for px, py in coords:
            r, g, b, _a = pixels[px, py]
            pixels[px, py] = (r, g, b, 0)
    return rgba


def patch_blink_face(base: Image.Image, source: Image.Image) -> Image.Image:
    patched = base.copy()
    patch = source.crop(BLINK_FACE_PATCH)
    mask = Image.new("L", patch.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, patch.width - 1, patch.height - 1), radius=38, fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(7))
    patched.paste(patch, BLINK_FACE_PATCH[:2], mask)
    patched.putalpha(base.getchannel("A"))
    return patched


def angle_slug(angle: int) -> str:
    return f"a{angle + 360 if angle < 0 else angle:03d}"


def mirror_angle(angle: int) -> int:
    return (180 - angle) % 360


def generate_angle_frames(processed: dict[int, Image.Image]) -> None:
    for path in (OUT / "look-angle").glob("*.png"):
        path.unlink()

    real_angle_images = {angle: processed[frame_id] for angle, frame_id in LOOK_ANGLE_FRAME_IDS.items()}
    for angle in range(0, 360, LOOK_ANGLE_STEP):
        if angle in real_angle_images:
            image = real_angle_images[angle]
        else:
            source_angle = mirror_angle(angle)
            image = ImageOps.mirror(real_angle_images[source_angle])
        image.save(OUT / "look-angle" / f"{angle_slug(angle)}.png")


def normalize_frame(frame: Image.Image) -> Image.Image:
    keyed = green_to_alpha(frame)
    cropped = keyed.crop(SOURCE_ROI)
    target_height = round(cropped.height * TARGET_WIDTH / cropped.width)
    resized = cropped.resize((TARGET_WIDTH, target_height), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", CANVAS, (255, 255, 255, 0))
    x = (CANVAS[0] - resized.width) // 2
    y = BASELINE - resized.height
    canvas.alpha_composite(resized, (x, y))
    return keep_main_subject(canvas)


def trim_corner_artifacts(image: Image.Image) -> Image.Image:
    clean = image.copy()
    alpha = np.array(clean.getchannel("A"), dtype=np.uint8)
    mask = Image.new("L", clean.size, 0)
    draw = ImageDraw.Draw(mask)
    width, height = clean.size
    draw.rectangle((0, 0, 58, 210), fill=255)
    draw.rectangle((width - 58, 0, width, 210), fill=255)
    draw.rectangle((0, height - 95, 112, height), fill=255)
    draw.rectangle((width - 112, height - 95, width, height), fill=255)
    corner = np.array(mask, dtype=np.uint8) > 0
    alpha[corner] = 0
    clean.putalpha(Image.fromarray(alpha, "L"))
    return clean


def save_named_frames(frames: dict[int, Image.Image]) -> None:
    for folder in ["look", "look-angle", "blink", "wave"]:
        (OUT / folder).mkdir(parents=True, exist_ok=True)

    processed = {index: normalize_frame(frame) for index, frame in frames.items()}

    processed = {index: trim_corner_artifacts(image) for index, image in processed.items()}

    for name, frame_id in LOOK_FRAME_IDS.items():
        processed[frame_id].save(OUT / "look" / f"{name}.png")
    ImageOps.mirror(processed[LOOK_FRAME_IDS["left"]]).save(OUT / "look" / "right.png")
    ImageOps.mirror(processed[LOOK_FRAME_IDS["up-left"]]).save(OUT / "look" / "up-right.png")
    ImageOps.mirror(processed[LOOK_FRAME_IDS["down-left"]]).save(OUT / "look" / "down-right.png")

    generate_angle_frames(processed)

    blink_base = processed[BLINK_FRAME_IDS["open"]]
    for name, frame_id in BLINK_FRAME_IDS.items():
        image = blink_base if name in {"open", "open-2"} else patch_blink_face(blink_base, processed[frame_id])
        image.save(OUT / "blink" / f"{name}.png")

    for index, frame_id in enumerate(WAVE_FRAME_IDS):
        processed[frame_id].save(OUT / "wave" / f"wave-{index}.png")


def build_preview() -> None:
    files = [
        *(OUT / "look").glob("*.png"),
        *(OUT / "look-angle").glob("*.png"),
        *(OUT / "blink").glob("*.png"),
        *(OUT / "wave").glob("*.png"),
    ]
    files = sorted(files, key=lambda path: (path.parent.name, path.name))
    cols = 5
    rows = (len(files) + cols - 1) // cols
    preview = Image.new("RGB", (cols * PREVIEW_CELL[0], rows * PREVIEW_CELL[1]), (225, 246, 231))
    checker = Image.new("RGB", PREVIEW_CELL, (225, 246, 231))
    draw = ImageDraw.Draw(checker)
    step = 18
    for y in range(0, PREVIEW_CELL[1], step):
        for x in range(0, PREVIEW_CELL[0], step):
            if (x // step + y // step) % 2:
                draw.rectangle((x, y, x + step - 1, y + step - 1), fill=(204, 232, 212))

    for index, path in enumerate(files):
        cell = checker.copy()
        image = Image.open(path).convert("RGBA")
        thumb = image.copy()
        thumb.thumbnail((PREVIEW_CELL[0] - 16, PREVIEW_CELL[1] - 34), Image.Resampling.LANCZOS)
        x = (PREVIEW_CELL[0] - thumb.width) // 2
        y = PREVIEW_CELL[1] - 30 - thumb.height
        cell.paste(thumb, (x, y), thumb)
        bbox = alpha_bbox(image)
        label = f"{path.parent.name}/{path.stem} {bbox[2]-bbox[0]}x{bbox[3]-bbox[1]}"
        ImageDraw.Draw(cell).text((6, PREVIEW_CELL[1] - 22), label, fill=(42, 84, 52))
        preview.paste(cell, ((index % cols) * PREVIEW_CELL[0], (index // cols) * PREVIEW_CELL[1]))

    preview.save(OUT / "preview.jpg", quality=92)


def audit() -> None:
    files = sorted([
        *(OUT / "look").glob("*.png"),
        *(OUT / "look-angle").glob("*.png"),
        *(OUT / "blink").glob("*.png"),
        *(OUT / "wave").glob("*.png"),
    ])
    sizes = set()
    bottoms = set()
    for path in files:
        image = Image.open(path).convert("RGBA")
        sizes.add(image.size)
        bottoms.add(alpha_bbox(image)[3])
    assert sizes == {CANVAS}, sizes
    assert max(bottoms) - min(bottoms) <= 1, bottoms
    print(f"video_mascot_frames={len(files)} sizes={sorted(sizes)} bottoms={sorted(bottoms)}")


def main() -> None:
    frame_ids = set(LOOK_FRAME_IDS.values()) | set(LOOK_ANGLE_FRAME_IDS.values()) | set(BLINK_FRAME_IDS.values()) | set(WAVE_FRAME_IDS)
    frames = load_video_frames(frame_ids)
    save_named_frames(frames)
    build_preview()
    audit()


if __name__ == "__main__":
    main()
