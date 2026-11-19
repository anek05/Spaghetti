local _, S = ...
local G, E=S.Graph,{graphs={},status={},states={},errors={}}; S.Engine=E
function E.Reload()
    S.Display.HideAll(); E.graphs={}; E.status={}; E.states={}; E.errors={}
    for id,g in pairs(S.db.graphs) do
        if g.mode=="reminder" and g.enabled and #G.Validate(g)==0 then E.graphs[id]=S.Copy(g) end
    end
    E.Evaluate("REFRESH")
end
function E.EvaluateGraph(gid,g,event)
    local cache,unknown={},{}
    local eval
    local function input(n,port,default)
        local c=G.Incoming(g,n.id,port)
        if not c then return default end
        return eval(g.nodes[c.from])
    end
    eval=function(n)
        if cache[n.id]~=nil then return cache[n.id] end
        if unknown[n.id] then return nil end
        local v
        if n.type=="player" then v=true
        elseif n.type=="combat" or n.type=="combat_state" and n.settings.state=="In Combat" then v=S.inCombat and true or false
        elseif n.type=="buff" then
            local active,reason
            if S.Spells then active,reason=S.Spells.ReadBuff(n.settings.spell,n.settings.spellMode) else active,reason=S.ReadBuff(tonumber(n.settings.spell)) end
            if active==nil then
                local label=S.Spells and S.Spells.Label(n.settings.spell,n.settings.spellMode) or "selected spell"
                unknown[n.id]="Buff "..label.." cannot be evaluated: "..(reason or "API state is Unknown")
            elseif n.settings.state=="Missing" then v=not active else v=active end
        elseif n.type=="not" then local a=input(n,"a"); if a~=nil then v=not a end
        elseif n.type=="and" then
            local a,b=input(n,"a"),input(n,"b")
            if a~=nil and b~=nil then v=a and b end
        end
        if n.type=="combat" or n.type=="combat_state" or n.type=="buff" then
            if G.Incoming(g,n.id,"gate") then
                local a=input(n,"gate"); if a==nil or v==nil then v=nil else v=a and v end
            end
        end
        if v==nil then unknown[n.id]=unknown[n.id] or "Upstream condition is unsupported." else cache[n.id]=v end
        return v
    end
    local function output(n)
        local run=G.Incoming(g,n.id,"run"); local condition=G.Incoming(g,n.id,"when")
        local value=true
        if condition then value=eval(g.nodes[condition.from]) end
        local fired=false
        if run then
            local src=g.nodes[run.from]
            fired=((src.type=="enter" or src.type=="combat_state" and src.settings.state=="Enter Combat") and event=="PLAYER_REGEN_DISABLED") or ((src.type=="leave" or src.type=="combat_state" and src.settings.state=="Leave Combat") and event=="PLAYER_REGEN_ENABLED")
        end
        if value==nil then return nil,run~=nil end
        return value and (not run or fired),run~=nil,value
    end
    local hidden={}
    for id,n in pairs(g.nodes) do
        if n.type=="hide" then
            local yes=output(n)
            if yes then
                if n.settings.target=="" then for sid,sn in pairs(g.nodes) do if sn.type=="show" then hidden[sid]=true end end
                else hidden[n.settings.target]=true end
            end
        end
    end
    for id,n in pairs(g.nodes) do
        if n.type=="show" then
            local yes,pulse,value=output(n); local key=gid..":"..id
            E.states[key]=yes==nil and "Unsupported / unknown" or (yes==false and not pulse and "Condition false" or "Waiting for condition")
            if hidden[id] or not n.settings.enabled or yes==nil or (pulse and value==false) then S.Display.Hide(key)
            elseif yes then
                local settings=S.Spells and S.Spells.ReminderSettings(g,n) or n.settings
                S.Display.Show(key,settings,pulse and tonumber(n.settings.duration) or nil)
            elseif not pulse then S.Display.Hide(key)
            elseif (event=="COMBAT_RECOVERY" or event=="PLAYER_REGEN_ENABLED") and S.Display.RefreshClick then
                -- A still-visible event pulse keeps its original expiry. Do not
                -- replay its event or resurrect an expired/hidden visual.
                local settings=S.Spells and S.Spells.ReminderSettings(g,n) or n.settings
                S.Display.RefreshClick(key,settings)
            end
        end
    end
    local status={}
    for id,reason in pairs(unknown) do status[#status+1]=id..": UNKNOWN — "..reason end
    for id,v in pairs(cache) do status[#status+1]=id..": "..(v and "TRUE" or "FALSE") end
    table.sort(status); E.status[gid]=table.concat(status,"\n")
end
function E.Evaluate(event)
    for gid,g in pairs(E.graphs) do
        local ok,problem=pcall(E.EvaluateGraph,gid,g,event)
        if not ok then
            local detail=(not S.Secret or not S.Secret(problem)) and tostring(problem) or "Restricted runtime error"
            E.errors[gid]=detail; E.status[gid]="Runtime Lua error: "..detail
            for id,n in pairs(g.nodes) do if n.type=="show" then
                E.states[gid..":"..id]="Runtime error"; pcall(S.Display.Hide,gid..":"..id)
            end end
        else E.errors[gid]=nil end
    end
    if S.Editor and S.Editor.window and S.Editor.window:IsShown() then S.Editor.UpdateStatus() end
end
function E.Overview()
    local rows={}
    for _,gid in ipairs(S.SortedKeys(S.db.graphs)) do
        local g=S.db.graphs[gid]
        if g.mode=="reminder" then
            local errors=G.Validate(g)
            for _,id in ipairs(S.SortedKeys(g.nodes)) do
                local n=g.nodes[id]
                if n.type=="show" then
                    local key=gid..":"..id; local state
                    if #errors>0 then state="Error: "..errors[1]
                    elseif not g.applied and not g.enabled then state="Saved • not applied"
                    elseif not g.enabled or not n.settings.enabled then state="Disabled"
                    elseif E.errors[gid] then state="Runtime error: "..E.errors[gid]
                    elseif S.Display.IsVisible and S.Display.IsVisible(key) then state="Visible"
                    else state=E.states[key] or "Waiting for condition" end
                    rows[#rows+1]={key=key,gid=gid,id=id,name=n.settings.text,graph=g.name,enabled=g.enabled and n.settings.enabled,state=state}
                end
            end
        end
    end
    return rows
end
function E.ToggleReminder(gid,id,enabled)
    local g=S.db.graphs[gid]; local n=g and g.nodes[id]
    if not n or n.type~="show" then return nil,"Reminder no longer exists." end
    if enabled and #G.Validate(g)>0 then return nil,"Fix this graph's validation errors before enabling it." end
    if enabled and not g.enabled then
        -- A per-reminder toggle must not implicitly activate all other outputs
        -- in a previously unapplied/disabled graph.
        for _,other in pairs(g.nodes) do if other.type=="show" then other.settings.enabled=false end end
    end
    n.settings.enabled=enabled
    if enabled then g.enabled=true; g.applied=true end
    local draft=S.Editor and S.Editor.drafts[gid]
    if draft then
        draft.enabled=g.enabled; draft.applied=g.applied
        for sid,sn in pairs(g.nodes) do if sn.type=="show" and draft.nodes[sid] then draft.nodes[sid].settings.enabled=sn.settings.enabled end end
    end
    if S.Canvas then S.Canvas.RefreshSpells() end
    E.Reload(); return true
end
