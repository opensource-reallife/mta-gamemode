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
function RankPermissionsGUI:constructor(permissionsType, type, wpn)
	self.ms_GUISizeX = type == "company" and 21 or 23
	self.ms_GUISizeY = 14

	GUIWindow.updateGrid()
	self.m_Width = grid("x", self.ms_GUISizeX) 
	self.m_Height = grid("y", self.ms_GUISizeY)

	self.m_Changes = {}
	self.m_PermissionsType = permissionsType
	self.m_Type = type
	self.m_Closing = false

	self.m_ValidWeapons = wpn
	self.m_Weapons = {}

	if permissionsType == "weapon" then
		self:formatWeapons()
	end

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
	
	self.m_PermissionScrollArea = GUIGridScrollableArea:new(1, 2.5, self.ms_GUISizeX - 1, self.ms_GUISizeY - 3.5, 1, 50, true, false, self.m_Window, 2.5)
	self.m_PermissionScrollArea:updateGrid()
	
	self.m_PermissionLabel = {}
	self.m_PermissionRectangle = {}
	self.m_PermissionCheckbox = {}
	
	-- self.m_SaveButton = GUIGridButton:new(self.ms_GUISizeX - 4, self.ms_GUISizeY, 4, 1, _"Speichern", self.m_Window):setBackgroundColor(Color.Green)
	-- self.m_SaveButton.onLeftClick = bind(self.saveButton_Click, self)

	GUIGridRectangle:new(1.25, 2, self.ms_GUISizeX - 1, 1.5, Color.Background, self.m_Window)

	addEventHandler("showRankPermissionsList", localPlayer, bind(self.updateList, self))
	triggerServerEvent("requestRankPermissionsList", localPlayer, permissionsType, type, false, true)

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

function RankPermissionsGUI:formatWeapons()
	for i, state in pairs(self.m_ValidWeapons) do
		self.m_Weapons[i] = WEAPON_NAMES[i]
	end
end

function RankPermissionsGUI:updateList(rankTbl, type, refresh)
	self.m_RankPermissions = rankTbl
	self.m_Permissions = self.m_PermissionsType ~= "weapon" and PermissionsManager:getSingleton():getPermissions(self.m_PermissionsType, type) or self.m_Weapons
	local permInfo = (self.m_PermissionsType == "permission" and PERMISSIONS_INFO) or (self.m_PermissionsType == "action" and ACTION_PERMISSIONS_INFO)
	local highestRank = type ~= "company" and 6 or 5

	if (refresh) then
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
				if not self.m_PermissionCheckbox[rank] then
					self.m_PermissionCheckbox[rank] = {}
				end
				local requiredRank = self.m_PermissionsType ~= "weapon" and tonumber(permInfo[permission][2][self.m_Type]) or 0
				if rank and requiredRank and (rank >= requiredRank) then
					self.m_PermissionCheckbox[rank][permission] = GUIGridCheckbox:new(7 + ((j + 1) * 2), 1.1, 1, 1.2, "", self.m_PermissionRectangle[permission]):setChecked(rank == highestRank and true or (self.m_RankPermissions[tostring(j)] and toboolean(self.m_RankPermissions[tostring(j)][tostring(permission)])))
	
					self.m_PermissionCheckbox[rank][permission].permission = permission
					self.m_PermissionCheckbox[rank][permission].rank = j
					self.m_PermissionCheckbox[rank][permission].onChange = function(state) self:onCheckBoxChange(j, permission, state) end
				end
			end 
			
			self.m_PermissionLabel[permission] = GUIGridLabel:new(1.1, 1, 8, 1.5, _(permissionName), self.m_PermissionRectangle[permission])
			self.m_PermissionLabel[permission].name = permission
			i = i + 1
			documentSizeY = documentSizeY + 1.25
		end
		self.m_PermissionScrollArea:resize(17, documentSizeY - 1)
	else
		for rank, v in pairs(self.m_RankPermissions) do
			for perm, state in pairs(v) do
				if self.m_PermissionCheckbox[tonumber(rank)] and self.m_PermissionCheckbox[tonumber(rank)][tonumber(perm)] then
					self.m_PermissionCheckbox[tonumber(rank)][tonumber(perm)]:setChecked(tonumber(rank) == highestRank or toboolean(state))
				end
			end
		end
	end
end

function RankPermissionsGUI:saveButton_Click()
	triggerServerEvent("changeRankPermissions", localPlayer, self.m_PermissionsType, self.m_Changes, self.m_Type)
	self.m_Changes = {}
end

function RankPermissionsGUI:onCheckBoxChange(rank, perm, state)
	triggerServerEvent("changeRankPermission", localPlayer, self.m_PermissionsType, self.m_Type, rank, perm, state)
end