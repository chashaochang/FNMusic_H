import { uiMaterial } from '@kit.ArkUI';

export enum FnMusicMaterialRole {
  FLOATING_NAVIGATION = 'floating_navigation',
  FLOATING_PLAYER = 'floating_player',
  INTERACTIVE_SURFACE = 'interactive_surface',
  ADAPTIVE_INTERACTIVE = 'adaptive_interactive',
  CHIP = 'chip',
  CHIP_SELECTED = 'chip_selected'
}

/** Shared API 26 immersive materials for native music surfaces. */
export class FnMusicMaterials {
  private static floatingNavigation?: uiMaterial.Material;
  private static floatingPlayer?: uiMaterial.Material;
  private static interactiveSurface?: uiMaterial.Material;
  private static adaptiveInteractive?: uiMaterial.Material;
  private static chip?: uiMaterial.Material;
  private static chipSelected?: uiMaterial.Material;
  private static readonly lightEffect: uiMaterial.LightEffectOptions = { color: Color.White };

  static material(role: FnMusicMaterialRole): uiMaterial.Material {
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
}
