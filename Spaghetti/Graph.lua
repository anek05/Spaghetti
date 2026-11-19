local _, S = ...
local G = {}; S.Graph = G
function G.New(id, name, mode)
    return {schema=2, id=id, name=name, mode=mode, nodes={}, connections={}, serial=0, enabled=false, applied=false, zoom=1, macroName="", macroNameCustom=false, perCharacter=true}
end
function G.ID(g, prefix)
    repeat g.serial = (g.serial or 0) + 1 until not g.nodes[prefix..g.serial] and not g.connections[prefix..g.serial]
    return prefix..g.serial
end
function G.Add(g, kind, x, y)
    local def = S.Registry[kind]
    if not def or def.mode ~= g.mode then return nil, "Node does not belong to this mode." end
    local id = G.ID(g, "n"); local n = {id=id, type=kind, x=x or 40, y=y or 40, settings={}}
    for _, f in ipairs(def.fields) do n.settings[f.key] = f.default end
    g.nodes[id] = n; return n
end
function G.Remove(g, id)
    g.nodes[id] = nil
    for key, c in pairs(g.connections) do if c.from == id or c.to == id then g.connections[key] = nil end end
end
function G.Incoming(g, id, port)
    for _, c in pairs(g.connections) do if c.to == id and c.input == port then return c end end
end
function G.Outgoing(g, id, port)
    for _, c in pairs(g.connections) do if c.from == id and c.output == port then return c end end
end
function G.CanConnect(g, from, output, to, input)
    local a, b = g.nodes[from], g.nodes[to]
    if not a or not b or not S.Registry[a.type] or not S.Registry[b.type] then return false, "Missing node." end
    local at, bt = S.Definition(a).outputs[output], S.Definition(b).inputs[input]
    if not at or not bt or at ~= bt then return false, "Connect ports of the same type: blue Flow or green Condition." end
    if from == to then return false, "A node cannot connect to itself." end
    if G.Incoming(g, to, input) then return false, "That input is connected. Right-click its port to disconnect first." end
    if at == "flow" and G.Outgoing(g, from, output) then return false, "Flow outputs support one connection." end
    local seen = {}
    local function reaches(id)
        if id == from then return true end
        if seen[id] then return false end; seen[id] = true
        for _, c in pairs(g.connections) do if c.from == id and reaches(c.to) then return true end end
        return false
    end
    if reaches(to) then return false, "Cycles are not supported. This would loop back to an earlier node." end
    return true, at
end
function G.Connect(g, from, output, to, input)
    local ok, kind = G.CanConnect(g, from, output, to, input)
    if not ok then return nil, kind end
    local id = G.ID(g, "c")
    g.connections[id] = {id=id, from=from, output=output, to=to, input=input, type=kind}; return g.connections[id]
end
function G.Disconnect(g, id, port, direction)
    for key, c in pairs(g.connections) do
        if (direction == "in" and c.to == id and c.input == port) or (direction == "out" and c.from == id and c.output == port) then g.connections[key] = nil end
    end
end
function G.Validate(g)
    local errors, warnings = {}, {}
    local function err(s) errors[#errors+1] = s end
    if g.schema ~= 1 and g.schema ~= 2 then err("Unsupported graph schema.") end
    local rebuilt = G.New(g.id, g.name, g.mode); rebuilt.nodes = g.nodes
    for _, key in ipairs(S.SortedKeys(g.connections)) do
        local c = g.connections[key]
        local ok, reason = G.CanConnect(rebuilt, c.from, c.output, c.to, c.input)
        if not ok then err("Connection "..key..": "..reason)
        elseif c.type ~= reason then err("Connection "..key..": stored type is incompatible.")
        else rebuilt.connections[key] = c end
    end
    for id, n in pairs(g.nodes) do
        local d = S.Registry[n.type]
        if not d or d.mode ~= g.mode then err(id..": unknown node or wrong mode.")
        else
            for _, f in ipairs(d.fields) do
                local v = n.settings[f.key]
                if S.Spells and (f.kind=="spell" or f.kind=="castspell") and v~="auto" and not (n.type=="show" and f.key=="castSpell" and not n.settings.clickable) then
                    local entry,why=S.Spells.Resolve(v,n.settings[f.key.."Mode"])
                    if why then warnings[#warnings+1]=id..": "..why end
                end
                if f.kind == "number" and (not tonumber(v) or tonumber(v) ~= tonumber(v) or math.abs(tonumber(v)) == math.huge) then err(id..": "..f.label.." must be a finite number.") end
                if f.options then
                    local found = false; for _, choice in ipairs(f.options) do if v == choice then found = true end end
                    if not found then err(id..": unsupported "..f.label..".") end
                end
            end
            if n.type == "buff" then
                if n.settings.spell=="" then err(id..": select a spell to check.") end
                local spell = tonumber(n.settings.spell)
                if spell and (spell < 1 or spell % 1 ~= 0) then err(id..": choose a valid spell.") end
                warnings[#warnings+1] = id..": secret/contextual buff checks are unsupported in combat; UNKNOWN never means Missing. Only client-declared NeverSecret auras can be evaluated."
            end
            if n.type == "show" then
                local icon=n.settings.spell
                if S.Spells then icon=S.Spells.ReminderSettings(g,n).spell end
                if not (n.settings.text or ""):find("%S") and not (tonumber(icon) and tonumber(icon)>0) then err(id..": enter reminder text or select an icon. Text-only reminders need no cast spell.") end
                if n.settings.clickable then
                    warnings[#warnings+1]=id..": click-to-cast is outside combat only. Secure controls hide during combat."
                    if S.Spells and not S.Spells.ReminderSettings(g,n).castEntry then warnings[#warnings+1]=id..": choose a learned spell to cast; automatic selection needs one upstream Buff." end
                end
                for key, bounds in pairs({duration={1,120}}) do
                    local v = tonumber(n.settings[key]); if v and (v < bounds[1] or v > bounds[2]) then err(id..": "..key.." is outside "..bounds[1].."–"..bounds[2]..".") end
                end
            end
            if n.type=="combat_state" and n.settings.state=="In Combat" then
                local gate=G.Incoming(g,id,"gate"); local invert=gate and g.nodes[gate.from]
                local input=invert and invert.type=="not" and G.Incoming(g,invert.id,"a")
                if input and g.nodes[input.from] and g.nodes[input.from].type=="player" then
                    warnings[#warnings+1]=id..": NOT(Player) is always false, so this gate prevents every reminder. For outside combat connect Combat State -> NOT -> Show instead."
                end
            end
            if g.mode == "reminder" then
                if n.type == "and" or n.type == "not" then
                    if not G.Incoming(g,id,"a") then err(id..": connect input A.") end
                    if n.type == "and" and not G.Incoming(g,id,"b") then err(id..": connect input B.") end
                end
                if n.type == "show" or n.type == "hide" then
                    if not G.Incoming(g,id,"when") and not G.Incoming(g,id,"run") then err(id..": connect Condition or Run.") end
                    if n.type == "hide" and n.settings.target ~= "" and (not g.nodes[n.settings.target] or g.nodes[n.settings.target].type ~= "show") then err(id..": target must be a Show Reminder node ID in this graph.") end
                end
            end
        end
    end
    if next(g.nodes) == nil then err("Add nodes from the library to begin.") end
    -- Every reminder node must contribute to an output.
    if g.mode == "reminder" then
        local used = {}
        local function upstream(id)
            if used[id] then return end; used[id] = true
            for _, c in pairs(g.connections) do if c.to == id then upstream(c.from) end end
        end
        for id,n in pairs(g.nodes) do if n.type == "show" or n.type == "hide" then upstream(id) end end
        for id in pairs(g.nodes) do if not used[id] then err(id..": disconnected from any reminder output.") end end
    end
    return errors, warnings
end
function G.ChangeCombatState(g,n,state)
    if state~="In Combat" and state~="Enter Combat" and state~="Leave Combat" then return nil,"Choose In Combat, Enter Combat or Leave Combat." end
    local previous=n.settings.state; n.settings.state=state
    local affected={node=n.id,edges={},ports={}}
    for cid,c in pairs(g.connections) do
        if c.from==n.id or c.to==n.id then
            local a,b=g.nodes[c.from],g.nodes[c.to]
            local ad,bd=a and S.Definition(a),b and S.Definition(b)
            if not ad or not bd or not ad.outputs[c.output] or ad.outputs[c.output]~=bd.inputs[c.input] then
                affected.edges[cid]=true; affected.ports[c.from..":out:"..c.output]=true; affected.ports[c.to..":in:"..c.input]=true
            end
        end
    end
    if next(affected.edges) then
        n.settings.state=previous
        local message="Cannot switch to "..state..": "..(state=="In Combat" and "this mode uses a condition, but the existing connection uses an event." or "this mode emits an event, but an existing connection uses a condition.").." Disconnect the highlighted ports first. Existing connections were retained."
        affected.message=message; return nil,message,affected
    end
    return true
end
