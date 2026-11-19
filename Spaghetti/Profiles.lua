local _, S = ...
local P={}; S.Profiles=P
function P.Normalize(db)
    if db.drafts~=nil and type(db.drafts)~="table" then return nil,"Invalid saved drafts; original profile retained." end
    local copy=S.Copy(db)
    copy.schema=3; copy.layouts=copy.layouts or {}; copy.drafts=copy.drafts or {}
    local function graph(g)
        if S.MacroIntegration then S.MacroIntegration.NormalizeName(g) end
        for _,n in pairs(g.nodes) do
            local d=S.Registry[n.type]
            if d then for _,f in ipairs(d.fields) do if n.settings[f.key]==nil then n.settings[f.key]=f.default end end end
        end
    end
    for _,g in pairs(copy.graphs) do graph(g) end
    for id,g in pairs(copy.drafts) do
        local ok=S.CheckStorage({schema=2,graphs={[id]=g}})
        if not ok then return nil,"Invalid saved draft; original profile retained." end
        graph(g)
    end
    return copy
end
function P.Open(current,legacy)
    if current~=nil then
        if type(current)~="table" or current.schema~=3 then return nil,"Unknown character profile format; its data was not changed." end
        local ok,why=S.CheckStorage(current); if not ok then return nil,why end
        return P.Normalize(current)
    end
    return {schema=3,graphs={},drafts={},layouts={},serial=0,importStatus=type(legacy)=="table" and type(legacy.graphs)=="table" and next(legacy.graphs) and "pending" or "none"}
end
function P.Import(profile,legacy,confirmed)
    if confirmed~=true then return nil,"Explicit import confirmation is required." end
    if profile.importStatus=="imported" then return nil,"Legacy data was already imported for this character." end
    local ok,why=S.CheckStorage(legacy); if not ok then return nil,"Legacy data was preserved: "..why end
    if legacy.schema~=1 and legacy.schema~=2 then return nil,"Unknown legacy format; original account data was preserved." end
    local converted,reason=S.Migrate(legacy); if not converted then return nil,reason end
    local normalized,problem=P.Normalize(converted); if not normalized then return nil,problem end
    local result=S.Copy(profile); local mapping={}
    for _,oldID in ipairs(S.SortedKeys(normalized.graphs)) do
        local id=oldID
        while result.graphs[id] do result.serial=(result.serial or 0)+1; id="g"..result.serial end
        mapping[oldID]=id
        local g=S.Copy(normalized.graphs[oldID]); g.id=id; g.enabled=false; g.applied=false; g.perCharacter=true
        for _,n in pairs(g.nodes) do if n.type=="show" then n.settings.enabled=false end end
        result.graphs[id]=g
        if normalized.drafts[oldID] then
            local draft=S.Copy(normalized.drafts[oldID]); draft.id=id; draft.enabled=false; draft.applied=false; draft.perCharacter=true
            for _,n in pairs(draft.nodes) do if n.type=="show" then n.settings.enabled=false end end
            result.drafts[id]=draft
        end
    end
    for key,value in pairs(normalized.layouts) do
        local gid,nid=key:match("^([^:]+):(.+)$")
        if mapping[gid] then result.layouts[mapping[gid]..":"..nid]=S.Copy(value) end
    end
    if normalized.selected and mapping[normalized.selected] then result.selected=mapping[normalized.selected] end
    result.importStatus="imported"
    local valid,errorMessage=S.CheckStorage(result); if not valid then return nil,"Import cancelled without changing data: "..errorMessage end
    return result
end
function P.Decline(profile) if profile.importStatus=="pending" then profile.importStatus="declined" end end
