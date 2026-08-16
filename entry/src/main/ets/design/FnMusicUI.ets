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
  // Feiniu Music Web genre cards use a 160 px vinyl at top 16 px with
  // 20 px right overflow, plus a centered 64 px label. Keep that source
  // composition when adapting the two-column card to the phone canvas.
  static readonly genreCardHeight: number = 120;
  static readonly genreCardRecordSize: number = 160;
  static readonly genreCardRecordTop: number = 16;
  static readonly genreCardRecordRightOverflow: number = 20;
  static readonly genreCardLabelSize: number = 64;
  // The detail page reuses the verified artist Hero height. Its larger
  // record preserves the Web detail composition while remaining phone-first.
  static readonly genreHeroRecordSize: number = 292;
  static readonly genreHeroLabelSize: number = 116;
  static readonly genreHeroRecordOffsetX: number = 64;
  static readonly genreHeroRecordOffsetY: number = 18;
  static readonly genreHeroLabelOffsetX: number = -24;
  static readonly genreHeroLabelOffsetY: number = 106;
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
  // Feiniu Music Web empty-state illustrations are authored on a 150 x 150
  // canvas. Keep that source geometry for full-page states and use the
  // compact size only inside constrained mobile sheets.
  static readonly emptyIllustrationSize: number = 150;
  static readonly emptyCompactIllustrationSize: number = 96;
  static readonly emptyIllustrationGap: number = 4;
  static readonly emptyTextGap: number = 6;
  static readonly emptyTitleSize: number = 14;
  static readonly emptyTopPadding: number = 20;
  static readonly emptyBottomPadding: number = 36;
  static readonly emptyCompactTopPadding: number = 8;
  static readonly emptyCompactBottomPadding: number = 16;
  static readonly emptyActionHeight: number = 36;
  // Web search landing reference: a 72 px material circle with a 28 px
  // magnifier, positioned above the explanatory copy.
  static readonly searchStartIconContainerSize: number = 72;
  static readonly searchStartIconSize: number = 28;
  static readonly searchStartTopPadding: number = 72;
  // The Web player uses a prominent semibold empty-lyric line. The phone
  // layout keeps the same hierarchy at a conservative mobile size.
  static readonly playerEmptyLyricSize: number = 24;
  static readonly playerLyricErrorSize: number = 18;
  static readonly playerEmptyLyricLineHeight: number = 32;
  static readonly playerLyricErrorLineHeight: number = 24;
}
