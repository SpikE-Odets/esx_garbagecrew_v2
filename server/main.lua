ESX = nil

local currentjobs, currentadd, currentworkers = {}, {}, {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

Citizen.CreateThread(function()
    while true do
        local addsleep = 250
        local collectionfinished = false
        local updated = false
        while #currentadd > 0 do
            addsleep = 0
            if currentadd[1].type == 'bagdumped' then
                for i,v in pairs(currentjobs) do
                    if v.pos == currentadd[1].location and v.trucknumber == currentadd[1].truckplate  then
                        for workers, ids in pairs(v.workers) do
                            if ids.id == currentadd[1].id then
                                ids.bags = ids.bags + 1
                                v.bagsdropped = v.bagsdropped + 1
                                if v.bagsremaining <= 0  and v.bagsdropped == v.totalbags then
                                    TriggerEvent('esx_garbagecrew:paycrew', i)
                                end
                                updated = true
                                break
                            end
                        end

                        if not updated then
                            local buildlist = { id = currentadd[1].id, bags = 1,}
                            table.insert(v.workers, buildlist)
                            v.bagsdropped = v.bagsdropped + 1
                            if v.bagsremaining <= 0  and v.bagsdropped == v.totalbags then
                            TriggerEvent('esx_garbagecrew:paycrew', i)
                            end
                        end
                        table.remove(currentadd, 1)
                    break
                    end
                    
                end
            elseif currentadd[1].type == 'setworkers' then
                Citizen.Wait(0)
                local bagtotal = math.random(Config.MinBags, Config.MaxBags)
                local buildlist = {type = 'bags', name = 'bagcollection', jobboss = currentadd[1].id, pos = currentadd[1].location, totalbags = bagtotal, bagsdropped = 0, bagsremaining = bagtotal, trucknumber = currentadd[1].trucknumber, truckid = currentadd[1].truckid, workers = {}, }
                table.insert(currentjobs, buildlist)
                TriggerClientEvent('esx_garbagecrew:updatejobs', -1, currentjobs)
                table.remove(currentadd, 1)
                break
            end
            Citizen.Wait(addsleep)
        end
        Citizen.Wait(addsleep)
    end
end)

RegisterServerEvent('esx_garbagecrew:bagdumped')
AddEventHandler('esx_garbagecrew:bagdumped', function(location, truckplate)
    local _source = source
    local buildlist = {
        type = 'bagdumped',
        id = _source,
        location = location,
        truckplate = truckplate,
    }
    table.insert(currentadd, buildlist)
end)

RegisterServerEvent('esx_garbagecrew:setworkers')
AddEventHandler('esx_garbagecrew:setworkers', function(location, trucknumber, truckid)
    print("trying to set workers")
    _source = source
    buildlist = { 
        type = 'setworkers',
        id = _source,
        location = location,
        trucknumber = trucknumber,
        truckid = truckid, 
    }
   table.insert(currentadd, buildlist)
   print(tostring(#currentadd))
end)


RegisterServerEvent('esx_garbagecrew:unknownlocation')
AddEventHandler('esx_garbagecrew:unknownlocation', function(location, truckplate)
    for i,v in pairs(currentjobs) do
        if v.pos == location and v.trucknumber == truckplate  then
            if #v.workers > 0 then
                TriggerEvent('esx_garbagecrew:paycrew', i)
            else
                table.remove(currentjobs, number)
                TriggerClientEvent('esx_garbagecrew:updatejobs', -1, currentjobs)
            end
            break
       end
   end
end)

RegisterServerEvent('esx_garbagecrew:bagremoval')
AddEventHandler('esx_garbagecrew:bagremoval', function(location, trucknumber)
    for i,v in pairs(currentjobs) do
        if v.pos == location and v.trucknumber == trucknumber and v.bagsremaining > 0 then
            v.bagsremaining = v.bagsremaining - 1
            break
        end
    end
 
    TriggerClientEvent('esx_garbagecrew:updatejobs', -1, currentjobs)
end)

RegisterServerEvent('esx_garbagecrew:movetruckcount')
AddEventHandler('esx_garbagecrew:movetruckcount', function()
    Config.TruckPlateNumb = Config.TruckPlateNumb + 1
    if Config.TruckPlateNumb == 1000 then
        Config.TruckPlateNumb = 1
    end
    TriggerClientEvent('esx_garbagecrew:movetruckcount', -1, Config.TruckPlateNumb)
end)

RegisterServerEvent('esx_garbagejob:setconfig')
AddEventHandler('esx_garbagejob:setconfig', function()
    TriggerClientEvent('esx_garbagecrew:movetruckcount', -1, Config.TruckPlateNumb)
    if #currentjobs >  0 then
        TriggerClientEvent('esx_garbagecrew:updatejobs', -1, currentjobs)
    end
end)

AddEventHandler('playerDropped', function()
    _source = source
     for i, v in pairs(currentjobs) do
        for index, value in pairs(v.workers) do
            if value.id == _source then
                TriggerEvent('esx_garbagecrew:paycrew', i)
            end
        end
     end
end)

AddEventHandler('esx_garbagecrew:paycrew', function(number)
    currentcrew = currentjobs[number].workers
    payamount = (Config.StopPay / currentjobs[number].totalbags) + Config.BagPay
    for i, v in pairs(currentcrew) do
        local xPlayer = ESX.GetPlayerFromId(v.id)
        if xPlayer ~= nil then
            local amount = math.ceil(payamount * v.bags)
            xPlayer.addMoney(tonumber(amount))
            TriggerClientEvent('esx:showNotification', v.id, 'Received '..tostring(amount)..' from this stop!')
        end
    end
    TriggerClientEvent('esx_garbagecrew:selectnextjob', currentjobs[number].jobboss )
    table.remove(currentjobs, number)
    TriggerClientEvent('esx_garbagecrew:updatejobs', -1, currentjobs)
end)
