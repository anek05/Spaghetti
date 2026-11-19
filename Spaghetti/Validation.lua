local _, S = ...
local V={}; S.Validation=V
local function category(message)
    if message:find("unsupported",1,true) or message:find("UNKNOWN",1,true) then return "Unsupported API" end
    if message:find("unavailable",1,true) or message:find("not in the current",1,true) then return "Unavailable selection" end
    if message:find("connect",1,true) and not message:find("disconnected",1,true) then return "Missing / incompatible connection" end
    if message:find("macro",1,true) or message:find("Branch",1,true) or message:find("terminal",1,true) then return "Macro compiler" end
    return "Configuration"
end
function V.Report(g,errors,warnings,rejection)
    local r={nodes={},edges={},ports={},messages={}}
    local function node(id,message,severity,kind)
        if not g.nodes[id] then return end
        local current=r.nodes[id]
        if not current or current.severity~="error" then r.nodes[id]={message=message,severity=severity,category=kind} end
    end
    local function add(message,severity)
        local kind=category(message); r.messages[#r.messages+1]=kind..": "..message
        local id=message:match("^([^:]+):")
        local edge=message:match("^Connection ([^:]+):")
        if edge and g.connections[edge] then
            r.edges[edge]=true; local c=g.connections[edge]
            node(c.from,message,severity,"Connection type"); node(c.to,message,severity,"Connection type")
            r.ports[c.from..":out:"..c.output]=true; r.ports[c.to..":in:"..c.input]=true
        elseif id and g.nodes[id] then node(id,message,severity,kind)
        elseif severity=="error" then for nid in pairs(g.nodes) do node(nid,message,severity,kind) end end
    end
    for _,s in ipairs(errors or {}) do add(s,"error") end
    for _,s in ipairs(warnings or {}) do add(s,"warning") end
    if rejection then
        node(rejection.node,rejection.message,"error","Rejected connection change")
        for id in pairs(rejection.edges or {}) do r.edges[id]=true end
        for key in pairs(rejection.ports or {}) do r.ports[key]=true end
        r.messages[#r.messages+1]=rejection.message
    end
    return r
end
