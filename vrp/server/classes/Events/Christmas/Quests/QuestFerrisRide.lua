QuestFerrisRide = inherit(ChristmasQuest)

addEvent("onFerrisWheelRide")

function QuestFerrisRide:constructor(id)
	ChristmasQuest.constructor(self, id)
	self.m_FortuneBind = bind(self.onFerrisRide, self)
	self.m_WheelPlayed = {}

	addEventHandler("onFerrisWheelRide", root, self.m_FortuneBind)
end

function QuestFerrisRide:destructor(id)
	ChristmasQuest.destructor(self)
	removeEventHandler("onFerrisWheelRide", root, self.m_FortuneBind)
end

function QuestFerrisRide:addPlayer(player)
	ChristmasQuest.addPlayer(self, player)
end

function QuestFerrisRide:removePlayer(player)
	ChristmasQuest.removePlayer(self, player)
end

function QuestFerrisRide:onFerrisRide()
	local player = source
	if table.find(self:getPlayers(), player) then
		self:success(player)
	end
end

