
local VorpCore = {}

TriggerEvent("getCore",function(core)
    VorpCore = core
end)


RegisterCommand('scenarios', function(source)
    local _source = source
    TriggerClientEvent("xakra_scenarios:open_menu", _source)
end)

RegisterCommand('cscenario', function(source)
    local _source = source
    TriggerClientEvent("xakra_scenarios:close_menu", _source)
end)
