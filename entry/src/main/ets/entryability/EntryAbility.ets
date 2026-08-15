import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want, common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { display, window } from '@kit.ArkUI';
import { AppRuntime } from '../common/AppRuntime';
import { MusicPreferenceStore } from '../common/MusicPreferenceStore';
import { WindowInsetsState, connectWindowInsetsState } from '../common/WindowInsetsState';
import { MusicPlaybackController } from '../playback/MusicPlaybackController';
import { ezCustomTransition } from '@hmanimations/ezcustomtransition';

const DOMAIN: number = 0x0000;
const TAG: string = 'FeiniuMusic';

export function preferredDensity(customDensity: number, systemDensity: number, defaultDensity: number): number {
  if (customDensity > 0) {
    return customDensity;
  }
  if (systemDensity > 0) {
    return systemDensity;
  }
  if (defaultDensity > 0) {
    return defaultDensity;
  }
  return 0;
}

export default class EntryAbility extends UIAbility {
  private mainWindow?: window.Window;
  private insets: WindowInsetsState = connectWindowInsetsState();
  private systemDensityChangeListenerRegistered: boolean = false;
  private avoidAreaChangeCallback = (options: window.AvoidAreaOptions): void => {
    if (this.mainWindow === undefined) {
      return;
    }
    if (options.type === window.AvoidAreaType.TYPE_SYSTEM ||
      options.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
      this.refreshInsets(this.mainWindow);
    }
  };
  private systemDensityChangeCallback = (_density: number): void => {
    if (this.mainWindow !== undefined) {
      this.refreshInsets(this.mainWindow);
    }
  };

  onCreate(_want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'EntryAbility created');
    this.lockDarkMode();
    AppRuntime.initialize(this.context as common.UIAbilityContext);
    MusicPreferenceStore.initialize(this.context as common.UIAbilityContext);
    MusicPlaybackController.instance().initialize(this.context as common.UIAbilityContext);
  }

  onForeground(): void {
    MusicPlaybackController.instance().refreshSystemSession();
  }

  onBackground(): void {
    MusicPlaybackController.instance().saveSession();
  }

  onDestroy(): void {
    MusicPlaybackController.instance().saveSession();
  }

  private density(windowClass: window.Window): number {
    try {
      const densityInfo = windowClass.getWindowDensityInfo();
      const density = preferredDensity(
        densityInfo.customDensity,
        densityInfo.systemDensity,
        densityInfo.defaultDensity
      );
      if (density > 0) {
        return density;
      }
    } catch (error) {
      hilog.warn(DOMAIN, TAG,
        'Failed to resolve window density; using display density: %{public}s', String(error));
    }
    try {
      return Math.max(display.getDefaultDisplaySync().densityPixels, 1);
    } catch (error) {
      hilog.warn(DOMAIN, TAG,
        'Failed to resolve display density; using raw pixels: %{public}s', String(error));
      return 1;
    }
  }

  private refreshInsets(windowClass: window.Window): void {
    const systemArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    const navigationArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
    const density = this.density(windowClass);
    this.insets.safeTop = Math.max(0, systemArea.topRect.height) / density;
    this.insets.safeBottom = Math.max(
      0,
      systemArea.bottomRect.height,
      navigationArea.bottomRect.height
    ) / density;
  }

  private lockDarkMode(): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Failed to lock dark color mode: %{public}s', JSON.stringify(error));
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    ezCustomTransition.init(windowStage);
    windowStage.getMainWindow((windowError, mainWindow) => {
      if (windowError.code || !mainWindow) {
        hilog.warn(DOMAIN, TAG, 'Failed to obtain main window: %{public}s', JSON.stringify(windowError));
        return;
      }
      this.mainWindow = mainWindow;
      this.refreshInsets(mainWindow);
      mainWindow.on('avoidAreaChange', this.avoidAreaChangeCallback);
      try {
        mainWindow.on('systemDensityChange', this.systemDensityChangeCallback);
        this.systemDensityChangeListenerRegistered = true;
      } catch (error) {
        hilog.warn(DOMAIN, TAG,
          'System-density listener is unavailable: %{public}s', String(error));
      }
      mainWindow.setWindowLayoutFullScreen(true).catch((layoutError: Error) => {
        hilog.warn(DOMAIN, TAG, 'Failed to enable immersive layout: %{public}s', JSON.stringify(layoutError));
      });
      mainWindow.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        statusBarContentColor: '#FFFFFFFF',
        navigationBarColor: '#00000000',
        navigationBarContentColor: '#FFFFFFFF'
      }).catch((barError: Error) => {
        hilog.warn(DOMAIN, TAG, 'Failed to set system bars: %{public}s', JSON.stringify(barError));
      });
    });

    windowStage.loadContent('pages/Index', (error) => {
      if (error.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load content: %{public}s', JSON.stringify(error));
        return;
      }
      hilog.info(DOMAIN, TAG, '%{public}s', 'Content loaded');
    });

  }

  onConfigurationUpdate(_newConfig: Configuration): void {
    ezCustomTransition.onConfigurationChanged();
  }

  onWindowStageDestroy(): void {
    if (this.mainWindow !== undefined) {
      try {
        this.mainWindow.off('avoidAreaChange', this.avoidAreaChangeCallback);
      } catch (_) {
      }
      if (this.systemDensityChangeListenerRegistered) {
        try {
          this.mainWindow.off('systemDensityChange', this.systemDensityChangeCallback);
        } catch (_) {
        }
      }
    }
    this.systemDensityChangeListenerRegistered = false;
    this.mainWindow = undefined;
    this.insets.safeTop = 0;
    this.insets.safeBottom = 0;
  }
}
