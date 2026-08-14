import { MusicUser } from '../model/MusicModels';
import { ApiError, ApiErrorKind } from '../network/ApiError';
import { LoginResult } from '../network/FeiniuMusicApi';
import {
  AuthPhase,
  AuthSnapshot,
  ConnectionCandidate,
  ConnectionResolution,
  ConnectionRoute,
  LoginCredentials,
  StoredConnection
} from './ConnectionModels';
import { StoredAuthSecrets } from './CredentialVault';
import { FnConnectOptions } from './FnConnectService';

/** Network contract injected to keep the authentication state machine locally testable. */
export interface AuthenticationApi {
  setEndpoint(baseUrl: string, relayMode: boolean): void;
  setToken(token: string): void;
  setAccessCode(accessCode: string): void;
  login(username: string, password: string, deviceId: string): Promise<LoginResult>;
  verifySession(): Promise<void>;
}

export interface ConnectionResolver {
  resolve(rawFnId: string, options: FnConnectOptions): Promise<ConnectionResolution>;
}

export interface CredentialStorage {
  loadSecrets(): Promise<StoredAuthSecrets>;
  saveLogin(credentials: LoginCredentials, token: string, user: MusicUser): Promise<void>;
  loadConnection(): StoredConnection;
  saveConnection(connection: StoredConnection): Promise<void>;
  deviceId(): Promise<string>;
  clearSession(keepAccount?: boolean): Promise<void>;
}

/** State sink used by the application shell or a V2 wrapper component. */
export type AuthListener = (snapshot: AuthSnapshot) => void;

enum LoginAttemptResult {
  FAILED,
  SUCCESS,
  CREDENTIAL_REJECTED,
  LOCAL_STORAGE_FAILED,
  INVALIDATED
}

const STARTUP_SESSION_VERIFY_TIMEOUT_MS: number = 2600;

/** Login, startup restore and bounded 401 recovery coordinator. */
export class AuthStore {
  private readonly api: AuthenticationApi;
  private readonly connector: ConnectionResolver;
  private readonly vault: CredentialStorage;
  private readonly listeners: AuthListener[] = [];
  private currentSnapshot: AuthSnapshot = new AuthSnapshot();
  private credentials: LoginCredentials = new LoginCredentials();
  private currentToken: string = '';
  private currentUser: MusicUser = new MusicUser();
  private authSessionGeneration: number = 0;
  private reconnecting?: Promise<boolean>;
  private reconnectingGeneration: number = -1;
  private storageMutation: Promise<void> = Promise.resolve();
  private lastLoginFailureMessage: string = '';
  private lastLoginFailurePriority: number = 0;

  constructor(api: AuthenticationApi, connector: ConnectionResolver, vault: CredentialStorage) {
    this.api = api;
    this.connector = connector;
    this.vault = vault;
  }

  snapshot(): AuthSnapshot {
    return this.currentSnapshot.clone();
  }

  user(): MusicUser {
    const value = new MusicUser();
    value.guid = this.currentUser.guid;
    value.name = this.currentUser.name;
    value.role = this.currentUser.role;
    value.userToken = this.currentUser.userToken;
    return value;
  }

  deviceId(): Promise<string> {
    return this.vault.deviceId();
  }

  /** Identifies the logical account session that owns authenticated data. */
  sessionGeneration(): number {
    return this.authSessionGeneration;
  }

  isSessionActive(generation: number): boolean {
    return generation === this.authSessionGeneration && this.currentSnapshot.phase === AuthPhase.AUTHENTICATED;
  }

  addListener(listener: AuthListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  removeListener(listener: AuthListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  async restore(): Promise<boolean> {
    const generation = this.beginAuthenticationSession();
    this.publish(AuthPhase.RESTORING, '正在恢复登录状态', false, '', '', '');
    let secrets: StoredAuthSecrets;
    try {
      await this.storageMutation;
      if (!this.isCurrentGeneration(generation)) {
        return false;
      }
      secrets = await this.vault.loadSecrets();
    } catch (_) {
      if (this.invalidateCurrentSession(generation, AuthPhase.SIGNED_OUT, '本地凭据无法读取，请重新登录', false)) {
        await this.enqueueStorageMutation((): Promise<void> => this.vault.clearSession(false));
      }
      return false;
    }
    if (!this.isCurrentGeneration(generation)) {
      return false;
    }
    if (secrets.credentials.fnId.trim().length === 0 || secrets.credentials.username.trim().length === 0) {
      this.invalidateCurrentSession(generation, AuthPhase.SIGNED_OUT, '', false);
      return false;
    }
    this.credentials = secrets.credentials.clone();
    if (secrets.token.trim().length === 0 && secrets.credentials.password.length === 0) {
      this.invalidateCurrentSession(generation, AuthPhase.SIGNED_OUT, '', false);
      return false;
    }
    const connection = this.vault.loadConnection();
    const candidates = await this.resolveCandidates(connection, generation, secrets.credentials.fnId);
    if (!this.isCurrentGeneration(generation)) {
      return false;
    }
    if (secrets.token.trim().length > 0 && await this.tryToken(candidates, secrets, generation)) {
      return true;
    }
    if (!this.isCurrentGeneration(generation)) {
      return false;
    }
    let loginResult = LoginAttemptResult.FAILED;
    if (secrets.credentials.password.length > 0) {
      loginResult = await this.tryLogin(candidates, secrets.credentials, generation);
    }
    if (loginResult === LoginAttemptResult.SUCCESS) {
      return true;
    }
    if (loginResult === LoginAttemptResult.INVALIDATED || !this.isCurrentGeneration(generation)) {
      return false;
    }
    const message = loginResult === LoginAttemptResult.CREDENTIAL_REJECTED ? '保存的登录信息已失效，请重新登录' :
      (loginResult === LoginAttemptResult.LOCAL_STORAGE_FAILED ? '登录成功，但安全保存失败，请重新登录' :
        '无法连接服务器，请检查网络或重新登录');
    if (this.invalidateCurrentSession(generation, AuthPhase.ERROR, message, true)) {
      await this.enqueueStorageMutation((): Promise<void> => this.vault.clearSession(true));
    }
    return false;
  }

  async signIn(credentials: LoginCredentials): Promise<boolean> {
    const normalized = credentials.clone();
    normalized.fnId = normalized.fnId.trim();
    normalized.username = normalized.username.trim();
    if (normalized.fnId.length === 0 || normalized.username.length === 0 || normalized.password.length === 0) {
      this.publish(AuthPhase.ERROR, '请完整填写服务器地址、用户名和密码', true);
      return false;
    }
    const generation = this.beginAuthenticationSession();
    this.credentials = normalized.clone();
    const connection = this.vault.loadConnection();
    if (connection.fnId.trim().toLowerCase() !== normalized.fnId.toLowerCase()) {
      connection.fnId = normalized.fnId;
      connection.lastSuccessfulBaseUrl = '';
      connection.candidateBaseUrls = [];
    }
    const candidates = await this.resolveCandidates(connection, generation, normalized.fnId);
    if (!this.isCurrentGeneration(generation)) {
      return false;
    }
    const loginResult = await this.tryLogin(candidates, normalized, generation);
    if (loginResult === LoginAttemptResult.SUCCESS) {
      return true;
    }
    if (loginResult === LoginAttemptResult.INVALIDATED || !this.isCurrentGeneration(generation)) {
      return false;
    }
    const message = loginResult === LoginAttemptResult.CREDENTIAL_REJECTED ? '用户名或密码错误' :
      (loginResult === LoginAttemptResult.LOCAL_STORAGE_FAILED ? '登录成功，但安全保存失败，请重试' :
        (this.lastLoginFailureMessage.length > 0 ? `登录失败：${this.lastLoginFailureMessage}` :
          '未获取到可用服务器地址'));
    this.invalidateCurrentSession(generation, AuthPhase.ERROR, message, true);
    return false;
  }

  /** Called after an authenticated request reports 401. Only one re-login may run at a time. */
  async recoverUnauthorized(): Promise<boolean> {
    return await this.recoverUnauthorizedForGeneration(this.authSessionGeneration);
  }

  private async recoverUnauthorizedForGeneration(generation: number): Promise<boolean> {
    if (this.reconnecting !== undefined && this.reconnectingGeneration === generation) {
      return await this.reconnecting;
    }
    if (!this.isSessionActive(generation)) {
      return false;
    }
    const request = this.recoverUnauthorizedOnce(generation);
    this.reconnecting = request;
    this.reconnectingGeneration = generation;
    try {
      return await request;
    } finally {
      if (this.reconnecting === request) {
        this.reconnecting = undefined;
        this.reconnectingGeneration = -1;
      }
    }
  }

  /** Runs one authenticated operation and retries it once after a successful bounded re-login. */
  async withAutoReconnect<T>(operation: () => Promise<T>): Promise<T> {
    const generation = this.authSessionGeneration;
    this.requireActiveSession(generation);
    try {
      const result = await operation();
      this.requireActiveSession(generation);
      return result;
    } catch (error) {
      this.requireCurrentGeneration(generation);
      if (!AuthStore.isUnauthorized(error as Error) ||
        !(await this.recoverUnauthorizedForGeneration(generation))) {
        const message = (error as Error).message;
        throw new Error(message.length > 0 ? message : '认证请求失败');
      }
      this.requireCurrentGeneration(generation);
      const result = await operation();
      this.requireActiveSession(generation);
      return result;
    }
  }

  async signOut(forgetAccount: boolean = false): Promise<void> {
    this.authSessionGeneration += 1;
    this.clearInMemorySession();
    this.publish(AuthPhase.SIGNED_OUT, '', false, '', '', '');
    await this.enqueueStorageMutation((): Promise<void> => this.vault.clearSession(!forgetAccount));
  }

  private async recoverUnauthorizedOnce(generation: number): Promise<boolean> {
    if (this.credentials.password.length === 0) {
      await this.storageMutation;
      if (!this.isCurrentGeneration(generation)) {
        return false;
      }
      const secrets = await this.vault.loadSecrets();
      if (!this.isCurrentGeneration(generation)) {
        return false;
      }
      this.credentials = secrets.credentials.clone();
    }
    if (this.credentials.password.length === 0) {
      await this.failAutomaticAuthentication(generation);
      return false;
    }
    const connection = this.vault.loadConnection();
    const credentials = this.credentials.clone();
    const candidates = await this.resolveCandidates(connection, generation, credentials.fnId);
    if (!this.isCurrentGeneration(generation)) {
      return false;
    }
    const result = await this.tryLogin(candidates, credentials, generation);
    if (result === LoginAttemptResult.SUCCESS) {
      return true;
    }
    if (result !== LoginAttemptResult.INVALIDATED) {
      await this.failAutomaticAuthentication(generation);
    }
    return false;
  }

  private async resolveCandidates(connection: StoredConnection, generation: number,
    fnId: string): Promise<ConnectionCandidate[]> {
    if (!this.isCurrentGeneration(generation)) {
      return [];
    }
    this.publish(AuthPhase.RESOLVING, '正在查找服务器', false, '', '', '');
    const previous = this.storedCandidates(connection);
    const resolvedFnId = connection.fnId.trim().length > 0 ? connection.fnId : fnId;
    try {
      const options = new FnConnectOptions();
      options.preference = connection.preference;
      options.p2pEnabled = connection.p2pEnabled;
      options.recentSuccessfulBaseUrl = connection.lastSuccessfulBaseUrl;
      const result = await this.connector.resolve(resolvedFnId, options);
      if (!this.isCurrentGeneration(generation)) {
        return [];
      }
      return this.mergeCandidates(result.allCandidates(), previous);
    } catch (_) {
      return this.isCurrentGeneration(generation) ? previous : [];
    }
  }

  private async tryToken(candidates: ConnectionCandidate[], secrets: StoredAuthSecrets,
    generation: number): Promise<boolean> {
    for (let index = 0; index < candidates.length; index++) {
      if (!this.isCurrentGeneration(generation)) {
        return false;
      }
      const candidate = candidates[index];
      this.configureApi(candidate, secrets.credentials.accessCode, secrets.token);
      this.publish(AuthPhase.CONNECTING, '正在验证登录状态', false, candidate.baseUrl, '', '');
      try {
        await this.withTimeout(this.api.verifySession(), STARTUP_SESSION_VERIFY_TIMEOUT_MS, '启动登录校验超时');
        if (!this.isCurrentGeneration(generation)) {
          return false;
        }
        const user = AuthStore.cloneUser(secrets.user);
        if (user.name.length === 0) {
          user.name = secrets.credentials.username;
        }
        user.userToken = secrets.token;
        await this.persistSuccessfulConnection(candidate, candidates, secrets.credentials.fnId, generation);
        if (!this.isCurrentGeneration(generation)) {
          return false;
        }
        this.currentToken = secrets.token;
        this.currentUser = user;
        this.api.setToken(secrets.token);
        this.publishAuthenticated(candidate.baseUrl);
        return true;
      } catch (error) {
        if (!this.isCurrentGeneration(generation)) {
          return false;
        }
        if (!AuthStore.isUnauthorized(error) && index === candidates.length - 1) {
          this.publish(AuthPhase.OFFLINE, '服务器暂时不可用', true);
        }
      }
    }
    return false;
  }

  private async tryLogin(candidates: ConnectionCandidate[], credentials: LoginCredentials,
    generation: number): Promise<LoginAttemptResult> {
    this.lastLoginFailureMessage = '';
    this.lastLoginFailurePriority = 0;
    const deviceId = await this.vault.deviceId();
    if (!this.isCurrentGeneration(generation)) {
      return LoginAttemptResult.INVALIDATED;
    }
    for (let index = 0; index < candidates.length; index++) {
      if (!this.isCurrentGeneration(generation)) {
        return LoginAttemptResult.INVALIDATED;
      }
      const candidate = candidates[index];
      this.configureApi(candidate, credentials.accessCode, '');
      this.publish(AuthPhase.AUTHENTICATING, '正在登录', false, candidate.baseUrl, '', '');
      let result: LoginResult;
      try {
        result = await this.api.login(credentials.username, credentials.password, deviceId);
      } catch (error) {
        if (!this.isCurrentGeneration(generation)) {
          return LoginAttemptResult.INVALIDATED;
        }
        if (AuthStore.isCredentialRejected(error as Error)) {
          return LoginAttemptResult.CREDENTIAL_REJECTED;
        }
        const failure = AuthStore.loginFailureMessage(error as Error);
        const priority = AuthStore.failurePriority(error as Error);
        if (this.lastLoginFailureMessage.length === 0 || priority > this.lastLoginFailurePriority) {
          this.lastLoginFailureMessage = failure;
          this.lastLoginFailurePriority = priority;
        }
        console.warn(`[AuthStore] Login candidate ${index + 1}/${candidates.length} (${candidate.route}) failed: ${failure}`);
        continue;
      }
      if (!this.isCurrentGeneration(generation)) {
        return LoginAttemptResult.INVALIDATED;
      }
      try {
        await this.enqueueStorageMutation(async (): Promise<void> => {
          if (this.isCurrentGeneration(generation)) {
            await this.vault.saveLogin(credentials, result.token, result.user);
          }
        });
        if (!this.isCurrentGeneration(generation)) {
          return LoginAttemptResult.INVALIDATED;
        }
        await this.persistSuccessfulConnection(candidate, candidates, credentials.fnId, generation);
        if (!this.isCurrentGeneration(generation)) {
          return LoginAttemptResult.INVALIDATED;
        }
        this.credentials = credentials.clone();
        this.currentToken = result.token;
        this.currentUser = AuthStore.cloneUser(result.user);
        this.currentUser.userToken = result.token;
        this.api.setToken(result.token);
        this.publishAuthenticated(candidate.baseUrl);
        return LoginAttemptResult.SUCCESS;
      } catch (error) {
        if (!this.isCurrentGeneration(generation)) {
          return LoginAttemptResult.INVALIDATED;
        }
        const message = (error as Error).message ?? '';
        console.warn(`[AuthStore] Local persistence failed after successful login (${candidate.route}): ${message}`);
        return LoginAttemptResult.LOCAL_STORAGE_FAILED;
      }
    }
    return LoginAttemptResult.FAILED;
  }

  private configureApi(candidate: ConnectionCandidate, accessCode: string, token: string): void {
    this.api.setEndpoint(candidate.baseUrl, candidate.route === ConnectionRoute.RELAY);
    this.api.setAccessCode(accessCode);
    this.api.setToken(token);
  }

  private async persistSuccessfulConnection(candidate: ConnectionCandidate, candidates: ConnectionCandidate[],
    fnId: string, generation: number): Promise<void> {
    await this.enqueueStorageMutation(async (): Promise<void> => {
      if (!this.isCurrentGeneration(generation)) {
        return;
      }
      const stored = this.vault.loadConnection();
      stored.fnId = fnId;
      stored.lastSuccessfulBaseUrl = candidate.baseUrl;
      stored.lastSuccessfulRoute = candidate.route;
      stored.candidateBaseUrls = candidates.map((value: ConnectionCandidate) => value.baseUrl);
      await this.vault.saveConnection(stored);
    });
  }

  private storedCandidates(connection: StoredConnection): ConnectionCandidate[] {
    const values: ConnectionCandidate[] = [];
    const append = (baseUrl: string, route: ConnectionRoute): void => {
      const normalized = baseUrl.trim().replace(/\/$/, '');
      if (normalized.length === 0 ||
        values.find((value: ConnectionCandidate) => value.baseUrl === normalized) !== undefined) {
        return;
      }
      const candidate = new ConnectionCandidate();
      candidate.baseUrl = normalized;
      candidate.route = route;
      values.push(candidate);
    };
    append(connection.lastSuccessfulBaseUrl, connection.lastSuccessfulRoute);
    connection.candidateBaseUrls.forEach((baseUrl: string) => {
      append(baseUrl, AuthStore.routeForUrl(baseUrl, connection));
    });
    return values;
  }

  private mergeCandidates(first: ConnectionCandidate[], second: ConnectionCandidate[]): ConnectionCandidate[] {
    const values: ConnectionCandidate[] = [];
    first.concat(second).forEach((candidate: ConnectionCandidate) => {
      if (candidate.baseUrl.length > 0 &&
        values.find((value: ConnectionCandidate) => value.baseUrl === candidate.baseUrl) === undefined) {
        values.push(candidate.clone());
      }
    });
    return values;
  }

  private publishAuthenticated(baseUrl: string): void {
    this.publish(AuthPhase.AUTHENTICATED, '', false, baseUrl, this.currentUser.name, this.currentUser.role);
  }

  private beginAuthenticationSession(): number {
    this.authSessionGeneration += 1;
    this.clearInMemorySession();
    return this.authSessionGeneration;
  }

  private invalidateCurrentSession(generation: number, phase: AuthPhase, message: string,
    canRetry: boolean): boolean {
    if (!this.isCurrentGeneration(generation)) {
      return false;
    }
    this.authSessionGeneration += 1;
    this.clearInMemorySession();
    this.publish(phase, message, canRetry, '', '', '');
    return true;
  }

  private async failAutomaticAuthentication(generation: number): Promise<void> {
    if (!this.invalidateCurrentSession(generation, AuthPhase.SIGNED_OUT, '登录已失效，请重新登录', false)) {
      return;
    }
    await this.enqueueStorageMutation((): Promise<void> => this.vault.clearSession(true));
  }

  private clearInMemorySession(): void {
    this.api.setToken('');
    this.api.setAccessCode('');
    this.credentials = new LoginCredentials();
    this.currentToken = '';
    this.currentUser = new MusicUser();
  }

  private isCurrentGeneration(generation: number): boolean {
    return generation === this.authSessionGeneration;
  }

  private requireCurrentGeneration(generation: number): void {
    if (!this.isCurrentGeneration(generation)) {
      throw new Error('登录会话已失效');
    }
  }

  private requireActiveSession(generation: number): void {
    if (!this.isSessionActive(generation)) {
      throw new Error('登录会话已失效');
    }
  }

  private enqueueStorageMutation(operation: () => Promise<void>): Promise<void> {
    const request = this.storageMutation.then(operation, operation);
    this.storageMutation = request.then((): void => {}, (): void => {});
    return request;
  }

  private withTimeout<T>(request: Promise<T>, timeoutMs: number, message: string): Promise<T> {
    return new Promise<T>((resolve: (value: T) => void, reject: (reason?: Error) => void) => {
      let settled: boolean = false;
      const timer: number = setTimeout((): void => {
        if (settled) {
          return;
        }
        settled = true;
        reject(new Error(message));
      }, timeoutMs);
      request.then((value: T): void => {
        if (settled) {
          return;
        }
        settled = true;
        clearTimeout(timer);
        resolve(value);
      }).catch((error: Error): void => {
        if (settled) {
          return;
        }
        settled = true;
        clearTimeout(timer);
        reject(error);
      });
    });
  }

  private publish(phase: AuthPhase, message: string, canRetry: boolean, baseUrl: string = '',
    username: string = this.currentSnapshot.username, role: string = this.currentSnapshot.role): void {
    const value = new AuthSnapshot();
    value.phase = phase;
    value.message = message;
    value.canRetry = canRetry;
    value.baseUrl = baseUrl;
    value.username = username;
    value.role = role;
    this.currentSnapshot = value;
    this.listeners.slice().forEach((listener: AuthListener) => listener(value.clone()));
  }

  static isUnauthorized(error: Error): boolean {
    return error instanceof ApiError && error.kind === ApiErrorKind.UNAUTHORIZED;
  }

  static isCredentialRejected(error: Error): boolean {
    return error instanceof ApiError && error.kind === ApiErrorKind.BUSINESS && error.businessCode === 120001;
  }

  private static failurePriority(error: Error): number {
    if (!(error instanceof ApiError)) {
      return 1;
    }
    if (error.kind === ApiErrorKind.BUSINESS) {
      return 5;
    }
    if (error.kind === ApiErrorKind.HTTP || error.kind === ApiErrorKind.UNAUTHORIZED) {
      return 4;
    }
    if (error.kind === ApiErrorKind.PARSE) {
      return 3;
    }
    return 2;
  }

  private static loginFailureMessage(error: Error): string {
    if (error instanceof ApiError) {
      if (error.kind === ApiErrorKind.HTTP && error.httpStatus > 0) {
        return `服务器返回 HTTP ${error.httpStatus}`;
      }
      if (error.kind === ApiErrorKind.PARSE) {
        return error.message.length > 0 ? error.message : '服务器响应无法解析';
      }
    }
    return error.message.length > 0 ? error.message : '网络连接异常';
  }

  private static cloneUser(user: MusicUser): MusicUser {
    const value = new MusicUser();
    value.guid = user.guid;
    value.name = user.name;
    value.role = user.role;
    value.userToken = user.userToken;
    return value;
  }

  private static routeForUrl(baseUrl: string, connection: StoredConnection): ConnectionRoute {
    if (baseUrl === connection.lastSuccessfulBaseUrl) {
      return connection.lastSuccessfulRoute;
    }
    if (baseUrl.indexOf('.5ddd.com') >= 0 || baseUrl.indexOf('.fnos.net') >= 0) {
      return ConnectionRoute.RELAY;
    }
    return ConnectionRoute.PUBLIC;
  }
}
