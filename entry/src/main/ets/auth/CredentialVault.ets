import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { preferences } from '@kit.ArkData';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { huks } from '@kit.UniversalKeystoreKit';
import { MusicUser } from '../model/MusicModels';
import {
  ConnectionPreference,
  ConnectionRoute,
  LoginCredentials,
  StoredConnection
} from './ConnectionModels';

const PREFERENCE_NAME: string = 'feiniu_music_auth';
const LEGACY_DIRECT_STORAGE_VERSION: number = 2;
const DIRECT_STORAGE_VERSION: number = 3;
const ENCRYPTED_VALUE_VERSION: number = 1;
const HUKS_KEY_ALIAS: string = 'cn.xiaobai.feiniumusic.credentials.aes256gcm.v1';
const GCM_IV_BYTE_LENGTH: number = 12;
const GCM_TAG_BYTE_LENGTH: number = 16;

enum SecretStorageMode {
  ENCRYPTED,
  LEGACY_PLAINTEXT
}

interface EncryptedValueEnvelope {
  version: number;
  iv: string;
  ciphertext: string;
  tag: string;
}

interface HuksOperationError extends Error {
  code?: number;
}

class EncryptedSecretValues {
  password: string = '';
  accessCode: string = '';
  token: string = '';
}

class VaultKeys {
  static readonly storageVersion: string = 'storage_version';
  static readonly fnId: string = 'fn_id';
  static readonly username: string = 'username';
  static readonly password: string = 'password_cipher';
  static readonly accessCode: string = 'access_code_cipher';
  static readonly token: string = 'token_cipher';
  static readonly userGuid: string = 'user_guid';
  static readonly userName: string = 'user_name';
  static readonly userRole: string = 'user_role';
  static readonly deviceId: string = 'device_id';
  static readonly lastBaseUrl: string = 'last_base_url';
  static readonly lastRoute: string = 'last_route';
  static readonly candidates: string = 'candidate_urls';
  static readonly routePreference: string = 'route_preference';
  static readonly p2pEnabled: string = 'p2p_enabled';
}

/** Credentials loaded only for the bounded automatic-login path. */
export class StoredAuthSecrets {
  credentials: LoginCredentials = new LoginCredentials();
  token: string = '';
  user: MusicUser = new MusicUser();
}

/** Stores ciphertext in Preferences while the non-exportable AES key remains in HUKS. */
export class CredentialVault {
  private readonly store: preferences.Preferences;
  private readonly encoder: util.TextEncoder = new util.TextEncoder();
  private readonly decoder: util.TextDecoder = util.TextDecoder.create('utf-8', { fatal: true });
  private readonly base64: util.Base64Helper = new util.Base64Helper();
  private keyAvailable: boolean = false;

  constructor(context: common.Context) {
    this.store = preferences.getPreferencesSync(context.getApplicationContext(), { name: PREFERENCE_NAME });
  }

  async loadSecrets(): Promise<StoredAuthSecrets> {
    const storageMode = await this.ensureDirectStorageVersion();
    const result = new StoredAuthSecrets();
    result.credentials.fnId = this.stringValue(VaultKeys.fnId);
    result.credentials.username = this.stringValue(VaultKeys.username);
    if (storageMode === SecretStorageMode.ENCRYPTED) {
      result.credentials.password = await this.decryptValue(VaultKeys.password,
        this.stringValue(VaultKeys.password));
      result.credentials.accessCode = await this.decryptValue(VaultKeys.accessCode,
        this.stringValue(VaultKeys.accessCode));
      result.token = await this.decryptValue(VaultKeys.token, this.stringValue(VaultKeys.token));
    } else {
      result.credentials.password = this.stringValue(VaultKeys.password);
      result.credentials.accessCode = this.stringValue(VaultKeys.accessCode);
      result.token = this.stringValue(VaultKeys.token);
    }
    result.user.guid = this.stringValue(VaultKeys.userGuid);
    result.user.name = this.stringValue(VaultKeys.userName);
    result.user.role = this.stringValue(VaultKeys.userRole);
    result.user.userToken = result.token;
    return result;
  }

  async saveLogin(credentials: LoginCredentials, token: string, user: MusicUser): Promise<void> {
    const secrets = await this.encryptSecretValues(credentials.password, credentials.accessCode, token.trim());
    this.store.putSync(VaultKeys.fnId, credentials.fnId.trim());
    this.store.putSync(VaultKeys.username, credentials.username.trim());
    this.store.putSync(VaultKeys.password, secrets.password);
    this.store.putSync(VaultKeys.accessCode, secrets.accessCode);
    this.store.putSync(VaultKeys.token, secrets.token);
    this.store.putSync(VaultKeys.userGuid, user.guid);
    this.store.putSync(VaultKeys.userName, user.name);
    this.store.putSync(VaultKeys.userRole, user.role);
    this.store.putSync(VaultKeys.storageVersion, DIRECT_STORAGE_VERSION);
    await this.store.flush();
  }

  async saveToken(token: string): Promise<void> {
    const storageMode = await this.ensureDirectStorageVersion();
    if (storageMode !== SecretStorageMode.ENCRYPTED) {
      throw new Error('HUKS credential migration is temporarily unavailable');
    }
    this.store.putSync(VaultKeys.token, await this.encryptValue(VaultKeys.token, token.trim()));
    this.store.putSync(VaultKeys.storageVersion, DIRECT_STORAGE_VERSION);
    await this.store.flush();
  }

  loadConnection(): StoredConnection {
    const value = new StoredConnection();
    value.fnId = this.stringValue(VaultKeys.fnId);
    value.lastSuccessfulBaseUrl = this.stringValue(VaultKeys.lastBaseUrl);
    value.lastSuccessfulRoute = this.routeValue(this.stringValue(VaultKeys.lastRoute));
    value.candidateBaseUrls = this.parseStringArray(this.stringValue(VaultKeys.candidates));
    value.preference = this.preferenceValue(this.stringValue(VaultKeys.routePreference));
    value.p2pEnabled = this.store.getSync(VaultKeys.p2pEnabled, true) as boolean;
    return value;
  }

  async saveConnection(connection: StoredConnection): Promise<void> {
    this.store.putSync(VaultKeys.fnId, connection.fnId.trim());
    this.store.putSync(VaultKeys.lastBaseUrl, connection.lastSuccessfulBaseUrl.trim());
    this.store.putSync(VaultKeys.lastRoute, connection.lastSuccessfulRoute);
    this.store.putSync(VaultKeys.candidates, JSON.stringify(connection.candidateBaseUrls));
    this.store.putSync(VaultKeys.routePreference, connection.preference);
    this.store.putSync(VaultKeys.p2pEnabled, connection.p2pEnabled);
    await this.store.flush();
  }

  async deviceId(): Promise<string> {
    const existing = this.stringValue(VaultKeys.deviceId).trim();
    if (/^[0-9a-f]{32}$/.test(existing)) {
      return existing;
    }
    const bytes = cryptoFramework.createRandom().generateRandomSync(16).data;
    const value = this.bytesToHex(bytes);
    this.store.putSync(VaultKeys.deviceId, value);
    await this.store.flush();
    return value;
  }

  async clearSession(keepAccount: boolean = true): Promise<void> {
    this.store.putSync(VaultKeys.token, '');
    if (!keepAccount) {
      this.store.putSync(VaultKeys.fnId, '');
      this.store.putSync(VaultKeys.username, '');
      this.store.putSync(VaultKeys.password, '');
      this.store.putSync(VaultKeys.accessCode, '');
      this.store.putSync(VaultKeys.userGuid, '');
      this.store.putSync(VaultKeys.userName, '');
      this.store.putSync(VaultKeys.userRole, '');
      this.store.putSync(VaultKeys.lastBaseUrl, '');
      this.store.putSync(VaultKeys.lastRoute, '');
      this.store.putSync(VaultKeys.candidates, '[]');
      this.store.putSync(VaultKeys.storageVersion, DIRECT_STORAGE_VERSION);
    }
    await this.store.flush();
    if (!keepAccount) {
      await this.deleteKeyIfPresent();
    }
  }

  private stringValue(key: string): string {
    return this.store.getSync(key, '') as string;
  }

  private routeValue(value: string): ConnectionRoute {
    if (value === ConnectionRoute.LAN || value === ConnectionRoute.PUBLIC || value === ConnectionRoute.RELAY) {
      return value as ConnectionRoute;
    }
    return ConnectionRoute.RELAY;
  }

  private preferenceValue(value: string): ConnectionPreference {
    if (value === ConnectionPreference.PUBLIC || value === ConnectionPreference.RELAY ||
      value === ConnectionPreference.SPEED) {
      return value as ConnectionPreference;
    }
    return ConnectionPreference.SPEED;
  }

  private parseStringArray(value: string): string[] {
    return CredentialVault.parseCandidateUrls(value);
  }

  private async ensureDirectStorageVersion(): Promise<SecretStorageMode> {
    const version = this.store.getSync(VaultKeys.storageVersion, 0) as number;
    if (version === DIRECT_STORAGE_VERSION) {
      return SecretStorageMode.ENCRYPTED;
    }
    if (version === LEGACY_DIRECT_STORAGE_VERSION) {
      return await this.migrateLegacyPlaintextSecrets() ? SecretStorageMode.ENCRYPTED :
        SecretStorageMode.LEGACY_PLAINTEXT;
    }
    if (version === 0 && this.sensitiveValuesAreEmpty()) {
      this.store.putSync(VaultKeys.storageVersion, DIRECT_STORAGE_VERSION);
      await this.store.flush();
      return SecretStorageMode.ENCRYPTED;
    }
    throw new Error(`Unsupported credential storage version: ${version}`);
  }

  private async migrateLegacyPlaintextSecrets(): Promise<boolean> {
    const password = this.stringValue(VaultKeys.password);
    const accessCode = this.stringValue(VaultKeys.accessCode);
    const token = this.stringValue(VaultKeys.token);
    let secrets: EncryptedSecretValues;
    try {
      secrets = await this.encryptSecretValues(password, accessCode, token);
    } catch (_) {
      return false;
    }
    try {
      this.store.putSync(VaultKeys.password, secrets.password);
      this.store.putSync(VaultKeys.accessCode, secrets.accessCode);
      this.store.putSync(VaultKeys.token, secrets.token);
      this.store.putSync(VaultKeys.storageVersion, DIRECT_STORAGE_VERSION);
      await this.store.flush();
      return true;
    } catch (_) {
      this.store.putSync(VaultKeys.password, password);
      this.store.putSync(VaultKeys.accessCode, accessCode);
      this.store.putSync(VaultKeys.token, token);
      this.store.putSync(VaultKeys.storageVersion, LEGACY_DIRECT_STORAGE_VERSION);
      try {
        await this.store.flush();
      } catch (_) {
      }
      return false;
    }
  }

  private async encryptSecretValues(password: string, accessCode: string,
    token: string): Promise<EncryptedSecretValues> {
    const result = new EncryptedSecretValues();
    result.password = await this.encryptValue(VaultKeys.password, password);
    result.accessCode = await this.encryptValue(VaultKeys.accessCode, accessCode);
    result.token = await this.encryptValue(VaultKeys.token, token);
    return result;
  }

  private async encryptValue(fieldKey: string, value: string): Promise<string> {
    if (value.length === 0) {
      return '';
    }
    await this.ensureEncryptionKey();
    const iv = cryptoFramework.createRandom().generateRandomSync(GCM_IV_BYTE_LENGTH).data;
    const properties = this.operationProperties(huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT, fieldKey, iv);
    const session = await huks.initSession(HUKS_KEY_ALIAS, { properties: properties });
    try {
      const result = await huks.finishSession(session.handle, {
        properties: properties,
        inData: this.encoder.encodeInto(value)
      });
      const combined = result.outData;
      if (combined === undefined || combined.length < GCM_TAG_BYTE_LENGTH) {
        throw new Error('HUKS returned an invalid AES-GCM payload');
      }
      const ciphertextLength = combined.length - GCM_TAG_BYTE_LENGTH;
      const envelope: EncryptedValueEnvelope = {
        version: ENCRYPTED_VALUE_VERSION,
        iv: this.base64.encodeToStringSync(iv),
        ciphertext: this.base64.encodeToStringSync(combined.slice(0, ciphertextLength)),
        tag: this.base64.encodeToStringSync(combined.slice(ciphertextLength))
      };
      return JSON.stringify(envelope);
    } catch (error) {
      await this.abortSessionQuietly(session.handle);
      throw new Error(this.errorMessage(error as Error, 'HUKS credential encryption failed'));
    }
  }

  private async decryptValue(fieldKey: string, value: string): Promise<string> {
    if (value.length === 0) {
      return '';
    }
    const envelope = this.parseEnvelope(value);
    const iv = this.base64.decodeSync(envelope.iv);
    const ciphertext = this.base64.decodeSync(envelope.ciphertext);
    const tag = this.base64.decodeSync(envelope.tag);
    if (iv.length !== GCM_IV_BYTE_LENGTH || tag.length !== GCM_TAG_BYTE_LENGTH) {
      throw new Error('Invalid encrypted credential parameters');
    }
    await this.requireExistingKey();
    const properties = this.operationProperties(huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT,
      fieldKey, iv, tag);
    const session = await huks.initSession(HUKS_KEY_ALIAS, { properties: properties });
    try {
      const result = await huks.finishSession(session.handle, {
        properties: properties,
        inData: ciphertext
      });
      if (result.outData === undefined) {
        throw new Error('HUKS returned no decrypted credential data');
      }
      return this.decoder.decodeToString(result.outData);
    } catch (error) {
      await this.abortSessionQuietly(session.handle);
      throw new Error(this.errorMessage(error as Error, 'HUKS credential decryption failed'));
    }
  }

  private operationProperties(purpose: huks.HuksKeyPurpose, fieldKey: string, iv: Uint8Array,
    tag?: Uint8Array): huks.HuksParam[] {
    const properties: huks.HuksParam[] = [
      { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
      { tag: huks.HuksTag.HUKS_TAG_KEY_SIZE, value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256 },
      { tag: huks.HuksTag.HUKS_TAG_PURPOSE, value: purpose },
      { tag: huks.HuksTag.HUKS_TAG_PADDING, value: huks.HuksKeyPadding.HUKS_PADDING_NONE },
      { tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE, value: huks.HuksCipherMode.HUKS_MODE_GCM },
      { tag: huks.HuksTag.HUKS_TAG_ASSOCIATED_DATA, value: this.encoder.encodeInto(fieldKey) },
      { tag: huks.HuksTag.HUKS_TAG_NONCE, value: iv }
    ];
    if (tag !== undefined) {
      properties.push({ tag: huks.HuksTag.HUKS_TAG_AE_TAG, value: tag });
    }
    return properties;
  }

  private keyGenerationOptions(): huks.HuksOptions {
    return {
      properties: [
        { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
        { tag: huks.HuksTag.HUKS_TAG_KEY_SIZE, value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256 },
        {
          tag: huks.HuksTag.HUKS_TAG_PURPOSE,
          value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT |
          huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT
        },
        { tag: huks.HuksTag.HUKS_TAG_PADDING, value: huks.HuksKeyPadding.HUKS_PADDING_NONE },
        { tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE, value: huks.HuksCipherMode.HUKS_MODE_GCM }
      ]
    };
  }

  private async ensureEncryptionKey(): Promise<void> {
    if (this.keyAvailable || await this.keyExists()) {
      this.keyAvailable = true;
      return;
    }
    try {
      await huks.generateKeyItem(HUKS_KEY_ALIAS, this.keyGenerationOptions());
    } catch (error) {
      if ((error as HuksOperationError).code !== 12000017) {
        throw new Error(this.errorMessage(error as Error, 'HUKS key generation failed'));
      }
    }
    this.keyAvailable = true;
  }

  private async requireExistingKey(): Promise<void> {
    if (this.keyAvailable || await this.keyExists()) {
      this.keyAvailable = true;
      return;
    }
    throw new Error('HUKS credential key is unavailable');
  }

  private async keyExists(): Promise<boolean> {
    try {
      return await huks.isKeyItemExist(HUKS_KEY_ALIAS, { properties: [] });
    } catch (error) {
      if ((error as HuksOperationError).code === 12000011) {
        return false;
      }
      throw new Error(this.errorMessage(error as Error, 'HUKS key lookup failed'));
    }
  }

  private async deleteKeyIfPresent(): Promise<void> {
    try {
      if (this.keyAvailable || await this.keyExists()) {
        await huks.deleteKeyItem(HUKS_KEY_ALIAS, { properties: [] });
      }
    } catch (_) {
    }
    this.keyAvailable = false;
  }

  private async abortSessionQuietly(handle: number): Promise<void> {
    try {
      await huks.abortSession(handle, { properties: [] });
    } catch (_) {
    }
  }

  private parseEnvelope(value: string): EncryptedValueEnvelope {
    try {
      const envelope = JSON.parse(value) as EncryptedValueEnvelope;
      if (envelope.version !== ENCRYPTED_VALUE_VERSION || envelope.iv.length === 0 ||
        envelope.tag.length === 0) {
        throw new Error('Invalid encrypted credential envelope');
      }
      return envelope;
    } catch (_) {
      throw new Error('Invalid encrypted credential envelope');
    }
  }

  private sensitiveValuesAreEmpty(): boolean {
    return this.stringValue(VaultKeys.password).length === 0 &&
      this.stringValue(VaultKeys.accessCode).length === 0 && this.stringValue(VaultKeys.token).length === 0;
  }

  private errorMessage(error: Error, fallback: string): string {
    return error.message.length > 0 ? error.message : fallback;
  }

  /** Pure parser exposed for local contract tests. */
  static parseCandidateUrls(value: string): string[] {
    if (value.trim().length === 0) {
      return [];
    }
    try {
      const parsed = JSON.parse(value) as string[];
      return parsed.filter((item: string) => item.trim().length > 0);
    } catch (_) {
      return [];
    }
  }

  private bytesToHex(bytes: Uint8Array): string {
    let result = '';
    bytes.forEach((value: number) => {
      result += value.toString(16).padStart(2, '0');
    });
    return result;
  }

}
