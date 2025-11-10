-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Gameplay/Shops/GasStationShop.lua
-- *  PURPOSE:     Gas Station Shop class
-- *
-- ****************************************************************************
GasStationShop = inherit(Shop)

function GasStationShop:constructor(id, name, position, rotation, typeData, dimension, robable, money, lastRob, owner, price, ownerType, stock, lastRestock)
	self:create(id, name, position, rotation, typeData, dimension, robable, money, lastRob, owner, price, ownerType, stock, lastRestock)

	self.m_Type = "GasStationShop"
	self.m_Items = SHOP_ITEMS[typeData["Name"]]

	if self.m_Ped then
		self.m_Ped:setData("clickable",true,true)
		addEventHandler("onElementClicked", self.m_Ped, function(button, state, player)
			if button =="left" and state == "down" then
				self:onGasStationMarkerHit(player, true)
			end
		end)
	end
end
