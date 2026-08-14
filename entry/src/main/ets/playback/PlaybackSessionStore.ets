import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { MusicTrack, MusicTrackWire, musicTrackFromWire, musicTrackToWire } from '../model/MusicModels';
import { PlaybackRepeatMode, PlaybackStatus, PlayerPresentationState } from './PlayerPresentationStore';

const STORE_NAME: string = 'feiniu_music_playback_session';
const SESSION_KEY: string = 'playback_session_v1';
const SESSION_VERSION: number = 1;
const MAX_PERSISTED_TRACKS: number = 500;

interface PlaybackSessionWire {
  version: number;
  queue: MusicTrackWire[];
  currentIndex: number;
  positionMs: number;
  durationMs: number;
  repeatMode: string;
  status: string;
  roamMode?: boolean;
}

export class RestoredPlaybackSession {
  queue: MusicTrack[] = [];
  currentIndex: number = -1;
  positionMs: number = 0;
  durationMs: number = 0;
  repeatMode: PlaybackRepeatMode = PlaybackRepeatMode.SEQUENCE;
  status: PlaybackStatus = PlaybackStatus.PAUSED;
  roamMode: boolean = false;
}

export class PlaybackSessionStore {
  private static store?: preferences.Preferences;

  static initialize(context: common.UIAbilityContext): void {
    if (PlaybackSessionStore.store !== undefined) {
      return;
    }
    PlaybackSessionStore.store = preferences.getPreferencesSync(
      context.getApplicationContext(),
      { name: STORE_NAME }
    );
  }

  static restore(): RestoredPlaybackSession | undefined {
    const store = PlaybackSessionStore.store;
    if (store === undefined) {
      return undefined;
    }
    const raw = store.getSync(SESSION_KEY, '') as string;
    if (raw.length === 0) {
      return undefined;
    }
    try {
      const wire = JSON.parse(raw) as PlaybackSessionWire;
      if (wire.version !== SESSION_VERSION || !Array.isArray(wire.queue)) {
        return undefined;
      }
      const queue = wire.queue
        .map((track: MusicTrackWire): MusicTrack => musicTrackFromWire(track))
        .filter((track: MusicTrack): boolean => track.guid.length > 0);
      if (queue.length === 0) {
        return undefined;
      }
      const restored = new RestoredPlaybackSession();
      restored.queue = queue;
      restored.currentIndex = Math.min(queue.length - 1, Math.max(0, Number(wire.currentIndex) || 0));
      restored.positionMs = Math.max(0, Number(wire.positionMs) || 0);
      restored.durationMs = Math.max(queue[restored.currentIndex].durationMs, Number(wire.durationMs) || 0);
      restored.repeatMode = PlaybackSessionStore.repeatMode(wire.repeatMode);
      restored.status = wire.status === PlaybackStatus.COMPLETED ? PlaybackStatus.COMPLETED : PlaybackStatus.PAUSED;
      restored.roamMode = wire.roamMode === true;
      return restored;
    } catch (_) {
      return undefined;
    }
  }

  static save(state: PlayerPresentationState): void {
    const store = PlaybackSessionStore.store;
    if (store === undefined || state.currentTrack() === undefined) {
      return;
    }
    let start: number = 0;
    if (state.queue.length > MAX_PERSISTED_TRACKS) {
      start = Math.min(
        state.queue.length - MAX_PERSISTED_TRACKS,
        Math.max(0, state.currentIndex - Math.floor(MAX_PERSISTED_TRACKS / 2))
      );
    }
    const queue = state.queue.slice(start, start + MAX_PERSISTED_TRACKS);
    const wire: PlaybackSessionWire = {
      version: SESSION_VERSION,
      queue: queue.map((track: MusicTrack): MusicTrackWire => musicTrackToWire(track)),
      currentIndex: Math.max(0, state.currentIndex - start),
      positionMs: Math.max(0, state.positionMs),
      durationMs: Math.max(0, state.durationMs),
      repeatMode: state.repeatMode,
      status: state.status,
      roamMode: state.roamMode
    };
    try {
      store.putSync(SESSION_KEY, JSON.stringify(wire));
      store.flush().catch((): void => {});
    } catch (_) {
    }
  }

  static clear(): void {
    const store = PlaybackSessionStore.store;
    if (store === undefined) {
      return;
    }
    try {
      store.putSync(SESSION_KEY, '');
      store.flush().catch((): void => {});
    } catch (_) {
    }
  }

  private static repeatMode(value: string): PlaybackRepeatMode {
    if (value === PlaybackRepeatMode.LIST) {
      return PlaybackRepeatMode.LIST;
    }
    if (value === PlaybackRepeatMode.ONE) {
      return PlaybackRepeatMode.ONE;
    }
    return PlaybackRepeatMode.SEQUENCE;
  }
}
