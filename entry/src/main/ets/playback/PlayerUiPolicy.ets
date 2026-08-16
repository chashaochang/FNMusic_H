import { MusicTrack, formatDuration } from '../model/MusicModels';
import { LyricLine } from './PlayerPresentationStore';

export class PlayerInfoRow {
  label: string = '';
  value: string = '';

  constructor(label: string, value: string) {
    this.label = label;
    this.value = value;
  }
}

export function playerFormatLabel(track: MusicTrack): string {
  const format = track.audioSpec.format.trim();
  if (format.length > 0) {
    return format.toUpperCase();
  }
  return track.audioSpec.codec.trim().toUpperCase();
}

export function playerTrackInfoRows(track: MusicTrack): PlayerInfoRow[] {
  const rows: PlayerInfoRow[] = [];
  pushInfo(rows, '歌曲', track.title);
  pushInfo(rows, '歌手', track.artistName);
  pushInfo(rows, '专辑', track.albumName);
  if (track.year > 0) {
    rows.push(new PlayerInfoRow('年份', `${track.year}`));
  }
  if (track.trackNo > 0) {
    rows.push(new PlayerInfoRow('音轨', track.discNo > 0 ? `${track.discNo}-${track.trackNo}` : `${track.trackNo}`));
  }
  pushInfo(rows, '格式', playerFormatLabel(track));
  pushInfo(rows, '编码', track.audioSpec.codec.toUpperCase());
  if (track.audioSpec.bitDepth > 0) {
    rows.push(new PlayerInfoRow('位深', `${track.audioSpec.bitDepth} bit`));
  }
  if (track.audioSpec.sampleRate > 0) {
    rows.push(new PlayerInfoRow('采样率', `${trimDecimal(track.audioSpec.sampleRate / 1000)} kHz`));
  }
  if (track.audioSpec.channel > 0) {
    rows.push(new PlayerInfoRow('声道', `${track.audioSpec.channel}`));
  }
  if (track.audioSpec.bitrate > 0) {
    rows.push(new PlayerInfoRow('码率', `${Math.round(track.audioSpec.bitrate / 1000)} kbps`));
  }
  const duration = track.durationMs > 0 ? track.durationMs : track.audioSpec.durationMs;
  if (duration > 0) {
    rows.push(new PlayerInfoRow('时长', formatDuration(duration)));
  }
  if (track.audioSpec.size > 0) {
    rows.push(new PlayerInfoRow('大小', formatBytes(track.audioSpec.size)));
  }
  if (track.createdAt > 0) {
    rows.push(new PlayerInfoRow('添加日期', formatTimestamp(track.createdAt)));
  }
  pushInfo(rows, '文件位置', track.audioSpec.path);
  return rows;
}

export function desktopLyricErrorMessage(code: number): string {
  if (code === 6600111) {
    return '当前设备不支持系统歌词';
  }
  if (code === 6600110) {
    return '系统歌词尚未启用';
  }
  return '系统歌词设置失败';
}

export function nearestLyricIndex(lines: LyricLine[], contentOffset: number, lineHeight: number,
  viewportAnchor: number): number {
  if (lines.length === 0 || lineHeight <= 0) {
    return -1;
  }
  const raw = Math.round((Math.max(0, contentOffset) + Math.max(0, viewportAnchor)) / lineHeight);
  return Math.max(0, Math.min(lines.length - 1, raw));
}

function pushInfo(rows: PlayerInfoRow[], label: string, value: string): void {
  const normalized = value.trim();
  if (normalized.length > 0) {
    rows.push(new PlayerInfoRow(label, normalized));
  }
}

function trimDecimal(value: number): string {
  const rounded = Math.round(value * 10) / 10;
  return Number.isInteger(rounded) ? `${Math.round(rounded)}` : `${rounded}`;
}

function formatBytes(size: number): string {
  const units: string[] = ['B', 'KB', 'MB', 'GB'];
  let value = Math.max(0, size);
  let unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit += 1;
  }
  const digits = unit === 0 ? Math.round(value) : Math.round(value * 10) / 10;
  return `${digits} ${units[unit]}`;
}

function formatTimestamp(value: number): string {
  const timestampMs = value < 100000000000 ? value * 1000 : value;
  const date = new Date(timestampMs);
  const pad = (numberValue: number): string => numberValue < 10 ? `0${numberValue}` : `${numberValue}`;
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ` +
    `${pad(date.getHours())}:${pad(date.getMinutes())}`;
}
