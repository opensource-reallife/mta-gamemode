QuestNoQuest = inherit(Quest)

function QuestNoQuest:constructor()
end

function QuestNoQuest:destructor()
end

function QuestNoQuest:addPlayer(player)
	Quest.addPlayer(self, player)
	self:success(player)
end

function QuestNoQuest:removePlayer(player)
	Quest.removePlayer(self, player)
end
