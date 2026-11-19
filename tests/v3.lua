local S={}
local function load(name) assert(loadfile("Spaghetti/"..name..".lua"))("Spaghetti",S) end
for _,name in ipairs({"Registry","Graph","Storage","Compat","Spells","Items","Migrations","Profiles","Validation","Placement","MacroCompiler","MacroIntegration","Examples"}) do load(name) end
local total=0
local function check(v,why) total=total+1; assert(v,why or ("v3 assertion "..total)) end
local G=S.Graph
local function content(g,kind,text) local n=G.Add(g,kind); if kind=="show" then n.settings.text=text or "Test reminder" end; return n end
local function has(list,term) return table.concat(list," "):find(term,1,true)~=nil end
local examples=S.Examples()
local legacy={schema=2,graphs=examples,layouts={["g2:n2"]={x=100,y=-80,size=64}},serial=3,selected="g2"}
legacy.graphs.g2.enabled=true; legacy.graphs.g2.applied=true; legacy.graphs.g2.zoom=.6
legacy.graphs.g3.perCharacter=false
local p=S.Profiles.Open(nil,legacy); local other=S.Profiles.Open(nil,legacy)
check(p.schema==3 and p.importStatus=="pending" and next(p.graphs)==nil,"new character never inherits account rules")
check(not S.Profiles.Import(p,legacy,false),"import needs explicit confirmation")
local imported,why=S.Profiles.Import(p,legacy,true); check(imported,why)
check(imported.graphs.g2.enabled==false and imported.graphs.g2.applied==false and imported.graphs.g2.nodes.n2.settings.enabled==false,"import starts inactive at graph and output level")
check(legacy.graphs.g2.enabled==true and legacy.graphs.g2.nodes.n2.settings.enabled==true,"legacy backup unchanged")
check(imported.graphs.g3.perCharacter and not legacy.graphs.g3.perCharacter,"imported macros default to character scope without changing legacy settings")
check(imported.graphs.g2.connections.c3.from=="n1" and imported.graphs.g2.nodes.n1.settings.state=="Enter Combat","node/edge relationships preserved")
check(imported.layouts["g2:n2"].size==64 and imported.graphs.g2.zoom==.6 and imported.selected=="g2","layout zoom selection preserved")
imported.layouts["g2:n2"].x=999; imported.graphs.g2.nodes.n2.settings.text="Changed"
check(legacy.layouts["g2:n2"].x==100 and legacy.graphs.g2.nodes.n2.settings.text~="Changed" and next(other.graphs)==nil,"all character data independently copied")
check(not S.Profiles.Import(imported,legacy,true),"legacy imports not repeated")
local second=S.Profiles.Import(other,legacy,true); check(second.layouts["g2:n2"].x==100 and second.graphs.g2.nodes.n2.settings.text~="Changed","another character gets its own explicit copy")
S.Profiles.Decline(p); check(p.importStatus=="declined" and S.Profiles.Open(p,legacy).importStatus=="declined","declined offer does not repeat after restore")
check(not S.Profiles.Open({schema=99},legacy) and legacy.schema==2,"unknown character data not overwritten")
check(not S.Profiles.Import(p,{schema=99,graphs={}},true),"failed import preserves all prior data")
imported.drafts.g2=S.Copy(imported.graphs.g2); imported.drafts.g2.nodes.n2.settings.text="Draft survives"
local restored=S.Profiles.Open(imported,legacy)
check(restored.drafts.g2.nodes.n2.settings.text=="Draft survives" and restored.layouts["g2:n2"].x==999,"character drafts/layout restored independently")
restored.drafts.g2.nodes.n2.settings.text="New draft"; check(imported.drafts.g2.nodes.n2.settings.text=="Draft survives","restored drafts use independent tables")
local collision=S.Profiles.Open(nil,legacy); collision.graphs.g2=G.New("g2","Existing character graph","reminder")
local merged=S.Profiles.Import(collision,legacy,true)
check(merged.graphs.g2.name=="Existing character graph" and #S.SortedKeys(merged.graphs)==4,"import ID collisions never replace existing character graphs")
local fresh=G.New("fresh","Fresh","reminder")
check(G.Add(fresh,"buff").settings.spell=="" and G.Add(fresh,"show").settings.text=="" and G.Add(fresh,"show").settings.spell=="0","no class-specific spell/text/icon defaults")
local macro=G.New("m","Fresh macro","macro")
check(G.Add(macro,"cast").settings.value=="" and G.Add(macro,"use").settings.value=="" and macro.perCharacter,"new macros/items default None and character scope")
local cs=G.New("cs","Modes","reminder"); local combat=G.Add(cs,"combat_state"); local show=content(cs,"show")
G.ChangeCombatState(cs,combat,"Enter Combat"); local edge=G.Connect(cs,combat.id,"next",show.id,"run")
local ok,message,rejected=G.ChangeCombatState(cs,combat,"In Combat")
check(not ok and message:find("Cannot switch to In Combat",1,true) and message:find("condition",1,true) and message:find("event",1,true),"rejected mode explains exactly why")
check(rejected.edges[edge.id] and rejected.ports[combat.id..":out:next"] and cs.connections[edge.id]==edge and combat.settings.state=="Enter Combat","rejected mode retains edges and identifies red ports/lines")
local report=S.Validation.Report(cs,{}, {},rejected)
check(report.nodes[combat.id].severity=="error" and report.edges[edge.id] and #report.messages>0,"reusable visual rejection report")
local clean=S.Validation.Report(cs,{},{}); check(not clean.nodes[combat.id] and not clean.edges[edge.id],"visual error state clears after correction")
local missing=G.New("bad","Missing configuration","reminder"); local miss=G.Add(missing,"show")
local errors,warnings=G.Validate(missing); check(has(errors,"enter reminder text") and has(errors,"connect Condition"),"missing content and missing input are explicit")
check(S.Validation.Report(missing,errors,warnings).nodes[miss.id].severity=="error","missing config is a red node state")
-- Collision-free placement uses actual dimensions, independent of zoom.
local pg=G.New("place","Placement","reminder"); local anchor=G.Add(pg,"player",40,50)
local large=content(pg,"show"); large.x=302; large.y=50
local new=G.Add(pg,"combat_state")
local function size(n) if n.id==large.id then return 300,440 end; return S.Placement.Size(n) end
local x,y=S.Placement.Find(pg,new,anchor.id,size)
check(x and (x+214+24<=large.x or x>=large.x+300+24 or y+S.Placement.Size(new)<=large.y or y>=large.y+440+24),"new node avoids actual occupied rectangle")
check(anchor.x==40 and large.x==302,"existing nodes never auto-move")
local single=G.New("one","Right of selected","reminder"); local a=G.Add(single,"player",40,50); local b=G.Add(single,"not")
local bx,by=S.Placement.Find(single,b,a.id,S.Placement.Size); check(bx==302 and by==50,"normal insertion to right of selection with wiring gap")
-- Correct NOT graph with text only, no icon and an irrelevant unavailable cast selection.
local visible={}; S.Display={HideAll=function() visible={} end,Hide=function(key) visible[key]=nil end,Show=function(key,settings) visible[key]=settings end,IsVisible=function(key) return visible[key]~=nil end}
load("ReminderEngine")
local ng=G.New("not","Not in combat","reminder"); local c=G.Add(ng,"combat_state"); local invert=G.Add(ng,"not"); local out=content(ng,"show","You are not in combat")
out.settings.spell="0"; out.settings.castSpell="not-known"; out.settings.clickable=false
G.Connect(ng,c.id,"value",invert.id,"a"); G.Connect(ng,invert.id,"value",out.id,"when"); ng.enabled=true
S.db={schema=3,graphs={notGraph=ng},layouts={},drafts={}}; S.db.graphs={notGraph=nil,notcombat=ng}; ng.id="notcombat"
S.inCombat=false; S.Engine.Reload(); check(visible["notcombat:"..out.id] and visible["notcombat:"..out.id].spell=="0","NOT(InCombat) visible outside combat with text and no icon")
S.inCombat=true; S.Engine.Evaluate("PLAYER_REGEN_DISABLED"); check(not visible["notcombat:"..out.id],"NOT(InCombat) hides entering combat")
S.inCombat=false; S.Engine.Evaluate("PLAYER_REGEN_ENABLED"); check(visible["notcombat:"..out.id],"NOT(InCombat) reappears leaving combat")
local _,notes=G.Validate(ng); check(not has(notes,"not-known") and not has(notes,"unavailable"),"irrelevant cast selection does not affect a nonclickable reminder")
local original=G.New("original","Original reversed construction","reminder")
local p1=G.Add(original,"player"); local no=G.Add(original,"not"); local state=G.Add(original,"combat_state"); local o=content(original,"show")
G.Connect(original,p1.id,"value",no.id,"a"); G.Connect(original,no.id,"value",state.id,"gate"); G.Connect(original,state.id,"value",o.id,"when")
local err,note=G.Validate(original); check(#err==0 and has(note,"NOT(Player) is always false"),"original construction valid but warns about false gate and gives correct wiring")
original.enabled=true; S.db.graphs={original=original}; S.inCombat=false; S.Engine.Reload(); check(not visible["original:"..o.id],"original construction false outside combat")
S.inCombat=true; S.Engine.Evaluate("PLAYER_REGEN_DISABLED"); check(not visible["original:"..o.id],"original construction false inside combat")
-- Inventory API model: equipped gear, bags, quality, stable identities and async misses.
local owned={ [6948]={name="Hearthstone",quality=1,icon=1,equippable=false}, [1000]={name="Test Sword",quality=3,icon=2,equippable=true}, [1001]={name="Test Shield",quality=2,icon=3,equippable=true} }
GetInventorySlotInfo=function(token) local ids={MainHandSlot=16,SecondaryHandSlot=17,HeadSlot=1,ChestSlot=5,Trinket0Slot=13,Trinket1Slot=14}; return ids[token] end
GetInventoryItemID=function(_,slot) if slot==16 then return 1000 end end
C_Item={GetItemInfo=function(id) local e=owned[id]; if e then return e.name,"item:"..id,e.quality,1,1,"", "",1,e.equippable and "INVTYPE_WEAPON" or "",e.icon end end,IsEquippableItem=function(id) return owned[id] and owned[id].equippable end}
C_Container={GetContainerNumSlots=function(bag) return bag==0 and 2 or 0 end,GetContainerItemInfo=function(_,slot) return {itemID=slot==1 and 6948 or 1001} end}
NUM_BAG_SLOTS=4; S.Items.Refresh()
check(#S.Items.entries==3 and S.Items.Resolve("item:1000").quality==3,"inventory enumeration merges equipped and bags with quality")
check(#S.Items.Search("TEST",true)==2 and #S.Items.Search("hearth",true)==0,"search and equippable filtering")
check(S.Items.SlotID("Main Hand")==16 and S.Items.SlotID("Off Hand")==17 and S.Items.SlotID("Trinket 2")==14,"native slot IDs queried rather than guessed")
GetCursorInfo=function() return "item",1001,"item:1001" end; check(S.Items.Cursor(true).id==1001,"bag/equipment item cursor payload")
GetCursorInfo=function() return "item",6948,"item:6948" end; check(not S.Items.Cursor(true) and S.Items.Cursor(false).id==6948,"non-equippable drop rejected only for equipment")
local function linear(kind,value)
 local g=G.New("macro","Macro","macro"); local start=G.Add(g,"start"); local action=G.Add(g,kind); action.settings.value=value; G.Connect(g,start.id,"next",action.id,"run"); return g,action
end
local focus,cast=linear("cast","Earth Shock"); cast.settings.unit="focus"; cast.settings.relation="Hostile"; cast.settings.alive=true
check(S.Macro.Compile(focus)=="#showtooltip\n/cast [@focus,harm,nodead] Earth Shock","direct hostile/alive focus syntax")
UnitExists=function() return false end
local body,_,whyFocus=S.Macro.Compile(focus); check(body and has(whyFocus,"no focus is set"),"no focus gives warning without promising runtime cast")
cast.settings.relation="Friendly"; cast.settings.exists=true; check(S.Macro.Compile(focus):find("[@focus,help,nodead,exists]",1,true),"supported friendly/alive/exists syntax")
local target=linear("target","focus"); check(S.Macro.Compile(target)=="#showtooltip\n/target focus","target focus changes current target")
local setFocus=linear("focus","target"); check(S.Macro.Compile(setFocus)=="#showtooltip\n/focus target","Set Focus is a separate operation")
local eq=linear("equip","item:1000"); check(S.Macro.Compile(eq)=="#showtooltip\n/equip item:1000","equip compiles standard command")
local eqs,slot=linear("equipslot","item:1001"); slot.settings.slot="Off Hand"; check(S.Macro.Compile(eqs)=="#showtooltip\n/equipslot 17 item:1001","equipslot syntax uses native slot")
local use=linear("use","item:6948"); check(S.Macro.Compile(use)=="#showtooltip\n/use item:6948","picker item Use syntax")
eq.nodes.n2.settings.value="item:6948"; check(not S.Macro.Compile(eq),"non-equippable item cannot compile equip")
S.Items.byID[1001]=nil; check(not S.Macro.Compile(eqs) and eqs.nodes.n2.settings.value=="item:1001" and S.Items.Label("item:1001"):find("unavailable",1,true),"missing item preserved and visibly unavailable")
C_EquipmentSet={CanUseEquipmentSets=function() return false end,GetEquipmentSetIDs=function() return {7} end,GetEquipmentSetInfo=function() return "Healing",8 end}
local set=linear("equipset","7"); check(not S.Items.SetsAvailable() and not S.Macro.Compile(set),"unsupported Equip Set is not functional-looking")
C_EquipmentSet.CanUseEquipmentSets=function() return true end; S.Items.Refresh()
check(S.Items.SetsAvailable() and S.Macro.Compile(set)=="#showtooltip\n/equipset Healing","equipment set guarded by native capability and ID lookup")
local locked=true; InCombatLockdown=function() return locked end
check(not S.MacroIntegration.Apply(focus,body),"native macro operations remain blocked in combat")
print("  "..total.." v0.3 assertions passed")
