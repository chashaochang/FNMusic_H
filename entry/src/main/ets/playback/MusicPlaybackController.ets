import { common } from '@kit.AbilityKit';
import { audio } from '@kit.AudioKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { media } from '@kit.MediaKit';
import { AuthStore } from '../auth/AuthStore';
import { MusicPreferenceStore } from '../common/MusicPreferenceStore';
import { MusicTrack } from '../model/MusicModels';
import { FeiniuMusicApi } from '../network/FeiniuMusicApi';
import { AudioBackgroundTask } from './AudioBackgroundTask';
import { AvSessionBridge } from './AvSessionBridge';
import { LyricsController } from './LyricsController';
import { PlaybackQueue } from './PlaybackQueue';
import { PlaybackSessionStore, RestoredPlaybackSession } from './PlaybackSessionStore';
import {
  LyricLoadStatus,
  PlaybackRepeatMode,
  PlaybackStatus,
  PlayerPresentationState,
  connectPlayerPresentationState
} from './PlayerPresentationStore';

export type QueueExtension = () => Promise<MusicTrack[]>;

export class MusicPlaybackController {
  private static shared: MusicPlaybackController = new MusicPlaybackController();
  private readonly playbackState: PlayerPresentationState = connectPlayerPresentationState();
  private readonly lyricsController: LyricsController = new LyricsController();
  private readonly backgroundTask: AudioBackgroundTask = new AudioBackgroundTask();
  private readonly session: AvSessionBridge = new AvSessionBridge();
  private context?: common.UIAbilityContext;
  private api?: FeiniuMusicApi;
  private auth?: AuthStore;
  private player?: media.AVPlayer;
  private generation: number = 0;
  private demoTimer: number = -1;
  private sessionChain: Promise<void> = Promise.resolve();
  private initialized: boolean = false;
  private queueExtension?: QueueExtension;
  private queueExtensionInFlight?: Promise<MusicTrack[]>;
  private roamTrackSource?: QueueExtension;
  private lastPersistedPositionMs: number = -1;

  static instance(): MusicPlaybackController {
    return MusicPlaybackController.shared;
  }

  state(): PlayerPresentationState {
    return this.playbackState;
  }

  initialize(context: common.UIAbilityContext): void {
    this.context = context;
    this.backgroundTask.configure(context);
    PlaybackSessionStore.initialize(context);
    this.restorePlaybackSession();
    this.session.configure(context, {
      onPlay: (): void => { this.resume().catch((): void => {}); },
      onPause: (): void => { this.pause().catch((): void => {}); },
      onStop: (): void => { this.stop().catch((): void => {}); },
      onNext: (): void => { this.next().catch((): void => {}); },
      onPrevious: (): void => { this.previous().catch((): void => {}); },
      onSeek: (positionMs: number): void => { this.seekTo(positionMs).catch((): void => {}); },
      onQueueItem: (index: number): void => { this.playAt(index).catch((): void => {}); }
    });
    this.initialized = true;
    this.session.initialize()
      .then((): void => {
        this.syncSession();
        if (MusicPreferenceStore.state().desktopLyricsEnabled) {
          this.enqueueSessionLyrics()
            .then((): Promise<void> => this.session.setDesktopLyricEnabled(true))
            .catch((): void => {
              MusicPreferenceStore.setDesktopLyricsEnabled(false);
            });
        }
      })
      .catch((): void => {});
  }

  configureApi(api?: FeiniuMusicApi, auth?: AuthStore): void {
    this.api = api;
    this.auth = auth;
  }

  configureRoamTrackSource(source: QueueExtension): void {
    this.roamTrackSource = source;
  }

  refreshSystemSession(): void {
    this.syncSession();
  }

  async showCastPicker(): Promise<void> {
    await this.session.showCastPicker();
  }

  async desktopLyricSupported(): Promise<boolean> {
    return await this.session.desktopLyricSupported();
  }

  async setDesktopLyricEnabled(enabled: boolean): Promise<void> {
    if (enabled) {
      await this.enqueueSessionLyrics();
    }
    await this.session.setDesktopLyricEnabled(enabled);
  }

  release(): void {
    this.generation += 1;
    this.stopDemoTimer();
    this.backgroundTask.stop();
    const player: media.AVPlayer | undefined = this.player;
    this.player = undefined;
    if (player !== undefined) {
      this.releasePlayer(player).catch((): void => {});
    }
    PlaybackSessionStore.clear();
    this.playbackState.reset();
    this.clearQueueExtension();
    this.session.destroy().catch((): void => {});
  }

  async playQueue(tracks: MusicTrack[], startIndex: number = 0, extension?: QueueExtension): Promise<void> {
    const values: MusicTrack[] = tracks.slice();
    const index: number = PlaybackQueue.normalizedIndex(values, startIndex);
    if (index < 0) {
      return;
    }
    this.playbackState.roamMode = false;
    this.playbackState.queueVisible = false;
    this.queueExtension = extension;
    this.queueExtensionInFlight = undefined;
    this.playbackState.queue = values;
    await this.playAt(index);
  }

  async playRoam(tracks: MusicTrack[], startIndex: number = 0): Promise<void> {
    const index: number = PlaybackQueue.normalizedIndex(tracks, startIndex);
    if (index < 0) {
      return;
    }
    this.clearQueueExtension();
    this.playbackState.roamMode = true;
    this.playbackState.queueVisible = false;
    this.playbackState.queue = [tracks[index]];
    await this.playAt(0);
  }

  async playAt(index: number, initialPositionMs: number = 0): Promise<void> {
    if (index < 0 || index >= this.playbackState.queue.length) {
      return;
    }
    const track: MusicTrack = this.playbackState.queue[index];
    const generation: number = ++this.generation;
    this.stopDemoTimer();
    await this.replacePlayer(undefined);
    if (generation !== this.generation) {
      return;
    }
    this.playbackState.currentIndex = index;
    this.playbackState.durationMs = Math.max(0, track.durationMs);
    this.playbackState.positionMs = this.playbackState.durationMs > 0 ?
      Math.min(Math.max(0, initialPositionMs), this.playbackState.durationMs) : Math.max(0, initialPositionMs);
    this.playbackState.bufferedMs = 0;
    this.playbackState.status = PlaybackStatus.PREPARING;
    this.playbackState.errorMessage = '';
    this.playbackState.demoMode = this.isDemoTrack(track);
    this.playbackState.lyricLines = [];
    this.playbackState.activeLyricIndex = -1;
    this.playbackState.lyricStatus = MusicPreferenceStore.state().lyricsEnabled ?
      LyricLoadStatus.LOADING : LyricLoadStatus.IDLE;
    this.playbackState.lyricErrorMessage = '';
    if (!this.playbackState.demoMode) {
      this.backgroundTask.start();
    }
    this.syncSession();
    this.loadLyrics(track, generation).catch((): void => {});
    if (this.isDemoTrack(track)) {
      this.startDemoPlayback(generation);
      return;
    }
    await this.startRealPlayback(track, generation);
  }

  async playNext(track: MusicTrack): Promise<void> {
    if (this.playbackState.queue.length === 0 || this.playbackState.currentIndex < 0) {
      await this.playQueue([track], 0);
      return;
    }
    this.playbackState.roamMode = false;
    const currentGuid: string = this.playbackState.currentTrack()?.guid ?? '';
    const values: MusicTrack[] = PlaybackQueue.insertNext(
      this.playbackState.queue,
      this.playbackState.currentIndex,
      track
    );
    this.playbackState.queue = values;
    const nextCurrentIndex: number = values.findIndex((item: MusicTrack): boolean => item.guid === currentGuid);
    this.playbackState.currentIndex = nextCurrentIndex >= 0 ? nextCurrentIndex : this.playbackState.currentIndex;
    this.syncSession();
  }

  async appendToQueue(track: MusicTrack): Promise<void> {
    if (this.playbackState.queue.length === 0) {
      await this.playQueue([track], 0);
      return;
    }
    this.playbackState.roamMode = false;
    this.playbackState.queue = PlaybackQueue.append(this.playbackState.queue, track);
    this.syncSession();
  }

  async removeQueueItem(index: number): Promise<void> {
    if (index < 0 || index >= this.playbackState.queue.length) {
      return;
    }
    if (this.playbackState.queue.length === 1) {
      await this.clearQueue();
      return;
    }

    const values: MusicTrack[] = this.playbackState.queue.slice();
    values.splice(index, 1);
    if (index === this.playbackState.currentIndex) {
      const nextIndex: number = Math.min(index, values.length - 1);
      this.playbackState.queue = values;
      await this.playAt(nextIndex);
      return;
    }

    if (index < this.playbackState.currentIndex) {
      this.playbackState.currentIndex -= 1;
    }
    this.playbackState.queue = values;
    this.syncSession();
  }

  async toggle(): Promise<void> {
    if (this.playbackState.status === PlaybackStatus.PLAYING ||
      this.playbackState.status === PlaybackStatus.BUFFERING) {
      await this.pause();
      return;
    }
    await this.resume();
  }

  async retryCurrent(): Promise<void> {
    const index: number = this.playbackState.currentIndex;
    if (index >= 0 && index < this.playbackState.queue.length) {
      await this.playAt(index);
    }
  }

  async retryLyrics(): Promise<void> {
    const track: MusicTrack | undefined = this.playbackState.currentTrack();
    if (track === undefined) {
      return;
    }
    await this.loadLyrics(track, this.generation);
  }

  async next(): Promise<void> {
    if (this.playbackState.roamMode) {
      await this.advanceRoam();
      return;
    }
    if (this.shouldExtendQueueAtEnd() && await this.extendQueueAtEnd()) {
      await this.playAt(this.playbackState.currentIndex + 1);
      return;
    }
    const index: number = PlaybackQueue.nextIndex(
      this.playbackState.queue,
      this.playbackState.currentIndex,
      this.playbackState.repeatMode
    );
    if (index >= 0) {
      await this.playAt(index);
      return;
    }
  }

  async previous(): Promise<void> {
    if (this.playbackState.positionMs > 3000) {
      await this.seekTo(0);
      return;
    }
    const index: number = PlaybackQueue.previousIndex(
      this.playbackState.queue,
      this.playbackState.currentIndex,
      this.playbackState.repeatMode
    );
    if (index >= 0 && index !== this.playbackState.currentIndex) {
      await this.playAt(index);
    } else {
      await this.seekTo(0);
    }
  }

  async seekTo(positionMs: number): Promise<void> {
    const target: number = this.clampPosition(positionMs);
    this.playbackState.positionMs = target;
    this.updateActiveLyric();
    if (!this.playbackState.demoMode && this.player !== undefined && this.canSeek(this.player.state)) {
      this.player.seek(target);
    }
    this.syncSession();
  }

  async stop(): Promise<void> {
    this.stopDemoTimer();
    this.backgroundTask.stop();
    const player: media.AVPlayer | undefined = this.player;
    if (player !== undefined && this.canStop(player.state)) {
      await player.stop();
    }
    this.playbackState.status = PlaybackStatus.PAUSED;
    this.playbackState.positionMs = 0;
    this.updateActiveLyric();
    this.syncSession();
  }

  async close(): Promise<void> {
    this.generation += 1;
    this.stopDemoTimer();
    this.backgroundTask.stop();
    await this.replacePlayer(undefined);
    PlaybackSessionStore.clear();
    this.playbackState.reset();
    this.clearQueueExtension();
    await this.session.deactivate().catch((): void => {});
  }

  cycleRepeatMode(): void {
    this.playbackState.repeatMode = this.playbackState.repeatMode === PlaybackRepeatMode.SEQUENCE ?
      PlaybackRepeatMode.LIST : this.playbackState.repeatMode === PlaybackRepeatMode.LIST ?
        PlaybackRepeatMode.ONE : PlaybackRepeatMode.SEQUENCE;
    this.syncSession();
  }

  toggleQueue(): void {
    if (this.playbackState.queueVisible) {
      this.hideQueue();
    } else {
      this.showQueue();
    }
  }

  showQueue(): void {
    if (!this.playbackState.roamMode && this.playbackState.currentTrack() !== undefined) {
      this.playbackState.queueVisible = true;
    }
  }

  hideQueue(): void {
    this.playbackState.queueVisible = false;
  }

  dismissOverlay(): boolean {
    if (!this.playbackState.queueVisible) {
      return false;
    }
    this.hideQueue();
    return true;
  }

  async clearQueue(): Promise<void> {
    await this.close();
  }

  async resume(): Promise<void> {
    const track: MusicTrack | undefined = this.playbackState.currentTrack();
    if (track === undefined) {
      return;
    }
    if (this.playbackState.status === PlaybackStatus.ERROR) {
      await this.retryCurrent();
      return;
    }
    if (this.playbackState.status === PlaybackStatus.COMPLETED) {
      await this.seekTo(0);
    }
    if (this.playbackState.demoMode) {
      this.playbackState.status = PlaybackStatus.PLAYING;
      this.startDemoTimer(this.generation);
      this.syncSession();
      return;
    }
    this.backgroundTask.start();
    const player: media.AVPlayer | undefined = this.player;
    if (player === undefined) {
      await this.playAt(this.playbackState.currentIndex, this.playbackState.positionMs);
      return;
    }
    if (player !== undefined && this.canPlay(player.state)) {
      await player.play();
    }
  }

  async pause(): Promise<void> {
    if (this.playbackState.demoMode) {
      this.stopDemoTimer();
      this.backgroundTask.stop();
      this.playbackState.status = PlaybackStatus.PAUSED;
      this.syncSession();
      return;
    }
    const player: media.AVPlayer | undefined = this.player;
    if (player !== undefined && player.state === 'playing') {
      await player.pause();
    }
  }

  private async startRealPlayback(track: MusicTrack, generation: number): Promise<void> {
    if (this.api === undefined || this.api.currentBaseUrl().length === 0) {
      this.playbackState.demoMode = true;
      this.startDemoPlayback(generation);
      return;
    }
    try {
      const player: media.AVPlayer = await media.createAVPlayer();
      if (generation !== this.generation) {
        await player.release();
        return;
      }
      player.audioRendererInfo = {
        usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
        rendererFlags: 0
      };
      this.bindPlayer(player, generation);
      this.player = player;
      const source: media.MediaSource = media.createMediaSourceWithUrl(
        this.api.streamUrl(track.guid),
        this.api.playbackHeaders()
      );
      await player.setMediaSource(source);
    } catch (error) {
      if (generation === this.generation) {
        this.fail((error as Error).message || '这首歌曲暂时无法播放');
      }
    }
  }

  private bindPlayer(player: media.AVPlayer, generation: number): void {
    player.on('stateChange', (state: media.AVPlayerState): void => {
      if (!this.isCurrent(player, generation)) {
        return;
      }
      if (state === 'prepared') {
        this.playbackState.durationMs = Math.max(this.playbackState.durationMs, player.duration);
        this.playbackState.status = PlaybackStatus.PAUSED;
        if (this.playbackState.positionMs > 0) {
          player.seek(this.clampPosition(this.playbackState.positionMs));
        }
        player.play().catch((error: BusinessError): void => this.failCurrent(player, generation, error.message));
      } else if (state === 'initialized') {
        player.prepare().catch((error: BusinessError): void => this.failCurrent(player, generation, error.message));
      } else if (state === 'playing') {
        this.backgroundTask.start();
        this.playbackState.status = PlaybackStatus.PLAYING;
        this.reportPlay();
      } else if (state === 'paused') {
        this.backgroundTask.stop();
        this.playbackState.status = PlaybackStatus.PAUSED;
      } else if (state === 'completed') {
        this.playbackState.status = PlaybackStatus.COMPLETED;
        this.handleCompleted(generation).catch((error: Error): void => {
          if (this.isCurrent(player, generation)) {
            this.fail(error.message || '切换下一首失败');
          }
        });
      } else if (state === 'stopped') {
        this.backgroundTask.stop();
        this.playbackState.status = PlaybackStatus.PAUSED;
      } else if (state === 'error') {
        this.fail('系统播放器发生错误');
      }
      this.syncSession();
    });
    player.on('timeUpdate', (positionMs: number): void => {
      if (!this.isCurrent(player, generation)) {
        return;
      }
      this.playbackState.positionMs = this.clampPosition(positionMs);
      if (this.updateActiveLyric()) {
        this.syncSessionLyrics();
      }
      this.persistPositionIfNeeded();
    });
    player.on('durationUpdate', (durationMs: number): void => {
      if (this.isCurrent(player, generation)) {
        this.playbackState.durationMs = Math.max(0, durationMs);
      }
    });
    player.on('bufferingUpdate', (type: media.BufferingInfoType, value: number): void => {
      if (!this.isCurrent(player, generation)) {
        return;
      }
      if (type === media.BufferingInfoType.BUFFERING_START) {
        this.backgroundTask.start();
        this.playbackState.status = PlaybackStatus.BUFFERING;
      } else if (type === media.BufferingInfoType.BUFFERING_END && player.state === 'playing') {
        this.playbackState.status = PlaybackStatus.PLAYING;
      } else if (type === media.BufferingInfoType.CACHED_DURATION) {
        this.playbackState.bufferedMs = Math.max(this.playbackState.positionMs, value);
      }
      this.syncSession();
    });
    player.on('seekDone', (positionMs: number): void => {
      if (this.isCurrent(player, generation)) {
        this.playbackState.positionMs = this.clampPosition(positionMs);
        this.updateActiveLyric();
        this.syncSession();
      }
    });
    player.on('error', (error: BusinessError): void => {
      if (this.isCurrent(player, generation)) {
        this.fail(error.message || '播放失败');
      }
    });
  }

  private startDemoPlayback(generation: number): void {
    if (generation !== this.generation) {
      return;
    }
    this.backgroundTask.stop();
    this.playbackState.demoMode = true;
    this.playbackState.status = PlaybackStatus.PLAYING;
    this.startDemoTimer(generation);
    this.syncSession();
  }

  private startDemoTimer(generation: number): void {
    this.stopDemoTimer();
    this.demoTimer = setInterval((): void => {
      if (generation !== this.generation || this.playbackState.status !== PlaybackStatus.PLAYING) {
        return;
      }
      const durationMs: number = Math.max(1000, this.playbackState.durationMs);
      this.playbackState.positionMs = Math.min(durationMs, this.playbackState.positionMs + 250);
      this.playbackState.bufferedMs = durationMs;
      if (this.updateActiveLyric()) {
        this.syncSessionLyrics();
      }
      this.persistPositionIfNeeded();
      if (this.playbackState.positionMs >= durationMs) {
        this.stopDemoTimer();
        this.playbackState.status = PlaybackStatus.COMPLETED;
        this.handleCompleted(generation);
      }
    }, 250);
  }

  private stopDemoTimer(): void {
    if (this.demoTimer >= 0) {
      clearInterval(this.demoTimer);
      this.demoTimer = -1;
    }
  }

  private async loadLyrics(track: MusicTrack, generation: number): Promise<void> {
    if (!MusicPreferenceStore.state().lyricsEnabled) {
      this.playbackState.lyricLines = [];
      this.playbackState.activeLyricIndex = -1;
      this.playbackState.lyricStatus = LyricLoadStatus.IDLE;
      this.playbackState.lyricErrorMessage = '';
      this.syncSessionLyrics();
      return;
    }
    if (generation === this.generation) {
      this.playbackState.lyricStatus = LyricLoadStatus.LOADING;
      this.playbackState.lyricErrorMessage = '';
    }
    if (this.isDemoTrack(track) || this.api === undefined || this.auth === undefined) {
      this.playbackState.lyricLines = this.lyricsController.demo(track);
      this.playbackState.lyricStatus = LyricLoadStatus.READY;
      this.updateActiveLyric();
      this.syncSessionLyrics();
      return;
    }
    try {
      const result = await this.auth.withAutoReconnect(() => this.api!.lyrics(track.guid));
      if (generation === this.generation) {
        this.playbackState.lyricLines = this.lyricsController.parse(result, track.durationMs);
        this.playbackState.lyricStatus = this.playbackState.lyricLines.length > 0 ?
          LyricLoadStatus.READY : LyricLoadStatus.EMPTY;
        this.playbackState.lyricErrorMessage = '';
        this.updateActiveLyric();
        this.syncSessionLyrics();
      }
    } catch (error) {
      if (generation === this.generation) {
        this.playbackState.lyricLines = [];
        this.playbackState.activeLyricIndex = -1;
        this.playbackState.lyricStatus = LyricLoadStatus.ERROR;
        this.playbackState.lyricErrorMessage = (error as Error).message ?? '歌词读取失败';
        this.syncSessionLyrics();
      }
    }
  }

  private async handleCompleted(generation: number): Promise<void> {
    if (generation !== this.generation) {
      return;
    }
    if (this.playbackState.roamMode) {
      await this.advanceRoam();
      return;
    }
    if (!MusicPreferenceStore.state().autoContinueEnabled &&
      this.playbackState.repeatMode !== PlaybackRepeatMode.ONE) {
      this.backgroundTask.stop();
      this.syncSession();
      return;
    }
    if (this.playbackState.repeatMode !== PlaybackRepeatMode.ONE &&
      this.shouldExtendQueueAtEnd() && await this.extendQueueAtEnd()) {
      await this.playAt(this.playbackState.currentIndex + 1);
      return;
    }
    const index: number = PlaybackQueue.nextIndex(
      this.playbackState.queue,
      this.playbackState.currentIndex,
      this.playbackState.repeatMode,
      true
    );
    if (index >= 0) {
      await this.playAt(index);
    } else {
      this.backgroundTask.stop();
      this.syncSession();
    }
  }

  private shouldExtendQueueAtEnd(): boolean {
    return this.queueExtension !== undefined &&
      PlaybackQueue.isAtEnd(this.playbackState.queue, this.playbackState.currentIndex);
  }

  private async extendQueueAtEnd(): Promise<boolean> {
    if (this.queueExtension === undefined ||
      this.playbackState.currentIndex + 1 < this.playbackState.queue.length) {
      return false;
    }
    const currentGuid: string = this.playbackState.currentTrack()?.guid ?? '';
    const extension = this.queueExtension;
    const request: Promise<MusicTrack[]> = this.queueExtensionInFlight ?? extension();
    this.queueExtensionInFlight = request;
    try {
      const existingGuids: Set<string> = new Set<string>(
        this.playbackState.queue.map((track: MusicTrack): string => track.guid)
      );
      const additions: MusicTrack[] = (await request).filter((track: MusicTrack): boolean =>
        track.guid.length > 0 && !existingGuids.has(track.guid));
      if (additions.length === 0 || (this.playbackState.currentTrack()?.guid ?? '') !== currentGuid) {
        return false;
      }
      this.playbackState.queue = this.playbackState.queue.concat(additions);
      this.syncSession();
      return true;
    } finally {
      if (this.queueExtensionInFlight === request) {
        this.queueExtensionInFlight = undefined;
      }
    }
  }

  private clearQueueExtension(): void {
    this.queueExtension = undefined;
    this.queueExtensionInFlight = undefined;
  }

  private async advanceRoam(): Promise<void> {
    if (!this.playbackState.roamMode || this.roamTrackSource === undefined) {
      this.backgroundTask.stop();
      this.syncSession();
      return;
    }
    const currentGuid: string = this.playbackState.currentTrack()?.guid ?? '';
    const tracks: MusicTrack[] = await this.roamTrackSource();
    const next: MusicTrack | undefined = tracks.find((track: MusicTrack): boolean =>
      track.guid.length > 0 && track.guid !== currentGuid) ??
      tracks.find((track: MusicTrack): boolean => track.guid.length > 0);
    if (next === undefined) {
      this.backgroundTask.stop();
      this.syncSession();
      return;
    }
    this.playbackState.queue = [next];
    this.playbackState.currentIndex = 0;
    await this.playAt(0);
  }

  private async replacePlayer(next?: media.AVPlayer): Promise<void> {
    const previous: media.AVPlayer | undefined = this.player;
    this.player = next;
    if (previous !== undefined && previous !== next) {
      await this.releasePlayer(previous);
    }
  }

  private async releasePlayer(player: media.AVPlayer): Promise<void> {
    if (player.state === 'released') {
      return;
    }
    player.off('stateChange');
    player.off('timeUpdate');
    player.off('durationUpdate');
    player.off('bufferingUpdate');
    player.off('seekDone');
    player.off('error');
    await player.release();
  }

  private updateActiveLyric(): boolean {
    const previousIndex: number = this.playbackState.activeLyricIndex;
    const nextIndex: number = this.lyricsController.activeIndex(
      this.playbackState.lyricLines,
      this.playbackState.positionMs + 360
    );
    this.playbackState.activeLyricIndex = nextIndex;
    return previousIndex !== nextIndex;
  }

  private syncSession(): void {
    this.saveSession();
    if (!this.initialized) {
      return;
    }
    const track: MusicTrack | undefined = this.playbackState.currentTrack();
    const coverUrl: string = track !== undefined && track.coverId.length > 0 && this.api !== undefined ?
      this.api.coverUrl(track.coverId, 512, track.updatedAt) : '';
    const coverHeaders: Record<string, string> = coverUrl.length > 0 && this.api !== undefined ?
      this.api.playbackHeaders() : {};
    const expectedAssetId: string = track?.guid ?? '';
    this.sessionChain = this.sessionChain.then((): Promise<void> =>
      this.session.sync(this.playbackState, expectedAssetId, coverUrl, coverHeaders)).catch((): void => {});
  }

  private syncSessionLyrics(): void {
    this.enqueueSessionLyrics();
  }

  private enqueueSessionLyrics(): Promise<void> {
    if (!this.initialized) {
      return Promise.resolve();
    }
    const expectedAssetId: string = this.playbackState.currentTrack()?.guid ?? '';
    this.sessionChain = this.sessionChain.then((): Promise<void> =>
      this.session.syncLyrics(this.playbackState, expectedAssetId)).catch((): void => {});
    return this.sessionChain;
  }

  saveSession(): void {
    PlaybackSessionStore.save(this.playbackState);
    this.lastPersistedPositionMs = this.playbackState.positionMs;
  }

  private persistPositionIfNeeded(): void {
    if (this.lastPersistedPositionMs < 0 ||
      Math.abs(this.playbackState.positionMs - this.lastPersistedPositionMs) >= 5000) {
      this.saveSession();
    }
  }

  private restorePlaybackSession(): void {
    const restored: RestoredPlaybackSession | undefined = PlaybackSessionStore.restore();
    if (restored === undefined) {
      return;
    }
    this.playbackState.queue = restored.queue;
    this.playbackState.currentIndex = restored.currentIndex;
    this.playbackState.status = restored.status;
    this.playbackState.positionMs = restored.positionMs;
    this.playbackState.durationMs = restored.durationMs;
    this.playbackState.bufferedMs = 0;
    this.playbackState.repeatMode = restored.repeatMode;
    this.playbackState.lyricLines = [];
    this.playbackState.activeLyricIndex = -1;
    this.playbackState.lyricStatus = LyricLoadStatus.IDLE;
    this.playbackState.lyricErrorMessage = '';
    this.playbackState.errorMessage = '';
    this.playbackState.queueVisible = false;
    this.playbackState.demoMode = false;
    this.playbackState.roamMode = restored.roamMode;
    this.lastPersistedPositionMs = restored.positionMs;
  }

  private reportPlay(): void {
    const track: MusicTrack | undefined = this.playbackState.currentTrack();
    if (track === undefined || this.api === undefined || this.auth === undefined || this.isDemoTrack(track)) {
      return;
    }
    this.auth.withAutoReconnect(() => this.api!.reportTrackPlay(track.guid)).catch((): void => {});
  }

  private fail(message: string): void {
    this.stopDemoTimer();
    this.backgroundTask.stop();
    this.playbackState.status = PlaybackStatus.ERROR;
    this.playbackState.errorMessage = message.length > 0 ? message : '播放失败';
    this.syncSession();
  }

  private failCurrent(player: media.AVPlayer, generation: number, message: string): void {
    if (this.isCurrent(player, generation)) {
      this.fail(message);
    }
  }

  private isCurrent(player: media.AVPlayer, generation: number): boolean {
    return generation === this.generation && this.player === player;
  }

  private isDemoTrack(track: MusicTrack): boolean {
    return track.guid.startsWith('demo-') || this.api === undefined || this.api.currentBaseUrl().length === 0;
  }

  private clampPosition(positionMs: number): number {
    const value: number = Math.max(0, positionMs);
    return this.playbackState.durationMs > 0 ? Math.min(value, this.playbackState.durationMs) : value;
  }

  private canPlay(state: media.AVPlayerState): boolean {
    return state === 'prepared' || state === 'paused' || state === 'completed';
  }

  private canStop(state: media.AVPlayerState): boolean {
    return state === 'prepared' || state === 'playing' || state === 'paused' || state === 'completed';
  }

  private canSeek(state: media.AVPlayerState): boolean {
    return state === 'prepared' || state === 'playing' || state === 'paused' || state === 'completed';
  }
}
