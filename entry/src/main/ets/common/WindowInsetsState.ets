import { AppStorageV2 } from '@kit.ArkUI';

@ObservedV2
export class WindowInsetsState {
  @Trace safeTop: number = 0;
  @Trace safeBottom: number = 0;
}

export function connectWindowInsetsState(): WindowInsetsState {
  return AppStorageV2.connect(WindowInsetsState, 'FeiniuMusicWindowInsets', () => new WindowInsetsState())!;
}
