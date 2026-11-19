local _, S = ...
local I,W=S.Items,S.Widgets
local U={rows={}}; S.ItemPicker=U
function U.Close()
    if U.window then U.window:Hide() end
    if U.anchor then U.anchor:UnlockHighlight(); U.anchor=nil end
end
function U.Refresh()
    if not U.window or not U.window:IsShown() then return end
    local entries
    if U.sets then
        entries={}; for _,e in pairs(I.sets) do if e.name:lower():find(U.search:GetText():lower(),1,true) then entries[#entries+1]=e end end
        table.sort(entries,function(a,b) return a.name<b.name end)
    else entries=I.Search(U.search:GetText(),U.equippable) end
    U.message:SetText(I.reason or (#entries.." available "..(U.sets and "equipment sets" or "items - equipped gear and bags only")))
    U.content:SetHeight(math.max(1,#entries*36))
    for _,row in ipairs(U.rows) do row:Hide() end
    for index,e in ipairs(entries) do
        local row=U.rows[index]
        if not row then
            row=W.Button(U.content,"",400,0,-(index-1)*36); row:SetHeight(34)
            row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(28,28); row.icon:SetPoint("LEFT",4,0)
            row:GetFontString():SetPoint("LEFT",40,0); row:GetFontString():SetJustifyH("LEFT"); U.rows[index]=row
        end
        row:SetText(e.name); row.icon:SetTexture(e.icon)
        local color=ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[e.quality]
        row:GetFontString():SetTextColor(color and color.r or 1,color and color.g or 1,color and color.b or 1)
        row:SetScript("OnClick",function() local selected=U.selected; U.Close(); selected(e) end)
        row:SetScript("OnEnter",function()
            GameTooltip:SetOwner(row,"ANCHOR_RIGHT")
            if not U.sets and GameTooltip.SetItemByID then GameTooltip:SetItemByID(e.id) else GameTooltip:SetText(e.name) end
            GameTooltip:Show()
        end); row:SetScript("OnLeave",function() GameTooltip:Hide() end); row:Show()
    end
end
function U.Open(anchor,equippable,sets,selected)
    if U.window and U.window:IsShown() and U.anchor==anchor then U.Close(); return end
    W.CloseMenu(); S.SpellPicker.Close(); U.Close(); I.Refresh()
    if not U.window then
        local f=W.Panel(UIParent); U.window=f; f:SetSize(450,410); f:SetFrameStrata("TOOLTIP"); f:SetClampedToScreen(true)
        W.Label(f,"CHOOSE AN ITEM / EQUIPMENT SET",12,-12,"GameFontNormal"); W.Button(f,"x",24,414,-4,U.Close)
        U.search=W.Edit(f,390,20,-36,"",function() U.scroll:SetVerticalScroll(0); U.Refresh() end); U.search:SetScript("OnEscapePressed",U.Close)
        U.message=W.Label(f,"",12,-70); U.message:SetWidth(420); U.message:SetHeight(36)
        W.Button(f,"Clear selection",145,12,-108,function() local selected=U.selected; U.Close(); selected(nil) end)
        U.scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate"); U.scroll:SetPoint("TOPLEFT",12,-142); U.scroll:SetPoint("BOTTOMRIGHT",-32,12)
        U.content=CreateFrame("Frame",nil,U.scroll); U.content:SetSize(402,1); U.scroll:SetScrollChild(U.content)
        f:EnableKeyboard(true); f:SetPropagateKeyboardInput(true)
        f:SetScript("OnKeyDown",function(self,key) if key=="ESCAPE" then self:SetPropagateKeyboardInput(false); U.Close() else self:SetPropagateKeyboardInput(true) end end)
        f:SetScript("OnUpdate",function(self)
            local down=IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton")
            if down and not self.wasDown and not self:IsMouseOver() and not (U.anchor and U.anchor:IsMouseOver()) then U.Close() end
            self.wasDown=down
        end)
    end
    U.anchor=anchor; U.equippable=equippable; U.sets=sets; U.selected=selected; anchor:LockHighlight()
    U.window:ClearAllPoints(); U.window:SetPoint("TOPLEFT",anchor,"BOTTOMLEFT",0,-2); U.search:SetText(""); U.window:Show(); U.Refresh(); U.search:SetFocus()
end
function U.Field(parent,width,x,y,settings,key,kind,changed)
    local b; local equipment=kind=="equipment"; local sets=kind=="equipset"
    local function refresh()
        local e=sets and I.sets[settings[key]] or I.Resolve(settings[key])
        b:SetText(sets and (e and e.name or "Select saved set (unavailable if missing)") or I.Label(settings[key])); b.icon:SetTexture(e and e.icon or 134400)
    end
    b=W.Button(parent,"",width,x,y,function()
        U.Open(b,equipment,sets,function(e) settings[key]=e and (sets and tostring(e.id) or "item:"..e.id) or ""; refresh(); changed() end)
    end)
    W.DecorateDropdown(b); b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetSize(20,20); b.icon:SetPoint("LEFT",3,0); b:GetFontString():SetPoint("LEFT",27,0)
    b:SetScript("OnReceiveDrag",function()
        if sets then S.Editor.Message("Select a native saved equipment set from the list."); return end
        I.Refresh(); local e,why=I.Cursor(equipment)
        if e then settings[key]="item:"..e.id; if ClearCursor then ClearCursor() end; refresh(); changed() else S.Editor.Message(why) end
    end)
    b:SetScript("OnEnter",function()
        local e=sets and I.sets[settings[key]] or I.Resolve(settings[key])
        GameTooltip:SetOwner(b,"ANCHOR_RIGHT")
        if e and not sets and GameTooltip.SetItemByID then GameTooltip:SetItemByID(e.id) else GameTooltip:SetText(sets and (e and e.name or "Saved equipment set unavailable") or I.Label(settings[key])) end
        GameTooltip:AddLine(sets and "Click to choose a supported native equipment set." or "Click to search owned items; drop a bag/equipment item here.",1,1,1,true); GameTooltip:Show()
    end); b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    b.Refresh=refresh; refresh(); return b
end
