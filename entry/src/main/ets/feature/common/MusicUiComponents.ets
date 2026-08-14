import { FnMusicUI } from '../../design/FnMusicUI';
import { FnMusicMaterialRole, FnMusicMaterials } from '../../design/FnMusicMaterials';
import { image } from '@kit.ImageKit';
import { CoverArtStore } from '../../common/CoverArtStore';
import {
  MusicAlbum,
  MusicArtist,
  MusicGenre,
  MusicPlaylist,
  MusicTrack,
  formatDuration
} from '../../model/MusicModels';

export interface MusicChipItem {
  id: string;
  title: string;
}

export interface MusicListCommand {
  id: string;
  title: string;
  symbol: Resource;
  destructive?: boolean;
}

@ComponentV2
export struct MusicChip {
  @Param item: MusicChipItem = { id: '', title: '' };
  @Param selected: boolean = false;
  @Param transparentSurface: boolean = false;
  @Event onSelect: (id: string) => void = (_: string): void => {};

  build() {
    if (this.transparentSurface) {
      Text(this.item.title)
        .height(FnMusicUI.chipHeight)
        .padding({ left: 15, right: 15 })
        .fontSize(14)
        .fontWeight(this.selected ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.selected ? $r('app.color.accent') : $r('app.color.text_primary'))
        .backgroundColor(Color.Transparent)
        .maxLines(1)
        .onClick((): void => {
          this.onSelect(this.item.id);
        })
    } else {
      Text(this.item.title)
        .height(FnMusicUI.chipHeight)
        .padding({ left: 15, right: 15 })
        .fontSize(14)
        .fontWeight(this.selected ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.selected ? $r('app.color.accent') : $r('app.color.text_primary'))
        .backgroundColor(Color.Transparent)
        .borderRadius(FnMusicUI.chipHeight / 2)
        .clip(true)
        .systemMaterial(FnMusicMaterials.material(this.selected ?
          FnMusicMaterialRole.CHIP_SELECTED : FnMusicMaterialRole.CHIP))
        .maxLines(1)
        .onClick((): void => {
          this.onSelect(this.item.id);
        })
    }
  }
}

@ComponentV2
export struct MusicChipStrip {
  @Param items: MusicChipItem[] = [];
  @Param selectedId: string = '';
  @Param transparentSurface: boolean = false;
  @Event onSelect: (id: string) => void = (_: string): void => {};

  build() {
    List({ space: FnMusicUI.compactGap }) {
      Repeat<MusicChipItem>(this.items)
        .each((repeatItem: RepeatItem<MusicChipItem>): void => {
          ListItem() {
            MusicChip({
              item: repeatItem.item,
              selected: repeatItem.item.id === this.selectedId,
              transparentSurface: this.transparentSurface,
              onSelect: (id: string): void => {
                this.onSelect(id);
              }
            })
          }
        })
        .key((item: MusicChipItem): string => item.id)
    }
    .listDirection(Axis.Horizontal)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .height(FnMusicUI.chipHeight)
  }
}

@ComponentV2
export struct MusicArtwork {
  @Param artworkSize: number = 44;
  @Param radius: number = FnMusicUI.cardRadius;
  @Param symbol: Resource = $r('sys.symbol.music');
  @Param placeholderMedia?: Resource = undefined;
  @Param coverId: string = '';
  @Param updatedAt: number = 0;
  @Local pixelMap?: image.PixelMap = undefined;

  aboutToAppear(): void {
    this.loadCover();
  }

  @Monitor('coverId', 'updatedAt')
  onCoverChanged(): void {
    this.loadCover();
  }

  private loadCover(): void {
    const coverId = this.coverId.trim();
    const updatedAt = this.updatedAt;
    if (coverId.length === 0) {
      this.pixelMap = undefined;
      return;
    }
    const targetSize = Math.max(96, Math.round(this.artworkSize * 3));
    const cached = CoverArtStore.cached(coverId, targetSize, updatedAt);
    if (cached !== undefined) {
      this.pixelMap = cached;
      return;
    }
    this.pixelMap = undefined;
    CoverArtStore.load(coverId, targetSize, updatedAt).then((pixelMap?: image.PixelMap): void => {
      if (this.coverId.trim() === coverId && this.updatedAt === updatedAt) {
        this.pixelMap = pixelMap;
      }
    }).catch((): void => {});
  }

  build() {
    Stack() {
      if (this.pixelMap !== undefined) {
        Image(this.pixelMap)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
      } else if (this.placeholderMedia !== undefined) {
        Image(this.placeholderMedia)
          .width(Math.max(32, Math.round(this.artworkSize * 0.34)))
          .height(Math.max(32, Math.round(this.artworkSize * 0.34)))
          .objectFit(ImageFit.Contain)
      } else {
        SymbolGlyph(this.symbol)
          .fontSize(Math.max(18, Math.round(this.artworkSize * 0.38)))
          .fontColor([$r('app.color.accent')])
      }
    }
    .width(this.artworkSize)
    .height(this.artworkSize)
    .borderRadius(this.radius)
    .backgroundColor($r('app.color.artwork_placeholder'))
    .clip(true)
  }
}

@ComponentV2
export struct SectionHeader {
  @Param title: string = '';
  @Param supporting: string = '';
  @Param actionTitle: string = '';
  @Event onAction: () => void = (): void => {};

  build() {
    Row({ space: FnMusicUI.compactGap }) {
      Column({ space: 2 }) {
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.supporting.length > 0) {
          Text(this.supporting)
            .fontSize(FnMusicUI.supportingSize)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.actionTitle.length > 0) {
        Button(this.actionTitle, { type: ButtonType.Capsule })
          .height(36)
          .padding({ left: 12, right: 12 })
          .fontSize(14)
          .fontColor($r('app.color.accent'))
          .backgroundColor(Color.Transparent)
          .systemMaterial(FnMusicMaterials.material(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
          .borderRadius(FnMusicUI.controlRadius)
          .onClick((): void => {
            this.onAction();
          })
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }
}

@ComponentV2
export struct SecondaryPageHeader {
  @Param title: string = '';
  @Param subtitle: string = '';
  @Param safeTop: number = 0;
  @Param trailingSymbol?: Resource = undefined;
  @Event onBack: () => void = (): void => {};
  @Event onTrailing: () => void = (): void => {};

  build() {
    Row({ space: FnMusicUI.compactGap }) {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.chevron_backward'))
          .fontSize(23)
          .fontColor([$r('app.color.text_primary')])
      }
      .width(FnMusicUI.tapTarget)
      .height(FnMusicUI.tapTarget)
      .buttonStyle(ButtonStyleMode.TEXTUAL)
      .backgroundColor(Color.Transparent)
      .systemMaterial(FnMusicMaterials.material(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
      .accessibilityText('返回')
      .onClick((): void => {
        this.onBack();
      })

      Column({ space: 1 }) {
        Text(this.title)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.subtitle.length > 0) {
          Text(this.subtitle)
            .fontSize(FnMusicUI.supportingSize)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.trailingSymbol !== undefined) {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph(this.trailingSymbol)
            .fontSize(22)
            .fontColor([$r('app.color.text_primary')])
        }
        .width(FnMusicUI.tapTarget)
        .height(FnMusicUI.tapTarget)
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .backgroundColor(Color.Transparent)
        .systemMaterial(FnMusicMaterials.material(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
        .accessibilityText('更多操作')
        .onClick((): void => {
          this.onTrailing();
        })
      }
    }
    .width('100%')
    .height(Math.max(0, this.safeTop) + FnMusicUI.homeActionBarHeight)
    .alignItems(VerticalAlign.Center)
    .padding({
      left: FnMusicUI.pagePadding,
      right: FnMusicUI.pagePadding,
      top: Math.max(0, this.safeTop)
    })
    .backgroundColor(Color.Transparent)
  }
}

@ComponentV2
export struct TrackRow {
  @Param track: MusicTrack = new MusicTrack();
  @Param index: number = 0;
  @Param showIndex: boolean = false;
  @Event onPlay: (index: number) => void = (_: number): void => {};
  @Event onMore: (track: MusicTrack) => void = (_: MusicTrack): void => {};

  build() {
    Row({ space: FnMusicUI.contentGap }) {
      if (this.showIndex) {
        Text(`${this.index + 1}`)
          .width(24)
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.text_secondary'))
          .textAlign(TextAlign.Center)
      } else {
        MusicArtwork({
          artworkSize: 42,
          radius: 6,
          coverId: this.track.coverId,
          updatedAt: this.track.updatedAt
        })
      }

      Column({ space: 2 }) {
        Row({ space: 5 }) {
          Text(this.track.title)
            .layoutWeight(1)
            .fontSize(FnMusicUI.bodySize)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.track.isFavorite) {
            SymbolGlyph($r('sys.symbol.heart_fill'))
              .fontSize(14)
              .fontColor([$r('app.color.accent')])
          }
        }
        .width('100%')

        Text(this.track.artistName.length > 0 ? `${this.track.artistName} · ${this.track.albumName}` : this.track.albumName)
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .onClick((): void => {
        this.onPlay(this.index);
      })

      Text(formatDuration(this.track.durationMs))
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.more'))
          .fontSize(21)
          .fontColor([$r('app.color.text_secondary')])
      }
      .width(38)
      .height(38)
      .backgroundColor($r('app.color.transparent'))
      .accessibilityText(`${this.track.title} 更多操作`)
      .onClick((): void => {
        this.onMore(this.track);
      })
    }
    .width('100%')
    .height(FnMusicUI.listRowHeight)
    .alignItems(VerticalAlign.Center)
  }
}

@ComponentV2
export struct AlbumRow {
  @Param album: MusicAlbum = new MusicAlbum();
  @Event onOpen: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};

  build() {
    Row({ space: FnMusicUI.contentGap }) {
      MusicArtwork({
        artworkSize: 52,
        radius: FnMusicUI.cardRadius,
        symbol: $r('sys.symbol.music_note_list'),
        coverId: this.album.coverId,
        updatedAt: this.album.createdAt
      })
      Column({ space: 3 }) {
        Text(this.album.name)
          .fontSize(FnMusicUI.bodySize)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${this.album.trackCount} 首歌曲`)
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(18)
        .fontColor([$r('app.color.text_secondary')])
    }
    .width('100%')
    .height(64)
    .padding({ left: 2, right: 2 })
    .onClick((): void => {
      this.onOpen(this.album);
    })
  }
}

@ComponentV2
export struct ArtistRow {
  @Param artist: MusicArtist = new MusicArtist();
  @Event onOpen: (artist: MusicArtist) => void = (_: MusicArtist): void => {};

  build() {
    Row({ space: FnMusicUI.contentGap }) {
      MusicArtwork({
        artworkSize: 50,
        radius: 25,
        symbol: $r('sys.symbol.person_fill'),
        coverId: this.artist.coverId
      })
      Column({ space: 3 }) {
        Text(this.artist.name)
          .fontSize(FnMusicUI.bodySize)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${this.artist.trackCount} 首歌 · ${this.artist.albumCount} 张专辑`)
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
      }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(18)
        .fontColor([$r('app.color.text_secondary')])
    }
    .width('100%')
    .height(64)
    .onClick((): void => {
      this.onOpen(this.artist);
    })
  }
}

@ComponentV2
export struct GenreRow {
  @Param genre: MusicGenre = new MusicGenre();
  @Event onOpen: (genre: MusicGenre) => void = (_: MusicGenre): void => {};

  build() {
    Row({ space: FnMusicUI.contentGap }) {
      MusicArtwork({
        artworkSize: 48,
        radius: FnMusicUI.cardRadius,
        symbol: $r('sys.symbol.music_badge_wave_2'),
        coverId: this.genre.coverId,
        updatedAt: this.genre.updatedAt
      })
      Column({ space: 2 }) {
        Text(this.genre.name)
          .fontSize(FnMusicUI.bodySize)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Text(`${this.genre.trackCount} 首歌曲`)
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(18)
        .fontColor([$r('app.color.text_secondary')])
    }
    .width('100%')
    .height(64)
    .onClick((): void => {
      this.onOpen(this.genre);
    })
  }
}

@ComponentV2
export struct PlaylistRow {
  @Param playlist: MusicPlaylist = new MusicPlaylist();
  @Event onOpen: (playlist: MusicPlaylist) => void = (_: MusicPlaylist): void => {};
  @Event onMore: (playlist: MusicPlaylist) => void = (_: MusicPlaylist): void => {};

  build() {
    Row({ space: FnMusicUI.contentGap }) {
      Row({ space: FnMusicUI.contentGap }) {
        MusicArtwork({
          artworkSize: 52,
          radius: FnMusicUI.cardRadius,
          symbol: $r('sys.symbol.music_note_list'),
          coverId: this.playlist.coverId,
          updatedAt: this.playlist.updatedAt
        })
        Column({ space: 3 }) {
          Text(this.playlist.name)
            .fontSize(FnMusicUI.bodySize)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(`${this.playlist.trackCount} 首歌曲`)
            .fontSize(FnMusicUI.supportingSize)
            .fontColor($r('app.color.text_secondary'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .height('100%')
      .alignItems(VerticalAlign.Center)
      .onClick((): void => {
        this.onOpen(this.playlist);
      })
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.more'))
          .fontSize(21)
          .fontColor([$r('app.color.text_secondary')])
      }
      .width(38)
      .height(38)
      .backgroundColor($r('app.color.transparent'))
      .accessibilityText(`${this.playlist.name} 更多操作`)
      .onClick((): void => {
        this.onMore(this.playlist);
      })
    }
    .width('100%')
    .height(64)
  }
}

@ComponentV2
export struct EmptyMusicState {
  @Param title: string = '这里还没有内容';
  @Param message: string = '连接服务器后会自动显示你的音乐。';
  @Param symbol: Resource = $r('sys.symbol.music');

  build() {
    Column({ space: FnMusicUI.compactGap }) {
      SymbolGlyph(this.symbol)
        .fontSize(36)
        .fontColor([$r('app.color.accent')])
      Text(this.title)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
      Text(this.message)
        .fontSize(FnMusicUI.supportingSize)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .lineHeight(20)
        .maxLines(3)
    }
    .width('100%')
    .padding({ top: 36, bottom: 36, left: 24, right: 24 })
    .justifyContent(FlexAlign.Center)
  }
}

@ComponentV2
export struct SettingsRow {
  @Param title: string = '';
  @Param subtitle: string = '';
  @Param symbol: Resource = $r('sys.symbol.gearshape');
  @Param destructive: boolean = false;
  @Param showChevron: boolean = true;
  @Event onSelect: () => void = (): void => {};

  build() {
    Row({ space: FnMusicUI.contentGap }) {
      Stack() {
        SymbolGlyph(this.symbol)
          .fontSize(20)
          .fontColor([this.destructive ? $r('app.color.danger') : $r('app.color.accent')])
      }
      .width(36)
      .height(36)
      .borderRadius(FnMusicUI.controlRadius)
      .backgroundColor(this.destructive ? $r('app.color.danger_soft') : $r('app.color.accent_soft'))

      Column({ space: 2 }) {
        Text(this.title)
          .fontSize(FnMusicUI.bodySize)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.destructive ? $r('app.color.danger') : $r('app.color.text_primary'))
        if (this.subtitle.length > 0) {
          Text(this.subtitle)
            .fontSize(FnMusicUI.supportingSize)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.showChevron) {
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(18)
          .fontColor([$r('app.color.text_secondary')])
      }
    }
    .width('100%')
    .height(FnMusicUI.listRowHeight)
    .padding({ left: 10, right: 10 })
    .onClick((): void => {
      this.onSelect();
    })
  }
}
