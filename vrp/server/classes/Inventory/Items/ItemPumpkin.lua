-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Inventory/ItemPumpkin.lua
-- *  PURPOSE:     Pumpkin class
-- *
-- ****************************************************************************
ItemPumpkin = inherit(Item)

function ItemPumpkin:constructor()

    self.m_Model = 1935
	self.m_Pumpkins = {}
end

function ItemPumpkin:destructor()

end

function ItemPumpkin:use(player)
	local inventory = player:getInventory()
	if inventory:getItemAmount("Kürbishut") > 0 then
		player:sendError(_("Du hast bereits einen Kürbishut!", player))
		return false
	end
	if not inventory:giveItemFromName("Kürbishut", 1, false, true) then
		return false
	end
	inventory:removeItem("Kürbis", 1)
	local tabName = InventoryManager:getSingleton():getItemTabName("Kürbishut")
	player:sendInfo(_("Du hast aus einem Kürbis einen Kürbishut gemacht! Du findest ihn unter %s.", player, _(tabName, player)))
end

function ItemPumpkin:addObject(Id, pos, rot, interior, dimension)
    self.m_Pumpkins[Id] = createObject(self.m_Model, pos, rot)
    self.m_Pumpkins[Id]:setInterior(interior)
    self.m_Pumpkins[Id]:setDimension(dimension)
	self.m_Pumpkins[Id].Id = Id
	self.m_Pumpkins[Id].Type = "Pumpkin"
    self.m_Pumpkins[Id]:setData("clickable", true, true)
    addEventHandler("onElementClicked",self.m_Pumpkins[Id], bind(self.onPumpkinClick, self))
	return self.m_Pumpkins[Id]
end

function ItemPumpkin:onPumpkinClick(button, state, player)
    if source.Type ~= "Pumpkin" then return end
	if button == "left" and state == "down" then
        if source:getModel() == self.m_Model then
            if player:getInventory():getFreePlacesForItem("Kürbis") >= 1 then
                source:destroy()
                player:getInventory():giveItem(27, 1)
                player:sendInfo(_("Du hast einen Kürbis gesammelt!", player))

				player:giveAchievement(109) -- Finde deinen ersten Kürbis

				if player:getInventory():getItemAmount("Kürbis") >= 50 then
					player:giveAchievement(110) -- Kürbissammler
				end
            else
                player:sendError(_("Du kannst nicht soviele Kürbisse tragen! Maximal %d Stk.!", player, player:getInventory():getMaxItemAmount("Kürbis")))
            end
        end
    end
end
