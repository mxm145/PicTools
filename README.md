# PicTools

PicTools is a simple macOS app for local image compression and cropping.

## Features

- Import individual images or a folder.
- Batch compress and export processed copies.
- Preserve original files by default.
- Choose output format: keep original, JPG, PNG, HEIC, or WebP when supported by macOS.
- Edit each image individually with mouse crop or numeric crop size.

## Build And Run

```bash
./script/build_and_run.sh
```

## Package DMG

```bash
./script/package_dmg.sh
```

The DMG is written to `dist/PicTools-v0.1.0.dmg`.

## Distribution Note

The current release is not notarized. macOS may show a Gatekeeper warning when
opening the downloaded app.
