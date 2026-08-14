import { FnMusicUI } from '../../design/FnMusicUI';
import { AuthPhase } from '../../auth/ConnectionModels';
import { AppRuntime, AppRuntimeState } from '../../common/AppRuntime';
import { MusicAlbum, MusicArtist, MusicGenre } from '../../model/MusicModels';
import { AlbumRow, ArtistRow, EmptyMusicState, GenreRow, SecondaryPageHeader } from '../common/MusicUiComponents';

@ComponentV2
struct CatalogPagingFooter {
  @Param loaded: number = 0;
  @Param total: number = 0;
  @Param hasMore: boolean = false;
  @Param loading: boolean = false;
  @Param errorMessage: string = '';
  @Event onRetry: () => void = (): void => {};

  build() {
    Column({ space: FnMusicUI.compactGap }) {
      if (this.loading) {
        LoadingProgress()
          .width(24)
          .height(24)
          .color($r('app.color.accent'))
        Text('正在加载更多')
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.text_secondary'))
      } else if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
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
          .onClick((): void => this.onRetry())
      } else if (this.hasMore) {
        Text(this.total > 0 ? `已加载 ${this.loaded} / 共 ${this.total}` : `已加载 ${this.loaded}`)
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.text_secondary'))
      }
    }
    .width('100%')
    .height(this.errorMessage.length > 0 ? 96 : (this.loading || this.hasMore ? 64 : 0))
    .justifyContent(FlexAlign.Center)
  }
}

@ComponentV2
export struct AlbumCollectionScreen {
  @Param albums: MusicAlbum[] = [];
  @Param safeTop: number = 0;
  @Param bottomInset: number = 0;
  @Local runtimeState: AppRuntimeState = AppRuntime.state();
  @Event onBack: () => void = (): void => {};
  @Event onOpen: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};

  private hasRuntimeCatalog(): boolean {
    return this.runtimeState.phase === AuthPhase.AUTHENTICATED;
  }

  private totalCount(): number {
    return this.hasRuntimeCatalog() ? Math.max(this.runtimeState.albumTotal, this.albums.length) : this.albums.length;
  }

  private loadMore(): void {
    if (this.hasRuntimeCatalog()) {
      AppRuntime.loadMoreAlbums().catch((): void => {});
    }
  }

  build() {
    Column() {
      SecondaryPageHeader({
        title: '专辑', subtitle: `${this.totalCount()} 张专辑`, safeTop: this.safeTop,
        onBack: (): void => this.onBack()
      })
      List({ space: FnMusicUI.compactGap }) {
        if (this.albums.length === 0) {
          ListItem() {
            EmptyMusicState({ title: '还没有专辑', message: '专辑数据同步后会显示在这里。' })
          }
        } else {
          Repeat<MusicAlbum>(this.albums)
            .each((repeatItem: RepeatItem<MusicAlbum>): void => {
              ListItem() {
                AlbumRow({ album: repeatItem.item, onOpen: (album: MusicAlbum): void => this.onOpen(album) })
              }
              .padding({ left: 10, right: 10 })
              .borderRadius(FnMusicUI.cardRadius)
              .backgroundColor($r('app.color.surface'))
            })
            .key((item: MusicAlbum): string => item.guid)
            .virtualScroll()
        }
        if (this.hasRuntimeCatalog()) {
          ListItem() {
            CatalogPagingFooter({
              loaded: this.albums.length,
              total: this.totalCount(),
              hasMore: this.runtimeState.albumsHasMore,
              loading: this.runtimeState.albumsLoadingMore,
              errorMessage: this.runtimeState.albumsLoadMoreError,
              onRetry: (): void => this.loadMore()
            })
          }
        }
        ListItem().height(this.bottomInset + FnMusicUI.sectionGap)
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: FnMusicUI.pagePadding, right: FnMusicUI.pagePadding })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .onReachEnd((): void => this.loadMore())
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}

@ComponentV2
export struct ArtistCollectionScreen {
  @Param artists: MusicArtist[] = [];
  @Param safeTop: number = 0;
  @Param bottomInset: number = 0;
  @Local runtimeState: AppRuntimeState = AppRuntime.state();
  @Event onBack: () => void = (): void => {};
  @Event onOpen: (artist: MusicArtist) => void = (_: MusicArtist): void => {};

  private hasRuntimeCatalog(): boolean {
    return this.runtimeState.phase === AuthPhase.AUTHENTICATED;
  }

  private totalCount(): number {
    return this.hasRuntimeCatalog() ? Math.max(this.runtimeState.artistTotal, this.artists.length) : this.artists.length;
  }

  private loadMore(): void {
    if (this.hasRuntimeCatalog()) {
      AppRuntime.loadMoreArtists().catch((): void => {});
    }
  }

  build() {
    Column() {
      SecondaryPageHeader({
        title: '歌手', subtitle: `${this.totalCount()} 位歌手`, safeTop: this.safeTop,
        onBack: (): void => this.onBack()
      })
      List({ space: FnMusicUI.compactGap }) {
        if (this.artists.length === 0) {
          ListItem() {
            EmptyMusicState({ title: '还没有歌手', message: '歌手数据同步后会显示在这里。', symbol: $r('sys.symbol.person_fill') })
          }
        } else {
          Repeat<MusicArtist>(this.artists)
            .each((repeatItem: RepeatItem<MusicArtist>): void => {
              ListItem() {
                ArtistRow({ artist: repeatItem.item, onOpen: (artist: MusicArtist): void => this.onOpen(artist) })
              }
              .padding({ left: 10, right: 10 })
              .borderRadius(FnMusicUI.cardRadius)
              .backgroundColor($r('app.color.surface'))
            })
            .key((item: MusicArtist): string => item.guid)
            .virtualScroll()
        }
        if (this.hasRuntimeCatalog()) {
          ListItem() {
            CatalogPagingFooter({
              loaded: this.artists.length,
              total: this.totalCount(),
              hasMore: this.runtimeState.artistsHasMore,
              loading: this.runtimeState.artistsLoadingMore,
              errorMessage: this.runtimeState.artistsLoadMoreError,
              onRetry: (): void => this.loadMore()
            })
          }
        }
        ListItem().height(this.bottomInset + FnMusicUI.sectionGap)
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: FnMusicUI.pagePadding, right: FnMusicUI.pagePadding })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .onReachEnd((): void => this.loadMore())
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}

@ComponentV2
export struct GenreCollectionScreen {
  @Param genres: MusicGenre[] = [];
  @Param safeTop: number = 0;
  @Param bottomInset: number = 0;
  @Local runtimeState: AppRuntimeState = AppRuntime.state();
  @Event onBack: () => void = (): void => {};
  @Event onOpen: (genre: MusicGenre) => void = (_: MusicGenre): void => {};

  private hasRuntimeCatalog(): boolean {
    return this.runtimeState.phase === AuthPhase.AUTHENTICATED;
  }

  private totalCount(): number {
    return this.hasRuntimeCatalog() ? Math.max(this.runtimeState.genreTotal, this.genres.length) : this.genres.length;
  }

  private loadMore(): void {
    if (this.hasRuntimeCatalog()) {
      AppRuntime.loadMoreGenres().catch((): void => {});
    }
  }

  build() {
    Column() {
      SecondaryPageHeader({
        title: '风格', subtitle: `${this.totalCount()} 种风格`, safeTop: this.safeTop,
        onBack: (): void => this.onBack()
      })
      List({ space: FnMusicUI.compactGap }) {
        if (this.genres.length === 0) {
          ListItem() {
            EmptyMusicState({ title: '还没有风格', message: '风格数据同步后会显示在这里。', symbol: $r('sys.symbol.music_badge_wave_2') })
          }
        } else {
          Repeat<MusicGenre>(this.genres)
            .each((repeatItem: RepeatItem<MusicGenre>): void => {
              ListItem() {
                GenreRow({ genre: repeatItem.item, onOpen: (genre: MusicGenre): void => this.onOpen(genre) })
              }
              .padding({ left: 10, right: 10 })
              .borderRadius(FnMusicUI.cardRadius)
              .backgroundColor($r('app.color.surface'))
            })
            .key((item: MusicGenre): string => item.guid)
            .virtualScroll()
        }
        if (this.hasRuntimeCatalog()) {
          ListItem() {
            CatalogPagingFooter({
              loaded: this.genres.length,
              total: this.totalCount(),
              hasMore: this.runtimeState.genresHasMore,
              loading: this.runtimeState.genresLoadingMore,
              errorMessage: this.runtimeState.genresLoadMoreError,
              onRetry: (): void => this.loadMore()
            })
          }
        }
        ListItem().height(this.bottomInset + FnMusicUI.sectionGap)
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: FnMusicUI.pagePadding, right: FnMusicUI.pagePadding })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .onReachEnd((): void => this.loadMore())
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}
