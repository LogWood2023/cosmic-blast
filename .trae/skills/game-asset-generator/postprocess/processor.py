from io import BytesIO
from typing import Optional


class PostProcessor:
    def __init__(self):
        self._cutout_session = None
        self._cutout_enabled = False
        self._cutout_model = "u2netp"

    def init_cutout(self, model: str = "u2netp"):
        from rembg import new_session

        self._cutout_model = model
        self._cutout_session = new_session(model)
        self._cutout_enabled = True

    def remove_background(self, image_data: bytes) -> bytes:
        if not self._cutout_enabled or self._cutout_session is None:
            return image_data

        from rembg import remove

        return remove(image_data, session=self._cutout_session)

    @property
    def cutout_enabled(self) -> bool:
        return self._cutout_enabled

    @staticmethod
    def clean_pixel_art(
        image_data: bytes,
        target_size: int = 256,
        num_colors: int = 32,
        contrast: float = 1.0,
        dither: bool = False,
    ) -> bytes:
        from PIL import Image, ImageEnhance

        img = Image.open(BytesIO(image_data))
        original_size = img.size
        original_mode = img.mode
        has_alpha = original_mode == "RGBA"

        if contrast != 1.0:
            img = ImageEnhance.Contrast(img).enhance(contrast)

        w, h = img.size
        ratio = target_size / max(w, h)
        new_w = max(1, int(w * ratio))
        new_h = max(1, int(h * ratio))
        small = img.resize((new_w, new_h), Image.LANCZOS)

        if has_alpha:
            alpha = small.split()[-1]
            rgb = small.convert("RGB")
            quantized = rgb.quantize(
                colors=num_colors,
                method=Image.Quantize.MEDIANCUT,
                dither=Image.Dither.FLOYDSTEINBERG if dither else Image.Dither.NONE,
            ).convert("RGB")
            quantized.putalpha(alpha)
        else:
            quantized = small.quantize(
                colors=num_colors,
                method=Image.Quantize.MEDIANCUT,
                dither=Image.Dither.FLOYDSTEINBERG if dither else Image.Dither.NONE,
            ).convert("RGB")

        clean = quantized.resize(original_size, Image.NEAREST)

        buf = BytesIO()
        clean.save(buf, format="PNG")
        return buf.getvalue()

    @staticmethod
    def resize_if_needed(
        image_data: bytes,
        target_size: Optional[tuple[int, int]] = None,
    ) -> bytes:
        if target_size is None:
            return image_data

        try:
            from PIL import Image
        except ImportError:
            return image_data

        img = Image.open(BytesIO(image_data))
        if img.size == target_size:
            return image_data

        img = img.resize(target_size, Image.LANCZOS)
        buf = BytesIO()
        img.save(buf, format="PNG")
        return buf.getvalue()

    @staticmethod
    def crop_resize_to_exact(
        image_data: bytes,
        target_size: tuple[int, int],
    ) -> bytes:
        from PIL import Image

        img = Image.open(BytesIO(image_data))
        target_w, target_h = target_size
        src_w, src_h = img.size
        target_ratio = target_w / target_h
        src_ratio = src_w / src_h

        if src_ratio > target_ratio:
            new_w = int(src_h * target_ratio)
            left = max(0, (src_w - new_w) // 2)
            img = img.crop((left, 0, left + new_w, src_h))
        elif src_ratio < target_ratio:
            new_h = int(src_w / target_ratio)
            top = max(0, (src_h - new_h) // 2)
            img = img.crop((0, top, src_w, top + new_h))

        img = img.resize(target_size, Image.NEAREST)
        buf = BytesIO()
        img.save(buf, format="PNG")
        return buf.getvalue()

    @staticmethod
    def strip_metadata(image_data: bytes) -> bytes:
        try:
            from PIL import Image
        except ImportError:
            return image_data

        img = Image.open(BytesIO(image_data))
        buf = BytesIO()
        img.save(buf, format="PNG")
        return buf.getvalue()
