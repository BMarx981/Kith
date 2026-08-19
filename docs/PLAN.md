# Kith — Development Plan

Working title: **Kith** (rename freely; nothing in the plan depends on it).

A shared household app that tracks friends — yours and your kids' — shows how long it's been since you last saw each person, and suggests who to reconnect with. Flutter + Riverpod + AutoRoute, shared data between partners, editable relationship types, full test coverage, and a calendar hookup.

---

## 1. Product definition

### Core loop
1. Household members add contacts (adults and kids' friends).
2. When you hang out, you log it in ~10 seconds (who, when, optional note).
3. Every contact carries a **freshness gauge** driven by time-since-last-hangout vs. that contact's target cadence.
4. The home screen surfaces **suggestions**: who's overdue, ranked, with one-tap "plan it" that creates a calendar event.

### Users
- Two (or more) adults in one household, both editing the same list.
- Kids do not need accounts in v1; kids' friends are contacts *tagged to* a kid ("Child's friend", renamed per household), managed by parents.

### Entities
| Entity | Purpose |
|---|---|
| Household | The shared container. All data is scoped to it. |
| Member | An authenticated adult user belonging to a household. Carries that person's weekly-digest preference. |
| Contact | A person (or family unit) you track. |
| RelationshipType | Editable, per-household label list. Seeded: Friend, Family, Neighbor, Child's friend, Coworker. Fully CRUD-able. |
| Hangout | A logged meetup: date, contacts involved, who from the household attended, note. |
| PlannedHangout | A future intent: contact(s), a day, status, calendar event link. Covers both halves of acting on a suggestion — an arrangement to meet, and a "not now" that defers one. |

### Contact fields
- Name, relationship type (FK to RelationshipType)
- Contact info: phone, email, address (all optional)
- **Parent/guardian contact** (name + phone) — first-class field, because for a kid's friend the person you actually text is the parent
- Target cadence: weekly / biweekly / monthly / quarterly / twice-a-year / custom days
- Priority weight (low/normal/high) — feeds the suggestion ranking
- Birthday, with the year optional (M6)
- Notes, tags
- Archived flag (soft delete)

### Freshness gauge
`freshness = daysSinceLastHangout / cadenceDays`
- **Fresh** (green): < 0.75
- **Due** (amber): 0.75 – 1.25
- **Overdue** (red): > 1.25
- **Never** (neutral): no hangout has ever been logged for this contact. Built as
  one fourth state rather than two, because "never seen" and "no hangouts logged"
  name the same condition from the two ends, and §4's golden list already spells
  the set as fresh/due/overdue/never. It is deliberately not a shade of red: with
  no last hangout there is no ratio, so the gauge draws no arc and the freshness
  sort puts these contacts last rather than inventing a ratio from `createdAt`.

Rendered as a ring/arc gauge on the contact card and a sortable column in list view. The gauge is a pure function of (lastHangoutDate, cadence, now) — trivially unit-testable, no side effects.

### Suggestion engine
Pure Dart, no I/O. Ranks non-archived contacts by:

```
score = overdueRatio * priorityWeight * recencyDamping
```

- `overdueRatio` = freshness ratio, clamped at **3.0**. Past three times the
  cadence the number keeps climbing but says nothing new, and an uncapped ratio
  would let one long-forgotten contact hold the top of the list forever while
  priority stopped mattering at all.
- `priorityWeight` = 0.5 / 1.0 / 1.5
- `recencyDamping` = **0.25** while a PlannedHangout is standing, 1 otherwise.
  A quarter rather than zero: somebody you have arranged to see is not a person
  to prompt about, but hiding them would mean the list quietly forgets the most
  overdue person in the household the moment a plan is made, and the plan is
  worth seeing on the card.
- Tie-break: longest absolute time since last hangout, then name, then id, so
  the ranking is a total order and never reshuffles between rebuilds.

Who is left out, and why:

- **Archived contacts.** Archiving is Kith's removal; a removed person is not
  someone to be prompted about.
- **Fresh contacts.** The section answers "who is overdue", so somebody seen
  well inside their cadence has nothing to answer, and a household that is on
  top of everything sees an empty section rather than being told to reconnect
  with the friend they saw yesterday.
- **Deferred contacts**, while the deferral runs (below).

A contact with no hangout behind them is *not* left out. They carry no ratio, so
they cannot be scored against anyone and they sort below every measured
contact — the same rule the freshness sort follows — but somebody deliberately
added and never seen is exactly who the section exists for.

Output: top-N (default **5**, the top of the 3–5 band) suggestions with a human
reason string ("It's been 6 weeks — you usually see Marcus monthly"). The
sentence carries the name so it also stands alone in a notification digest.
Deterministic given a fixed clock → 100% coverable with table-driven tests.

### Acting on a suggestion

Three answers, all of which write a PlannedHangout, because all three are a
future intent about a person on a day:

| Action | Status | Day | Effect |
|---|---|---|---|
| Plan it | `proposed` | the day you picked | Damps the score by `recencyDamping`; the card says what is arranged |
| Snooze | `snoozed` | a week out | Removes the contact from the section until that day |
| Dismiss | `snoozed` | one whole cadence out | The same, for longer |

There is deliberately no "never suggest again": a contact you never want
prompted about is a contact to archive, so dismissing defers rather than
deletes. A plan runs out at the end of the day it names — an arrangement whose
day has gone by either happened, in which case a logged hangout has already
reset the gauge, or it did not, in which case the contact belongs back in the
section rather than damped by an arrangement nobody kept.

A snooze outranks an arrangement for the same contact, so saying "not now"
after making a plan still silences the prompt; otherwise the soonest plan
speaks for them.

### Suggestion surfacing
- Home screen "Reconnect" section (top 3–5), with the month's birthdays in a
  strip above it
- Optional weekly local notification digest ("3 people are overdue"), per
  member, off unless asked for — shipped in M6

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
- **flutter_local_notifications** + **timezone** + **flutter_timezone** for the
  weekly digest, and **flutter_contacts** for the address book import (M6)

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
    calendar/          // CalendarSink + Google Calendar: link, publish, poll
  routing/             // AutoRoute definitions + guards
```

### State conventions
- Repositories expose `Stream<T>` / `Future<T>`; providers wrap them (`StreamProvider`/`AsyncNotifier`).
- UI never touches Firestore types — only domain models.
- All time reads go through a `clockProvider` so tests can pin "now".

---

## 3. Calendar integration

PlannedHangouts belong on the household's calendar. That is one problem with a
supported answer, and a second, harder problem sitting behind it.

### The supported path: a shared Google Calendar

The app writes PlannedHangouts to a dedicated Google Calendar ("Hangouts") that
the household links once via OAuth. Confirm a plan and an event is created;
edit or cancel it and the event follows. Both ends are officially supported,
and the events show up in everyone's ordinary calendar app for free.

Everything the app writes goes through a `CalendarSink` interface, so a second
implementation later is additive rather than a rewrite.

### Downstream: the Skylight frame

A Skylight frame can subscribe to a Google Calendar as a synced source, so once
the calendar above exists, pointing the frame at it is a one-time setup step in
the Skylight app rather than anything Kith builds. Writing to a frame *directly*
is a different problem: there is no official API, only a community
reverse-engineered one, with email/password auth and endpoints that can change
without notice.

That work, and the frame-side setup guide that goes with it, has its own plan:
**`docs/SKYLIGHT.md`**. Nothing in the milestones below depends on it.

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
- Email and Google sign-in
- Create household / join via invite code / member list
- Route guards (auth, household membership)
- Firestore security rules + emulator rule tests
- **Gate:** two accounts can join one household on two devices.

Apple sign-in is not built. It was listed here originally and never shipped;
the screen offers no Apple button rather than one that always fails, and
`FirebaseAuthService.signInWithApple` answers `providerUnavailable`. It is
required to ship an iOS app that offers any other federated sign-in, so it is
a release blocker rather than a milestone gap, and it lands before the App
Store does.

Google sign-in went in ahead of M5 (2026-08-18) rather than with M1's other
work: Google Calendar authorisation runs through the same account and the same
plugin, and building the OAuth path twice to keep the milestone boundary tidy
would have cost more than it saved.

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

Snooze and dismiss are PlannedHangout statuses rather than a collection or a
flag of their own: deferring somebody is a dated household act both partners
should see, not a hidden edit to a shared record, and it is the same shape as
an arrangement. `PlannedHangout.calendarEventId` ships unwritten in M4 — the
field is part of the entity, and adding it in M5 would mean migrating documents
and rules for a value the model already round-trips.

### M5 — Google Calendar
- `CalendarSink` interface + `GoogleCalendarSink`
- Google Calendar OAuth per household, calendar picker/creator
- PlannedHangout confirm → event create; edit/cancel sync both ways (webhook-less: poll on app open + on confirm)
- **Gate:** confirming a plan puts a matching event on the linked Google Calendar as seen from a second client, and cancelling the plan removes it.

The gate deliberately stops at Google Calendar. Whether a frame has picked up a
subscribed calendar is Skylight's behaviour on Skylight's schedule, so gating
the milestone there would make a green build wait on hardware and on a
third-party refresh interval, for a write the tests can already prove correct.
Once the event is right in Google Calendar, the frame is a setup step, not a
feature.

M5 landed 2026-08-18. Three notes on what the milestone actually needed.

**Two scopes, not one.** §6's risk row says `calendar.events`, which covers
writing a plan onto a calendar and taking it off again. It does not cover
reading which calendars an account has, so on that scope alone the only way to
link one would be to type its address. The picker the milestone asks for needs
`calendar.calendarlist.readonly` alongside it — read-only, and over the
subscription list rather than over anybody's events. Both are asked for
together, at link time rather than at sign-in, so signing in to Kith still
grants it nothing.

**The link is on the household; the grant is per member.** `calendarId` and
`calendarName` are fields on `households/{hid}`, because the calendar the frame
reads is household property and both partners' plans belong on it. The OAuth
grant behind it is personal and is never stored: each member authorises their
own Google account, and a member without access to the linked calendar finds
out when a write is refused rather than by being told in advance. Any member
may link or unlink, which is a second branch on the household update rule
rather than an owner-only change.

**`confirmed` means one thing.** A plan is confirmed when, and only when, it is
on the household's calendar. Planning with a calendar linked writes the event
and confirms in one gesture; a plan whose event could not be written stays
`proposed` and says so on the card. That is what makes the status worth storing
rather than deriving, and it is what the poll reconciles against.

What M5 does not do: it never deletes an event it did not write, so unlinking a
calendar leaves the events already on it alone, and a cancel whose event delete
failed leaves one entry behind for the household to remove themselves. There is
no sweep for orphans.

**The gate is a device check.** Everything below it is proven headlessly: the
REST calls against a mocked transport, the sync ordering against a fake sink,
the plan flow and the poll through the widget tree. What no test can prove is
the last mile — a real OAuth client, a real Google account, a real second
client looking at the same calendar. Confirming a plan and watching it appear,
then cancelling it and watching it go, is a run on a device against the
household's own account.

### M6 — Polish & stretch
- Weekly digest local notification
- Contact import from device contacts
- Birthday tracking on contacts

M6 landed 2026-08-19, all three items. Four notes on what it actually needed.

**A birthday is not a date.** `Contact.birthday` is a `Birthday`, not a
`DateTime`, because a birthday recurs and its year is optional: you know a
friend's is the 14th of March long before you know they were born in 1988, and
a contact whose year had to be guessed to be stored would carry a fabricated
age forever. It is stored as one string in the two vCard spellings —
`1988-03-14`, or `--03-14` with no year — so it is one optional field, one
`clearBirthday` flag and one regex in the rules rather than three integer
columns. Everything that needs the year answers null without one.

The editor takes it as text with a lenient parser (`14 Mar`, `14 March 1988`,
`Mar 14`, ISO) rather than a date picker, because a picker cannot express "I
don't know the year" without a second control. All-numeric slash forms are
refused: `3/4/1988` is two different days either side of the Atlantic and the
app carries no locale to break the tie, so asking for the month by name is the
smaller cost.

A 29th of February lands on the 28th in a common year rather than the 1st of
March: the birthday belongs to February, and pushing it into the next month
would move it past a 1 March birthday that comes after it in every leap year.

Upcoming birthdays are a strip above the Reconnect list, not entries in it. The
engine ranks who you are overdue with; a date that is coming whatever you do
does not compete with that, and it cannot be planned, snoozed or dismissed,
which is what a card in the list offers. Capped at three so it stays a
heads-up.

**The digest is a snapshot, rescheduled on open.** The weekly digest is a
one-shot local notification carrying who is overdue *now*, and the app
reschedules it every time it opens. A repeating notification would keep
announcing whatever was true the week it was set up, and a household that has
since seen everybody would be told for months that three people are overdue.
The cost is real and worth naming: a member who never opens the app gets one
digest and then silence, because there is nobody to recompute the next one. The
alternative is a stale nudge repeating forever, and a correct fix is a server,
which the app deliberately does not have. A digest with nothing to say is
cancelled rather than posted — a notification asking for attention in order to
report that no attention is needed is worse than none.

**The preference is per member, and lives in Firestore.** `digestDay` (null for
off) and `digestHour` are fields on `households/{hid}/members/{uid}`. Per
member because it is personal: one partner may want the nudge and the other may
not. In Firestore rather than on the device because a member who signs in on a
second phone should get the digest there too, and because the alternative was a
fourth dependency for a key-value store. Null day rather than a separate on/off
flag, so "off" and "no day chosen" cannot disagree. The hour survives being
switched off, so turning it back on does not lose the time they picked.

Scheduling is inexact on Android. An exact alarm needs `SCHEDULE_EXACT_ALARM`,
which Android reserves for alarms and timers, and a weekly summary that arrives
within the hour is the same summary.

**Import reads, and never writes back.** The address book import asks for the
read permission only; Kith brings people over and never touches the phone's
contacts. Anybody the household already has is shown greyed and ticked rather
than hidden — somebody scrolling their address book wants to know why their
oldest friend is not on the list, and a silently shortened list answers
nothing. Matching is on name, phone digits or email, any one of which is
enough; an archived contact counts as already here, because re-importing
somebody the household deliberately put away would undo the archive by the back
door.

One label and one cadence for the whole import rather than per person: an
address book row says nothing about how often you want to see somebody, and
asking twenty times is how an import stops being one. Both are editable
afterwards. A birthday event on the row comes across, which is the one place
the milestone's three items meet.

Writes are one create per contact rather than a batch, because the repository's
create is what validates a draft and mints an id. An import that fails on the
fourteenth person has still added thirteen, and the screen says how many landed
and stays on the list, so retrying does not produce duplicates.

**Four dependencies, and what each is for.** `flutter_local_notifications`
posts the digest; `timezone` turns "Sunday at 9" into an instant;
`flutter_timezone` is what asks the phone which zone it is in, which `timezone`
cannot do and which the notification plugin's own README names as the way to do
it; `flutter_contacts` reads the address book. Platform config went with them:
desugaring and two receivers on Android, `POST_NOTIFICATIONS`,
`RECEIVE_BOOT_COMPLETED` and `READ_CONTACTS`, the notification-centre delegate
in `AppDelegate.swift`, and `NSContactsUsageDescription`.

**The gate is a device check**, as M5's was. Everything below it is proven
headlessly: the schedule call against a mocked plugin, the address book read
against a mocked method channel, the digest text and the birthday maths as pure
functions, and all three surfaces through the widget tree and the goldens. What
no test can prove is that a notification actually arrives on Sunday morning and
that a real address book reads the way a mocked one does.

---

## 6. Risks

| Risk | Mitigation |
|---|---|
| Skylight has no official API | No milestone depends on one: the frame subscribes to the Google Calendar M5 writes. Direct-to-frame work is scoped separately in `docs/SKYLIGHT.md` |
| Google Calendar OAuth verification friction (restricted scopes) | `calendar.events` plus read-only `calendar.calendarlist.readonly`, asked for at link time rather than at sign-in; personal-use app can stay in testing mode. See the M5 notes |
| 100% coverage slows iteration | Pure-function-heavy design keeps it tractable; hand-written models are boilerplate-tested via shared round-trip helpers |
| Hand-written model boilerplate drifts (copyWith missing a field, asymmetric toMap/fromMap) | Mandatory round-trip + copyWith-every-field tests per model; a shared test helper makes adding them cheap |
| Two-writer conflicts | Firestore last-write-wins is fine for this data shape; hangouts are append-only |
| Scope creep (chores, rewards, meal plans…) | This app tracks *people and hangouts*. Skylight already does the rest. |

---

## 7. Open questions

1. ~~**Backend**~~: **Decided** — Firestore, as assumed throughout the plan.
2. ~~**Platforms**~~: **Decided** — iOS + Android only. Web and desktop scaffolding removed in M0.
3. **Name**: "Kith" is a placeholder.
4. ~~**Google account**~~: **Decided** (2026-08-18) — the household already runs a Google Calendar the frame syncs from, so M5 links an existing calendar rather than creating one. The picker lists the account's calendars; there is no create flow.
5. **Kids' visibility**: v1 assumes kids don't use the app. Ever want a read-only kid view?
