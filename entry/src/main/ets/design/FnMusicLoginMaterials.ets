import { uiMaterial } from '@kit.ArkUI';

export enum FnMusicLoginMaterialRole {
  BRAND_MARK = 'brand_mark',
  INPUT = 'input',
  PRIMARY_ACTION = 'primary_action',
  SECONDARY_ACTION = 'secondary_action'
}

/** Cached API 26 materials used only by the login surface. */
export class FnMusicLoginMaterials {
  private static brandMark?: uiMaterial.Material;
  private static input?: uiMaterial.Material;
  private static primaryAction?: uiMaterial.Material;
  private static secondaryAction?: uiMaterial.Material;
  private static readonly interactiveLightEffect: uiMaterial.LightEffectOptions = {
    color: Color.White
  };

  static material(role: FnMusicLoginMaterialRole): uiMaterial.Material {
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
}
