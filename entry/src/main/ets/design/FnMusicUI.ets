/** Shared visual metrics for the phone-first Feiniu Music client. */
export class FnMusicUI {
  static readonly pagePadding: number = 16;
  static readonly secondaryPagePadding: number = 14;
  static readonly compactGap: number = 8;
  static readonly contentGap: number = 12;
  static readonly homeTitleToContentGap: number = 16;
  static readonly homeRecentAlbumGap: number = 16;
  static readonly sectionGap: number = 20;
  static readonly homeChipToContentGap: number = 18;
  static readonly homeRecentSectionGap: number = 36;
  static readonly homeTrackRowGap: number = 10;
  static readonly cardRadius: number = 16;
  static readonly controlRadius: number = 8;
  static readonly chipHeight: number = 36;
  static readonly searchHeight: number = 48;
  static readonly listRowHeight: number = 56;
  static readonly denseTrackRowHeight: number = 58;
  static readonly actionHeight: number = 48;
  static readonly bottomBarHeight: number = 60;
  static readonly bottomNavigationExpandedWidth: number = 240;
  static readonly homeActionBarHeight: number = 56;
  static readonly secondaryHeaderHeight: number = 56;
  static readonly albumGridGap: number = 12;
  static readonly albumGridItemSize: number = 160;
  static readonly homeCatalogGridItemSize: number = 158;
  static readonly albumGridRadius: number = 10;
  static readonly detailHeroCoverSize: number = 116;
  // Video-derived catalog/detail baselines for the phone layout.
  static readonly collectionArtistArtworkSize: number = 56;
  static readonly collectionAlbumArtworkSize: number = 58;
  static readonly collectionRowHeight: number = 72;
  // Android reference: the artist image region ends at about 1040 px on a
  // 1280 px-wide screenshot. With the project's 1 px = 0.28125 vp baseline,
  // that maps to roughly 292.5 vp. Album Hero remains content-measured.
  static readonly artistHeroHeight: number = 292;
  // Keep the artist name on the same visual baseline after removing the
  // duplicated track/album summary from the Hero.
  static readonly artistHeroTitleBottomPadding: number = 48;
  // Reference screenshot baseline: 1280 px canvas maps to 360 vp; the visible
  // album cover is roughly 150 vp and is paired with a partially exposed record.
  static readonly collectionHeroArtworkSize: number = 156;
  static readonly albumHeroArtworkGroupWidth: number = 210;
  static readonly albumHeroArtworkGroupHeight: number = 164;
  static readonly albumHeroRecordSize: number = 148;
  static readonly albumHeroRecordLabelSize: number = 40;
  static readonly albumHeroTextPadding: number = 28;
  static readonly albumHeroTitleSize: number = 20;
  static readonly collectionSegmentHeight: number = 48;
  static readonly collectionSegmentVerticalPadding: number = 8;
  static readonly collectionActionHeight: number = 52;
  static readonly homeFeatureCardWidth: number = 226;
  static readonly homeFeatureCardHeight: number = 202.4;
  static readonly homeFeatureCardOverflowTop: number = 12;
  static readonly homeFeatureCardRadius: number = 12;
  static readonly homeStickyRunway: number = 240;
  static readonly bottomBarSurfaceHeight: number = 56;
  static readonly bottomBarSideMargin: number = 16;
  static readonly homeMiniPlayerHeight: number = 48;
  static readonly miniPlayerHeight: number = 52;
  static readonly floatingPlayerHeight: number = 52;
  static readonly compactPlayerHeight: number = FnMusicUI.bottomBarHeight;
  static readonly miniPlayerArtworkSize: number = 36;
  static readonly compactPlayerArtworkSize: number = 48;
  static readonly compactPlayerGap: number = 8;
  static readonly compactPlayerSideMargin: number = 12;
  static readonly homeMiniPlayerExpandedWidth: number = 264;
  static readonly bodySize: number = 15;
  static readonly supportingSize: number = 13;
  static readonly titleSize: number = 24;
  static readonly tapTarget: number = 44;
}
