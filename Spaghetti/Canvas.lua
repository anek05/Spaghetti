local _, S = ...
local C={nodes={},lines={},cache={}}; S.Canvas=C
local W,G=S.Widgets,S.Graph
local colors={bool={.3,.85,.55},flow={.3,.65,1}}
function C.NodeSize(n)
    local f=C.nodes[n.id]
    if f then return f:GetWidth(),f:GetHeight() end
    return S.Placement.Size(n)
end
function C.ScrollTo(n)
    local w,h=C.NodeSize(n); local z=C.zoom or 1
    local x,y=C.scroll:GetHorizontalScroll(),C.scroll:GetVerticalScroll()
    local vw,vh=C.scroll:GetWidth(),C.scroll:GetHeight()
    if n.x*z<x or (n.x+w)*z>x+vw then x=math.max(0,(n.x+w+30)*z-vw) end
    if n.y*z<y or (n.y+h)*z>y+vh then y=math.max(0,(n.y+h+30)*z-vh) end
    local _,maxH=C.hbar:GetMinMaxValues(); local _,maxV=C.vbar:GetMinMaxValues()
    C.hbar:SetValue(math.min(maxH,x)); C.vbar:SetValue(math.min(maxV,y))
end
function C.Add(kind)
    local g=S.Editor.graph; local n,why=G.Add(g,kind)
    if not n then S.Editor.Message(why); return end
    local x,y=S.Placement.Find(g,n,g.selectedNode or g.lastNode,C.NodeSize,C.scroll:GetHorizontalScroll()/(C.zoom or 1)+40,C.scroll:GetVerticalScroll()/(C.zoom or 1)+50)
    if not x then G.Remove(g,n.id); S.Editor.Message(y); return end
    n.x=x; n.y=y; g.lastNode=n.id; g.selectedNode=n.id
    S.Editor.Changed(); C.Render(); C.ScrollTo(n)
end
function C.GraphToView(x,y,z,h,v) return x*z-h,y*z-v end
function C.ViewToGraph(x,y,z,h,v) return (x+h)/z,(y+v)/z end
function C.SetZoom(value,atX,atY,quiet)
    if not C.frame then return end
    value=math.max(.5,math.min(1.5,value)); local old=C.zoom or 1
    local h,v=C.scroll:GetHorizontalScroll(),C.scroll:GetVerticalScroll()
    atX,atY=atX or C.scroll:GetWidth()/2,atY or C.scroll:GetHeight()/2
    local gx,gy=C.ViewToGraph(atX,atY,old,h,v)
    C.zoom=value; C.frame:SetScale(value); C.host:SetSize(1700*value,1200*value)
    local maxH,maxV=math.max(0,1700*value-C.scroll:GetWidth()),math.max(0,1200*value-C.scroll:GetHeight())
    C.hbar:SetMinMaxValues(0,math.max(1,maxH)); C.vbar:SetMinMaxValues(0,math.max(1,maxV))
    C.hbar:SetValue(math.max(0,math.min(maxH,gx*value-atX))); C.vbar:SetValue(math.max(0,math.min(maxV,gy*value-atY)))
    if C.zoomLabel then C.zoomLabel:SetText(math.floor(value*100+.5).."%") end
    if S.Editor.graph then S.Editor.graph.zoom=value; if not quiet then S.Editor.Changed() end end
    C.Draw()
end
function C.RefreshSpells()
    for _,f in pairs(C.nodes) do
        for _,field in ipairs(f.spellFields or {}) do field.Refresh() end
        for _,field in ipairs(f.checkFields or {}) do field.widget:SetChecked(field.node.settings[field.key]) end
        for _,field in ipairs(f.valueFields or {}) do local v=field.node.settings[field.key]; field.widget:SetText(field.labels and field.labels[v] or tostring(v)) end
    end
end
function C.Clear()
    C.wiring=nil
    if C.ghost then C.ghost:Hide() end
    for _,frame in pairs(C.nodes) do frame:Hide() end
    C.nodes={}
    for _,line in ipairs(C.lines) do line:Hide() end
end
local function center(port,canvas)
    local x,y=port:GetCenter()
    if not x then return 0,0 end
    return x-canvas:GetLeft(),y-canvas:GetTop()
end
function C.Draw()
    local g=S.Editor.graph; if not g or not C.frame:IsVisible() then return end
    local i=0
    for _,key in ipairs(S.SortedKeys(g.connections)) do
        local c=g.connections[key]; local a,b=C.nodes[c.from],C.nodes[c.to]
        local ap=a and a.ports["out:"..c.output]; local bp=b and b.ports["in:"..c.input]
        if ap and bp then
            i=i+1
            local line=C.lines[i]
            if not line then line=C.frame:CreateLine(nil,"ARTWORK"); C.lines[i]=line; line:SetThickness(3) end
            local ax,ay=center(ap,C.frame); local bx,by=center(bp,C.frame)
            line:SetStartPoint("TOPLEFT",ax,ay); line:SetEndPoint("TOPLEFT",bx,by)
            local color=C.feedback and C.feedback.edges[key] and {1,.2,.18} or colors[c.type] or colors.flow
            line.connectionID=key; line:SetColorTexture(color[1],color[2],color[3],.85); line:Show()
        end
    end
    for j=i+1,#C.lines do C.lines[j]:Hide() end
end
function C.Cancel() C.wiring=nil; if C.ghost then C.ghost:Hide() end end
function C.Finish(node,port,direction)
    local wire=C.wiring; if not wire then return end
    if wire.direction==direction then S.Editor.Message("Connect an output to an input."); C.Cancel(); return end
    local from,output,to,input
    if direction=="in" then from,output,to,input=wire.node,wire.port,node,port
    else from,output,to,input=node,port,wire.node,wire.port end
    local c,reason=G.Connect(S.Editor.graph,from,output,to,input)
    C.Cancel()
    if c then S.Editor.Changed(); C.Draw() else
        S.Editor.Reject({node=to,message=reason,ports={[from..":out:"..output]=true,[to..":in:"..input]=true},edges={}})
    end
end
local function port(frame,node,key,direction,kind,index)
    local b=CreateFrame("Button",nil,frame)
    b:SetSize(18,18); b:SetPoint(direction=="in" and "TOPLEFT" or "TOPRIGHT",direction=="in" and -7 or 7,-34-(index-1)*24)
    b:RegisterForClicks("LeftButtonUp","RightButtonUp")
    local color=colors[kind]; local t=b:CreateTexture(nil,"ARTWORK"); t:SetAllPoints(); t:SetColorTexture(color[1],color[2],color[3],1); b.texture=t; b.kind=kind
    local l=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    if direction=="in" then l:SetPoint("LEFT",b,"RIGHT",4,0) else l:SetPoint("RIGHT",b,"LEFT",-4,0) end
    l:SetText(S.PortLabel(node,key,direction))
    b:SetScript("OnMouseDown",function(_,button)
        if button~="LeftButton" then return end
        if C.wiring then C.Finish(node.id,key,direction)
        else C.wiring={node=node.id,port=key,direction=direction,button=b}; S.Editor.Message("Drag to a matching port. Right-click a port to remove its connections.") end
    end)
    b:SetScript("OnMouseUp",function(_,button)
        if button=="RightButton" then C.Cancel(); G.Disconnect(S.Editor.graph,node.id,key,direction); S.Editor.Changed(); C.Draw()
        elseif C.wiring and C.wiring.button~=b then C.Finish(node.id,key,direction) end
    end)
    b:SetScript("OnEnter",function()
        GameTooltip:SetOwner(b,"ANCHOR_RIGHT"); GameTooltip:SetText((kind=="bool" and "Boolean condition" or "Execution event").." "..direction.." - "..S.PortLabel(node,key,direction))
        GameTooltip:AddLine("Drag to connect. Right-click to disconnect.",1,1,1,true); GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    frame.ports[direction..":"..key]=b
end
function C.RenderNode(node)
    local d=S.Definition(node)
    if not d then return end
    -- WoW frames cannot be destroyed. Reuse each draft node's widgets on redraw.
    local variant=node.type..(node.type=="combat_state" and node.settings.state or "")..(node.type=="show" and tostring(node.settings.clickable) or "")
    C.cache[node]=C.cache[node] or {}
    if C.cache[node][variant] then
        local f=C.cache[node][variant]; C.nodes[node.id]=f
        f:ClearAllPoints(); f:SetPoint("TOPLEFT",node.x,-node.y); f:Show(); return
    end
    local f=W.Panel(C.frame); C.nodes[node.id]=f; f.ports={}
    C.cache[node][variant]=f; f.spellFields={}; f.checkFields={}; f.valueFields={}
    local inputs,outputs=S.SortedKeys(d.inputs),S.SortedKeys(d.outputs)
    local fieldTop=40+math.max(#inputs,#outputs)*24
    f:SetSize(214,fieldTop+#d.fields*44+15); f:SetPoint("TOPLEFT",node.x,-node.y)
    f:SetMovable(true); f:EnableMouse(true)
    local title=CreateFrame("Button",nil,f); title:SetPoint("TOPLEFT",1,-1); title:SetPoint("TOPRIGHT",-27,-1); title:SetHeight(27)
    local bar=title:CreateTexture(nil,"BACKGROUND"); bar:SetAllPoints(); bar:SetColorTexture(d.mode=="macro" and .23 or .08,.2,.3,1)
    local text=title:CreateFontString(nil,"OVERLAY","GameFontNormal"); text:SetPoint("LEFT",7,0); text:SetText(d.title)
    f.badge=W.Label(f,"",172,-8); f.message=W.Label(f,"",0,0); f.message:ClearAllPoints(); f.message:SetPoint("TOPLEFT",f,"BOTTOMLEFT",0,-3); f.message:SetWidth(214); f.message:SetHeight(38)
    title:SetScript("OnMouseDown",function() S.Editor.graph.selectedNode=node.id end)
    title:RegisterForDrag("LeftButton")
    title:SetScript("OnDragStart",function() S.Editor.graph.selectedNode=node.id; C.Cancel(); f:StartMoving(); C.dragging=f end)
    title:SetScript("OnDragStop",function()
        f:StopMovingOrSizing(); C.dragging=nil
        node.x=math.max(12,math.min(1460,f:GetLeft()-C.frame:GetLeft()))
        node.y=math.max(8,math.min(1140-f:GetHeight(),C.frame:GetTop()-f:GetTop()))
        f:ClearAllPoints(); f:SetPoint("TOPLEFT",node.x,-node.y); S.Editor.Changed(); C.Draw()
    end)
    title:SetScript("OnEnter",function()
        GameTooltip:SetOwner(title,"ANCHOR_TOP"); GameTooltip:SetText(d.title.." • "..node.id)
        GameTooltip:AddLine(d.help or "Drag the title to move. Configure this node below.",1,1,1,true); GameTooltip:Show()
        local issue=C.feedback and C.feedback.nodes[node.id]
        if issue then GameTooltip:AddLine(issue.category..": "..issue.message,1,.5,.3,true); GameTooltip:Show() end
    end); title:SetScript("OnLeave",function() GameTooltip:Hide() end)
    W.Button(f,"x",24,188,-2,function() G.Remove(S.Editor.graph,node.id); S.Editor.Changed(); C.Render() end)
    for i,key in ipairs(inputs) do port(f,node,key,"in",d.inputs[key],i) end
    for i,key in ipairs(outputs) do port(f,node,key,"out",d.outputs[key],i) end
    for i,field in ipairs(d.fields) do
        local y=-fieldTop-(i-1)*44
        local function set(v)
            if node.type=="combat_state" and field.key=="state" then
                local ok,why,detail=G.ChangeCombatState(S.Editor.graph,node,v)
                if not ok then S.Editor.Reject(detail or {node=node.id,message=why}); return false end
                S.Editor.Changed(); C.Render(); return true
            end
            node.settings[field.key]=v; S.Editor.Changed(); if node.type=="show" and field.key=="clickable" then C.Render() end; return true
        end
        if field.kind=="check" then
            local check=CreateFrame("CheckButton",nil,f,"UICheckButtonTemplate"); check:SetPoint("TOPLEFT",8,y); check:SetSize(24,24)
            check:SetChecked(node.settings[field.key]); check:SetScript("OnClick",function(self) set(self:GetChecked()==true) end)
            f.checkFields[#f.checkFields+1]={widget=check,node=node,key=field.key}
            W.Label(f,field.label,36,y-5)
        else
            W.Label(f,field.label,12,y)
            if field.kind=="spell" or field.kind=="icon" or field.kind=="castspell" then
                f.spellFields[#f.spellFields+1]=S.SpellPicker.Field(f,190,10,y-14,node.settings,field.key,field.kind,function() S.Editor.Changed(); C.RefreshSpells() end,S.Editor.graph,node)
            elseif field.kind=="item" or field.kind=="equipment" or field.kind=="equipset" then
                f.spellFields[#f.spellFields+1]=S.ItemPicker.Field(f,190,10,y-14,node.settings,field.key,field.kind,S.Editor.Changed)
            elseif field.options then
                local labels=field.key=="unit" and S.UnitLabels or nil
                local dropdown=W.Dropdown(f,190,10,y-14,labels and labels[node.settings[field.key]] or tostring(node.settings[field.key]),field.options,set,labels)
                f.valueFields[#f.valueFields+1]={widget=dropdown,node=node,key=field.key,labels=labels}
            else
                local edit=W.Edit(f,182,16,y-14,tostring(node.settings[field.key] or ""),set)
                if node.type=="show" and field.key=="text" then
                    local placeholder=W.Label(edit,"Remember [enter text]",2,-5); placeholder:SetTextColor(.5,.5,.5)
                    local previous=edit:GetScript("OnTextChanged")
                    edit:SetScript("OnTextChanged",function(self,user) placeholder:SetShown(self:GetText()==""); previous(self,user) end)
                    placeholder:SetShown(edit:GetText()=="")
                end
            end
        end
    end
end
function C.Render()
    C.Clear()
    if not S.Editor.graph then return end
    for _,id in ipairs(S.SortedKeys(S.Editor.graph.nodes)) do C.RenderNode(S.Editor.graph.nodes[id]) end
    C.RefreshSpells(); if S.Editor.feedback then C.ApplyFeedback(S.Editor.feedback) else C.Draw() end
end
function C.ApplyFeedback(report)
    C.feedback=report
    for id,f in pairs(C.nodes) do
        local issue=report.nodes[id]
        if issue then
            local error=issue.severity=="error"; f:SetBackdropBorderColor(1,error and .2 or .7,.15,1)
            f.badge:SetText(error and "!" or "?"); f.badge:SetTextColor(1,error and .25 or .75,.2)
            f.message:SetText(S.Editor.rejection and S.Editor.rejection.node==id and issue.message or "")
        else f:SetBackdropBorderColor(.18,.23,.29,1); f.badge:SetText("o"); f.badge:SetTextColor(.3,.8,.5); f.message:SetText("") end
        for key,p in pairs(f.ports) do
            local color=report.ports[id..":"..key] and {1,.15,.1} or colors[p.kind]
            p.texture:SetColorTexture(color[1],color[2],color[3],1)
        end
    end
    C.Draw()
end
function C.Build(parent)
    local viewport=W.Panel(parent,.025,.035,.055); C.viewport=viewport
    viewport:SetPoint("TOPLEFT",178,-107); viewport:SetPoint("BOTTOMRIGHT",-24,239)
    local scroll=CreateFrame("ScrollFrame",nil,viewport); C.scroll=scroll
    scroll:SetPoint("TOPLEFT",4,-4); scroll:SetPoint("BOTTOMRIGHT",-18,18)
    C.host=CreateFrame("Frame",nil,scroll); C.host:SetSize(1700,1200); scroll:SetScrollChild(C.host)
    local canvas=CreateFrame("Frame",nil,C.host); C.frame=canvas; C.zoom=1
    canvas:SetSize(1700,1200); canvas:SetPoint("TOPLEFT",0,0); canvas:EnableMouse(true)
    canvas:SetScript("OnMouseDown",function() C.Cancel(); W.CloseMenu(); S.SpellPicker.Close(); S.ItemPicker.Close() end)
    local hint=W.Label(canvas,"BLUE = flow     GREEN = condition     •     Drag titles to move. Drag ports to connect.",16,-10)
    hint:SetTextColor(.4,.5,.6)
    for x=0,1700,40 do local t=canvas:CreateTexture(nil,"BACKGROUND"); t:SetColorTexture(.1,.13,.18,.45); t:SetPoint("TOPLEFT",x,0); t:SetSize(1,1200) end
    for y=0,1200,40 do local t=canvas:CreateTexture(nil,"BACKGROUND"); t:SetColorTexture(.1,.13,.18,.45); t:SetPoint("TOPLEFT",0,-y); t:SetSize(1700,1) end
    local function slider(vertical)
        local s=CreateFrame("Slider",nil,viewport,"BackdropTemplate")
        s:SetOrientation(vertical and "VERTICAL" or "HORIZONTAL"); s:SetMinMaxValues(0,1); s:SetValueStep(1); s:SetObeyStepOnDrag(true)
        s:SetThumbTexture("Interface\\Buttons\\WHITE8X8"); s:GetThumbTexture():SetVertexColor(.3,.55,.7,.8)
        if vertical then s:SetWidth(12); s:SetPoint("TOPRIGHT",-2,-4); s:SetPoint("BOTTOMRIGHT",-2,20); s:GetThumbTexture():SetSize(10,35)
        else s:SetHeight(12); s:SetPoint("BOTTOMLEFT",4,2); s:SetPoint("BOTTOMRIGHT",-20,2); s:GetThumbTexture():SetSize(35,10) end
        s:SetScript("OnValueChanged",function(_,value) if vertical then scroll:SetVerticalScroll(value) else scroll:SetHorizontalScroll(value) end; C.Draw() end)
        return s
    end
    C.vbar=slider(true); C.hbar=slider(false)
    scroll:SetScript("OnSizeChanged",function(self)
        C.vbar:SetMinMaxValues(0,math.max(1,1200*C.zoom-self:GetHeight())); C.hbar:SetMinMaxValues(0,math.max(1,1700*C.zoom-self:GetWidth())); C.Draw()
    end)
    scroll:EnableMouseWheel(true); scroll:SetScript("OnMouseWheel",function(_,delta)
        if IsControlKeyDown and IsControlKeyDown() then
            local x,y=GetCursorPosition(); local scale=scroll:GetEffectiveScale()
            C.SetZoom((C.zoom or 1)+delta*.1,x/scale-scroll:GetLeft(),scroll:GetTop()-y/scale); return
        end
        local s=IsShiftKeyDown() and C.hbar or C.vbar; local lo,hi=s:GetMinMaxValues(); s:SetValue(math.max(lo,math.min(hi,s:GetValue()-delta*40)))
    end)
    local toolbar=parent.controls or parent
    W.ToolbarButton(toolbar,"−",26,946,-43,function() C.SetZoom(C.zoom-.1) end)
    W.ToolbarButton(toolbar,"+",26,975,-43,function() C.SetZoom(C.zoom+.1) end)
    W.ToolbarButton(toolbar,"Reset",55,1004,-43,function() C.SetZoom(1) end)
    C.zoomLabel=W.Label(toolbar,"100%",1068,-50)
    canvas:SetScript("OnUpdate",function()
        if C.dragging then C.Draw() end
        if C.wiring then
            if not C.ghost then C.ghost=canvas:CreateLine(nil,"OVERLAY"); C.ghost:SetThickness(3); C.ghost:SetColorTexture(1,.8,.3,1) end
            local x,y=GetCursorPosition(); local scale=canvas:GetEffectiveScale(); x=x/scale-canvas:GetLeft(); y=y/scale-canvas:GetTop()
            local ax,ay=center(C.wiring.button,canvas); C.ghost:SetStartPoint("TOPLEFT",ax,ay); C.ghost:SetEndPoint("TOPLEFT",x,y); C.ghost:Show()
            -- MouseUp is delivered to the button where the drag began. Resolve hovered destination explicitly.
            if not IsMouseButtonDown("LeftButton") then
                for id,f in pairs(C.nodes) do for key,p in pairs(f.ports) do
                    if p~=C.wiring.button and p:IsMouseOver() then local direction,portName=key:match("^(%a+):(.+)$"); C.Finish(id,portName,direction); return end
                end end
                -- Keep a click-to-connect fallback until clicking a destination or blank canvas.
            end
        end
    end)
    return canvas
end
