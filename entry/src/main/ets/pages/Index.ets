import { common } from '@kit.AbilityKit';
import { AppRuntime, AppRuntimeState } from '../common/AppRuntime';
import { AuthPhase, LoginCredentials } from '../auth/ConnectionModels';
import { LoginScreen } from '../feature/auth/LoginScreen';
import { AppShell, AppShellController } from '../shell/AppShell';
import { CoverArtStore } from '../common/CoverArtStore';
import { WindowInsetsState, connectWindowInsetsState } from '../common/WindowInsetsState';
import { FnMusicUI } from '../design/FnMusicUI';

@Entry
@ComponentV2
struct Index {
  @Local runtime: AppRuntimeState = AppRuntime.state();
  @Local insets: WindowInsetsState = connectWindowInsetsState();
  @Local restoring: boolean = true;
  private shellController: AppShellController = new AppShellController();

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    AppRuntime.initialize(context);
    this.restoreSession();
  }

  private async restoreSession(): Promise<void> {
    this.restoring = true;
    try {
      await AppRuntime.restore();
    } finally {
      this.restoring = false;
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
      if (this.restoring) {
        Column({ space: 16 }) {
          LoadingProgress()
            .width(36)
            .height(36)
            .color($r('app.color.accent'))
          Text(this.runtime.message.length > 0 ? this.runtime.message : '正在准备音乐库')
            .fontSize(FnMusicUI.bodySize)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.runtime.phase === AuthPhase.AUTHENTICATED) {
        AppShell({
          runtime: this.runtime,
          controller: this.shellController,
          safeTop: Math.max(0, this.insets.safeTop),
          safeBottom: Math.max(0, this.insets.safeBottom),
          onLogout: (): void => this.signOut()
        })
        .width('100%')
        .height('100%')
      } else {
        LoginScreen({
          runtime: this.runtime,
          onLogin: (credentials: LoginCredentials): void => this.signIn(credentials),
          onRetry: (): void => {
            AppRuntime.retry().catch((): void => {});
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
