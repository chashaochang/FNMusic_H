import { FnMusicUI } from '../design/FnMusicUI';
import { FnMusicMaterialRole, FnMusicMaterials } from '../design/FnMusicMaterials';
import { MusicPreferenceState, MusicPreferenceStore, connectMusicPreferenceState } from '../common/MusicPreferenceStore';
import { FnToast } from '../common/FnToast';
import { LengthMetrics } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { MusicAlbum, MusicArtist, MusicPlaylist, MusicTrack, formatDuration } from '../model/MusicModels';
import {
  EmptyMusicState,
  MusicArtwork,
  MusicEmptyKind,
  RoamPulseIcon
} from '../feature/common/MusicUiComponents';
import { MusicPlaybackController } from './MusicPlaybackController';
import { PlayerDynamicPalette, PlayerPaletteState } from './PlayerDynamicPalette';
import { nearestLyricIndex, playerFormatLabel, desktopLyricErrorMessage } from './PlayerUiPolicy';
import {
  LyricsSettingsSheet,
  PlayerArtistPicker,
  PlayerPlaylistPicker,
  PlayerTrackMenu,
  TrackInfoSheet
} from './PlayerTrackOverlays';
import {
  LyricLoadStatus,
  LyricLine,
  PlaybackRepeatMode,
  PlaybackStatus,
  PlayerPresentationState,
  connectPlayerPresentationState
} from './PlayerPresentationStore';

export enum PlayerHostPlacement {
  HOME = 'home',
  COMPACT_HOME = 'compact_home',
  ROOT_FLOATING = 'root_floating',
  FLOATING = 'floating'
}

export const HOME_PLAYER_TRANSITION_ID: string = 'feiniu_music_home_player_transition';
export const FLOATING_PLAYER_TRANSITION_ID: string = 'feiniu_music_floating_player_transition';

enum ExpandedPanel {
  PLAYER = 'player',
  LYRICS = 'lyrics',
  QUEUE = 'queue'
}

const PLAYER_LYRIC_LINE_HEIGHT: number = 46;
const PLAYER_LYRIC_FADING_EDGE_LENGTH: number = 80;
const PLAYER_LYRIC_ACTIVE_TOP_OFFSET: number = 160;
const PLAYER_LYRIC_CONTENT_BOTTOM_PADDING: number = 420;
const PLAYER_PAGE_SWIPE_DISTANCE: number = 180;
const PLAYER_PAGE_SWITCH_THRESHOLD: number = 22;
const PLAYER_IMMERSION_DELAY: number = 5000;
const PLAYER_COVER_LIFT: number = 10;
const PLAYER_INFO_LIFT: number = 20;
const PLAYER_LYRIC_SETTINGS_OFFSET: number = 126;
const PLAYER_LYRIC_RESTORE_HEIGHT: number = 80;
const PLAYER_LYRIC_IMMERSIVE_BOTTOM_GUTTER: number = 8;
const PLAYER_LYRIC_PREVIEW_TOP: number = 224;
const PLAYER_MENU_BOTTOM_OFFSET: number = 56;

@ComponentV2
export struct MiniPlayerBar {
  @Param state: PlayerPresentationState = new PlayerPresentationState();
  @Param placement: PlayerHostPlacement = PlayerHostPlacement.HOME;
  @Param heightOverride: number = 0;
  @Param transitionId: string = HOME_PLAYER_TRANSITION_ID;
  @Event onExpand: () => void = (): void => {};
  @Event onToggle: () => void = (): void => {};
  @Event onNext: () => void = (): void => {};
  @Event onQueue: () => void = (): void => {};

  private track(): MusicTrack {
    return this.state.currentTrack() ?? new MusicTrack();
  }

  private playing(): boolean {
    return this.state.status === PlaybackStatus.PLAYING || this.state.status === PlaybackStatus.BUFFERING ||
      this.state.status === PlaybackStatus.PREPARING;
  }

  private compact(): boolean {
    return this.placement === PlayerHostPlacement.COMPACT_HOME;
  }

  private playerHeight(): number {
    if (this.heightOverride > 0) {
      return this.heightOverride;
    }
    return this.compact() ? FnMusicUI.compactPlayerHeight :
      (this.placement === PlayerHostPlacement.HOME ? FnMusicUI.miniPlayerHeight : FnMusicUI.floatingPlayerHeight);
  }

  private artworkSize(): number {
    if (!this.compact()) {
      return FnMusicUI.miniPlayerArtworkSize;
    }
    const heightRange: number = FnMusicUI.compactPlayerHeight - FnMusicUI.homeMiniPlayerHeight;
    if (heightRange <= 0) {
      return FnMusicUI.compactPlayerArtworkSize;
    }
    const progress: number = Math.max(0, Math.min(1,
      (this.playerHeight() - FnMusicUI.homeMiniPlayerHeight) / heightRange));
    return FnMusicUI.miniPlayerArtworkSize +
      (FnMusicUI.compactPlayerArtworkSize - FnMusicUI.miniPlayerArtworkSize) * progress;
  }

  build() {
    Row({ space: 8 }) {
      Row({ space: 8 }) {
          MusicArtwork({
            artworkSize: this.artworkSize(),
            radius: this.artworkSize() / 2,
            placeholderMedia: $r('app.media.music_track_placeholder'),
            placeholderRatio: 0.56,
            coverId: this.track().coverId,
            updatedAt: this.track().updatedAt
          })
          Column({ space: 2 }) {
            Text(this.track().title)
              .width('100%')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.track().artistName.length > 0 ? this.track().artistName : this.track().albumName)
              .width('100%')
              .fontSize(11)
              .fontColor($r('app.color.text_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .height('100%')
      .alignItems(VerticalAlign.Center)
      .onClick((): void => this.onExpand())

      Button({ type: ButtonType.Circle, stateEffect: true }) {
          if (this.state.status === PlaybackStatus.PREPARING || this.state.status === PlaybackStatus.BUFFERING) {
            LoadingProgress()
              .width(20)
              .height(20)
              .color($r('app.color.mini_player_play_foreground'))
          } else {
            SymbolGlyph(this.playing() ? $r('sys.symbol.pause_fill') : $r('sys.symbol.play_fill'))
              .fontSize(16)
              .fontColor([$r('app.color.mini_player_play_foreground')])
          }
        }
        .width(32)
        .height(32)
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .backgroundColor($r('app.color.mini_player_play_background'))
        .accessibilityText(this.playing() ? '暂停' : '播放')
        .onClick((): void => this.onToggle())

      Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph($r('sys.symbol.forward_end_fill'))
            .fontSize(19)
            .fontColor([$r('app.color.text_primary')])
        }
        .width(32)
        .height(32)
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .backgroundColor(Color.Transparent)
        .accessibilityText('下一首')
        .onClick((): void => this.onNext())

      Button({ type: ButtonType.Circle, stateEffect: !this.state.roamMode }) {
        if (this.state.roamMode) {
          RoamPulseIcon({ iconSize: 21 })
        } else {
          SymbolGlyph($r('sys.symbol.music_note_list'))
            .fontSize(20)
            .fontColor([$r('app.color.text_primary')])
        }
      }
      .width(32)
      .height(32)
      .buttonStyle(ButtonStyleMode.TEXTUAL)
      .backgroundColor(Color.Transparent)
      .accessibilityText(this.state.roamMode ? '漫游模式' : '播放队列')
      .onClick((): void => {
        if (!this.state.roamMode) {
          this.onQueue();
        }
      })
    }
    .width('100%')
    .height(this.playerHeight())
    .padding({ left: 8, right: this.state.roamMode ? 10 : 6 })
    .alignItems(VerticalAlign.Center)
    .borderRadius(this.playerHeight() / 2)
    .clip(true)
    .systemMaterial(FnMusicMaterials.material(FnMusicMaterialRole.FLOATING_PLAYER))
    .id(this.transitionId)
  }
}

@ComponentV2
struct QueuePanel {
  @Param state: PlayerPresentationState = new PlayerPresentationState();
  @Param safeBottom: number = 0;
  @Local selectedTab: number = 0;
  @Event onClose: () => void = (): void => {};
  @Event onSelect: (index: number) => void = (_: number): void => {};
  @Event onRemove: (index: number) => void = (_: number): void => {};
  @Event onClear: () => void = (): void => {};
  @Event onRepeat: () => void = (): void => {};

  private repeatSymbol(): Resource {
    return this.state.repeatMode === PlaybackRepeatMode.ONE ?
      $r('sys.symbol.repeat_1') : $r('sys.symbol.repeat');
  }

  private repeatLabel(): string {
    if (this.state.repeatMode === PlaybackRepeatMode.ONE) {
      return '单曲循环';
    }
    if (this.state.repeatMode === PlaybackRepeatMode.LIST) {
      return '列表循环';
    }
    return '顺序播放';
  }

  private formatLabel(track: MusicTrack): string {
    const format: string = track.audioSpec.format.trim();
    return (format.length > 0 ? format : track.audioSpec.codec.trim()).toUpperCase();
  }

  private trackSubtitle(track: MusicTrack): string {
    const artist: string = track.artistName.trim();
    const album: string = track.albumName.trim();
    if (artist.length > 0 && album.length > 0) {
      return `${artist} - ${album}`;
    }
    return artist.length > 0 ? artist : album;
  }

  build() {
    Column() {
      Row() {
        Text('播放列表')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(20)
            .fontColor([$r('app.color.text_primary')])
        }
        .width(44)
        .height(44)
        .backgroundColor(Color.Transparent)
        .systemMaterial(FnMusicMaterials.material(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
        .accessibilityText('关闭播放列表')
        .onClick((): void => this.onClose())
      }
      .width('100%')
      .height(60)

      Row() {
        if (this.selectedTab === 0) {
          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Text(`当前列表 ${this.state.queue.length}`)
              .fontSize(FnMusicUI.bodySize)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
          }
          .layoutWeight(1)
          .height(42)
          .borderRadius(21)
          .backgroundColor(Color.Transparent)
          .systemMaterial(FnMusicMaterials.material(FnMusicMaterialRole.CHIP_SELECTED))
          .onClick((): void => { this.selectedTab = 0; })
        } else {
          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Text(`当前列表 ${this.state.queue.length}`)
              .fontSize(FnMusicUI.bodySize)
              .fontWeight(FontWeight.Regular)
              .fontColor($r('app.color.text_secondary'))
          }
          .layoutWeight(1)
          .height(42)
          .borderRadius(21)
          .backgroundColor(Color.Transparent)
          .onClick((): void => { this.selectedTab = 0; })
        }

        if (this.selectedTab === 1) {
          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Text('历史列表 0')
              .fontSize(FnMusicUI.bodySize)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
          }
          .layoutWeight(1)
          .height(42)
          .borderRadius(21)
          .backgroundColor(Color.Transparent)
          .systemMaterial(FnMusicMaterials.material(FnMusicMaterialRole.CHIP_SELECTED))
          .onClick((): void => { this.selectedTab = 1; })
        } else {
          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Text('历史列表 0')
              .fontSize(FnMusicUI.bodySize)
              .fontWeight(FontWeight.Regular)
              .fontColor($r('app.color.text_secondary'))
          }
          .layoutWeight(1)
          .height(42)
          .borderRadius(21)
          .backgroundColor(Color.Transparent)
          .onClick((): void => { this.selectedTab = 1; })
        }
      }
      .width('100%')
      .height(46)
      .padding(2)
      .borderRadius(23)
      .backgroundColor($r('app.color.surface_secondary'))

      Text('播放来源：飞牛音乐')
        .width('100%')
        .fontSize(FnMusicUI.supportingSize)
        .fontColor($r('app.color.text_secondary'))
        .padding({ top: 16, bottom: 12 })

      Row() {
        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Row({ space: 8 }) {
            SymbolGlyph(this.repeatSymbol())
              .fontSize(20)
              .fontColor([$r('app.color.text_primary')])
            Text(this.repeatLabel())
              .fontSize(FnMusicUI.bodySize)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
          }
        }
        .height(42)
        .padding({ left: 0, right: 8 })
        .backgroundColor(Color.Transparent)
        .onClick((): void => this.onRepeat())

        Blank()

        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph($r('sys.symbol.trash'))
            .fontSize(20)
            .fontColor([$r('app.color.text_secondary')])
        }
        .width(42)
        .height(42)
        .backgroundColor(Color.Transparent)
        .enabled(this.state.queue.length > 0)
        .accessibilityText('清空播放列表')
        .onClick((): void => this.onClear())
      }
      .width('100%')
      .height(50)

      if (this.selectedTab === 0) {
        if (this.state.queue.length === 0) {
          Column() {
            EmptyMusicState({
              kind: MusicEmptyKind.LIST,
              title: '空空如也',
              compact: true,
              illustrationSize: FnMusicUI.emptyIllustrationSize
            })
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          List({ space: 0 }) {
            Repeat<MusicTrack>(this.state.queue)
              .each((repeatItem: RepeatItem<MusicTrack>): void => {
                ListItem() {
                  Column() {
                    Row({ space: 10 }) {
                      Row({ space: 10 }) {
                        SymbolGlyph(repeatItem.index === this.state.currentIndex ?
                          $r('sys.symbol.speaker_wave_2_fill') : $r('sys.symbol.music'))
                          .width(24)
                          .fontSize(17)
                          .fontColor([repeatItem.index === this.state.currentIndex ?
                            $r('app.color.accent') : $r('app.color.text_secondary')])
                        Column({ space: 3 }) {
                          Text(repeatItem.item.title)
                            .fontSize(FnMusicUI.bodySize)
                            .fontWeight(repeatItem.index === this.state.currentIndex ? FontWeight.Medium : FontWeight.Regular)
                            .fontColor(repeatItem.index === this.state.currentIndex ?
                              $r('app.color.accent') : $r('app.color.text_primary'))
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                          Row({ space: 6 }) {
                            if (this.formatLabel(repeatItem.item).length > 0) {
                              Text(this.formatLabel(repeatItem.item))
                                .height(20)
                                .padding({ left: 5, right: 5 })
                                .fontSize(10)
                                .fontColor($r('app.color.text_secondary'))
                                .borderRadius(5)
                                .backgroundColor($r('app.color.player_format_background'))
                            }
                            Text(this.trackSubtitle(repeatItem.item))
                              .layoutWeight(1)
                              .fontSize(FnMusicUI.supportingSize)
                              .fontColor(repeatItem.index === this.state.currentIndex ?
                                $r('app.color.accent') : $r('app.color.text_secondary'))
                              .maxLines(1)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                          }
                          .width('100%')
                        }
                        .layoutWeight(1)
                        .alignItems(HorizontalAlign.Start)
                      }
                      .layoutWeight(1)
                      .height('100%')
                      .alignItems(VerticalAlign.Center)
                      .onClick((): void => this.onSelect(repeatItem.index))
                      Button({ type: ButtonType.Circle, stateEffect: true }) {
                        SymbolGlyph($r('sys.symbol.xmark'))
                          .fontSize(19)
                          .fontColor([$r('app.color.text_secondary')])
                      }
                      .width(40)
                      .height(40)
                      .backgroundColor(Color.Transparent)
                      .accessibilityText(`从播放列表移除 ${repeatItem.item.title}`)
                      .onClick((): void => this.onRemove(repeatItem.index))
                    }
                    .width('100%')
                    .height(58)
                    .padding({ left: 2, right: 0 })

                    Divider()
                      .strokeWidth(0.5)
                      .color($r('app.color.divider'))
                      .margin({ left: 34 })
                  }
                }
              })
              .key((item: MusicTrack): string => item.guid)
              .virtualScroll()
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Off)
          .cachedCount(3)
        }
      } else {
        Column() {
          EmptyMusicState({
            kind: MusicEmptyKind.LIST,
            title: '暂无历史列表',
            compact: true,
            illustrationSize: FnMusicUI.emptyIllustrationSize
          })
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('76%')
    .padding({ left: 20, right: 20, top: 12, bottom: Math.max(18, this.safeBottom + 12) })
    .borderRadius({ topLeft: 28, topRight: 28 })
    .clip(true)
    .backgroundColor(Color.Transparent)
    .systemMaterial(FnMusicMaterials.material(FnMusicMaterialRole.FLOATING_NAVIGATION))
  }
}

@ComponentV2
export struct PlaybackQueueSheet {
  @Param state: PlayerPresentationState = new PlayerPresentationState();
  @Param safeBottom: number = 0;
  @Event onClose: () => void = (): void => {};
  @Event onSelect: (index: number) => void = (_: number): void => {};
  @Event onRemove: (index: number) => void = (_: number): void => {};
  @Event onClear: () => void = (): void => {};
  @Event onRepeat: () => void = (): void => {};

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.scrim'))
        .onClick((): void => this.onClose())
      QueuePanel({
        state: this.state,
        safeBottom: this.safeBottom,
        onClose: (): void => this.onClose(),
        onSelect: (index: number): void => this.onSelect(index),
        onRemove: (index: number): void => this.onRemove(index),
        onClear: (): void => this.onClear(),
        onRepeat: (): void => this.onRepeat()
      })
    }
    .width('100%')
    .height('100%')
  }
}

@ComponentV2
struct PlayerPageIndicator {
  @Param page: ExpandedPanel = ExpandedPanel.PLAYER;

  build() {
    Row({ space: 6 }) {
      PlayerPageDot({ selected: this.page === ExpandedPanel.PLAYER })
      PlayerPageDot({ selected: this.page === ExpandedPanel.LYRICS })
    }
    .height(12)
    .alignItems(VerticalAlign.Center)
  }
}

@ComponentV2
struct PlayerPageDot {
  @Param selected: boolean = false;

  build() {
    Column()
      .width(this.selected ? 14 : 5)
      .height(5)
      .borderRadius(3)
      .backgroundColor(this.selected ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
      .opacity(this.selected ? 0.9 : 0.45)
      .animation({ duration: 180, curve: Curve.EaseOut })
  }
}

@ComponentV2
struct PlayerControlRow {
  @Param state: PlayerPresentationState = new PlayerPresentationState();
  @Event onRepeat: () => void = (): void => {};
  @Event onPrevious: () => void = (): void => {};
  @Event onToggle: () => void = (): void => {};
  @Event onNext: () => void = (): void => {};
  @Event onQueue: () => void = (): void => {};

  private playing(): boolean {
    return this.state.status === PlaybackStatus.PLAYING || this.state.status === PlaybackStatus.BUFFERING ||
      this.state.status === PlaybackStatus.PREPARING;
  }

  private repeatSymbol(): Resource {
    return this.state.repeatMode === PlaybackRepeatMode.ONE ?
      $r('sys.symbol.repeat_1') : $r('sys.symbol.repeat');
  }

  build() {
    Row() {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph(this.repeatSymbol())
          .fontSize(21)
          .fontColor([this.state.repeatMode === PlaybackRepeatMode.SEQUENCE ?
            $r('app.color.text_secondary') : $r('app.color.accent')])
      }
      .width(FnMusicUI.tapTarget)
      .height(FnMusicUI.tapTarget)
      .backgroundColor(Color.Transparent)
      .accessibilityText('循环模式')
      .onClick((): void => this.onRepeat())

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.backward_end_fill'))
          .fontSize(24)
          .fontColor([$r('app.color.text_primary')])
      }
      .width(52)
      .height(52)
      .backgroundColor(Color.Transparent)
      .accessibilityText('上一首')
      .onClick((): void => this.onPrevious())

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        if (this.state.status === PlaybackStatus.PREPARING || this.state.status === PlaybackStatus.BUFFERING) {
          LoadingProgress().width(28).height(28).color($r('app.color.accent_contrast'))
        } else {
          SymbolGlyph(this.playing() ? $r('sys.symbol.pause_fill') : $r('sys.symbol.play_fill'))
            .fontSize(30)
            .fontColor([$r('app.color.accent_contrast')])
        }
      }
      .width(64)
      .height(64)
      .backgroundColor($r('app.color.accent'))
      .accessibilityText(this.playing() ? '暂停' : '播放')
      .onClick((): void => this.onToggle())

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.forward_end_fill'))
          .fontSize(24)
          .fontColor([$r('app.color.text_primary')])
      }
      .width(52)
      .height(52)
      .backgroundColor(Color.Transparent)
      .accessibilityText('下一首')
      .onClick((): void => this.onNext())

      Button({ type: ButtonType.Circle, stateEffect: !this.state.roamMode }) {
        if (this.state.roamMode) {
          RoamPulseIcon({ iconSize: 22 })
        } else {
          SymbolGlyph($r('sys.symbol.music_note_list'))
            .fontSize(21)
            .fontColor([$r('app.color.text_secondary')])
        }
      }
      .width(FnMusicUI.tapTarget)
      .height(FnMusicUI.tapTarget)
      .backgroundColor(Color.Transparent)
      .accessibilityText(this.state.roamMode ? '漫游模式' : '播放队列')
      .onClick((): void => {
        if (!this.state.roamMode) {
          this.onQueue();
        }
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
  }
}

@ComponentV2
struct PlayerLyricPage {
  @Param state: PlayerPresentationState = new PlayerPresentationState();
  @Param track: MusicTrack = new MusicTrack();
  @Param visible: boolean = false;
  @Event onSeek: (positionMs: number) => void = (_: number): void => {};
  @Event onRetry: () => void = (): void => {};
  @Event onToggle: () => void = (): void => {};
  @Event onNext: () => void = (): void => {};
  @Event onPrevious: () => void = (): void => {};
  @Event onRepeat: () => void = (): void => {};
  @Event onQueue: () => void = (): void => {};
  @Event onSettings: () => void = (): void => {};
  @Local controlsVisible: boolean = true;
  @Local previewing: boolean = false;
  @Local previewIndex: number = -1;
  @Local contentOffset: number = 0;
  private lyricScroller: Scroller = new Scroller();
  private immersionTimer: number = -1;

  aboutToAppear(): void {
    this.scrollToActiveLine(false);
    this.restartImmersionTimer();
  }

  aboutToDisappear(): void {
    this.clearImmersionTimer();
  }

  @Monitor('state.activeLyricIndex')
  onActiveLyricChanged(): void {
    if (!this.previewing) {
      this.scrollToActiveLine(true);
    }
  }

  @Monitor('visible')
  onVisibleChanged(): void {
    if (this.visible) {
      this.controlsVisible = true;
      this.previewing = false;
      this.previewIndex = -1;
      this.scrollToActiveLine(true);
      this.restartImmersionTimer();
    } else {
      this.clearImmersionTimer();
    }
  }

  @Monitor('track.guid')
  onTrackChanged(): void {
    this.controlsVisible = true;
    this.previewing = false;
    this.previewIndex = -1;
    this.restartImmersionTimer();
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column({ space: 12 }) {
        Row({ space: 12 }) {
          MusicArtwork({
            artworkSize: 52,
            radius: 8,
            placeholderMedia: $r('app.media.music_track_placeholder'),
            placeholderRatio: 0.56,
            coverId: this.track.coverId,
            updatedAt: this.track.updatedAt
          })
          Column({ space: 3 }) {
            Text(this.track.title)
              .width('100%')
              .fontSize(18)
              .lineHeight(24)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.track.artistName.length > 0 ? this.track.artistName : this.track.albumName)
              .width('100%')
              .fontSize(FnMusicUI.supportingSize)
              .fontColor($r('app.color.text_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({ left: 4, right: 4 })
        .alignItems(VerticalAlign.Center)

        if (this.state.lyricStatus === LyricLoadStatus.LOADING) {
          Column({ space: 12 }) {
            LoadingProgress()
              .width(28)
              .height(28)
              .color($r('app.color.text_secondary'))
            Text('正在读取歌词')
              .fontSize(FnMusicUI.supportingSize)
              .fontColor($r('app.color.text_secondary'))
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else if (this.state.lyricLines.length === 0) {
          Column({ space: 12 }) {
            Text(this.state.lyricStatus === LyricLoadStatus.ERROR ? '歌词读取失败' : '暂无歌词')
              .fontSize(this.state.lyricStatus === LyricLoadStatus.ERROR ?
                FnMusicUI.playerLyricErrorSize : FnMusicUI.playerEmptyLyricSize)
              .lineHeight(this.state.lyricStatus === LyricLoadStatus.ERROR ?
                FnMusicUI.playerLyricErrorLineHeight : FnMusicUI.playerEmptyLyricLineHeight)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_secondary'))
            if (this.state.lyricStatus === LyricLoadStatus.ERROR) {
              Button('重新读取')
                .height(34)
                .padding({ left: 18, right: 18 })
                .fontSize(FnMusicUI.supportingSize)
                .fontColor($r('app.color.text_primary'))
                .backgroundColor($r('app.color.surface_secondary'))
                .borderRadius(17)
                .onClick((): void => {
                  this.restartImmersionTimer();
                  this.onRetry();
                })
            }
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          Scroll(this.lyricScroller) {
            Column() {
              Repeat<LyricLine>(this.state.lyricLines)
                .each((repeatItem: RepeatItem<LyricLine>): void => {
                  Text(repeatItem.item.text)
                    .width('100%')
                    .height(PLAYER_LYRIC_LINE_HEIGHT)
                    .fontSize(20)
                    .lineHeight(PLAYER_LYRIC_LINE_HEIGHT)
                    .fontWeight(repeatItem.index === this.highlightedIndex() ?
                      FontWeight.Bold : FontWeight.Medium)
                    .fontColor(repeatItem.index === this.highlightedIndex() ?
                      $r('app.color.text_primary') : $r('app.color.player_lyric_inactive'))
                    .scale({
                      x: repeatItem.index === this.highlightedIndex() ? 1.035 : 0.985,
                      y: repeatItem.index === this.highlightedIndex() ? 1.035 : 0.985,
                      centerX: '0%',
                      centerY: '50%'
                    })
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .animation({ duration: 320, curve: Curve.EaseInOut })
                })
                .key((item: LyricLine): string => `${item.timeMs}:${item.text}`)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding({
              left: 4,
              right: 4,
              top: PLAYER_LYRIC_ACTIVE_TOP_OFFSET,
              bottom: PLAYER_LYRIC_CONTENT_BOTTOM_PADDING
            })
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Off)
          .fadingEdge(true, { fadingEdgeLength: LengthMetrics.vp(PLAYER_LYRIC_FADING_EDGE_LENGTH) })
          .onWillScroll((_xOffset: number, _yOffset: number, _scrollState: ScrollState,
            scrollSource: ScrollSource): void => {
            if (this.isUserScrollSource(scrollSource)) {
              this.beginLyricPreview();
            }
          })
          .onDidScroll((): void => this.syncLyricPreview())
          .onScrollStop((): void => {
            this.syncLyricPreview();
            if (this.previewing && this.controlsVisible) {
              this.restartImmersionTimer();
            }
          })
          .onAreaChange((): void => this.scrollToActiveLine(false))
        }

        Blank()
          .height(this.controlsVisible ? 4 : PLAYER_LYRIC_IMMERSIVE_BOTTOM_GUTTER)

        if (this.controlsVisible) {
          Column({ space: 4 }) {
            Slider({
              value: this.state.positionMs,
              min: 0,
              max: Math.max(1, this.state.durationMs),
              step: 1000,
              style: SliderStyle.OutSet
            })
              .width('100%')
              .height(28)
              .blockSize({ width: 13, height: 13 })
              .blockColor($r('app.color.accent'))
              .trackColor($r('app.color.outline'))
              .selectedColor($r('app.color.accent'))
              .trackThickness(4)
              .onChange((value: number, mode: SliderChangeMode): void => {
                this.restartImmersionTimer();
                if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
                  this.onSeek(value);
                }
              })
            Row() {
              Text(formatDuration(this.state.positionMs)).fontSize(11).fontColor($r('app.color.text_secondary'))
              Blank()
              Text(formatDuration(this.state.durationMs)).fontSize(11).fontColor($r('app.color.text_secondary'))
            }
            .width('100%')
          }
          .width('100%')

          PlayerControlRow({
            state: this.state,
            onRepeat: (): void => { this.restartImmersionTimer(); this.onRepeat(); },
            onPrevious: (): void => { this.restartImmersionTimer(); this.onPrevious(); },
            onToggle: (): void => { this.restartImmersionTimer(); this.onToggle(); },
            onNext: (): void => { this.restartImmersionTimer(); this.onNext(); },
            onQueue: (): void => { this.restartImmersionTimer(); this.onQueue(); }
          })
          .transition(TransitionEffect.OPACITY)
        }
      }
      .width('100%')
      .height('100%')

      if (!this.controlsVisible) {
        Row() {
          Button({ type: ButtonType.Normal, stateEffect: false }) {
            Row()
              .width('100%')
              .height('100%')
          }
          .layoutWeight(1)
          .height('100%')
          .padding(0)
          .backgroundColor($r('app.color.player_hit_target'))
          .accessibilityText('显示播放控制')
          .onClick((): void => {
            this.controlsVisible = true;
            this.restartImmersionTimer();
          })
          Blank().width(44)
        }
        .width('100%')
        .height(PLAYER_LYRIC_RESTORE_HEIGHT)
        .zIndex(2)
      }

      if (this.previewing && this.previewIndex >= 0 && this.previewIndex < this.state.lyricLines.length) {
        Stack({ alignContent: Alignment.TopEnd }) {
          Row({ space: 4 }) {
            SymbolGlyph($r('sys.symbol.play_fill'))
              .fontSize(12)
              .fontColor([$r('app.color.accent_contrast')])
            Text(formatDuration(this.previewPosition()))
              .fontSize(11)
              .fontColor($r('app.color.accent_contrast'))
          }
          .height(30)
          .padding({ left: 10, right: 10 })
          .borderRadius(15)
          .backgroundColor($r('app.color.accent'))
          .onClick((): void => this.seekPreview(this.previewPosition()))
        }
        .width('100%')
        .height('100%')
        .padding({ top: PLAYER_LYRIC_PREVIEW_TOP, right: 4 })
        .hitTestBehavior(HitTestMode.Transparent)
      }

      Stack({ alignContent: Alignment.Center }) {
        SymbolGlyph($r('sys.symbol.lyrics_square'))
          .fontSize(22)
          .fontColor([$r('app.color.text_primary')])
      }
        .width(FnMusicUI.tapTarget)
        .height(FnMusicUI.tapTarget)
        .zIndex(3)
        .translate({ y: this.controlsVisible ? -PLAYER_LYRIC_SETTINGS_OFFSET : 0 })
        .accessibilityText('歌词设置')
        .onClick((): void => {
          if (this.controlsVisible) {
            this.restartImmersionTimer();
          } else {
            this.clearImmersionTimer();
          }
          this.onSettings();
        })
    }
    .width('100%')
    .height('100%')
  }

  private seekPreview(positionMs: number): void {
    const controlsWereVisible = this.controlsVisible;
    this.previewing = false;
    this.previewIndex = -1;
    this.onSeek(positionMs);
    this.scrollToActiveLine(true);
    if (controlsWereVisible) {
      this.restartImmersionTimer();
    } else {
      this.clearImmersionTimer();
    }
  }

  private isUserScrollSource(source: ScrollSource): boolean {
    return source === ScrollSource.DRAG || source === ScrollSource.FLING ||
      source === ScrollSource.OTHER_USER_INPUT || source === ScrollSource.SCROLL_BAR ||
      source === ScrollSource.SCROLL_BAR_FLING;
  }

  private beginLyricPreview(): void {
    if (!this.previewing) {
      this.previewing = true;
    }
    this.syncLyricPreview();
  }

  private syncLyricPreview(): void {
    if (!this.previewing) {
      return;
    }
    this.contentOffset = Math.max(0, this.lyricScroller.currentOffset().yOffset);
    this.previewIndex = nearestLyricIndex(this.state.lyricLines, this.contentOffset,
      PLAYER_LYRIC_LINE_HEIGHT, 0);
  }

  private highlightedIndex(): number {
    return this.previewing && this.previewIndex >= 0 ? this.previewIndex : this.state.activeLyricIndex;
  }

  private previewPosition(): number {
    if (this.previewIndex < 0 || this.previewIndex >= this.state.lyricLines.length) {
      return this.state.positionMs;
    }
    return this.state.lyricLines[this.previewIndex].timeMs;
  }

  private restartImmersionTimer(): void {
    this.clearImmersionTimer();
    if (!this.visible) {
      return;
    }
    this.controlsVisible = true;
    this.immersionTimer = setTimeout((): void => {
      if (this.visible) {
        this.controlsVisible = false;
      }
    }, PLAYER_IMMERSION_DELAY);
  }

  private clearImmersionTimer(): void {
    if (this.immersionTimer >= 0) {
      clearTimeout(this.immersionTimer);
      this.immersionTimer = -1;
    }
  }

  private scrollToActiveLine(animated: boolean): void {
    if (!this.visible || this.previewing || this.state.activeLyricIndex < 0) {
      return;
    }
    this.lyricScroller.scrollTo({
      xOffset: 0,
      yOffset: this.state.activeLyricIndex * PLAYER_LYRIC_LINE_HEIGHT,
      animation: animated ? { duration: 480, curve: Curve.EaseInOut } : undefined
    });
  }

}

@ComponentV2
struct ExpandedPlayer {
  @Param state: PlayerPresentationState = new PlayerPresentationState();
  @Param panel: ExpandedPanel = ExpandedPanel.PLAYER;
  @Param palette: PlayerPaletteState = new PlayerPaletteState();
  @Param menuVisible: boolean = false;
  @Param safeTop: number = 0;
  @Param safeBottom: number = 0;
  @Event onCollapse: () => void = (): void => {};
  @Event onCast: () => void = (): void => {};
  @Event onFavorite: () => void = (): void => {};
  @Event onToggleMenu: () => void = (): void => {};
  @Event onOpenAlbum: () => void = (): void => {};
  @Event onOpenArtist: () => void = (): void => {};
  @Event onAddPlaylist: () => void = (): void => {};
  @Event onTrackInfo: () => void = (): void => {};
  @Event onLyricsSettings: () => void = (): void => {};
  @Event onToggle: () => void = (): void => {};
  @Event onNext: () => void = (): void => {};
  @Event onPrevious: () => void = (): void => {};
  @Event onSeek: (positionMs: number) => void = (_: number): void => {};
  @Event onPanel: (panel: ExpandedPanel) => void = (_: ExpandedPanel): void => {};
  @Event onRepeat: () => void = (): void => {};
  @Event onQueueSelect: (index: number) => void = (_: number): void => {};
  @Event onQueueRemove: (index: number) => void = (_: number): void => {};
  @Event onClearQueue: () => void = (): void => {};
  @Event onRetryLyrics: () => void = (): void => {};
  @Local contentDragOffsetX: number = 0;

  private track(): MusicTrack {
    return this.state.currentTrack() ?? new MusicTrack();
  }

  private subtitle(): string {
    const artist = this.track().artistName.trim();
    const album = this.track().albumName.trim();
    if (artist.length > 0 && album.length > 0) {
      return `${artist} - ${album}`;
    }
    return artist.length > 0 ? artist : album;
  }

  private playbackErrorText(): string {
    const message = this.state.errorMessage.toLowerCase();
    if (message.includes('timeout') || message.includes('cachebuffer') || message.includes('timed out')) {
      return '播放连接超时，请重试';
    }
    return '播放失败，请重试';
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [
            [$r('app.color.page_player_background_start'), 0],
            [$r('app.color.page_player_background_end'), 1]
          ]
        })

      if (this.palette.available()) {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 180,
            colors: [[this.palette.startColor, 0], [this.palette.endColor, 1]]
          })
          .opacity(0.56)
          .animation({ duration: 320, curve: Curve.EaseOut })
      }

      Column() {
        Row() {
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph($r('sys.symbol.chevron_down'))
              .fontSize(24)
              .fontColor([$r('app.color.text_primary')])
          }
          .width(FnMusicUI.tapTarget)
          .height(FnMusicUI.tapTarget)
          .backgroundColor(Color.Transparent)
          .accessibilityText('收起播放器')
          .onClick((): void => this.onCollapse())
          Blank()
          PlayerPageIndicator({ page: this.panel })
          Blank()
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph($r('sys.symbol.airplayaudio'))
              .fontSize(21)
              .fontColor([$r('app.color.text_primary')])
          }
          .width(FnMusicUI.tapTarget)
          .height(FnMusicUI.tapTarget)
          .backgroundColor(Color.Transparent)
          .accessibilityText('投播')
          .onClick((): void => this.onCast())
        }
        .width('100%')

        Stack({ alignContent: Alignment.Center }) {
          MusicArtwork({
            artworkSize: 252,
            radius: 18,
            placeholderMedia: $r('app.media.music_track_placeholder'),
            placeholderRatio: 0.24,
            coverId: this.track().coverId,
            updatedAt: this.track().updatedAt
          })
            .opacity(1 - this.lyricPageProgress())
            .scale({ x: this.coverScale(), y: this.coverScale() })
            .translate({ x: this.coverTranslateX(), y: this.coverTranslateY() - PLAYER_COVER_LIFT })
            .animation({ duration: this.contentDragOffsetX === 0 ? 220 : 0, curve: Curve.EaseOut })

          PlayerLyricPage({
            state: this.state,
            track: this.track(),
            visible: this.panel === ExpandedPanel.LYRICS,
            onSeek: (positionMs: number): void => this.onSeek(positionMs),
            onRetry: (): void => this.onRetryLyrics(),
            onToggle: (): void => this.onToggle(),
            onNext: (): void => this.onNext(),
            onPrevious: (): void => this.onPrevious(),
            onRepeat: (): void => this.onRepeat(),
            onQueue: (): void => this.onPanel(ExpandedPanel.QUEUE),
            onSettings: (): void => this.onLyricsSettings()
          })
            .opacity(this.lyricPageProgress())
            .translate({ x: (1 - this.lyricPageProgress()) * 28, y: 0 })
            .animation({ duration: this.contentDragOffsetX === 0 ? 220 : 0, curve: Curve.EaseOut })
        }
        .width('100%')
        .layoutWeight(1)
        .clip(true)
        .gesture(
          PanGesture({ direction: PanDirection.Horizontal, distance: 2 })
            .onActionUpdate((event: GestureEvent): void => this.updateContentDrag(event.offsetX))
            .onActionEnd((event: GestureEvent): void => this.finishContentSwipe(event.offsetX))
            .onActionCancel((): void => { this.contentDragOffsetX = 0; })
        )

        if (this.panel !== ExpandedPanel.LYRICS) {
          Column({ space: 8 }) {
            Column({ space: 8 }) {
              Row({ space: 8 }) {
            Column({ space: 4 }) {
              Text(this.track().title)
                .width('100%')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(this.subtitle())
                .width('100%')
                .fontSize(FnMusicUI.bodySize)
                .fontColor($r('app.color.text_secondary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Button({ type: ButtonType.Circle, stateEffect: true }) {
              SymbolGlyph(this.track().isFavorite ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
                .fontSize(22)
                .fontColor([this.track().isFavorite ? $r('app.color.accent') : $r('app.color.text_primary')])
            }
            .width(FnMusicUI.tapTarget)
            .height(FnMusicUI.tapTarget)
            .backgroundColor(Color.Transparent)
            .accessibilityText(this.track().isFavorite ? '取消收藏' : '收藏')
            .onClick((): void => this.onFavorite())

            Button({ type: ButtonType.Circle, stateEffect: true }) {
              SymbolGlyph($r('sys.symbol.more'))
                .fontSize(22)
                .fontColor([$r('app.color.text_primary')])
            }
            .width(FnMusicUI.tapTarget)
            .height(FnMusicUI.tapTarget)
            .backgroundColor(Color.Transparent)
            .accessibilityText('更多歌曲操作')
            .onClick((): void => this.onToggleMenu())
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

            if (this.state.status === PlaybackStatus.ERROR) {
            Row({ space: 10 }) {
              Text(this.playbackErrorText())
                .layoutWeight(1)
                .fontSize(FnMusicUI.supportingSize)
                .fontColor($r('app.color.text_secondary'))
                .maxLines(2)
              Button('重新播放')
                .height(36)
                .padding({ left: 16, right: 16 })
                .fontSize(FnMusicUI.supportingSize)
                .fontColor($r('app.color.accent_contrast'))
                .backgroundColor($r('app.color.accent'))
                .borderRadius(18)
                .onClick((): void => this.onToggle())
            }
            .width('100%')
            }

            Column({ space: 4 }) {
            Slider({
              value: this.state.positionMs,
              min: 0,
              max: Math.max(1, this.state.durationMs),
              step: 1000,
              style: SliderStyle.OutSet
            })
              .width('100%')
              .height(30)
              .blockSize({ width: 14, height: 14 })
              .blockColor($r('app.color.accent'))
              .trackColor($r('app.color.outline'))
              .selectedColor($r('app.color.accent'))
              .trackThickness(4)
              .onChange((value: number, mode: SliderChangeMode): void => {
                if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
                  this.onSeek(value);
                }
              })
            Row() {
              Text(formatDuration(this.state.positionMs))
                .fontSize(11)
                .fontColor($r('app.color.text_secondary'))
              Blank()
              if (playerFormatLabel(this.track()).length > 0) {
                Text(playerFormatLabel(this.track()))
                  .height(22)
                  .padding({ left: 9, right: 9 })
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                  .borderRadius(5)
                  .backgroundColor($r('app.color.player_format_background'))
              }
              Blank()
              Text(formatDuration(this.state.durationMs))
                .fontSize(11)
                .fontColor($r('app.color.text_secondary'))
            }
            .width('100%')
            }
            .width('100%')

            }
            .width('100%')
            .translate({ y: -PLAYER_INFO_LIFT })

            PlayerControlRow({
              state: this.state,
              onRepeat: (): void => this.onRepeat(),
              onPrevious: (): void => this.onPrevious(),
              onToggle: (): void => this.onToggle(),
              onNext: (): void => this.onNext(),
              onQueue: (): void => this.onPanel(ExpandedPanel.QUEUE)
            })
          }
          .width('100%')
        }
      }
      .width('100%')
      .height('100%')
      .padding({
        left: 24,
        right: 24,
        top: Math.max(20, this.safeTop + 8),
        bottom: Math.max(24, this.safeBottom + 16)
      })

      if (this.menuVisible) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(Color.Transparent)
          .zIndex(19)
          .onClick((): void => this.onToggleMenu())

        Stack({ alignContent: Alignment.BottomEnd }) {
          PlayerTrackMenu({
            canOpenAlbum: this.track().albumGuid.length > 0 || this.track().albumName.length > 0,
            canOpenArtist: this.track().artists.length > 0 || this.track().artistName.length > 0,
            onOpenAlbum: (): void => this.onOpenAlbum(),
            onOpenArtist: (): void => this.onOpenArtist(),
            onAddPlaylist: (): void => this.onAddPlaylist(),
            onInfo: (): void => this.onTrackInfo()
          })
        }
        .width('100%')
        .height('100%')
        .padding({ right: 24, bottom: PLAYER_MENU_BOTTOM_OFFSET })
        .hitTestBehavior(HitTestMode.Transparent)
        .zIndex(20)
      }

      if (this.panel === ExpandedPanel.QUEUE) {
        PlaybackQueueSheet({
          state: this.state,
          safeBottom: this.safeBottom,
          onClose: (): void => this.onPanel(ExpandedPanel.PLAYER),
          onSelect: (index: number): void => this.onQueueSelect(index),
          onRemove: (index: number): void => this.onQueueRemove(index),
          onClear: (): void => this.onClearQueue(),
          onRepeat: (): void => this.onRepeat()
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  private finishContentSwipe(offsetX: number): void {
    if (offsetX <= -PLAYER_PAGE_SWITCH_THRESHOLD) {
      this.onPanel(ExpandedPanel.LYRICS);
    } else if (offsetX >= PLAYER_PAGE_SWITCH_THRESHOLD) {
      this.onPanel(ExpandedPanel.PLAYER);
    }
    this.contentDragOffsetX = 0;
  }

  private updateContentDrag(offsetX: number): void {
    if (this.panel === ExpandedPanel.QUEUE ||
      (this.panel === ExpandedPanel.PLAYER && offsetX > 0) ||
      (this.panel === ExpandedPanel.LYRICS && offsetX < 0)) {
      this.contentDragOffsetX = 0;
      return;
    }
    this.contentDragOffsetX = Math.max(-PLAYER_PAGE_SWIPE_DISTANCE,
      Math.min(PLAYER_PAGE_SWIPE_DISTANCE, offsetX));
  }

  private lyricPageProgress(): number {
    if (this.panel !== ExpandedPanel.LYRICS) {
      return Math.max(0, Math.min(1, -this.contentDragOffsetX / PLAYER_PAGE_SWIPE_DISTANCE));
    }
    return Math.max(0, Math.min(1, 1 - this.contentDragOffsetX / PLAYER_PAGE_SWIPE_DISTANCE));
  }

  private coverScale(): number {
    return 1 - this.lyricPageProgress() * 0.66;
  }

  private coverTranslateX(): number {
    return -104 * this.lyricPageProgress();
  }

  private coverTranslateY(): number {
    return -126 * this.lyricPageProgress();
  }
}

@ComponentV2
export struct MusicPlayerScreen {
  @Param safeTop: number = 0;
  @Param safeBottom: number = 0;
  @Param albums: MusicAlbum[] = [];
  @Param artists: MusicArtist[] = [];
  @Param playlists: MusicPlaylist[] = [];
  @Event onBack: () => void = (): void => {};
  @Event onFavorite: (track: MusicTrack, favorite: boolean) => void =
    (_: MusicTrack, __: boolean): void => {};
  @Event onOpenAlbum: (track: MusicTrack) => void = (_: MusicTrack): void => {};
  @Event onOpenArtist: (artist: MusicArtist) => void = (_: MusicArtist): void => {};
  @Event onAddPlaylist: (track: MusicTrack, playlist: MusicPlaylist) => void =
    (_: MusicTrack, __: MusicPlaylist): void => {};
  @Local state: PlayerPresentationState = connectPlayerPresentationState();
  @Local preferences: MusicPreferenceState = connectMusicPreferenceState();
  @Local panel: ExpandedPanel = ExpandedPanel.PLAYER;
  @Local palette: PlayerPaletteState = new PlayerPaletteState();
  @Local menuVisible: boolean = false;
  @Local artistPickerVisible: boolean = false;
  @Local playlistPickerVisible: boolean = false;
  @Local trackInfoVisible: boolean = false;
  @Local lyricsSettingsVisible: boolean = false;
  @Local desktopLyricSupported: boolean = false;
  @Local checkingDesktopLyric: boolean = false;
  private controller: MusicPlaybackController = MusicPlaybackController.instance();

  aboutToAppear(): void {
    this.syncQueuePanel();
    this.loadPalette();
  }

  @Monitor('state.queueVisible')
  onQueueVisibilityChanged(): void {
    this.syncQueuePanel();
  }

  @Monitor('state.currentIndex', 'state.queue')
  onCurrentTrackChanged(): void {
    this.dismissLocalOverlays();
    this.loadPalette();
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      ExpandedPlayer({
        state: this.state,
        panel: this.panel,
        palette: this.palette,
        menuVisible: this.menuVisible,
        safeTop: this.safeTop,
        safeBottom: this.safeBottom,
        onCollapse: (): void => {
          if (!this.dismissLocalOverlays()) {
            this.onBack();
          }
        },
        onCast: (): void => this.showCastPicker(),
        onFavorite: (): void => {
          const track = this.currentTrack();
          this.onFavorite(track, !track.isFavorite);
        },
        onToggleMenu: (): void => {
          this.menuVisible = !this.menuVisible;
        },
        onOpenAlbum: (): void => {
          this.menuVisible = false;
          this.onOpenAlbum(this.currentTrack());
        },
        onOpenArtist: (): void => this.openArtist(),
        onAddPlaylist: (): void => {
          this.menuVisible = false;
          this.playlistPickerVisible = true;
        },
        onTrackInfo: (): void => {
          this.menuVisible = false;
          this.trackInfoVisible = true;
        },
        onLyricsSettings: (): void => this.openLyricsSettings(),
        onToggle: (): void => {
          this.controller.toggle().catch((): void => {});
        },
        onNext: (): void => {
          this.controller.next().catch((): void => {});
        },
        onPrevious: (): void => {
          this.controller.previous().catch((): void => {});
        },
        onSeek: (positionMs: number): void => {
          this.controller.seekTo(positionMs).catch((): void => {});
        },
        onPanel: (panel: ExpandedPanel): void => {
          this.menuVisible = false;
          if (panel === ExpandedPanel.QUEUE) {
            this.controller.showQueue();
            return;
          }
          this.controller.hideQueue();
          this.panel = panel;
        },
        onRepeat: (): void => this.controller.cycleRepeatMode(),
        onQueueSelect: (index: number): void => {
          this.controller.playAt(index).catch((): void => {});
        },
        onQueueRemove: (index: number): void => {
          const closesPlayer: boolean = this.state.queue.length <= 1;
          this.controller.removeQueueItem(index).then((): void => {
            if (closesPlayer) {
              this.onBack();
            }
          }).catch((): void => {});
        },
        onClearQueue: (): void => {
          this.controller.clearQueue().then((): void => this.onBack()).catch((): void => {});
        },
        onRetryLyrics: (): void => {
          this.controller.retryLyrics().catch((): void => {});
        }
      })

      if (this.artistPickerVisible) {
        PlayerArtistPicker({
          artists: this.artistCandidates(),
          onClose: (): void => { this.artistPickerVisible = false; },
          onSelect: (artist: MusicArtist): void => {
            this.artistPickerVisible = false;
            this.onOpenArtist(artist);
          }
        })
        .zIndex(40)
      }

      if (this.playlistPickerVisible) {
        PlayerPlaylistPicker({
          playlists: this.playlists,
          onClose: (): void => { this.playlistPickerVisible = false; },
          onSelect: (playlist: MusicPlaylist): void => {
            this.playlistPickerVisible = false;
            this.onAddPlaylist(this.currentTrack(), playlist);
          }
        })
        .zIndex(41)
      }

      if (this.trackInfoVisible) {
        TrackInfoSheet({
          track: this.currentTrack(),
          onClose: (): void => { this.trackInfoVisible = false; }
        })
        .zIndex(42)
      }

      if (this.lyricsSettingsVisible) {
        LyricsSettingsSheet({
          preferences: this.preferences,
          supported: this.desktopLyricSupported,
          checking: this.checkingDesktopLyric,
          onClose: (): void => { this.lyricsSettingsVisible = false; },
          onToggle: (enabled: boolean): void => this.toggleDesktopLyrics(enabled)
        })
        .zIndex(43)
      }
    }
    .width('100%')
    .height('100%')
  }

  private syncQueuePanel(): void {
    if (this.state.queueVisible) {
      this.panel = ExpandedPanel.QUEUE;
    } else if (this.panel === ExpandedPanel.QUEUE) {
      this.panel = ExpandedPanel.PLAYER;
    }
  }

  private currentTrack(): MusicTrack {
    return this.state.currentTrack() ?? new MusicTrack();
  }

  private dismissLocalOverlays(): boolean {
    const visible = this.menuVisible || this.artistPickerVisible || this.playlistPickerVisible ||
      this.trackInfoVisible || this.lyricsSettingsVisible;
    this.menuVisible = false;
    this.artistPickerVisible = false;
    this.playlistPickerVisible = false;
    this.trackInfoVisible = false;
    this.lyricsSettingsVisible = false;
    return visible;
  }

  private artistCandidates(): MusicArtist[] {
    const track = this.currentTrack();
    if (track.artists.length > 0) {
      return track.artists;
    }
    return this.artists.filter((artist: MusicArtist): boolean =>
      artist.guid === track.artistGuid || artist.name === track.artistName);
  }

  private openArtist(): void {
    this.menuVisible = false;
    const candidates = this.artistCandidates();
    if (candidates.length === 0) {
      FnToast.show('未找到这首歌曲的歌手');
    } else if (candidates.length === 1) {
      this.onOpenArtist(candidates[0]);
    } else {
      this.artistPickerVisible = true;
    }
  }

  private loadPalette(): void {
    const track = this.currentTrack();
    const expectedKey = PlayerDynamicPalette.coverKey(track);
    this.palette = new PlayerPaletteState();
    PlayerDynamicPalette.load(track).then((palette?: PlayerPaletteState): void => {
      if (palette !== undefined && PlayerDynamicPalette.coverKey(this.currentTrack()) === expectedKey) {
        this.palette = palette;
      }
    }).catch((): void => {});
  }

  private showCastPicker(): void {
    this.controller.showCastPicker().catch((): void => {
      FnToast.show('当前设备暂时无法打开投播');
    });
  }

  private openLyricsSettings(): void {
    this.lyricsSettingsVisible = true;
    this.checkingDesktopLyric = true;
    this.controller.desktopLyricSupported().then((supported: boolean): void => {
      this.desktopLyricSupported = supported;
      if (!supported && this.preferences.desktopLyricsEnabled) {
        MusicPreferenceStore.setDesktopLyricsEnabled(false);
      }
    }).catch((): void => {
      this.desktopLyricSupported = false;
    }).finally((): void => {
      this.checkingDesktopLyric = false;
    });
  }

  private toggleDesktopLyrics(enabled: boolean): void {
    this.checkingDesktopLyric = true;
    this.controller.setDesktopLyricEnabled(enabled).then((): void => {
      MusicPreferenceStore.setDesktopLyricsEnabled(enabled);
      FnToast.show(enabled ? '已开启状态栏歌词' : '已关闭状态栏歌词');
    }).catch((error: Error): void => {
      const code = (error as BusinessError).code;
      MusicPreferenceStore.setDesktopLyricsEnabled(!enabled);
      FnToast.show(desktopLyricErrorMessage(code));
    }).finally((): void => {
      this.checkingDesktopLyric = false;
    });
  }
}
