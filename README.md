# ReaLearn Companion

This is an addition to the [REAPER](https://www.reaper.fm/) plug-in
[ReaLearn](https://www.helgoboss.org/projects/realearn/) and allows you to project a schematic
representation of your currently active ReaLearn controller to your mobile device.

## Usage

1. Install [ReaLearn](https://www.helgoboss.org/projects/realearn/) in REAPER.
2. Press its "Projection" button and follow the instructions.

## Development

Right now requires Flutter dev channel version 1.24.0-3.0.pre (as of this writing, higher versions
have [this bug](https://github.com/flutter/flutter/issues/69254)).

### Generate code

Generated code is committed, so this needs to be executed only after changing files that influence
generated code.

```sh
flutter pub run build_runner build --delete-conflicting-outputs
```

### Generate icons

Reexport the icon as PNG after changing the SVG:
1. In [Inkscape](http://www.inkscape.org/), load `resources/icon.svg`
1. Make sure helper layers are hidden
1. File → Export PNG Image...
    - Export area: Drawing
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
            - Resize: 57 % (maybe choose something like 50% next time because we changed
              export area to "Drawing" which results in a slightly larger image)
    - Background Layer
        - Source Asset
            - Color: #252525
    - Press Next and Finish

Export icons for web app:
1. In Inkscape, load `resources/icon.svg`
1. Make sure the "Rounded background" layer is visible and other helper layers are hidden
1. File → Export PNG Image...
    - Export area: Drawing
    - Width/height: 32 pixels for `favicon.png`, 192/512 pixels for `Icon-*.png`
    - Filename: `web/favicon.png`, `web/icons/Icon-192.png` and `web/icons/Icon-512.png`

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

### Release

1. Adjust version *and* build number in `pubspec.yaml`.
2. `flutter build appbundle`.
3. Upload at Google Play Store.