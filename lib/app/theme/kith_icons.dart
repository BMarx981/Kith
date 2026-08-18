import 'package:flutter/widgets.dart';

/// The app's icons, drawn from the bundled Phosphor regular face.
///
/// Each constant is named for the job it does in Kith rather than for the
/// shape it happens to be, so a screen reads as intent and a later change of
/// glyph stays a one-line edit here. `docs/DESIGN.md` records the rules.
///
/// Only the icons in use are listed. The bundled face carries the whole
/// Phosphor set, and release builds tree-shake it down to the codepoints named
/// below, so adding one is a line here rather than a new asset.
abstract final class KithIcons {
  static const _family = 'Phosphor';

  /// The Reconnect surface: the ranked suggestions of who to see next.
  static const reconnect = IconData(0xe2a8, fontFamily: _family);

  /// Contacts, and the household's members.
  static const people = IconData(0xe4d6, fontFamily: _family);

  /// The household itself: its members, its invite code, its settings.
  static const household = IconData(0xe2c2, fontFamily: _family);

  /// Reveals a password that is currently masked.
  static const showPassword = IconData(0xe220, fontFamily: _family);

  /// Masks a password that is currently revealed.
  static const hidePassword = IconData(0xe224, fontFamily: _family);

  /// Leaves the signed-in session.
  static const signOut = IconData(0xe42a, fontFamily: _family);

  /// Copies the invite code to the clipboard.
  static const copy = IconData(0xe1ca, fontFamily: _family);

  /// Adds a contact, or a relationship label.
  static const add = IconData(0xe3d4, fontFamily: _family);

  /// Narrows the contact list by what was typed.
  static const search = IconData(0xe30c, fontFamily: _family);

  /// Reorders the contact list.
  static const sort = IconData(0xe444, fontFamily: _family);

  /// Relationship labels: the per-household list, and the filter that uses it.
  static const label = IconData(0xe478, fontFamily: _family);

  /// Edits a relationship label in place.
  static const edit = IconData(0xe3b4, fontFamily: _family);

  /// Deletes a relationship label.
  static const delete = IconData(0xe4a6, fontFamily: _family);

  /// Grab handle for dragging a relationship label up or down its list.
  static const reorder = IconData(0xe1fc, fontFamily: _family);

  /// A logged hangout: the timeline, and the way through to it.
  static const hangout = IconData(0xe712, fontFamily: _family);

  /// The day a hangout happened on.
  static const date = IconData(0xe10a, fontFamily: _family);

  /// One contact's hangout history.
  static const history = IconData(0xe1a0, fontFamily: _family);
}
