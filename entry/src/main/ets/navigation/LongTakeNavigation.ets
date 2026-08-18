import {
  LongTakeSession,
  LongTakeTransitionDelegate,
  LongTakeTransitionParam
} from '@hmanimations/ezcustomtransition';
import {
  HdsNavDestination,
  HdsNavDestinationTitleMode
} from '@kit.UIDesignKit';

export const DETAIL_HERO_TRANSITION_SCOPE: string = 'fn_music_detail_hero';

export class LongTakeRouteParams {
  longTakeTransitionParam?: LongTakeTransitionParam = undefined;
  alignTargetId: string = '';
}

export class LongTakeSource {
  componentId: string = '';
  cornerRadius: number = 0;

  constructor(componentId: string = '', cornerRadius: number = 0) {
    this.componentId = componentId;
    this.cornerRadius = cornerRadius;
  }
}

export function transitionSourceId(scope: string, kind: string, identity: string): string {
  return `fn_music_${scope}_${kind}_${identity}`;
}

export function detailHeroTransitionId(kind: string, identity: string): string {
  return transitionSourceId(DETAIL_HERO_TRANSITION_SCOPE, kind, identity);
}

@Component
export struct LongTakeNavDestination {
  pathStack: NavPathStack = new NavPathStack();
  @BuilderParam contentBuilder: () => void;
  onHidden: () => void = (): void => {};
  @State private longTakeSession: LongTakeSession = new LongTakeSession();
  @State private longTakeParam: LongTakeTransitionParam | undefined = undefined;

  @Builder
  private destinationContent() {
    Stack() {
      this.contentBuilder()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  build() {
    HdsNavDestination() {
      if (this.longTakeParam !== undefined) {
        LongTakeTransitionDelegate({
          longTakeSession: this.longTakeSession,
          contentBuilder: (): void => {
            this.destinationContent()
          }
        })
      } else {
        this.destinationContent()
      }
    }
    .backgroundColor(this.longTakeParam !== undefined ?
      this.longTakeSession.navDestinationBgColor : Color.Transparent)
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .hideTitleBar(true)
    .hideToolBar(true)
    .onSizeChange((_: SizeOptions, size: SizeOptions): void => {
      this.longTakeSession.setNewSize(size);
    })
    .onReady((context: NavDestinationContext): void => {
      const params = context.pathInfo?.param as LongTakeRouteParams;
      this.longTakeParam = params?.longTakeTransitionParam;
      if (this.longTakeParam === undefined) {
        return;
      }
      this.longTakeSession.init(context, this.longTakeParam, {
        pop: (): void => {
          this.pathStack.pop();
        },
        alignTargetId: params?.alignTargetId.length > 0 ? params.alignTargetId : undefined,
        contentSizeUsePercent: true
      });
    })
    .onHidden((): void => this.onHidden())
  }
}
