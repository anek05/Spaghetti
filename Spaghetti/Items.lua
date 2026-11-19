local _, S = ...
local I={entries={},byID={},sets={},requested={}}; S.Items=I
local slots={{"Head","HeadSlot"},{"Neck","NeckSlot"},{"Shoulder","ShoulderSlot"},{"Shirt","ShirtSlot"},{"Chest","ChestSlot"},{"Waist","WaistSlot"},{"Legs","LegsSlot"},{"Feet","FeetSlot"},{"Wrist","WristSlot"},{"Hands","HandsSlot"},{"Finger 1","Finger0Slot"},{"Finger 2","Finger1Slot"},{"Trinket 1","Trinket0Slot"},{"Trinket 2","Trinket1Slot"},{"Back","BackSlot"},{"Main Hand","MainHandSlot"},{"Off Hand","SecondaryHandSlot"},{"Ranged","RangedSlot"},{"Tabard","TabardSlot"}}
local function safe(fn,...)
    if type(fn)~="function" then return end
    local ok,v=pcall(fn,...); if ok and not S.Secret(v) then return v end
end
function I.SlotID(label)
    for _,slot in ipairs(slots) do if slot[1]==label then
        local id=safe(GetInventorySlotInfo,slot[2]); if type(id)=="number" and id>=1 and id<=19 and id%1==0 then return id end
    end end
end
function I.Info(id)
    if not C_Item or not C_Item.GetItemInfo then return end
    local ok,name,link,quality,_,_,_,_,_,equipLoc,icon=pcall(C_Item.GetItemInfo,id)
    if not ok or S.Secret(name) or type(name)~="string" or S.Secret(quality) or S.Secret(equipLoc) or S.Secret(icon) then return end
    return {id=id,name=name,link=link,quality=quality,icon=icon or 134400,equippable=safe(C_Item.IsEquippableItem,id)==true,equipLoc=equipLoc}
end
function I.SetsAvailable()
    return C_EquipmentSet and type(C_EquipmentSet.GetEquipmentSetIDs)=="function" and type(C_EquipmentSet.GetEquipmentSetInfo)=="function" and safe(C_EquipmentSet.CanUseEquipmentSets)==true or false
end
function I.Refresh()
    I.entries={}; I.byID={}; I.sets={}; I.reason=nil
    local owned={}
    for _,slot in ipairs(slots) do local id=I.SlotID(slot[1]); local item=id and safe(GetInventoryItemID,"player",id); if type(item)=="number" then owned[item]=true end end
    if C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo then
        for bag=0,(NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4) do
            local num=safe(C_Container.GetContainerNumSlots,bag)
            if type(num)=="number" then for slot=1,num do
                local info=safe(C_Container.GetContainerItemInfo,bag,slot)
                if type(info)=="table" and not S.Secret(info.itemID) and type(info.itemID)=="number" then owned[info.itemID]=true end
            end end
        end
    else I.reason="Bag APIs are unavailable; only readable equipped items can be shown." end
    for id in pairs(owned) do
        local e=I.Info(id)
        if e then I.entries[#I.entries+1]=e; I.byID[id]=e
        elseif C_Item and C_Item.RequestLoadItemDataByID and not I.requested[id] then I.requested[id]=true; pcall(C_Item.RequestLoadItemDataByID,id) end
    end
    table.sort(I.entries,function(a,b) return a.name<b.name end)
    if I.SetsAvailable() then
        local ids=safe(C_EquipmentSet.GetEquipmentSetIDs)
        if type(ids)=="table" then for _,id in ipairs(ids) do
            local ok,name,icon=pcall(C_EquipmentSet.GetEquipmentSetInfo,id)
            if ok and not S.Secret(name) and type(name)=="string" then I.sets[tostring(id)]={id=id,name=name,icon=not S.Secret(icon) and icon or 134400} end
        end end
    end
end
function I.Search(query,equippable)
    local out={}; query=(query or ""):lower()
    for _,e in ipairs(I.entries) do if (not equippable or e.equippable) and e.name:lower():find(query,1,true) then out[#out+1]=e end end
    return out
end
function I.Resolve(value)
    local id=type(value)=="string" and value:match("^item:(%d+)$")
    id=tonumber(id)
    if id and I.byID[id] then return I.byID[id] end
    return nil,value=="" and "Select an item." or "Selected item is unavailable in your equipped gear or bags. Its saved identity is retained."
end
function I.Label(value)
    if value=="" then return "None - select item" end
    local e=I.Resolve(value); if e then return e.name end
    local id=type(value)=="string" and tonumber(value:match("^item:(%d+)$")); local old=id and I.Info(id)
    return (old and old.name or value).." (unavailable)"
end
function I.Cursor(equippable)
    if not GetCursorInfo then return nil,"Item dragging is unavailable." end
    local ok,kind,id=pcall(GetCursorInfo)
    if not ok or S.Secret(kind) or S.Secret(id) or kind~="item" then return nil,"Drag an owned item from a bag or equipment slot." end
    local e=I.byID[id]
    if not e then return nil,"This item is not available in your equipped gear or bags." end
    if equippable and not e.equippable then return nil,"This item cannot be equipped; choose an equippable item." end
    return e
end
