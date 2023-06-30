local RSGCore = exports['rsg-core']:GetCoreObject()
local Zones = {}
local zonename = nil
local inFarmZone = false
local spawnedAnimals = {}
local milkingAnimaton = 'mini_games@story@mar5@milk_cow'
local milkingAnim = 'milk_idle'
local animals = {
    'a_c_cow',
}

CreateThread(function()
    for k=1, #Config.FarmZoneMilk do
        Zones[k] = PolyZone:Create(Config.FarmZoneMilk[k].zones, {
            name = Config.FarmZoneMilk[k].name,
            minZ = Config.FarmZoneMilk[k].minz,
            maxZ = Config.FarmZoneMilk[k].maxz,
            debugPoly = false,
        })
        Zones[k]:onPlayerInOut(function(isPointInside)
            if isPointInside then
                inFarmZone = true
                zonename = Zones[k].name
                exports['rsg-target']:AddTargetModel(animals, {
                    options = {
                        {
                            type = 'client',
                            event = 'ip_farm:client:milking',
                            label = 'Collect Milk',
                        }
                    },
                    distance = 2.5,
                })
            else
                exports['rsg-target']:RemoveTargetModel(animals, 'Collect Milk')
                DeleteAnimals()
                inFarmZone = false
            end
        end)
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        if inFarmZone == true and zonename == 'farm1' then
            for z, x in pairs(Config.AnimalFarmz) do
                lib.requestModel(GetHashKey(Config.AnimalFarmz[z].Model))
                local animals = CreatePed(GetHashKey(Config.AnimalFarmz[z].Model), Config.AnimalFarmz[z].Pos.x, Config.AnimalFarmz[z].Pos.y, Config.AnimalFarmz[z].Pos.z, Config.AnimalFarmz[z].Heading, true, false, 0, 0)
                while not DoesEntityExist(animals) do
                    Wait(300)
                end
                Citizen.InvokeNative(0x283978A15512B2FE, animals, true)
                Citizen.InvokeNative(0xAEB97D84CDF3C00B, animals, true)
                Citizen.InvokeNative(0x3B005FF0538ED2A9, animals, true)
                SetEntityAsMissionEntity(animals, true, false)
                table.insert(spawnedAnimals, animals)
            end
            Wait(300000) -- Wait 5 menit before spawn again
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        for i = #spawnedAnimals, 1, -1 do
            if not DoesEntityExist(spawnedAnimals[i]) or IsEntityDead(spawnedAnimals[i]) then
                DeleteEntity(spawnedAnimals[i])
                table.remove(spawnedAnimals, i)
            end
        end
    end
end)

function DeleteAnimals()
    Wait(5000)
    while #spawnedAnimals > 0 do
        local animal = table.remove(spawnedAnimals)
        DeletePed(animal)
        Wait(500)
    end
end

-- function loadAnimDict(dict)
--     if not HasAnimDictLoaded(dict) then
--         RequestAnimDict(dict)
--         while not HasAnimDictLoaded(dict) do
--             Citizen.Wait(0)
--         end
--     end
-- end

AddEventHandler('ip_farm:client:milkinganimation', function()
    lib.requestAnimDict(milkingAnimaton)
    TaskPlayAnim(cache.ped, milkingAnimaton, milkingAnim, 3.0, 3.0, -1, 1, 0, false, false, false)
end)

local milkingCooldown = {} -- tabel untuk menyimpan hewan yang telah diperas

RegisterNetEvent('ip_farm:client:milking')
AddEventHandler('ip_farm:client:milking', function()

    -- local item1 = 'weapon_melee_machete'
    -- local hasItem1 = RSGCore.Functions.HasItem(item1, 1)
    local weapon = Citizen.InvokeNative(0x8425C5F057012DAB, cache.ped)
    if weapon == 0x28950C71 and inFarmZone then
        local nearbyAnimals = {}
        local playerPos = GetEntityCoords(cache.ped)
        for _, animal in ipairs(spawnedAnimals) do
            local distance = #(playerPos - GetEntityCoords(animal))
            if distance <= 3.5 and not IsEntityDead(animal) and not milkingCooldown[animal] then
                table.insert(nearbyAnimals, animal)
            end
        end
        if #nearbyAnimals > 0 then
            TriggerEvent('ip_farm:client:milkinganimation')
            RSGCore.Functions.Progressbar("milking", 'Milking', 10000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function()
                local animal = nearbyAnimals[1]
                TriggerServerEvent('ip_farm:server:giveitem', 'milk', math.random(2,5))
                ClearPedTasks(cache.ped)
                FreezeEntityPosition(cache.ped, false)
                milkingCooldown[animal] = true
                SetTimeout(5000, function()
                    milkingCooldown[animal] = DeleteEntity(animal)
                end)
            end)
        else
            TriggerEvent("ip-core:NotifyLeft", "Farmer", "There are no animals nearby or they are dead, or in cooldown.", 'satchel_textures', 'animal_cow', 4000)
        end
    else
        TriggerEvent("ip-core:NotifyLeft", "Farmer", "You can't do this", 'multiwheel_emotes', 'emote_reaction_thumbsdown', 4000)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        DeleteAnimals()
    end
end)
