import { FnMusicUI } from '../../design/FnMusicUI';
import { MusicTrack } from '../../model/MusicModels';
import { MusicArtwork, SettingsRow } from '../common/MusicUiComponents';

@ComponentV2
export struct TrackActionsSheet {
  @Param track: MusicTrack = new MusicTrack();
  @Param canRemoveFromPlaylist: boolean = false;
  @Event onClose: () => void = (): void => {};
  @Event onPlayNext: () => void = (): void => {};
  @Event onAddQueue: () => void = (): void => {};
  @Event onFavorite: () => void = (): void => {};
  @Event onAddPlaylist: () => void = (): void => {};
  @Event onOpenAlbum: () => void = (): void => {};
  @Event onOpenArtist: () => void = (): void => {};
  @Event onRemove: () => void = (): void => {};

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.scrim'))
        .onClick((): void => this.onClose())

      Column({ space: 4 }) {
        Row({ space: FnMusicUI.contentGap }) {
          MusicArtwork({
            artworkSize: 52,
            radius: FnMusicUI.cardRadius,
            coverId: this.track.coverId,
            updatedAt: this.track.updatedAt
          })
          Column({ space: 3 }) {
            Text(this.track.title)
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.track.artistName)
              .fontSize(FnMusicUI.supportingSize)
              .fontColor($r('app.color.text_secondary'))
              .maxLines(1)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          Button({ type: ButtonType.Circle }) {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(20)
              .fontColor([$r('app.color.text_primary')])
          }
          .width(FnMusicUI.tapTarget)
          .height(FnMusicUI.tapTarget)
          .backgroundColor($r('app.color.surface_secondary'))
          .accessibilityText('关闭歌曲操作')
          .onClick((): void => this.onClose())
        }
        .width('100%')
        .padding({ left: 10, right: 4, bottom: 8 })

        Scroll() {
          Column() {
            SettingsRow({ title: '下一首播放', symbol: $r('sys.symbol.forward_end_fill'), onSelect: (): void => this.onPlayNext() })
            SettingsRow({ title: '加入播放队列', symbol: $r('sys.symbol.music_note_list'), onSelect: (): void => this.onAddQueue() })
            SettingsRow({
              title: this.track.isFavorite ? '取消收藏' : '收藏',
              symbol: this.track.isFavorite ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'),
              onSelect: (): void => this.onFavorite()
            })
            SettingsRow({ title: '加入歌单', symbol: $r('sys.symbol.plus_circle'), onSelect: (): void => this.onAddPlaylist() })
            SettingsRow({ title: '查看专辑', symbol: $r('sys.symbol.music_note_list'), onSelect: (): void => this.onOpenAlbum() })
            SettingsRow({ title: '查看歌手', symbol: $r('sys.symbol.person'), onSelect: (): void => this.onOpenArtist() })
            if (this.canRemoveFromPlaylist) {
              SettingsRow({
                title: '从歌单移除',
                symbol: $r('sys.symbol.trash'),
                destructive: true,
                showChevron: false,
                onSelect: (): void => this.onRemove()
              })
            }
          }
          .width('100%')
        }
        .height(336)
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
    .zIndex(50)
  }
}
