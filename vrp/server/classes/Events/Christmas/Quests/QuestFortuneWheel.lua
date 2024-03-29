QuestFortuneWheel = inherit(ChristmasQuest)
QuestFortuneWheel.Target = 3

addEvent("onFortuneWheelPlay")

function QuestFortuneWheel:constructor(id)
	ChristmasQuest.constructor(self, id)
	self.m_FortuneBind = bind(self.onFortuneWheelPlay, self)
	self.m_WheelPlayed = {}

	addEventHandler("onFortuneWheelPlay", root, self.m_FortuneBind)
end

function QuestFortuneWheel:destructor(id)
	ChristmasQuest.destructor(self)
	removeEventHandler("onFortuneWheelPlay", root, self.m_FortuneBind)
end

function QuestFortuneWheel:addPlayer(player)
	ChristmasQuest.addPlayer(self, player)
end

function QuestFortuneWheel:removePlayer(player)
	ChristmasQuest.removePlayer(self, player)
end

function QuestFortuneWheel:onFortuneWheelPlay()
	local player = source
	if table.find(self:getPlayers(), player) then
		if not self.m_WheelPlayed[player:getId()] then self.m_WheelPlayed[player:getId()] = 0 end
		self.m_WheelPlayed[player:getId()] = self.m_WheelPlayed[player:getId()] +1
		player:sendShortMessage(_("Quest: Du hast das Glücksrad bereits %d/%dx gedreht!", player, self.m_WheelPlayed[player:getId()], QuestFortuneWheel.Target))
		if self.m_WheelPlayed[player:getId()] >= QuestFortuneWheel.Target then
			self:success(player)
		end
	end
end

