-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Inventory/ItemDrugs.lua
-- *  PURPOSE:     Drugs Super class
-- *
-- ****************************************************************************
ItemDrugs = inherit(Item)
ItemDrugs.Texts = {
	[1] = "raucht Weed!",
	[13] = "isst einen Magic Mushroom!",
	[23] = "spritzt sich Heroin!",
	[24] = "schnupft Kokain!",

}

function ItemDrugs:constructor()

end

function ItemDrugs:destructor()

end

function ItemDrugs:use( player )
	player:meChat(true, ItemDrugs.Texts[self:getId()])

	player:giveAchievement(73)
end
