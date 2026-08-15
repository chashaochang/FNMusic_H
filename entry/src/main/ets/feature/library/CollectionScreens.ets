import { FnMusicUI } from '../../design/FnMusicUI';
import { AuthPhase } from '../../auth/ConnectionModels';
import { AppRuntime, AppRuntimeState } from '../../common/AppRuntime';
import { MusicAlbum, MusicArtist, MusicGenre } from '../../model/MusicModels';
import { EmptyMusicState, SecondaryPageHeader } from '../common/MusicUiComponents';
import { AlbumCatalogItem, ArtistCatalogItem, GenreGridItem } from './LibraryVisualComponents';

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
  @Event onPlay: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};

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
      List({ space: 0 }) {
        if (this.albums.length === 0) {
          ListItem() {
            EmptyMusicState({ title: '还没有专辑', message: '专辑数据同步后会显示在这里。' })
          }
        } else {
          Repeat<MusicAlbum>(this.albums)
            .each((repeatItem: RepeatItem<MusicAlbum>): void => {
              ListItem() {
                Column() {
                  AlbumCatalogItem({
                    album: repeatItem.item,
                    showPlay: true,
                    onOpen: (album: MusicAlbum): void => this.onOpen(album),
                    onPlay: (album: MusicAlbum): void => this.onPlay(album)
                  })
                  Divider()
                    .strokeWidth(0.5)
                    .color($r('app.color.divider'))
                    .margin({ left: 74 })
                }
              }
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
      .padding({ left: FnMusicUI.secondaryPagePadding, right: FnMusicUI.secondaryPagePadding })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .cachedCount(3)
      .onReachEnd((): void => this.loadMore())
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,
      colors: [
        [$r('app.color.page_catalog_background_start'), 0],
        [$r('app.color.page_catalog_background_end'), 1]
      ]
    })
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
      List({ space: 0 }) {
        if (this.artists.length === 0) {
          ListItem() {
            EmptyMusicState({ title: '还没有歌手', message: '歌手数据同步后会显示在这里。', symbol: $r('sys.symbol.person_fill') })
          }
        } else {
          Repeat<MusicArtist>(this.artists)
            .each((repeatItem: RepeatItem<MusicArtist>): void => {
              ListItem() {
                Column() {
                  ArtistCatalogItem({ artist: repeatItem.item, onOpen: (artist: MusicArtist): void => this.onOpen(artist) })
                  Divider()
                    .strokeWidth(0.5)
                    .color($r('app.color.divider'))
                    .margin({ left: 72 })
                }
              }
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
      .padding({ left: FnMusicUI.secondaryPagePadding, right: FnMusicUI.secondaryPagePadding })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .cachedCount(3)
      .onReachEnd((): void => this.loadMore())
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,
      colors: [
        [$r('app.color.page_artist_background_start'), 0],
        [$r('app.color.page_artist_background_end'), 1]
      ]
    })
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

  private rowIndexes(): number[] {
    const indexes: number[] = [];
    const rowCount: number = Math.ceil(this.genres.length / 2);
    for (let index: number = 0; index < rowCount; index++) {
      indexes.push(index);
    }
    return indexes;
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
      List({ space: FnMusicUI.albumGridGap }) {
        if (this.genres.length === 0) {
          ListItem() {
            EmptyMusicState({ title: '还没有风格', message: '风格数据同步后会显示在这里。', symbol: $r('sys.symbol.music_badge_wave_2') })
          }
        } else {
          Repeat<number>(this.rowIndexes())
            .each((repeatItem: RepeatItem<number>): void => {
              ListItem() {
                Row({ space: FnMusicUI.albumGridGap }) {
                  GenreGridItem({
                    genre: this.genres[repeatItem.item * 2],
                    onOpen: (genre: MusicGenre): void => this.onOpen(genre)
                  })
                  if (repeatItem.item * 2 + 1 < this.genres.length) {
                    GenreGridItem({
                      genre: this.genres[repeatItem.item * 2 + 1],
                      onOpen: (genre: MusicGenre): void => this.onOpen(genre)
                    })
                  } else {
                    Blank().width(FnMusicUI.albumGridItemSize)
                  }
                }
                .width('100%')
              }
            })
            .key((item: number): string => `${item}`)
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
      .padding({ left: FnMusicUI.secondaryPagePadding, right: FnMusicUI.secondaryPagePadding })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .cachedCount(3)
      .onReachEnd((): void => this.loadMore())
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,
      colors: [
        [$r('app.color.page_genre_background_start'), 0],
        [$r('app.color.page_genre_background_end'), 1]
      ]
    })
  }
}
