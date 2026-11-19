# Testing Spaghetti

## Automated tests

Follow [CONTRIBUTING](../CONTRIBUTING.md) to install the pinned dependency, then run from the project root:

```sh
python -B tests/run.py
```

The runner loads all addon Lua source into Lua 5.1 and LuaJIT 2.1 through Lupa. Model suites cover graph rules, migrations, profiles/import, reminder logic, macro compilation and native identity. UI doubles cover callback wiring, toolbar routing, draft behavior and protected-operation guards.

Combat lifecycle tests include an exit event while native lockdown remains active, later release with the editor open, bounded retries, new combat/logout cancellation and current saved rules rather than captured drafts. They also cover disabled/deleted/no-icon outputs, previews, placement and pulse expiry. Font tests check native state configuration on reused library rows; they do not simulate the client's font renderer.

Mock coverage cannot establish real mouse routing, native action execution, secure timing, taint freedom, client persistence or readable combat aura data. A configured GitHub workflow is not evidence of a successful Actions run.

## Manual tests

- [Manual MVP test template](../tests/manual/MVP_TEST_PLAN.md).
- [Three focused checks](../tests/manual/RETEST.md): macro status after combat, clickable reminder recovery and library hover/leave.
- [Known limitations and planned work](BACKLOG.md).

Use short passes of 3–5 checks or fewer. Record loaded addon version/build, language, UI scale, other addons, relevant graph settings and exact Lua/protected-action errors. Fully restart after changing TOC/modules. Test the intended live action rather than treating preview as acceptance.

Existing filled outcomes are historical evidence: never change them to OK because code or mocks pass. Record new game outcomes separately. Keep agent run summaries and execution logs outside the repository; they are not project documentation.

## Regression areas

| Area | What to check |
| --- | --- |
| Editor | Toolbar clicks, close/Escape during combat, dropdown/picker dismissal, node drag/wiring, scale/zoom and reused library rows. Closing must not deactivate reminders. |
| Profiles | Independent characters, drafts versus saved runtime, reload/full restart, explicit non-destructive import and inactive imported outputs. Use test copies; never corrupt live SavedVariables. |
| Reminders | In Combat versus Enter/Leave events, NOT/AND, Hide precedence, text/icon combinations, per-output toggles and preview/placement isolation. |
| Aura truth | Readable active/missing transitions outside combat; secret/unavailable state remains Unknown, including through NOT/AND. Record exact spell/rank and permitted diagnostic text. |
| Macros | Generated text, graph/custom names, explicit native creation/update/cancel, verified drag, external edits/deletion/reordering, collisions, scope and native limits. |
| Secure clicks | Real selfcast outside combat, blocked combat clicks, recovery after native lockdown, no invisible no-icon/disabled targets and no casts from preview/placement. |
| Timing | Visible event pulses keep their original expiry during recovery; expired/hidden outputs must not reappear. New combat cancels older recovery callbacks. |

For an equipment case, the reported Main Hand example generates `#showtooltip` followed by `/equipslot 16 item:15424`. Other items, slots, classes and equipment sets require appropriate test conditions. Focus casts and modifier branches remain subject to normal targeting, range, resource and GCD rules.

Repeat relevant checks with other addons disabled and with the normal addon set when investigating a conflict. An untestable case remains open rather than becoming a pass.
