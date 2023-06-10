-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Faction/Actions/SARManager.lua
-- *  PURPOSE:     Search and Rescue Manager Class
-- *
-- ****************************************************************************

SARManager = inherit(Singleton)

function SARManager:constructor()
	self.m_StatisticShortMessage = {}

	addEvent("refreshSARStats", true)
	addEventHandler("refreshSARStats", root, bind(self.updateStatistics, self))
end

function SARManager:updateStatistics(missionName, pedStats, timeRemaining)
	if not self.m_StatisticShortMessage[missionName] then
		self.m_StatisticShortMessage[missionName] = ShortMessage:new("", "Suchen & Retten ("..(missionName)..")", Color.Orange, 2000, nil, function()
			self.m_StatisticShortMessage[missionName] = nil
		end)
	end
	local sm = self.m_StatisticShortMessage[missionName]

	local seconds = math.floor(timeRemaining / 1000)
	local minutes = math.floor(seconds / 60)
	seconds = (seconds % 60) + 1
	if seconds == 60 then
		seconds = 0
		minutes = minutes + 1
	end
	local timeFormatted = string.format("%s Minuten %s Sekunden", minutes, seconds)

	local t = ("Zeit übrig: %s\n\nGesuchte Personen: %s\nGefundende Personen: %s\nGerettete Personen: %s"):format(timeFormatted, pedStats["total"], pedStats["found"], pedStats["rescued"])

	sm:setText(t)
	sm:resetTimeout()
end