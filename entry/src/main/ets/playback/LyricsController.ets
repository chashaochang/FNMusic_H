import { MusicLyrics, MusicLyricsResult, MusicTrack } from '../model/MusicModels';
import { LyricLine } from './PlayerPresentationStore';

const LRC_TIMESTAMP: RegExp = /\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]/g;
const LRC_OFFSET: RegExp = /\[offset:([+-]?\d+)\]/i;

export class LyricsController {
  parse(result: MusicLyricsResult, durationMs: number): LyricLine[] {
    const lyric: MusicLyrics | undefined = this.preferred(result);
    if (lyric === undefined || lyric.content.trim().length === 0) {
      return [];
    }
    if (lyric.isLrc || LRC_TIMESTAMP.test(lyric.content)) {
      LRC_TIMESTAMP.lastIndex = 0;
      return this.parseLrc(lyric.content, lyric.offsetMs);
    }
    return this.distributePlainText(lyric.content, durationMs);
  }

  demo(track: MusicTrack): LyricLine[] {
    const lines: string[] = [
      track.title,
      '灯光沿着窗边慢慢醒来',
      '熟悉的旋律落进此刻',
      '让脚步跟着风继续向前',
      '山海之间 总有回声相伴',
      '把喜欢的歌留在身边'
    ];
    return lines.map((text: string, index: number): LyricLine => new LyricLine(index * 15000, text));
  }

  activeIndex(lines: LyricLine[], positionMs: number): number {
    let result: number = -1;
    for (let index: number = 0; index < lines.length; index += 1) {
      if (lines[index].timeMs > positionMs) {
        break;
      }
      result = index;
    }
    return result;
  }

  private preferred(result: MusicLyricsResult): MusicLyrics | undefined {
    if (result.list.length === 0) {
      return undefined;
    }
    if (result.preferred.length > 0) {
      const preferred: MusicLyrics | undefined = result.list.find((item: MusicLyrics): boolean =>
        item.guid === result.preferred);
      if (preferred !== undefined) {
        return preferred;
      }
    }
    return result.list[0];
  }

  private parseLrc(content: string, apiOffsetMs: number): LyricLine[] {
    const offsetMatch: RegExpMatchArray | null = content.match(LRC_OFFSET);
    const contentOffsetMs: number = offsetMatch === null ? 0 : Number(offsetMatch[1]);
    const offsetMs: number = apiOffsetMs + (Number.isFinite(contentOffsetMs) ? contentOffsetMs : 0);
    const lines: LyricLine[] = [];
    content.split(/\r?\n/).forEach((raw: string): void => {
      const timestamps: number[] = [];
      LRC_TIMESTAMP.lastIndex = 0;
      let match: RegExpExecArray | null = LRC_TIMESTAMP.exec(raw);
      while (match !== null) {
        const minutes: number = Number(match[1]);
        const seconds: number = Number(match[2]);
        const fraction: string = match[3] ?? '';
        const fractionMs: number = fraction.length === 0 ? 0 :
          fraction.length === 1 ? Number(fraction) * 100 :
            fraction.length === 2 ? Number(fraction) * 10 : Number(fraction.slice(0, 3));
        timestamps.push(minutes * 60000 + seconds * 1000 + fractionMs + offsetMs);
        match = LRC_TIMESTAMP.exec(raw);
      }
      const text: string = raw.replace(LRC_TIMESTAMP, '').replace(LRC_OFFSET, '').trim();
      if (text.length === 0) {
        return;
      }
      timestamps.forEach((timeMs: number): void => {
        lines.push(new LyricLine(Math.max(0, timeMs), text));
      });
    });
    return lines.sort((left: LyricLine, right: LyricLine): number => left.timeMs - right.timeMs);
  }

  private distributePlainText(content: string, durationMs: number): LyricLine[] {
    const texts: string[] = content.split(/\r?\n/).map((line: string): string => line.trim())
      .filter((line: string): boolean => line.length > 0);
    if (texts.length === 0) {
      return [];
    }
    const availableMs: number = Math.max(1000, durationMs > 0 ? durationMs : texts.length * 5000);
    const intervalMs: number = Math.max(1000, Math.floor(availableMs / texts.length));
    return texts.map((text: string, index: number): LyricLine => new LyricLine(index * intervalMs, text));
  }
}
