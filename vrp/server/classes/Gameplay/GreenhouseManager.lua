-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Gameplay/GreenhouseManager.lua
-- *  PURPOSE:     Greenhouse manager class
-- *
-- ****************************************************************************

GreenhouseManager = inherit(Singleton)

function GreenhouseManager:constructor()
    self.m_Greenhouses = {}
    self.m_GreenhousePrice = 50000
    self.m_BankServer = BankServer.get("gameplay.greenhouse")
    
    self.m_GreenhouseLeaveBind = bind(self.deleteGreenhouse, self)
    PlayerManager:getSingleton():getQuitHook():register(self.m_GreenhouseLeaveBind)
    PlayerManager:getSingleton():getWastedHook():register(self.m_GreenhouseLeaveBind)
    PlayerManager:getSingleton():getAFKHook():register(self.m_GreenhouseLeaveBind)

    addEvent("greenhouseBuy")
	addEventHandler("greenhouseBuy", root, function()
        local price = self.m_GreenhousePrice
		if source:getBankMoney() < price then
			return source:sendError(_("Du hast nicht genug Geld auf der Bank! (%s)", source, toMoneyString(price)))
        else
            if source:transferBankMoney(self.m_BankServer, price, "Gewächshaus-Kauf", "Gameplay", "Greenhouse") then
                source:setHasGreenhouse(true)
            end
        end
	end)

    addEvent("greenhouseEnter")
	addEventHandler("greenhouseEnter", root, function()
        if (source:getFaction() and source:isFactionDuty()) or (source:getCompany() and source:isCompanyDuty()) then
            return source:sendError(_("Du darfst nicht im Dienst sein!", source))
        end
        if source:isInVehicle() then
            return source:sendError(_("Du darfst in keinem Fahrzeug sitzen!", source))
        end
        if source:getWanteds() >= 1 then
            return source:sendError(_("Du kannst das nicht tun, solange du gesucht wirst!", source))
        end
        local shop = ShopManager:getSingleton():getFromId(35) -- Gardening shop
        local group = shop and shop.m_Robable and shop.m_Robable.m_AttackerGroup or false
        if group and group == source:getGroup() then
            return source:sendError(_("Du kannst das nicht tun, während deine Gruppe die Gärtnerei überfällt!", source))
        end
        self:createGreenhouse(source)
	end)

    addEvent("greenhouseExit")
	addEventHandler("greenhouseExit", root, function()
        self:deleteGreenhouse(source)
	end)

	self.m_Ped = NPC:new(157, 2426.80, 121.42, 26.47, 180)
	self.m_Ped:setImmortal(true)
	self.m_Ped:setFrozen(true)
	self.m_Ped:setData("clickable", true, true)
    ElementInfo:new(self.m_Ped, "Gewächshaus", 1.3)
	addEventHandler("onElementClicked", self.m_Ped, function(button, state, player)
		if button == "left" and state == "down" then
            if not player:hasGreenhouse() then
                QuestionBox:new(player, _("Willst du ein Gewächshaus für %s kaufen? Achtung: Der Anbau illegaler Pflanzen ist darin nicht möglich!", player, toMoneyString(self.m_GreenhousePrice)), "greenhouseBuy", nil, false, false)
            else
                QuestionBox:new(player, _("Willst du dein Gewächshaus betreten?", player), "greenhouseEnter", nil, false, false)
            end
		end
	end)

    core:getStopHook():register(function()
        for player, greenhouse in pairs(self.m_Greenhouses) do
            self:deleteGreenhouse(player)
        end
    end)
end

function GreenhouseManager:createGreenhouse(player)
    if not self.m_Greenhouses[player] then
        self.m_Greenhouses[player] = Greenhouse:new(player)
        return self.m_Greenhouses[player]
    end
    return false
end

function GreenhouseManager:deleteGreenhouse(player)
    if self.m_Greenhouses[player] then
        delete(self.m_Greenhouses[player])
        self.m_Greenhouses[player] = nil
        return true
    end
    return false
end