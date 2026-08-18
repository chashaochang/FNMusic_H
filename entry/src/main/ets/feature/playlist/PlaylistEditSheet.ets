import { fileIo } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { FnMusicUI } from '../../design/FnMusicUI';
import { FnMusicMaterialRole, FnMusicMaterials } from '../../design/FnMusicMaterials';
import { MusicPlaylist } from '../../model/MusicModels';
import { MusicArtwork, SettingsRow } from '../common/MusicUiComponents';

export enum PlaylistEditMode {
  CREATE = 'create',
  EDIT = 'edit'
}

export enum PlaylistSaveStage {
  UPLOADING = 'uploading',
  SAVING = 'saving'
}

export class PlaylistEditRequest {
  name: string = '';
  coverId: string = '';
  coverBytes: Uint8Array = new Uint8Array(0);
  coverFileName: string = 'playlist-cover.png';
  coverMimeType: string = 'image/png';
}

@ComponentV2
export struct PlaylistEditSheet {
  private static readonly defaultCoverCount: number = 4;
  private static readonly maxCoverBytes: number = 5 * 1024 * 1024;
  @Param mode: PlaylistEditMode = PlaylistEditMode.CREATE;
  @Param playlist: MusicPlaylist = new MusicPlaylist();
  @Local name: string = '';
  @Local selectedCoverId: string = 'playlist_default_1';
  @Local customCoverUri: string = '';
  @Local customCoverName: string = '';
  @Local customCoverSize: number = 0;
  @Local customCoverMimeType: string = 'image/png';
  @Local isSaving: boolean = false;
  @Local saveStage: PlaylistSaveStage = PlaylistSaveStage.SAVING;
  @Local errorMessage: string = '';
  private customCoverBytes: Uint8Array = new Uint8Array(0);
  @Event onClose: () => void = (): void => {};
  @Event onSave: (request: PlaylistEditRequest,
    onStage: (stage: PlaylistSaveStage) => void) => Promise<void> =
    (_: PlaylistEditRequest, __: (stage: PlaylistSaveStage) => void): Promise<void> => Promise.resolve();
  @Event onDelete: () => void = (): void => {};

  aboutToAppear(): void {
    this.name = this.mode === PlaylistEditMode.EDIT ? this.playlist.name : '';
    const currentCover = this.mode === PlaylistEditMode.EDIT ? this.playlist.coverId.trim() : '';
    this.selectedCoverId = currentCover.length > 0 ? currentCover : this.randomDefaultCoverId(0);
    this.customCoverUri = '';
    this.customCoverName = '';
    this.customCoverSize = 0;
    this.customCoverMimeType = 'image/png';
    this.customCoverBytes = new Uint8Array(0);
    this.errorMessage = '';
    this.isSaving = false;
  }

  private defaultCoverIndex(coverId: string): number {
    for (let index = 1; index <= PlaylistEditSheet.defaultCoverCount; index++) {
      if (coverId === `playlist_default_${index}`) {
        return index;
      }
    }
    return 0;
  }

  private randomDefaultCoverId(currentIndex: number): string {
    if (currentIndex < 1 || currentIndex > PlaylistEditSheet.defaultCoverCount) {
      return `playlist_default_${Math.floor(Math.random() * PlaylistEditSheet.defaultCoverCount) + 1}`;
    }
    const shift = Math.floor(Math.random() * (PlaylistEditSheet.defaultCoverCount - 1)) + 1;
    return `playlist_default_${((currentIndex - 1 + shift) % PlaylistEditSheet.defaultCoverCount) + 1}`;
  }

  private switchDefaultCover(): void {
    if (this.isSaving) {
      return;
    }
    this.selectedCoverId = this.randomDefaultCoverId(this.defaultCoverIndex(this.selectedCoverId));
    this.clearLocalCover();
    this.errorMessage = '';
  }

  private clearLocalCover(): void {
    this.customCoverUri = '';
    this.customCoverName = '';
    this.customCoverSize = 0;
    this.customCoverMimeType = 'image/png';
    this.customCoverBytes = new Uint8Array(0);
  }

  private hasCustomCover(): boolean {
    if (this.customCoverUri.length > 0) {
      return true;
    }
    return this.mode === PlaylistEditMode.EDIT && this.selectedCoverId.length > 0 &&
      this.defaultCoverIndex(this.selectedCoverId) === 0;
  }

  private removeCustomCover(): void {
    if (this.isSaving || !this.hasCustomCover()) {
      return;
    }
    this.selectedCoverId = this.randomDefaultCoverId(0);
    this.clearLocalCover();
    this.errorMessage = '';
  }

  private async selectCustomCover(): Promise<void> {
    if (this.isSaving) {
      return;
    }
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = 1;
    try {
      const result = await new photoAccessHelper.PhotoViewPicker().select(options);
      if (result.photoUris.length === 0) {
        return;
      }
      const uri = result.photoUris[0];
      const bytes = this.readCoverBytes(uri);
      const extension = this.detectImageExtension(bytes);
      if (extension.length === 0) {
        throw new Error('仅支持 JPG、JPEG、PNG 或 WEBP 图片');
      }
      this.customCoverUri = uri;
      this.customCoverBytes = bytes;
      this.customCoverSize = bytes.length;
      this.customCoverMimeType = extension === 'jpg' ? 'image/jpeg' : `image/${extension}`;
      this.customCoverName = `playlist-cover.${extension}`;
      this.errorMessage = '';
    } catch (error) {
      this.errorMessage = (error as Error).message || '图片读取失败，请重新选择';
    }
  }

  private readCoverBytes(uri: string): Uint8Array {
    let file: fileIo.File | undefined = undefined;
    try {
      file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(file.fd);
      if (stat.size <= 0) {
        throw new Error('所选图片为空');
      }
      if (stat.size > PlaylistEditSheet.maxCoverBytes) {
        throw new Error('图片不能超过 5MB');
      }
      const bytes = new Uint8Array(stat.size);
      let totalRead = 0;
      while (totalRead < stat.size) {
        const chunkLength = Math.min(1024 * 1024, stat.size - totalRead);
        const chunk = new ArrayBuffer(chunkLength);
        const readLength = fileIo.readSync(file.fd, chunk, { length: chunkLength });
        if (readLength <= 0) {
          break;
        }
        bytes.set(new Uint8Array(chunk, 0, readLength), totalRead);
        totalRead += readLength;
      }
      if (totalRead !== stat.size) {
        throw new Error('图片读取不完整，请重新选择');
      }
      return bytes;
    } finally {
      if (file !== undefined) {
        fileIo.closeSync(file);
      }
    }
  }

  private detectImageExtension(bytes: Uint8Array): string {
    if (bytes.length >= 8 && bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4e &&
      bytes[3] === 0x47 && bytes[4] === 0x0d && bytes[5] === 0x0a && bytes[6] === 0x1a && bytes[7] === 0x0a) {
      return 'png';
    }
    if (bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
      return 'jpg';
    }
    if (bytes.length >= 12 && bytes[0] === 0x52 && bytes[1] === 0x49 && bytes[2] === 0x46 &&
      bytes[3] === 0x46 && bytes[8] === 0x57 && bytes[9] === 0x45 && bytes[10] === 0x42 && bytes[11] === 0x50) {
      return 'webp';
    }
    return '';
  }

  private formatCoverSize(): string {
    if (this.customCoverSize <= 0) {
      const index = this.defaultCoverIndex(this.selectedCoverId);
      return index > 0 ? `默认封面 ${index} / ${PlaylistEditSheet.defaultCoverCount}` : '当前歌单封面';
    }
    const value = this.customCoverSize / (1024 * 1024);
    return `${value.toFixed(value >= 1 ? 1 : 2)} MB`;
  }

  private canSubmit(): boolean {
    return !this.isSaving && this.name.trim().length > 0;
  }

  private async submit(): Promise<void> {
    const normalizedName = this.name.trim();
    if (normalizedName.length === 0 || this.isSaving) {
      return;
    }
    const request = new PlaylistEditRequest();
    request.name = normalizedName;
    request.coverId = this.selectedCoverId;
    request.coverBytes = this.customCoverBytes;
    request.coverFileName = this.customCoverName.length > 0 ? this.customCoverName : 'playlist-cover.png';
    request.coverMimeType = this.customCoverMimeType;
    this.errorMessage = '';
    this.isSaving = true;
    this.saveStage = request.coverBytes.length > 0 ? PlaylistSaveStage.UPLOADING : PlaylistSaveStage.SAVING;
    try {
      await this.onSave(request, (stage: PlaylistSaveStage): void => {
        this.saveStage = stage;
      });
      this.onClose();
    } catch (error) {
      this.errorMessage = (error as Error).message || '歌单保存失败，请重试';
    } finally {
      this.isSaving = false;
    }
  }

  private saveButtonText(): string {
    if (!this.isSaving) {
      return this.mode === PlaylistEditMode.CREATE ? '创建歌单' : '保存修改';
    }
    return this.saveStage === PlaylistSaveStage.UPLOADING ? '正在上传封面' :
      (this.mode === PlaylistEditMode.CREATE ? '正在创建歌单' : '正在保存修改');
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.scrim'))
        .hitTestBehavior(HitTestMode.Block)
        .onClick((): void => {
          if (!this.isSaving) {
            this.onClose();
          }
        })

      Column({ space: FnMusicUI.contentGap }) {
        Row() {
          Column({ space: 2 }) {
            Text(this.mode === PlaylistEditMode.CREATE ? '新建歌单' : '编辑歌单')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            Text(this.mode === PlaylistEditMode.CREATE ? '给喜欢的音乐准备一个新空间' : '调整歌单名称和封面')
              .fontSize(FnMusicUI.supportingSize)
              .fontColor($r('app.color.text_secondary'))
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
          Button({ type: ButtonType.Circle }) {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(18)
              .fontColor([$r('app.color.text_primary')])
          }
          .width(FnMusicUI.tapTarget)
          .height(FnMusicUI.tapTarget)
          .backgroundColor(Color.Transparent)
          .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
          .enabled(!this.isSaving)
          .opacity(this.isSaving ? 0.45 : 1)
          .accessibilityText('关闭')
          .onClick((): void => this.onClose())
        }
        .width('100%')

        Column({ space: 10 }) {
          Stack({ alignContent: Alignment.Center }) {
            if (this.customCoverUri.length > 0) {
              Image(this.customCoverUri)
                .width(FnMusicUI.albumGridItemSize)
                .height(FnMusicUI.albumGridItemSize)
                .objectFit(ImageFit.Cover)
                .borderRadius(FnMusicUI.cardRadius)
            } else {
              MusicArtwork({
                artworkSize: FnMusicUI.albumGridItemSize,
                radius: FnMusicUI.cardRadius,
                coverId: this.selectedCoverId,
                placeholderMedia: $r('app.media.music_album_placeholder')
              })
            }

            Row({ space: 6 }) {
              Button({ type: ButtonType.Circle }) {
                SymbolGlyph($r('sys.symbol.arrow_clockwise'))
                  .fontSize(17)
                  .fontColor([$r('app.color.text_primary')])
              }
              .width(36)
              .height(36)
              .backgroundColor(Color.Transparent)
              .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.FLOATING_NAVIGATION))
              .enabled(!this.isSaving)
              .accessibilityText('更换默认封面')
              .onClick((): void => this.switchDefaultCover())

              Button({ type: ButtonType.Circle }) {
                SymbolGlyph($r('sys.symbol.trash'))
                  .fontSize(17)
                  .fontColor([this.hasCustomCover() ? $r('app.color.text_primary') :
                    $r('app.color.text_secondary')])
              }
              .width(36)
              .height(36)
              .backgroundColor(Color.Transparent)
              .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.FLOATING_NAVIGATION))
              .enabled(!this.isSaving && this.hasCustomCover())
              .opacity(this.hasCustomCover() ? 1 : 0.45)
              .accessibilityText('删除自定义封面')
              .onClick((): void => this.removeCustomCover())

              Button({ type: ButtonType.Circle }) {
                SymbolGlyph($r('sys.symbol.plus_circle'))
                  .fontSize(18)
                  .fontColor([$r('app.color.text_primary')])
              }
              .width(36)
              .height(36)
              .backgroundColor(Color.Transparent)
              .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.FLOATING_NAVIGATION))
              .enabled(!this.isSaving)
              .accessibilityText('选择自定义封面')
              .onClick((): void => {
                this.selectCustomCover();
              })
            }
            .padding(4)
            .position({ x: 20, y: 116 })
          }
          .width(FnMusicUI.albumGridItemSize)
          .height(FnMusicUI.albumGridItemSize)

          Text(this.formatCoverSize())
            .fontSize(FnMusicUI.supportingSize)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
          Text('支持 JPG、JPEG、PNG、WEBP，最大 5MB')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')

        Column({ space: 6 }) {
          Text('歌单名称')
            .fontSize(FnMusicUI.supportingSize)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
          TextInput({ text: this.name, placeholder: '请输入歌单名称' })
            .width('100%')
            .height(FnMusicUI.searchHeight)
            .fontSize(FnMusicUI.bodySize)
            .fontColor($r('app.color.text_primary'))
            .placeholderColor($r('app.color.text_secondary'))
            .padding({ left: 14, right: 14 })
            .borderRadius(FnMusicUI.controlRadius)
            .backgroundColor($r('app.color.surface_secondary'))
            .maxLength(32)
            .enabled(!this.isSaving)
            .onChange((value: string): void => {
              this.name = value;
              if (this.errorMessage.length > 0) {
                this.errorMessage = '';
              }
            })
            .onSubmit((): void => {
              this.submit();
            })
          Text(`${this.name.length} / 32`)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        if (this.errorMessage.length > 0) {
          Row({ space: 6 }) {
            SymbolGlyph($r('sys.symbol.exclamationmark_circle_fill'))
              .fontSize(16)
              .fontColor([$r('app.color.danger')])
            Text(this.errorMessage)
              .fontSize(FnMusicUI.supportingSize)
              .fontColor($r('app.color.danger'))
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        }

        Row({ space: 10 }) {
          Button('取消')
            .layoutWeight(1)
            .height(FnMusicUI.actionHeight)
            .fontSize(FnMusicUI.bodySize)
            .fontColor($r('app.color.text_primary'))
            .backgroundColor(Color.Transparent)
            .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
            .borderRadius(FnMusicUI.controlRadius)
            .enabled(!this.isSaving)
            .opacity(this.isSaving ? 0.45 : 1)
            .onClick((): void => this.onClose())

          Button() {
            Row({ space: 7 }) {
              if (this.isSaving) {
                LoadingProgress()
                  .width(17)
                  .height(17)
                  .color($r('app.color.accent_contrast'))
              }
              Text(this.saveButtonText())
                .fontSize(FnMusicUI.bodySize)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.accent_contrast'))
            }
          }
          .layoutWeight(1.45)
          .height(FnMusicUI.actionHeight)
          .backgroundColor($r('app.color.accent'))
          .borderRadius(FnMusicUI.controlRadius)
          .enabled(this.canSubmit())
          .opacity(this.canSubmit() || this.isSaving ? 1 : 0.45)
          .onClick((): void => {
            this.submit();
          })
        }
        .width('100%')

        if (this.mode === PlaylistEditMode.EDIT) {
          SettingsRow({
            title: '删除歌单',
            subtitle: '不会删除音乐文件',
            symbol: $r('sys.symbol.trash'),
            destructive: true,
            showChevron: false,
            onSelect: (): void => {
              if (!this.isSaving) {
                this.onDelete();
              }
            }
          })
        }
      }
      .width('calc(100% - 28vp)')
      .padding({ left: 18, right: 18, top: 16, bottom: 18 })
      .borderRadius(FnMusicUI.cardRadius)
      .backgroundColor(Color.Transparent)
      .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.FLOATING_NAVIGATION))
      .onClick((): void => {})
      .transition(
        TransitionEffect.scale({ x: 0.96, y: 0.96 })
          .combine(TransitionEffect.translate({ y: 12 }))
          .combine(TransitionEffect.OPACITY)
          .animation({ duration: 220, curve: Curve.FastOutSlowIn })
      )
    }
    .width('100%')
    .height('100%')
    .zIndex(50)
    .transition(TransitionEffect.OPACITY.animation({ duration: 180, curve: Curve.EaseOut }))
  }
}
