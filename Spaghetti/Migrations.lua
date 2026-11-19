local _, S = ...
function S.Migrate(db)
    local ok,reason=S.CheckStorage(db); if not ok then return nil,reason end
    if db.schema==2 then return db end
    local migrated=S.Copy(db)
    migrated.legacyBackup=S.Copy(db); migrated.schema=2; migrated.layouts=migrated.layouts or {}
    local modes={enter="Enter Combat",leave="Leave Combat",combat="In Combat"}
    for gid,g in pairs(migrated.graphs) do
        g.schema=2; g.applied=g.enabled; g.zoom=1; g.migrationWarnings={}
        for id,n in pairs(g.nodes) do
            local s=n.settings
            if modes[n.type] then s.state=modes[n.type]; n.type="combat_state" end
            if n.type=="show" then
                migrated.layouts[gid..":"..id]={x=math.max(-3000,math.min(3000,tonumber(s.x) or 0)),y=math.max(-2000,math.min(2000,tonumber(s.y) or 140)),size=math.max(16,math.min(128,tonumber(s.size) or 48))}
                s.clickable=false; s.castSpell="auto"
            end
            if n.type=="buff" or n.type=="show" then s.spellMode=s.spellMode or "auto" end
            if n.type=="cast" then
                -- Resolve only a unique current learned name. Ambiguity preserves original text.
                if not tonumber(s.value) and S.Spells then
                    local results={}; for _,e in ipairs(S.Spells.entries) do if e.name==s.value and not e.passive then results[#results+1]=e end end
                    local e=results[1]
                    if #results==1 or e and e.family and #e.family.members==#results then s.value=tostring(e.id) end
                end
                s.valueMode="auto"
            end
            local definition=S.Registry[n.type]
            if definition then for _,field in ipairs(definition.fields) do if s[field.key]==nil then s[field.key]=field.default end end end
            if (n.type=="buff" or n.type=="cast") and S.Spells then
                local seed=n.type=="cast" and s.value or s.spell
                local e=S.Spells.Resolve(seed)
                if not e then g.migrationWarnings[#g.migrationWarnings+1]=id..": saved spell retained; select a learned spell when available." end
            end
        end
        -- All old combat ports keep their names and types. Never rewrite/drop an edge.
        local errors=S.Graph.Validate(g)
        if #errors>0 then g.migrationWarnings[#g.migrationWarnings+1]="Graph needs review; original data remains in legacyBackup. "..table.concat(errors," ") end
    end
    local valid,why=S.CheckStorage(migrated)
    if not valid then return nil,"Migration was cancelled; original data preserved: "..why end
    return migrated
end
