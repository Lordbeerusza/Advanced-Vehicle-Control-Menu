local QBCore = exports['qb-core']:GetCoreObject()

-- Detect proximity to vehicle and trigger vehicle control menu
local proximityRadius = 5.0  -- Radius around player to detect vehicle proximity
local keyBinding = 311  -- K key

-- Open Vehicle Remote Menu with K key if near vehicle
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustPressed(0, keyBinding) then
            local playerPed = PlayerPedId()
            local pos = GetEntityCoords(playerPed)
            local vehicle = GetClosestVehicle(pos.x, pos.y, pos.z, proximityRadius, 0, 71)

            if vehicle ~= 0 then
                QBCore.Functions.Notify("Opening vehicle control menu", 'primary')

                -- Compact qb-menu with only icons and minimal text
                exports['qb-menu']:openMenu({
                    {
                        header = "🚗 Vehicle Control Menu",
                        isMenuHeader = true
                    },
                    {
                        header = "🔑 Engine On/Off",
                        txt = "",
                        icon = "fa-solid fa-car",
                        params = {
                            event = "vehControl:toggleEngine",
                            args = { vehicle = vehicle }
                        }
                    },
                    {
                        header = "💡 Lights On/Off/Low/HighBeam",
                        txt = "",
                        icon = "fa-solid fa-lightbulb",
                        params = {
                            event = "vehControl:cycleLights",
                            args = { vehicle = vehicle }
                        }
                    },
                    {
                        header = "🌈 Neons On/Off",
                        txt = "",
                        icon = "fa-solid fa-rainbow",
                        params = {
                            event = "vehControl:toggleNeons",
                            args = { vehicle = vehicle }
                        }
                    },
                    {
                        header = "🪟 Windows Up/Down",
                        txt = "",
                        icon = "fa-solid fa-wind",
                        params = {
                            event = "vehControl:toggleWindows",
                            args = { vehicle = vehicle }
                        }
                    },
                    {
                        header = "🚪 Doors Open/Close",
                        txt = "",
                        icon = "fa-solid fa-door-open",
                        params = {
                            event = "vehControl:toggleDoors",
                            args = { vehicle = vehicle }
                        }
                    },
                    {
                        header = "💥 Hydraulics",
                        txt = "",
                        icon = "fa-solid fa-arrow-up",
                        params = {
                            event = "vehControl:toggleHydraulics",
                            args = { vehicle = vehicle }
                        }
                    },
                    {
                        header = "🛠️ Bonnet Open/Close",
                        txt = "",
                        icon = "fa-solid fa-warehouse",
                        params = {
                            event = "vehControl:toggleBonnet",
                            args = { vehicle = vehicle }
                        }
                    },
                    {
                        header = "📦 Trunk Open/Close",
                        txt = "",
                        icon = "fa-solid fa-box-open",
                        params = {
                            event = "vehControl:toggleTrunk",
                            args = { vehicle = vehicle }
                        }
                    }
                })
            else
                QBCore.Functions.Notify("No vehicle nearby!", 'error')
            end
        end
    end
end)

-- Toggle Engine
RegisterNetEvent('vehControl:toggleEngine', function(data)
    local vehicle = data.vehicle
    if DoesEntityExist(vehicle) then
        local engineStatus = GetIsVehicleEngineRunning(vehicle)
        
        -- Toggle engine state
        SetVehicleEngineOn(vehicle, not engineStatus, true, true)
        
        -- To handle vehicles that aren't being driven, we need to manually manage engine state
        if engineStatus then
            SetVehicleUndriveable(vehicle, true)  -- Disable vehicle when engine is off
            SetVehicleEngineOn(vehicle, false, true, true)  -- Turn engine off
        else
            SetVehicleUndriveable(vehicle, false)  -- Enable vehicle when engine is on
            SetVehicleEngineOn(vehicle, true, true, true)  -- Turn engine on
        end

        QBCore.Functions.Notify(engineStatus and "Engine turned off" or "Engine turned on", 'primary')
    else
        QBCore.Functions.Notify("No vehicle nearby!", 'error')
    end
end)

-- Variable to store the current light state
local lightState = 0  -- 0 = off, 1 = headlights, 2 = high beams

-- Toggle Headlights (cycleLights function)
RegisterNetEvent('vehControl:cycleLights', function(data)
    local vehicle = data.vehicle
    if vehicle ~= 0 then
        if lightState == 0 then
            SetVehicleLights(vehicle, 2)  -- Normal headlights
            SetVehicleFullbeam(vehicle, false)
            lightState = 1
            QBCore.Functions.Notify("Low beams (headlights) turned on", 'primary')
        elseif lightState == 1 then
            SetVehicleFullbeam(vehicle, true)  -- High beams on
            lightState = 2
            QBCore.Functions.Notify("High beams turned on", 'primary')
        else
            SetVehicleLights(vehicle, 0)  -- All lights off
            SetVehicleFullbeam(vehicle, false)
            lightState = 0
            QBCore.Functions.Notify("All lights turned off", 'primary')
        end
    end
end)

-- Toggle Doors
RegisterNetEvent('vehControl:toggleDoors', function(data)
    local vehicle = data.vehicle
    if vehicle ~= 0 then
        local doorIndex = {0, 1, 2, 3}
        for _, index in ipairs(doorIndex) do
            if GetVehicleDoorAngleRatio(vehicle, index) > 0 then
                SetVehicleDoorShut(vehicle, index, false)
            else
                SetVehicleDoorOpen(vehicle, index, false, false)
            end
        end
        QBCore.Functions.Notify("Toggling doors", 'primary')
    end
end)

-- Toggle Neons
RegisterNetEvent('vehControl:toggleNeons', function(data)
    local vehicle = data.vehicle
    if vehicle ~= 0 then
        for i = 0, 3 do
            local isNeonOn = IsVehicleNeonLightEnabled(vehicle, i)
            SetVehicleNeonLightEnabled(vehicle, i, not isNeonOn)
        end
        QBCore.Functions.Notify("Neon lights toggled", 'success')
    end
end)

-- Roll Windows Up/Down
RegisterNetEvent('vehControl:toggleWindows', function(data)
    local vehicle = data.vehicle
    if vehicle ~= 0 then
        local rolledUp = IsVehicleWindowIntact(vehicle, 0)
        for i = 0, 3 do
            if rolledUp then
                RollDownWindow(vehicle, i)
            else
                RollUpWindow(vehicle, i)
            end
        end
        QBCore.Functions.Notify(rolledUp and "Windows rolled down" or "Windows rolled up", 'success')
    end
end)

-- Toggle Hydraulics
RegisterNetEvent('vehControl:toggleHydraulics', function(data)
    local vehicle = data.vehicle
    if vehicle ~= 0 then
        local hasHydraulics = IsVehicleModel(vehicle, `LOWRIDER`)
        if hasHydraulics then
            local isHydraulicsActive = GetVehicleSuspensionHeight(vehicle) < 0.1
            if isHydraulicsActive then
                SetVehicleSuspensionHeight(vehicle, 0.2)
                QBCore.Functions.Notify("Hydraulics deactivated", 'warning')
            else
                SetVehicleSuspensionHeight(vehicle, -0.2)
                QBCore.Functions.Notify("Hydraulics activated", 'success')
            end
        else
            QBCore.Functions.Notify("This vehicle doesn't support hydraulics", 'error')
        end
    end
end)

-- Toggle Bonnet (Hood)
RegisterNetEvent('vehControl:toggleBonnet', function(data)
    local vehicle = data.vehicle
    if vehicle ~= 0 then
        local isBonnetOpen = GetVehicleDoorAngleRatio(vehicle, 4) > 0.1
        if isBonnetOpen then
            SetVehicleDoorShut(vehicle, 4, false)
            QBCore.Functions.Notify("Bonnet (hood) closed", 'success')
        else
            SetVehicleDoorOpen(vehicle, 4, false, false)
            QBCore.Functions.Notify("Bonnet (hood) opened", 'success')
        end
    end
end)

-- Toggle Trunk
RegisterNetEvent('vehControl:toggleTrunk', function(data)
    local vehicle = data.vehicle
    if vehicle ~= 0 then
        local isTrunkOpen = GetVehicleDoorAngleRatio(vehicle, 5) > 0.1
        if isTrunkOpen then
            SetVehicleDoorShut(vehicle, 5, false)
            QBCore.Functions.Notify("Trunk closed", 'success')
        else
            SetVehicleDoorOpen(vehicle, 5, false, false)
            QBCore.Functions.Notify("Trunk opened", 'success')
        end
    end
end)
