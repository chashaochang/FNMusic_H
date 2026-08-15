@ObservedV2
export class MusicArtist {
  @Trace guid: string = '';
  @Trace name: string = '';
  @Trace coverId: string = '';
  @Trace trackCount: number = 0;
  @Trace albumCount: number = 0;

  constructor(guid: string = '', name: string = '', coverId: string = '') {
    this.guid = guid;
    this.name = name;
    this.coverId = coverId;
  }
}

@ObservedV2
export class MusicAlbum {
  @Trace guid: string = '';
  @Trace name: string = '';
  @Trace coverId: string = '';
  @Trace year: number = 0;
  @Trace artistName: string = '';
  @Trace trackCount: number = 0;
  @Trace createdAt: number = 0;

  constructor(guid: string = '', name: string = '', coverId: string = '', year: number = 0,
    artistName: string = '') {
    this.guid = guid;
    this.name = name;
    this.coverId = coverId;
    this.year = year;
    this.artistName = artistName;
  }
}

@ObservedV2
export class MusicGenre {
  @Trace guid: string = '';
  @Trace name: string = '';
  @Trace trackCount: number = 0;
  @Trace coverId: string = '';
  @Trace createdAt: number = 0;
  @Trace updatedAt: number = 0;

  constructor(guid: string = '', name: string = '', trackCount: number = 0) {
    this.guid = guid;
    this.name = name;
    this.trackCount = trackCount;
  }
}

@ObservedV2
export class MusicTrack {
  @Trace guid: string = '';
  @Trace title: string = '';
  @Trace albumName: string = '';
  @Trace artistName: string = '';
  @Trace albumGuid: string = '';
  @Trace artistGuid: string = '';
  @Trace coverId: string = '';
  @Trace durationMs: number = 0;
  @Trace isFavorite: boolean = false;
  @Trace hasLyric: boolean = false;
  @Trace createdAt: number = 0;
  @Trace updatedAt: number = 0;
  @Trace year: number = 0;
  @Trace discNo: number = 0;
  @Trace trackNo: number = 0;
  @Trace isCue: boolean = false;
  @Trace isAudioFileDeleted: boolean = false;
  @Trace score: number = 0;
  @Trace isrc: string = '';
  album: MusicAlbum = new MusicAlbum();
  artists: MusicArtist[] = [];
  genres: MusicGenre[] = [];
  audioSpec: MusicAudioSpec = new MusicAudioSpec();

  constructor(guid: string = '', title: string = '', artistName: string = '', albumName: string = '',
    durationMs: number = 0) {
    this.guid = guid;
    this.title = title;
    this.artistName = artistName;
    this.albumName = albumName;
    this.durationMs = durationMs;
  }
}

@ObservedV2
export class MusicPlaylist {
  @Trace guid: string = '';
  @Trace name: string = '';
  @Trace coverId: string = '';
  @Trace trackCount: number = 0;
  @Trace description: string = '';
  @Trace createdAt: number = 0;
  @Trace updatedAt: number = 0;

  constructor(guid: string = '', name: string = '', trackCount: number = 0) {
    this.guid = guid;
    this.name = name;
    this.trackCount = trackCount;
  }
}

export class MusicUser {
  guid: string = '';
  name: string = '';
  role: string = '';
  userToken: string = '';
}

export class MusicAudioSpec {
  bitDepth: number = 0;
  sampleRate: number = 0;
  channel: number = 0;
  bitrate: number = 0;
  codec: string = '';
  format: string = '';
  durationMs: number = 0;
  size: number = 0;
  path: string = '';
}

export class MusicLyrics {
  guid: string = '';
  content: string = '';
  isLrc: boolean = false;
  offsetMs: number = 0;
}

export class MusicLyricsResult {
  list: MusicLyrics[] = [];
  preferred: string = '';
}

export class MusicRoamItem {
  roamId: string = '';
  track: MusicTrack = new MusicTrack();
}

export class MusicRoamResult {
  previous?: MusicRoamItem;
  current?: MusicRoamItem;
  next?: MusicRoamItem;
}

export class PageResult<T> {
  list: T[] = [];
  total: number = 0;
  sort: string = '';
}

export type NumericWireValue = number | string | null;
export type BooleanWireValue = boolean | number | string | null;

export interface MusicUserWire {
  name?: string;
  guid?: string;
  role?: string;
}

export interface LoginDataWire {
  userToken?: string;
  user?: MusicUserWire;
}

export interface MusicArtistWire {
  guid?: string;
  name?: string;
  coverId?: string;
  trackCount?: NumericWireValue;
  albumCount?: NumericWireValue;
}

export interface MusicAlbumWire {
  guid?: string;
  name?: string;
  coverId?: string;
  releaseDate?: NumericWireValue;
  artists?: MusicArtistWire[];
  trackCount?: NumericWireValue;
  createdAt?: NumericWireValue;
}

export interface MusicGenreWire {
  guid?: string;
  name?: string;
  coverId?: string;
  trackCount?: NumericWireValue;
  createdAt?: NumericWireValue;
  updatedAt?: NumericWireValue;
}

export interface MusicAudioSpecWire {
  bitDepth?: NumericWireValue;
  sampleRate?: NumericWireValue;
  channel?: NumericWireValue;
  bitrate?: NumericWireValue;
  codec?: string;
  format?: string;
  duration?: NumericWireValue;
  size?: NumericWireValue;
  path?: string;
}

export interface MusicTrackWire {
  guid?: string;
  title?: string;
  coverId?: string;
  year?: NumericWireValue;
  discNo?: NumericWireValue;
  trackNo?: NumericWireValue;
  duration?: NumericWireValue;
  isCue?: BooleanWireValue;
  createdAt?: NumericWireValue;
  updatedAt?: NumericWireValue;
  album?: MusicAlbumWire;
  artists?: MusicArtistWire[];
  isFavorite?: BooleanWireValue;
  hasLyric?: BooleanWireValue;
  audioSpec?: MusicAudioSpecWire;
  isrc?: string;
  genres?: MusicGenreWire[];
  audioFileDeleted?: BooleanWireValue;
  isAudioFileDeleted?: BooleanWireValue;
  audio_file_deleted?: BooleanWireValue;
  accessStatus?: NumericWireValue;
  score?: NumericWireValue;
}

export interface MusicPlaylistWire {
  guid?: string;
  name?: string;
  coverId?: string;
  trackCount?: NumericWireValue;
  createdAt?: NumericWireValue;
  updatedAt?: NumericWireValue;
  description?: string;
}

export interface MusicLyricsWire {
  guid?: string;
  content?: string;
  isLRC?: BooleanWireValue;
  offset?: NumericWireValue;
}

export interface MusicLyricsDataWire {
  list?: MusicLyricsWire[];
  preferred?: string;
}

export interface MusicRoamItemWire {
  roamId?: string;
  track?: MusicTrackWire;
}

export interface MusicRoamDataWire {
  previous?: MusicRoamItemWire;
  current?: MusicRoamItemWire;
  next?: MusicRoamItemWire;
}

export interface PageDataWire<T> {
  list?: T[];
  total?: NumericWireValue;
  sort?: string;
}

export interface TrackMetadataWire {
  track?: MusicTrackWire;
}

export enum LibrarySection {
  RECENTLY_ADDED = 'recently_added',
  ALBUMS = 'albums',
  ARTISTS = 'artists',
  GENRES = 'genres',
  LIBRARY = 'library'
}

export enum CollectionKind {
  ROAM = 'roam',
  FAVORITES = 'favorites',
  HISTORY = 'history',
  RECENTLY_ADDED = 'recently_added',
  LIBRARY = 'library',
  PLAYLIST = 'playlist',
  ALBUM = 'album',
  ARTIST = 'artist',
  GENRE = 'genre'
}

export function demoTracks(): MusicTrack[] {
  return [
    new MusicTrack('demo-1', '山海之间', '飞牛音乐', '此刻', 248000),
    new MusicTrack('demo-2', '夜航', '飞牛音乐', '漫游', 213000),
    new MusicTrack('demo-3', '晨光落在书架', '飞牛音乐', '最近添加', 196000),
    new MusicTrack('demo-4', '回到原野', '飞牛音乐', '收藏', 275000),
    new MusicTrack('demo-5', '微风经过', '飞牛音乐', '音乐库', 232000)
  ];
}

export function formatDuration(durationMs: number): string {
  const totalSeconds: number = Math.max(0, Math.floor(durationMs / 1000));
  const minutes: number = Math.floor(totalSeconds / 60);
  const seconds: number = totalSeconds % 60;
  return `${minutes}:${seconds < 10 ? '0' : ''}${seconds}`;
}

export function wireNumber(value: NumericWireValue | undefined, fallback: number = 0): number {
  if (typeof value === 'number') {
    return Number.isFinite(value) ? Math.floor(value) : fallback;
  }
  if (typeof value === 'string' && value.trim().length > 0) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? Math.floor(parsed) : fallback;
  }
  return fallback;
}

export function wireYear(value: NumericWireValue | undefined): number {
  if (typeof value === 'string') {
    const normalized = value.trim();
    if (normalized.length === 4 || (normalized.length > 4 &&
      (normalized.charAt(4) === '-' || normalized.charAt(4) === '/' || normalized.charAt(4) === '.'))) {
      const dateYear = Number(normalized.substring(0, 4));
      if (Number.isInteger(dateYear) && dateYear >= 1000 && dateYear <= 9999) {
        return dateYear;
      }
    }
  }

  const numericValue = wireNumber(value);
  if (numericValue >= 1000 && numericValue <= 9999) {
    return numericValue;
  }
  if (numericValue >= 1000000000) {
    const timestampMs = numericValue < 100000000000 ? numericValue * 1000 : numericValue;
    const timestampYear = new Date(timestampMs).getFullYear();
    if (Number.isInteger(timestampYear) && timestampYear >= 1000 && timestampYear <= 9999) {
      return timestampYear;
    }
  }
  return 0;
}

export function wireBoolean(value: BooleanWireValue | undefined): boolean {
  if (typeof value === 'boolean') {
    return value;
  }
  if (typeof value === 'number') {
    return value !== 0;
  }
  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase();
    return normalized === '1' || normalized === 'true' || normalized === 'yes';
  }
  return false;
}

export function musicUserFromWire(data: LoginDataWire): MusicUser {
  const value = new MusicUser();
  value.userToken = data.userToken ?? '';
  value.guid = data.user?.guid ?? '';
  value.name = data.user?.name ?? '';
  value.role = data.user?.role ?? '';
  return value;
}

export function musicArtistFromWire(data: MusicArtistWire): MusicArtist {
  const value = new MusicArtist(data.guid ?? '', data.name ?? '未知歌手', data.coverId ?? '');
  value.trackCount = wireNumber(data.trackCount);
  value.albumCount = wireNumber(data.albumCount);
  return value;
}

export function musicAlbumFromWire(data: MusicAlbumWire): MusicAlbum {
  const artistNames: string[] = [];
  (data.artists ?? []).forEach((artist: MusicArtistWire): void => {
    const name = (artist.name ?? '').trim();
    if (name.length > 0) {
      artistNames.push(name);
    }
  });
  const value = new MusicAlbum(
    data.guid ?? '',
    data.name ?? '未知专辑',
    data.coverId ?? '',
    wireYear(data.releaseDate),
    artistNames.join(' / ')
  );
  value.trackCount = wireNumber(data.trackCount);
  value.createdAt = wireNumber(data.createdAt);
  return value;
}

export function musicGenreFromWire(data: MusicGenreWire): MusicGenre {
  const value = new MusicGenre(data.guid ?? '', data.name ?? '未知风格', wireNumber(data.trackCount));
  value.coverId = data.coverId ?? '';
  value.createdAt = wireNumber(data.createdAt);
  value.updatedAt = wireNumber(data.updatedAt);
  return value;
}

export function musicAudioSpecFromWire(data: MusicAudioSpecWire | undefined): MusicAudioSpec {
  const value = new MusicAudioSpec();
  if (data === undefined) {
    return value;
  }
  value.bitDepth = wireNumber(data.bitDepth);
  value.sampleRate = wireNumber(data.sampleRate);
  value.channel = wireNumber(data.channel);
  value.bitrate = wireNumber(data.bitrate);
  value.codec = data.codec ?? '';
  value.format = data.format ?? '';
  value.durationMs = wireNumber(data.duration);
  value.size = wireNumber(data.size);
  value.path = data.path ?? '';
  return value;
}

export function musicTrackFromWire(data: MusicTrackWire): MusicTrack {
  const album = musicAlbumFromWire(data.album ?? {});
  const artists = (data.artists ?? []).map((item: MusicArtistWire) => musicArtistFromWire(item));
  const artistName = artists.map((item: MusicArtist) => item.name).join(' / ');
  const value = new MusicTrack(
    data.guid ?? '',
    data.title ?? '未知标题',
    artistName,
    album.name,
    wireNumber(data.duration)
  );
  value.album = album;
  value.artists = artists;
  value.genres = (data.genres ?? []).map((item: MusicGenreWire) => musicGenreFromWire(item));
  value.audioSpec = musicAudioSpecFromWire(data.audioSpec);
  value.albumGuid = album.guid;
  value.artistGuid = artists.length > 0 ? artists[0].guid : '';
  value.coverId = data.coverId ?? album.coverId;
  value.isFavorite = wireBoolean(data.isFavorite);
  value.hasLyric = wireBoolean(data.hasLyric);
  value.createdAt = wireNumber(data.createdAt);
  value.updatedAt = wireNumber(data.updatedAt);
  value.year = wireNumber(data.year);
  value.discNo = wireNumber(data.discNo);
  value.trackNo = wireNumber(data.trackNo);
  value.isCue = wireBoolean(data.isCue);
  value.isrc = data.isrc ?? '';
  value.score = Number(data.score ?? 0);
  value.isAudioFileDeleted = wireBoolean(data.audioFileDeleted) || wireBoolean(data.isAudioFileDeleted) ||
    wireBoolean(data.audio_file_deleted) || wireNumber(data.accessStatus) === 3;
  return value;
}

export function musicTrackToWire(value: MusicTrack): MusicTrackWire {
  const artists: MusicArtistWire[] = value.artists.length > 0 ?
    value.artists.map((artist: MusicArtist): MusicArtistWire => ({
      guid: artist.guid,
      name: artist.name,
      coverId: artist.coverId,
      trackCount: artist.trackCount,
      albumCount: artist.albumCount
    })) : (value.artistName.length > 0 ? [{ guid: value.artistGuid, name: value.artistName }] : []);
  return {
    guid: value.guid,
    title: value.title,
    coverId: value.coverId,
    year: value.year,
    discNo: value.discNo,
    trackNo: value.trackNo,
    duration: value.durationMs,
    isCue: value.isCue,
    createdAt: value.createdAt,
    updatedAt: value.updatedAt,
    album: {
      guid: value.album.guid.length > 0 ? value.album.guid : value.albumGuid,
      name: value.album.name.length > 0 ? value.album.name : value.albumName,
      coverId: value.album.coverId,
      releaseDate: value.album.year,
      trackCount: value.album.trackCount,
      createdAt: value.album.createdAt
    },
    artists: artists,
    isFavorite: value.isFavorite,
    hasLyric: value.hasLyric,
    audioSpec: {
      bitDepth: value.audioSpec.bitDepth,
      sampleRate: value.audioSpec.sampleRate,
      channel: value.audioSpec.channel,
      bitrate: value.audioSpec.bitrate,
      codec: value.audioSpec.codec,
      format: value.audioSpec.format,
      duration: value.audioSpec.durationMs,
      size: value.audioSpec.size,
      path: value.audioSpec.path
    },
    isrc: value.isrc,
    genres: value.genres.map((genre: MusicGenre): MusicGenreWire => ({
      guid: genre.guid,
      name: genre.name,
      coverId: genre.coverId,
      trackCount: genre.trackCount,
      createdAt: genre.createdAt,
      updatedAt: genre.updatedAt
    })),
    isAudioFileDeleted: value.isAudioFileDeleted,
    score: value.score
  };
}

export function musicPlaylistFromWire(data: MusicPlaylistWire): MusicPlaylist {
  const value = new MusicPlaylist(data.guid ?? '', data.name ?? '未知歌单', wireNumber(data.trackCount));
  value.coverId = data.coverId ?? '';
  value.createdAt = wireNumber(data.createdAt);
  value.updatedAt = wireNumber(data.updatedAt);
  value.description = data.description ?? '';
  return value;
}

export function musicLyricsFromWire(data: MusicLyricsDataWire): MusicLyricsResult {
  const value = new MusicLyricsResult();
  value.preferred = data.preferred ?? '';
  value.list = (data.list ?? []).map((item: MusicLyricsWire) => {
    const lyric = new MusicLyrics();
    lyric.guid = item.guid ?? '';
    lyric.content = item.content ?? '';
    lyric.isLrc = wireBoolean(item.isLRC);
    lyric.offsetMs = wireNumber(item.offset);
    return lyric;
  });
  return value;
}

export function musicRoamFromWire(data: MusicRoamDataWire): MusicRoamResult {
  const value = new MusicRoamResult();
  value.previous = musicRoamItemFromWire(data.previous);
  value.current = musicRoamItemFromWire(data.current);
  value.next = musicRoamItemFromWire(data.next);
  return value;
}

function musicRoamItemFromWire(data: MusicRoamItemWire | undefined): MusicRoamItem | undefined {
  if (data === undefined) {
    return undefined;
  }
  const value = new MusicRoamItem();
  value.roamId = data.roamId ?? '';
  value.track = musicTrackFromWire(data.track ?? {});
  return value;
}

export function pageFromWire<TWire, TModel>(data: PageDataWire<TWire>, mapper: (item: TWire) => TModel): PageResult<TModel> {
  const value = new PageResult<TModel>();
  value.list = (data.list ?? []).map((item: TWire) => mapper(item));
  value.total = wireNumber(data.total);
  value.sort = data.sort ?? '';
  return value;
}
