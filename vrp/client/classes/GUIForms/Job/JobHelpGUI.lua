-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/JobHelpGUI.lua
-- *  PURPOSE:     Job GUI class
-- *
-- ****************************************************************************
JobHelpGUI = inherit(GUIForm)
inherit(Singleton, JobHelpGUI)

function JobHelpGUI:constructor()
	GUIForm.constructor(self, screenWidth/2-300, screenHeight/2-230, 600, 460, true, false, Vector3(2750.27, -2374.66, 819.24))

	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, "Job Info", true, true, self)
	self.m_InfoLabel = GUILabel:new(5, 35, self.m_Width-10, 20, _"Doppelklicke um die Position auf der Karte zu markieren!", self):setColor(Color.Red)
	self.m_InfoLabel:setFont(VRPFont(24))

	self.m_JobList = GUIGridList:new(5, 60, self.m_Width-10, self.m_Height-60, self)
	self.m_JobList:addColumn(_"Jobs", 0.5)
	self.m_JobList:addColumn(_"Min. Job-Level", 0.25)
	self.m_JobList:addColumn(_"Multiplikator", 0.25)

	local pos
	for index, job in pairs(JobManager:getSingleton().m_Jobs) do
		local mult = job.m_Multiplicator and ("+"..job.m_Multiplicator.."%") or " - "
		if job.m_Name == "Boxer" or job.m_Name == "Schatzsucher" then mult = " - " end
		item = self.m_JobList:addItem(job.m_Name, job.m_Level, mult)
		item.onLeftDoubleClick = function () self:showJob(job.m_Ped:getPosition()) end
	end
end

function JobHelpGUI:showJob(pedPos)
	if self.m_JobList:getSelectedItem() and pedPos then
		local item = self.m_JobList:getSelectedItem()
		local blipPos = Vector2(pedPos.x, pedPos.y)
		ShortMessage:new(_"Klicke, um die Navigation zum Job zu starten.", "Job", false, -1, function()
			GPS:getSingleton():startNavigationTo(pedPos)
		end, false, blipPos, {{path = "Marker.png", pos = blipPos}})
	end
end