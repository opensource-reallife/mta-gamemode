-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/RaceLobbyGUI.lua
-- *  PURPOSE:     Race Lobby GUI
-- *
-- ****************************************************************************

addRemoteEvents{"raceOpenLobbyGUI"}

RaceLobbyGUI = inherit(GUIForm)
inherit(Singleton, RaceLobbyGUI)

function RaceLobbyGUI:constructor(marker, lobbyTable, mapTable)
	GUIWindow.updateGrid()
	self.m_Width = grid("x", 16)
	self.m_Height = grid("y", 12)
	GUIForm.constructor(self, screenWidth/2-300, screenHeight/2-230, self.m_Width, self.m_Height, true, false, marker)

	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Race Lobbys", true, true, self)
	GUIGridLabel:new(1, 1, 16, 1, "Warnung: Alle deine Waffen werden beim betreten einer Lobby gelöscht!", self.m_Window):setColor(Color.Red)

	self.m_LobbyGrid = GUIGridGridList:new(1, 2, 15, 8, self.m_Window)
	self.m_LobbyGrid:addColumn(_"Name", 0.3)
	self.m_LobbyGrid:addColumn(_"Karte", 0.3)
	self.m_LobbyGrid:addColumn(_"Spieler", 0.2)
	self.m_LobbyGrid:addColumn(_"Passwort", 0.2)
	self.m_LobbyGrid:setSortable(true)
	self.m_LobbyGrid:setSortColumn(_"Name")

	self.m_CreateLobbyButton = GUIGridButton:new(12, 11, 4, 1, _"Lobby erstellen", self.m_Window):setBackgroundColor(Color.LightBlue):setBarEnabled(true)
	self.m_CreateLobbyButton.onLeftClick = function()
		RaceCreateLobbyGUI:new(marker, mapTable)
		delete(self)
	end

	self.m_JoinButton = GUIGridButton:new(12, 10, 4, 1, _"Lobby betreten", self.m_Window):setBackgroundColor(Color.Green):setBarEnabled(true)
	self.m_JoinButton.onLeftClick = bind(self.joinLobby, self)

	GUIGridRectangle:new(1, 10, 10, 1, Color.Grey, self.m_Window)
	GUIGridIconButton:new(1, 10, FontAwesomeSymbols.Book, self.m_Window)
	self.m_MapLabel = GUIGridLabel:new(1, 10, 10, 1, "Keine Lobby ausgewählt", self.m_Window):setAlignX("center")

	GUIGridRectangle:new(1, 11, 10, 1, Color.Grey, self.m_Window)
	GUIGridIconButton:new(1, 11, FontAwesomeSymbols.Player, self.m_Window)
	self.m_AuthorLabel = GUIGridLabel:new(1, 11, 10, 1, "Keine Lobby ausgewählt", self.m_Window):setAlignX("center")

	for id, lobby in pairs(lobbyTable) do
		local lobbyName, lobbyMap = lobby.Name, lobby.Map
		if #lobbyName > 16 then lobbyName = string.sub(lobbyName, 1, 13) .. "..." end
		if #lobbyMap > 16 then lobbyMap = string.sub(lobbyMap, 1, 13) .. "..." end

		local item = self.m_LobbyGrid:addItem(lobbyName, lobbyMap, ("%d / %d"):format(lobby.Players, lobby.MaxPlayers), lobby.Password and _"Ja" or _"Nein")
		item.Owner = lobby.Owner
		item.Password = lobby.Password
		item.onLeftClick = function()
			self.m_MapLabel:setText(_("Karte: %s", lobby.Map))
			self.m_AuthorLabel:setText(_("Ersteller: %s", lobby.MapAuthor))
		end
	end
end

function RaceLobbyGUI:joinLobby()
	local selectedItem = self.m_LobbyGrid:getSelectedItem()
	if selectedItem then
		if selectedItem.Password then
			InputBox:new(_"Passwort eingeben", _"Diese Lobby ist Passwortgeschützt! Gib das Passwort ein:",
				function(password) triggerServerEvent("raceJoinLobby", localPlayer, selectedItem.Owner, password) end
			)
		else
			triggerServerEvent("raceJoinLobby", localPlayer, selectedItem.Owner)
		end
		delete(self)
	else
		ErrorBox:new(_"Es ist keine Lobby ausgewählt!")
	end
end

addEventHandler("raceOpenLobbyGUI", root, function(marker, lobbyTable, mapTable)
	RaceLobbyGUI:new(marker, lobbyTable, mapTable)
end)