QuestNoQuest = inherit(ChristmasQuest)

function QuestNoQuest:constructor(id)
	ChristmasQuest.constructor(self, id)
end

function QuestNoQuest:destructor(id)
	ChristmasQuest.destructor(self)
end

function QuestNoQuest:addPlayer(player)
	ChristmasQuest.addPlayer(self, player)
	self:success(player)
end

function QuestNoQuest:removePlayer(player)
	ChristmasQuest.removePlayer(self, player)
end
