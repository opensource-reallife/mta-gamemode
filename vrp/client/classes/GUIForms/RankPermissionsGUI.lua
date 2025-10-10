-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/RankPermissionsGUI.lua
-- *  PURPOSE:     RankPermissionsGUI class
-- *
-- ****************************************************************************

RankPermissionsGUI = inherit(GUIForm)
inherit(Singleton, RankPermissionsGUI)

addRemoteEvents{"showRankPermissionsList"}
function RankPermissionsGUI:constructor(permissionsType, type)
	self.ms_GUISizeX = type == "company" and 21 or 23
	self.ms_GUISizeY = 14

	GUIWindow.updateGrid()
	self.m_Width = grid("x", self.ms_GUISizeX) 
	self.m_Height = grid("y", self.ms_GUISizeY)

	self.m_Changes = {}
	self.m_PermissionsType = permissionsType
	self.m_Type = type
	self.m_Closing = false

	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Berechtigungen verwalten", true, true, self)
	self.m_Window:addBackButton(function()
		if type == "faction" then
			FactionGUI:getSingleton():show()
		end
		if type == "company" then
			CompanyGUI:getSingleton():show()
		end
		if type == "group" then
			GroupGUI:getSingleton():show()
		end
	end)
	
	self.m_PermissionScrollArea = GUIGridScrollableArea:new(1, 2.5, self.ms_GUISizeX - 1, self.ms_GUISizeY - 3.5, 1, 90, true, false, self.m_Window, 2.5)
	self.m_PermissionScrollArea:updateGrid()
	
	self.m_PermissionLabel = {}
	self.m_PermissionRectangle = {}
	
	self.m_SaveButton = GUIGridButton:new(self.ms_GUISizeX - 4, self.ms_GUISizeY, 4, 1, _"Speichern", self.m_Window):setBackgroundColor(Color.Green)
	self.m_SaveButton.onLeftClick = bind(self.saveButton_Click, self)

	GUIGridRectangle:new(1.25, 2, self.ms_GUISizeX - 1, 1.5, Color.Background, self.m_Window)

	addEventHandler("showRankPermissionsList", localPlayer, bind(self.updateList, self))
	triggerServerEvent("requestRankPermissionsList", localPlayer, permissionsType, type)

	SelfGUI:getSingleton():addWindow(self)
end

function RankPermissionsGUI:destructor()
	SelfGUI:getSingleton():removeWindow(self)
	GUIForm.destructor(self)
end

function RankPermissionsGUI:onHide()
	if not self.m_Closing then
		self.m_Closing = true
		delete(self)
	end
end

function RankPermissionsGUI:updateList(rankTbl, type)
	self.m_RankPermissions = rankTbl
	self.m_Permissions = PermissionsManager:getSingleton():getPermissions(self.m_PermissionsType, type)
	local permInfo = self.m_PermissionsType == "permission" and PERMISSIONS_INFO or ACTION_PERMISSIONS_INFO

	self.m_PermissionScrollArea:clear()
	self.m_PermissionRectangle = {}
	self.m_RankLabels = {}
	self.m_Changes = {}

	local documentSizeY = 0
	for j = 0, type ~= "company" and 6 or 5, 1 do
		self.m_RankLabels[j] = GUIGridLabel:new(7 + ((j + 1) * 2), 1.75, 5, 2, _("Rang %s", j), self.m_Window)
		documentSizeY = documentSizeY + 1
	end
	
	local i = 0.34
	for permission, permissionName in pairs(self.m_Permissions) do
		self.m_PermissionRectangle[permission] = GUIGridRectangle:new(1, (i * 1.5 - 1), self.ms_GUISizeX - 1, 1.5, Color.Background, self.m_PermissionScrollArea)

		for j = 0, type ~= "company" and 6 or 5, 1 do
			local rank = tonumber(j)
			local requiredRank = tonumber(permInfo[permission][2][self.m_Type])
			if rank and requiredRank and (rank >= requiredRank) then
				local checkbox = GUIGridCheckbox:new(7 + ((j + 1) * 2), 1.1, 1, 1.2, "", self.m_PermissionRectangle[permission]):setChecked(self.m_RankPermissions[tostring(j)] and self.m_RankPermissions[tostring(j)][permission])
				checkbox.permission = permission
				checkbox.rank = j
				checkbox.onChange = function(state) self:onCheckBoxChange(j, permission, state) end
			end
		end 
		
		self.m_PermissionLabel[permission] = GUIGridLabel:new(1.1, 1, 8, 1.5, _(permissionName), self.m_PermissionRectangle[permission])
		self.m_PermissionLabel[permission].name = permission
		i = i + 1
		documentSizeY = documentSizeY + 1
	end
	self.m_PermissionScrollArea:resize(17, documentSizeY - 1)
end

function RankPermissionsGUI:saveButton_Click()
	triggerServerEvent("changeRankPermissions", localPlayer, self.m_PermissionsType, self.m_Changes, self.m_Type)
	self.m_Changes = {}
end

function RankPermissionsGUI:onCheckBoxChange(rank, perm, state)
	if not self.m_Changes[rank] then
		self.m_Changes[rank] = {}
	end
	self.m_Changes[rank][perm] = state
end