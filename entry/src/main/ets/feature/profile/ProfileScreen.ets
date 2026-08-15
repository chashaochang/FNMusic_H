import { FnMusicUI } from '../../design/FnMusicUI';
import { MusicPlaylist, MusicUser } from '../../model/MusicModels';
import { MusicArtwork, SettingsRow } from '../common/MusicUiComponents';
import { PlaylistCollectionSection } from '../playlist/PlaylistScreen';

@ComponentV2
struct ProfileIdentityCard {
  @Param user: MusicUser = new MusicUser();

  private roleLabel(): string {
    const role = this.user.role.toLowerCase();
    if (role === 'admin' || role === 'administrator') {
      return '管理员';
    }
    if (role === 'user') {
      return '普通用户';
    }
    return this.user.role.length > 0 ? this.user.role : '普通用户';
  }

  build() {
    Row({ space: 12 }) {
      MusicArtwork({ artworkSize: 48, radius: 24, symbol: $r('sys.symbol.person_fill') })
      Column({ space: 4 }) {
        Text(this.user.name.length > 0 ? this.user.name : '飞牛用户')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
        Row() {
          Text(this.roleLabel())
            .fontSize(12)
            .fontColor($r('app.color.chip_selected_text'))
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(4)
            .backgroundColor($r('app.color.surface_secondary'))
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }
}

@ComponentV2
export struct ProfileScreen {
  @Param user: MusicUser = new MusicUser();
  @Param playlists: MusicPlaylist[] = [];
  @Param bottomInset: number = 0;
  @Event onOpenPlaylist: (playlist: MusicPlaylist) => void = (_: MusicPlaylist): void => {};
  @Event onPlaylistMore: (playlist: MusicPlaylist) => void = (_: MusicPlaylist): void => {};
  @Event onCreatePlaylist: () => void = (): void => {};
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
    Scroll() {
      Column({ space: FnMusicUI.sectionGap }) {
        ProfileIdentityCard({ user: this.user })

        PlaylistCollectionSection({
          playlists: this.playlists,
          onOpenPlaylist: (playlist: MusicPlaylist): void => this.onOpenPlaylist(playlist),
          onPlaylistMore: (playlist: MusicPlaylist): void => this.onPlaylistMore(playlist),
          onCreatePlaylist: (): void => this.onCreatePlaylist()
        })

        Column() {
          SettingsRow({
            title: '设置',
            subtitle: '个人、服务器和关于',
            symbol: $r('sys.symbol.gearshape'),
            onSelect: (): void => {
              this.onOpenSettings();
            }
          })
          Divider()
            .strokeWidth(1)
            .color($r('app.color.divider'))
            .margin({ left: 56 })
          SettingsRow({
            title: '退出登录',
            subtitle: '清除当前登录会话',
            symbol: $r('sys.symbol.power'),
            destructive: true,
            showChevron: false,
            onSelect: (): void => {
              this.confirmLogout();
            }
          })
        }
        .width('100%')
        .padding({ left: 4, right: 4 })
        .borderRadius(FnMusicUI.cardRadius)
        .backgroundColor($r('app.color.surface'))
      }
      .width('100%')
      .padding({
        left: FnMusicUI.pagePadding,
        right: FnMusicUI.pagePadding,
        top: 12,
        bottom: this.bottomInset + FnMusicUI.sectionGap
      })
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .linearGradient({
      angle: 180,
      colors: [
        [$r('app.color.page_profile_background_start'), 0],
        [$r('app.color.page_profile_background_end'), 1]
      ]
    })
  }
}
