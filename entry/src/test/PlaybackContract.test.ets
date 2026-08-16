import { describe, expect, it } from '@ohos/hypium';
import { MusicLyrics, MusicLyricsResult, MusicTrack } from '../main/ets/model/MusicModels';
import {
  activeAvSessionLyricText,
  avSessionLyrics
} from '../main/ets/playback/AvSessionLyricPolicy';
import { LyricsController } from '../main/ets/playback/LyricsController';
import { PlaybackQueue } from '../main/ets/playback/PlaybackQueue';
import { LyricLine, PlaybackRepeatMode } from '../main/ets/playback/PlayerPresentationStore';
import {
  desktopLyricErrorMessage,
  nearestLyricIndex,
  playerFormatLabel,
  playerTrackInfoRows
} from '../main/ets/playback/PlayerUiPolicy';

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

    it('formatsPlayerMetadataWithoutInventingValues', 0, () => {
      const track = new MusicTrack('track-1', '测试歌曲', '测试歌手', '测试专辑', 125000);
      track.audioSpec.format = 'flac';
      track.audioSpec.codec = 'flac';
      track.audioSpec.bitDepth = 24;
      track.audioSpec.sampleRate = 96000;
      expect(playerFormatLabel(track)).assertEqual('FLAC');
      expect(playerTrackInfoRows(track).length >= 7).assertTrue();
      track.audioSpec.format = '';
      track.audioSpec.codec = 'dff';
      expect(playerFormatLabel(track)).assertEqual('DFF');
    });

    it('mapsDesktopLyricCapabilityErrors', 0, () => {
      expect(desktopLyricErrorMessage(6600111)).assertEqual('当前设备不支持系统歌词');
      expect(desktopLyricErrorMessage(6600110)).assertEqual('系统歌词尚未启用');
      expect(desktopLyricErrorMessage(1)).assertEqual('系统歌词设置失败');
    });

    it('formatsStandardAvSessionLyricsAndCurrentLine', 0, () => {
      const lines: LyricLine[] = [
        new LyricLine(-100, '序曲'),
        new LyricLine(61520, '  第二句  ')
      ];
      expect(avSessionLyrics(lines)).assertEqual('[00:00.00]序曲\n[01:01.52]  第二句  ');
      expect(activeAvSessionLyricText(lines, -1)).assertEqual('');
      expect(activeAvSessionLyricText(lines, 1)).assertEqual('第二句');
      expect(activeAvSessionLyricText(lines, 2)).assertEqual('');
    });

    it('keepsLyricPreviewIndexInsideBounds', 0, () => {
      const lines: LyricLine[] = [
        new LyricLine(0, '第一句'),
        new LyricLine(1000, '第二句'),
        new LyricLine(2000, '第三句')
      ];
      expect(nearestLyricIndex([], 0, 36, 72)).assertEqual(-1);
      expect(nearestLyricIndex(lines, -100, 36, 0)).assertEqual(0);
      expect(nearestLyricIndex(lines, 36, 36, 0)).assertEqual(1);
      expect(nearestLyricIndex(lines, 9999, 36, 0)).assertEqual(2);
    });
  });
}
