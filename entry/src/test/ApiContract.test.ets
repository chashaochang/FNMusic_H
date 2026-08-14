import { describe, expect, it } from '@ohos/hypium';
import {
  MusicAlbum,
  MusicAlbumWire,
  MusicArtist,
  MusicArtistWire,
  MusicTrackWire,
  PageDataWire,
  musicAlbumFromWire,
  musicArtistFromWire,
  musicTrackFromWire,
  pageFromWire
} from '../main/ets/model/MusicModels';
import { parseApiEnvelope } from '../main/ets/network/ApiEnvelope';
import { ApiError, ApiErrorKind } from '../main/ets/network/ApiError';
import { FeiniuMusicApi } from '../main/ets/network/FeiniuMusicApi';
import {
  FnConnectResolveData,
  buildFnConnectCandidates,
  buildFnConnectSignature,
  isFnConnectInput,
  normalizeDirectBaseUrl,
  normalizeRelayBaseUrl
} from '../main/ets/auth/FnConnectService';

export default function apiContractTest(): void {
  describe('ApiContract', () => {
    it('parsesEnvelopeAndTrackPage', 0, () => {
      const fixture = '{"code":0,"msg":"ok","data":{"list":[{"guid":"track-1",' +
        '"title":"测试歌曲","duration":"123000","artists":[{"guid":"artist-1",' +
        '"name":"测试歌手"}],"album":{"guid":"album-1","name":"测试专辑"}}],"total":"1"}}';
      const envelope = parseApiEnvelope<PageDataWire<MusicTrackWire>>(fixture);
      const page = pageFromWire(envelope.data as PageDataWire<MusicTrackWire>, musicTrackFromWire);
      expect(page.total).assertEqual(1);
      expect(page.list[0].artistName).assertEqual('测试歌手');
      expect(page.list[0].durationMs).assertEqual(123000);
    });

    it('parsesCatalogTotalsAndEntityCounts', 0, () => {
      const albumData: PageDataWire<MusicAlbumWire> = {
        list: [{ guid: 'album-1', name: '测试专辑', trackCount: '12' }],
        total: '37'
      };
      const artistData: PageDataWire<MusicArtistWire> = {
        list: [{ guid: 'artist-1', name: '测试歌手', trackCount: '24', albumCount: 3 }],
        total: 18
      };
      const albumPage = pageFromWire<MusicAlbumWire, MusicAlbum>(albumData, musicAlbumFromWire);
      const artistPage = pageFromWire<MusicArtistWire, MusicArtist>(artistData, musicArtistFromWire);
      expect(albumPage.total).assertEqual(37);
      expect(albumPage.list[0].trackCount).assertEqual(12);
      expect(artistPage.total).assertEqual(18);
      expect(artistPage.list[0].trackCount).assertEqual(24);
      expect(artistPage.list[0].albumCount).assertEqual(3);
    });

    it('keepsBusinessErrorsVisible', 0, () => {
      let errorKind: ApiErrorKind = ApiErrorKind.PARSE;
      let businessCode: number = 0;
      try {
        parseApiEnvelope<object>('{"code":120001,"msg":"bad credentials"}');
      } catch (error) {
        const apiError = error as ApiError;
        errorKind = apiError.kind;
        businessCode = apiError.businessCode;
      }
      expect(errorKind).assertEqual(ApiErrorKind.BUSINESS);
      expect(businessCode).assertEqual(120001);
    });

    it('rejectsMissingData', 0, () => {
      let kind: ApiErrorKind = ApiErrorKind.NETWORK;
      try {
        parseApiEnvelope<object>('{"code":0,"msg":"ok"}');
      } catch (error) {
        kind = (error as ApiError).kind;
      }
      expect(kind).assertEqual(ApiErrorKind.PARSE);
    });

    it('doesNotTreatInvalidTokenAsEmptyData', 0, () => {
      let kind: ApiErrorKind = ApiErrorKind.NETWORK;
      try {
        parseApiEnvelope<object>('{"code":401,"msg":"INVALID TOKEN"}');
      } catch (error) {
        kind = (error as ApiError).kind;
      }
      expect(kind).assertEqual(ApiErrorKind.UNAUTHORIZED);
    });

    it('hashesPasswordWithSha256', 0, () => {
      expect(FeiniuMusicApi.sha256Hex('abc'))
        .assertEqual('ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
    });

    it('normalizesBaseUrl', 0, () => {
      expect(FeiniuMusicApi.normalizeBaseUrl(' https://demo.example/ ')).assertEqual('https://demo.example');
    });

    it('buildsAuthenticatedPlaybackContract', 0, () => {
      const api = new FeiniuMusicApi();
      api.setEndpoint('https://demo.example/', true);
      api.setToken('token value');
      expect(api.streamUrl('track/1'))
        .assertEqual('https://demo.example/music/api/v1/track/stream?guid=track%2F1');
      expect(api.playbackHeaders().Cookie).assertEqual('music-token=token value; mode=relay');
      expect(Object.keys(api.playbackHeaders()).indexOf('mode')).assertEqual(-1);
    });

    it('keepsRelayModeCookieDuringPasswordLogin', 0, () => {
      const api = new FeiniuMusicApi();
      api.setEndpoint('https://demo.5ddd.com', true);
      expect(api.loginHeaders().Cookie).assertEqual('mode=relay');
      api.setToken('old-token');
      expect(api.loginHeaders().Cookie).assertEqual('mode=relay');
    });

    it('buildsFnConnectCandidatesLikeTheWorkingFnosClient', 0, () => {
      const data: FnConnectResolveData = {
        ipv4: ['192.168.1.2'],
        ipv6: ['fd00::2'],
        publicIpv4: ['203.0.113.2'],
        publicIpv6: ['2001:db8::2'],
        fn: ['demo.5ddd.com'],
        port: { httpPort: 5666, httpsPort: 5667 }
      };
      const urls = buildFnConnectCandidates('demo', data)
        .map((candidate) => candidate.baseUrl);
      expect(urls.indexOf('http://192.168.1.2:5666') >= 0).assertTrue();
      expect(urls.indexOf('https://203.0.113.2:5667') >= 0).assertTrue();
      expect(urls.indexOf('https://[2001:db8::2]:5667') >= 0).assertTrue();
      expect(urls.indexOf('https://demo.5ddd.com:5667') >= 0).assertTrue();
      expect(urls.indexOf('https://192.168.1.2:5667')).assertEqual(-1);
      expect(urls.indexOf('http://203.0.113.2:5666')).assertEqual(-1);
      expect(urls.indexOf('http://[2001:db8::2]:5666')).assertEqual(-1);
      expect(urls.find((url: string) => url.indexOf('fd00::2') >= 0)).assertUndefined();
      expect(normalizeRelayBaseUrl('https://demo.5ddd.com:443/')).assertEqual('https://demo.5ddd.com');
      expect(normalizeRelayBaseUrl('https://demo.5ddd.com:8443/')).assertEqual('https://demo.5ddd.com:8443');
      expect(normalizeRelayBaseUrl('demo.5ddd.com', 5667)).assertEqual('https://demo.5ddd.com:5667');
    });

    it('distinguishesFnConnectInputsFromDirectServerAddresses', 0, () => {
      expect(isFnConnectInput('demo')).assertTrue();
      expect(isFnConnectInput('5ddd.com/demo')).assertTrue();
      expect(isFnConnectInput('https://demo.5ddd.com')).assertTrue();
      expect(isFnConnectInput('https://demo.fnos.net:443')).assertTrue();
      expect(isFnConnectInput('nas.example.com')).assertFalse();
      expect(isFnConnectInput('192.168.1.8')).assertFalse();
      expect(isFnConnectInput('https://nas.example.com:443')).assertFalse();
    });

    it('normalizesDirectServerAddressesWithoutFnConnectResolution', 0, () => {
      expect(normalizeDirectBaseUrl('nas.example.com')).assertEqual('http://nas.example.com:5666');
      expect(normalizeDirectBaseUrl('192.168.1.8:8080')).assertEqual('http://192.168.1.8:8080');
      expect(normalizeDirectBaseUrl('https://nas.example.com')).assertEqual('https://nas.example.com:5667');
      expect(normalizeDirectBaseUrl('https://nas.example.com:443')).assertEqual('https://nas.example.com:443');
      expect(normalizeDirectBaseUrl('fd00::8')).assertEqual('http://[fd00::8]:5666');
    });

    it('buildsFnConnectSignature', 0, () => {
      expect(buildFnConnectSignature('test-fnid', '1700000000000'))
        .assertEqual('aaaf6ff35a5b10d291d23d0efc1f3ab017721347e72867dd6a1d588b21948141');
    });

    it('mapsNetworkKitLoginFailures', 0, () => {
      expect(FeiniuMusicApi.networkErrorMessage(2300060, ''))
        .assertEqual('服务器 SSL 证书无效或已过期');
      expect(FeiniuMusicApi.networkErrorMessage(2300028, ''))
        .assertEqual('连接服务器超时');
    });
  });
}
