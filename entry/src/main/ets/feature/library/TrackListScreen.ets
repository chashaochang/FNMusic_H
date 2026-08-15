import { FnMusicUI } from '../../design/FnMusicUI';
import { AuthPhase } from '../../auth/ConnectionModels';
import { AppRuntime, AppRuntimeState } from '../../common/AppRuntime';
import {
  CollectionKind,
  MusicAlbum,
  MusicArtist,
  MusicGenre,
  MusicPlaylist,
  MusicTrack
} from '../../model/MusicModels';
import {
  EmptyMusicState,
  MusicChipItem,
  SectionHeader,
  SecondaryPageHeader
} from '../common/MusicUiComponents';
import {
  AlbumCatalogItem,
  AlbumDetailHero,
  ArtistDetailHero,
  CollectionActionRow,
  CollectionSegmentedSwitch,
  DenseTrackRow,
  MusicDetailHero,
  PlaylistDetailHero
} from './LibraryVisualComponents';

enum TrackSortMode {
  DEFAULT = 'default',
  TITLE_ASC = 'title_asc',
  TITLE_DESC = 'title_desc'
}

@ObservedV2
class ArtistSectionState {
  @Trace selectedId: string = 'tracks';
}

@ComponentV2
struct ImageDetailTrackList {
  @Require @Param scroller: Scroller;
  @Param tracks: MusicTrack[] = [];
  @Param totalCount: number = 0;
  @Param loading: boolean = false;
  @Param errorMessage: string = '';
  @Param bottomInset: number = 0;
  @Param showActionRow: boolean = false;
  @Param showIndex: boolean = true;
  @Param showArtwork: boolean = false;
  @Param showFormat: boolean = false;
  @Param showDuration: boolean = true;
  @Param showFavoriteAction: boolean = false;
  @Param useTrackNumber: boolean = false;
  @Param canRemoveFromPlaylist: boolean = false;
  @Event onPlayAll: () => void = (): void => {};
  @Event onPlayIndex: (index: number) => void = (_: number): void => {};
  @Event onFavorite: (track: MusicTrack, favorite: boolean) => void =
    (_: MusicTrack, __: boolean): void => {};
  @Event onTrackMore: (track: MusicTrack, canRemove: boolean) => void =
    (_: MusicTrack, __: boolean): void => {};
  @Event onSort: () => void = (): void => {};

  build() {
    List({ space: 0, scroller: this.scroller }) {
      if (this.showActionRow) {
        ListItem() {
          CollectionActionRow({
            count: this.totalCount,
            onPlayAll: (): void => this.onPlayAll(),
            onMore: (): void => this.onSort()
          })
        }
        .padding({ left: FnMusicUI.secondaryPagePadding, right: FnMusicUI.secondaryPagePadding })
      }

      if (this.loading) {
        ListItem() {
          Column({ space: FnMusicUI.compactGap }) {
            LoadingProgress()
              .width(28)
              .height(28)
              .color($r('app.color.accent'))
            Text('正在加载')
              .fontSize(FnMusicUI.supportingSize)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .height(180)
          .justifyContent(FlexAlign.Center)
        }
        .padding({ left: FnMusicUI.secondaryPagePadding, right: FnMusicUI.secondaryPagePadding })
      } else if (this.errorMessage.length > 0) {
        ListItem() {
          EmptyMusicState({
            title: '加载失败',
            message: this.errorMessage,
            symbol: $r('sys.symbol.exclamationmark_circle_fill')
          })
        }
        .padding({ left: FnMusicUI.secondaryPagePadding, right: FnMusicUI.secondaryPagePadding })
      } else if (this.tracks.length === 0) {
        ListItem() {
          EmptyMusicState({ title: '这里还没有歌曲', message: '添加歌曲后会显示在这里。' })
        }
        .padding({ left: FnMusicUI.secondaryPagePadding, right: FnMusicUI.secondaryPagePadding })
      } else {
        Repeat<MusicTrack>(this.tracks)
          .each((repeatItem: RepeatItem<MusicTrack>): void => {
            ListItem() {
              Column() {
                DenseTrackRow({
                  track: repeatItem.item,
                  index: repeatItem.index,
                  showIndex: this.showIndex,
                  showArtwork: this.showArtwork,
                  showFormat: this.showFormat,
                  showDuration: this.showDuration,
                  showFavoriteAction: this.showFavoriteAction,
                  useTrackNumber: this.useTrackNumber,
                  onPlay: (index: number): void => this.onPlayIndex(index),
                  onFavorite: (track: MusicTrack, favorite: boolean): void =>
                    this.onFavorite(track, favorite),
                  onMore: (track: MusicTrack): void =>
                    this.onTrackMore(track, this.canRemoveFromPlaylist)
                })
                Divider()
                  .strokeWidth(0.5)
                  .color($r('app.color.divider'))
                  .margin({ left: this.showIndex ? 34 : (this.showArtwork ? 52 : 0) })
              }
            }
            .padding({ left: FnMusicUI.secondaryPagePadding, right: FnMusicUI.secondaryPagePadding })
          })
          .key((item: MusicTrack): string => item.guid)
          .virtualScroll()
      }

      ListItem().height(this.bottomInset + FnMusicUI.sectionGap)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.None)
    .nestedScroll({
      scrollForward: NestedScrollMode.PARENT_FIRST,
      scrollBackward: NestedScrollMode.SELF_FIRST
    })
  }
}

@ComponentV2
struct ArtistAlbumList {
  @Require @Param scroller: Scroller;
  @Param albums: MusicAlbum[] = [];
  @Param bottomInset: number = 0;
  @Event onOpenAlbum: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};

  build() {
    List({ space: 0, scroller: this.scroller }) {
      if (this.albums.length === 0) {
        ListItem() {
          EmptyMusicState({
            title: '还没有可显示的专辑',
            message: '当前已加载的歌手歌曲中没有可识别的专辑。'
          })
        }
        .padding({ left: FnMusicUI.secondaryPagePadding, right: FnMusicUI.secondaryPagePadding })
      } else {
        Repeat<MusicAlbum>(this.albums)
          .each((repeatItem: RepeatItem<MusicAlbum>): void => {
            ListItem() {
              Column() {
                AlbumCatalogItem({
                  album: repeatItem.item,
                  showPlay: false,
                  onOpen: (album: MusicAlbum): void => this.onOpenAlbum(album)
                })
                Divider()
                  .strokeWidth(0.5)
                  .color($r('app.color.divider'))
                  .margin({ left: 74 })
              }
            }
            .padding({ left: FnMusicUI.secondaryPagePadding, right: FnMusicUI.secondaryPagePadding })
          })
          .key((item: MusicAlbum): string => item.guid)
          .virtualScroll()
      }

      ListItem().height(this.bottomInset + FnMusicUI.sectionGap)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.None)
    .nestedScroll({
      scrollForward: NestedScrollMode.PARENT_FIRST,
      scrollBackward: NestedScrollMode.SELF_FIRST
    })
  }
}

@ComponentV2
export struct TrackListScreen {
  @Param title: string = '';
  @Param subtitle: string = '';
  @Param collectionId: string = '';
  @Param tracks: MusicTrack[] = [];
  @Param artistAlbums: MusicAlbum[] = [];
  @Param album: MusicAlbum = new MusicAlbum();
  @Param artist: MusicArtist = new MusicArtist();
  @Param genre: MusicGenre = new MusicGenre();
  @Param playlist: MusicPlaylist = new MusicPlaylist();
  @Param symbol: Resource = $r('sys.symbol.music_note_list');
  @Param canRemoveFromPlaylist: boolean = false;
  @Param safeTop: number = 0;
  @Param bottomInset: number = 0;
  @Param loading: boolean = false;
  @Param errorMessage: string = '';
  @Local sortMode: TrackSortMode = TrackSortMode.DEFAULT;
  @Local detailScroller: Scroller = new Scroller();
  @Local detailTrackScroller: Scroller = new Scroller();
  @Local artistAlbumScroller: Scroller = new Scroller();
  @Local detailScrollOffset: number = 0;
  @Local detailHeroHeight: number = 0;
  @Local artistSectionState: ArtistSectionState = new ArtistSectionState();
  @Local runtimeState: AppRuntimeState = AppRuntime.state();
  @Event onBack: () => void = (): void => {};
  @Event onPlay: (tracks: MusicTrack[], index: number) => void = (_: MusicTrack[], __: number): void => {};
  @Event onFavorite: (track: MusicTrack, favorite: boolean) => void =
    (_: MusicTrack, __: boolean): void => {};
  @Event onTrackMore: (track: MusicTrack, canRemove: boolean) => void = (_: MusicTrack, __: boolean): void => {};
  @Event onPageMore: () => void = (): void => {};
  @Event onOpenAlbum: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};

  private artistSections(): MusicChipItem[] {
    return [
      { id: 'tracks', title: `歌曲 ${this.visibleTotal()}` },
      { id: 'albums', title: `专辑 ${this.artist.albumCount}` }
    ];
  }

  @Monitor('collectionId')
  onCollectionChanged(): void {
    this.artistSectionState.selectedId = 'tracks';
    this.detailScrollOffset = 0;
    this.detailHeroHeight = 0;
    this.detailScroller.scrollTo({ xOffset: 0, yOffset: 0, animation: false });
    this.detailTrackScroller.scrollToIndex(0, false, ScrollAlign.START);
    this.artistAlbumScroller.scrollToIndex(0, false, ScrollAlign.START);
  }

  private isImageDetailCollection(): boolean {
    return this.collectionId === CollectionKind.ARTIST || this.collectionId === CollectionKind.ALBUM ||
      this.collectionId === CollectionKind.PLAYLIST;
  }

  private detailHeaderCollapsed(): boolean {
    if (this.detailHeroHeight <= 0) {
      return false;
    }
    return this.detailScrollOffset >= this.detailStickyTriggerOffset();
  }

  private detailStickyTriggerOffset(): number {
    if (!this.isImageDetailCollection() || this.detailHeroHeight <= 0) {
      return 0;
    }
    return Math.max(0, this.detailHeroHeight -
      Math.max(0, this.safeTop) - FnMusicUI.secondaryHeaderHeight);
  }

  private imageDetailSectionHeight(): string {
    const reservedHeight: number = Math.max(0, this.safeTop) + FnMusicUI.secondaryHeaderHeight;
    return `calc(100% - ${reservedHeight}vp)`;
  }

  private headerOpacity(): number {
    if (!this.isImageDetailCollection()) {
      return 0;
    }
    if (this.detailHeroHeight <= 0) {
      return 0;
    }
    const trigger: number = Math.max(1, this.detailStickyTriggerOffset());
    return Math.max(0, Math.min(1, this.detailScrollOffset / (trigger * 0.82)));
  }

  private usesRuntimeLibrary(): boolean {
    return this.collectionId === CollectionKind.LIBRARY && this.runtimeState.phase === AuthPhase.AUTHENTICATED;
  }

  private visibleTracks(): MusicTrack[] {
    return this.usesRuntimeLibrary() ? this.runtimeState.tracks : this.tracks;
  }

  private visibleTotal(): number {
    const tracks = this.visibleTracks();
    if (this.usesRuntimeLibrary()) return Math.max(this.runtimeState.trackTotal, tracks.length);
    if (this.collectionId === CollectionKind.ALBUM) return Math.max(this.album.trackCount, tracks.length);
    if (this.collectionId === CollectionKind.ARTIST) return Math.max(this.artist.trackCount, tracks.length);
    if (this.collectionId === CollectionKind.GENRE) return Math.max(this.genre.trackCount, tracks.length);
    if (this.collectionId === CollectionKind.PLAYLIST) return Math.max(this.playlist.trackCount, tracks.length);
    return tracks.length;
  }

  private loadMore(): void {
    if (this.usesRuntimeLibrary()) {
      AppRuntime.loadMoreTracks().catch((): void => {});
    }
  }

  private sortedTracks(): MusicTrack[] {
    const tracks = this.visibleTracks().slice();
    if (this.sortMode === TrackSortMode.DEFAULT) {
      return tracks;
    }
    return tracks.sort((left: MusicTrack, right: MusicTrack): number => {
      const compare: number = left.title.localeCompare(right.title);
      return this.sortMode === TrackSortMode.TITLE_ASC ? compare : -compare;
    });
  }

  private sortLabel(): string {
    if (this.sortMode === TrackSortMode.TITLE_ASC) {
      return '标题升序';
    }
    if (this.sortMode === TrackSortMode.TITLE_DESC) {
      return '标题降序';
    }
    return '默认排序';
  }

  private sortSymbol(): Resource {
    if (this.sortMode === TrackSortMode.TITLE_ASC) {
      return $r('sys.symbol.arrow_up');
    }
    if (this.sortMode === TrackSortMode.TITLE_DESC) {
      return $r('sys.symbol.arrow_down');
    }
    return $r('sys.symbol.arrow_clockwise');
  }

  private cycleSortMode(): void {
    if (this.sortMode === TrackSortMode.DEFAULT) {
      this.sortMode = TrackSortMode.TITLE_ASC;
    } else if (this.sortMode === TrackSortMode.TITLE_ASC) {
      this.sortMode = TrackSortMode.TITLE_DESC;
    } else {
      this.sortMode = TrackSortMode.DEFAULT;
    }
  }

  private headerTitle(): string {
    if (this.collectionId === CollectionKind.ALBUM) return this.title.length > 0 ? this.title : '专辑';
    if (this.collectionId === CollectionKind.ARTIST) return this.title.length > 0 ? this.title : '歌手';
    if (this.collectionId === CollectionKind.GENRE) return '风格';
    if (this.collectionId === CollectionKind.FAVORITES) return '收藏';
    if (this.collectionId === CollectionKind.HISTORY) return '最近播放';
    if (this.collectionId === CollectionKind.LIBRARY) return '音乐库';
    if (this.collectionId === CollectionKind.PLAYLIST) return this.title.length > 0 ? this.title : '歌单';
    if (this.collectionId === CollectionKind.RECENTLY_ADDED) return '最近添加';
    return this.title;
  }

  private heroCoverId(): string {
    if (this.collectionId === CollectionKind.ALBUM) return this.album.coverId;
    if (this.collectionId === CollectionKind.ARTIST) return this.artist.coverId;
    if (this.collectionId === CollectionKind.GENRE) return this.genre.coverId;
    if (this.collectionId === CollectionKind.PLAYLIST) return this.playlist.coverId;
    return '';
  }

  private heroUpdatedAt(): number {
    if (this.collectionId === CollectionKind.ALBUM) return this.album.createdAt;
    if (this.collectionId === CollectionKind.GENRE) return this.genre.updatedAt;
    if (this.collectionId === CollectionKind.PLAYLIST) return this.playlist.updatedAt;
    return 0;
  }

  private heroPlaceholderMedia(): Resource | undefined {
    if (this.collectionId === CollectionKind.ALBUM || this.collectionId === CollectionKind.PLAYLIST) {
      return $r('app.media.music_album_placeholder');
    }
    if (this.collectionId === CollectionKind.GENRE) {
      return $r('app.media.music_genre_vinyl');
    }
    return undefined;
  }

  private heroPlaceholderRatio(): number {
    return this.collectionId === CollectionKind.GENRE ? 0.86 : 0.34;
  }

  private heroShowsPlaceholderSymbol(): boolean {
    return this.collectionId !== CollectionKind.ARTIST;
  }

  private heroSubtitle(): string {
    if (this.collectionId === CollectionKind.ALBUM) {
      return this.album.artistName.length > 0 ? this.album.artistName : this.subtitle;
    }
    if (this.collectionId === CollectionKind.ARTIST) {
      return `${this.artist.trackCount} 首歌 · ${this.artist.albumCount} 张专辑`;
    }
    if (this.collectionId === CollectionKind.GENRE) {
      return `${this.visibleTotal()} 首歌曲`;
    }
    return this.subtitle;
  }

  private heroSupporting(): string {
    if (this.collectionId === CollectionKind.ALBUM) {
      const year = this.album.year > 0 ? `${this.album.year} 年 · ` : '';
      return `${year}${this.visibleTotal()} 首歌曲`;
    }
    if (this.collectionId === CollectionKind.ARTIST || this.collectionId === CollectionKind.GENRE) {
      return '';
    }
    if (this.collectionId === CollectionKind.PLAYLIST && this.playlist.description.length > 0) {
      return `${this.playlist.description} · ${this.visibleTotal()} 首歌曲`;
    }
    return `${this.visibleTotal()} 首歌曲`;
  }

  private showLargeHero(): boolean {
    return this.collectionId !== CollectionKind.LIBRARY;
  }

  private showShuffle(): boolean {
    return this.collectionId !== CollectionKind.HISTORY && this.collectionId !== CollectionKind.RECENTLY_ADDED;
  }

  private backgroundStart(): ResourceColor {
    if (this.collectionId === CollectionKind.ALBUM) return $r('app.color.album_detail_background');
    if (this.collectionId === CollectionKind.FAVORITES) return $r('app.color.page_favorite_background_start');
    if (this.collectionId === CollectionKind.HISTORY) return $r('app.color.page_history_background_start');
    if (this.collectionId === CollectionKind.ROAM) return $r('app.color.page_roam_background_start');
    if (this.collectionId === CollectionKind.ARTIST) return $r('app.color.album_detail_background');
    if (this.collectionId === CollectionKind.PLAYLIST) return $r('app.color.album_detail_background');
    if (this.collectionId === CollectionKind.GENRE) return $r('app.color.page_genre_background_start');
    return $r('app.color.page_catalog_background_start');
  }

  private backgroundEnd(): ResourceColor {
    if (this.collectionId === CollectionKind.ALBUM) return $r('app.color.album_detail_background');
    if (this.collectionId === CollectionKind.FAVORITES) return $r('app.color.page_favorite_background_end');
    if (this.collectionId === CollectionKind.HISTORY) return $r('app.color.page_history_background_end');
    if (this.collectionId === CollectionKind.ROAM) return $r('app.color.page_roam_background_end');
    if (this.collectionId === CollectionKind.ARTIST) return $r('app.color.album_detail_background');
    if (this.collectionId === CollectionKind.PLAYLIST) return $r('app.color.album_detail_background');
    if (this.collectionId === CollectionKind.GENRE) return $r('app.color.page_genre_background_end');
    return $r('app.color.page_catalog_background_end');
  }

  private shuffleStartIndex(): number {
    if (this.visibleTracks().length < 2) return 0;
    return Math.floor(Math.random() * this.visibleTracks().length);
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.isImageDetailCollection()) {
        Scroll(this.detailScroller) {
          Column() {
            Column() {
              if (this.collectionId === CollectionKind.ARTIST) {
                ArtistDetailHero({ artist: this.artist })
              } else if (this.collectionId === CollectionKind.ALBUM) {
                AlbumDetailHero({
                  album: this.album,
                  trackCount: this.visibleTotal(),
                  safeTop: this.safeTop
                })
              } else {
                PlaylistDetailHero({
                  playlist: this.playlist,
                  trackCount: this.visibleTotal(),
                  loadedCount: this.visibleTracks().length,
                  safeTop: this.safeTop,
                  onShuffle: (): void => {
                    const tracks = this.sortedTracks();
                    if (tracks.length > 0) this.onPlay(tracks, this.shuffleStartIndex());
                  },
                  onManage: (): void => this.onPageMore()
                })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .onAreaChange((_: Area, area: Area): void => {
              const height = area.height as number;
              if (height > 0) {
                this.detailHeroHeight = height;
              }
            })

            Column() {
              if (this.collectionId === CollectionKind.ARTIST) {
                Row() {
                  CollectionSegmentedSwitch({
                    items: this.artistSections(),
                    selectedId: this.artistSectionState.selectedId,
                    onSelect: (id: string): void => {
                      this.artistSectionState.selectedId = id;
                    }
                  })
                }
                .width('100%')
                .height(FnMusicUI.collectionSegmentHeight + FnMusicUI.collectionSegmentVerticalPadding * 2)
                .padding({
                  left: FnMusicUI.secondaryPagePadding,
                  right: FnMusicUI.secondaryPagePadding,
                  top: FnMusicUI.collectionSegmentVerticalPadding,
                  bottom: FnMusicUI.collectionSegmentVerticalPadding
                })
                .alignItems(VerticalAlign.Center)

                if (this.artistSectionState.selectedId === 'tracks') {
                  Row() {
                    CollectionActionRow({
                      count: this.visibleTotal(),
                      onPlayAll: (): void => {
                        const tracks = this.sortedTracks();
                        if (tracks.length > 0) this.onPlay(tracks, 0);
                      },
                      onMore: (): void => this.cycleSortMode()
                    })
                  }
                  .width('100%')
                  .height(FnMusicUI.collectionActionHeight)
                  .padding({ left: FnMusicUI.secondaryPagePadding, right: FnMusicUI.secondaryPagePadding })
                  .alignItems(VerticalAlign.Center)
                }

                Stack() {
                  if (this.artistSectionState.selectedId === 'albums') {
                    ArtistAlbumList({
                      scroller: this.artistAlbumScroller,
                      albums: this.artistAlbums,
                      bottomInset: this.bottomInset,
                      onOpenAlbum: (album: MusicAlbum): void => this.onOpenAlbum(album)
                    })
                  } else {
                    ImageDetailTrackList({
                      scroller: this.detailTrackScroller,
                      tracks: this.sortedTracks(),
                      totalCount: this.visibleTotal(),
                      loading: this.loading,
                      errorMessage: this.errorMessage,
                      bottomInset: this.bottomInset,
                      showActionRow: false,
                      showIndex: false,
                      showArtwork: false,
                      showFormat: false,
                      showDuration: false,
                      showFavoriteAction: true,
                      useTrackNumber: false,
                      canRemoveFromPlaylist: this.canRemoveFromPlaylist,
                      onPlayAll: (): void => {},
                      onPlayIndex: (index: number): void => this.onPlay(this.sortedTracks(), index),
                      onFavorite: (track: MusicTrack, favorite: boolean): void =>
                        this.onFavorite(track, favorite),
                      onTrackMore: (track: MusicTrack, canRemove: boolean): void =>
                        this.onTrackMore(track, canRemove),
                      onSort: (): void => this.cycleSortMode()
                    })
                  }
                }
                .width('100%')
                .layoutWeight(1)
              } else {
                Row() {
                  CollectionActionRow({
                    count: this.visibleTotal(),
                    onPlayAll: (): void => {
                      const tracks = this.sortedTracks();
                      if (tracks.length > 0) this.onPlay(tracks, 0);
                    },
                    onMore: (): void => this.cycleSortMode()
                  })
                }
                .width('100%')
                .height(FnMusicUI.collectionActionHeight)
                .padding({ left: FnMusicUI.secondaryPagePadding, right: FnMusicUI.secondaryPagePadding })
                .alignItems(VerticalAlign.Center)

                Stack() {
                  ImageDetailTrackList({
                    scroller: this.detailTrackScroller,
                    tracks: this.sortedTracks(),
                    totalCount: this.visibleTotal(),
                    loading: this.loading,
                    errorMessage: this.errorMessage,
                    bottomInset: this.bottomInset,
                    showActionRow: false,
                    showIndex: this.collectionId === CollectionKind.ALBUM,
                    showArtwork: false,
                    showFormat: this.collectionId === CollectionKind.ALBUM,
                    showDuration: this.collectionId === CollectionKind.ALBUM,
                    showFavoriteAction: true,
                    useTrackNumber: this.collectionId === CollectionKind.ALBUM,
                    canRemoveFromPlaylist: this.canRemoveFromPlaylist,
                    onPlayAll: (): void => {},
                    onPlayIndex: (index: number): void => this.onPlay(this.sortedTracks(), index),
                    onFavorite: (track: MusicTrack, favorite: boolean): void =>
                      this.onFavorite(track, favorite),
                    onTrackMore: (track: MusicTrack, canRemove: boolean): void =>
                      this.onTrackMore(track, canRemove),
                    onSort: (): void => this.cycleSortMode()
                  })
                }
                .width('100%')
                .layoutWeight(1)
              }
            }
            .width('100%')
            .height(this.imageDetailSectionHeight())
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(this.backgroundEnd())
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .height('100%')
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .onDidScroll((): void => {
          this.detailScrollOffset = Math.max(0, this.detailScroller.currentOffset().yOffset);
        })
      } else {
        List({ space: 0, scroller: this.detailScroller }) {
        ListItem()
          .height(this.isImageDetailCollection() ? 0 : Math.max(0, this.safeTop) + FnMusicUI.secondaryHeaderHeight)

        if (this.showLargeHero()) {
          ListItem() {
            if (this.collectionId === CollectionKind.ARTIST) {
              ArtistDetailHero({ artist: this.artist })
            } else if (this.collectionId === CollectionKind.ALBUM) {
              AlbumDetailHero({
                album: this.album,
                trackCount: this.visibleTotal(),
                safeTop: this.safeTop
              })
            } else {
              MusicDetailHero({
                title: this.title,
                subtitle: this.heroSubtitle(),
                supporting: this.heroSupporting(),
                coverId: this.heroCoverId(),
                updatedAt: this.heroUpdatedAt(),
                symbol: this.symbol,
                placeholderMedia: this.heroPlaceholderMedia(),
                placeholderRatio: this.heroPlaceholderRatio(),
                showPlaceholderSymbol: this.heroShowsPlaceholderSymbol(),
                circularArtwork: false,
                collectionId: this.collectionId,
                loadedCount: this.visibleTracks().length,
                showShuffle: this.showShuffle(),
                onPlayAll: (): void => this.onPlay(this.visibleTracks(), 0),
                onShuffle: (): void => this.onPlay(this.visibleTracks(), this.shuffleStartIndex())
              })
            }
          }
          .padding({
            left: this.collectionId === CollectionKind.ARTIST || this.collectionId === CollectionKind.ALBUM ? 0 : FnMusicUI.secondaryPagePadding,
            right: this.collectionId === CollectionKind.ARTIST || this.collectionId === CollectionKind.ALBUM ? 0 : FnMusicUI.secondaryPagePadding,
            bottom: FnMusicUI.sectionGap
          })
        } else if (this.collectionId !== CollectionKind.LIBRARY) {
          ListItem() {
            Row({ space: FnMusicUI.compactGap }) {
              Button({ type: ButtonType.Normal, stateEffect: true }) {
                Row({ space: 7 }) {
                  SymbolGlyph($r('sys.symbol.shuffle'))
                    .fontSize(17)
                    .fontColor([$r('app.color.accent_contrast')])
                  Text('随机漫游')
                    .fontSize(FnMusicUI.bodySize)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.accent_contrast'))
                }
              }
              .layoutWeight(1)
              .height(FnMusicUI.actionHeight)
              .borderRadius(FnMusicUI.actionHeight / 2)
              .backgroundColor($r('app.color.accent'))
              .enabled(this.visibleTracks().length > 0)
              .onClick((): void => this.onPlay(this.visibleTracks(), this.shuffleStartIndex()))
            }
            .width('100%')
          }
          .padding({
            left: FnMusicUI.secondaryPagePadding,
            right: FnMusicUI.secondaryPagePadding,
            bottom: FnMusicUI.contentGap
          })
        }

        ListItemGroup() {
          if (this.collectionId === CollectionKind.ARTIST && this.artistSectionState.selectedId === 'albums') {
            ListItem() {
              if (this.artistAlbums.length === 0) {
                EmptyMusicState({
                  title: '还没有可显示的专辑',
                  message: '当前已加载的歌手歌曲中没有可识别的专辑。'
                })
              } else {
                Column({ space: 0 }) {
                  Repeat<MusicAlbum>(this.artistAlbums)
                    .each((repeatItem: RepeatItem<MusicAlbum>): void => {
                      AlbumCatalogItem({
                        album: repeatItem.item,
                        showPlay: false,
                        onOpen: (album: MusicAlbum): void => this.onOpenAlbum(album)
                      })
                      Divider()
                        .strokeWidth(0.5)
                        .color($r('app.color.divider'))
                        .margin({ left: 74 })
                    })
                    .key((item: MusicAlbum): string => item.guid)
                }
              }
            }
            .padding({ left: FnMusicUI.secondaryPagePadding, right: FnMusicUI.secondaryPagePadding })
          } else {
            ListItem() {
              if (this.collectionId === CollectionKind.ARTIST) {
                CollectionActionRow({
                  count: this.visibleTotal(),
                  onPlayAll: (): void => {
                    const tracks = this.sortedTracks();
                    if (tracks.length > 0) this.onPlay(tracks, 0);
                  },
                  onMore: (): void => this.cycleSortMode()
                })
              } else if (this.collectionId === CollectionKind.LIBRARY) {
                SectionHeader({
                  title: '音乐库',
                  supporting: `共 ${this.visibleTotal()} 首歌曲`
                })
              } else {
                Row() {
                  Text('歌曲')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.text_primary'))
                  Blank()
                  Button({ type: ButtonType.Normal }) {
                    Row({ space: 5 }) {
                      SymbolGlyph(this.sortSymbol())
                        .fontSize(15)
                        .fontColor([$r('app.color.accent')])
                      Text(this.sortLabel())
                        .fontSize(13)
                        .fontColor($r('app.color.accent'))
                    }
                  }
                  .height(36)
                  .padding({ left: 10, right: 10 })
                  .borderRadius(FnMusicUI.controlRadius)
                  .backgroundColor(Color.Transparent)
                  .onClick((): void => this.cycleSortMode())
                }
                .width('100%')
                .height(46)
              }
            }
            .padding({
              left: FnMusicUI.secondaryPagePadding,
              right: FnMusicUI.secondaryPagePadding,
              top: this.collectionId === CollectionKind.LIBRARY ? FnMusicUI.homeChipToContentGap : 0
            })

            if (this.loading) {
              ListItem() {
                Column({ space: FnMusicUI.compactGap }) {
                  LoadingProgress()
                    .width(28)
                    .height(28)
                    .color($r('app.color.accent'))
                  Text('正在加载')
                    .fontSize(FnMusicUI.supportingSize)
                    .fontColor($r('app.color.text_secondary'))
                }
                .width('100%')
                .height(180)
                .justifyContent(FlexAlign.Center)
              }
              .padding({ left: FnMusicUI.secondaryPagePadding, right: FnMusicUI.secondaryPagePadding })
            } else if (this.errorMessage.length > 0) {
              ListItem() {
                EmptyMusicState({
                  title: '加载失败',
                  message: this.errorMessage,
                  symbol: $r('sys.symbol.exclamationmark_circle_fill')
                })
              }
              .padding({ left: FnMusicUI.secondaryPagePadding, right: FnMusicUI.secondaryPagePadding })
            } else if (this.visibleTracks().length === 0) {
              ListItem() {
                EmptyMusicState({
                  title: this.collectionId === CollectionKind.LIBRARY ? '音乐库为空' : '这里还没有歌曲',
                  message: this.collectionId === CollectionKind.LIBRARY ?
                    '服务器音乐库中的歌曲会显示在这里。' : '添加歌曲后会显示在这里。'
                })
              }
              .padding({ left: FnMusicUI.secondaryPagePadding, right: FnMusicUI.secondaryPagePadding })
            } else {
              Repeat<MusicTrack>(this.sortedTracks())
                .each((repeatItem: RepeatItem<MusicTrack>): void => {
                  ListItem() {
                    Column() {
                      DenseTrackRow({
                        track: repeatItem.item,
                        index: repeatItem.index,
                        showIndex: this.collectionId !== CollectionKind.LIBRARY,
                        showFormat: this.collectionId === CollectionKind.LIBRARY,
                        onPlay: (index: number): void => this.onPlay(this.sortedTracks(), index),
                        onMore: (track: MusicTrack): void => this.onTrackMore(track, this.canRemoveFromPlaylist)
                      })
                      Divider()
                        .strokeWidth(0.5)
                        .color($r('app.color.divider'))
                        .margin({ left: this.collectionId === CollectionKind.LIBRARY ? 52 : 34 })
                    }
                  }
                  .padding({ left: FnMusicUI.secondaryPagePadding, right: FnMusicUI.secondaryPagePadding })
                })
                .key((item: MusicTrack): string => item.guid)
                .virtualScroll()
            }
          }

          if (this.usesRuntimeLibrary()) {
            ListItem() {
              Column({ space: FnMusicUI.compactGap }) {
                if (this.runtimeState.tracksLoadingMore) {
                  LoadingProgress()
                    .width(24)
                    .height(24)
                    .color($r('app.color.accent'))
                  Text('正在加载更多')
                    .fontSize(FnMusicUI.supportingSize)
                    .fontColor($r('app.color.text_secondary'))
                } else if (this.runtimeState.tracksLoadMoreError.length > 0) {
                  Text(this.runtimeState.tracksLoadMoreError)
                    .fontSize(FnMusicUI.supportingSize)
                    .fontColor($r('app.color.text_secondary'))
                    .maxLines(2)
                    .textAlign(TextAlign.Center)
                  Button('重试加载')
                    .height(36)
                    .fontSize(FnMusicUI.supportingSize)
                    .fontColor($r('app.color.accent'))
                    .backgroundColor($r('app.color.surface_secondary'))
                    .borderRadius(FnMusicUI.controlRadius)
                    .onClick((): void => this.loadMore())
                } else if (this.runtimeState.tracksHasMore) {
                  Text(`已加载 ${this.visibleTracks().length} / 共 ${this.visibleTotal()}`)
                    .fontSize(FnMusicUI.supportingSize)
                    .fontColor($r('app.color.text_secondary'))
                }
              }
              .width('100%')
              .height(this.runtimeState.tracksLoadMoreError.length > 0 ? 96 :
                (this.runtimeState.tracksLoadingMore || this.runtimeState.tracksHasMore ? 64 : 0))
              .justifyContent(FlexAlign.Center)
            }
            .padding({ left: FnMusicUI.secondaryPagePadding, right: FnMusicUI.secondaryPagePadding })
          }
        }

        ListItem().height(this.bottomInset + FnMusicUI.sectionGap)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .cachedCount(3)
      .onDidScroll((): void => {
        this.detailScrollOffset = Math.max(0, this.detailScroller.currentOffset().yOffset);
      })
      .onReachEnd((): void => this.loadMore())
      }

      SecondaryPageHeader({
        title: this.headerTitle(),
        subtitle: this.isImageDetailCollection() ? '' : `${this.visibleTotal()} 首`,
        safeTop: this.safeTop,
        showTitle: !this.isImageDetailCollection() || this.detailHeaderCollapsed(),
        backgroundOpacity: this.headerOpacity(),
        headerBackground: this.backgroundEnd(),
        trailingDots: this.canRemoveFromPlaylist,
        onBack: (): void => this.onBack(),
        onTrailing: (): void => this.onPageMore()
      })
      .zIndex(20)
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,
      colors: [[this.backgroundStart(), 0], [this.backgroundEnd(), 1]]
    })
  }
}
