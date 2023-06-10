-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Factions/Actions/SearchAndRescue/SAR.lua
-- *  PURPOSE:     Search and Rescue Class
-- *
-- ****************************************************************************

SAR = inherit(Object)

function SAR:constructor(pedPositions, missionID, missionInfo)
    self.m_Injured = { }
    self.m_PedStats = { ["total"] = 0, ["found"] = 0, ["rescued"] = 0 }
    self.m_MissionData = { ["id"] = missionID, ["name"] = missionInfo[1], ["blip"] = nil }
    self.m_Timers = { ["cancel"] = setTimer(bind(self.endSAR, self), 1000 * 60 * missionInfo[5], 1), ["stats"] = setTimer(bind(self.triggerStatistics, self), 1000, 0) }
    self.m_DeleteEvent = bind(self.Event_onElementDestroy, self)
    self.m_BankAccountServer = BankServer.get("action.sar")

    FactionRescue:getSingleton():sendWarning(missionInfo[2], "Suchen & Retten", true)
    self:createBlip(missionInfo[3], missionInfo[4])
    self:createInjured(pedPositions)
end

function SAR:createInjured(pedPositions)
    local pedPositions = Randomizer:getRandomOf(table.size(pedPositions) * (Randomizer:get(20, 40) / 100), pedPositions)

    for key, value in pairs(pedPositions) do
        self.m_PedStats["total"] = self.m_PedStats["total"] + 1

        self.m_Injured[key] = ColShape.Sphere(value[1], value[2], value[3], 10)

        self.m_Injured[key].ped = NPC:new(Randomizer:get(9, 41), value[1], value[2], value[3], Randomizer:get(0, 360))
        self.m_Injured[key].ped:setFrozen(true)
        self.m_Injured[key].ped:setImmortal(true)
        self.m_Injured[key].ped:setAnimation("CRACK", "crckidle2", -1, true, false, false)

        addEventHandler("onColShapeHit", self.m_Injured[key], bind(self.Event_onColShapeHit, self))
        addEventHandler("onElementDestroy", self.m_Injured[key].ped, self.m_DeleteEvent)
        addEventHandler("onElementStartSync", self.m_Injured[key].ped, bind(self.Event_onElementStartSync, self))
    end
end

function SAR:createBlip(blipX, blipY)
    self.m_MissionData["blip"] = Blip:new("Police.png", blipX, blipY, root, 400)
	self.m_MissionData["blip"]:setOptionalColor(BLIP_COLOR_CONSTANTS.Red)
	self.m_MissionData["blip"]:setDisplayText("Rettungsaktion")
end

function SAR:Event_onColShapeHit(hitElement)
    if hitElement:getType() == "player" then
        local faction = hitElement:getFaction()
        if (faction:isRescueFaction() or faction:isStateFaction()) and hitElement:isFactionDuty() then
            local ped = source.ped
            if isElement(ped) and not ped.m_Dead then
                hitElement:sendInfo(_("Du hast eine verletzte Person gefunden!"))
                ped.m_Dead = true
                FactionRescue:getSingleton():createPedDeathPickup(ped, "Verletzte Person")
                self.m_PedStats["found"] = self.m_PedStats["found"] + 1
                self.m_BankAccountServer:transferMoney(hitElement, 500, "Verletzte Person gefunden (Suchen & Retten)", "Faction", "SAR")
            end
        else
            hitElement:sendInfo(_("Eine verletzte Person! Du solltest schnellstens Rettungskräfte informieren!"))
        end
    end
end

function SAR:Event_onElementDestroy()
    self.m_PedStats["rescued"] = self.m_PedStats["rescued"] + 1

    if self.m_PedStats["rescued"] == self.m_PedStats["total"] then
        self:endSAR()
    end
end

function SAR:Event_onElementStartSync()
    source:setAnimation("CRACK", "crckidle2", -1, true, false, false)
end

function SAR:endSAR()
    if self.m_PedStats["rescued"] == self.m_PedStats["total"] then
        FactionRescue:getSingleton():sendWarning("Die Rettungsaktion wurde erfolgreich beendet!", "Suchen & Retten", true)
    elseif self.m_PedStats["rescued"] > 0 then
        FactionRescue:getSingleton():sendWarning("Es konnten leider nur " .. self.m_PedStats["rescued"] .. " von " .. self.m_PedStats["total"] .. " Personen rechtzeitig gerettet werden!", "Suchen & Retten", true)
    else
        FactionRescue:getSingleton():sendWarning("Niemand konnte rechtzeitig gerettet werden!", "Suchen & Retten", true)
    end

    if self.m_PedStats["rescued"] > 0 then
        self.m_BankAccountServer:transferMoney(FactionRescue:getSingleton().m_Faction, self.m_PedStats["rescued"] * 2000, "Abschluss Suchen & Retten", "Event", "SAR")
    end

    SARManager:getSingleton():stopSAR(self.m_MissionData["id"])
end

function SAR:triggerStatistics()
    local timeLeft = self.m_Timers["cancel"]:getDetails()
	triggerClientEvent(FactionRescue:getSingleton():getOnlinePlayers(true, true), "refreshSARStats", resourceRoot, self.m_MissionData["name"], self.m_PedStats, timeLeft)
end

function SAR:destructor()
    for key, value in pairs(self.m_Injured) do
        if isElement(value.ped) then
            if value.ped.m_DeathPickup then FactionRescue:getSingleton():removePedDeathPickup(value.ped) end
            removeEventHandler("onElementDestroy", value.ped, self.m_DeleteEvent)
            value.ped:destroy()
        end
        if isElement(value) then
            value:destroy()
        end
    end

    if self.m_MissionData["blip"] then self.m_MissionData["blip"]:delete() end
    if self.m_Timers["cancel"] then self.m_Timers["cancel"]:destroy() end
    if self.m_Timers["stats"] then self.m_Timers["stats"]:destroy() end
end