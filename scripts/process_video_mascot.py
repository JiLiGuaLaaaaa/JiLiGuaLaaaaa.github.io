from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from shutil import rmtree

import imageio.v3 as iio
import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
VIDEO_SRC = ROOT / "生成指定动作视频 (3).mp4"
OUT = ROOT / "public" / "images" / "video-mascot"
AUDIT = OUT / "audit"

CANVAS = (860, 680)
BASELINE = 664
SOURCE_ROI = (0, 0, 1280, 720)
TARGET_WIDTH = 820
PREVIEW_CELL = (198, 188)
EDGE_AUDIT_CELL = (210, 190)

LOOK_FRAME_IDS = {
    "center": 152,
    "up": 120,
    "down": 40,
    "left": 88,
    "down-left": 64,
    "up-left": 112,
}
BLINK_FRAME_IDS = {
    "open": 152,
    "half-1": 164,
    "half-2": 166,
    "closed": 170,
    "open-2": 180,
}

# Browser pointer angles: 0 right, 90 down, 180 left, 270 up.
# Source frames 90..270 are real video frames; the right side is mirrored from
# those real frames to avoid inventing blended ghost frames.
LOOK_ANGLE_SOURCES = {
    90: (40, False),
    100: (48, False),
    110: (56, False),
    120: (64, False),
    130: (72, False),
    140: (80, False),
    150: (88, False),
    160: (92, False),
    170: (96, False),
    180: (100, False),
    190: (104, False),
    200: (108, False),
    210: (112, False),
    220: (116, False),
    230: (120, False),
    240: (128, False),
    250: (136, False),
    260: (144, False),
    270: (152, False),
    280: (144, True),
    290: (136, True),
    300: (128, True),
    310: (120, True),
    320: (116, True),
    330: (112, True),
    340: (108, True),
    350: (104, True),
    0: (100, True),
    10: (96, True),
    20: (92, True),
    30: (88, True),
    40: (80, True),
    50: (72, True),
    60: (64, True),
    70: (56, True),
    80: (48, True),
}
WAVE_FRAME_IDS = [196, 200, 204, 208, 212, 216, 224, 236]
LOOK_ANGLE_STEP = 10
BLINK_FACE_PATCH = (258, 226, 602, 404)


@dataclass(frozen=True)
class FrameMeta:
    name: str
    frame_id: int
    mirrored: bool = False
    direction: str = ""


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
    green = (g > 78) & (g > r + 18) & (g > b + 18)
    if not np.any(green):
        return np.array([76, 186, 132], dtype=np.uint8)
    return np.median(rgb[green], axis=0).astype(np.uint8)


def erase_watermark_zones(rgb: np.ndarray) -> np.ndarray:
    clean = rgb.copy()
    key = sample_green(clean)
    h, w = clean.shape[:2]
    clean[0:150, 0:390] = key
    clean[0:145, w - 380 : w] = key
    clean[h - 120 : h, w - 300 : w] = key
    return clean


def largest_component(mask: np.ndarray) -> np.ndarray:
    height, width = mask.shape
    visited = np.zeros_like(mask, dtype=bool)
    best_coords: list[tuple[int, int]] = []

    for y in range(height):
        for x in range(width):
            if visited[y, x] or not mask[y, x]:
                visited[y, x] = True
                continue

            stack = [(x, y)]
            visited[y, x] = True
            coords: list[tuple[int, int]] = []
            while stack:
                cx, cy = stack.pop()
                coords.append((cx, cy))
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < width and 0 <= ny < height and not visited[ny, nx]:
                        visited[ny, nx] = True
                        if mask[ny, nx]:
                            stack.append((nx, ny))
            if len(coords) > len(best_coords):
                best_coords = coords

    keep = np.zeros_like(mask, dtype=bool)
    for x, y in best_coords:
        keep[y, x] = True
    return keep


def green_to_alpha(image: Image.Image) -> Image.Image:
    rgb = np.asarray(image.convert("RGB"), dtype=np.uint8)
    rgb = erase_watermark_zones(rgb)
    key = sample_green(rgb).astype(np.float32)
    data = rgb.astype(np.float32)
    r = data[..., 0]
    g = data[..., 1]
    b = data[..., 2]
    max_rb = np.maximum(r, b)
    min_rgb = np.minimum.reduce([r, g, b])
    max_rgb = np.maximum.reduce([r, g, b])
    saturation = max_rgb - min_rgb

    green_delta = g - max_rb
    green_level = np.clip((g - 70.0) / 95.0, 0.0, 1.0)
    key_strength = np.clip((green_delta - 5.0) / 55.0, 0.0, 1.0) * green_level
    alpha = (1.0 - key_strength) * 255.0
    alpha[(g > 86) & (green_delta > 34)] = 0

    skin = (r > 130) & (g > 70) & (b > 50) & (r > b + 16) & (g > b + 5) & (g < r + 58)
    cloth = (alpha > 35) & (saturation < 92) & (r > 92) & (g > 78) & (b > 74)
    hair_dark = (alpha > 20) & (r > 32) & (b > 36) & (g < 130) & (r < 150)
    alpha[skin | cloth | hair_dark] = np.maximum(alpha[skin | cloth | hair_dark], 245)

    rough = alpha > 18
    keep = largest_component(rough)
    keep = np.array(Image.fromarray((keep * 255).astype(np.uint8), "L").filter(ImageFilter.MaxFilter(7))) > 0
    alpha[~keep] = 0

    alpha_image = Image.fromarray(np.clip(alpha, 0, 255).astype(np.uint8), "L")
    alpha_image = alpha_image.filter(ImageFilter.MinFilter(3))
    alpha_image = alpha_image.filter(ImageFilter.GaussianBlur(0.32))
    alpha = np.array(alpha_image, dtype=np.uint8)
    alpha[(alpha < 22) & ~(skin | cloth)] = 0
    alpha[skin | cloth | hair_dark] = np.maximum(alpha[skin | cloth | hair_dark], 238)

    soft_alpha = np.clip(alpha.astype(np.float32) / 255.0, 0.0, 1.0)
    edge_unmix = (alpha > 0) & (alpha < 245)
    safe = np.maximum(soft_alpha, 0.08)
    for channel in range(3):
        data[..., channel] = np.where(edge_unmix, (data[..., channel] - key[channel] * (1.0 - soft_alpha)) / safe, data[..., channel])
    data = np.clip(data, 0, 255)
    r = data[..., 0]
    g = data[..., 1]
    b = data[..., 2]
    max_rb = np.maximum(r, b)

    spill = (alpha > 0) & (g > max_rb + 1)
    neutral_green = r * 0.55 + b * 0.45
    data[..., 1] = np.where(spill, np.minimum(g, neutral_green + 4), g)

    # Premultiply-like edge cleanup: transparent edge pixels keep subject color,
    # not white/green background color, reducing visible halos on dark pages.
    edge = (alpha > 0) & (alpha < 248)
    data[..., 0] = np.where(edge, np.clip(data[..., 0] * 0.98, 0, 255), data[..., 0])
    data[..., 1] = np.where(edge, np.clip(data[..., 1] * 0.95, 0, 255), data[..., 1])
    data[..., 2] = np.where(edge, np.clip(data[..., 2] * 0.98, 0, 255), data[..., 2])

    rgba = np.dstack([np.clip(data, 0, 255).astype(np.uint8), alpha])
    return Image.fromarray(rgba, "RGBA")


def alpha_bbox(image: Image.Image, threshold: int = 8) -> tuple[int, int, int, int]:
    mask = image.getchannel("A").point(lambda value: 255 if value > threshold else 0)
    bbox = mask.getbbox()
    if not bbox:
        raise ValueError("empty alpha frame")
    return bbox


def normalize_frame(frame: Image.Image) -> Image.Image:
    keyed = green_to_alpha(frame)
    cropped = keyed.crop(SOURCE_ROI)
    target_height = round(cropped.height * TARGET_WIDTH / cropped.width)
    resized = cropped.resize((TARGET_WIDTH, target_height), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", CANVAS, (255, 255, 255, 0))
    x = (CANVAS[0] - resized.width) // 2
    y = BASELINE - resized.height
    canvas.alpha_composite(resized, (x, y))
    return canvas


def trim_corner_artifacts(image: Image.Image) -> Image.Image:
    clean = image.copy()
    alpha = np.array(clean.getchannel("A"), dtype=np.uint8)
    mask = Image.new("L", clean.size, 0)
    draw = ImageDraw.Draw(mask)
    width, height = clean.size
    draw.rectangle((0, 0, 72, 230), fill=255)
    draw.rectangle((width - 72, 0, width, 230), fill=255)
    draw.rectangle((0, height - 108, 120, height), fill=255)
    draw.rectangle((width - 120, height - 108, width, height), fill=255)
    alpha[np.array(mask, dtype=np.uint8) > 0] = 0
    clean.putalpha(Image.fromarray(alpha, "L"))
    return clean


def patch_blink_face(base: Image.Image, source: Image.Image) -> Image.Image:
    patched = base.copy()
    patch = source.crop(BLINK_FACE_PATCH)
    mask = Image.new("L", patch.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, patch.width - 1, patch.height - 1), radius=42, fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(7))
    patched.paste(patch, BLINK_FACE_PATCH[:2], mask)
    patched.putalpha(base.getchannel("A"))
    return patched


def angle_slug(angle: int) -> str:
    return f"a{angle + 360 if angle < 0 else angle:03d}"


def clean_output_dirs() -> None:
    for folder in ["look", "look-angle", "blink", "wave"]:
        target = OUT / folder
        if target.exists():
            rmtree(target)
        target.mkdir(parents=True, exist_ok=True)
    AUDIT.mkdir(parents=True, exist_ok=True)


def save_image(image: Image.Image, path: Path, mirrored: bool = False) -> None:
    output = ImageOps.mirror(image) if mirrored else image
    output.save(path)


def generate_angle_frames(processed: dict[int, Image.Image]) -> list[FrameMeta]:
    metas: list[FrameMeta] = []
    for angle in range(0, 360, LOOK_ANGLE_STEP):
        frame_id, mirrored = LOOK_ANGLE_SOURCES[angle]
        save_image(processed[frame_id], OUT / "look-angle" / f"{angle_slug(angle)}.png", mirrored)
        metas.append(FrameMeta(f"a{angle:03d}", frame_id, mirrored, f"{angle}deg"))
    return metas


def save_named_frames(frames: dict[int, Image.Image]) -> list[FrameMeta]:
    clean_output_dirs()
    processed = {index: trim_corner_artifacts(normalize_frame(frame)) for index, frame in frames.items()}
    metas: list[FrameMeta] = []

    for name, frame_id in LOOK_FRAME_IDS.items():
        save_image(processed[frame_id], OUT / "look" / f"{name}.png")
        metas.append(FrameMeta(f"look/{name}", frame_id, False, name))
    mirror_pairs = {
        "right": ("left", "right"),
        "up-right": ("up-left", "up-right"),
        "down-right": ("down-left", "down-right"),
    }
    for out_name, (src_name, direction) in mirror_pairs.items():
        frame_id = LOOK_FRAME_IDS[src_name]
        save_image(processed[frame_id], OUT / "look" / f"{out_name}.png", True)
        metas.append(FrameMeta(f"look/{out_name}", frame_id, True, direction))

    metas.extend(generate_angle_frames(processed))

    blink_base = processed[BLINK_FRAME_IDS["open"]]
    for name, frame_id in BLINK_FRAME_IDS.items():
        image = blink_base if name in {"open", "open-2"} else patch_blink_face(blink_base, processed[frame_id])
        image.save(OUT / "blink" / f"{name}.png")
        metas.append(FrameMeta(f"blink/{name}", frame_id, False, name))

    for index, frame_id in enumerate(WAVE_FRAME_IDS):
        processed[frame_id].save(OUT / "wave" / f"wave-{index}.png")
        metas.append(FrameMeta(f"wave/wave-{index}", frame_id, False, f"wave-{index}"))

    write_audit_report(metas)
    build_audit_sheets(metas)
    return metas


def compose_checker(size: tuple[int, int], cell: int = 18) -> Image.Image:
    checker = Image.new("RGB", size, (225, 246, 231))
    draw = ImageDraw.Draw(checker)
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            if (x // cell + y // cell) % 2:
                draw.rectangle((x, y, x + cell - 1, y + cell - 1), fill=(204, 232, 212))
    return checker


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
    checker = compose_checker(PREVIEW_CELL)

    for index, path in enumerate(files):
        cell = checker.copy()
        image = Image.open(path).convert("RGBA")
        thumb = image.copy()
        thumb.thumbnail((PREVIEW_CELL[0] - 16, PREVIEW_CELL[1] - 36), Image.Resampling.LANCZOS)
        x = (PREVIEW_CELL[0] - thumb.width) // 2
        y = PREVIEW_CELL[1] - 32 - thumb.height
        cell.paste(thumb, (x, y), thumb)
        bbox = alpha_bbox(image)
        label = f"{path.parent.name}/{path.stem} {bbox[2]-bbox[0]}x{bbox[3]-bbox[1]}"
        ImageDraw.Draw(cell).text((6, PREVIEW_CELL[1] - 23), label, fill=(42, 84, 52))
        preview.paste(cell, ((index % cols) * PREVIEW_CELL[0], (index // cols) * PREVIEW_CELL[1]))

    preview.save(OUT / "preview.jpg", quality=92)


def write_audit_report(metas: list[FrameMeta]) -> None:
    lines = [
        "# video mascot audit",
        "",
        f"source: {VIDEO_SRC.name}",
        f"canvas: {CANVAS[0]}x{CANVAS[1]}",
        f"baseline: {BASELINE}",
        "",
        "| output | source frame | mirrored | direction |",
        "| --- | ---: | --- | --- |",
    ]
    for meta in metas:
        lines.append(f"| {meta.name} | {meta.frame_id} | {'yes' if meta.mirrored else 'no'} | {meta.direction} |")
    (AUDIT / "video3-audit.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def frame_path(meta: FrameMeta) -> Path:
    folder, name = meta.name.split("/", 1) if "/" in meta.name else ("look-angle", meta.name)
    return OUT / folder / f"{name}.png"


def build_audit_sheet(metas: list[FrameMeta], out: Path, cols: int = 5) -> None:
    rows = (len(metas) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * EDGE_AUDIT_CELL[0], rows * EDGE_AUDIT_CELL[1]), (225, 246, 231))
    checker = compose_checker(EDGE_AUDIT_CELL)
    for index, meta in enumerate(metas):
        path = frame_path(meta)
        cell = checker.copy()
        image = Image.open(path).convert("RGBA")
        thumb = image.copy()
        thumb.thumbnail((EDGE_AUDIT_CELL[0] - 14, EDGE_AUDIT_CELL[1] - 44), Image.Resampling.LANCZOS)
        x = (EDGE_AUDIT_CELL[0] - thumb.width) // 2
        y = EDGE_AUDIT_CELL[1] - 40 - thumb.height
        cell.paste(thumb, (x, y), thumb)
        label = f"{meta.name} f{meta.frame_id}{' M' if meta.mirrored else ''}"
        ImageDraw.Draw(cell).text((6, EDGE_AUDIT_CELL[1] - 34), label, fill=(36, 74, 48))
        ImageDraw.Draw(cell).text((6, EDGE_AUDIT_CELL[1] - 18), meta.direction, fill=(36, 74, 48))
        sheet.paste(cell, ((index % cols) * EDGE_AUDIT_CELL[0], (index // cols) * EDGE_AUDIT_CELL[1]))
    sheet.save(out, quality=92)


def build_edge_sheet(paths: list[Path], out: Path) -> None:
    cols = len(paths)
    zoom = 2
    cell = (220, 240)
    sheet = Image.new("RGB", (cols * cell[0], cell[1]), (38, 38, 38))
    for index, path in enumerate(paths):
        image = Image.open(path).convert("RGBA")
        bbox = alpha_bbox(image, 4)
        pad = 18
        crop = image.crop((max(0, bbox[0] - pad), max(0, bbox[1] - pad), min(image.width, bbox[2] + pad), min(image.height, bbox[3] + pad)))
        if path.parent.name == "wave":
            crop = crop.crop((0, 0, min(crop.width, 260), min(crop.height, 290)))
        crop = crop.resize((crop.width * zoom, crop.height * zoom), Image.Resampling.NEAREST)
        crop.thumbnail((cell[0] - 10, cell[1] - 30), Image.Resampling.NEAREST)
        checker = compose_checker((cell[0], cell[1]), 10)
        checker = ImageChops.multiply(checker, Image.new("RGB", (cell[0], cell[1]), (150, 150, 150)))
        x = index * cell[0] + (cell[0] - crop.width) // 2
        y = 8
        checker.paste(crop, ((cell[0] - crop.width) // 2, y), crop)
        ImageDraw.Draw(checker).text((6, cell[1] - 20), f"{path.parent.name}/{path.stem}", fill=(255, 255, 255))
        sheet.paste(checker, (index * cell[0], 0))
    sheet.save(out, quality=92)


def build_audit_sheets(metas: list[FrameMeta]) -> None:
    build_audit_sheet([meta for meta in metas if meta.name.startswith("look/")], AUDIT / "video3-look-audit.jpg")
    build_audit_sheet([meta for meta in metas if meta.name.startswith("a")], AUDIT / "video3-angle-audit.jpg", cols=6)
    build_audit_sheet([meta for meta in metas if meta.name.startswith("wave/")], AUDIT / "video3-wave-audit.jpg", cols=4)
    build_edge_sheet([OUT / "wave" / f"wave-{index}.png" for index in (4, 5, 6)], AUDIT / "video3-wave-456-edge-audit.jpg")


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
    assert len(files) == 58, len(files)
    print(f"video_mascot_frames={len(files)} sizes={sorted(sizes)} bottoms={sorted(bottoms)}")


def main() -> None:
    frame_ids = (
        set(LOOK_FRAME_IDS.values())
        | {frame_id for frame_id, _mirrored in LOOK_ANGLE_SOURCES.values()}
        | set(BLINK_FRAME_IDS.values())
        | set(WAVE_FRAME_IDS)
    )
    frames = load_video_frames(frame_ids)
    save_named_frames(frames)
    build_preview()
    audit()


if __name__ == "__main__":
    main()
