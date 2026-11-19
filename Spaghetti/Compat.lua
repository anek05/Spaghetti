local _, S = ...
function S.Secret(v)
    return (issecretvalue and issecretvalue(v)) or (issecrettable and type(v)=="table" and issecrettable(v)) or false
end
function S.SpellName(id)
    if not C_Spell or not C_Spell.GetSpellName then return end
    local ok,v=pcall(C_Spell.GetSpellName,id)
    if ok and not S.Secret(v) and type(v)=="string" then return v end
end
function S.SpellTexture(id)
    if not C_Spell or not C_Spell.GetSpellTexture then return 134400 end
    local ok,v=pcall(C_Spell.GetSpellTexture,id)
    if ok and not S.Secret(v) and v then return v end
    return 134400
end
-- A combat read is allowed only when the client explicitly declares this spell
-- non-secret now. Failed/secret/unknown permission never means Missing.
function S.ReadBuff(id)
    local combat=S.inCombat or (InCombatLockdown and InCombatLockdown())
    if combat then
        if not C_Secrets or not C_Secrets.ShouldSpellAuraBeSecret or not C_Secrets.GetSpellAuraSecrecy or not Enum or not Enum.SecrecyLevel then return nil,"Combat aura permission is unavailable." end
        local known,level=pcall(C_Secrets.GetSpellAuraSecrecy,id)
        if not known or S.Secret(level) then return nil,"Combat aura classification is unknown." end
        if level~=Enum.SecrecyLevel.NeverSecret then return nil,"Combat buff tracking unsupported for this secret/contextual aura; its current state is UNKNOWN." end
        local ok,secret=pcall(C_Secrets.ShouldSpellAuraBeSecret,id)
        if not ok or S.Secret(secret) then return nil,"Combat aura permission is unknown." end
        if secret~=false then return nil,"This combat aura is secret; missing/active cannot be determined." end
    end
    if not C_UnitAuras or not C_UnitAuras.GetPlayerAuraBySpellID then return nil,"C_UnitAuras.GetPlayerAuraBySpellID is unavailable." end
    if not issecretvalue then return nil,"Secret-value guard is unavailable; aura evaluation disabled." end
    if C_Secrets and C_Secrets.ShouldSpellAuraBeSecret then
        local ok,v=pcall(C_Secrets.ShouldSpellAuraBeSecret,id)
        if not ok or S.Secret(v) then return nil,"Aura secrecy could not be determined." end
        if v then return nil,"This spell's aura is secret." end
    end
    local ok,aura=pcall(C_UnitAuras.GetPlayerAuraBySpellID,id)
    if not ok or S.Secret(aura) then return nil,"Aura is restricted or inaccessible." end
    -- Only existence is used. No duration, instance ID or secret fields are inspected.
    return aura~=nil
end
function S.Print(text) if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff63cbe8Spaghetti:|r "..text) end end
