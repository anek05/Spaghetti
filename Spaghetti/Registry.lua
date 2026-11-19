local _, S = ...
S.Registry = {}
local R = S.Registry
local function field(key, label, default, options, kind)
    return { key = key, label = label, default = default, options = options, kind = kind }
end
local function node(id, title, mode, inputs, outputs, fields, help)
    R[id] = { id=id, title=title, mode=mode, inputs=inputs or {}, outputs=outputs or {}, fields=fields or {}, help=help }
end
local bool = { value="bool" }
local gate = { gate="bool" }
local flow = { next="flow" }
node("player", "Player", "reminder", {}, bool, {}, "Always true. Connect to a condition's Gate input.")
node("enter", "Enter Combat", "reminder", {}, flow, {}, "Fires once on entering combat. Reminder stays for its Duration.")
node("leave", "Leave Combat", "reminder", {}, flow, {}, "Fires once on leaving combat.")
node("combat", "Is In Combat", "reminder", gate, bool, {}, "True while in combat. Optional Gate is combined with this condition.")
R.enter.hidden=true; R.leave.hidden=true; R.combat.hidden=true
node("combat_state", "Combat State", "reminder", gate, bool, {
    field("state", "State", "In Combat", {"In Combat", "Enter Combat", "Leave Combat"})
}, "In Combat is a persistent condition; Enter/Leave Combat emit one flow event. Disconnect incompatible ports before changing mode.")
node("buff", "Buff Active / Missing", "reminder", gate, bool, {
    field("spell", "Spell", "", nil, "spell"), field("state", "State", "Missing", {"Missing", "Active"})
}, "Reads player auras outside combat only. Combat is UNSUPPORTED: no missing-buff inference is made.")
node("and", "AND", "reminder", {a="bool", b="bool"}, bool, {}, "Both inputs must be true; unsupported input remains unsupported.")
node("not", "NOT", "reminder", {a="bool"}, bool, {}, "Inverts a supported condition. Unsupported remains unsupported.")
node("show", "Show Reminder", "reminder", {when="bool", run="flow"}, {}, {
    field("text", "Reminder text", ""), field("spell", "Icon", "0", nil, "icon"),
    field("clickable", "Clickable (outside combat)", false, nil, "check"), field("castSpell", "Spell to cast", "auto", nil, "castspell"),
    field("duration", "Event duration (seconds)", "5", nil, "number"),
    field("enabled", "Enabled", true, nil, "check")
}, "Condition input shows while true. Run input shows on the event for Duration. Both inputs combine as a gate.")
node("hide", "Hide Reminder", "reminder", {when="bool", run="flow"}, {}, {
    field("target", "Show node ID (blank = all)", "")
}, "Hides reminders in this graph. Hide wins when Show and Hide are both active.")
node("start", "Macro Start", "macro", {}, flow, {}, "One entry per macro. Connect Next to an action or Branch.")
node("modifier", "Modifier Key", "macro", {}, bool, {field("key", "Key", "shift", {"shift", "ctrl", "alt"})})
node("exists", "Target Exists", "macro", {}, bool)
node("friendly", "Target Friendly", "macro", {}, bool)
node("hostile", "Target Hostile", "macro", {}, bool)
node("mcombat", "Combat Condition", "macro", {}, bool, {field("state", "State", "combat", {"combat", "nocombat"})})
node("branch", "Conditional Branch", "macro", {run="flow", condition="bool"}, {yes="flow", no="flow"}, {},
    "MVP: one condition and two terminal actions of the same command and target. No nested branches.")
local units = {"auto", "target", "player", "focus", "mouseover", "pet"}
node("cast", "Cast Spell", "macro", {run="flow"}, flow, {field("value", "Spell", "", nil, "castspell"), field("unit", "Cast on", "auto", units),
    field("relation", "Target must be", "Any", {"Any","Friendly","Hostile"}), field("alive", "Target must be alive", false,nil,"check"), field("exists", "Target must exist", false,nil,"check")
}, "Cast directly on Focus with [@focus], without changing your current target. Focus must already be set; range and normal spell rules still apply.")
node("use", "Use Item", "macro", {run="flow"}, flow, {field("value", "Item", "", nil, "item"), field("unit", "Target", "auto", units)})
node("target", "Target Unit", "macro", {run="flow"}, flow, {field("value", "Change current target to", "target", {"target", "player", "focus", "mouseover", "pet"})}, "Changes your current target to the selected unit. Focus means /target focus; it does not SET a focus. A separate Cast target selector can avoid changing target.")
node("focus", "Set Focus", "macro", {run="flow"}, flow, {field("value", "Use as focus", "target", {"target","mouseover","player","pet"})}, "Generates /focus for a hardware-pressed native macro. This sets your focus; it is different from targeting or casting on an existing focus.")
node("equip", "Equip Item", "macro", {run="flow"}, flow, {field("value","Item to equip","",nil,"equipment")}, "Generates /equip. Native inventory, class and combat restrictions still apply; the addon does not equip anything itself.")
node("equipslot", "Equip Slot", "macro", {run="flow"}, flow, {field("value","Item to equip","",nil,"equipment"),field("slot","Equipment slot","Main Hand",{"Main Hand","Off Hand","Head","Neck","Shoulder","Shirt","Chest","Waist","Legs","Feet","Wrist","Hands","Finger 1","Finger 2","Trinket 1","Trinket 2","Back","Ranged","Tabard"})}, "Generates /equipslot using the client's slot ID. Not every equippable item fits every slot; normal game rules apply.")
node("equipset", "Equip Set", "macro", {run="flow"}, flow, {field("value","Saved equipment set","",nil,"equipset")}, "Available only when the client reports that native equipment sets can be used. Generates /equipset; never equips through addon Lua.")
R.equipset.available=function() return S.Items and S.Items.SetsAvailable() end
S.PortNames = { value="Value", gate="Gate", a="A", b="B", when="Condition", run="Run", next="Next", yes="True", no="False", condition="Condition" }
function S.SortedKeys(t)
    local keys = {}; for k in pairs(t or {}) do keys[#keys+1] = k end
    table.sort(keys); return keys
end
function S.Copy(v)
    if type(v) ~= "table" then return v end
    local t = {}; for k, x in pairs(v) do t[k] = S.Copy(x) end; return t
end
function S.Definition(n)
    local d=S.Registry[n.type]
    if n.type=="combat_state" and n.settings.state~="In Combat" then
        local copy=S.Copy(d); copy.inputs={}; copy.outputs={next="flow"}; return copy
    end
    if n.type=="show" and not n.settings.clickable then
        local copy=S.Copy(d); copy.fields={}
        for _,f in ipairs(d.fields) do if f.key~="castSpell" then copy.fields[#copy.fields+1]=f end end
        return copy
    end
    return d
end
function S.PortLabel(n,key,direction)
    if n.type=="combat_state" and direction=="out" then return n.settings.state=="In Combat" and "Is in combat" or n.settings.state.." event" end
    if n.type=="not" then return direction=="in" and "Condition" or "Inverted result" end
    return S.PortNames[key] or key
end
S.UnitLabels={auto="Current Target",target="Current Target (explicit)",focus="Focus",mouseover="Mouseover",player="Self",pet="Pet"}
