# Kith — Design language

Soft minimal. A muted cool palette, one restrained accent, hairlines instead of
elevation, a warm serif for display and a quiet sans for everything else. Light
and dark are equal citizens and follow the system setting.

This document is the source of truth for the app's visual layer. If the code and
this file disagree, the file wins until it is deliberately changed.

---

## 1. Principles

1. **Hairlines, not elevation.** Surfaces are separated by a 1px `outlineVariant`
   rule, never by a shadow. Card elevation is 0 everywhere.
2. **One accent.** Sage green is the only accent colour. Nothing else in the app
   competes for attention. Never introduce a second accent to distinguish a
   feature; use weight, size or spacing instead.
3. **Serif display, quiet sans.** Fraunces carries the wordmark, page titles and
   app-bar titles. Inter carries everything else. The contrast between the two
   is the app's signature, so neither should drift into the other's job.
   Icons are Phosphor, whose rounded terminals answer Fraunces rather than
   Material's squared ones.
4. **No ink ripple.** The Material ripple is the loudest stock-Material tell.
   Presses read as a low-alpha overlay instead.
5. **Semantics stay honest.** Freshness is green / amber / red because those
   readings are learned, not decorative. "Never seen" is a distinct fourth,
   neutral, state — it is not a shade of red.
6. **Restraint over ornament.** Radii stop at 12. There is no gradient, no
   glassmorphism, no decorative illustration.

---

## 2. Colour

The scheme is built with `ColorScheme.fromSeed` and then `copyWith` over every
role the app actually renders. The seed alone is not trusted: the tonal
purple-grey surfaces it derives are the most recognisable stock-Material tell,
and replacing them is most of the redesign.

### Scheme roles

| Role | Light | Dark | Used for |
|---|---|---|---|
| `primary` | `0xFF3E6B52` | `0xFF93C3A7` | Accent: filled buttons, focus rings, wordmark |
| `onPrimary` | `0xFFF7F9F7` | `0xFF11291C` | Text on the accent |
| `surface` | `0xFFF8FAF8` | `0xFF141817` | Scaffold and app bar background |
| `onSurface` | `0xFF1E2622` | `0xFFE3E8E4` | Primary text |
| `surfaceContainerLowest` | `0xFFFFFFFF` | `0xFF0F1211` | Recessed fills |
| `surfaceContainerLow` | `0xFFF1F4F1` | `0xFF1B201D` | Card fill |
| `surfaceContainer` | `0xFFEEF2EF` | `0xFF1F2421` | Menus, sheets |
| `surfaceContainerHigh` | `0xFFECEFEC` | `0xFF222825` | Dialogs |
| `surfaceContainerHighest` | `0xFFE9EDEA` | `0xFF262C29` | Raised fills, avatars |
| `onSurfaceVariant` | `0xFF5B655F` | `0xFF98A29B` | Secondary text, labels, hints |
| `outline` | `0xFFAEB8B1` | `0xFF4C544F` | Input borders, muted icons |
| `outlineVariant` | `0xFFE2E7E3` | `0xFF272D2A` | Hairlines: dividers, card and app-bar rules |
| `error` | `0xFFA6403A` | `0xFFDD8F89` | Failure text and error borders |
| `inverseSurface` | `0xFF2A322D` | `0xFFE3E8E4` | Snackbar background |
| `onInverseSurface` | `0xFFF1F4F1` | `0xFF1E2622` | Snackbar text |
| `surfaceTint` | transparent | transparent | Nothing: elevation never tones a surface |

The whole `surfaceContainer` ramp is overridden, not only the two steps the
app renders today. A dialog or menu that picked a seed-derived value out of
the middle of a hand-built ramp would read as a different app.

The light surfaces are a cool off-white; the dark surfaces are a green-tinted
charcoal rather than a neutral grey, so the accent sits in the same family as
its background in both themes.

### Freshness

Exposed as the `FreshnessColors` theme extension, not as scheme roles, because
they are domain semantics rather than UI chrome. Read them via
`Theme.of(context).extension<FreshnessColors>()`.

| State | Light | Dark | Meaning |
|---|---|---|---|
| `fresh` | `0xFF3E6B52` | `0xFF93C3A7` | Seen recently relative to cadence (< 0.75) |
| `due` | `0xFF9A7126` | `0xFFD3AC66` | At or near cadence (0.75 – 1.25) |
| `overdue` | `0xFFA6403A` | `0xFFDD8F89` | Well past cadence (> 1.25) |
| `unknown` | `0xFF79837D` | `0xFF828C86` | Never seen, or no hangouts logged |

`fresh` is the accent itself and `overdue` is the error colour, so the gauge
harmonises with the rest of the app instead of importing a third palette. The
four states are always mutually distinct — a test enforces it.

---

## 3. Typography

Two families, both bundled as TTF assets. No web fonts, no `google_fonts`
package: the app must render identically offline and in golden tests.

### Fraunces — display

A soft, slightly wonky serif. Warm and domestic, which suits a friendship
tracker, and immediately not-Material. Bundled as the **72pt optical size, Soft**
static instance at **SemiBold (600)** — one weight, one file.

| Style | Size | Weight | Line height | Used for |
|---|---|---|---|---|
| `headlineMedium` | 30 | 600 | 1.15 | The "Kith" wordmark (-0.2 letter-spacing) |
| `headlineSmall` | 24 | 600 | 1.2 | Page titles inside a body |
| `titleLarge` | 21 | 600 | 1.2 | App-bar titles |

### Inter — everything else

Set as `ThemeData.fontFamily`, so anything not listed above inherits it.
Every style is coloured `onSurface` from the scheme, so the scale reads the
same in both brightnesses; screens tint individual pieces of copy with
`copyWith`.

| Style | Size | Weight | Line height | Used for |
|---|---|---|---|---|
| `titleMedium` | 16 | 600 | 1.3 | Emphasised body headings |
| `titleSmall` | 12 | 600 | 1.3 | Section labels (+0.6 letter-spacing) |
| `bodyLarge` | 16 | 400 | 1.5 | Long-form body copy |
| `bodyMedium` | 14 | 400 | 1.45 | Default body copy |
| `bodySmall` | 12 | 400 | 1.4 | Captions, helper and debug text |
| `labelLarge` | 15 | 600 | 1.2 | Button labels |

Weights bundled: 400 Regular, 500 Medium, 600 SemiBold. Nothing bolder — the
design gets emphasis from colour and space, not from weight.

### Provenance and licences

Both families are under the SIL Open Font License 1.1, which requires the
licence to travel with the font software. Each family therefore ships its
`OFL.txt` alongside the TTFs, and both are declared as bundled assets.

| Family | Source | Files |
|---|---|---|
| Fraunces | `github.com/undercasetype/Fraunces` (`fonts/ttf`, `OFL.txt`) | `Fraunces72ptSoft-SemiBold.ttf` |
| Inter | `github.com/rsms/inter` release v4.1 (`extras/ttf`, `LICENSE.txt`) | `Inter-Regular.ttf`, `Inter-Medium.ttf`, `Inter-SemiBold.ttf` |

They live under `assets/fonts/fraunces/` and `assets/fonts/inter/`. The icon
face is bundled the same way; see section 4.

---

## 4. Iconography

**Phosphor**, regular weight, bundled as a TTF asset. Material's icon set is the
loudest remaining stock tell after the surfaces: it mixes fills into a nominally
outlined set (solid heads on the people mark, a solid lid on the bin) and
squares off its terminals, which reads heavy beside a hairline border and a soft
serif wordmark. Phosphor's terminals are rounded like Fraunces Soft's, and its
forms stay open.

`Icons.*` is not used anywhere in `lib/`. Screens reach for `KithIcons`, in
`lib/app/theme/kith_icons.dart`, whose constants are named for the job the icon
does in Kith rather than for the shape it happens to be: `KithIcons.signOut`,
not `KithIcons.arrowRight`. A later change of glyph is then a one-line edit in
one file.

| Constant | Phosphor glyph | Used for |
|---|---|---|
| `reconnect` | `heart` | The Reconnect surface |
| `people` | `users` | Contacts, and the household's member list |
| `household` | `house` | The way through to the household screen |
| `showPassword` | `eye` | Reveals a masked password |
| `hidePassword` | `eye-slash` | Masks a revealed password |
| `signOut` | `sign-out` | Leaves the session |
| `copy` | `copy` | Copies the invite code |
| `add` | `plus` | Adds a contact or a relationship label |
| `search` | `magnifying-glass` | Narrows the contact list |
| `sort` | `sort-ascending` | Reorders the contact list |
| `label` | `tag` | Relationship labels, and the filter that uses them |
| `edit` | `pencil-simple` | Renames a relationship label |
| `delete` | `trash` | Deletes a relationship label |
| `reorder` | `dots-six-vertical` | Grab handle for dragging a label |

Rules:

- Only icons actually rendered get a constant. The bundled face carries the
  whole Phosphor set and release builds tree-shake it to the codepoints named,
  so adding one is a line in `kith_icons.dart`, never a new asset.
- One weight. Light is prettier at 48px but goes frail at the 20px of the
  password toggle, and a set that changes weight by size stops reading as a set.
- Never a filled icon to mean emphasis. Emphasis is colour and space, the same
  rule the type scale follows.
- `uses-material-design: true` stays in `pubspec.yaml`. Nothing in `lib/` reads
  from it, but the framework draws its own chrome with Material glyphs, and the
  app bar's automatic back button is one of them.
- Licence: MIT, bundled at `assets/fonts/phosphor/LICENSE`.

---

## 5. Spacing, shape and motion

### Spacing

`KithSpacing` in `lib/app/theme/kith_spacing.dart` — a plain class of static
consts rather than a `ThemeExtension`, because spacing does not lerp and const
`EdgeInsets` must stay possible.

| Token | Value |
|---|---|
| `xxs` | 4 |
| `xs` | 8 |
| `sm` | 12 |
| `md` | 16 |
| `lg` | 24 |
| `xl` | 32 |
| `xxl` | 48 |
| `formMaxWidth` | 420 |

Screens use these instead of bare numbers. A one-off number in a screen is a
sign the scale is missing a step, not a licence to hardcode.

### Radii

| Value | Applies to |
|---|---|
| 10 | Inputs, buttons, snackbars |
| 12 | Bordered surfaces (cards) |
| stadium | Chips |

Nothing is rounder than 12 except chips.

### Motion

Page transitions are fade-forwards on Android and Cupertino on iOS/macOS, so
navigation feels calm rather than springy. Progress indicators are 2.5px with
round caps in the accent colour.

---

## 6. Component treatments

Set once in `KithTheme._build`, so screens stay free of styling code.

- **AppBar** — `surface` background, `onSurface` foreground, left-aligned title
  in Fraunces, elevation 0 and `scrolledUnderElevation` 0, plus the signature
  detail: a 1px `outlineVariant` bottom border that never changes on scroll.
- **Card** — elevation 0, `surfaceContainerLow` fill, 1px `outlineVariant`
  border, radius 12. The plain `Card` widget is still the way to get one.
- **Inputs** — borders live in `InputDecorationThemeData`: enabled is 1px
  `outline` at radius 10, focused is 1.5px `primary`, error and focused-error
  use `error`. Screens must not pass their own `border:`.
- **FilledButton** — radius 10, 48 minimum height, elevation 0, no splash.
- **TextButton** — radius 10, no splash, `primary` foreground.
- **Chip** — stadium, no fill, 1px `outline` border, `onSurfaceVariant` label.
  A *selected* chip is marked by its border and its label only: 1.5px
  `primary` and a `primary` label, still no fill and no checkmark. A filled,
  ticked chip is one of the loudest Material tells, and the accent reads
  clearly enough on its own.
- **FloatingActionButton** — the one filled accent surface in the app, and the
  only control that floats over content: `primary` on `onPrimary`, elevation 0
  in every state, no splash, radius 12. Flat and squared like everything else,
  so it reads as part of the page rather than as a Material dropped onto it.
- **Divider** — 1px `outlineVariant`, zero indent.
- **SnackBar** — floating, `inverseSurface`, radius 10.
- **Splash** — `NoSplash.splashFactory` app-wide, with a low-alpha pressed
  overlay carrying the feedback instead.

---

## 7. Rules for future milestones

- Contact rows and suggestion cards are **hairline surfaces**: a border and a
  fill, never a shadow.
- A list row is a `ListTile` with a `surfaceContainerHighest` avatar carrying
  the initial, the name as the title, and the secondary facts joined by a
  middle dot in the subtitle. Contacts and household members are laid out the
  same way on purpose.
- The freshness gauge reads its colours from `FreshnessColors` and nowhere else.
- Icons come from `KithIcons`. A screen that imports `Icons` is a bug.
- Never add a second accent colour. If two things need to be told apart, use
  `onSurfaceVariant` versus `onSurface`, or space them.
- Never hardcode a colour outside `lib/app/theme/`. Screens style through
  `Theme.of(context)` roles only.
- Use `KithSpacing` for padding and gaps. New steps get added to the scale
  rather than inlined at a call site.
- Every new surface gets a light and a dark golden in `test/goldens/`.
