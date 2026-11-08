-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Inventory/ItemFirework.lua
-- *  PURPOSE:     Firework items Class
-- *
-- ****************************************************************************
ItemFirework = inherit(Item)

ItemFirework.Cooldown = { -- in Seconds
	[87] = 20,
	[85] = 20,
	[83] = 1,
	[86] = 5,
	[84] = 5,
	[88] = 5,
}

function ItemFirework:constructor()
end

function ItemFirework:destructor()
end

function ItemFirework:use(player, itemId, bag, place, itemName)
	if not FIREWORK_ENABLED then
		player:sendError(_("Das Feuerwerk ist zurzeit deaktiviert!", player))
		return
	end

	if player.vehicle then
		player:sendError(_("Du kannst kein Feuerwerk in einem Fahrzeug zünden!", player))
		return
	end

	if player:getInterior() == 0 and player:getDimension() == 0 then
		local fireworkId = self:getId()
		if ItemFirework.Cooldown[fireworkId] then
			if not player.fireworkCooldown then player.fireworkCooldown = {} end
			if player.fireworkCooldown[fireworkId] then
				if not timestampCoolDown(player.fireworkCooldown[fireworkId], ItemFirework.Cooldown[fireworkId]) then
					player:sendError(_("Du kannst die %s nicht so knapp hintereinander nutzen!", player, itemName))
					return
				end
			end
			player.fireworkCooldown[fireworkId] = getRealTime().timestamp
		end

		local rnd = 0

		if fireworkId == 85 then rnd = math.random(5, 8)
		elseif fireworkId == 86 then rnd = math.random(10, 15)
		elseif fireworkId == 87 then rnd = math.random(7, 12)
		end
		player:meChat(true, "zündet eine/n %s!", itemName, true)

		triggerClientEvent(root, "onClientFireworkStart", player, fireworkId, serialiseVector(player:getPosition()), rnd)
		player:getInventory():removeItem(fireworkId, 1)
	else
		player:sendError(_("Du kannst kein Feuerwerk in einem Interior zünden!", player))
	end
end
