import { FnMusicUI } from '../../design/FnMusicUI';
import { MusicPreferenceState } from '../../common/MusicPreferenceStore';
import { SettingsRow } from '../common/MusicUiComponents';

@ComponentV2
struct PreferenceToggleRow {
  @Param title: string = '';
  @Param subtitle: string = '';
  @Param symbol: Resource = $r('sys.symbol.gearshape');
  @Param checked: boolean = true;
  @Event onChanged: (checked: boolean) => void = (_: boolean): void => {};

  build() {
    Row({ space: 12 }) {
      SymbolGlyph(this.symbol)
        .width(28)
        .fontSize(21)
        .fontColor([$r('app.color.accent')])
      Column({ space: 2 }) {
        Text(this.title)
          .fontSize(FnMusicUI.bodySize)
          .fontColor($r('app.color.text_primary'))
        Text(this.subtitle)
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Toggle({ type: ToggleType.Switch, isOn: this.checked })
        .selectedColor($r('app.color.accent'))
        .onChange((checked: boolean): void => this.onChanged(checked))
    }
    .width('100%')
    .height(FnMusicUI.listRowHeight)
    .padding({ left: 10, right: 10 })
  }
}

@ComponentV2
export struct SettingsSheet {
  @Local activeDetail: string = '';
  @Param connectionLabel: string = '';
  @Param preferences: MusicPreferenceState = new MusicPreferenceState();
  @Event onClose: () => void = (): void => {};
  @Event onLibraryManagement: () => void = (): void => {};
  @Event onUserManagement: () => void = (): void => {};
  @Event onReconnect: () => void = (): void => {};
  @Event onMotionChanged: (enabled: boolean) => void = (_: boolean): void => {};
  @Event onAutoContinueChanged: (enabled: boolean) => void = (_: boolean): void => {};
  @Event onLyricsChanged: (enabled: boolean) => void = (_: boolean): void => {};
  @Event onSystemAppearance: () => void = (): void => {};

  private detailTitle(): string {
    if (this.activeDetail === 'personal') {
      return '个人设置';
    }
    if (this.activeDetail === 'server') {
      return '服务器设置';
    }
    return '关于';
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.scrim'))
        .onClick((): void => {
          this.onClose();
        })

      Column({ space: 6 }) {
        Row() {
          Column({ space: 2 }) {
            Text('设置')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            Text('飞牛音乐偏好与服务器')
              .fontSize(FnMusicUI.supportingSize)
              .fontColor($r('app.color.text_secondary'))
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(20)
              .fontColor([$r('app.color.text_primary')])
          }
          .width(FnMusicUI.tapTarget)
          .height(FnMusicUI.tapTarget)
          .backgroundColor($r('app.color.surface_secondary'))
          .accessibilityText('关闭设置')
          .onClick((): void => {
            this.onClose();
          })
        }
        .width('100%')
        .padding({ left: 10, right: 4, top: 4, bottom: 6 })

        if (this.activeDetail.length === 0) {
          Column() {
            SettingsRow({
              title: '个人设置',
              subtitle: '主题、动态效果、播放与歌词',
              symbol: $r('sys.symbol.person'),
              onSelect: (): void => {
                this.activeDetail = 'personal';
              }
            })
            Divider().strokeWidth(1).color($r('app.color.divider')).margin({ left: 56 })
            SettingsRow({
              title: '音乐库管理',
              subtitle: '扫描和目录管理',
              symbol: $r('sys.symbol.externaldrive'),
              onSelect: (): void => this.onLibraryManagement()
            })
            Divider().strokeWidth(1).color($r('app.color.divider')).margin({ left: 56 })
            SettingsRow({
              title: '用户管理',
              subtitle: 'NAS 用户与权限',
              symbol: $r('sys.symbol.person_2'),
              onSelect: (): void => this.onUserManagement()
            })
            Divider().strokeWidth(1).color($r('app.color.divider')).margin({ left: 56 })
            SettingsRow({
              title: '服务器设置',
              subtitle: 'FN Connect、地址与重新探测',
              symbol: $r('sys.symbol.externaldrive'),
              onSelect: (): void => {
                this.activeDetail = 'server';
              }
            })
            Divider().strokeWidth(1).color($r('app.color.divider')).margin({ left: 56 })
            SettingsRow({
              title: '关于',
              subtitle: '版本、开源说明与第三方声明',
              symbol: $r('sys.symbol.info_circle'),
              onSelect: (): void => {
                this.activeDetail = 'about';
              }
            })
          }
          .width('100%')
        } else {
          Column({ space: FnMusicUI.contentGap }) {
            Row({ space: 8 }) {
              Button({ type: ButtonType.Circle }) {
                SymbolGlyph($r('sys.symbol.chevron_backward'))
                  .fontSize(20)
                  .fontColor([$r('app.color.text_primary')])
              }
              .width(FnMusicUI.tapTarget)
              .height(FnMusicUI.tapTarget)
              .backgroundColor($r('app.color.surface_secondary'))
              .accessibilityText('返回设置')
              .onClick((): void => {
                this.activeDetail = '';
              })
              Text(this.detailTitle())
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
            }
            .width('100%')

            if (this.activeDetail === 'personal') {
              SettingsRow({
                title: '外观模式', subtitle: '跟随系统深浅色', symbol: $r('sys.symbol.sun_max'), showChevron: false,
                onSelect: (): void => this.onSystemAppearance()
              })
              PreferenceToggleRow({
                title: '动态效果', subtitle: '页面过渡与播放器连续动画',
                symbol: $r('sys.symbol.music_badge_wave_2'), checked: this.preferences.motionEnabled,
                onChanged: (enabled: boolean): void => this.onMotionChanged(enabled)
              })
              PreferenceToggleRow({
                title: '自动续播', subtitle: '当前歌曲结束后继续播放',
                symbol: $r('sys.symbol.play_fill'), checked: this.preferences.autoContinueEnabled,
                onChanged: (enabled: boolean): void => this.onAutoContinueChanged(enabled)
              })
              PreferenceToggleRow({
                title: '歌词显示', subtitle: '加载并显示逐行歌词',
                symbol: $r('sys.symbol.music_note_list'), checked: this.preferences.lyricsEnabled,
                onChanged: (enabled: boolean): void => this.onLyricsChanged(enabled)
              })
            } else if (this.activeDetail === 'server') {
              SettingsRow({ title: 'FN Connect', subtitle: '使用登录页保存的设备标识', symbol: $r('sys.symbol.externaldrive'), showChevron: false })
              SettingsRow({
                title: '当前地址',
                subtitle: this.connectionLabel.length > 0 ? this.connectionLabel : '暂未连接',
                symbol: $r('sys.symbol.checkmark_circle_fill'),
                showChevron: false
              })
              SettingsRow({
                title: '重新探测',
                subtitle: '按连接优先级测试可用地址',
                symbol: $r('sys.symbol.arrow_clockwise'),
                onSelect: (): void => this.onReconnect()
              })
            } else {
              SettingsRow({ title: '飞牛音乐', subtitle: 'HarmonyOS API 26', symbol: $r('sys.symbol.info_circle'), showChevron: false })
              SettingsRow({ title: '开源说明', subtitle: '独立原生实现', symbol: $r('sys.symbol.doc'), showChevron: false })
              SettingsRow({ title: '第三方声明', subtitle: '系统能力与依赖说明', symbol: $r('sys.symbol.list_bullet_square'), showChevron: false })
            }
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 12, bottom: 24 })
      .borderRadius({ topLeft: FnMusicUI.cardRadius, topRight: FnMusicUI.cardRadius })
      .backgroundColor($r('app.color.surface_elevated'))
      .transition(TransitionEffect.translate({ y: 72 }).combine(TransitionEffect.OPACITY))
    }
    .width('100%')
    .height('100%')
    .zIndex(40)
  }
}
