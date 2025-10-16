ChristmasQuest = inherit(Object)

function ChristmasQuest:constructor(Id)
	self.m_Players = {}
	self.m_QuestId = Id

	self.m_Name = ChristmasQuestManager.Quests[Id]["Name"]
	self.m_Description = ChristmasQuestManager.Quests[Id]["Description"]
	self.m_Packages = ChristmasQuestManager.Quests[Id]["Packages"]

end

function ChristmasQuest:destructor()
	for index, player in pairs(self:getPlayers()) do
		self:removePlayer(player)
	end
end


function ChristmasQuest:addPlayer(player, ...)
	table.insert(self.m_Players, player)
	player:triggerEvent("questAddPlayer", self.m_QuestId, self.m_Name, self.m_Description, ...)
end

function ChristmasQuest:getPlayers()
	return self.m_Players
end

function ChristmasQuest:isQuestDone(player)
	local row = sql:queryFetchSingle("SELECT Id FROM ??_christmas_quest WHERE UserId = ? and QuestId = ?", sql:getPrefix(), player:getId(), self.m_QuestId)
	return row and true or false
end

function ChristmasQuest:removePlayer(player)
	table.remove(self.m_Players, table.find(self.m_Players, player))
	player:triggerEvent("questRemovePlayer", self.m_QuestId)
end

function ChristmasQuest:onClick(player)
	player:triggerEvent("questOpenGUI", self.m_QuestId, self.m_Name, self.m_Description, self.m_Packages)
end

function ChristmasQuest:success(player)
	if table.find(self:getPlayers(), player) then
		outputDebug("success")
		player:sendSuccess(_("Quest bestanden! Du erhälst %d Päckchen!", player, self.m_Packages))
		sql:queryExec("INSERT INTO ??_christmas_quest (UserId, QuestId, Date) VALUES(?, ?, NOW())", sql:getPrefix(), player:getId(), self.m_QuestId)
		player:getInventory():giveItem("Päckchen", self.m_Packages)
		self:removePlayer(player)
		outputDebug(self.m_Players)
	end
end
