ESX = nil
local AreaType, AreaMarker, AreaInfo, currentZone, currentstop = nil, nil, nil, nil, 0
local HasAlreadyEnteredArea, clockedin, vehiclespawned, albetogetbags, truckdeposit = false, false, false, false, false
local work_truck, NewDrop, LastDrop, binpos, truckpos, garbagebag, truckplate = nil, nil, nil, nil, nil, nil, nil
local Blips, CollectionJobs, depositlist = {}, {}, {}



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

RegisterNetEvent('esxgarbagejob:movetruckcount')
AddEventHandler('esxgarbagejob:movetruckcount', function(count)
	Config.TruckPlateNumb = count
end)

RegisterNetEvent('esx_garbagecrew:updatejobs')
AddEventHandler('esx_garbagecrew:updatejobs', function(newjobtable)
	CollectionJobs = newjobtable
end)


RegisterNetEvent('esx_garbagecrew:selectnextjob')
AddEventHandler('esx_garbagecrew:selectnextjob', function()
	SetBlipRoute(Blips['delivery'], false)
	FindDeliveryLoc(LastDrop)
	albetogetbags = false
end)

RegisterNetEvent('esx_garbagecrew:enteredarea')
AddEventHandler('esx_garbagecrew:enteredarea', function(zone)
	CurrentAction = zone.name

	if CurrentAction == 'timeclock' then
		MenuCloakRoom()
	end

	if CurrentAction == 'vehiclelist' then
		if clockedin  then
			MenuVehicleSpawner()
		end
	end

	if CurrentAction == 'endmission' then
		CurrentActionMsg = _U('cancel_mission')
	end

	if CurrentAction == 'collection' and not albetogetbags then
		if IsPedInAnyVehicle(GetPlayerPed(-1)) and GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(-1), false)) == worktruckplate then
			CurrentActionMsg = _U('collection')
		else
			CurrentActionMsg = _U('need_work_truck')
		end

	end

	if CurrentAction == 'bagcollection' then
		if zone.bagsremaining > 0 then
			CurrentActionMsg = _U('collect_bags', tostring(zone.bagsremaining))
		else
			CurrentActionMsg = nil
		end
	end

	if CurrentAction == 'deposit' then
		CurrentActionMsg = _U('toss_bag')
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

		for i, v in pairs(CollectionJobs)  do
			if GetDistanceBetweenCoords(plyloc, v.pos, true)  < 10.0 and truckpos == nil then
				sleep = 0
				DrawMarker(1, v.pos.x,  v.pos.y,  v.pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0,  3.0,  3.0, 1.0, 255,0, 0, 100, false, true, 2, false, false, false, false)
			end
		end

		if truckpos ~= nil then
			if GetDistanceBetweenCoords(plyloc, truckpos, true) < 10.0  then
				sleep = 0
				DrawMarker(27, truckpos.x,  truckpos.y,  truckpos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0,  1.5, 1.5, 1.0, 0,100, 0, 100, false, true, 2, false, false, false, false)
			end
		end

		if oncollection then
			if GetDistanceBetweenCoords(plyloc, NewDrop.pos, true) < 20.0 and not albetogetbags then
				sleep = 0
				DrawMarker(1, NewDrop.pos.x,  NewDrop.pos.y,  NewDrop.pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0,  NewDrop.size,  NewDrop.size, 1.0, 204,204, 0, 100, false, true, 2, false, false, false, false)
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
					if IsPedInAnyVehicle(GetPlayerPed(-1)) then
						local getvehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)
						TaskLeaveVehicle(GetPlayerPed(-1), getvehicle, 0)
					end
					while IsPedInAnyVehicle(GetPlayerPed(-1)) do
						Citizen.Wait(0)
					end
					Citizen.InvokeNative( 0xAE3CBE5BF394C9C9, Citizen.PointerValueIntInitialized( work_truck ) )
					if Blips['delivery'] ~= nil then
						RemoveBlip(Blips['delivery'])
						Blips['delivery'] = nil
					end
					
					if Blips['endmission'] ~= nil then
						RemoveBlip(Blips['endmission'])
						Blips['endmission'] = nil
					end
					SetBlipRoute(Blips['delivery'], false)
					vehiclespawned = false
					CurrentAction =nil
					CurrentActionMsg = nil
				end

				if CurrentAction == 'collection' then
					if CurrentActionMsg == _U('collection') then
						SelectBinAndCrew(GetEntityCoords(GetPlayerPed(-1)))
						CurrentAction = nil
						CurrentActionMsg  = nil
						IsInArea = false
					end
				end

				if CurrentAction == 'bagcollection' then
					CurrentAction = nil
					CurrentActionMsg = nil
					CollectBagFromBin(currentZone)
					IsInArea = false
				end

				if CurrentAction == 'deposit' then
					CurrentAction = nil
					CurrentActionMsg = nil
					PlaceBagInTruck(currentZone)
					IsInArea = false
				end

			end
		end

	end
end)


-- thread so the script knows you have entered a markers area - 
Citizen.CreateThread( function()
	while true do 
		sleep = 1000
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

		if oncollection and not albetogetbags then
			if GetDistanceBetweenCoords(plyloc, NewDrop.pos, true)  <  NewDrop.size then
				IsInArea = true
				currentZone = NewDrop
			end
		end

		if truckpos ~= nil then
			if GetDistanceBetweenCoords(plyloc, truckpos, false)  <  2.0 then
				IsInArea = true
				currentZone = {type = 'Deposit', name = 'deposit', pos = truckpos,}
			end
		end

		for i,v in pairs(CollectionJobs) do
			if GetDistanceBetweenCoords(plyloc, v.pos, false)  <  2.0 and truckpos == nil then
				IsInArea = true
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
			sleep = 1000
			TriggerEvent('esx_garbagecrew:leftarea', currentZone)
		end

		Citizen.Wait(sleep)
	end
end)


function CollectBagFromBin(currentZone)
	binpos = currentZone.pos
	truckplate = currentZone.trucknumber
	if not HasAnimDictLoaded("anim@heists@narcotics@trash") then
		RequestAnimDict("anim@heists@narcotics@trash") 
		while not HasAnimDictLoaded("anim@heists@narcotics@trash") do 
			Citizen.Wait(0)
		end
	end
	local worktruck = NetworkGetEntityFromNetworkId(currentZone.truckid)
	if DoesEntityExist(worktruck) then
		truckpos =  GetWorldPositionOfEntityBone(worktruck, GetEntityBoneIndexByName(worktruck, "platelight"))  GetEntityCoords(worktruck)
		TaskStartScenarioInPlace(PlayerPedId(), "PROP_HUMAN_BUM_BIN", 0, true)
		TriggerServerEvent('esx_garbagecrew:bagremoval', currentZone.pos, currentZone.trucknumber) 
		trashcollection = false
		Citizen.Wait(4000)
		ClearPedTasks(PlayerPedId())
		local randombag = math.random(0,2)
		if randombag == 0 then
			garbagebag = CreateObject(GetHashKey("prop_cs_street_binbag_01"), 0, 0, 0, true, true, true) -- creates object
			AttachEntityToEntity(garbagebag, GetPlayerPed(-1), GetPedBoneIndex(GetPlayerPed(-1), 57005), 0.4, 0, 0, 0, 270.0, 60.0, true, true, false, true, 1, true) -- object is attached to right hand    
		elseif randombag == 1 then
			garbagebag = CreateObject(GetHashKey("bkr_prop_fakeid_binbag_01"), 0, 0, 0, true, true, true) -- creates object
			AttachEntityToEntity(garbagebag, GetPlayerPed(-1), GetPedBoneIndex(GetPlayerPed(-1), 57005), .65, 0, -.1, 0, 270.0, 60.0, true, true, false, true, 1, true) -- object is attached to right hand    
		elseif randombag == 2 then
			garbagebag = CreateObject(GetHashKey("hei_prop_heist_binbag"), 0, 0, 0, true, true, true) -- creates object
			AttachEntityToEntity(garbagebag, GetPlayerPed(-1), GetPedBoneIndex(GetPlayerPed(-1), 57005), 0.12, 0.0, 0.00, 25.0, 270.0, 180.0, true, true, false, true, 1, true) -- object is attached to right hand    
		end   
		TaskPlayAnim(PlayerPedId(), 'anim@heists@narcotics@trash', 'walk', 1.0, -1.0,-1,49,0,0, 0,0)
		CurrentAction = nil
		CurrentActionMsg = nil
		HasAlreadyEnteredArea = false

	else
		ESX.ShowNotification(_U('not_near_truck'))
	end
end

function PlaceBagInTruck(thiszone)
	if not HasAnimDictLoaded("anim@heists@narcotics@trash") then
		RequestAnimDict("anim@heists@narcotics@trash") 
		while not HasAnimDictLoaded("anim@heists@narcotics@trash") do 
			Citizen.Wait(0)
		end
	end
	ClearPedTasksImmediately(GetPlayerPed(-1))
	TaskPlayAnim(PlayerPedId(), 'anim@heists@narcotics@trash', 'throw_b', 1.0, -1.0,-1,2,0,0, 0,0)
	Citizen.Wait(800)
	local garbagebagdelete = DeleteEntity(garbagebag)
	Citizen.Wait(100)
	ClearPedTasksImmediately(GetPlayerPed(-1))
	CurrentAction = nil
	CurrentActionMsg = nil
	depositlist = nil
	truckpos = nil
	TriggerServerEvent('esx_garbagecrew:bagdumped', binpos, truckplate)
	HasAlreadyEnteredArea = false
end

function SelectBinAndCrew(location)
	local bin = nil
	for i, v in pairs(Config.DumpstersAvaialbe) do
		bin = GetClosestObjectOfType(location, 10.0, GetHashKey(v), false, false, false )
		if bin ~= 0 then
			break
		end
	end
	if bin ~= 0 then
		truckplate = GetVehicleNumberPlateText(work_truck)
		truckid = NetworkGetNetworkIdFromEntity(work_truck)
		TriggerServerEvent('esx_garbagecrew:setworkers', GetEntityCoords(bin), truckplate, truckid )
		truckpos = nil
		albetogetbags = true
		SetBlipRoute(Blips['delivery'], false)
	else
		ESX.ShowNotification('No trash available for pickup at this location.')
		SetBlipRoute(Blips['delivery'], false)
		FindDeliveryLoc(LastDrop)
	end
end

function FindDeliveryLoc(LastDrop)
	if currentstop < Config.MaxStops then
		if LastDrop ~= nil then
			lastregion = GetNameOfZone(LastDrop.pos)
		end
		local newdropregion = nil
		while newdropregion == nil or newdropregion == lastregion do
			randomloc = math.random(1, #Config.Collections)
			newdropregion = GetNameOfZone(Config.Collections[randomloc].pos)
		end
		NewDrop = Config.Collections[randomloc]
		LastDrop = NewDrop
		if Blips['delivery'] ~= nil then
			RemoveBlip(Blips['delivery'])
			Blips['delivery'] = nil
		end
		
		if Blips['endmission'] ~= nil then
			RemoveBlip(Blips['endmission'])
			Blips['endmission'] = nil
		end
		
		Blips['delivery'] = AddBlipForCoord(NewDrop.pos)
		SetBlipSprite (Blips['delivery'], 318)
		SetBlipAsShortRange(Blips['delivery'], true)
		SetBlipRoute(Blips['delivery'], true)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(_U('blip_delivery'))
		EndTextCommandSetBlipName(Blips['delivery'])
		
		Blips['endmission'] = AddBlipForCoord(Config.Zones[1].pos)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(_U('blip_goal'))
		EndTextCommandSetBlipName(Blips['endmission'])

		oncollection = true
		ESX.ShowNotification(_U('drive_to_collection'))
	else
		ESX.ShowNotification(_U('return_depot'))
	end
end

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
      		end
			if data.current.value == 'job_wear' then
				clockedin = true
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
					SetVehicleNumberPlateText(vehicle, 'GCREW00'..trucknumber)
					worktruckplate =   'GCREW00'..trucknumber 
				elseif trucknumber <=99 then
					SetVehicleNumberPlateText(vehicle, 'GCREW0'..trucknumber)
					worktruckplate =   'GCREW0'..trucknumber 
				else
					SetVehicleNumberPlateText(vehicle, 'GCREW'..trucknumber)
					worktruckplate =   'GCREW'..trucknumber 
				end


				TriggerServerEvent('esxgarbagejob:movetruckcount')   
				SetEntityAsMissionEntity(vehicle,true, true)
				TaskWarpPedIntoVehicle(GetPlayerPed(-1), vehicle, -1)  
				vehiclespawned = true 
				work_truck = vehicle
				FindDeliveryLoc(LastDrop)

			end)

			menu.close()
		end,
		function(data, menu)
			menu.close()
		end
	)
end


Citizen.CreateThread(function()
	local blip = AddBlipForCoord(Config.Zones[2].pos)
  
	SetBlipSprite (blip, 318)
	SetBlipDisplay(blip, 4)
	SetBlipScale  (blip, 1.2)
	SetBlipColour (blip, 5)
	SetBlipAsShortRange(blip, true)

	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString(_U('blip_job'))
	EndTextCommandSetBlipName(blip)
end)