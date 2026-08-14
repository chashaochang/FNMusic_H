# FeiniuMusic

An independent, unofficial HarmonyOS API 26 client for Feiniu Music.

This project is not affiliated with or endorsed by Feiniu. It uses public
service interfaces and public open-source references; it does not include
reverse-engineered application packages or proprietary Feiniu assets.

## Features

- FN ID/FN Connect and direct-domain login with HUKS-encrypted credential restore
- Home, profile, search, albums, artists, genres and paged music library
- Recently added albums and tracks, favorites, history and roaming playback
- Native AVPlayer/AVSession playback, queue management and lyric display
- Mini-player/full-player geometry transition and adaptive bottom navigation
- HarmonyOS light/dark resources, safe-area handling and immersive materials
- Phone-only Stage model application written in ArkTS

Real library content is loaded only after a successful FN Connect or direct NAS
login. Server availability, permissions and music-service versions can affect
the features exposed by the client.

## Build

Use the API 26 toolchain bundled with DevEco Studio 3:

```bash
env DEVECO_SDK_HOME='/Applications/DevEco-Studio 3.app/Contents/sdk' \
  '/Applications/DevEco-Studio 3.app/Contents/tools/node/bin/node' \
  '/Applications/DevEco-Studio 3.app/Contents/tools/hvigor/bin/hvigorw.js' \
  assembleHap --mode module -p module=entry@default \
  -p product=default -p buildMode=debug --no-daemon
```

The repository intentionally contains no signing credentials. A command-line
build therefore generates an unsigned HAP under:

`entry/build/default/outputs/default/`

Configure a local debug signing profile in DevEco Studio before installing the
HAP on an emulator or physical phone. Never commit the generated certificate,
profile, keystore or passwords.

## Verification boundary

- Hvigor build proves API 26 ArkTS compilation and HAP packaging only.
- Installation requires an online API 26 emulator or physical phone compatible with the local signing profile.
- Background playback, AVSession media keys and audio format coverage require a physical device.
- Login, FN Connect, paging, stream Range/seek, favorites and playlist writes require a real Feiniu Music server.

## License

Project code is distributed under `AGPL-3.0-only`. Third-party components keep
their original licenses; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
