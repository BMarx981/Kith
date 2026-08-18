# Kith — Development Plan

Working title: **Kith** (rename freely; nothing in the plan depends on it).

A shared household app that tracks friends — yours and your kids' — shows how long it's been since you last saw each person, and suggests who to reconnect with. Flutter + Riverpod + AutoRoute, shared data between partners, editable relationship types, full test coverage, and a Skylight Calendar hookup.

---

## 1. Product definition

### Core loop
1. Household members add contacts (adults and kids' friends).
2. When you hang out, you log it in ~10 seconds (who, when, optional note).
3. Every contact carries a **freshness gauge** driven by time-since-last-hangout vs. that contact's target cadence.
4. The home screen surfaces **suggestions**: who's overdue, ranked, with one-tap "plan it" that creates a calendar event visible on the Skylight.

### Users
- Two (or more) adults in one household, both editing the same list.
- Kids do not need accounts in v1; kids' friends are contacts *tagged to* a kid ("Child's friend", renamed per household), managed by parents.

### Entities
| Entity | Purpose |
|---|---|
| Household | The shared container. All data is scoped to it. |
| Member | An authenticated adult user belonging to a household. |
| Contact | A person (or family unit) you track. |
| RelationshipType | Editable, per-household label list. Seeded: Friend, Family, Neighbor, Child's friend, Coworker. Fully CRUD-able. |
| Hangout | A logged meetup: date, contacts involved, who from the household attended, note. |
| PlannedHangout | A future intent: contact(s), proposed date/window, status, calendar event link. |

### Contact fields
- Name, relationship type (FK to RelationshipType)
- Contact info: phone, email, address (all optional)
- **Parent/guardian contact** (name + phone) — first-class field, because for a kid's friend the person you actually text is the parent
- Target cadence: weekly / biweekly / monthly / quarterly / twice-a-year / custom days
- Priority weight (low/normal/high) — feeds the suggestion ranking
- Notes, tags
- Archived flag (soft delete)

### Freshness gauge
`freshness = daysSinceLastHangout / cadenceDays`
- **Fresh** (green): < 0.75
- **Due** (amber): 0.75 – 1.25
- **Overdue** (red): > 1.25
- **Never seen** and **no hangouts logged** are distinct states with their own visuals.

Rendered as a ring/arc gauge on the contact card and a sortable column in list view. The gauge is a pure function of (lastHangoutDate, cadence, now) — trivially unit-testable, no side effects.

### Suggestion engine
Pure Dart, no I/O. Ranks non-archived contacts by:

```
score = overdueRatio * priorityWeight * recencyDamping
```

- `overdueRatio` = freshness value, clamped
- `priorityWeight` = 0.5 / 1.0 / 1.5
- `recencyDamping` suppresses contacts with a PlannedHangout already scheduled
- Tie-break: longest absolute time since last hangout

Output: top-N suggestions with a human reason string ("It's been 6 weeks — you usually see Marcus monthly"). Deterministic given a fixed clock → 100% coverable with table-driven tests.

### Suggestion surfacing
- Home screen "Reconnect" section (top 3–5)
- Optional weekly local notification digest ("3 people are overdue") — phase 2

---

## 2. Architecture

The visual layer has its own spec: **`docs/DESIGN.md`** covers the palette,
type scale, spacing tokens and component treatments, and is the source of
truth for anything a screen renders.

### Stack
- **Flutter** (stable channel), Dart 3.x
- **Riverpod** classic providers (`NotifierProvider`, `AsyncNotifierProvider`, `StreamProvider`) — no codegen; `riverpod_lint` enabled
- **AutoRoute** for typed routes and guards — **the single codegen exception** in the project (`*.gr.dart` via build_runner)
- **Hand-written immutable models**: explicit `const` constructors, `toMap`/`fromMap`, `copyWith`, `==`/`hashCode` — all fully unit-tested
- **Firebase**: Auth (email/password + Google/Apple sign-in), **Cloud Firestore** for shared realtime data. No Storage: contacts carry no photo (decided 2026-08-18 — a coloured initial identifies a row well enough to not be worth an image picker, upload path and a second set of security rules).
- **clock** package for injectable time (critical for testing the gauge/suggestions)

No freezed, no json_serializable, no riverpod codegen. The only generated files in the repo are AutoRoute's router output.

Why Firestore: shared multi-writer household data with realtime sync and offline persistence out of the box, and it matches the MenuBoard backend experience — no new infra to learn. (Alternative: Supabase/Postgres with RLS; see Open Questions.)

### Sharing model
- On first run a user creates a Household or joins one via **invite code** (6-char code stored on the household doc, regenerable).
- Firestore layout:

```
households/{hid}
  members/{uid}            // role: owner | member
  contacts/{cid}
  relationshipTypes/{rid}
  hangouts/{hgid}
  plannedHangouts/{pid}

inviteCodes/{code}         // { householdId, createdBy, createdAt }
```

- `inviteCodes` is the only top-level collection, and it holds no user data. It is a code → household id index, needed because a prospective member cannot read anything under `households/{hid}` until they are already a member. The document id *is* the code, so `get` requires knowing it and `list` is denied. It is a lookup convenience, not the security boundary: the join is authorised by the member-create rule re-reading the household document and comparing against *its* `inviteCode`, so a forged index entry grants nothing. Full reasoning in `docs/M1-FIRESTORE-RULES.md`.
- **Security rules**: a user can read/write under `households/{hid}` iff `exists(households/{hid}/members/{request.auth.uid})`. Rules get their own emulator test suite.

### Project layout (feature-first)

```
lib/
  app/                 // MaterialApp, router config, shared widgets
    theme/             // palette, type scale, spacing, component themes
  core/                // clock, result types, extensions, constants
  data/
    models/            // hand-written immutable entities
    repositories/      // Firestore-backed repos behind abstract interfaces
    services/          // auth service, calendar sync service
  features/
    auth/
    household/         // create/join, member management, invite codes
    contacts/          // list, detail, edit, relationship type manager
    hangouts/          // quick-log flow, history
    suggestions/       // engine (pure) + home screen presentation
    calendar/          // Skylight integration
  routing/             // AutoRoute definitions + guards
```

### State conventions
- Repositories expose `Stream<T>` / `Future<T>`; providers wrap them (`StreamProvider`/`AsyncNotifier`).
- UI never touches Firestore types — only domain models.
- All time reads go through a `clockProvider` so tests can pin "now".

---

## 3. Skylight Calendar integration

Skylight has **no official public API**. Two paths, both planned:

### Path A (MVP, reliable): shared calendar bridge
The app writes PlannedHangouts to a calendar source that Skylight already knows how to ingest:
1. Household links a dedicated Google Calendar (e.g., "Hangouts") via Google Calendar API (OAuth per household).
2. Skylight is pointed at that calendar once, in the Skylight app, as a synced source.
3. Confirming a suggestion → creates/updates/deletes an event on that calendar → appears on the Skylight frame automatically.

This is stable, officially supported on both ends, and also makes the events visible in everyone's normal calendar apps for free.

### Path B (stretch, feature-flagged): direct unofficial API
A community-maintained, reverse-engineered OpenAPI spec for the Skylight API exists (github.com/TheEagleByte/skylight-api), with email/password auth yielding a Basic token and endpoints for calendar events, chores, and lists per frame. This allows writing events directly to the frame without a Google account in the middle — but it's unofficial and can break without notice.

Plan: define a `CalendarSink` interface; ship `GoogleCalendarSink` in MVP; add `SkylightDirectSink` behind a settings toggle in a later milestone, clearly labeled experimental.

---

## 4. Testing strategy

**Coverage is measured and reported, not gated.** `tool/check_coverage.sh` prints per-file and total line coverage for `lib/` with AutoRoute's generated output (`*.gr.dart`) filtered out, and exits zero regardless of the number. Setting `COVERAGE_THRESHOLD` turns it back into a hard gate if that is ever wanted.

The intent behind the original 100% target still stands where it earns its keep: freshness math, suggestion scoring, model round-trips, repositories and invite-code logic are expected to be exhaustively tested. Presentation code is tested for behaviour, not for line count.

Layers:
1. **Unit tests** — models (serialization round-trips, `copyWith`, equality — these are hand-written now, so they carry real test weight), freshness math, suggestion engine (table-driven, fixed clock), repositories against `fake_cloud_firestore`, auth service against `firebase_auth_mocks`, invite-code logic, CalendarSink implementations against mocked HTTP (`mocktail` + `http` test client).
2. **Widget tests** — every screen and reusable widget; providers overridden with fakes via `ProviderScope(overrides:)`. Router tested with AutoRoute's testing utilities (guard redirects: unauthenticated → login, no household → onboarding).
3. **Golden tests** — every rendered surface in light + dark (`test/goldens/`), and the freshness gauge widget in each state (fresh/due/overdue/never). Fonts are loaded from the bundle first, so goldens exercise the real type scale. Authored on macOS; another platform would need its own set.
4. **Firestore security rules tests** — Firebase emulator suite: member can read household, non-member cannot, etc.
5. **Integration tests** — `integration_test/` happy paths: sign up → create household → add contact → log hangout → see gauge change → confirm suggestion. Run locally against the emulators.

Tooling: `flutter test --coverage`, a dependency-free lcov filter/report script in `tool/`, and `very_good_analysis` under a zero-warning policy. No CI pipeline: `flutter analyze` and `flutter test` are run locally before any task is called done.

---

## 5. Milestones

Gated — each milestone ends with the analyzer clean, tests green, and a go/no-go review.

### M0 — Skeleton & rails (foundation)
- Lints and the coverage report script wired up
- Flutter project building with Riverpod (classic providers) and AutoRoute (sole codegen dependency)
- Theme, app shell, routing skeleton with placeholder screens
- CLAUDE.md and docs/ in place
- **Gate:** `flutter analyze` clean and the full suite green on an empty-ish app.

### M1 — Auth & household
- Email + Google/Apple sign-in
- Create household / join via invite code / member list
- Route guards (auth, household membership)
- Firestore security rules + emulator rule tests
- **Gate:** two accounts can join one household on two devices.

### M2 — Contacts & relationship types
- Contact CRUD with all fields incl. parent/guardian contact
- RelationshipType manager (add/rename/reorder/delete-with-reassign)
- List view with search, filter by type, and sort by name, recently added or cadence
- **Gate:** partner edits appear on the other device in realtime.

Sorting by freshness is M3's, not M2's: freshness is a function of the last
hangout, and there are no hangouts until M3, so every contact would read the
same. The sort control gains the option alongside the gauge.

### M3 — Hangouts & the gauge
- Quick-log flow (multi-contact select, date defaults to today, note)
- Hangout history per contact + household timeline
- Freshness gauge widget (goldens) + list sorting by freshness, added to the M2 sort control
- **Gate:** logging a hangout updates gauges everywhere instantly.

### M4 — Suggestions
- Pure suggestion engine + tests
- Home "Reconnect" section with reason strings
- "Plan it" flow → creates PlannedHangout (no calendar yet), snooze/dismiss
- **Gate:** suggestions match hand-computed expectations for seeded fixtures.

### M5 — Calendar (Skylight via Google Calendar)
- Google Calendar OAuth per household, calendar picker/creator
- PlannedHangout confirm → event create; edit/cancel sync both ways (webhook-less: poll on app open + on confirm)
- Setup guide screen: "point your Skylight at this calendar"
- **Gate:** confirmed hangout appears on the physical Skylight frame.

### M6 — Polish & stretch (optional)
- Weekly digest local notification
- SkylightDirectSink (unofficial API, experimental toggle)
- Contact import from device contacts
- Birthday tracking on contacts

---

## 6. Risks

| Risk | Mitigation |
|---|---|
| Skylight unofficial API breaks | It's a stretch item behind a flag; Path A is the supported route |
| Google Calendar OAuth verification friction (restricted scopes) | Use `calendar.events` scope on a dedicated calendar only; personal-use app can stay in testing mode |
| 100% coverage slows iteration | Pure-function-heavy design keeps it tractable; hand-written models are boilerplate-tested via shared round-trip helpers |
| Hand-written model boilerplate drifts (copyWith missing a field, asymmetric toMap/fromMap) | Mandatory round-trip + copyWith-every-field tests per model; a shared test helper makes adding them cheap |
| Two-writer conflicts | Firestore last-write-wins is fine for this data shape; hangouts are append-only |
| Scope creep (chores, rewards, meal plans…) | This app tracks *people and hangouts*. Skylight already does the rest. |

---

## 7. Open questions

1. ~~**Backend**~~: **Decided** — Firestore, as assumed throughout the plan.
2. ~~**Platforms**~~: **Decided** — iOS + Android only. Web and desktop scaffolding removed in M0.
3. **Name**: "Kith" is a placeholder.
4. **Google account**: does the household already run a Google Calendar the Skylight syncs from? If yes, M5 gets simpler (reuse it rather than OAuth-creating a new one).
5. **Kids' visibility**: v1 assumes kids don't use the app. Ever want a read-only kid view?
