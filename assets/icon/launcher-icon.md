# Launcher icon

`launcher_icon.png` is the current text-free launcher master, edited from
`logo_full.png` using the built-in image-generation tool. Existing in-app and
splash artwork is separate from this launcher asset.

The generation prompt was:

> Use case: precise-object-edit. Edit target: supplied green Status Downloader app icon. Create a polished production launcher icon retaining the recognizable white download arrow inside a white and lime segmented chat/status ring with the small play badge. REMOVE ALL TEXT completely, including Status and Downloader. Recenter the entire symbol vertically and horizontally so it is balanced. Refine the excessively busy shiny background to a restrained deep emerald gradient with subtle green glow. Preserve recognizable symbol shapes and colors. Square 1024x1024 image, opaque edge-to-edge background with NO rounded-corner mask, NO external shadow, NO borders, NO text, NO letters, NO watermarks. The COMPLETE foreground symbol including the play badge and chat tail MUST fit within the central circle of diameter 580 pixels, centered at (512,512), leaving generous clean emerald background around every edge. This generous padding is essential for Android circular adaptive icon cropping. Output a single finished icon, not a mockup or grid.

The returned master is 1254×1254 pixels. Native icon sizes are exported using
macOS `sips -z <size> <size> assets/icon/launcher_icon.png --out <destination>`.
The adaptive icon uses a 432×432 export in `drawable-nodpi/ic_launcher_logo.png`,
with the actual safe area enforced by `drawable/ic_launcher_safe_foreground.xml`.

| Android density | Launcher / round size | Foreground size |
| --- | ---: | ---: |
| mdpi | 48 | 108 |
| hdpi | 72 | 162 |
| xhdpi | 96 | 216 |
| xxhdpi | 144 | 324 |
| xxxhdpi | 192 | 432 |

iOS exports follow the sizes and scales in the existing AppIcon `Contents.json`.
The operating system applies the launcher mask; the master has no baked-in text
or transparent corners.
