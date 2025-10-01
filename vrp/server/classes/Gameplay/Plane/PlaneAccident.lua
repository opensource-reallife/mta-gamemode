-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Gameplay/Plane/PlaneAccident.lua
-- *  PURPOSE:     Plane Accident Class
-- *
-- ****************************************************************************

PlaneAccident = inherit(Plane)

function PlaneAccident:setAccidentPlane(flyingTime, colX, colY, colZ, colTime, standstillX, standstillY, standstillZ, standstillTime, fireX, fireY, fireWidth, fireHeight)
    if colX and colY and colZ and colTime then
        Timer(
            function()
                self.m_Object:move(colTime, colX, colY, colZ)
                self.m_Plane:setDamageProof(true)
                self.m_Plane:setHealth(50)
                self.m_Plane:setEngineState(true)
            end
        , flyingTime, 1)

        if standstillX and standstillY and standstillZ and standstillTime then
            Timer(
                function()
                    self.m_Plane:setEngineState(false)
                    self:explode()
                    self.m_Object:move(standstillTime, standstillX, standstillY, standstillZ, 0, 0, 0, "OutQuad")

                    Timer(
                        function()
                            self:explode()
                            self:createAccidentFire()
                            self:createRubble()
                        end
                    , standstillTime, 1)

                end
            , flyingTime + colTime, 1)
        end
        --[[if DEBUG then
            getRandomPlayer():setPosition(standstillX, standstillY, standstillZ)
        end]]
    end
end

function PlaneAccident:destructor()
    if isElement(self.m_Rubble) then
        self.m_Rubble:destroy()
    end
    if isElement(self.m_TrashDeliveryMarker) then
        self.m_TrashDeliveryMarker:destroy()
    end
    if isElement(self.m_AccidentDeliveryBlip) then
        self.m_AccidentDeliveryBlip:delete()
    end
end

function PlaneAccident:createAccidentFire()
    local planePos = self.m_Plane:getPosition()
    local planeID = self.m_Plane:getModel()
    local zone = getZoneName(planePos.x, planePos.y, planePos.z)
    local city = getZoneName(planePos.x, planePos.y, planePos.z, true)
    FireManager:getSingleton().m_Fires[1000] = {
        ["name"] = ("Flugzeug Unfall: %s"):format(zone),
        ["message"] = "Ein Flugzeugabsturz wurde gemeldet!\nPosition: %s",
        ["position"] = Vector3(planePos.x-PlaneSizeTable[planeID][1], planePos.y-PlaneSizeTable[planeID][2], planePos.z),
        ["positionTbl"] = {planePos.x-PlaneSizeTable[planeID][1], planePos.y-PlaneSizeTable[planeID][2], planePos.z},
        ["width"] = PlaneSizeTable[planeID][1] * 2,
        ["height"] = PlaneSizeTable[planeID][2] * 2,
        ["creator"] = "Flugzeug-Unfall",
        ["enabled"] = true,
    }
    FireManager:getSingleton():startFire(1000)
    PlayerManager:getSingleton():breakingNews("Ein Flugzeugabsturz wurde in %s, %s gemeldet!", zone, city)
end

function PlaneAccident:createRubble()
    if isElement(self.m_Rubble) then
        self.m_Rubble:destroy()
    end
    for _, player in pairs(Element.getAllByType("player")) do
        player:triggerEvent("triggerClientPlaneDestroySmoke", self.m_Plane)
    end
    Timer(
        function()
            if #CompanyManager:getSingleton():getFromId(CompanyStaticId.MECHANIC):getOnlinePlayers() >= 1 then
                self:createTrashData()
                local planePos = self.m_Plane:getPosition()
                local planeRot = self.m_Plane:getRotation()
                self.m_Rubble = createObject(10985, planePos.x, planePos.y, planePos.z + PlaneRubbleOffsets[self.m_Plane:getModel()], planeRot.x, planeRot.y, planeRot.z + 45)
                self.m_IsRubbleBeingRemoved = false
                addEventHandler("onElementClicked", self.m_Rubble, bind(self.removeRubble, self))
            else
                PlaneManager:getSingleton():endAccident()
            end
            triggerClientEvent(root, "deletePlaneInstance", root, true)
            if isElement(self.m_Plane) then
                self.m_Plane:destroy()
            end
            if isElement(self.m_Object) then
                self.m_Object:destroy()
            end
            if isElement(self.m_Pilot) then
                self.m_Pilot:destroy()
            end
        end
    , 10000, 1)
end

function PlaneAccident:removeRubble(button, state, player)
    if button == "left" and state == "down" then
        if source == self.m_Rubble then
            if player:getCompany():getId() == 2 and player:isCompanyDuty() then
                if self.m_IsRubbleBeingRemoved ~= true then
                    local playerPos = player:getPosition()
                    local rubblePos = source:getPosition()
                    local company = player:getCompany()
                    local vehNearRubble = false
                    for i, veh in pairs(company.m_Vehicles) do
                        if veh:getModel() == 455 and getDistanceBetweenPoints3D(playerPos.x, playerPos.y, playerPos.z, veh.position.x, veh.position.y, veh.position.z) < 20 then
                            vehNearRubble = true
                            self.m_Flatbed = veh
                            break
                        end
                    end
                    if player:getContactElement() == self.m_Rubble then
                        if vehNearRubble then
                            player:setAnimation("BOMBER", "BOM_Plant_Loop", -1, true, false, false)
                            toggleAllControls(player, false)
                            self.m_IsRubbleBeingRemoved = true
                            Timer(
                                function()
                                    local rubblePos = self.m_Rubble:getPosition()
                                    self.m_Rubble:setPosition(rubblePos.x, rubblePos.y, rubblePos.z-1)
                                end
                            , 5000, 3)

                            Timer(
                                function(player)
                                    self.m_Rubble:destroy()
                                    player:setAnimation()
                                    toggleAllControls(player, true)
                                    self.m_Flatbed:setVariant(4, 2)
                                    self.m_TrashDeliveryMarker:setAlpha(255)
                                    self.m_TrashTruckLoaded = true
                                    player:sendInfo(_("Fahre nun die Überreste zurück zur Mech&Tow Base!", player))
                                    self.m_AccidentDeliveryBlip = Blip:new("Marker.png", 865.72, -1282.10, {company = 2}, 400, {255, 255, 255}, {175, 175, 175})
                                    self.m_AccidentMechanicBlip:delete()
                                end
                            , 15100, 1, player)
                        else
                            player:sendError(_("Der Flatbed ist zu weit entfernt!", player))
                        end
                    else
                        player:sendError(_("Du musst auf den Wrackteilen stehen!", player))
                    end
                else
                    player:sendError(_("Die Wrackteile werden bereits verladen!", player))
                end
            else
                player:sendError(_("Du bist kein Mechaniker im Dienst!", player))
            end
        end
    end
end

function PlaneAccident:createTrashData()
    self.m_TrashDeliveryMarker = Marker(865.72, -1282.10, 13.21, "cylinder", 4.0, 255, 0, 0, 0)

    local planePos = self.m_Plane:getPosition()
    local zone = getZoneName(planePos).." - "..getZoneName(planePos, true)
    CompanyManager:getSingleton():getFromId(CompanyStaticId.MECHANIC):sendWarning("Ein Mechaniker wird mit dem Flatbed aus der Basis am Unfallort benötigt!\nPosition: %s", "Flugzeug-Wrack", true, planePos, zone)
    self.m_AccidentMechanicBlip = Blip:new("Marker.png", planePos.x, planePos.y, {company = 2}, 400, {255, 255, 255}, {175, 175, 175})

    addEventHandler("onMarkerHit", self.m_TrashDeliveryMarker, 
        function(hitElement, matchingDim)
            if matchingDim then
                if hitElement:getType("vehicle") and hitElement:isPermanent() and hitElement:getModel() == 455 and hitElement.m_OwnerType == 3 and hitElement.m_Owner == 2 then
                    if self.m_TrashTruckLoaded == true then
                        if hitElement.controller then
                            BankServer.get("company.mechanic"):transferMoney(hitElement.controller, 5000, "Flugzeug-Wrack Abgabe", "Company", "Plane accident removal", {silent = true})
                        end
                        self.m_Flatbed:setVariant(3, 4)
                        self.m_TrashDeliveryMarker:destroy()
                        self.m_AccidentDeliveryBlip:delete()
                        PlaneManager:getSingleton():endAccident()
                    end
                end
            end
        end
    )
end

function PlaneAccident:explode()
    local planePos = self.m_Plane:getPosition()
    local forwardVector = self.m_Plane.matrix.forward
    local rightVector = self.m_Plane.matrix.right
    local vehicleID = self.m_Plane:getModel()

    createExplosion(planePos.x, planePos.y, planePos.z, 23)
    if PlaneExplosionSizes[vehicleID] == 2 then
        createExplosion(planePos.x + forwardVector.x*5, planePos.y + forwardVector.y*5, planePos.z + forwardVector.z*5, 23)
        createExplosion(planePos.x + forwardVector.x*-5, planePos.y + forwardVector.y*-5, planePos.z + forwardVector.z*-5, 23)
        createExplosion(planePos.x + rightVector.x*5, planePos.y + rightVector.y*5, planePos.z + rightVector.z*5, 23)
        createExplosion(planePos.x + rightVector.x*-5, planePos.y + rightVector.y*-5, planePos.z + rightVector.z*-5, 23)
    elseif PlaneExplosionSizes[vehicleID] == 3 then
        createExplosion(planePos.x + forwardVector.x*15, planePos.y + forwardVector.y*15, planePos.z + forwardVector.z*15, 23)
        createExplosion(planePos.x + forwardVector.x*-15, planePos.y + forwardVector.y*-15, planePos.z + forwardVector.z*-15, 23)
        createExplosion(planePos.x + rightVector.x*15, planePos.y + rightVector.y*15, planePos.z + rightVector.z*15, 23)
        createExplosion(planePos.x + rightVector.x*-15, planePos.y + rightVector.y*-15, planePos.z + rightVector.z*-15, 23)
    elseif PlaneExplosionSizes[vehicleID] == 4 then
        createExplosion(planePos.x + forwardVector.x*15, planePos.y + forwardVector.y*15, planePos.z + forwardVector.z*15, 23)
        createExplosion(planePos.x + forwardVector.x*-15, planePos.y + forwardVector.y*-15, planePos.z + forwardVector.z*-15, 23)
        createExplosion(planePos.x + rightVector.x*15, planePos.y + rightVector.y*15, planePos.z + rightVector.z*15, 23)
        createExplosion(planePos.x + rightVector.x*-15, planePos.y + rightVector.y*-15, planePos.z + rightVector.z*-15, 23)
        createExplosion(planePos.x + rightVector.x*25, planePos.y + rightVector.y*25, planePos.z + rightVector.z*25, 23)
        createExplosion(planePos.x + rightVector.x*-25, planePos.y + rightVector.y*-25, planePos.z + rightVector.z*-25, 23)
    end
end