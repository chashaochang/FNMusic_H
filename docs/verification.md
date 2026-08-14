# Verification

Date: 2026-08-14

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

- LocalUnit (36 passed, 0 failed)
- CompileResource
- CompileArkTS
- PackageHap
- PackingCheck

Final build result: `BUILD SUCCESSFUL`.

Artifact:

- `entry/build/default/outputs/default/entry-default-unsigned.hap`
- Size: 2771976 bytes
- SHA-256: `913953f4d86948af48b961115bfdfc13d8b532e2ff2ab2bf428e3cf1865ab6a0`

The HAP archive passed `unzip -t` without compressed-data errors.

## FNID login correction

The HarmonyOS client now follows the public FeiNiuMusic login contract used for this project:

- FNID resolves and orders NAS connection candidates; it does not return a music login token.
- Password login is sent to `<baseUrl>/music/api/v1/user/password-login` with the username, SHA-256 password and device ID.
- Relay discovery and password login send `Cookie: mode=relay`; authenticated relay requests send `music-token=<token>; mode=relay`.
- IP results generate both HTTP and HTTPS candidates, while relay hostnames use HTTPS on the default 443 port.
- DNS, connection, timeout, TLS, HTTP, business and parse failures remain distinguishable instead of collapsing into one generic error.

LocalUnit covers the relay login cookie, candidate generation, NetworkKit error mapping, login-error propagation and multi-candidate error priority. This verifies the client contract only, not successful authentication against a real NAS.

## Not yet verified

- Installation and launch on an API 26 emulator or physical phone
- Real Feiniu server login and API behavior
- Media streaming, Range/seek, AVSession and background playback
- HUKS v2-to-v3 credential migration with the current source build; the public
  build is intentionally unsigned and cannot replace the differently signed
  emulator installation

## Tooling notes

- An API 26 phone image (`Pura 90 Pro`) is installed locally, but the headless emulator process cannot start in the current sandboxed desktop session because no macOS display service is available.
- DevEco MCP currently resolves to `/Applications/DevEco-Studio.app`, whose Hvigor only supports modelVersion `6.1.0`; API 26 builds must use `/Applications/DevEco-Studio 3.app` on this machine.
- DevEco CodeLinter `6.0.240` is present, but its standalone runner exits before producing a report in this DevEco Studio 3 environment. Hvigor `CompileArkTS` remains the current static type and API compatibility gate.
