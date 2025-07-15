# Expo Image Sequence Encoder

[![npm version](https://badge.fury.io/js/expo-image-sequence-encoder.svg)](https://badge.fury.io/js/expo-image-sequence-encoder) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**On‑device PNG → MP4/MOV encoder for React‑Native & Expo**

*No FFmpeg • No GPL • Just the platform video encoders — `AVAssetWriter` (iOS) & `MediaCodec` (Android)*

## Table of Contents

- [Expo Image Sequence Encoder](#expo-image-sequence-encoder)
  - [Table of Contents](#tableofcontents)
  - [Features](#features)
  - [Installation](#installation)
  - [Usage](#usage)
    - [API](#api)
  - [Troubleshooting](#troubleshooting)
  - [Contributing](#contributing)
  - [License](#license)

## Features

* **Offline** – runs entirely on the device, no upload required
* **Tiny footprint** – adds ≈150 kB native code, zero third-party binaries
* **Expo-friendly** – ships with a config-plugin; just add it to `app.json`
* **Classic & New Architecture** – works if the host app opts into TurboModule/Fabric later

## Installation

> **Supported React‑Native versions:** 0.79 (Expo SDK 53).<br>
> Older versions may compile but are not tested.

```bash
npx expo install expo-image-sequence-encoder
```

Add the plugin entry to **`app.json` / `app.config.js`** so EAS can autolink:

```jsonc
{
  "expo": {
    "plugins": ["expo-image-sequence-encoder"]
  }
}
```

That’s it — run a development build or EAS production build and the native
module is ready.

> **Local testing:** run `npx expo run:ios` or `npx expo run:android` after
> installing the library; Expo Go will **not** include the native code.

## Usage

```ts
import { encode } from 'expo-image-sequence-encoder';
import * as FileSystem from 'expo-file-system';

// after you have /cache/frames/frame-00000.png …
const uri = await encode({
  folder:  FileSystem.cacheDirectory + 'frames/',
  fps:     30,
  width:   1280,
  height:  720,
  output:  FileSystem.documentDirectory + 'chat.mp4',
});

console.log('MP4 saved at', uri);
```

### API

| Option      | Type   | Description                                                     |
| ------------| ------ | --------------------------------------------------------------- |
| `folder`    | string | Directory ending with `/`, containing sequential **PNG** frames |
| `fps`       | number | Frames per second in the output file                            |
| `width`     | number | Output width in pixels                                          |
| `height`    | number | Output height in pixels                                         |
| `output`    | string | Absolute path for the video (overwritten if already exists)     |
| `container` | string | Output container format, either `mp4` or `mov` (default: `mp4`) |

Returns **`Promise<string>`** – absolute file URI of the saved video.

> ⚠️ The module does **no** down‑scaling; make sure `width` & `height` match the
> PNG resolution or resize the frames before calling `encode()`.

## Troubleshooting

| Problem                                          | Fix                                                                                                         |
| ------------------------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| **`Native module not linked`**                   | Rebuild the dev client (`eas build --profile development`) or run `npx expo run-android / run-ios`.         |
| **`INFO_OUTPUT_FORMAT_CHANGED twice` (Android)** | Stick to even dimensions (e.g. 1280×720); some encoders reject odd sizes.                                   |
| **iOS < 12 crash**                               | The podspec targets iOS 12+. Older OS versions are not supported.                                           |

## Contributing

PRs are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

MIT © 2025 Elliot Fleming

See [LICENSE](LICENSE) for details.
