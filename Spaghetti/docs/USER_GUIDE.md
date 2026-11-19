# Spaghetti user guide

For development version 0.3.1 and local Unreleased stabilization changes. The editor offers **Reminder / CD** and **Macro** modes; the former UI label does not imply a general cooldown engine. Features below describe intended behavior. The source project's README and manual test records distinguish owner-reported game results from automated coverage and pending checks.

## Editing graphs

Open `/spaghetti`, choose a mode and select New or an existing graph. Examples adds an explicit example rather than replacing your graphs. New characters start empty; class templates are never automatically activated.

Add nodes from the library, configure their fields and drag node titles to move them. Blue ports carry event/flow signals; green ports carry conditions. Drag output to input to connect. Right-click a port to disconnect; a node's `x` removes it and its edges. Incompatible types, self-links and unsupported cycles are rejected. Changing Combat State to an incompatible event/condition mode currently preserves the old mode and connections and explains the rejection; automatic disconnection is future work.

Zoom is 50–150% through Ctrl+wheel or the zoom controls. Wheel/Shift+wheel and scrollbars pan. New nodes are placed near the selected/last node using rendered dimensions, with an explicit failure if the fixed canvas has no free space. Existing nodes are not automatically rearranged.

Save commits the draft. Invalid drafts can be saved for later repair, but invalid runtime graphs do not execute. Editing an already active reminder affects its saved runtime only after Save/Apply; switching graphs does not implicitly apply the draft. WoW writes SavedVariables on reload or normal logout.

## Reminder flows

For text outside combat, connect `Combat State (In Combat) → NOT → Show Reminder` through green ports. Set text, choose No icon, leave Clickable off and Show Enabled on, then Apply reminder. `Player → NOT → Combat State` instead gates combat with false; the editor warns about that direction.

In Combat is a persistent condition. Enter Combat and Leave Combat emit a single event; connect their blue Next port to Show's Run input and set Event duration. Apply while already in combat waits for the next transition. Show may combine a condition and event, with the condition gating the event. Hide targets a Show node ID or all outputs in its graph and takes precedence within an evaluation. Unknown propagates through boolean nodes rather than becoming Missing.

Show supports text only, icon only, or both. Empty text plus no usable icon is an error. A cast spell matters only when Clickable is enabled. Active Reminders distinguishes saved/not applied, disabled, waiting/false, visible, Unknown and errors. Its switches affect individual saved outputs, not unrelated draft edits or sibling outputs.

Test / Preview is a labeled five-second visual preview, independent of live conditions. It never casts or counts as a live rule. Edit placement opens unprotected draggable previews with size controls; Save placement commits and Cancel restores the saved layout. Placement is blocked/cancelled in combat. These previews must not be confused with a real reminder that returns after placement closes.

Clickable reminders use a separate secure icon for a genuine player click outside combat. They are hidden securely at combat entry. Local Unreleased changes retry current rule evaluation briefly if native lockdown has not cleared at the exit event. Recovery still needs game retesting; no combat click-to-cast support is intended. No icon, disabled outputs, previews and placement must not leave invisible cast targets.

## Spell and item selection

Spell fields search readable learned spellbook entries, with localized names, icons and available rank information. Passive spells are excluded from cast choices. Learned spellbook drops are supported. Auto rank uses unambiguous family/rank evidence; otherwise the existing selection is retained with a warning. Exact rank remains selectable. Associated Spell can derive a selection from one unambiguous upstream Buff.

The Item Picker searches readable equipped gear, backpack and equipped bags, not the bank or a global item database. Equip fields filter equippable items. Native item drops are checked against the readable owned catalog. Selections use stable `item:ID` identities; an unavailable selection remains saved and explains why it cannot currently be used. Uncached item requests are limited per session.

## Native macros

Connect Macro Start to linear Cast Spell, Use Item, Target Unit, Set Focus or equipment actions. The alternative supported shape is one immediate Branch with one condition and two terminal Cast/Use actions with matching commands and targeting. Nested branches and mixed equipment branches are unsupported. Multiple action lines remain subject to the game's hardware-press/GCD rules.

The graph name supplies the default Macro name. Editing Macro name makes it independent; Use graph name restores the default. Legacy non-default names remain custom. An ambiguous old `Spaghetti` value is retained as metadata and explained rather than silently rewriting an existing native macro. Names are limited to 16 characters and bodies to 255 bytes; collisions, scope and replacement are checked without silent truncation.

Create macro writes to the selected native scope, character-specific by default. Update macro asks for replacement confirmation. Native name, body and scope are read back before a ready association is recorded. Macro Action distinguishes Not created, Created, Out of sync and Missing. A saved graph and generated preview are separate from the native macro.

When Created, drag the icon directly to an action bar outside combat and use the resulting native button normally. Selecting, previewing or clicking a field does not pick up or execute a macro. Status checks use a unique name/body/scope match across current slots, not a trusted cached index. External edits or ambiguous identities stop dragging. External renames/deletion require explicit recreation rather than guessing by body. Existing native icon choices are retained.

Out of sync means the graph's intended name, generated text or scope differs from the native macro. Review the change, choose Update macro and confirm; Cancel leaves the native content unchanged. The editor shows intended versus actual names when they differ. Native creation/editing and pickup are blocked during combat. Local recovery changes clear only marked combat notices after lockdown, preserving unrelated feedback.

Equip Item emits `/equip item:ID`; Equip Slot emits `/equipslot <slot> item:ID`. Main Hand is normally slot 16, obtained through the client's slot lookup. For Axe of Orgrimmar, the tested example is `#showtooltip` followed by `/equipslot 16 item:15424`. Equip Set is offered only when the required native capability and set enumeration are available.

Target Unit (focus) emits `/target focus`, changing current target to an existing focus. Set Focus emits a separate `/focus` action. Cast Spell (Focus) emits `[@focus]` and preserves current target; optional Friendly/Hostile, Alive and Exists requirements become native conditions. For example: `/cast [@focus,harm,nodead] Earth Shock`. A missing/invalid focus, range, resources, cooldown or line of sight may prevent execution even when text is valid.

## Profiles and restrictions

Graphs, persistent drafts, enabled/applied flags, placement, selection, zoom and editor geometry belong to the character's `SpaghettiCharDB`. The old account-wide `SpaghettiDB` remains a separate legacy source. Import copy is explicit and makes independent graphs/settings; imported reminders and their Show outputs start disabled/unapplied. Imported macros default to character scope without modifying existing native macros. Keep separate remembers the decision for that character; Import account data remains available when applicable.

Battle Shout rank 2 Missing was reported working outside combat. Combat evaluation is not approved: secret/inaccessible reads remain Unknown with a named reason, never inferred absence. During combat the implementation requires NeverSecret classification and explicit current permission before reading. There is no timer/cast estimator, secret-manager introspection or macro-text parser. Runtime Lua errors are reported separately from Unknown.

Close/X and Escape are ordinary editor controls; closing does not deactivate applied reminders. Text-box Escape may first clear text focus. Back up your own SavedVariables after a normal logout before upgrades; do not edit live profiles to provoke tests.
