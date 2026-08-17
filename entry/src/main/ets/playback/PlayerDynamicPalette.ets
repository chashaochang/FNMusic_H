import { effectKit } from '@kit.ArkGraphics2D';
import { CoverArtStore } from '../common/CoverArtStore';
import { MusicTrack } from '../model/MusicModels';

@ObservedV2
export class PlayerPaletteState {
  @Trace startColor: string = '';
  @Trace endColor: string = '';
  @Trace progressTrackColor: string = '';
  @Trace progressStartColor: string = '';
  @Trace progressMiddleColor: string = '';
  @Trace progressEndColor: string = '';
  @Trace progressGlowColor: string = '';
  @Trace progressThumbGlowColor: string = '';
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
      palette.progressTrackColor =
        PlayerDynamicPalette.color(average.red, average.green, average.blue, 0.34, 1, 0.24, 246);
      palette.progressStartColor =
        PlayerDynamicPalette.color(main.red, main.green, main.blue, 0.64, 1.06, 1, 250);
      palette.progressMiddleColor =
        PlayerDynamicPalette.color(main.red, main.green, main.blue, 0.44, 1.04, 1, 250);
      palette.progressEndColor =
        PlayerDynamicPalette.color(average.red, average.green, average.blue, 0.42, 1.04, 1, 248);
      palette.progressGlowColor =
        PlayerDynamicPalette.color(main.red, main.green, main.blue, 0.42, 1.06, 0.58, 250);
      palette.progressThumbGlowColor =
        PlayerDynamicPalette.color(main.red, main.green, main.blue, 0.55, 1.07, 0.3, 250);
      return palette;
    } catch (_) {
      return undefined;
    }
  }

  private static color(red: number, green: number, blue: number, mixWhite: number, brightness: number,
    alpha: number = 1, maxChannel: number = 238): string {
    const mixedRed = PlayerDynamicPalette.channel(
      (red * (1 - mixWhite) + 255 * mixWhite) * brightness, maxChannel);
    const mixedGreen = PlayerDynamicPalette.channel(
      (green * (1 - mixWhite) + 255 * mixWhite) * brightness, maxChannel);
    const mixedBlue = PlayerDynamicPalette.channel(
      (blue * (1 - mixWhite) + 255 * mixWhite) * brightness, maxChannel);
    return `rgba(${mixedRed},${mixedGreen},${mixedBlue},${alpha})`;
  }

  private static channel(value: number, maxChannel: number = 238): number {
    return Math.max(20, Math.min(maxChannel, Math.round(value)));
  }
}
