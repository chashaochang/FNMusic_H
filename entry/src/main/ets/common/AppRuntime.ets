import { common } from '@kit.AbilityKit';
import { AppStorageV2 } from '@kit.ArkUI';
import { AuthenticationApi, AuthStore, ConnectionResolver, CredentialStorage } from '../auth/AuthStore';
import { AuthPhase, AuthSnapshot, LoginCredentials } from '../auth/ConnectionModels';
import { CredentialVault } from '../auth/CredentialVault';
import { FnConnectService } from '../auth/FnConnectService';
import {
  MusicAlbum,
  MusicArtist,
  MusicGenre,
  MusicLyricsResult,
  MusicPlaylist,
  MusicRoamResult,
  MusicTrack,
  MusicUser
} from '../model/MusicModels';
import { FeiniuMusicApi } from '../network/FeiniuMusicApi';
import { MusicPlaybackController } from '../playback/MusicPlaybackController';

@ObservedV2
export class AppRuntimeState {
  @Trace phase: string = AuthPhase.IDLE;
  @Trace message: string = '';
  @Trace baseUrl: string = '';
  @Trace username: string = '';
  @Trace role: string = '';
  @Trace canRetry: boolean = false;
  @Trace loadingLibrary: boolean = false;
  @Trace libraryError: string = '';
  @Trace tracks: MusicTrack[] = [];
  @Trace recentTracks: MusicTrack[] = [];
  @Trace trackTotal: number = 0;
  @Trace tracksHasMore: boolean = false;
  @Trace tracksLoadingMore: boolean = false;
  @Trace tracksLoadMoreError: string = '';
  @Trace albums: MusicAlbum[] = [];
  @Trace recentAlbums: MusicAlbum[] = [];
  @Trace albumTotal: number = 0;
  @Trace albumsHasMore: boolean = false;
  @Trace albumsLoadingMore: boolean = false;
  @Trace albumsLoadMoreError: string = '';
  @Trace artists: MusicArtist[] = [];
  @Trace artistTotal: number = 0;
  @Trace artistsHasMore: boolean = false;
  @Trace artistsLoadingMore: boolean = false;
  @Trace artistsLoadMoreError: string = '';
  @Trace genres: MusicGenre[] = [];
  @Trace genreTotal: number = 0;
  @Trace genresHasMore: boolean = false;
  @Trace genresLoadingMore: boolean = false;
  @Trace genresLoadMoreError: string = '';
  @Trace playlists: MusicPlaylist[] = [];
}

/** Owns the authenticated API session shared by the entry page, screens and audio player. */
export class AppRuntime {
  private static readonly catalogPageSize: number = 100;
  private static readonly homeRecentSize: number = 10;
  private static readonly runtimeStateKey: string = 'FeiniuMusicRuntimeState';
  private static context?: common.UIAbilityContext;
  private static api: FeiniuMusicApi = new FeiniuMusicApi();
  private static auth?: AuthStore;
  private static initialized: boolean = false;
  private static restoring?: Promise<boolean>;
  private static loadedLibrarySessionGeneration: number = -1;
  private static roamRelativeId: string = '';
  private static trackPage: number = 0;
  private static albumPage: number = 0;
  private static artistPage: number = 0;
  private static genrePage: number = 0;

  static state(): AppRuntimeState {
    return AppStorageV2.connect(AppRuntimeState, AppRuntime.runtimeStateKey, () => new AppRuntimeState())!;
  }

  static initialize(context: common.UIAbilityContext): void {
    AppRuntime.context = context;
    if (AppRuntime.initialized) {
      return;
    }
    const vault = new CredentialVault(context);
    AppRuntime.auth = new AuthStore(
      AppRuntime.api as AuthenticationApi,
      new FnConnectService() as ConnectionResolver,
      vault as CredentialStorage
    );
    AppRuntime.auth.addListener((snapshot: AuthSnapshot): void => AppRuntime.publishAuth(snapshot));
    const playback = MusicPlaybackController.instance();
    playback.configureApi(AppRuntime.api, AppRuntime.auth);
    playback.configureRoamTrackSource((): Promise<MusicTrack[]> => AppRuntime.nextRoam());
    AppRuntime.initialized = true;
  }

  static isAuthenticated(): boolean {
    return AppRuntime.state().phase === AuthPhase.AUTHENTICATED;
  }

  static isRestoring(): boolean {
    const phase = AppRuntime.state().phase;
    return phase === AuthPhase.IDLE || phase === AuthPhase.RESTORING || phase === AuthPhase.RESOLVING ||
      phase === AuthPhase.CONNECTING || phase === AuthPhase.AUTHENTICATING;
  }

  static async restore(): Promise<boolean> {
    if (AppRuntime.restoring !== undefined) {
      return await AppRuntime.restoring;
    }
    AppRuntime.ensureInitialized();
    AppRuntime.restoring = AppRuntime.restoreInternal();
    try {
      return await AppRuntime.restoring;
    } finally {
      AppRuntime.restoring = undefined;
    }
  }

  static async signIn(credentials: LoginCredentials): Promise<boolean> {
    AppRuntime.ensureInitialized();
    const auth = AppRuntime.auth!;
    const result = await auth.signIn(credentials);
    const generation = auth.sessionGeneration();
    if (result && auth.isSessionActive(generation)) {
      await AppRuntime.loadLibrary();
    }
    return result && auth.isSessionActive(generation);
  }

  static async retry(): Promise<boolean> {
    if (AppRuntime.isAuthenticated()) {
      try {
        AppRuntime.ensureInitialized();
        const auth = AppRuntime.auth!;
        const restored = await auth.restore();
        const generation = auth.sessionGeneration();
        if (restored && auth.isSessionActive(generation)) {
          await AppRuntime.loadLibrary();
        }
        return restored && auth.isSessionActive(generation) && AppRuntime.state().libraryError.length === 0;
      } catch (_) {
        return false;
      }
    }
    return await AppRuntime.restore();
  }

  static async signOut(forgetAccount: boolean = false): Promise<void> {
    AppRuntime.ensureInitialized();
    const request = AppRuntime.auth!.signOut(forgetAccount);
    MusicPlaybackController.instance().release();
    AppRuntime.clearLibrary();
    await request;
  }

  static user(): MusicUser {
    AppRuntime.ensureInitialized();
    return AppRuntime.auth!.user();
  }

  static apiClient(): FeiniuMusicApi {
    return AppRuntime.api;
  }

  static authStore(): AuthStore {
    AppRuntime.ensureInitialized();
    return AppRuntime.auth!;
  }

  static async loadLibrary(): Promise<void> {
    AppRuntime.ensureInitialized();
    const auth = AppRuntime.auth!;
    const generation = auth.sessionGeneration();
    if (!auth.isSessionActive(generation)) {
      AppRuntime.clearLibrary();
      return;
    }
    const state = AppRuntime.state();
    state.loadingLibrary = true;
    state.libraryError = '';
    AppRuntime.resetPaginationState(state);
    try {
      const tracks = await auth.withAutoReconnect(() =>
        AppRuntime.api.tracks(1, AppRuntime.catalogPageSize, 'createdAt,desc'));
      if (!auth.isSessionActive(generation)) {
        return;
      }
      state.tracks = tracks.list;
      state.recentTracks = tracks.list.slice(0, AppRuntime.homeRecentSize);
      state.trackTotal = Math.max(tracks.total, tracks.list.length);
      state.tracksHasMore = AppRuntime.pageHasMore(tracks.list.length, tracks.total);
      AppRuntime.trackPage = 1;
      AppRuntime.loadedLibrarySessionGeneration = generation;
      state.loadingLibrary = false;
      await Promise.all([
        AppRuntime.loadSecondaryCatalog(generation, async (): Promise<void> => {
          const albums = await auth.withAutoReconnect(() =>
            AppRuntime.api.albums(1, AppRuntime.catalogPageSize, 'trackCount,desc'));
          if (auth.isSessionActive(generation)) {
            state.albums = albums.list;
            state.albumTotal = Math.max(albums.total, albums.list.length);
            state.albumsHasMore = AppRuntime.pageHasMore(albums.list.length, albums.total);
            AppRuntime.albumPage = 1;
          }
        }),
        AppRuntime.loadSecondaryCatalog(generation, async (): Promise<void> => {
          const artists = await auth.withAutoReconnect(() =>
            AppRuntime.api.artists(1, AppRuntime.catalogPageSize));
          if (auth.isSessionActive(generation)) {
            state.artists = artists.list;
            state.artistTotal = Math.max(artists.total, artists.list.length);
            state.artistsHasMore = AppRuntime.pageHasMore(artists.list.length, artists.total);
            AppRuntime.artistPage = 1;
          }
        }),
        AppRuntime.loadSecondaryCatalog(generation, async (): Promise<void> => {
          const genres = await auth.withAutoReconnect(() =>
            AppRuntime.api.genres(1, AppRuntime.catalogPageSize));
          if (auth.isSessionActive(generation)) {
            state.genres = genres.list;
            state.genreTotal = Math.max(genres.total, genres.list.length);
            state.genresHasMore = AppRuntime.pageHasMore(genres.list.length, genres.total);
            AppRuntime.genrePage = 1;
          }
        }),
        AppRuntime.loadSecondaryCatalog(generation, async (): Promise<void> => {
          const recentAlbums = await auth.withAutoReconnect(() =>
            AppRuntime.api.albums(1, AppRuntime.homeRecentSize, 'newTrackAddedAt,desc'));
          if (auth.isSessionActive(generation)) {
            state.recentAlbums = recentAlbums.list;
          }
        }),
        AppRuntime.loadSecondaryCatalog(generation, async (): Promise<void> => {
          const playlists = await auth.withAutoReconnect(() => AppRuntime.api.playlists(1, 80));
          if (auth.isSessionActive(generation)) {
            state.playlists = playlists.list;
          }
        })
      ]);
    } catch (error) {
      if (auth.isSessionActive(generation)) {
        const message = (error as Error).message;
        state.libraryError = message.length > 0 ? message : '音乐库加载失败';
      }
    } finally {
      if (auth.sessionGeneration() === generation) {
        state.loadingLibrary = false;
      }
    }
  }

  static async loadMoreTracks(): Promise<void> {
    AppRuntime.ensureInitialized();
    const state = AppRuntime.state();
    if (state.tracksLoadingMore || !state.tracksHasMore) {
      return;
    }
    const auth = AppRuntime.auth!;
    const generation = auth.sessionGeneration();
    if (!auth.isSessionActive(generation)) {
      return;
    }
    const nextPage = Math.max(1, AppRuntime.trackPage) + 1;
    state.tracksLoadingMore = true;
    state.tracksLoadMoreError = '';
    try {
      const page = await auth.withAutoReconnect(() =>
        AppRuntime.api.tracks(nextPage, AppRuntime.catalogPageSize, 'createdAt,desc'));
      if (!auth.isSessionActive(generation)) {
        return;
      }
      state.tracks = AppRuntime.appendUniqueTracks(state.tracks, page.list);
      state.trackTotal = Math.max(page.total, state.tracks.length);
      state.tracksHasMore = AppRuntime.pageHasMore(state.tracks.length, page.total, page.list.length);
      AppRuntime.trackPage = nextPage;
    } catch (error) {
      if (auth.isSessionActive(generation)) {
        state.tracksLoadMoreError = AppRuntime.errorMessage(error, '加载更多歌曲失败');
      }
    } finally {
      if (auth.sessionGeneration() === generation) {
        state.tracksLoadingMore = false;
      }
    }
  }

  static async loadMoreAlbums(): Promise<void> {
    AppRuntime.ensureInitialized();
    const state = AppRuntime.state();
    if (state.albumsLoadingMore || !state.albumsHasMore) {
      return;
    }
    const auth = AppRuntime.auth!;
    const generation = auth.sessionGeneration();
    if (!auth.isSessionActive(generation)) {
      return;
    }
    const nextPage = Math.max(1, AppRuntime.albumPage) + 1;
    state.albumsLoadingMore = true;
    state.albumsLoadMoreError = '';
    try {
      const page = await auth.withAutoReconnect(() =>
        AppRuntime.api.albums(nextPage, AppRuntime.catalogPageSize, 'trackCount,desc'));
      if (!auth.isSessionActive(generation)) {
        return;
      }
      state.albums = AppRuntime.appendUniqueAlbums(state.albums, page.list);
      state.albumTotal = Math.max(page.total, state.albums.length);
      state.albumsHasMore = AppRuntime.pageHasMore(state.albums.length, page.total, page.list.length);
      AppRuntime.albumPage = nextPage;
    } catch (error) {
      if (auth.isSessionActive(generation)) {
        state.albumsLoadMoreError = AppRuntime.errorMessage(error, '加载更多专辑失败');
      }
    } finally {
      if (auth.sessionGeneration() === generation) {
        state.albumsLoadingMore = false;
      }
    }
  }

  static async loadMoreArtists(): Promise<void> {
    AppRuntime.ensureInitialized();
    const state = AppRuntime.state();
    if (state.artistsLoadingMore || !state.artistsHasMore) {
      return;
    }
    const auth = AppRuntime.auth!;
    const generation = auth.sessionGeneration();
    if (!auth.isSessionActive(generation)) {
      return;
    }
    const nextPage = Math.max(1, AppRuntime.artistPage) + 1;
    state.artistsLoadingMore = true;
    state.artistsLoadMoreError = '';
    try {
      const page = await auth.withAutoReconnect(() =>
        AppRuntime.api.artists(nextPage, AppRuntime.catalogPageSize));
      if (!auth.isSessionActive(generation)) {
        return;
      }
      state.artists = AppRuntime.appendUniqueArtists(state.artists, page.list);
      state.artistTotal = Math.max(page.total, state.artists.length);
      state.artistsHasMore = AppRuntime.pageHasMore(state.artists.length, page.total, page.list.length);
      AppRuntime.artistPage = nextPage;
    } catch (error) {
      if (auth.isSessionActive(generation)) {
        state.artistsLoadMoreError = AppRuntime.errorMessage(error, '加载更多歌手失败');
      }
    } finally {
      if (auth.sessionGeneration() === generation) {
        state.artistsLoadingMore = false;
      }
    }
  }

  static async loadMoreGenres(): Promise<void> {
    AppRuntime.ensureInitialized();
    const state = AppRuntime.state();
    if (state.genresLoadingMore || !state.genresHasMore) {
      return;
    }
    const auth = AppRuntime.auth!;
    const generation = auth.sessionGeneration();
    if (!auth.isSessionActive(generation)) {
      return;
    }
    const nextPage = Math.max(1, AppRuntime.genrePage) + 1;
    state.genresLoadingMore = true;
    state.genresLoadMoreError = '';
    try {
      const page = await auth.withAutoReconnect(() =>
        AppRuntime.api.genres(nextPage, AppRuntime.catalogPageSize));
      if (!auth.isSessionActive(generation)) {
        return;
      }
      state.genres = AppRuntime.appendUniqueGenres(state.genres, page.list);
      state.genreTotal = Math.max(page.total, state.genres.length);
      state.genresHasMore = AppRuntime.pageHasMore(state.genres.length, page.total, page.list.length);
      AppRuntime.genrePage = nextPage;
    } catch (error) {
      if (auth.isSessionActive(generation)) {
        state.genresLoadMoreError = AppRuntime.errorMessage(error, '加载更多风格失败');
      }
    } finally {
      if (auth.sessionGeneration() === generation) {
        state.genresLoadingMore = false;
      }
    }
  }

  static async searchTracks(query: string): Promise<MusicTrack[]> {
    return (await AppRuntime.authStore().withAutoReconnect(() => AppRuntime.api.searchTracks(query))).list;
  }

  static async searchAlbums(query: string): Promise<MusicAlbum[]> {
    return (await AppRuntime.authStore().withAutoReconnect(() => AppRuntime.api.searchAlbums(query))).list;
  }

  static async searchArtists(query: string): Promise<MusicArtist[]> {
    return (await AppRuntime.authStore().withAutoReconnect(() => AppRuntime.api.searchArtists(query))).list;
  }

  static async setFavorite(track: MusicTrack, favorite: boolean): Promise<void> {
    await AppRuntime.authStore().withAutoReconnect(() => AppRuntime.api.setFavorite(track.guid, favorite));
    track.isFavorite = favorite;
    const state = AppRuntime.state();
    AppRuntime.updateFavorite(state.tracks, track.guid, favorite);
    state.tracks = state.tracks.slice();
    const playerState = MusicPlaybackController.instance().state();
    AppRuntime.updateFavorite(playerState.queue, track.guid, favorite);
    playerState.queue = playerState.queue.slice();
    MusicPlaybackController.instance().refreshSystemSession();
  }

  static async favoriteTracks(): Promise<MusicTrack[]> {
    return (await AppRuntime.authStore().withAutoReconnect(() => AppRuntime.api.favoriteTracks())).list;
  }

  static async playHistory(): Promise<MusicTrack[]> {
    return (await AppRuntime.authStore().withAutoReconnect(() => AppRuntime.api.playHistory())).list;
  }

  static async deletePlayHistory(trackGuids: string[]): Promise<void> {
    await AppRuntime.authStore().withAutoReconnect(() => AppRuntime.api.deletePlayHistory(trackGuids));
  }

  static async albumTracks(guid: string): Promise<MusicTrack[]> {
    return (await AppRuntime.authStore().withAutoReconnect(() => AppRuntime.api.albumTracks(guid))).list;
  }

  static async artistTracks(guid: string): Promise<MusicTrack[]> {
    return (await AppRuntime.authStore().withAutoReconnect(() => AppRuntime.api.artistTracks(guid))).list;
  }

  static async genreTracks(guid: string): Promise<MusicTrack[]> {
    return (await AppRuntime.authStore().withAutoReconnect(() => AppRuntime.api.genreTracks(guid))).list;
  }

  static async playlistTracks(guid: string): Promise<MusicTrack[]> {
    return (await AppRuntime.authStore().withAutoReconnect(() => AppRuntime.api.playlistTracks(guid))).list;
  }

  static async trackMetadata(guid: string): Promise<MusicTrack> {
    return await AppRuntime.authStore().withAutoReconnect(() => AppRuntime.api.trackMetadata(guid));
  }

  static async lyrics(guid: string): Promise<MusicLyricsResult> {
    return await AppRuntime.authStore().withAutoReconnect(() => AppRuntime.api.lyrics(guid));
  }

  static async startRoam(): Promise<MusicTrack[]> {
    const deviceId = await AppRuntime.authStore().deviceId();
    const result = await AppRuntime.authStore().withAutoReconnect(() => AppRuntime.api.roamStart(deviceId));
    AppRuntime.roamRelativeId = result.current?.roamId ?? '';
    return AppRuntime.roamTracks(result, true);
  }

  static async nextRoam(): Promise<MusicTrack[]> {
    if (AppRuntime.roamRelativeId.length === 0) {
      return await AppRuntime.startRoam();
    }
    const deviceId = await AppRuntime.authStore().deviceId();
    const result = await AppRuntime.authStore().withAutoReconnect(() =>
      AppRuntime.api.roamNext(deviceId, AppRuntime.roamRelativeId));
    AppRuntime.roamRelativeId = result.current?.roamId ?? AppRuntime.roamRelativeId;
    return AppRuntime.roamTracks(result, false);
  }

  static async createPlaylist(name: string, coverId?: string): Promise<MusicPlaylist> {
    const playlist = await AppRuntime.authStore().withAutoReconnect(() => AppRuntime.api.createPlaylist(name, coverId));
    if (playlist.coverId.length === 0 && coverId !== undefined) {
      playlist.coverId = coverId;
    }
    AppRuntime.state().playlists = [playlist].concat(AppRuntime.state().playlists);
    return playlist;
  }

  static async renamePlaylist(playlist: MusicPlaylist, name: string): Promise<void> {
    await AppRuntime.editPlaylist(playlist, name);
  }

  static async editPlaylist(playlist: MusicPlaylist, name: string, coverId?: string): Promise<void> {
    const normalized = name.trim();
    await AppRuntime.authStore().withAutoReconnect(() =>
      AppRuntime.api.editPlaylist(playlist.guid, normalized, coverId));
    playlist.name = normalized;
    if (coverId !== undefined) {
      playlist.coverId = coverId;
    }
    AppRuntime.state().playlists = AppRuntime.state().playlists.slice();
  }

  static async uploadPlaylistCover(bytes: Uint8Array, fileName: string, mimeType: string): Promise<string> {
    return await AppRuntime.authStore().withAutoReconnect(() =>
      AppRuntime.api.uploadPlaylistCover(bytes, fileName, mimeType));
  }

  static async deletePlaylist(playlist: MusicPlaylist): Promise<void> {
    await AppRuntime.authStore().withAutoReconnect(() => AppRuntime.api.deletePlaylist(playlist.guid));
    AppRuntime.state().playlists = AppRuntime.state().playlists.filter((item: MusicPlaylist): boolean =>
      item.guid !== playlist.guid);
  }

  static async addTrackToPlaylist(playlistGuid: string, trackGuid: string): Promise<void> {
    await AppRuntime.authStore().withAutoReconnect(() =>
      AppRuntime.api.addTracksToPlaylist(playlistGuid, [trackGuid]));
  }

  static async removeTrackFromPlaylist(playlistGuid: string, trackGuid: string): Promise<void> {
    await AppRuntime.authStore().withAutoReconnect(() =>
      AppRuntime.api.removeTracksFromPlaylist(playlistGuid, [trackGuid]));
  }

  static async removeTracksFromPlaylist(playlistGuid: string, trackGuids: string[]): Promise<void> {
    if (trackGuids.length === 0) {
      return;
    }
    await AppRuntime.authStore().withAutoReconnect(() =>
      AppRuntime.api.removeTracksFromPlaylist(playlistGuid, trackGuids));
  }

  static streamUrl(trackGuid: string): string {
    return AppRuntime.api.streamUrl(trackGuid);
  }

  static coverUrl(coverId: string, size: number = 512, updatedAt?: number): string {
    return AppRuntime.api.coverUrl(coverId, size, updatedAt);
  }

  static playbackHeaders(rangeStart?: number, rangeEnd?: number): Record<string, string> {
    return AppRuntime.api.playbackHeaders(rangeStart, rangeEnd);
  }

  static async reportTrackPlay(trackGuid: string): Promise<void> {
    try {
      await AppRuntime.authStore().withAutoReconnect(() => AppRuntime.api.reportTrackPlay(trackGuid));
    } catch (_) {
      // Playback reporting is best-effort and never interrupts listening.
    }
  }

  private static async restoreInternal(): Promise<boolean> {
    const auth = AppRuntime.auth!;
    const result = await auth.restore();
    const generation = auth.sessionGeneration();
    if (result && auth.isSessionActive(generation)) {
      await AppRuntime.loadLibrary();
    }
    return result && auth.isSessionActive(generation);
  }

  private static publishAuth(snapshot: AuthSnapshot): void {
    const state = AppRuntime.state();
    state.phase = snapshot.phase;
    state.message = snapshot.message;
    state.baseUrl = snapshot.baseUrl;
    state.username = snapshot.username;
    state.role = snapshot.role;
    state.canRetry = snapshot.canRetry;
    if (snapshot.phase === AuthPhase.AUTHENTICATED) {
      MusicPlaybackController.instance().refreshSystemSession();
    }
    const generation = AppRuntime.auth?.sessionGeneration() ?? -1;
    const startsAnotherSession = snapshot.phase !== AuthPhase.AUTHENTICATED &&
      AppRuntime.loadedLibrarySessionGeneration >= 0 &&
      AppRuntime.loadedLibrarySessionGeneration !== generation;
    if (startsAnotherSession || snapshot.phase === AuthPhase.SIGNED_OUT || snapshot.phase === AuthPhase.ERROR) {
      AppRuntime.clearLibrary();
    }
  }

  private static roamTracks(result: MusicRoamResult, initial: boolean): MusicTrack[] {
    const tracks: MusicTrack[] = [];
    if (initial && result.current !== undefined) {
      tracks.push(result.current.track);
    }
    if (result.next !== undefined) {
      tracks.push(result.next.track);
    }
    return tracks;
  }

  private static async loadSecondaryCatalog(generation: number, load: () => Promise<void>): Promise<void> {
    try {
      await load();
    } catch (_) {
      // Tracks are the primary home payload. Secondary sections degrade independently.
    }
    if (AppRuntime.auth?.sessionGeneration() !== generation) {
      return;
    }
  }

  private static updateFavorite(tracks: MusicTrack[], guid: string, favorite: boolean): void {
    tracks.forEach((item: MusicTrack): void => {
      if (item.guid === guid) {
        item.isFavorite = favorite;
      }
    });
  }

  private static pageHasMore(loadedCount: number, total: number, lastPageCount: number = loadedCount): boolean {
    if (lastPageCount <= 0) {
      return false;
    }
    return total > 0 ? loadedCount < total : lastPageCount >= AppRuntime.catalogPageSize;
  }

  private static appendUniqueTracks(current: MusicTrack[], incoming: MusicTrack[]): MusicTrack[] {
    const known = new Set<string>(current.map((item: MusicTrack): string => item.guid));
    const additions = incoming.filter((item: MusicTrack): boolean => item.guid.length > 0 && !known.has(item.guid));
    return current.concat(additions);
  }

  private static appendUniqueAlbums(current: MusicAlbum[], incoming: MusicAlbum[]): MusicAlbum[] {
    const known = new Set<string>(current.map((item: MusicAlbum): string => item.guid));
    const additions = incoming.filter((item: MusicAlbum): boolean => item.guid.length > 0 && !known.has(item.guid));
    return current.concat(additions);
  }

  private static appendUniqueArtists(current: MusicArtist[], incoming: MusicArtist[]): MusicArtist[] {
    const known = new Set<string>(current.map((item: MusicArtist): string => item.guid));
    const additions = incoming.filter((item: MusicArtist): boolean => item.guid.length > 0 && !known.has(item.guid));
    return current.concat(additions);
  }

  private static appendUniqueGenres(current: MusicGenre[], incoming: MusicGenre[]): MusicGenre[] {
    const known = new Set<string>(current.map((item: MusicGenre): string => item.guid));
    const additions = incoming.filter((item: MusicGenre): boolean => item.guid.length > 0 && !known.has(item.guid));
    return current.concat(additions);
  }

  private static errorMessage(error: Object, fallback: string): string {
    const message = (error as Error).message;
    return message !== undefined && message.length > 0 ? message : fallback;
  }

  private static resetPaginationState(state: AppRuntimeState): void {
    state.recentTracks = [];
    state.trackTotal = 0;
    state.tracksHasMore = false;
    state.tracksLoadingMore = false;
    state.tracksLoadMoreError = '';
    state.recentAlbums = [];
    state.albumTotal = 0;
    state.albumsHasMore = false;
    state.albumsLoadingMore = false;
    state.albumsLoadMoreError = '';
    state.artistTotal = 0;
    state.artistsHasMore = false;
    state.artistsLoadingMore = false;
    state.artistsLoadMoreError = '';
    state.genreTotal = 0;
    state.genresHasMore = false;
    state.genresLoadingMore = false;
    state.genresLoadMoreError = '';
    AppRuntime.trackPage = 0;
    AppRuntime.albumPage = 0;
    AppRuntime.artistPage = 0;
    AppRuntime.genrePage = 0;
  }

  private static clearLibrary(): void {
    const state = AppRuntime.state();
    state.tracks = [];
    state.albums = [];
    state.artists = [];
    state.genres = [];
    state.playlists = [];
    state.libraryError = '';
    state.loadingLibrary = false;
    AppRuntime.resetPaginationState(state);
    AppRuntime.loadedLibrarySessionGeneration = -1;
    AppRuntime.roamRelativeId = '';
  }

  private static ensureInitialized(): void {
    if (!AppRuntime.initialized || AppRuntime.auth === undefined || AppRuntime.context === undefined) {
      throw new Error('应用运行时尚未初始化');
    }
  }
}
