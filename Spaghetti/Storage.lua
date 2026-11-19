local _, S = ...
-- Check the SavedVariables boundary before any graph code accesses nested tables.
-- Unknown formats are retained untouched, rather than reset to defaults.
function S.CheckStorage(db)
    if type(db)~="table" or (db.schema~=1 and db.schema~=2 and db.schema~=3) or type(db.graphs)~="table" then return nil,"Unsupported database schema." end
    local function serial(v) return v==nil or (type(v)=="number" and v>=0 and v<1000000000 and v%1==0) end
    if not serial(db.serial) then return nil,"Invalid database ID counter." end
    if db.drafts~=nil and type(db.drafts)~="table" then return nil,"Invalid draft storage." end
    if db.editorWindow~=nil then
        if type(db.editorWindow)~="table" then return nil,"Invalid editor layout." end
        for key,bounds in pairs({x={-10000,10000},y={-10000,10000},width={1160,1900},height={740,1300}}) do
            local value=db.editorWindow[key]
            if type(value)~="number" or value~=value or value<bounds[1] or value>bounds[2] then return nil,"Invalid editor layout bounds." end
        end
    end
    if db.layouts~=nil then
        if type(db.layouts)~="table" then return nil,"Invalid placement store." end
        for key,v in pairs(db.layouts) do
            if type(key)~="string" or type(v)~="table" then return nil,"Invalid placement record." end
            for field,bounds in pairs({x={-3000,3000},y={-2000,2000},size={16,128}}) do
                local n=v[field]; if type(n)~="number" or n~=n or n<bounds[1] or n>bounds[2] then return nil,"Invalid placement bounds." end
            end
        end
    end
    for id,g in pairs(db.graphs) do
        if type(id)~="string" or type(g)~="table" or g.id~=id or (g.schema~=1 and g.schema~=2) or type(g.name)~="string" or (g.mode~="macro" and g.mode~="reminder") or type(g.nodes)~="table" or type(g.connections)~="table" then return nil,"Invalid graph record or unsupported schema." end
        if not serial(g.serial) or type(g.enabled)~="boolean" or type(g.macroName)~="string" or type(g.perCharacter)~="boolean" then return nil,"Invalid graph settings." end
        if g.zoom~=nil and (type(g.zoom)~="number" or g.zoom~=g.zoom or g.zoom<.5 or g.zoom>1.5) then return nil,"Invalid graph zoom." end
        for nid,n in pairs(g.nodes) do
            if type(nid)~="string" or type(n)~="table" or n.id~=nid or type(n.type)~="string" or type(n.settings)~="table" or type(n.x)~="number" or type(n.y)~="number" or n.x~=n.x or n.y~=n.y or math.abs(n.x)==math.huge or math.abs(n.y)==math.huge then return nil,"Invalid node record." end
            for key,v in pairs(n.settings) do
                if type(key)~="string" or (type(v)~="string" and type(v)~="number" and type(v)~="boolean") then return nil,"Node settings must contain serializable scalar values." end
            end
            local d=S.Registry[n.type]
            if d and db.schema==3 then
                for _,f in ipairs(d.fields) do
                    local value=n.settings[f.key]
                    if value==nil then -- Newly added fields are filled by profile normalization.
                    elseif f.kind=="check" then
                        if type(value)~="boolean" then return nil,"Invalid checkbox setting." end
                    elseif type(value)~="string" and type(value)~="number" then return nil,"Invalid field setting." end
                end
            end
        end
        for cid,c in pairs(g.connections) do
            if type(cid)~="string" or type(c)~="table" or c.id~=cid or type(c.from)~="string" or type(c.to)~="string" or type(c.input)~="string" or type(c.output)~="string" or type(c.type)~="string" then return nil,"Invalid connection record." end
        end
    end
    return true
end
