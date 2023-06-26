-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Faction/FactionInsurgent.lua
-- *  PURPOSE:     Insurgent Faction Class
-- *
-- ****************************************************************************

FactionInsurgent = inherit(Singleton)

function FactionInsurgent:constructor() 
	self.m_Faction = FactionManager.Map[13]
end

function FactionInsurgent:getOnlinePlayers(afkCheck, dutyCheck)
	local players = {}
	for index, value in pairs(self.m_Faction:getOnlinePlayers(afkCheck, dutyCheck)) do
		table.insert(players, value)
	end
	return players
end

function FactionInsurgent:sendWarning(text, header, withOffDuty, ...)
	for k, player in pairs(self:getOnlinePlayers(false, not withOffDuty)) do
		player:sendWarning(_(text, player, ...), 30000, header)
	end
end

function FactionInsurgent:destructor() 
end

