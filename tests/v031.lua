local S={}
local function load(name) assert(loadfile("Spaghetti/"..name..".lua"))("Spaghetti",S) end
for _,name in ipairs({"Registry","Graph","Storage","Compat","Spells","Items","Migrations","Profiles","MacroCompiler","MacroIntegration","Examples"}) do load(name) end
local total=0
local function check(v,why) total=total+1; assert(v,why or ("0.3.1 assertion "..total)) end
local I,G=S.MacroIntegration,S.Graph
local g=G.New("equip","Equip test","macro")
check(I.Name(g)=="Equip test" and not g.macroNameCustom,"graph name supplies native default")
g.name="Equip axe"; check(I.Name(g)=="Equip axe","uncustomized default follows graph rename")
g.macroName="My axe"; g.macroNameCustom=true; g.name="New graph"
check(I.Name(g)=="My axe","custom native name independent from graph")
g.macroNameCustom=false; check(I.Name(g)=="New graph","reset to graph default")
local old={name="Equip test",macroName="Spaghetti"}; I.NormalizeName(old)
check(not old.macroNameCustom and old.macroName=="Spaghetti" and old.legacyMacroName=="Spaghetti" and I.Name(old)=="Equip test","legacy default ambiguity retained without forcing it as native name")
local explicit={name="Graph",macroName="Custom old name"}; I.NormalizeName(explicit); explicit.name="Renamed graph"
check(explicit.macroNameCustom and I.Name(explicit)=="Custom old name","existing non-default configured name preserved")
check(I.Name({name="Graph",macroName="Spaghetti",macroNameCustom=true})=="Spaghetti","explicitly customized Spaghetti remains custom")
check(not I.NameError(string.rep("\195\169",16)) and I.NameError(string.rep("\195\169",17)),"16-character Unicode limit, not 16 bytes")
check(I.NameError("   ") and I.NameError("x\ny") and I.NameError(string.rep("x",17)),"empty/control/long names rejected without truncation")
local locked=false; InCombatLockdown=function() return locked end
issecretvalue=function() return false end
Constants={MacroConsts={MAX_ACCOUNT_MACROS=120,MAX_CHARACTER_MACROS=30}}
local native,writes,picks={},0,{}
local wrongName,wrongBody,full=false,false,false
GetMacroInfo=function(index) local r=native[index]; if r then return r.name,r.icon or 134400,r.body end end
GetNumMacros=function()
 if full then return 120,30 end
 local a,c=0,0; for index in pairs(native) do if index>120 then c=c+1 else a=a+1 end end; return a,c
end
CreateMacro=function(name,icon,body,character)
 writes=writes+1
 local index=character and 121 or 1
 while native[index] do index=index+1 end
 native[index]={name=wrongName and "Wrong stored" or name,icon=icon,body=wrongBody and "truncated" or body.."\n"}; return index
end
EditMacro=function(index,name,icon,body)
 writes=writes+1; native[index]={name=wrongName and "Wrong stored" or name,icon=icon,body=wrongBody and "truncated" or body.."\n"}; return index
end
PickupMacro=function(index) picks[#picks+1]=index end
g=G.New("equip","Equip test","macro")
local body="#showtooltip\n/equipslot 16 item:15424"
check(I.Status(g,body).state=="Not created","generated/saved graph is not a native macro")
local index=I.Apply(g,body)
check(index==121 and native[index].name=="Equip test" and g.nativeMacro.perCharacter,"CreateMacro receives graph name and character scope")
check(I.Status(g,body).ready and I.Status(g,body).state=="Created","stored name/body verified before Created")
check(I.Pickup(g,body)==121 and picks[#picks]==121,"genuine pickup uses actual verified index")
local copy=S.Copy(g); check(I.Status(copy,body).ready,"association survives SavedVariables-compatible copy/reopen")
native[130]=native[121]; native[121]={name="Unrelated",body="/use item:1"}
check(I.Pickup(copy,body)==130 and picks[#picks]==130,"reordered native macro resolves from signature, never stale index")
local count=#picks; locked=true
check(not I.Pickup(copy,body) and #picks==count,"combat pickup blocked")
local before=writes; check(not I.Apply(copy,body) and writes==before,"combat create/edit still blocked")
locked=false; copy.name="Equip another"
check(I.Status(copy,body).state=="Out of sync" and not I.Pickup(copy,body),"renaming default graph marks intended native name out of sync")
local _,reason,plan=I.Apply(copy,body)
check(reason=="CONFIRM" and plan.index==130 and plan.oldName=="Equip test" and writes==before,"renaming existing native macro requires explicit confirmation")
index=I.Apply(copy,body,plan)
check(index==130 and native[130].name=="Equip another" and I.Status(copy,body).ready,"confirmed rename updates actual stored identity")
local changed=body.."\n/use item:6948"
check(I.Status(copy,changed).state=="Out of sync" and not I.Pickup(copy,changed),"generated body change blocks drag until native update")
native[130].body="/use item:999"
check(I.Status(copy,body).state=="Out of sync" and not I.Pickup(copy,body),"external native body edits never silently dragged")
_,reason,plan=I.Apply(copy,body); check(reason=="CONFIRM" and plan.oldBody=="/use item:999","external edit needs fresh replacement confirmation")
native[130].body="/use item:998"; before=writes
check(not I.Apply(copy,body,plan) and writes==before,"stale confirmation rejected")
_,_,plan=I.Apply(copy,body); check(I.Apply(copy,body,plan)==130,"explicit current confirmation may update native body")
native[130].name="Renamed outside"
count=#picks; check(I.Status(copy,body).state=="Missing" and not I.Pickup(copy,body) and #picks==count,"external rename is missing/renamed, not guessed by body")
native[130]={name="Now unrelated",body=body}
check(not I.Pickup(copy,body),"same body at stale slot with different name not identity")
check(I.Apply(copy,body)==122 and I.Status(copy,body).ready,"explicit recreate uses a free slot, not unrelated stale record")
native[123]=S.Copy(native[122]); before=writes
check(not I.Apply(copy,body) and writes==before and not I.Pickup(copy,body),"ambiguous duplicate signatures/names fail closed")
native[123]=nil; native[122]=nil
check(I.Status(copy,body).state=="Missing" and not I.Pickup(copy,body),"deleted macro handled safely")
native[1]={name="Equip another",body=body}
check(not I.Apply(copy,body),"cross-scope name collision does not target account macro")
native={}; full=true
check(not I.Apply(copy,body),"native constants/available slots checked")
full=false; wrongName=true; local failed=G.New("bad","Correct name","macro")
local _,mismatch=I.Apply(failed,body)
check(mismatch:find("name mismatch",1,true) and not failed.nativeMacro,"readback name mismatch reported; no drag association recorded")
wrongName=false; wrongBody=true; native={}
local _,badBody=I.Apply(failed,body); check(badBody:find("body or scope",1,true) and not failed.nativeMacro,"readback body mismatch not mistaken for success")
wrongBody=false; native={}; failed.perCharacter=false
check(I.Apply(failed,body)==1 and not failed.nativeMacro.perCharacter,"explicit account scope remains available")
native[1].icon=123456; local newBody=body.."\n/use item:2"
_,_,plan=I.Apply(failed,newBody); I.Apply(failed,newBody,plan)
check(native[1].icon==123456 and I.Status(failed,newBody).record.icon==123456,"native icon preserved for updates and draggable representation")
native={}; local sorted=G.New("sorted","Before rename","macro"); I.Apply(sorted,body)
EditMacro=function(index,name,icon,text) writes=writes+1; native[index]=nil; native[140]={name=name,icon=icon,body=text}; return 140 end
sorted.name="After rename"; _,_,plan=I.Apply(sorted,body)
check(I.Apply(sorted,body,plan)==140 and sorted.nativeMacro.index==140 and I.Status(sorted,body).ready,"EditMacro may return a different alphabetical index")
check(I.Pickup(sorted,body)==140,"pickup follows returned/verified edited identity")
local read=GetMacroInfo; GetMacroInfo=function() error("unavailable read") end; before=writes; count=#picks
check(not I.Pickup(sorted,body) and #picks==count and not I.Apply(sorted,body) and writes==before,"unreadable native API never falls through to pickup or overwrite")
GetMacroInfo=read
local legacyGraph=G.New("legacy","Graph default","macro"); legacyGraph.macroName="Spaghetti"; legacyGraph.macroNameCustom=nil
local profile={schema=3,graphs={legacy=legacyGraph},drafts={},layouts={},serial=1}
local normalized=S.Profiles.Open(profile,nil)
check(I.Name(normalized.graphs.legacy)=="Graph default" and normalized.graphs.legacy.legacyMacroName=="Spaghetti" and legacyGraph.macroNameCustom==nil,"profile naming normalization is additive and leaves original data unchanged")
-- Equipment and existing cast/focus compilation remain graph-driven.
S.Items.byID[15424]={id=15424,name="Axe of Orgrimmar",equippable=true,icon=1}
GetInventorySlotInfo=function(token) if token=="MainHandSlot" then return 16 end end
local eq=G.New("eq","Equip test","macro"); local start=G.Add(eq,"start"); local slot=G.Add(eq,"equipslot")
slot.settings.value="item:15424"; G.Connect(eq,start.id,"next",slot.id,"run")
check(S.Macro.Compile(eq)==body,"reported Axe of Orgrimmar Equip Slot case unchanged")
local cast=G.New("cast","Cast","macro"); local st=G.Add(cast,"start"); local act=G.Add(cast,"cast"); act.settings.value="Earth Shock"; act.settings.unit="focus"; act.settings.relation="Hostile"; act.settings.alive=true; G.Connect(cast,st.id,"next",act.id,"run")
check(S.Macro.Compile(cast)=="#showtooltip\n/cast [@focus,harm,nodead] Earth Shock","Cast Spell qualifiers unchanged")
-- Diagnostics: valid/unapplied/false/Unknown/runtime error are distinct.
local visible={}; S.Display={HideAll=function() visible={} end,Hide=function(key) visible[key]=nil end,Show=function(key,s) visible[key]=s end,IsVisible=function(key) return visible[key]~=nil end}
load("ReminderEngine")
local r=G.New("r","Combat diagnostic","reminder"); local c=G.Add(r,"combat_state"); local out=G.Add(r,"show"); out.settings.text="Combat reminder"; G.Connect(r,c.id,"value",out.id,"when")
S.db={graphs={r=r},layouts={}}; S.inCombat=false
check(S.Engine.Overview()[1].state=="Saved • not applied","valid but unapplied distinct")
r.enabled=true; r.applied=true; S.Engine.Reload()
check(S.Engine.Overview()[1].state=="Condition false" and S.Engine.status.r:find("FALSE",1,true),"enabled false condition is explicit")
local buff=G.Add(r,"buff"); buff.settings.spell="6673"; G.Disconnect(r,out.id,"when","in"); G.Connect(r,c.id,"value",buff.id,"gate"); G.Connect(r,buff.id,"value",out.id,"when")
S.Spells.byID[6673]={id=6673,name="Battle Shout",rankText="Rank 2"}; S.inCombat=true
S.ReadBuff=function() return nil,"Secret combat aura" end; S.Engine.Reload()
check(S.Engine.Overview()[1].state=="Unsupported / unknown" and S.Engine.status.r:find("Battle Shout",1,true) and S.Engine.status.r:find("cannot be evaluated",1,true),"Battle Shout Unknown explained by name and reason")
check(not visible["r:"..out.id],"Unknown never becomes Missing")
S.ReadBuff=function() error("test runtime fault") end; S.Engine.Evaluate("UNIT_AURA")
check(S.Engine.Overview()[1].state:find("Runtime error",1,true) and S.Engine.status.r:find("test runtime fault",1,true),"runtime Lua failure separate from API Unknown and suppressed")
S.ReadBuff=function() return nil,"Secret combat aura" end; S.Engine.Evaluate("UNIT_AURA")
check(not S.Engine.errors.r and S.Engine.Overview()[1].state=="Unsupported / unknown","recovered runtime error returns to correct diagnostic")
print("  "..total.." v0.3.1 assertions passed")
