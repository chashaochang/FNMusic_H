# Login HarmonyOS Native Red Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the existing FN Connect login screen as an API 26 HarmonyOS native material experience using Feiniu Music red without changing authentication behavior.

**Architecture:** Add one focused theme/material resolver next to the existing UI tokens, then split the login surface into `@ComponentV2` children that consume observed runtime state and emit typed events. Keep credentials local to the page and preserve the existing `LoginCredentials`, `onLogin`, and `onRetry` contracts.

**Tech Stack:** HarmonyOS API 26, ArkTS, ArkUI ComponentV2, `@kit.ArkUI` `uiMaterial.ImmersiveMaterial`, system semantic resources, Hypium LocalUnit, Hvigor.

---

### Task 1: Define Login Theme Tokens

**Files:**
- Create: `entry/src/main/ets/design/FnMusicLoginMaterials.ets`
- Create: `entry/src/main/ets/design/FnMusicLoginMetrics.ets`
- Modify: `entry/src/main/resources/base/element/color.json`
- Modify: `entry/src/main/resources/dark/element/color.json`

- [ ] **Step 1: Add light and dark semantic resources**

Define `login_canvas`, `brand_red`, `brand_red_soft`, `brand_on_red`, `login_material_tint`, `login_disabled_fill`, `login_disabled_text`, and `focus_outline` in both resource sets. Keep `danger`/`danger_soft` unchanged so brand and error semantics remain independent.

- [ ] **Step 2: Add the API 26 material resolver**

Create cached adaptive-field, primary-action, and secondary-action `uiMaterial.Material` instances. The primary material uses `$r('app.color.brand_red')`, enables shadow and interaction, and supplies a white `lightEffect`; neutral surfaces use `$r('app.color.login_material_tint')`.

- [ ] **Step 3: Add geometry and motion tokens**

Expose login-specific constants for 20vp page padding, 48vp brand mark, 52vp fields, 14vp field radius, 48vp action height, 24vp action radius, and 160/180ms transitions. Do not alter authenticated page dimensions.

- [ ] **Step 4: Run a resource/source syntax build checkpoint**

Run the API 26 HAP build command documented by the local project and expect resource compilation to pass before editing the page.

### Task 2: Rebuild The Login Component Tree

**Files:**
- Modify: `entry/src/main/ets/feature/auth/LoginScreen.ets`

- [ ] **Step 1: Preserve the page contract**

Keep `runtime`, `onLogin`, `onRetry`, `LoginCredentials`, and busy phase handling. Add a `ready()` guard that requires trimmed FNID/username and a non-empty password.

- [ ] **Step 2: Implement focused field components**

Create `@ComponentV2` `NativeLoginField` with typed `@Param` values and `@Event` callbacks. Render the `TextInput` over the adaptive system material, maintain a 52vp frame, animate a brand focus outline, expose the password visibility action, and disable editing while busy.

- [ ] **Step 3: Implement dynamic status/action components**

Create `@ComponentV2` `LoginStatusMessage`, `LoginPrimaryAction`, and `LoginRetryAction`. Keep a fixed primary action frame while swapping label/loading content; use semantic danger resources for errors and native material for retry.

- [ ] **Step 4: Implement the security-code disclosure**

Create `@ComponentV2` `SecurityCodeSection`, retain the optional password input, and animate insertion/removal with opacity and a small translate transition. Disable disclosure and field interaction while authentication is busy.

- [ ] **Step 5: Compose the phone layout**

Remove the opaque outer form card. Build a safe-area-aware scroll surface with a constrained centered column, native brand header, unframed fields, disclosure, status, actions, and privacy copy. Use system semantic text/icon colors and no hardcoded page colors.

### Task 3: Verify State And Size Behavior

**Files:**
- Test: `entry/src/test/ApiContract.test.ets`
- Test: `entry/src/test/AuthStateMachine.test.ets`
- Modify: `docs/verification.md`

- [ ] **Step 1: Run LocalUnit**

Run the existing full LocalUnit suite and expect the previous 29 tests plus any newly discovered project tests to pass with zero failures.

- [ ] **Step 2: Review the state matrix in source**

Inspect empty, partial, focused, ready, loading, error, retry, collapsed/expanded, and light/dark resource paths. Confirm dynamic sections are `@ComponentV2` rather than `@Builder`.

- [ ] **Step 3: Run the UI size guard**

Run `scripts/ui-size-guard.sh`. Review every reported `fontSize(16+)`, `height(60+)`, and large icon occurrence; confirm the login page introduces only the documented 20fp title and no field/action above the approved dimensions.

- [ ] **Step 4: Record verification evidence**

Append the exact test totals, UI guard conclusion, build command, HAP path, archive check, byte size, SHA-256, and device state to `docs/verification.md`.

### Task 4: Build And Device Check

**Files:**
- Modify: `docs/verification.md`

- [ ] **Step 1: Build with DevEco Studio 3 API 26 tooling**

Run the project Hvigor wrapper with the configured DevEco Studio 3 Node runtime and assemble the signed debug HAP. Expect target and compatible SDK 26.0.0.

- [ ] **Step 2: Validate the artifact**

Run `unzip -t` on the produced HAP, obtain its exact byte size, and calculate SHA-256.

- [ ] **Step 3: Check HDC and perform device acceptance when possible**

Run `hdc list targets`. If a device is online, install, launch, inspect light/dark/login states and capture screenshots. If the device is offline, record that build/static evidence does not complete native material visual acceptance.

- [ ] **Step 4: Review implementation against the specification**

Confirm the authentication protocol was untouched, brand red is restrained, errors remain semantic danger red, keyboard scrolling remains reachable, and no unverified device claim is made.
