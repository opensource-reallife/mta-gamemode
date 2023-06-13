-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Faction/Actions/SearchAndRescue/SARManager.lua
-- *  PURPOSE:     Search and Rescue Manager Class
-- *
-- ****************************************************************************

SARManager = inherit(Singleton)

local SAR_TIME_MIN = 120 -- in minutes
local SAR_TIME_MAX = 180 -- in minutes
local SAR_MIN_PLAYERS = 2
local SAR_MAX_CONCURRENT = 1

function SARManager:constructor()
    self.m_CurrentSAR = { }
    self.m_SARMissions = {
        -- name, message, blipX, blipY, minutes
        [1] = {"Mount Chiliad", "Eine Gruppe Wanderer wird im Gebiet des Mount Chiliad vermisst!", -2371.401, -1611.086, 30},
        [2] = {"Einkaufszentrum LS", "Ein Amokläufer hat mehrere Besucher eines Einkaufszentrums beim All Saints General Hospital verletzt!", 1129.113, -1489.698, 10},
        [3] = {"Geisterstadt", "Einige Jugendliche sind von einer Übernachtung in der sogenannten Geisterstadt nicht zurückgekehrt.", -384.62, 2239.91, 20},
    }
    self.m_MissionPeds = {
        [1] = {
            {-2719.30, -1319.13, 150.31},
            {-2722.60, -1838.54, 149.90},
            {-2487.15, -1114.97, 137.41},
            {-2641.16, -1402.86, 264.53},
            {-2608.78, -1342.57, 260.49},
            {-2465.76, -1347.47, 310.96},
            {-2432.27, -1333.85, 310.63},
            {-2515.25, -1429.03, 349.52},
            {-2605.03, -1587.13, 344.27},
            {-2505.00, -1881.58, 300.06},
            {-2688.98, -1679.47, 257.37},
            {-1968.93, -1610.57, 87.01},
            {-1969.70, -1511.46, 88.32},
            {-2055.26, -1525.29, 125.16},
            {-2053.52, -1571.85, 139.35},
            {-2149.59, -1756.62, 210.28},
            {-2295.78, -1928.07, 273.47},
            {-2503.74, -1882.26, 299.87},
            {-2717.17, -1593.94, 236.61},
            {-2669.45, -1544.86, 305.26},
            {-2475.74, -1294.20, 297.37},
            {-2329.90, -1196.06, 205.74},
            {-2445.75, -1224.96, 232.65},
            {-2316.66, -1254.79, 244.20},
            {-2226.67, -1364.44, 278.14},
            {-2178.28, -1433.02, 220.12},
            {-2358.24, -1359.94, 299.41},
            {-2335.04, -1686.58, 484.58},
            {-2339.61, -1552.06, 477.46},
            {-2292.57, -1804.90, 438.10},
        },
        [2] = {
            {1145.928, -1449.324, 15.797},
            {1111.809, -1470.681, 15.797},
            {1072.574, -1494.065, 22.756},
            {1118.865, -1514.919, 15.797},
            {1158.60, -1452.69, 22.77},
            {1144.86, -1426.53, 22.77},
            {1114.40, -1517.22, 15.80},
            {1109.15, -1491.38, 15.80},
            {1097.45, -1481.94, 15.80},
            {1106.50, -1420.21, 15.80},
            {1131.03, -1438.25, 15.80},
            {1138.93, -1483.36, 15.80},
            {1156.01, -1516.22, 22.75},
            {1105.87, -1521.05, 22.75},
            {1127.26, -1549.69, 22.75},
        },
        [3] = {
            {-480.40, 2183.54, 41.86},
            {-337.43, 2224.80, 42.49},
            {-333.21, 2215.00, 42.48},
            {-424.27, 2238.60, 42.43},
            {-403.49, 2267.75, 41.89},
            {-128.88, 2256.27, 27.88},
            {-423.12, 2125.82, 46.18},
            {-460.42, 2183.78, 47.05},
            {-503.15, 2287.86, 64.19},
            {-294.14, 2114.70, 51.23},
            {-296.04, 2066.68, 60.83},
            {-304.03, 2094.70, 35.48},
            {-323.40, 2277.85, 69.95},
            {-346.55, 2322.24, 58.42},
            {-516.75, 2132.25, 72.28},
        }
    }

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