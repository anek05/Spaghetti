local _, S = ...
local I={}; S.MacroIntegration=I
function I.NormalizeName(g)
    if g.macroNameCustom==nil then
        if g.macroName==nil or g.macroName=="Spaghetti" or g.macroName=="" then
            g.legacyMacroName=g.macroName; g.macroNameCustom=false
        else g.macroNameCustom=true end
    end
end
function I.Name(g)
    I.NormalizeName(g)
    return g.macroNameCustom and g.macroName or g.name
end
function I.NameError(name)
    if type(name)~="string" or not name:find("%S") then return "Enter a native macro name, or give the graph a name." end
    local _,length=name:gsub("[^\128-\191]","")
    if length>16 or name:find("[%c|]") then return "Macro names allow at most 16 characters and no control characters or color codes. Nothing was truncated." end
end
function I.Limits()
    local c=Constants and Constants.MacroConsts
    return c and c.MAX_ACCOUNT_MACROS or MAX_ACCOUNT_MACROS or 120,c and c.MAX_CHARACTER_MACROS or MAX_CHARACTER_MACROS or 30
end
function I.Body(body)
    return type(body)=="string" and body:gsub("\r\n","\n"):gsub("%s+$","") or ""
end
function I.Read(index)
    if not GetMacroInfo then return nil,"GetMacroInfo is unavailable; native identity cannot be verified." end
    local ok,name,icon,body=pcall(GetMacroInfo,index)
    if not ok or (S.Secret and (S.Secret(name) or S.Secret(icon) or S.Secret(body))) then return nil,"Native macro information is unreadable; no macro will be picked up or overwritten." end
    if type(name)~="string" then return end
    local account=I.Limits()
    return {index=index,name=name,icon=icon or 134400,body=body or "",perCharacter=index>account}
end
function I.Scan()
    local records={}
    if not GetMacroInfo then return nil,"GetMacroInfo is unavailable; native identity cannot be verified." end
    local account,character=I.Limits()
    -- The whole native slot range is small. Enumerate it to handle holes, duplicate
    -- names, and external reordering; a name lookup or cached index is not identity.
    for index=1,account+character do
        local r,reason=I.Read(index); if reason then return nil,reason end
        if r then records[#records+1]=r end
    end
    return records
end
local function sameName(a,b) return a:lower()==b:lower() end
local function signature(r,meta)
    return r.name==meta.name and r.perCharacter==(meta.perCharacter==true) and I.Body(r.body)==I.Body(meta.body)
end
function I.Resolve(g,records)
    local meta=g.nativeMacro
    if type(meta)~="table" or type(meta.name)~="string" or type(meta.body)~="string" or type(meta.perCharacter)~="boolean" then return nil,"Not created","Create a native macro first. Saving/generating a graph does not create it." end
    if not records then local reason; records,reason=I.Scan(); if not records then return nil,"Out of sync",reason end end
    local exact,named={},{}
    for _,r in ipairs(records) do
        if signature(r,meta) then exact[#exact+1]=r end
        if r.perCharacter==(meta.perCharacter==true) and sameName(r.name,meta.name) then named[#named+1]=r end
    end
    if #exact==1 then return exact[1] end
    if #exact>1 then return nil,"Out of sync","Multiple native macros match the stored identity; choose a unique name before updating or dragging." end
    if #named>0 then return nil,"Out of sync","The native macro was edited outside Spaghetti. Review and confirm an update; it will not be dragged or overwritten silently." end
    return nil,"Missing","Native macro is missing or renamed. The old index is not trusted. Recreate explicitly; no other macro will be picked up by that stale index."
end
function I.Status(g,body)
    local record,state,reason=I.Resolve(g)
    if not record then return {state=state,reason=reason,ready=false} end
    if not body then return {state="Out of sync",reason="The current graph cannot generate macro text. Fix its validation errors before dragging/updating; the saved native association is retained.",record=record,ready=false} end
    if record.name~=I.Name(g) or record.perCharacter~=(g.perCharacter==true) or I.Body(record.body)~=I.Body(body) then
        return {state="Out of sync",reason="The graph's generated text, intended name or scope differs from the native macro. Update/recreate it through the guarded workflow.",record=record,ready=false}
    end
    return {state="Created",reason="Ready to drag this verified native macro to an action bar.",record=record,ready=true}
end
function I.Validate(g,body)
    if (InCombatLockdown and InCombatLockdown()) or S.inCombat then return nil,"Macro creation is blocked during combat lockdown." end
    if not CreateMacro or not EditMacro or not GetMacroInfo or not GetNumMacros then return nil,"Required native macro APIs are unavailable." end
    local name=I.Name(g); local errorMessage=I.NameError(name)
    if errorMessage then return nil,errorMessage end
    if type(body)~="string" or #body>255 then return nil,"Macro text must fit the native 255-byte limit." end
    local records,scanError=I.Scan(); if not records then return nil,scanError end
    local matches={}
    for _,r in ipairs(records) do if sameName(r.name,name) then matches[#matches+1]=r end end
    if #matches>1 then return nil,"Multiple native macros have that name. Choose a unique name; no ambiguous macro will be overwritten." end
    local target=I.Resolve(g,records)
    if not target and type(g.nativeMacro)=="table" and type(g.nativeMacro.name)=="string" then
        -- An externally edited body may only be updated after a fresh explicit
        -- confirmation of this uniquely named, same-scope native record.
        local old={}
        for _,r in ipairs(records) do if sameName(r.name,g.nativeMacro.name) and r.perCharacter==(g.nativeMacro.perCharacter==true) then old[#old+1]=r end end
        if #old==1 then target=old[1] end
    end
    if target and target.perCharacter~=(g.perCharacter==true) then target=nil end
    if matches[1] then
        if matches[1].perCharacter~=(g.perCharacter==true) then return nil,"A macro with this name exists in the other scope. Choose a unique name." end
        if target and target.index~=matches[1].index then return nil,"That name belongs to a different native macro. Choose a unique name before renaming this one." end
        target=matches[1]
    end
    if target then return {index=target.index,name=name,oldName=target.name,oldBody=target.body,icon=target.icon,perCharacter=target.perCharacter} end
    local ok,a,c=pcall(GetNumMacros)
    if not ok or type(a)~="number" or type(c)~="number" then return nil,"Native macro counts are unavailable." end
    local account,character=I.Limits()
    if g.perCharacter and c>=character or not g.perCharacter and a>=account then return nil,"No free macro slots in the selected scope." end
    return {name=name,perCharacter=g.perCharacter==true,icon=134400}
end
function I.Apply(g,body,confirmed)
    local plan,reason=I.Validate(g,body); if not plan then return nil,reason end
    if plan.index then
        if not confirmed or confirmed.index~=plan.index or confirmed.name~=plan.name or confirmed.oldName~=plan.oldName or confirmed.oldBody~=plan.oldBody or confirmed.perCharacter~=plan.perCharacter then return nil,"CONFIRM",plan end
    end
    local ok,index
    if plan.index then ok,index=pcall(EditMacro,plan.index,plan.name,plan.icon,body)
    else ok,index=pcall(CreateMacro,plan.name,plan.icon,body,g.perCharacter==true) end
    if not ok or type(index)~="number" then return nil,"The client rejected the macro. Check its slots, name and combat state." end
    local actual=I.Read(index)
    if not actual or actual.name~=plan.name then
        return nil,"Native macro name mismatch: requested '"..plan.name.."', but the client stored '"..(actual and actual.name or "unavailable").."'. No ready-to-drag association was recorded; inspect the native macro before retrying."
    end
    if actual.perCharacter~=plan.perCharacter or I.Body(actual.body)~=I.Body(body) then return nil,"Native macro body or scope did not match the request. No ready-to-drag association was recorded." end
    g.nativeMacro={index=index,name=actual.name,body=actual.body,perCharacter=actual.perCharacter}
    return index
end
function I.Pickup(g,body)
    if (InCombatLockdown and InCombatLockdown()) or S.inCombat then return nil,"Macro dragging is blocked during combat lockdown." end
    if not PickupMacro then return nil,"PickupMacro is unavailable on this client." end
    local status=I.Status(g,body)
    if not status.ready then return nil,status.state..": "..(status.reason or "") end
    -- Revalidate by full native identity immediately before the protected call.
    local ok,reason=pcall(PickupMacro,status.record.index)
    if not ok then return nil,"The client rejected macro pickup. Try outside combat." end
    return status.record.index
end
