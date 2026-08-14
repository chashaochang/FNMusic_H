import { promptAction } from '@kit.ArkUI';

export class FnToast {
  static show(message: string): void {
    promptAction.showToast({
      message: message,
      duration: 1800,
      bottom: '96vp'
    });
  }

  static development(): void {
    FnToast.show('功能开发中');
  }
}
