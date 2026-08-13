QuestGrowablePlant = inherit(Quest)
QuestGrowablePlant.Target = 5

addEvent("onGrowablePlanted")

function QuestGrowablePlant:constructor()
	self.m_GrowableBind = bind(self.onGrowablePlanted, self)
	self.m_GrowablesPlanted = {}

	addEventHandler("onGrowablePlanted", root, self.m_GrowableBind)
end

function QuestGrowablePlant:virtual_destructor()
	removeEventHandler("onGrowablePlanted", root, self.m_GrowableBind)
end

function QuestGrowablePlant:onGrowablePlanted()
	local player = source
	if table.find(self:getPlayers(), player) then
		if not self.m_GrowablesPlanted[player:getId()] then self.m_GrowablesPlanted[player:getId()] = 0 end
		self.m_GrowablesPlanted[player:getId()] = self.m_GrowablesPlanted[player:getId()] + 1
		player:sendShortMessage(_("Quest: Du hast %d/%d Pflanzen angepflanzt!", player, self.m_GrowablesPlanted[player:getId()], QuestGrowablePlant.Target))
		if self.m_GrowablesPlanted[player:getId()] >= QuestGrowablePlant.Target then
			self:success(player)
		end
	end
end