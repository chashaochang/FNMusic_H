import { common } from '@kit.AbilityKit';
import { avSession } from '@kit.AVSessionKit';
import { MusicTrack } from '../model/MusicModels';
import { PlaybackRepeatMode, PlaybackStatus, PlayerPresentationState } from './PlayerPresentationStore';

export interface AvSessionCallbacks {
  onPlay: () => void;
  onPause: () => void;
  onStop: () => void;
  onNext: () => void;
  onPrevious: () => void;
  onSeek: (positionMs: number) => void;
  onQueueItem: (index: number) => void;
}

export class AvSessionBridge {
  private context?: common.UIAbilityContext;
  private session?: avSession.AVSession;
  private initializing?: Promise<void>;
  private callbacks?: AvSessionCallbacks;
  private active: boolean = false;

  private readonly playListener = (): void => this.callbacks?.onPlay();
  private readonly pauseListener = (): void => this.callbacks?.onPause();
  private readonly stopListener = (): void => this.callbacks?.onStop();
  private readonly nextListener = (): void => this.callbacks?.onNext();
  private readonly previousListener = (): void => this.callbacks?.onPrevious();
  private readonly seekListener = (positionMs: number): void => this.callbacks?.onSeek(positionMs);
  private readonly queueListener = (itemId: number): void => this.callbacks?.onQueueItem(itemId);

  configure(context: common.UIAbilityContext, callbacks: AvSessionCallbacks): void {
    this.context = context;
    this.callbacks = callbacks;
  }

  async initialize(): Promise<void> {
    if (this.session !== undefined) {
      return;
    }
    if (this.initializing !== undefined) {
      await this.initializing;
      return;
    }
    const task: Promise<void> = this.create();
    this.initializing = task;
    try {
      await task;
    } finally {
      if (this.initializing === task) {
        this.initializing = undefined;
      }
    }
  }

  async sync(state: PlayerPresentationState, coverUrl: string = ''): Promise<void> {
    await this.initialize();
    const session: avSession.AVSession | undefined = this.session;
    const track: MusicTrack | undefined = state.currentTrack();
    if (session === undefined || track === undefined) {
      return;
    }
    const metadata: avSession.AVMetadata = {
      assetId: track.guid,
      title: track.title,
      artist: track.artistName,
      album: track.albumName,
      duration: Math.max(0, state.durationMs),
      lyric: state.lyricLines.map((line): string => `[${Math.floor(line.timeMs / 60000)}:${
        `${Math.floor((line.timeMs % 60000) / 1000)}`.padStart(2, '0')}]${line.text}`).join('\n')
    };
    if (coverUrl.length > 0) {
      metadata.mediaImage = coverUrl;
    }
    const previous: MusicTrack | undefined = state.currentIndex > 0 ? state.queue[state.currentIndex - 1] : undefined;
    const next: MusicTrack | undefined = state.currentIndex + 1 < state.queue.length ?
      state.queue[state.currentIndex + 1] : undefined;
    if (previous !== undefined) {
      metadata.previousAssetId = previous.guid;
    }
    if (next !== undefined) {
      metadata.nextAssetId = next.guid;
    }
    await session.setAVMetadata(metadata);
    const items: avSession.AVQueueItem[] = state.queue.map((item: MusicTrack, index: number): avSession.AVQueueItem => ({
      itemId: index,
      description: {
        assetId: item.guid,
        title: item.title,
        subtitle: item.artistName,
        artist: item.artistName,
        albumTitle: item.albumName,
        duration: item.durationMs,
        mediaType: 'audio'
      }
    }));
    await session.setAVQueueItems(items);
    await session.setAVQueueTitle('飞牛音乐播放队列');
    await session.setAVPlaybackState({
      state: this.playbackState(state.status),
      position: {
        elapsedTime: Math.max(0, Math.min(state.positionMs, Math.max(state.positionMs, state.durationMs))),
        updateTime: Date.now()
      },
      bufferedTime: Math.max(0, state.bufferedMs),
      loopMode: this.loopMode(state.repeatMode),
      isFavorite: track.isFavorite,
      activeItemId: state.currentIndex,
      duration: Math.max(0, state.durationMs),
      speed: 1
    });
    if (!this.active) {
      await session.activate();
      this.active = true;
    }
  }

  async deactivate(): Promise<void> {
    if (this.session === undefined || !this.active) {
      return;
    }
    await this.session.deactivate();
    this.active = false;
  }

  async showCastPicker(): Promise<void> {
    if (this.context === undefined) {
      throw new Error('播放器尚未初始化');
    }
    const picker = new avSession.AVCastPickerHelper(this.context);
    await picker.select({ sessionType: 'audio' });
  }

  async desktopLyricSupported(): Promise<boolean> {
    return await avSession.isDesktopLyricSupported();
  }

  async setDesktopLyricEnabled(enabled: boolean): Promise<void> {
    await this.initialize();
    const session = this.session;
    if (session === undefined) {
      throw new Error('播放器会话尚未初始化');
    }
    const supported = await avSession.isDesktopLyricSupported();
    if (!supported) {
      throw new Error('当前设备不支持系统歌词');
    }
    await session.enableDesktopLyric(enabled);
    if (enabled) {
      await session.setDesktopLyricVisible(true);
    }
  }

  async destroy(): Promise<void> {
    if (this.initializing !== undefined) {
      try {
        await this.initializing;
      } catch (_) {
      }
    }
    const session: avSession.AVSession | undefined = this.session;
    if (session === undefined) {
      return;
    }
    this.removeListeners(session);
    if (this.active) {
      await session.deactivate().catch((): void => {});
    }
    await session.destroy();
    if (this.session === session) {
      this.session = undefined;
    }
    this.active = false;
  }

  private async create(): Promise<void> {
    if (this.context === undefined) {
      return;
    }
    const session: avSession.AVSession = await avSession.createAVSession(this.context, 'Feiniu Music', 'audio');
    try {
      this.registerListeners(session);
      await session.setBackgroundPlayMode(avSession.BackgroundPlayMode.ENABLE_BACKGROUND_PLAY);
      this.session = session;
    } catch (error) {
      await session.destroy();
      throw error as Error;
    }
  }

  private registerListeners(session: avSession.AVSession): void {
    session.on('play', this.playListener);
    session.on('pause', this.pauseListener);
    session.on('stop', this.stopListener);
    session.on('playNext', this.nextListener);
    session.on('playPrevious', this.previousListener);
    session.on('seek', this.seekListener);
    session.on('skipToQueueItem', this.queueListener);
  }

  private removeListeners(session: avSession.AVSession): void {
    session.off('play', this.playListener);
    session.off('pause', this.pauseListener);
    session.off('stop', this.stopListener);
    session.off('playNext', this.nextListener);
    session.off('playPrevious', this.previousListener);
    session.off('seek', this.seekListener);
    session.off('skipToQueueItem', this.queueListener);
  }

  private playbackState(status: PlaybackStatus): avSession.PlaybackState {
    switch (status) {
      case PlaybackStatus.PREPARING:
        return avSession.PlaybackState.PLAYBACK_STATE_PREPARE;
      case PlaybackStatus.PLAYING:
        return avSession.PlaybackState.PLAYBACK_STATE_PLAY;
      case PlaybackStatus.PAUSED:
        return avSession.PlaybackState.PLAYBACK_STATE_PAUSE;
      case PlaybackStatus.BUFFERING:
        return avSession.PlaybackState.PLAYBACK_STATE_BUFFERING;
      case PlaybackStatus.COMPLETED:
        return avSession.PlaybackState.PLAYBACK_STATE_COMPLETED;
      case PlaybackStatus.ERROR:
        return avSession.PlaybackState.PLAYBACK_STATE_ERROR;
      default:
        return avSession.PlaybackState.PLAYBACK_STATE_INITIAL;
    }
  }

  private loopMode(mode: PlaybackRepeatMode): avSession.LoopMode {
    if (mode === PlaybackRepeatMode.ONE) {
      return avSession.LoopMode.LOOP_MODE_SINGLE;
    }
    if (mode === PlaybackRepeatMode.LIST) {
      return avSession.LoopMode.LOOP_MODE_LIST;
    }
    return avSession.LoopMode.LOOP_MODE_SEQUENCE;
  }
}
