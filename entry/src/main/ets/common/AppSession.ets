import { MusicAlbum, MusicArtist, MusicGenre, MusicPlaylist, MusicTrack, MusicUser, demoTracks } from '../model/MusicModels';

@ObservedV2
export class AppSessionState {
  @Trace authenticated: boolean = false;
  @Trace restoring: boolean = true;
  @Trace user: MusicUser = new MusicUser();
  @Trace tracks: MusicTrack[] = demoTracks();
  @Trace albums: MusicAlbum[] = [];
  @Trace artists: MusicArtist[] = [];
  @Trace genres: MusicGenre[] = [];
  @Trace playlists: MusicPlaylist[] = [];
  @Trace connectionLabel: string = '演示模式';

  constructor() {
    this.albums = [
      new MusicAlbum('album-1', '此刻', '', 2026, '飞牛音乐'),
      new MusicAlbum('album-2', '漫游', '', 2026, '飞牛音乐'),
      new MusicAlbum('album-3', '最近添加', '', 2026, '飞牛音乐')
    ];
    this.artists = [
      new MusicArtist('artist-1', '飞牛音乐'),
      new MusicArtist('artist-2', '本地音乐人'),
      new MusicArtist('artist-3', '收藏歌手')
    ];
    this.genres = [
      new MusicGenre('genre-1', '流行', 26),
      new MusicGenre('genre-2', '轻音乐', 18),
      new MusicGenre('genre-3', '摇滚', 12),
      new MusicGenre('genre-4', '古典', 9)
    ];
    this.playlists = [
      new MusicPlaylist('playlist-1', '夜晚慢听', 12),
      new MusicPlaylist('playlist-2', '通勤收藏', 18)
    ];
    this.user.name = '飞牛用户';
    this.user.role = 'user';
  }
}

export const appSession: AppSessionState = new AppSessionState();
