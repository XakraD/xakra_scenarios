
local VorpCore = {}

TriggerEvent("getCore",function(core)
    VorpCore = core
end)


RegisterCommand('scenarios', function(source)
    local _source = source
    TriggerClientEvent("xakra_scenarios:open_menu", _source)
end)

