# Feiniu Music Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven development or inline execution to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the approved API 26 phone client so its authenticated browsing and playback paths behave as one coherent music application and produce a freshly verified unsigned HAP.

**Architecture:** Keep the existing root `AppRuntime`, `AuthStore`, and single `MusicPlaybackController`. Add only bounded state needed for roam continuation and progressive catalog loading; preserve the approved page hierarchy and ArkUI components.

**Tech Stack:** HarmonyOS API 26, ArkTS, ArkUI ComponentV2, NetworkKit, MediaKit AVPlayer, AVSessionKit, HUKS, Hypium LocalUnit, Hvigor.

---

### Task 1: Harden playback switching

**Files:**
- Modify: `entry/src/main/ets/playback/MusicPlaybackController.ets`

- [ ] Guard every asynchronous stage of `playAt()` with its playback generation.
- [ ] Start the AVPlayer before awaiting lyrics; load lyrics in parallel and discard stale results.
- [ ] Catch `createAVPlayer()` failures and expose `PlaybackStatus.ERROR` so retry remains available.
- [ ] Preserve the current queue, repeat modes, AVSession callbacks, and demo behavior.

### Task 2: Make roam continuous

**Files:**
- Modify: `entry/src/main/ets/common/AppRuntime.ets`
- Modify: `entry/src/main/ets/playback/MusicPlaybackController.ets`
- Modify: `entry/src/main/ets/shell/AppShell.ets`

- [ ] Preserve the ordered roam items and the `roamId` needed by `roam-next`.
- [ ] Configure a queue-end callback only for queues started from the roam card or roam page.
- [ ] Fetch and append the next unseen roam item before advancing at queue end.
- [ ] Bound failed continuation to one request per queue-end action and leave the completed state retryable.

### Task 3: Isolate accounts and make catalog loading resilient

**Files:**
- Modify: `entry/src/main/ets/auth/AuthStore.ets`
- Modify: `entry/src/main/ets/common/AppRuntime.ets`
- Modify: `entry/src/test/AuthStateMachine.test.ets`

- [ ] Ignore saved candidate URLs when a manual sign-in uses a different FN Connect ID.
- [ ] Load the primary track list first, publish it immediately for the active auth generation, and load secondary catalog sections independently.
- [ ] Keep an explicit first-load error only when the primary track request fails; secondary failures must not blank the home screen.
- [ ] Synchronize favorite state across the root library and current playback queue by GUID.

### Task 4: Verification and delivery

**Files:**
- Modify: `README.md`
- Modify: `docs/verification.md`

- [ ] Run all LocalUnit tests and record the unique passing count.
- [ ] Run `scripts/ui-size-guard.sh` and inspect each reported large value.
- [ ] Build the API 26 debug HAP using DevEco Studio 3.
- [ ] Run `hdc list targets`; install and launch only when a target is present.
- [ ] Validate the HAP archive, record exact size and SHA-256, and state signing/device/server gaps without overstating acceptance.
