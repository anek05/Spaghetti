# Changelog

## Unreleased

- Recover macro status and active reminder click targets after delayed native lockdown release, with bounded retries cancelled by new combat/logout. Clear marked stale combat notices without discarding unrelated feedback.
- Refresh still-visible event-pulse click targets without restarting their expiry. Preserve current saved-rule, preview, placement, disabled and no-icon boundaries.
- Configure node-library normal/highlight/disabled font states locally to address sticky hover color.
- Extend UI regression coverage for adversarial combat exit, lifecycle cancellation, current saved settings and reused library rows. In-game retests remain open.
- Consolidate project documentation, separate manual test records from developer guides, remove duplicate package documentation and expand local-data ignore patterns.
- Add a blank public MVP test template and exclude the private filled owner record from normal Git uploads without modifying its contents.

## 0.3.1 - 2026-11-14

- Bounded the overlapping title drag region and established explicit toolbar mouse/frame ordering, including zoom controls; decorative panels no longer capture mouse input.
- Native macro names default to graph names, with explicit custom overrides/reset and conservative legacy normalization. Native name readback, collisions, scope, slot limits and replacement confirmations are validated.
- Added Macro Action with native icon and genuine drag-to-action-bar pickup outside combat. Persisted identity is revalidated by name/body/scope across index changes; external edits, missing macros and duplicates cannot silently pick up a reused index.
- Separated graph save/generation from Created, Not created, Out of sync and Missing native statuses. Confirmation preserves newer draft edits.
- Added named Unknown/secret buff diagnostics and isolated runtime Lua errors without changing aura truth or introducing estimates.
- Added 48 model assertions and UI lifecycle/hit-routing regression coverage under Lua 5.1 and LuaJIT. Native in-game behavior requires separate acceptance using the [manual test plan](tests/manual/MVP_TEST_PLAN.md).
- Preserved schemas and character/account storage boundaries. Recorded Macro Text to Graph and estimated buff state as future work only.

## 0.3.0 - 2026-11-14

- Added per-character SpaghettiCharDB profiles, persistent local drafts and editor geometry. Original account-wide SpaghettiDB remains untouched.
- Added explicit one-time legacy import/decline, independent copies, collision-safe graph/layout rekeying and inactive imported reminders. New/imported native macro creation defaults to character scope.
- Added red node/port/wire feedback and contextual messages for rejected Combat State switches; existing edges remain intact.
- Verified NOT(InCombat) outside/inside/outside behavior. Added a warning for NOT(Player) feeding the Combat gate.
- Removed class-specific new-node defaults; added empty content placeholders, text-only/icon-only reminder layouts and hidden irrelevant cast settings.
- Added actual-dimension collision-aware node insertion to the right of selected/last nodes, viewport reveal and explicit full-canvas failure.
- Replaced template close behavior with an unprotected direct close handler and Escape registration, isolated from secure reminders.
- Added Item Picker for readable equipped gear and bags, quality/tooltips, cursor drops and retained unavailable identities.
- Added direct Focus casts with friendly/hostile/alive/exists qualifiers, readable target labels and separate Set Focus action.
- Added linear Equip Item, Equip Slot and capability-gated Equip Set compilation. No automatic item/equipment/focus actions.
- Extended model and UI regression tests. Combat aura truth and secure click restrictions remain unchanged.

## 0.2.0 — 2026-11-14

- Added reusable searchable spell/icon picker and learned-spell cursor drops.
- Added shared, conservative rank resolution and exact-rank selection; retained unavailable legacy selections.
- Consolidated combat nodes into typed Combat State modes; migrated existing edges/coordinates and kept a v1 backup.
- Removed redundant Player from fresh examples while preserving existing Player nodes.
- Added dropdown arrows, expanded feedback, header toggle and outside/Escape dismissal.
- Added Active Reminders with per-output toggles, graph shortcuts and explicit applied/waiting/visible/unsupported/error states.
- Added independent reminder placement storage, draggable/resizable placement previews and Save/Cancel.
- Added 50–150% graph zoom with Ctrl+wheel/buttons and per-graph persistence.
- Added optional secure hardware click-to-cast **outside combat only**, separate from dynamic visuals.
- Allowed combat aura evaluation only for client-declared NeverSecret spells with current explicit permission; secret/contextual results remain Unknown.
- Preserved macro compiler layouts and guarded native macro creation/editing.
- Extended tests for migrations, spells, statuses, layout, zoom and secure-layer boundaries.

Reliable Battle Shout Missing decisions and arbitrary clickable reminder visibility during combat remain unsupported; estimates and manager-frame introspection are not substitutes.
