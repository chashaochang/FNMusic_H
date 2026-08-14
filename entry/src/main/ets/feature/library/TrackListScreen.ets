import { FnMusicUI } from '../../design/FnMusicUI';
import { AuthPhase } from '../../auth/ConnectionModels';
import { AppRuntime, AppRuntimeState } from '../../common/AppRuntime';
import { CollectionKind, MusicTrack } from '../../model/MusicModels';
import { EmptyMusicState, SecondaryPageHeader, TrackRow } from '../common/MusicUiComponents';

@ComponentV2
struct TrackListHero {
  @Param title: string = '';
  @Param subtitle: string = '';
  @Param loadedCount: number = 0;
  @Param totalCount: number = 0;
  @Param symbol: Resource = $r('sys.symbol.music_note_list');
  @Event onPlayAll: () => void = (): void => {};
  @Event onShuffle: () => void = (): void => {};

  build() {
    Column({ space: FnMusicUI.contentGap }) {
      Row({ space: 14 }) {
        Stack() {
          SymbolGlyph(this.symbol)
            .fontSize(35)
            .fontColor([$r('app.color.accent')])
        }
        .width(78)
        .height(78)
        .borderRadius(FnMusicUI.cardRadius)
        .backgroundColor($r('app.color.accent_soft'))

        Column({ space: 4 }) {
          Text(this.title)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.subtitle.length > 0 ? this.subtitle : `${this.totalCount} 首歌曲`)
            .fontSize(FnMusicUI.supportingSize)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(2)
            .lineHeight(19)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Row({ space: FnMusicUI.compactGap }) {
        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Row({ space: 7 }) {
            SymbolGlyph($r('sys.symbol.play_fill'))
              .fontSize(17)
              .fontColor([$r('app.color.accent_contrast')])
            Text('全部播放')
              .fontSize(FnMusicUI.bodySize)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.accent_contrast'))
          }
        }
        .layoutWeight(1)
        .height(FnMusicUI.actionHeight)
        .borderRadius(FnMusicUI.controlRadius)
        .backgroundColor(this.loadedCount > 0 ? $r('app.color.accent') : $r('app.color.outline'))
        .enabled(this.loadedCount > 0)
        .onClick((): void => this.onPlayAll())

        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Row({ space: 7 }) {
            SymbolGlyph($r('sys.symbol.shuffle'))
              .fontSize(18)
              .fontColor([$r('app.color.text_primary')])
            Text('随机播放')
              .fontSize(FnMusicUI.bodySize)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
          }
        }
        .layoutWeight(1)
        .height(FnMusicUI.actionHeight)
        .borderRadius(FnMusicUI.controlRadius)
        .backgroundColor($r('app.color.surface_secondary'))
        .enabled(this.loadedCount > 0)
        .onClick((): void => this.onShuffle())
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .borderRadius(FnMusicUI.cardRadius)
    .backgroundColor($r('app.color.surface'))
    .alignItems(HorizontalAlign.Start)
  }
}

@ComponentV2
export struct TrackListScreen {
  @Param title: string = '';
  @Param subtitle: string = '';
  @Param collectionId: string = '';
  @Param tracks: MusicTrack[] = [];
  @Param symbol: Resource = $r('sys.symbol.music_note_list');
  @Param canRemoveFromPlaylist: boolean = false;
  @Param safeTop: number = 0;
  @Param bottomInset: number = 0;
  @Param loading: boolean = false;
  @Param errorMessage: string = '';
  @Local ascending: boolean = true;
  @Local runtimeState: AppRuntimeState = AppRuntime.state();
  @Event onBack: () => void = (): void => {};
  @Event onPlay: (tracks: MusicTrack[], index: number) => void = (_: MusicTrack[], __: number): void => {};
  @Event onTrackMore: (track: MusicTrack, canRemove: boolean) => void = (_: MusicTrack, __: boolean): void => {};
  @Event onPageMore: () => void = (): void => {};

  private usesRuntimeLibrary(): boolean {
    return this.collectionId === CollectionKind.LIBRARY && this.runtimeState.phase === AuthPhase.AUTHENTICATED;
  }

  private visibleTracks(): MusicTrack[] {
    return this.usesRuntimeLibrary() ? this.runtimeState.tracks : this.tracks;
  }

  private visibleTotal(): number {
    const tracks = this.visibleTracks();
    return this.usesRuntimeLibrary() ? Math.max(this.runtimeState.trackTotal, tracks.length) : tracks.length;
  }

  private loadMore(): void {
    if (this.usesRuntimeLibrary()) {
      AppRuntime.loadMoreTracks().catch((): void => {});
    }
  }

  private sortedTracks(): MusicTrack[] {
    return this.visibleTracks().slice().sort((left: MusicTrack, right: MusicTrack): number => {
      const compare: number = left.title.localeCompare(right.title);
      return this.ascending ? compare : -compare;
    });
  }

  private shuffleStartIndex(): number {
    if (this.visibleTracks().length < 2) {
      return 0;
    }
    return Math.floor(Math.random() * this.visibleTracks().length);
  }

  build() {
    Column() {
      SecondaryPageHeader({
        title: this.title,
        subtitle: `${this.visibleTotal()} 首歌曲`,
        safeTop: this.safeTop,
        trailingSymbol: this.canRemoveFromPlaylist ? $r('sys.symbol.more') : undefined,
        onBack: (): void => this.onBack(),
        onTrailing: (): void => this.onPageMore()
      })

      List({ space: FnMusicUI.contentGap }) {
        ListItem() {
          TrackListHero({
            title: this.title,
            subtitle: this.subtitle,
            loadedCount: this.visibleTracks().length,
            totalCount: this.visibleTotal(),
            symbol: this.symbol,
            onPlayAll: (): void => {
              this.onPlay(this.visibleTracks(), 0);
            },
            onShuffle: (): void => {
              this.onPlay(this.visibleTracks(), this.shuffleStartIndex());
            }
          })
        }

        ListItem() {
          Row() {
            Text('歌曲')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            Blank()
            Button({ type: ButtonType.Normal }) {
              Row({ space: 5 }) {
                SymbolGlyph(this.ascending ? $r('sys.symbol.arrow_up') : $r('sys.symbol.arrow_down'))
                  .fontSize(15)
                  .fontColor([$r('app.color.accent')])
                Text(this.ascending ? '标题升序' : '标题降序')
                  .fontSize(13)
                  .fontColor($r('app.color.accent'))
              }
            }
            .height(36)
            .padding({ left: 10, right: 10 })
            .borderRadius(FnMusicUI.controlRadius)
            .backgroundColor($r('app.color.transparent'))
            .onClick((): void => {
              this.ascending = !this.ascending;
            })
          }
          .width('100%')
          .height(42)
        }

        if (this.loading) {
          ListItem() {
            Column({ space: FnMusicUI.compactGap }) {
              LoadingProgress()
                .width(28)
                .height(28)
                .color($r('app.color.accent'))
              Text('正在加载')
                .fontSize(FnMusicUI.supportingSize)
                .fontColor($r('app.color.text_secondary'))
            }
            .width('100%')
            .height(180)
            .justifyContent(FlexAlign.Center)
          }
        } else if (this.errorMessage.length > 0) {
          ListItem() {
            EmptyMusicState({
              title: '加载失败',
              message: this.errorMessage,
              symbol: $r('sys.symbol.exclamationmark_circle_fill')
            })
          }
        } else if (this.visibleTracks().length === 0) {
          ListItem() {
            EmptyMusicState({ title: '这里还没有歌曲', message: '添加歌曲后会显示在这里。' })
          }
        } else {
          Repeat<MusicTrack>(this.sortedTracks())
            .each((repeatItem: RepeatItem<MusicTrack>): void => {
              ListItem() {
                TrackRow({
                  track: repeatItem.item,
                  index: repeatItem.index,
                  showIndex: true,
                  onPlay: (index: number): void => {
                    this.onPlay(this.sortedTracks(), index);
                  },
                  onMore: (track: MusicTrack): void => {
                    this.onTrackMore(track, this.canRemoveFromPlaylist);
                  }
                })
              }
              .padding({ left: 10, right: 8 })
              .borderRadius(FnMusicUI.cardRadius)
              .backgroundColor($r('app.color.surface'))
            })
            .key((item: MusicTrack): string => item.guid)
            .virtualScroll()
        }

        if (this.usesRuntimeLibrary()) {
          ListItem() {
            Column({ space: FnMusicUI.compactGap }) {
              if (this.runtimeState.tracksLoadingMore) {
                LoadingProgress()
                  .width(24)
                  .height(24)
                  .color($r('app.color.accent'))
                Text('正在加载更多歌曲')
                  .fontSize(FnMusicUI.supportingSize)
                  .fontColor($r('app.color.text_secondary'))
              } else if (this.runtimeState.tracksLoadMoreError.length > 0) {
                Text(this.runtimeState.tracksLoadMoreError)
                  .fontSize(FnMusicUI.supportingSize)
                  .fontColor($r('app.color.text_secondary'))
                  .maxLines(2)
                  .textAlign(TextAlign.Center)
                Button('重试加载')
                  .height(36)
                  .fontSize(FnMusicUI.supportingSize)
                  .fontColor($r('app.color.accent'))
                  .backgroundColor($r('app.color.surface_secondary'))
                  .borderRadius(FnMusicUI.controlRadius)
                  .onClick((): void => this.loadMore())
              } else if (this.runtimeState.tracksHasMore) {
                Text(`已加载 ${this.visibleTracks().length} / 共 ${this.visibleTotal()} 首`)
                  .fontSize(FnMusicUI.supportingSize)
                  .fontColor($r('app.color.text_secondary'))
              }
            }
            .width('100%')
            .height(this.runtimeState.tracksLoadMoreError.length > 0 ? 96 :
              (this.runtimeState.tracksLoadingMore || this.runtimeState.tracksHasMore ? 64 : 0))
            .justifyContent(FlexAlign.Center)
          }
        }

        ListItem()
          .height(this.bottomInset + FnMusicUI.sectionGap)
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: FnMusicUI.pagePadding, right: FnMusicUI.pagePadding })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .cachedCount(2)
      .onReachEnd((): void => this.loadMore())
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}
