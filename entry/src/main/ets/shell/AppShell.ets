import { appSession } from '../common/AppSession';
import { AppRuntime, AppRuntimeState } from '../common/AppRuntime';
import { FnToast } from '../common/FnToast';
import { MusicPreferenceState, MusicPreferenceStore, connectMusicPreferenceState } from '../common/MusicPreferenceStore';
import { FnMusicUI } from '../design/FnMusicUI';
import { FnMusicMaterialRole, FnMusicMaterials } from '../design/FnMusicMaterials';
import { LengthMetrics } from '@kit.ArkUI';
import { EmptyMusicState, MusicEmptyKind } from '../feature/common/MusicUiComponents';
import { HomeScreen } from '../feature/home/HomeScreen';
import { ProfileScreen } from '../feature/profile/ProfileScreen';
import { SearchRequest, SearchScreen } from '../feature/search/SearchScreen';
import { SettingsSheet } from '../feature/settings/SettingsSheet';
import {
  AlbumCollectionScreen,
  ArtistCollectionScreen,
  GenreCollectionScreen
} from '../feature/library/CollectionScreens';
import { TrackActionsSheet } from '../feature/library/TrackActionsSheet';
import { TrackListScreen, TrackSortMode } from '../feature/library/TrackListScreen';
import {
  PlaylistActionsSheet,
  PlaylistSortKey,
  PlaylistSortOrder,
  PlaylistSortSheet
} from '../feature/playlist/PlaylistDetailSheets';
import {
  PlaylistEditMode,
  PlaylistEditRequest,
  PlaylistEditSheet,
  PlaylistSaveStage
} from '../feature/playlist/PlaylistEditSheet';
import { PlaylistScreen } from '../feature/playlist/PlaylistScreen';
import {
  CollectionKind,
  MusicAlbum,
  MusicArtist,
  MusicGenre,
  MusicPlaylist,
  MusicTrack,
  MusicUser,
  PageResult
} from '../model/MusicModels';
import { MusicPlaybackController } from '../playback/MusicPlaybackController';
import { PlayerPresentationState, connectPlayerPresentationState } from '../playback/PlayerPresentationStore';
import {
  FLOATING_PLAYER_TRANSITION_ID,
  HOME_PLAYER_TRANSITION_ID,
  MiniPlayerBar,
  MusicPlayerScreen,
  PlaybackQueueSheet,
  PlayerHostPlacement
} from '../playback/PlayerComponents';
import { TrackInfoSheet } from '../playback/PlayerTrackOverlays';
import {
  ezCustomTransition,
  LongTakeSession,
  LongTakeTransitionDelegate,
  LongTakeTransitionParam,
  LongTakeTransitionType
} from '@hmanimations/ezcustomtransition';
import {
  DividerMode,
  HdsNavDestination,
  HdsNavDestinationAttribute,
  HdsNavDestinationTitleMode,
  HdsNavigation,
  HdsNavigationAttribute,
  HdsNavigationTitleBarOptions,
  HdsNavigationTitleMode,
  HdsTabs,
  HdsTabsController,
  ScrollEffectType,
  TitleSize,
  hdsMaterial
} from '@kit.UIDesignKit';

export enum AppShellPage {
  ROOT = 'root',
  SEARCH = 'search',
  TRACKS = 'tracks',
  ALBUMS = 'albums',
  ARTISTS = 'artists',
  GENRES = 'genres',
  ALBUM_DETAIL = 'album_detail',
  ARTIST_DETAIL = 'artist_detail',
  GENRE_DETAIL = 'genre_detail',
  PLAYLIST_DETAIL = 'playlist_detail',
  PLAYER = 'player'
}

enum RootTab {
  HOME = 'home',
  PLAYLIST = 'playlist',
  PROFILE = 'profile'
}

class PlayerRouteParams {
  longTakeTransitionParam?: LongTakeTransitionParam = undefined;
}

@Component
struct PlayerNavDestination {
  pathStack: NavPathStack = new NavPathStack();
  safeTop: number = 0;
  safeBottom: number = 0;
  albums: MusicAlbum[] = [];
  artists: MusicArtist[] = [];
  playlists: MusicPlaylist[] = [];
  onBack: () => void = (): void => {};
  onFavorite: (track: MusicTrack, favorite: boolean) => void =
    (_: MusicTrack, __: boolean): void => {};
  onOpenAlbum: (track: MusicTrack) => void = (_: MusicTrack): void => {};
  onOpenArtist: (artist: MusicArtist) => void = (_: MusicArtist): void => {};
  onAddPlaylist: (track: MusicTrack, playlist: MusicPlaylist) => void =
    (_: MusicTrack, __: MusicPlaylist): void => {};
  onHidden: () => void = (): void => {};
  onBackPressed: () => boolean = (): boolean => false;
  onTransitionUnavailable: () => void = (): void => {};
  @State private longTakeSession: LongTakeSession = new LongTakeSession();
  @State private longTakeParam: LongTakeTransitionParam | undefined = undefined;

  @Builder
  private playerContent() {
    MusicPlayerScreen({
      safeTop: this.safeTop,
      safeBottom: this.safeBottom,
      albums: this.albums,
      artists: this.artists,
      playlists: this.playlists,
      onBack: (): void => this.onBack(),
      onFavorite: (track: MusicTrack, favorite: boolean): void => this.onFavorite(track, favorite),
      onOpenAlbum: (track: MusicTrack): void => this.onOpenAlbum(track),
      onOpenArtist: (artist: MusicArtist): void => this.onOpenArtist(artist),
      onAddPlaylist: (track: MusicTrack, playlist: MusicPlaylist): void => this.onAddPlaylist(track, playlist)
    })
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  build() {
    HdsNavDestination() {
      if (this.longTakeParam !== undefined) {
        LongTakeTransitionDelegate({
          longTakeSession: this.longTakeSession,
          contentBuilder: (): void => {
            this.playerContent()
          }
        })
      } else {
        this.playerContent()
      }
    }
    .backgroundColor(this.longTakeParam !== undefined ?
      this.longTakeSession.navDestinationBgColor : Color.Transparent)
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .hideTitleBar(true)
    .hideToolBar(true)
    .onSizeChange((_: SizeOptions, size: SizeOptions): void => {
      this.longTakeSession.setNewSize(size);
    })
    .onReady((context: NavDestinationContext): void => {
      const params = context.pathInfo?.param as PlayerRouteParams;
      this.longTakeParam = params?.longTakeTransitionParam;
      if (this.longTakeParam === undefined) {
        this.onTransitionUnavailable();
        return;
      }
      this.longTakeSession.init(context, this.longTakeParam, {
        pop: (): void => {
          this.pathStack.pop();
        },
        contentSizeUsePercent: true
      });
    })
    .onHidden((): void => this.onHidden())
    .onBackPressed((): boolean => this.onBackPressed())
  }
}

@ComponentV2
struct HomeBottomChrome {
  @Param selectedTab: RootTab = RootTab.HOME;
  @Param progress: number = 0;
  @Param safeBottom: number = 0;
  @Param showPlayer: boolean = true;
  @Local playerState: PlayerPresentationState = connectPlayerPresentationState();
  @Local availableWidth: number = 360;
  @Event onSelectTab: (tab: RootTab) => void = (_: RootTab): void => {};
  @Event onRestore: () => void = (): void => {};
  @Event onExpand: () => void = (): void => {};
  @Event onQueue: () => void = (): void => {};
  private playback: MusicPlaybackController = MusicPlaybackController.instance();

  private normalizedProgress(): number {
    if (!this.hasPlayer()) {
      return 0;
    }
    return Math.max(0, Math.min(1, this.progress));
  }

  private interpolate(start: number, end: number): number {
    return start + (end - start) * this.normalizedProgress();
  }

  private navigationProgress(): number {
    return Math.max(0, Math.min(1, (this.normalizedProgress() - 0.12) / 0.88));
  }

  private expandedNavigationOpacity(): number {
    return Math.max(0, 1 - this.normalizedProgress() / 0.35);
  }

  private compactNavigationOpacity(): number {
    return Math.min(1, this.normalizedProgress() / 0.35);
  }

  private hasPlayer(): boolean {
    return this.showPlayer && this.playerState.currentTrack() !== undefined;
  }

  private chromeHeight(): number {
    return Math.max(0, this.safeBottom) + FnMusicUI.bottomBarHeight +
      (this.hasPlayer() ? FnMusicUI.homeMiniPlayerHeight + FnMusicUI.compactPlayerGap : 0);
  }

  private navigationTop(): number {
    return this.hasPlayer() ? FnMusicUI.homeMiniPlayerHeight + FnMusicUI.compactPlayerGap : 0;
  }

  private playerHeight(): number {
    return this.interpolate(FnMusicUI.homeMiniPlayerHeight, FnMusicUI.compactPlayerHeight);
  }

  private expandedChromeWidth(): number {
    return Math.max(220, this.availableWidth - FnMusicUI.bottomBarSideMargin * 2);
  }

  private navigationWidth(): number {
    const expandedWidth: number = this.expandedChromeWidth();
    return this.hasPlayer() ? expandedWidth +
      (FnMusicUI.bottomBarHeight - expandedWidth) * this.navigationProgress() : expandedWidth;
  }

  private navigationX(): number {
    const centered = Math.max(FnMusicUI.bottomBarSideMargin,
      (this.availableWidth - this.expandedChromeWidth()) / 2);
    return this.hasPlayer() ? centered +
      (FnMusicUI.bottomBarSideMargin - centered) * this.navigationProgress() : centered;
  }

  private playerX(): number {
    return this.interpolate(FnMusicUI.bottomBarSideMargin,
      FnMusicUI.bottomBarSideMargin + FnMusicUI.bottomBarHeight + FnMusicUI.compactPlayerGap);
  }

  private playerWidth(): number {
    const expanded = this.expandedChromeWidth();
    const compact = Math.max(180, this.availableWidth - this.playerX() - FnMusicUI.bottomBarSideMargin);
    return this.interpolate(expanded, compact);
  }

  private tabColor(tab: RootTab): ResourceColor {
    return this.selectedTab === tab ? $r('app.color.accent') : $r('app.color.text_primary');
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Stack({ alignContent: Alignment.Center }) {
        Row() {
          Column({ space: 4 }) {
            SymbolGlyph(this.selectedTab === RootTab.HOME ? $r('sys.symbol.house_fill') : $r('sys.symbol.house'))
              .fontSize(22)
              .fontColor([this.tabColor(RootTab.HOME)])
            Text('首页')
              .fontSize(12)
              .fontColor(this.tabColor(RootTab.HOME))
          }
          .layoutWeight(1)
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .onClick((): void => this.onSelectTab(RootTab.HOME))

          Column({ space: 4 }) {
            SymbolGlyph($r('sys.symbol.music_note_list'))
              .fontSize(22)
              .fontColor([this.tabColor(RootTab.PLAYLIST)])
            Text('歌单')
              .fontSize(12)
              .fontColor(this.tabColor(RootTab.PLAYLIST))
          }
          .layoutWeight(1)
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .onClick((): void => this.onSelectTab(RootTab.PLAYLIST))

          Column({ space: 4 }) {
            SymbolGlyph($r('sys.symbol.person_crop_circle_fill'))
              .fontSize(22)
              .fontColor([this.tabColor(RootTab.PROFILE)])
            Text('我的')
              .fontSize(12)
              .fontColor(this.tabColor(RootTab.PROFILE))
          }
          .layoutWeight(1)
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .onClick((): void => this.onSelectTab(RootTab.PROFILE))
        }
        .width('100%')
        .height('100%')
        .opacity(this.expandedNavigationOpacity())
        .enabled(this.normalizedProgress() < 0.3)

        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph($r('sys.symbol.house_fill'))
            .fontSize(22)
            .fontColor([$r('app.color.accent')])
        }
        .width(FnMusicUI.bottomBarHeight)
        .height(FnMusicUI.bottomBarHeight)
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .backgroundColor(Color.Transparent)
        .opacity(this.compactNavigationOpacity())
        .enabled(this.normalizedProgress() >= 0.3)
        .accessibilityText('恢复底部导航')
        .onClick((): void => this.onRestore())
      }
      .width(this.navigationWidth())
      .height(FnMusicUI.bottomBarHeight)
      .borderRadius(FnMusicUI.bottomBarHeight / 2)
      .clip(true)
      .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.FLOATING_PLAYER))
      .position({ x: this.navigationX(), y: this.navigationTop() })

      if (this.hasPlayer()) {
      MiniPlayerBar({
        state: this.playerState,
        placement: PlayerHostPlacement.COMPACT_HOME,
        heightOverride: this.playerHeight(),
        transitionId: HOME_PLAYER_TRANSITION_ID,
        onExpand: (): void => this.onExpand(),
        onToggle: (): void => {
          this.playback.toggle().catch((): void => {});
        },
        onNext: (): void => {
          this.playback.next().catch((): void => {});
        },
        onQueue: (): void => this.onQueue()
      })
      .width(this.playerWidth())
      .height(this.playerHeight())
      .position({
        x: this.playerX(),
        y: this.interpolate(0, FnMusicUI.homeMiniPlayerHeight + FnMusicUI.compactPlayerGap)
      })
      }
    }
    .width('100%')
    .height(this.chromeHeight())
    .hitTestBehavior(HitTestMode.Transparent)
    .onAreaChange((_: Area, area: Area): void => {
      const width = area.width as number;
      if (width > 0) {
        this.availableWidth = width;
      }
    })
  }
}

export class AppShellController {
  private backHandler?: () => boolean;

  attach(backHandler: () => boolean): void {
    this.backHandler = backHandler;
  }

  detach(): void {
    this.backHandler = undefined;
  }

  handleBack(): boolean {
    return this.backHandler?.() ?? false;
  }
}

class ArtistDetailSnapshot {
  collectionId: string = '';
  pageTitle: string = '';
  pageSubtitle: string = '';
  pageSymbol: Resource = $r('sys.symbol.person_fill');
  artist: MusicArtist = new MusicArtist();
  tracks: MusicTrack[] = [];
  trackTotal: number = 0;
  trackDeclaredTotal: number = 0;
  trackPage: number = 0;
  tracksHasMore: boolean = false;
  loading: boolean = false;
  loadingMore: boolean = false;
  errorMessage: string = '';
  loadMoreError: string = '';
}

@ComponentV2
export struct AppShell {
  @Param runtime?: AppRuntimeState = undefined;
  @Param controller?: AppShellController = undefined;
  @Param safeTop: number = 0;
  @Param safeBottom: number = 0;
  @Event onLogout: () => void = (): void => {};
  @Local rootTab: RootTab = RootTab.HOME;
  @Local page: AppShellPage = AppShellPage.ROOT;
  @Local previousPage: AppShellPage = AppShellPage.ROOT;
  @Local playerReturnPage: AppShellPage = AppShellPage.ROOT;
  @Local pageTitle: string = '';
  @Local pageSubtitle: string = '';
  @Local pageSymbol: Resource = $r('sys.symbol.music_note_list');
  @Local activeTracks: MusicTrack[] = [];
  @Local activeTrackTotal: number = 0;
  @Local activeTracksHasMore: boolean = false;
  @Local activeTracksLoadingMore: boolean = false;
  @Local activeTracksLoadMoreError: string = '';
  @Local activeTrack: MusicTrack = new MusicTrack();
  @Local activeAlbum: MusicAlbum = new MusicAlbum();
  @Local activeArtist: MusicArtist = new MusicArtist();
  @Local activeGenre: MusicGenre = new MusicGenre();
  @Local activeGenreVisualIndex: number = 0;
  @Local activePlaylist: MusicPlaylist = new MusicPlaylist();
  @Local showSettings: boolean = false;
  @Local showTrackActions: boolean = false;
  @Local canRemoveActiveTrack: boolean = false;
  @Local showTrackInfo: boolean = false;
  @Local trackInfoTrack: MusicTrack = new MusicTrack();
  @Local showPlaylistActions: boolean = false;
  @Local showPlaylistSort: boolean = false;
  @Local playlistSelectionMode: boolean = false;
  @Local playlistOperationBusy: boolean = false;
  @Local playlistSortKey: PlaylistSortKey = PlaylistSortKey.ADDED_DATE;
  @Local playlistSortOrder: PlaylistSortOrder = PlaylistSortOrder.DESCENDING;
  @Local showPlaylistEditor: boolean = false;
  @Local showPlaylistPicker: boolean = false;
  @Local playlistEditMode: PlaylistEditMode = PlaylistEditMode.CREATE;
  @Local workingPlaylists: MusicPlaylist[] = [];
  @Local searchTracks: MusicTrack[] = [];
  @Local searchAlbums: MusicAlbum[] = [];
  @Local searchArtists: MusicArtist[] = [];
  @Local searchLoading: boolean = false;
  @Local searchError: string = '';
  @Local activeTracksLoading: boolean = false;
  @Local activeTracksError: string = '';
  @Local activeCollectionId: string = '';
  @Local playAllInProgress: boolean = false;
  @Local playAllShuffleInProgress: boolean = false;
  @Local playerState: PlayerPresentationState = connectPlayerPresentationState();
  @Local preferences: MusicPreferenceState = connectMusicPreferenceState();
  @Local navigationEnabled: boolean = true;
  @Local homeChromeProgress: number = 0;
  @Local homeSectionPinned: boolean = false;
  @Local homeSearchCollapsed: boolean = false;
  private nextLocalPlaylistId: number = 1;
  private searchSequence: number = 0;
  private tracksLoadSequence: number = 0;
  private activeTracksPage: number = 0;
  private activeTrackDeclaredTotal: number = 0;
  private playback: MusicPlaybackController = MusicPlaybackController.instance();
  private tabsController: HdsTabsController = new HdsTabsController();
  private homeScroller: Scroller = new Scroller();
  private pathStack: NavPathStack = new NavPathStack();
  private playerTransitionInProgress: boolean = false;
  private pendingPlayerMinimizeAction?: () => void = undefined;
  private artistDetailSnapshot?: ArtistDetailSnapshot = undefined;

  @Monitor('rootTab')
  onRootTabChanged(): void {
    this.tabsController.changeIndex(this.rootTabIndex(this.rootTab));
    if (this.rootTab !== RootTab.HOME) {
      this.homeChromeProgress = 0;
      this.homeSectionPinned = false;
    }
  }

  private rootTabIndex(tab: RootTab): number {
    if (tab === RootTab.PLAYLIST) return 1;
    if (tab === RootTab.PROFILE) return 2;
    return 0;
  }

  private rootTabFromIndex(index: number): RootTab {
    if (index === 1) return RootTab.PLAYLIST;
    if (index === 2) return RootTab.PROFILE;
    return RootTab.HOME;
  }

  private rootTitle(): string {
    if (this.rootTab === RootTab.PLAYLIST) return '歌单';
    if (this.rootTab === RootTab.PROFILE) return '我的';
    return '首页';
  }

  private navigationTitleBar(): HdsNavigationTitleBarOptions {
    return {
      avoidLayoutSafeArea: true,
      enableComponentSafeArea: false,
      content: {
        title: {
          mainTitle: this.rootTitle(),
          mainTitleSize: TitleSize.TITLE_S
        },
        menu: {
          value: this.rootTab === RootTab.HOME && this.homeSearchCollapsed ? [{
            content: {
              icon: $r('sys.symbol.magnifyingglass'),
              label: '搜索',
              action: (): void => this.openPage(AppShellPage.SEARCH)
            }
          }] : (this.rootTab === RootTab.PLAYLIST ? [{
            content: {
              icon: $r('sys.symbol.plus_circle'),
              label: '新建歌单',
              action: (): void => this.beginCreatePlaylist()
            }
          }] : []),
          maxCount: 1
        }
      },
      style: {
        scrollEffectOpts: {
          enableScrollEffect: true,
          scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR,
          blurEffectiveStartOffset: LengthMetrics.vp(1),
          blurEffectiveEndOffset: LengthMetrics.vp(24)
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.GENTLE
        },
        originalStyle: {
          backgroundStyle: {
            backgroundColor: Color.Transparent,
            maskExtraHeight: 0,
            blurRadius: 0
          },
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r('app.color.text_primary')
            },
            menuStyle: {
              iconColor: $r('app.color.text_primary'),
              textColor: $r('app.color.accent')
            }
          }
        },
        scrollEffectStyle: {
          backgroundStyle: {
            backgroundColor: Color.Transparent,
            maskExtraHeight: 32,
            blurRadius: 24
          },
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r('app.color.text_primary')
            },
            menuStyle: {
              iconColor: $r('app.color.text_primary'),
              textColor: $r('app.color.accent')
            }
          }
        }
      }
    };
  }

  @Builder
  private rootTabBar(title: string, tab: RootTab, symbol: Resource) {
    Column({ space: 4 }) {
      SymbolGlyph(symbol)
        .fontSize(22)
        .fontColor([this.rootTab === tab ? $r('app.color.accent') : $r('app.color.text_primary')])
      Text(title)
        .fontSize(12)
        .fontColor(this.rootTab === tab ? $r('app.color.accent') : $r('app.color.text_primary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private rootTabs() {
    Stack({ alignContent: Alignment.BottomStart }) {
      HdsTabs({
      index: this.rootTabIndex(this.rootTab),
      barPosition: BarPosition.End,
      controller: this.tabsController
    }) {
      TabContent() {
        HomeScreen({
          tracks: this.tracks(), albums: this.albums(), artists: this.artists(), genres: this.genres(),
          bottomInset: this.bottomAvoidance(),
          stickyTopInset: this.safeTop,
          pageScroller: this.homeScroller,
          onPinnedChange: (pinned: boolean): void => {
            this.homeSectionPinned = pinned;
          },
          onSearchCollapsedChange: (collapsed: boolean): void => {
            this.homeSearchCollapsed = collapsed;
          },
          onChromeProgress: (progress: number): void => {
            this.homeChromeProgress = progress;
          },
          onOpenSearch: (): void => this.openPage(AppShellPage.SEARCH),
          onOpenCollection: (id: string, title: string): void => {
            if (id === CollectionKind.RECENTLY_ADDED) {
              this.openCollection(CollectionKind.LIBRARY, '音乐库');
              return;
            }
            this.openCollection(id, title);
          },
          onPlayCollection: (id: string): void => {
            this.playCollection(id);
          },
          onOpenSection: (id: string): void => {
            if (id === 'albums') this.openPage(AppShellPage.ALBUMS);
            else if (id === 'artists') this.openPage(AppShellPage.ARTISTS);
            else if (id === 'genres') this.openPage(AppShellPage.GENRES);
          },
          onOpenAlbum: (album: MusicAlbum): void => this.openAlbum(album),
          onPlayAlbum: (album: MusicAlbum): void => {
            this.playAlbum(album);
          },
          onOpenArtist: (artist: MusicArtist): void => this.openArtist(artist),
          onOpenGenre: (genre: MusicGenre): void => this.openGenre(genre),
          onPlayTracks: (tracks: MusicTrack[], index: number): void => this.playTracks(tracks, index),
          onTrackMore: (track: MusicTrack): void => this.showTrackMenu(track)
        })
      }
      .tabBar(this.rootTabBar('首页', RootTab.HOME,
        this.rootTab === RootTab.HOME ? $r('sys.symbol.house_fill') : $r('sys.symbol.house')))

      TabContent() {
        PlaylistScreen({
          playlists: this.playlists(),
          safeTop: this.safeTop,
          bottomInset: this.bottomAvoidance(),
          onOpenPlaylist: (playlist: MusicPlaylist): void => this.openPlaylist(playlist),
          onPlaylistMore: (playlist: MusicPlaylist): void => {
            this.activePlaylist = playlist;
            this.playlistEditMode = PlaylistEditMode.EDIT;
            this.showPlaylistEditor = true;
          }
        })
      }
      .tabBar(this.rootTabBar('歌单', RootTab.PLAYLIST, $r('sys.symbol.music_note_list')))

      TabContent() {
        ProfileScreen({
          user: this.currentUser(), playlists: this.playlists(),
          bottomInset: this.bottomAvoidance(),
          onOpenPlaylist: (playlist: MusicPlaylist): void => this.openPlaylist(playlist),
          onPlaylistMore: (playlist: MusicPlaylist): void => {
            this.activePlaylist = playlist;
            this.playlistEditMode = PlaylistEditMode.EDIT;
            this.showPlaylistEditor = true;
          },
          onCreatePlaylist: (): void => {
            this.beginCreatePlaylist();
          },
          onOpenSettings: (): void => { this.showSettings = true; },
          onLogout: (): void => this.onLogout()
        })
      }
      .tabBar(this.rootTabBar('我的', RootTab.PROFILE,
        $r('sys.symbol.person_crop_circle_fill')))
    }
    .barHeight(0)
    .barMode(BarMode.Fixed, { nonScrollableLayoutStyle: LayoutStyle.ALWAYS_CENTER })
    .vertical(false)
    .divider({ mode: DividerMode.NONE })
    .barOverlap(true)
    .animationDuration(0)
    .scrollable(false)
    .width('100%')
      .height('100%')
      .onTabBarClick((index: number): void => {
        this.rootTab = this.rootTabFromIndex(index);
      })

      HomeBottomChrome({
        selectedTab: this.rootTab,
        progress: this.rootTab === RootTab.HOME ? this.homeChromeProgress : 0,
        safeBottom: this.safeBottom,
        showPlayer: this.rootTab === RootTab.HOME,
        onSelectTab: (tab: RootTab): void => {
          this.rootTab = tab;
        },
        onRestore: (): void => this.restoreHomeChrome(),
        onExpand: (): void => this.openPlayer(),
        onQueue: (): void => this.openPlayerQueue()
      })
      .align(Alignment.BottomStart)
    }
    .width('100%')
    .height('100%')
  }

  aboutToAppear(): void {
    this.controller?.attach((): boolean => this.handleBack());
  }

  aboutToDisappear(): void {
    this.controller?.detach();
  }

  private restoreHomeChrome(): void {
    this.getUIContext().animateTo({ duration: 280, curve: Curve.Smooth }, (): void => {
      this.homeChromeProgress = 0;
      this.homeSectionPinned = false;
    });
    this.homeScroller.scrollEdge(Edge.Start);
  }

  private beginCreatePlaylist(): void {
    this.playlistEditMode = PlaylistEditMode.CREATE;
    this.activePlaylist = new MusicPlaylist();
    this.showPlaylistEditor = true;
  }

  private hasPlayer(): boolean {
    return this.playerState.currentTrack() !== undefined;
  }

  private sheetVisible(): boolean {
    return this.playerState.queueVisible || this.showSettings || this.showTrackActions ||
      this.showTrackInfo || this.showPlaylistActions || this.showPlaylistSort ||
      this.showPlaylistEditor || this.showPlaylistPicker;
  }

  private bottomAvoidance(): number {
    if (this.page === AppShellPage.PLAYER) {
      return 0;
    }
    if (this.page !== AppShellPage.ROOT) {
      return this.hasPlayer() ? FnMusicUI.floatingPlayerHeight + FnMusicUI.compactPlayerGap : 0;
    }
    if (this.rootTab !== RootTab.HOME) {
      return FnMusicUI.bottomBarHeight +
        (this.hasPlayer() ? FnMusicUI.floatingPlayerHeight + FnMusicUI.compactPlayerGap : 0);
    }
    return FnMusicUI.bottomBarHeight;
  }

  private miniPlayerPlacement(): PlayerHostPlacement {
    if (this.page !== AppShellPage.ROOT) {
      return PlayerHostPlacement.FLOATING;
    }
    if (this.rootTab !== RootTab.HOME) {
      return PlayerHostPlacement.ROOT_FLOATING;
    }
    return PlayerHostPlacement.HOME;
  }

  private miniPlayerBottom(): number {
    if (this.page !== AppShellPage.ROOT) {
      return Math.max(0, this.safeBottom) + FnMusicUI.compactPlayerGap;
    }
    return Math.max(0, this.safeBottom) + FnMusicUI.bottomBarHeight + FnMusicUI.compactPlayerGap;
  }

  private libraryUnavailable(): boolean {
    return this.runtime !== undefined &&
      (this.runtime.loadingLibrary || this.runtime.libraryError.length > 0) &&
      this.runtime.tracks.length === 0 && this.runtime.albums.length === 0 &&
      this.runtime.artists.length === 0 && this.runtime.genres.length === 0 &&
      this.runtime.playlists.length === 0;
  }

  private tracks(): MusicTrack[] {
    if (this.runtime !== undefined) {
      return this.runtime.tracks;
    }
    return appSession.tracks;
  }

  private albums(): MusicAlbum[] {
    if (this.runtime !== undefined) {
      return this.runtime.albums;
    }
    return appSession.albums;
  }

  private albumsForArtist(artist: MusicArtist): MusicAlbum[] {
    const artistName: string = artist.name.trim().toLocaleLowerCase();
    if (artistName.length === 0 || this.activeCollectionId !== CollectionKind.ARTIST) {
      return [];
    }
    const albums: MusicAlbum[] = [];
    this.activeTracks.forEach((track: MusicTrack): void => {
      const belongsToArtist: boolean = track.artists.some((item: MusicArtist): boolean =>
        item.guid === artist.guid || item.name.trim().toLocaleLowerCase() === artistName);
      if (!belongsToArtist && track.artistGuid !== artist.guid &&
        !track.artistName.toLocaleLowerCase().split(' / ').some((name: string): boolean => name.trim() === artistName)) {
        return;
      }
      const albumGuid: string = track.albumGuid.length > 0 ? track.albumGuid : track.album.guid;
      const albumName: string = track.albumName.length > 0 ? track.albumName : track.album.name;
      if (albumGuid.length === 0 && albumName.length === 0) {
        return;
      }
      const existing: MusicAlbum | undefined = albums.find((item: MusicAlbum): boolean =>
        (albumGuid.length > 0 && item.guid === albumGuid) ||
          (albumGuid.length === 0 && item.name === albumName));
      if (existing !== undefined) {
        if (existing.trackCount <= 0) {
          existing.trackCount += 1;
        }
        return;
      }
      const catalogAlbum: MusicAlbum | undefined = this.albums().find((item: MusicAlbum): boolean =>
        (albumGuid.length > 0 && item.guid === albumGuid) || item.name === albumName);
      const source: MusicAlbum = catalogAlbum ?? track.album;
      const album = new MusicAlbum(
        albumGuid,
        albumName.length > 0 ? albumName : source.name,
        source.coverId.length > 0 ? source.coverId : track.coverId,
        source.year > 0 ? source.year : track.year,
        artist.name
      );
      album.trackCount = source.trackCount > 0 ? source.trackCount : 1;
      album.createdAt = source.createdAt > 0 ? source.createdAt : track.createdAt;
      albums.push(album);
    });
    return albums;
  }

  private artists(): MusicArtist[] {
    if (this.runtime !== undefined) {
      return this.runtime.artists;
    }
    return appSession.artists;
  }

  private genres(): MusicGenre[] {
    if (this.runtime !== undefined) {
      return this.runtime.genres;
    }
    return appSession.genres;
  }

  private playlists(): MusicPlaylist[] {
    if (this.runtime !== undefined) {
      return this.runtime.playlists;
    }
    if (this.workingPlaylists.length > 0) {
      return this.workingPlaylists;
    }
    return appSession.playlists;
  }

  private openPage(page: AppShellPage): void {
    if (page === AppShellPage.SEARCH || page === AppShellPage.ALBUMS || page === AppShellPage.ARTISTS ||
      page === AppShellPage.GENRES) {
      this.activeCollectionId = '';
    }
    if (this.page === AppShellPage.SEARCH) {
      this.previousPage = AppShellPage.SEARCH;
    } else if (page !== AppShellPage.ALBUM_DETAIL && page !== AppShellPage.ARTIST_DETAIL &&
      page !== AppShellPage.GENRE_DETAIL) {
      this.previousPage = AppShellPage.ROOT;
    }
    this.page = page;
    this.pathStack.pushPath({ name: page });
  }

  private openPlayer(): void {
    this.openPlayerDestination(false);
  }

  private openPlayerQueue(): void {
    if (!this.playerState.roamMode) {
      this.playback.showQueue();
    }
  }

  private openPlayerDestination(showQueueAfterTransition: boolean): void {
    if (this.playerTransitionInProgress || !this.hasPlayer()) {
      return;
    }
    const routeParams = new PlayerRouteParams();
    routeParams.longTakeTransitionParam = ezCustomTransition.generateLongTakeParam(
      this.getUIContext(), this.playerTransitionSourceId(), this.playerTransitionRadius(), {
        type: LongTakeTransitionType.CardLongTake,
        useSpringCurve: false,
        isGestureEnabled: false,
        onEnterTransitionEnd: (): void => {
          this.playerTransitionInProgress = false;
          this.navigationEnabled = true;
          if (showQueueAfterTransition && this.page === AppShellPage.PLAYER) {
            this.playback.showQueue();
          }
        },
        onBackTransitionEnd: (): void => this.finishPlayerMinimize()
      });
    this.playerTransitionInProgress = true;
    this.playerReturnPage = this.page;
    this.playback.hideQueue();
    this.page = AppShellPage.PLAYER;
    this.pathStack.pushPath({ name: AppShellPage.PLAYER, param: routeParams });
  }

  private minimizePlayer(after?: () => void): void {
    if (this.playerTransitionInProgress) {
      return;
    }
    this.playerTransitionInProgress = true;
    this.pendingPlayerMinimizeAction = after;
    this.playback.hideQueue();
    this.pathStack.pop();
  }

  private playerTransitionSourceId(): string {
    return this.page === AppShellPage.ROOT && this.rootTab === RootTab.HOME ?
      HOME_PLAYER_TRANSITION_ID : FLOATING_PLAYER_TRANSITION_ID;
  }

  private playerTransitionRadius(): number {
    if (this.page === AppShellPage.ROOT && this.rootTab === RootTab.HOME) {
      const progress: number = Math.max(0, Math.min(1, this.homeChromeProgress));
      return (FnMusicUI.homeMiniPlayerHeight +
        (FnMusicUI.compactPlayerHeight - FnMusicUI.homeMiniPlayerHeight) * progress) / 2;
    }
    return FnMusicUI.floatingPlayerHeight / 2;
  }

  private finishPlayerMinimize(): void {
    this.playerTransitionInProgress = false;
    this.navigationEnabled = true;
    const action = this.pendingPlayerMinimizeAction;
    this.pendingPlayerMinimizeAction = undefined;
    action?.();
  }

  private goBack(): void {
    if (this.playback.dismissOverlay()) {
      return;
    }
    if (this.showSettings || this.showTrackActions || this.showTrackInfo || this.showPlaylistActions ||
      this.showPlaylistSort || this.showPlaylistEditor || this.showPlaylistPicker) {
      this.showSettings = false;
      this.showTrackActions = false;
      this.showTrackInfo = false;
      this.showPlaylistActions = false;
      this.showPlaylistSort = false;
      this.showPlaylistEditor = false;
      this.showPlaylistPicker = false;
      return;
    }
    if (this.playlistSelectionMode) {
      this.playlistSelectionMode = false;
      return;
    }
    if (this.page === AppShellPage.ALBUM_DETAIL || this.page === AppShellPage.ARTIST_DETAIL ||
      this.page === AppShellPage.GENRE_DETAIL) {
      const leavingPage: AppShellPage = this.page;
      this.pathStack.pop();
      this.syncPageFromPathStack();
      if (leavingPage === AppShellPage.ALBUM_DETAIL && this.page === AppShellPage.ARTIST_DETAIL &&
        this.artistDetailSnapshot !== undefined) {
        this.restoreArtistDetail(this.artistDetailSnapshot);
        this.artistDetailSnapshot = undefined;
      } else if (this.page !== AppShellPage.ARTIST_DETAIL) {
        this.artistDetailSnapshot = undefined;
      }
      return;
    }
    if (this.page === AppShellPage.PLAYER) {
      this.minimizePlayer();
      return;
    }
    this.pathStack.pop();
    this.syncPageFromPathStack();
  }

  private syncPageFromPathStack(): void {
    const names: string[] = this.pathStack.getAllPathName();
    this.page = names.length > 0 ? names[names.length - 1] as AppShellPage : AppShellPage.ROOT;
  }

  private tracksForCollection(id: string): MusicTrack[] {
    if (id === 'favorites') {
      return this.tracks().filter((track: MusicTrack): boolean => track.isFavorite);
    }
    if (id === 'history') {
      return this.tracks().slice().reverse();
    }
    if (id === 'roam') {
      return this.tracks().length > 1 ? this.tracks().slice(1).concat(this.tracks().slice(0, 1)) : this.tracks();
    }
    return this.tracks();
  }

  private resetActiveTrackPaging(total: number = 0): void {
    this.activeTrackTotal = Math.max(0, total);
    this.activeTrackDeclaredTotal = Math.max(0, total);
    this.activeTracksPage = 0;
    this.activeTracksHasMore = false;
    this.activeTracksLoadingMore = false;
    this.activeTracksLoadMoreError = '';
  }

  private activeTrackPageSize(): number {
    if (this.activeCollectionId === CollectionKind.PLAYLIST) {
      return 300;
    }
    if (this.activeCollectionId === CollectionKind.FAVORITES ||
      this.activeCollectionId === CollectionKind.HISTORY) {
      return 100;
    }
    return 120;
  }

  private supportsActiveTrackPaging(): boolean {
    return this.activeCollectionId === CollectionKind.FAVORITES ||
      this.activeCollectionId === CollectionKind.HISTORY ||
      this.activeCollectionId === CollectionKind.ALBUM ||
      this.activeCollectionId === CollectionKind.ARTIST ||
      this.activeCollectionId === CollectionKind.GENRE ||
      this.activeCollectionId === CollectionKind.PLAYLIST;
  }

  private async requestActiveTrackPage(page: number): Promise<PageResult<MusicTrack>> {
    if (this.activeCollectionId === CollectionKind.FAVORITES) {
      return await AppRuntime.favoriteTracksPage(page, this.activeTrackPageSize());
    }
    if (this.activeCollectionId === CollectionKind.HISTORY) {
      return await AppRuntime.playHistoryPage(page, this.activeTrackPageSize());
    }
    if (this.activeCollectionId === CollectionKind.ALBUM) {
      return await AppRuntime.albumTracksPage(this.activeAlbum.guid, page, this.activeTrackPageSize());
    }
    if (this.activeCollectionId === CollectionKind.ARTIST) {
      return await AppRuntime.artistTracksPage(this.activeArtist.guid, page, this.activeTrackPageSize());
    }
    if (this.activeCollectionId === CollectionKind.GENRE) {
      return await AppRuntime.genreTracksPage(this.activeGenre.guid, page, this.activeTrackPageSize());
    }
    if (this.activeCollectionId === CollectionKind.PLAYLIST) {
      return await AppRuntime.playlistTracksPage(this.activePlaylist.guid, page, this.activeTrackPageSize());
    }
    throw new Error('当前列表不支持分页加载');
  }

  private appendUniqueActiveTracks(current: MusicTrack[], incoming: MusicTrack[]): MusicTrack[] {
    const known = new Set<string>(current.map((track: MusicTrack): string => track.guid));
    const additions = incoming.filter((track: MusicTrack): boolean =>
      track.guid.length > 0 && !known.has(track.guid));
    return current.concat(additions);
  }

  private async loadActiveTrackPage(page: number, replace: boolean): Promise<void> {
    if (!this.supportsActiveTrackPaging()) {
      return;
    }
    const sequence = ++this.tracksLoadSequence;
    if (replace) {
      this.activeTracksLoading = true;
      this.activeTracksError = '';
      this.activeTracksLoadMoreError = '';
    } else {
      this.activeTracksLoadingMore = true;
      this.activeTracksLoadMoreError = '';
    }
    try {
      const result: PageResult<MusicTrack> = await this.requestActiveTrackPage(page);
      if (sequence !== this.tracksLoadSequence) {
        return;
      }
      const tracks: MusicTrack[] = replace ? this.appendUniqueActiveTracks([], result.list) :
        this.appendUniqueActiveTracks(this.activeTracks, result.list);
      const declaredTotal: number = Math.max(this.activeTrackDeclaredTotal, result.total);
      const total: number = Math.max(declaredTotal, tracks.length);
      this.activeTracks = tracks;
      this.activeTrackTotal = total;
      this.activeTrackDeclaredTotal = declaredTotal;
      this.activeTracksPage = page;
      this.activeTracksHasMore = result.list.length > 0 &&
        (declaredTotal > 0 ? tracks.length < declaredTotal : result.list.length >= this.activeTrackPageSize());
    } catch (error) {
      if (sequence === this.tracksLoadSequence) {
        const message: string = (error as Error).message || '列表加载失败';
        if (replace) {
          this.activeTracksError = message;
        } else {
          this.activeTracksLoadMoreError = message;
        }
      }
    } finally {
      if (sequence === this.tracksLoadSequence) {
        if (replace) {
          this.activeTracksLoading = false;
        } else {
          this.activeTracksLoadingMore = false;
        }
      }
    }
  }

  private loadMoreActiveTracks(): void {
    if (!this.supportsActiveTrackPaging() || this.activeTracksLoading || this.activeTracksLoadingMore ||
      !this.activeTracksHasMore) {
      return;
    }
    this.loadActiveTrackPage(Math.max(1, this.activeTracksPage) + 1, false).catch((): void => {});
  }

  private openCollection(id: string, title: string): void {
    this.activeCollectionId = id;
    this.pageTitle = title;
    this.pageSubtitle = id === 'recently_added' ? '按添加时间从新到旧' : '';
    this.pageSymbol = id === 'favorites' ? $r('sys.symbol.heart_fill') :
      id === 'history' ? $r('sys.symbol.arrow_clockwise') :
        id === 'roam' ? $r('sys.symbol.crown_fill') : $r('sys.symbol.music_note_list');
    this.activeTracks = this.runtime === undefined ? this.tracksForCollection(id) : [];
    this.resetActiveTrackPaging(this.runtime === undefined ? this.activeTracks.length :
      (id === CollectionKind.LIBRARY ? this.runtime?.trackTotal ?? 0 : 0));
    this.activeTracksError = '';
    this.openPage(AppShellPage.TRACKS);
    if (this.runtime !== undefined) {
      this.loadCollection(id).catch((): void => {});
    }
  }

  private openAlbum(album: MusicAlbum): void {
    this.activeCollectionId = CollectionKind.ALBUM;
    this.activeAlbum = album;
    this.pageTitle = album.name;
    this.pageSubtitle = album.artistName;
    this.pageSymbol = $r('sys.symbol.music_note_list');
    this.activeTracks = this.runtime === undefined ? this.tracks().filter((track: MusicTrack): boolean =>
      track.albumGuid === album.guid || track.albumName === album.name) : [];
    this.resetActiveTrackPaging(this.runtime === undefined ? this.activeTracks.length : album.trackCount);
    this.activeTracksError = '';
    this.openPage(AppShellPage.ALBUM_DETAIL);
    if (this.runtime !== undefined) {
      this.loadActiveTrackPage(1, true).catch((): void => {});
    }
  }

  private openAlbumFromArtist(album: MusicAlbum): void {
    const snapshot = new ArtistDetailSnapshot();
    snapshot.collectionId = this.activeCollectionId;
    snapshot.pageTitle = this.pageTitle;
    snapshot.pageSubtitle = this.pageSubtitle;
    snapshot.pageSymbol = this.pageSymbol;
    snapshot.artist = this.activeArtist;
    snapshot.tracks = this.activeTracks.slice();
    snapshot.trackTotal = this.activeTrackTotal;
    snapshot.trackDeclaredTotal = this.activeTrackDeclaredTotal;
    snapshot.trackPage = this.activeTracksPage;
    snapshot.tracksHasMore = this.activeTracksHasMore;
    snapshot.loading = this.activeTracksLoading;
    snapshot.loadingMore = this.activeTracksLoadingMore;
    snapshot.errorMessage = this.activeTracksError;
    snapshot.loadMoreError = this.activeTracksLoadMoreError;
    this.artistDetailSnapshot = snapshot;
    this.openAlbum(album);
  }

  private restoreArtistDetail(snapshot: ArtistDetailSnapshot): void {
    this.activeCollectionId = snapshot.collectionId;
    this.pageTitle = snapshot.pageTitle;
    this.pageSubtitle = snapshot.pageSubtitle;
    this.pageSymbol = snapshot.pageSymbol;
    this.activeArtist = snapshot.artist;
    this.activeTracks = snapshot.tracks;
    this.activeTrackTotal = snapshot.trackTotal;
    this.activeTrackDeclaredTotal = snapshot.trackDeclaredTotal;
    this.activeTracksPage = snapshot.trackPage;
    this.activeTracksHasMore = snapshot.tracksHasMore;
    this.activeTracksLoading = snapshot.loading;
    this.activeTracksLoadingMore = snapshot.loadingMore;
    this.activeTracksError = snapshot.errorMessage;
    this.activeTracksLoadMoreError = snapshot.loadMoreError;
  }

  private openArtist(artist: MusicArtist): void {
    this.activeCollectionId = CollectionKind.ARTIST;
    this.activeArtist = artist;
    this.pageTitle = artist.name;
    this.pageSubtitle = '歌手热门歌曲';
    this.pageSymbol = $r('sys.symbol.person_fill');
    this.activeTracks = this.runtime === undefined ? this.tracks().filter((track: MusicTrack): boolean =>
      track.artistGuid === artist.guid || track.artistName === artist.name) : [];
    this.resetActiveTrackPaging(this.runtime === undefined ? this.activeTracks.length : artist.trackCount);
    this.activeTracksError = '';
    this.openPage(AppShellPage.ARTIST_DETAIL);
    if (this.runtime !== undefined) {
      this.loadActiveTrackPage(1, true).catch((): void => {});
    }
  }

  private openGenre(genre: MusicGenre): void {
    this.activeCollectionId = CollectionKind.GENRE;
    this.activeGenre = genre;
    const genreIndex = this.genres().findIndex((item: MusicGenre): boolean => item.guid === genre.guid);
    this.activeGenreVisualIndex = Math.max(0, genreIndex);
    this.pageTitle = genre.name;
    this.pageSubtitle = `${genre.trackCount} 首歌曲`;
    this.pageSymbol = $r('sys.symbol.music_badge_wave_2');
    this.activeTracks = this.runtime === undefined ? this.tracks() : [];
    this.resetActiveTrackPaging(this.runtime === undefined ? this.activeTracks.length : genre.trackCount);
    this.activeTracksError = '';
    this.openPage(AppShellPage.GENRE_DETAIL);
    if (this.runtime !== undefined) {
      this.loadActiveTrackPage(1, true).catch((): void => {});
    }
  }

  private openPlaylist(playlist: MusicPlaylist): void {
    this.activeCollectionId = CollectionKind.PLAYLIST;
    this.activePlaylist = playlist;
    this.playlistSelectionMode = false;
    this.playlistOperationBusy = false;
    this.playlistSortKey = PlaylistSortKey.ADDED_DATE;
    this.playlistSortOrder = PlaylistSortOrder.DESCENDING;
    this.pageTitle = playlist.name;
    this.pageSubtitle = playlist.description.length > 0 ? playlist.description : '自建歌单';
    this.pageSymbol = $r('sys.symbol.music_note_list');
    this.activeTracks = this.runtime === undefined ?
      this.tracks().slice(0, Math.min(this.tracks().length, Math.max(1, playlist.trackCount))) : [];
    this.resetActiveTrackPaging(this.runtime === undefined ? this.activeTracks.length : playlist.trackCount);
    this.activeTracksError = '';
    this.openPage(AppShellPage.PLAYLIST_DETAIL);
    if (this.runtime !== undefined) {
      this.loadActiveTrackPage(1, true).catch((): void => {});
    }
  }

  private async loadCollection(id: string): Promise<void> {
    if (id === CollectionKind.LIBRARY || id === CollectionKind.RECENTLY_ADDED) {
      return;
    }
    if (id === CollectionKind.ROAM) {
      await this.loadDetail((): Promise<MusicTrack[]> => AppRuntime.startRoam());
      return;
    }
    await this.loadActiveTrackPage(1, true);
  }

  private async loadDetail(load: () => Promise<MusicTrack[]>): Promise<void> {
    const sequence = ++this.tracksLoadSequence;
    this.activeTracksLoading = true;
    this.activeTracksError = '';
    try {
      const tracks = await load();
      if (sequence === this.tracksLoadSequence) {
        this.activeTracks = tracks;
        this.activeTrackTotal = tracks.length;
        this.activeTrackDeclaredTotal = tracks.length;
        this.activeTracksPage = tracks.length > 0 ? 1 : 0;
        this.activeTracksHasMore = false;
      }
    } catch (error) {
      if (sequence === this.tracksLoadSequence) {
        this.activeTracksError = (error as Error).message || '列表加载失败';
      }
    } finally {
      if (sequence === this.tracksLoadSequence) {
        this.activeTracksLoading = false;
      }
    }
  }

  private showTrackMenu(track: MusicTrack, canRemove: boolean = false): void {
    this.activeTrack = track;
    this.canRemoveActiveTrack = canRemove;
    this.showTrackActions = true;
  }

  private showTrackInfoSheet(track: MusicTrack): void {
    this.trackInfoTrack = track;
    this.showTrackInfo = true;
    if (this.runtime === undefined || track.guid.length === 0) {
      return;
    }
    const guid = track.guid;
    AppRuntime.trackMetadata(guid).then((metadata: MusicTrack): void => {
      if (this.showTrackInfo && this.trackInfoTrack.guid === guid) {
        this.trackInfoTrack = metadata;
      }
    }).catch((): void => {
      // The list payload already contains the core metadata, so a detail fetch
      // failure does not block the read-only information sheet.
    });
  }

  private async appendSelectedTracksToQueue(tracks: MusicTrack[]): Promise<void> {
    if (tracks.length === 0 || this.playlistOperationBusy) {
      return;
    }
    this.playlistOperationBusy = true;
    try {
      for (const track of tracks) {
        await this.playback.appendToQueue(track);
      }
      FnToast.show(`已将 ${tracks.length} 首歌曲加入播放列表`);
    } catch (_) {
      FnToast.show('暂时无法调整播放列表');
    } finally {
      this.playlistOperationBusy = false;
    }
  }

  private async removeActivePlaylistTracks(tracks: MusicTrack[]): Promise<void> {
    if (tracks.length === 0 || this.playlistOperationBusy) {
      return;
    }
    const guids: string[] = tracks.map((track: MusicTrack): string => track.guid)
      .filter((guid: string, index: number, values: string[]): boolean => guid.length > 0 && values.indexOf(guid) === index);
    if (guids.length === 0) {
      return;
    }
    this.playlistOperationBusy = true;
    try {
      if (this.runtime !== undefined) {
        await AppRuntime.removeTracksFromPlaylist(this.activePlaylist.guid, guids);
      }
      this.activeTracks = this.activeTracks.filter((track: MusicTrack): boolean => !guids.includes(track.guid));
      this.activeTrackTotal = Math.max(0, this.activeTrackTotal - guids.length);
      this.activeTrackDeclaredTotal = Math.max(0, this.activeTrackDeclaredTotal - guids.length);
      this.activePlaylist.trackCount = Math.max(0, this.activePlaylist.trackCount - guids.length);
      if (this.runtime !== undefined) {
        this.runtime.playlists = this.runtime.playlists.slice();
      }
      this.playlistSelectionMode = false;
      FnToast.show(`已从歌单移除 ${guids.length} 首歌曲`);
    } catch (error) {
      FnToast.show((error as Error).message || '移出歌单失败');
    } finally {
      this.playlistOperationBusy = false;
    }
  }

  private confirmRemovePlaylistTracks(tracks: MusicTrack[]): void {
    if (tracks.length === 0) {
      return;
    }
    this.getUIContext().getPromptAction().showDialog({
      title: '移出歌单',
      message: `确定从「${this.activePlaylist.name}」移出选中的 ${tracks.length} 首歌曲吗？`,
      buttons: [
        { text: '取消', color: $r('app.color.text_secondary') },
        { text: '移出', color: $r('app.color.danger') }
      ]
    }).then((result): void => {
      if (result.index === 1) {
        this.removeActivePlaylistTracks(tracks).catch((): void => {});
      }
    }).catch((): void => {});
  }

  private clearUnavailablePlaylistTracks(): void {
    const unavailable = this.activeTracks.filter((track: MusicTrack): boolean => track.isAudioFileDeleted);
    this.showPlaylistActions = false;
    if (unavailable.length === 0) {
      FnToast.show('当前歌单没有失效歌曲');
      return;
    }
    this.getUIContext().getPromptAction().showDialog({
      title: '清除失效歌曲',
      message: `将从歌单移除 ${unavailable.length} 首已经失效的歌曲，音乐文件不会被删除。`,
      buttons: [
        { text: '取消', color: $r('app.color.text_secondary') },
        { text: '清除', color: $r('app.color.danger') }
      ]
    }).then((result): void => {
      if (result.index === 1) {
        this.removeActivePlaylistTracks(unavailable).catch((): void => {});
      }
    }).catch((): void => {});
  }

  private playTracks(tracks: MusicTrack[], index: number, continuousRoam: boolean = false): void {
    if (tracks.length === 0) {
      FnToast.show('当前列表没有可播放歌曲');
      return;
    }
    const play = continuousRoam ? this.playback.playRoam(tracks, index) : this.playback.playQueue(tracks, index);
    play.catch((): void => {
      FnToast.show('暂时无法播放这首歌曲');
    });
  }

  private sortTracksForPlayback(tracks: MusicTrack[], collectionId: string, sortMode: TrackSortMode,
    playlistSortKey: PlaylistSortKey, playlistSortOrder: PlaylistSortOrder): MusicTrack[] {
    const sorted: MusicTrack[] = tracks.slice();
    if (collectionId === CollectionKind.PLAYLIST) {
      if (playlistSortKey === PlaylistSortKey.TITLE) {
        sorted.sort((left: MusicTrack, right: MusicTrack): number => left.title.localeCompare(right.title));
        return playlistSortOrder === PlaylistSortOrder.ASCENDING ? sorted : sorted.reverse();
      }
      return playlistSortOrder === PlaylistSortOrder.ASCENDING ? sorted.reverse() : sorted;
    }
    if (sortMode === TrackSortMode.TITLE_ASC || sortMode === TrackSortMode.TITLE_DESC) {
      sorted.sort((left: MusicTrack, right: MusicTrack): number => {
        const compare: number = left.title.localeCompare(right.title);
        return sortMode === TrackSortMode.TITLE_ASC ? compare : -compare;
      });
    }
    return sorted;
  }

  private async playAllActiveCollection(sortMode: TrackSortMode, shuffle: boolean): Promise<void> {
    if (this.playAllInProgress) {
      FnToast.show('正在加载全部歌曲，请稍候');
      return;
    }
    const collectionId: string = this.activeCollectionId;
    const loadedTracks: MusicTrack[] = collectionId === CollectionKind.LIBRARY && this.runtime !== undefined ?
      this.runtime.tracks.slice() : this.activeTracks.slice();
    const total: number = collectionId === CollectionKind.LIBRARY && this.runtime !== undefined ?
      this.runtime.trackTotal : this.activeTrackDeclaredTotal;
    const albumGuid: string = this.activeAlbum.guid;
    const artistGuid: string = this.activeArtist.guid;
    const genreGuid: string = this.activeGenre.guid;
    const playlistGuid: string = this.activePlaylist.guid;
    const playlistSortKey: PlaylistSortKey = this.playlistSortKey;
    const playlistSortOrder: PlaylistSortOrder = this.playlistSortOrder;
    this.playAllInProgress = true;
    this.playAllShuffleInProgress = shuffle;
    try {
      let tracks: MusicTrack[] = loadedTracks;
      let continuousRoam: boolean = false;
      if (this.runtime !== undefined) {
        if (collectionId === CollectionKind.FAVORITES) {
          tracks = await AppRuntime.favoriteTracksAll(loadedTracks, total);
        } else if (collectionId === CollectionKind.HISTORY) {
          tracks = await AppRuntime.playHistoryAll(loadedTracks, total);
        } else if (collectionId === CollectionKind.ALBUM) {
          tracks = await AppRuntime.albumTracksAll(albumGuid, loadedTracks, total);
        } else if (collectionId === CollectionKind.ARTIST) {
          tracks = await AppRuntime.artistTracksAll(artistGuid, loadedTracks, total);
        } else if (collectionId === CollectionKind.GENRE) {
          tracks = await AppRuntime.genreTracksAll(genreGuid, loadedTracks, total);
        } else if (collectionId === CollectionKind.PLAYLIST) {
          tracks = await AppRuntime.playlistTracksAll(playlistGuid, loadedTracks, total);
        } else if (collectionId === CollectionKind.ROAM) {
          tracks = await AppRuntime.startRoam();
          continuousRoam = true;
        } else {
          tracks = await AppRuntime.libraryTracksAll(loadedTracks, total);
        }
      }
      const sorted: MusicTrack[] = this.sortTracksForPlayback(
        tracks, collectionId, sortMode, playlistSortKey, playlistSortOrder);
      const startIndex: number = shuffle && sorted.length > 1 ? Math.floor(Math.random() * sorted.length) : 0;
      this.playTracks(sorted, startIndex, continuousRoam);
    } catch (error) {
      FnToast.show((error as Error).message || '全部歌曲加载失败');
    } finally {
      this.playAllInProgress = false;
      this.playAllShuffleInProgress = false;
    }
  }

  private async playAlbum(album: MusicAlbum): Promise<void> {
    try {
      const isActiveAlbum: boolean = this.activeCollectionId === CollectionKind.ALBUM &&
        this.activeAlbum.guid === album.guid;
      const tracks: MusicTrack[] = this.runtime === undefined ?
        this.tracks().filter((track: MusicTrack): boolean =>
          track.albumGuid === album.guid || track.albumName === album.name) :
        await AppRuntime.albumTracksAll(album.guid, isActiveAlbum ? this.activeTracks : [],
          isActiveAlbum ? this.activeTrackDeclaredTotal : album.trackCount);
      this.playTracks(tracks, 0);
    } catch (error) {
      FnToast.show((error as Error).message || '专辑歌曲加载失败');
    }
  }

  private async playCollection(id: string): Promise<void> {
    if (this.runtime === undefined) {
      this.playTracks(this.tracksForCollection(id), 0);
      return;
    }
    try {
      const tracks: MusicTrack[] = id === CollectionKind.FAVORITES ? await AppRuntime.favoriteTracksAll() :
        id === CollectionKind.HISTORY ? await AppRuntime.playHistoryAll() :
          id === CollectionKind.ROAM ? await AppRuntime.startRoam() :
            await AppRuntime.libraryTracksAll(this.runtime.tracks, this.runtime.trackTotal);
      this.playTracks(tracks, 0, id === CollectionKind.ROAM);
    } catch (error) {
      FnToast.show((error as Error).message || '列表加载失败');
    }
  }

  private syncFavoriteState(guid: string, favorite: boolean): void {
    const update = (tracks: MusicTrack[]): MusicTrack[] => {
      tracks.forEach((track: MusicTrack): void => {
        if (track.guid === guid) {
          track.isFavorite = favorite;
        }
      });
      return tracks.slice();
    };
    this.activeTracks = update(this.activeTracks);
    this.searchTracks = update(this.searchTracks);
    this.playerState.queue = update(this.playerState.queue);
    if (this.runtime !== undefined) {
      this.runtime.tracks = update(this.runtime.tracks);
    }
  }

  private setTrackFavorite(track: MusicTrack, favorite: boolean): void {
    if (this.runtime === undefined) {
      this.syncFavoriteState(track.guid, favorite);
      FnToast.show(favorite ? '已收藏' : '已取消收藏');
      return;
    }
    AppRuntime.setFavorite(track, favorite).then((): void => {
      this.syncFavoriteState(track.guid, favorite);
      FnToast.show(favorite ? '已收藏' : '已取消收藏');
    }).catch((error: Error): void => {
      FnToast.show(error.message || '收藏操作失败');
    });
  }

  private async savePlaylist(request: PlaylistEditRequest,
    onStage: (stage: PlaylistSaveStage) => void): Promise<void> {
    let coverId = request.coverId;
    if (this.runtime !== undefined) {
      if (request.coverBytes.length > 0) {
        onStage(PlaylistSaveStage.UPLOADING);
        coverId = await AppRuntime.uploadPlaylistCover(
          request.coverBytes,
          request.coverFileName,
          request.coverMimeType
        );
      }
      onStage(PlaylistSaveStage.SAVING);
      if (this.playlistEditMode === PlaylistEditMode.CREATE) {
        await AppRuntime.createPlaylist(request.name, coverId);
      } else {
        await AppRuntime.editPlaylist(this.activePlaylist, request.name, coverId);
      }
      FnToast.show(this.playlistEditMode === PlaylistEditMode.CREATE ? '歌单已创建' : '歌单已保存');
      return;
    }
    onStage(PlaylistSaveStage.SAVING);
    if (this.playlistEditMode === PlaylistEditMode.CREATE) {
      const playlist: MusicPlaylist = new MusicPlaylist(`local-${this.nextLocalPlaylistId}`, request.name, 0);
      playlist.coverId = coverId;
      this.nextLocalPlaylistId += 1;
      this.workingPlaylists = [playlist].concat(this.workingPlaylists);
    } else {
      this.activePlaylist.name = request.name;
      this.activePlaylist.coverId = coverId;
      this.workingPlaylists = this.workingPlaylists.map((playlist: MusicPlaylist): MusicPlaylist =>
        playlist.guid === this.activePlaylist.guid ? this.activePlaylist : playlist);
    }
    FnToast.show(this.playlistEditMode === PlaylistEditMode.CREATE ? '歌单已创建' : '歌单已保存');
  }

  private async deletePlaylist(): Promise<void> {
    if (this.runtime !== undefined) {
      try {
        await AppRuntime.deletePlaylist(this.activePlaylist);
        this.showPlaylistEditor = false;
        if (this.page === AppShellPage.PLAYLIST_DETAIL) {
          this.playlistSelectionMode = false;
          this.pathStack.pop();
          this.syncPageFromPathStack();
        }
        FnToast.show('歌单已删除');
      } catch (error) {
        FnToast.show((error as Error).message || '歌单删除失败');
      }
      return;
    }
    this.workingPlaylists = this.workingPlaylists.filter((playlist: MusicPlaylist): boolean =>
      playlist.guid !== this.activePlaylist.guid);
    this.showPlaylistEditor = false;
    if (this.page === AppShellPage.PLAYLIST_DETAIL) {
      this.playlistSelectionMode = false;
      this.pathStack.pop();
      this.syncPageFromPathStack();
    }
    FnToast.show('歌单已删除');
  }

  private confirmDeletePlaylist(): void {
    this.getUIContext().getPromptAction().showDialog({
      title: '删除歌单',
      message: `确定删除「${this.activePlaylist.name}」吗？音乐文件不会被删除。`,
      buttons: [
        { text: '取消', color: $r('app.color.text_secondary') },
        { text: '删除', color: $r('app.color.danger') }
      ]
    }).then((result): void => {
      if (result.index === 1) {
        this.deletePlaylist();
      }
    }).catch((): void => {});
  }

  private async handleSearch(request: SearchRequest): Promise<void> {
    if (this.runtime === undefined) {
      return;
    }
    const sequence = ++this.searchSequence;
    this.searchLoading = true;
    this.searchError = '';
    try {
      if (request.kind === 'albums') {
        const values = await AppRuntime.searchAlbums(request.query);
        if (sequence === this.searchSequence) {
          this.searchAlbums = values;
        }
      } else if (request.kind === 'artists') {
        const values = await AppRuntime.searchArtists(request.query);
        if (sequence === this.searchSequence) {
          this.searchArtists = values;
        }
      } else {
        const values = await AppRuntime.searchTracks(request.query);
        if (sequence === this.searchSequence) {
          this.searchTracks = values;
        }
      }
    } catch (error) {
      if (sequence === this.searchSequence) {
        this.searchError = (error as Error).message || '搜索失败，请稍后重试';
      }
    } finally {
      if (sequence === this.searchSequence) {
        this.searchLoading = false;
      }
    }
  }

  private currentUser(): MusicUser {
    if (this.runtime !== undefined) {
      const user: MusicUser = new MusicUser();
      user.name = this.runtime.username;
      user.role = this.runtime.role;
      return user;
    }
    return appSession.user;
  }

  private isConnected(): boolean {
    if (this.runtime !== undefined) {
      return this.runtime.baseUrl.length > 0;
    }
    return appSession.connectionLabel.length > 0;
  }

  public handleBack(): boolean {
    if (this.showSettings || this.showTrackActions || this.showTrackInfo || this.showPlaylistActions ||
      this.showPlaylistSort || this.showPlaylistEditor || this.showPlaylistPicker ||
      this.playlistSelectionMode || this.page !== AppShellPage.ROOT) {
      this.goBack();
      return true;
    }
    return false;
  }

  @Builder
  private appDestination(name: string, _: Object) {
    if (name === AppShellPage.PLAYER) {
      PlayerNavDestination({
        pathStack: this.pathStack,
        safeTop: this.safeTop,
        safeBottom: this.safeBottom,
        albums: this.albums(),
        artists: this.artists(),
        playlists: this.playlists(),
        onBack: (): void => this.goBack(),
        onFavorite: (track: MusicTrack, favorite: boolean): void => {
          this.setTrackFavorite(track, favorite);
        },
        onOpenAlbum: (track: MusicTrack): void => {
          const album = this.albums().find((item: MusicAlbum): boolean =>
            item.guid === track.albumGuid || item.name === track.albumName);
          if (album === undefined) {
            FnToast.show('未找到这首歌曲的专辑');
            return;
          }
          this.minimizePlayer((): void => this.openAlbum(album));
        },
        onOpenArtist: (artist: MusicArtist): void => {
          this.minimizePlayer((): void => this.openArtist(artist));
        },
        onAddPlaylist: (track: MusicTrack, playlist: MusicPlaylist): void => {
          if (this.runtime === undefined) {
            playlist.trackCount += 1;
            FnToast.show(`已加入「${playlist.name}」`);
            return;
          }
          AppRuntime.addTrackToPlaylist(playlist.guid, track.guid).then((): void => {
            playlist.trackCount += 1;
            this.runtime!.playlists = this.runtime!.playlists.slice();
            FnToast.show(`已加入「${playlist.name}」`);
          }).catch((error: Error): void => {
            FnToast.show(error.message || '加入歌单失败');
          });
        },
        onHidden: (): void => {
          this.syncPageFromPathStack();
          this.finishPlayerMinimize();
        },
        onBackPressed: (): boolean => {
          if (this.playback.dismissOverlay()) {
            return true;
          }
          this.minimizePlayer();
          return true;
        },
        onTransitionUnavailable: (): void => {
          this.playerTransitionInProgress = false;
          this.navigationEnabled = true;
        }
      })
    } else {
      HdsNavDestination() {
        if (name === AppShellPage.SEARCH) {
        SearchScreen({
          tracks: this.runtime === undefined ? this.tracks() : this.searchTracks,
          albums: this.runtime === undefined ? this.albums() : this.searchAlbums,
          artists: this.runtime === undefined ? this.artists() : this.searchArtists,
          safeTop: this.safeTop,
          bottomInset: this.bottomAvoidance(),
          loading: this.searchLoading,
          errorMessage: this.searchError,
          onBack: (): void => this.goBack(),
          onSearch: (request: SearchRequest): void => {
            this.handleSearch(request).catch((): void => {});
          },
          onPlay: (tracks: MusicTrack[], index: number): void => this.playTracks(tracks, index),
          onTrackMore: (track: MusicTrack): void => this.showTrackMenu(track),
          onOpenAlbum: (album: MusicAlbum): void => this.openAlbum(album),
          onOpenArtist: (artist: MusicArtist): void => this.openArtist(artist)
        })
      } else if (name === AppShellPage.ALBUMS) {
        AlbumCollectionScreen({
          albums: this.albums(),
          safeTop: this.safeTop,
          bottomInset: this.bottomAvoidance(),
          onBack: (): void => this.goBack(),
          onOpen: (album: MusicAlbum): void => this.openAlbum(album),
          onPlay: (album: MusicAlbum): void => {
            this.playAlbum(album);
          }
        })
      } else if (name === AppShellPage.ARTISTS) {
        ArtistCollectionScreen({
          artists: this.artists(),
          safeTop: this.safeTop,
          bottomInset: this.bottomAvoidance(),
          onBack: (): void => this.goBack(),
          onOpen: (artist: MusicArtist): void => this.openArtist(artist)
        })
      } else if (name === AppShellPage.GENRES) {
        GenreCollectionScreen({
          genres: this.genres(),
          safeTop: this.safeTop,
          bottomInset: this.bottomAvoidance(),
          onBack: (): void => this.goBack(),
          onOpen: (genre: MusicGenre): void => this.openGenre(genre)
        })
      } else {
        TrackListScreen({
          title: this.pageTitle,
          subtitle: this.pageSubtitle,
          collectionId: this.activeCollectionId,
          tracks: this.activeTracks,
          artistAlbums: this.albumsForArtist(this.activeArtist),
          album: this.activeAlbum,
          artist: this.activeArtist,
          genre: this.activeGenre,
          genreVisualIndex: this.activeGenreVisualIndex,
          playlist: this.activePlaylist,
          symbol: this.pageSymbol,
          canRemoveFromPlaylist: name === AppShellPage.PLAYLIST_DETAIL,
          safeTop: this.safeTop,
          bottomInset: this.bottomAvoidance(),
          loading: this.activeTracksLoading,
          errorMessage: this.activeTracksError,
          totalCount: this.activeTrackTotal,
          hasMore: this.activeTracksHasMore,
          loadingMore: this.activeTracksLoadingMore,
          loadMoreError: this.activeTracksLoadMoreError,
          playAllLoading: this.playAllInProgress,
          playAllShuffleLoading: this.playAllShuffleInProgress,
          playlistSortKey: this.playlistSortKey,
          playlistSortOrder: this.playlistSortOrder,
          playlistSelectionMode: this.playlistSelectionMode,
          playlistOperationBusy: this.playlistOperationBusy,
          onBack: (): void => this.goBack(),
          onPlay: (tracks: MusicTrack[], index: number): void => this.playTracks(tracks, index),
          onPlayAll: (sortMode: TrackSortMode, shuffle: boolean): void => {
            this.playAllActiveCollection(sortMode, shuffle).catch((): void => {});
          },
          onLoadMore: (): void => this.loadMoreActiveTracks(),
          onFavorite: (track: MusicTrack, favorite: boolean): void =>
            this.setTrackFavorite(track, favorite),
          onOpenAlbum: (album: MusicAlbum): void => this.openAlbumFromArtist(album),
          onTrackMore: (track: MusicTrack, canRemove: boolean): void => this.showTrackMenu(track, canRemove),
          onRequestPlaylistSort: (): void => {
            this.showPlaylistSort = true;
          },
          onPlaylistSelectionDone: (): void => {
            this.playlistSelectionMode = false;
          },
          onPlaySelected: (tracks: MusicTrack[]): void => {
            this.playTracks(tracks, 0);
          },
          onAddSelectedQueue: (tracks: MusicTrack[]): void => {
            this.appendSelectedTracksToQueue(tracks).catch((): void => {});
          },
          onRemoveSelected: (tracks: MusicTrack[]): void => {
            this.confirmRemovePlaylistTracks(tracks);
          },
          onPageMore: (): void => {
            if (name === AppShellPage.PLAYLIST_DETAIL) {
              this.showPlaylistActions = true;
            } else {
              FnToast.development();
            }
          }
        })
        }
      }
      .backgroundColor(Color.Transparent)
      .titleMode(HdsNavDestinationTitleMode.MINI)
      .hideTitleBar(true)
      .hideToolBar(true)
      .onHidden((): void => {
        this.syncPageFromPathStack();
      })
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
    HdsNavigation(this.pathStack) {
      Stack({ alignContent: Alignment.Bottom }) {
      if (this.libraryUnavailable()) {
        Column({ space: FnMusicUI.contentGap }) {
          if (this.runtime?.loadingLibrary) {
            LoadingProgress()
              .width(32)
              .height(32)
              .color($r('app.color.accent'))
            Text('正在加载音乐库')
              .fontSize(FnMusicUI.bodySize)
              .fontColor($r('app.color.text_secondary'))
          } else {
            EmptyMusicState({
              kind: MusicEmptyKind.LOAD_FAILED,
              title: '音乐库加载失败',
              message: this.runtime?.libraryError ?? '暂时无法读取服务器音乐库',
              actionTitle: '重新加载',
              onAction: (): void => {
                AppRuntime.loadLibrary().catch((): void => {});
              }
            })
          }
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        this.rootTabs()
      }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_background'))
    }
    .titleMode(HdsNavigationTitleMode.MINI)
    .titleBar(this.navigationTitleBar())
    .hideTitleBar(this.page === AppShellPage.ROOT && this.rootTab === RootTab.HOME && this.homeSectionPinned)
    .hideToolBar(true)
    .hideBackButton(true)
    .bindToScrollable([this.homeScroller])
    .navDestination(this.appDestination)
    .enabled(this.navigationEnabled)
    .customNavContentTransition((from: NavContentInfo, to: NavContentInfo,
      operation: NavigationOperation): NavigationAnimatedTransition | undefined => {
      return ezCustomTransition.customNavContentTransition(from, to, operation, {
        onTransitionStart: (): void => {
          this.navigationEnabled = false;
        },
        onTransitionEnd: (): void => {
          this.navigationEnabled = true;
        }
      });
    })
    .width('100%')
    .height('100%')

      if (this.hasPlayer() && !this.sheetVisible() &&
        (this.page !== AppShellPage.ROOT || this.rootTab !== RootTab.HOME)) {
        MiniPlayerBar({
          state: this.playerState,
          placement: this.miniPlayerPlacement(),
          transitionId: FLOATING_PLAYER_TRANSITION_ID,
          onExpand: (): void => this.openPlayer(),
          onToggle: (): void => {
            this.playback.toggle().catch((): void => {});
          },
          onNext: (): void => {
            this.playback.next().catch((): void => {});
          },
          onQueue: (): void => this.openPlayerQueue()
        })
        .width('calc(100% - 32vp)')
        .height(FnMusicUI.miniPlayerHeight)
        .constraintSize({ maxWidth: 720 })
        .margin({
          bottom: this.miniPlayerBottom()
        })
        .alignSelf(ItemAlign.Center)
        .zIndex(this.page === AppShellPage.PLAYER ? -1 : 100)
      }

      if (this.playerState.queueVisible && this.page !== AppShellPage.PLAYER) {
        PlaybackQueueSheet({
          state: this.playerState,
          safeBottom: this.safeBottom,
          onClose: (): void => this.playback.hideQueue(),
          onSelect: (index: number): void => {
            this.playback.playAt(index).catch((): void => {});
          },
          onRemove: (index: number): void => {
            this.playback.removeQueueItem(index).catch((): void => {});
          },
          onClear: (): void => {
            this.playback.clearQueue().catch((): void => {});
          },
          onRepeat: (): void => this.playback.cycleRepeatMode()
        })
        .zIndex(300)
      }

      if (this.showSettings) {
        SettingsSheet({
          connected: this.isConnected(),
          preferences: this.preferences,
          onClose: (): void => {
            this.showSettings = false;
          },
          onLibraryManagement: (): void => FnToast.development(),
          onUserManagement: (): void => FnToast.development(),
          onSystemAppearance: (): void => FnToast.show('当前已跟随系统深浅色'),
          onMotionChanged: (enabled: boolean): void => {
            MusicPreferenceStore.setMotionEnabled(enabled);
            FnToast.show(enabled ? '已开启动画效果' : '已关闭动画效果');
          },
          onAutoContinueChanged: (enabled: boolean): void => {
            MusicPreferenceStore.setAutoContinueEnabled(enabled);
            FnToast.show(enabled ? '已开启自动续播' : '已关闭自动续播');
          },
          onLyricsChanged: (enabled: boolean): void => {
            MusicPreferenceStore.setLyricsEnabled(enabled);
            FnToast.show(enabled ? '已开启歌词显示' : '已关闭歌词显示');
          },
          onReconnect: (): void => {
            AppRuntime.retry().then((connected: boolean): void => {
              FnToast.show(connected ? '已重新连接服务器' : '暂时无法连接服务器');
            }).catch((error: Error): void => {
              FnToast.show(error.message || '服务器探测失败');
            });
          }
        })
      }

      if (this.showTrackActions) {
        TrackActionsSheet({
          track: this.activeTrack,
          canRemoveFromPlaylist: this.canRemoveActiveTrack,
          onClose: (): void => {
            this.showTrackActions = false;
          },
          onPlay: (): void => {
            this.showTrackActions = false;
            this.playTracks([this.activeTrack], 0);
          },
          onPlayNext: (): void => {
            this.showTrackActions = false;
            this.playback.playNext(this.activeTrack).then((): void => {
              FnToast.show('已设为下一首播放');
            }).catch((): void => {
              FnToast.show('暂时无法调整播放队列');
            });
          },
          onAddQueue: (): void => {
            this.showTrackActions = false;
            this.playback.appendToQueue(this.activeTrack).then((): void => {
              FnToast.show('已加入播放队列');
            }).catch((): void => {
              FnToast.show('暂时无法调整播放队列');
            });
          },
          onFavorite: (): void => {
            const favorite = !this.activeTrack.isFavorite;
            if (this.runtime === undefined) {
              this.activeTrack.isFavorite = favorite;
              this.showTrackActions = false;
              FnToast.show(favorite ? '已收藏' : '已取消收藏');
              return;
            }
            AppRuntime.setFavorite(this.activeTrack, favorite).then((): void => {
              this.syncFavoriteState(this.activeTrack.guid, favorite);
              this.showTrackActions = false;
              FnToast.show(favorite ? '已收藏' : '已取消收藏');
            }).catch((error: Error): void => {
              FnToast.show(error.message || '收藏操作失败');
            });
          },
          onAddPlaylist: (): void => {
            this.showTrackActions = false;
            if (this.playlists().length === 0) {
              FnToast.show('请先创建歌单');
              return;
            }
            this.showPlaylistPicker = true;
          },
          onOpenAlbum: (): void => {
            this.showTrackActions = false;
            const album: MusicAlbum | undefined = this.albums().find((item: MusicAlbum): boolean =>
              item.guid === this.activeTrack.albumGuid || item.name === this.activeTrack.albumName);
            if (album !== undefined) {
              this.openAlbum(album);
            } else {
              FnToast.show('未找到这首歌曲的专辑');
            }
          },
          onOpenArtist: (): void => {
            this.showTrackActions = false;
            const artist: MusicArtist | undefined = this.artists().find((item: MusicArtist): boolean =>
              item.guid === this.activeTrack.artistGuid || item.name === this.activeTrack.artistName);
            if (artist !== undefined) {
              this.openArtist(artist);
            } else {
              FnToast.show('未找到这首歌曲的歌手');
            }
          },
          onRemove: (): void => {
            if (this.runtime === undefined) {
              this.activeTracks = this.activeTracks.filter((track: MusicTrack): boolean =>
                track.guid !== this.activeTrack.guid);
              this.showTrackActions = false;
              FnToast.show('已从歌单移除');
              return;
            }
            AppRuntime.removeTrackFromPlaylist(this.activePlaylist.guid, this.activeTrack.guid).then((): void => {
              this.activeTracks = this.activeTracks.filter((track: MusicTrack): boolean =>
                track.guid !== this.activeTrack.guid);
              this.activeTrackTotal = Math.max(0, this.activeTrackTotal - 1);
              this.activeTrackDeclaredTotal = Math.max(0, this.activeTrackDeclaredTotal - 1);
              this.activePlaylist.trackCount = Math.max(0, this.activePlaylist.trackCount - 1);
              if (this.runtime !== undefined) {
                this.runtime.playlists = this.runtime.playlists.slice();
              }
              this.showTrackActions = false;
              FnToast.show('已从歌单移除');
            }).catch((error: Error): void => {
              FnToast.show(error.message || '移出歌单失败');
            });
          },
          onInfo: (): void => {
            this.showTrackActions = false;
            this.showTrackInfoSheet(this.activeTrack);
          }
        })
      }

      if (this.showTrackInfo) {
        TrackInfoSheet({
          track: this.trackInfoTrack,
          onClose: (): void => {
            this.showTrackInfo = false;
          }
        })
        .zIndex(52)
      }

      if (this.showPlaylistSort) {
        PlaylistSortSheet({
          sortKey: this.playlistSortKey,
          sortOrder: this.playlistSortOrder,
          onClose: (): void => {
            this.showPlaylistSort = false;
          },
          onSortKey: (key: PlaylistSortKey): void => {
            this.playlistSortKey = key;
          },
          onSortOrder: (order: PlaylistSortOrder): void => {
            this.playlistSortOrder = order;
          }
        })
        .zIndex(52)
      }

      if (this.showPlaylistActions) {
        PlaylistActionsSheet({
          onClose: (): void => {
            this.showPlaylistActions = false;
          },
          onMultiSelect: (): void => {
            this.showPlaylistActions = false;
            if (this.activeTracks.length === 0) {
              FnToast.show('当前歌单还没有歌曲');
              return;
            }
            this.playlistSelectionMode = true;
          },
          onClearUnavailable: (): void => this.clearUnavailablePlaylistTracks(),
          onEdit: (): void => {
            this.showPlaylistActions = false;
            this.playlistEditMode = PlaylistEditMode.EDIT;
            this.showPlaylistEditor = true;
          },
          onDelete: (): void => {
            this.showPlaylistActions = false;
            this.confirmDeletePlaylist();
          }
        })
        .zIndex(52)
      }

      if (this.showPlaylistPicker) {
        Stack({ alignContent: Alignment.Bottom }) {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor($r('app.color.scrim'))
            .onClick((): void => {
              this.showPlaylistPicker = false;
            })

          Column({ space: FnMusicUI.compactGap }) {
            Row() {
              Text('加入歌单')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
              Blank()
              Button({ type: ButtonType.Circle }) {
                SymbolGlyph($r('sys.symbol.xmark'))
                  .fontSize(20)
                  .fontColor([$r('app.color.text_primary')])
              }
              .width(FnMusicUI.tapTarget)
              .height(FnMusicUI.tapTarget)
              .backgroundColor($r('app.color.surface_secondary'))
              .onClick((): void => {
                this.showPlaylistPicker = false;
              })
            }
            .width('100%')

            Scroll() {
              Column() {
                Repeat<MusicPlaylist>(this.playlists())
                  .each((repeatItem: RepeatItem<MusicPlaylist>): void => {
                    Row({ space: FnMusicUI.contentGap }) {
                      SymbolGlyph($r('sys.symbol.music_note_list'))
                        .fontSize(20)
                        .fontColor([$r('app.color.accent')])
                      Column({ space: 3 }) {
                        Text(repeatItem.item.name)
                          .fontSize(FnMusicUI.bodySize)
                          .fontColor($r('app.color.text_primary'))
                          .maxLines(1)
                        Text(`${repeatItem.item.trackCount} 首歌曲`)
                          .fontSize(FnMusicUI.supportingSize)
                          .fontColor($r('app.color.text_secondary'))
                      }
                      .layoutWeight(1)
                      .alignItems(HorizontalAlign.Start)
                      SymbolGlyph($r('sys.symbol.chevron_forward'))
                        .fontSize(16)
                        .fontColor([$r('app.color.text_secondary')])
                    }
                    .width('100%')
                    .height(FnMusicUI.listRowHeight)
                    .padding({ left: 10, right: 10 })
                    .onClick((): void => {
                      if (this.runtime === undefined) {
                        this.showPlaylistPicker = false;
                        FnToast.show('已加入歌单');
                        return;
                      }
                      AppRuntime.addTrackToPlaylist(repeatItem.item.guid, this.activeTrack.guid).then((): void => {
                        repeatItem.item.trackCount += 1;
                        if (this.runtime !== undefined) {
                          this.runtime.playlists = this.runtime.playlists.slice();
                        }
                        this.showPlaylistPicker = false;
                        FnToast.show(`已加入「${repeatItem.item.name}」`);
                      }).catch((error: Error): void => {
                        FnToast.show(error.message || '加入歌单失败');
                      });
                    })
                  })
                  .key((item: MusicPlaylist): string => item.guid)
              }
            }
            .height(Math.min(320, Math.max(FnMusicUI.listRowHeight, this.playlists().length * FnMusicUI.listRowHeight)))
            .scrollBar(BarState.Off)
          }
          .width('100%')
          .padding({ left: 10, right: 10, top: 14, bottom: 24 })
          .borderRadius({ topLeft: FnMusicUI.cardRadius, topRight: FnMusicUI.cardRadius })
          .backgroundColor($r('app.color.surface_elevated'))
          .transition(TransitionEffect.translate({ y: 72 }).combine(TransitionEffect.OPACITY))
        }
        .width('100%')
        .height('100%')
        .zIndex(51)
      }

      if (this.showPlaylistEditor) {
        PlaylistEditSheet({
          mode: this.playlistEditMode,
          playlist: this.activePlaylist,
          onClose: (): void => {
            this.showPlaylistEditor = false;
          },
          onSave: (request: PlaylistEditRequest,
            onStage: (stage: PlaylistSaveStage) => void): Promise<void> => {
            return this.savePlaylist(request, onStage);
          },
          onDelete: (): void => {
            this.confirmDeletePlaylist();
          }
        })
      }
      }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
    .zIndex(this.sheetVisible() ? 200 : 0)
    }
  }
