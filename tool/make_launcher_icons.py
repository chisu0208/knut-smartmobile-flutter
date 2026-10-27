"""런처 아이콘 만들기(통합본 1-3).

원본 APK의 assets/app_icon_1024.png(학교 엠블럼)로 Android 런처 아이콘을 만든다.

- mipmap-*/ic_launcher.png, ic_launcher_round.png: Android 7.x(API 24~25)용 일반·둥근 아이콘
- mipmap-*/ic_launcher_foreground.png, ic_launcher_monochrome.png: Android 8.0 이상 적응형 아이콘
  (mipmap-anydpi-v26/ic_launcher*.xml이 배경색 @color/ic_launcher_background와 함께 쓴다)

실행(저장소 맨 위에서, Pillow 필요):
    python3 tool/make_launcher_icons.py
"""

import io
import pathlib
import zipfile

from PIL import Image, ImageChops, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
APK = ROOT / "한국교통대학교 스마트모바일_1.1.3.apk"
RES = ROOT / "android" / "app" / "src" / "main" / "res"

# 밀도별 크기(px): 일반 아이콘 48dp, 적응형 아이콘 한 겹 108dp
DENSITIES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}

# 적응형 아이콘에서 엠블럼 그림이 차지할 비율. 원 둘레(그림의 약 73%)가 안전 영역(66dp/108dp)
# 안에 들어가고, 가려지는 바깥(72dp/108dp)은 그림 안쪽만 보이도록 한다.
ADAPTIVE_SCALE = 0.76


def load_emblem() -> Image.Image:
    with zipfile.ZipFile(APK) as apk:
        data = apk.read("assets/app_icon_1024.png")
    image = Image.open(io.BytesIO(data)).convert("RGBA")
    # 가장자리 1px 회색 테두리를 잘라 낸다.
    width, height = image.size
    return image.crop((2, 2, width - 2, height - 2))


def rounded(image: Image.Image, radius_ratio: float) -> Image.Image:
    size = image.size[0]
    mask = Image.new("L", (size * 4, size * 4), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size * 4 - 1, size * 4 - 1), radius=int(size * 4 * radius_ratio), fill=255
    )
    mask = mask.resize((size, size), Image.LANCZOS)
    out = image.copy()
    out.putalpha(ImageChops.multiply(out.getchannel("A"), mask))
    return out


def circle(image: Image.Image) -> Image.Image:
    size = image.size[0]
    mask = Image.new("L", (size * 4, size * 4), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size * 4 - 1, size * 4 - 1), fill=255)
    mask = mask.resize((size, size), Image.LANCZOS)
    out = image.copy()
    out.putalpha(ImageChops.multiply(out.getchannel("A"), mask))
    return out


def centered(image: Image.Image, canvas: int, scale: float) -> Image.Image:
    inner = round(canvas * scale)
    out = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    offset = (canvas - inner) // 2
    out.paste(image.resize((inner, inner), Image.LANCZOS), (offset, offset))
    return out


def monochrome(image: Image.Image) -> Image.Image:
    """흰 엠블럼(원, 글자, 방패)만 남긴 한 색 아이콘(테마 아이콘용)."""
    gray = image.convert("RGB").split()
    darkest = ImageChops.darker(ImageChops.darker(gray[0], gray[1]), gray[2])
    alpha = darkest.point(lambda v: max(0, min(255, (v - 150) * 255 // 105)))
    out = Image.new("RGBA", image.size, (255, 255, 255, 0))
    out.putalpha(alpha)
    return out


def main() -> None:
    emblem = load_emblem()
    mono = monochrome(emblem)
    for name, factor in DENSITIES.items():
        folder = RES / f"mipmap-{name}"
        folder.mkdir(parents=True, exist_ok=True)
        legacy = emblem.resize((round(48 * factor),) * 2, Image.LANCZOS)
        rounded(legacy, 0.125).save(folder / "ic_launcher.png", optimize=True)
        circle(legacy).save(folder / "ic_launcher_round.png", optimize=True)
        layer = round(108 * factor)
        centered(emblem, layer, ADAPTIVE_SCALE).save(
            folder / "ic_launcher_foreground.png", optimize=True
        )
        centered(mono, layer, ADAPTIVE_SCALE).save(
            folder / "ic_launcher_monochrome.png", optimize=True
        )
    print("아이콘을 만들었습니다:", RES)


if __name__ == "__main__":
    main()
