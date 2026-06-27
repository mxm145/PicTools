# PicTools Design

## Goal

Build a simple macOS app for local image compression and cropping.

The app should let users import images or a folder, adjust compression settings,
optionally crop individual images, and export processed copies to a user-selected
folder. Original files are preserved by default.

## Confirmed Requirements

- Import local images or a folder through one combined picker entry.
- Support common image formats through macOS system image capabilities, including
  JPG, PNG, HEIC, WebP, and any other formats the system can decode and encode.
- Show imported images in a list.
- Each image row has an Edit button.
- There is no standalone crop button in the main window.
- Compression supports a user-controlled quality/compression setting.
- Output format is selectable:
  - Keep original format
  - JPG
  - PNG
  - HEIC
  - WebP when available through the system
- Export defaults to preserving originals and writing new files to a
  user-selected folder.
- Cropping supports both mouse-drawn selection and numeric output dimensions.
- Numeric cropping can crop from directions such as center, top-left, top-right,
  bottom-left, and bottom-right.

## User Experience

The app uses one main window with three areas:

- Left: image list and one button labeled "Choose Images or Folder".
- Center: selected image preview, original size, estimated output size, and
  processing status.
- Right: compression settings, output format, and output folder controls.

The main action is "Compress and Export".

Clicking Edit on an image opens a single-image editing panel. This panel shows a
larger preview with a draggable crop rectangle and controls for width, height,
and crop anchor. Applying the edit stores pending crop settings for that image
only. It does not overwrite the source file.

## Processing Flow

1. User chooses images or a folder.
2. The app filters the selection to supported image files.
3. The user selects compression options and output folder.
4. The user may edit individual images to add crop settings.
5. Export processes each image:
   - Load the source image.
   - Apply crop settings if present.
   - Encode using the selected output format and compression setting.
   - Write the result to the chosen output folder.
6. Source files are never modified.

## Implementation Approach

Use a native SwiftUI macOS app with ImageIO/CoreGraphics and related system
frameworks for image reading, cropping, and encoding.

This keeps the first version dependency-free and aligned with macOS desktop UI
patterns. Third-party image libraries are out of scope for the first version
unless native APIs cannot satisfy a required format.

## Components

- App entry point: defines the SwiftUI WindowGroup.
- Image model: tracks source URL, format, dimensions, file size, crop settings,
  output status, and output URL.
- Image store: owns imported images, selection, settings, and export workflow.
- Image loading service: reads metadata and preview images.
- Image export service: applies crop and compression, then writes output files.
- Main view: lays out the three-panel workflow.
- Image list view: renders imported images and row-level Edit buttons.
- Detail preview view: shows selected image preview and status.
- Compression settings view: manages quality, format, and output folder.
- Crop editor view: handles drag selection and numeric crop settings.

## Error Handling

Keep errors user-facing and simple:

- Unsupported files are skipped and summarized.
- Failed exports are marked on the affected image row.
- The app asks for an output folder before export if none is selected.
- Filename collisions are handled by adding a numeric suffix.

## Testing And Verification

Manual verification for the first version:

- Import multiple individual images.
- Import a folder containing mixed supported and unsupported files.
- Export while keeping original formats.
- Export to JPG, PNG, HEIC, and WebP when available.
- Verify originals are unchanged.
- Apply mouse-drawn crop to one image and export it.
- Apply numeric anchored crop to one image and export it.
- Verify failed files show an error without stopping the whole batch.

Automated tests should cover the non-UI processing logic where practical:

- Output filename generation.
- Crop rectangle calculation for each anchor.
- Format selection behavior.
- Export service behavior for representative sample images.
