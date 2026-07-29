-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/WeatherStationGUI.lua
-- *  PURPOSE:     Weather Station GUI
-- *
-- ****************************************************************************

WeatherStationGUI = inherit(GUIForm)
inherit(Singleton, WeatherStationGUI)

function WeatherStationGUI:constructor(weatherStations)
	local columns = 1

	GUIWindow.updateGrid()
	self.m_Width = grid("x", columns * 8 + 1)
	self.m_Height = grid("y", math.round(table.size(weatherStations) / columns) * 3 + 1)
	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height)
	local window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Wetterstationen", true, true, self)

	local n, row  = 0, 0
	for k, weatherStation in pairs(weatherStations) do
		if not weatherStation.m_MainStation then
			n = n + 1
			local i = n - columns*row

			local image = weatherStation.m_Connected and "files/images/Other/antenna_c.png" or  "files/images/Other/antenna_nc.png"
			local stationBackground = GUIGridRectangle:new(1 + 8*(i-1), row*3 + 1, 8, 3, Color.LightGrey, window)
			local background = GUIRectangle:new(2, 2, stationBackground.m_Height - 4, stationBackground.m_Height - 4, weatherStation.m_Connected and Color.Green or Color.Grey, stationBackground)
			GUIImage:new(5, 5, background.m_Width - 10, background.m_Height - 10, image, background)

			GUIGridLabel:new(4 + 8*(i-1), row*3 + 1.4, 3, 1, _"Station:\nStatus:\nFrequenz:", window):setAlign("left", "top")
			GUIGridLabel:new(6 + 8*(i-1), row*3 + 1.4, 3, 1, ("%s\n%s\n%s MHz"):format(weatherStation.m_StationName, weatherStation.m_Connected and _"Verbunden" or _"Außer Betrieb", weatherStation.m_TargetFrequency), window):setAlign("left", "top")

			if i%columns == 0 then row = row + 1 end
		end
	end
end

addRemoteEvents({"onWeatherStationClicked"})
addEventHandler("onWeatherStationClicked", root, function(...)
	if not WeatherStationGUI:isInstantiated() then
		WeatherStationGUI:new(...)
	end
end)