QuestSlotmachine = inherit(Quest)
QuestSlotmachine.Target = 3

addEvent("onSlotmachineUse")

function QuestSlotmachine:constructor()
	self.m_SlotmachineBind = bind(self.onSlotmachineUse, self)
	self.m_SlotmachineUsed = {}

	addEventHandler("onSlotmachineUse", root, self.m_SlotmachineBind)
end

function QuestSlotmachine:virtual_destructor()
	removeEventHandler("onSlotmachineUse", root, self.m_SlotmachineBind)
end

function QuestSlotmachine:onSlotmachineUse()
	local player = source
	if table.find(self:getPlayers(), player) then
		if not self.m_SlotmachineUsed[player:getId()] then self.m_SlotmachineUsed[player:getId()] = 0 end
		self.m_SlotmachineUsed[player:getId()] = self.m_SlotmachineUsed[player:getId()] + 1
		player:sendShortMessage(_("Quest: Du hast %d/%d am Spielautomaten gespielt!", player, self.m_SlotmachineUsed[player:getId()], QuestSlotmachine.Target))
		if self.m_SlotmachineUsed[player:getId()] >= QuestSlotmachine.Target then
			self:success(player)
		end
	end
end