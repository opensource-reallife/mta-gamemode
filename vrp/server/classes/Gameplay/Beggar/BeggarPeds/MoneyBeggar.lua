MoneyBeggar = inherit(BeggarPed)

function MoneyBeggar:constructor()
end

function MoneyBeggar:giveBeggarMoney(player, money)
	if self.m_Despawning then return end
	if not player.vehicle then
		if self.m_Robber == player:getId() then return self:sendMessage(player, BeggarPhraseTypes.NoTrust) end
		if player:getMoney() >= money then
			-- give wage
			player:giveCombinedReward(_("Bettler-Geschenk", player), {
				money = {
					mode = "take",
					bank = false,
					amount = money,
					toOrFrom = self.m_BankAccountServer,
					category = "Gameplay",
					subcategory = "Beggar"
				},
				points = 1,
			})
			if money == 1 then
				player:meChat(true, "übergibt %s einen Schein!", self.m_Name, false)
			else
				player:meChat(true, "übergibt %s ein paar Scheine!", self.m_Name, false)
			end
			self:sendMessage(player, BeggarPhraseTypes.Thanks)

			-- give Achievement
			player:giveAchievement(56)
			if self.m_Name == BeggarNames[19] then
				player:giveAchievement(80)
			elseif self.m_Name == BeggarNames[32] then
				player:giveAchievement(81)
			end

			-- Despawn the Beggar
			setTimer(
				function ()
					self:despawn()
				end, 50, 1
			)
		else
			player:sendError(_("Du hast nicht soviel Geld dabei!", player))
		end
	else
		self:sendMessage(player, BeggarPhraseTypes.InVehicle)
	end
end
