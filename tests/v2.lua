local S={}
local function load(name) assert(loadfile("Spaghetti/"..name..".lua"))("Spaghetti",S) end
for _,name in ipairs({"Registry","Graph","Storage","Compat","Spells","Migrations","MacroCompiler","Examples"}) do load(name) end
local count=0
local function check(v,why) count=count+1; assert(v,why or ("v2 check "..count)) end
local combat=false
InCombatLockdown=function() return combat end
issecretvalue=function(v) return type(v)=="table" and v.secret==true end
issecrettable=issecretvalue
Enum={SpellBookSpellBank={Player=0},SpellBookItemType={Spell=1,FutureSpell=2,Flyout=3},SecrecyLevel={NeverSecret=0,AlwaysSecret=1,ContextuallySecret=2}}
local book={
 {spellID=6673,itemType=1,name="Battle Shout",subName="Rank 1",isPassive=false,iconID=1,low=false},
 {spellID=100,itemType=1,name="Charge",subName="",isPassive=false,iconID=3,low=false},
 {spellID=200,itemType=1,name="Passive",subName="",isPassive=true,iconID=4,low=false},
 {spellID=201,itemType=2,name="Future",subName="",isPassive=false},
 {spellID=202,itemType=3,name="Flyout",subName="",isPassive=false},
}
C_SpellBook={
 GetNumSpellBookSkillLines=function() return 2 end,
 GetSpellBookSkillLineInfo=function(line) if line==1 then return {name="Warrior",itemIndexOffset=0,numSpellBookItems=#book} else return {name="General",itemIndexOffset=#book,numSpellBookItems=1} end end,
 GetSpellBookItemInfo=function(slot) return book[slot] or {spellID=300,itemType=1,name="Cooking",subName="",isPassive=false,iconID=7} end,
 GetSpellBookItemName=function(slot) local e=book[slot]; if e then return e.name,e.subName end; return "Cooking","" end,
 IsSpellBookItemLowRank=function(slot) return book[slot] and book[slot].low or false end,
 IsSpellKnown=function() return true end,
}
C_Spell={GetSpellName=function(id) for _,e in ipairs(book) do if e.spellID==id then return e.name end end end,GetSpellTexture=function(id) return id end}
local P,G=S.Spells,S.Graph
P.Refresh(); check(#P.entries==4,"learned class/general/profession/passive entries; no future/flyout")
check(#P.Search("BATTLE SHOUT",true)==1,"case-insensitive search")
check(#P.Search("Passive",true)==0 and #P.Search("Passive",false)==1,"passive filter for cast actions")
check(P.Resolve(6673).id==6673,"single rank retained with fallback warning")
local settings={}; check(P.Select(settings,"spell",P.byID[6673]) and settings.spell=="6673" and settings.spellMode=="auto","selection stores logical seed")
book[1].low=true
table.insert(book,{spellID=5242,itemType=1,name="Battle Shout",subName="Rank 2",isPassive=false,iconID=2,low=false})
P.Refresh(); check(P.Resolve(settings.spell).id==5242,"learning highest rank updates runtime resolution without rewriting seed")
check(settings.spell=="6673","logical selection remains stable")
check(P.Resolve(6673,"exact").id==6673,"explicit rank preserved")
check(#P.Resolve(6673).family.members==2,"family has client rank evidence")
table.insert(book,{spellID=9000,itemType=1,name="Battle Shout",subName="Rank 2",isPassive=false,iconID=2,low=false})
P.Refresh(); check(P.Resolve(6673).id==6673 and not P.byID[6673].family,"same-name ambiguity is never a rank family")
table.remove(book); P.Refresh()
check(not P.Resolve(999999),"unavailable spell does not silently choose another by name")
GetCursorInfo=function() return "spell",1,0,6673 end
check(P.Cursor(true).id==6673,"native cursor spell selection")
GetCursorInfo=function() return "spell",3,0,200 end
check(not P.Cursor(true),"passive cursor rejected for casts")
GetCursorInfo=function() return "item",123 end
check(not P.Cursor(false),"nonspell cursor rejected")
local old={schema=1,serial=1,selected="old",graphs={}}
local g={schema=1,id="old",name="Old graph",mode="reminder",serial=7,enabled=true,macroName="Spaghetti",perCharacter=false,nodes={
 p={id="p",type="player",x=10,y=20,settings={}},
 combat={id="combat",type="combat",x=200,y=20,settings={}},
 buff={id="buff",type="buff",x=400,y=20,settings={spell="6673",state="Missing"}},
 show={id="show",type="show",x=600,y=20,settings={text="Old",spell="5242",size="64",x="-100",y="200",duration="5",enabled=true}},
},connections={
 c1={id="c1",from="p",output="value",to="combat",input="gate",type="bool"},
 c2={id="c2",from="combat",output="value",to="buff",input="gate",type="bool"},
 c3={id="c3",from="buff",output="value",to="show",input="when",type="bool"},
}}
old.graphs.old=g
local migrated,why=S.Migrate(old); check(migrated,why)
check(old.schema==1 and old.graphs.old.nodes.combat.type=="combat","migration leaves source untouched")
check(migrated.schema==2 and migrated.graphs.old.nodes.combat.type=="combat_state","combat condition migrated")
check(migrated.graphs.old.nodes.combat.settings.state=="In Combat" and migrated.graphs.old.nodes.combat.x==200,"state and position retained")
check(migrated.graphs.old.connections.c2.from=="combat" and migrated.graphs.old.connections.c2.type=="bool","edges retained")
check(migrated.legacyBackup.graphs.old.nodes.buff.settings.spell=="6673","original numeric spell retained in backup")
check(migrated.graphs.old.nodes.buff.settings.spell=="6673" and P.Resolve("6673").id==5242,"migrated ID uses shared resolver")
check(migrated.layouts["old:show"].x==-100 and migrated.layouts["old:show"].size==64,"old placements migrate separately")
check(#G.Validate(migrated.graphs.old)==0,"Player compatibility and migrated graph validate")
check(S.Migrate(migrated)==migrated,"migration idempotence")
local ev=S.Copy(g); ev.id="event"; ev.nodes={enter={id="enter",type="enter",x=0,y=0,settings={}},show=S.Copy(g.nodes.show)}
ev.connections={c1={id="c1",from="enter",output="next",to="show",input="run",type="flow"}}
local result=S.Migrate({schema=1,graphs={event=ev}})
check(result.graphs.event.nodes.enter.settings.state=="Enter Combat" and result.graphs.event.connections.c1.type=="flow","old enter event migration")
ev.nodes.enter.type="leave"; result=S.Migrate({schema=1,graphs={event=ev}})
check(result.graphs.event.nodes.enter.settings.state=="Leave Combat","old leave event migration")
g.nodes.buff.settings.spell="99999"; result=S.Migrate(old)
check(result.graphs.old.nodes.buff.settings.spell=="99999" and #result.graphs.old.migrationWarnings>0,"unresolved ID retained with migration warning")
local graph=G.New("cs","Combat modes","reminder"); local state=G.Add(graph,"combat_state"); local show=G.Add(graph,"show"); show.settings.text="Test"
check(G.Connect(graph,state.id,"value",show.id,"when"),"boolean condition connects")
check(not G.ChangeCombatState(graph,state,"Enter Combat") and state.settings.state=="In Combat","changing connected type refuses data loss")
G.Disconnect(graph,show.id,"when","in"); check(G.ChangeCombatState(graph,state,"Enter Combat"))
check(not G.Connect(graph,state.id,"next",show.id,"when"),"event port remains typed flow")
check(G.Connect(graph,state.id,"next",show.id,"run"))
local m=S.Examples().g3; m.nodes.n4.settings.value="6673"; m.nodes.n5.settings.value="100"
check(S.Macro.Compile(m)=="#showtooltip\n/cast [mod:shift] Battle Shout; Charge","picker spells compile localized names and auto ranks")
m.nodes.n4.settings.valueMode="exact"; check(S.Macro.Compile(m):find("Battle Shout(Rank 1)",1,true),"explicit macro rank")
m.nodes.n4.settings.value="200"; check(not S.Macro.Compile(m),"passive cannot compile cast")
m.nodes.n4.settings.value="99999"; check(not S.Macro.Compile(m),"unavailable selected cast fails")
local auraCalls=0
C_UnitAuras={GetPlayerAuraBySpellID=function(id) auraCalls=auraCalls+1; if id==6673 then return {} end end}
check(P.ReadBuff("6673")==true,"lower verified rank satisfies logical buff")
C_UnitAuras.GetPlayerAuraBySpellID=function() return nil end
check(P.ReadBuff("6673")==false,"all readable family ranks absent confirms missing")
combat=true; check(P.ReadBuff("6673")==nil,"no permission means Unknown in combat")
local before=auraCalls; C_Secrets={ShouldSpellAuraBeSecret=function() return true end}
check(P.ReadBuff("6673")==nil and auraCalls==before,"secret spell never queried")
C_Secrets.ShouldSpellAuraBeSecret=function() return false end
check(P.ReadBuff("6673")==nil,"transient false without static classification cannot prove missing")
C_Secrets.GetSpellAuraSecrecy=function() return Enum.SecrecyLevel.NeverSecret end
check(P.ReadBuff("6673")==false,"NeverSecret plus explicit current permission permits reading")
C_Secrets.GetSpellAuraSecrecy=function() return Enum.SecrecyLevel.ContextuallySecret end
check(P.ReadBuff("6673")==nil,"contextually hidden nil is never Missing")
C_Secrets.GetSpellAuraSecrecy=function() return Enum.SecrecyLevel.NeverSecret end
C_UnitAuras.GetPlayerAuraBySpellID=function() return {secret=true} end
check(P.ReadBuff("6673")==nil,"even permission never turns a secret result into missing")
combat=false; C_Secrets=nil
local visible={}
S.Display={Show=function(key,settings,seconds) visible[key]={settings=settings,seconds=seconds} end,Hide=function(key) visible[key]=nil end,HideAll=function() visible={} end,IsVisible=function(key) return visible[key]~=nil end}
load("ReminderEngine"); load("Layout")
S.db={schema=2,graphs={cs=graph},layouts={}}; local E=S.Engine
check(E.Overview()[1].state=="Saved • not applied","saved is different from applied")
E.ToggleReminder("cs",show.id,true); check(E.Overview()[1].state=="Waiting for condition","enabled event waits")
E.Evaluate("PLAYER_REGEN_DISABLED"); check(E.Overview()[1].state=="Visible","event pulse visible")
check(visible["cs:"..show.id].seconds==5,"event uses duration")
E.ToggleReminder("cs",show.id,false); check(E.Overview()[1].state=="Disabled","overview disable synchronized")
E.ToggleReminder("cs",show.id,true); check(E.Overview()[1].state=="Waiting for condition","re-enable waits for next event")
G.Disconnect(graph,show.id,"run","in"); G.ChangeCombatState(graph,state,"In Combat"); G.Connect(graph,state.id,"value",show.id,"when")
S.inCombat=false; E.Reload(); check(not visible["cs:"..show.id],"persistent condition false outside combat")
S.inCombat=true; E.Evaluate("PLAYER_REGEN_DISABLED"); check(visible["cs:"..show.id],"persistent condition true in combat")
S.inCombat=false; E.Evaluate("PLAYER_REGEN_ENABLED"); check(not visible["cs:"..show.id],"persistent condition clears")
local bg=S.Examples().g1; bg.enabled=true; bg.applied=true; S.db.graphs={g1=bg}; S.inCombat=true; E.Reload()
check(E.Overview()[1].state=="Unsupported / unknown","unsupported combat buff is explicit in overview")
check(not visible["g1:n4"],"Unknown never Missing")
S.inCombat=false; check(S.Layout.Put("g1:n4",{x=123,y=-45,size=72}))
local place=S.Layout.Get("g1:n4",{}); check(place.x==123 and place.y==-45 and place.size==72,"placement persistence independent from graph logic")
combat=true; check(not S.Layout.Put("g1:n4",{x=0,y=0,size=48}) and S.Layout.Get("g1:n4",{}).x==123,"combat prevents placement mutation")
combat=false
load("Canvas")
local C=S.Canvas
for _,z in ipairs({.5,1,1.5}) do
 local vx,vy=C.GraphToView(400,200,z,60,90)
 local gx,gy=C.ViewToGraph(vx,vy,z,60,90)
 check(math.abs(gx-400)<.00001 and math.abs(gy-200)<.00001,"zoom transform roundtrip")
end
local a,b=C.GraphToView(100,100,.5,20,20); local c,d=C.GraphToView(300,200,.5,20,20)
check(a==30 and b==30 and c==130 and d==80,"port endpoints use same scaled viewport transform")
local multi=G.New("multi","Independent outputs","reminder")
local player=G.Add(multi,"player"); local first=G.Add(multi,"show"); local second=G.Add(multi,"show"); first.settings.text="First"; second.settings.text="Second"
G.Connect(multi,player.id,"value",first.id,"when"); G.Connect(multi,player.id,"value",second.id,"when")
S.db.graphs={multi=multi}; E.ToggleReminder("multi",first.id,true)
check(multi.nodes[first.id].settings.enabled and not multi.nodes[second.id].settings.enabled,"enabling one unapplied reminder does not activate siblings")
E.ToggleReminder("multi",second.id,true)
check(multi.nodes[first.id].settings.enabled and multi.nodes[second.id].settings.enabled,"other outputs can be enabled independently")
print("  "..count.." v0.2 assertions passed")
