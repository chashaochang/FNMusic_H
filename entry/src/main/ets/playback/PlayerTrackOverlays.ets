import { MusicPreferenceState } from '../common/MusicPreferenceStore';
import { FnMusicUI } from '../design/FnMusicUI';
import { FnMusicMaterialRole, FnMusicMaterials } from '../design/FnMusicMaterials';
import { MusicArtist, MusicPlaylist, MusicTrack } from '../model/MusicModels';
import { EmptyMusicState, MusicEmptyKind } from '../feature/common/MusicUiComponents';
import { PlayerInfoRow, playerTrackInfoRows } from './PlayerUiPolicy';

@ComponentV2
struct PlayerMenuRow {
  @Param title: string = '';
  @Param symbol: Resource = $r('sys.symbol.music');
  @Param available: boolean = true;
  @Event onSelect: () => void = (): void => {};

  build() {
    Row({ space: 12 }) {
      SymbolGlyph(this.symbol)
        .width(24)
        .fontSize(19)
        .fontColor([this.available ? $r('app.color.text_primary') : $r('app.color.text_secondary')])
      Text(this.title)
        .layoutWeight(1)
        .fontSize(FnMusicUI.bodySize)
        .fontColor(this.available ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
    }
    .width('100%')
    .height(48)
    .padding({ left: 14, right: 14 })
    .opacity(this.available ? 1 : 0.45)
    .enabled(this.available)
    .onClick((): void => this.onSelect())
  }
}

@ComponentV2
export struct PlayerTrackMenu {
  @Param canOpenAlbum: boolean = false;
  @Param canOpenArtist: boolean = false;
  @Event onOpenAlbum: () => void = (): void => {};
  @Event onOpenArtist: () => void = (): void => {};
  @Event onAddPlaylist: () => void = (): void => {};
  @Event onInfo: () => void = (): void => {};

  build() {
    Column() {
      PlayerMenuRow({
        title: '查看专辑', symbol: $r('sys.symbol.music_note_list'), available: this.canOpenAlbum,
        onSelect: (): void => this.onOpenAlbum()
      })
      PlayerMenuRow({
        title: '查看歌手', symbol: $r('sys.symbol.person'), available: this.canOpenArtist,
        onSelect: (): void => this.onOpenArtist()
      })
      PlayerMenuRow({
        title: '添加到歌单', symbol: $r('sys.symbol.plus_circle'),
        onSelect: (): void => this.onAddPlaylist()
      })
      PlayerMenuRow({
        title: '歌曲信息', symbol: $r('sys.symbol.info_circle'),
        onSelect: (): void => this.onInfo()
      })
    }
    .width(188)
    .height(200)
    .padding({ top: 4, bottom: 4 })
    .borderRadius(FnMusicUI.controlRadius)
    .backgroundColor($r('app.color.surface_elevated'))
    .clip(true)
    .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
  }
}

@ComponentV2
export struct PlayerArtistPicker {
  @Param artists: MusicArtist[] = [];
  @Event onClose: () => void = (): void => {};
  @Event onSelect: (artist: MusicArtist) => void = (_: MusicArtist): void => {};

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column().width('100%').height('100%').backgroundColor($r('app.color.scrim'))
        .onClick((): void => this.onClose())
      Column({ space: 4 }) {
        SheetHeader({ title: '选择歌手', onClose: (): void => this.onClose() })
        Repeat<MusicArtist>(this.artists)
          .each((repeatItem: RepeatItem<MusicArtist>): void => {
            PlayerMenuRow({
              title: repeatItem.item.name,
              symbol: $r('sys.symbol.person'),
              onSelect: (): void => this.onSelect(repeatItem.item)
            })
          })
          .key((item: MusicArtist): string => item.guid.length > 0 ? item.guid : item.name)
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 12, bottom: 24 })
      .borderRadius({ topLeft: FnMusicUI.cardRadius, topRight: FnMusicUI.cardRadius })
      .backgroundColor($r('app.color.surface_elevated'))
    }
    .width('100%')
    .height('100%')
  }
}

@ComponentV2
export struct PlayerPlaylistPicker {
  @Param playlists: MusicPlaylist[] = [];
  @Event onClose: () => void = (): void => {};
  @Event onSelect: (playlist: MusicPlaylist) => void = (_: MusicPlaylist): void => {};

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column().width('100%').height('100%').backgroundColor($r('app.color.scrim'))
        .onClick((): void => this.onClose())
      Column({ space: 4 }) {
        SheetHeader({ title: '添加到歌单', onClose: (): void => this.onClose() })
        if (this.playlists.length === 0) {
          EmptyMusicState({
            kind: MusicEmptyKind.LIST,
            title: '还没有自建歌单',
            message: '请先创建歌单',
            compact: true
          })
        } else {
          Scroll() {
            Column() {
              Repeat<MusicPlaylist>(this.playlists)
                .each((repeatItem: RepeatItem<MusicPlaylist>): void => {
                  Row({ space: 12 }) {
                    SymbolGlyph($r('sys.symbol.music_note_list'))
                      .width(24)
                      .fontSize(20)
                      .fontColor([$r('app.color.accent')])
                    Column({ space: 2 }) {
                      Text(repeatItem.item.name)
                        .fontSize(FnMusicUI.bodySize)
                        .fontColor($r('app.color.text_primary'))
                        .maxLines(1)
                      Text(`${repeatItem.item.trackCount} 首歌曲`)
                        .fontSize(FnMusicUI.supportingSize)
                        .fontColor($r('app.color.text_secondary'))
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                  }
                  .width('100%')
                  .height(FnMusicUI.listRowHeight)
                  .padding({ left: 14, right: 14 })
                  .onClick((): void => this.onSelect(repeatItem.item))
                })
                .key((item: MusicPlaylist): string => item.guid)
            }
          }
          .height(Math.min(320, Math.max(FnMusicUI.listRowHeight,
            this.playlists.length * FnMusicUI.listRowHeight)))
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 12, bottom: 24 })
      .borderRadius({ topLeft: FnMusicUI.cardRadius, topRight: FnMusicUI.cardRadius })
      .backgroundColor($r('app.color.surface_elevated'))
    }
    .width('100%')
    .height('100%')
  }
}

@ComponentV2
export struct TrackInfoSheet {
  @Param track: MusicTrack = new MusicTrack();
  @Event onClose: () => void = (): void => {};

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column().width('100%').height('100%').backgroundColor($r('app.color.scrim'))
        .onClick((): void => this.onClose())
      Column({ space: 4 }) {
        SheetHeader({ title: '歌曲信息', onClose: (): void => this.onClose() })
        Scroll() {
          Column() {
            Repeat<PlayerInfoRow>(playerTrackInfoRows(this.track))
              .each((repeatItem: RepeatItem<PlayerInfoRow>): void => {
                Row({ space: 14 }) {
                  Text(repeatItem.item.label)
                    .width(64)
                    .fontSize(FnMusicUI.supportingSize)
                    .fontColor($r('app.color.text_secondary'))
                  Text(repeatItem.item.value)
                    .layoutWeight(1)
                    .fontSize(FnMusicUI.bodySize)
                    .fontColor($r('app.color.text_primary'))
                    .maxLines(2)
                }
                .width('100%')
                .constraintSize({ minHeight: 48 })
                .padding({ left: 14, right: 14, top: 8, bottom: 8 })
              })
              .key((item: PlayerInfoRow): string => item.label)
          }
        }
        .height(360)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 12, bottom: 24 })
      .borderRadius({ topLeft: FnMusicUI.cardRadius, topRight: FnMusicUI.cardRadius })
      .backgroundColor($r('app.color.surface_elevated'))
    }
    .width('100%')
    .height('100%')
  }
}

@ComponentV2
export struct LyricsSettingsSheet {
  @Param preferences: MusicPreferenceState = new MusicPreferenceState();
  @Param supported: boolean = false;
  @Param checking: boolean = false;
  @Event onClose: () => void = (): void => {};
  @Event onToggle: (enabled: boolean) => void = (_: boolean): void => {};

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column().width('100%').height('100%').backgroundColor($r('app.color.scrim'))
        .onClick((): void => this.onClose())
      Column({ space: 10 }) {
        SheetHeader({ title: '歌词', onClose: (): void => this.onClose() })
        Row({ space: 12 }) {
          SymbolGlyph($r('sys.symbol.lyrics_square'))
            .width(26)
            .fontSize(22)
            .fontColor([$r('app.color.accent')])
          Column({ space: 2 }) {
            Text('状态栏歌词')
              .fontSize(FnMusicUI.bodySize)
              .fontColor($r('app.color.text_primary'))
            Text(this.checking ? '正在检查系统能力' :
              (this.supported ? '由 HarmonyOS 系统歌词服务显示' : '当前设备不支持系统歌词'))
              .fontSize(FnMusicUI.supportingSize)
              .fontColor($r('app.color.text_secondary'))
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          Toggle({ type: ToggleType.Switch, isOn: this.preferences.desktopLyricsEnabled })
            .selectedColor($r('app.color.accent'))
            .enabled(this.supported && !this.checking)
            .onChange((enabled: boolean): void => this.onToggle(enabled))
        }
        .width('100%')
        .height(FnMusicUI.listRowHeight)
        .padding({ left: 12, right: 12 })
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 12, bottom: 24 })
      .borderRadius({ topLeft: FnMusicUI.cardRadius, topRight: FnMusicUI.cardRadius })
      .backgroundColor($r('app.color.surface_elevated'))
    }
    .width('100%')
    .height('100%')
  }
}

@ComponentV2
struct SheetHeader {
  @Param title: string = '';
  @Event onClose: () => void = (): void => {};

  build() {
    Row() {
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Blank()
      Button({ type: ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(19)
          .fontColor([$r('app.color.text_primary')])
      }
      .width(FnMusicUI.tapTarget)
      .height(FnMusicUI.tapTarget)
      .backgroundColor($r('app.color.surface_secondary'))
      .accessibilityText('关闭')
      .onClick((): void => this.onClose())
    }
    .width('100%')
    .padding({ left: 10, right: 4, bottom: 4 })
  }
}
