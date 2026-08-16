import { common } from '@kit.AbilityKit';
import { avSession } from '@kit.AVSessionKit';
import { image } from '@kit.ImageKit';
import { http } from '@kit.NetworkKit';
import { MusicTrack } from '../model/MusicModels';
import { activeAvSessionLyricText, avSessionLyrics } from './AvSessionLyricPolicy';
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
  private artworkUrl: string = '';
  private artwork?: image.PixelMap;
  private artworkEpoch: number = 0;
  private metadata?: avSession.AVMetadata;

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

  async sync(state: PlayerPresentationState, expectedAssetId: string = '', coverUrl: string = '',
    coverHeaders: Record<string, string> = {}): Promise<void> {
    await this.initialize();
    const session: avSession.AVSession | undefined = this.session;
    let track: MusicTrack | undefined = state.currentTrack();
    if (session === undefined || track === undefined || track.guid !== expectedAssetId) {
      return;
    }
    const artwork: image.PixelMap | undefined = await this.resolveArtwork(coverUrl, coverHeaders);
    track = state.currentTrack();
    if (track === undefined || track.guid !== expectedAssetId) {
      return;
    }
    const previous: MusicTrack | undefined = state.currentIndex > 0 ? state.queue[state.currentIndex - 1] : undefined;
    const next: MusicTrack | undefined = state.currentIndex + 1 < state.queue.length ?
      state.queue[state.currentIndex + 1] : undefined;
    const metadata: avSession.AVMetadata = this.createMetadata(state, track, artwork, previous, next);
    await session.setAVMetadata(metadata);
    this.metadata = metadata;
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

  async syncLyrics(state: PlayerPresentationState, expectedAssetId: string = ''): Promise<void> {
    await this.initialize();
    const session: avSession.AVSession | undefined = this.session;
    const track: MusicTrack | undefined = state.currentTrack();
    const metadata: avSession.AVMetadata | undefined = this.metadata;
    if (session === undefined || track === undefined || track.guid !== expectedAssetId ||
      metadata === undefined || metadata.assetId !== expectedAssetId) {
      return;
    }
    metadata.lyric = avSessionLyrics(state.lyricLines);
    metadata.singleLyricText = activeAvSessionLyricText(state.lyricLines, state.activeLyricIndex);
    await session.setAVMetadata(metadata);
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
    this.metadata = undefined;
    this.clearArtwork();
    this.active = false;
  }

  private createMetadata(state: PlayerPresentationState, track: MusicTrack,
    artwork: image.PixelMap | undefined, previous: MusicTrack | undefined,
    next: MusicTrack | undefined): avSession.AVMetadata {
    const metadata: avSession.AVMetadata = {
      assetId: track.guid,
      title: track.title,
      artist: track.artistName,
      album: track.albumName,
      duration: Math.max(0, state.durationMs),
      lyric: avSessionLyrics(state.lyricLines),
      singleLyricText: activeAvSessionLyricText(state.lyricLines, state.activeLyricIndex)
    };
    if (artwork !== undefined) {
      metadata.mediaImage = artwork;
    }
    if (previous !== undefined) {
      metadata.previousAssetId = previous.guid;
    }
    if (next !== undefined) {
      metadata.nextAssetId = next.guid;
    }
    return metadata;
  }

  private async resolveArtwork(url: string, headers: Record<string, string>): Promise<image.PixelMap | undefined> {
    const normalizedUrl: string = url.trim();
    if (normalizedUrl.length === 0) {
      return undefined;
    }
    if (this.artworkUrl === normalizedUrl && this.artwork !== undefined) {
      return this.artwork;
    }
    const epoch: number = this.artworkEpoch;
    const loaded: image.PixelMap | undefined = await this.fetchArtwork(normalizedUrl, headers);
    if (loaded === undefined) {
      return undefined;
    }
    if (epoch !== this.artworkEpoch) {
      await loaded.release().catch((): void => {});
      return undefined;
    }
    const previous: image.PixelMap | undefined = this.artwork;
    this.artworkUrl = normalizedUrl;
    this.artwork = loaded;
    if (previous !== undefined && previous !== loaded) {
      await previous.release().catch((): void => {});
    }
    return loaded;
  }

  private async fetchArtwork(url: string, headers: Record<string, string>): Promise<image.PixelMap | undefined> {
    const client = http.createHttp();
    let source: image.ImageSource | undefined = undefined;
    try {
      const response = await client.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        header: headers,
        connectTimeout: 10000,
        readTimeout: 15000,
        usingCache: true
      });
      if (response.responseCode < 200 || response.responseCode >= 300 || !(response.result instanceof ArrayBuffer) ||
        response.result.byteLength === 0) {
        return undefined;
      }
      source = image.createImageSource(response.result);
      return await source.createPixelMap({
        desiredSize: { width: 512, height: 512 }
      });
    } catch (_) {
      return undefined;
    } finally {
      if (source !== undefined) {
        await source.release().catch((): void => {});
      }
      client.destroy();
    }
  }

  private clearArtwork(): void {
    this.artworkEpoch += 1;
    const artwork: image.PixelMap | undefined = this.artwork;
    this.artwork = undefined;
    this.artworkUrl = '';
    artwork?.release().catch((): void => {});
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
