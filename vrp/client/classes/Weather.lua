-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Weather.lua
-- *  PURPOSE:     Weather managing class
-- *
-- ****************************************************************************
Weather = inherit(Singleton)

function Weather:constructor()
    addRemoteEvents({"receiveRainLevel"})
    addEventHandler("receiveRainLevel", resourceRoot, bind(self.setRainLevel, self))
    if core:get("Other", "RainHidden", false) then setRainLevel(0) end
end

function Weather:setRainLevel(rainLevel)
	if core:get("Other", "RainHidden", false) then
        setRainLevel(0)
    else
        setRainLevel(rainLevel)
    end
end