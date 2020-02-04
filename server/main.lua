ESX = nil

local currentjobs = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('esxgarbagejob:movetruckcount')
AddEventHandler('esxgarbagejob:movetruckcount', function()
    Config.TruckPlateNumb = Config.TruckPlateNumb + 1
    if Config.TruckPlateNumb == 1000 then
        Config.TruckPlateNumb = 1
    end
    TriggerClientEvent('esxgarbagejob:movetruckcount', -1, Config.TruckPlateNumb)
end)

RegisterServerEvent('esx_garbagejob:setconfig')
AddEventHandler('esx_garbagejob:setconfig', function()
    TriggerClientEvent('esxgarbagejob:movetruckcount', -1, Config.TruckPlateNumb)
    if #currentjobs >  0 then
        TriggerClientEvent('esx_garbagecrew:updatejobs', -1, currentjobs)
    end
end)




RegisterServerEvent('esx_garbagecrew:setworkers')
AddEventHandler('esx_garbagecrew:setworkers', function(location, trucknumber)
    print('bin location: '.. tostring(location))
    _source = source
    local bagtotal = math.random(1, Config.MaxBags)
    if currentjobs[trucknumber] ~= nil then
        currentjobs[trucknumber] = nil
    end
    local buildlist = {type = 'bags',name = 'bagcollection', jobboss = _source, pos = location, totalbags = bagtotal, trucknumber = trucknumber,}
    table.insert(currentjobs, buildlist)
    TriggerClientEvent('esx_garbagecrew:updatejobs', -1, currentjobs)
end)

