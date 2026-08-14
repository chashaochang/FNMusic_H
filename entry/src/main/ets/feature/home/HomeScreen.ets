import { FnMusicUI } from '../../design/FnMusicUI';
import { FnMusicMaterialRole, FnMusicMaterials } from '../../design/FnMusicMaterials';
import { AuthPhase } from '../../auth/ConnectionModels';
import { AppRuntime, AppRuntimeState } from '../../common/AppRuntime';
import {
  LibrarySection,
  MusicAlbum,
  MusicArtist,
  MusicGenre,
  MusicTrack
} from '../../model/MusicModels';
import {
  AlbumRow,
  ArtistRow,
  EmptyMusicState,
  GenreRow,
  MusicArtwork,
  MusicChipItem,
  MusicChipStrip,
  SectionHeader,
  TrackRow
} from '../common/MusicUiComponents';

export interface HomeFeatureCardData {
  id: string;
  title: string;
}

@ObservedV2
class StickySectionState {
  @Trace pinned: boolean = false;
  @Trace selectedId: string = LibrarySection.RECENTLY_ADDED;
}

@ComponentV2
struct HomeStickyChipHeader {
  @Param items: MusicChipItem[] = [];
  @Param state: StickySectionState = new StickySectionState();
  @Param stickyTopInset: number = 0;
  @Event onSelect: (id: string) => void = (_: string): void => {};
  @Event onOpenSearch: () => void = (): void => {};
  @Event onPositionChange: (globalY: number) => void = (_: number): void => {};

  build() {
    Row({ space: 8 }) {
      MusicChipStrip({
        items: this.items,
        selectedId: this.state.selectedId,
        onSelect: (id: string): void => {
          this.onSelect(id);
        }
      })
      .layoutWeight(1)

      if (this.state.pinned) {
        Button({ type: ButtonType.Circle, stateEffect: false }) {
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontSize(24)
            .fontColor([$r('app.color.text_primary')])
        }
        .width(40)
        .height(40)
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .backgroundColor(Color.Transparent)
        .systemMaterial(FnMusicMaterials.material(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
        .accessibilityText('搜索')
        .onClick((): void => this.onOpenSearch())
      }
    }
    .width('100%')
    .height(this.state.pinned ? this.stickyTopInset + FnMusicUI.homeActionBarHeight :
      FnMusicUI.chipHeight + FnMusicUI.contentGap)
    .padding({
      left: FnMusicUI.pagePadding,
      right: FnMusicUI.pagePadding,
      top: this.state.pinned ? this.stickyTopInset : 0
    })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.Transparent)
    .hitTestBehavior(HitTestMode.Transparent)
    .onAreaChange((_: Area, area: Area): void => {
      this.onPositionChange(area.globalPosition.y as number);
    })
  }
}

@ComponentV2
struct HomeSearchEntry {
  @Event onOpen: () => void = (): void => {};
  @Event onPositionChange: (globalY: number, height: number) => void = (_: number, __: number): void => {};

  build() {
    Row({ space: 10 }) {
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(19)
        .fontColor([$r('app.color.text_secondary')])
      Text('搜索歌曲、专辑或歌手')
        .layoutWeight(1)
        .fontSize(FnMusicUI.bodySize)
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
      SymbolGlyph($r('sys.symbol.arrow_right'))
        .fontSize(17)
        .fontColor([$r('app.color.text_secondary')])
    }
    .width('100%')
    .height(FnMusicUI.searchHeight)
    .padding({ left: 15, right: 15 })
    .borderRadius(FnMusicUI.searchHeight / 2)
    .clip(true)
    .backgroundColor(Color.Transparent)
    .systemMaterial(FnMusicMaterials.material(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
    .onAreaChange((_: Area, area: Area): void => {
      this.onPositionChange(area.globalPosition.y as number, area.height as number);
    })
    .onClick((): void => {
      this.onOpen();
    })
  }
}

@ComponentV2
struct HomeFeatureCardBackground {
  @Param cardId: string = '';
  @Local motion: boolean = false;
  private motionTimer: number = -1;

  aboutToAppear(): void {
    const delay = this.cardId === 'favorites' ? 40 : this.cardId === 'history' ? 180 : 320;
    this.motionTimer = setTimeout((): void => {
      this.motion = true;
    }, delay);
  }

  aboutToDisappear(): void {
    if (this.motionTimer >= 0) {
      clearTimeout(this.motionTimer);
      this.motionTimer = -1;
    }
  }

  build() {
    Stack() {
      if (this.cardId === 'roam') {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 90,
            colors: [
              [$r('app.color.home_card_roam_start'), 0],
              [$r('app.color.home_card_roam_middle'), 0.62],
              [$r('app.color.home_card_roam_end'), 1]
            ]
          })
        Image($r('app.media.home_roam_background'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .hitTestBehavior(HitTestMode.None)
      } else if (this.cardId === 'favorites') {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 112,
            colors: [
              [$r('app.color.home_card_favorite_start'), 0],
              [$r('app.color.home_card_favorite_middle'), 0.54],
              [$r('app.color.home_card_favorite_end'), 1]
            ]
          })
        Column()
          .width(156)
          .height(138)
          .radialGradient({
            center: ['50%', '50%'],
            radius: '50%',
            colors: [
              [$r('app.color.home_card_favorite_glow'), 0],
              [$r('app.color.transparent'), 1]
            ]
          })
          .blur(28)
          .translate({ x: this.motion ? 78 : -58, y: this.motion ? 18 : 88 })
          .animation({
            duration: 2000,
            tempo: 0.42,
            curve: Curve.EaseInOut,
            iterations: -1,
            playMode: PlayMode.Alternate
          })
        Column()
          .width(152)
          .height(132)
          .radialGradient({
            center: ['50%', '50%'],
            radius: '50%',
            colors: [
              [$r('app.color.home_card_album_pink'), 0],
              [$r('app.color.transparent'), 1]
            ]
          })
          .blur(30)
          .translate({ x: this.motion ? -28 : 94, y: this.motion ? 78 : -20 })
          .animation({
            duration: 2000,
            tempo: 0.36,
            curve: Curve.EaseInOut,
            iterations: -1,
            playMode: PlayMode.Alternate
          })
      } else if (this.cardId === 'history') {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 90,
            colors: [
              [$r('app.color.home_card_history_start'), 0],
              [$r('app.color.home_card_history_middle'), 0.54],
              [$r('app.color.home_card_history_end'), 1]
            ]
          })
        Column()
          .width(124)
          .height(226)
          .radialGradient({
            center: ['50%', '50%'],
            radius: '50%',
            colors: [
              [$r('app.color.home_card_history_shadow'), 0],
              [$r('app.color.transparent'), 1]
            ]
          })
          .blur(28)
          .translate({ x: this.motion ? -38 : 104, y: this.motion ? -10 : -42 })
          .animation({
            duration: 2000,
            tempo: 0.4,
            curve: Curve.EaseInOut,
            iterations: -1,
            playMode: PlayMode.Alternate
          })
        Column()
          .width(148)
          .height(150)
          .radialGradient({
            center: ['50%', '50%'],
            radius: '50%',
            colors: [
              [$r('app.color.home_card_history_icon'), 0],
              [$r('app.color.transparent'), 1]
            ]
          })
          .blur(32)
          .opacity(0.56)
          .translate({ x: this.motion ? 90 : -36, y: this.motion ? 42 : 82 })
          .animation({
            duration: 2000,
            tempo: 0.34,
            curve: Curve.EaseInOut,
            iterations: -1,
            playMode: PlayMode.Alternate
          })
      } else {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 90,
            colors: [
              [$r('app.color.home_card_recent_start'), 0],
              [$r('app.color.home_card_recent_middle'), 0.48],
              [$r('app.color.home_card_recent_end'), 1]
            ]
          })
        Column()
          .width(148)
          .height(226)
          .radialGradient({
            center: ['50%', '50%'],
            radius: '50%',
            colors: [
              [$r('app.color.home_card_recent_shadow'), 0],
              [$r('app.color.transparent'), 1]
            ]
          })
          .blur(30)
          .translate({ x: this.motion ? 94 : -42, y: this.motion ? -28 : 12 })
          .animation({
            duration: 2000,
            tempo: 0.38,
            curve: Curve.EaseInOut,
            iterations: -1,
            playMode: PlayMode.Alternate
          })
        Column()
          .width(142)
          .height(170)
          .radialGradient({
            center: ['50%', '50%'],
            radius: '50%',
            colors: [
              [$r('app.color.home_card_foreground'), 0],
              [$r('app.color.transparent'), 1]
            ]
          })
          .blur(34)
          .opacity(0.48)
          .translate({ x: this.motion ? -24 : 104, y: this.motion ? 70 : -24 })
          .animation({
            duration: 2000,
            tempo: 0.32,
            curve: Curve.EaseInOut,
            iterations: -1,
            playMode: PlayMode.Alternate
          })
      }
    }
    .width('100%')
    .height('100%')
    .borderRadius(FnMusicUI.homeFeatureCardRadius)
    .clip(true)
    .hitTestBehavior(HitTestMode.None)
  }
}

@ComponentV2
struct HomeRoamCardArtwork {
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($r('app.media.home_roam_record'))
        .width(110.5)
        .height(110.5)
        .objectFit(ImageFit.Contain)
        .translate({ x: 55.6, y: 14.2 })

      Image($r('app.media.home_roam_cover'))
        .width(141.7)
        .height(141.7)
        .objectFit(ImageFit.Cover)
        .borderRadius(10)
        .clip(true)
    }
    .width(168.6)
    .height(141.7)
    .rotate({ angle: -2 })
    .translate({ x: 15.8, y: -6.1 })
    .hitTestBehavior(HitTestMode.None)
  }
}

@ComponentV2
struct HomeFeatureCard {
  @Param data: HomeFeatureCardData = {
    id: '',
    title: ''
  };
  @Event onPlay: (id: string) => void = (_: string): void => {};

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      HomeFeatureCardBackground({ cardId: this.data.id })

      if (this.data.id === 'roam') {
        Stack({ alignContent: Alignment.TopStart }) {
          HomeRoamCardArtwork()
        }
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.None)
      } else {
        Stack({ alignContent: Alignment.Center }) {
          Image(this.data.id === 'favorites' ? $r('app.media.home_favorite_icon') :
            this.data.id === 'history' ? $r('app.media.home_history_icon') : $r('app.media.home_recent_icon'))
            .width(68.5)
            .height(68.5)
            .objectFit(ImageFit.Contain)
            .translate({ y: -15.2 })
        }
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.None)
      }

      Row({ space: 6 }) {
        if (this.data.id === 'roam') {
          Image($r('app.media.home_roam_signal'))
            .width(21)
            .height(21)
            .objectFit(ImageFit.Contain)
        }
        Text(this.data.title)
          .fontSize(FnMusicUI.bodySize)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.home_card_foreground'))
          .maxLines(1)

        Blank()

        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Image($r('app.media.home_card_play'))
            .width(16)
            .height(16)
            .objectFit(ImageFit.Contain)
        }
        .width(34)
        .height(34)
        .backgroundColor($r('app.color.home_card_play_surface'))
        .accessibilityText(`播放${this.data.title}`)
        .onTouch((event: TouchEvent): void => {
          event.stopPropagation();
        })
        .onClick((): void => {
          this.onPlay(this.data.id);
        })
      }
      .width('100%')
      .height(54)
      .padding({ left: 14, right: 12, bottom: 10 })
      .alignItems(VerticalAlign.Center)
    }
    .width(FnMusicUI.homeFeatureCardWidth)
    .height(FnMusicUI.homeFeatureCardHeight)
    .borderRadius(FnMusicUI.homeFeatureCardRadius)
  }
}

@ComponentV2
struct HomeTrackPreview {
  @Param tracks: MusicTrack[] = [];
  @Param title: string = '最近加入';
  @Param supporting: string = '按添加时间排序';
  @Param framed: boolean = true;
  @Param showAllAction: boolean = true;
  @Event onPlayTrack: (tracks: MusicTrack[], index: number) => void = (_: MusicTrack[], __: number): void => {};
  @Event onMore: (track: MusicTrack) => void = (_: MusicTrack): void => {};
  @Event onOpenAll: () => void = (): void => {};

  build() {
    Column({ space: this.framed ? 4 : FnMusicUI.contentGap }) {
      SectionHeader({
        title: this.title,
        supporting: this.supporting,
        actionTitle: this.showAllAction ? '全部' : '',
        onAction: (): void => {
          this.onOpenAll();
        }
      })
      if (this.tracks.length === 0) {
        EmptyMusicState({
          title: '还没有歌曲',
          message: '服务器音乐库中的歌曲会显示在这里。',
          symbol: $r('sys.symbol.music_note_list')
        })
      } else {
        Column({ space: this.framed ? 0 : FnMusicUI.homeTrackRowGap }) {
          Repeat<MusicTrack>(this.tracks.slice(0, 6))
            .each((repeatItem: RepeatItem<MusicTrack>): void => {
              TrackRow({
                track: repeatItem.item,
                index: repeatItem.index,
                onPlay: (index: number): void => {
                  this.onPlayTrack(this.tracks, index);
                },
                onMore: (track: MusicTrack): void => {
                  this.onMore(track);
                }
              })
            })
            .key((item: MusicTrack): string => item.guid)
        }
        .width('100%')
        .padding(this.framed ? { left: 10, right: 8, top: 2, bottom: 2 } :
          { left: 0, right: 0, top: 0, bottom: 0 })
        .borderRadius(this.framed ? FnMusicUI.cardRadius : 0)
        .backgroundColor(this.framed ? $r('app.color.surface') : Color.Transparent)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

@ComponentV2
struct HomeRecentAlbumTile {
  @Param album: MusicAlbum = new MusicAlbum();
  @Event onOpen: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};
  @Event onPlay: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};

  build() {
    Column({ space: 6 }) {
      Stack({ alignContent: Alignment.BottomEnd }) {
        MusicArtwork({
          artworkSize: 132,
          radius: FnMusicUI.controlRadius,
          coverId: this.album.coverId,
          updatedAt: this.album.createdAt,
          placeholderMedia: $r('app.media.home_album_placeholder')
        })
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Image($r('app.media.home_card_play'))
            .width(16)
            .height(16)
            .objectFit(ImageFit.Contain)
        }
        .width(34)
        .height(34)
        .backgroundColor($r('app.color.home_card_play_surface'))
        .translate({ x: -8, y: -8 })
        .accessibilityText(`播放专辑${this.album.name}`)
        .onTouch((event: TouchEvent): void => {
          event.stopPropagation();
        })
        .onClick((): void => this.onPlay(this.album))
      }
      .width(132)
      .height(132)
      Text(this.album.name)
        .width('100%')
        .fontSize(FnMusicUI.bodySize)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(this.album.artistName.length > 0 ? this.album.artistName : `${this.album.trackCount} 首歌曲`)
        .width('100%')
        .fontSize(FnMusicUI.supportingSize)
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width(132)
    .alignItems(HorizontalAlign.Start)
    .onClick((): void => this.onOpen(this.album))
  }
}

@ComponentV2
struct HomeRecentAlbumPreview {
  @Param albums: MusicAlbum[] = [];
  @Event onOpen: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};
  @Event onPlay: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};

  build() {
    Column({ space: FnMusicUI.contentGap }) {
      SectionHeader({ title: '最近添加专辑' })
      if (this.albums.length === 0) {
        EmptyMusicState({ title: '还没有专辑', message: '最近添加的专辑会显示在这里。' })
      } else {
        List({ space: FnMusicUI.contentGap }) {
          Repeat<MusicAlbum>(this.albums.slice(0, 10))
            .each((repeatItem: RepeatItem<MusicAlbum>): void => {
              ListItem() {
                HomeRecentAlbumTile({
                  album: repeatItem.item,
                  onOpen: (album: MusicAlbum): void => this.onOpen(album),
                  onPlay: (album: MusicAlbum): void => this.onPlay(album)
                })
              }
            })
            .key((item: MusicAlbum): string => item.guid)
        }
        .listDirection(Axis.Horizontal)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .width('100%')
        .height(184)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

@ComponentV2
struct HomeAlbumPreview {
  @Param albums: MusicAlbum[] = [];
  @Param title: string = '专辑';
  @Param supporting: string = '';
  @Param maxItems: number = 6;
  @Param showAllAction: boolean = false;
  @Event onOpen: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};
  @Event onOpenAll: () => void = (): void => {};

  build() {
    Column({ space: 4 }) {
      SectionHeader({
        title: this.title,
        supporting: this.supporting.length > 0 ? this.supporting : `${this.albums.length} 张专辑`,
        actionTitle: this.showAllAction ? '全部' : '',
        onAction: (): void => this.onOpenAll()
      })
      if (this.albums.length === 0) {
        EmptyMusicState({ title: '还没有专辑', message: '专辑数据同步后会显示在这里。' })
      } else {
        Column() {
          Repeat<MusicAlbum>(this.albums.slice(0, this.maxItems))
            .each((repeatItem: RepeatItem<MusicAlbum>): void => {
              AlbumRow({
                album: repeatItem.item,
                onOpen: (album: MusicAlbum): void => {
                  this.onOpen(album);
                }
              })
            })
            .key((item: MusicAlbum): string => item.guid)
        }
        .width('100%')
        .padding({ left: 10, right: 10 })
        .borderRadius(FnMusicUI.cardRadius)
        .backgroundColor($r('app.color.surface'))
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

@ComponentV2
struct HomeArtistPreview {
  @Param artists: MusicArtist[] = [];
  @Param supporting: string = '';
  @Param maxItems: number = 6;
  @Event onOpen: (artist: MusicArtist) => void = (_: MusicArtist): void => {};

  build() {
    Column({ space: 4 }) {
      SectionHeader({
        title: '歌手',
        supporting: this.supporting.length > 0 ? this.supporting : `${this.artists.length} 位歌手`
      })
      if (this.artists.length === 0) {
        EmptyMusicState({ title: '还没有歌手', message: '歌手数据同步后会显示在这里。', symbol: $r('sys.symbol.person_fill') })
      } else {
        Column() {
          Repeat<MusicArtist>(this.artists.slice(0, this.maxItems))
            .each((repeatItem: RepeatItem<MusicArtist>): void => {
              ArtistRow({
                artist: repeatItem.item,
                onOpen: (artist: MusicArtist): void => {
                  this.onOpen(artist);
                }
              })
            })
            .key((item: MusicArtist): string => item.guid)
        }
        .width('100%')
        .padding({ left: 10, right: 10 })
        .borderRadius(FnMusicUI.cardRadius)
        .backgroundColor($r('app.color.surface'))
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

@ComponentV2
struct HomeGenrePreview {
  @Param genres: MusicGenre[] = [];
  @Param supporting: string = '';
  @Param maxItems: number = 6;
  @Event onOpen: (genre: MusicGenre) => void = (_: MusicGenre): void => {};

  build() {
    Column({ space: 4 }) {
      SectionHeader({
        title: '风格',
        supporting: this.supporting.length > 0 ? this.supporting : `${this.genres.length} 种风格`
      })
      if (this.genres.length === 0) {
        EmptyMusicState({ title: '还没有风格', message: '风格数据同步后会显示在这里。', symbol: $r('sys.symbol.music_badge_wave_2') })
      } else {
        Column() {
          Repeat<MusicGenre>(this.genres.slice(0, this.maxItems))
            .each((repeatItem: RepeatItem<MusicGenre>): void => {
              GenreRow({
                genre: repeatItem.item,
                onOpen: (genre: MusicGenre): void => {
                  this.onOpen(genre);
                }
              })
            })
            .key((item: MusicGenre): string => item.guid)
        }
        .width('100%')
        .padding({ left: 10, right: 10 })
        .borderRadius(FnMusicUI.cardRadius)
        .backgroundColor($r('app.color.surface'))
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

@ComponentV2
export struct HomeScreen {
  @Param tracks: MusicTrack[] = [];
  @Param albums: MusicAlbum[] = [];
  @Param artists: MusicArtist[] = [];
  @Param genres: MusicGenre[] = [];
  @Param bottomInset: number = 0;
  @Param stickyTopInset: number = 0;
  @Param pageScroller: Scroller = new Scroller();
  @Local sectionState: StickySectionState = new StickySectionState();
  @Local runtimeState: AppRuntimeState = AppRuntime.state();
  @Local searchCollapsed: boolean = false;
  @Event onPinnedChange: (pinned: boolean) => void = (_: boolean): void => {};
  @Event onSearchCollapsedChange: (collapsed: boolean) => void = (_: boolean): void => {};
  @Event onChromeProgress: (progress: number) => void = (_: number): void => {};
  @Event onOpenSearch: () => void = (): void => {};
  @Event onOpenCollection: (id: string, title: string) => void = (_: string, __: string): void => {};
  @Event onPlayCollection: (id: string) => void = (_: string): void => {};
  @Event onOpenSection: (id: string) => void = (_: string): void => {};
  @Event onOpenAlbum: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};
  @Event onPlayAlbum: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};
  @Event onOpenArtist: (artist: MusicArtist) => void = (_: MusicArtist): void => {};
  @Event onOpenGenre: (genre: MusicGenre) => void = (_: MusicGenre): void => {};
  @Event onPlayTracks: (tracks: MusicTrack[], index: number) => void = (_: MusicTrack[], __: number): void => {};
  @Event onTrackMore: (track: MusicTrack) => void = (_: MusicTrack): void => {};

  private readonly featureCards: HomeFeatureCardData[] = [
    { id: 'roam', title: '漫游' },
    { id: 'favorites', title: '收藏' },
    { id: 'history', title: '最近播放' },
    { id: 'recently_added', title: '最近添加' }
  ];

  private readonly sections: MusicChipItem[] = [
    { id: LibrarySection.RECENTLY_ADDED, title: '最近添加' },
    { id: LibrarySection.ALBUMS, title: '专辑' },
    { id: LibrarySection.ARTISTS, title: '歌手' },
    { id: LibrarySection.GENRES, title: '风格' },
    { id: LibrarySection.LIBRARY, title: '音乐库' }
  ];

  private hasRuntimeCatalog(): boolean {
    return this.runtimeState.phase === AuthPhase.AUTHENTICATED;
  }

  private recentAlbumItems(): MusicAlbum[] {
    if (this.hasRuntimeCatalog()) {
      return this.runtimeState.recentAlbums;
    }
    return this.albums.slice().sort((left: MusicAlbum, right: MusicAlbum): number =>
      right.createdAt - left.createdAt).slice(0, 10);
  }

  private recentTrackItems(): MusicTrack[] {
    if (this.hasRuntimeCatalog()) {
      return this.runtimeState.recentTracks;
    }
    return this.tracks.slice().sort((left: MusicTrack, right: MusicTrack): number =>
      right.createdAt - left.createdAt).slice(0, 10);
  }

  private albumCount(): number {
    return this.hasRuntimeCatalog() ? Math.max(this.runtimeState.albumTotal, this.albums.length) : this.albums.length;
  }

  private artistCount(): number {
    return this.hasRuntimeCatalog() ? Math.max(this.runtimeState.artistTotal, this.artists.length) : this.artists.length;
  }

  private genreCount(): number {
    return this.hasRuntimeCatalog() ? Math.max(this.runtimeState.genreTotal, this.genres.length) : this.genres.length;
  }

  private trackCount(): number {
    return this.hasRuntimeCatalog() ? Math.max(this.runtimeState.trackTotal, this.tracks.length) : this.tracks.length;
  }

  private updatePinnedState(pinned: boolean): void {
    if (pinned === this.sectionState.pinned) {
      return;
    }
    this.sectionState.pinned = pinned;
    this.onPinnedChange(pinned);
  }

  private updateStickyHeaderPosition(globalY: number): void {
    const titleBarBottom = Math.max(0, this.stickyTopInset) + FnMusicUI.homeActionBarHeight;
    this.updatePinnedState(globalY <= titleBarBottom + 1);
  }

  private updateSearchPosition(globalY: number, height: number): void {
    const titleBarBottom = Math.max(0, this.stickyTopInset) + FnMusicUI.homeActionBarHeight;
    const collapsed = globalY + height <= titleBarBottom + 1;
    if (collapsed === this.searchCollapsed) {
      return;
    }
    this.searchCollapsed = collapsed;
    this.onSearchCollapsedChange(collapsed);
  }

  private selectSection(id: string): void {
    this.sectionState.selectedId = id;
    this.pageScroller.scrollToIndex(3, true, ScrollAlign.START);
  }

  @Builder
  stickyChipHeader() {
    HomeStickyChipHeader({
      items: this.sections,
      state: this.sectionState,
      stickyTopInset: this.stickyTopInset,
      onSelect: (id: string): void => {
        this.selectSection(id);
      },
      onOpenSearch: (): void => this.onOpenSearch(),
      onPositionChange: (globalY: number): void => {
        this.updateStickyHeaderPosition(globalY);
      }
    })
  }

  build() {
    List({ space: FnMusicUI.contentGap, scroller: this.pageScroller }) {
      ListItem()
        .height(Math.max(0, this.stickyTopInset) + FnMusicUI.homeActionBarHeight -
          FnMusicUI.sectionGap + FnMusicUI.compactGap)

      ListItem() {
        HomeSearchEntry({
          onOpen: (): void => {
            this.onOpenSearch();
          },
          onPositionChange: (globalY: number, height: number): void => {
            this.updateSearchPosition(globalY, height);
          }
        })
      }
      .padding({ left: FnMusicUI.pagePadding, right: FnMusicUI.pagePadding })

      ListItem() {
        List({ space: 10 }) {
          ListItem().width(FnMusicUI.pagePadding - 10)

          Repeat<HomeFeatureCardData>(this.featureCards)
            .each((repeatItem: RepeatItem<HomeFeatureCardData>): void => {
              ListItem() {
                Stack({ alignContent: Alignment.BottomStart }) {
                  HomeFeatureCard({
                    data: repeatItem.item,
                    onPlay: (id: string): void => {
                      this.onPlayCollection(id);
                    }
                  })
                }
                .width(FnMusicUI.homeFeatureCardWidth)
                .height(FnMusicUI.homeFeatureCardHeight + FnMusicUI.homeFeatureCardOverflowTop)
              }
              .onClick((): void => {
                if (repeatItem.item.id !== 'roam') {
                  this.onOpenCollection(repeatItem.item.id, repeatItem.item.title);
                }
              })
            })
            .key((item: HomeFeatureCardData): string => item.id)

          ListItem().width(FnMusicUI.pagePadding - 10)
        }
        .listDirection(Axis.Horizontal)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .width('100%')
        .height(FnMusicUI.homeFeatureCardHeight + FnMusicUI.homeFeatureCardOverflowTop)
      }

      ListItemGroup({ header: this.stickyChipHeader }) {
        ListItem() {
          if (this.sectionState.selectedId === LibrarySection.RECENTLY_ADDED) {
            Column({ space: FnMusicUI.homeRecentSectionGap }) {
              HomeRecentAlbumPreview({
                albums: this.recentAlbumItems(),
                onOpen: (album: MusicAlbum): void => this.onOpenAlbum(album),
                onPlay: (album: MusicAlbum): void => this.onPlayAlbum(album)
              })
              HomeTrackPreview({
                tracks: this.recentTrackItems(),
                title: '最近添加歌曲',
                supporting: '',
                framed: false,
                showAllAction: false,
                onPlayTrack: (tracks: MusicTrack[], index: number): void => {
                  this.onPlayTracks(tracks, index);
                },
                onMore: (track: MusicTrack): void => {
                  this.onTrackMore(track);
                },
                onOpenAll: (): void => {
                  this.onOpenCollection('recently_added', '最近添加');
                }
              })
            }
          } else if (this.sectionState.selectedId === LibrarySection.ALBUMS) {
            Column({ space: 10 }) {
              HomeAlbumPreview({
                albums: this.albums,
                supporting: `${this.albumCount()} 张专辑`,
                onOpen: (album: MusicAlbum): void => this.onOpenAlbum(album),
                onOpenAll: (): void => this.onOpenSection(LibrarySection.ALBUMS)
              })
              Button('查看全部专辑')
                .width('100%')
                .height(FnMusicUI.actionHeight)
                .fontSize(FnMusicUI.bodySize)
                .fontColor($r('app.color.accent'))
                .backgroundColor($r('app.color.surface_secondary'))
                .borderRadius(FnMusicUI.controlRadius)
                .onClick((): void => this.onOpenSection(LibrarySection.ALBUMS))
            }
          } else if (this.sectionState.selectedId === LibrarySection.ARTISTS) {
            Column({ space: 10 }) {
              HomeArtistPreview({
                artists: this.artists,
                supporting: `${this.artistCount()} 位歌手`,
                onOpen: (artist: MusicArtist): void => this.onOpenArtist(artist)
              })
              Button('查看全部歌手')
                .width('100%')
                .height(FnMusicUI.actionHeight)
                .fontSize(FnMusicUI.bodySize)
                .fontColor($r('app.color.accent'))
                .backgroundColor($r('app.color.surface_secondary'))
                .borderRadius(FnMusicUI.controlRadius)
                .onClick((): void => this.onOpenSection(LibrarySection.ARTISTS))
            }
          } else if (this.sectionState.selectedId === LibrarySection.GENRES) {
            Column({ space: 10 }) {
              HomeGenrePreview({
                genres: this.genres,
                supporting: `${this.genreCount()} 种风格`,
                onOpen: (genre: MusicGenre): void => this.onOpenGenre(genre)
              })
              Button('查看全部风格')
                .width('100%')
                .height(FnMusicUI.actionHeight)
                .fontSize(FnMusicUI.bodySize)
                .fontColor($r('app.color.accent'))
                .backgroundColor($r('app.color.surface_secondary'))
                .borderRadius(FnMusicUI.controlRadius)
                .onClick((): void => this.onOpenSection(LibrarySection.GENRES))
            }
          } else {
            HomeTrackPreview({
              tracks: this.tracks,
              title: '音乐库',
              supporting: `${this.trackCount()} 首歌曲`,
              onPlayTrack: (tracks: MusicTrack[], index: number): void => {
                this.onPlayTracks(tracks, index);
              },
              onMore: (track: MusicTrack): void => {
                this.onTrackMore(track);
              },
              onOpenAll: (): void => {
                this.onOpenCollection('library', '音乐库');
              }
            })
          }
        }
        .padding({
          left: FnMusicUI.pagePadding,
          right: FnMusicUI.pagePadding,
          top: FnMusicUI.homeChipToContentGap
        })
      }
      ListItem().height(this.bottomInset + FnMusicUI.sectionGap + FnMusicUI.homeStickyRunway)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .sticky(StickyStyle.Header)
    .linearGradient({
      angle: 180,
      colors: [
        [$r('app.color.home_page_background_start'), 0],
        [$r('app.color.home_page_background_end'), 1]
      ]
    })
    .onDidScroll((): void => {
      const offset = Math.max(0, this.pageScroller.currentOffset().yOffset);
      this.onChromeProgress(Math.min(1, offset / 96));
    })
  }
}
