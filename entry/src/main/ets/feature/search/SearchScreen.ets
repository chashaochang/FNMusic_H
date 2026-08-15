import { FnMusicUI } from '../../design/FnMusicUI';
import { FnMusicMaterialRole, FnMusicMaterials } from '../../design/FnMusicMaterials';
import { MusicAlbum, MusicArtist, MusicTrack } from '../../model/MusicModels';
import {
  EmptyMusicState,
  MusicChipItem,
  MusicChipStrip
} from '../common/MusicUiComponents';
import { AlbumGrid, ArtistListItem, DenseTrackRow } from '../library/LibraryVisualComponents';

export interface SearchRequest {
  query: string;
  kind: string;
  immediate: boolean;
}

@ObservedV2
class SearchSectionState {
  @Trace selectedId: string = 'tracks';
}

@ComponentV2
struct SearchStickyChipHeader {
  @Param items: MusicChipItem[] = [];
  @Param state: SearchSectionState = new SearchSectionState();
  @Event onSelect: (id: string) => void = (_: string): void => {};

  build() {
    Row() {
      MusicChipStrip({
        items: this.items,
        selectedId: this.state.selectedId,
        onSelect: (id: string): void => this.onSelect(id)
      })
    }
    .width('100%')
    .height(FnMusicUI.chipHeight + FnMusicUI.compactGap)
    .padding({ left: FnMusicUI.pagePadding, right: FnMusicUI.pagePadding })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.Transparent)
    .zIndex(100)
    .hitTestBehavior(HitTestMode.Transparent)
  }
}

@ComponentV2
struct SearchTrackResults {
  @Param tracks: MusicTrack[] = [];
  @Event onPlay: (tracks: MusicTrack[], index: number) => void = (_: MusicTrack[], __: number): void => {};
  @Event onMore: (track: MusicTrack) => void = (_: MusicTrack): void => {};

  build() {
    Column() {
      if (this.tracks.length === 0) {
        EmptyMusicState({ title: '没有找到歌曲', message: '换个关键词再试试。', symbol: $r('sys.symbol.magnifyingglass') })
      } else {
        Repeat<MusicTrack>(this.tracks)
          .each((repeatItem: RepeatItem<MusicTrack>): void => {
            Column() {
              DenseTrackRow({
                track: repeatItem.item,
                index: repeatItem.index,
                onPlay: (index: number): void => {
                  this.onPlay(this.tracks, index);
                },
                onMore: (track: MusicTrack): void => {
                  this.onMore(track);
                }
              })
              Divider()
                .strokeWidth(0.5)
                .color($r('app.color.divider'))
                .margin({ left: 52 })
            }
          })
          .key((item: MusicTrack): string => item.guid)
      }
    }
    .width('100%')
  }
}

@ComponentV2
struct SearchAlbumResults {
  @Param albums: MusicAlbum[] = [];
  @Event onOpen: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};

  build() {
    if (this.albums.length === 0) {
      EmptyMusicState({ title: '没有找到专辑', message: '换个关键词再试试。', symbol: $r('sys.symbol.magnifyingglass') })
    } else {
      AlbumGrid({
        albums: this.albums,
        showPlay: false,
        onOpen: (album: MusicAlbum): void => this.onOpen(album)
      })
    }
  }
}

@ComponentV2
struct SearchArtistResults {
  @Param artists: MusicArtist[] = [];
  @Event onOpen: (artist: MusicArtist) => void = (_: MusicArtist): void => {};

  build() {
    Column() {
      if (this.artists.length === 0) {
        EmptyMusicState({ title: '没有找到歌手', message: '换个关键词再试试。', symbol: $r('sys.symbol.magnifyingglass') })
      } else {
        Repeat<MusicArtist>(this.artists)
          .each((repeatItem: RepeatItem<MusicArtist>): void => {
            Column() {
              ArtistListItem({ artist: repeatItem.item, onOpen: (artist: MusicArtist): void => this.onOpen(artist) })
              Divider()
                .strokeWidth(0.5)
                .color($r('app.color.divider'))
                .margin({ left: 60 })
            }
          })
          .key((item: MusicArtist): string => item.guid)
      }
    }
    .width('100%')
  }
}

@ComponentV2
struct RecentSearches {
  @Param searches: string[] = [];
  @Event onSelect: (value: string) => void = (_: string): void => {};
  @Event onClear: () => void = (): void => {};

  build() {
    Column({ space: FnMusicUI.contentGap }) {
      Row() {
        Text('最近搜索')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Blank()
        if (this.searches.length > 0) {
          Button('清空', { type: ButtonType.Normal })
            .height(36)
            .padding({ left: 12, right: 12 })
            .fontSize(14)
            .fontColor($r('app.color.accent'))
            .backgroundColor($r('app.color.transparent'))
            .borderRadius(FnMusicUI.controlRadius)
            .onClick((): void => {
              this.onClear();
            })
        }
      }
      .width('100%')

      if (this.searches.length === 0) {
        EmptyMusicState({ title: '还没有搜索记录', message: '搜索过的内容会留在这里。', symbol: $r('sys.symbol.magnifyingglass') })
      } else {
        Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          Repeat<string>(this.searches)
            .each((repeatItem: RepeatItem<string>): void => {
              Row({ space: 6 }) {
                SymbolGlyph($r('sys.symbol.arrow_clockwise'))
                  .fontSize(15)
                  .fontColor([$r('app.color.text_secondary')])
                Text(repeatItem.item)
                  .fontSize(14)
                  .fontColor($r('app.color.text_primary'))
                  .maxLines(1)
              }
              .height(36)
              .padding({ left: 12, right: 12 })
              .borderRadius(18)
              .backgroundColor($r('app.color.chip_idle'))
              .margin({ right: 8, bottom: 8 })
              .onClick((): void => {
                this.onSelect(repeatItem.item);
              })
            })
            .key((item: string): string => item)
        }
        .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

@ComponentV2
export struct SearchScreen {
  @Param tracks: MusicTrack[] = [];
  @Param albums: MusicAlbum[] = [];
  @Param artists: MusicArtist[] = [];
  @Param safeTop: number = 0;
  @Param bottomInset: number = 0;
  @Param loading: boolean = false;
  @Param errorMessage: string = '';
  @Local query: string = '';
  @Local sectionState: SearchSectionState = new SearchSectionState();
  @Local recentSearches: string[] = [];
  private debounceTimer: number = -1;
  @Event onBack: () => void = (): void => {};
  @Event onSearch: (request: SearchRequest) => void = (_: SearchRequest): void => {};
  @Event onPlay: (tracks: MusicTrack[], index: number) => void = (_: MusicTrack[], __: number): void => {};
  @Event onTrackMore: (track: MusicTrack) => void = (_: MusicTrack): void => {};
  @Event onOpenAlbum: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};
  @Event onOpenArtist: (artist: MusicArtist) => void = (_: MusicArtist): void => {};

  private readonly kinds: MusicChipItem[] = [
    { id: 'tracks', title: '歌曲' },
    { id: 'albums', title: '专辑' },
    { id: 'artists', title: '歌手' }
  ];

  private cancelDebounce(): void {
    if (this.debounceTimer >= 0) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = -1;
    }
  }

  private scheduleSearch(): void {
    this.cancelDebounce();
    if (this.query.trim().length === 0) {
      return;
    }
    this.debounceTimer = setTimeout((): void => {
      this.debounceTimer = -1;
      this.onSearch({ query: this.query.trim(), kind: this.sectionState.selectedId, immediate: false });
    }, 400);
  }

  private executeSearch(value: string, immediate: boolean): void {
    const normalized: string = value.trim();
    this.query = normalized;
    this.cancelDebounce();
    if (normalized.length === 0) {
      return;
    }
    const filtered: string[] = this.recentSearches.filter((item: string): boolean => item !== normalized);
    this.recentSearches = [normalized].concat(filtered).slice(0, 8);
    this.onSearch({ query: normalized, kind: this.sectionState.selectedId, immediate: immediate });
  }

  aboutToDisappear(): void {
    this.cancelDebounce();
  }

  @Builder
  searchStickyHeader() {
    SearchStickyChipHeader({
      items: this.kinds,
      state: this.sectionState,
      onSelect: (id: string): void => {
        this.sectionState.selectedId = id;
        this.executeSearch(this.query, true);
      }
    })
  }

  build() {
    Column() {
      Row({ space: FnMusicUI.compactGap }) {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph($r('sys.symbol.chevron_backward'))
            .fontSize(23)
            .fontColor([$r('app.color.text_primary')])
        }
        .width(FnMusicUI.tapTarget)
        .height(FnMusicUI.tapTarget)
        .backgroundColor(Color.Transparent)
        .systemMaterial(FnMusicMaterials.material(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
        .accessibilityText('返回')
        .onClick((): void => {
          this.onBack();
        })

        Search({ value: this.query, placeholder: '搜索歌曲、专辑或歌手' })
          .layoutWeight(1)
          .height(FnMusicUI.searchHeight)
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_secondary'))
          .textFont({ size: FnMusicUI.bodySize })
          .searchIcon({ size: 19, color: $r('app.color.text_secondary') })
          .cancelButton({ style: CancelButtonStyle.INPUT, icon: { size: 18, color: $r('app.color.text_secondary') } })
          .searchButton('搜索', { fontSize: 14, fontColor: $r('app.color.accent') })
          .borderRadius(FnMusicUI.searchHeight / 2)
          .backgroundColor(Color.Transparent)
          .clip(true)
          .systemMaterial(FnMusicMaterials.material(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
          .onChange((value: string): void => {
            this.query = value;
            this.scheduleSearch();
          })
          .onSubmit((value: string): void => {
            this.executeSearch(value, true);
          })
      }
      .width('100%')
      .height(Math.max(0, this.safeTop) + FnMusicUI.homeActionBarHeight)
      .padding({
        left: FnMusicUI.pagePadding,
        right: FnMusicUI.pagePadding,
        top: Math.max(0, this.safeTop)
      })
      .backgroundColor(Color.Transparent)

      List({ space: 0 }) {
        if (this.query.trim().length === 0) {
          ListItem() {
            RecentSearches({
              searches: this.recentSearches,
              onSelect: (value: string): void => {
                this.executeSearch(value, true);
              },
              onClear: (): void => {
                this.recentSearches = [];
              }
            })
          }
          .padding({
            left: FnMusicUI.pagePadding,
            right: FnMusicUI.pagePadding,
            top: FnMusicUI.contentGap
          })
        } else {
          ListItemGroup({ header: this.searchStickyHeader }) {
            ListItem() {
              if (this.loading) {
                Column({ space: FnMusicUI.compactGap }) {
                  LoadingProgress()
                    .width(28)
                    .height(28)
                    .color($r('app.color.accent'))
                  Text('正在搜索')
                    .fontSize(FnMusicUI.supportingSize)
                    .fontColor($r('app.color.text_secondary'))
                }
                .width('100%')
                .height(180)
                .justifyContent(FlexAlign.Center)
              } else if (this.errorMessage.length > 0) {
                EmptyMusicState({
                  title: '搜索失败',
                  message: this.errorMessage,
                  symbol: $r('sys.symbol.exclamationmark_circle_fill')
                })
              } else if (this.sectionState.selectedId === 'tracks') {
                SearchTrackResults({
                  tracks: this.tracks,
                  onPlay: (tracks: MusicTrack[], index: number): void => this.onPlay(tracks, index),
                  onMore: (track: MusicTrack): void => this.onTrackMore(track)
                })
              } else if (this.sectionState.selectedId === 'albums') {
                SearchAlbumResults({
                  albums: this.albums,
                  onOpen: (album: MusicAlbum): void => this.onOpenAlbum(album)
                })
              } else {
                SearchArtistResults({
                  artists: this.artists,
                  onOpen: (artist: MusicArtist): void => this.onOpenArtist(artist)
                })
              }
            }
            .padding({
              left: FnMusicUI.pagePadding,
              right: FnMusicUI.pagePadding,
              top: FnMusicUI.contentGap
            })
          }
        }

        ListItem().height(this.bottomInset + FnMusicUI.sectionGap)
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .sticky(StickyStyle.Header)
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
