PaymentChoiceGUI = inherit(GUIForm)
inherit(Singleton, PaymentChoiceGUI)

addRemoteEvents{"paymentChoiceOpen", "paymentChoiceClose"}

function PaymentChoiceGUI:constructor(id, title, amount, fee, feePercent, cash, bank, isPremium, rangeElement, range)
	GUIForm.constructor(self, screenWidth/2 - screenWidth*0.3/2, screenHeight/2 - screenHeight*0.26/2, screenWidth*0.3, screenHeight*0.26, true, false, rangeElement, range)

	self.m_PaymentId = id
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Zahlungsart wählen", true, true, self)

	local total = amount + fee
	local feeText = isPremium and _"VIP: keine Kartengebühr" or _("Mit Karte %d%% Gebühr (%s)", feePercent, toMoneyString(fee))

	GUILabel:new(self.m_Width*0.03, self.m_Height*0.17, self.m_Width*0.94, self.m_Height*0.13, title, self.m_Window):setAlignX("center")
	GUILabel:new(self.m_Width*0.03, self.m_Height*0.31, self.m_Width*0.94, self.m_Height*0.1, feeText, self.m_Window):setAlignX("center"):setColor(isPremium and Color.Green or Color.LightGrey)
	GUILabel:new(self.m_Width*0.03, self.m_Height*0.43, self.m_Width*0.94, self.m_Height*0.1, _("Bargeld: %s · Konto: %s", toMoneyString(cash), toMoneyString(bank)), self.m_Window):setAlignX("center"):setColor(Color.LightGrey)

	self.m_CashButton = GUIButton:new(self.m_Width*0.05, self.m_Height*0.62, self.m_Width*0.43, self.m_Height*0.28, _("Bar: %s", toMoneyString(amount)), self.m_Window):setBackgroundColor(Color.Green)
	self.m_CardButton = GUIButton:new(self.m_Width*0.52, self.m_Height*0.62, self.m_Width*0.43, self.m_Height*0.28, _("Karte: %s", toMoneyString(total)), self.m_Window):setBackgroundColor(Color.Accent)

	self.m_CashButton:setEnabled(cash >= amount)
	self.m_CardButton:setEnabled(bank >= total)
	self.m_CashButton.onLeftClick = function() self:select("cash") end
	self.m_CardButton.onLeftClick = function() self:select("card") end
end

function PaymentChoiceGUI:destructor()
	if not self.m_Answered then
		triggerServerEvent("paymentChoiceCancel", localPlayer, self.m_PaymentId)
	end
	GUIForm.destructor(self)
end

function PaymentChoiceGUI:select(method)
	self.m_Answered = true
	triggerServerEvent("paymentChoiceSelect", localPlayer, self.m_PaymentId, method)
	delete(self)
end

addEventHandler("paymentChoiceOpen", root,
	function(...)
		if PaymentChoiceGUI:isInstantiated() then
			local gui = PaymentChoiceGUI:getSingleton()
			gui.m_Answered = true
			delete(gui)
		end
		PaymentChoiceGUI:new(...)
	end
)

addEventHandler("paymentChoiceClose", root,
	function(id)
		if PaymentChoiceGUI:isInstantiated() and PaymentChoiceGUI:getSingleton().m_PaymentId == id then
			local gui = PaymentChoiceGUI:getSingleton()
			gui.m_Answered = true
			delete(gui)
		end
	end
)
