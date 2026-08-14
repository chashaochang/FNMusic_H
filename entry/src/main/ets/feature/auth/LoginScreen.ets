import { AuthPhase, LoginCredentials } from '../../auth/ConnectionModels';
import { AppRuntimeState } from '../../common/AppRuntime';
import { WindowInsetsState, connectWindowInsetsState } from '../../common/WindowInsetsState';
import { FnMusicLoginMaterialRole, FnMusicLoginMaterials } from '../../design/FnMusicLoginMaterials';
import { FnMusicLoginMetrics } from '../../design/FnMusicLoginMetrics';
import { FnMusicUI } from '../../design/FnMusicUI';

@ComponentV2
export struct LoginScreen {
  @Local insets: WindowInsetsState = connectWindowInsetsState();
  @Param runtime: AppRuntimeState = new AppRuntimeState();
  @Local fnId: string = '';
  @Local username: string = '';
  @Local password: string = '';
  @Local accessCode: string = '';
  @Local showPassword: boolean = false;
  @Local showAdvanced: boolean = false;
  @Event onLogin: (credentials: LoginCredentials) => void = (_: LoginCredentials): void => {};
  @Event onRetry: () => void = (): void => {};

  private busy(): boolean {
    return this.runtime.phase === AuthPhase.RESTORING || this.runtime.phase === AuthPhase.RESOLVING ||
      this.runtime.phase === AuthPhase.CONNECTING || this.runtime.phase === AuthPhase.AUTHENTICATING;
  }

  private ready(): boolean {
    return this.fnId.trim().length > 0 && this.username.trim().length > 0 && this.password.length > 0;
  }

  private busyLabel(): string {
    if (this.runtime.phase === AuthPhase.RESOLVING) {
      return '正在查找服务器';
    }
    if (this.runtime.phase === AuthPhase.CONNECTING) {
      return '正在连接服务器';
    }
    if (this.runtime.phase === AuthPhase.AUTHENTICATING) {
      return '正在验证身份';
    }
    return '正在恢复连接';
  }

  private submit(): void {
    if (this.busy() || !this.ready()) {
      return;
    }
    const value = new LoginCredentials();
    value.fnId = this.fnId.trim();
    value.username = this.username.trim();
    value.password = this.password;
    value.accessCode = this.accessCode;
    this.onLogin(value);
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.login_canvas'))
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      Scroll() {
        Column() {
          LoginBrandHeaderV2()

          Column({ space: 12 }) {
            NativeLoginFieldV2({
              text: this.fnId,
              placeholder: 'FN ID、域名或服务器地址',
              accessibilityLabel: 'FN ID、域名或服务器地址',
              fieldEnabled: !this.busy(),
              onTextChanged: (value: string): void => {
                this.fnId = value;
              }
            })

            NativeLoginFieldV2({
              text: this.username,
              placeholder: '用户名',
              accessibilityLabel: '用户名',
              fieldEnabled: !this.busy(),
              onTextChanged: (value: string): void => {
                this.username = value;
              }
            })

            NativeLoginFieldV2({
              text: this.password,
              placeholder: '密码',
              accessibilityLabel: '密码',
              password: true,
              showPassword: this.showPassword,
              fieldEnabled: !this.busy(),
              onTextChanged: (value: string): void => {
                this.password = value;
              },
              onTogglePassword: (): void => {
                this.showPassword = !this.showPassword;
              },
              onSubmit: (): void => this.submit()
            })

            SecurityCodeSectionV2({
              expanded: this.showAdvanced,
              accessCode: this.accessCode,
              sectionEnabled: !this.busy(),
              onExpandedChanged: (expanded: boolean): void => {
                this.getUIContext().animateTo({
                  duration: FnMusicLoginMetrics.contentMotionDuration,
                  curve: Curve.FastOutSlowIn
                }, (): void => {
                  this.showAdvanced = expanded;
                });
              },
              onAccessCodeChanged: (value: string): void => {
                this.accessCode = value;
              },
              onSubmit: (): void => this.submit()
            })

            LoginStatusMessageV2({
              message: this.runtime.message,
              errorState: this.runtime.phase === AuthPhase.ERROR
            })

            LoginPrimaryActionV2({
              ready: this.ready(),
              busy: this.busy(),
              busyLabel: this.busyLabel(),
              onAction: (): void => this.submit()
            })

            if (this.runtime.canRetry && !this.busy()) {
              LoginRetryActionV2({ onAction: (): void => this.onRetry() })
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ top: 28 })

          Row({ space: 6 }) {
            SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
              .fontSize(14)
              .fontColor([$r('sys.color.icon_secondary')])
            Text('登录信息仅保存在本机应用私有空间。')
              .layoutWeight(1)
              .fontSize(12)
              .lineHeight(18)
              .fontColor($r('sys.color.font_secondary'))
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
          .padding({ top: 24, bottom: 28 })
        }
        .width('100%')
        .constraintSize({ maxWidth: FnMusicLoginMetrics.contentMaxWidth })
        .alignItems(HorizontalAlign.Start)
        .padding({
          left: FnMusicLoginMetrics.pageHorizontalPadding,
          right: FnMusicLoginMetrics.pageHorizontalPadding,
          top: Math.max(0, this.insets.safeTop) + 18
        })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
  }
}

@ComponentV2
struct LoginBrandHeaderV2 {
  build() {
    Row({ space: 14 }) {
      Stack() {
        SymbolGlyph($r('sys.symbol.music_note_list'))
          .fontSize(25)
          .fontColor([$r('app.color.brand_on_red')])
      }
      .width(FnMusicLoginMetrics.brandMarkSize)
      .height(FnMusicLoginMetrics.brandMarkSize)
      .borderRadius(FnMusicLoginMetrics.brandMarkRadius)
      .clip(true)
      .systemMaterial(FnMusicLoginMaterials.material(FnMusicLoginMaterialRole.BRAND_MARK))

      Column({ space: 3 }) {
        Text('飞牛音乐')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
        Text('连接你的飞牛服务器')
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('sys.color.font_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }
}

@ComponentV2
struct NativeLoginFieldV2 {
  @Param text: string = '';
  @Param placeholder: string = '';
  @Param accessibilityLabel: string = '';
  @Param password: boolean = false;
  @Param showPassword: boolean = false;
  @Param showVisibilityAction: boolean = true;
  @Param fieldEnabled: boolean = true;
  @Local focused: boolean = false;
  @Event onTextChanged: (value: string) => void = (_: string): void => {};
  @Event onTogglePassword: () => void = (): void => {};
  @Event onSubmit: () => void = (): void => {};

  build() {
    Stack({ alignContent: Alignment.End }) {
      Stack() {
        TextInput({ text: this.text, placeholder: this.placeholder })
          .type(this.password ? InputType.Password : InputType.Normal)
          .showPassword(this.password && this.showPassword)
          .showPasswordIcon(false)
          .width('100%')
          .height(FnMusicLoginMetrics.fieldHeight)
          .fontSize(FnMusicUI.bodySize)
          .fontColor($r('sys.color.font_primary'))
          .placeholderColor($r('sys.color.font_secondary'))
          .caretColor($r('app.color.brand_red'))
          .backgroundColor(Color.Transparent)
          .padding({ left: 16, right: this.password && this.showVisibilityAction ? 48 : 16 })
          .enabled(this.fieldEnabled)
          .accessibilityText(this.accessibilityLabel)
          .onFocus((): void => {
            this.getUIContext().animateTo({
              duration: FnMusicLoginMetrics.focusMotionDuration,
              curve: Curve.FastOutSlowIn
            }, (): void => {
              this.focused = true;
            });
          })
          .onBlur((): void => {
            this.getUIContext().animateTo({
              duration: FnMusicLoginMetrics.focusMotionDuration,
              curve: Curve.FastOutSlowIn
            }, (): void => {
              this.focused = false;
            });
          })
          .onChange((value: string): void => this.onTextChanged(value))
          .onSubmit((): void => this.onSubmit())
      }
      .width('100%')
      .height(FnMusicLoginMetrics.fieldHeight)
      .borderRadius(FnMusicLoginMetrics.fieldRadius)
      .clip(true)
      .systemMaterial(FnMusicLoginMaterials.material(FnMusicLoginMaterialRole.INPUT))

      Row()
        .width('100%')
        .height(FnMusicLoginMetrics.fieldHeight)
        .borderRadius(FnMusicLoginMetrics.fieldRadius)
        .border({ width: FnMusicLoginMetrics.focusOutlineWidth, color: $r('app.color.focus_outline') })
        .opacity(this.focused ? 1 : 0)
        .hitTestBehavior(HitTestMode.Transparent)

      if (this.password && this.showVisibilityAction) {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph(this.showPassword ? $r('sys.symbol.eye_slash') : $r('sys.symbol.eye'))
            .fontSize(20)
            .fontColor([$r('sys.color.icon_secondary')])
        }
        .width(44)
        .height(44)
        .backgroundColor(Color.Transparent)
        .enabled(this.fieldEnabled)
        .accessibilityText(this.showPassword ? '隐藏密码' : '显示密码')
        .onClick((): void => this.onTogglePassword())
        .margin({ right: 4 })
      }
    }
    .width('100%')
    .height(FnMusicLoginMetrics.fieldHeight)
  }
}

@ComponentV2
struct SecurityCodeSectionV2 {
  @Param expanded: boolean = false;
  @Param accessCode: string = '';
  @Param sectionEnabled: boolean = true;
  @Event onExpandedChanged: (expanded: boolean) => void = (_: boolean): void => {};
  @Event onAccessCodeChanged: (value: string) => void = (_: string): void => {};
  @Event onSubmit: () => void = (): void => {};

  build() {
    Column({ space: 8 }) {
      Row({ space: 7 }) {
        Text(this.expanded ? '收起安全码' : '填写安全码')
          .fontSize(FnMusicUI.supportingSize)
          .fontColor(this.sectionEnabled ? $r('app.color.brand_red') : $r('app.color.login_disabled_text'))
        SymbolGlyph(this.expanded ? $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down'))
          .fontSize(15)
          .fontColor([this.sectionEnabled ? $r('app.color.brand_red') : $r('app.color.login_disabled_text')])
      }
      .height(40)
      .enabled(this.sectionEnabled)
      .accessibilityText(this.expanded ? '收起服务器安全码' : '填写服务器安全码')
      .onClick((): void => this.onExpandedChanged(!this.expanded))

      if (this.expanded) {
        NativeLoginFieldV2({
          text: this.accessCode,
          placeholder: '服务器安全码（可选）',
          accessibilityLabel: '服务器安全码，可选',
          password: true,
          showVisibilityAction: false,
          fieldEnabled: this.sectionEnabled,
          onTextChanged: (value: string): void => this.onAccessCodeChanged(value),
          onSubmit: (): void => this.onSubmit()
        })
        .transition(
          TransitionEffect.OPACITY
            .animation({ duration: FnMusicLoginMetrics.contentMotionDuration, curve: Curve.EaseOut })
            .combine(TransitionEffect.translate({ y: 8 })
              .animation({ duration: FnMusicLoginMetrics.contentMotionDuration, curve: Curve.FastOutSlowIn }))
        )
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

@ComponentV2
struct LoginStatusMessageV2 {
  @Param message: string = '';
  @Param errorState: boolean = false;

  build() {
    if (this.message.length > 0) {
      Row({ space: 8 }) {
        SymbolGlyph(this.errorState ? $r('sys.symbol.exclamationmark_circle_fill') :
          $r('sys.symbol.info_circle_fill'))
          .fontSize(18)
          .fontColor([this.errorState ? $r('app.color.danger') : $r('app.color.brand_red')])
        Text(this.message)
          .layoutWeight(1)
          .fontSize(FnMusicUI.supportingSize)
          .lineHeight(19)
          .fontColor(this.errorState ? $r('app.color.danger') : $r('sys.color.font_secondary'))
          .maxLines(3)
      }
      .width('100%')
      .padding(12)
      .borderRadius(FnMusicLoginMetrics.fieldRadius)
      .backgroundColor(this.errorState ? $r('app.color.danger_soft') : $r('app.color.brand_red_soft'))
      .transition(
        TransitionEffect.OPACITY
          .animation({ duration: FnMusicLoginMetrics.contentMotionDuration, curve: Curve.EaseOut })
          .combine(TransitionEffect.translate({ y: 6 })
            .animation({ duration: FnMusicLoginMetrics.contentMotionDuration, curve: Curve.FastOutSlowIn }))
      )
    }
  }
}

@ComponentV2
struct LoginPrimaryActionV2 {
  @Param ready: boolean = false;
  @Param busy: boolean = false;
  @Param busyLabel: string = '';
  @Event onAction: () => void = (): void => {};

  build() {
    if (this.ready || this.busy) {
      Button({ type: ButtonType.Capsule, stateEffect: true }) {
        if (this.busy) {
          Row({ space: 9 }) {
            LoadingProgress()
              .width(20)
              .height(20)
              .color($r('app.color.brand_on_red'))
            Text(this.busyLabel)
              .fontSize(FnMusicUI.bodySize)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.brand_on_red'))
          }
        } else {
          Text('登录')
            .fontSize(FnMusicUI.bodySize)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.brand_on_red'))
        }
      }
      .width('100%')
      .height(FnMusicLoginMetrics.actionHeight)
      .borderRadius(FnMusicLoginMetrics.actionRadius)
      .enabled(!this.busy)
      .accessibilityText(this.busy ? this.busyLabel : '登录')
      .systemMaterial(FnMusicLoginMaterials.material(FnMusicLoginMaterialRole.PRIMARY_ACTION))
      .onClick((): void => this.onAction())
    } else {
      Button('登录', { type: ButtonType.Capsule, stateEffect: false })
        .width('100%')
        .height(FnMusicLoginMetrics.actionHeight)
        .borderRadius(FnMusicLoginMetrics.actionRadius)
        .fontSize(FnMusicUI.bodySize)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.login_disabled_text'))
        .backgroundColor($r('app.color.login_disabled_fill'))
        .enabled(false)
        .accessibilityText('登录，需要填写服务器地址、用户名和密码')
    }
  }
}

@ComponentV2
struct LoginRetryActionV2 {
  @Event onAction: () => void = (): void => {};

  build() {
    Button({ type: ButtonType.Capsule, stateEffect: true }) {
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.arrow_clockwise'))
          .fontSize(18)
          .fontColor([$r('app.color.brand_red')])
        Text('重试自动连接')
          .fontSize(FnMusicUI.bodySize)
          .fontColor($r('app.color.brand_red'))
      }
    }
    .width('100%')
    .height(FnMusicLoginMetrics.actionHeight)
    .borderRadius(FnMusicLoginMetrics.actionRadius)
    .accessibilityText('重试自动连接')
    .systemMaterial(FnMusicLoginMaterials.material(FnMusicLoginMaterialRole.SECONDARY_ACTION))
    .onClick((): void => this.onAction())
    .transition(TransitionEffect.OPACITY.animation({
      duration: FnMusicLoginMetrics.contentMotionDuration,
      curve: Curve.EaseOut
    }))
  }
}
