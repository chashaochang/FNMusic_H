import { LyricLine } from './PlayerPresentationStore';

function twoDigits(value: number): string {
  return `${Math.max(0, Math.floor(value))}`.padStart(2, '0');
}

function lrcTimestamp(timeMs: number): string {
  const safeTimeMs: number = Math.max(0, Math.floor(timeMs));
  const minutes: number = Math.floor(safeTimeMs / 60000);
  const seconds: number = Math.floor((safeTimeMs % 60000) / 1000);
  const hundredths: number = Math.floor((safeTimeMs % 1000) / 10);
  return `[${twoDigits(minutes)}:${twoDigits(seconds)}.${twoDigits(hundredths)}]`;
}

export function avSessionLyrics(lines: LyricLine[]): string {
  return lines.map((line: LyricLine): string => `${lrcTimestamp(line.timeMs)}${line.text}`).join('\n');
}

export function activeAvSessionLyricText(lines: LyricLine[], activeIndex: number): string {
  if (activeIndex < 0 || activeIndex >= lines.length) {
    return '';
  }
  return lines[activeIndex].text.trim();
}
