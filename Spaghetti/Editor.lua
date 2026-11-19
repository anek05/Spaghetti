local _, S = ...
local E={mode="reminder",drafts={},dirty={}}; S.Editor=E
local W,G=S.Widgets,S.Graph
function E.Message(text,combatOnly)
    E.combatNotice=combatOnly
    if E.notice then E.notice:SetText(text or "") end
end
function E.Changed()
    if not E.graph then return end
    E.rejection=nil
    S.db.drafts=S.db.drafts or {}; S.db.drafts[E.graph.id]=S.Copy(E.graph)
    E.dirty[E.graph.id]=true; E.UpdateStatus()
    if S.Canvas then S.Canvas.RefreshSpells() end
end
function E.Reject(detail)
    E.rejection=detail; E.Message(detail.message); E.UpdateStatus()
end
function E.Close()
    W.CloseMenu(); S.SpellPicker.Close(); S.ItemPicker.Close(); S.Canvas.Cancel()
    if E.window then E.window:Hide() end
end
function E.StoreWindow()
    if not E.window or not S.db then return end
    local f=E.window; local x,y=f:GetCenter(); local px,py=UIParent:GetCenter()
    local factor=f:GetEffectiveScale()/UIParent:GetEffectiveScale()
    S.db.editorWindow={x=x*factor-px,y=y*factor-py,width=f:GetWidth(),height=f:GetHeight()}
end
function E.ImportLegacy()
    local profile,why=S.Profiles.Import(S.db,S.legacySource,true)
    if not profile then E.Message(why); return end
    SpaghettiCharDB=profile; S.db=profile; E.drafts=S.Copy(profile.drafts); E.dirty={}; E.graph=nil
    for id in pairs(E.drafts) do E.dirty[id]=true end
    S.Engine.Reload()
    local id=profile.selected or S.SortedKeys(profile.graphs)[1]
    if id then E.Select(id) else E.New() end
    E.Message("Imported an independent copy. All imported reminder graphs and outputs are disabled; review before Apply.")
end
local function nameList(mode)
    local list={}
    for _,id in ipairs(S.SortedKeys(S.db.graphs)) do
        local g=E.drafts[id] or S.db.graphs[id]
        if g.mode==mode then list[#list+1]={label=g.name,value=id} end
    end
    return list
end
function E.Select(id)
    local saved=S.db.graphs[id]; if not saved then return end
    E.graph=E.drafts[id] or S.Copy(saved); E.drafts[id]=E.graph
    E.mode=E.graph.mode; S.db.selected=id
    E.rejection=nil
    E.name:SetText(E.graph.name); E.macroName:SetText(S.MacroIntegration.Name(E.graph)); E.scope:SetChecked(E.graph.perCharacter)
    E.graphButton:SetText(E.graph.name); E.modeButton:SetText(E.mode=="macro" and "Macro" or "Reminder / CD")
    E.BuildLibrary(); S.Canvas.Cancel(); S.Canvas.Render(); E.UpdateStatus(); E.Message("Changes persist with Save. Apply saves and activates reminders, or creates a native macro.")
    S.Canvas.SetZoom(E.graph.zoom or 1,nil,nil,true); S.Canvas.RefreshSpells()
end
function E.Switch(mode)
    E.mode=mode
    local list=nameList(mode)
    if #list==0 then E.New() else E.Select(list[1].value) end
end
function E.New()
    local id
    repeat S.db.serial=(S.db.serial or 3)+1; id="g"..S.db.serial until not S.db.graphs[id]
    local g=G.New(id,"Untitled "..S.db.serial,E.mode); S.Save(g); E.Select(id); E.Changed()
end
function E.Save()
    if not E.graph then return end
    if not E.graph.name:find("%S") then E.Message("Give this graph a name before saving."); return end
    S.Save(E.graph); E.dirty[E.graph.id]=nil
    -- Saving an enabled reminder also updates its runtime snapshot, provided validation passes.
    S.Engine.Reload(); E.UpdateStatus(); E.Message("Saved. WoW writes SavedVariables on /reload or normal logout.")
end
function E.Preview()
    if E.graph.mode=="macro" then
        E.preview:SetFocus(); E.preview:HighlightText(); E.Message("Generated macro selected. Ctrl+C copies it.")
        return
    end
    local count=0
    local errors=G.Validate(E.graph)
    if #errors>0 then E.Message("Fix validation errors before previewing. Unsupported combat warnings do not block preview."); return end
    for id,n in pairs(E.graph.nodes) do
        if n.type=="show" and n.settings.enabled then
            local settings=S.Spells.ReminderSettings(E.graph,n); settings.layoutKey=E.graph.id..":"..id
            S.Display.Show("preview:"..E.graph.id..":"..id,settings,5,true); count=count+1
        end
    end
    E.Message(count>0 and "PREVIEW only • visuals shown for 5 seconds, independent of graph conditions." or "Add and enable a Show Reminder node to preview.")
end
function E.Apply()
    local g=E.graph
    if g.mode=="reminder" then
        local errors=G.Validate(g)
        if #errors>0 then E.Message("Fix the validation errors before applying. You can still save the graph."); return end
        g.enabled=true; g.applied=true; E.Save(); E.Message("Applied. Check Active Reminders: secret/unavailable buff conditions are Unsupported / unknown, never Missing.")
    else
        local body,errors=S.Macro.Compile(g)
        if not body then E.Message(table.concat(errors," ")); return end
        local index,reason,plan=S.MacroIntegration.Apply(g,body)
        if index then E.Save(); E.Message("Native macro verified. Drag its Macro Action icon directly to your action bar.")
        elseif reason=="CONFIRM" then
            local snapshot=S.Copy(g)
            StaticPopup_Show("SPAGHETTI_REPLACE",plan.oldName or plan.name,plan.name,{graph=snapshot,body=body,plan=plan})
        else E.Message(reason,S.inCombat or InCombatLockdown and InCombatLockdown()); E.UpdateStatus() end
    end
end
function E.FinishReplacement(snapshot)
    local current=E.drafts[snapshot.id]
    local same=current and S.MacroIntegration.Name(current)==S.MacroIntegration.Name(snapshot) and current.perCharacter==snapshot.perCharacter and S.Macro.Compile(current)==S.Macro.Compile(snapshot)
    if same then
        current.nativeMacro=S.Copy(snapshot.nativeMacro); S.Save(current); E.dirty[current.id]=nil
    else
        local saved=S.db.graphs[snapshot.id]
        if saved then saved.nativeMacro=S.Copy(snapshot.nativeMacro) end
        if current then current.nativeMacro=S.Copy(snapshot.nativeMacro); S.db.drafts[current.id]=S.Copy(current) end
    end
    E.UpdateStatus(); E.Message("Native macro name/body verified. Current graph edits were preserved; check Macro Action status before dragging.")
end
function E.UpdateStatus()
    local g=E.graph; if not g or not E.validation then return end
    if E.combatNotice and not S.inCombat and not (InCombatLockdown and InCombatLockdown()) then E.Message("") end
    local errors,warnings,body
    if g.mode=="macro" then body,errors,warnings=S.Macro.Compile(g) else errors,warnings=G.Validate(g) end
    local messages={}
    for _,s in ipairs(errors) do messages[#messages+1]="ERROR: "..s end
    for _,s in ipairs(warnings) do messages[#messages+1]="LIMIT: "..s end
    if E.rejection then table.insert(messages,1,E.rejection.message) end
    E.feedback=S.Validation.Report(g,errors,warnings,E.rejection)
    if S.Canvas.frame then S.Canvas.ApplyFeedback(E.feedback) end
    for _,s in ipairs(g.migrationWarnings or {}) do messages[#messages+1]="MIGRATION: "..s end
    if #errors==0 then messages[#messages+1]="Graph valid"..(g.mode=="reminder" and (g.enabled and " • enabled (see runtime status)" or " • disabled / not applied") or " • generated from connected nodes") end
    if g.mode=="reminder" and g.enabled then messages[#messages+1]="Live saved graph:\n"..(S.Engine.status[g.id] or "Waiting for evaluation.") end
    if E.dirty[g.id] then messages[#messages+1]="Unsaved changes. Active reminders use the last saved version." end
    E.validation:SetText(table.concat(messages,"\n"))
    E.validationContent:SetHeight(math.max(180,E.validation:GetStringHeight()+10))
    E.previewBody=body or ""; E.preview:SetText(body or "Fix the errors to generate macro text.")
    local _,characters=(body or ""):gsub("[^\128-\191]","")
    E.count:SetText("Generated macro • "..characters.." characters / "..#(body or "").." bytes (255-byte limit)")
    E.macroPanel:SetShown(g.mode=="macro"); E.reminderPanel:SetShown(g.mode=="reminder")
    local nativeStatus=g.mode=="macro" and S.MacroIntegration.Status(g,body)
    E.apply:SetText(g.mode=="macro" and (nativeStatus.state=="Not created" or nativeStatus.state=="Missing") and "Create macro" or g.mode=="macro" and "Update macro" or "Apply reminder")
    local nativeNameError
    if g.mode=="macro" then
        local name=S.MacroIntegration.Name(g)
        nativeNameError=S.MacroIntegration.NameError(name)
        if nativeNameError then messages[#messages+1]="MACRO NAME: "..nativeNameError; E.validation:SetText(table.concat(messages,"\n")) end
        if g.legacyMacroName=="Spaghetti" and not g.macroNameCustom then messages[#messages+1]="Legacy macro name 'Spaghetti' retained. The native name now follows the graph; edit Macro name to customize it."; E.validation:SetText(table.concat(messages,"\n")) end
        E.UpdateMacroAction(nativeStatus,name)
    end
    if g.mode=="macro" and (S.inCombat or InCombatLockdown and InCombatLockdown()) then E.apply:Disable(); messages[#messages+1]="Macro creation blocked during combat lockdown."; E.validation:SetText(table.concat(messages,"\n"))
    else E.apply:SetEnabled(#errors==0 and not nativeNameError) end
    E.graphButton:SetText(g.name..(E.dirty[g.id] and " *" or ""))
    E.UpdateOverview()
    if E.importButton then E.importButton:SetShown(S.db.importStatus=="pending" or S.db.importStatus=="declined") end
    E.validationContent:SetHeight(math.max(180,E.validation:GetStringHeight()+10))
end
function E.UpdateMacroAction(status,name)
    if not E.macroAction then return end
    local locked=S.inCombat or InCombatLockdown and InCombatLockdown()
    local ready=status.ready and not locked and PickupMacro~=nil
    E.macroAction.icon:SetTexture(status.record and status.record.icon or 134400)
    E.macroAction:SetEnabled(ready); E.macroAction:EnableMouse(ready)
    E.macroActionName:SetText(status.record and ("Native: "..status.record.name..(status.record.name~=name and " | Intended: "..name or "")) or name)
    E.macroActionState:SetText(status.state..(locked and " - dragging blocked in combat" or ready and " - drag icon to your action bar" or not PickupMacro and " - PickupMacro is unavailable" or " - "..(status.reason or "")))
end
function E.UpdateOverview() if S.Overview then S.Overview.Update() end end
function E.BuildLibrary()
    for _,b in ipairs(E.libraryButtons or {}) do b:Hide() end
    E.libraryButtons=E.libraryButtons or {}
    local entries={}
    for id,d in pairs(S.Registry) do if d.mode==E.mode and not d.hidden and (not d.available or d.available()) then entries[#entries+1]=id end end
    table.sort(entries,function(a,b) return S.Registry[a].title<S.Registry[b].title end)
    for i,id in ipairs(entries) do
        local b=E.libraryButtons[i]
        if not b then b=W.Button(E.libraryContent,"",134,4,-(i-1)*29); E.libraryButtons[i]=b end
        b:SetNormalFontObject("GameFontHighlightSmall")
        b:SetHighlightFontObject("GameFontNormalSmall")
        b:SetDisabledFontObject("GameFontDisableSmall")
        b:SetText("+ "..S.Registry[id].title); b:Show()
        b:SetScript("OnClick",function()
            S.Canvas.Add(id)
        end)
    end
    E.libraryContent:SetHeight(math.max(1,#entries*29))
end
function E.Build()
    StaticPopupDialogs.SPAGHETTI_IMPORT={text="Import a COPY of old account-wide Spaghetti graphs into THIS character?\nAll imported reminders will be disabled. Original account data remains unchanged.",button1="Import copy",button2="Keep separate",timeout=0,whileDead=true,hideOnEscape=false,
        OnAccept=function() E.ImportLegacy() end,
        OnCancel=function() S.Profiles.Decline(S.db); E.UpdateStatus() end}
    StaticPopupDialogs.SPAGHETTI_REPLACE={text="Update native macro \"%s\" to \"%s\" using the reviewed generated text?\nExisting native edits will be replaced.",button1="Update",button2="Cancel",timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3,
        OnAccept=function(_,data)
            local index,reason=S.MacroIntegration.Apply(data.graph,data.body,data.plan)
            if index then E.FinishReplacement(data.graph)
            else E.Message(reason=="CONFIRM" and "Macro changed since confirmation. Review and try again." or reason,S.inCombat or InCombatLockdown and InCombatLockdown()); E.UpdateStatus() end
        end}
    StaticPopupDialogs.SPAGHETTI_DELETE={text="Delete graph \"%s\"? Its active reminders will stop.",button1="Delete",button2="Cancel",timeout=0,whileDead=true,hideOnEscape=true,
        OnAccept=function(_,id)
            S.db.graphs[id]=nil; E.drafts[id]=nil; S.db.drafts[id]=nil; E.dirty[id]=nil; S.Engine.Reload()
            local list=nameList(E.mode); if #list>0 then E.Select(list[1].value) else E.New() end
        end}
    local f=W.Panel(UIParent,.04,.052,.075,"SpaghettiEditorFrame"); E.window=f
    f:SetSize(1200,800); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG"); f:SetClampedToScreen(true)
    f:SetScale(math.min(1,(UIParent:GetWidth()-30)/1200,(UIParent:GetHeight()-30)/800))
    if S.db.editorWindow then
        local v=S.db.editorWindow
        f:SetSize(v.width,v.height); f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",v.x,v.y)
    end
    f:SetMovable(true); f:EnableMouse(true); f:SetResizable(true)
    if f.SetResizeBounds then f:SetResizeBounds(1160,740,1900,1300) end
    local title=CreateFrame("Frame",nil,f); E.titleDrag=title
    title:SetPoint("TOPLEFT",4,-4); title:SetSize(560,30); title:SetFrameLevel(f:GetFrameLevel()+1); title:EnableMouse(true); title:RegisterForDrag("LeftButton")
    title:SetScript("OnDragStart",function() f:StartMoving() end); title:SetScript("OnDragStop",function() f:StopMovingOrSizing(); E.StoreWindow() end)
    W.Label(title,"S P A G H E T T I   /   visual programming",16,-11,"GameFontNormalLarge")
    local controls=CreateFrame("Frame",nil,f); E.controls=controls; f.controls=controls
    controls:SetPoint("TOPLEFT",0,0); controls:SetPoint("TOPRIGHT",0,0); controls:SetHeight(104)
    controls:SetFrameLevel(f:GetFrameLevel()+20); controls:EnableMouse(false)
    local close=W.ToolbarButton(controls,"X",28,0,0,E.Close); E.closeButton=close; close:ClearAllPoints(); close:SetPoint("TOPRIGHT",-4,-4)
    UISpecialFrames=UISpecialFrames or {}; table.insert(UISpecialFrames,"SpaghettiEditorFrame")
    f:SetScript("OnHide",function() S.Canvas.Cancel(); W.CloseMenu(); S.SpellPicker.Close(); S.ItemPicker.Close() end)
    E.importButton=W.ToolbarButton(controls,"Import account data",155,600,-7,function() StaticPopup_Show("SPAGHETTI_IMPORT") end)
    E.templatesButton=W.ToolbarButton(controls,"Examples",90,775,-7,function()
        W.Choose(E.templatesButton,{{label="Combat event demo",value="g2"},{label="Warrior buff capability test",value="g1"},{label="Warrior modifier macro",value="g3"}},function(key)
            local g=S.Examples()[key]; local id
            repeat S.db.serial=(S.db.serial or 0)+1; id="g"..S.db.serial until not S.db.graphs[id]
            g.id=id; S.Save(g); E.Select(id)
        end)
    end)
    W.DecorateDropdown(E.templatesButton)
    E.modeButton=W.ToolbarButton(controls,"Reminder / CD",140,15,-43,function()
        W.Choose(E.modeButton,{{label="Reminder / CD",value="reminder"},{label="Macro",value="macro"}},E.Switch)
    end)
    E.graphButton=W.ToolbarButton(controls,"Select graph",280,164,-43,function() W.Choose(E.graphButton,nameList(E.mode),E.Select) end)
    W.DecorateDropdown(E.modeButton); W.DecorateDropdown(E.graphButton)
    W.ToolbarButton(controls,"New",60,452,-43,E.New)
    W.ToolbarButton(controls,"Delete",65,520,-43,function() StaticPopup_Show("SPAGHETTI_DELETE",E.graph.name,nil,E.graph.id) end)
    W.ToolbarButton(controls,"Save",70,593,-43,E.Save)
    W.ToolbarButton(controls,"Test / Preview",120,671,-43,E.Preview)
    E.apply=W.ToolbarButton(controls,"Apply reminder",135,799,-43,E.Apply)
    W.Label(controls,"Graph name",18,-81); E.name=W.Edit(controls,370,102,-73,"",function(text)
        if E.graph then E.graph.name=text; if not E.graph.macroNameCustom then E.macroName:SetText(S.MacroIntegration.Name(E.graph)) end; E.Changed() end
    end)
    E.notice=W.Label(controls,"",489,-81); E.notice:SetPoint("TOPRIGHT",controls,"TOPRIGHT",-24,-81); E.notice:SetHeight(26); E.notice:SetTextColor(.6,.8,.9)
    E.library=W.Panel(f); E.library:SetPoint("TOPLEFT",8,-107); E.library:SetPoint("BOTTOMLEFT",8,239); E.library:SetWidth(166)
    W.Label(E.library,"NODE LIBRARY",10,-12,"GameFontNormal")
    local libraryScroll=CreateFrame("ScrollFrame",nil,E.library,"UIPanelScrollFrameTemplate"); libraryScroll:SetPoint("TOPLEFT",0,-32); libraryScroll:SetPoint("BOTTOMRIGHT",-24,4)
    E.libraryContent=CreateFrame("Frame",nil,libraryScroll); E.libraryContent:SetSize(138,1); libraryScroll:SetScrollChild(E.libraryContent)
    S.Canvas.Build(f)
    local bottom=W.Panel(f); bottom:SetPoint("BOTTOMLEFT",8,8); bottom:SetPoint("BOTTOMRIGHT",-8,8); bottom:SetHeight(224)
    W.Label(bottom,"VALIDATION / LIVE STATUS",12,-12,"GameFontNormal")
    local vs=CreateFrame("ScrollFrame",nil,bottom,"UIPanelScrollFrameTemplate"); vs:SetPoint("TOPLEFT",12,-34); vs:SetPoint("BOTTOMLEFT",12,12); vs:SetWidth(430)
    local vc=CreateFrame("Frame",nil,vs); vc:SetSize(425,400); vs:SetScrollChild(vc)
    E.validation=W.Label(vc,"",0,0); E.validation:SetWidth(420); E.validation:SetSpacing(3)
    E.validationContent=vc
    E.macroPanel=CreateFrame("Frame",nil,bottom); E.macroPanel:SetPoint("TOPLEFT",480,-8); E.macroPanel:SetPoint("BOTTOMRIGHT",-12,8)
    E.count=W.Label(E.macroPanel,"Generated macro",0,-4,"GameFontNormal")
    W.Label(E.macroPanel,"Macro name",0,-33); E.macroName=W.Edit(E.macroPanel,170,90,-25,"",function(text) E.graph.macroName=text; E.graph.macroNameCustom=true; E.Changed() end)
    W.Button(E.macroPanel,"Use graph name",120,275,-25,function() E.graph.macroNameCustom=false; E.macroName:SetText(S.MacroIntegration.Name(E.graph)); E.Changed() end)
    E.scope=CreateFrame("CheckButton",nil,E.macroPanel,"UICheckButtonTemplate"); E.scope:SetPoint("TOPLEFT",414,-24); E.scope:SetSize(24,24)
    W.Label(E.macroPanel,"Character-specific",439,-32); E.scope:SetScript("OnClick",function(self) E.graph.perCharacter=self:GetChecked()==true; E.Changed() end)
    local ps=CreateFrame("ScrollFrame",nil,E.macroPanel,"UIPanelScrollFrameTemplate"); ps:SetPoint("TOPLEFT",4,-60); ps:SetPoint("BOTTOMRIGHT",-28,91)
    E.preview=CreateFrame("EditBox",nil,ps); E.preview:SetMultiLine(true); E.preview:SetAutoFocus(false); E.preview:SetFontObject("ChatFontNormal"); E.preview:SetSize(600,180); ps:SetScrollChild(E.preview)
    E.preview:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    E.preview:SetScript("OnTextChanged",function(self,user) if user then self:SetText(E.previewBody or ""); self:HighlightText() end end)
    ps:SetScript("OnSizeChanged",function(self) E.preview:SetWidth(math.max(100,self:GetWidth()-8)) end)
    W.Label(E.macroPanel,"Macro Action",0,-132,"GameFontNormal")
    E.macroAction=CreateFrame("Button",nil,E.macroPanel); E.macroAction:SetSize(36,36); E.macroAction:SetPoint("TOPLEFT",0,-155); E.macroAction:RegisterForDrag("LeftButton")
    E.macroAction.icon=E.macroAction:CreateTexture(nil,"ARTWORK"); E.macroAction.icon:SetAllPoints(); E.macroAction.icon:SetTexture(134400)
    E.macroActionName=W.Label(E.macroPanel,"",44,-154); E.macroActionName:SetWidth(540)
    E.macroActionState=W.Label(E.macroPanel,"",44,-174); E.macroActionState:SetWidth(540); E.macroActionState:SetHeight(38)
    E.macroAction:SetScript("OnDragStart",function()
        local body,errors=S.Macro.Compile(E.graph)
        if not body then E.Message(table.concat(errors," ")); return end
        local index,reason=S.MacroIntegration.Pickup(E.graph,body)
        if not index then E.Message(reason,S.inCombat or InCombatLockdown and InCombatLockdown()) else E.Message("Native macro on cursor. Drop it on your action bar.") end
        E.UpdateStatus()
    end)
    E.macroAction:SetScript("OnEnter",function()
        GameTooltip:SetOwner(E.macroAction,"ANCHOR_RIGHT"); GameTooltip:SetText("Macro Action")
        GameTooltip:AddLine("Only a verified native macro can be dragged. Select/preview/click does not pick up or execute anything. Dragging is blocked in combat.",1,1,1,true); GameTooltip:Show()
    end); E.macroAction:SetScript("OnLeave",function() GameTooltip:Hide() end)
    E.reminderPanel=CreateFrame("Frame",nil,bottom); E.reminderPanel:SetPoint("TOPLEFT",480,-16); E.reminderPanel:SetPoint("BOTTOMRIGHT",-12,12)
    S.Overview.Build(E.reminderPanel)
    local resize=W.Button(f,"/",20,0,0)
    resize:ClearAllPoints(); resize:SetPoint("BOTTOMRIGHT",0,0)
    resize:SetScript("OnMouseDown",function() f:StartSizing("BOTTOMRIGHT") end)
    resize:SetScript("OnMouseUp",function() f:StopMovingOrSizing(); E.StoreWindow(); S.Canvas.Draw() end)
    f:Show()
    E.Select(S.db.selected and S.db.graphs[S.db.selected] and S.db.selected or S.SortedKeys(S.db.graphs)[1])
    if not E.graph then E.New() end
    if S.db.importStatus=="pending" then StaticPopup_Show("SPAGHETTI_IMPORT") end
end
function E.Toggle()
    if not E.window then E.Build() else
        local show=not E.window:IsShown(); E.window:SetShown(show)
        if show then E.UpdateStatus() end
    end
end
