local insideApartment = false
local currentApt = nil

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)

        for id, apt in pairs(Config.Apartments) do
            local dist = #(pos - apt.entrance)
            if dist < 2.0 then
                sleep = 0
                DrawText3D(apt.entrance.x, apt.entrance.y, apt.entrance.z, "[E] Enter | [G] Buy (" .. apt.price .. ")")
                if IsControlJustPressed(0, 38) then -- E
                    TriggerServerEvent("apartment:enter", id)
                elseif IsControlJustPressed(0, 47) then -- G
                    TriggerServerEvent("apartment:buy", id)
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent("apartment:entered", function(interiorCoords, heading)
    local ped = PlayerPedId()
    SetEntityCoords(ped, interiorCoords)
    SetEntityHeading(ped, heading)
    insideApartment = true
end)

RegisterNetEvent("apartment:exited", function()
    insideApartment = false
    -- optionally teleport to entrance
    -- handled on server if needed
end)

-- handle invite
RegisterNetEvent("apartment:invited", function(ownerId, apartmentId, bucket)
    local apt = Config.Apartments[apartmentId]
    TriggerEvent("chat:addMessage", {
        args = {"Apartment", "Player " .. ownerId .. " invited you to their apartment! Press [E] to accept."}
    })

    CreateThread(function()
        local start = GetGameTimer()
        while GetGameTimer() - start < 10000 do -- 10 seconds
            if IsControlJustPressed(0, 38) then
                TriggerServerEvent("apartment:acceptInvite", ownerId, apartmentId, bucket)
                return
            end
            Wait(0)
        end
    end)
end)

-- Exit key inside apartment
CreateThread(function()
    while true do
        Wait(0)
        if insideApartment and IsControlJustPressed(0, 38) then
            TriggerServerEvent("apartment:exit")
        end
    end
end)

function DrawText3D(x, y, z, text)
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
