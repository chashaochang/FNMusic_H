import { FnMusicUI } from '../../design/FnMusicUI';
import { FnMusicMaterialRole, FnMusicMaterials } from '../../design/FnMusicMaterials';

export enum PlaylistSortKey {
  ADDED_DATE = 'added_date',
  TITLE = 'title'
}

export enum PlaylistSortOrder {
  ASCENDING = 'ascending',
  DESCENDING = 'descending'
}

@ComponentV2
struct PlaylistSheetHeader {
  @Param title: string = '';
  @Event onClose: () => void = (): void => {};

  build() {
    Row() {
      Text(this.title)
        .layoutWeight(1)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(19)
          .fontColor([$r('app.color.text_primary')])
      }
      .width(FnMusicUI.tapTarget)
      .height(FnMusicUI.tapTarget)
      .backgroundColor(Color.Transparent)
      .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
      .accessibilityText(`关闭${this.title}`)
      .onClick((): void => this.onClose())
    }
    .width('100%')
    .height(FnMusicUI.listRowHeight)
    .padding({ left: 14, right: 8 })
    .alignItems(VerticalAlign.Center)
  }
}

@ComponentV2
struct PlaylistChoiceRow {
  @Param title: string = '';
  @Param selected: boolean = false;
  @Event onSelect: () => void = (): void => {};

  build() {
    Row({ space: FnMusicUI.contentGap }) {
      Text(this.title)
        .layoutWeight(1)
        .fontSize(FnMusicUI.bodySize)
        .fontWeight(this.selected ? FontWeight.Medium : FontWeight.Regular)
        .fontColor($r('app.color.text_primary'))
      if (this.selected) {
        SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
          .fontSize(21)
          .fontColor([$r('app.color.accent')])
      } else {
        Blank().width(21)
      }
    }
    .width('100%')
    .height(FnMusicUI.listRowHeight)
    .padding({ left: 14, right: 14 })
    .borderRadius(FnMusicUI.controlRadius)
    .backgroundColor(this.selected ? $r('app.color.surface_secondary') : Color.Transparent)
    .onClick((): void => this.onSelect())
  }
}

@ComponentV2
export struct PlaylistSortSheet {
  @Param sortKey: PlaylistSortKey = PlaylistSortKey.ADDED_DATE;
  @Param sortOrder: PlaylistSortOrder = PlaylistSortOrder.DESCENDING;
  @Event onClose: () => void = (): void => {};
  @Event onSortKey: (key: PlaylistSortKey) => void = (_: PlaylistSortKey): void => {};
  @Event onSortOrder: (order: PlaylistSortOrder) => void = (_: PlaylistSortOrder): void => {};

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.scrim'))
        .onClick((): void => this.onClose())

      Column({ space: 4 }) {
        PlaylistSheetHeader({ title: '排序', onClose: (): void => this.onClose() })

        Text('排序依据')
          .width('100%')
          .padding({ left: 14, right: 14, top: 4, bottom: 2 })
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.text_secondary'))
        PlaylistChoiceRow({
          title: '按添加日期',
          selected: this.sortKey === PlaylistSortKey.ADDED_DATE,
          onSelect: (): void => this.onSortKey(PlaylistSortKey.ADDED_DATE)
        })
        PlaylistChoiceRow({
          title: '按歌曲名',
          selected: this.sortKey === PlaylistSortKey.TITLE,
          onSelect: (): void => this.onSortKey(PlaylistSortKey.TITLE)
        })

        Divider()
          .strokeWidth(0.5)
          .color($r('app.color.divider'))
          .margin({ left: 14, right: 14, top: 4, bottom: 4 })

        Text('排序顺序')
          .width('100%')
          .padding({ left: 14, right: 14, top: 2, bottom: 2 })
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.text_secondary'))
        PlaylistChoiceRow({
          title: '升序',
          selected: this.sortOrder === PlaylistSortOrder.ASCENDING,
          onSelect: (): void => this.onSortOrder(PlaylistSortOrder.ASCENDING)
        })
        PlaylistChoiceRow({
          title: '降序',
          selected: this.sortOrder === PlaylistSortOrder.DESCENDING,
          onSelect: (): void => this.onSortOrder(PlaylistSortOrder.DESCENDING)
        })
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 8, bottom: 24 })
      .borderRadius({ topLeft: FnMusicUI.cardRadius + 8, topRight: FnMusicUI.cardRadius + 8 })
      .backgroundColor($r('app.color.surface_elevated'))
      .clip(true)
      .transition(
        TransitionEffect.translate({ y: 72 })
          .combine(TransitionEffect.OPACITY)
          .animation({ duration: 240, curve: Curve.FastOutSlowIn })
      )
    }
    .width('100%')
    .height('100%')
    .zIndex(50)
    .transition(TransitionEffect.OPACITY.animation({ duration: 180, curve: Curve.EaseOut }))
  }
}

@ComponentV2
struct PlaylistActionRow {
  @Param title: string = '';
  @Param symbol: Resource = $r('sys.symbol.music_note_list');
  @Param destructive: boolean = false;
  @Param showDivider: boolean = true;
  @Event onSelect: () => void = (): void => {};

  build() {
    Column() {
      Row({ space: FnMusicUI.contentGap }) {
        SymbolGlyph(this.symbol)
          .width(26)
          .fontSize(21)
          .fontColor([this.destructive ? $r('app.color.danger') : $r('app.color.text_primary')])
        Text(this.title)
          .layoutWeight(1)
          .fontSize(FnMusicUI.bodySize)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.destructive ? $r('app.color.danger') : $r('app.color.text_primary'))
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
export struct PlaylistActionsSheet {
  @Event onClose: () => void = (): void => {};
  @Event onMultiSelect: () => void = (): void => {};
  @Event onClearUnavailable: () => void = (): void => {};
  @Event onEdit: () => void = (): void => {};
  @Event onDelete: () => void = (): void => {};

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.scrim'))
        .onClick((): void => this.onClose())

      Column() {
        PlaylistSheetHeader({ title: '歌单操作', onClose: (): void => this.onClose() })
        PlaylistActionRow({
          title: '多选',
          symbol: $r('sys.symbol.checkmark_circle_fill'),
          onSelect: (): void => this.onMultiSelect()
        })
        PlaylistActionRow({
          title: '清除失效歌曲',
          symbol: $r('sys.symbol.arrow_clockwise'),
          onSelect: (): void => this.onClearUnavailable()
        })
        PlaylistActionRow({
          title: '编辑',
          symbol: $r('sys.symbol.gearshape'),
          onSelect: (): void => this.onEdit()
        })
        PlaylistActionRow({
          title: '删除',
          symbol: $r('sys.symbol.trash'),
          destructive: true,
          showDivider: false,
          onSelect: (): void => this.onDelete()
        })
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 8, bottom: 24 })
      .borderRadius({ topLeft: FnMusicUI.cardRadius + 8, topRight: FnMusicUI.cardRadius + 8 })
      .backgroundColor($r('app.color.surface_elevated'))
      .clip(true)
      .transition(
        TransitionEffect.translate({ y: 72 })
          .combine(TransitionEffect.OPACITY)
          .animation({ duration: 240, curve: Curve.FastOutSlowIn })
      )
    }
    .width('100%')
    .height('100%')
    .zIndex(50)
    .transition(TransitionEffect.OPACITY.animation({ duration: 180, curve: Curve.EaseOut }))
  }
}
