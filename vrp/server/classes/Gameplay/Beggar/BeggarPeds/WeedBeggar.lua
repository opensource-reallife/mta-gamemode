WeedBeggar = inherit(BeggarPed)

function WeedBeggar:constructor()

end

function WeedBeggar:sellWeed(player, amount)
	if self.m_Despawning then return end
	if not player.vehicle then
		if self.m_Robber == player:getId() then return self:sendMessage(player, BeggarPhraseTypes.NoTrust) end
		if player:getInventory():removeItem("Weed", amount) then
			player:giveCombinedReward("Bettler-Handel", {
				money = {
					mode = "give",
					bank = false,
					amount = amount*12,
					toOrFrom = self.m_BankAccountServer,
					category = "Gameplay",
					subcategory = "BeggarWeed"
				},
				points = math.ceil(20 * amount/200),
			})
			player:meChat(true, ("übergibt %s %s"):format(self.m_Name, amount > 100 and "eine große Tüte" or "eine Tüte"))
			self:sendMessage(player, BeggarPhraseTypes.Thanks)
			-- Despawn the Beggar
			setTimer(
				function ()
					self:despawn()
				end, 50, 1
			)
			-- Give Wanteds
			if chance(3) then
				setTimer(function()
					if player and isElement(player) then
						player:sendWarning(_("Deine illegalen Aktivitäten wurden von einem Augenzeugen an das SAPD gemeldet!", player))
						player:giveWanteds(2)
						player:sendMessage(_("Verbrechen begangen: %s, %d Wanted/s", player, _("Handel mit illegalen Gegenständen", player), 2), 255, 255, 0)
					end
				end, math.random(2000, 10000), 1)
			end
		else
			player:sendError(_("Du hast nicht so viel Weed dabei!", player))
		end
	else
		self:sendMessage(player, BeggarPhraseTypes.InVehicle)
	end
end
