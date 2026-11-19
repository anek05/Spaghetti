local _, S = ...
function S.Examples()
    local G=S.Graph
    local a=G.New("g1","Warrior • Battle Shout (combat limited)","reminder")
    local p=G.Add(a,"player",24,40); local c=G.Add(a,"combat_state",255,40)
    local b=G.Add(a,"buff",486,40); local o=G.Add(a,"show",720,40)
    b.settings.spell="6673"; o.settings.text="Remember Battle Shout"; o.settings.spell="auto"
    G.Remove(a,p.id); G.Connect(a,c.id,"value",b.id,"gate"); G.Connect(a,b.id,"value",o.id,"when")
    local e=G.New("g2","Demo • Enter Combat","reminder")
    local event=G.Add(e,"combat_state",40,60); event.settings.state="Enter Combat"; local show=G.Add(e,"show",310,60)
    show.settings.text="Combat started"; G.Connect(e,event.id,"next",show.id,"run")
    local m=G.New("g3","Warrior • Shift macro","macro")
    local start=G.Add(m,"start",24,40); local mod=G.Add(m,"modifier",24,210)
    local branch=G.Add(m,"branch",265,40); local yes=G.Add(m,"cast",510,40); local no=G.Add(m,"cast",510,260)
    yes.settings.value="Battle Shout"
    no.settings.value="Charge"; m.macroName="ShoutCharge"; m.macroNameCustom=true
    G.Connect(m,start.id,"next",branch.id,"run"); G.Connect(m,mod.id,"value",branch.id,"condition")
    G.Connect(m,branch.id,"yes",yes.id,"run"); G.Connect(m,branch.id,"no",no.id,"run")
    return {g1=a,g2=e,g3=m}
end
