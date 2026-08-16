import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import {
  LoginDataWire,
  MusicAlbum,
  MusicAlbumWire,
  MusicArtist,
  MusicArtistWire,
  MusicGenre,
  MusicGenreWire,
  MusicLyricsDataWire,
  MusicLyricsResult,
  MusicPlaylist,
  MusicPlaylistWire,
  MusicRoamDataWire,
  MusicRoamResult,
  MusicTrack,
  MusicTrackWire,
  MusicUser,
  PageDataWire,
  PageResult,
  TrackMetadataWire,
  musicAlbumFromWire,
  musicArtistFromWire,
  musicGenreFromWire,
  musicLyricsFromWire,
  musicPlaylistFromWire,
  musicRoamFromWire,
  musicTrackFromWire,
  musicUserFromWire,
  pageFromWire
} from '../model/MusicModels';
import { ApiEnvelope, EmptyResponseData, parseApiEnvelope } from './ApiEnvelope';
import { ApiError, ApiErrorKind } from './ApiError';

export type QueryValue = string | number | boolean;

interface LoginRequestBody {
  username: string;
  password: string;
  deviceId: string;
}

interface PlatformNetworkError {
  code?: number;
  message?: string;
}

interface FavoriteBody {
  trackGUID: string;
}

interface TrackGuidsBody {
  trackGUIDs: string[];
}

interface PlaylistGuidBody {
  guid: string;
}

interface PlaylistTracksBody {
  guid: string;
  trackGUIDs: string[];
}

interface PlaylistCreateBody {
  name: string;
  coverId?: string;
}

interface PlaylistEditBody {
  guid: string;
  name?: string;
  coverId?: string;
}

interface TrackPlayPayload {
  trackGUID: string;
}

interface TrackPlayEvent {
  eventType: string;
  occurredAt: number;
  payload: TrackPlayPayload;
}

interface TrackPlayEventsBody {
  events: TrackPlayEvent[];
}

interface CoverIdDataWire {
  coverId?: string;
}

/** Successful password login. */
export class LoginResult {
  token: string = '';
  user: MusicUser = new MusicUser();
}

export class MusicApiConfiguration {
  baseUrl: string = '';
  token: string = '';
  accessCode: string = '';
  relayMode: boolean = false;
  connectTimeoutMs: number = 10000;
  readTimeoutMs: number = 20000;
  maxRedirects: number = 5;
}

/** NetworkKit implementation of the documented Feiniu Music HTTP contract. */
export class FeiniuMusicApi {
  private readonly configuration: MusicApiConfiguration;
  private readonly encoder: util.TextEncoder = new util.TextEncoder();
  private readonly base64: util.Base64Helper = new util.Base64Helper();

  constructor(configuration: MusicApiConfiguration = new MusicApiConfiguration()) {
    this.configuration = configuration;
  }

  setEndpoint(baseUrl: string, relayMode: boolean): void {
    this.configuration.baseUrl = FeiniuMusicApi.normalizeBaseUrl(baseUrl);
    this.configuration.relayMode = relayMode;
  }

  setToken(token: string): void {
    this.configuration.token = token.trim();
  }

  setAccessCode(accessCode: string): void {
    this.configuration.accessCode = accessCode;
  }

  currentBaseUrl(): string {
    return this.configuration.baseUrl;
  }

  currentToken(): string {
    return this.configuration.token;
  }

  /** Headers used before a music-token exists. Relay routing still requires its mode cookie. */
  loginHeaders(): Record<string, string> {
    return this.headers(false);
  }

  async login(username: string, password: string, deviceId: string): Promise<LoginResult> {
    const body: LoginRequestBody = {
      username: username.trim(),
      password: FeiniuMusicApi.sha256Hex(password),
      deviceId: deviceId
    };
    const envelope = await this.request<LoginDataWire>('POST', '/user/password-login', undefined, body, false, true);
    const user = musicUserFromWire(envelope.data as LoginDataWire);
    if (user.userToken.trim().length === 0) {
      throw new ApiError(ApiErrorKind.PARSE, '登录成功响应缺少 userToken');
    }
    const result = new LoginResult();
    result.token = user.userToken;
    result.user = user;
    return result;
  }

  async verifySession(): Promise<void> {
    await this.tracks(1, 1);
  }

  async tracks(page: number = 1, size: number = 50, sort?: string): Promise<PageResult<MusicTrack>> {
    return this.pageRequest<MusicTrackWire, MusicTrack>('/track/list', this.pageQuery(page, size, sort), musicTrackFromWire);
  }

  async albums(page: number = 1, size: number = 50, sort?: string): Promise<PageResult<MusicAlbum>> {
    return this.pageRequest<MusicAlbumWire, MusicAlbum>('/album/list', this.pageQuery(page, size, sort), musicAlbumFromWire);
  }

  async albumTracks(albumGuid: string, page: number = 1, size: number = 120): Promise<PageResult<MusicTrack>> {
    const query = this.detailPageQuery('albumGUID', albumGuid, page, size);
    return this.pageRequest<MusicTrackWire, MusicTrack>('/track/album-detail/list', query, musicTrackFromWire);
  }

  async artists(page: number = 1, size: number = 200): Promise<PageResult<MusicArtist>> {
    return this.pageRequest<MusicArtistWire, MusicArtist>('/artist/list', this.pageQuery(page, size), musicArtistFromWire);
  }

  async artistTracks(artistGuid: string, page: number = 1, size: number = 120,
    sort?: string): Promise<PageResult<MusicTrack>> {
    const query = this.detailPageQuery('artistGUID', artistGuid, page, size, sort);
    return this.pageRequest<MusicTrackWire, MusicTrack>('/track/artist-detail/list', query, musicTrackFromWire);
  }

  async genres(page: number = 1, size: number = 50, sort?: string): Promise<PageResult<MusicGenre>> {
    return this.pageRequest<MusicGenreWire, MusicGenre>('/genre/list', this.pageQuery(page, size, sort), musicGenreFromWire);
  }

  async genreTracks(genreGuid: string, page: number = 1, size: number = 120,
    sort?: string): Promise<PageResult<MusicTrack>> {
    const query = this.detailPageQuery('genreGUID', genreGuid, page, size, sort);
    return this.pageRequest<MusicTrackWire, MusicTrack>('/track/genre-detail/list', query, musicTrackFromWire);
  }

  async trackMetadata(guid: string): Promise<MusicTrack> {
    const envelope = await this.request<TrackMetadataWire>('GET', '/track/metadata', this.singleQuery('guid', guid));
    const data = envelope.data as TrackMetadataWire;
    if (data.track === undefined) {
      return musicTrackFromWire(data as MusicTrackWire);
    }
    return musicTrackFromWire(data.track);
  }

  async searchTracks(query: string, page: number = 1, size: number = 50): Promise<PageResult<MusicTrack>> {
    return this.pageRequest<MusicTrackWire, MusicTrack>('/search/track', this.searchQuery(query, page, size),
      musicTrackFromWire);
  }

  async searchAlbums(query: string, page: number = 1, size: number = 24): Promise<PageResult<MusicAlbum>> {
    return this.pageRequest<MusicAlbumWire, MusicAlbum>('/search/album', this.searchQuery(query, page, size),
      musicAlbumFromWire);
  }

  async searchArtists(query: string, page: number = 1, size: number = 24): Promise<PageResult<MusicArtist>> {
    return this.pageRequest<MusicArtistWire, MusicArtist>('/search/artist', this.searchQuery(query, page, size),
      musicArtistFromWire);
  }

  async favoriteTracks(page: number = 1, size: number = -1, sort?: string): Promise<PageResult<MusicTrack>> {
    return this.pageRequest<MusicTrackWire, MusicTrack>('/favorite-track/list', this.pageQuery(page, size, sort),
      musicTrackFromWire);
  }

  async setFavorite(trackGuid: string, favorite: boolean): Promise<void> {
    const body: FavoriteBody = { trackGUID: trackGuid };
    await this.request<EmptyResponseData>('POST', favorite ? '/favorite-track/create' : '/favorite-track/delete',
      undefined, body, true, false);
  }

  async playHistory(page: number = 1, size: number = 100): Promise<PageResult<MusicTrack>> {
    return this.pageRequest<MusicTrackWire, MusicTrack>('/play-history/list', this.pageQuery(page, size),
      musicTrackFromWire);
  }

  async deletePlayHistory(trackGuids: string[]): Promise<void> {
    if (trackGuids.length === 0) {
      return;
    }
    const body: TrackGuidsBody = { trackGUIDs: trackGuids };
    await this.request<EmptyResponseData>('POST', '/play-history/delete', undefined, body, true, false);
  }

  async roamStart(deviceId: string): Promise<MusicRoamResult> {
    const envelope = await this.request<MusicRoamDataWire>('GET', '/track/roam-start',
      this.singleQuery('deviceId', deviceId));
    const result = musicRoamFromWire(envelope.data as MusicRoamDataWire);
    if (result.current === undefined) {
      throw new ApiError(ApiErrorKind.PARSE, '漫游响应缺少当前歌曲');
    }
    return result;
  }

  async roamNext(deviceId: string, relativeRoamId: string): Promise<MusicRoamResult> {
    let query = this.singleQuery('deviceId', deviceId);
    query = this.appendQuery(query, 'relativeRoamId', relativeRoamId);
    const envelope = await this.request<MusicRoamDataWire>('GET', '/track/roam-next', query);
    return musicRoamFromWire(envelope.data as MusicRoamDataWire);
  }

  async playlists(page: number = 1, size: number = 50): Promise<PageResult<MusicPlaylist>> {
    return this.pageRequest<MusicPlaylistWire, MusicPlaylist>('/playlist/list', this.pageQuery(page, size),
      musicPlaylistFromWire);
  }

  async playlistTracks(playlistGuid: string, page: number = 1, size: number = 300): Promise<PageResult<MusicTrack>> {
    const query = this.detailPageQuery('playlistGUID', playlistGuid, page, size);
    return this.pageRequest<MusicTrackWire, MusicTrack>('/track/playlist-detail/list', query, musicTrackFromWire);
  }

  async createPlaylist(name: string, coverId?: string): Promise<MusicPlaylist> {
    const body: PlaylistCreateBody = { name: name.trim() };
    if (coverId !== undefined && coverId.trim().length > 0) {
      body.coverId = coverId;
    }
    const envelope = await this.request<MusicPlaylistWire>('POST', '/playlist/create', undefined, body);
    return musicPlaylistFromWire(envelope.data as MusicPlaylistWire);
  }

  async editPlaylist(guid: string, name?: string, coverId?: string): Promise<void> {
    const body: PlaylistEditBody = { guid: guid };
    if (name !== undefined) {
      body.name = name.trim();
    }
    if (coverId !== undefined) {
      body.coverId = coverId;
    }
    await this.request<EmptyResponseData>('POST', '/playlist/edit', undefined, body, true, false);
  }

  async deletePlaylist(guid: string): Promise<void> {
    const body: PlaylistGuidBody = { guid: guid };
    await this.request<EmptyResponseData>('POST', '/playlist/delete', undefined, body, true, false);
  }

  async addTracksToPlaylist(guid: string, trackGuids: string[]): Promise<void> {
    const body: PlaylistTracksBody = { guid: guid, trackGUIDs: trackGuids };
    await this.request<EmptyResponseData>('POST', '/playlist/add-track', undefined, body, true, false);
  }

  async removeTracksFromPlaylist(guid: string, trackGuids: string[]): Promise<void> {
    const body: PlaylistTracksBody = { guid: guid, trackGUIDs: trackGuids };
    await this.request<EmptyResponseData>('POST', '/playlist/remove-track', undefined, body, true, false);
  }

  async lyrics(trackGuid: string): Promise<MusicLyricsResult> {
    const envelope = await this.request<MusicLyricsDataWire>('GET', '/lyric/list',
      this.singleQuery('trackGUID', trackGuid));
    const data = envelope.data as MusicLyricsDataWire;
    if (data.list === undefined) {
      throw new ApiError(ApiErrorKind.PARSE, '歌词响应缺少 list 字段');
    }
    return musicLyricsFromWire(data);
  }

  streamUrl(trackGuid: string): string {
    return this.mediaUrl('/track/stream', this.singleQuery('guid', trackGuid));
  }

  coverUrl(coverId: string, size: number = 512, updatedAt?: number): string {
    const defaultCoverIndex = FeiniuMusicApi.playlistDefaultCoverIndex(coverId.trim());
    if (defaultCoverIndex > 0) {
      return `${this.configuration.baseUrl}/music/static/assets/img/playlist-covers/${defaultCoverIndex}.png`;
    }
    let query = this.singleQuery('coverId', coverId);
    query = this.appendQuery(query, 'size', size);
    if (updatedAt !== undefined && updatedAt > 0) {
      query = this.appendQuery(query, 't', updatedAt);
    }
    return this.mediaUrl('/static/cover', query);
  }

  playbackHeaders(rangeStart?: number, rangeEnd?: number): Record<string, string> {
    const headers = this.headers(true);
    if (rangeStart !== undefined && rangeStart >= 0) {
      headers.Range = rangeEnd !== undefined && rangeEnd >= rangeStart ?
        `bytes=${rangeStart}-${rangeEnd}` : `bytes=${rangeStart}-`;
    }
    return headers;
  }

  async reportTrackPlay(trackGuid: string): Promise<void> {
    const event: TrackPlayEvent = {
      eventType: 'track_play',
      occurredAt: Date.now(),
      payload: { trackGUID: trackGuid }
    };
    const body: TrackPlayEventsBody = { events: [event] };
    await this.request<EmptyResponseData>('POST', '/event/report', undefined, body, true, false);
  }

  async uploadPlaylistCover(bytes: Uint8Array, fileName: string = 'cover.png',
    mimeType: string = 'image/png'): Promise<string> {
    const boundary = `----FeiniuMusic${Date.now()}`;
    const prefix = this.encoder.encodeInto(
      `--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="${fileName}"\r\n` +
      `Content-Type: ${mimeType}\r\n\r\n`
    );
    const suffix = this.encoder.encodeInto(`\r\n--${boundary}--\r\n`);
    const body = new Uint8Array(prefix.length + bytes.length + suffix.length);
    body.set(prefix, 0);
    body.set(bytes, prefix.length);
    body.set(suffix, prefix.length + bytes.length);
    const envelope = await this.request<CoverIdDataWire>('POST', '/static/cover/playlist', undefined,
      body.buffer, true, true, `multipart/form-data; boundary=${boundary}`);
    const coverId = (envelope.data as CoverIdDataWire).coverId ?? '';
    if (coverId.length === 0) {
      throw new ApiError(ApiErrorKind.PARSE, '上传成功响应缺少 coverId');
    }
    return coverId;
  }

  private static playlistDefaultCoverIndex(coverId: string): number {
    for (let index = 1; index <= 4; index++) {
      if (coverId === `playlist_default_${index}`) {
        return index;
      }
    }
    return 0;
  }

  private async pageRequest<TWire, TModel>(path: string, query: string,
    mapper: (item: TWire) => TModel): Promise<PageResult<TModel>> {
    const envelope = await this.request<PageDataWire<TWire>>('GET', path, query);
    const data = envelope.data as PageDataWire<TWire>;
    if (data.list === undefined || data.total === undefined) {
      throw new ApiError(ApiErrorKind.PARSE, '分页响应缺少 list 或 total 字段');
    }
    return pageFromWire(data, mapper);
  }

  private async request<T>(method: 'GET' | 'POST', path: string, query?: string,
    body?: Object | ArrayBuffer, authenticated: boolean = true, requireData: boolean = true,
    contentType: string = 'application/json'): Promise<ApiEnvelope<T>> {
    if (this.configuration.baseUrl.length === 0) {
      throw new ApiError(ApiErrorKind.NETWORK, '服务器地址未配置');
    }
    const client = http.createHttp();
    try {
      const options: http.HttpRequestOptions = {
        method: method === 'GET' ? http.RequestMethod.GET : http.RequestMethod.POST,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: this.configuration.connectTimeoutMs,
        readTimeout: this.configuration.readTimeoutMs,
        maxRedirects: this.configuration.maxRedirects,
        usingCache: false,
        header: this.headers(authenticated, contentType)
      };
      if (query !== undefined) {
        options.queryParams = query;
      }
      if (body !== undefined) {
        options.body = body instanceof ArrayBuffer ? body : JSON.stringify(body);
      }
      const response = await client.request(this.apiUrl(path), options);
      const text = FeiniuMusicApi.responseText(response.result);
      if (response.responseCode === 401) {
        throw new ApiError(ApiErrorKind.UNAUTHORIZED, '登录已失效', 401);
      }
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new ApiError(ApiErrorKind.HTTP, `服务器返回 HTTP ${response.responseCode}`, response.responseCode);
      }
      return parseApiEnvelope<T>(text, requireData);
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      const platformError = error as PlatformNetworkError;
      const code = platformError.code ?? 0;
      throw new ApiError(ApiErrorKind.NETWORK,
        FeiniuMusicApi.networkErrorMessage(code, platformError.message ?? ''), 0, 0, code);
    } finally {
      client.destroy();
    }
  }

  private pageQuery(page: number, size: number, sort?: string): string {
    let query = this.singleQuery('page', page);
    query = this.appendQuery(query, 'size', size);
    if (sort !== undefined && sort.trim().length > 0) {
      query = this.appendQuery(query, 'sort', sort);
    }
    return query;
  }

  private detailPageQuery(key: string, value: string, page: number, size: number, sort?: string): string {
    let query = this.pageQuery(page, size, sort);
    query = this.appendQuery(query, key, value);
    return query;
  }

  private searchQuery(value: string, page: number, size: number): string {
    let query = this.pageQuery(page, size);
    query = this.appendQuery(query, 'q', value);
    return query;
  }

  private singleQuery(key: string, value: QueryValue): string {
    return `${encodeURIComponent(key)}=${encodeURIComponent(`${value}`)}`;
  }

  private appendQuery(query: string, key: string, value: QueryValue): string {
    const pair = this.singleQuery(key, value);
    return query.length > 0 ? `${query}&${pair}` : pair;
  }

  private headers(authenticated: boolean, contentType: string = 'application/json'): Record<string, string> {
    const headers: Record<string, string> = {
      'Accept': 'application/json',
      'Content-Type': contentType
    };
    if (this.configuration.relayMode) {
      headers.Cookie = authenticated && this.configuration.token.length > 0 ?
        `music-token=${this.configuration.token}; mode=relay` : 'mode=relay';
    } else if (authenticated && this.configuration.token.length > 0) {
      headers.Cookie = `music-token=${this.configuration.token}`;
    }
    if (this.configuration.accessCode.length > 0) {
      headers['x-access-code'] = this.base64.encodeToStringSync(this.encoder.encodeInto(this.configuration.accessCode));
      headers['x-access-source'] = 'app';
    }
    return headers;
  }

  private apiUrl(path: string): string {
    return `${this.configuration.baseUrl}/music/api/v1${path}`;
  }

  private mediaUrl(path: string, query: string): string {
    return query.length > 0 ? `${this.apiUrl(path)}?${query}` : this.apiUrl(path);
  }

  static normalizeBaseUrl(value: string): string {
    return value.trim().replace(/\/$/, '');
  }

  static networkErrorMessage(code: number, detail: string): string {
    if (code === 2300006) {
      return '无法解析服务器地址';
    }
    if (code === 2300007) {
      return '无法连接服务器';
    }
    if (code === 2300028) {
      return '连接服务器超时';
    }
    if (code === 2300047) {
      return '服务器重定向次数过多';
    }
    if (code === 2300058) {
      return '本地 SSL 证书错误';
    }
    if (code === 2300060) {
      return '服务器 SSL 证书无效或已过期';
    }
    if (code === 2300077) {
      return 'SSL CA 证书不可用';
    }
    if (code === 2300094) {
      return '服务器身份校验失败';
    }
    if (code === 2300997) {
      return '系统禁止明文 HTTP 连接';
    }
    const normalized = detail.trim();
    return normalized.length > 0 ? normalized : (code > 0 ? `网络连接异常（${code}）` : '网络连接异常');
  }

  static sha256Hex(value: string): string {
    const source = FeiniuMusicApi.utf8Bytes(value);
    const paddedLength = Math.ceil((source.length + 9) / 64) * 64;
    const data = new Uint8Array(paddedLength);
    data.set(source);
    data[source.length] = 0x80;
    const bitLength = source.length * 8;
    const highLength = Math.floor(bitLength / 0x100000000);
    const lowLength = bitLength >>> 0;
    FeiniuMusicApi.writeUInt32BE(data, paddedLength - 8, highLength);
    FeiniuMusicApi.writeUInt32BE(data, paddedLength - 4, lowLength);

    const state: number[] = [
      0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
      0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    ];
    const constants: number[] = [
      0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4,
      0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe,
      0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f,
      0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
      0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc,
      0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
      0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116,
      0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
      0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7,
      0xc67178f2
    ];
    const words: number[] = new Array<number>(64).fill(0);
    for (let offset = 0; offset < data.length; offset += 64) {
      for (let index = 0; index < 16; index++) {
        const position = offset + index * 4;
        words[index] = ((data[position] << 24) | (data[position + 1] << 16) |
          (data[position + 2] << 8) | data[position + 3]) >>> 0;
      }
      for (let index = 16; index < 64; index++) {
        const s0 = FeiniuMusicApi.rotateRight(words[index - 15], 7) ^
          FeiniuMusicApi.rotateRight(words[index - 15], 18) ^ (words[index - 15] >>> 3);
        const s1 = FeiniuMusicApi.rotateRight(words[index - 2], 17) ^
          FeiniuMusicApi.rotateRight(words[index - 2], 19) ^ (words[index - 2] >>> 10);
        words[index] = (words[index - 16] + s0 + words[index - 7] + s1) >>> 0;
      }

      let a = state[0];
      let b = state[1];
      let c = state[2];
      let d = state[3];
      let e = state[4];
      let f = state[5];
      let g = state[6];
      let h = state[7];
      for (let index = 0; index < 64; index++) {
        const upperSigma1 = FeiniuMusicApi.rotateRight(e, 6) ^ FeiniuMusicApi.rotateRight(e, 11) ^
          FeiniuMusicApi.rotateRight(e, 25);
        const choice = (e & f) ^ (~e & g);
        const temporary1 = (h + upperSigma1 + choice + constants[index] + words[index]) >>> 0;
        const upperSigma0 = FeiniuMusicApi.rotateRight(a, 2) ^ FeiniuMusicApi.rotateRight(a, 13) ^
          FeiniuMusicApi.rotateRight(a, 22);
        const majority = (a & b) ^ (a & c) ^ (b & c);
        const temporary2 = (upperSigma0 + majority) >>> 0;
        h = g;
        g = f;
        f = e;
        e = (d + temporary1) >>> 0;
        d = c;
        c = b;
        b = a;
        a = (temporary1 + temporary2) >>> 0;
      }
      state[0] = (state[0] + a) >>> 0;
      state[1] = (state[1] + b) >>> 0;
      state[2] = (state[2] + c) >>> 0;
      state[3] = (state[3] + d) >>> 0;
      state[4] = (state[4] + e) >>> 0;
      state[5] = (state[5] + f) >>> 0;
      state[6] = (state[6] + g) >>> 0;
      state[7] = (state[7] + h) >>> 0;
    }
    return state.map((word: number): string => (word >>> 0).toString(16).padStart(8, '0')).join('');
  }

  private static rotateRight(value: number, count: number): number {
    return ((value >>> count) | (value << (32 - count))) >>> 0;
  }

  private static utf8Bytes(value: string): Uint8Array {
    const bytes: number[] = [];
    for (let index = 0; index < value.length; index++) {
      let code = value.charCodeAt(index);
      if (code >= 0xd800 && code <= 0xdbff && index + 1 < value.length) {
        const low = value.charCodeAt(index + 1);
        if (low >= 0xdc00 && low <= 0xdfff) {
          code = 0x10000 + ((code - 0xd800) << 10) + (low - 0xdc00);
          index += 1;
        }
      }
      if (code <= 0x7f) {
        bytes.push(code);
      } else if (code <= 0x7ff) {
        bytes.push(0xc0 | (code >>> 6));
        bytes.push(0x80 | (code & 0x3f));
      } else if (code <= 0xffff) {
        bytes.push(0xe0 | (code >>> 12));
        bytes.push(0x80 | ((code >>> 6) & 0x3f));
        bytes.push(0x80 | (code & 0x3f));
      } else {
        bytes.push(0xf0 | (code >>> 18));
        bytes.push(0x80 | ((code >>> 12) & 0x3f));
        bytes.push(0x80 | ((code >>> 6) & 0x3f));
        bytes.push(0x80 | (code & 0x3f));
      }
    }
    const result = new Uint8Array(bytes.length);
    for (let index = 0; index < bytes.length; index++) {
      result[index] = bytes[index];
    }
    return result;
  }

  private static writeUInt32BE(target: Uint8Array, offset: number, value: number): void {
    target[offset] = (value >>> 24) & 0xff;
    target[offset + 1] = (value >>> 16) & 0xff;
    target[offset + 2] = (value >>> 8) & 0xff;
    target[offset + 3] = value & 0xff;
  }

  private static responseText(value: string | Object | ArrayBuffer): string {
    if (typeof value === 'string') {
      return value;
    }
    if (value instanceof ArrayBuffer) {
      return new util.TextDecoder('utf-8', { fatal: false })
        .decodeWithStream(new Uint8Array(value), { stream: false });
    }
    return JSON.stringify(value);
  }
}
