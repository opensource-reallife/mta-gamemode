-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Gameplay/Places/FurnitureShop.lua
-- *  PURPOSE:     Furniture shops singleton class
-- *
-- ****************************************************************************

FurnitureShop = inherit(Singleton)

function FurnitureShop:constructor()
	local blip = Blip:new("FurnitureShop.png", -553.23, 2593.86, root, 600)
	blip:setDisplayText("Einrichtungsgeschäft", BLIP_CATEGORY.Shop)
	self.m_BankAccountServer = BankServer.get("shop.furniture")
	addEvent("furnitureBuy", true)
	addEventHandler("furnitureBuy", root, bind(self.Event_furnitureBuy, self))
end

function FurnitureShop:Event_furnitureBuy(model)
	if source ~= client then return end
	if not FurnitureInfo[model] then return end
	local name, price = unpack(FurnitureInfo[model])
	if client:getMoney() >= price then
		if client:getInventory():giveItem("Einrichtung", 1, model) then
			client:triggerEvent("furnitureBought")
			client:transferMoney(self.m_BankAccountServer, price, "Einrichtungs-Kauf", "Gameplay", "Furniture")
		end
	else
		client:sendError(_("Du hast nicht genügend Geld!", client))
	end
end