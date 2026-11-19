local _, S = ...
local D={frames={},generation={}}; S.Display=D
function D.Hide(key)
    D.generation[key]=(D.generation[key] or 0)+1
    if D.frames[key] then D.frames[key]:Hide() end
    if S.SecureClicks then S.SecureClicks.Hide(key) end
end
function D.IsVisible(key) return D.frames[key] and not D.frames[key].preview and D.frames[key]:IsShown() or false end
function D.HideAll()
    for key in pairs(D.frames) do D.Hide(key) end
end
local function clickText(key,f,settings,layout,preview)
    local note=""
    if S.SecureClicks then
        local ready,reason=S.SecureClicks.Sync(key,settings,layout,not preview)
        if settings.clickable and not preview then note="\n"..(ready and "Click icon • outside combat only" or (reason or "Click unavailable")) end
    end
    f.text:SetText((preview and "PREVIEW\n" or "")..(settings.text or "")..((settings.text or ""):find("%S") and note or ""))
end
function D.RefreshClick(key,settings)
    local f=D.frames[key]
    if D.IsVisible(key) and f.clickLayout then clickText(key,f,settings,f.clickLayout,false) end
end
function D.Show(key,settings,seconds,preview)
    if S.Layout and S.Layout.active then return end
    if not settings.enabled then D.Hide(key); return end
    local f=D.frames[key]
    if not f then
        f=CreateFrame("Frame",nil,UIParent,"BackdropTemplate"); D.frames[key]=f
        f:SetFrameStrata("HIGH")
        f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        f:SetBackdropColor(.035,.055,.08,.94); f:SetBackdropBorderColor(.2,.7,.85,1)
        f.icon=f:CreateTexture(nil,"ARTWORK")
        f.text=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); f.text:SetJustifyH("LEFT")
    end
    f:SetFrameStrata(preview and "TOOLTIP" or "HIGH")
    f.preview=preview
    local layout=S.Layout and S.Layout.Get(settings.layoutKey or key,settings) or {size=tonumber(settings.size) or 48,x=tonumber(settings.x) or 0,y=tonumber(settings.y) or 140}
    local size=layout.size; local icon=(tonumber(settings.spell) or 0)>0
    local hasText=(settings.text or ""):find("%S")~=nil
    local width=(hasText or preview) and (icon and math.max(260,size+230) or 260) or (size+20)
    layout.frameWidth=width
    f.clickLayout=layout
    f:SetSize(width,icon and size+20 or math.max(52,size)); f:ClearAllPoints()
    f:SetPoint("CENTER",UIParent,"CENTER",layout.x,layout.y)
    f.icon:SetSize(size,size); f.icon:SetPoint("LEFT",10,0)
    f.icon:SetTexture(icon and S.SpellTexture(tonumber(settings.spell)) or nil)
    f.icon:SetShown(icon)
    f.text:ClearAllPoints(); f.text:SetPoint("LEFT",icon and size+20 or 12,0); f.text:SetWidth(210)
    clickText(key,f,settings,layout,preview); f:Show()
    f.text:SetShown(hasText or preview)
    if hasText or preview then f:SetHeight(math.max(f:GetHeight(),f.text:GetStringHeight()+20)) end
    D.generation[key]=(D.generation[key] or 0)+1; local generation=D.generation[key]
    if seconds and C_Timer and C_Timer.After then C_Timer.After(seconds,function() if D.generation[key]==generation then D.Hide(key); if S.Editor and S.Editor.UpdateOverview then S.Editor.UpdateOverview() end end end) end
end
