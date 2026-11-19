local _, S = ...
local P={entries={},byID={},families={},generation=0}; S.Spells=P
local function call(fn,...)
    if type(fn)~="function" then return end
    local ok,a,b=pcall(fn,...)
    if ok and not S.Secret(a) and not S.Secret(b) then return a,b end
end
P.Call=call
local function rankParts(text)
    if type(text)~="string" then return end
    local prefix,number=text:match("^(.-)(%d+)%s*$")
    if prefix and prefix~="" then return prefix,tonumber(number) end
end
function P.Refresh()
    P.entries={}; P.byID={}; P.families={}; P.generation=P.generation+1
    local book=C_SpellBook
    local bank=Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    local spellType=Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell
    if not book or bank==nil or spellType==nil or not book.GetSpellBookItemInfo or not book.GetSpellBookSkillLineInfo then
        P.reason="The modern spellbook API is unavailable. Existing spell selections are retained."; return
    end
    local count=call(book.GetNumSpellBookSkillLines)
    if type(count)~="number" then P.reason="Spellbook is not ready; try again after login."; return end
    P.reason=nil
    for line=1,count do
        local skill=call(book.GetSpellBookSkillLineInfo,line)
        if type(skill)=="table" and not skill.offSpecID then
            local offset,num=skill.itemIndexOffset,skill.numSpellBookItems
            if type(offset)=="number" and type(num)=="number" then
                for slot=offset+1,offset+num do
                    local info=call(book.GetSpellBookItemInfo,slot,bank)
                    if type(info)=="table" and info.itemType==spellType and not info.isOffSpec then
                        local id=info.spellID or info.actionID
                        local name,sub=call(book.GetSpellBookItemName,slot,bank)
                        name=name or info.name; sub=sub or info.subName or ""
                        local known=call(book.IsSpellKnown,id,bank)
                        -- SpellBookItemType.Spell is learned; FutureSpell and Flyout are separate types.
                        if type(id)=="number" and type(name)=="string" and name~="" and known~=false and not P.byID[id] then
                            local prefix,rank=rankParts(sub)
                            local e={id=id,name=name,rankText=sub,rank=rank,prefix=prefix,scope=skill.name or tostring(line),slot=slot,bank=bank,
                                icon=info.iconID or S.SpellTexture(id),passive=info.isPassive==true,low=call(book.IsSpellBookItemLowRank,slot,bank)}
                            P.entries[#P.entries+1]=e; P.byID[id]=e
                        end
                    end
                end
            end
        end
    end
    -- A shared name alone is never a family. Require a learned spellbook skill line,
    -- rank subtexts with a common prefix, unique rank numbers, and client LowRank
    -- flags agreeing on exactly one highest member. Otherwise keep fixed identity.
    local candidates={}
    for _,e in ipairs(P.entries) do
        if e.rank and e.low~=nil then
            local key=e.scope.."\031"..e.name.."\031"..e.prefix
            candidates[key]=candidates[key] or {}; table.insert(candidates[key],e)
        end
    end
    for _,group in pairs(candidates) do
        local highest,topCount,ranks,valid=nil,0,{},true
        for _,e in ipairs(group) do
            if ranks[e.rank] then valid=false end; ranks[e.rank]=true
            if e.low==false then highest=e; topCount=topCount+1 end
        end
        if #group>1 and valid and topCount==1 then
            for _,e in ipairs(group) do if e.rank>highest.rank then valid=false end end
            if valid then
                local family={members=group,highest=highest}
                for _,e in ipairs(group) do e.family=family; P.families[e.id]=family end
            end
        end
    end
    table.sort(P.entries,function(a,b) if a.name==b.name then return (a.rank or 0)>(b.rank or 0) end return a.name<b.name end)
end
function P.Search(query,castable)
    local results={}; query=string.lower(query or "")
    for _,e in ipairs(P.entries) do
        if (not castable or not e.passive) and string.lower(e.name.." "..e.rankText):find(query,1,true) then results[#results+1]=e end
    end
    return results
end
function P.Resolve(seed,mode)
    local id=tonumber(seed); local entry=id and P.byID[id]
    if not id and type(seed)=="string" and P.ResolveLegacyName then entry=P.ResolveLegacyName(seed) end
    if not entry then return nil,P.reason or "Selected spell is not in the current learned spellbook. Its saved selection is retained." end
    if mode~="exact" and entry.family then return entry.family.highest end
    return entry,mode~="exact" and "Rank family unverified: tracking this learned spell only. Re-select after learning a rank if it disappears from the spellbook." or nil
end
function P.ResolveLegacyName(name)
    local matches={}
    for _,e in ipairs(P.entries) do if e.name==name and not e.passive then matches[#matches+1]=e end end
    if #matches==1 then return matches[1] end
    local first=matches[1]
    if first and first.family and #first.family.members==#matches then return first.family.highest end
end
function P.Label(seed,mode)
    if seed=="" or seed==nil then return "None - select spell" end
    if seed=="auto" then return "Use associated spell" end
    if tonumber(seed)==0 then return "No icon" end
    local e,reason=P.Resolve(seed,mode)
    if e then return e.name..(e.rankText~="" and " — "..e.rankText or "") end
    local name=tonumber(seed) and S.SpellName(tonumber(seed)) or (type(seed)=="string" and seed or nil)
    return (name or "Saved spell").." (unavailable)",reason
end
function P.Select(settings,key,entry,mode)
    if not entry or not P.byID[entry.id] then return nil,"That spell is no longer available." end
    settings[key]=tostring(entry.id); settings[key.."Mode"]=mode or "auto"
    return true
end
function P.Cursor(castable)
    if not GetCursorInfo then return nil,"Spellbook dragging is unavailable." end
    local ok,kind,slot,bank,id=pcall(GetCursorInfo)
    if not ok or S.Secret(kind) or kind~="spell" then return nil,"Drag a learned spell from the native Spellbook." end
    -- The fourth return is spellID; slot/bank are used only as a supported fallback.
    if S.Secret(id) or S.Secret(slot) or S.Secret(bank) then return nil,"The cursor spell is unavailable." end
    local e=id and P.byID[id]
    if not e and C_SpellBook and type(slot)=="number" then
        local info=call(C_SpellBook.GetSpellBookItemInfo,slot,bank)
        if type(info)=="table" then e=P.byID[info.spellID or info.actionID] end
    end
    if not e or castable and e.passive then return nil,"Choose a learned, castable spell." end
    return e
end
function P.Associated(g,nodeID)
    local found,seen={},{}
    local function visit(id)
        if seen[id] then return end; seen[id]=true
        local n=g.nodes[id]
        if n and n.type=="buff" then found[n.settings.spell]=true end
        for _,c in pairs(g.connections) do if c.to==id then visit(c.from) end end
    end
    visit(nodeID)
    local seed
    for id in pairs(found) do if seed then return nil,"Multiple buff spells feed this reminder; choose an explicit spell." end; seed=id end
    return seed
end
function P.ReminderSettings(g,n)
    local settings=S.Copy(n.settings)
    local associated=P.Associated(g,n.id)
    local seed=settings.spell=="auto" and associated or settings.spell
    local e=seed and P.Resolve(seed,settings.spellMode)
    settings.spell=e and tostring(e.id) or (tonumber(seed) and seed or "0")
    local castSeed=settings.castSpell=="auto" and associated or settings.castSpell
    settings.castEntry=castSeed and P.Resolve(castSeed,settings.castSpellMode)
    return settings
end
function P.ReadBuff(seed,mode)
    local e,reason=P.Resolve(seed,mode)
    if not e then return nil,reason end
    local entries=(mode~="exact" and e.family and e.family.members) or {e}
    local unknown
    for _,rank in ipairs(entries) do
        local active,why=S.ReadBuff(rank.id)
        if active==true then return true end
        if active==nil then unknown=why end
    end
    if unknown then return nil,unknown end
    return false
end
