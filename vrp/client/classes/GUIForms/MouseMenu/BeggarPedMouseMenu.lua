-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/MouseMenu/PlayerMouseMenu.lua
-- *  PURPOSE:     Player mouse menu class
-- *
-- ****************************************************************************
BeggarPedMouseMenu = inherit(GUIMouseMenu)

function BeggarPedMouseMenu:constructor(posX, posY, element)
	GUIMouseMenu.constructor(self, posX, posY, 300, 1) -- height doesn't matter as it will be set automatically

	local string = 
	self:addItem(_("%s (Obdachloser)", element:getData("BeggarName"))):setTextColor(Color.Orange)

	if element:getData("BeggarType") == BeggarTypes.Money then
		self:addItem(_"Geld geben",
			function ()
				SendMoneyGUI:new(
					function (amount)
						triggerServerEvent("giveBeggarPedMoney", self:getElement(), amount)
					end
				)
			end
		)
	elseif element:getData("BeggarType") == BeggarTypes.Food then
		self:addItem(_"Burger geben",
			function ()
				triggerServerEvent("giveBeggarItem", self:getElement(), "Burger")
			end
		)
	elseif element:getData("BeggarType") == BeggarTypes.Heroin then


		self:addItem(_"5g Heroin kaufen",
			function ()
				QuestionBox:new(
					_("Möchtest du 5g Heroin für 150$ kaufen?"),
					function ()
						triggerServerEvent("buyBeggarItem", self:getElement(), "Heroin")
					end,
					nil,
					element
				)
			end
		)
	elseif element:getData("BeggarType") == BeggarTypes.Weed then

		self:addItem(_"Weed verkaufen",
			function ()
				InputBox:new(_"Weed verkaufen", _"Wieviel Weed möchtest du verkaufen?",
					function (amount)
						if tonumber(amount) and tonumber(amount) > 0 and tonumber(amount) <= 200 then
							triggerServerEvent("sellBeggarWeed", self:getElement(), tonumber(amount))
						else
							outputChatBox(("#FE8A00%s: #FFFFFF%s"):format(element:getData("BeggarName"), _"Mehr als 200g Weed kann ich mir nicht leisten!"), 0,0,0, true)
						end
					end, true)
			end
		)
	elseif element:getData("BeggarType") == BeggarTypes.Transport then
		self:addItem(_"Obdachlosen transportieren",
			function ()
				triggerServerEvent("acceptTransport", self:getElement())
			end
		)
	end

	self:addItem(_"Ausrauben",
		function ()
			triggerServerEvent("robBeggarPed", self:getElement())
		end
	)
	self:adjustWidth()
end
