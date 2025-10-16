-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Events/Easter/Easter.lua
-- *  PURPOSE:     Easter class
-- *
-- ****************************************************************************

Easter = inherit(Singleton)
Easter.startDay = EVENT_EASTER_START_DAY
Easter.today = getRealTime().yearday
Easter.RabbitObjects = { -- true = createObject ; false = removeWorldModel
    [4] = {
        {isNew=true, id=6959, x=2772.6, y=-1383.54, z=9.2, xr=0, yr=270, zr=0}
    },
    [8] = {
        {isNew=false, id=10671, radius=8.4, x=-2454.252, y=-125.72504, z=27.12412},
        {isNew=true, id=10671, x=-2454.5, y=-123.059, z=27.5, xr=0, yr=0, zr=0}
    },
    [9] = {
        {isNew=false, id=1497, radius=3.5, x=965.89465, y=2161.281, z=10.96091},
        {isNew=true, id=1491, x=966.07898, y=2162.1599, z=9.8, xr=0, yr=0, zr=270},
        {isNew=true, id=1491, x=966.09961, y=2159.1348, z=9.8, xr=0, yr=0, zr=90}
    }
}
addRemoteEvents{"Easter:requestHidingRabbits", "Easter:onHidingRabbitFound"}

local day = getRealTime().monthday
local month = getRealTime().month+1

if (month == 3) or (month == 4 and day <= 7) then
	Easter.ms_PricePoolName = "Easter2024-1"
	Easter.ms_PricePoolEnd = 1712505600
	Easter.ms_PricePoolPrices = {
        {"money", 50000}, 
        {"vehicle", 600}, 
        {"VIP", 1}
	}
end

function Easter:constructor()
    self.m_Objects = {}
    for day, data in pairs(Easter.RabbitObjects) do
        if getRealTime().yearday - Easter.startDay >= day then
            for index, object in pairs(data) do
                if object.isNew then
                    self.m_Objects[#self.m_Objects+1] = createObject(object.id, object.x, object.y, object.z, object.xr, object.yr, object.zr)
                else
                    removeWorldModel(object.id, object.radius, object.x, object.y, object.z)
                end
            end
        end
    end
    if Easter.ms_PricePoolName then
		self.m_PricePool = PricePoolManager:getSingleton():getPricePool(Easter.ms_PricePoolName, "Osterei", Easter.ms_PricePoolPrices, Easter.ms_PricePoolEnd)
		if self.m_PricePool then
            self.m_PricePool:setDailyEntryBuyLimit(50)
			PricePoolManager:getSingleton():createPed(self.m_PricePool, 185, Vector3(1483.915, -1750.245, 15.445), 0)
		end
	end
    addEventHandler("Easter:requestHidingRabbits", root, bind(self.requestHidingRabbits, self))
    addEventHandler("Easter:onHidingRabbitFound", root, bind(self.onHidingRabbitFound, self))
end

function Easter:destructor()
    for day, data in pairs(Easter.RabbitObjects) do
        for index, object in pairs(data) do
            if object.isNew == false then
                restoreWorldModel(object.id, object.radius, object.x, object.y, object.z)
            end
        end
    end
end

function Easter:requestHidingRabbits()
    local rabbit = 0
    local result = sql:queryFetchSingle("SELECT RabbitsFound, Year FROM ??_easter_rabbit_data WHERE UserId = ?", sql:getPrefix(), client:getId())
	if result then
        if result.Year ~= getRealTime().year + 1900 then
            sql:queryExec("DELETE FROM ??_easter_rabbit_data WHERE UserId = ?", sql:getPrefix(), client:getId())
        else
            rabbit = result.RabbitsFound
        end
    end
    if Easter.today - Easter.startDay >= rabbit then
        client:triggerEvent("Easter:loadHidingRabbit", rabbit)
    end
end

function Easter:onHidingRabbitFound(rabbit)
    if rabbit == 1 then
        sql:queryExec("INSERT INTO ??_easter_rabbit_data (UserId, RabbitsFound, Year) VALUES (?, ?, ?)", sql:getPrefix(), client:getId(), 1, getRealTime().year + 1900)
    else
        sql:queryExec("UPDATE ??_easter_rabbit_data SET RabbitsFound = ? WHERE UserId = ?", sql:getPrefix(), rabbit, client:getId())
    end
    client:getInventory():giveItem("Osterei", 10)
    client:sendSuccess("Du hast ein Helferchen des Osterhasen gefunden! Du hast 10 Ostereier erhalten!")
end