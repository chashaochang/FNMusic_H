import { http } from '@kit.NetworkKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';
import { FeiniuMusicApi } from '../network/FeiniuMusicApi';
import {
  ConnectionCandidate,
  ConnectionPreference,
  ConnectionResolution,
  ConnectionRoute
} from './ConnectionModels';

export interface FnConnectPortInfo {
  httpPort?: number;
  httpsPort?: number;
}

export interface FnConnectResolveData {
  ipv4?: string[];
  ipv6?: string[];
  publicIpv4?: string[];
  publicIpv6?: string[];
  fn?: string[];
  port?: FnConnectPortInfo;
}

interface FnConnectResolveEnvelope {
  code?: number;
  msg?: string;
  data?: FnConnectResolveData;
}

interface FnConnectResolveRequest {
  fnId: string;
}

interface ProbeRequestHeaders {
  Accept: string;
  Cookie?: string;
}

class FnConnectDigest {
  private static readonly encoder: util.TextEncoder = new util.TextEncoder();

  static hex(algorithm: string, value: string): string {
    const digest = cryptoFramework.createMd(algorithm);
    digest.updateSync({ data: FnConnectDigest.encoder.encodeInto(value) });
    const bytes = digest.digestSync().data;
    let result = '';
    bytes.forEach((byte: number) => {
      result += byte.toString(16).padStart(2, '0');
    });
    return result;
  }
}

export function buildFnConnectSignature(fnId: string, timestamp: string): string {
  return FeiniuMusicApi.sha256Hex(`trim_connect\`${fnId}\`${timestamp}\`anna`);
}

function hasExplicitPort(value: string): boolean {
  const authority = value.split('/')[0];
  if (authority.startsWith('[')) {
    return /\]:\d+$/.test(authority);
  }
  if ((authority.match(/:/g) ?? []).length > 1) {
    return false;
  }
  const colonIndex = authority.lastIndexOf(':');
  if (colonIndex <= 0) {
    return false;
  }
  return /^\d+$/.test(authority.substring(colonIndex + 1));
}

function isRelayPath(value: string): boolean {
  return /^5ddd\.com\/[^/]+$/i.test(value);
}

function isRelayDomain(value: string): boolean {
  return /(^|\/)[^/]*\.fnos\.net(?::\d+)?$/i.test(value) ||
    /\.fnos\.net(?::\d+)?(\/|$)/i.test(value) ||
    /(^|\/)[^/]*\.5ddd\.com(?::\d+)?$/i.test(value) ||
    /\.5ddd\.com(?::\d+)?(\/|$)/i.test(value);
}

export function isFnConnectInput(value: string): boolean {
  const normalized = value.trim();
  if (normalized.length === 0) {
    return false;
  }
  if (/^[A-Za-z0-9_-]+$/.test(normalized)) {
    return true;
  }
  const withoutScheme = normalized.replace(/^[a-z]+:\/\//i, '').replace(/\/$/, '');
  return isRelayPath(withoutScheme) || isRelayDomain(withoutScheme);
}

export function normalizeDirectBaseUrl(value: string): string {
  let normalized = value.trim().replace(/\/$/, '');
  if (normalized.length === 0) {
    return '';
  }
  if (normalized.startsWith('ws://')) {
    normalized = `http://${normalized.substring('ws://'.length)}`;
  } else if (normalized.startsWith('wss://')) {
    normalized = `https://${normalized.substring('wss://'.length)}`;
  }
  let scheme = 'http://';
  if (normalized.startsWith('https://')) {
    scheme = 'https://';
    normalized = normalized.substring('https://'.length);
  } else if (normalized.startsWith('http://')) {
    normalized = normalized.substring('http://'.length);
  }
  const slashIndex = normalized.indexOf('/');
  let authority = slashIndex >= 0 ? normalized.substring(0, slashIndex) : normalized;
  const suffix = slashIndex >= 0 ? normalized.substring(slashIndex) : '';
  if (authority.indexOf(':') >= 0 && !authority.startsWith('[') && !hasExplicitPort(authority)) {
    authority = `[${authority}]`;
  }
  if (authority.length === 0) {
    return '';
  }
  if (!hasExplicitPort(authority)) {
    authority = `${authority}:${scheme === 'https://' ? 5667 : 5666}`;
  }
  return `${scheme}${authority}${suffix}`;
}

export function normalizeRelayBaseUrl(value: string, httpsPort: number = 5667): string {
  let normalized = value.trim().replace(/\/$/, '');
  if (normalized.startsWith('https://')) {
    normalized = normalized.substring('https://'.length);
  } else if (normalized.startsWith('http://')) {
    normalized = normalized.substring('http://'.length);
  }
  let hostAndPort = normalized.split('/')[0];
  if (hostAndPort.endsWith(':443')) {
    hostAndPort = hostAndPort.replace(/:443$/, '');
  } else if (!hasExplicitPort(hostAndPort) && hostAndPort.length > 0) {
    hostAndPort = `${hostAndPort}:${httpsPort}`;
  }
  return hostAndPort.length > 0 ? `https://${hostAndPort}` : '';
}

/** Builds the same LAN, public and relay candidates used by the working HarmonyOS fnOS client. */
export function buildFnConnectCandidates(fnId: string, data: FnConnectResolveData): ConnectionCandidate[] {
  const httpPort = data.port?.httpPort ?? 5666;
  const httpsPort = data.port?.httpsPort ?? 5667;
  const candidates: ConnectionCandidate[] = [];
  const append = (baseUrl: string, route: ConnectionRoute): void => {
    const normalized = baseUrl.trim().replace(/\/$/, '');
    if (normalized.length === 0 ||
      candidates.find((candidate: ConnectionCandidate) => candidate.baseUrl === normalized) !== undefined) {
      return;
    }
    const candidate = new ConnectionCandidate();
    candidate.baseUrl = normalized;
    candidate.route = route;
    candidates.push(candidate);
  };
  const appendLanIpv4 = (address: string): void => {
    const host = address.trim();
    if (host.length > 0) {
      append(`http://${host}:${httpPort}`, ConnectionRoute.LAN);
    }
  };
  const appendPublicIpv4 = (address: string): void => {
    const host = address.trim();
    if (host.length > 0) {
      append(`https://${host}:${httpsPort}`, ConnectionRoute.PUBLIC);
    }
  };
  const appendPublicIpv6 = (address: string): void => {
    const host = address.trim();
    if (host.length > 0) {
      append(`https://[${host}]:${httpsPort}`, ConnectionRoute.PUBLIC);
    }
  };
  (data.ipv4 ?? []).forEach((address: string) => appendLanIpv4(address));
  (data.publicIpv4 ?? []).forEach((address: string) => appendPublicIpv4(address));
  (data.publicIpv6 ?? []).forEach((address: string) => appendPublicIpv6(address));
  (data.fn ?? []).forEach((address: string) =>
    append(normalizeRelayBaseUrl(address, httpsPort), ConnectionRoute.RELAY));
  return candidates;
}

class FnConnectCacheItem {
  result: ConnectionResolution = new ConnectionResolution();
  expiresAt: number = 0;
}

/** User-controlled FN Connect routing behavior. */
export class FnConnectOptions {
  preference: ConnectionPreference = ConnectionPreference.SPEED;
  p2pEnabled: boolean = true;
  recentSuccessfulBaseUrl: string = '';
}

/** FN Connect implementation migrated from the user-approved local HarmonyOS project. */
export class FnConnectService {
  private static readonly API_URL: string = 'https://5ddd.com/api/v1/fn/con';
  private static readonly AUTHX_PREFIX: string = 'NDzZTVxnRKP8Z0jXg1VAMonaG8akvh';
  private static readonly AUTHX_API_KEY: string = 'zIGtkc3dqZnJpd29qZXJqa2w7c';
  private static readonly CACHE_DURATION_MS: number = 30000;
  private static readonly cache: Map<string, FnConnectCacheItem> = new Map<string, FnConnectCacheItem>();
  private static readonly pending: Map<string, Promise<ConnectionResolution>> =
    new Map<string, Promise<ConnectionResolution>>();

  async resolve(rawInput: string, options: FnConnectOptions = new FnConnectOptions()): Promise<ConnectionResolution> {
    const normalizedInput = rawInput.trim();
    if (normalizedInput.length === 0) {
      throw new Error('服务器地址不能为空');
    }
    if (!isFnConnectInput(normalizedInput)) {
      return this.directResolution(normalizedInput);
    }
    const fnId = FnConnectService.extractFnId(normalizedInput);
    if (fnId.length === 0) {
      throw new Error('FN Connect 标识不能为空');
    }
    const key = `${fnId}:${options.preference}:${options.p2pEnabled}`;
    const cached = FnConnectService.cache.get(key);
    if (cached !== undefined && cached.expiresAt > Date.now()) {
      return this.cloneResolution(cached.result);
    }
    const existing = FnConnectService.pending.get(key);
    if (existing !== undefined) {
      return this.cloneResolution(await existing);
    }
    const request = this.resolveRemote(fnId, options);
    FnConnectService.pending.set(key, request);
    try {
      const result = await request;
      const item = new FnConnectCacheItem();
      item.result = this.cloneResolution(result);
      item.expiresAt = Date.now() + FnConnectService.CACHE_DURATION_MS;
      FnConnectService.cache.set(key, item);
      return this.cloneResolution(result);
    } finally {
      FnConnectService.pending.delete(key);
    }
  }

  static clearCache(): void {
    FnConnectService.cache.clear();
    FnConnectService.pending.clear();
  }

  private async resolveRemote(fnId: string, options: FnConnectOptions): Promise<ConnectionResolution> {
    const payload: FnConnectResolveRequest = { fnId: fnId };
    const timestamp = `${Date.now()}`;
    const client = http.createHttp();
    try {
      const response = await client.request(FnConnectService.API_URL, {
        method: http.RequestMethod.POST,
        expectDataType: http.HttpDataType.STRING,
        readTimeout: 15000,
        connectTimeout: 10000,
        usingCache: false,
        maxRedirects: 3,
        header: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'fn-sign': buildFnConnectSignature(fnId, timestamp),
          'authx': this.authx('/api/v1/fn/con', payload)
        },
        body: JSON.stringify(payload)
      });
      const text = FnConnectService.responseText(response.result);
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`FN Connect 服务返回 HTTP ${response.responseCode}`);
      }
      let envelope: FnConnectResolveEnvelope;
      try {
        envelope = JSON.parse(text) as FnConnectResolveEnvelope;
      } catch (_) {
        throw new Error('FN Connect 返回了无法解析的数据');
      }
      if (envelope.code !== 0 || envelope.data === undefined) {
        throw new Error((envelope.msg ?? '').trim().length > 0 ? `${envelope.msg}` : 'FN Connect 解析失败');
      }
      return await this.pickTargets(fnId, envelope.data, options);
    } catch (error) {
      const message = (error as Error).message;
      const fallback = await this.buildRelayFallback(fnId, options);
      if (fallback.preferred.baseUrl.length > 0) {
        return fallback;
      }
      throw new Error(message.length > 0 ? message : 'FN Connect 解析失败');
    } finally {
      client.destroy();
    }
  }

  private async buildRelayFallback(fnId: string, options: FnConnectOptions): Promise<ConnectionResolution> {
    const candidates: ConnectionCandidate[] = [];
    this.appendCandidate(candidates, `https://${fnId}.5ddd.com`, ConnectionRoute.RELAY);
    this.appendCandidate(candidates, `https://${fnId}.fnos.net`, ConnectionRoute.RELAY);
    return await this.probeAndOrder(fnId, candidates, options);
  }

  private directResolution(rawInput: string): ConnectionResolution {
    const baseUrl = normalizeDirectBaseUrl(rawInput);
    if (baseUrl.length === 0) {
      throw new Error('服务器地址无效');
    }
    const result = new ConnectionResolution();
    result.fnId = rawInput;
    result.preferred.baseUrl = baseUrl;
    result.preferred.route = ConnectionRoute.LAN;
    result.preferred.reachable = true;
    return result;
  }

  private async pickTargets(fnId: string, data: FnConnectResolveData,
    options: FnConnectOptions): Promise<ConnectionResolution> {
    let candidates = buildFnConnectCandidates(fnId, data);
    if (!options.p2pEnabled) {
      const nonPublic = candidates.filter((candidate: ConnectionCandidate) => candidate.route !== ConnectionRoute.PUBLIC);
      candidates = nonPublic.length > 0 ? nonPublic : candidates;
    }
    if (candidates.length === 0) {
      throw new Error('FN Connect 没有返回可用地址');
    }
    return await this.probeAndOrder(fnId, candidates, options);
  }

  private async probeAndOrder(fnId: string, candidates: ConnectionCandidate[],
    options: FnConnectOptions): Promise<ConnectionResolution> {
    const probes = await Promise.all(candidates.map((candidate: ConnectionCandidate) => this.probe(candidate)));
    probes.sort((left: ConnectionCandidate, right: ConnectionCandidate) => {
      if (left.reachable !== right.reachable) {
        return left.reachable ? -1 : 1;
      }
      if (options.preference === ConnectionPreference.SPEED && left.reachable && right.reachable) {
        return left.elapsedMs - right.elapsedMs;
      }
      const routeDiff = this.routePriority(left.route, options.preference) -
        this.routePriority(right.route, options.preference);
      if (routeDiff !== 0) {
        return routeDiff;
      }
      const recentDiff = this.recentPriority(left.baseUrl, options.recentSuccessfulBaseUrl) -
        this.recentPriority(right.baseUrl, options.recentSuccessfulBaseUrl);
      if (recentDiff !== 0) {
        return recentDiff;
      }
      return left.elapsedMs - right.elapsedMs;
    });
    const result = new ConnectionResolution();
    result.fnId = fnId;
    if (probes.length > 0) {
      result.preferred = probes[0].clone();
      result.fallbacks = probes.slice(1).map((candidate: ConnectionCandidate) => candidate.clone());
    }
    return result;
  }

  private async probe(candidate: ConnectionCandidate): Promise<ConnectionCandidate> {
    const result = candidate.clone();
    const start = Date.now();
    const client = http.createHttp();
    try {
      const headers: ProbeRequestHeaders = {
        Accept: 'application/json,text/plain,*/*'
      };
      if (candidate.route === ConnectionRoute.RELAY) {
        headers.Cookie = 'mode=relay';
      }
      const response = await client.request(`${candidate.baseUrl}/license/v1/device/baseInfo`, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        readTimeout: 1800,
        connectTimeout: 1200,
        maxRedirects: 2,
        header: headers
      });
      result.reachable = response.responseCode >= 200 && response.responseCode < 500;
    } catch (_) {
      result.reachable = false;
    } finally {
      result.elapsedMs = Date.now() - start;
      client.destroy();
    }
    return result;
  }

  private appendCandidate(values: ConnectionCandidate[], baseUrl: string, route: ConnectionRoute): void {
    const normalized = baseUrl.trim().replace(/\/$/, '');
    if (normalized.length === 0 ||
      values.find((candidate: ConnectionCandidate) => candidate.baseUrl === normalized) !== undefined) {
      return;
    }
    const candidate = new ConnectionCandidate();
    candidate.baseUrl = normalized;
    candidate.route = route;
    values.push(candidate);
  }

  private routePriority(route: ConnectionRoute, preference: ConnectionPreference): number {
    if (preference === ConnectionPreference.PUBLIC) {
      return route === ConnectionRoute.PUBLIC ? 0 : (route === ConnectionRoute.RELAY ? 1 : 2);
    }
    if (preference === ConnectionPreference.RELAY) {
      return route === ConnectionRoute.RELAY ? 0 : (route === ConnectionRoute.PUBLIC ? 1 : 2);
    }
    return route === ConnectionRoute.LAN ? 0 : (route === ConnectionRoute.RELAY ? 1 : 2);
  }

  private recentPriority(candidate: string, recent: string): number {
    return recent.trim().length > 0 && candidate === recent.trim().replace(/\/$/, '') ? 0 : 1;
  }

  private authx(path: string, body: FnConnectResolveRequest): string {
    const nonce = `${Math.floor(Math.random() * 900000) + 100000}`;
    const timestamp = `${Date.now()}`;
    const bodyHash = FnConnectDigest.hex('MD5', JSON.stringify(body));
    const signature = FnConnectDigest.hex('MD5', [
      FnConnectService.AUTHX_PREFIX,
      path,
      nonce,
      timestamp,
      bodyHash,
      FnConnectService.AUTHX_API_KEY
    ].join('_'));
    return `nonce=${nonce}&timestamp=${timestamp}&sign=${signature}`;
  }

  private cloneResolution(source: ConnectionResolution): ConnectionResolution {
    const value = new ConnectionResolution();
    value.fnId = source.fnId;
    value.preferred = source.preferred.clone();
    value.fallbacks = source.fallbacks.map((candidate: ConnectionCandidate) => candidate.clone());
    return value;
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

  private static extractFnId(rawValue: string): string {
    const normalized = rawValue.trim()
      .replace(/^https?:\/\//i, '')
      .replace(/^wss?:\/\//i, '')
      .replace(/\/$/, '');
    if (normalized.startsWith('5ddd.com/')) {
      return normalized.substring('5ddd.com/'.length).split('/')[0];
    }
    const authority = normalized.split('/')[0].replace(/:\d+$/, '');
    if (authority.endsWith('.fnos.net')) {
      return authority.substring(0, authority.length - '.fnos.net'.length);
    }
    if (authority.endsWith('.5ddd.com')) {
      return authority.substring(0, authority.length - '.5ddd.com'.length);
    }
    return authority;
  }
}
