-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Gameplay/ArmsDealer.lua
-- *  PURPOSE:     Arms Dealer class
-- *
-- ****************************************************************************
ArmsDealer = inherit(Singleton)
ArmsDealer.Data = 
{ 
    ["Waffen"] = AmmuNationInfo,
    ["Spezial"] = 
    {
        ["Gasmaske"] = {100, 50000},
        ["Gasgranate"] = {20, 50000, 17},
        ["Rauchgranate"] = {20, 50000},
        ["Scharfschützengewehr"] = {5, 60000, 34},
        ["Fallschirm"] = {20, 5000, 46},
        ["DefuseKit"] = {20, 5000},
    },
    ["Explosiv"] = 
    {
        ["RPG-7"] = {7, 100000, 35}, 
        ["Granate"] = {7, 80000, 16},
        ["SLAM"] = {3, 40000}
    }
}

ArmsDealer.ProhibitedRank = 
{
    ["RPG-7"] = 3, 
    ["Granate"] = 3, 
    ["SLAM"] = 3,
    ["Scharfschützengewehr"] =  3 
}
ArmsDealer.MaxBags = 4

addRemoteEvents{"requestArmsDealerInfo", "checkoutArmsDealerCart", }
function ArmsDealer:constructor()
    self.m_Order = {}
    self.m_BagContent = {}
    self.m_MaxPrice = {}
    self.m_OrderedToday = {}
    self.m_BankAccountServer = BankServer.get("gameplay.blackmarket")
    addEventHandler("requestArmsDealerInfo", root, bind(self.sendInfo, self))
    addEventHandler("checkoutArmsDealerCart", root, bind(self.checkoutCart, self))
end

function ArmsDealer:getItemData(item)
    for category, data in pairs(ArmsDealer.Data) do 
        for product, subdata in pairs(data) do 
            if product == item then 
                return subdata
            end
        end
    end
    return false
end


function ArmsDealer:checkoutCart(cart, maxPrice)
    local faction = client:getFaction()
    if not ActionsCheck:getSingleton():isActionAllowed(client) then return end
    if faction:isEvilFaction() then
        if not PermissionsManager:getSingleton():isPlayerAllowedToStart(client, "faction", "Airdrop") then
            client:sendError(_("Du bist nicht berechtigt einen %s zu starten!", client, faction:isStateFaction() and "Staats-Waffendrop" or "Airdrop"))
            return
        end
        if FactionState:getSingleton():countPlayers(true, false) < ARMSDEALER_MIN_MEMBERS then
            return client:sendError(_("Es müssen mindestens %d Staatsfraktionisten aktiv sein!",client, ARMSDEALER_MIN_MEMBERS))
        end
    else
        if not PermissionsManager:getSingleton():isPlayerAllowedToStart(client, "faction", "StateAirdrop") then
            client:sendError(_("Du bist nicht berechtigt einen %s zu starten!", client, faction:isStateFaction() and "Staats-Waffendrop" or "Airdrop"))
            return
        end
        if FactionEvil:getSingleton():countPlayers(true, false) < ARMSDEALER_MIN_MEMBERS then
            return client:sendError(_("Es müssen mindestens %d Spieler böser Fraktionen aktiv sein!",client, ARMSDEALER_MIN_MEMBERS))
        end
    end

    if not client or not client.getFaction or not client:getFaction() then
        return 
    end 
    if not cart or self.m_InAir then
        return client:sendError(_("Es läuft zurzeit bereits ein Airdrop!", client))
    end


    if self:isFactionAllowedToOrder(faction) then
        self.m_Order[faction] = {}
        self.m_BagContent[faction] = {}
        self.m_MaxPrice[faction] = maxPrice
        self.m_TotalPrice = 0
        local depot = faction.m_Depot
        local orderCount = 0
        local price, maxAmount, currentAmount, pricePerPiece, totalPrice
        local validWeapons, maxWeapons, weaponDepot = faction.m_ValidWeapons, faction.m_WeaponDepotInfo, depot:getWeaponTable()
        local maxEquipment = faction.m_EquipmentDepotInfo
        for category, data in pairs(cart) do 
            for product, subdata in pairs(data) do 
                if category == "Weapon" then
                    if subdata["Waffe"] > 0 then
                        --maxAmount = maxWeapons[product]["Waffe"]
                        --currentAmount = weaponDepot[product]["Waffe"]
                        pricePerPiece = maxWeapons[product]["WaffenPreis"]
                        totalPrice = pricePerPiece*subdata["Waffe"]
                        self.m_TotalPrice = self.m_TotalPrice + totalPrice
                        table.insert(self.m_Order[faction], {"Waffe", WEAPON_NAMES[product], subdata["Waffe"], totalPrice, product, pricePerPiece})
                    end
                    if subdata["Munition"] > 0 then 
                        --currentAmount = weaponDepot[product]["Munition"]
                        pricePerPiece = maxWeapons[product]["MagazinPreis"]
                        totalPrice = pricePerPiece*subdata["Munition"]
                        self.m_TotalPrice = self.m_TotalPrice + totalPrice
                        table.insert(self.m_Order[faction], {"Munition", WEAPON_NAMES[product], subdata["Munition"], totalPrice, product, pricePerPiece})
                    end
                elseif category == "Equipment" then
                    if subdata["Count"] > 0 then
                        --maxAmount = maxWeapons[product]["Waffe"]
                        --currentAmount = weaponDepot[product]["Waffe"]
                        pricePerPiece = maxEquipment[product]["Price"]
                        totalPrice = pricePerPiece*subdata["Count"]
                        self.m_TotalPrice = self.m_TotalPrice + totalPrice
                        table.insert(self.m_Order[faction], {"Equipment", WEAPON_NAMES[product], subdata["Count"], totalPrice, product, pricePerPiece})
                    end
                else 
                    --if ArmsDealer.Data[category] and ArmsDealer.Data[category][product] then
                    --    table.insert(self.m_Order[faction], {"Equipment", product, ArmsDealer.Data[category][product][1], ArmsDealer.Data[category][product][2], ArmsDealer.Data[category][product][3] })
                    --end
                end
                
            end
        end
        if faction:transferMoney(self.m_BankAccountServer, self.m_TotalPrice, "Lieferung", "Action", "Blackmarket") then
            local bagContent = self:splitOrder(faction)
            self:processCart(bagContent, faction)
            StatisticsLogger:getSingleton():addActionLog("Airdrop", "start", client, faction, "faction")
            client:getFaction():addLog(client, "Lager", ("Airdrop gestartet für $%s!"):format(self.m_TotalPrice))
            self.m_LastPlayer = client 
            self.m_LastFaction = faction
            self.m_OrderedToday[faction] = true
        else
            return client:sendError(_("Deine Fraktion hat nicht genügend Geld (%s)", client, toMoneyString(self.m_TotalPrice)))
        end
    else 
        client:sendError(_("Deine Fraktion hat bereits heute bestellt!", client))
    end
end

function ArmsDealer:processCart( order, faction )
    local endPoint = factionAirDropPoint[faction:getId()]
    local etaTime
    if endPoint then
        etaTime = self:setupPlane(endPoint, 400000, faction, order)
    end
    
    self.m_Blip =  Blip:new("Marker.png", endPoint.x, endPoint.y, {faction = {faction:getId()}}, 9999, BLIP_COLOR_CONSTANTS.Red)
    self.m_Blip:attach(self.m_Plane)

    self.m_DropBlip = Blip:new("SniperGame.png", endPoint.x, endPoint.y,  {factionType = {"State", "Evil"}}, 9999, BLIP_COLOR_CONSTANTS.Blue)
    self.m_DropIndicator = createObject(354, endPoint.x, endPoint.y, endPoint.z)
    if faction:isStateFaction() then
        PlayerManager:getSingleton():breakingNews("Der Luftraum von San Andreas wird aufgrund eines Staatlichen Waffendrops nun verschärft beobachtet!")
    else
        PlayerManager:getSingleton():breakingNews("Ein nicht identifiziertes Flugzeug ist in den Flugraum von San Andreas eingedrungen!")
    end
    
    self.m_InAir = true
end

function ArmsDealer:sendInfo()
    if client.getFaction and client:getFaction() and client:getFaction():isEvilFaction() then
        local faction = client:getFaction()
        local depot = faction.m_Depot
        client:triggerEvent("updateArmsDealerInfo", ArmsDealer.Data, faction.m_ValidWeapons, faction.m_WeaponDepotInfo, depot:getWeaponTable() )
    end
end

function ArmsDealer:startAirDrop(faction, order, acceleration)
    local endPoint = factionAirDropPoint[faction:getId()]
    if endPoint then 
        local length = 30 / #order 
        for i, data in ipairs(order) do 
            setTimer(function() 
                if self.m_Plane then 
                    local pos = self.m_Plane:getPosition()
                    ArmsPackage:new(data, Vector3(pos.x-4, pos.y, pos.z), Vector3(pos.x-4, pos.y, endPoint.z-0.35), faction:getType())
                end
            end, acceleration*(length*i), 1)
        end
    end
end

function ArmsDealer:setupPlane(pos, time, faction, order)
    if faction:isEvilFaction() then
        self:sendOperatorMessage(faction, "In der Luft!")
        ActionsCheck:getSingleton():setAction("Waffendrop")
        local acceleration = time/6000
        local startPoint = Vector3(-3000, pos.y, 100)
        local distanceToDrop = math.abs(-3000 - pos.x)
        local distanceAfterDrop = 6000 - distanceToDrop
        local endPoint = Vector3(3000, pos.y, 100)
        self.m_Plane =  TemporaryVehicle.create(592, -3000, pos.y, 100)
        self.m_Plane:disableRespawn(true)
        self.m_Plane:setColor(0,0,0,0,0,0)
        self.m_Plane:setCollisionsEnabled(false)
        setVehicleLandingGearDown(self.m_Plane, false)
        self.m_MoveObject = createObject(1337, -3000, pos.y, 100)
        self.m_MoveObject:setCollisionsEnabled(false)
        self.m_MoveObject:setAlpha(0)
        self.m_Plane:attach(self.m_MoveObject, Vector3(0, 0, 0), Vector3(0, 0, 270))
        self.m_MoveObject:move(acceleration*distanceToDrop, pos.x, pos.y, 100)
        faction:setCountDown((acceleration*distanceToDrop)/1000, "Airdrop")
        setTimer(function() self:sendOperatorMessage(faction, "Abwurf in T-10!") end, (distanceToDrop*acceleration)-10000, 1)
        setTimer(function() 
            self.m_MoveObject:move(distanceAfterDrop*acceleration, 3000, pos.y, 100) 
            self:sendOperatorMessage(faction, "Abwurf!")
            self:startAirDrop(faction, order, acceleration)
            setTimer(function() self:clear() end, distanceAfterDrop*acceleration, 1)
        end, acceleration*distanceToDrop, 1)
        return (acceleration*distanceToDrop)/1000
    else
        self:sendOperatorMessage(faction, "Auf dem Weg zum Waffenstützpunkt!")
        ActionsCheck:getSingleton():setAction("Staats-Waffendrop")
        FactionState:getSingleton():setCountDown(7 * 60, "Staats-Waffendrop")
       
        self.m_Plane = TemporaryVehicle.create(520, -1437.20, 507.79, 19.15, 270)
        self.m_Plane:setDamageProof(true)
        self.m_Plane:setCollisionsEnabled(false)
    
        self.m_MoveObject = createObject(2710,  -1437.20, 507.79, 19.15, 0, 0, 270)
        self.m_MoveObject:setAlpha(0)
        self.m_Plane:attach(self.m_MoveObject, 0, 0, 0, 0, 0, 0)
    
        self.m_Pilot = Ped(287, Vector3(-1437.20, 507.79, 19.15+3))
        self.m_Pilot:setCollisionsEnabled(false)
        self.m_Pilot:warpIntoVehicle(self.m_Plane)
    
        setTimer(function()
            self.m_MoveObject:move(15000, -850.21, 513.78, 37.16, 10, 0, 0, "InQuad")
        end, 5000, 1)
        setTimer(function()
            setVehicleLandingGearDown(self.m_Plane, false)
        end, 10000, 1)
        setTimer(function()
            self.m_MoveObject:move(40000, 3937.20, 507.79, 157.16, -10, 0, 0) 
        end, 20000, 1) 
        setTimer(function()
            self.m_Plane:setDimension(PRIVATE_DIMENSION_SERVER)
        end, 60000, 1) 
    
        setTimer(function()
            self:sendOperatorMessage(faction, "Auf dem Weg zur Abwurfstelle!")
            self.m_Plane:setDimension(0)
            self.m_MoveObject:setRotation(0, 0, findRotation(self.m_MoveObject.position.x, self.m_MoveObject.position.y,  281.39, 2501.79))
            self.m_MoveObject:move(2 * 1000 * 60, 281.39, 2501.79, 148.59)
    
            setTimer(function()
                self.m_MoveObject:move(2 * 1000 * 60, self.m_MoveObject.matrix:transformPosition(Vector3(0, 3000, 0)))
                self:sendOperatorMessage(faction, "Abwurf!")
                self:startAirDrop(faction, order, 50)
                setTimer(function() self:clear() end, 15 * 1000, 1)
            end, 1000 * 60 * 2, 1)
    
        end, 1000 * 60 * 5, 1)
        setTimer(function() self:sendOperatorMessage(faction, "Abwurf in T-10!") end, 7 * 60 * 1000 - 10000, 1)
    end
end

function ArmsDealer:sendOperatorMessage(faction, text)
    if faction and text then 
        local players = faction:getOnlinePlayers()
        for index, player in pairs(players) do 
            playSoundFrontEnd(player, 47)
            setTimer(playSoundFrontEnd, 1000, 1, player, 48)
        end
        faction:sendMessage(("%s %s"):format("[**OPERATOR**]", text), 23, 143, 255)
    end
end


function ArmsDealer:clear()
    if self.m_Blip then 
        self.m_Blip:delete()
        self.m_Blip = nil
    end
    if self.m_Plane and isElement(self.m_Plane) then 
        self.m_Plane:destroy()
        self.m_Plane = nil
    end
    if self.m_MoveObject and isElement(self.m_MoveObject) then 
        self.m_MoveObject:destroy()
        self.m_MoveObject = nil
    end
    if self.m_DropBlip then 
        self.m_DropBlip:delete()
        self.m_DropBlip = nil 
    end
    if self.m_DropIndicator and isElement(self.m_DropIndicator) then 
        self.m_DropIndicator:destroy()
        self.m_DropIndicator = nil
    end
    if self.m_Pilot and isElement(self.m_Pilot) then
        self.m_Pilot:destroy()
        self.m_Pilot = nil
    end
    self.m_InAir = false
    StatisticsLogger:getSingleton():addActionLog("Airdrop", "stop", self.m_LastPlayer, self.m_LastFaction, "faction")
    self.m_LastPlayer = nil 
    self.m_LastFaction = nil
    ActionsCheck:getSingleton():endAction()
end

function ArmsDealer:destructor()

end

function ArmsDealer:splitOrderOld(faction)
    local bagContent = {}
    local pricePerBag = self.m_MaxPrice[faction] / ArmsDealer.MaxBags
    for i = 1, 4, 1 do
        if table.size(self.m_Order[faction]) == 0 then
            break
        end
        if not self.m_BagContent[faction][i] then
            self.m_BagContent[faction][i] = {}
            self.m_BagContent[faction][i]["BagPrice"] = 0
        end

        for mi, data in pairs(self.m_Order[faction]) do
            if data[4] + self.m_BagContent[faction][i]["BagPrice"] <= pricePerBag or i == ArmsDealer.MaxBags then
                self.m_BagContent[faction][i]["BagPrice"] = self.m_BagContent[faction][i]["BagPrice"] + data[4]
                table.insert(self.m_BagContent[faction][i], data)
                self.m_Order[faction][mi] = nil
            end
        end
    end

    for i, v in pairs(self.m_BagContent[faction]) do
        if v.BagPrice > 0 then
            table.insert(bagContent, v)
        else
            self.m_BagContent[faction][i] = nil
        end
    end

    return bagContent
end

--{"Equipment", WEAPON_NAMES[product], subdata["Count"], totalPrice, product}
function ArmsDealer:splitOrder(faction)
    local bagContent, pieceCount = {}, {}
    local pricePerBag = self.m_MaxPrice[faction] / ArmsDealer.MaxBags
    

    for i = 1, ArmsDealer.MaxBags, 1 do
        if table.size(self.m_Order[faction]) == 0 then
            break
        end

        if not self.m_BagContent[faction][i] then
            self.m_BagContent[faction][i] = {}
            self.m_BagContent[faction][i]["BagPrice"] = 0
        end
        
    
        for id, data in pairs(self.m_Order[faction]) do
            local currentPrice = self.m_BagContent[faction][i]["BagPrice"]
            if currentPrice + data[4] <= pricePerBag or i == ArmsDealer.MaxBags then
                table.insert(self.m_BagContent[faction][i], data)
                self.m_BagContent[faction][i]["BagPrice"] = self.m_BagContent[faction][i]["BagPrice"] + data[4]
                self.m_Order[faction][id] = nil
            else
                local newData, data2
                for mi = 1, data[3], 1 do
                    if (mi * data[6]) + currentPrice <= pricePerBag then

                        data2 = {data[1], data[2], mi, mi*data[6], data[5], data[6]}
                        newData = {data[1], data[2], data[3]-mi, data[4]-(mi*data[6]), data[5], data[6]}
                    end 
                end
                if data2 and newData then
                    self.m_BagContent[faction][i]["BagPrice"] = self.m_BagContent[faction][i]["BagPrice"] + data2[4]
                    table.insert(self.m_Order[faction], newData)
                    table.insert(self.m_BagContent[faction][i], data2)
                    self.m_Order[faction][id] = nil
                end
            end
        end
    end

    return self.m_BagContent[faction]
end

function ArmsDealer:isFactionAllowedToOrder(faction)
    if faction:isEvilFaction() and not self.m_OrderedToday[faction] then
        return true
    end

    for i, sFaction in pairs(FactionState:getSingleton():getFactions()) do
        if self.m_OrderedToday[sFaction] then
            return false
        end
    end

    return true
end