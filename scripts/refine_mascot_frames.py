from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "public" / "images" / "mascot-frames"
BLINK_SRC = ROOT / "ChatGPT Image 2026年5月9日 17_10_19.png"
LOOK_SRC = ROOT / "ChatGPT Image 2026年5月9日 17_10_55.png"
WAVE_SRC = ROOT / "ChatGPT Image 2026年5月9日 16_58_49.png"

CANVAS = (520, 560)
BASELINE = 548
PREVIEW_CELL = (188, 182)
WAVE_TARGET_HEIGHT = 516
BLINK_FRAME_NAMES = ["open", "half-1", "half-2", "closed", "open-2"]
BLINK_EYE_BOXES = [(170, 262, 232, 294), (288, 262, 350, 294)]
WAVE_ARM_CUTS = [
    (344, 220),
    (342, 198),
    (338, 174),
    (334, 146),
    (330, 122),
    (328, 105),
    (326, 95),
    (324, 88),
]


def whiten_to_alpha(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    background: set[tuple[int, int]] = set()
    queue: deque[tuple[int, int]] = deque()

    def is_background_candidate(x: int, y: int) -> bool:
        r, g, b, a = pixels[x, y]
        if a == 0:
            return True
        whiteness = min(r, g, b)
        spread = max(r, g, b) - whiteness
        return whiteness > 238 and spread < 34

    for x in range(width):
        for y in (0, height - 1):
            if is_background_candidate(x, y) and (x, y) not in background:
                background.add((x, y))
                queue.append((x, y))
    for y in range(height):
        for x in (0, width - 1):
            if is_background_candidate(x, y) and (x, y) not in background:
                background.add((x, y))
                queue.append((x, y))

    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in background:
                if is_background_candidate(nx, ny):
                    background.add((nx, ny))
                    queue.append((nx, ny))

    for x, y in background:
        r, g, b, _a = pixels[x, y]
        pixels[x, y] = (r, g, b, 0)
    return rgba


def remove_left_edge_fragments(
    image: Image.Image,
    *,
    alpha_threshold: int = 8,
    max_area: int = 420,
    max_x: int = 72,
) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    visited = [[False for _ in range(width)] for _ in range(height)]
    components: list[tuple[int, int, list[tuple[int, int]]]] = []

    for y in range(height):
        for x in range(width):
            if visited[y][x]:
                continue
            visited[y][x] = True
            if pixels[x, y][3] <= alpha_threshold:
                continue

            queue: deque[tuple[int, int]] = deque([(x, y)])
            coords: list[tuple[int, int]] = []
            area = 0
            right_edge = x
            while queue:
                cx, cy = queue.popleft()
                if pixels[cx, cy][3] <= alpha_threshold:
                    continue
                coords.append((cx, cy))
                area += 1
                right_edge = max(right_edge, cx)

                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < width and 0 <= ny < height and not visited[ny][nx]:
                        visited[ny][nx] = True
                        queue.append((nx, ny))

            if area:
                components.append((area, right_edge, coords))

    if not components:
        return rgba

    largest_index = max(range(len(components)), key=lambda idx: components[idx][0])
    for index, (area, right_edge, coords) in enumerate(components):
        if index == largest_index:
            continue
        if area <= max_area and right_edge <= max_x:
            for px, py in coords:
                r, g, b, _a = pixels[px, py]
                pixels[px, py] = (r, g, b, 0)

    return rgba


def keep_primary_component(image: Image.Image, *, alpha_threshold: int = 8) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    visited = [[False for _ in range(width)] for _ in range(height)]
    components: list[tuple[int, int, int, int, int, list[tuple[int, int]]]] = []

    for y in range(height):
        for x in range(width):
            if visited[y][x]:
                continue
            visited[y][x] = True
            if pixels[x, y][3] <= alpha_threshold:
                continue

            queue: deque[tuple[int, int]] = deque([(x, y)])
            coords: list[tuple[int, int]] = []
            min_x = max_x = x
            min_y = max_y = y
            while queue:
                cx, cy = queue.popleft()
                if pixels[cx, cy][3] <= alpha_threshold:
                    continue
                coords.append((cx, cy))
                min_x = min(min_x, cx)
                max_x = max(max_x, cx)
                min_y = min(min_y, cy)
                max_y = max(max_y, cy)
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < width and 0 <= ny < height and not visited[ny][nx]:
                        visited[ny][nx] = True
                        queue.append((nx, ny))

            if coords:
                components.append((len(coords), min_x, min_y, max_x, max_y, coords))

    if not components:
        return rgba

    center_x = width / 2
    center_y = height / 2

    def component_score(component: tuple[int, int, int, int, int, list[tuple[int, int]]]) -> float:
        area, min_x, min_y, max_x, max_y, _coords = component
        box_center_x = (min_x + max_x) / 2
        box_center_y = (min_y + max_y) / 2
        distance = abs(box_center_x - center_x) + abs(box_center_y - center_y) * 0.7
        return area - distance * 2.0

    primary_index = max(range(len(components)), key=lambda idx: component_score(components[idx]))
    for index, (_area, _min_x, _min_y, _max_x, _max_y, coords) in enumerate(components):
        if index == primary_index:
            continue
        for px, py in coords:
            r, g, b, _a = pixels[px, py]
            pixels[px, py] = (r, g, b, 0)

    return rgba


def alpha_bbox(image: Image.Image, threshold: int = 8) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    mask = alpha.point(lambda value: 255 if value > threshold else 0)
    bbox = mask.getbbox()
    if not bbox:
        raise ValueError("empty frame")
    return bbox


def repair_lower_garment_holes(
    image: Image.Image,
    *,
    lower_start_ratio: float = 0.58,
    margin_x: int = 22,
    kernel_size: int = 19,
    min_row_span: int = 110,
    row_fill: bool = True,
) -> Image.Image:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    closed = alpha.filter(ImageFilter.MaxFilter(kernel_size)).filter(ImageFilter.MinFilter(kernel_size))
    alpha_pixels = alpha.load()
    closed_pixels = closed.load()
    width, height = rgba.size
    bbox = alpha_bbox(rgba)
    x_start = max(0, bbox[0] + margin_x)
    x_end = min(width, bbox[2] - margin_x)
    y_start = max(0, bbox[1] + round((bbox[3] - bbox[1]) * lower_start_ratio))

    if x_end <= x_start or y_start >= bbox[3]:
        return rgba

    for y in range(y_start, bbox[3]):
        for x in range(x_start, x_end):
            if alpha_pixels[x, y] <= 8 and closed_pixels[x, y] > 8:
                alpha_pixels[x, y] = 255

    if row_fill:
        row_fill_start = max(y_start, bbox[1] + round((bbox[3] - bbox[1]) * 0.5))
        for y in range(row_fill_start, bbox[3]):
            row_pixels = [x for x in range(x_start, x_end) if alpha_pixels[x, y] > 8]
            if len(row_pixels) < 2:
                continue
            left_edge = row_pixels[0]
            right_edge = row_pixels[-1]
            if right_edge - left_edge < min_row_span:
                continue
            for x in range(left_edge, right_edge + 1):
                alpha_pixels[x, y] = 255

    rgba.putalpha(alpha)
    return rgba


def remove_wave_edge_fragments(image: Image.Image) -> Image.Image:
    cleaned = remove_left_edge_fragments(image, max_area=9000, max_x=86)
    pixels = cleaned.load()
    width, height = cleaned.size
    visited = [[False for _ in range(width)] for _ in range(height)]
    for y in range(height):
        for x in range(min(54, width)):
            r, g, b, a = pixels[x, y]
            if a <= 8:
                continue
            if y < 405 and (x < 36 or min(r, g, b) > 180):
                pixels[x, y] = (r, g, b, 0)

    for y in range(height):
        for x in range(width):
            if visited[y][x]:
                continue
            visited[y][x] = True
            if pixels[x, y][3] <= 8:
                continue

            queue: deque[tuple[int, int]] = deque([(x, y)])
            coords: list[tuple[int, int]] = []
            min_x = max_x = x
            min_y = max_y = y
            while queue:
                cx, cy = queue.popleft()
                if pixels[cx, cy][3] <= 8:
                    continue
                coords.append((cx, cy))
                min_x = min(min_x, cx)
                max_x = max(max_x, cx)
                min_y = min(min_y, cy)
                max_y = max(max_y, cy)
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < width and 0 <= ny < height and not visited[ny][nx]:
                        visited[ny][nx] = True
                        queue.append((nx, ny))

            area = len(coords)
            near_left_edge = min_x <= 108 and max_x <= 140
            isolated_lower_piece = min_y >= 430 and area <= 1600
            isolated_vertical_edge = max_x <= 58 and area <= 1200
            if near_left_edge and (isolated_lower_piece or isolated_vertical_edge):
                for px, py in coords:
                    r, g, b, _a = pixels[px, py]
                    pixels[px, py] = (r, g, b, 0)
    return cleaned


def inpaint_lower_transparency(image: Image.Image) -> Image.Image:
    rgba = repair_lower_garment_holes(image, lower_start_ratio=0.56, margin_x=18, kernel_size=17)
    pixels = rgba.load()
    alpha = rgba.getchannel("A")
    alpha_pixels = alpha.load()
    bbox = alpha_bbox(rgba)
    x_start = max(0, bbox[0] + 18)
    x_end = min(rgba.width, bbox[2] - 18)
    y_start = max(395, bbox[1] + round((bbox[3] - bbox[1]) * 0.58))

    for y in range(y_start, bbox[3]):
        opaque_xs = [x for x in range(x_start, x_end) if alpha_pixels[x, y] > 8]
        if len(opaque_xs) < 2:
            continue
        left_edge = opaque_xs[0]
        right_edge = opaque_xs[-1]
        if right_edge - left_edge < 120:
            continue
        for x in range(left_edge, right_edge + 1):
            if alpha_pixels[x, y] > 8:
                continue
            left = next((lx for lx in range(x - 1, left_edge - 1, -1) if alpha_pixels[lx, y] > 8), None)
            right = next((rx for rx in range(x + 1, right_edge + 1) if alpha_pixels[rx, y] > 8), None)
            if left is None and right is None:
                continue
            if left is None:
                sample = pixels[right, y]
            elif right is None:
                sample = pixels[left, y]
            else:
                sample = tuple((pixels[left, y][channel] + pixels[right, y][channel]) // 2 for channel in range(4))
            pixels[x, y] = (sample[0], sample[1], sample[2], 255)
            alpha_pixels[x, y] = 255

    rgba.putalpha(alpha)
    return rgba


def clear_left_wave_artifact(image: Image.Image, index: int) -> Image.Image:
    if index < 4:
        return image

    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(118, rgba.height):
        x_limit = 128 if y < 360 else 146
        for x in range(min(x_limit, rgba.width)):
            r, g, b, a = pixels[x, y]
            if a > 8:
                pixels[x, y] = (r, g, b, 0)
    return rgba


def normalize_frame(
    image: Image.Image,
    *,
    target_height: int = 526,
    x_shift: int = 0,
    y_shift: int = 0,
    prepared_alpha: bool = False,
) -> Image.Image:
    frame = image.convert("RGBA") if prepared_alpha else whiten_to_alpha(image)
    bbox = alpha_bbox(frame)
    subject = frame.crop(bbox)
    scale = target_height / subject.height
    target_width = max(1, round(subject.width * scale))
    subject = subject.resize((target_width, target_height), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", CANVAS, (255, 255, 255, 0))
    x = (CANVAS[0] - subject.width) // 2 + x_shift
    y = BASELINE - subject.height + y_shift
    canvas.alpha_composite(subject, (x, y))
    return canvas


def build_stable_wave_frame(base: Image.Image, source: Image.Image, index: int) -> Image.Image:
    frame = repair_lower_garment_holes(base)
    source_rgba = source.convert("RGBA")
    source_pixels = source_rgba.load()
    mask = Image.new("L", CANVAS, 0)
    mask_pixels = mask.load()
    x_cut, y_cut = WAVE_ARM_CUTS[index]

    for y in range(y_cut, CANVAS[1]):
        dynamic_x_cut = x_cut
        if y < 250:
            dynamic_x_cut = max(dynamic_x_cut, 382)
        elif y < 340:
            dynamic_x_cut = max(dynamic_x_cut, 360)

        for x in range(dynamic_x_cut, CANVAS[0]):
            r, g, b, a = source_pixels[x, y]
            if a <= 8:
                continue
            if max(r, g, b) < 88:
                continue
            edge_fade = min(1, max(0, (x - dynamic_x_cut) / 18))
            if edge_fade <= 0:
                continue
            mask_pixels[x, y] = round(a * edge_fade)

    overlay = Image.new("RGBA", CANVAS, (255, 255, 255, 0))
    overlay.paste(source_rgba, (0, 0), mask)
    frame.alpha_composite(overlay)
    return repair_lower_garment_holes(frame, row_fill=False)


def quadratic_points(
    start: tuple[int, int],
    control: tuple[int, int],
    end: tuple[int, int],
    *,
    steps: int = 32,
) -> list[tuple[int, int]]:
    points = []
    for index in range(steps):
        t = index / (steps - 1)
        x = round((1 - t) ** 2 * start[0] + 2 * (1 - t) * t * control[0] + t**2 * end[0])
        y = round((1 - t) ** 2 * start[1] + 2 * (1 - t) * t * control[1] + t**2 * end[1])
        points.append((x, y))
    return points


def sample_box_color(base: Image.Image, box: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    pixels = base.convert("RGBA").load()
    colors: list[tuple[int, int, int]] = []
    for y in range(298, 326):
        for x in range(180, 340):
            r, g, b, a = pixels[x, y]
            if (
                a > 220
                and r > 210
                and 150 <= g <= 232
                and 140 <= b <= 224
                and r >= g >= b - 8
                and max(r, g, b) - min(r, g, b) < 92
            ):
                colors.append((r, g, b))

    if not colors:
        return (248, 226, 216, 255)

    r, g, b = (sum(color[index] for color in colors) // len(colors) for index in range(3))
    return (min(255, r + 2), min(255, g + 7), min(255, b + 8), 255)


def cover_eye_region(frame: Image.Image, box: tuple[int, int, int, int], opacity: int) -> None:
    patch = Image.new("RGBA", CANVAS, sample_box_color(frame, box))
    mask = Image.new("L", CANVAS, 0)
    draw = ImageDraw.Draw(mask)
    x1, y1, x2, y2 = box
    draw.ellipse((x1 + 1, y1 + 1, x2 - 1, y2), fill=round(opacity * 0.78))
    draw.ellipse((x1 + 7, y1 + 4, x2 - 7, y2 - 3), fill=opacity)
    mask = mask.filter(ImageFilter.GaussianBlur(0.75))
    frame.alpha_composite(Image.composite(patch, Image.new("RGBA", CANVAS, (0, 0, 0, 0)), mask))


def paste_eye_slit(frame: Image.Image, base: Image.Image, box: tuple[int, int, int, int], openness: int) -> None:
    x1, y1, x2, y2 = box
    eye = base.convert("RGBA").crop(box)
    mask = Image.new("L", eye.size, 0)
    draw = ImageDraw.Draw(mask)
    center_y = eye.height // 2 + 1
    draw.rounded_rectangle(
        (9, center_y - openness, eye.width - 9, center_y + openness),
        radius=max(2, openness),
        fill=175,
    )
    mask = mask.filter(ImageFilter.GaussianBlur(0.35))
    frame.paste(eye, (x1, y1), mask)


def draw_blink_expression(base: Image.Image, name: str) -> Image.Image:
    if name in {"open", "open-2"}:
        return base.convert("RGBA").copy()

    frame = base.convert("RGBA").copy()
    draw = ImageDraw.Draw(frame, "RGBA")
    expressions = {
        "half-1": {
            "eye_y": 277,
            "curve": -3,
            "width": 2,
            "cover": 185,
            "slit": 3,
            "mouth_y": 324,
        },
        "half-2": {
            "eye_y": 278,
            "curve": -1,
            "width": 2,
            "cover": 220,
            "slit": 1,
            "mouth_y": 324,
        },
        "closed": {
            "eye_y": 279,
            "curve": 1,
            "width": 2,
            "cover": 255,
            "slit": 0,
            "mouth_y": 324,
        },
    }
    expression = expressions[name]

    for box in BLINK_EYE_BOXES:
        cover_eye_region(frame, box, expression["cover"])
        if expression["slit"]:
            paste_eye_slit(frame, base, box, openness=expression["slit"])

        x1, _y1, x2, _y2 = box
        y = expression["eye_y"]
        inset = 11 if name == "closed" else 12
        start = (x1 + inset, y)
        control = ((x1 + x2) // 2, y + expression["curve"])
        end = (x2 - inset, y)
        points = quadratic_points(start, control, end)
        draw.line(points, fill=(48, 23, 42, 238), width=expression["width"], joint="curve")

        if name == "closed":
            left_lash = (start[0] + 3, y - 1)
            right_lash = (end[0] - 3, y - 1)
            draw.line([left_lash, (left_lash[0] - 3, left_lash[1] - 2)], fill=(48, 23, 42, 150), width=1)
            draw.line([right_lash, (right_lash[0] + 3, right_lash[1] - 2)], fill=(48, 23, 42, 150), width=1)

    mouth_y = expression["mouth_y"]
    mouth_points = quadratic_points((238, mouth_y), (264, mouth_y + 1), (288, mouth_y), steps=24)
    draw.line(mouth_points, fill=(110, 54, 64, 185), width=1)
    return frame


def crop_grid(image: Image.Image, cols: int, rows: int, index: int) -> Image.Image:
    col = index % cols
    row = index // cols
    w, h = image.size
    x1 = round(col * w / cols)
    y1 = round(row * h / rows)
    x2 = round((col + 1) * w / cols)
    y2 = round((row + 1) * h / rows)
    return image.crop((x1, y1, x2, y2))


def crop_strip(image: Image.Image, count: int, index: int, pad_x: int = 0) -> Image.Image:
    w, h = image.size
    x1 = round(index * w / count)
    x2 = round((index + 1) * w / count)
    x1 = max(0, x1 - pad_x)
    x2 = min(w, x2 + pad_x)
    return image.crop((x1, 0, x2, h))


def crop_wave_cell(image: Image.Image, index: int) -> Image.Image:
    w, h = image.size
    x1 = round(index * w / 8)
    x2 = round((index + 1) * w / 8)
    return image.crop((x1, 0, x2, h))


def regenerate_wave_frames() -> None:
    wave_sheet = Image.open(WAVE_SRC).convert("RGBA")
    for index in range(8):
        crop = crop_wave_cell(wave_sheet, index)
        cleaned = keep_primary_component(whiten_to_alpha(crop))
        source = normalize_frame(cleaned, target_height=WAVE_TARGET_HEIGHT, prepared_alpha=True)
        frame = inpaint_lower_transparency(source)
        frame = clear_left_wave_artifact(frame, index)
        frame.save(OUT / "wave" / f"wave-{index}.png")


def refine_up_down_look_frames() -> None:
    look_sheet = Image.open(LOOK_SRC).convert("RGBA")
    # The provided 3x3 sheet contains clear straight-up at top-right and
    # straight-down at bottom-right. The middle-left/right cells are clearer
    # horizontal looks, so keep the previous mirror rule for those directions.
    center = repair_lower_garment_holes(Image.open(OUT / "look" / "center.png").convert("RGBA"))
    center.save(OUT / "look" / "center.png")

    up_crop = crop_grid(look_sheet, 3, 3, 2)
    up = repair_lower_garment_holes(normalize_frame(up_crop, target_height=527))
    w, h = look_sheet.size
    down_crop = look_sheet.crop((round(2 * w / 3), round(2 * h / 3) + 24, w, h))
    down = repair_lower_garment_holes(normalize_frame(down_crop, target_height=527))
    up.save(OUT / "look" / "up.png")
    down.save(OUT / "look" / "down.png")

    left = repair_lower_garment_holes(Image.open(OUT / "look" / "left.png").convert("RGBA"))
    down_left = repair_lower_garment_holes(Image.open(OUT / "look" / "down-left.png").convert("RGBA"))
    up_left = repair_lower_garment_holes(Image.open(OUT / "look" / "up-left.png").convert("RGBA"))
    left.save(OUT / "look" / "left.png")
    down_left.save(OUT / "look" / "down-left.png")
    up_left.save(OUT / "look" / "up-left.png")
    ImageOps.mirror(left).save(OUT / "look" / "right.png")
    ImageOps.mirror(up_left).save(OUT / "look" / "up-right.png")
    ImageOps.mirror(down_left).save(OUT / "look" / "down-right.png")


def regenerate_blink_frames() -> None:
    base = Image.open(OUT / "look" / "center.png").convert("RGBA")
    for name in BLINK_FRAME_NAMES:
        frame = draw_blink_expression(base, name)
        frame.save(OUT / "blink" / f"{name}.png")


def blend(a_path: Path, b_path: Path, out_path: Path, alpha: float) -> None:
    a = Image.open(a_path).convert("RGBA")
    b = Image.open(b_path).convert("RGBA")
    Image.blend(a, b, alpha).save(out_path)


def create_inbetweens() -> None:
    for index in range(7):
        frame = Image.open(OUT / "wave" / f"wave-{index + 1}.png").convert("RGBA")
        frame.save(OUT / "wave" / f"wave-{index}-to-{index + 1}.png")


def align_all_bottoms() -> None:
    files = []
    for sub in ["look", "blink", "wave"]:
        files.extend((OUT / sub).glob("*.png"))
    for path in files:
        image = Image.open(path).convert("RGBA")
        bbox = alpha_bbox(image)
        dy = BASELINE - bbox[3]
        if dy == 0:
            continue
        canvas = Image.new("RGBA", CANVAS, (255, 255, 255, 0))
        canvas.alpha_composite(image, (0, dy))
        canvas.save(path)


def quantize_pngs() -> None:
    files = []
    for sub in ["look", "blink", "wave"]:
        files.extend((OUT / sub).glob("*.png"))
    for png in sorted(files):
        image = Image.open(png).convert("RGBA")
        image.save(png, optimize=True)


def build_preview() -> None:
    files = [
        *(OUT / "look").glob("*.png"),
        *(OUT / "blink").glob("*.png"),
        *(OUT / "wave").glob("*.png"),
    ]
    files = sorted(files, key=lambda p: (p.parent.name, p.name))
    cols = 5
    rows = (len(files) + cols - 1) // cols
    preview = Image.new("RGB", (cols * PREVIEW_CELL[0], rows * PREVIEW_CELL[1]), (255, 238, 246))
    checker = Image.new("RGB", PREVIEW_CELL, (255, 238, 246))
    draw = ImageDraw.Draw(checker)
    step = 18
    for y in range(0, PREVIEW_CELL[1], step):
        for x in range(0, PREVIEW_CELL[0], step):
            if (x // step + y // step) % 2:
                draw.rectangle((x, y, x + step - 1, y + step - 1), fill=(248, 218, 232))

    for i, path in enumerate(files):
        cell = checker.copy()
        image = Image.open(path).convert("RGBA")
        thumb = image.copy()
        thumb.thumbnail((PREVIEW_CELL[0] - 16, PREVIEW_CELL[1] - 34), Image.Resampling.LANCZOS)
        x = (PREVIEW_CELL[0] - thumb.width) // 2
        y = PREVIEW_CELL[1] - 30 - thumb.height
        cell.paste(thumb, (x, y), thumb)
        bbox = alpha_bbox(image)
        label = f"{path.parent.name}/{path.stem} {bbox[2]-bbox[0]}x{bbox[3]-bbox[1]}"
        ImageDraw.Draw(cell).text((6, PREVIEW_CELL[1] - 22), label, fill=(92, 48, 68))
        preview.paste(cell, ((i % cols) * PREVIEW_CELL[0], (i // cols) * PREVIEW_CELL[1]))

    preview.save(OUT / "preview.jpg", quality=92)


def audit() -> None:
    files = sorted([*(OUT / "look").glob("*.png"), *(OUT / "blink").glob("*.png"), *(OUT / "wave").glob("*.png")])
    sizes = set()
    bottoms = set()
    for path in files:
        image = Image.open(path).convert("RGBA")
        sizes.add(image.size)
        bottoms.add(alpha_bbox(image)[3])
    assert sizes == {CANVAS}, sizes
    assert max(bottoms) - min(bottoms) <= 1, bottoms

    for left_name, right_name in [
        ("left.png", "right.png"),
        ("up-left.png", "up-right.png"),
        ("down-left.png", "down-right.png"),
    ]:
        left = Image.open(OUT / "look" / left_name).convert("RGBA")
        right = Image.open(OUT / "look" / right_name).convert("RGBA")
        assert ImageChops.difference(ImageOps.mirror(left), right).getbbox() is None

    print(
        f"motion_frames={len(files)} sizes={sorted(sizes)} bottoms={sorted(bottoms)}"
    )


def main() -> None:
    refine_up_down_look_frames()
    regenerate_blink_frames()
    regenerate_wave_frames()
    create_inbetweens()
    align_all_bottoms()
    quantize_pngs()
    build_preview()
    audit()


if __name__ == "__main__":
    main()
