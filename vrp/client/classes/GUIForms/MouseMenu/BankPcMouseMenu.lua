-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/MouseMenu/PlayerMouseMenu.lua
-- *  PURPOSE:     Player mouse menu class
-- *
-- ****************************************************************************
BankPcMouseMenu = inherit(GUIMouseMenu)

function BankPcMouseMenu:constructor(posX, posY, element)
	GUIMouseMenu.constructor(self, posX, posY, 300, 1) -- height doesn't matter as it will be set automatically

	self:addItem(_("Bank Computer")):setTextColor(Color.Orange)

	local itemText = "Tresortür öffnen"
	if localPlayer:getFaction():isStateFaction() then
		itemText = "Tresortür verriegeln"
	end

	self:addItem(itemText,
		function ()
			triggerServerEvent("bankRobberyPcHack", localPlayer, element)
		end
	)

	self:addItem("Alarm deaktivieren",
		function ()
			triggerServerEvent("bankRobberyPcDisarm", localPlayer)
		end
	)
end
