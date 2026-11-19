local _, S = ...
local W={}; S.Widgets=W
function W.DecorateDropdown(button)
    if button.chevron then return end
    button.chevron=button:CreateTexture(nil,"OVERLAY")
    button.chevron:SetSize(14,14); button.chevron:SetPoint("RIGHT",-6,0)
    button.chevron:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
    button:GetFontString():SetPoint("RIGHT",-23,0)
end
function W.CloseMenu()
    if W.menu then W.menu:Hide() end
    if W.anchor then W.anchor:UnlockHighlight(); W.anchor=nil end
end
function W.Panel(parent,r,g,b,name)
    local f=CreateFrame("Frame",name,parent,"BackdropTemplate")
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:SetBackdropColor(r or .055,g or .07,b or .095,1); f:SetBackdropBorderColor(.18,.23,.29,1)
    f:EnableMouse(false)
    return f
end
function W.Label(parent,text,x,y,font)
    local l=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
    l:SetPoint("TOPLEFT",x,y); l:SetText(text); l:SetJustifyH("LEFT"); return l
end
function W.Button(parent,text,width,x,y,fn)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(width,24); b:SetPoint("TOPLEFT",x,y); b:SetText(text); b:SetScript("OnClick",fn); return b
end
function W.ToolbarButton(parent,text,width,x,y,fn)
    local b=W.Button(parent,text,width,x,y,fn)
    b:SetFrameLevel(parent:GetFrameLevel()+1); b:EnableMouse(true)
    if b.SetHitRectInsets then b:SetHitRectInsets(0,0,0,0) end
    return b
end
function W.Edit(parent,width,x,y,text,fn)
    local e=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
    e:SetAutoFocus(false); e:SetSize(width,24); e:SetPoint("TOPLEFT",x,y); e:SetText(text or "")
    e:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    e:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
    e:SetScript("OnTextChanged",function(self,user) if user and fn then fn(self:GetText()) end end)
    return e
end
-- Small reusable dropdown, constructed only from native buttons and font strings.
function W.Choose(anchor,items,selected)
    if W.menu and W.menu:IsShown() and W.anchor==anchor then W.CloseMenu(); return end
    W.CloseMenu()
    if S.SpellPicker then S.SpellPicker.Close() end
    if S.ItemPicker then S.ItemPicker.Close() end
    W.DecorateDropdown(anchor); W.anchor=anchor; anchor:LockHighlight()
    local menu=W.menu
    if not menu then
        menu=W.Panel(UIParent,.065,.085,.12); W.menu=menu; menu.rows={}
        menu:SetFrameStrata("TOOLTIP"); menu:SetClampedToScreen(true)
        menu.scroll=CreateFrame("ScrollFrame",nil,menu,"UIPanelScrollFrameTemplate")
        menu.scroll:SetPoint("TOPLEFT",4,-4); menu.scroll:SetPoint("BOTTOMRIGHT",-28,4)
        menu.content=CreateFrame("Frame",nil,menu.scroll); menu.scroll:SetScrollChild(menu.content)
        menu:EnableKeyboard(true); menu:SetPropagateKeyboardInput(true)
        menu:SetScript("OnKeyDown",function(self,key) if key=="ESCAPE" then self:SetPropagateKeyboardInput(false); W.CloseMenu() else self:SetPropagateKeyboardInput(true) end end)
        menu:SetScript("OnUpdate",function(self)
            local down=IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton")
            if down and not self.wasDown and not self:IsMouseOver() and not (W.anchor and W.anchor:IsMouseOver()) then W.CloseMenu() end
            self.wasDown=down
        end)
    end
    menu:SetSize(260,math.min(#items,14)*25+12); menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT",anchor,"BOTTOMLEFT",0,-2); menu:SetClampedToScreen(true)
    menu.content:SetSize(226,math.max(1,#items*25)); menu.scroll:SetVerticalScroll(0)
    for _,row in ipairs(menu.rows) do row:Hide() end
    for i,item in ipairs(items) do
        local b=menu.rows[i]
        if not b then b=W.Button(menu.content,"",224,0,-(i-1)*25); menu.rows[i]=b; b:GetFontString():SetJustifyH("LEFT") end
        b:SetText(item.label); b:SetScript("OnClick",function() W.CloseMenu(); selected(item.value) end); b:Show()
    end
    menu:Show()
end
function W.Dropdown(parent,width,x,y,text,options,fn,labels)
    local b
    b=W.Button(parent,text,width,x,y,function()
        local items={}; for _,value in ipairs(options) do items[#items+1]={label=labels and labels[value] or value,value=value} end
        W.Choose(b,items,function(value) local ok=fn(value); if ok~=false then b:SetText(labels and labels[value] or value) end end)
    end)
    W.DecorateDropdown(b); return b
end
