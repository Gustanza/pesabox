/// The product name users see. The product was renamed PesaBox → HelaBox
/// (TODO.md §3); every user-facing mention goes through this constant.
/// Internal identifiers (package name `pesa_box_app`, class `PesaBoxApp`,
/// the server's `pesabox` database) are deliberately left alone — renaming
/// them would break installs and data for no user benefit.
const String kBrandName = 'HelaBox';
