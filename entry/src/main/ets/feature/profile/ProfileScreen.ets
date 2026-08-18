import { FnMusicUI } from '../../design/FnMusicUI';
import { FnMusicMaterialRole, FnMusicMaterials } from '../../design/FnMusicMaterials';
import { MusicPlaylist, MusicUser } from '../../model/MusicModels';
import { MusicArtwork } from '../common/MusicUiComponents';

@ComponentV2
struct ProfileIdentityCard {
  @Param user: MusicUser = new MusicUser();

  private displayName(): string {
    return this.user.name.trim().length > 0 ? this.user.name : '飞牛用户';
  }

  private roleLabel(): string {
    const role: string = this.user.role.toLowerCase();
    if (role === 'admin' || role === 'administrator') {
      return '管理员';
    }
    if (role === 'user') {
      return '普通用户';
    }
    return this.user.role.trim().length > 0 ? this.user.role : '普通用户';
  }

  build() {
    Row({ space: FnMusicUI.contentGap }) {
      MusicArtwork({
        artworkSize: FnMusicUI.profileAvatarSize,
        radius: FnMusicUI.profileAvatarSize / 2,
        symbol: $r('sys.symbol.person_fill')
      })

      Column({ space: 4 }) {
        Text(this.displayName())
          .width('100%')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.roleLabel())
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 4, right: 4, top: 4, bottom: 8 })
    .alignItems(VerticalAlign.Center)
  }
}

@ComponentV2
struct ProfileMenuRow {
  @Param title: string = '';
  @Param trailing: string = '';
  @Param symbol: Resource = $r('sys.symbol.gearshape');
  @Param destructive: boolean = false;
  @Param showChevron: boolean = true;
  @Event onSelect: () => void = (): void => {};

  build() {
    Button({ type: ButtonType.Normal, stateEffect: true }) {
      Row({ space: FnMusicUI.settingsRowGap }) {
        Stack({ alignContent: Alignment.Center }) {
          SymbolGlyph(this.symbol)
            .fontSize(FnMusicUI.settingsIconSize)
            .fontColor([this.destructive ? $r('app.color.danger') : $r('app.color.text_primary')])
        }
        .width(FnMusicUI.settingsIconContainerSize)
        .height(FnMusicUI.settingsIconContainerSize)
        .backgroundColor(Color.Transparent)

        Text(this.title)
          .layoutWeight(1)
          .fontSize(FnMusicUI.bodySize)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.destructive ? $r('app.color.danger') : $r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.trailing.length > 0) {
          Text(this.trailing)
            .fontSize(FnMusicUI.supportingSize)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
        }

        if (this.showChevron) {
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(18)
            .fontColor([$r('app.color.text_secondary')])
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(FnMusicUI.settingsRowHeight)
    .padding(0)
    .borderRadius(0)
    .buttonStyle(ButtonStyleMode.TEXTUAL)
    .backgroundColor(Color.Transparent)
    .accessibilityText(this.title)
    .onClick((): void => this.onSelect())
  }
}

@ComponentV2
export struct ProfileScreen {
  @Param user: MusicUser = new MusicUser();
  @Param playlists: MusicPlaylist[] = [];
  @Param safeTop: number = 0;
  @Param bottomInset: number = 0;
  @Param pageScroller: Scroller = new Scroller();
  @Event onOpenPlaylists: () => void = (): void => {};
  @Event onOpenSettings: () => void = (): void => {};
  @Event onLogout: () => void = (): void => {};

  private confirmLogout(): void {
    this.getUIContext().getPromptAction().showDialog({
      title: '退出登录',
      message: '将清除本机保存的账号与登录信息。',
      buttons: [
        { text: '取消', color: $r('app.color.text_secondary') },
        { text: '退出', color: $r('app.color.danger') }
      ]
    }).then((result): void => {
      if (result.index === 1) {
        this.onLogout();
      }
    }).catch((): void => {});
  }

  build() {
    Scroll(this.pageScroller) {
      Column({ space: FnMusicUI.contentGap }) {
        Blank().height(Math.max(0, this.safeTop) + FnMusicUI.secondaryHeaderHeight)

        ProfileIdentityCard({ user: this.user })

        Column() {
          ProfileMenuRow({
            title: '自建歌单',
            trailing: `${this.playlists.length} 个`,
            symbol: $r('sys.symbol.music_note_list'),
            onSelect: (): void => this.onOpenPlaylists()
          })
          Divider()
            .strokeWidth(1)
            .color($r('app.color.divider'))
            .margin({ left: FnMusicUI.settingsDividerStart })
          ProfileMenuRow({
            title: '设置',
            symbol: $r('sys.symbol.gearshape'),
            onSelect: (): void => this.onOpenSettings()
          })
        }
        .width('100%')
        .borderRadius(FnMusicUI.settingsCardRadius)
        .clip(true)
        .backgroundColor(Color.Transparent)
        .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.CONTENT_GROUP))
        .border({ width: 0.5, color: $r('app.color.profile_group_border') })

        Column() {
          ProfileMenuRow({
            title: '退出登录',
            symbol: $r('sys.symbol.power'),
            destructive: true,
            showChevron: false,
            onSelect: (): void => this.confirmLogout()
          })
        }
        .width('100%')
        .borderRadius(FnMusicUI.settingsCardRadius)
        .clip(true)
        .backgroundColor(Color.Transparent)
        .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.CONTENT_GROUP))
        .border({ width: 0.5, color: $r('app.color.profile_group_border') })
      }
      .width('100%')
      .padding({
        left: FnMusicUI.pagePadding,
        right: FnMusicUI.pagePadding,
        bottom: this.bottomInset + FnMusicUI.sectionGap
      })
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .align(Alignment.Top)
    .linearGradient({
      angle: 180,
      colors: [
        [$r('app.color.page_profile_background_start'), 0],
        [$r('app.color.page_profile_background_end'), 1]
      ]
    })
  }
}
