# HarmonyOS Native Red Login Verification

Date: 2026-08-14

## Scope

This verification covers the HarmonyOS native red login surface and the FN Connect login repair that followed the reported "all available addresses failed" error.

## Implementation Evidence

- Login UI: `entry/src/main/ets/feature/auth/LoginScreen.ets`
- Native materials: `entry/src/main/ets/design/FnMusicLoginMaterials.ets`
- Login metrics: `entry/src/main/ets/design/FnMusicLoginMetrics.ets`
- FN Connect routing and signing: `entry/src/main/ets/auth/FnConnectService.ets`
- Automatic reconnect: `entry/src/main/ets/auth/AuthStore.ets`
- Window insets and density lifecycle: `entry/src/main/ets/entryability/EntryAbility.ets`
- Light resources: `entry/src/main/resources/base/element/color.json`
- Dark resources: `entry/src/main/resources/dark/element/color.json`

The login screen uses `@ComponentV2` children for dynamic fields, disclosure, status, actions, and retry state. Base and dark resources both define login canvas, foreground red, material red, neutral material, disabled, and focus tokens.

## Login And Connection Review

- FN Connect/FNID resolves NAS targets; NAS username and password are then submitted to `/music/api/v1/user/password-login`.
- FN Connect requests include both `authx` and the required `fn-sign` SHA-256 header.
- The request continues to use the API 26 `body` field.
- Relay requests preserve `Cookie: mode=relay`.
- Direct server addresses can bypass FN Connect resolution and receive default music service ports when omitted.
- Candidate failures preserve the most useful network, TLS, HTTP, or business error.
- Saved sessions restore automatically, and unauthorized sessions perform one serialized reconnect.

## UI State Review

- Empty or partial input keeps the primary action disabled.
- Ready input enables submission.
- Focus uses a permanently mounted opacity-animated red outline.
- Loading keeps control geometry stable and displays phase-specific progress text.
- Password remains `InputType.Password`; `showPassword()` controls visibility.
- The optional security code has no ineffective visibility action.
- Login content applies the observed top safe inset while the background remains immersive.
- Density resolves in `custom > system > default > display > 1` order and refreshes on `systemDensityChange`.

## LocalUnit

Command:

```bash
env DEVECO_SDK_HOME='/Applications/DevEco-Studio 3.app/Contents/sdk' \
  '/Applications/DevEco-Studio 3.app/Contents/tools/node/bin/node' \
  '/Applications/DevEco-Studio 3.app/Contents/tools/hvigor/bin/hvigorw.js' \
  test -p module=entry -p coverage=false --no-daemon
```

Result: `36` passed, `0` failed, `0` errors.

The added contract checks cover the FN Connect signature vector, route candidate mapping, relay port normalization, direct-address detection, direct-address normalization, HUKS missing-key classification, and local-persistence failure handling.

## UI Size Review

`rg` is unavailable, so an equivalent recursive `grep` scan was used. The scan reports existing deliberate large symbols, artwork, player controls, sheets, and fixed media areas across the app. Login-specific values remain within the established baseline except for the approved 20fp brand title and 18-25fp system symbols.

## API 26 Build

Command:

```bash
env DEVECO_SDK_HOME='/Applications/DevEco-Studio 3.app/Contents/sdk' \
  '/Applications/DevEco-Studio 3.app/Contents/tools/node/bin/node' \
  '/Applications/DevEco-Studio 3.app/Contents/tools/hvigor/bin/hvigorw.js' \
  assembleHap --mode module -p product=default \
  -p module=entry@default -p buildMode=debug --no-daemon
```

Result: `BUILD SUCCESSFUL` for target and compatible SDK `26.0.0` on phone.

Current public-source artifact:

- Path: `entry/build/default/outputs/default/entry-default-unsigned.hap`
- Size: `2,771,976` bytes
- SHA-256: `913953f4d86948af48b961115bfdfc13d8b532e2ff2ab2bf428e3cf1865ab6a0`
- Archive: `unzip -t` reported no compressed-data errors.

## Device Verification

In the earlier signed login-screen verification pass, a physical device connected and the HAP installed successfully. `EntryAbility` started in the foreground and the application process remained alive after launch. Process-filtered logs contained `EntryAbility created`, `Content loaded`, first-frame rendering, active-window, and foreground lifecycle evidence, with no startup crash. A final 1280 x 2832 JPEG screenshot was captured locally at `.tmp/feiniu-login-final.jpeg`.

That screenshot confirms the HarmonyOS-native light material layout, immersive system bars and safe-area spacing, red brand treatment, stable input geometry, password visibility control, security-code disclosure, disabled action state, and local-security notice. It does not verify the current HUKS v3 migration because the repository no longer contains signing credentials; the current unsigned HAP cannot replace the differently signed emulator installation.
