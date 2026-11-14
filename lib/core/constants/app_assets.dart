/// Asset path constants.
///
/// These point at assets that will be added in a later phase. They are defined
/// here so no build method hard-codes a path; referencing an asset that is not
/// yet declared in pubspec is safe as long as it is not actually loaded by an
/// [Image]/[AssetImage] call. The app currently relies on Material icons, which
/// require no asset declaration.
class AppAssets {
  AppAssets._();

  /// App logo (to be added to assets/images/ in a later phase).
  static const String logo = 'assets/images/sync_logo.png';

  /// Welcome illustration (to be added in a later phase).
  static const String welcomeIllustration = 'assets/images/welcome.png';
}
