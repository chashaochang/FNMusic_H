import { FnMusicUI } from '../../design/FnMusicUI';
import { MusicPlaylist } from '../../model/MusicModels';
import {
  EmptyMusicState,
  MusicEmptyKind,
  MusicArtwork,
  PlaylistRow,
  SectionHeader,
  VerticalMoreDots
} from '../common/MusicUiComponents';
import { LongTakeSource, transitionSourceId } from '../../navigation/LongTakeNavigation';

@ComponentV2
struct PlaylistGridItem {
  @Param playlist: MusicPlaylist = new MusicPlaylist();
  @Param itemWidth: number = FnMusicUI.homeCatalogGridItemSize;
  @Param transitionScope: string = 'playlist_grid';
  @Event onOpen: (playlist: MusicPlaylist, source: LongTakeSource) => void =
    (_: MusicPlaylist, __: LongTakeSource): void => {};
  @Event onMore: (playlist: MusicPlaylist) => void = (_: MusicPlaylist): void => {};

  private sourceId(): string {
    return transitionSourceId(this.transitionScope, 'playlist', this.playlist.guid);
  }

  build() {
    Column({ space: 8 }) {
      Stack({ alignContent: Alignment.BottomStart }) {
        MusicArtwork({
          artworkSize: this.itemWidth,
          radius: FnMusicUI.albumGridRadius,
          symbol: $r('sys.symbol.music_note_list'),
          placeholderMedia: $r('app.media.music_album_placeholder'),
          placeholderRatio: 0.7,
          coverId: this.playlist.coverId,
          updatedAt: this.playlist.updatedAt
        })
        .id(this.sourceId())
        .onClick((): void => this.onOpen(
          this.playlist,
          new LongTakeSource(this.sourceId(), FnMusicUI.albumGridRadius)
        ))

        Row({ space: 4 }) {
          SymbolGlyph($r('sys.symbol.music_note_list'))
            .fontSize(12)
            .fontColor([$r('app.color.album_count_badge_text')])
          Text(`${this.playlist.trackCount} 首`)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.album_count_badge_text'))
        }
        .height(26)
        .padding({ left: 9, right: 9 })
        .borderRadius(13)
        .backgroundColor($r('app.color.album_count_badge_bg'))
        .translate({ x: 8, y: -8 })
        .hitTestBehavior(HitTestMode.None)
      }
      .width(this.itemWidth)
      .height(this.itemWidth)

      Row({ space: 4 }) {
        Column({ space: 3 }) {
          Text(this.playlist.name)
            .fontSize(FnMusicUI.bodySize)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.playlist.description.length > 0) {
          Text(this.playlist.description)
            .fontSize(FnMusicUI.supportingSize)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .onClick((): void => this.onOpen(
          this.playlist,
          new LongTakeSource(this.sourceId(), FnMusicUI.albumGridRadius)
        ))

        Button({ type: ButtonType.Circle, stateEffect: true }) {
          VerticalMoreDots()
        }
        .width(36)
        .height(36)
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .backgroundColor(Color.Transparent)
        .accessibilityText(`${this.playlist.name} 更多操作`)
        .onClick((): void => this.onMore(this.playlist))
      }
      .width(this.itemWidth)
      .alignItems(VerticalAlign.Top)
    }
    .width(this.itemWidth)
    .alignItems(HorizontalAlign.Start)
  }
}

@ComponentV2
export struct PlaylistCollectionSection {
  @Param playlists: MusicPlaylist[] = [];
  @Event onOpenPlaylist: (playlist: MusicPlaylist) => void = (_: MusicPlaylist): void => {};
  @Event onPlaylistMore: (playlist: MusicPlaylist) => void = (_: MusicPlaylist): void => {};
  @Event onCreatePlaylist: () => void = (): void => {};

  build() {
    Column({ space: 6 }) {
      SectionHeader({
        title: '自建歌单',
        supporting: `${this.playlists.length} 个歌单`,
        actionTitle: '新建',
        onAction: (): void => this.onCreatePlaylist()
      })

      if (this.playlists.length === 0) {
        EmptyMusicState({
          kind: MusicEmptyKind.LIST,
          title: '还没有自建歌单',
          message: '点击「新建」创建第一个歌单。'
        })
      } else {
        Column() {
          Repeat<MusicPlaylist>(this.playlists)
            .each((repeatItem: RepeatItem<MusicPlaylist>): void => {
              PlaylistRow({
                playlist: repeatItem.item,
                onOpen: (playlist: MusicPlaylist): void => this.onOpenPlaylist(playlist),
                onMore: (playlist: MusicPlaylist): void => this.onPlaylistMore(playlist)
              })
            })
            .key((item: MusicPlaylist): string => item.guid)
        }
        .width('100%')
        .padding({ left: 10, right: 8 })
        .borderRadius(FnMusicUI.cardRadius)
        .backgroundColor($r('app.color.surface'))
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

@ComponentV2
export struct PlaylistScreen {
  @Param playlists: MusicPlaylist[] = [];
  @Param safeTop: number = 0;
  @Param bottomInset: number = 0;
  @Event onOpenPlaylist: (playlist: MusicPlaylist, source: LongTakeSource) => void =
    (_: MusicPlaylist, __: LongTakeSource): void => {};
  @Event onPlaylistMore: (playlist: MusicPlaylist) => void = (_: MusicPlaylist): void => {};

  private rowIndexes(): number[] {
    const indexes: number[] = [];
    const rowCount: number = Math.ceil(this.playlists.length / 2);
    for (let index: number = 0; index < rowCount; index++) {
      indexes.push(index);
    }
    return indexes;
  }

  build() {
    List({ space: 0 }) {
      ListItem() {
        SectionHeader({
          title: '自建歌单',
          supporting: `共 ${this.playlists.length} 个歌单`
        })
      }
      .padding({
        left: FnMusicUI.pagePadding,
        right: FnMusicUI.pagePadding,
        top: Math.max(0, this.safeTop) + FnMusicUI.secondaryHeaderHeight + FnMusicUI.contentGap,
        bottom: FnMusicUI.homeTitleToContentGap
      })

      if (this.playlists.length === 0) {
        ListItem() {
          EmptyMusicState({
            kind: MusicEmptyKind.LIST,
            title: '还没有自建歌单',
            message: '点击右上角新建第一个歌单。'
          })
        }
        .padding({ left: FnMusicUI.pagePadding, right: FnMusicUI.pagePadding })
      } else {
        Repeat<number>(this.rowIndexes())
          .each((repeatItem: RepeatItem<number>): void => {
            ListItem() {
              Row({ space: FnMusicUI.albumGridGap }) {
                PlaylistGridItem({
                  playlist: this.playlists[repeatItem.item * 2],
                  transitionScope: 'playlist_tab',
                  onOpen: (playlist: MusicPlaylist, source: LongTakeSource): void =>
                    this.onOpenPlaylist(playlist, source),
                  onMore: (playlist: MusicPlaylist): void => this.onPlaylistMore(playlist)
                })
                if (repeatItem.item * 2 + 1 < this.playlists.length) {
                  PlaylistGridItem({
                    playlist: this.playlists[repeatItem.item * 2 + 1],
                    transitionScope: 'playlist_tab',
                    onOpen: (playlist: MusicPlaylist, source: LongTakeSource): void =>
                      this.onOpenPlaylist(playlist, source),
                    onMore: (playlist: MusicPlaylist): void => this.onPlaylistMore(playlist)
                  })
                } else {
                  Blank().width(FnMusicUI.homeCatalogGridItemSize)
                }
              }
              .width('100%')
            }
            .padding({
              left: FnMusicUI.pagePadding,
              right: FnMusicUI.pagePadding,
              bottom: FnMusicUI.sectionGap
            })
          })
          .key((item: number): string => `${item}`)
      }

      ListItem()
        .height(this.bottomInset + FnMusicUI.sectionGap)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .linearGradient({
      angle: 180,
      colors: [
        [$r('app.color.page_catalog_background_start'), 0],
        [$r('app.color.page_catalog_background_end'), 1]
      ]
    })
  }
}
