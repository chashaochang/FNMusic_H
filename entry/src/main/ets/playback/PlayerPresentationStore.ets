import { AppStorageV2 } from '@kit.ArkUI';
import { MusicTrack } from '../model/MusicModels';

export enum PlaybackStatus {
  IDLE = 'idle',
  PREPARING = 'preparing',
  PLAYING = 'playing',
  PAUSED = 'paused',
  BUFFERING = 'buffering',
  COMPLETED = 'completed',
  ERROR = 'error'
}

export enum PlaybackRepeatMode {
  SEQUENCE = 'sequence',
  LIST = 'list',
  ONE = 'one'
}

export enum LyricLoadStatus {
  IDLE = 'idle',
  LOADING = 'loading',
  READY = 'ready',
  EMPTY = 'empty',
  ERROR = 'error'
}

@ObservedV2
export class PlayerPresentationState {
  @Trace queue: MusicTrack[] = [];
  @Trace currentIndex: number = -1;
  @Trace status: PlaybackStatus = PlaybackStatus.IDLE;
  @Trace positionMs: number = 0;
  @Trace durationMs: number = 0;
  @Trace bufferedMs: number = 0;
  @Trace repeatMode: PlaybackRepeatMode = PlaybackRepeatMode.SEQUENCE;
  @Trace lyricLines: LyricLine[] = [];
  @Trace activeLyricIndex: number = -1;
  @Trace lyricStatus: LyricLoadStatus = LyricLoadStatus.IDLE;
  @Trace lyricErrorMessage: string = '';
  @Trace errorMessage: string = '';
  @Trace queueVisible: boolean = false;
  @Trace demoMode: boolean = false;

  currentTrack(): MusicTrack | undefined {
    if (this.currentIndex < 0 || this.currentIndex >= this.queue.length) {
      return undefined;
    }
    return this.queue[this.currentIndex];
  }

  reset(): void {
    this.queue = [];
    this.currentIndex = -1;
    this.status = PlaybackStatus.IDLE;
    this.positionMs = 0;
    this.durationMs = 0;
    this.bufferedMs = 0;
    this.lyricLines = [];
    this.activeLyricIndex = -1;
    this.lyricStatus = LyricLoadStatus.IDLE;
    this.lyricErrorMessage = '';
    this.errorMessage = '';
    this.queueVisible = false;
    this.demoMode = false;
  }
}

@ObservedV2
export class LyricLine {
  @Trace timeMs: number = 0;
  @Trace text: string = '';

  constructor(timeMs: number = 0, text: string = '') {
    this.timeMs = timeMs;
    this.text = text;
  }
}

export function connectPlayerPresentationState(): PlayerPresentationState {
  return AppStorageV2.connect(PlayerPresentationState, 'FeiniuMusicPlayerPresentation',
    (): PlayerPresentationState => new PlayerPresentationState())!;
}
