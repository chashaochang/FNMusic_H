import { effectKit } from '@kit.ArkGraphics2D';
import { CoverArtStore } from '../common/CoverArtStore';
import { MusicTrack } from '../model/MusicModels';

@ObservedV2
export class PlayerPaletteState {
  @Trace startColor: string = '';
  @Trace endColor: string = '';
  @Trace coverKey: string = '';

  available(): boolean {
    return this.startColor.length > 0 && this.endColor.length > 0;
  }
}

export class PlayerDynamicPalette {
  static coverKey(track: MusicTrack): string {
    return `${track.coverId.trim()}:${track.updatedAt}`;
  }

  static async load(track: MusicTrack): Promise<PlayerPaletteState | undefined> {
    const coverKey = PlayerDynamicPalette.coverKey(track);
    if (track.coverId.trim().length === 0) {
      return undefined;
    }
    try {
      const pixelMap = await CoverArtStore.load(track.coverId, 192, track.updatedAt);
      if (pixelMap === undefined) {
        return undefined;
      }
      const picker = await effectKit.createColorPicker(pixelMap);
      const main = await picker.getMainColor();
      const average = picker.getAverageColor();
      const palette = new PlayerPaletteState();
      palette.coverKey = coverKey;
      palette.startColor = PlayerDynamicPalette.color(main.red, main.green, main.blue, 0.46, 0.88);
      palette.endColor = PlayerDynamicPalette.color(average.red, average.green, average.blue, 0.22, 0.52);
      return palette;
    } catch (_) {
      return undefined;
    }
  }

  private static color(red: number, green: number, blue: number, mixWhite: number, brightness: number): string {
    const mixedRed = PlayerDynamicPalette.channel((red * (1 - mixWhite) + 255 * mixWhite) * brightness);
    const mixedGreen = PlayerDynamicPalette.channel((green * (1 - mixWhite) + 255 * mixWhite) * brightness);
    const mixedBlue = PlayerDynamicPalette.channel((blue * (1 - mixWhite) + 255 * mixWhite) * brightness);
    return `rgba(${mixedRed},${mixedGreen},${mixedBlue},1)`;
  }

  private static channel(value: number): number {
    return Math.max(20, Math.min(238, Math.round(value)));
  }
}
