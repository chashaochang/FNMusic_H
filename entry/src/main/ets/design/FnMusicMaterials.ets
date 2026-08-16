import { uiMaterial } from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit';

export enum FnMusicMaterialRole {
  FLOATING_NAVIGATION = 'floating_navigation',
  FLOATING_PLAYER = 'floating_player',
  INTERACTIVE_SURFACE = 'interactive_surface',
  ADAPTIVE_INTERACTIVE = 'adaptive_interactive',
  CHIP = 'chip',
  CHIP_SELECTED = 'chip_selected',
  MUSIC_CHIP_SELECTED = 'music_chip_selected',
  DETAIL_SEGMENT_SELECTED = 'detail_segment_selected'
}

class FnMusicMaterialModifier<T extends CommonAttribute> implements AttributeModifier<T> {
  private role: FnMusicMaterialRole;

  constructor(role: FnMusicMaterialRole) {
    this.role = role;
  }

  applyNormalAttribute(instance: T): void {
    FnMusicMaterials.apply(instance, this.role);
  }
}

/** Shared immersive materials with an API 24 blur fallback. */
export class FnMusicMaterials {
  private static floatingNavigation?: uiMaterial.Material;
  private static floatingPlayer?: uiMaterial.Material;
  private static interactiveSurface?: uiMaterial.Material;
  private static adaptiveInteractive?: uiMaterial.Material;
  private static chip?: uiMaterial.Material;
  private static chipSelected?: uiMaterial.Material;
  private static musicChipSelected?: uiMaterial.Material;
  private static detailSegmentSelected?: uiMaterial.Material;
  private static readonly lightEffect: uiMaterial.LightEffectOptions = { color: Color.White };

  static modifier<T extends CommonAttribute>(role: FnMusicMaterialRole): AttributeModifier<T> {
    return new FnMusicMaterialModifier<T>(role);
  }

  static apply<T extends CommonAttribute>(instance: T, role: FnMusicMaterialRole): void {
    if (deviceInfo.apiAvailable('26.0.0')) {
      instance.systemMaterial(FnMusicMaterials.material(role));
      return;
    }
    instance
      .backgroundBlurStyle(FnMusicMaterials.fallbackBlurStyle(role), {
        colorMode: ThemeColorMode.SYSTEM,
        adaptiveColor: AdaptiveColor.DEFAULT,
        scale: 1
      })
      .backgroundColor(FnMusicMaterials.fallbackColor(role));
  }

  private static fallbackBlurStyle(role: FnMusicMaterialRole): BlurStyle {
    if (role === FnMusicMaterialRole.FLOATING_NAVIGATION || role === FnMusicMaterialRole.FLOATING_PLAYER) {
      return BlurStyle.COMPONENT_REGULAR;
    }
    return BlurStyle.COMPONENT_THIN;
  }

  private static fallbackColor(role: FnMusicMaterialRole): ResourceColor {
    if (role === FnMusicMaterialRole.FLOATING_NAVIGATION) {
      return $r('app.color.material_fallback_floating_navigation');
    }
    if (role === FnMusicMaterialRole.FLOATING_PLAYER) {
      return $r('app.color.material_fallback_floating_player');
    }
    if (role === FnMusicMaterialRole.CHIP_SELECTED) {
      return $r('app.color.chip_selected_material');
    }
    if (role === FnMusicMaterialRole.MUSIC_CHIP_SELECTED) {
      return $r('app.color.music_chip_selected_material');
    }
    if (role === FnMusicMaterialRole.DETAIL_SEGMENT_SELECTED) {
      return $r('app.color.detail_segment_selected_material');
    }
    if (role === FnMusicMaterialRole.CHIP) {
      return $r('app.color.material_fallback_chip');
    }
    return $r('app.color.material_fallback_interactive');
  }

  static material(role: FnMusicMaterialRole): uiMaterial.Material {
    if (deviceInfo.apiAvailable('26.0.0')) {
    if (role === FnMusicMaterialRole.FLOATING_NAVIGATION) {
      if (FnMusicMaterials.floatingNavigation === undefined) {
        FnMusicMaterials.floatingNavigation = new uiMaterial.ImmersiveMaterial({
          style: uiMaterial.ImmersiveStyle.REGULAR,
          materialColor: $r('app.color.navigation_background'),
          colorInvert: false,
          applyShadow: true,
          interactive: true,
          lightEffect: FnMusicMaterials.lightEffect
        });
      }
      return FnMusicMaterials.floatingNavigation;
    }
    if (role === FnMusicMaterialRole.FLOATING_PLAYER) {
      if (FnMusicMaterials.floatingPlayer === undefined) {
        FnMusicMaterials.floatingPlayer = new uiMaterial.ImmersiveMaterial({
          applyShadow: true,
          interactive: true,
          lightEffect: FnMusicMaterials.lightEffect
        });
      }
      return FnMusicMaterials.floatingPlayer;
    }
    if (role === FnMusicMaterialRole.ADAPTIVE_INTERACTIVE) {
      if (FnMusicMaterials.adaptiveInteractive === undefined) {
        FnMusicMaterials.adaptiveInteractive = new uiMaterial.ImmersiveMaterial({ interactive: true });
      }
      return FnMusicMaterials.adaptiveInteractive;
    }
    if (role === FnMusicMaterialRole.CHIP_SELECTED) {
      if (FnMusicMaterials.chipSelected === undefined) {
        FnMusicMaterials.chipSelected = new uiMaterial.ImmersiveMaterial({
          style: uiMaterial.ImmersiveStyle.REGULAR,
          materialColor: $r('app.color.chip_selected_material'),
          colorInvert: false,
          applyShadow: false,
          interactive: true,
          lightEffect: FnMusicMaterials.lightEffect
        });
      }
      return FnMusicMaterials.chipSelected;
    }
    if (role === FnMusicMaterialRole.MUSIC_CHIP_SELECTED) {
      if (FnMusicMaterials.musicChipSelected === undefined) {
        FnMusicMaterials.musicChipSelected = new uiMaterial.ImmersiveMaterial({
          style: uiMaterial.ImmersiveStyle.REGULAR,
          materialColor: $r('app.color.music_chip_selected_material'),
          colorInvert: false,
          applyShadow: false,
          interactive: true,
          lightEffect: FnMusicMaterials.lightEffect
        });
      }
      return FnMusicMaterials.musicChipSelected;
    }
    if (role === FnMusicMaterialRole.DETAIL_SEGMENT_SELECTED) {
      if (FnMusicMaterials.detailSegmentSelected === undefined) {
        FnMusicMaterials.detailSegmentSelected = new uiMaterial.ImmersiveMaterial({
          style: uiMaterial.ImmersiveStyle.REGULAR,
          materialColor: $r('app.color.detail_segment_selected_material'),
          colorInvert: false,
          applyShadow: false,
          interactive: true,
          lightEffect: FnMusicMaterials.lightEffect
        });
      }
      return FnMusicMaterials.detailSegmentSelected;
    }
    if (role === FnMusicMaterialRole.CHIP) {
      if (FnMusicMaterials.chip === undefined) {
        FnMusicMaterials.chip = new uiMaterial.ImmersiveMaterial({ applyShadow: false, interactive: true });
      }
      return FnMusicMaterials.chip;
    }
    if (FnMusicMaterials.interactiveSurface === undefined) {
      FnMusicMaterials.interactiveSurface = new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.REGULAR,
        materialColor: Color.Transparent,
        colorInvert: false,
        applyShadow: false,
        interactive: true,
        lightEffect: FnMusicMaterials.lightEffect
      });
    }
    return FnMusicMaterials.interactiveSurface;
    }
    throw new Error('System material is unavailable below API 26.');
  }
}
