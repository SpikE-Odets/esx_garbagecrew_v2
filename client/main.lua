ESX = nil
local AreaType, AreaMarker, AreaInfo, currentZone = nil, nil, nil, nil
local HasAlreadyEnteredArea, clockedin, vehiclespawned = false, false, false
local work_truck = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(100)
	end

	PlayerData = ESX.GetPlayerData()
end)



RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	PlayerData = xPlayer
	TriggerServerEvent('esx_garbagejob:setconfig')
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
end)

RegisterNetEvent('esx_garbagecrew:enteredarea')
AddEventHandler('esx_garbagecrew:enteredarea', function(zone)
	print('entered area')
	lastZone = zone  
	CurrentAction = zone.name
	print(CurrentAction)
	if CurrentAction == 'timeclock' then
		MenuCloakRoom()
	end

	if CurrentAction == 'vehiclelist' then
		print('Entered Vehicle List Marker - Clocked In ('..tostring(clockedin) .. ')')
		if clockedin  then
			MenuVehicleSpawner()
		end
	end

	if CurrentAction == 'endmission' then
		print('entered the end mission marker')
		CurrentActionMsg = _U('cancel_mission')
	end

end)

RegisterNetEvent('esx_garbagecrew:leftarea')
AddEventHandler('esx_garbagecrew:leftarea', function()
	ESX.UI.Menu.CloseAll()    
    CurrentAction = nil
	CurrentActionMsg = ''
end)

Citizen.CreateThread( function()
	while true do 
		sleep = 1000
		ply = GetPlayerPed(-1)
		plyloc = GetEntityCoords(ply)

		for i, v in pairs(Config.Zones) do
			if GetDistanceBetweenCoords(plyloc, v.pos, true)  < 20.0 then
				sleep = 0

				if v.name == 'timeclock' and IsGarbageJob() then
					DrawMarker(1, v.pos.x, v.pos.y, v.pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, v.size,  v.size, 1.0, 204,204, 0, 100, false, true, 2, false, false, false, false)
				elseif v.name == 'endmission' and vehiclespawned then
					DrawMarker(1, v.pos.x, v.pos.y, v.pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0,  v.size,  v.size, 1.0, 204,204, 0, 100, false, true, 2, false, false, false, false)
				elseif v.name == 'vehiclelist' and clockedin and not vehiclespawned then
					DrawMarker(1, v.pos.x, v.pos.y, v.pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0,  v.size,  v.size, 1.0, 204,204, 0, 100, false, true, 2, false, false, false, false)
				end
			end
		end

		if oncollection then
			for i, v in pairs(Config.Collections) do
				if GetDistanceBetweenCoords(plyloc, v.pos, true)  < 20.0 then
					sleep = 0
					DrawMarker(1, v.pos, 0, 0, 0, 0, 0, 0, 3.0, 3.0, 1.0, 0, 204, 204, 0, 0, 0, 0, 0)
				end
			end
		end

		Citizen.Wait(sleep)
	end
end)


Citizen.CreateThread( function()
	while true do 
		Citizen.Wait(0)
		while CurrentAction ~= nil and CurrentActionMsg ~= nil do
			Citizen.Wait(0)
			SetTextComponentFormat('STRING')
        	AddTextComponentString(CurrentActionMsg)
			DisplayHelpTextFromStringLabel(0, 0, 1, -1)

			if IsControlJustReleased(0, 38) then

				if CurrentAction == 'endmission' then
					ESX.Game.DeleteVehicle(work_truck)
					vehiclespawned = false
					
				end




			end
		end

	end
end)
-- thread so the script knows you have entered a markers area - 
Citizen.CreateThread( function()
	while true do 
		sleep = 2500
		ply = GetPlayerPed(-1)
		plyloc = GetEntityCoords(ply)
		IsInArea = false
		currentZone = nil
		
		for i,v in pairs(Config.Zones) do
			if GetDistanceBetweenCoords(plyloc, v.pos, false)  <  v.size then
				IsInArea = true
				currentZone = v
			end
		end

		for i,v in pairs(Config.Collections) do
			if GetDistanceBetweenCoords(plyloc, v.pos, true)  <  v.size then
				IsInCollection = true
				currentZone = v
			end
		end

		if IsInArea and not HasAlreadyEnteredArea then
			HasAlreadyEnteredArea = true
			sleep = 0
			TriggerEvent('esx_garbagecrew:enteredarea', currentZone)
		end
	

		if not IsInArea and HasAlreadyEnteredArea then
			HasAlreadyEnteredArea = false
			sleep = 2500
			TriggerEvent('esx_garbagecrew:leftarea', currentZone)

		end

		Citizen.Wait(sleep)
	end
end)


function IsGarbageJob()
	if ESX ~= nil then
		local isjob = false
		if PlayerData.job.name == 'garbage' then
			isjob = true
		end
		return isjob
	end
end

function MenuCloakRoom()
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open(
		'default', GetCurrentResourceName(), 'cloakroom',
		{
			title    = _U('cloakroom'),
			elements = {
				{label = _U('job_wear'), value = 'job_wear'},
				{label = _U('citizen_wear'), value = 'citizen_wear'}
			}
		},
		function(data, menu)
			if data.current.value == 'citizen_wear' then
				clockedin = false
				ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
					  local model = nil

					  if skin.sex == 0 then
						model = GetHashKey("mp_m_freemode_01")
					  else
						model = GetHashKey("mp_f_freemode_01")
					  end

					  RequestModel(model)
					  while not HasModelLoaded(model) do
						RequestModel(model)
						Citizen.Wait(1)
					  end

					  SetPlayerModel(PlayerId(), model)
					  SetModelAsNoLongerNeeded(model)

					  TriggerEvent('skinchanger:loadSkin', skin)
					  TriggerEvent('esx:restoreLoadout')
        end)
      end
			if data.current.value == 'job_wear' then
				clockedin = true
				ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
	    			if skin.sex == 0 then
	    				TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_male)
					else
	    				TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_female)

					RequestModel(model)
					while not HasModelLoaded(model) do
					RequestModel(model)
					Citizen.Wait(0)
					end

				SetPlayerModel(PlayerId(), model)
				SetModelAsNoLongerNeeded(model)
					end
					
				end)

			end	
			menu.close()
		end,
		function(data, menu)
			menu.close()
		end
	)
end

function MenuVehicleSpawner()
	local elements = {}

	for i=1, #Config.Trucks, 1 do
		table.insert(elements, {label = GetLabelText(GetDisplayNameFromVehicleModel(Config.Trucks[i])), value = Config.Trucks[i]})
	end


	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open(
		'default', GetCurrentResourceName(), 'vehiclespawner',
		{
			title    = _U('vehiclespawner'),
			elements = elements
		},
		function(data, menu)
			ESX.Game.SpawnVehicle(data.current.value, Config.VehicleSpawn.pos, 270.0, function(vehicle)
				local trucknumber = Config.TruckPlateNumb + 1
				if trucknumber <=9 then
					SetVehicleNumberPlateText(vehicle, 'TCREW00'..trucknumber)
					plaquevehicule =   'TCREW00'..trucknumber 
				elseif trucknumber <=99 then
					SetVehicleNumberPlateText(vehicle, 'TCREW0'..trucknumber)
					plaquevehicule =   'TCREW0'..trucknumber 
				else
					SetVehicleNumberPlateText(vehicle, 'TCREW'..trucknumber)
					plaquevehicule =   'TCREW'..trucknumber 
				end


				TriggerServerEvent('esxgarbagejob:movetruckcount')   
				SetEntityAsMissionEntity(vehicle,true, true)
				TaskWarpPedIntoVehicle(GetPlayerPed(-1), vehicle, -1)  
				vehiclespawned = true 
				work_truck = vehicle

			end)

			menu.close()
		end,
		function(data, menu)
			menu.close()
		end
	)
end