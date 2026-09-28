/// The product name users see. The product was renamed PesaBox → HelaBox
/// (TODO.md §3); every user-facing mention goes through this constant.
/// Internal identifiers (package name `pesa_box_app`, class `PesaBoxApp`,
/// the server's `pesabox` database) are deliberately left alone — renaming
/// them would break installs and data for no user benefit.
const String kBrandName = 'HelaBox';

/// Logo images (from the "HELABOX FINAL LOGO" pack, assets/brand/).
/// Launcher icons are generated from assets/brand/launcher_*.png with
/// `dart run flutter_launcher_icons`.
const String kBrandIconAsset = 'assets/brand/helabox_icon.png';
const String kBrandLogoAsset = 'assets/brand/helabox_logo.png';
const String kBrandWordmarkWhiteAsset = 'assets/brand/helabox_wordmark_white.png';
