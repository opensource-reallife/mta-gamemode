QuestBeggarHelp = inherit(Quest)

addEvent("onBeggarHelp")

function QuestBeggarHelp:constructor()
	self.m_BeggarHelpBind = bind(self.onBeggarHelp, self)
	addEventHandler("onBeggarHelp", root, self.m_BeggarHelpBind)
end

function QuestBeggarHelp:virtual_destructor()
	removeEventHandler("onBeggarHelp", root, self.m_BeggarHelpBind)
end

function QuestBeggarHelp:onBeggarHelp()
	local player = source
	if table.find(self:getPlayers(), player) then
		self:success(player)
	end
end