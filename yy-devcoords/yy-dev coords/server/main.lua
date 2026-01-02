local Config = Config or {}

local function notify(src, message, nType)
    TriggerClientEvent('yy-devcoords:client:Notify', src, message, nType)
end

local function hasAllowlistAccess(src)
    local allowedIds = Config.AllowedIdentifiers or {}
    local allowedCids = Config.AllowedCitizenIds or {}

    if type(allowedIds) == 'string' then
        allowedIds = { allowedIds }
    end

    if #allowedIds > 0 then
        local identifiers = GetPlayerIdentifiers(src)
        for _, id in ipairs(identifiers) do
            local lowerId = string.lower(id)
            for _, allowed in ipairs(allowedIds) do
                if lowerId == string.lower(tostring(allowed)) then
                    return true
                end
            end
        end
    end

    if #allowedCids > 0 and exports.qbx_core and exports.qbx_core.GetPlayer then
        local player = exports.qbx_core:GetPlayer(src)
        if player and player.PlayerData and player.PlayerData.citizenid then
            local cid = tostring(player.PlayerData.citizenid)
            for _, allowed in ipairs(allowedCids) do
                if cid == tostring(allowed) then
                    return true
                end
            end
        end
    end

    return false
end

RegisterCommand(Config.Command or 'devcoords', function(source)
    local src = source
    if src == 0 then return end
    if not hasAllowlistAccess(src) then
        notify(src, 'You do not have permission to use this command.', 'error')
        return
    end
    TriggerClientEvent('yy-devcoords:client:Toggle', src)
end, false)
