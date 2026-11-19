local addonName, S = ...
S.addonName=addonName
function S.Save(g)
    S.db.graphs[g.id]=S.Copy(g); S.db.selected=g.id
    if S.db.drafts then S.db.drafts[g.id]=nil end
end
local events=CreateFrame("Frame")
local recoverySerial=0
local function cancelRecovery() recoverySerial=recoverySerial+1 end
local function recoverAfterLockdown()
    cancelRecovery()
    if not (InCombatLockdown and InCombatLockdown()) or not (C_Timer and C_Timer.After) then return end
    local serial,attempts=recoverySerial,0
    local function retry()
        if serial~=recoverySerial or S.inCombat or not S.db then return end
        attempts=attempts+1
        if not (InCombatLockdown and InCombatLockdown()) then
            -- Re-evaluate current saved rules, never captured draft/preview settings.
            S.Engine.Evaluate("COMBAT_RECOVERY")
        elseif attempts<20 then C_Timer.After(.1,retry) end
    end
    -- At most 20 checks over roughly two seconds; no permanent polling.
    C_Timer.After(.1,retry)
end
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent",function(_,event,name)
    if event=="ADDON_LOADED" then
        if name~=addonName then return end
        S.Spells.Refresh()
        S.Items.Refresh()
        local db,reason=S.Profiles.Open(SpaghettiCharDB,SpaghettiDB)
        if not db then S.Print(reason); return end
        SpaghettiCharDB=db; S.db=db; S.legacySource=SpaghettiDB
        S.Editor.drafts=S.Copy(db.drafts); S.Editor.dirty={}
        for id in pairs(db.drafts) do S.Editor.dirty[id]=true end
        S.inCombat=InCombatLockdown and InCombatLockdown() or false
        events:RegisterEvent("PLAYER_LOGIN"); events:RegisterEvent("PLAYER_ENTERING_WORLD")
        events:RegisterEvent("PLAYER_REGEN_DISABLED"); events:RegisterEvent("PLAYER_REGEN_ENABLED"); events:RegisterEvent("UNIT_AURA")
        events:RegisterEvent("SPELLS_CHANGED"); events:RegisterEvent("LEARNED_SPELL_IN_SKILL_LINE"); events:RegisterEvent("SPELL_TEXT_UPDATE")
        events:RegisterEvent("BAG_UPDATE_DELAYED"); events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED"); events:RegisterEvent("GET_ITEM_INFO_RECEIVED"); events:RegisterEvent("EQUIPMENT_SETS_CHANGED")
        events:RegisterEvent("UPDATE_MACROS")
        events:RegisterEvent("PLAYER_LOGOUT")
        SLASH_SPAGHETTI1="/spaghetti"
        SlashCmdList.SPAGHETTI=function() S.Editor.Toggle() end
        S.Engine.Reload()
        S.Print("0.3.1 loaded. /spaghetti opens this character's profile. Legacy account data is never activated automatically.")
    elseif S.db then
        if event=="PLAYER_LOGOUT" then cancelRecovery(); return end
        if event=="UPDATE_MACROS" then if S.Editor.window and S.Editor.window:IsShown() then S.Editor.UpdateStatus() end; return end
        if event=="UNIT_AURA" and name~="player" then return end
        if event=="PLAYER_REGEN_DISABLED" then cancelRecovery(); S.inCombat=true elseif event=="PLAYER_REGEN_ENABLED" then S.inCombat=false end
        if event=="PLAYER_LOGIN" or event=="SPELLS_CHANGED" or event=="LEARNED_SPELL_IN_SKILL_LINE" or event=="SPELL_TEXT_UPDATE" then
            S.Spells.Refresh(); if S.SpellPicker then S.SpellPicker.Refresh() end
            if S.Canvas and S.Editor and S.Editor.graph then S.Canvas.RefreshSpells() end
        end
        if event=="PLAYER_REGEN_DISABLED" and S.Layout and S.Layout.active then S.Layout.Cancel(true) end
        if event=="PLAYER_LOGIN" or event=="BAG_UPDATE_DELAYED" or event=="PLAYER_EQUIPMENT_CHANGED" or event=="GET_ITEM_INFO_RECEIVED" or event=="EQUIPMENT_SETS_CHANGED" then
            S.Items.Refresh(); S.ItemPicker.Refresh()
            if S.Editor.window then S.Editor.BuildLibrary(); S.Canvas.RefreshSpells() end
        end
        S.Engine.Evaluate(event)
        if event=="PLAYER_REGEN_ENABLED" then recoverAfterLockdown() end
    end
end)
