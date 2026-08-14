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
  subtitle: string;
  symbol: Resource;
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
        transparentSurface: true,
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
    .height(this.stickyTopInset + FnMusicUI.homeActionBarHeight)
    .padding({ left: FnMusicUI.pagePadding, right: FnMusicUI.pagePadding, top: this.stickyTopInset })
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
    .onClick((): void => {
      this.onOpen();
    })
  }
}

@ComponentV2
struct HomeFeatureCard {
  @Param data: HomeFeatureCardData = {
    id: '',
    title: '',
    subtitle: '',
    symbol: $r('sys.symbol.music')
  };
  @Event onPlay: (id: string) => void = (_: string): void => {};

  build() {
    Column({ space: 12 }) {
      Row() {
        Stack() {
          SymbolGlyph(this.data.symbol)
            .fontSize(23)
            .fontColor([$r('app.color.accent')])
        }
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor($r('app.color.surface_secondary'))

        Blank()

        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph($r('sys.symbol.play_fill'))
            .fontSize(17)
            .fontColor([$r('app.color.accent_contrast')])
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .systemMaterial(FnMusicMaterials.material(FnMusicMaterialRole.INTERACTIVE_SURFACE))
        .accessibilityText(`播放${this.data.title}`)
        .onTouch((event: TouchEvent): void => {
          event.stopPropagation();
        })
        .onClick((): void => {
          this.onPlay(this.data.id);
        })
      }
      .width('100%')

      Text(this.data.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .maxLines(1)
      Text(this.data.subtitle)
        .fontSize(FnMusicUI.supportingSize)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .maxLines(2)
        .lineHeight(19)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row({ space: 5 }) {
        Text('查看全部')
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.accent'))
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(14)
          .fontColor([$r('app.color.accent')])
      }
      .width('100%')
    }
    .width(226)
    .height(164)
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
    .borderRadius(16)
    .backgroundColor($r('app.color.surface'))
  }
}

@ComponentV2
struct HomeTrackPreview {
  @Param tracks: MusicTrack[] = [];
  @Param title: string = '最近加入';
  @Param supporting: string = '按添加时间排序';
  @Event onPlayTrack: (tracks: MusicTrack[], index: number) => void = (_: MusicTrack[], __: number): void => {};
  @Event onMore: (track: MusicTrack) => void = (_: MusicTrack): void => {};
  @Event onOpenAll: () => void = (): void => {};

  build() {
    Column({ space: 4 }) {
      SectionHeader({
        title: this.title,
        supporting: this.supporting,
        actionTitle: '全部',
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
        Column() {
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
        .padding({ left: 10, right: 8, top: 2, bottom: 2 })
        .borderRadius(FnMusicUI.cardRadius)
        .backgroundColor($r('app.color.surface'))
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
  @Event onPinnedChange: (pinned: boolean) => void = (_: boolean): void => {};
  @Event onChromeProgress: (progress: number) => void = (_: number): void => {};
  @Event onOpenSearch: () => void = (): void => {};
  @Event onOpenCollection: (id: string, title: string) => void = (_: string, __: string): void => {};
  @Event onPlayCollection: (id: string) => void = (_: string): void => {};
  @Event onOpenSection: (id: string) => void = (_: string): void => {};
  @Event onOpenAlbum: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};
  @Event onOpenArtist: (artist: MusicArtist) => void = (_: MusicArtist): void => {};
  @Event onOpenGenre: (genre: MusicGenre) => void = (_: MusicGenre): void => {};
  @Event onPlayTracks: (tracks: MusicTrack[], index: number) => void = (_: MusicTrack[], __: number): void => {};
  @Event onTrackMore: (track: MusicTrack) => void = (_: MusicTrack): void => {};

  private readonly featureCards: HomeFeatureCardData[] = [
    { id: 'roam', title: '漫游', subtitle: '从音乐库开始连续发现', symbol: $r('sys.symbol.crown_fill') },
    { id: 'favorites', title: '收藏', subtitle: '回到你喜欢的歌曲', symbol: $r('sys.symbol.heart_fill') },
    { id: 'history', title: '最近播放', subtitle: '继续上一次的聆听', symbol: $r('sys.symbol.arrow_clockwise') },
    { id: 'recently_added', title: '最近添加', subtitle: '看看音乐库的新成员', symbol: $r('sys.symbol.plus_circle') }
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
    List({ space: FnMusicUI.sectionGap, scroller: this.pageScroller }) {
      ListItem()
        .height(Math.max(0, this.stickyTopInset) + FnMusicUI.homeActionBarHeight + 12)

      ListItem() {
        HomeSearchEntry({
          onOpen: (): void => {
            this.onOpenSearch();
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
                HomeFeatureCard({
                  data: repeatItem.item,
                  onPlay: (id: string): void => {
                    this.onPlayCollection(id);
                  }
                })
              }
              .onClick((): void => {
                this.onOpenCollection(repeatItem.item.id, repeatItem.item.title);
              })
            })
            .key((item: HomeFeatureCardData): string => item.id)

          ListItem().width(FnMusicUI.pagePadding - 10)
        }
        .listDirection(Axis.Horizontal)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .width('100%')
        .height(164)
      }

      ListItemGroup({ header: this.stickyChipHeader }) {
        ListItem() {
          if (this.sectionState.selectedId === LibrarySection.RECENTLY_ADDED) {
            Column({ space: FnMusicUI.sectionGap }) {
              HomeAlbumPreview({
                albums: this.recentAlbumItems(),
                title: '最近添加的专辑',
                supporting: '按最近加入歌曲排序',
                showAllAction: true,
                onOpen: (album: MusicAlbum): void => this.onOpenAlbum(album),
                onOpenAll: (): void => this.onOpenSection(LibrarySection.ALBUMS)
              })
              HomeTrackPreview({
                tracks: this.recentTrackItems(),
                title: '最近添加的歌曲',
                supporting: '按添加时间从新到旧',
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
        .padding({ left: FnMusicUI.pagePadding, right: FnMusicUI.pagePadding })
      }
      ListItem().height(this.bottomInset + FnMusicUI.sectionGap + FnMusicUI.homeStickyRunway)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .sticky(StickyStyle.Header)
    .backgroundColor($r('app.color.page_background'))
    .onDidScroll((): void => {
      const offset = Math.max(0, this.pageScroller.currentOffset().yOffset);
      this.onChromeProgress(Math.min(1, offset / 96));
    })
  }
}
