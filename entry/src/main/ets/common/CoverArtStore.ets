import { image } from '@kit.ImageKit';
import { http } from '@kit.NetworkKit';
import { AppRuntime } from './AppRuntime';

/** Loads authenticated Feiniu cover images and keeps a bounded in-memory cache. */
export class CoverArtStore {
  private static readonly maxEntries: number = 96;
  private static readonly maxDecodedPixels: number = 12 * 1024 * 1024;
  private static readonly cache: Map<string, image.PixelMap> = new Map<string, image.PixelMap>();
  private static readonly decodedPixels: Map<string, number> = new Map<string, number>();
  private static readonly pending: Map<string, Promise<image.PixelMap | undefined>> =
    new Map<string, Promise<image.PixelMap | undefined>>();
  private static totalDecodedPixels: number = 0;
  private static epoch: number = 0;

  static cached(coverId: string, size: number, updatedAt: number = 0): image.PixelMap | undefined {
    return CoverArtStore.cache.get(CoverArtStore.key(coverId, size, updatedAt));
  }

  static async load(coverId: string, size: number, updatedAt: number = 0): Promise<image.PixelMap | undefined> {
    const normalized = coverId.trim();
    if (normalized.length === 0) {
      return undefined;
    }
    const key = CoverArtStore.key(normalized, size, updatedAt);
    const cached = CoverArtStore.cache.get(key);
    if (cached !== undefined) {
      return cached;
    }
    const pending = CoverArtStore.pending.get(key);
    if (pending !== undefined) {
      return await pending;
    }
    const epoch = CoverArtStore.epoch;
    const task = CoverArtStore.fetch(normalized, size, updatedAt);
    CoverArtStore.pending.set(key, task);
    try {
      const pixelMap = await task;
      if (pixelMap !== undefined && epoch === CoverArtStore.epoch) {
        CoverArtStore.cache.set(key, pixelMap);
        const pixels = CoverArtStore.normalizedSize(size) ** 2;
        CoverArtStore.decodedPixels.set(key, pixels);
        CoverArtStore.totalDecodedPixels += pixels;
        CoverArtStore.trim();
      } else if (pixelMap !== undefined) {
        await pixelMap.release().catch((): void => {});
        return undefined;
      }
      return pixelMap;
    } finally {
      if (CoverArtStore.pending.get(key) === task) {
        CoverArtStore.pending.delete(key);
      }
    }
  }

  static clear(): void {
    CoverArtStore.epoch += 1;
    CoverArtStore.pending.clear();
    CoverArtStore.cache.forEach((pixelMap: image.PixelMap): void => {
      pixelMap.release().catch((): void => {});
    });
    CoverArtStore.cache.clear();
    CoverArtStore.decodedPixels.clear();
    CoverArtStore.totalDecodedPixels = 0;
  }

  private static async fetch(coverId: string, size: number, updatedAt: number): Promise<image.PixelMap | undefined> {
    const client = http.createHttp();
    let source: image.ImageSource | undefined = undefined;
    try {
      const decodedSize = CoverArtStore.normalizedSize(size);
      const response = await client.request(AppRuntime.coverUrl(coverId, decodedSize, updatedAt), {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        header: AppRuntime.playbackHeaders(),
        connectTimeout: 10000,
        readTimeout: 15000,
        usingCache: true
      });
      if (response.responseCode < 200 || response.responseCode >= 300 || !(response.result instanceof ArrayBuffer) ||
        response.result.byteLength === 0) {
        return undefined;
      }
      source = image.createImageSource(response.result);
      return await source.createPixelMap({
        desiredSize: { width: decodedSize, height: decodedSize }
      });
    } catch (_) {
      return undefined;
    } finally {
      if (source !== undefined) {
        await source.release().catch((): void => {});
      }
      client.destroy();
    }
  }

  private static trim(): void {
    while (CoverArtStore.cache.size > CoverArtStore.maxEntries ||
      CoverArtStore.totalDecodedPixels > CoverArtStore.maxDecodedPixels) {
      const oldest = CoverArtStore.cache.keys().next().value as string | undefined;
      if (oldest === undefined) {
        return;
      }
      const pixelMap = CoverArtStore.cache.get(oldest);
      CoverArtStore.totalDecodedPixels -= CoverArtStore.decodedPixels.get(oldest) ?? 0;
      CoverArtStore.cache.delete(oldest);
      CoverArtStore.decodedPixels.delete(oldest);
      pixelMap?.release().catch((): void => {});
    }
  }

  private static key(coverId: string, size: number, updatedAt: number): string {
    return AppRuntime.coverUrl(coverId, CoverArtStore.normalizedSize(size), updatedAt);
  }

  private static normalizedSize(size: number): number {
    return Math.min(768, Math.max(48, Math.round(size)));
  }
}
