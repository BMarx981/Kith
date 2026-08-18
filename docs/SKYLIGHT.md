# Skylight — frame integration plan

Status: **deferred.** Nothing in `docs/PLAN.md` M0–M6 depends on this document.
Kith's calendar milestone (M5) ends at Google Calendar; this is the work that
sits downstream of it.

---

## 1. Why this is its own plan

Skylight is two things to Kith, and they have very different risk profiles:

- **A calendar subscriber.** A frame can be pointed at a Google Calendar in the
  Skylight app and it renders what it finds. This needs no code from us — it is
  a setup step a household does once — and it is how the product is expected to
  work day to day.
- **A write target.** Putting events on a frame *directly*, without a Google
  Calendar in the middle, means an unofficial API: reverse-engineered, no
  contract, no deprecation policy, no support if it stops.

Folding the second into a milestone would mean gating a build on a vendor's
behaviour. Keeping it here means M5 can ship, be tested and be trusted on its
own, and this can be picked up (or abandoned) without touching it.

## 2. Path A — subscribe (the supported route)

Once M5 has the household writing PlannedHangouts to a dedicated Google
Calendar, the frame side is configuration:

1. In the Skylight app, add the household's "Hangouts" Google Calendar as a
   synced calendar source.
2. Events written by Kith appear on the frame on Skylight's own sync schedule.

The only thing Kith could usefully build here is a **setup guide screen** —
static instructions plus the calendar's share address, so nobody has to
remember which account owns it. That is a help screen, not an integration, and
it can land any time after M5.

Open: how quickly a frame picks up changes to a subscribed calendar, and
whether deletions propagate as reliably as creations. Both are observable with
one frame and one test calendar, and neither blocks M5.

## 3. Path B — write directly (experimental)

A community-maintained reverse-engineered OpenAPI spec exists
(github.com/TheEagleByte/skylight-api): email/password auth yielding a Basic
token, with endpoints for calendar events, chores and lists per frame.

If this is ever built, it lands as a second `CalendarSink` implementation —
`SkylightDirectSink` — behind a settings toggle labelled experimental, and it
is **allowed to fail gracefully**. A frame write that errors must never block
logging a hangout, confirming a plan, or the Google Calendar write that is the
real record.

### What building it would involve

- Credential capture and storage: Skylight account email/password, which is a
  materially worse thing to hold than an OAuth token, and needs a decision about
  where it lives before any of the rest matters.
- Frame discovery (a household may have more than one) and frame selection.
- Event create/update/delete mapped from PlannedHangout, tested against a
  mocked HTTP client the way `GoogleCalendarSink` is.
- A visible health state, so a sink that has started failing says so instead of
  silently dropping events.

### What would have to be true first

- M5 shipped and stable, so there is a working sink to compare against.
- A clear reason the Google Calendar route is not enough — Path B removes a
  Google account from the middle, and that is its whole benefit.
- Acceptance that it can break without notice and that fixing it is
  re-reverse-engineering, not reading a changelog.

## 4. Decision

Not scheduled. Revisit after M5 is running against a real frame for a while;
if subscription latency and reliability turn out to be fine, Path B has no
problem left to solve.
