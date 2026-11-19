-- Strict, intentionally incomplete WoW widget double. This tests callback wiring,
-- not real-client rendering, native widget behavior, or protected API enforcement.
local O={}; O.__index=O
local combat=false
local made={}; local function object(kind,parent)
    local o=setmetatable({kind=kind,parent=parent,scripts={},shown=true,w=200,h=24,x=0,y=0,text="",value=0,lo=0,hi=1},O)
    made[#made+1]=o; return o
end
local noop={"SetBackdrop","SetBackdropColor","SetBackdropBorderColor","SetFrameStrata","SetClampedToScreen","SetScale","SetMovable","EnableMouse","SetResizable","SetResizeBounds","RegisterForDrag","SetAutoFocus","SetFontObject","SetMultiLine","SetJustifyH","SetTextColor","SetSpacing","SetColorTexture","SetTexture","SetVertexColor","SetAllPoints","SetThickness","SetStartPoint","SetEndPoint","RegisterForClicks","EnableKeyboard","SetPropagateKeyboardInput","SetOrientation","SetValueStep","SetObeyStepOnDrag","EnableMouseWheel","SetFocus","ClearFocus","HighlightText","StartMoving","StopMovingOrSizing","StartSizing","RegisterEvent","AddLine","SetOwner","SetHighlightTexture","LockHighlight","UnlockHighlight","SetSpellByID"}
for _,k in ipairs(noop) do O[k]=function() end end
function O:SetScript(name,fn) assert(self.kind~="FontString" and self.kind~="Texture" and self.kind~="Line","Regions do not support frame scripts"); self.scripts[name]=fn end
function O:GetScript(name) return self.scripts[name] end
function O:CreateTexture() return object("Texture",self) end
function O:CreateFontString() return object("FontString",self) end
function O:CreateLine() return object("Line",self) end
function O:SetSize(w,h) self.w=w; self.h=h; if self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self,w,h) end end
function O:SetWidth(w) self.w=w end
function O:SetHeight(h) self.h=h end
function O:GetWidth() return self.w end
function O:GetHeight() return self.h end
function O:GetStringHeight() return math.max(14,select(2,self.text:gsub("\n",""))*14+14) end
function O:SetPoint(point,a,b,c,d)
    self.points=self.points or {}
    local rel,other,x,y=self.parent,point,0,0
    if type(a)=="number" then x,y=a,b or 0
    elseif type(a)=="table" then rel=a; if type(b)=="string" then other,x,y=b,c or 0,d or 0 else x,y=b or 0,c or 0 end end
    self.points[#self.points+1]={point=point,relative=rel,other=other,x=x,y=y}
    if type(a)=="number" then self.x=a; self.y=b or 0 else self.x=c or 0; self.y=d or 0 end
end
function O:ClearAllPoints() self.points={} end
function O:GetLeft() return (self.parent and self.parent:GetLeft() or 0)+self.x end
function O:GetTop() return (self.parent and self.parent:GetTop() or 1000)+self.y end
function O:GetCenter() return self:GetLeft()+self.w/2,self:GetTop()-self.h/2 end
function O:GetEffectiveScale() return 1 end
function O:SetParent(parent) self.parent=parent end
function O:SetText(text) self.text=text; if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self,false) end end
function O:GetText() return self.text end
function O:GetFontString() self.font=self.font or object("FontString",self); return self.font end
function O:SetNormalFontObject(font) self.normalFont=font end
function O:SetHighlightFontObject(font) self.highlightFont=font end
function O:SetDisabledFontObject(font) self.disabledFont=font end
function O:SetShown(value) self.shown=value end
function O:Show() self.shown=true end
function O:Hide() self.shown=false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
function O:IsShown() return self.shown end
function O:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function O:SetChecked(value) self.checked=value end
function O:GetChecked() return self.checked end
function O:SetEnabled(value) self.enabled=value end
function O:Enable() self.enabled=true end
function O:Disable() self.enabled=false end
function O:SetScrollChild(child) self.child=child end
function O:SetVerticalScroll(value) self.vertical=value end
function O:SetHorizontalScroll(value) self.horizontal=value end
function O:GetVerticalScroll() return self.vertical or 0 end
function O:GetHorizontalScroll() return self.horizontal or 0 end
function O:SetThumbTexture() self.thumb=object("Texture",self) end
function O:GetThumbTexture() return self.thumb end
function O:SetMinMaxValues(lo,hi) self.lo=lo; self.hi=hi end
function O:GetMinMaxValues() return self.lo,self.hi end
function O:GetValue() return self.value end
function O:SetValue(value) self.value=value; if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,value) end end
function O:IsMouseOver() return self.hover or false end
function O:SetAttribute(key,value) assert(not combat,"protected attributes changed during combat"); self.attributes=self.attributes or {}; self.attributes[key]=value end
function O:SetScale(value) self.scale=value end
function O:GetEffectiveScale() return (self.scale or 1)*(self.parent and self.parent:GetEffectiveScale() or 1) end
function O:LockHighlight() self.expanded=true end
function O:UnlockHighlight() self.expanded=false end
function O:SetColorTexture(r,g,b,a) self.color={r,g,b,a} end
function O:EnableMouse(value) self.mouse=value end
function O:GetFrameStrata() return self.strata or (self.parent and self.parent:GetFrameStrata() or "MEDIUM") end
function O:SetFrameStrata(value) self.strata=value end
function O:GetFrameLevel() return self.level or ((self.parent and self.parent:GetFrameLevel() or 0)+1) end
function O:SetFrameLevel(level) self.level=level end
function O:SetHitRectInsets(...) self.hitInsets={...} end
for _,method in ipairs({"Show","Hide","SetSize","SetPoint","ClearAllPoints","SetFrameStrata"}) do
    local original=O[method]
    O[method]=function(self,...)
        assert(not (self.secure and combat),"addon changed a protected frame during combat: "..method)
        return original(self,...)
    end
end
CreateFrame=function(kind,name,parent,template) local o=object(kind,parent); o.secure=template and template:find("SecureActionButtonTemplate",1,true); if o.secure then assert(not combat,"secure frame created during combat") end; if name then _G[name]=o end; return o end
RegisterStateDriver=function(button,state,condition) assert(not combat); button.driver={state=state,condition=condition} end
UIParent=object("Frame"); UIParent:SetSize(1920,1080)
GameTooltip=object("Frame")
DEFAULT_CHAT_FRAME={AddMessage=function() end}
StaticPopupDialogs={}; local popups={}; StaticPopup_Show=function(which,a,b,data) local p={which=which,data=data}; popups[#popups+1]=p; return p end
SlashCmdList={}; C_Timer={After=function(seconds,fn) end}
InCombatLockdown=function() return combat end
Enum={SpellBookSpellBank={Player=0},SpellBookItemType={Spell=1}}
local bookEntries={
 {spellID=6673,itemType=1,name="Battle Shout",subName="Rank 1",isPassive=false,iconID=1},
 {spellID=5242,itemType=1,name="Battle Shout",subName="Rank 2",isPassive=false,iconID=2},
 {spellID=100,itemType=1,name="Charge",subName="",isPassive=false,iconID=3}
}
C_SpellBook={
 GetNumSpellBookSkillLines=function() return 1 end,
 GetSpellBookSkillLineInfo=function() return {name="Warrior",itemIndexOffset=0,numSpellBookItems=#bookEntries} end,
 GetSpellBookItemInfo=function(slot) return bookEntries[slot] end,
 GetSpellBookItemName=function(slot) local e=bookEntries[slot]; return e.name,e.subName end,
 IsSpellBookItemLowRank=function(slot) return slot==1 end,
 IsSpellKnown=function() return true end
}
IsShiftKeyDown=function() return false end
IsMouseButtonDown=function() return false end
GetCursorPosition=function() return 500,500 end
issecretvalue=function() return false end
C_Spell={GetSpellTexture=function() return 134400 end,GetSpellName=function() return "Battle Shout" end}
C_UnitAuras={GetPlayerAuraBySpellID=function() return nil end}
local S={}
local order={}
for line in io.lines("Spaghetti/Spaghetti.toc") do if line:match("%.lua$") then order[#order+1]=line:gsub("%.lua$", "") end end
for _,name in ipairs(order) do assert(loadfile("Spaghetti/"..name..".lua"))("Spaghetti",S) end
local events=made[#made]; assert(events.scripts.OnEvent)
events.scripts.OnEvent(events,"ADDON_LOADED","Spaghetti")
assert(S.db and SlashCmdList.SPAGHETTI)
S.db.graphs=S.Examples(); S.db.selected="g2"; S.db.serial=3
SlashCmdList.SPAGHETTI(); assert(S.Editor.window:IsShown())
local E,C=S.Editor,S.Canvas
assert(E.graph.id=="g2" and C.nodes.n1 and C.nodes.n2)
E.Preview(); assert(S.Display.frames["preview:g2:n2"]:IsShown())
E.Apply(); assert(S.db.graphs.g2.enabled and S.Engine.graphs.g2)
combat=true; events.scripts.OnEvent(events,"PLAYER_REGEN_DISABLED")
assert(S.Display.frames["g2:n2"]:IsShown())
E.Select("g3"); assert(E.previewBody=="#showtooltip\n/cast [mod:shift] Battle Shout; Charge")
assert(E.apply.enabled==false,"combat create button disabled")
combat=false; events.scripts.OnEvent(events,"PLAYER_REGEN_ENABLED"); assert(E.apply.enabled)
E.Select("g1")
local p=C.nodes.n2.ports["out:value"]; local q=C.nodes.n3.ports["in:gate"]
q.scripts.OnMouseUp(q,"RightButton"); assert(not S.Graph.Incoming(E.graph,"n3","gate"))
p.scripts.OnMouseDown(p,"LeftButton"); q.scripts.OnMouseUp(q,"LeftButton")
assert(S.Graph.Incoming(E.graph,"n3","gate"),"port callbacks connect real model edges")
local frame=C.nodes.n2
-- Title is a child button with drag callbacks.
local dragged=false
for _,o in ipairs(made) do if o.parent==frame and o.scripts.OnDragStart then o.scripts.OnDragStart(o); o.scripts.OnDragStop(o); dragged=true; break end end
assert(dragged and E.dirty.g1)
E.Save(); assert(S.db.graphs.g1.nodes.n2.x~=nil and not E.dirty.g1)
E.New(); assert(next(E.graph.nodes)==nil)
for _,b in ipairs(E.libraryButtons) do if b.text=="+ Combat State" then b.scripts.OnClick(b) end end
for _,b in ipairs(E.libraryButtons) do if b.text=="+ Show Reminder" then b.scripts.OnClick(b) end end
assert(E.graph.nodes.n1 and E.graph.nodes.n2)
E.graph.nodes.n2.settings.text="Test reminder"
assert(S.Graph.ChangeCombatState(E.graph,E.graph.nodes.n1,"Enter Combat")); C.Render()
C.nodes.n1.ports["out:next"].scripts.OnMouseDown(C.nodes.n1.ports["out:next"],"LeftButton")
C.nodes.n2.ports["in:run"].scripts.OnMouseUp(C.nodes.n2.ports["in:run"],"LeftButton")
E.Apply(); assert(S.Engine.graphs[E.graph.id])
local id=E.graph.id; StaticPopupDialogs.SPAGHETTI_DELETE.OnAccept(nil,id); assert(not S.db.graphs[id])
-- Dropdown toggle, expanded state, option clicks and Escape dismissal.
E.modeButton.scripts.OnClick(E.modeButton); assert(S.Widgets.menu:IsShown() and E.modeButton.expanded)
E.modeButton.scripts.OnClick(E.modeButton); assert(not S.Widgets.menu:IsShown() and not E.modeButton.expanded)
E.modeButton.scripts.OnClick(E.modeButton); S.Widgets.menu.scripts.OnKeyDown(S.Widgets.menu,"ESCAPE"); assert(not S.Widgets.menu:IsShown())
-- Picker field opens searchable icon/name/rank rows, then changes the graph setting.
E.Select("g1")
local field=C.nodes.n3.spellFields[1]; field.scripts.OnClick(field)
local picker=S.SpellPicker; assert(picker.window:IsShown() and #picker.rows>=3)
picker.search.text="charge"; picker.search.scripts.OnTextChanged(picker.search,true)
assert(picker.rows[1].text=="Charge" and not picker.rows[2]:IsShown())
picker.rows[1].scripts.OnClick(picker.rows[1]); assert(E.graph.nodes.n3.settings.spell=="100" and not picker.window:IsShown())
GetCursorInfo=function() return "spell",1,0,6673 end
field.scripts.OnReceiveDrag(field); assert(E.graph.nodes.n3.settings.spell=="6673")
-- Zoom scales the shared graph parent, retains model coordinates and saves per graph.
local x,y=E.graph.nodes.n3.x,E.graph.nodes.n3.y
C.SetZoom(.5); assert(C.frame.scale==.5 and C.host:GetWidth()==850 and E.graph.zoom==.5)
assert(E.graph.nodes.n3.x==x and E.graph.nodes.n3.y==y and C.nodes.n3.parent==C.frame)
E.Save(); E.Select("g3"); E.Select("g1"); assert(E.graph.zoom==.5 and C.zoom==.5)
-- Placement preview changes layout without rewriting graph settings or conditions.
local before=S.Copy(E.graph.nodes.n4.settings)
S.Layout.Open(); assert(S.Layout.active and not E.window:IsShown() and S.Layout.handles["g1:n4"]:IsShown())
S.Layout.pending["g1:n4"]={x=80,y=95,size=64}; S.Layout.Save()
assert(S.db.layouts["g1:n4"].x==80 and E.window:IsShown() and not S.Layout.active)
assert(E.graph.nodes.n4.settings.text==before.text and E.graph.nodes.n4.settings.spell==before.spell)
-- Separate secure layer: configuration only OOC, secure state driver hides on combat entry.
local settings=S.Spells.ReminderSettings(E.graph,E.graph.nodes.n4); settings.enabled=true; settings.clickable=true; settings.castEntry=S.Spells.byID[5242]
S.Display.Show("click-test",settings)
local secure=S.SecureClicks.buttons["click-test"]
assert(secure and secure.parent==UIParent and secure.parent~=S.Display.frames["click-test"] and secure.driver)
assert(secure.attributes.type1=="spell" and secure.attributes.spell1=="Battle Shout")
S.inCombat=true
S.SecureClicks.Sync("combat-event-no-button",settings,{x=0,y=0,size=48},true)
assert(not S.SecureClicks.buttons["combat-event-no-button"],"combat-only event never creates a secure action")
S.inCombat=false
assert(secure.icon,"secure hit target has its own visible icon")
local iconSpell=settings.spell; settings.spell="0"; S.Display.Show("click-test",settings)
assert(not secure:IsShown(),"No icon must not leave an invisible click interceptor")
settings.spell=iconSpell; S.Display.Show("click-test",settings)
local oldName=secure.attributes.spell1
combat=true
-- Model the native secure driver, not addon Lua hiding a protected frame.
secure.shown=false
S.Display.Show("click-test",settings)
assert(not secure:IsShown() and S.Display.frames["click-test"]:IsShown() and secure.attributes.spell1==oldName)
S.Display.Hide("click-test"); assert(not secure:IsShown() and not S.Display.frames["click-test"]:IsShown())
S.Layout.Open(); assert(not S.Layout.active)
combat=false
S.Display.Show("click-test",settings); assert(secure:IsShown())
S.Display.Hide("click-test"); assert(not secure:IsShown(),"no invisible click interceptor when reminder hides")
-- Rejected mode switch is visible at the real dropdown callback, on ports and wires.
E.Select("g2")
local mode=C.nodes.n1.valueFields[1].widget
mode.scripts.OnClick(mode); S.Widgets.menu.rows[1].scripts.OnClick(S.Widgets.menu.rows[1])
assert(E.graph.nodes.n1.settings.state=="Enter Combat" and E.rejection and E.rejection.message:find("Cannot switch",1,true))
assert(C.nodes.n1.badge.text=="!" and C.nodes.n1.message.text~="" and C.feedback.edges.c3)
local red=false; for _,line in ipairs(C.lines) do if line.connectionID=="c3" and line.color and line.color[1]==1 then red=true end end
assert(red,"rejected mode styles affected connection lines red")
-- Ordinary editor close/escape stays unprotected and never disables live rules.
combat=true; events.scripts.OnEvent(events,"PLAYER_REGEN_DISABLED")
E.closeButton.scripts.OnClick(E.closeButton)
assert(not E.window:IsShown() and S.Engine.graphs.g2 and S.Display.IsVisible("g2:n2"))
assert(E.window.parent==UIParent and not E.window.secure)
combat=false; events.scripts.OnEvent(events,"PLAYER_REGEN_ENABLED"); E.Toggle(); assert(E.window:IsShown())
assert(_G[UISpecialFrames[#UISpecialFrames]]==E.window,"Escape registration points only to unprotected editor")
-- Actual display widgets adapt to text-only and icon-only content.
S.Display.Show("text-test",{enabled=true,text="You are not in combat",spell="0",castSpell="unavailable",clickable=false})
assert(S.Display.frames["text-test"]:IsShown() and not S.Display.frames["text-test"].icon:IsShown() and S.Display.frames["text-test"].text:IsShown())
S.Display.Show("icon-test",{enabled=true,text="",spell="6673",clickable=false})
assert(S.Display.frames["icon-test"].icon:IsShown() and not S.Display.frames["icon-test"].text:IsShown() and S.Display.frames["icon-test"]:GetWidth()==68)
-- Add-node callback places to the right and persists character-local drafts.
E.New(); C.Add("player"); local firstNode=E.graph.nodes.n1; C.Add("show"); local nextNode=E.graph.nodes.n2
assert(nextNode.x>=firstNode.x+C.nodes.n1:GetWidth()+48 and nextNode.settings.text=="" and nextNode.settings.spell=="0")
C.SetZoom(.5); C.Add("not"); assert(E.graph.nodes.n3.x>=nextNode.x+C.nodes.n2:GetWidth()+48)
assert(S.db.drafts[E.graph.id] and S.db.drafts[E.graph.id].zoom==.5)
-- Item Picker changes stable item references through the same editor field lifecycle.
GetInventorySlotInfo=function() return nil end
C_Item={GetItemInfo=function(id) return "Hearthstone","item:"..id,1,1,1,"","",1,"",134400 end,IsEquippableItem=function() return false end}
C_Container={GetContainerNumSlots=function(bag) return bag==0 and 1 or 0 end,GetContainerItemInfo=function() return {itemID=6948} end}
S.Items.Refresh(); E.Switch("macro"); C.Add("use")
local useNode=E.graph.nodes[E.graph.lastNode]; local itemField=C.nodes[useNode.id].spellFields[1]
itemField.scripts.OnClick(itemField); assert(S.ItemPicker.window:IsShown() and S.ItemPicker.rows[1].text=="Hearthstone")
S.ItemPicker.rows[1].scripts.OnClick(S.ItemPicker.rows[1]); assert(useNode.settings.value=="item:6948" and not S.ItemPicker.window:IsShown())
SlashCmdList.SPAGHETTI(); assert(not E.window:IsShown()); SlashCmdList.SPAGHETTI(); assert(E.window:IsShown())
-- Contract-level mouse routing model: anchors, effective scale, frame strata,
-- levels, visibility and scroll clipping. This is not proof of native WoW input.
local strata={BACKGROUND=1,LOW=2,MEDIUM=3,HIGH=4,DIALOG=5,TOOLTIP=8}
local function rectangle(o,cache)
    if cache[o] then return cache[o] end
    if o==UIParent then local r={left=0,top=0,w=1920,h=1080}; cache[o]=r; return r end
    local points=o.points
    if not points or #points==0 then
        if o.parent and o.parent.child==o then points={{point="TOPLEFT",relative=o.parent,other="TOPLEFT",x=-(o.parent.horizontal or 0),y=o.parent.vertical or 0}} else return nil end
    end
    local scale=o:GetEffectiveScale(); local width,height=o.w*scale,o.h*scale
    local left,right,top,bottom,cx,cy
    local function fraction(point,axis)
        if point:find(axis=="x" and "LEFT" or "TOP",1,true) then return 0 end
        if point:find(axis=="x" and "RIGHT" or "BOTTOM",1,true) then return 1 end
        return .5
    end
    for _,p in ipairs(points) do
        local rel=p.relative and rectangle(p.relative,cache)
        if rel then
            local x=rel.left+fraction(p.other,"x")*rel.w+p.x*scale
            local y=rel.top+fraction(p.other,"y")*rel.h-p.y*scale
            local fx,fy=fraction(p.point,"x"),fraction(p.point,"y")
            if fx==0 then left=x elseif fx==1 then right=x else cx=x end
            if fy==0 then top=y elseif fy==1 then bottom=y else cy=y end
        end
    end
    if left and right then width=right-left end; if top and bottom then height=bottom-top end
    local r={left=left or (right and right-width) or (cx and cx-width/2) or 0,top=top or (bottom and bottom-height) or (cy and cy-height/2) or 0,w=width,h=height}; cache[o]=r; return r
end
local function within(r,x,y) return r and x>=r.left and x<=r.left+r.w and y>=r.top and y<=r.top+r.h end
local function mouseTarget(x,y)
    local cache={}; local best,bestStrata,bestLevel=nil,-1,-1
    for _,o in ipairs(made) do
        if (o.kind=="Button" or o.kind=="CheckButton" or o.kind=="EditBox" or o.mouse) and o.mouse~=false and o.enabled~=false and o:IsVisible() and within(rectangle(o,cache),x,y) then
            local parent,clipped=o.parent,false
            while parent do if parent.kind=="ScrollFrame" and not within(rectangle(parent,cache),x,y) then clipped=true; break end; parent=parent.parent end
            local s,l=strata[o:GetFrameStrata()] or 3,o:GetFrameLevel()
            if not clipped and (s>bestStrata or s==bestStrata and l>=bestLevel) then best,bestStrata,bestLevel=o,s,l end
        end
    end
    return best
end
local function clickFrame(button)
    local r=assert(rectangle(button,{})); local hit=mouseTarget(r.left+r.w/2,r.top+r.h/2)
    assert(hit==button,"toolbar mouse target was intercepted: "..button.text.." by "..(hit and hit.text or "nothing"))
    if button.scripts.OnClick then button.scripts.OnClick(button) end
end
S.db.importStatus="declined"; E.UpdateStatus()
assert(not E.controls.mouse and E.titleDrag:GetWidth()==560 and E.controls:GetFrameLevel()>E.titleDrag:GetFrameLevel())
for _,scale in ipairs({.7,1,1.2}) do for _,size in ipairs({{1160,740},{1600,1000}}) do
    E.window:SetScale(scale); E.window:SetSize(size[1],size[2]); S.Widgets.CloseMenu(); S.ItemPicker.Close(); S.SpellPicker.Close()
    clickFrame(E.importButton); assert(popups[#popups].which=="SPAGHETTI_IMPORT")
    clickFrame(E.templatesButton); assert(S.Widgets.menu:IsShown()); S.Widgets.CloseMenu()
    clickFrame(E.modeButton); assert(S.Widgets.menu:IsShown()); S.Widgets.CloseMenu()
    clickFrame(E.closeButton); assert(not E.window:IsShown()); E.Toggle()
end end
E.window:SetScale(1); E.window:SetSize(1200,800)
local previousCount=#S.SortedKeys(S.db.graphs); local existing=S.db.graphs.g3
clickFrame(E.templatesButton); clickFrame(S.Widgets.menu.rows[1])
assert(#S.SortedKeys(S.db.graphs)==previousCount+1 and S.db.graphs.g3==existing,"example selection adds, never replaces a user graph")
-- Native Macro Action: no PickupMacro from selection, clicks or preview.
local nativeMacros,pickups={},{}
GetMacroInfo=function(index) local m=nativeMacros[index]; if m then return m.name,m.icon,m.body end end
GetNumMacros=function() return 0,nativeMacros[121] and 1 or 0 end
CreateMacro=function(name,icon,body,character) assert(not combat); local id=character and 121 or 1; nativeMacros[id]={name=name,icon=icon,body=body}; return id end
EditMacro=function(index,name,icon,body) assert(not combat); nativeMacros[index]={name=name,icon=icon,body=body}; return index end
PickupMacro=function(index) assert(not combat); pickups[#pickups+1]=index end
S.Items.byID[15424]={id=15424,name="Axe of Orgrimmar",equippable=true,icon=1}
GetInventorySlotInfo=function(token) if token=="MainHandSlot" then return 16 end end
E.mode="macro"; E.New(); local graphID=E.graph.id
local start=S.Graph.Add(E.graph,"start"); local equip=S.Graph.Add(E.graph,"equipslot"); equip.settings.value="item:15424"
S.Graph.Connect(E.graph,start.id,"next",equip.id,"run"); E.name.text="Equip test"; E.name.scripts.OnTextChanged(E.name,true)
assert(E.macroName.text=="Equip test" and E.macroAction.enabled==false and #pickups==0)
E.Preview(); assert(#pickups==0)
E.apply.scripts.OnClick(E.apply)
assert(nativeMacros[121].name=="Equip test" and E.macroAction.enabled and E.macroActionState.text:find("Created",1,true))
E.Select(graphID); E.Preview(); assert(#pickups==0 and not E.macroAction.scripts.OnClick)
E.macroAction.scripts.OnDragStart(E.macroAction); assert(pickups[#pickups]==121)
nativeMacros[130]=nativeMacros[121]; nativeMacros[121]={name="Other macro",body="/use item:1",icon=134400}
events.scripts.OnEvent(events,"UPDATE_MACROS"); E.macroAction.scripts.OnDragStart(E.macroAction); assert(pickups[#pickups]==130)
local verifiedBody=nativeMacros[130].body; nativeMacros[130].body="/use item:2"; events.scripts.OnEvent(events,"UPDATE_MACROS")
local picked=#pickups; assert(not E.macroAction.enabled and E.macroActionState.text:find("Out of sync",1,true))
E.macroAction.scripts.OnDragStart(E.macroAction); assert(#pickups==picked)
nativeMacros[130].body=verifiedBody; combat=true; events.scripts.OnEvent(events,"PLAYER_REGEN_DISABLED")
assert(not E.macroAction.enabled and E.macroActionState.text:find("combat",1,true)); E.macroAction.scripts.OnDragStart(E.macroAction); assert(#pickups==picked)
clickFrame(E.closeButton); assert(not E.window:IsShown())
combat=false; events.scripts.OnEvent(events,"PLAYER_REGEN_ENABLED"); E.Toggle(); assert(E.macroAction.enabled,"reopening after combat refreshes drag readiness")
E.name.text="Equip renamed"; E.name.scripts.OnTextChanged(E.name,true)
assert(E.macroName.text=="Equip renamed" and E.macroActionState.text:find("Out of sync",1,true))
E.macroName.text="Custom macro"; E.macroName.scripts.OnTextChanged(E.macroName,true)
E.name.text="Another graph"; E.name.scripts.OnTextChanged(E.name,true)
assert(E.macroName.text=="Custom macro" and E.graph.macroNameCustom)
local reviewed=S.Copy(E.graph); reviewed.nativeMacro={index=130,name="Reviewed",body=verifiedBody,perCharacter=true}
E.graph.name="Newer draft while confirming"; E.graph.macroName="Newer custom"; E.Changed()
E.FinishReplacement(reviewed)
assert(E.graph.name=="Newer draft while confirming" and S.db.drafts[graphID].name==E.graph.name and E.graph.nativeMacro.name=="Reviewed","confirmation must preserve newer draft edits")
-- Native lockdown may still be true at the exit event. Keep the editor open:
-- no graph switch, reopen, aura event or reload is allowed to mask recovery.
local timers={}
C_Timer.After=function(seconds,fn) timers[#timers+1]={seconds=seconds,fn=fn} end
local function tick()
    local pending=timers; timers={}
    for _,t in ipairs(pending) do t.fn() end
end
local function enterCombat()
    combat=true
    for _,button in pairs(S.SecureClicks.buttons) do button.shown=false end -- native state driver
    events.scripts.OnEvent(events,"PLAYER_REGEN_DISABLED")
end
E.graph.nativeMacro={index=130,name=nativeMacros[130].name,body=verifiedBody,perCharacter=true}
E.graph.macroName=nativeMacros[130].name; E.UpdateStatus()
assert(E.macroAction.enabled)
local live=S.Graph.New("recovery","Recovery","reminder"); live.enabled=true; live.applied=true
local player=S.Graph.Add(live,"player"); local show=S.Graph.Add(live,"show")
show.settings.text="Click recovery"; show.settings.spell="5242"; show.settings.castSpell="5242"; show.settings.clickable=true
S.Graph.Connect(live,player.id,"value",show.id,"when"); S.Save(live); S.Engine.Reload()
local key=live.id..":"..show.id; local hit=S.SecureClicks.buttons[key]; assert(hit and hit:IsShown())
enterCombat(); E.macroAction.scripts.OnDragStart(E.macroAction)
assert(E.notice.text:find("combat",1,true) and not hit:IsShown())
events.scripts.OnEvent(events,"PLAYER_REGEN_ENABLED") -- native lockdown still active
assert(not E.macroAction.enabled and not hit:IsShown())
tick(); assert(not E.macroAction.enabled and not hit:IsShown(),"no early protected recovery")
combat=false; tick()
assert(E.window:IsShown() and E.macroAction.enabled and E.apply.enabled,"open editor recovers after native lockdown releases")
assert(not E.notice.text:find("combat",1,true) and not E.validation.text:find("blocked during combat",1,true))
assert(hit:IsShown() and hit.attributes.spell1=="Battle Shout","visible saved reminder recovers without Apply")
E.Message("Keep this unrelated warning"); E.UpdateStatus(); assert(E.notice.text=="Keep this unrelated warning")
-- A pending retry must use the current saved graph, never the edited draft.
enterCombat(); events.scripts.OnEvent(events,"PLAYER_REGEN_ENABLED")
local changed=S.Copy(live); changed.nodes[show.id].settings.castSpell="100"; S.Save(changed); S.Engine.Reload()
E.drafts[live.id]=S.Copy(live); E.drafts[live.id].nodes[show.id].settings.castSpell="6673"
combat=false; tick(); assert(hit:IsShown() and hit.attributes.spell1=="Charge")
-- Disable/delete/no-icon/preview/placement during the wait must not resurrect a target.
for _,mode in ipairs({"disabled","deleted","no-icon","preview","placement"}) do
    S.Layout.active=false; S.Save(live); S.Engine.Reload(); assert(hit:IsShown())
    enterCombat(); events.scripts.OnEvent(events,"PLAYER_REGEN_ENABLED")
    if mode=="deleted" then S.db.graphs[live.id]=nil
    elseif mode=="disabled" then S.db.graphs[live.id].enabled=false
    elseif mode=="no-icon" then S.db.graphs[live.id].nodes[show.id].settings.spell="0"
    elseif mode=="placement" then S.Layout.active=true
    else S.Display.Show("preview:"..key,S.Spells.ReminderSettings(live,show),5,true) end
    S.Engine.Reload(); combat=false; tick()
    if mode=="preview" then
        assert(not S.SecureClicks.buttons["preview:"..key] and hit:IsShown(),"only the saved live rule may regain its target")
    else assert(not hit:IsShown(),"stale target restored after "..mode) end
end
S.Layout.active=false
-- New combat invalidates old callbacks even if native lockdown changes independently.
S.Save(live); S.Engine.Reload(); enterCombat(); events.scripts.OnEvent(events,"PLAYER_REGEN_ENABLED")
enterCombat(); combat=false; tick(); assert(not hit:IsShown(),"old recovery survived new combat")
events.scripts.OnEvent(events,"PLAYER_REGEN_ENABLED"); assert(hit:IsShown())
-- Stuck native lockdown gets a finite retry budget, then later events can refresh normally.
timers={}; enterCombat(); events.scripts.OnEvent(events,"PLAYER_REGEN_ENABLED")
for _=1,25 do tick() end
assert(#timers==0 and not hit:IsShown() and not E.macroAction.enabled,"retry loop must stop and remain guarded")
combat=false; events.scripts.OnEvent(events,"UNIT_AURA","player"); assert(hit:IsShown())
-- Leaving the session cancels queued recovery.
enterCombat(); events.scripts.OnEvent(events,"PLAYER_REGEN_ENABLED")
events.scripts.OnEvent(events,"PLAYER_LOGOUT"); combat=false; tick(); assert(not hit:IsShown())
S.inCombat=false
-- Recovery updates a still-visible pulse without restarting its duration.
timers={}; local pulse=S.Graph.New("pulse-recovery","Pulse recovery","reminder"); pulse.enabled=true; pulse.applied=true
local trigger=S.Graph.Add(pulse,"combat_state"); trigger.settings.state="Enter Combat"
local pout=S.Graph.Add(pulse,"show"); pout.settings=S.Copy(show.settings); pout.settings.duration="7"
S.Graph.Connect(pulse,trigger.id,"next",pout.id,"run"); S.Save(pulse); S.Engine.Reload()
enterCombat(); local pulseKey=pulse.id..":"..pout.id; local generation=S.Display.generation[pulseKey]
events.scripts.OnEvent(events,"PLAYER_REGEN_ENABLED")
local recovery,expiry
for _,timer in ipairs(timers) do if timer.seconds==.1 then recovery=timer.fn elseif timer.seconds==7 then expiry=timer.fn end end
assert(recovery and expiry); combat=false; recovery()
assert(S.Display.IsVisible(pulseKey) and S.SecureClicks.buttons[pulseKey]:IsShown() and S.Display.generation[pulseKey]==generation)
expiry(); assert(not S.Display.IsVisible(pulseKey) and not S.SecureClicks.buttons[pulseKey]:IsShown())
S.Engine.Evaluate("COMBAT_RECOVERY"); assert(not S.Display.IsVisible(pulseKey) and not S.SecureClicks.buttons[pulseKey]:IsShown(),"expired pulse resurrected")
-- Configuration contract only: native font transitions still require real hover testing.
for _,mode in ipairs({"macro","reminder","macro"}) do
    E.mode=mode; E.BuildLibrary()
    for _,row in ipairs(E.libraryButtons) do if row:IsShown() then
        assert(row.normalFont=="GameFontHighlightSmall" and row.highlightFont=="GameFontNormalSmall" and row.disabledFont=="GameFontDisableSmall")
    end end
end
assert(not E.closeButton.normalFont,"library styling must not change other buttons")
print("  Mocked UI lifecycle: toolbar routing, native macro drag, bounded combat recovery, current saved rules and library font configuration")
