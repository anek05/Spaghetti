local _, S = ...
local G, M = S.Graph, {}; S.Macro = M
M.LIMIT = 255
local predicates = { exists="exists", friendly="help", hostile="harm" }
local commands = {cast="cast", use="use", target="target",focus="focus",equip="equip",equipslot="equipslot",equipset="equipset"}
local function safeText(s)
    return type(s)=="string" and s:find("%S") and not s:find("[\r\n%[%];/|]") and not s:find("%c")
end
function M.Compile(g)
    local errors, warnings = G.Validate(g)
    if g.mode ~= "macro" then errors[#errors+1] = "Choose Macro mode." end
    local used, starts = {}, {}
    for _,n in pairs(g.nodes) do if n.type == "start" then starts[#starts+1]=n end end
    local function fail(s) errors[#errors+1]=s end
    if #starts ~= 1 then fail("A macro needs exactly one Macro Start.") end
    if #errors > 0 then return nil, errors, warnings end
    local function nextNode(n, port)
        local c=G.Outgoing(g,n.id,port or "next"); return c and g.nodes[c.to]
    end
    local function action(n)
        if not n or not commands[n.type] then fail("Connect a supported macro action.") return end
        used[n.id]=true
        local v=n.settings.value
        if not safeText(v) then fail(n.id..": select a spell/item or enter a plain spell/item name without macro syntax.") return end
        if n.type=="equipset" then
            local set=S.Items and S.Items.SetsAvailable() and S.Items.sets[v]
            if not set then fail(n.id..": native equipment sets are unsupported or the selected set is unavailable.") return end
            v=set.name
        elseif n.type=="equip" or n.type=="equipslot" or n.type=="use" and v:match("^item:%d+$") then
            local item,reason
            if S.Items then item,reason=S.Items.Resolve(v) end
            if not item then fail(n.id..": "..(reason or "Select an available item to equip/use.")) return end
            if n.type~="use" and not item.equippable then fail(n.id..": select an equippable item.") return end
            v="item:"..item.id
            if n.type=="equipslot" then
                local slot=S.Items.SlotID(n.settings.slot)
                if not slot then fail(n.id..": selected equipment slot is unavailable on this client.") return end
                v=slot.." "..v
            end
        end
        if n.type=="cast" and v:match("^%d+$") then
            -- /cast accepts spell names, not arbitrary bare spell IDs. Resolve using modern API adapter.
            local e,why=S.Spells and S.Spells.Resolve(v,n.settings.valueMode)
            local name=e and e.name or (not S.Spells and S.SpellName and S.SpellName(tonumber(v)))
            if e and e.passive then fail(n.id..": passive spells cannot be cast.") return end
            if e and n.settings.valueMode=="exact" and e.rankText~="" then name=name.."("..e.rankText..")" end
            if not name then fail(n.id..": spell ID cannot be resolved; enter the localized spell name.") return end
            v=name
            if not safeText(v) then fail("Resolved spell name contains unsupported syntax.") return end
        elseif n.type=="use" and v:match("^%d+$") and tonumber(v)>19 then v="item:"..v end
        local unit=n.settings.unit or "auto"
        if n.type=="cast" and unit=="focus" then
            warnings[#warnings+1]=n.id..": casts directly on an existing focus without changing current target. Set focus first; native range, life and spell-target rules still apply."
            if UnitExists then
                local ok,exists=pcall(UnitExists,"focus")
                if ok and not (S.Secret and S.Secret(exists)) and exists==false then warnings[#warnings+1]=n.id..": no focus is set now. Right-clicking a unit is not the same as setting focus." end
            end
        end
        if n.type=="equip" or n.type=="equipslot" or n.type=="equipset" then warnings[#warnings+1]=n.id..": equipment macros obey native slot, inventory and combat restrictions; they cannot bypass lockdown." end
        if not safeText(v) then fail(n.id..": generated action contains unsupported macro syntax.") return end
        return commands[n.type], v, unit
    end
    local lines={"#showtooltip"}
    local function qualifier(unit, condition,actionNode)
        local parts={}
        if unit~="auto" then parts[#parts+1]="@"..unit end
        if actionNode and actionNode.type=="cast" then
            local settings=actionNode.settings
            if settings.relation=="Friendly" then parts[#parts+1]="help" elseif settings.relation=="Hostile" then parts[#parts+1]="harm" end
            if settings.alive then parts[#parts+1]="nodead" end
            if settings.exists then parts[#parts+1]="exists" end
        end
        if condition then parts[#parts+1]=condition end
        return #parts>0 and "["..table.concat(parts,",").."] " or ""
    end
    local n=nextNode(starts[1]); used[starts[1].id]=true
    if not n then fail("Connect Macro Start to an action or Conditional Branch.") end
    while n do
        if used[n.id] then fail("Repeated flow node."); break end
        if n.type=="branch" then
            used[n.id]=true
            if #lines>1 then fail("MVP branches must immediately follow Macro Start.") end
            local c=G.Incoming(g,n.id,"condition"); local cond=c and g.nodes[c.from]
            local p=cond and predicates[cond.type]
            if cond and cond.type=="modifier" then p="mod:"..cond.settings.key end
            if cond and cond.type=="mcombat" then p=cond.settings.state end
            if not p then fail("Connect one supported macro condition to Branch.Condition.") else used[cond.id]=true end
            local yes,no=nextNode(n,"yes"),nextNode(n,"no")
            local ac,av,au=action(yes); local bc,bv,bu=action(no)
            if yes and nextNode(yes) or no and nextNode(no) then fail("Branch arms must be terminal actions; nested branches/chains are unsupported.") end
            if yes and no and yes.id==no.id then fail("Branch alternatives must be distinct nodes.") end
            if ac and bc then
                if ac~=bc or au~=bu then fail("Branch arms must use the same command and target selector.")
                elseif ac~="cast" and ac~="use" then fail("Branch alternatives support only Cast or Use; equipment/target/focus actions must be linear.")
                elseif qualifier(au,nil,yes)~=qualifier(bu,nil,no) then fail("Branch arms must have matching target requirements.")
                elseif p then lines[#lines+1]="/"..ac.." "..qualifier(au,p,yes)..av.."; "..qualifier(bu,nil,no)..bv end
            end
            n=nil
        else
            local command,value,unit=action(n)
            if command then lines[#lines+1]="/"..command.." "..qualifier(unit,nil,n)..value end
            n=nextNode(n)
        end
    end
    for id in pairs(g.nodes) do if not used[id] then fail(id..": disconnected or unsupported node; nothing is silently ignored.") end end
    local body=table.concat(lines,"\n")
    if #body>M.LIMIT then fail("Macro is "..#body.." bytes; maximum is "..M.LIMIT..". Shorten the graph. No text was truncated.") end
    if #errors>0 then return nil,errors,warnings end
    return body,errors,warnings
end
