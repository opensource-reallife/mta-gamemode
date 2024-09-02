-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/RaceCreateLobby.lua
-- *  PURPOSE:     Race Create Lobby GUI
-- *
-- ****************************************************************************
RaceCreateLobbyGUI = inherit(GUIForm)
inherit(Singleton, RaceCreateLobbyGUI)

function RaceCreateLobbyGUI:constructor(marker, mapTable)
	GUIWindow.updateGrid()
	self.m_Width = grid("x", 14)
	self.m_Height = grid("y", 6) 
	GUIForm.constructor(self, screenWidth/2-270, screenHeight/2-200, self.m_Width, self.m_Height, true, false, marker)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Lobby erstellen", true, true, self)

	GUIGridLabel:new(1, 1, 16, 1, "Warnung: Deine eigene Lobby wird gelöscht, sobald du sie verlässt!", self.m_Window):setColor(Color.Red)

	GUIGridLabel:new(1, 2, 11, 1, "Karte:", self.m_Window)
	self.m_MapChanger = GUIGridChanger:new(4, 2, 10, 1, self.m_Window)

	GUIGridLabel:new(1, 3, 11, 1, "Spieler:", self.m_Window)
	self.m_MaxPlayerChanger = GUIGridChanger:new(4, 3, 10, 1, self.m_Window)
	for i = 2, 15 do self.m_MaxPlayerChanger:addItem(i) end

	GUIGridLabel:new(1, 4, 11, 1, "Passwort:", self.m_Window)
	self.m_Password = GUIGridEdit:new(4, 4, 10, 1, self.m_Window):setMaxLength(20)

	self.m_CreateLobby = GUIGridButton:new(1, 5, 13, 1, _"Lobby erstellen (500$)", self.m_Window):setBackgroundColor(Color.Green):setBarEnabled(true)
	self.m_CreateLobby.onLeftClick = bind(self.createLobby, self)

	self.m_MapChangerMapping = {}
	for mapId, mapName in pairs(mapTable) do
		local item = self.m_MapChanger:addItem(mapName)
		self.m_MapChangerMapping[item] = mapId
	end
end

function RaceCreateLobbyGUI:createLobby()
	local password = self.m_Password:getText()
	if password == "" then password = false end

	local maxPlayers = self.m_MaxPlayerChanger:getSelectedItem()

	local _, changerItemId = self.m_MapChanger:getSelectedItem()
	local mapFileName = self.m_MapChangerMapping[changerItemId]

	triggerServerEvent("raceCreateLobby", localPlayer, password, maxPlayers, mapFileName)
	delete(self)
end