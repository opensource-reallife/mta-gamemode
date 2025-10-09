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
	self.ms_GUISizeX = 32
	self.ms_GUISizeY = 17

	GUIWindow.updateGrid()
	self.m_Width = grid("x", self.ms_GUISizeX) 
	self.m_Height = grid("y", self.ms_GUISizeY)

	self.m_Changes = {}
	self.m_PermissionsType = permissionsType
	self.m_Type = type


	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Berechtigungen verwalten", true, true, self)
	
	self.m_PermissionScrollArea = GUIGridScrollableArea:new(1, 3, self.ms_GUISizeX - 1,  13, 1, 90, true, false, self.m_Window, 3)
	self.m_PermissionScrollArea:updateGrid()
	
	self.m_PermissionLabel = {}
	self.m_PermissionRectangle = {}
	
	self.m_SaveButton = GUIGridButton:new(28, 17, 4, 1, _"Speichern", self.m_Window)
	self.m_SaveButton.onLeftClick = bind(self.saveButton_Click, self)

	addEventHandler("showRankPermissionsList", localPlayer, bind(self.updateList, self))

	triggerServerEvent("requestRankPermissionsList", localPlayer, permissionsType, type)
end

function RankPermissionsGUI:destructor()
	GUIForm.destructor(self)
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
		self.m_RankLabels[j] = GUIGridLabel:new(7 + ((j + 1) * 3), 2, 5, 2, _("Rang %s", j), self.m_Window)
		documentSizeY = documentSizeY + 1
	end
	
	local i = 0.5
	for permission, permissionName in pairs(self.m_Permissions) do
		self.m_PermissionRectangle[permission] = GUIGridRectangle:new(1, (i * 1.5 - 1), self.ms_GUISizeX - 1, 1.5, tocolor(0, 0, 0, 180), self.m_PermissionScrollArea)

		for j = 0, type ~= "company" and 6 or 5, 1 do
			local checkbox = GUIGridCheckbox:new(7 + ((j + 1) * 3), 1.1, 1, 1.2, "", self.m_PermissionRectangle[permission]):setChecked(self.m_RankPermissions[tostring(j)] and self.m_RankPermissions[tostring(j)][permission])
			if (tonumber(j) < tonumber(permInfo[permission][2][self.m_Type])) then
				checkbox:setEnabled(false)
				checkbox:setAlpha(0)
			end
			checkbox.permission = permission
			checkbox.rank = j
			checkbox.onChange = function(state) self:onCheckBoxChange(j, permission, state) end
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