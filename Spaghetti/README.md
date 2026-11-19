# Spaghetti 0.3.1

Visual reminders and native macro graphs for World of Warcraft: Forever, interface 16001. This is a development version; the source folder may contain Unreleased fixes beyond the originally tested 0.3.1 build.

## Install and open

Copy this folder to your Forever client's `Interface/AddOns/Spaghetti/`, with `Spaghetti.toc` directly inside it. Fully restart WoW after upgrading, enable Spaghetti and enter `/spaghetti`.

**Reminder / CD** builds condition/event reminders; it has no general cooldown engine. **Macro** generates native macro text: create/update a macro, then drag its Macro Action icon to an action bar outside combat. A graph save or text preview does not update the native macro.

Clickable reminders support outside-combat use only. Post-combat recovery and library hover colors have local fixes awaiting in-game retesting. Secret/unavailable aura data remains Unknown, never Missing. Macros obey native game restrictions.

Read the bundled [user guide](docs/USER_GUIDE.md) for first flows, storage and limitations. Development/test history is maintained in the source project's root documentation, not duplicated in this addon package. No private test profiles are included here.

[MIT License](LICENSE).
