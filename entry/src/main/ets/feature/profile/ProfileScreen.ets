import { FnMusicUI } from '../../design/FnMusicUI';
import { MusicPlaylist, MusicUser } from '../../model/MusicModels';
import { EmptyMusicState, MusicArtwork, PlaylistRow, SectionHeader, SettingsRow } from '../common/MusicUiComponents';

@ComponentV2
struct ProfileIdentityCard {
  @Param user: MusicUser = new MusicUser();
  @Param connectionLabel: string = '';

  build() {
    Row({ space: 12 }) {
      MusicArtwork({ artworkSize: 48, radius: 24, symbol: $r('sys.symbol.person_fill') })
      Column({ space: 4 }) {
        Text(this.user.name.length > 0 ? this.user.name : '飞牛用户')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
        Row({ space: 8 }) {
          Text(this.user.role.length > 0 ? this.user.role : 'user')
            .fontSize(12)
            .fontColor($r('app.color.chip_selected_text'))
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(4)
            .backgroundColor($r('app.color.surface_secondary'))
          Text(this.connectionLabel)
            .fontSize(FnMusicUI.supportingSize)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
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
  @Param connectionLabel: string = '';
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
        ProfileIdentityCard({ user: this.user, connectionLabel: this.connectionLabel })

        Column({ space: 6 }) {
          SectionHeader({
            title: '自建歌单',
            supporting: `${this.playlists.length} 个歌单`,
            actionTitle: '新建',
            onAction: (): void => {
              this.onCreatePlaylist();
            }
          })
          if (this.playlists.length === 0) {
            EmptyMusicState({
              title: '还没有自建歌单',
              message: '点击「新建」创建第一个歌单。',
              symbol: $r('sys.symbol.music_note_list')
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
    .backgroundColor($r('app.color.page_background'))
  }
}
