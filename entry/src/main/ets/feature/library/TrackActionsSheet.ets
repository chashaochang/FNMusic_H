import { FnMusicUI } from '../../design/FnMusicUI';
import { FnMusicMaterialRole, FnMusicMaterials } from '../../design/FnMusicMaterials';
import { MusicTrack } from '../../model/MusicModels';

@ComponentV2
struct TrackActionRow {
  @Param title: string = '';
  @Param symbol: Resource = $r('sys.symbol.music');
  @Param highlighted: boolean = false;
  @Param destructive: boolean = false;
  @Param showDivider: boolean = true;
  @Event onSelect: () => void = (): void => {};

  private foreground(): ResourceColor {
    if (this.destructive) {
      return $r('app.color.danger');
    }
    if (this.highlighted) {
      return $r('app.color.accent');
    }
    return $r('app.color.text_primary');
  }

  build() {
    Column() {
      Row({ space: FnMusicUI.contentGap }) {
        SymbolGlyph(this.symbol)
          .width(26)
          .fontSize(22)
          .fontColor([this.foreground()])
        Text(this.title)
          .layoutWeight(1)
          .fontSize(FnMusicUI.bodySize)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.foreground())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .height(FnMusicUI.listRowHeight)
      .padding({ left: 14, right: 14 })
      .alignItems(VerticalAlign.Center)

      if (this.showDivider) {
        Row() {
          Blank().width(52)
          Divider()
            .layoutWeight(1)
            .strokeWidth(0.5)
            .color($r('app.color.divider'))
        }
        .width('100%')
        .height(1)
        .padding({ right: 14 })
      }
    }
    .width('100%')
    .onClick((): void => this.onSelect())
  }
}

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

  private actionListHeight(): number {
    const count = this.canRemoveFromPlaylist ? 7 : 6;
    return count * (FnMusicUI.listRowHeight + 1) - 1;
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.scrim'))
        .onClick((): void => this.onClose())

      Column() {
        Row({ space: FnMusicUI.contentGap }) {
          Text(this.track.title)
            .layoutWeight(1)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Button({ type: ButtonType.Circle }) {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(19)
              .fontColor([$r('app.color.text_primary')])
          }
          .width(FnMusicUI.tapTarget)
          .height(FnMusicUI.tapTarget)
          .backgroundColor($r('app.color.surface_secondary'))
          .systemMaterial(FnMusicMaterials.material(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
          .accessibilityText('关闭歌曲操作')
          .onClick((): void => this.onClose())
        }
        .width('100%')
        .height(64)
        .padding({ left: 14, right: 10 })
        .alignItems(VerticalAlign.Center)

        Scroll() {
          Column() {
            TrackActionRow({
              title: '下一首播放',
              symbol: $r('sys.symbol.forward_end_fill'),
              onSelect: (): void => this.onPlayNext()
            })
            TrackActionRow({
              title: '加入播放队列',
              symbol: $r('sys.symbol.music_note_list'),
              onSelect: (): void => this.onAddQueue()
            })
            TrackActionRow({
              title: this.track.isFavorite ? '取消收藏' : '添加至收藏',
              symbol: this.track.isFavorite ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'),
              highlighted: this.track.isFavorite,
              onSelect: (): void => this.onFavorite()
            })
            TrackActionRow({
              title: '添加至歌单',
              symbol: $r('sys.symbol.plus_circle'),
              onSelect: (): void => this.onAddPlaylist()
            })
            TrackActionRow({
              title: this.track.artistName.length > 0 ? `查看歌手：${this.track.artistName}` : '查看歌手',
              symbol: $r('sys.symbol.person'),
              onSelect: (): void => this.onOpenArtist()
            })
            TrackActionRow({
              title: this.track.albumName.length > 0 ? `查看专辑：${this.track.albumName}` : '查看专辑',
              symbol: $r('sys.symbol.music_note_list'),
              showDivider: this.canRemoveFromPlaylist,
              onSelect: (): void => this.onOpenAlbum()
            })
            if (this.canRemoveFromPlaylist) {
              TrackActionRow({
                title: '从歌单移除',
                symbol: $r('sys.symbol.trash'),
                destructive: true,
                showDivider: false,
                onSelect: (): void => this.onRemove()
              })
            }
          }
          .width('100%')
        }
        .height(this.actionListHeight())
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .padding({ bottom: 24 })
      .borderRadius({ topLeft: FnMusicUI.cardRadius + 8, topRight: FnMusicUI.cardRadius + 8 })
      .backgroundColor($r('app.color.surface_elevated'))
      .clip(true)
      .systemMaterial(FnMusicMaterials.material(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
      .transition(TransitionEffect.translate({ y: 72 }).combine(TransitionEffect.OPACITY))
    }
    .width('100%')
    .height('100%')
    .zIndex(50)
  }
}
