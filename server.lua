RegisterServerEvent('server:spawnPed')
AddEventHandler('server:spawnPed', function(hash, type)
	local serverId = source
	TriggerClientEvent('client:createPed', serverId, serverId, hash, type)
end)

RegisterServerEvent('server:registerPet')
AddEventHandler('server:registerPet', function(handle, hash, name, showName)
	local serverId = source
	TriggerClientEvent('client:registerPet', -1, serverId, handle, hash, name, showName)
end)

RegisterServerEvent('server:deletePed')
AddEventHandler('server:deletePed', function()
	local serverId = source
	TriggerClientEvent('client:deletePed', -1, serverId)
end)

RegisterServerEvent('server:teleportPed')
AddEventHandler('server:teleportPed', function ()
	local serverId = source
	TriggerClientEvent('client:teleportPed', -1, serverId)
end)