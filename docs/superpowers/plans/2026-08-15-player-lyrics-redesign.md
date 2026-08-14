# 播放器与歌词页改造 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 按飞牛网页与华为音乐参考图重做手机播放器封面页和歌词页，接入真实收藏、歌曲菜单、封面取色、投播、系统桌面歌词及可验证的后台播放行为。

**Architecture:** 保留单一 `MusicPlaybackController`、`AVPlayer` 和 `AVSession`，把播放器页面拆成 `@ComponentV2` 子组件。纯格式化、歌词预览和错误映射逻辑放进可单测的策略文件；系统能力统一封装在 `AvSessionBridge`；页面级菜单和导航动作由 `AppShell` 注入，避免播放器直接操纵导航栈。

**Tech Stack:** HarmonyOS API 26、ArkTS、ArkUI `@ComponentV2`、AVPlayer、AVSession/AVCast、ArkGraphics2D `effectKit`、ArkData Preferences、HMRouter/HdsNavigation、Hypium。

---

### Task 1: 播放器纯逻辑策略与测试

**Files:**
- Create: `entry/src/main/ets/playback/PlayerUiPolicy.ets`
- Modify: `entry/src/test/PlaybackContract.test.ets`

- [ ] **Step 1: 为格式标签、歌曲信息和系统能力错误写失败测试**

在 `PlaybackContract.test.ets` 增加以下断言：

```typescript
it('formatsPlayerMetadataWithoutInventingValues', 0, () => {
  const track = new MusicTrack('track-1', '测试歌曲', '测试歌手', '测试专辑', 125000);
  track.audioSpec.format = 'flac';
  track.audioSpec.bitDepth = 24;
  track.audioSpec.sampleRate = 96000;
  expect(playerFormatLabel(track)).assertEqual('FLAC');
  expect(playerTrackInfoRows(track).length >= 4).assertTrue();
});

it('mapsDesktopLyricCapabilityErrors', 0, () => {
  expect(desktopLyricErrorMessage(6600111)).assertEqual('当前设备不支持系统歌词');
  expect(desktopLyricErrorMessage(6600110)).assertEqual('系统歌词尚未启用');
});
```

- [ ] **Step 2: 运行测试并确认新导入尚不存在**

Run:

```bash
/usr/bin/env DEVECO_SDK_HOME='/Applications/DevEco-Studio 3.app/Contents/sdk' \
  '/Applications/DevEco-Studio 3.app/Contents/tools/node/bin/node' \
  '/Applications/DevEco-Studio 3.app/Contents/tools/hvigor/bin/hvigorw.js' \
  --mode module -p product=default test
```

Expected: 新增 `PlayerUiPolicy` 导入或符号不存在导致编译失败。

- [ ] **Step 3: 实现纯逻辑策略**

`PlayerUiPolicy.ets` 至少导出：

```typescript
export class PlayerInfoRow {
  label: string = '';
  value: string = '';
  constructor(label: string, value: string) {
    this.label = label;
    this.value = value;
  }
}

export function playerFormatLabel(track: MusicTrack): string;
export function playerTrackInfoRows(track: MusicTrack): PlayerInfoRow[];
export function desktopLyricErrorMessage(code: number): string;
export function nearestLyricIndex(lines: LyricLine[], contentOffset: number, lineHeight: number,
  viewportAnchor: number): number;
```

格式为空时回退 codec；歌曲信息忽略空字段和完整路径；采样率显示为 `96 kHz`，文件大小按 B/KB/MB/GB 格式化；歌词目标索引必须限制在数组范围内。

- [ ] **Step 4: 运行播放器契约测试**

Run: 同 Step 2。

Expected: `PlaybackContract` 全部通过。

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets/playback/PlayerUiPolicy.ets entry/src/test/PlaybackContract.test.ets
git commit -m '补充播放器展示与歌词预览策略'
```

### Task 2: 封面动态配色

**Files:**
- Create: `entry/src/main/ets/playback/PlayerDynamicPalette.ets`
- Modify: `entry/src/main/ets/playback/PlayerComponents.ets`

- [ ] **Step 1: 创建封面配色状态组件**

实现 `@ObservedV2 PlayerPaletteState`，包含 `startColor`、`endColor`、`foregroundIsLight` 和 `coverKey`。实现 `PlayerDynamicPalette.load(track)`：

```typescript
const pixelMap = await CoverArtStore.load(track.coverId, 192, track.updatedAt);
const picker = await effectKit.createColorPicker(pixelMap);
const main = await picker.getMainColor();
const average = picker.getAverageColor();
```

将 RGB 转成 `rgba(r,g,b,1)` 字符串，限制亮度和饱和度，生成上浅下深的两色背景。加载失败返回 `undefined`，页面继续使用 base/dark 资源。

- [ ] **Step 2: 在播放器根背景中消费真实配色**

`ExpandedPlayer` 只接收 `palette` 参数，不直接执行异步取色。`MusicPlayerScreen` 监听当前歌曲 guid/coverId/updatedAt，异步更新真实 `@Local` palette；切歌结果返回时核对 coverKey，避免旧请求覆盖新歌曲。

- [ ] **Step 3: 检查深浅色回退资源**

Run:

```bash
rg -n 'page_player_background_start|page_player_background_end' \
  entry/src/main/resources/base/element/color.json \
  entry/src/main/resources/dark/element/color.json
```

Expected: 两套资源键均存在。

- [ ] **Step 4: 编译确认 ArkTS 类型正确**

Run:

```bash
/usr/bin/env DEVECO_SDK_HOME='/Applications/DevEco-Studio 3.app/Contents/sdk' \
  '/Applications/DevEco-Studio 3.app/Contents/tools/node/bin/node' \
  '/Applications/DevEco-Studio 3.app/Contents/tools/hvigor/bin/hvigorw.js' \
  --mode module -p product=default assembleHap --analyze=normal --parallel --incremental --daemon
```

Expected: `BUILD SUCCESSFUL`。

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets/playback/PlayerDynamicPalette.ets entry/src/main/ets/playback/PlayerComponents.ets
git commit -m '为播放器接入封面动态配色'
```

### Task 3: 重排封面页与网页同构歌曲菜单

**Files:**
- Create: `entry/src/main/ets/playback/PlayerTrackOverlays.ets`
- Modify: `entry/src/main/ets/playback/PlayerComponents.ets`
- Modify: `entry/src/main/ets/shell/AppShell.ets`

- [ ] **Step 1: 拆出五键播放控制**

创建 `@ComponentV2 PlayerControlRow`，参数为 `state` 和循环、上一首、播放、下一首、队列事件。顺序固定为循环、上一首、播放/暂停、下一首、队列；漫游模式下队列按钮替换为现有漫游图标且不可点击。

- [ ] **Step 2: 重排封面页内容**

移除 `currentLyric()` 展示和底部三键操作排。歌曲信息使用：

```typescript
Row({ space: 10 }) {
  Column({ space: 4 }) { /* 标题与 歌手 - 专辑 */ }.layoutWeight(1)
  Button({ type: ButtonType.Circle }) { /* heart */ }
  Button({ type: ButtonType.Circle }) { /* ellipsis */ }
}
```

收藏和菜单按钮固定 44vp 点击区域、透明背景。时间行中间显示 `playerFormatLabel(track)`。

- [ ] **Step 3: 实现按钮附近的菜单和二级选择**

`PlayerTrackOverlays.ets` 提供 `PlayerTrackMenu`、`PlayerArtistPicker`、`PlayerPlaylistPicker` 和 `TrackInfoSheet`。主菜单四项严格为查看专辑、查看歌手、添加到歌单、歌曲信息。更多按钮使用 `bindPopup(showMenu, { builder, placement: Placement.TopRight, mask: false, autoCancel: true, onStateChange })` 绑定 `PlayerTrackMenu`；浮层使用项目系统材质背景。

- [ ] **Step 4: 从 AppShell 注入真实业务动作**

为 `MusicPlayerScreen` 增加事件：

```typescript
@Event onFavorite: (track: MusicTrack, favorite: boolean) => Promise<boolean>;
@Event onOpenAlbum: (track: MusicTrack) => void;
@Event onOpenArtist: (artist: MusicArtist) => void;
@Event onAddPlaylist: (track: MusicTrack, playlist: MusicPlaylist) => Promise<boolean>;
```

`AppShell` 调用 `AppRuntime.setFavorite()`、`AppRuntime.addTrackToPlaylist()` 和现有 `openAlbum/openArtist()`。收藏失败返回 false 并回滚；加入歌单成功更新 `trackCount`。

- [ ] **Step 5: 编译并运行 UI 大尺寸检查**

Run:

```bash
scripts/ui-size-guard.sh
```

Expected: 本次新增超过基线的尺寸均有截图依据或已调整。

Run: Task 2 Step 4 构建命令。

Expected: `BUILD SUCCESSFUL`。

- [ ] **Step 6: 提交**

```bash
git add entry/src/main/ets/playback/PlayerTrackOverlays.ets \
  entry/src/main/ets/playback/PlayerComponents.ets entry/src/main/ets/shell/AppShell.ets
git commit -m '重做播放器信息区与歌曲菜单'
```

### Task 4: 歌词页 5 秒沉浸与滚动 Seek

**Files:**
- Modify: `entry/src/main/ets/playback/PlayerComponents.ets`
- Modify: `entry/src/test/PlaybackContract.test.ets`

- [ ] **Step 1: 补歌词目标索引边界测试**

增加空列表、顶部、底部和超范围滚动偏移测试，确认 `nearestLyricIndex()` 不返回非法索引。

- [ ] **Step 2: 为歌词页建立真实交互状态**

`PlayerLyricPage` 增加：

```typescript
@Local controlsVisible: boolean = true;
@Local previewing: boolean = false;
@Local previewIndex: number = -1;
private immersionTimer: number = -1;
```

进入歌词页、播放操作、Seek 和手动滚动均调用 `restartImmersionTimer()`；5 秒后只隐藏进度和控制排。

- [ ] **Step 3: 实现空白区恢复和“词”按钮职责**

歌词内容左侧增加透明点击区，只在沉浸态恢复控制。右下角“词”按钮始终可见，只触发 `onLyricsSettings()`，不得修改 `controlsVisible`。

- [ ] **Step 4: 实现手动滚动预览**

监听 Scroll 触摸/滚动事件进入 `previewing`，按当前偏移计算 `previewIndex`。候选行右侧显示播放图标和格式化时间；点击调用 `onSeek(line.timeMs)`，然后关闭预览、滚动到真实活动行并重启计时。预览期间活动歌词变化不得自动调用 `scrollToActiveLine()`。

- [ ] **Step 5: 验证测试和构建**

Run: Task 1 Step 2 测试命令，然后运行 Task 2 Step 4 构建命令。

Expected: 测试通过且 `BUILD SUCCESSFUL`。

- [ ] **Step 6: 提交**

```bash
git add entry/src/main/ets/playback/PlayerComponents.ets entry/src/test/PlaybackContract.test.ets
git commit -m '实现歌词沉浸与滚动定位播放'
```

### Task 5: 歌词设置、系统桌面歌词与投播

**Files:**
- Create: `entry/src/main/ets/playback/LyricsSettingsComponents.ets`
- Modify: `entry/src/main/ets/common/MusicPreferenceStore.ets`
- Modify: `entry/src/main/ets/playback/AvSessionBridge.ets`
- Modify: `entry/src/main/ets/playback/MusicPlaybackController.ets`
- Modify: `entry/src/main/ets/playback/PlayerComponents.ets`

- [ ] **Step 1: 扩展歌词设置持久化模型**

增加 `desktopLyricsEnabled`、`lyricsDoubleLine`、`lyricsCentered`、`lyricsHorizontal`、`lyricsVertical`、`lyricsWidth`、`lyricsBackdropOpacity`、`lyricsFontSize` 和 `lyricsColorIndex`。数值写入 Preferences 时限制在 UI Slider 的合法区间。

- [ ] **Step 2: 实现歌词底部弹窗和设置页**

右下角“词”打开“歌词”底部弹窗；“状态栏歌词”进入设置内容。开关使用系统 `Toggle`，单行/双行和居左/居中使用分段控件，数值使用 Slider，颜色使用色块。API 不支持的样式项显示禁用态和“由系统管理”的辅助文案。

- [ ] **Step 3: 接入系统桌面歌词**

`AvSessionBridge` 增加：

```typescript
async desktopLyricSupported(): Promise<boolean>;
async setDesktopLyricEnabled(enabled: boolean): Promise<void>;
async setDesktopLyricVisible(visible: boolean): Promise<void>;
```

启用时先调用 `avSession.isDesktopLyricSupported()`，再调用会话 `enableDesktopLyric(true)` 和 `setDesktopLyricVisible(true)`。错误码通过 `desktopLyricErrorMessage()` 映射并回滚偏好状态。

- [ ] **Step 4: 接入 AVCast**

`AvSessionBridge` 在 `configure()` 保存的 `UIAbilityContext` 上创建 `new avSession.AVCastPickerHelper(context)`，暴露 `openCastPicker()` 并调用 `picker.select({ sessionType: 'audio' })`。注册 `picker.on('pickerStateChange', callback)` 同步选择器状态；设备无 AVCast 能力或 `select()` 抛错时返回可读错误，不影响本机 AVPlayer。销毁桥接器时调用 `picker.off('pickerStateChange', callback)` 并清空引用。

- [ ] **Step 5: 验证 API 26 构建**

Run: Task 2 Step 4 构建命令。

Expected: `BUILD SUCCESSFUL`，没有使用高于 API 26 的接口。

- [ ] **Step 6: 提交**

```bash
git add entry/src/main/ets/playback/LyricsSettingsComponents.ets \
  entry/src/main/ets/common/MusicPreferenceStore.ets entry/src/main/ets/playback/AvSessionBridge.ets \
  entry/src/main/ets/playback/MusicPlaybackController.ets entry/src/main/ets/playback/PlayerComponents.ets
git commit -m '接入系统歌词设置与投播能力'
```

### Task 6: 后台播放生命周期验证与修正

**Files:**
- Modify: `entry/src/main/ets/entryability/EntryAbility.ets`
- Modify: `entry/src/main/ets/playback/MusicPlaybackController.ets`
- Modify: `entry/src/main/ets/playback/AvSessionBridge.ets`
- Modify: `docs/verification.md`

- [ ] **Step 1: 记录前后台状态而不释放播放资源**

`onBackground()` 只保存播放会话并同步 AVSession；`onForeground()` 恢复系统会话状态。确认任何生命周期回调都不会调用 `release()`、`close()` 或 `deactivate()` 正在播放的 session。

- [ ] **Step 2: 根据真实设备结果决定是否增加长时任务**

先使用现有 `backgroundModes: ["audioPlayback"]`、`KEEP_BACKGROUND_RUNNING` 和 `setBackgroundPlayMode(ENABLE_BACKGROUND_PLAY)` 验证。只有真机熄屏后被中止时，才封装 `backgroundTaskManager.startBackgroundRunning()`，在播放开始时申请、暂停或关闭时结束，避免重复通知。

- [ ] **Step 3: 更新验证文档**

在 `docs/verification.md` 分开记录模拟器、真机、锁屏、熄屏、耳机控制、媒体中心和进程回收结果。未执行的真机项明确标记未验证，不用构建结果代替。

- [ ] **Step 4: 提交**

```bash
git add entry/src/main/ets/entryability/EntryAbility.ets \
  entry/src/main/ets/playback/MusicPlaybackController.ets \
  entry/src/main/ets/playback/AvSessionBridge.ets docs/verification.md
git commit -m '完善后台播放生命周期与验收记录'
```

### Task 7: 模拟器端到端验收

**Files:**
- Modify: `docs/verification.md`

- [ ] **Step 1: 完整构建**

Run: Task 2 Step 4 构建命令。

Expected: `BUILD SUCCESSFUL`，HAP 位于 `entry/build/default/outputs/default/`。

- [ ] **Step 2: 仅向 API 26 模拟器安装**

Run:

```bash
'/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc' list targets
```

选择模拟器目标 `127.0.0.1:5555`，不要操作连接的真机。安装已签名 HAP 并启动 `cn.xiaobai.feiniumusic`。

- [ ] **Step 3: 验证交互矩阵**

逐项检查：顶部透明按钮、投播降级、封面取色、歌曲信息区、收藏、四项菜单、格式标签、五键控制、左右切页、歌词 5 秒沉浸、左侧空白恢复、手动滚动时间按钮、Seek、歌词弹窗、系统歌词不支持提示、深浅色和返回行为。

- [ ] **Step 4: 检查 hilog**

Run:

```bash
'/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc' \
  -t 127.0.0.1:5555 shell hilog -x
```

Expected: 无 ArkTS crash、无 `class constructor cannot called without 'new'`、无重复播放器宿主。

- [ ] **Step 5: 更新验证记录并提交**

```bash
git add docs/verification.md
git commit -m '记录播放器与歌词页模拟器验收结果'
```
