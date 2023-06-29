local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterServerEvent('ip_farm:server:giveitem')
AddEventHandler('ip_farm:server:giveitem', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    Player.Functions.AddItem(item, amount)
    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], "add", amount)
end)