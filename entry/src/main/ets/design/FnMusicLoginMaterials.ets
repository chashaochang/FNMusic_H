import { uiMaterial } from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit';

export enum FnMusicLoginMaterialRole {
  BRAND_MARK = 'brand_mark',
  INPUT = 'input',
  PRIMARY_ACTION = 'primary_action',
  SECONDARY_ACTION = 'secondary_action'
}

class FnMusicLoginMaterialModifier<T extends CommonAttribute> implements AttributeModifier<T> {
  private role: FnMusicLoginMaterialRole;

  constructor(role: FnMusicLoginMaterialRole) {
    this.role = role;
  }

  applyNormalAttribute(instance: T): void {
    FnMusicLoginMaterials.apply(instance, this.role);
  }
}

/** Cached login materials with an API 24 blur fallback. */
export class FnMusicLoginMaterials {
  private static brandMark?: uiMaterial.Material;
  private static input?: uiMaterial.Material;
  private static primaryAction?: uiMaterial.Material;
  private static secondaryAction?: uiMaterial.Material;
  private static readonly interactiveLightEffect: uiMaterial.LightEffectOptions = {
    color: Color.White
  };

  static modifier<T extends CommonAttribute>(role: FnMusicLoginMaterialRole): AttributeModifier<T> {
    return new FnMusicLoginMaterialModifier<T>(role);
  }

  static apply<T extends CommonAttribute>(instance: T, role: FnMusicLoginMaterialRole): void {
    if (deviceInfo.apiAvailable('26.0.0')) {
      instance.systemMaterial(FnMusicLoginMaterials.material(role));
      return;
    }
    instance
      .backgroundBlurStyle(BlurStyle.COMPONENT_THIN, {
        colorMode: ThemeColorMode.DARK,
        adaptiveColor: AdaptiveColor.DEFAULT,
        scale: 1
      })
      .backgroundColor(FnMusicLoginMaterials.fallbackColor(role));
  }

  private static fallbackColor(role: FnMusicLoginMaterialRole): ResourceColor {
    if (role === FnMusicLoginMaterialRole.BRAND_MARK || role === FnMusicLoginMaterialRole.PRIMARY_ACTION) {
      return $r('app.color.login_brand_material_fallback');
    }
    return $r('app.color.login_material_tint');
  }

  static material(role: FnMusicLoginMaterialRole): uiMaterial.Material {
    if (deviceInfo.apiAvailable('26.0.0')) {
    if (role === FnMusicLoginMaterialRole.BRAND_MARK) {
      if (FnMusicLoginMaterials.brandMark === undefined) {
        FnMusicLoginMaterials.brandMark = new uiMaterial.ImmersiveMaterial({
          style: uiMaterial.ImmersiveStyle.REGULAR,
          materialColor: $r('app.color.brand_red_material'),
          colorInvert: false,
          applyShadow: true,
          interactive: false,
          lightEffect: FnMusicLoginMaterials.interactiveLightEffect
        });
      }
      return FnMusicLoginMaterials.brandMark;
    }
    if (role === FnMusicLoginMaterialRole.PRIMARY_ACTION) {
      if (FnMusicLoginMaterials.primaryAction === undefined) {
        FnMusicLoginMaterials.primaryAction = new uiMaterial.ImmersiveMaterial({
          style: uiMaterial.ImmersiveStyle.REGULAR,
          materialColor: $r('app.color.brand_red_material'),
          colorInvert: false,
          applyShadow: true,
          interactive: true,
          lightEffect: FnMusicLoginMaterials.interactiveLightEffect
        });
      }
      return FnMusicLoginMaterials.primaryAction;
    }
    if (role === FnMusicLoginMaterialRole.SECONDARY_ACTION) {
      if (FnMusicLoginMaterials.secondaryAction === undefined) {
        FnMusicLoginMaterials.secondaryAction = new uiMaterial.ImmersiveMaterial({
          style: uiMaterial.ImmersiveStyle.THIN,
          materialColor: $r('app.color.login_material_tint'),
          colorInvert: false,
          applyShadow: false,
          interactive: true,
          lightEffect: FnMusicLoginMaterials.interactiveLightEffect
        });
      }
      return FnMusicLoginMaterials.secondaryAction;
    }
    if (FnMusicLoginMaterials.input === undefined) {
      FnMusicLoginMaterials.input = new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.THIN,
        materialColor: $r('app.color.login_material_tint'),
        colorInvert: false,
        applyShadow: false,
        interactive: true,
        lightEffect: FnMusicLoginMaterials.interactiveLightEffect
      });
    }
    return FnMusicLoginMaterials.input;
    }
    throw new Error('System material is unavailable below API 26.');
  }
}
