import { MusicTrack } from '../model/MusicModels';
import { PlaybackRepeatMode } from './PlayerPresentationStore';

export class PlaybackQueue {
  static normalizedIndex(tracks: MusicTrack[], index: number): number {
    if (tracks.length === 0) {
      return -1;
    }
    return Math.min(tracks.length - 1, Math.max(0, index));
  }

  static nextIndex(tracks: MusicTrack[], index: number, mode: PlaybackRepeatMode,
    completed: boolean = false): number {
    if (tracks.length === 0 || index < 0) {
      return -1;
    }
    if (completed && mode === PlaybackRepeatMode.ONE) {
      return index;
    }
    if (index + 1 < tracks.length) {
      return index + 1;
    }
    return mode === PlaybackRepeatMode.LIST ? 0 : -1;
  }

  static isAtEnd(tracks: MusicTrack[], index: number): boolean {
    return tracks.length > 0 && index >= 0 && index + 1 >= tracks.length;
  }

  static previousIndex(tracks: MusicTrack[], index: number, mode: PlaybackRepeatMode): number {
    if (tracks.length === 0 || index < 0) {
      return -1;
    }
    if (index > 0) {
      return index - 1;
    }
    return mode === PlaybackRepeatMode.LIST ? tracks.length - 1 : 0;
  }

  static insertNext(tracks: MusicTrack[], currentIndex: number, track: MusicTrack): MusicTrack[] {
    const values: MusicTrack[] = tracks.slice();
    const existingIndex: number = values.findIndex((item: MusicTrack): boolean => item.guid === track.guid);
    if (existingIndex >= 0) {
      values.splice(existingIndex, 1);
      if (existingIndex <= currentIndex) {
        currentIndex -= 1;
      }
    }
    values.splice(Math.min(values.length, Math.max(0, currentIndex + 1)), 0, track);
    return values;
  }

  static append(tracks: MusicTrack[], track: MusicTrack): MusicTrack[] {
    if (tracks.find((item: MusicTrack): boolean => item.guid === track.guid) !== undefined) {
      return tracks.slice();
    }
    return tracks.concat([track]);
  }
}
