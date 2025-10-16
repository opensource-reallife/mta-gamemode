-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/Race/RaceLobbyGUI.lua
-- *  PURPOSE:     RaceMatchGUI class
-- *
-- ****************************************************************************

addRemoteEvents{"raceOpenMatchGUI", "raceRefreshMatchGUI", "raceCloseMatchGUI"}

RaceMatchGUI = inherit(GUIForm)
inherit(Singleton, RaceMatchGUI)

function RaceMatchGUI:constructor()
	GUIWindow.updateGrid()			
	self.m_Width = grid("x", 8)
	self.m_Height = grid("y", 8)

    GUIForm.constructor(self, screenWidth*0.98-self.m_Width, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, false)
    self.m_MatchWindow = GUIWindow:new(0, 0, self.m_Width, self.m_Height, "Destruction Derby", true, false, self)
    
    self.m_MatchGridList = GUIGridGridList:new(1, 1, 7, 6, self.m_MatchWindow)
    self.m_MatchGridList:addColumn(_"Spieler:", 0.5)
    self.m_MatchGridList:addColumn(_"Platz:", 0.5)

    self.m_LeaveButton = GUIGridButton:new(1, 7, 7, 1, _"Lobby verlassen", self.m_MatchWindow)
    self.m_LeaveButton.onLeftClick = function()
		triggerServerEvent("raceLeaveLobby", localPlayer)
	end

    self.m_DestroyFunc = bind(self.Event_onElementDestroy, self)
end

function RaceMatchGUI:Event_onElementDestroy()
    setCameraMatrix(2828, -1867, 51, 2797.49, -1831, 30)
end

function RaceMatchGUI:refresh(playerTable, scoreTable)
    self.m_MatchGridList:clear()
    for i, player in ipairs(playerTable) do
        if isElement(player) then
            local item = self.m_MatchGridList:addItem(player:getName(), scoreTable[player] or "-")
            item.onLeftClick = function() self:spectPlayer(player) end
        end
    end
end

function RaceMatchGUI:spectPlayer(player)
    if isElement(self.m_Vehicle) then
        removeEventHandler("onClientElementDestroy", self.m_Vehicle, self.m_DestroyFunc)
    end

    local vehicle = player:getOccupiedVehicle()
    if vehicle and not localPlayer:getOccupiedVehicle() then
        setCameraTarget(vehicle)
        addEventHandler("onClientElementDestroy", vehicle, self.m_DestroyFunc)
    end

    self.m_Vehicle = vehicle
end

function RaceMatchGUI:virtual_destructor()
    if isElement(self.m_Vehicle) then
        removeEventHandler("onClientElementDestroy", self.m_Vehicle, self.m_DestroyFunc)
    end
end

addEventHandler("raceOpenMatchGUI", root, function(playerTable)
	RaceMatchGUI:new(playerTable)
end)

addEventHandler("raceRefreshMatchGUI", root, function(playerTable, scoreTable)
	RaceMatchGUI:getSingleton():refresh(playerTable, scoreTable)
end)

addEventHandler("raceCloseMatchGUI", root, function()
	delete(RaceMatchGUI:getSingleton())
end)