-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Faction/ActionMoneySplitManager.lua
-- *  PURPOSE:     ActionMoneySplitManager Class
-- *
-- ****************************************************************************

ActionMoneySplitManager = inherit(Singleton)

function ActionMoneySplitManager:constructor()
    addRemoteEvents{"actionMoneySplitRequestSplitData", "actionMoneySplitChangeSplits"}

    self.m_MaxSplits = {}

    self:loadActionMoneySplits()

    addEventHandler("actionMoneySplitRequestSplitData", root, bind(self.Event_actionMoneySplitRequestSplitData, self))
	addEventHandler("actionMoneySplitChangeSplits", root, bind(self.Event_actionMoneySplitChangeSplits, self))

end

function ActionMoneySplitManager:loadActionMoneySplits()
    local result = sql:queryFetch("SELECT * FROM ??_action_money_splits", sql:getPrefix())
    for i, v in pairs(result) do
        self.m_MaxSplits[v["Action"]] = v["MaxSplit"]
    end
end

function ActionMoneySplitManager:getMaxPerPlayer()
	return MAX_MONEY_PER_PLAYER_FROM_SPLIT
end

function ActionMoneySplitManager:getMaxLimits()
    return self.m_MaxSplits
end

function ActionMoneySplitManager:getMaxLimit(action)
    return self.m_MaxSplits[action]
end

function ActionMoneySplitManager:Event_actionMoneySplitRequestSplitData()
	if not client or not client:getFaction() then return end

	local faction = client:getFaction()
    if (faction:isStateFaction()) then
        faction = FactionManager:getSingleton():getFromId(1)
    end

	local temp = {["currentStates"] = {}, ["maxStates"] = {}, ["maxSplitPerPlayer"] = self:getMaxPerPlayer()}

	temp["currentStates"] = faction:getActionSplits()
	temp["maxStates"] = self:getMaxLimits()

	client:triggerEvent("sendActionMoneySplitData", temp)
end


function ActionMoneySplitManager:Event_actionMoneySplitChangeSplits(changes)
	if not client or not client:getFaction() then return end
	if table.size(changes) == 0 then return end
	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "faction", "changeActionMoneySplit") then
		-- TODO Nils
		return
	end
	local faction = client:getFaction()
    if (faction:isStateFaction()) then
        faction = FactionManager:getSingleton():getFromId(1)
    end

	for name, percentSplit in pairs(changes) do
		faction:setActionSplit(name, percentSplit)
	end
	client:sendSuccess(_("Aktionsbeteilungswerte wurde geändert.", client))
end

function ActionMoneySplitManager:splitMoney(faction, action, earnedMoney)
    if not faction or not earnedMoney or earnedMoney <= 0 then return end

    local actionSplit = faction:getActionSplit(action)

    if (not actionSplit or actionSplit <= 0) then return end

    local moneyToSplit = earnedMoney / 100 * actionSplit

    local onlinePlayers = faction:getActionSplitMoneyPlayers()
    if (faction:isStateFaction()) then
        onlinePlayers = FactionState:getSingleton():getActionSplitMoneyPlayers()   
    end
    local count = #onlinePlayers

    local moneyPerPersonRaw = math.floor(moneyToSplit / count)  
    local moneyPerPerson = moneyPerPersonRaw > self:getMaxPerPlayer() and self:getMaxPerPlayer() or moneyPerPersonRaw

    for i, v in pairs(onlinePlayers) do
        faction:transferMoney({v, true}, moneyPerPerson, "Aktionsbeteiligung", "Action", "ActionMoneySplit", {silent = true})
        faction:addLog(v, "Aktion", ("hat %s aufgrund der Aktionsbeteiligung ausgezahlt bekommen."):format(toMoneyString(moneyPerPerson), v:getName()))
    end
end