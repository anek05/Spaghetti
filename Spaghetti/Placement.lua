local _, S = ...
local P={WIDTH=1700,HEIGHT=1200,GAP=48}; S.Placement=P
function P.Size(n)
    local d=S.Definition(n)
    if not d then return 214,100 end
    local inputs,outputs=#S.SortedKeys(d.inputs),#S.SortedKeys(d.outputs)
    return 214,40+math.max(inputs,outputs)*24+#d.fields*44+15
end
function P.Find(g,n,anchor,dimensions,viewX,viewY)
    local w,h=dimensions(n)
    local candidates={}
    local a=anchor and g.nodes[anchor]
    if a then
        local aw=dimensions(a); candidates[#candidates+1]={x=a.x+aw+P.GAP,y=a.y}
    else candidates[#candidates+1]={x=viewX or 40,y=viewY or 50} end
    local function free(x,y)
        if x<12 or y<32 or x+w>P.WIDTH-12 or y+h>P.HEIGHT-12 then return false end
        for _,other in pairs(g.nodes) do if other.id~=n.id then
            local ow,oh=dimensions(other)
            if x<other.x+ow+24 and x+w+24>other.x and y<other.y+oh+24 and y+h+24>other.y then return false end
        end end
        return true
    end
    if free(candidates[1].x,candidates[1].y) then return candidates[1].x,candidates[1].y end
    local origin=candidates[1]
    for y=40,P.HEIGHT-h-12,24 do for x=16,P.WIDTH-w-12,24 do candidates[#candidates+1]={x=x,y=y} end end
    table.remove(candidates,1)
    table.sort(candidates,function(a,b) return (a.x-origin.x)^2+(a.y-origin.y)^2<(b.x-origin.x)^2+(b.y-origin.y)^2 end)
    for _,c in ipairs(candidates) do if free(c.x,c.y) then return c.x,c.y end end
    return nil,"No free space remains on this canvas. Move or remove a node, then try again; existing nodes were not moved."
end
