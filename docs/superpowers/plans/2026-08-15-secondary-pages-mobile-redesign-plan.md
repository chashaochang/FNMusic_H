# 飞牛音乐二级页面移动端重设计 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将飞牛音乐 Web 端的专辑、歌手、风格、音乐库、收藏、最近播放、歌单和搜索内容重组为差异化 HarmonyOS 手机二级页面。

**Architecture:** `AppShell` 继续负责路由、接口和播放事件；新增的 `@ComponentV2` 展示组件负责网格、列表、Hero 和页面壳层。集合页与搜索页复用专辑网格、歌手列表、风格卡片，详情页通过实体参数选择对应 Hero，不使用无业务意义的刷新字段。

**Tech Stack:** HarmonyOS API 26、ArkTS、ArkUI `@ComponentV2`、HdsNavigation、现有 `AppRuntime`、`CoverArtStore`、`FnMusicUI` 与深浅色资源。

---

### Task 1: 公共二级页视觉组件

**Files:**
- Create: `entry/src/main/ets/feature/library/LibraryVisualComponents.ets`
- Modify: `entry/src/main/ets/design/FnMusicUI.ets`
- Modify: `entry/src/main/resources/base/element/color.json`
- Modify: `entry/src/main/resources/dark/element/color.json`

- [ ] **Step 1: 增加保守尺寸 Token**

在 `FnMusicUI` 增加 `secondaryPagePadding = 14`、`secondaryHeaderHeight = 56`、`albumGridGap = 12`、`albumGridRadius = 10`、`detailHeroCoverSize = 116`、`denseTrackRowHeight = 58`，保持正文 `15fp`、辅助文字 `13fp`。

- [ ] **Step 2: 增加深浅色语义资源**

增加详情 Hero 遮罩、连续列表分隔、风格卡片表面、轻量格式标签和 ActionBar 渐隐颜色；base/dark 使用同名资源，禁止页面内硬编码颜色。

- [ ] **Step 3: 创建动态展示组件**

在 `LibraryVisualComponents.ets` 创建：

```ts
@ComponentV2 export struct AlbumGridItem { /* MusicAlbum + onOpen + onPlay */ }
@ComponentV2 export struct AlbumGrid { /* MusicAlbum[] */ }
@ComponentV2 export struct ArtistListItem { /* MusicArtist + onOpen */ }
@ComponentV2 export struct GenreGridItem { /* MusicGenre + onOpen */ }
@ComponentV2 export struct DenseTrackRow { /* MusicTrack + index + onPlay + onMore */ }
@ComponentV2 export struct MusicDetailHero { /* kind + entity fields + actions */ }
```

所有接口数据通过 `@Param` 输入，事件通过 `@Event` 输出；禁止 `@Builder` 承载动态列表。

- [ ] **Step 4: 运行静态尺寸检查**

Run: `bash scripts/ui-size-guard.sh`

Expected: 新增的大尺寸仅限专辑封面和 Hero 封面，正文、按钮、行高没有无依据超标。

### Task 2: 专辑、歌手、风格集合页

**Files:**
- Modify: `entry/src/main/ets/feature/library/CollectionScreens.ets`
- Modify: `entry/src/main/ets/feature/common/MusicUiComponents.ets`

- [ ] **Step 1: 将专辑列表替换为双列网格**

使用 `Grid` 和 `GridItem` 渲染 `AlbumGridItem`，保留现有 `AppRuntime.loadMoreAlbums()`、总数、加载、失败重试和空态。封面主体进入详情，右下角播放按钮触发新增 `onPlay` 事件。

- [ ] **Step 2: 将歌手页改为连续头像列表**

移除每行独立重色卡片，使用轻量连续表面和分隔；显示歌手头像、歌曲数和专辑数，保留分页。

- [ ] **Step 3: 将风格页改为双列主题卡片**

使用稳定的卡片变体映射和现有封面；无封面使用项目音乐图标资源，显示歌曲数并进入风格详情。

- [ ] **Step 4: 更新集合页事件签名**

`AlbumCollectionScreen` 新增：

```ts
@Event onPlay: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};
```

并在 `AppShell` 调用现有 `playAlbum()`。

### Task 3: 详情页与歌曲集合页

**Files:**
- Modify: `entry/src/main/ets/feature/library/TrackListScreen.ets`
- Modify: `entry/src/main/ets/shell/AppShell.ets`

- [ ] **Step 1: 扩展详情页实体参数**

`TrackListScreen` 接收 `album?: MusicAlbum`、`artist?: MusicArtist`、`genre?: MusicGenre`、`playlist?: MusicPlaylist`，由 `AppShell` 根据当前页面传入 `activeAlbum`、`activeArtist`、`activeGenre`、`activePlaylist`。

- [ ] **Step 2: 按集合类型选择 Hero**

专辑显示方形封面、歌手、年份和歌曲数；歌手显示圆形头像、歌曲数和专辑数；风格显示唱片视觉；收藏和最近显示对应主题图形；音乐库不显示大 Hero，只显示紧凑工具行。

- [ ] **Step 3: 使用连续歌曲列表**

替换逐行独立卡片为 `DenseTrackRow` 连续列表，保留单曲播放、时长、收藏状态、更多菜单、分页加载和歌单移除能力。

- [ ] **Step 4: 增加歌手“歌曲/专辑”切换**

在歌手详情中用 Chip 切换；专辑数据从当前已加载 `albums` 按 `artistName` 过滤，歌曲继续使用 `artistTracks`。无专辑时显示空态，不发明新接口。

### Task 4: 搜索页差异化结果

**Files:**
- Modify: `entry/src/main/ets/feature/search/SearchScreen.ets`

- [ ] **Step 1: 保留固定顶部搜索壳层**

返回按钮、搜索框和安全区保持透明材质，输入为空显示最近搜索，查询中保留 400ms 防抖。

- [ ] **Step 2: 替换三类结果容器**

歌曲结果使用 `DenseTrackRow`；专辑结果使用双列 `AlbumGrid`；歌手结果使用连续 `ArtistListItem`。Chip 切换不清空查询词。

- [ ] **Step 3: 对齐加载、错误和空态**

三类结果使用统一高度和左右边距，避免状态变化导致顶部搜索栏跳动。

### Task 5: 构建与模拟器验收

**Files:**
- Modify only if verification finds defects in files touched above.

- [ ] **Step 1: 运行 ArkTS 构建**

Run: `DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk /Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode module -p product=default -p module=entry@default -p buildMode=debug assembleHap`

Expected: `BUILD SUCCESSFUL`。

- [ ] **Step 2: 运行 UI 尺寸检查**

Run: `bash scripts/ui-size-guard.sh`

Expected: 无未经说明的大字号、大行高和大图标。

- [ ] **Step 3: 安装到模拟器并逐页截图**

安装 debug HAP 到 `127.0.0.1:5555`，依次验证专辑集合/详情、歌手集合/详情、风格集合/详情、音乐库、收藏、最近和搜索。

- [ ] **Step 4: 检查状态矩阵**

验证深浅色、缺失封面、长标题、空收藏、加载/失败、分页、有/无悬浮播放条、ActionBar 滚动材质和触摸区域。

- [ ] **Step 5: 提交实现**

```bash
git add entry/src/main/ets entry/src/main/resources docs/superpowers/plans/2026-08-15-secondary-pages-mobile-redesign-plan.md
git commit -m "重设计音乐二级页面"
```
