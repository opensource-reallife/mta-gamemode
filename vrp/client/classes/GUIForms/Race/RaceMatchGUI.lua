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
    GUIForm.constructor(self, screenWidth*0.8, screenHeight - screenHeight*0.62, screenWidth*0.4, screenHeight*0.5, false)
    self.m_MatchWindow = GUIWindow:new(0, 0, 300, 300, "Race", true, false, self)
    
    self.m_MatchGridList = GUIGridList:new(self.m_PosX*0.004, self.m_PosY*0.1, 290, 220, self.m_MatchWindow)
    self.m_MatchGridList:addColumn(_"Spieler:", 0.5)
    self.m_MatchGridList:addColumn(_"Platz:", 0.5)

    self.m_LeaveButton = GUIButton:new(self.m_PosX*0, self.m_PosY*0.68, 300, 30, _"Lobby verlassen", self.m_MatchWindow)
    self.m_LeaveButton.onLeftClick = function()
		triggerServerEvent("raceLeaveLobby", localPlayer)
	end
end

function RaceMatchGUI:refresh(playerTable, scoreTable)
    self.m_MatchGridList:clear()
    for i, player in ipairs(playerTable) do
        local item = self.m_MatchGridList:addItem(player:getName(), scoreTable[player] or "-")
        item.onLeftClick = function() self:spectPlayer(player) end
    end
end

function RaceMatchGUI:spectPlayer(player)
    local vehicle = player:getOccupiedVehicle()
    if vehicle and not localPlayer:getOccupiedVehicle() then
        setCameraTarget(vehicle)
        addEventHandler("onClientElementDestroy", vehicle, function()
            setCameraMatrix(2828, -1867, 51, 2797.49, -1831, 30)
        end)
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