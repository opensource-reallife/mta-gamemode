QuestFishing = inherit(Quest)
QuestFishing.Target = 10

addEvent("onFishCaught")

function QuestFishing:constructor()
	self.m_FishingBind = bind(self.onFishCaught, self)
	self.m_FishCaught = {}

	addEventHandler("onFishCaught", root, self.m_FishingBind)
end

function QuestFishing:destructor()
	removeEventHandler("onFishCaught", root, self.m_FishingBind)
end

function QuestFishing:onFishCaught()
	local player = source
	if table.find(self:getPlayers(), player) then
		if not self.m_FishCaught[player:getId()] then self.m_FishCaught[player:getId()] = 0 end
		self.m_FishCaught[player:getId()] = self.m_FishCaught[player:getId()] + 1
		player:sendShortMessage(_("Quest: Du hast %d/%d Fische geangelt!", player, self.m_FishCaught[player:getId()], QuestFishing.Target))
		if self.m_FishCaught[player:getId()] >= QuestFishing.Target then
			self:success(player)
		end
	end
end