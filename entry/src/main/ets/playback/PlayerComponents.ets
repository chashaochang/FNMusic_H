import { FnMusicUI } from '../design/FnMusicUI';
import { FnMusicMaterialRole, FnMusicMaterials } from '../design/FnMusicMaterials';
import { MusicTrack, formatDuration } from '../model/MusicModels';
import { MusicArtwork } from '../feature/common/MusicUiComponents';
import { MusicPlaybackController } from './MusicPlaybackController';
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

export const PLAYER_GEOMETRY_ID: string = 'feiniu_music_player_geometry';

enum ExpandedPanel {
  PLAYER = 'player',
  LYRICS = 'lyrics',
  QUEUE = 'queue'
}

const PLAYER_LYRIC_LINE_HEIGHT: number = 36;
const PLAYER_LYRIC_ACTIVE_TOP_OFFSET: number = 72;
const PLAYER_PAGE_SWIPE_DISTANCE: number = 180;
const PLAYER_PAGE_SWITCH_THRESHOLD: number = 22;

@ComponentV2
export struct MiniPlayerBar {
  @Param state: PlayerPresentationState = new PlayerPresentationState();
  @Param placement: PlayerHostPlacement = PlayerHostPlacement.HOME;
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
    return this.compact() ? FnMusicUI.compactPlayerHeight :
      (this.placement === PlayerHostPlacement.HOME ? FnMusicUI.miniPlayerHeight : FnMusicUI.floatingPlayerHeight);
  }

  build() {
    Row({ space: 8 }) {
      Row({ space: 8 }) {
          MusicArtwork({
            artworkSize: 36,
            radius: 18,
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
              .color($r('app.color.text_primary'))
          } else {
            SymbolGlyph(this.playing() ? $r('sys.symbol.pause_fill') : $r('sys.symbol.play_fill'))
              .fontSize(16)
              .fontColor([Color.Black])
          }
        }
        .width(32)
        .height(32)
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .backgroundColor('rgba(255,255,255,0.90)')
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
          Image($r('app.media.mini_player_roam'))
            .width(21)
            .height(21)
            .objectFit(ImageFit.Contain)
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
    .geometryTransition(PLAYER_GEOMETRY_ID)
  }
}

@ComponentV2
struct QueuePanel {
  @Param state: PlayerPresentationState = new PlayerPresentationState();
  @Param safeBottom: number = 0;
  @Event onSelect: (index: number) => void = (_: number): void => {};
  @Event onClear: () => void = (): void => {};

  build() {
    Column({ space: FnMusicUI.compactGap }) {
      Row() {
        Column({ space: 2 }) {
          Text('播放队列')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text(`${this.state.queue.length} 首歌曲`)
            .fontSize(FnMusicUI.supportingSize)
            .fontColor($r('app.color.text_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        Button('清空')
          .height(36)
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.danger'))
          .backgroundColor($r('app.color.transparent'))
          .enabled(this.state.queue.length > 0)
          .onClick((): void => this.onClear())
      }
      .width('100%')

      List({ space: 4 }) {
        Repeat<MusicTrack>(this.state.queue)
          .each((repeatItem: RepeatItem<MusicTrack>): void => {
            ListItem() {
              Row({ space: 10 }) {
                SymbolGlyph(repeatItem.index === this.state.currentIndex ?
                  $r('sys.symbol.speaker_wave_2_fill') : $r('sys.symbol.music'))
                  .width(26)
                  .fontSize(17)
                  .fontColor([repeatItem.index === this.state.currentIndex ?
                    $r('app.color.accent') : $r('app.color.text_secondary')])
                Column({ space: 2 }) {
                  Text(repeatItem.item.title)
                    .fontSize(FnMusicUI.bodySize)
                    .fontWeight(repeatItem.index === this.state.currentIndex ? FontWeight.Medium : FontWeight.Regular)
                    .fontColor(repeatItem.index === this.state.currentIndex ?
                      $r('app.color.accent') : $r('app.color.text_primary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(repeatItem.item.artistName)
                    .fontSize(FnMusicUI.supportingSize)
                    .fontColor($r('app.color.text_secondary'))
                    .maxLines(1)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                Text(formatDuration(repeatItem.item.durationMs))
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
              }
              .width('100%')
              .height(FnMusicUI.listRowHeight)
              .padding({ left: 8, right: 8 })
              .borderRadius(FnMusicUI.cardRadius)
              .backgroundColor(repeatItem.index === this.state.currentIndex ?
                $r('app.color.accent_soft') : $r('app.color.transparent'))
              .onClick((): void => this.onSelect(repeatItem.index))
            }
          })
          .key((item: MusicTrack): string => item.guid)
          .virtualScroll()
      }
      .height(300)
      .width('100%')
      .scrollBar(BarState.Off)
      .cachedCount(2)
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 14, bottom: Math.max(24, this.safeBottom + 16) })
    .borderRadius({ topLeft: FnMusicUI.cardRadius, topRight: FnMusicUI.cardRadius })
    .backgroundColor($r('app.color.surface_elevated'))
  }
}

@ComponentV2
export struct PlaybackQueueSheet {
  @Param state: PlayerPresentationState = new PlayerPresentationState();
  @Param safeBottom: number = 0;
  @Event onClose: () => void = (): void => {};
  @Event onSelect: (index: number) => void = (_: number): void => {};
  @Event onClear: () => void = (): void => {};

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
        onSelect: (index: number): void => this.onSelect(index),
        onClear: (): void => this.onClear()
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
struct PlayerLyricPage {
  @Param state: PlayerPresentationState = new PlayerPresentationState();
  @Param track: MusicTrack = new MusicTrack();
  @Param visible: boolean = false;
  @Event onSeek: (positionMs: number) => void = (_: number): void => {};
  @Event onRetry: () => void = (): void => {};
  private lyricScroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.scrollToActiveLine(false);
  }

  @Monitor('state.activeLyricIndex')
  onActiveLyricChanged(): void {
    this.scrollToActiveLine(true);
  }

  @Monitor('visible')
  onVisibleChanged(): void {
    this.scrollToActiveLine(true);
  }

  build() {
    Column({ space: 16 }) {
      Row({ space: 14 }) {
        MusicArtwork({
          artworkSize: 58,
          radius: 8,
          coverId: this.track.coverId,
          updatedAt: this.track.updatedAt
        })
        Column({ space: 4 }) {
          Text(this.track.title)
            .width('100%')
            .fontSize(20)
            .lineHeight(26)
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
            .fontSize(FnMusicUI.bodySize)
            .fontColor($r('app.color.text_secondary'))
          if (this.state.lyricStatus === LyricLoadStatus.ERROR) {
            Button('重新读取')
              .height(34)
              .padding({ left: 18, right: 18 })
              .fontSize(FnMusicUI.supportingSize)
              .fontColor($r('app.color.text_primary'))
              .backgroundColor($r('app.color.surface_secondary'))
              .borderRadius(17)
              .onClick((): void => this.onRetry())
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
                  .fontSize(repeatItem.index === this.state.activeLyricIndex ? 21 : 18)
                  .lineHeight(PLAYER_LYRIC_LINE_HEIGHT)
                  .fontWeight(repeatItem.index === this.state.activeLyricIndex ?
                    FontWeight.Bold : FontWeight.Medium)
                  .fontColor(repeatItem.index === this.state.activeLyricIndex ?
                    $r('app.color.text_primary') : $r('app.color.text_secondary'))
                  .opacity(repeatItem.index === this.state.activeLyricIndex ? 1 : 0.58)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .animation({ duration: 180, curve: Curve.EaseOut })
                  .onClick((): void => this.onSeek(repeatItem.item.timeMs))
              })
              .key((item: LyricLine): string => `${item.timeMs}:${item.text}`)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 4, right: 4, bottom: 18 })
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .onAreaChange((): void => this.scrollToActiveLine(false))
      }
    }
    .width('100%')
    .height('100%')
  }

  private scrollToActiveLine(animated: boolean): void {
    if (!this.visible || this.state.activeLyricIndex < 0) {
      return;
    }
    this.lyricScroller.scrollTo({
      xOffset: 0,
      yOffset: Math.max(0,
        this.state.activeLyricIndex * PLAYER_LYRIC_LINE_HEIGHT - PLAYER_LYRIC_ACTIVE_TOP_OFFSET),
      animation: animated ? { duration: 220, curve: Curve.EaseOut } : undefined
    });
  }
}

@ComponentV2
struct ExpandedPlayer {
  @Param state: PlayerPresentationState = new PlayerPresentationState();
  @Param panel: ExpandedPanel = ExpandedPanel.PLAYER;
  @Param safeTop: number = 0;
  @Param safeBottom: number = 0;
  @Event onCollapse: () => void = (): void => {};
  @Event onToggle: () => void = (): void => {};
  @Event onNext: () => void = (): void => {};
  @Event onPrevious: () => void = (): void => {};
  @Event onSeek: (positionMs: number) => void = (_: number): void => {};
  @Event onPanel: (panel: ExpandedPanel) => void = (_: ExpandedPanel): void => {};
  @Event onRepeat: () => void = (): void => {};
  @Event onQueueSelect: (index: number) => void = (_: number): void => {};
  @Event onClearQueue: () => void = (): void => {};
  @Event onRetryLyrics: () => void = (): void => {};
  @Local contentDragOffsetX: number = 0;

  private track(): MusicTrack {
    return this.state.currentTrack() ?? new MusicTrack();
  }

  private playing(): boolean {
    return this.state.status === PlaybackStatus.PLAYING || this.state.status === PlaybackStatus.BUFFERING ||
      this.state.status === PlaybackStatus.PREPARING;
  }

  private repeatSymbol(): Resource {
    return this.state.repeatMode === PlaybackRepeatMode.ONE ?
      $r('sys.symbol.repeat_1') : $r('sys.symbol.repeat');
  }

  private currentLyric(): string {
    if (this.state.activeLyricIndex < 0 || this.state.activeLyricIndex >= this.state.lyricLines.length) {
      return this.state.lyricLines.length > 0 ? this.state.lyricLines[0].text : '暂无歌词';
    }
    return this.state.lyricLines[this.state.activeLyricIndex].text;
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
      Column() {
        Row() {
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph($r('sys.symbol.chevron_down'))
              .fontSize(24)
              .fontColor([$r('app.color.text_primary')])
          }
          .width(FnMusicUI.tapTarget)
          .height(FnMusicUI.tapTarget)
          .backgroundColor($r('app.color.surface_secondary'))
          .accessibilityText('收起播放器')
          .onClick((): void => this.onCollapse())
          Blank()
          PlayerPageIndicator({ page: this.panel })
          Blank()
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph($r('sys.symbol.music_note_list'))
              .fontSize(21)
              .fontColor([$r('app.color.text_primary')])
          }
          .width(FnMusicUI.tapTarget)
          .height(FnMusicUI.tapTarget)
          .backgroundColor($r('app.color.surface_secondary'))
          .accessibilityText('播放队列')
          .onClick((): void => this.onPanel(ExpandedPanel.QUEUE))
        }
        .width('100%')

        Stack({ alignContent: Alignment.Center }) {
          MusicArtwork({
            artworkSize: 252,
            radius: 18,
            coverId: this.track().coverId,
            updatedAt: this.track().updatedAt
          })
            .opacity(1 - this.lyricPageProgress())
            .scale({ x: this.coverScale(), y: this.coverScale() })
            .translate({ x: this.coverTranslateX(), y: this.coverTranslateY() })
            .animation({ duration: this.contentDragOffsetX === 0 ? 220 : 0, curve: Curve.EaseOut })

          PlayerLyricPage({
            state: this.state,
            track: this.track(),
            visible: this.panel === ExpandedPanel.LYRICS,
            onSeek: (positionMs: number): void => this.onSeek(positionMs),
            onRetry: (): void => this.onRetryLyrics()
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

        Column({ space: 5 }) {
          Text(this.track().title)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.track().artistName.length > 0 ? this.track().artistName : this.track().albumName)
            .fontSize(FnMusicUI.bodySize)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
          Text(this.currentLyric())
            .fontSize(FnMusicUI.bodySize)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.accent'))
            .maxLines(2)
            .textAlign(TextAlign.Center)
            .lineHeight(22)
            .padding({ top: 8 })
            .onClick((): void => this.onPanel(this.panel === ExpandedPanel.LYRICS ?
              ExpandedPanel.PLAYER : ExpandedPanel.LYRICS))
          if (this.state.status === PlaybackStatus.ERROR) {
            Column({ space: 8 }) {
              Text(this.playbackErrorText())
                .fontSize(FnMusicUI.supportingSize)
                .fontColor($r('app.color.text_secondary'))
                .maxLines(2)
                .textAlign(TextAlign.Center)
              Button('重新播放')
                .height(40)
                .padding({ left: 18, right: 18 })
                .fontSize(FnMusicUI.supportingSize)
                .fontColor($r('app.color.accent_contrast'))
                .backgroundColor($r('app.color.accent'))
                .borderRadius(20)
                .onClick((): void => this.onToggle())
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 6 })
          }
        }
        .width('100%')

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
            Text(formatDuration(this.state.durationMs))
              .fontSize(11)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
        }
        .width('100%')

        Row({ space: 24 }) {
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph($r('sys.symbol.backward_end_fill'))
              .fontSize(25)
              .fontColor([$r('app.color.text_primary')])
          }
          .width(52)
          .height(52)
          .backgroundColor($r('app.color.surface_secondary'))
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
          .width(66)
          .height(66)
          .backgroundColor($r('app.color.accent'))
          .accessibilityText(this.playing() ? '暂停' : '播放')
          .onClick((): void => this.onToggle())

          Button({ type: ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph($r('sys.symbol.forward_end_fill'))
              .fontSize(25)
              .fontColor([$r('app.color.text_primary')])
          }
          .width(52)
          .height(52)
          .backgroundColor($r('app.color.surface_secondary'))
          .accessibilityText('下一首')
          .onClick((): void => this.onNext())
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        Row({ space: 34 }) {
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph(this.repeatSymbol())
              .fontSize(22)
              .fontColor([this.state.repeatMode === PlaybackRepeatMode.SEQUENCE ?
                $r('app.color.text_secondary') : $r('app.color.accent')])
          }
          .width(44)
          .height(44)
          .backgroundColor($r('app.color.transparent'))
          .accessibilityText('循环模式')
          .onClick((): void => this.onRepeat())
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph($r('sys.symbol.lyrics_square'))
              .fontSize(22)
              .fontColor([this.panel === ExpandedPanel.LYRICS ? $r('app.color.accent') : $r('app.color.text_secondary')])
          }
          .width(44)
          .height(44)
          .backgroundColor($r('app.color.transparent'))
          .accessibilityText('歌词')
          .onClick((): void => this.onPanel(this.panel === ExpandedPanel.LYRICS ?
            ExpandedPanel.PLAYER : ExpandedPanel.LYRICS))
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph($r('sys.symbol.music_note_list'))
              .fontSize(22)
              .fontColor([this.panel === ExpandedPanel.QUEUE ? $r('app.color.accent') : $r('app.color.text_secondary')])
          }
          .width(44)
          .height(44)
          .backgroundColor($r('app.color.transparent'))
          .accessibilityText('队列')
          .onClick((): void => this.onPanel(ExpandedPanel.QUEUE))
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height('100%')
      .padding({
        left: 24,
        right: 24,
        top: Math.max(20, this.safeTop + 8),
        bottom: Math.max(24, this.safeBottom + 16)
      })
      .linearGradient({
        angle: 180,
        colors: [
          [$r('app.color.page_player_background_start'), 0],
          [$r('app.color.page_player_background_end'), 1]
        ]
      })

      if (this.panel === ExpandedPanel.QUEUE) {
        PlaybackQueueSheet({
          state: this.state,
          safeBottom: this.safeBottom,
          onClose: (): void => this.onPanel(ExpandedPanel.PLAYER),
          onSelect: (index: number): void => this.onQueueSelect(index),
          onClear: (): void => this.onClearQueue()
        })
      }
    }
    .width('100%')
    .height('100%')
    .geometryTransition(PLAYER_GEOMETRY_ID)
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
  @Event onBack: () => void = (): void => {};
  @Local state: PlayerPresentationState = connectPlayerPresentationState();
  @Local panel: ExpandedPanel = ExpandedPanel.PLAYER;
  private controller: MusicPlaybackController = MusicPlaybackController.instance();

  aboutToAppear(): void {
    this.syncQueuePanel();
  }

  @Monitor('state.queueVisible')
  onQueueVisibilityChanged(): void {
    this.syncQueuePanel();
  }

  build() {
    ExpandedPlayer({
      state: this.state,
      panel: this.panel,
      safeTop: this.safeTop,
      safeBottom: this.safeBottom,
      onCollapse: (): void => this.onBack(),
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
      onClearQueue: (): void => {
        this.controller.clearQueue().then((): void => this.onBack()).catch((): void => {});
      },
      onRetryLyrics: (): void => {
        this.controller.retryLyrics().catch((): void => {});
      }
    })
  }

  private syncQueuePanel(): void {
    if (this.state.queueVisible) {
      this.panel = ExpandedPanel.QUEUE;
    } else if (this.panel === ExpandedPanel.QUEUE) {
      this.panel = ExpandedPanel.PLAYER;
    }
  }
}
