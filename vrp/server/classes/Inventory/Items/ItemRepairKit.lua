-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Inventory/ItemRepairKit.lua
-- *  PURPOSE:     Repair Kit item class
-- *
-- ****************************************************************************
ItemRepairKit = inherit(Item)

function ItemRepairKit:constructor()
end

function ItemRepairKit:destructor()
end

function ItemRepairKit:use(player)
	if player.vehicle then
		if player.vehicle:getHealth() <= 310 then
			player:meChat(true, "steigt aus und legt einige Kabel an den Motor an!")
			setElementHealth(player.vehicle, 500)
			player.vehicle:setBroken(false)
			player:sendSuccess(_("Dein Fahrzeug funktioniert wieder einigermaßen!", player))
			player:getInventory():removeItem(self:getName(), 1)
		else
			player:sendError(_("Dein Fahrzeug ist nicht kaputt!", player))
		end
	else
		player:sendError(_("Du musst in einem Fahrzeug sitzen!", player))
	end
end
