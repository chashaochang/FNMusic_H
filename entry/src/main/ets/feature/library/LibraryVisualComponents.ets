import { FnMusicUI } from '../../design/FnMusicUI';
import { FnMusicMaterialRole, FnMusicMaterials } from '../../design/FnMusicMaterials';
import {
  CollectionKind,
  MusicAlbum,
  MusicArtist,
  MusicGenre,
  MusicPlaylist,
  MusicTrack,
  formatDuration
} from '../../model/MusicModels';
import { MusicArtwork, MusicChipItem, VerticalMoreDots } from '../common/MusicUiComponents';

function genreLabelMedia(variantIndex: number): Resource {
  const variant = Math.abs(variantIndex) % 4;
  if (variant === 1) return $r('app.media.music_genre_label_orange');
  if (variant === 2) return $r('app.media.music_genre_label_blue');
  if (variant === 3) return $r('app.media.music_genre_label_purple');
  return $r('app.media.music_genre_label_red');
}

@ComponentV2
export struct AlbumGridItem {
  @Param album: MusicAlbum = new MusicAlbum();
  @Param itemWidth: number = FnMusicUI.albumGridItemSize;
  @Param showPlay: boolean = true;
  @Event onOpen: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};
  @Event onPlay: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};

  build() {
    Column({ space: 7 }) {
      Stack({ alignContent: Alignment.BottomEnd }) {
        MusicArtwork({
          artworkSize: this.itemWidth,
          radius: FnMusicUI.albumGridRadius,
          symbol: $r('sys.symbol.music_note_list'),
          placeholderMedia: $r('app.media.music_album_placeholder'),
          coverId: this.album.coverId,
          updatedAt: this.album.createdAt
        })

        Row() {
          Blank()
          Text(`${this.album.trackCount}`)
            .width(36)
            .height(24)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.album_count_badge_text'))
            .textAlign(TextAlign.Center)
            .borderRadius(12)
            .backgroundColor($r('app.color.album_count_badge_bg'))
        }
        .width('100%')
        .height('100%')
        .padding({ top: 8, right: 8 })
        .alignItems(VerticalAlign.Top)
        .hitTestBehavior(HitTestMode.None)

        if (this.showPlay) {
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph($r('sys.symbol.play_fill'))
              .fontSize(17)
              .fontColor([$r('app.color.text_primary')])
          }
          .width(38)
          .height(38)
          .backgroundColor(Color.Transparent)
          .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
          .translate({ x: -8, y: -8 })
          .accessibilityText(`播放专辑 ${this.album.name}`)
          .onClick((): void => this.onPlay(this.album))
        }
      }
      .width(this.itemWidth)
      .height(this.itemWidth)
      .onClick((): void => this.onOpen(this.album))

      Column({ space: 2 }) {
        Text(this.album.name)
          .fontSize(FnMusicUI.bodySize)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.album.artistName.length > 0 ? this.album.artistName : '未知')
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width(this.itemWidth)
      .alignItems(HorizontalAlign.Start)
      .onClick((): void => this.onOpen(this.album))
    }
    .width(this.itemWidth)
    .alignItems(HorizontalAlign.Start)
  }
}

@ComponentV2
export struct AlbumGrid {
  @Param albums: MusicAlbum[] = [];
  @Param itemWidth: number = FnMusicUI.albumGridItemSize;
  @Param showPlay: boolean = true;
  @Event onOpen: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};
  @Event onPlay: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};

  private rowIndexes(): number[] {
    const indexes: number[] = [];
    const rowCount: number = Math.ceil(this.albums.length / 2);
    for (let index: number = 0; index < rowCount; index++) {
      indexes.push(index);
    }
    return indexes;
  }

  build() {
    Column({ space: FnMusicUI.sectionGap }) {
      Repeat<number>(this.rowIndexes())
        .each((repeatItem: RepeatItem<number>): void => {
          Row() {
            AlbumGridItem({
              album: this.albums[repeatItem.item * 2],
              itemWidth: this.itemWidth,
              showPlay: this.showPlay,
              onOpen: (album: MusicAlbum): void => this.onOpen(album),
              onPlay: (album: MusicAlbum): void => this.onPlay(album)
            })
            Blank()
            if (repeatItem.item * 2 + 1 < this.albums.length) {
              AlbumGridItem({
                album: this.albums[repeatItem.item * 2 + 1],
                itemWidth: this.itemWidth,
                showPlay: this.showPlay,
                onOpen: (album: MusicAlbum): void => this.onOpen(album),
                onPlay: (album: MusicAlbum): void => this.onPlay(album)
              })
            } else {
              Blank().width(this.itemWidth)
            }
          }
          .width('100%')
        })
        .key((item: number): string => `${item}`)
    }
    .width('100%')
  }
}

@ComponentV2
export struct AlbumCatalogItem {
  @Param album: MusicAlbum = new MusicAlbum();
  @Param showPlay: boolean = true;
  @Event onOpen: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};
  @Event onPlay: (album: MusicAlbum) => void = (_: MusicAlbum): void => {};

  private metadata(): string {
    const count = this.album.trackCount > 0 ? `${this.album.trackCount} 首` : '歌曲信息';
    return this.album.year > 0 ? `${count} · ${this.album.year}` : count;
  }

  build() {
    Row({ space: FnMusicUI.contentGap }) {
      MusicArtwork({
        artworkSize: FnMusicUI.collectionAlbumArtworkSize,
        radius: 10,
        placeholderMedia: $r('app.media.music_album_placeholder'),
        placeholderRatio: 0.78,
        coverId: this.album.coverId,
        updatedAt: this.album.createdAt
      })

      Column({ space: 4 }) {
        Text(this.album.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.metadata())
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.showPlay) {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph($r('sys.symbol.play_fill'))
            .fontSize(18)
            .fontColor([$r('app.color.text_primary')])
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
        .accessibilityText(`播放专辑 ${this.album.name}`)
        .onClick((): void => this.onPlay(this.album))
      }
    }
    .width('100%')
    .height(FnMusicUI.collectionRowHeight)
    .padding({ left: 4, right: 4 })
    .alignItems(VerticalAlign.Center)
    .onClick((): void => this.onOpen(this.album))
  }
}

@ComponentV2
export struct ArtistCatalogItem {
  @Param artist: MusicArtist = new MusicArtist();
  @Event onOpen: (artist: MusicArtist) => void = (_: MusicArtist): void => {};

  private metadata(): string {
    const tracks = this.artist.trackCount > 0 ? `${this.artist.trackCount} 首歌` : '歌曲信息';
    const albums = this.artist.albumCount > 0 ? `${this.artist.albumCount} 张专辑` : '';
    return albums.length > 0 ? `${tracks} · ${albums}` : tracks;
  }

  build() {
    Row({ space: FnMusicUI.contentGap }) {
      MusicArtwork({
        artworkSize: FnMusicUI.collectionArtistArtworkSize,
        radius: FnMusicUI.collectionArtistArtworkSize / 2,
        symbol: $r('sys.symbol.person_fill'),
        showPlaceholderSymbol: false,
        coverId: this.artist.coverId
      })

      Column({ space: 4 }) {
        Text(this.artist.name)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.metadata())
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

    }
    .width('100%')
    .height(FnMusicUI.collectionRowHeight)
    .padding({ left: 4, right: 4 })
    .alignItems(VerticalAlign.Center)
    .onClick((): void => this.onOpen(this.artist))
  }
}

@ComponentV2
export struct CollectionSegmentedSwitch {
  @Param items: MusicChipItem[] = [];
  @Param selectedId: string = '';
  @Event onSelect: (id: string) => void = (_: string): void => {};

  private isSelected(item: MusicChipItem): boolean {
    return item.id === this.selectedId;
  }

  build() {
    Row({ space: 4 }) {
      Repeat<MusicChipItem>(this.items)
        .each((repeatItem: RepeatItem<MusicChipItem>): void => {
          if (this.isSelected(repeatItem.item)) {
            Button({ type: ButtonType.Capsule, stateEffect: true }) {
              Text(repeatItem.item.title)
                .fontSize(FnMusicUI.bodySize)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.detail_segment_selected_text'))
            }
            .layoutWeight(1)
            .height(FnMusicUI.collectionSegmentHeight - 8)
            .backgroundColor(Color.Transparent)
            .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.DETAIL_SEGMENT_SELECTED))
            .onClick((): void => this.onSelect(repeatItem.item.id))
          } else {
            Button({ type: ButtonType.Capsule, stateEffect: true }) {
              Text(repeatItem.item.title)
                .fontSize(FnMusicUI.bodySize)
                .fontWeight(FontWeight.Regular)
                .fontColor($r('app.color.text_secondary'))
            }
            .layoutWeight(1)
            .height(FnMusicUI.collectionSegmentHeight - 8)
            .backgroundColor(Color.Transparent)
            .onClick((): void => this.onSelect(repeatItem.item.id))
          }
        })
        .key((item: MusicChipItem): string => item.id)
    }
    .width('100%')
    .height(FnMusicUI.collectionSegmentHeight)
    .padding(4)
    .borderRadius(FnMusicUI.collectionSegmentHeight / 2)
    .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.CHIP))
  }
}

@ComponentV2
export struct CollectionActionRow {
  @Param count: number = 0;
  @Param loading: boolean = false;
  @Event onPlayAll: () => void = (): void => {};
  @Event onMore: () => void = (): void => {};

  build() {
    Row({ space: FnMusicUI.compactGap }) {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        if (this.loading) {
          LoadingProgress()
            .width(18)
            .height(18)
            .color($r('app.color.accent_contrast'))
        } else {
          SymbolGlyph($r('sys.symbol.play_fill'))
            .fontSize(16)
            .fontColor([$r('app.color.accent_contrast')])
        }
      }
      .width(40)
      .height(40)
      .backgroundColor($r('app.color.accent'))
      .enabled(this.count > 0 && !this.loading)
      .opacity(this.count > 0 ? 1 : 0.38)
      .accessibilityText(this.loading ? '正在加载全部歌曲' : `播放全部 ${this.count} 首`)
      .onClick((): void => this.onPlayAll())

      Text(this.loading ? '正在加载全部歌曲' : `播放全部 ${this.count}`)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Blank()

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.sort'))
          .fontSize(20)
          .fontColor([$r('app.color.text_secondary')])
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .enabled(!this.loading)
      .opacity(this.loading ? 0.38 : 1)
      .accessibilityText('排序')
      .onClick((): void => this.onMore())
    }
    .width('100%')
    .height(FnMusicUI.collectionActionHeight)
    .padding({ left: 2, right: 2 })
    .alignItems(VerticalAlign.Center)
  }
}

@ComponentV2
export struct GenreVinylArtwork {
  @Param variantIndex: number = 0;
  @Param widthValue: number = FnMusicUI.albumGridItemSize;
  @Param heightValue: number = FnMusicUI.genreCardHeight;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($r('app.media.music_genre_vinyl'))
        .width(FnMusicUI.genreCardRecordSize)
        .height(FnMusicUI.genreCardRecordSize)
        .objectFit(ImageFit.Contain)
        .translate({
          x: this.widthValue - FnMusicUI.genreCardRecordSize + FnMusicUI.genreCardRecordRightOverflow,
          y: FnMusicUI.genreCardRecordTop
        })

      Image(genreLabelMedia(this.variantIndex))
        .width(FnMusicUI.genreCardLabelSize)
        .height(FnMusicUI.genreCardLabelSize)
        .objectFit(ImageFit.Contain)
        .translate({
          x: this.widthValue - FnMusicUI.genreCardRecordSize + FnMusicUI.genreCardRecordRightOverflow +
            (FnMusicUI.genreCardRecordSize - FnMusicUI.genreCardLabelSize) / 2,
          y: FnMusicUI.genreCardRecordTop +
            (FnMusicUI.genreCardRecordSize - FnMusicUI.genreCardLabelSize) / 2
        })
    }
    .width(this.widthValue)
    .height(this.heightValue)
    .hitTestBehavior(HitTestMode.None)
  }
}

@ComponentV2
export struct ArtistListItem {
  @Param artist: MusicArtist = new MusicArtist();
  @Event onOpen: (artist: MusicArtist) => void = (_: MusicArtist): void => {};

  build() {
    Row({ space: FnMusicUI.contentGap }) {
      MusicArtwork({
        artworkSize: 48,
        radius: 24,
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
    }
    .width('100%')
    .height(60)
    .padding({ left: 8, right: 8 })
    .borderRadius(12)
    .hoverEffect(HoverEffect.Auto)
    .onClick((): void => this.onOpen(this.artist))
  }
}

@ComponentV2
export struct GenreGridItem {
  @Param genre: MusicGenre = new MusicGenre();
  @Param itemWidth: number = FnMusicUI.albumGridItemSize;
  @Param variantIndex: number = 0;
  @Event onOpen: (genre: MusicGenre) => void = (_: MusicGenre): void => {};

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      GenreVinylArtwork({
        variantIndex: this.variantIndex,
        widthValue: this.itemWidth,
        heightValue: FnMusicUI.genreCardHeight
      })
      Column({ space: 2 }) {
        Text(this.genre.name)
          .fontSize(FnMusicUI.bodySize)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${this.genre.trackCount} 首歌`)
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.text_secondary'))
      }
      .width(this.itemWidth - 58)
      .padding({ left: 12, top: 16 })
      .alignItems(HorizontalAlign.Start)
    }
    .width(this.itemWidth)
    .height(FnMusicUI.genreCardHeight)
    .borderRadius(FnMusicUI.albumGridRadius)
    .backgroundColor($r('app.color.genre_card_surface'))
    .clip(true)
    .onClick((): void => this.onOpen(this.genre))
  }
}

@ComponentV2
export struct PlaylistSelectionActionRow {
  @Param selectedCount: number = 0;
  @Param totalCount: number = 0;
  @Param busy: boolean = false;
  @Event onToggleAll: () => void = (): void => {};
  @Event onPlaySelected: () => void = (): void => {};
  @Event onAddQueue: () => void = (): void => {};
  @Event onRemove: () => void = (): void => {};
  @Event onDone: () => void = (): void => {};

  private allSelected(): boolean {
    return this.totalCount > 0 && this.selectedCount === this.totalCount;
  }

  build() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text(`已选择 ${this.selectedCount} 首`)
          .layoutWeight(1)
          .fontSize(FnMusicUI.bodySize)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Button(this.allSelected() ? '取消全选' : '全选', { type: ButtonType.Capsule, stateEffect: true })
          .height(34)
          .padding({ left: 12, right: 12 })
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(Color.Transparent)
          .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
          .enabled(!this.busy && this.totalCount > 0)
          .onClick((): void => this.onToggleAll())
        Button('完成', { type: ButtonType.Capsule, stateEffect: true })
          .height(34)
          .padding({ left: 12, right: 12 })
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(Color.Transparent)
          .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
          .enabled(!this.busy)
          .onClick((): void => this.onDone())
      }
      .width('100%')

      Row({ space: 8 }) {
        Button('播放选中', { type: ButtonType.Capsule, stateEffect: true })
          .layoutWeight(1)
          .height(36)
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(Color.Transparent)
          .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
          .enabled(!this.busy && this.selectedCount > 0)
          .onClick((): void => this.onPlaySelected())
        Button('加入播放列表', { type: ButtonType.Capsule, stateEffect: true })
          .layoutWeight(1)
          .height(36)
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(Color.Transparent)
          .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
          .enabled(!this.busy && this.selectedCount > 0)
          .onClick((): void => this.onAddQueue())
        Button('移出歌单', { type: ButtonType.Capsule, stateEffect: true })
          .layoutWeight(1)
          .height(36)
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.danger'))
          .backgroundColor(Color.Transparent)
          .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
          .enabled(!this.busy && this.selectedCount > 0)
          .onClick((): void => this.onRemove())
      }
      .width('100%')
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }
}

@ComponentV2
export struct DenseTrackRow {
  @Param track: MusicTrack = new MusicTrack();
  @Param index: number = 0;
  @Param showIndex: boolean = false;
  @Param showArtwork: boolean = true;
  @Param showFormat: boolean = false;
  @Param showDuration: boolean = true;
  @Param showFavoriteAction: boolean = false;
  @Param useTrackNumber: boolean = false;
  @Param selectionMode: boolean = false;
  @Param selected: boolean = false;
  @Event onPlay: (index: number) => void = (_: number): void => {};
  @Event onFavorite: (track: MusicTrack, favorite: boolean) => void =
    (_: MusicTrack, __: boolean): void => {};
  @Event onMore: (track: MusicTrack) => void = (_: MusicTrack): void => {};
  @Event onToggleSelection: (track: MusicTrack) => void = (_: MusicTrack): void => {};

  private formatLabel(): string {
    const format = this.track.audioSpec.format.trim();
    return format.length > 0 ? format.toUpperCase() : this.track.audioSpec.codec.trim().toUpperCase();
  }

  private displayIndex(): number {
    if (this.useTrackNumber && this.track.trackNo > 0) {
      return this.track.trackNo;
    }
    return this.index + 1;
  }

  build() {
    Row({ space: 10 }) {
      if (this.selectionMode) {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          if (this.selected) {
            SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
              .fontSize(22)
              .fontColor([$r('app.color.accent')])
          } else {
            Row()
              .width(18)
              .height(18)
              .borderRadius(9)
              .border({ width: 1.5, color: $r('app.color.text_secondary') })
          }
        }
        .width(34)
        .height(34)
        .backgroundColor(Color.Transparent)
        .accessibilityText(this.selected ? `取消选择 ${this.track.title}` : `选择 ${this.track.title}`)
        .onClick((): void => this.onToggleSelection(this.track))
      } else if (this.showIndex) {
        Text(`${this.displayIndex()}`)
          .width(24)
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .textAlign(TextAlign.Center)
      } else if (this.showArtwork) {
        MusicArtwork({
          artworkSize: 42,
          radius: 7,
          placeholderMedia: $r('app.media.music_track_placeholder'),
          placeholderRatio: 0.56,
          coverId: this.track.coverId,
          updatedAt: this.track.updatedAt
        })
      }

      Column({ space: 3 }) {
        Row({ space: 5 }) {
          Text(this.track.title)
            .layoutWeight(1)
            .fontSize(FnMusicUI.bodySize)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.track.isFavorite && !this.showFavoriteAction) {
            SymbolGlyph($r('sys.symbol.heart_fill'))
              .fontSize(13)
              .fontColor([$r('app.color.accent')])
          }
        }
        .width('100%')
        Row({ space: 6 }) {
          if (this.showFormat && this.formatLabel().length > 0) {
            Text(this.formatLabel())
              .height(18)
              .padding({ left: 5, right: 5 })
              .fontSize(10)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_secondary'))
              .borderRadius(5)
              .backgroundColor($r('app.color.player_format_background'))
          }
          Text(this.track.artistName.length > 0 ?
            `${this.track.artistName}${this.track.albumName.length > 0 ? ` · ${this.track.albumName}` : ''}` :
            this.track.albumName)
            .layoutWeight(1)
            .fontSize(FnMusicUI.supportingSize)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .onClick((): void => {
        if (this.selectionMode) {
          this.onToggleSelection(this.track);
        } else {
          this.onPlay(this.index);
        }
      })

      if (this.showDuration && !this.selectionMode) {
        Text(formatDuration(this.track.durationMs))
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
      }

      if (this.showFavoriteAction && !this.selectionMode) {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph(this.track.isFavorite ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
            .fontSize(20)
            .fontColor([this.track.isFavorite ? $r('app.color.accent') : $r('app.color.text_secondary')])
        }
        .width(36)
        .height(36)
        .backgroundColor(Color.Transparent)
        .accessibilityText(this.track.isFavorite ? `取消收藏 ${this.track.title}` : `收藏 ${this.track.title}`)
        .onClick((): void => this.onFavorite(this.track, !this.track.isFavorite))
      }

      if (!this.selectionMode) {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          VerticalMoreDots()
        }
        .width(36)
        .height(36)
        .backgroundColor(Color.Transparent)
        .accessibilityText(`${this.track.title} 更多操作`)
        .onClick((): void => this.onMore(this.track))
      }
    }
    .width('100%')
    .height(FnMusicUI.denseTrackRowHeight)
    .padding({ left: 2, right: 2 })
    .borderRadius(FnMusicUI.controlRadius)
    .backgroundColor(this.selectionMode && this.selected ? $r('app.color.surface_secondary') : Color.Transparent)
  }
}

@ComponentV2
struct WebCollectionHeroArtwork {
  @Param collectionId: string = '';
  @Param artworkSize: number = FnMusicUI.detailHeroCoverSize;
  @Local motion: boolean = false;
  private motionTimer: number = -1;

  aboutToAppear(): void {
    this.motionTimer = setTimeout((): void => {
      this.motion = true;
    }, this.collectionId === CollectionKind.FAVORITES ? 60 : 180);
  }

  aboutToDisappear(): void {
    if (this.motionTimer >= 0) {
      clearTimeout(this.motionTimer);
      this.motionTimer = -1;
    }
  }

  private iconMedia(): Resource {
    return this.collectionId === CollectionKind.FAVORITES ?
      $r('app.media.home_favorite_icon') : $r('app.media.secondary_recent_icon');
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.collectionId === CollectionKind.FAVORITES) {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 112,
            colors: [
              [$r('app.color.home_card_favorite_start'), 0],
              [$r('app.color.home_card_favorite_middle'), 0.54],
              [$r('app.color.home_card_favorite_end'), 1]
            ]
          })
        Column()
          .width(this.artworkSize * 0.92)
          .height(this.artworkSize * 0.82)
          .radialGradient({
            center: ['50%', '50%'],
            radius: '50%',
            colors: [
              [$r('app.color.home_card_favorite_glow'), 0],
              [$r('app.color.transparent'), 1]
            ]
          })
          .blur(22)
          .translate({
            x: this.motion ? this.artworkSize * 0.27 : -this.artworkSize * 0.34,
            y: this.motion ? -this.artworkSize * 0.31 : this.artworkSize * 0.28
          })
          .animation({ duration: 2400, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate })
      } else {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 90,
            colors: [
              [$r('app.color.home_card_history_start'), 0],
              [$r('app.color.home_card_history_middle'), 0.54],
              [$r('app.color.home_card_history_end'), 1]
            ]
          })
        Column()
          .width(this.artworkSize * 0.78)
          .height(this.artworkSize * 1.22)
          .radialGradient({
            center: ['50%', '50%'],
            radius: '50%',
            colors: [
              [$r('app.color.home_card_history_shadow'), 0],
              [$r('app.color.transparent'), 1]
            ]
          })
          .blur(22)
          .translate({
            x: this.motion ? -this.artworkSize * 0.34 : this.artworkSize * 0.46,
            y: this.motion ? -this.artworkSize * 0.18 : -this.artworkSize * 0.42
          })
          .animation({ duration: 2400, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate })
      }

      Image(this.iconMedia())
        .width(48)
        .height(48)
        .objectFit(ImageFit.Contain)
        .hitTestBehavior(HitTestMode.None)
    }
    .width(this.artworkSize)
    .height(this.artworkSize)
    .borderRadius(14)
    .clip(true)
    .hitTestBehavior(HitTestMode.None)
  }
}

@ComponentV2
export struct ArtistDetailHero {
  @Param artist: MusicArtist = new MusicArtist();

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      MusicArtwork({
        artworkSize: 360,
        fill: true,
        radius: 0,
        symbol: $r('sys.symbol.person_fill'),
        showPlaceholderSymbol: false,
        coverId: this.artist.coverId
      })
        .opacity(1)

      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [
            [$r('app.color.transparent'), 0.12],
            [$r('app.color.album_hero_top_scrim'), 0.4],
            [$r('app.color.album_hero_middle_scrim'), 0.7],
            [$r('app.color.album_detail_background'), 1]
          ]
        })

      Column() {
        Text(this.artist.name)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding({
        left: 24,
        right: 24,
        bottom: FnMusicUI.artistHeroTitleBottomPadding
      })
      .alignItems(HorizontalAlign.Start)

      Image($r('app.media.artist_hero_curve_mask'))
        .width('100%')
        .height(24)
        .objectFit(ImageFit.Fill)
        .hitTestBehavior(HitTestMode.None)
    }
    .width('100%')
    .height(FnMusicUI.artistHeroHeight)
    .clip(true)
  }
}

@ComponentV2
export struct GenreDetailHero {
  @Param genre: MusicGenre = new MusicGenre();
  @Param variantIndex: number = 0;

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [
            [$r('app.color.page_genre_background_start'), 0],
            [$r('app.color.page_genre_background_end'), 1]
          ]
        })

      Column()
        .width('100%')
        .height('100%')
        .radialGradient({
          center: ['82%', '35%'],
          radius: '72%',
          colors: [
            [$r('app.color.album_cover_shadow'), 0],
            [$r('app.color.transparent'), 1]
          ]
        })
        .opacity(0.34)

      Stack({ alignContent: Alignment.TopEnd }) {
        Image($r('app.media.music_genre_vinyl'))
          .width(FnMusicUI.genreHeroRecordSize)
          .height(FnMusicUI.genreHeroRecordSize)
          .objectFit(ImageFit.Contain)
          .translate({
            x: FnMusicUI.genreHeroRecordOffsetX,
            y: FnMusicUI.genreHeroRecordOffsetY
          })

        Image(genreLabelMedia(this.variantIndex))
          .width(FnMusicUI.genreHeroLabelSize)
          .height(FnMusicUI.genreHeroLabelSize)
          .objectFit(ImageFit.Contain)
          .translate({
            x: FnMusicUI.genreHeroLabelOffsetX,
            y: FnMusicUI.genreHeroLabelOffsetY
          })
      }
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.None)

      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [
            [$r('app.color.transparent'), 0.12],
            [$r('app.color.album_hero_top_scrim'), 0.44],
            [$r('app.color.page_genre_background_end'), 1]
          ]
        })

      Column({ space: 4 }) {
        Text(this.genre.name)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${this.genre.trackCount} 首歌曲`)
          .fontSize(FnMusicUI.supportingSize)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .padding({
        left: 24,
        right: 24,
        bottom: FnMusicUI.artistHeroTitleBottomPadding
      })
      .alignItems(HorizontalAlign.Start)

      Image($r('app.media.artist_hero_curve_mask'))
        .width('100%')
        .height(24)
        .objectFit(ImageFit.Fill)
        .fillColor($r('app.color.page_genre_background_end'))
        .hitTestBehavior(HitTestMode.None)
    }
    .width('100%')
    .height(FnMusicUI.artistHeroHeight)
    .clip(true)
  }
}

@ComponentV2
export struct AlbumDetailHero {
  @Param album: MusicAlbum = new MusicAlbum();
  @Param trackCount: number = 0;
  @Param safeTop: number = 0;
  @Local contentHeight: number = 0;

  private metadata(): string {
    const count = `${this.trackCount} 首歌曲`;
    return this.album.year > 0 ? `${this.album.year}年发行 · ${count}` : count;
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      MusicArtwork({
        artworkSize: 420,
        fill: true,
        radius: 0,
        placeholderMedia: $r('app.media.music_album_placeholder'),
        placeholderRatio: 0.78,
        coverId: this.album.coverId,
        updatedAt: this.album.createdAt
      })
        .width('100%')
        .height(this.contentHeight)
        .opacity(0.72)
        .blur(34)
        .scale({ x: 1.24, y: 1.24 })
        .hitTestBehavior(HitTestMode.None)

      Column()
        .width('100%')
        .height(this.contentHeight)
        .linearGradient({
          angle: 180,
          colors: [
            [$r('app.color.album_hero_top_scrim'), 0],
            [$r('app.color.album_hero_middle_scrim'), 0.58],
            [$r('app.color.album_detail_background'), 1]
          ]
        })
        .hitTestBehavior(HitTestMode.None)

      Column()
        .width('100%')
        .height(this.contentHeight)
        .radialGradient({
          center: ['72%', '34%'],
          radius: '92%',
          colors: [
            [$r('app.color.transparent'), 0.18],
            [$r('app.color.album_hero_vignette'), 1]
          ]
        })
        .hitTestBehavior(HitTestMode.None)

      Column() {
        Blank()
          .height(Math.max(0, this.safeTop) + FnMusicUI.secondaryHeaderHeight + FnMusicUI.contentGap)

        Stack({ alignContent: Alignment.Center }) {
          Image($r('app.media.music_genre_vinyl'))
            .width(FnMusicUI.albumHeroRecordSize)
            .height(FnMusicUI.albumHeroRecordSize)
            .objectFit(ImageFit.Contain)
            .opacity(0.94)
            .translate({ x: 22 })
            .hitTestBehavior(HitTestMode.None)

          MusicArtwork({
            artworkSize: FnMusicUI.albumHeroRecordLabelSize,
            radius: FnMusicUI.albumHeroRecordLabelSize / 2,
            placeholderMedia: $r('app.media.music_album_placeholder'),
            placeholderRatio: 0.72,
            coverId: this.album.coverId,
            updatedAt: this.album.createdAt
          })
          .translate({ x: 22 })
          .hitTestBehavior(HitTestMode.None)

          MusicArtwork({
            artworkSize: FnMusicUI.collectionHeroArtworkSize,
            radius: 14,
            placeholderMedia: $r('app.media.music_album_placeholder'),
            placeholderRatio: 0.78,
            coverId: this.album.coverId,
            updatedAt: this.album.createdAt
          })
          .translate({ x: -14 })
          .shadow({
            radius: 22,
            color: $r('app.color.album_cover_shadow'),
            offsetX: 0,
            offsetY: 12
          })
        }
        .width(FnMusicUI.albumHeroArtworkGroupWidth)
        .height(FnMusicUI.albumHeroArtworkGroupHeight)

        Blank().height(22)

        Column({ space: 9 }) {
          Text(this.album.name)
            .fontSize(FnMusicUI.albumHeroTitleSize)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .maxLines(2)
            .lineHeight(27)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Center)
          Text(this.album.artistName.length > 0 ? this.album.artistName : '未知歌手')
            .fontSize(FnMusicUI.bodySize)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Center)
          Text(this.metadata())
            .fontSize(FnMusicUI.supportingSize)
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding({ left: FnMusicUI.albumHeroTextPadding, right: FnMusicUI.albumHeroTextPadding })
        .alignItems(HorizontalAlign.Center)

        Blank().height(30)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .onAreaChange((_: Area, area: Area): void => {
        const height = area.height as number;
        if (height > 0) {
          this.contentHeight = height;
        }
      })
    }
    .width('100%')
    .backgroundColor($r('app.color.album_detail_background'))
    .clip(true)
  }
}

@ComponentV2
export struct PlaylistDetailHero {
  @Param playlist: MusicPlaylist = new MusicPlaylist();
  @Param trackCount: number = 0;
  @Param loadedCount: number = 0;
  @Param safeTop: number = 0;
  @Param shuffleLoading: boolean = false;
  @Local contentHeight: number = 0;
  @Event onShuffle: () => void = (): void => {};
  @Event onManage: () => void = (): void => {};

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      MusicArtwork({
        artworkSize: 420,
        fill: true,
        radius: 0,
        showPlaceholderSymbol: false,
        coverId: this.playlist.coverId,
        updatedAt: this.playlist.updatedAt
      })
      .width('100%')
      .height(this.contentHeight)
      .opacity(0.7)
      .blur(36)
      .scale({ x: 1.26, y: 1.26 })
      .hitTestBehavior(HitTestMode.None)

      Column()
        .width('100%')
        .height(this.contentHeight)
        .linearGradient({
          angle: 180,
          colors: [
            [$r('app.color.album_hero_top_scrim'), 0],
            [$r('app.color.album_hero_middle_scrim'), 0.62],
            [$r('app.color.album_detail_background'), 1]
          ]
        })
        .hitTestBehavior(HitTestMode.None)

      Column({ space: FnMusicUI.contentGap }) {
        Blank()
          .height(Math.max(0, this.safeTop) + FnMusicUI.secondaryHeaderHeight + FnMusicUI.compactGap)

        Row({ space: 16 }) {
          MusicArtwork({
            artworkSize: FnMusicUI.detailHeroCoverSize,
            radius: 14,
            symbol: $r('sys.symbol.music_note_list'),
            placeholderMedia: $r('app.media.music_album_placeholder'),
            placeholderRatio: 0.72,
            coverId: this.playlist.coverId,
            updatedAt: this.playlist.updatedAt
          })
          .shadow({
            radius: 20,
            color: $r('app.color.album_cover_shadow'),
            offsetX: 0,
            offsetY: 10
          })

          Column({ space: 7 }) {
            Text(this.playlist.name)
              .fontSize(FnMusicUI.albumHeroTitleSize)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .maxLines(3)
              .lineHeight(27)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            if (this.playlist.description.length > 0) {
              Text(this.playlist.description)
                .fontSize(FnMusicUI.supportingSize)
                .fontColor($r('app.color.text_secondary'))
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            Text(`${this.trackCount} 首歌曲`)
              .fontSize(FnMusicUI.supportingSize)
              .fontColor($r('app.color.text_secondary'))
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Row({ space: FnMusicUI.compactGap }) {
          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Row({ space: 7 }) {
              if (this.shuffleLoading) {
                LoadingProgress()
                  .width(18)
                  .height(18)
                  .color($r('app.color.text_primary'))
              } else {
                SymbolGlyph($r('sys.symbol.shuffle'))
                  .fontSize(17)
                  .fontColor([$r('app.color.text_primary')])
              }
              Text(this.shuffleLoading ? '正在加载' : '随机播放')
                .fontSize(FnMusicUI.bodySize)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
            }
          }
          .layoutWeight(1)
          .height(FnMusicUI.tapTarget)
          .borderRadius(FnMusicUI.tapTarget / 2)
          .backgroundColor(Color.Transparent)
          .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
          .opacity(this.loadedCount > 0 ? 1 : 0.38)
          .enabled(this.loadedCount > 0 && !this.shuffleLoading)
          .onClick((): void => this.onShuffle())

          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Row({ space: 7 }) {
              SymbolGlyph($r('sys.symbol.gearshape'))
                .fontSize(17)
                .fontColor([$r('app.color.text_primary')])
              Text('管理歌单')
                .fontSize(FnMusicUI.bodySize)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
            }
          }
          .layoutWeight(1)
          .height(FnMusicUI.tapTarget)
          .borderRadius(FnMusicUI.tapTarget / 2)
          .backgroundColor(Color.Transparent)
          .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
          .onClick((): void => this.onManage())
        }
        .width('100%')

        Image($r('app.media.artist_hero_curve_mask'))
          .width('calc(100% + 28vp)')
          .height(24)
          .objectFit(ImageFit.Fill)
          .translate({ x: -FnMusicUI.secondaryPagePadding })
          .hitTestBehavior(HitTestMode.None)
      }
      .width('100%')
      .padding({ left: FnMusicUI.secondaryPagePadding, right: FnMusicUI.secondaryPagePadding })
      .alignItems(HorizontalAlign.Start)
      .onAreaChange((_: Area, area: Area): void => {
        const height = area.height as number;
        if (height > 0) {
          this.contentHeight = height;
        }
      })
    }
    .width('100%')
    .backgroundColor($r('app.color.album_detail_background'))
    .clip(true)
  }
}

@ComponentV2
export struct MusicDetailHero {
  @Param title: string = '';
  @Param subtitle: string = '';
  @Param supporting: string = '';
  @Param coverId: string = '';
  @Param updatedAt: number = 0;
  @Param symbol: Resource = $r('sys.symbol.music_note_list');
  @Param placeholderMedia?: Resource = undefined;
  @Param placeholderRatio: number = 0.34;
  @Param showPlaceholderSymbol: boolean = true;
  @Param circularArtwork: boolean = false;
  @Param collectionId: string = '';
  @Param loadedCount: number = 0;
  @Param showShuffle: boolean = true;
  @Param playAllLoading: boolean = false;
  @Param shuffleLoading: boolean = false;
  @Event onPlayAll: () => void = (): void => {};
  @Event onShuffle: () => void = (): void => {};

  build() {
    Column({ space: FnMusicUI.contentGap }) {
      Row({ space: 15 }) {
        if (this.collectionId === CollectionKind.FAVORITES || this.collectionId === CollectionKind.HISTORY) {
          WebCollectionHeroArtwork({ collectionId: this.collectionId })
        } else {
          MusicArtwork({
            artworkSize: FnMusicUI.detailHeroCoverSize,
            radius: this.circularArtwork ? FnMusicUI.detailHeroCoverSize / 2 : 14,
            symbol: this.symbol,
            placeholderMedia: this.placeholderMedia,
            placeholderRatio: this.placeholderRatio,
            showPlaceholderSymbol: this.showPlaceholderSymbol,
            coverId: this.coverId,
            updatedAt: this.updatedAt
          })
        }
        Column({ space: 5 }) {
          Text(this.title)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.subtitle.length > 0) {
            Text(this.subtitle)
              .fontSize(FnMusicUI.bodySize)
              .fontColor($r('app.color.text_secondary'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          if (this.supporting.length > 0) {
            Text(this.supporting)
              .fontSize(FnMusicUI.supportingSize)
              .fontColor($r('app.color.text_secondary'))
              .maxLines(2)
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Row({ space: FnMusicUI.compactGap }) {
        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Row({ space: 7 }) {
            if (this.playAllLoading) {
              LoadingProgress()
                .width(18)
                .height(18)
                .color($r('app.color.text_primary'))
            } else {
              SymbolGlyph($r('sys.symbol.play_fill'))
                .fontSize(17)
                .fontColor([$r('app.color.text_primary')])
            }
            Text(this.playAllLoading ? '正在加载' : '播放全部')
              .fontSize(FnMusicUI.bodySize)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
          }
        }
        .layoutWeight(1)
        .height(FnMusicUI.actionHeight)
        .borderRadius(FnMusicUI.actionHeight / 2)
        .backgroundColor(Color.Transparent)
        .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
        .opacity(this.loadedCount > 0 ? 1 : 0.38)
        .enabled(this.loadedCount > 0 && !this.playAllLoading && !this.shuffleLoading)
        .onClick((): void => this.onPlayAll())

        if (this.showShuffle) {
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            if (this.shuffleLoading) {
              LoadingProgress()
                .width(18)
                .height(18)
                .color($r('app.color.text_primary'))
            } else {
              SymbolGlyph($r('sys.symbol.shuffle'))
                .fontSize(19)
                .fontColor([$r('app.color.text_primary')])
            }
          }
          .width(FnMusicUI.actionHeight)
          .height(FnMusicUI.actionHeight)
          .backgroundColor(Color.Transparent)
          .attributeModifier(FnMusicMaterials.modifier(FnMusicMaterialRole.ADAPTIVE_INTERACTIVE))
          .enabled(this.loadedCount > 0 && !this.playAllLoading && !this.shuffleLoading)
          .opacity(this.loadedCount > 0 && !this.playAllLoading ? 1 : 0.38)
          .accessibilityText(this.shuffleLoading ? '正在随机加载全部歌曲' : '随机播放')
          .onClick((): void => this.onShuffle())
        }
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
