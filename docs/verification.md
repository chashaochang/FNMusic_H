# Verification

Date: 2026-08-16

## Environment

- DevEco Studio: `/Applications/DevEco-Studio 3.app`
- IDE version: `26.0.0.621`
- SDK: API 26 Beta2, `26.0.0.32`
- Node: `24.14.1` from the same DevEco installation
- Hvigor: `6.26.2`
- App bundle: `cn.xiaobai.feiniumusic`

## Dependency sync

Dependency installation completed with the DevEco-bundled Node and ohpm CLI. The shell wrapper was not used because the current machine's default Node selected an incompatible CommonJS/ESM combination.

## Build result

The following stages completed successfully:

- LocalUnit (40 passed, 0 failed, 0 errors)
- CompileResource
- CompileArkTS
- PackageHap
- PackingCheck
- SignHap（仅用于本机验证，发布产物仍为未签名包）

Final build result: `BUILD SUCCESSFUL`.

Artifact:

- `dist/FNMusic_H-1.0.2-unsigned.hap`
- Version: `1.0.2` (`versionCode=1000002`, `buildVersion=3`)
- SDK: target API 26 Beta2, compatible API 24
- Size: 2702977 bytes
- SHA-256: `0915366d562f05a7604a2a923b5b70a0610f7a56b470ff004e9685c77757613b`

The HAP archive passed `unzip -t` without compressed-data errors.

## Background playback

- Audio playback now starts a system `AUDIO_PLAYBACK` continuous task while preparing, buffering or playing.
- Pausing, stopping, clearing the queue, signing out and playback errors stop the continuous task.
- The API 26 emulator kept playback active in the background for about four minutes; AVSession remained `playing`.
- Process logs contained `startBackgroundRunning succeeded`, and pausing produced `stopBackgroundRunning succeeded`.

## FNID login correction

The HarmonyOS client now follows the public FeiNiuMusic login contract used for this project:

- FNID resolves and orders NAS connection candidates; it does not return a music login token.
- Password login is sent to `<baseUrl>/music/api/v1/user/password-login` with the username, SHA-256 password and device ID.
- Relay discovery and password login send `Cookie: mode=relay`; authenticated relay requests send `music-token=<token>; mode=relay`.
- IP results generate both HTTP and HTTPS candidates, while relay hostnames use HTTPS on the default 443 port.
- DNS, connection, timeout, TLS, HTTP, business and parse failures remain distinguishable instead of collapsing into one generic error.

LocalUnit covers the relay login cookie, candidate generation, NetworkKit error mapping, login-error propagation and multi-candidate error priority. This verifies the client contract only, not successful authentication against a real NAS.

## Not yet verified

- Long-duration background playback on a physical phone
- Real Feiniu server login and API behavior
- Media streaming and Range/seek compatibility across different libraries
- HUKS v2-to-v3 credential migration with the current source build; the public
  build is intentionally unsigned and cannot replace the differently signed
  emulator installation

## Tooling notes

- An API 26 phone image (`Pura 90 Pro`) is installed locally, but the headless emulator process cannot start in the current sandboxed desktop session because no macOS display service is available.
- DevEco MCP currently resolves to `/Applications/DevEco-Studio.app`, whose Hvigor only supports modelVersion `6.1.0`; API 26 builds must use `/Applications/DevEco-Studio 3.app` on this machine.
- DevEco CodeLinter `6.0.240` is present, but its standalone runner exits before producing a report in this DevEco Studio 3 environment. Hvigor `CompileArkTS` remains the current static type and API compatibility gate.
