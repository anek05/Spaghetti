local _, S = ...
local P,W=S.Spells,S.Widgets
local UI={}; S.SpellPicker=UI
function UI.Close()
    if UI.window then UI.window:Hide() end
    if UI.anchor then UI.anchor:UnlockHighlight(); UI.anchor=nil end
end
function UI.Refresh()
    if not UI.window or not UI.window:IsShown() then return end
    local entries=P.Search(UI.search:GetText(),UI.castable)
    for _,row in ipairs(UI.rows) do row:Hide() end
    UI.content:SetHeight(math.max(1,#entries*36))
    UI.message:SetText(P.reason or (#entries.." learned spells • highest verified rank by default"))
    for i,e in ipairs(entries) do
        local row=UI.rows[i]
        if not row then
            row=W.Button(UI.content,"",400,0,-(i-1)*36)
            row:SetHeight(34); row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(28,28); row.icon:SetPoint("LEFT",4,0)
            row:GetFontString():SetPoint("LEFT",38,0); row:GetFontString():SetJustifyH("LEFT"); UI.rows[i]=row
        end
        row:SetText(e.name..(e.rankText~="" and " — "..e.rankText or "")..(e.passive and " (passive)" or "")); row.icon:SetTexture(e.icon)
        row:SetScript("OnClick",function()
            local selected=UI.selected; local mode=UI.exact:GetChecked() and "exact" or "auto"
            UI.Close(); selected(e,mode)
        end); row:Show()
    end
end
function UI.Open(anchor,castable,selected,allowSpecial)
    if UI.window and UI.window:IsShown() and UI.anchor==anchor then UI.Close(); return end
    W.CloseMenu(); UI.Close()
    if S.ItemPicker then S.ItemPicker.Close() end
    if not UI.window then
        local f=W.Panel(UIParent,.05,.075,.11); UI.window=f; UI.rows={}
        f:SetSize(450,440); f:SetFrameStrata("TOOLTIP"); f:SetClampedToScreen(true); f:EnableMouse(true)
        W.Label(f,"CHOOSE A SPELL",12,-12,"GameFontNormal")
        W.Button(f,"x",24,414,-4,UI.Close)
        UI.search=W.Edit(f,390,20,-36,"",function() if UI.scroll then UI.scroll:SetVerticalScroll(0) end; UI.Refresh() end)
        UI.search:SetScript("OnEscapePressed",UI.Close)
        f:EnableKeyboard(true); f:SetPropagateKeyboardInput(true)
        f:SetScript("OnKeyDown",function(self,key)
            if key=="ESCAPE" then self:SetPropagateKeyboardInput(false); UI.Close() else self:SetPropagateKeyboardInput(true) end
        end)
        UI.exact=CreateFrame("CheckButton",nil,f,"UICheckButtonTemplate"); UI.exact:SetSize(24,24); UI.exact:SetPoint("TOPLEFT",12,-65)
        W.Label(f,"Keep this exact rank (default: follow verified highest rank)",38,-72)
        UI.auto=W.Button(f,"Associated spell",150,12,-96,function() local fn=UI.selected; UI.Close(); fn("auto") end)
        UI.none=W.Button(f,"No icon",100,168,-96,function() local fn=UI.selected; UI.Close(); fn("0") end)
        UI.clear=W.Button(f,"Clear",90,280,-96,function() local fn=UI.selected; UI.Close(); fn("") end)
        UI.message=W.Label(f,"",12,-128); UI.message:SetWidth(420); UI.message:SetHeight(32)
        UI.scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate"); UI.scroll:SetPoint("TOPLEFT",12,-166); UI.scroll:SetPoint("BOTTOMRIGHT",-32,12)
        UI.content=CreateFrame("Frame",nil,UI.scroll); UI.content:SetSize(402,1); UI.scroll:SetScrollChild(UI.content)
        f:SetScript("OnUpdate",function(self)
            local down=IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton")
            if down and not self.wasDown and not self:IsMouseOver() and not (UI.anchor and UI.anchor:IsMouseOver()) then UI.Close() end
            self.wasDown=down
        end)
    end
    UI.anchor=anchor; UI.castable=castable; UI.selected=selected
    anchor:LockHighlight(); UI.window:ClearAllPoints(); UI.window:SetPoint("TOPLEFT",anchor,"BOTTOMLEFT",0,-2)
    UI.auto:SetShown(allowSpecial); UI.none:SetShown(allowSpecial=="icon")
    UI.search:SetText(""); UI.exact:SetChecked(false); UI.window:Show(); UI.Refresh(); UI.search:SetFocus()
end
function UI.Field(parent,width,x,y,settings,key,kind,changed,graph,node)
    local b
    local castable=kind=="castspell"; local special=kind=="icon" and "icon" or key=="castSpell"
    local function refresh()
        local seed=settings[key]
        if seed=="auto" and graph and node then seed=P.Associated(graph,node.id) end
        local e=P.Resolve(seed,settings[key.."Mode"])
        b:SetText(settings[key]=="auto" and e and ("Auto • "..e.name) or P.Label(settings[key],settings[key.."Mode"])); b.icon:SetTexture(e and e.icon or 134400)
    end
    b=W.Button(parent,"",width,x,y,function()
        UI.Open(b,castable,function(e,mode)
            if type(e)=="table" then P.Select(settings,key,e,mode) else settings[key]=e; settings[key.."Mode"]="auto" end
            refresh(); changed()
        end,special)
    end)
    W.DecorateDropdown(b); b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetSize(20,20); b.icon:SetPoint("LEFT",3,0)
    b:GetFontString():SetPoint("LEFT",27,0); b:GetFontString():SetJustifyH("LEFT")
    b:SetScript("OnReceiveDrag",function()
        local e,why=P.Cursor(castable)
        if e then P.Select(settings,key,e); if ClearCursor then ClearCursor() end; refresh(); changed()
        else S.Editor.Message(why) end
    end)
    b:SetScript("OnEnter",function()
        local e=P.Resolve(settings[key],settings[key.."Mode"])
        GameTooltip:SetOwner(b,"ANCHOR_RIGHT")
        if e and GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(e.id) else GameTooltip:SetText(P.Label(settings[key],settings[key.."Mode"])) end
        GameTooltip:AddLine("Click to search; drop a learned Spellbook spell here.",1,1,1,true); GameTooltip:Show()
    end); b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    b.Refresh=refresh; refresh(); return b
end
