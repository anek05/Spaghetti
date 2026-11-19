# Known limitations and planned work

Spaghetti 0.3.1 is a development version, not an approved MVP. The UI name Reminder / CD does not imply a general cooldown engine. Code and mock coverage do not replace native game acceptance.

## Stabilization requiring game checks

| Area | Current behavior / remaining check |
| --- | --- |
| Macro status after combat (SP-01) | Bounded recovery and clearing of marked combat notices are implemented. Verify current status and actual dragging with the editor continuously open. |
| Clickable reminder recovery (SP-02) | Recovery reevaluates current saved rules after native lockdown. Verify a real selfcast before and after combat without Apply/reload. Combat clicks remain unsupported. |
| Library hover text (SP-03) | Normal/highlight/disabled fonts are configured locally. Verify white normally, yellow during hover, white after leave, including reused rows. |
| Macro update instructions | Confirm cancel/update and custom-name behavior with a small native test. Earlier difficulty understanding Out of sync is not evidence of a broken update function. |
| Legacy import | Requires suitable older data. Lack of test data is not acceptance; never delete profiles to create a fixture. |

Use the [focused manual checks](../tests/manual/RETEST.md) and [testing guide](TESTING.md). The [manual MVP template](../tests/manual/MVP_TEST_PLAN.md) provides repeatable steps with blank result fields. Existing private owner records are preserved separately and are not part of the upload.

## Planned usability improvements

- **SP-04: saved and active state.** Make unsaved changes and activation of the saved rule easier to distinguish from runtime conditions and native macro status. Preview must remain distinct from Apply.
- **SP-05: editor and inventory windows.** Improve access to Character Info/Bags without breaking picker/dialog or secure-reminder hit ordering.
- **SP-06: incompatible state changes.** A proposal to change state and remove only incompatible edges needs a new behavior contract and tests. Current behavior rejects the change and preserves all edges.
- **SP-07: readable combat diagnostics.** Allow permitted status/reason to be reviewed after combat, without storing secret payloads or changing aura truth.

These SP identifiers are local references, not published GitHub issue numbers.

## Macro Text to Graph

Parse only a documented supported subset and generate an equivalent graph using existing node types. Preserve command order, targeting and every condition. Retain original input, report unsupported syntax and never claim equivalence after incomplete parsing. No parser is implemented.

## Separate estimated buff state

Investigate observed player casts, known durations and previous readable aura state as explicitly uncertain estimates. Define provenance and invalidation rules. Never replace Buff Active/Missing or turn secret/Unknown into Missing. No estimator is implemented.

## Other deferred systems

General cooldown tracking, complex/nested macro branches, combat click-to-cast, a larger canvas, broad item catalogs and Blizzard Edit Mode integration are outside the current stabilization scope.
