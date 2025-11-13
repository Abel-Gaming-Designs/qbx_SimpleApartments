local ownedApts = {}
local playerBuckets = {}
local nextBucketId = 1000 -- start high to avoid world conflicts

-- Load apartments on resource start
CreateThread(function()
    local result = MySQL.query.await("SELECT * FROM apartments", {})
    for _, row in ipairs(result or {}) do
        ownedApts[row.owner] = {
            id = row.apartment_id,
            bucket = row.bucket
        }
    end
    print(("[Apartments] Loaded %s owned apartments."):format(#(result or {})))
end)

-- Buy an apartment
RegisterNetEvent("apartment:buy", function(apartmentId)
    local src = source
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return end

    local apt = Config.Apartments[apartmentId]
    if not apt then return end

    if ownedApts[Player.PlayerData.citizenid] then
        TriggerClientEvent("QBX:Notify", src, "You already own an apartment!", "error")
        return
    end

    local money = Player.Functions.GetMoney("bank") or 0
    if money < apt.price then
        print('Not enough money')
        TriggerClientEvent("QBX:Notify", src, "Not enough money in your bank account.", "error")
        return
    end

    Player.Functions.RemoveMoney("bank", apt.price, "purchased-apartment")

    local bucket = nextBucketId
    nextBucketId += 1

    MySQL.insert.await("INSERT INTO apartments (owner, apartment_id, bucket) VALUES (?, ?, ?)", {
        Player.PlayerData.citizenid, apartmentId, bucket
    })

    ownedApts[Player.PlayerData.citizenid] = { id = apartmentId, bucket = bucket }

    TriggerClientEvent("QBX:Notify", src, "You purchased your apartment!", "success")
end)

-- Enter your apartment
RegisterNetEvent("apartment:enter", function()
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    local owned = ownedApts[Player.PlayerData.citizenid]
    if not owned then
        TriggerClientEvent("QBX:Notify", src, "You don't own an apartment!", "error")
        return
    end

    local apt = Config.Apartments[owned.id]
    if not apt then return end

    SetPlayerRoutingBucket(src, owned.bucket)
    playerBuckets[src] = owned.bucket

    TriggerClientEvent("apartment:entered", src, apt.interior, apt.heading)
end)

-- Invite another player
RegisterNetEvent("apartment:invite", function(targetId)
    local src = source
    local target = tonumber(targetId)
    if not GetPlayerName(target) then return end

    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    local owned = ownedApts[Player.PlayerData.citizenid]
    if not owned then return end

    TriggerClientEvent("apartment:invited", target, src, owned.id, owned.bucket)
end)

-- Accept invite
RegisterNetEvent("apartment:acceptInvite", function(ownerId, apartmentId, bucket)
    local src = source
    SetPlayerRoutingBucket(src, bucket)
    playerBuckets[src] = bucket
    local apt = Config.Apartments[apartmentId]
    if apt then
        TriggerClientEvent("apartment:entered", src, apt.interior, apt.heading)
    end
end)

-- Exit apartment
RegisterNetEvent("apartment:exit", function()
    local src = source
    SetPlayerRoutingBucket(src, 0)
    playerBuckets[src] = nil
    TriggerClientEvent("apartment:exited", src)
end)

-- Cleanup on disconnect
AddEventHandler("playerDropped", function(source)
    playerBuckets[source] = nil
end)
