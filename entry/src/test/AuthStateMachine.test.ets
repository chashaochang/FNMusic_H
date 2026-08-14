import { describe, expect, it } from '@ohos/hypium';
import { MusicUser } from '../main/ets/model/MusicModels';
import { ApiError, ApiErrorKind } from '../main/ets/network/ApiError';
import { LoginResult } from '../main/ets/network/FeiniuMusicApi';
import {
  AuthenticationApi,
  AuthStore,
  ConnectionResolver,
  CredentialStorage
} from '../main/ets/auth/AuthStore';
import {
  AuthPhase,
  ConnectionCandidate,
  ConnectionResolution,
  ConnectionRoute,
  LoginCredentials,
  StoredConnection
} from '../main/ets/auth/ConnectionModels';
import { StoredAuthSecrets } from '../main/ets/auth/CredentialVault';
import { FnConnectOptions } from '../main/ets/auth/FnConnectService';

class FakeAuthApi implements AuthenticationApi {
  token: string = '';
  accessCode: string = '';
  loginCount: number = 0;
  verifyError?: ApiError;
  loginError?: ApiError;

  setEndpoint(_baseUrl: string, _relayMode: boolean): void {
  }

  setToken(token: string): void {
    this.token = token;
  }

  setAccessCode(_accessCode: string): void {
    this.accessCode = _accessCode;
  }

  async login(username: string, _password: string, _deviceId: string): Promise<LoginResult> {
    this.loginCount += 1;
    if (this.loginError !== undefined) {
      throw this.loginError;
    }
    return this.loginResult(username, `token-${this.loginCount}`);
  }

  protected loginResult(username: string, token: string): LoginResult {
    const result = new LoginResult();
    result.token = token;
    result.user = new MusicUser();
    result.user.name = username;
    result.user.role = 'user';
    result.user.userToken = result.token;
    return result;
  }

  async verifySession(): Promise<void> {
    if (this.verifyError !== undefined) {
      throw this.verifyError;
    }
  }
}

class EndpointFailureAuthApi extends FakeAuthApi {
  private currentEndpoint: string = '';
  private endpoints: string[] = [];
  private failures: Error[] = [];

  constructor(endpoints: string[], failures: Error[]) {
    super();
    this.endpoints = endpoints;
    this.failures = failures;
  }

  setEndpoint(baseUrl: string, _relayMode: boolean): void {
    this.currentEndpoint = baseUrl;
  }

  async login(username: string, _password: string, _deviceId: string): Promise<LoginResult> {
    this.loginCount += 1;
    const index = this.endpoints.indexOf(this.currentEndpoint);
    if (index >= 0 && index < this.failures.length) {
      throw this.failures[index];
    }
    return this.loginResult(username, `token-${this.loginCount}`);
  }
}

class TrackingVerifyAuthApi extends FakeAuthApi {
  private currentEndpoint: string = '';
  verifiedEndpoints: string[] = [];

  setEndpoint(baseUrl: string, _relayMode: boolean): void {
    this.currentEndpoint = baseUrl;
  }

  async verifySession(): Promise<void> {
    this.verifiedEndpoints.push(this.currentEndpoint);
  }
}

class DeferredLoginAuthApi extends FakeAuthApi {
  readonly loginStarted: Promise<void>;
  private notifyLoginStarted?: () => void;
  private resolveLogin?: (result: LoginResult) => void;
  private pendingUsername: string = '';

  constructor() {
    super();
    this.loginStarted = new Promise<void>((resolve: () => void) => {
      this.notifyLoginStarted = resolve;
    });
  }

  login(username: string, _password: string, _deviceId: string): Promise<LoginResult> {
    this.loginCount += 1;
    this.pendingUsername = username;
    this.notifyLoginStarted?.();
    return new Promise<LoginResult>((resolve: (result: LoginResult) => void) => {
      this.resolveLogin = resolve;
    });
  }

  completeLogin(token: string): void {
    this.resolveLogin?.(this.loginResult(this.pendingUsername, token));
  }
}

class DeferredVerifyAuthApi extends FakeAuthApi {
  readonly verificationStarted: Promise<void>;
  private notifyVerificationStarted?: () => void;
  private resolveVerification?: () => void;

  constructor() {
    super();
    this.verificationStarted = new Promise<void>((resolve: () => void) => {
      this.notifyVerificationStarted = resolve;
    });
  }

  verifySession(): Promise<void> {
    this.notifyVerificationStarted?.();
    return new Promise<void>((resolve: () => void) => {
      this.resolveVerification = resolve;
    });
  }

  completeVerification(): void {
    this.resolveVerification?.();
  }
}

class DeferredValue {
  readonly request: Promise<string>;
  private resolveRequest?: (value: string) => void;

  constructor() {
    this.request = new Promise<string>((resolve: (value: string) => void) => {
      this.resolveRequest = resolve;
    });
  }

  resolve(value: string): void {
    this.resolveRequest?.(value);
  }
}

class FakeResolver implements ConnectionResolver {
  lastOptions: FnConnectOptions = new FnConnectOptions();

  async resolve(_rawFnId: string, _options: FnConnectOptions): Promise<ConnectionResolution> {
    this.lastOptions = _options;
    const result = new ConnectionResolution();
    result.fnId = 'demo';
    result.preferred = new ConnectionCandidate();
    result.preferred.baseUrl = 'https://demo.5ddd.com';
    result.preferred.route = ConnectionRoute.RELAY;
    result.preferred.reachable = true;
    return result;
  }
}

class MultiCandidateResolver implements ConnectionResolver {
  private candidates: ConnectionCandidate[] = [];

  constructor(baseUrls: string[]) {
    baseUrls.forEach((baseUrl: string, index: number) => {
      const candidate = new ConnectionCandidate();
      candidate.baseUrl = baseUrl;
      candidate.route = index === 0 ? ConnectionRoute.RELAY : ConnectionRoute.PUBLIC;
      candidate.reachable = true;
      this.candidates.push(candidate);
    });
  }

  async resolve(_rawFnId: string, _options: FnConnectOptions): Promise<ConnectionResolution> {
    const result = new ConnectionResolution();
    result.fnId = 'demo';
    if (this.candidates.length > 0) {
      result.preferred = this.candidates[0].clone();
    }
    for (let index = 1; index < this.candidates.length; index++) {
      result.fallbacks.push(this.candidates[index].clone());
    }
    return result;
  }
}

class FakeVault implements CredentialStorage {
  secrets: StoredAuthSecrets = new StoredAuthSecrets();
  connection: StoredConnection = new StoredConnection();
  saveLoginCount: number = 0;
  clearSessionCount: number = 0;
  lastKeepAccount: boolean = true;

  async loadSecrets(): Promise<StoredAuthSecrets> {
    return this.secrets;
  }

  async saveLogin(credentials: LoginCredentials, token: string, user: MusicUser): Promise<void> {
    this.saveLoginCount += 1;
    this.secrets.credentials = credentials.clone();
    this.secrets.token = token;
    this.secrets.user = user;
  }

  loadConnection(): StoredConnection {
    return this.connection;
  }

  async saveConnection(connection: StoredConnection): Promise<void> {
    this.connection = connection;
  }

  async deviceId(): Promise<string> {
    return '00112233445566778899aabbccddeeff';
  }

  async clearSession(keepAccount: boolean = true): Promise<void> {
    this.clearSessionCount += 1;
    this.lastKeepAccount = keepAccount;
    this.secrets.token = '';
    this.secrets.user.userToken = '';
    if (!keepAccount) {
      this.secrets.credentials = new LoginCredentials();
      this.secrets.user = new MusicUser();
      this.connection = new StoredConnection();
    }
  }
}

class DeferredSaveVault extends FakeVault {
  readonly saveStarted: Promise<void>;
  private notifySaveStarted?: () => void;
  private releaseSave?: () => void;

  constructor() {
    super();
    this.saveStarted = new Promise<void>((resolve: () => void) => {
      this.notifySaveStarted = resolve;
    });
  }

  async saveLogin(credentials: LoginCredentials, token: string, user: MusicUser): Promise<void> {
    this.notifySaveStarted?.();
    await new Promise<void>((resolve: () => void) => {
      this.releaseSave = resolve;
    });
    await super.saveLogin(credentials, token, user);
  }

  completeSave(): void {
    this.releaseSave?.();
  }
}

class FailingSaveVault extends FakeVault {
  async saveLogin(_credentials: LoginCredentials, _token: string, _user: MusicUser): Promise<void> {
    this.saveLoginCount += 1;
    throw new Error('Preferences unavailable');
  }
}

function credentials(username: string = 'tester'): LoginCredentials {
  const value = new LoginCredentials();
  value.fnId = 'demo';
  value.username = username;
  value.password = 'secret';
  value.accessCode = 'access-code';
  return value;
}

function savedSession(vault: FakeVault): void {
  vault.connection.fnId = 'demo';
  vault.secrets.credentials = credentials();
  vault.secrets.token = 'saved-token';
  vault.secrets.user.name = 'tester';
  vault.secrets.user.role = 'user';
  vault.secrets.user.userToken = 'saved-token';
}

export default function authStateMachineTest(): void {
  describe('AuthStateMachine', () => {
    it('signsInAndPersistsSession', 0, async () => {
      const api = new FakeAuthApi();
      const vault = new FakeVault();
      vault.connection.fnId = 'demo';
      const store = new AuthStore(api, new FakeResolver(), vault);
      expect(await store.signIn(credentials())).assertTrue();
      expect(store.snapshot().phase).assertEqual(AuthPhase.AUTHENTICATED);
      expect(vault.secrets.token).assertEqual('token-1');
    });

    it('doesNotRetryAnotherCandidateAfterLocalPersistenceFails', 0, async () => {
      const endpoints = ['https://relay.example', 'https://public.example'];
      const api = new FakeAuthApi();
      const vault = new FailingSaveVault();
      vault.connection.fnId = 'demo';
      const store = new AuthStore(api, new MultiCandidateResolver(endpoints), vault);
      expect(await store.signIn(credentials())).assertFalse();
      expect(api.loginCount).assertEqual(1);
      expect(vault.saveLoginCount).assertEqual(1);
      expect(store.snapshot().message).assertEqual('登录成功，但安全保存失败，请重试');
    });

    it('surfacesTheCandidateLoginFailure', 0, async () => {
      const api = new FakeAuthApi();
      api.loginError = new ApiError(ApiErrorKind.NETWORK, '服务器 SSL 证书无效或已过期', 0, 0, 2300060);
      const vault = new FakeVault();
      vault.connection.fnId = 'demo';
      const store = new AuthStore(api, new FakeResolver(), vault);
      expect(await store.signIn(credentials())).assertFalse();
      expect(store.snapshot().message).assertEqual('登录失败：服务器 SSL 证书无效或已过期');
    });

    it('prefersHigherPriorityFailureAcrossCandidates', 0, async () => {
      const endpoints = ['https://relay.example', 'https://lan.example', 'https://public.example'];
      const api = new EndpointFailureAuthApi(endpoints, [
        new ApiError(ApiErrorKind.NETWORK, '网络超时'),
        new ApiError(ApiErrorKind.PARSE, '服务器响应无法解析'),
        new ApiError(ApiErrorKind.HTTP, 'upstream unavailable', 503)
      ]);
      const vault = new FakeVault();
      vault.connection.fnId = 'demo';
      const store = new AuthStore(api, new MultiCandidateResolver(endpoints), vault);
      expect(await store.signIn(credentials())).assertFalse();
      expect(api.loginCount).assertEqual(3);
      expect(store.snapshot().message).assertEqual('登录失败：服务器返回 HTTP 503');
    });

    it('doesNotReplaceHigherPriorityFailureWithLaterNetworkError', 0, async () => {
      const endpoints = ['https://relay.example', 'https://public.example'];
      const api = new EndpointFailureAuthApi(endpoints, [
        new ApiError(ApiErrorKind.HTTP, 'bad gateway', 502),
        new ApiError(ApiErrorKind.NETWORK, '连接被拒绝')
      ]);
      const vault = new FakeVault();
      vault.connection.fnId = 'demo';
      const store = new AuthStore(api, new MultiCandidateResolver(endpoints), vault);
      expect(await store.signIn(credentials())).assertFalse();
      expect(api.loginCount).assertEqual(2);
      expect(store.snapshot().message).assertEqual('登录失败：服务器返回 HTTP 502');
    });

    it('keepsFirstFailureWhenCandidatesSharePriority', 0, async () => {
      const endpoints = ['https://relay.example', 'https://public.example'];
      const api = new EndpointFailureAuthApi(endpoints, [
        new ApiError(ApiErrorKind.PARSE, '第一个地址返回异常'),
        new ApiError(ApiErrorKind.PARSE, '第二个地址返回异常')
      ]);
      const vault = new FakeVault();
      vault.connection.fnId = 'demo';
      const store = new AuthStore(api, new MultiCandidateResolver(endpoints), vault);
      expect(await store.signIn(credentials())).assertFalse();
      expect(api.loginCount).assertEqual(2);
      expect(store.snapshot().message).assertEqual('登录失败：第一个地址返回异常');
    });

    it('doesNotReuseSavedAddressForAnotherFnId', 0, async () => {
      const api = new FakeAuthApi();
      const vault = new FakeVault();
      vault.connection.fnId = 'old-device';
      vault.connection.lastSuccessfulBaseUrl = 'https://old-device.example';
      vault.connection.candidateBaseUrls = ['https://old-device.example'];
      const resolver = new FakeResolver();
      const store = new AuthStore(api, resolver, vault);
      expect(await store.signIn(credentials())).assertTrue();
      expect(resolver.lastOptions.recentSuccessfulBaseUrl).assertEqual('');
      expect(vault.connection.fnId).assertEqual('demo');
      expect(vault.connection.candidateBaseUrls.indexOf('https://old-device.example')).assertEqual(-1);
    });

    it('restoresSavedTokenWithoutRelogin', 0, async () => {
      const api = new FakeAuthApi();
      const vault = new FakeVault();
      savedSession(vault);
      vault.secrets.credentials.password = '';
      const store = new AuthStore(api, new FakeResolver(), vault);
      expect(await store.restore()).assertTrue();
      expect(api.loginCount).assertEqual(0);
      expect(store.snapshot().phase).assertEqual(AuthPhase.AUTHENTICATED);
    });

    it('prefersFreshlyResolvedAddressOverStoredVpnAddressDuringRestore', 0, async () => {
      const currentAddress = 'https://current-reachable.example';
      const storedVpnAddress = 'https://vpn-only.example';
      const api = new TrackingVerifyAuthApi();
      const vault = new FakeVault();
      savedSession(vault);
      vault.secrets.credentials.password = '';
      vault.connection.lastSuccessfulBaseUrl = storedVpnAddress;
      vault.connection.candidateBaseUrls = [storedVpnAddress];
      const store = new AuthStore(api, new MultiCandidateResolver([currentAddress]), vault);

      expect(await store.restore()).assertTrue();
      expect(api.verifiedEndpoints.length).assertEqual(1);
      expect(api.verifiedEndpoints[0]).assertEqual(currentAddress);
    });

    it('returnsToLoginQuietlyWhenNoRestorableSessionExists', 0, async () => {
      const api = new FakeAuthApi();
      const vault = new FakeVault();
      vault.connection.fnId = 'demo';
      vault.secrets.credentials.fnId = 'demo';
      vault.secrets.credentials.username = 'tester';
      const store = new AuthStore(api, new FakeResolver(), vault);
      expect(await store.restore()).assertFalse();
      expect(api.loginCount).assertEqual(0);
      expect(store.snapshot().phase).assertEqual(AuthPhase.SIGNED_OUT);
      expect(store.snapshot().message).assertEqual('');
    });

    it('relogsOnceAfterUnauthorized', 0, async () => {
      const api = new FakeAuthApi();
      const vault = new FakeVault();
      savedSession(vault);
      const store = new AuthStore(api, new FakeResolver(), vault);
      expect(await store.restore()).assertTrue();
      let calls: number = 0;
      const result = await store.withAutoReconnect<string>(async () => {
        calls += 1;
        if (calls === 1) {
          throw new ApiError(ApiErrorKind.UNAUTHORIZED, 'expired', 401);
        }
        return 'ok';
      });
      expect(result).assertEqual('ok');
      expect(calls).assertEqual(2);
      expect(api.loginCount).assertEqual(1);
    });

    it('forgetsAccountOnExplicitLogout', 0, async () => {
      const api = new FakeAuthApi();
      const vault = new FakeVault();
      vault.secrets.credentials.fnId = 'demo';
      vault.secrets.credentials.username = 'tester';
      vault.secrets.credentials.password = 'secret';
      const store = new AuthStore(api, new FakeResolver(), vault);
      await store.signOut(true);
      expect(store.snapshot().phase).assertEqual(AuthPhase.SIGNED_OUT);
      expect(vault.secrets.token).assertEqual('');
      expect(vault.secrets.credentials.username).assertEqual('');
      expect(api.token).assertEqual('');
      expect(api.accessCode).assertEqual('');
      expect(store.user().name).assertEqual('');
    });

    it('invalidatesLoginThatCompletesAfterSignOut', 0, async () => {
      const api = new DeferredLoginAuthApi();
      const vault = new FakeVault();
      vault.connection.fnId = 'demo';
      const store = new AuthStore(api, new FakeResolver(), vault);
      const signInRequest = store.signIn(credentials('late-user'));
      await api.loginStarted;
      await store.signOut(true);
      api.completeLogin('late-token');
      expect(await signInRequest).assertFalse();
      expect(store.snapshot().phase).assertEqual(AuthPhase.SIGNED_OUT);
      expect(store.user().name).assertEqual('');
      expect(api.token).assertEqual('');
      expect(api.accessCode).assertEqual('');
      expect(vault.saveLoginCount).assertEqual(0);
      expect(vault.secrets.token).assertEqual('');
    });

    it('keepsLogoutCleanupAfterPendingCredentialSave', 0, async () => {
      const api = new FakeAuthApi();
      const vault = new DeferredSaveVault();
      vault.connection.fnId = 'demo';
      const store = new AuthStore(api, new FakeResolver(), vault);
      const signInRequest = store.signIn(credentials('pending-save'));
      await vault.saveStarted;
      const signOutRequest = store.signOut(true);
      vault.completeSave();
      expect(await signInRequest).assertFalse();
      await signOutRequest;
      expect(store.snapshot().phase).assertEqual(AuthPhase.SIGNED_OUT);
      expect(vault.saveLoginCount).assertEqual(1);
      expect(vault.clearSessionCount).assertEqual(1);
      expect(vault.secrets.token).assertEqual('');
      expect(vault.secrets.credentials.username).assertEqual('');
    });

    it('invalidatesTokenRestoreThatCompletesAfterSignOut', 0, async () => {
      const api = new DeferredVerifyAuthApi();
      const vault = new FakeVault();
      savedSession(vault);
      const store = new AuthStore(api, new FakeResolver(), vault);
      const restoreRequest = store.restore();
      await api.verificationStarted;
      await store.signOut(true);
      api.completeVerification();
      expect(await restoreRequest).assertFalse();
      expect(store.snapshot().phase).assertEqual(AuthPhase.SIGNED_OUT);
      expect(store.user().name).assertEqual('');
      expect(api.token).assertEqual('');
      expect(vault.secrets.token).assertEqual('');
    });

    it('invalidatesReconnectThatCompletesAfterSignOut', 0, async () => {
      const api = new DeferredLoginAuthApi();
      const vault = new FakeVault();
      savedSession(vault);
      const store = new AuthStore(api, new FakeResolver(), vault);
      expect(await store.restore()).assertTrue();
      let operationCount: number = 0;
      let rejected: boolean = false;
      const request = store.withAutoReconnect<string>(async () => {
        operationCount += 1;
        if (operationCount === 1) {
          throw new ApiError(ApiErrorKind.UNAUTHORIZED, 'expired', 401);
        }
        return 'stale-data';
      });
      await api.loginStarted;
      await store.signOut(true);
      api.completeLogin('late-reconnect-token');
      try {
        await request;
      } catch (_) {
        rejected = true;
      }
      expect(rejected).assertTrue();
      expect(operationCount).assertEqual(1);
      expect(store.snapshot().phase).assertEqual(AuthPhase.SIGNED_OUT);
      expect(store.user().name).assertEqual('');
      expect(api.token).assertEqual('');
      expect(vault.saveLoginCount).assertEqual(0);
    });

    it('rejectsAuthenticatedDataThatArrivesAfterSignOut', 0, async () => {
      const api = new FakeAuthApi();
      const vault = new FakeVault();
      savedSession(vault);
      const store = new AuthStore(api, new FakeResolver(), vault);
      expect(await store.restore()).assertTrue();
      const deferred = new DeferredValue();
      let rejected: boolean = false;
      const request = store.withAutoReconnect<string>(() => deferred.request);
      await store.signOut(true);
      deferred.resolve('stale-library-data');
      try {
        await request;
      } catch (_) {
        rejected = true;
      }
      expect(rejected).assertTrue();
      expect(store.snapshot().phase).assertEqual(AuthPhase.SIGNED_OUT);
    });

    it('clearsSessionWhenAutomaticReconnectFails', 0, async () => {
      const api = new FakeAuthApi();
      const vault = new FakeVault();
      savedSession(vault);
      const store = new AuthStore(api, new FakeResolver(), vault);
      expect(await store.restore()).assertTrue();
      api.loginError = new ApiError(ApiErrorKind.NETWORK, 'offline');
      expect(await store.recoverUnauthorized()).assertFalse();
      expect(store.snapshot().phase).assertEqual(AuthPhase.SIGNED_OUT);
      expect(store.user().name).assertEqual('');
      expect(api.token).assertEqual('');
      expect(api.accessCode).assertEqual('');
      expect(vault.secrets.token).assertEqual('');
      expect(vault.lastKeepAccount).assertTrue();
    });
  });
}
