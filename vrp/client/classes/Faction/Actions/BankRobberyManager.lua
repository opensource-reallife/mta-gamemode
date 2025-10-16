-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Faction/Actions/BankRobberyManager.lua
-- *  PURPOSE:     Bank Robbery Manager Class
-- *
-- ****************************************************************************

BankRobberyManager = inherit(Singleton)

function BankRobberyManager:constructor()
	self.m_StatisticShortMessage = false

	addEvent("refreshBankRobStats", true)
	addEventHandler("refreshBankRobStats", root, bind(self.updateStatistics, self))
end

function BankRobberyManager:updateStatistics(timeRemaining, timeSafeOpen)
	local timeRemainingFormatted, timeSafeOpenFormatted = "-", "-"

	if not self.m_StatisticShortMessage then
		self.m_StatisticShortMessage = ShortMessage:new("", "Bank-Überfall", Color.LightBlue, 2000, nil, function()
			self.m_StatisticShortMessage = nil
		end, nil, nil, true)
	end

	if timeRemaining then
		local seconds = math.floor(timeRemaining / 1000)
		local minutes = math.floor(seconds / 60)
		seconds = (seconds % 60) + 1
		if seconds == 60 then
			seconds = 0
			minutes = minutes + 1
		end
		timeRemainingFormatted = string.format("%s Minute(n), %s Sekunde(n)", minutes, seconds)
	end

	if timeSafeOpen then
		local seconds = math.floor(timeSafeOpen / 1000)
		local minutes = math.floor(seconds / 60)
		seconds = (seconds % 60) + 1
		if seconds == 60 then
			seconds = 0
			minutes = minutes + 1
		end
		timeSafeOpenFormatted = string.format("%s Minute(n), %s Sekunde(n)", minutes, seconds)
	end

	self.m_StatisticShortMessage:setText(("Zeit übrig: %s\nSafe offen: %s"):format(timeRemainingFormatted, timeSafeOpenFormatted))
	self.m_StatisticShortMessage:resetTimeout()
end