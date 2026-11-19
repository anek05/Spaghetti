# Architecture

This extends the original shared graph editor. Graph schema remains 2 (new optional settings are normalized); the character profile envelope is schema 3. Reminder execution and macro compilation remain separate.

## Persistence boundary

```lua
-- Account SavedVariables: original legacy data, never assigned/mutated by v0.3
SpaghettiDB = {schema=2, graphs=..., layouts=...}

-- SavedVariablesPerCharacter: independent character profile
SpaghettiCharDB = {
  schema=3, serial=0, graphs={}, drafts={}, layouts={},
  selected=nil, importStatus="pending", -- or none/declined/imported
  editorWindow={x=0,y=0,width=1200,height=800}, -- optional
}
```

Profiles.Open validates and copies an existing character profile, normalizing new settings without replacing existing choices. First login creates an empty profile. A pending legacy offer does not execute legacy rules. Profiles.Import requires explicit confirmation, validates/converts legacy v1/v2 on copies, merges graph IDs without collision, rekeys placement prefixes, preserves node/edge IDs and makes all imported rules/outputs inactive. Imported native macro scope defaults to character. The account variable itself is the unchanged backup. Import decision is per-character and persistent.

Drafts are deep copies written to the character envelope on editor changes. Runtime snapshots use only committed graphs. Save commits the selected draft and removes its stored draft; unrelated drafts are retained. Overview enable flags synchronize both committed state and its live draft without committing unrelated changes. Layout and editor geometry are character-local. No Frame/runtime catalog objects enter SavedVariables.

## Modules

| Module | Responsibility |
| --- | --- |
| Registry / Graph | Shared definitions, dynamic ports/fields, stable IDs, edges, cycle/type validation and rejected-mode details |
| Storage / Migrations / Profiles | Serializable boundary, v1 conversion and independent character import/restore |
| Validation | Reusable reports for nodes, edges, ports, configuration/API/selection/compiler issues and rejected operations |
| Placement | Collision-aware graph-coordinate insertion using dimensions supplied by the actual renderer |
| Compat / Spells | Guarded modern APIs, learned catalog, conservative rank resolution and safe three-valued aura reads |
| Items | Equipped/bag catalog, item identity, cache requests, native slot lookup and equipment-set capability |
| MacroCompiler / MacroIntegration | Native text compilation, fixed supported flow, target requirements and guarded creation/editing |
| ReminderEngine / ReminderDisplay | Event-driven snapshots, Unknown propagation, content-adaptive unprotected visuals and pulse timers |
| Layout / SecureClicks | Unprotected placement previews; separate protected outside-combat hardware-click layer |
| Widgets / SpellPicker / ItemPicker | Reusable controls, clear dismissal, filtered selection, native drops and tooltips |
| Canvas | Cached dynamic node variants, typed ports, wires, validation styling, selection and zoom/pan |
| Overview / Editor / Core | Character workflow, import offer, examples, drafts, close/escape, runtime overview and events |

## Interaction

Combat mode changes collect incompatible edge IDs/ports before rejecting. They restore the old mode and retain every edge. Editor keeps rejection feedback until a change/selection; Canvas applies red outlines, port/wire colors and a compact near-node message. Generic reports preserve original string validation APIs used by compiler/tests. Missing content/input is an error; unavailable/unsupported states are surfaced rather than silently discarded.

The renderer measures existing node width/height. Placement first tries selected-node-right plus a wire gap, then nearby free candidates within the fixed 1700x1200 canvas. It never rearranges existing nodes. Scroll reveal converts graph bounds through the current zoom. Zoom still uses one scaled graph parent inside an unscaled scroll host: viewport=(graph*zoom-scroll), inverse=(viewport+scroll)/zoom. Ports, content and lines share this transform.

Show fields hide cast selection while non-clickable; text is never auto-overwritten. Icon/text layout adapts without altering saved placement. NOT preserves Unknown and inverts readable booleans. Player → NOT → Combat State gates combat with false; validation explains that distinction.

The editor is a named, ordinary BackdropTemplate frame with plain close handler and UISpecialFrames registration. Closing hides standalone menus and cancels wires but does not reload/disable runtime graphs. Secure action roots are separate UIParent children, never descendants/anchors of the editor or combat-hidden visual.

## Execution limits

Rules evaluate on combat/world/player-aura events, not frame polling. Spellbook/inventory events refresh catalogs and visible previews. Native item cache misses are requested once per session to avoid retry loops. No secret UNIT_AURA payload is inspected. Unknown never turns into Missing, including through NOT/AND.

The compiler supports the existing linear or one-branch subset. Cast qualifiers encode unit/relation/alive/exists as native conditionals. Target and Set Focus are separate commands. Equipment actions are linear and compile only; native restrictions decide execution. Equip Set requires positive CanUseEquipmentSets and readable set enumeration. No addon Lua calls equip, FocusUnit, TargetUnit or spell execution APIs.

Protected macro mutation remains outside-lockdown only with replacement confirmation. Secure clickable reminders remain outside-combat only, hide through a preconfigured secure handler and have no invisible no-icon target. Preview/placement never casts. Native secure recovery and taint behavior require targeted game tests; see [testing](TESTING.md).

## Native macro and toolbar contracts

Graph schema remains 2 and profile schema 3. Macro naming adds optional metadata: macroNameCustom, preserved legacyMacroName and nativeMacro (name/body/scope/index hint). Profile normalization operates on copies; legacy account data is never rewritten. Native identity is a unique matching name/body/scope signature, not a cached index. Full slot scans resolve reordering and reject ambiguity. Native replacement requires a fresh matching confirmation plan; readback verifies name/body/scope before recording an association. UPDATE_MACROS refreshes visible status. Only Macro Action OnDragStart invokes the guarded native pickup wrapper.

Toolbar controls share an explicit elevated mouse-transparent parent; individual controls enable mouse with bounded hit rectangles. The title drag region no longer overlaps first-row controls. Decorative panels are mouse-transparent; editor/canvas roots explicitly opt in. Secure reminder roots remain separate. Reminder evaluation isolates Lua errors per graph and reports named Unknown buff reasons, preserving three-valued logic.

## Combat lifecycle

Core normally evaluates rules at combat events. If PLAYER_REGEN_ENABLED arrives while InCombatLockdown is still true, it schedules at most 20 C_Timer.After checks at 0.1-second intervals. Each checks native lockdown again; none permits protected operations early. A generation token invalidates pending callbacks at new combat or PLAYER_LOGOUT. No retry carries a graph, settings or Frame snapshot. Once native lockdown clears, COMBAT_RECOVERY evaluates current saved runtime graphs and updates the open editor. Exhaustion stops retries safely; normal subsequent events remain available.

Continuous conditions use ordinary Display.Show/Hide. A still-visible event pulse may refresh only its click text/secure layer on exit/recovery, without restarting its generation/expiry timer. Hidden/expired pulses remain hidden. SecureClicks.Sync retains all existing lockdown, enabled/icon/cast/preview/placement guards. Editor notices mark transient combat failures; only those notices clear once both cached combat and native lockdown are false. Other notices are preserved. Library rows use local normal/highlight/disabled font states instead of a one-time FontString override.

The recovery path does not change graph/profile schemas, reminder activation or the incompatible-state connection contract. Regression coverage and required native checks are described in [testing](TESTING.md); client API boundaries are summarized in [API reference](API_REFERENCE.md).
