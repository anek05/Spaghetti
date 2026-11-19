# Forever API boundaries

This reference explains the client contracts Spaghetti relies on. Source mirrors and generated documentation establish API shapes, not successful execution on every client build. Keep native game tests separate from model/mock coverage. Do not substitute Retail or Classic behavior for Forever without identifying the difference.

## Spell identity and ranks

Spells.lua builds a learned-player catalog using C_SpellBook skill lines, item information, spell names and the client's enum values. Passive spells may supply icons/buff selections but are excluded from cast choices. Spellbook cursor drops must resolve to a learned catalog entry.

Auto rank requires unambiguous skill-line, localized name, rank subtext and highest-rank evidence. IsSpellBookItemLowRank alone is not a complete ancestry table. GetBaseSpell handles overrides rather than proving a general rank family. Ambiguous or unavailable selections remain saved with a warning instead of being silently replaced.

Sources: [Forever C_SpellBook documentation](https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/Spells-Auras-Talents/C_SpellBook.md), [C_Spell documentation](https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/Spells-Auras-Talents/C_Spell.md). These generated references may describe an older build than the installed client.

## Aura truth and secret values

Outside combat, guarded exact-ID lookups use the verified learned spell family. In combat, Spaghetti requires both static NeverSecret classification and explicit current permission before attempting an aura read. Failed calls, secret/inaccessible values, unavailable selections and missing secrecy classification produce Unknown. Unknown never becomes Missing through Buff, NOT or AND.

C_Secrets.GetSpellAuraSecrecy describes base classification; ShouldSpellAuraBeSecret describes current context. A spell name or another addon's reminder is not evidence that arbitrary combat aura absence is readable. C_CooldownViewer configuration and native widget rendering do not supply a general Missing boolean. Spaghetti does not inspect hidden manager state or replace aura truth with cast/expiry estimates.

Sources: [Forever C_Secrets documentation](https://github.com/Atraeau/WoW-Addons/blob/d4f674ba9991ac5115c6bbbdfe03e5547294406a/docs/api/System-Config/C_Secrets.md), [C_UnitAuras](https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/Spells-Auras-Talents/C_UnitAuras.md), [C_CooldownViewer](https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/Spells-Auras-Talents/C_CooldownViewer.md).

## Secure clicks and combat lifecycle

SecureClicks uses separate UIParent children with SecureActionButtonTemplate and SecureHandlerStateTemplate, configured outside lockdown. RegisterStateDriver hides them on combat entry. Addon-originated creation, attributes, geometry and visibility changes remain guarded by InCombatLockdown. Only subsequent permitted evaluation may show a click target again. Preview, placement, disabled outputs and no-icon reminders must never provide cast targets.

Combat recovery rechecks native lockdown rather than assuming the exit event has already cleared it. C_Timer.After checks are bounded and invalidated by new combat or logout. They carry no captured graph/settings. Visible event pulses may refresh their click layer without restarting their expiry. See [architecture](ARCHITECTURE.md) for the lifecycle and [testing](TESTING.md) for required game checks.

Sources: [Forever secure templates](https://github.com/Ketho/wow-ui-source-forever/blob/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua), [Forever UITimer API](https://github.com/Ketho/wow-ui-source-forever/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_APIDocumentationGenerated/UITimerDocumentation.lua).

## Native macros

The compiler emits the supported command subset; native execution still depends on a real player action and the game's targeting, equipment and GCD rules. Native create/edit/pickup are blocked during combat. CreateMacro/EditMacro return an index that may change as macros are sorted. GetMacroIndexByName alone is insufficient when names collide.

MacroIntegration scans the current slot range and requires a unique name/body/scope match before pickup. A cached index is only a hint. Replacement requires confirmation, followed by name/body/scope readback. External edits, duplicate identities or missing/renamed macros disable dragging rather than guessing a different macro. The implementation validates names up to 16 characters and bodies up to 255 bytes without truncation.

Sources: [Forever MacroUI](https://github.com/Ketho/wow-ui-source-forever/blob/forever/Interface/AddOns/Blizzard_MacroUI/Blizzard_MacroUI.lua), [macro constants](https://github.com/Ketho/wow-ui-source-forever/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MacroConstantsDocumentation.lua). MacroUI's drag path registers LeftButton and calls PickupMacro from OnDragStart.

## Inventory and UI

Item selection is limited to readable equipped items and equipped bags/backpack. Stable item:ID values survive moves; uncached/unavailable selections remain explicit. Equip slots use GetInventorySlotInfo. Equipment-set nodes require positive native capability and the required enumeration APIs.

Sources: [Forever C_Item](https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/Items-Inventory/C_Item.md), [C_Container](https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/Items-Inventory/C_Container.md), [C_EquipmentSet](https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/Items-Inventory/C_EquipmentSet.md).

Toolbar mouse targets use explicit frame ordering and bounded hit rectangles. Decorative panels are mouse-transparent. Library rows configure normal, highlight and disabled font states independently; a one-time FontString override does not define all button states.

Sources: [Forever SimpleButton API](https://github.com/Ketho/wow-ui-source-forever/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleButtonAPIDocumentation.lua), [shared UI templates](https://github.com/Ketho/wow-ui-source-forever/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml). Mainline here is a path inside the Forever mirror.
