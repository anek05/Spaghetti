# Spaghetti

Spaghetti is a visual node editor for **World of Warcraft: Forever**. Connect conditions and actions to build reminders or generate native WoW macros, without writing Lua.

The editor has two modes:

- **Reminder / CD** evaluates supported conditions and combat events, then displays text, icons or both. The label is the existing UI name; there is no general cooldown engine.
- **Macro** compiles supported graphs to native macro text. Create or update the macro, then drag its **Macro Action** icon directly onto an action bar outside combat. The game executes it on a normal button press.

## Development status

**0.3.1 is a development version, not an approved MVP.** Owner-reported tests on Forever **1.60.1.70938**, interface **16001**, cover editor basics, reminders, the equipment-macro/action-bar flow, reload/full restart and character isolation in the tested cases. T01–T18 contain 13 OK, 3 partial and 2 not testable results; T19–T21 are untested.

Local changes under **Unreleased** address post-combat recovery and node-library font states. These changes have automated regression coverage but still need in-game retesting. They do not change the historical results or constitute a 0.3.2 release.

Known limits:

- Clickable reminders are supported **outside combat only**. Post-combat recovery needs confirmation in T16; macro status needs confirmation in T08.
- Secret or unavailable aura data remains **Unknown**, never assumed Missing. Battle Shout rank 2 Missing was reported working outside combat; combat behavior is not approved by T11.
- Macro graphs support linear actions or one restricted branch, subject to native targeting, GCD and equipment rules. There is no macro-text parser or estimated buff tracker.

See [known limitations and planned work](docs/BACKLOG.md) and the [manual test template](tests/manual/MVP_TEST_PLAN.md) for current scope and remaining checks.

## Install

The **project root** contains development files. The inner **`Spaghetti/` folder** is the addon.

1. Copy that inner folder to `<WoW Forever>/_forever_/Interface/AddOns/Spaghetti/`. `Spaghetti.toc` must be directly inside the installed folder, without another nested `Spaghetti` directory.
2. Fully restart WoW after upgrading, enable the addon and enter `/spaghetti`.
3. A new character starts with an empty profile. Use **New**, or explicitly add an example through **Examples**.

Graphs, drafts and placement are character-specific. Existing account data is available only through explicit copy import; it is not automatically activated. Back up your own SavedVariables after normal logout before upgrading.

## First flows

For a text reminder outside combat, choose Reminder / CD and connect **Combat State (In Combat) → NOT → Show Reminder** using the green condition ports. Set reminder text, leave No icon and Clickable off, then **Apply reminder**. Preview is temporary; Save alone does not activate a new rule.

For a macro, choose Macro, name the graph, then connect **Macro Start → Equip Slot** using the blue flow ports. Select an owned item and matching slot. Check the generated text, click **Create macro**, and drag the Macro Action icon when its status is **Created**. A custom Macro name overrides the graph-name default. Saving a graph does not create or update its native macro.

## Continue

- [User guide](Spaghetti/docs/USER_GUIDE.md): editing, pickers, naming, import and placement.
- [Contributing and tests](CONTRIBUTING.md), [architecture](docs/ARCHITECTURE.md), [client API boundaries](docs/API_REFERENCE.md).
- [GitHub first-time setup](GITHUB_START.md), [changelog](CHANGELOG.md), [future scope](docs/BACKLOG.md).
- [MIT License](LICENSE). The addon folder contains the same license; linked external sources retain their own terms.
