local _, S = ...
local C={buttons={}}; S.SecureClicks=C
function C.Sync(key,settings,layout,visible)
    -- Secure state code hides on combat entry and never automatically re-shows.
    -- All addon-originated attributes, geometry and visibility changes are OOC.
    if S.inCombat or InCombatLockdown and InCombatLockdown() then return false,"Click outside combat only" end
    local button=C.buttons[key]
    local e=settings and settings.castEntry
    if not visible or not settings or not settings.clickable or not e or e.passive or S.Layout.active or (tonumber(settings.spell) or 0)<=0 then
        if button then button:Hide() end; return false,"Choose a cast spell and a visible icon"
    end
    if not RegisterStateDriver then return false,"Secure state handling unavailable" end
    if not button then
        local ok,b=pcall(CreateFrame,"Button",nil,UIParent,"SecureActionButtonTemplate,SecureHandlerStateTemplate")
        if not ok or not b then return false,"Secure button unavailable" end
        button=b; C.buttons[key]=button
        button:Hide()
        button.icon=button:CreateTexture(nil,"ARTWORK"); button.icon:SetAllPoints()
        button:SetAttribute("_onstate-combat",[[if newstate == "1" then self:Hide() end]])
        button.ready=pcall(RegisterStateDriver,button,"combat","[combat] 1; 0")
        button:RegisterForClicks("LeftButtonUp","LeftButtonDown")
        button:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); if GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(self.spellID) end; GameTooltip:Show() end)
        button:SetScript("OnLeave",function() GameTooltip:Hide() end)
    end
    if not button.ready then return false,"Secure combat handler unavailable" end
    local spell=e.name
    if settings.castSpellMode=="exact" and e.rankText~="" then spell=spell.."("..e.rankText..")" end
    button.spellID=e.id; button:SetAttribute("type1","spell"); button:SetAttribute("spell1",spell)
    button:SetAttribute("unit1","player"); button:SetSize(layout.size,layout.size); button:ClearAllPoints()
    button.icon:SetTexture(S.SpellTexture(tonumber(settings.spell)))
    button:SetPoint("CENTER",UIParent,"CENTER",layout.x-(layout.frameWidth or math.max(260,layout.size+230))/2+10+layout.size/2,layout.y)
    -- Match the visual's strata so an editor/dialog covering it also covers the
    -- hit target; never place a transparent click layer above that dialog.
    button:SetFrameStrata("HIGH"); button:Show(); return true
end
function C.Hide(key)
    if not S.inCombat and not (InCombatLockdown and InCombatLockdown()) and C.buttons[key] then C.buttons[key]:Hide() end
end
