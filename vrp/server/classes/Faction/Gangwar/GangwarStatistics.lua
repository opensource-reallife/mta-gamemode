-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Faction/Gangwar/GangwarStatistics.lua
-- *  PURPOSE:     Gangwar-Statistics Class
-- *
-- ****************************************************************************
GangwarStatistics = inherit(Singleton)
local secondsPerDay = (60*60)*24
local CACHE_TIME = (60*1000)*30

GangwarStatistics.CacheStats = { }
function GangwarStatistics:constructor() 
	self.m_SQLStats = {}
	self.runtimeMostDamage = {}
	self.m_BankAccountServer = BankServer.get("faction.gangwar")
	self:prepareAttackLog( )
	self:getTopTenList( )
end

function GangwarStatistics:prepareAttackLog() 
	self.m_AttackLog = {}
	local result = StatisticsLogger:getSingleton():getGangwarAttackLog( 20 ) 
	if result then 
		for k, row in pairs(result) do 
			self.m_AttackLog[#self.m_AttackLog+1] = {row["Gebiet"], row["Angreifer"], row["Besitzer"], row["StartZeit"], row["EndZeit"], row["Gewinner"]}
		end
	end
end

function GangwarStatistics:getAttackLog() 
	return self.m_AttackLog
end

function GangwarStatistics:addAttackLog( area, attacker, owner, start, endTime, winner)
	table.insert(self.m_AttackLog, 1, {area, attacker, owner, start, endTime, winner})
end

function GangwarStatistics:markAttackLogInvalid( area, attacker, start )
	for _, row in ipairs(self.m_AttackLog) do
		if row[1] == area and row[2] == attacker and row[4] == start then
			row[6] = GANGWAR_INVALID_WINNER
		end
	end
end

function GangwarStatistics:payOfflinePlayer( playerId, amount, areaName )
	self.m_BankAccountServer:transferMoney({"player", playerId, true}, amount, "Gangwar-Boni", "Faction", "GangwarBoni")
	local target, isOffline = DatabasePlayer.get(playerId)
	if target and isOffline then
		target:addOfflineMessage(("Du hast für den Gangwar um %s %d$ Gangwar-Boni auf dein Konto erhalten."):format(areaName, amount), 1)
		delete(target)
	end
end

function GangwarStatistics:collectDamage( stats, review )
	local best = {}
	local receivers = {}
	for id, entry in pairs(stats) do
		local damage = math.ceil(entry.damage)
		local kills = entry.kills
		local moneyDamage = damage * GANGWAR_PAY_PER_DAMAGE
		local moneyKill = kills * GANGWAR_PAY_PER_KILL
		best[#best + 1] = {id = id, name = entry.name, faction = entry.faction:getShortName(), damage = damage, kills = kills}
		self.m_SQLStats[#self.m_SQLStats+1] = {id, "Damage", damage, entry.name}
		self.m_SQLStats[#self.m_SQLStats+1] = {id, "Kill", kills, entry.name}

		local player = Player.getFromId(id)
		if player and isElement(player) then
			receivers[#receivers + 1] = {player = player, own = {
				factionId = entry.faction:getId(),
				color = entry.faction.m_Color,
				damage = damage,
				kills = kills,
				moneyDamage = moneyDamage,
				moneyKill = moneyKill,
			}}
			if moneyDamage + moneyKill > 0 then
				self.m_BankAccountServer:transferMoney({player, true}, moneyDamage + moneyKill, "Gangwar-Boni", "Faction", "GangwarBoni")
			end
		elseif moneyDamage + moneyKill > 0 then
			self:payOfflinePlayer(id, moneyDamage + moneyKill, review.area)
		end
	end

	table.sort(best, function(a, b) return a.damage > b.damage end)
	review.best = best
	for index, receiver in ipairs(receivers) do
		receiver.player:triggerEvent("GangwarReview:show", review, receiver.own)
	end
	if best[1] and best[1].damage > 0 then
		self.m_SQLStats[#self.m_SQLStats+1] = {best[1].id, "MVP", 1, best[1].name}
	end
	self:flushSQLTable()
	self:getTopTenList()
end

function GangwarStatistics:flushSQLTable() 
	local count = 0
	if self.m_SQLStats then 
		local user, type, amount
		for i = 1, #self.m_SQLStats do 
			user, type, amount, name = self.m_SQLStats[i][1], self.m_SQLStats[i][2], self.m_SQLStats[i][3], self.m_SQLStats[i][4]
			count = count + 1
			sqlLogs:queryExec("INSERT INTO ??_GangwarStatistics (UserId, Type, Amount, Date) VALUES(?, ?, ?, NOW())", sqlLogs:getPrefix(), user, type, amount or 1)
			if type == "Damage" then 
				sqlLogs:queryExec("INSERT INTO ??_GangwarTopList (UserId, Name, Damage, Kills, MVP ) VALUES(?, ?, ?, 0, 0) ON DUPLICATE KEY UPDATE Damage = Damage + ?, Name = ?", sqlLogs:getPrefix(), user, name, amount, amount, name)
			elseif type == "Kill" then
				sqlLogs:queryExec("INSERT INTO ??_GangwarTopList (UserId, Name, Damage, Kills, MVP ) VALUES(?, ?, 0, ?, 0) ON DUPLICATE KEY UPDATE Kills = Kills + ?, Name = ?", sqlLogs:getPrefix(), user, name, amount, amount, name)
			else
				sqlLogs:queryExec("INSERT INTO ??_GangwarTopList (UserId, Name, Damage, Kills, MVP ) VALUES(?, ?, 0, 0, 1) ON DUPLICATE KEY UPDATE MVP = MVP + 1, Name = ?", sqlLogs:getPrefix(), user, name, name)
			end
		end
	end
	if count > 0 then outputDebugString(("-- Flushed Gangwar-Statistics into SQL (%s entries) --"):format(count)) end
	self.m_SQLStats = {}
end

function GangwarStatistics:getPlayerStats( player )  
	local now = getTickCount()
	if player then
		local user = player:getId() 
		if not GangwarStatistics.CacheStats[user] then
			local result = sqlLogs:queryFetchSingle("SELECT * FROM ??_GangwarTopList WHERE UserId = ?", sqlLogs:getPrefix(), user)
			if result then
				GangwarStatistics.CacheStats[user] = { getTickCount(), result.Damage, result.Kills, result.MVP }
				local result = sqlLogs:queryFetchSingle("SELECT (SELECT COUNT(*) FROM ??_GangwarTopList WHERE Damage >= ?) AS Position FROM ??_GangwarTopList WHERE UserId=?", sqlLogs:getPrefix(), result.Damage, sqlLogs:getPrefix(), user)
				if result then
					table.insert(GangwarStatistics.CacheStats[user], result.Position or "-")
				end
				local result = sqlLogs:queryFetchSingle("SELECT (SELECT COUNT(*) FROM ??_GangwarTopList WHERE Kills >= ?) AS Position FROM ??_GangwarTopList WHERE UserId=?", sqlLogs:getPrefix(), GangwarStatistics.CacheStats[user][3], sqlLogs:getPrefix(), user)
				if result then
					table.insert(GangwarStatistics.CacheStats[user], result.Position or "-")
				end
				local result = sqlLogs:queryFetchSingle("SELECT (SELECT COUNT(*) FROM ??_GangwarTopList WHERE MVP >= ?) AS Position FROM ??_GangwarTopList WHERE UserId=?", sqlLogs:getPrefix(), GangwarStatistics.CacheStats[user][4], sqlLogs:getPrefix(), user)
				if result then
					table.insert(GangwarStatistics.CacheStats[user], result.Position or "-")
				end
			else 
				GangwarStatistics.CacheStats[user] = { getTickCount(), 0, 0, 0, "-", "-", "-" }
			end
			return GangwarStatistics.CacheStats[user]
		else
			local user = player:getId() 
			local lastUpdated = GangwarStatistics.CacheStats[user][1]
			if not lastUpdated or ( now >= lastUpdated+CACHE_TIME) then 
				local result = sqlLogs:queryFetchSingle("SELECT * FROM ??_GangwarTopList WHERE UserId = ?", sqlLogs:getPrefix(), user)
				if result then
					GangwarStatistics.CacheStats[user] = { getTickCount(), result.Damage, result.Kills, result.MVP }
					local result = sqlLogs:queryFetchSingle("SELECT (SELECT COUNT(*) FROM ??_GangwarTopList WHERE Damage >= ?) AS Position FROM ??_GangwarTopList WHERE UserId=?", sqlLogs:getPrefix(), result.Damage, sqlLogs:getPrefix(), user)
					if result then
						table.insert(GangwarStatistics.CacheStats[user], result.Position or "-")
					end
					local result = sqlLogs:queryFetchSingle("SELECT (SELECT COUNT(*) FROM ??_GangwarTopList WHERE Kills >= ?) AS Position FROM ??_GangwarTopList WHERE UserId=?", sqlLogs:getPrefix(), GangwarStatistics.CacheStats[user][3], sqlLogs:getPrefix(), user)
					if result then
						table.insert(GangwarStatistics.CacheStats[user], result.Position or "-")
					end
					local result = sqlLogs:queryFetchSingle("SELECT (SELECT COUNT(*) FROM ??_GangwarTopList WHERE MVP >= ?) AS Position FROM ??_GangwarTopList WHERE UserId=?", sqlLogs:getPrefix(), GangwarStatistics.CacheStats[user][4], sqlLogs:getPrefix(), user)
					if result then
						table.insert(GangwarStatistics.CacheStats[user], result.Position or "-")
					end
				else 
					GangwarStatistics.CacheStats[user] = { getTickCount(), 0, 0, 0, "-", "-", "-" }
				end
				return GangwarStatistics.CacheStats[user]
			else 
				return GangwarStatistics.CacheStats[user]
			end
		end
	end
	return false
end

function GangwarStatistics:getTopTenList( ) 
	GangwarStatistics.TopStats = { }
	local result = StatisticsLogger:getSingleton():getGangwarTopDamage( 10 ) 
	GangwarStatistics.TopStats["Damage"] = { }
	for k, row in pairs(result) do
		GangwarStatistics.TopStats["Damage"][#GangwarStatistics.TopStats["Damage"]+1] = {row.Name, row.Damage}
	end
	GangwarStatistics.TopStats["Kill"] = { }
	local result = StatisticsLogger:getSingleton():getGangwarTopKill( 10 ) 
	for k, row in pairs(result) do
		GangwarStatistics.TopStats["Kill"][#GangwarStatistics.TopStats["Kill"]+1] = {row.Name, row.Kills}
	end
	GangwarStatistics.TopStats["MVP"] = { }
	local result = StatisticsLogger:getSingleton():getGangwarTopMVP( 10 ) 
	for k, row in pairs(result) do
		GangwarStatistics.TopStats["MVP"][#GangwarStatistics.TopStats["MVP"]+1] = {row.Name, row.MVP}
	end
end


function GangwarStatistics:destructor()	
	self:flushSQLTable()
end
