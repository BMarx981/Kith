# M1 — Firestore security rules

Status: **rules implemented, tests deferred.** Written 2026-08-15, after the
Firebase project (`kith-hawkstreak`) was created and its client config was
committed to a public repository. `firestore.rules`, `.firebaserc`,
`firestore.indexes.json` and the `firebase.json` firestore/emulators blocks
landed 2026-08-16.

**The test matrix below is unbuilt, by decision.** The harness question at the
bottom was answered "skip for now" on 2026-08-16 rather than picking either
runner, so the rules ship unverified against behaviour. This is a live deviation
from the `CLAUDE.md` non-negotiable "every rules change ships with an emulator
rules test", recorded here rather than by quietly relaxing that rule. The matrix
stays as the spec for whenever the harness question gets a real answer, and it
should be built before anything beyond the two-person household depends on it.

M3 (2026-08-18) added shape validation for `hangouts/{hgid}` under the same
deviation: the rules compile clean by the check below, the matrix gained its
hangout cases, and none of them are executed. The debt is now two milestones
deep and is the largest single thing outstanding on the backend.

What *was* verified: the rules compile clean. The emulator does not compile
rules at startup, so the check is a `PUT` of the file to the running emulator's
`/emulator/v1/projects/{project}:securityRules` endpoint, which returns 400 with
a line number on a syntax error and 200 with an empty body when there are no
errors *or warnings*. That needs only `curl` and the Firebase CLI — no npm. It
proves the file parses. It proves nothing about whether it denies the right
things.

```bash
firebase emulators:exec --only firestore --project kith-hawkstreak '
  python3 -c "import json,sys; print(json.dumps({\"rules\":{\"files\":[{\"name\":\"firestore.rules\",\"content\":open(\"firestore.rules\").read()}]}}))" > /tmp/p.json
  curl -sf -X PUT -H "Content-Type: application/json" --data @/tmp/p.json \
    "http://127.0.0.1:8080/emulator/v1/projects/kith-hawkstreak:securityRules"
'
```

## Why this is the next thing

The committed `google-services.json` / `GoogleService-Info.plist` / `firebase_options.dart`
contain no secrets — Firebase client API keys identify a project, they do not
authorise anything, and they ship inside every copy of the app regardless. What
the public repo *does* publish is the **project id**, and a project id is all an
attacker needs to point a Firestore SDK at the database.

That is harmless while the rules deny everything. It is total exposure if the
database is ever created in test mode. So the rules land **before** the database
does, and `PLAN.md`'s M1 line item "Firestore security rules + emulator rule
tests" is promoted ahead of the sign-in screen.

## The decision this forces: a top-level invite-code index

`CLAUDE.md` currently says:

> Firestore paths are household-scoped: everything lives under `households/{hid}/...`.
> No top-level user data collections.

**Joining a household cannot obey that rule.** The join flow is:

1. A prospective member types a 6-character invite code.
2. The app must turn that code into a household id.
3. Only then can it write `households/{hid}/members/{uid}`.

At step 2 the user is not yet a member, so they cannot read anything under
`households/{hid}`. The two ways out:

| Option | Verdict |
|---|---|
| Let unauthenticated-to-the-household users **query** `households` where `inviteCode == X` | **Rejected.** Firestore rules cannot inspect a query's `where` predicates — only `limit`/`offset`/`orderBy`. Permitting the query means permitting `list` on the whole collection. |
| A top-level **`inviteCodes/{code}`** index document mapping code → household id | **Chosen.** The document id *is* the code, so `get` requires knowing it and `list` stays denied. |
| A callable Cloud Function that performs the join server-side | **Rejected for now.** Requires the Blaze plan and a second deployment target. Revisit if abuse appears. |

This needs a **CLAUDE.md amendment**, not a silent violation. Wording as
landed: household *data* stays under `households/{hid}`; the only permitted
top-level collection is `inviteCodes`, which holds no user data — just a code →
household id pointer that exists so a non-member can find the household they
were invited to. Any further top-level collection needs explicit approval.

### Why the index alone is not the security boundary

A top-level collection any authenticated user can create in is squattable:
someone could write `inviteCodes/ABC123` pointing at *your* household and then
"join" it. So the index is a **lookup convenience only**. The actual check lives
in the member-create rule, which reads the household document server-side and
compares against *its* `inviteCode` field. A forged index entry fails that check.

Consequences that fall out of this, all of them wanted:

- **Uniqueness is free.** The code is the document id, so a colliding
  `create` fails at the database. That maps onto the existing `ConflictFailure`,
  and the repository retries with a freshly generated code.
- **Regeneration is a three-step transaction**: create the new index doc, update
  `households/{hid}.inviteCode`, delete the old index doc.
- **Squatting is possible but unmitigated by design.** The code space is
  32^6 ≈ 1.07 billion (Crockford Base32, six characters). Occupying a meaningful
  fraction of it is not a threat model for a two-person household app. Recorded
  here so it is a decision rather than an oversight.

### The proof-of-knowledge wart

To let the rule verify the joiner knows the code, the member document carries a
`joinedWithCode` field at create time. It is a write-time token, not part of the
`Member` domain model — `Member.fromMap` ignores unknown keys, so nothing needs
to change there. It is called out here because a reader of the raw Firestore data
will otherwise wonder what it is.

### Household creation is three writes, not one

(This section said "two writes" when it was drafted. The access matrix below
requires the household-create rule to find an index entry the creator already
owns, which cannot be true unless the index entry is written first, so it is
three. Corrected 2026-08-16.)

Rules evaluate each write in a batch against the state *before* the batch, so a
batched "create household + create owner member doc" cannot have the member rule
`get()` the household it is being created alongside. The same applies to the
index entry the household rule checks. The order is therefore:

1. `inviteCodes/{code}` — the creator reserves the code, with
   `householdId` set to the household id they are about to use.
2. `households/{hid}` — the create rule confirms that index entry exists,
   points here, and was created by this uid.
3. `households/{hid}/members/{uid}` — the owner document, allowed because the
   now-committed household names this uid as `createdBy`.

The client generates the household id locally (`collection.doc()`) so step 1 can
name it before step 2 exists.

Partial failure is inert at every step. Stopping after 1 leaves an index entry
pointing at a household that does not exist; a `get` on it resolves to nothing
and the join fails cleanly. Stopping after 2 leaves a household with no members,
which is invisible to every query in the app and readable by nobody. The
repository retries; no cleanup job is needed.

## Finding your household: a collection group query

Added 2026-08-17, with the household guard.

A returning user has to answer "which household am I in?" before they can read
anything inside it. The membership document at
`households/{hid}/members/{uid}` is the only record that they belong to one,
and it is unreachable by path because the path contains the `hid` they are
trying to discover.

Three ways out were considered:

1. **Custom auth claims.** What Firebase documentation pushes hardest, because
   rules then read the claim for free instead of paying a `get()`. Needs a
   Cloud Function to mint them and a token refresh to propagate, so a user who
   joins a household stays locked out until the token rolls over. Rejected: no
   backend in this project, and the plan adds no infrastructure.
2. **A top-level `users/{uid}` document** holding the household id. Simplest
   query, but it makes membership two writes that can diverge, and it is a
   second top-level collection, which `CLAUDE.md` requires approval for.
3. **A collection group query** over `members`, filtered to the caller's own
   uid. Chosen. The membership document stays the single source of truth: the
   question is asked of the data directly rather than of a copy kept alongside
   it. No new top-level collection, so the `CLAUDE.md` rule stands unamended.

The query is `collectionGroup('members').where('id', '==', uid)`. It filters on
the `id` **field**, not the document id, because a collection group cannot be
queried by document id without spelling out full paths — and because the field
constraint is what makes the query provably safe to the rules engine.

The rule:

```
match /{path=**}/members/{uid} {
  allow read: if signedIn() && request.auth.uid == resource.data.id;
}
```

Rules are not filters. This passes only for a query whose constraints guarantee
every document it could return satisfies the rule, which is why the `where`
clause and the rule condition have to mirror each other exactly. Drop the
`where` and Firestore refuses the whole query rather than returning a filtered
subset.

Two things a reader should know about it:

- **It widens nothing.** The documents it returns are the caller's own
  membership records, which live in households they are a member of by
  definition, and which `isMember(hid)` already granted them.
- **`{path=**}` is broad.** It matches any collection named `members` anywhere
  in the database. Nothing else uses that name today; a future one would
  inherit this rule, so the name is effectively reserved.

Ordering is done on the client rather than with an `orderBy`, because ordering
a filtered collection group query costs a composite index and a user is in one
or two households.

`firestore.indexes.json` carries the matching field override. Collection-scope
single-field indexes are created automatically; **collection-group-scope ones
are not**, so `members.id` has to be declared or the query fails in production
with a missing-index error. The override repeats the collection-scope entries
Firestore would have made on its own, because a field override replaces the
automatic configuration for that field rather than adding to it.

## Access matrix

`isMember(hid)` = `exists(/databases/$(db)/documents/households/$(hid)/members/$(request.auth.uid))`
`isOwner(hid)`  = that document exists **and** its `role == 'owner'`

| Path | read | create | update | delete |
|---|---|---|---|---|
| `households/{hid}` | member | signed in, `createdBy == uid`, `inviteCode` matches an index doc they own | owner; `id`/`createdAt`/`createdBy` immutable | denied in v1 |
| `households/{hid}/members/{uid}` | member | self only, and either `joinedWithCode` equals the household's current code with `role == 'member'`, or the household's `createdBy == uid` with `role == 'owner'` | self (`displayName`, `email`, `photoUrl`), or owner (`role`); `id`/`joinedAt` immutable | self (leave), or owner (remove) |
| `households/{hid}/contacts/{cid}` | member | member, valid shape, `id == cid` | member, valid shape; `id`/`createdAt` immutable | **denied** — archiving is the removal the app offers |
| `households/{hid}/relationshipTypes/{rid}` | member | member, valid shape, `id == rid` | member, valid shape; `id`/`createdAt` immutable | member |
| `households/{hid}/hangouts/{hgid}` | member | member, valid shape, `id == hgid`, `createdBy == uid` | member, valid shape; `id`/`createdBy`/`createdAt` immutable | member |
| `households/{hid}/plannedHangouts/{pid}` | member | member | member | member |
| `{path=**}/members/{uid}` (collection group) | own membership only, and only for a query constrained to `id == uid` | n/a | n/a | n/a |
| `inviteCodes/{code}` | `get` if signed in; `list` **denied** | signed in, `createdBy == uid`, id is a well-formed code | denied — regeneration is create + delete | owner of the household it points at |
| everything else | denied | denied | denied | denied |

Rules to write explicitly, because they are the ones that bite:

- **No privilege escalation on join.** A self-created member document must carry
  `role == 'member'`. Only the owner path may write `role == 'owner'`, and only
  when the household's `createdBy` is that uid.
- **No owner demotion by non-owners**, and an owner cannot remove their own
  owner role while they are the only owner. (Enforced in rules; the "last owner"
  count is not queryable from rules, so this is `role` immutability on self-update
  plus owner-only role writes.)
- **Field-shape validation on create**: required keys present, types correct,
  timestamps are `int` epoch millis. This is the layer that stops a hostile
  client writing a 10 MB string into `name`.
- **Terminal deny.** No wildcard `match /{document=**}` allow. Anything not
  matched above is refused.
- **No per-member ownership inside a household.** Any member may write any
  contact and any label. That is the product: two adults edit one list.
  Deleting a label and reassigning the contacts filed under it is one client
  batch, which is why both writes are permitted to the same member; rules
  cannot check that the batch is well formed, and that guarantee stays the
  repository's.
- **Contacts are never hard-deleted.** `allow delete: if false`, because a
  contact's hangouts are the household's history and deleting the person would
  orphan them. `isArchived` is the soft delete.

Amended 2026-08-18, when M2 landed the contact and label models: those two
paths moved from "membership is the whole gate" to full shape validation
mirroring `lib/data/models/contact.dart` and
`lib/data/models/relationship_type.dart`. `hangouts` and `plannedHangouts`
still gate on membership alone, and tighten in M3.

## Repository / config changes

All done as of 2026-08-16.

- `firestore.rules` — new.
- `firestore.indexes.json` — new. Empty until 2026-08-17, when the
  `members.id` collection-group field override landed for the membership
  lookup. Grows again in M2/M3 when list views need composite indexes.
- `firebase.json` — held only the FlutterFire block. Now also carries `firestore`
  (rules + indexes paths) and an `emulators` block: firestore 8080, auth 9099,
  UI 4000, `singleProjectMode` on.
- `.firebaserc` — new; pins `kith-hawkstreak` as the default project so
  `firebase emulators:start` and `firebase deploy` do not need `--project`.
- `CLAUDE.md` — the `inviteCodes` amendment, plus a pointer here for the
  deferred rules tests.
- `docs/PLAN.md` — §2 now shows `inviteCodes` in the Firestore layout.

## Test plan

`CLAUDE.md`: *every access pattern gets a positive and a negative case*. Concretely,
per collection: member succeeds, non-member fails, unauthenticated fails. Plus the
cases that are specific to this design:

**Join flow**
- Correct code → member document created, `role == 'member'`.
- Wrong code → denied.
- Correct code but `role: 'owner'` in the payload → denied (escalation).
- Correct code but `uid` mismatched to the document id → denied (joining as someone else).
- A forged `inviteCodes/{code}` pointing at a household the attacker does not own → denied.
- Code that was regenerated after being read → denied.

**Membership**
- Member reads/writes every subcollection: allowed.
- Non-member reads any of them: denied.
- Unauthenticated reads any of them: denied.
- Member of household A reads household B: denied.

**Membership lookup (collection group)**
- Own membership, queried as `where('id', '==', own uid)`: allowed.
- The same query for somebody else's uid: denied.
- The query with no `where` clause at all: denied.
- Unauthenticated: denied.

**Roles**
- Owner changes another member's role: allowed.
- Member changes their own role to owner: denied.
- Member updates their own `displayName`: allowed.
- Member removes another member: denied. Owner removes another member: allowed.
- Member removes themselves: allowed.

**Hangouts** (added with the shape rules in M3, 2026-08-18)
- Member logs a hangout naming themselves as `createdBy`: allowed.
- Member logs one crediting somebody else: denied.
- Member edits another member's hangout — date, note, who was there: allowed.
- Edit attempting to change `createdBy` or `createdAt`: denied.
- Hangout with an empty `contactIds`: denied.
- Hangout with more than 50 contacts or more than 20 attendees: denied.
- Note past 2000 characters: denied.
- Non-member reads or writes any hangout: denied.
- Member deletes a hangout: allowed. (Unlike contacts, which have no delete.)

**Immutability**
- Update attempting to change `households/{hid}.createdAt` / `createdBy` / `id`: denied.
- Update attempting to change `members/{uid}.joinedAt`: denied.

**Index**
- Signed-in `get` on a known code: allowed.
- `list` on `inviteCodes`: denied, signed in or not.
- Unauthenticated `get`: denied.

## The decision, and how it went

**Answered 2026-08-16: skip the rules tests for now.** Neither runner was
adopted; `test/rules/` does not exist. The rules were written and syntax-checked
against the emulator, and that is the whole of the verification. Revisit by
picking one of the two options below — the recommendation still stands.

**How do the rules tests run?** This is a dependency question, so it is yours.

| Option | Cost | Notes |
|---|---|---|
| **`@firebase/rules-unit-testing` (JS)** — recommended | Adds `package.json` + `node_modules` to a Flutter repo | The supported, fast path. Runs headless against the emulator in seconds, has first-class `assertFails`/`assertSucceeds`, and `withSecurityRulesDisabled` for seeding fixtures. Every Firebase rules example is written against it. |
| **Dart integration tests** against the emulator | No new tooling | Needs a booted simulator or device, so it is slow, and it cannot seed fixtures past the rules it is testing. Impersonating several users means creating real emulator auth accounts per case. |

I lean strongly to the JS runner: rules are a Firestore artefact, not a Flutter
one, and the Dart route makes the negative cases awkward exactly where they matter
most. `test/rules/` would then hold JS, and `flutter test` would remain untouched.

## Sequencing

1. ~~`.firebaserc` + `firebase.json` emulator block + empty `firestore.indexes.json`.~~ Done.
2. ~~Rules test harness and the **failing** matrix above.~~ **Skipped by
   decision** — see above. The matrix is unbuilt.
3. ~~`firestore.rules`.~~ Done, and syntax-checked rather than behaviour-tested.
4. ~~`CLAUDE.md` + `docs/PLAN.md` amendments.~~ Done.
5. Create the database in `us-east1` **locked**, then `firebase deploy --only firestore:rules`.
6. Restrict the API keys in the Google Cloud console (separate from this work,
   but do it in the same sitting).

Steps 1–4 needed no live project and no database. Step 5 is the first one that
touches the real backend, and it is the next action here.

## Explicitly out of scope

- The `HouseholdRepository` implementation. Rules define the contract; the
  repository comes next and is tested against `fake_cloud_firestore`, which does
  not evaluate rules.
- Storage rules. Contact photos were cut from the plan on 2026-08-18, so the
  app uses no Storage bucket and there is nothing to write rules for.
- App Check. Worth it only if abuse actually shows up.
- Any Cloud Function.
