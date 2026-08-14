import { describe, expect, it } from '@ohos/hypium';
import { MusicLyrics, MusicLyricsResult, MusicTrack } from '../main/ets/model/MusicModels';
import { LyricsController } from '../main/ets/playback/LyricsController';
import { PlaybackQueue } from '../main/ets/playback/PlaybackQueue';
import { PlaybackRepeatMode } from '../main/ets/playback/PlayerPresentationStore';

export default function playbackContractTest(): void {
  describe('PlaybackContract', () => {
    it('movesThroughQueueWithRepeatPolicy', 0, () => {
      const tracks: MusicTrack[] = [new MusicTrack('a'), new MusicTrack('b')];
      expect(PlaybackQueue.nextIndex(tracks, 0, PlaybackRepeatMode.SEQUENCE)).assertEqual(1);
      expect(PlaybackQueue.nextIndex(tracks, 1, PlaybackRepeatMode.SEQUENCE)).assertEqual(-1);
      expect(PlaybackQueue.nextIndex(tracks, 1, PlaybackRepeatMode.LIST)).assertEqual(0);
      expect(PlaybackQueue.nextIndex(tracks, 1, PlaybackRepeatMode.ONE, true)).assertEqual(1);
    });

    it('identifiesQueueEndBeforeApplyingListRepeat', 0, () => {
      const tracks: MusicTrack[] = [new MusicTrack('a'), new MusicTrack('b')];
      expect(PlaybackQueue.isAtEnd(tracks, 0)).assertFalse();
      expect(PlaybackQueue.isAtEnd(tracks, 1)).assertTrue();
      expect(PlaybackQueue.nextIndex(tracks, 1, PlaybackRepeatMode.LIST)).assertEqual(0);
    });

    it('insertsNextWithoutDuplicatingTrack', 0, () => {
      const tracks: MusicTrack[] = [new MusicTrack('a'), new MusicTrack('b'), new MusicTrack('c')];
      const values = PlaybackQueue.insertNext(tracks, 0, tracks[2]);
      expect(values.length).assertEqual(3);
      expect(values[1].guid).assertEqual('c');
    });

    it('parsesLrcTimestampsAndOffset', 0, () => {
      const lyrics = new MusicLyricsResult();
      const lyric = new MusicLyrics();
      lyric.isLrc = true;
      lyric.offsetMs = 100;
      lyric.content = '[offset:200]\n[00:01.50]第一句\n[00:03.250]第二句';
      lyrics.list = [lyric];
      const lines = new LyricsController().parse(lyrics, 10000);
      expect(lines.length).assertEqual(2);
      expect(lines[0].timeMs).assertEqual(1800);
      expect(lines[1].timeMs).assertEqual(3550);
    });
  });
}
