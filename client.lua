local TOGGLE_KEY = 318

local pets = {
	["Cat"] = 1462895032,
	["Husky"] = 1318032802,
	["Pug"] = 1832265812,
	["Poodle"] = 1125994524,
	["Rottweiler"] = -1788665315,
	["Retriever"] = 882848737,
	["Shepherd"] = 1126154828,
	["Westy"] = -1384627013,
    ["Boar"] = 3462393972,
    ["Chickenhawk"] = 2864127842,
    ["Chimp"] = 2825402133,
    ["Chop"] = 351016938,
    ["Cormorant"] = 1457690978,
    ["Cow"] = 4244282910,
    ["Coyote"] = 1682622302,
    ["Crow"] = 402729631,
    ["Deer"] = 3630914197,
    ["Fish"] = 802685111,
    ["Hen"] = 1794449327,
    ["MtLion"] = 307287994,
    ["Pig"] = 2971380566,
    ["Pigeon"] = 111281960,
    ["Rat"] = 3283429734,
    ["Rhesus"] = 3268439891,
    ["Seagull"] = 3549666813,
    ["SharkTiger"] = 113504370,
}

local my_pet ={
	handle = nil,
	hash = pets["Husky"],
	name = "",
	showName = false,
}

local other_pets = {}

RegisterNetEvent('client:createPed')
AddEventHandler('client:createPed', function(serverId, hash, type)
	if GetPlayerServerId(PlayerId()) == serverId then
		local playerPed = GetPlayerPed(GetPlayerFromServerId(serverId))
		local x,y,z = table.unpack(GetOffsetFromEntityInWorldCoords(playerPed, 0, 0.5, 0))
		local pos = {x = x, y = y, z = z, rot = 0}

		RequestModel(hash)

		while not HasModelLoaded(hash) do
			Citizen.Wait(1)
		end

		local handle = CreatePed(type, hash, pos.x, pos.y, pos.z, GetEntityHeading(playerPed), true, false)

		SetBlockingOfNonTemporaryEvents(handle, true)
		SetEntityInvincible(handle, true)
		SetPedFleeAttributes(handle, 0, 0)
		SetModelAsNoLongerNeeded(hash)

		my_pet.handle = handle

		-- Adds the pet for other users  --
		TriggerServerEvent('server:registerPet',  my_pet.hash, my_pet.handle, my_pet.name, my_pet.showName)
	end
end)

RegisterNetEvent('client:registerPet')
AddEventHandler('client:registerPet', function(serverId, hash, handle, name, showName)
	if GetPlayerServerId(PlayerId()) ~= serverId then -- We do not update the local user
		other_pets[serverId] = {
			hash = hash,
			handle = handle,
			name = name,
			showName = showName
		}
	end
end)

RegisterNetEvent('client:deletePed')
AddEventHandler('client:deletePed', function(serverId)
	if GetPlayerServerId(PlayerId()) == serverId then
		local has_control = false

		RequestNetworkControl(function(cb)
			has_control = cb
		end)

		if has_control then
			SetEntityAsMissionEntity(my_pet.handle, true, true)
			DeleteEntity(my_pet.handle)
			my_pet.handle = nil
		end
	end
end)

RegisterNetEvent('client:teleportPed')
AddEventHandler('client:teleportPed', function(serverId)
	local handle = my_pet.handle

	if GetPlayerServerId(PlayerId()) == serverId and handle ~= nil then
		local playerPed = GetPlayerPed(GetPlayerFromServerId(serverId))
		local has_control = false
		local x,y,z = table.unpack(GetOffsetFromEntityInWorldCoords(playerPed, 0, 0.5, 0))

		RequestNetworkControl(function(cb)
			has_control = cb
		end)

		if has_control and DoesEntityExist(handle) then
			if IsPedInAnyVehicle(playerPed, true) then
				local car = GetVehiclePedIsUsing(playerPed)

				for i = 1, GetVehicleMaxNumberOfPassengers(car) do
					if IsVehicleSeatFree(car, i) then
						TaskWarpPedIntoVehicle(my_pet.handle, car, i)
						break
					else
						SetEntityCoordsNoOffset(my_pet.handle, x, y, z) -- Still teleports the pet to the current location of the vehicle.
						Notify('~r~Vehicle is full! Please find another vehicle.')
					end
				end
			else
				SetEntityCoordsNoOffset(my_pet.handle, x, y, z)
			end
		end
	end
end)

--+++++++
-- MENU +
--+++++++
Citizen.CreateThread(function()
	CreateWarMenu('PET_MENU', 'PET MENU', 'PET MENU')
	CreateWarSubMenu('PET_SPAWN', 'PET_MENU', 'PET LIST', tablelength(pets).." PETS AVAILABLE", {0.7, 0.1}, 1.0, {75,175,50,255})

	while true do Wait(0)
		local showName = "Off"

		if my_pet.showName then
			showName = "On"
		end

		if IsControlJustReleased(0, TOGGLE_KEY) then
			WarMenu.OpenMenu('PET_MENU')
		end
		if WarMenu.IsMenuOpened('PET_MENU') then
			if WarMenu.MenuButton('Spawn Pet', 'PET_SPAWN') then
			elseif WarMenu.Button('Rename Pet', my_pet.name) then
				local name = Input(my_pet.name)
				if name ~= nil or name ~= '' then
					my_pet.name = name
					TriggerServerEvent('server:registerPet', my_pet.handle, my_pet.hash, my_pet.name, my_pet.showName)
				else
					my_pet.name = ''
					TriggerServerEvent('server:registerPet', my_pet.handle, my_pet.hash, my_pet.name, my_pet.showName)
					Notify('~r~Invalid Name!')
				end
			elseif WarMenu.Button('Toggle Name', showName) then
				my_pet.showName = not my_pet.showName
				TriggerServerEvent('server:registerPet', my_pet.handle, my_pet.hash, my_pet.name, my_pet.showName)
			elseif WarMenu.Button('Teleport to Player') then
				TriggerServerEvent('server:teleportPed')
			elseif WarMenu.Button('~r~Delete Pet') then
				TriggerServerEvent('server:deletePed')
			end
			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('PET_SPAWN') then
			for key, value in pairs(pets) do
				if WarMenu.Button(key) then
					if my_pet.handle == nil then
						-- 28 = Animal, list here: https://github.com/jorjic/fivem-docs/wiki/Ped-Types-&-Relationships
						TriggerServerEvent('server:spawnPed', tonumber(value), 28)
					else
						Notify("~r~Delete your current pet!")
					end
				end
			end
			WarMenu.Display()
		end

		-- TODO: Check if we can use MpGamerTag for npc ped models
		if my_pet.handle ~= nil and my_pet.showName then
			aPos = GetEntityCoords(my_pet.handle)
			DrawText3d(aPos.x, aPos.y, aPos.z + 0.7, 0.5, 0, "~g~[" .. GetPlayerName(PlayerId()) .. "'s Pet]", 255, 255, 255, false)
			DrawText3d(aPos.x, aPos.y, aPos.z + 0.6, 0.5, 0, my_pet.name, 255, 255, 255, false)
		end

		for key, value in pairs(other_pets) do
			if value.handle ~= nil and value.showName then
				aPos = GetEntityCoords(value.handle)
				DrawText3d(aPos.x, aPos.y, aPos.z + 0.7, 0.5, 0, "~g~[" .. GetPlayerName(key) .. "'s Pet]", 255, 255, 255, false)
				DrawText3d(aPos.x, aPos.y, aPos.z + 0.6, 0.5, 0, my_pet.name, 255, 255, 255, false)
			end
		end
	end
end)

--+++++++++++++++++++++++++++++
-- F O L L O W      O W N E R +
--+++++++++++++++++++++++++++++
Citizen.CreateThread(function()
	while true do Wait(100)
		if my_pet.handle ~= nil then
			local has_control = false
			RequestNetworkControl(function(cb)
				has_control = cb
			end)
			if has_control then
				local x,y,z = table.unpack(GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0, -0.5, 0))
				local a,b,c = table.unpack(GetEntityCoords(my_pet.handle))
				local dist = Vdist(x, y, z, a, b, c)

				-- TODO: When player is in vehicle, make ped get into vehicle.
				if dist <= 2.5 and IsPedInAnyVehicle(GetPlayerPed(-1), true) and not IsPedInAnyVehicle(my_pet.handle, true) then
					local car = GetVehiclePedIsUsing(GetPlayerPed(-1))

					for i = 1, GetVehicleMaxNumberOfPassengers(car) do
						if IsVehicleSeatFree(car, i) then
							-- https://runtime.fivem.net/doc/natives/#_0xC20E50AA46D09CA8
							TaskEnterVehicle(my_pet.handle, car, 60, 0, 2)
							break
						end
					end
				elseif dist > 2.5 then
					TaskGoToCoordAnyMeans(my_pet.handle, x, y, z, 10.0, 0, 0, 0, 0)
					while dist > 2.5 do Wait(0)
						if my_pet.handle == nil then break end
						a,b,c = table.unpack(GetEntityCoords(my_pet.handle))
						dist = Vdist(x, y, z, a, b, c)
					end
				end
			end
		end
	end
end)

--++++++++++++
-- F U N C S +
--++++++++++++
function Notify(text)
	SetNotificationTextEntry('STRING')
	AddTextComponentString(text)
	DrawNotification(true, false)
end

function Input(help)
	local var = ''
	DisplayOnscreenKeyboard(6, "FMMC_KEY_TIP8", "", help, "", "", "", 60)
	while UpdateOnscreenKeyboard() == 0 do
		DisableAllControlActions(0)
		Citizen.Wait(0)
	end
	if GetOnscreenKeyboardResult() then
		var = GetOnscreenKeyboardResult()
	end
	return var
end

-- Credit to xander1998 for this function --
function RequestNetworkControl(callback)
    local netId = NetworkGetNetworkIdFromEntity(my_pet.handle)
    local timer = 0
    NetworkRequestControlOfNetworkId(netId)
    while not NetworkHasControlOfNetworkId(netId) do
        Citizen.Wait(1)
        NetworkRequestControlOfNetworkId(netId)
        timer = timer + 1
        if timer == 5000 then
            Citizen.Trace("Control failed")
            callback(false)
            break
        end
    end
    callback(true)
end

function CreateWarMenu(id, title, subtitle)--, pos, width, rgba)
	--local x,y = table.unpack(pos)
	--local r,g,b,a = table.unpack(rgba)
	WarMenu.CreateMenu(id, title)
	WarMenu.SetSubTitle(id, subtitle)
	--WarMenu.SetMenuX(id, x)
	--WarMenu.SetMenuY(id, y)
	--WarMenu.SetMenuWidth(id, width)
	--WarMenu.SetTitleBackgroundColor(id, r, g, b, a)
	--WarMenu.SetTitleColor(id, 255, 255, 255, a)
end

function CreateWarSubMenu(id, base, title, subtitle)
	WarMenu.CreateSubMenu(id, base, title)
	WarMenu.SetSubTitle(id, subtitle)
end

function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function DrawText3d(x,y,z, size, font, text, r, g, b, outline)
	local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)

    local scale = (1/dist)*2
    local fov = (1/GetGameplayCamFov())*100
    local scale = scale*fov
	
	if onScreen then
		SetTextScale(size*scale, size*scale)
		SetTextFont(font)
		SetTextProportional(1)
		SetTextColour(r, g, b, 255)
		if not outline then
			SetTextDropshadow(0, 0, 0, 0, 55)
			SetTextEdge(2, 0, 0, 0, 150)
			SetTextDropShadow()
			SetTextOutline()
		end
		SetTextEntry("STRING")
		SetTextCentre(1)
		AddTextComponentString(text)
		SetDrawOrigin(x,y,z, 0)
		DrawText(0.0, 0.0)
		ClearDrawOrigin()
	end
end