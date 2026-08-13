QuestFerrisRide = inherit(Quest)

addEvent("onFerrisWheelRide")

function QuestFerrisRide:constructor()
	self.m_FerrisBind = bind(self.onFerrisRide, self)
	addEventHandler("onFerrisWheelRide", root, self.m_FerrisBind)
end

function QuestFerrisRide:virtual_destructor()
	removeEventHandler("onFerrisWheelRide", root, self.m_FerrisBind)
end

function QuestFerrisRide:onFerrisRide()
	local player = source
	if table.find(self:getPlayers(), player) then
		self:success(player)
	end
end