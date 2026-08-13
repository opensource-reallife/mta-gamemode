Quest = inherit(Object)

function Quest:virtual_constructor(questId, questData)
	self.m_Players = {}
	self.m_QuestId = questId

	self.m_Name = questData["Name"]
	self.m_Description = questData["Description"]
	self.m_Reward = questData["Reward"]
end

function Quest:destructor()
	for index, player in pairs(self:getPlayers()) do
		self:removePlayer(player)
	end
end

function Quest:addPlayer(player)
	table.insert(self.m_Players, player)
	player:triggerEvent("questAddPlayer", self.m_QuestId, _(self.m_Name, player), _(self.m_Description, player))
end

function Quest:getPlayers()
	return self.m_Players
end

function Quest:isQuestDone(player)
	local questManager = QuestManager:getSingleton()
	local playerId = player:getId()
	if questManager.m_QuestProgress[playerId] and questManager.m_QuestProgress[playerId][self.m_QuestId] then
		return true
	end
	return false
end

function Quest:removePlayer(player)
	table.remove(self.m_Players, table.find(self.m_Players, player))
	player:triggerEvent("questRemovePlayer", self.m_QuestId)
end

function Quest:onClick(player)
	player:triggerEvent("questOpenGUI", self.m_QuestId, _(self.m_Name, player), _(self.m_Description, player), self.m_Reward, player)
end

function Quest:success(player)
	if table.find(self:getPlayers(), player) then
		local questManager = QuestManager:getSingleton()
		local playerId = player:getId()
		if not questManager.m_QuestProgress[playerId] then
			questManager.m_QuestProgress[playerId] = {}
		end
		questManager.m_QuestProgress[playerId][self.m_QuestId] = true
		
		outputDebug("success")
		local rewardString = ""
		for k, v in ipairs(self.m_Reward) do
			if v[1] == "Dollar" then
				local bankServer = BankServer.get("gameplay.quest")
				bankServer:transferMoney(player, v[2], "Quest-Belohnung", "Gameplay", "Quest")
			elseif v[1] == "Punkte" then
				player:givePoints(v[2])
			else
				player:getInventory():giveItem(v[1], v[2])
			end
			rewardString = rewardString .. v[2] .. " " .. _(v[1], player)
			if self.m_Reward[k+1] then
				rewardString = rewardString .. ", "
			end
		end
		player:sendSuccess(_("Quest bestanden! Belohnung: %s", player, rewardString))
		sql:queryExec("INSERT INTO ??_quest (UserId, QuestId, Date) VALUES(?, ?, NOW())", sql:getPrefix(), playerId, self.m_QuestId)
		self:removePlayer(player)
		outputDebug(self.m_Players)
	end
end
