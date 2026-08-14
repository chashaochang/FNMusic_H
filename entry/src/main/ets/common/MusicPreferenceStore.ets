import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { AppStorageV2 } from '@kit.ArkUI';

const STORE_NAME: string = 'feiniu_music_preferences';
const MOTION_KEY: string = 'motion_enabled';
const AUTO_CONTINUE_KEY: string = 'auto_continue_enabled';
const LYRICS_KEY: string = 'lyrics_enabled';
const DESKTOP_LYRICS_KEY: string = 'desktop_lyrics_enabled';

@ObservedV2
export class MusicPreferenceState {
  @Trace motionEnabled: boolean = true;
  @Trace autoContinueEnabled: boolean = true;
  @Trace lyricsEnabled: boolean = true;
  @Trace desktopLyricsEnabled: boolean = false;
}

export function connectMusicPreferenceState(): MusicPreferenceState {
  return AppStorageV2.connect(MusicPreferenceState, 'FeiniuMusicPreferences',
    (): MusicPreferenceState => new MusicPreferenceState())!;
}

export class MusicPreferenceStore {
  private static store?: preferences.Preferences;
  private static sharedState: MusicPreferenceState = connectMusicPreferenceState();

  static initialize(context: common.UIAbilityContext): void {
    if (MusicPreferenceStore.store !== undefined) {
      return;
    }
    MusicPreferenceStore.store = preferences.getPreferencesSync(context.getApplicationContext(), { name: STORE_NAME });
    MusicPreferenceStore.restore();
  }

  static state(): MusicPreferenceState {
    return MusicPreferenceStore.sharedState;
  }

  static setMotionEnabled(enabled: boolean): void {
    MusicPreferenceStore.sharedState.motionEnabled = enabled;
    MusicPreferenceStore.persist(MOTION_KEY, enabled);
  }

  static setAutoContinueEnabled(enabled: boolean): void {
    MusicPreferenceStore.sharedState.autoContinueEnabled = enabled;
    MusicPreferenceStore.persist(AUTO_CONTINUE_KEY, enabled);
  }

  static setLyricsEnabled(enabled: boolean): void {
    MusicPreferenceStore.sharedState.lyricsEnabled = enabled;
    MusicPreferenceStore.persist(LYRICS_KEY, enabled);
  }

  static setDesktopLyricsEnabled(enabled: boolean): void {
    MusicPreferenceStore.sharedState.desktopLyricsEnabled = enabled;
    MusicPreferenceStore.persist(DESKTOP_LYRICS_KEY, enabled);
  }

  private static restore(): void {
    const store = MusicPreferenceStore.store;
    if (store === undefined) {
      return;
    }
    MusicPreferenceStore.sharedState.motionEnabled = store.getSync(MOTION_KEY, true) as boolean;
    MusicPreferenceStore.sharedState.autoContinueEnabled = store.getSync(AUTO_CONTINUE_KEY, true) as boolean;
    MusicPreferenceStore.sharedState.lyricsEnabled = store.getSync(LYRICS_KEY, true) as boolean;
    MusicPreferenceStore.sharedState.desktopLyricsEnabled = store.getSync(DESKTOP_LYRICS_KEY, false) as boolean;
  }

  private static persist(key: string, value: boolean): void {
    const store = MusicPreferenceStore.store;
    if (store === undefined) {
      return;
    }
    store.putSync(key, value);
    store.flush().catch((): void => {});
  }
}
