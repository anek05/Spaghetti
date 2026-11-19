local _, S = ...
local O={rows={}}; S.Overview=O
function O.Build(parent)
    local W=S.Widgets
    W.Label(parent,"ACTIVE REMINDERS",0,0,"GameFontNormal")
    W.Button(parent,"Edit placement",130,330,3,function() S.Layout.Open() end)
    W.Button(parent,"Disable graph",120,465,3,function()
        S.Editor.graph.enabled=false; S.Editor.graph.applied=true; S.Editor.Save()
    end)
    O.scroll=CreateFrame("ScrollFrame",nil,parent,"UIPanelScrollFrameTemplate")
    O.scroll:SetPoint("TOPLEFT",0,-34); O.scroll:SetPoint("BOTTOMRIGHT",-26,3)
    O.content=CreateFrame("Frame",nil,O.scroll); O.content:SetSize(590,1); O.scroll:SetScrollChild(O.content)
end
function O.Update()
    if not O.content or not S.db then return end
    local W=S.Widgets; local list=S.Engine.Overview()
    for _,row in ipairs(O.rows) do row:Hide() end
    O.content:SetHeight(math.max(1,#list*56))
    for i,item in ipairs(list) do
        local row=O.rows[i]
        if not row then
            row=CreateFrame("Frame",nil,O.content); row:SetSize(588,54); row:SetPoint("TOPLEFT",0,-(i-1)*56)
            row.toggle=CreateFrame("CheckButton",nil,row,"UICheckButtonTemplate"); row.toggle:SetPoint("TOPLEFT",0,-3); row.toggle:SetSize(24,24)
            row.name=W.Label(row,"",30,0); row.name:SetWidth(470); row.name:SetHeight(18)
            row.status=W.Label(row,"",30,-20); row.status:SetWidth(480); row.status:SetHeight(32)
            row.open=W.Button(row,"Open",54,526,-4); O.rows[i]=row
        end
        row.name:SetText((item.name or "Reminder").." • "..item.graph)
        row.status:SetText((item.enabled and "Enabled" or "Disabled").." | "..item.state)
        row.toggle:SetChecked(item.enabled)
        row.toggle:SetScript("OnClick",function(self)
            local ok,why=S.Engine.ToggleReminder(item.gid,item.id,self:GetChecked()==true)
            if not ok then S.Editor.Message(why); O.Update() end
        end)
        row.open:SetScript("OnClick",function() S.Editor.Select(item.gid) end); row:Show()
    end
end
