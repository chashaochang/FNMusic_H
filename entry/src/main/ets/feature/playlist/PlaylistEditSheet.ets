import { FnMusicUI } from '../../design/FnMusicUI';
import { MusicPlaylist } from '../../model/MusicModels';
import { SettingsRow } from '../common/MusicUiComponents';

export enum PlaylistEditMode {
  CREATE = 'create',
  EDIT = 'edit'
}

@ComponentV2
export struct PlaylistEditSheet {
  @Param mode: PlaylistEditMode = PlaylistEditMode.CREATE;
  @Param playlist: MusicPlaylist = new MusicPlaylist();
  @Local name: string = '';
  @Event onClose: () => void = (): void => {};
  @Event onSave: (name: string) => void = (_: string): void => {};
  @Event onDelete: () => void = (): void => {};

  aboutToAppear(): void {
    this.name = this.mode === PlaylistEditMode.EDIT ? this.playlist.name : '';
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.scrim'))
        .onClick((): void => this.onClose())

      Column({ space: FnMusicUI.contentGap }) {
        Row() {
          Text(this.mode === PlaylistEditMode.CREATE ? '新建歌单' : '编辑歌单')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Blank()
          Button({ type: ButtonType.Circle }) {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(20)
              .fontColor([$r('app.color.text_primary')])
          }
          .width(FnMusicUI.tapTarget)
          .height(FnMusicUI.tapTarget)
          .backgroundColor($r('app.color.surface_secondary'))
          .accessibilityText('关闭')
          .onClick((): void => this.onClose())
        }
        .width('100%')

        TextInput({ text: this.name, placeholder: '歌单名称' })
          .width('100%')
          .height(FnMusicUI.searchHeight)
          .fontSize(FnMusicUI.bodySize)
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_secondary'))
          .padding({ left: 14, right: 14 })
          .borderRadius(FnMusicUI.controlRadius)
          .backgroundColor($r('app.color.surface_secondary'))
          .maxLength(40)
          .onChange((value: string): void => {
            this.name = value;
          })
          .onSubmit((): void => {
            if (this.name.trim().length > 0) {
              this.onSave(this.name.trim());
            }
          })

        Button(this.mode === PlaylistEditMode.CREATE ? '创建歌单' : '保存修改')
          .width('100%')
          .height(FnMusicUI.actionHeight)
          .fontSize(FnMusicUI.bodySize)
          .fontColor($r('app.color.accent_contrast'))
          .backgroundColor($r('app.color.accent'))
          .borderRadius(FnMusicUI.controlRadius)
          .enabled(this.name.trim().length > 0)
          .opacity(this.name.trim().length > 0 ? 1 : 0.45)
          .onClick((): void => {
            if (this.name.trim().length > 0) {
              this.onSave(this.name.trim());
            }
          })

        if (this.mode === PlaylistEditMode.EDIT) {
          SettingsRow({
            title: '删除歌单',
            subtitle: '不会删除音乐文件',
            symbol: $r('sys.symbol.trash'),
            destructive: true,
            showChevron: false,
            onSelect: (): void => this.onDelete()
          })
        }
      }
      .width('100%')
      .padding({ left: FnMusicUI.pagePadding, right: FnMusicUI.pagePadding, top: 14, bottom: 24 })
      .borderRadius({ topLeft: FnMusicUI.cardRadius, topRight: FnMusicUI.cardRadius })
      .backgroundColor($r('app.color.surface_elevated'))
      .transition(TransitionEffect.translate({ y: 72 }).combine(TransitionEffect.OPACITY))
    }
    .width('100%')
    .height('100%')
    .zIndex(50)
  }
}
