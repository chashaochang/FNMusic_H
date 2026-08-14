import { common } from '@kit.AbilityKit';
import { AppRuntime, AppRuntimeState } from '../common/AppRuntime';
import { AuthPhase, LoginCredentials } from '../auth/ConnectionModels';
import { LoginScreen } from '../feature/auth/LoginScreen';
import { AppShell, AppShellController } from '../shell/AppShell';
import { CoverArtStore } from '../common/CoverArtStore';
import { WindowInsetsState, connectWindowInsetsState } from '../common/WindowInsetsState';
import { FnMusicLoginMetrics } from '../design/FnMusicLoginMetrics';
import { FnMusicUI } from '../design/FnMusicUI';

@ComponentV2
struct StartupRecordLoading {
  @Param message: string = '正在准备音乐库';
  @Param active: boolean = true;
  @Local discAngle: number = 0;
  @Local discOffsetY: number = 0;
  @Local discScale: number = 1;
  @Local discOpacity: number = 1;
  @Local exitReady: boolean = false;
  @Event onComplete: () => void = (): void => {};
  private timers: number[] = [];
  private exiting: boolean = false;

  aboutToAppear(): void {
    this.timers = [
      setTimeout((): void => {
        this.getUIContext().animateTo({
          duration: FnMusicLoginMetrics.introRotateDuration,
          curve: Curve.Linear
        }, (): void => {
          this.discAngle = 62;
        });
      }, 40),
      setTimeout((): void => {
        this.exitReady = true;
        this.tryExit();
      }, FnMusicLoginMetrics.introExitDelay)
    ];
  }

  aboutToDisappear(): void {
    this.timers.forEach((timer: number): void => clearTimeout(timer));
    this.timers = [];
  }

  @Monitor('active')
  onActiveChanged(): void {
    this.tryExit();
  }

  private tryExit(): void {
    if (this.active || !this.exitReady || this.exiting) {
      return;
    }
    this.exiting = true;
    this.getUIContext().animateTo({
      duration: FnMusicLoginMetrics.introExitDuration,
      curve: Curve.FastOutSlowIn
    }, (): void => {
      this.discAngle = 76;
      this.discOffsetY = -720;
      this.discScale = 1.14;
      this.discOpacity = 0.72;
    });
    this.timers.push(setTimeout((): void => {
      this.onComplete();
    }, FnMusicLoginMetrics.introExitDuration));
  }

  build() {
    Column({ space: 24 }) {
      Image($r('app.media.login_record'))
        .width(FnMusicLoginMetrics.introDiscSize)
        .height(FnMusicLoginMetrics.introDiscSize)
        .objectFit(ImageFit.Contain)
        .rotate({ angle: this.discAngle })
      Text(this.message)
        .fontSize(FnMusicUI.bodySize)
        .fontColor($r('app.color.login_text_secondary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .scale({ x: this.discScale, y: this.discScale })
    .translate({ y: this.discOffsetY })
    .opacity(this.discOpacity)
    .backgroundColor($r('app.color.login_canvas'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}

@Entry
@ComponentV2
struct Index {
  @Local runtime: AppRuntimeState = AppRuntime.state();
  @Local insets: WindowInsetsState = connectWindowInsetsState();
  @Local restoring: boolean = true;
  @Local startupOverlayActive: boolean = true;
  @Local startupOverlayVisible: boolean = true;
  private shellController: AppShellController = new AppShellController();

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    AppRuntime.initialize(context);
    this.restoreSession();
  }

  private async restoreSession(): Promise<void> {
    this.restoring = true;
    this.startupOverlayActive = true;
    this.startupOverlayVisible = true;
    let restored: boolean = false;
    try {
      restored = await AppRuntime.restore();
    } finally {
      this.restoring = false;
      if (restored && this.runtime.phase === AuthPhase.AUTHENTICATED) {
        this.startupOverlayActive = false;
      } else {
        this.startupOverlayVisible = false;
      }
    }
  }

  private signIn(credentials: LoginCredentials): void {
    CoverArtStore.clear();
    AppRuntime.signIn(credentials).catch((): void => {});
  }

  private signOut(): void {
    CoverArtStore.clear();
    AppRuntime.signOut(true).catch((): void => {});
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (!this.restoring && this.runtime.phase === AuthPhase.AUTHENTICATED) {
        AppShell({
          runtime: this.runtime,
          controller: this.shellController,
          safeTop: Math.max(0, this.insets.safeTop),
          safeBottom: Math.max(0, this.insets.safeBottom),
          onLogout: (): void => this.signOut()
        })
        .width('100%')
        .height('100%')
      } else if (!this.restoring) {
        LoginScreen({
          runtime: this.runtime,
          onLogin: (credentials: LoginCredentials): void => this.signIn(credentials),
          onRetry: (): void => {
            AppRuntime.retry().catch((): void => {});
          }
        })
      } else {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.login_canvas'))
      }

      if (this.startupOverlayVisible) {
        StartupRecordLoading({
          message: this.runtime.message.length > 0 ? this.runtime.message : '正在准备音乐库',
          active: this.startupOverlayActive,
          onComplete: (): void => {
            this.startupOverlayVisible = false;
          }
        })
      }

    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }

  onBackPress(): boolean | void {
    return this.shellController.handleBack();
  }
}
