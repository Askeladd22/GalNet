if x4native_api and x4native_api.log then
    x4native_api.log(1, "[GNN Lua] gnn_market_emit.lua loaded")
else
    DebugError("[GNN Lua] gnn_market_emit.lua loaded")
end

local function register_gnn_market_emit_listener()
    RegisterEvent("gnn.market.emit", function(_, arg)
        local payload = arg ~= nil and tostring(arg) or ""
        if x4native_api and x4native_api.log then
            x4native_api.log(1, "[GNN Lua] received gnn.market.emit payload=" .. payload)
        else
            DebugError("[GNN Lua] received gnn.market.emit payload=" .. payload)
        end
    end)
end

register_gnn_market_emit_listener()
