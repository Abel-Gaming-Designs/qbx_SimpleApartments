local insideApartment = false
local currentApt = nil
local exitPos = vector3(266.0, -1007.0, -101.0) -- fallback; will update when entering
local entrancePos = nil

-- Draw Text Helper
local function DrawText3D(x, y, z, text)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

-- Main loop for apartment entrances
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)

        if not insideApartment then
            for id, apt in pairs(Config.Apartments) do
                local dist = #(pos - apt.entrance)
                if dist < 2.0 then
                    sleep = 0
                    DrawText3D(apt.entrance.x, apt.entrance.y, apt.entrance.z, "[E] Enter | [G] Buy ($" .. apt.price .. ")")
                    if IsControlJustPressed(0, 38) then -- E
                        entrancePos = apt.entrance
                        TriggerServerEvent("apartment:enter", id)
                    elseif IsControlJustPressed(0, 47) then -- G
                        TriggerServerEvent("apartment:buy", id)
                    end
                end
            end
        else
            -- Inside apartment: show exit marker
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local dist = #(pos - exitPos)

            if dist < 2.0 then
                sleep = 0
                DrawText3D(exitPos.x, exitPos.y, exitPos.z, "[E] Exit Apartment")
                if IsControlJustPressed(0, 38) then
                    TriggerServerEvent("apartment:exit")
                end
            end
        end

        Wait(sleep)
    end
end)

-- When server tells player they entered apartment
RegisterNetEvent("apartment:entered", function(interiorCoords, heading)
    SetEntityCoords(PlayerPedId(), interiorCoords)
    SetEntityHeading(PlayerPedId(), heading)
    exitPos = interiorCoords
    insideApartment = true
end)

-- When server confirms exit
RegisterNetEvent("apartment:exited", function()
    insideApartment = false
    if entrancePos then
        SetEntityCoords(PlayerPedId(), entrancePos)
    end
    TriggerEvent("QBX:Notify", "You have exited your apartment.", "inform")
end)

-- Handle invites (unchanged)
RegisterNetEvent("apartment:invited", function(ownerId, apartmentId, bucket)
    local apt = Config.Apartments[apartmentId]
    TriggerEvent("QBX:Notify", "Player " .. ownerId .. " invited you to their apartment. Press [E] to accept.", "inform")

    CreateThread(function()
        local start = GetGameTimer()
        while GetGameTimer() - start < 10000 do
            if IsControlJustPressed(0, 38) then
                TriggerServerEvent("apartment:acceptInvite", ownerId, apartmentId, bucket)
                return
            end
            Wait(0)
        end
    end)
end)
