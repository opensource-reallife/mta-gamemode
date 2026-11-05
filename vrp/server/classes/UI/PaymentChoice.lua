PaymentChoice = inherit(Object)
PaymentChoice.Map = {}
PaymentChoice.ByPlayer = {}
PaymentChoice.Count = 0
PaymentChoice.CardFeePercent = 10
PaymentChoice.Timeout = 2*60*1000

addRemoteEvents{"paymentChoiceSelect", "paymentChoiceCancel"}

function PaymentChoice.getFee(player, amount)
	if player:isPremium() then
		return 0
	end
	return math.ceil(amount*PaymentChoice.CardFeePercent/100)
end

function PaymentChoice:constructor(player, amount, target, reason, category, subcategory, options)
	options = options or {}
	self.m_Amount = math.floor(tonumber(amount) or 0)
	if self.m_Amount <= 0 then
		error("PaymentChoice @ Invalid amount, Reason: " .. tostring(reason))
	end
	if not target then
		error("PaymentChoice @ Target is missing, Reason: " .. tostring(reason))
	end

	if PaymentChoice.ByPlayer[player] then
		delete(PaymentChoice.ByPlayer[player])
	end

	PaymentChoice.Count = PaymentChoice.Count + 1
	self.m_Id = PaymentChoice.Count
	self.m_Player = player
	self.m_Target = target
	self.m_Reason = reason
	self.m_Category = category
	self.m_Subcategory = subcategory
	self.m_Fee = PaymentChoice.getFee(player, self.m_Amount)
	self.m_OnPaid = options.onPaid
	self.m_OnCancel = options.onCancel
	self.m_RangeElement = options.rangeElement
	self.m_Range = options.range or 10

	PaymentChoice.Map[self.m_Id] = self
	PaymentChoice.ByPlayer[player] = self
	self.m_Timer = setTimer(function() self:cancel() end, PaymentChoice.Timeout, 1)

	player:triggerEvent("paymentChoiceOpen", self.m_Id, options.title or reason, self.m_Amount, self.m_Fee, PaymentChoice.CardFeePercent, player:getMoney(), player:getBankMoney(), player:isPremium(), self.m_RangeElement, self.m_Range)
end

function PaymentChoice:destructor()
	if self.m_Timer and isTimer(self.m_Timer) then
		killTimer(self.m_Timer)
	end
	PaymentChoice.Map[self.m_Id] = nil
	if PaymentChoice.ByPlayer[self.m_Player] == self then
		PaymentChoice.ByPlayer[self.m_Player] = nil
	end
	if isElement(self.m_Player) then
		self.m_Player:triggerEvent("paymentChoiceClose", self.m_Id)
	end
end

function PaymentChoice:cancel()
	local player, onCancel = self.m_Player, self.m_OnCancel
	delete(self)
	if onCancel and isElement(player) then
		onCancel(player)
	end
end

function PaymentChoice:isInRange()
	if not self.m_RangeElement then
		return true
	end
	local position = isElement(self.m_RangeElement) and self.m_RangeElement:getPosition() or self.m_RangeElement
	return (self.m_Player:getPosition() - position).length <= self.m_Range + 2
end

function PaymentChoice:pay(method)
	local player = self.m_Player
	if method ~= "cash" and method ~= "card" then
		return
	end
	if not self:isInRange() then
		player:sendError(_("Du bist zu weit entfernt!", player))
		return self:cancel()
	end

	local paid, fee = false, 0
	if method == "cash" then
		paid = player:transferMoney(self.m_Target, self.m_Amount, self.m_Reason, self.m_Category, self.m_Subcategory)
		if not paid then
			player:sendError(_("Du hast nicht genug Bargeld!", player))
		end
	else
		fee = self.m_Fee
		if player:getBankMoney() >= self.m_Amount + fee then
			paid = player:transferBankMoney(self.m_Target, self.m_Amount, self.m_Reason, self.m_Category, self.m_Subcategory)
			if paid and fee > 0 then
				player:transferBankMoney(BankServer.get("gameplay.cardfee"), fee, "Kartengebühr", self.m_Category, "CardFee")
			end
		end
		if not paid then
			player:sendError(_("Du hast nicht genug Geld auf dem Konto!", player))
		end
	end

	if not paid then
		return self:cancel()
	end

	local amount, onPaid = self.m_Amount, self.m_OnPaid
	delete(self)
	if onPaid then
		onPaid(player, method, amount + fee, fee)
	end
end

addEventHandler("paymentChoiceSelect", root,
	function(id, method)
		local choice = PaymentChoice.Map[id]
		if not choice then
			client:sendError(_("Die Anfrage ist abgelaufen!", client))
			return
		end
		if choice.m_Player == client then
			choice:pay(method)
		end
	end
)

addEventHandler("paymentChoiceCancel", root,
	function(id)
		local choice = PaymentChoice.Map[id]
		if choice and choice.m_Player == client then
			choice:cancel()
		end
	end
)

addEventHandler("onPlayerQuit", root,
	function()
		local choice = PaymentChoice.ByPlayer[source]
		if choice then
			delete(choice)
		end
	end
)
