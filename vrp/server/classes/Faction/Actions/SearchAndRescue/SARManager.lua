-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Faction/Actions/SearchAndRescue/SARManager.lua
-- *  PURPOSE:     Search and Rescue Manager Class
-- *
-- ****************************************************************************

SARManager = inherit(Singleton)

local SAR_TIME_MIN = 120 -- in minutes
local SAR_TIME_MAX = 240 -- in minutes
local SAR_MIN_PLAYERS = 2
local SAR_MAX_CONCURRENT = 1

function SARManager:constructor()
    self.m_CurrentSAR = { }

    self.m_SARMissions = { }
    local result = sql:queryFetch("SELECT * FROM ??_sar_missions", sql:getPrefix())
	for i, row in pairs(result) do
		self.m_SARMissions[row.Id] = {row.Name, row.Message, row.BlipX, row.BlipY, row.Duration}
    end

    self.m_MissionPeds = { }
    local result = sql:queryFetch("SELECT * FROM ??_sar_peds", sql:getPrefix())
	for i, row in pairs(result) do
        if not self.m_MissionPeds[row.MissionId] then self.m_MissionPeds[row.MissionId] = { } end
        table.insert(self.m_MissionPeds[row.MissionId], {row.PosX, row.PosY, row.PosZ})
    end

    self.m_SARTimer = setTimer(bind(self.checkSAR, self), 1000 * 60 * math.random(SAR_TIME_MIN, SAR_TIME_MAX), 1)
end

function SARManager:checkSAR()
    if FactionRescue:getSingleton():countPlayers(true, false) >= SAR_MIN_PLAYERS and table.size(self.m_CurrentSAR) < SAR_MAX_CONCURRENT then
        self:startSAR()
    else
        outputDebug("Could not start SAR because not enough players or max concurrent already running")
    end

    if self.m_SARTimer:isValid() then self.m_SARTimer:destroy() end
    self.m_SARTimer = setTimer(bind(self.checkSAR, self), 1000 * 60 * math.random(SAR_TIME_MIN, SAR_TIME_MAX), 1)
end

function SARManager:startSAR(missionID)
    local missionID = tonumber(missionID)

    if not missionID then
        missionID = math.random(table.size(self.m_SARMissions))
    end

    self:stopSAR(missionID)

    outputDebug("Starting SAR with name " .. self.m_SARMissions[missionID][1])
    
    self.m_CurrentSAR[missionID] = SAR:new(self.m_MissionPeds[missionID], missionID, self.m_SARMissions[missionID])
end

function SARManager:stopSAR(missionID)
    local missionID = tonumber(missionID)

    if missionID then
        if self.m_CurrentSAR[missionID] then
            outputDebug("Stopping SAR with name " .. self.m_SARMissions[missionID][1])
            self.m_CurrentSAR[missionID]:delete()
            self.m_CurrentSAR[missionID] = nil
        end
    else
        for key, value in pairs(self.m_CurrentSAR) do
            outputDebug("Stopping SAR with name " .. self.m_SARMissions[key][1])
            self.m_CurrentSAR[key]:delete()
            self.m_CurrentSAR[key] = nil
        end
    end
end