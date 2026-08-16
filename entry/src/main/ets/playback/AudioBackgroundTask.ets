import { common, wantAgent } from '@kit.AbilityKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'AudioBackgroundTask';

export class AudioBackgroundTask {
  private context?: common.UIAbilityContext;
  private desiredRunning: boolean = false;
  private systemRunning: boolean = false;
  private operationChain: Promise<void> = Promise.resolve();

  configure(context: common.UIAbilityContext): void {
    if (this.context !== context) {
      this.context = context;
      this.systemRunning = false;
    }
    if (this.desiredRunning) {
      this.enqueueReconcile();
    }
  }

  start(): void {
    this.desiredRunning = true;
    this.enqueueReconcile();
  }

  stop(): void {
    this.desiredRunning = false;
    this.enqueueReconcile();
  }

  private enqueueReconcile(): void {
    const operation: Promise<void> = this.operationChain.then((): Promise<void> => this.reconcile());
    this.operationChain = operation.catch((error: BusinessError): void => {
      hilog.error(DOMAIN, TAG,
        'Audio background task reconciliation failed code=%{public}d message=%{public}s',
        error.code ?? 0, error.message ?? 'unknown');
    });
  }

  private async reconcile(): Promise<void> {
    const context: common.UIAbilityContext | undefined = this.context;
    if (context === undefined) {
      return;
    }
    if (this.desiredRunning && !this.systemRunning) {
      const info: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: context.abilityInfo.bundleName,
            abilityName: context.abilityInfo.name
          }
        ],
        operationType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      };
      const agent = await wantAgent.getWantAgent(info);
      if (!this.desiredRunning) {
        return;
      }
      await backgroundTaskManager.startBackgroundRunning(
        context,
        backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK,
        agent
      );
      this.systemRunning = true;
      hilog.info(DOMAIN, TAG, '%{public}s', 'startBackgroundRunning succeeded');
    }
    if (!this.desiredRunning && this.systemRunning) {
      await backgroundTaskManager.stopBackgroundRunning(context);
      this.systemRunning = false;
      hilog.info(DOMAIN, TAG, '%{public}s', 'stopBackgroundRunning succeeded');
    }
  }
}
