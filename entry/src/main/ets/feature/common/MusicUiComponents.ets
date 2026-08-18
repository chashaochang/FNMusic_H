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
  icon?: Resource;
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

  private foreground(): ResourceColor {
    if (this.transparentSurface) {
      return $r('app.color.text_primary');
    }
    return this.selected ? $r('app.color.music_chip_selected_text') : $r('app.color.text_primary');
  }

  build() {
    if (this.transparentSurface) {
      Row({ space: 6 }) {
        if (this.item.icon !== undefined) {
          Image(this.item.icon)
            .width(16)
            .height(16)
            .objectFit(ImageFit.Contain)
            .fillColor(this.foreground())
        }
        Text(this.item.title)
          .fontSize(14)
          .fontWeight(this.selected ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(this.foreground())
          .maxLines(1)
      }
        .height(FnMusicUI.chipHeight)
        .padding({ left: 13, right: 13 })
        .backgroundColor(Color.Transparent)
        .alignItems(VerticalAlign.Center)
        .onClick((): void => {
          this.onSelect(this.item.id);
        })
    } else {
      Row({ space: 6 }) {
        if (this.item.icon !== undefined) {
          Image(this.item.icon)
            .width(16)
            .height(16)
            .objectFit(ImageFit.Contain)
            .fillColor(this.foreground())
        }
        Text(this.item.title)
          .fontSize(14)
          .fontWeight(this.selected ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(this.foreground())
          .maxLines(1)
      }
        .height(FnMusicUI.chipHeight)
        .padding({ left: 13, right: 13 })
        .backgroundColor(Color.Transparent)
        .borderRadius(FnMusicUI.chipHeight / 2)
        .clip(true)
        .attributeModifier(FnMusicMaterials.modifier(this.selected ?
          FnMusicMaterialRole.MUSIC_CHIP_SELECTED : FnMusicMaterialRole.CHIP))
        .alignItems(VerticalAlign.Center)
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
  @Param scroller: Scroller = new Scroller();
  @Event onSelect: (id: string) => void = (_: string): void => {};

  build() {
    List({ space: FnMusicUI.compactGap, scroller: this.scroller }) {
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
    .clip(true)
  }
}

@ComponentV2
export struct MusicArtwork {
  @Param artworkSize: number = 44;
  @Param fill: boolean = false;
  @Param radius: number = FnMusicUI.cardRadius;
  @Param symbol: Resource = $r('sys.symbol.music');
  @Param placeholderMedia?: Resource = undefined;
  @Param placeholderRatio: number = 0.34;
  @Param showPlaceholderSymbol: boolean = true;
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
          .width(Math.max(18, Math.round(this.artworkSize * this.placeholderRatio)))
          .height(Math.max(18, Math.round(this.artworkSize * this.placeholderRatio)))
          .objectFit(ImageFit.Contain)
      } else if (this.showPlaceholderSymbol) {
        SymbolGlyph(this.symbol)
          .fontSize(Math.max(18, Math.round(this.artworkSize * 0.38)))
          .fontColor([$r('app.color.accent')])
      }
    }
    .width(this.fill ? '100%' : this.artworkSize)
    .height(this.fill ? '100%' : this.artworkSize)
    .borderRadius(this.radius)
    .backgroundColor($r('app.color.artwork_placeholder'))
    .clip(true)
  }
}

@ComponentV2
export struct RoamPulseIcon {
  @Param iconSize: number = 22;
  @Param lightContent: boolean = false;
  @Local pulsing: boolean = false;

  aboutToAppear(): void {
    setTimeout((): void => {
      this.pulsing = true;
    }, 40);
  }

  private outerMedia(): Resource {
    return this.lightContent ? $r('app.media.home_roam_outer') : $r('app.media.mini_player_roam_outer');
  }

  private innerMedia(): Resource {
    return this.lightContent ? $r('app.media.home_roam_inner') : $r('app.media.mini_player_roam_inner');
  }

  private dotMedia(): Resource {
    return this.lightContent ? $r('app.media.home_roam_dot') : $r('app.media.mini_player_roam_dot');
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Image(this.outerMedia())
        .width(this.iconSize)
        .height(this.iconSize)
        .objectFit(ImageFit.Contain)
        .opacity(this.pulsing ? 1 : 0.32)
        .scale({ x: this.pulsing ? 1 : 0.966, y: this.pulsing ? 1 : 0.966 })
        .animation({
          duration: 920,
          curve: Curve.EaseInOut,
          iterations: -1,
          playMode: PlayMode.Alternate
        })
      Image(this.innerMedia())
        .width(this.iconSize)
        .height(this.iconSize)
        .objectFit(ImageFit.Contain)
        .opacity(this.pulsing ? 0.46 : 1)
        .scale({ x: this.pulsing ? 0.97 : 1, y: this.pulsing ? 0.97 : 1 })
        .animation({
          duration: 680,
          curve: Curve.EaseInOut,
          iterations: -1,
          playMode: PlayMode.Alternate
        })
      Image(this.dotMedia())
        .width(this.iconSize)
        .height(this.iconSize)
        .objectFit(ImageFit.Contain)
        .opacity(this.pulsing ? 1 : 0.8)
        .scale({ x: this.pulsing ? 1 : 0.98, y: this.pulsing ? 1 : 0.98 })
        .animation({
          duration: 540,
          curve: Curve.EaseInOut,
          iterations: -1,
          playMode: PlayMode.Alternate
        })
    }
    .width(this.iconSize)
    .height(this.iconSize)
    .hitTestBehavior(HitTestMode.None)
  }
}

@ComponentV2
export struct VerticalMoreDots {
  @Param color: ResourceColor = $r('app.color.text_secondary');

  build() {
    Column({ space: 4 }) {
      Row()
        .width(3)
        .height(3)
        .borderRadius(2)
        .backgroundColor(this.color)
      Row()
        .width(3)
        .height(3)
        .borderRadius(2)
        .backgroundColor(this.color)
    }
    .width(20)
    .height(20)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .hitTestBehavior(HitTestMode.None)
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
          .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
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
  @Param showTitle: boolean = true;
  @Param backgroundOpacity: number = 0;
  @Param headerBackground: ResourceColor = $r('app.color.page_background');
  @Param trailingSymbol?: Resource = undefined;
  @Param trailingDots: boolean = false;
  @Event onBack: () => void = (): void => {};
  @Event onTrailing: () => void = (): void => {};

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.headerBackground)
        .opacity(Math.max(0, Math.min(1, this.backgroundOpacity)))
        .hitTestBehavior(HitTestMode.None)

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
        .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
        .accessibilityText('返回')
        .onClick((): void => {
          this.onBack();
        })

        if (this.showTitle) {
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
        } else {
          Blank().layoutWeight(1)
        }

        if (this.trailingDots || this.trailingSymbol !== undefined) {
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            if (this.trailingDots) {
              VerticalMoreDots({ color: $r('app.color.text_primary') })
            } else {
              SymbolGlyph(this.trailingSymbol)
                .fontSize(22)
                .fontColor([$r('app.color.text_primary')])
            }
          }
          .width(FnMusicUI.tapTarget)
          .height(FnMusicUI.tapTarget)
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .backgroundColor(Color.Transparent)
          .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
          .accessibilityText('更多操作')
          .onClick((): void => {
            this.onTrailing();
          })
        }
      }
      .width('100%')
      .height('100%')
      .alignItems(VerticalAlign.Center)
      .padding({
        left: FnMusicUI.pagePadding,
        right: FnMusicUI.pagePadding,
        top: Math.max(0, this.safeTop)
      })
    }
    .width('100%')
    .height(Math.max(0, this.safeTop) + FnMusicUI.homeActionBarHeight)
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
          placeholderMedia: $r('app.media.music_track_placeholder'),
          placeholderRatio: 0.56,
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
        VerticalMoreDots()
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
        placeholderMedia: $r('app.media.music_album_placeholder'),
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
        showPlaceholderSymbol: false,
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
          placeholderMedia: $r('app.media.music_album_placeholder'),
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

export enum MusicEmptyKind {
  CONTENT = 'content',
  SEARCH = 'search',
  LIST = 'list',
  LOAD_FAILED = 'load_failed',
  NETWORK_ERROR = 'network_error',
  NOT_FOUND = 'not_found'
}

@ComponentV2
export struct EmptyMusicState {
  @Param kind: MusicEmptyKind = MusicEmptyKind.CONTENT;
  @Param title: string = '空空如也';
  @Param message: string = '';
  @Param compact: boolean = false;
  @Param illustrationSize: number = 0;
  @Param actionTitle: string = '';
  @Param actionEnabled: boolean = true;
  @Event onAction: () => void = (): void => {};

  private illustration(): Resource {
    switch (this.kind) {
      case MusicEmptyKind.SEARCH:
        return $r('app.media.music_empty_search');
      case MusicEmptyKind.LIST:
        return $r('app.media.music_empty_list');
      case MusicEmptyKind.LOAD_FAILED:
        return $r('app.media.music_empty_load_failed');
      case MusicEmptyKind.NETWORK_ERROR:
        return $r('app.media.music_empty_network_error');
      case MusicEmptyKind.NOT_FOUND:
        return $r('app.media.music_empty_not_found');
      case MusicEmptyKind.CONTENT:
      default:
        return $r('app.media.music_empty_content');
    }
  }

  private resolvedIllustrationSize(): number {
    if (this.illustrationSize > 0) {
      return this.illustrationSize;
    }
    return this.compact ? FnMusicUI.emptyCompactIllustrationSize : FnMusicUI.emptyIllustrationSize;
  }

  build() {
    Column({ space: FnMusicUI.emptyIllustrationGap }) {
      Image(this.illustration())
        .width(this.resolvedIllustrationSize())
        .height(this.resolvedIllustrationSize())
        .objectFit(ImageFit.Contain)

      Column({ space: FnMusicUI.emptyTextGap }) {
        Text(this.title)
          .fontSize(FnMusicUI.emptyTitleSize)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_secondary'))
          .textAlign(TextAlign.Center)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.message.length > 0) {
          Text(this.message)
            .fontSize(FnMusicUI.supportingSize)
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Center)
            .lineHeight(20)
            .maxLines(3)
        }

        if (this.actionTitle.length > 0) {
          Blank().height(4)
          Button(this.actionTitle, { type: ButtonType.Normal, stateEffect: true })
            .height(FnMusicUI.emptyActionHeight)
            .padding({ left: 16, right: 16 })
            .fontSize(FnMusicUI.supportingSize)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.accent_contrast'))
            .backgroundColor($r('app.color.accent'))
            .borderRadius(FnMusicUI.emptyActionHeight / 2)
            .enabled(this.actionEnabled)
            .onClick((): void => this.onAction())
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .padding({
      top: this.compact ? FnMusicUI.emptyCompactTopPadding : FnMusicUI.emptyTopPadding,
      bottom: this.compact ? FnMusicUI.emptyCompactBottomPadding : FnMusicUI.emptyBottomPadding,
      left: 24,
      right: 24
    })
    .alignItems(HorizontalAlign.Center)
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
    Row({ space: FnMusicUI.settingsRowGap }) {
      Stack() {
        SymbolGlyph(this.symbol)
          .fontSize(FnMusicUI.settingsIconSize)
          .fontColor([this.destructive ? $r('app.color.danger') : $r('sys.color.icon_secondary')])
      }
      .width(FnMusicUI.settingsIconContainerSize)
      .height(FnMusicUI.settingsIconContainerSize)
      .backgroundColor(Color.Transparent)

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
    .padding({ right: 4 })
    .onClick((): void => {
      this.onSelect();
    })
  }
}
