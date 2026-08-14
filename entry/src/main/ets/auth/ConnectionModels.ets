/** Available FN Connect route families. */
export enum ConnectionRoute {
  LAN = 'lan',
  PUBLIC = 'public',
  RELAY = 'relay'
}

/** User-selected route ordering policy. */
export enum ConnectionPreference {
  SPEED = 'speed',
  PUBLIC = 'public',
  RELAY = 'relay'
}

/** One address that can be tried for a server. */
export class ConnectionCandidate {
  baseUrl: string = '';
  route: ConnectionRoute = ConnectionRoute.RELAY;
  reachable: boolean = false;
  elapsedMs: number = 0;

  clone(): ConnectionCandidate {
    const result = new ConnectionCandidate();
    result.baseUrl = this.baseUrl;
    result.route = this.route;
    result.reachable = this.reachable;
    result.elapsedMs = this.elapsedMs;
    return result;
  }
}

/** Result of resolving and probing one FN Connect identifier. */
export class ConnectionResolution {
  fnId: string = '';
  preferred: ConnectionCandidate = new ConnectionCandidate();
  fallbacks: ConnectionCandidate[] = [];

  allCandidates(): ConnectionCandidate[] {
    const values: ConnectionCandidate[] = [];
    if (this.preferred.baseUrl.length > 0) {
      values.push(this.preferred.clone());
    }
    this.fallbacks.forEach((candidate: ConnectionCandidate) => {
      if (values.find((value: ConnectionCandidate) => value.baseUrl === candidate.baseUrl) === undefined) {
        values.push(candidate.clone());
      }
    });
    return values;
  }
}

/** User-entered login fields. */
export class LoginCredentials {
  fnId: string = '';
  username: string = '';
  password: string = '';
  accessCode: string = '';

  clone(): LoginCredentials {
    const value = new LoginCredentials();
    value.fnId = this.fnId;
    value.username = this.username;
    value.password = this.password;
    value.accessCode = this.accessCode;
    return value;
  }
}

/** Persisted server routing information. */
export class StoredConnection {
  fnId: string = '';
  lastSuccessfulBaseUrl: string = '';
  lastSuccessfulRoute: ConnectionRoute = ConnectionRoute.RELAY;
  candidateBaseUrls: string[] = [];
  preference: ConnectionPreference = ConnectionPreference.SPEED;
  p2pEnabled: boolean = true;
}

/** Authentication lifecycle exposed to the application shell. */
export enum AuthPhase {
  IDLE = 'idle',
  RESTORING = 'restoring',
  RESOLVING = 'resolving',
  CONNECTING = 'connecting',
  AUTHENTICATING = 'authenticating',
  AUTHENTICATED = 'authenticated',
  OFFLINE = 'offline',
  SIGNED_OUT = 'signed_out',
  ERROR = 'error'
}

/** Immutable snapshot suitable for a UI store wrapper. */
export class AuthSnapshot {
  phase: AuthPhase = AuthPhase.IDLE;
  message: string = '';
  baseUrl: string = '';
  username: string = '';
  role: string = '';
  canRetry: boolean = false;

  clone(): AuthSnapshot {
    const value = new AuthSnapshot();
    value.phase = this.phase;
    value.message = this.message;
    value.baseUrl = this.baseUrl;
    value.username = this.username;
    value.role = this.role;
    value.canRetry = this.canRetry;
    return value;
  }
}
