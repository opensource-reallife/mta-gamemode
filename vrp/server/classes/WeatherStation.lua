-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/WeatherStation.lua
-- *  PURPOSE:     Serverside weather stations
-- *
-- ****************************************************************************
WeatherStation = inherit(Object)

function WeatherStation:constructor(data)
	self.m_MainStation = data.MainStation
	self.m_StationName = data.Name
	self.m_TargetFrequency = Randomizer:get(30, 300)
	self.m_Frequency = self.m_TargetFrequency
	self.m_Connected = true

	if not self.m_MainStation then
		self.m_Blip = Blip:new("SatelliteDish.png", data.Position.x, data.Position.y, {company = CompanyStaticId.SANNEWS}, 400)
		self.m_Blip:setDisplayText("Wetterstation", BLIP_CATEGORY.Other)
	end

	self.m_Station = createObject(1596, data.Position)
	self.m_Station:setData("clickable", true, true)

	self.m_Timer = false
	self.m_TimerBind = bind(self.resetTimer, self)
	self:resetTimer(true)

	addEventHandler("onElementClicked",self.m_Station, bind(self.onStationClicked, self))
end

function WeatherStation:onStationClicked(button, state, player)
	if getDistanceBetweenPoints3D(self.m_Station.position, player.position) > 10 then return end
	if button == "left" and state == "down" then
		if player:getCompany() and player:getCompany():getId() == CompanyStaticId.SANNEWS and player:isCompanyDuty() then
			if self.m_MainStation then
				player:triggerEvent("onWeatherStationClicked", Weather:getSingleton().m_WeatherStations)
			elseif self.m_Frequency ~= self.m_TargetFrequency then
				player:triggerEvent("inputBox", _("Wetterstation", player), _("Gib die korrekte Frequenz ein, um die Verbindung wiederherzustellen!", player), "receiveFrequency", self.m_StationName)
			else
				player:sendInfo(_("Diese Station ist bereits korrekt eingestellt!", player))
			end
		else
			player:sendError(_("Du bist kein San News-Mitglied oder nicht im Dienst!", player))
		end
	end
end

function WeatherStation:resetTimer(retainState)
	if isTimer(self.m_Timer) then self.m_Timer:destroy() end
	if table.size(CompanyManager.Map[CompanyStaticId.SANNEWS]:getOnlinePlayers(true)) >= 1 and not retainState then
		self.m_TargetFrequency = Randomizer:get(30, 300)
		self.m_Frequency = false
		self.m_Connected = false
	end
	self.m_Timer = Timer(self.m_TimerBind, 1000 * 60 * Randomizer:get(30, 90), 1)
end