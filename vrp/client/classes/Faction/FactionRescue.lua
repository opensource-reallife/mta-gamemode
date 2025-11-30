-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Faction/FactionRescue.lua
-- *  PURPOSE:     Faction Rescue Class
-- *
-- ****************************************************************************
FactionRescue = inherit(Singleton)

addRemoteEvents{
	"rescueLadderUpdateCollision", "rescueLadderFixCamera"
}

function FactionRescue:constructor()
end

function FactionRescue:getOnlinePlayers(afkCheck, dutyCheck)
	local players = {}
	for _, player in pairs(getElementsByType("player")) do
		if player and isElement(player) and not player:getName():find("Gast_") then
			if (not afkCheck or not player:getPublicSync("AFK")) and (not dutyCheck or player:getPublicSync("Faction:Duty")) and (player:getFactionId() == 4) then
				players[#players + 1] = player
			end
		end
	end
	return players
end

function FactionRescue:sendSound(text, withOffDuty, tts, ...)
	for k, player in pairs(self:getOnlinePlayers(false, not withOffDuty)) do
		if player == localPlayer then -- Only play for local player
			if tts then
				local lang
				if player:getLocale() == "de" then
					lang = "de-De"
				else
					lang = "en-Us"
				end
				playSound(("http://translate.google.com/translate_tts?ie=UTF-8&tl=%s&q=%s&client=tw-ob"):format(lang, _(text, ...)))
			else
				playSound(text)
			end
		end
	end
end

addEventHandler("rescueLadderUpdateCollision", root, function(enable)
	if source:getType() == "vehicle" and source:getModel() == 544 then
		local source = source
		local enable = enable
		local removeCollisions
		removeCollisions = function(ele)
			for i, e in pairs(ele:getAttachedElements()) do
				if e:getType() == "object" then
					setElementCollisionsEnabled(e, enable == nil and false or enable)
					e:setCollidableWith(source, false)
					removeCollisions(e)
				end
			end
		end
		removeCollisions(source)
	end
end)


addEventHandler("rescueLadderFixCamera", root, function(ladder1, ladder3)
	if ladder1 then
		local mult = math.clamp(1, getDistanceBetweenPoints3D(ladder1.matrix.position, ladder3.matrix.position), 30)
		local pos1 = ladder1.matrix.position - ladder1.matrix.right*mult + ladder1.matrix.up*mult
		local pos2 = ladder3.matrix.position - ladder3.matrix.forward*4
		setCameraMatrix(pos1, pos2, 0, 180)
	else
		nextframe(function()
			setCameraTarget(localPlayer)
		end)
	end
end)