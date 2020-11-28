# realearn_companion

ReaLearn Companion

## Development

Right now requires Flutter dev channel version 1.24.0-3.0.pre (as of this writing, higher versions
have [this bug](https://github.com/flutter/flutter/issues/69254)).

### Generate code

Generated code is committed, so this needs to be executed only after changing files that influence
generated code.

```sh
flutter pub run build_runner build
```

### Generate icons

Reexport the icon as PNG after changing the SVG:
1. In [Inkscape](http://www.inkscape.org/), load `resources/icon.svg`
1. Make sure helper layers are hidden
1. File → Export PNG Image...
    - Export area: Page
    - Width/height: 512 pixels at 96 dpi
    - Filename: `resources/icon.png`
    - Advanced
        - Bit depth: RGBA_8 (should be the default, corresponds to sRGB as required by Google Play)
    - Press Export

Generate icon assets:
1. In Android Studio, right-click `android/app/src/main/res` → New → Image Asset
    - Foreground Layer
        - Source Asset
            - Asset Type: Image
            - Path: `resources/icon.png`
        - Scaling
            - Trim: No
            - Resize: 57 %
    - Background Layer
        - Source Asset
            - Color: #252525
    - Press Next and Finish

Copy icons over to web app:
1. Copy `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` to `web/icons/ic_launcher.png`
2. Copy `android/app/src/main/res/drawable-xxxhdpi/splash.png` to `web/icons/splash.png`
3. Copy `resources/icon.png` to `web/favicon.png` and resize it to 16x16

Interesting colors are:
- Background: #252525
- Active LEDs: #ffffff
- Inactive LEDs: #808080
- Magic wand: #ffcc00 (theme/primary color)
- Text: #e6e6e6

### Generate splash screen

After adjusting `resources/icon.png`, run this:

```sh
flutter pub run flutter_native_splash:create
```