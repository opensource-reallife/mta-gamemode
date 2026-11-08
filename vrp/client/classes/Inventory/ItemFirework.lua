addEvent("onClientFireworkStart", true)
addEventHandler("onClientFireworkStart", root, function(firework, position, rnd)
	if isElementStreamedIn(source) then
		if source ~= localPlayer and not core:get("Sounds", "Fireworks", true) then
			if not localPlayer.fireWorkMessageCooldown or timestampCoolDown(localPlayer.fireWorkMessageCooldown, 20) then
				ShortMessage:new("In deiner Nähe wurde ein Feuerwerk abgefeuert! Aktiviere diese in den Einstellungen um sie zu sehen!")
				localPlayer.fireWorkMessageCooldown = getRealTime().timestamp
			end
			return
		end
		local pos   = normaliseVector(position);
		if firework == 83 then
			ItemFireworkRocket:new(pos)
		elseif firework == 84 then
			ItemPipeBomb:new(pos);
		elseif firework == 85 then
			ItemFireworkBattery:new(pos, rnd);
		elseif firework == 86 then
			ItemFireworkRomanCandle:new(pos, rnd);
		elseif firework == 87 then
			ItemFireworkRomanCandleBattery:new(pos, rnd);
		elseif firework == 88 then
			ItemFireworkGroundShell:new(pos)
		elseif firework == 89 then
			ItemFireworkBanger:new(pos)
		end
	end
end)


