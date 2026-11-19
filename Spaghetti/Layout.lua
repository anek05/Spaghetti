local _, S = ...
local L={handles={}}; S.Layout=L
function L.Get(key,settings)
    local stored=S.db and S.db.layouts and S.db.layouts[key]
    return S.Copy(stored or {x=tonumber(settings.x) or 0,y=tonumber(settings.y) or 140,size=tonumber(settings.size) or 48})
end
function L.Put(key,value)
    if InCombatLockdown and InCombatLockdown() then return nil,"Positioning is blocked during combat." end
    if type(value.x)~="number" or type(value.y)~="number" or type(value.size)~="number" or value.x~=value.x or value.y~=value.y or value.size~=value.size then return nil,"Invalid placement." end
    S.db.layouts=S.db.layouts or {}; S.db.layouts[key]={x=math.max(-3000,math.min(3000,value.x)),y=math.max(-2000,math.min(2000,value.y)),size=math.max(16,math.min(128,value.size))}
    return true
end
function L.Cancel(combat)
    if not L.active then return end
    L.active=false; L.pending=nil
    for _,f in pairs(L.handles) do f:Hide() end
    if L.toolbar then L.toolbar:Hide() end
    if S.Editor.window and not combat then S.Editor.window:Show() end
    S.Engine.Reload()
end
function L.Save()
    if InCombatLockdown and InCombatLockdown() then return nil,"Positioning is blocked during combat." end
    for key,value in pairs(L.pending or {}) do L.Put(key,value) end
    L.Cancel(); return true
end
function L.Open()
    if InCombatLockdown and InCombatLockdown() then S.Editor.Message("Leave combat before positioning reminders."); return end
    local g=S.Editor.graph; local errors=S.Graph.Validate(g)
    if #errors>0 then S.Editor.Message("Fix graph validation first; placement does not change graph logic."); return end
    L.active=true; L.pending={}; S.Display.HideAll(); S.Editor.window:Hide()
    local W=S.Widgets
    if not L.toolbar then
        L.toolbar=W.Panel(UIParent); L.toolbar:SetSize(500,65); L.toolbar:SetPoint("TOP",0,-70); L.toolbar:SetFrameStrata("TOOLTIP")
        W.Label(L.toolbar,"SPAGHETTI EDIT MODE • drag reminders; use − / + to resize",12,-10)
        W.Button(L.toolbar,"Save placement",140,180,-34,L.Save); W.Button(L.toolbar,"Cancel",100,330,-34,L.Cancel)
    end
    L.toolbar:Show()
    for id,n in pairs(g.nodes) do if n.type=="show" then
        local key=g.id..":"..id; local value=L.Get(key,n.settings); L.pending[key]=value
        local f=L.handles[key]
        if not f then
            f=W.Panel(UIParent); L.handles[key]=f; f:SetFrameStrata("DIALOG"); f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
            f.icon=f:CreateTexture(nil,"ARTWORK"); f.icon:SetPoint("LEFT",8,0)
            f.label=W.Label(f,"",0,0); f.label:ClearAllPoints(); f.label:SetPoint("LEFT",f.icon,"RIGHT",10,0); f.label:SetWidth(210)
            local function resize(delta)
                if not L.active or InCombatLockdown and InCombatLockdown() then return end
                local v=L.pending[key]; v.size=math.max(16,math.min(128,v.size+delta)); f:SetSize(v.size+240,v.size+34); f.icon:SetSize(v.size,v.size)
            end
            local minus=W.Button(f,"−",28,0,0,function() resize(-8) end); minus:ClearAllPoints(); minus:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-36,2)
            local plus=W.Button(f,"+",28,0,0,function() resize(8) end); plus:ClearAllPoints(); plus:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-4,2)
            f:SetScript("OnDragStart",function() if not (InCombatLockdown and InCombatLockdown()) then f:StartMoving() end end)
            f:SetScript("OnDragStop",function()
                f:StopMovingOrSizing(); if not L.active then return end
                local x,y=f:GetCenter(); local px,py=UIParent:GetCenter()
                L.pending[key].x=x-px; L.pending[key].y=y-py
            end)
        end
        local settings=S.Spells.ReminderSettings(g,n)
        f.icon:SetTexture(tonumber(settings.spell) and S.SpellTexture(tonumber(settings.spell)) or 134400)
        f.icon:SetSize(value.size,value.size); f:SetSize(value.size+240,value.size+34)
        f.label:SetText((n.settings.text or "Reminder").."\nDrag to position • "..g.name)
        f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",value.x,value.y); f:Show()
    end end
end
