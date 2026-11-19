local S={}
local function load(name) assert(loadfile("Spaghetti/"..name..".lua"))("Spaghetti",S) end
for _,name in ipairs({"Registry","Graph","Storage","Compat","MacroCompiler","Examples","MacroIntegration"}) do load(name) end
local count=0
local function check(v,message) count=count+1; assert(v,message or ("check "..count)) end
local function contains(list,term) return table.concat(list," "):find(term,1,true)~=nil end
local G=S.Graph
local examples=S.Examples()
check(S.CheckStorage({schema=2,graphs=examples}),"valid SavedVariables boundary")
check(not S.CheckStorage({schema=4,graphs=examples}),"future storage must not be overwritten")
local malformed=S.Copy(examples); malformed.g1.nodes.n2.settings=nil
check(not S.CheckStorage({schema=2,graphs=malformed}),"corrupt storage rejected before rendering")
local body,errors=S.Macro.Compile(examples.g3)
check(body=="#showtooltip\n/cast [mod:shift] Battle Shout; Charge","modifier example must compile from its edges")
check(#errors==0)
check(#G.Validate(examples.g1)==0,"buff graph saves despite warning")
local _,warnings=G.Validate(examples.g1); check(contains(warnings,"unsupported in combat"))
local g=G.New("test","Test","reminder")
local a=G.Add(g,"player",10,20); local b=G.Add(g,"not",300,200); local c=G.Add(g,"not",500,200)
check(a.id~=b.id and a.x==10 and a.y==20)
check(G.Connect(g,a.id,"value",b.id,"a"))
check(not G.Connect(g,a.id,"value",b.id,"a"),"occupied input rejected")
check(G.Connect(g,b.id,"value",c.id,"a"))
check(not G.Connect(g,c.id,"value",b.id,"a"),"cycle/occupied input rejected")
G.Disconnect(g,b.id,"a","in")
check(not G.Connect(g,c.id,"value",b.id,"a"),"cycle rejected even with free input")
check(not G.Connect(g,b.id,"value",b.id,"a"),"self edge rejected")
local ev=G.Add(g,"enter")
check(not G.Connect(g,ev.id,"next",b.id,"a"),"flow cannot feed boolean")
check(not G.Add(g,"start"),"mode mismatch")
G.Remove(g,b.id); check(not G.Incoming(g,c.id,"a"),"deletion cleans edges")
local corrupt=S.Copy(examples.g3); local key=next(corrupt.connections); corrupt.connections[key].type="other"
check(#G.Validate(corrupt)>0,"stored edge type validated")
local cycle=G.New("cy","cycle","reminder"); local n1=G.Add(cycle,"not"); local n2=G.Add(cycle,"not")
G.Connect(cycle,n1.id,"value",n2.id,"a")
cycle.connections.bad={from=n2.id,output="value",to=n1.id,input="a",type="bool"}
check(contains(G.Validate(cycle),"Cycles"),"persisted cycles rejected")
local function macroChange(fn,term)
    local m=S.Copy(examples.g3); fn(m); local out,e=S.Macro.Compile(m)
    check(not out and contains(e,term),term)
end
macroChange(function(m) G.Add(m,"exists") end,"disconnected")
macroChange(function(m) m.nodes.n4.settings.value="Foo\n/run Bad()" end,"plain spell")
macroChange(function(m) m.nodes.n4.settings.value=string.rep("a",255) end,"maximum")
macroChange(function(m) m.nodes.n4.settings.unit="enemy" end,"unsupported Cast on")
macroChange(function(m) m.nodes.n2.type="buff" end,"wrong mode")
macroChange(function(m) m.nodes.n5.type="use" end,"same command")
macroChange(function(m) local x=G.Add(m,"cast"); G.Connect(m,"n4","next",x.id,"run") end,"terminal")
for kind,predicate in pairs({exists="exists",friendly="help",hostile="harm",mcombat="nocombat"}) do
    local m=S.Copy(examples.g3); m.nodes.n2.type=kind; m.nodes.n2.settings={state="nocombat"}
    local out=S.Macro.Compile(m); check(out and out:find("["..predicate.."]",1,true),kind)
end
for _,modifier in ipairs({"ctrl","alt"}) do
    local m=S.Copy(examples.g3); m.nodes.n2.settings.key=modifier
    check(S.Macro.Compile(m):find("[mod:"..modifier.."]",1,true))
end
local m=G.New("m","Linear","macro"); local st=G.Add(m,"start"); local target=G.Add(m,"target"); local cast=G.Add(m,"cast"); local use=G.Add(m,"use")
cast.settings.value="Battle Shout"; cast.settings.unit="mouseover"; use.settings.value="12345"; G.Connect(m,st.id,"next",target.id,"run"); G.Connect(m,target.id,"next",cast.id,"run"); G.Connect(m,cast.id,"next",use.id,"run")
check(S.Macro.Compile(m)=="#showtooltip\n/target target\n/cast [@mouseover] Battle Shout\n/use item:12345","linear macro actions")
local function serialize(v)
    if type(v)=="table" then
        local a={"{"}; for k,x in pairs(v) do a[#a+1]="["..serialize(k).."]="..serialize(x).."," end; a[#a+1]="}"; return table.concat(a)
    elseif type(v)=="string" then return string.format("%q",v)
    elseif type(v)=="number" or type(v)=="boolean" then return tostring(v)
    else error("Nonserializable value: "..type(v)) end
end
local encoded=serialize(examples); local restored=assert(loadstring("return "..encoded))()
check(S.Macro.Compile(restored.g3)==body,"SavedVariables-compatible table roundtrip")
check(restored.g1.nodes.n3.x==486 and restored.g1.connections.c5~=nil,"positions and stable edge IDs persist")
-- Secret-value objects throw if used as booleans in the real client. Here ensure early guards prevent queries.
local combat=false; InCombatLockdown=function() return combat end
issecretvalue=function(v) return type(v)=="table" and v.secret==true end
issecrettable=function(v) assert(type(v)=="table"); return v.secret==true end
local calls=0; C_UnitAuras={GetPlayerAuraBySpellID=function() calls=calls+1; return nil end}
S.inCombat=true; check(S.ReadBuff(6673)==nil and calls==0,"never query combat auras")
S.inCombat=false; check(S.ReadBuff(6673)==false,"missing out of combat")
C_UnitAuras.GetPlayerAuraBySpellID=function() return {secret=true} end
check(S.ReadBuff(6673)==nil,"secret table is unknown")
C_Secrets={ShouldSpellAuraBeSecret=function() return true end}
check(S.ReadBuff(6673)==nil,"secret spell rejected before query")
C_Secrets=nil; C_UnitAuras.GetPlayerAuraBySpellID=function() error("restricted") end
check(S.ReadBuff(6673)==nil,"API errors are unknown")
C_UnitAuras.GetPlayerAuraBySpellID=nil; check(S.ReadBuff(6673)==nil,"missing API")
-- Runtime uses fake display so actual evaluation can run independently of WoW.
local visible={}; S.Display={HideAll=function() visible={} end,Show=function(key,settings,seconds) visible[key]={settings=settings,seconds=seconds} end,Hide=function(key) visible[key]=nil end}
load("ReminderEngine")
S.db={graphs=S.Copy(examples)}; S.db.graphs.g1.enabled=true; S.db.graphs.g2.enabled=true
S.inCombat=true; S.Engine.Reload()
check(not visible["g1:n4"],"unsupported missing buff does not display")
S.Engine.Evaluate("PLAYER_REGEN_DISABLED"); check(visible["g2:n2"] and visible["g2:n2"].seconds==5,"combat event works")
S.Engine.Evaluate("UNIT_AURA"); check(visible["g2:n2"],"unrelated aura event does not erase pulse")
check(S.Engine.status.g1:find("UNKNOWN",1,true),"unknown shown in runtime diagnostics")
local neg=G.New("neg","No false inversion","reminder"); local buff=G.Add(neg,"buff"); local invert=G.Add(neg,"not"); local show=G.Add(neg,"show"); buff.settings.spell="6673"; show.settings.text="Test"
G.Connect(neg,buff.id,"value",invert.id,"a"); G.Connect(neg,invert.id,"value",show.id,"when"); neg.enabled=true
S.db.graphs={neg=neg}; S.Engine.Reload(); check(not visible["neg:"..show.id],"NOT unknown cannot produce a reminder")
S.inCombat=false; C_UnitAuras.GetPlayerAuraBySpellID=function() return {} end
S.Engine.Evaluate("UNIT_AURA"); check(visible["neg:"..show.id],"NOT of missing false works out of combat")
neg.nodes[show.id].settings.enabled=false; S.Engine.Reload(); check(not visible["neg:"..show.id],"disabled outputs stay hidden")
-- Native integration: scope, slots, replacement and lockdown are validated at execution time.
local macros={}; local writes=0
MAX_ACCOUNT_MACROS=120; MAX_CHARACTER_MACROS=30
GetMacroIndexByName=function(name) for id,v in pairs(macros) do if v.name==name then return id end end return 0 end
GetMacroInfo=function(id) local v=macros[id]; if v then return v.name,134400,v.body end end
GetNumMacros=function() return 0,0 end
CreateMacro=function(name,icon,text,perCharacter) writes=writes+1; local id=perCharacter and 121 or 1; macros[id]={name=name,body=text}; return id end
EditMacro=function(id,name,icon,text) writes=writes+1; macros[id]={name=name,body=text}; return id end
local mg=S.Copy(examples.g3); mg.perCharacter=false
combat=true; check(not S.MacroIntegration.Apply(mg,body) and writes==0,"lockdown blocks native calls")
combat=false; check(S.MacroIntegration.Apply(mg,body)==1 and writes==1,"create account macro")
local _,reason,plan=S.MacroIntegration.Apply(mg,body)
check(reason=="CONFIRM" and writes==1,"never silently overwrite")
macros[1].body="changed"; check(not S.MacroIntegration.Apply(mg,body,plan) and writes==1,"stale confirmation rejected")
_,_,plan=S.MacroIntegration.Apply(mg,body); check(S.MacroIntegration.Apply(mg,body,plan)==1 and writes==2,"confirmed edit")
mg.perCharacter=true; check(not S.MacroIntegration.Apply(mg,body),"cross-scope collision rejected")
mg.macroName="Unique"; GetNumMacros=function() return 120,30 end
check(not S.MacroIntegration.Apply(mg,body),"full slots rejected")
mg.macroName=string.rep("x",17); check(not S.MacroIntegration.Apply(mg,body),"name length enforced")
check(not S.MacroIntegration.Apply(mg,string.rep("x",256)),"body size enforced")
print("  "..count.." logic assertions passed")
