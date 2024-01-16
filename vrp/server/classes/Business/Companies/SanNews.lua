SanNews = inherit(Company)

function SanNews:constructor()
	self.m_isInterview = false
	self.m_InterviewPlayer = {}
	self.m_Blips = {}
	self.m_NextAd = getRealTime().timestamp
	self.m_onInterviewColshapeLeaveFunc = bind(self.onInterviewColshapeLeave, self)
	self.m_onPlayerChatFunc = bind(self.Event_onPlayerChat, self)
	self.m_SanNewsMessageEnabled = false
	self.m_RunningEvent = false
	self.m_SanNewsAds = {
		Ads = {},
		Settings = {
			AdsMainTimerObj = false,
			AdsMainTimer = 20,
			AdsActive = 1,
			currentForcedAdCooldown = false,
			isAdDeliveryRunning = false
		}
	}
	self.m_IsEventMode = false
	
	nextframe(function()
		self:loadAllAdData()
	end)
	
	self:InitTimeManagement()

	local safe = createObject(2332, 732.40, -1341.90, 13, 0, 0, 90)
 	self:setSafe(safe)

	local id = self:getId()
	local blip = Blip:new("House.png", 732.40, -1339.90, {company = id}, 400, {companyColors[id].r, companyColors[id].g, companyColors[id].b})
	blip:setDisplayText(self:getName(), BLIP_CATEGORY.Company)

   	Gate:new(968, Vector3(781.40, -1384.60, 13.50), Vector3(0, 90, 180), Vector3(781.40, -1384.60, 13.50), Vector3(0, 5, 180), false).onGateHit = bind(self.onBarrierHit, self)
	Gate:new(968, Vector3(781.30, -1330.30, 13.40), Vector3(0, 90, 180), Vector3(781.30, -1330.30, 13.40), Vector3(0, 5, 180), false).onGateHit = bind(self.onBarrierHit, self)

	-- Register in Player Hooks
	Player.getQuitHook():register(bind(self.Event_onPlayerQuit, self))
	Player.getChatHook():register(bind(self.Event_onPlayerChat, self))

	addRemoteEvents{"sanNewsStartInterview", "sanNewsStopInterview", "sanNewsAdvertisement", "sanNewsToggleMessage", "sanNewsStartStreetrace", "sanNewsAddBlip", "sanNewsDeleteBlips", "sanNewsSendAdDataToClient", "sanNewsGetAdDataFromClient", "sanNewsAdsSaveSettingsForCustomerFromClient", "sanNewsCreateNewCustomerFromClient", "sanNewsRemoveCustomerFromClient", "SanNewsAdsSearchPlayer", "SanNewsAdsSearchGroup", "sanNewsAdsRefreshCustomers", "sanNewsAdSettings", "sanNewsForceAd", "sanNewsGetAdPaymentData", "sanNewsPaymentAccept", "sanNewsEventModeToggle"}
	addEventHandler("sanNewsStartInterview", root, bind(self.Event_startInterview, self))
	addEventHandler("sanNewsStopInterview", root, bind(self.Event_stopInterview, self))
	addEventHandler("sanNewsAdvertisement", root, bind(self.Event_advertisement, self))
	addEventHandler("sanNewsToggleMessage", root, bind(self.Event_toggleMessage, self))
	addEventHandler("sanNewsStartStreetrace", root, bind(self.Event_startStreetrace, self))
	addEventHandler("sanNewsAddBlip", root, bind(self.Event_addBlip, self))
	addEventHandler("sanNewsDeleteBlips", root, bind(self.Event_deleteBlips, self))
	addEventHandler("sanNewsSendAdDataToClient", root, bind(self.AdsUpdateToClient, self))
	addEventHandler("sanNewsGetAdDataFromClient", root, bind(self.AdsUpdateFromClient, self))
	addEventHandler("sanNewsAdsSaveSettingsForCustomerFromClient", root, bind(self.AdsSaveSettingsForCustomerFromClient, self))
	addEventHandler("sanNewsCreateNewCustomerFromClient", root, bind(self.CreateNewAdCustomerFromClient, self))
	addEventHandler("sanNewsRemoveCustomerFromClient", root, bind(self.RemoveAdCustomerFromClient, self))
	addEventHandler("SanNewsAdsSearchPlayer", root, bind(self.AdSearchPlayer, self))
	addEventHandler("SanNewsAdsSearchGroup", root, bind(self.AdSearchGroup, self))
	addEventHandler("sanNewsAdsRefreshCustomers", root, bind(self.AdRefreshCustomers, self))
	addEventHandler("sanNewsAdSettings", root, bind(self.AdSettings, self))
	addEventHandler("sanNewsForceAd", root, bind(self.forceAd, self))
	addEventHandler("sanNewsGetAdPaymentData", root, bind(self.getContractData, self))
	addEventHandler("sanNewsPaymentAccept", root, bind(self.AcceptAdPayment, self))
	addEventHandler("sanNewsEventModeToggle", root, bind(self.toogleEventMode, self))

	addCommandHandler("news", bind(self.Event_news, self))
	addCommandHandler("sannews", bind(self.Event_sanNewsMessage, self), false, false)
end

function SanNews:destructor()

end

function SanNews:toogleEventMode()
	if client then
		if client:getCompany() == self then
			if client:isCompanyDuty() then
				if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "eventMode") then return end
				if self.m_IsEventMode then 
					self.m_IsEventMode = false
					self:sendShortMessage(_("Event-Modus deaktiviert."))
				else
					self.m_IsEventMode = true 
					self:sendShortMessage(_("Event-Modus aktiviert."))
				end
			else
				client:sendError(_("Du bist nicht im Dienst!", client))
				return
			end
		end
	end
end

function SanNews:loadAllAdData()
	local result = sql:queryFetch("SELECT * FROM ??_sannewsads", sql:getPrefix())
	if not result then return end

	local adSettings = sql:queryFetch("SELECT * FROM ??_sannewssettings", sql:getPrefix())
	if not adSettings then return end

	for k, row in pairs(result) do

		local theCustomerName
		if row.customerType == "Faction" then 
			local fac = FactionManager:getSingleton():getFromId(row.customerUniqueID)
			theCustomerName = fac:getShortName()
		end

		if row.customerType == "Company" then 
			local com = CompanyManager:getSingleton():getFromId(row.customerUniqueID)
			theCustomerName = com:getShortName()
		end

		if row.customerType == "Group" then 
			local gro = GroupManager:getSingleton():getFromId(row.customerUniqueID)
			theCustomerName = gro:getName()
		end

		if row.customerType == "Player" then 
			theCustomerName = Account.getNameFromId(row.customerUniqueID)
		end

		local prepareAdText = fromJSON(row.adText)
		local prepareAdTextEN = fromJSON(row.adTextEN)
		local preparePaymentAcceptance = fromJSON(row.paymentAcceptance)

		self.m_SanNewsAds["Ads"][row.customerID] = {
			customerID = row.customerID,
			customerName = theCustomerName,
			minPlayersOnlineToDeliverAds = row.minPlayersOnlineToDeliverAds,
			deliveringSpeed = row.deliveringSpeed,
			isActive = toboolean(row.isActive),
			moneyPerAd = row.moneyPerAd,
			adStartTimeEveryDay = row.adStartTimeEveryDay,
			adEndTimeEveryDay = row.adEndTimeEveryDay,
			lastDeliveryDate = row.lastDeliveryDate,
			lastDeliveryTime = row.lastDeliveryTime,
			timesDelivered = row.timesDelivered,
			customerType = row.customerType,
			customerUniqueID = row.customerUniqueID,
			maxPerDay = row.maxPerDay,
			deliveredThisDay = row.deliveredThisDay,
			adText = {
				[1] = prepareAdText["1"],
				[2] = prepareAdText["2"],
				[3] = prepareAdText["3"],
				[4] = prepareAdText["4"],
				[5] = prepareAdText["5"]
			},
			adTextEN = {
				[1] = prepareAdTextEN["1"],
				[2] = prepareAdTextEN["2"],
				[3] = prepareAdTextEN["3"],
				[4] = prepareAdTextEN["4"],
				[5] = prepareAdTextEN["5"]
			},
			paymentAcceptance = {
				paymentAccepted = preparePaymentAcceptance["paymentAccepted"],
				paymentAcceptedByPlayerID = preparePaymentAcceptance["paymentAcceptedByPlayerID"],
				paymentAcceptanceDate = preparePaymentAcceptance["paymentAcceptanceDate"],
				cancelationByPlayerID = preparePaymentAcceptance["cancelationByPlayerID"],
				cancelationDate = preparePaymentAcceptance["cancelationDate"]			
			}
		} 
	end

	for k, row in pairs(adSettings) do
		if k == 1 then 
			self.m_SanNewsAds["Settings"]["AdsMainTimer"] = tonumber(row.AdsMainTimer)
			self.m_SanNewsAds["Settings"]["AdsActive"] = tonumber(row.AdsActive)
		end
	end
end

function SanNews:AdRefreshCustomers()
	if client then 
		if client:getCompany() ~= self then
        	return
    	end
		if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "seeAdsForceAds") then return end
		self.m_SanNewsAds["Ads"] = {}
		self:loadAllAdData()
		self:AdsUpdateToClient()
	end
end

function SanNews:AdSettings(data)
	if client then 
		if client:getCompany() ~= self then
        	return
    	end
		if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "editAds") then return end
		if not data then return end
		if tonumber(data[1]) == nil then return end 
		local intervalOptions = SN_AD_SETTINGS_INTERVAL_OPTIONS

		for i = 1, #intervalOptions do 
			if data[1] == intervalOptions[i] then 
				self.m_SanNewsAds["Settings"]["AdsMainTimer"] = data[1]
			end
		end

		if data[2] == 0 then 
			self.m_SanNewsAds["Settings"]["AdsActive"] = 0
		elseif data[2] == 1 then 
			self.m_SanNewsAds["Settings"]["AdsActive"] = 1
		else
			return 
		end

		sql:queryExec("UPDATE ??_sannewssettings SET AdsActive = ?, AdsMainTimer = ?", sql:getPrefix(), self.m_SanNewsAds["Settings"]["AdsActive"], self.m_SanNewsAds["Settings"]["AdsMainTimer"])

		client:sendSuccess(_("Änderungen gespeichert.", client))

		if self.m_SanNewsAds["Settings"]["AdsActive"] == 0 then 
			if isTimer(self.m_SanNewsAds["Settings"]["AdsMainTimerObj"]) then killTimer(self.m_SanNewsAds["Settings"]["AdsMainTimerObj"]) end
		else
			self:InitTimeManagement()
		end

		self:AdsUpdateToClient()
	end
end

function SanNews:InitTimeManagement()
	if isTimer(self.m_SanNewsAds["Settings"]["AdsMainTimerObj"]) then killTimer(self.m_SanNewsAds["Settings"]["AdsMainTimerObj"]) end
	self.m_SanNewsAds["Settings"]["AdsMainTimerObj"] = setTimer(function ()
		self:deliverAds()
	end, self.m_SanNewsAds["Settings"]["AdsMainTimer"] * 60 * 1000, 0)
end

function SanNews:whereAdIsActive(tableWithCustomerIDs)
	local whereActive = {}
	for k, Ad in pairs(tableWithCustomerIDs) do 
		if self.m_SanNewsAds["Ads"][Ad]["isActive"] then 
			table.insert(whereActive, self.m_SanNewsAds["Ads"][Ad]["customerID"])
		end
	end

	if #whereActive >= 1 then 
		return whereActive
	else
		return false
	end
end

function SanNews:wherePaymentAccepted(tableWithCustomerIDs)
	local wherePaymentAccepted = {}
	for k, Ad in pairs(tableWithCustomerIDs) do 
		if self.m_SanNewsAds["Ads"][Ad]["paymentAcceptance"]["paymentAccepted"] == 1 then 
			table.insert(wherePaymentAccepted, self.m_SanNewsAds["Ads"][Ad]["customerID"])
		end
	end
	if #wherePaymentAccepted >= 1 then 
		return wherePaymentAccepted
	else
		return false 
	end
end

function SanNews:whereMoneyPerAdIsZero(tableWithCustomerIDs)
	local whereMoneyPerAdIsZero = {}
	for k, Ad in pairs(tableWithCustomerIDs) do 
		if self.m_SanNewsAds["Ads"][Ad]["moneyPerAd"] <= 0 then 
			table.insert(whereMoneyPerAdIsZero, self.m_SanNewsAds["Ads"][Ad]["customerID"])
		end
	end
	if #whereMoneyPerAdIsZero >= 1 then 
		return whereMoneyPerAdIsZero
	else
		return false 
	end
end

function SanNews:whereMoneyPerAdIsZeroOrWherePaymentAccepted (tableWithCustomerIDs)
	local whereMoneyPerAdIsZeroOrWherePaymentAccepted = {}
	for k, Ad in pairs(tableWithCustomerIDs) do 
		if self.m_SanNewsAds["Ads"][Ad]["moneyPerAd"] <= 0 or self.m_SanNewsAds["Ads"][Ad]["paymentAcceptance"]["paymentAccepted"] == 1 then 
			table.insert(whereMoneyPerAdIsZeroOrWherePaymentAccepted, self.m_SanNewsAds["Ads"][Ad]["customerID"])
		end
	end
	if #whereMoneyPerAdIsZeroOrWherePaymentAccepted >= 1 then 
		return whereMoneyPerAdIsZeroOrWherePaymentAccepted
	else
		return false 
	end
end

function SanNews:whereEnoughPlayersAreOnline(tableWithCustomerIDs)
	local currentPlayerCount = 0
	for k, v in pairs(getElementsByType("player")) do
		currentPlayerCount = currentPlayerCount + 1 
	end

	local whereEnoughPlayersOnline = {}
	for k, Ad in pairs(tableWithCustomerIDs) do 
		if currentPlayerCount >= self.m_SanNewsAds["Ads"][Ad]["minPlayersOnlineToDeliverAds"] then 
			table.insert(whereEnoughPlayersOnline, self.m_SanNewsAds["Ads"][Ad]["customerID"])
		end
	end
	if #whereEnoughPlayersOnline >= 1 then
		return whereEnoughPlayersOnline
	else
		return false
	end
end

function SanNews:getTablesWithPlayersInEnglishAndPlayersInGerman()
	local playersInEnglish = {}
	local playersInGerman = {}
	for k, player in pairs(getElementsByType("player")) do 
		if player:getLocale() == "en" then 
			table.insert(playersInEnglish, player)
		end
		if player:getLocale() == "de" then 
			table.insert(playersInGerman, player)
		end
	end
	return playersInEnglish, playersInGerman
end

function SanNews:whereAdIsInsideTimeFrame(tableWithCustomerIDs, currentTime)
	local hours = currentTime.hour 

	local whereInsideTimeframe = {}
	for k, Ad in pairs(tableWithCustomerIDs) do 
		local startTime1 = self.m_SanNewsAds["Ads"][Ad]["adStartTimeEveryDay"]
		local endTime1 = self.m_SanNewsAds["Ads"][Ad]["adEndTimeEveryDay"]
		
		if startTime1 == endTime1 then 
			table.insert(whereInsideTimeframe, self.m_SanNewsAds["Ads"][Ad]["customerID"])
		elseif startTime1 < endTime1 then 
			if startTime1 <= hours and endTime1 > hours then 
				table.insert(whereInsideTimeframe, self.m_SanNewsAds["Ads"][Ad]["customerID"])
			end
		elseif startTime1 > endTime1 then 
			if startTime1 <= hours and hours < 24 then 
				table.insert(whereInsideTimeframe, self.m_SanNewsAds["Ads"][Ad]["customerID"])
			elseif hours < endTime1 and hours >= 0 then 
				table.insert(whereInsideTimeframe, self.m_SanNewsAds["Ads"][Ad]["customerID"])
			elseif endTime == 0 and hours == 23 then 
				table.insert(whereInsideTimeframe, self.m_SanNewsAds["Ads"][Ad]["customerID"])
			else 
			end
		else
		end
	end
	if #whereInsideTimeframe >= 1 then
		return whereInsideTimeframe
	else
		return false 
	end
end

function SanNews:whereAdDayLimitIsNotReached(tableWithCustomerIDs, currentTime)
	local year = currentTime.year 
	local month = currentTime.month
	local monthDay = currentTime.monthday

	local currentDate = string.format("%04d-%02d-%02d", year+1900, month+1, monthDay)
	local whereMaxPerDayLimitNotReached = {}
	for k, Ad in pairs(tableWithCustomerIDs) do 
		if currentDate ~= self.m_SanNewsAds["Ads"][Ad]["lastDeliveryDate"] then 
			self.m_SanNewsAds["Ads"][Ad]["deliveredThisDay"] = 0
		end
		if self.m_SanNewsAds["Ads"][Ad]["maxPerDay"] > self.m_SanNewsAds["Ads"][Ad]["deliveredThisDay"] then
			table.insert(whereMaxPerDayLimitNotReached, self.m_SanNewsAds["Ads"][Ad]["customerID"])
		end 
	end
	if #whereMaxPerDayLimitNotReached >= 1 then
		return whereMaxPerDayLimitNotReached
	else
		return false 
	end
end

function SanNews:whereEnoughMoneyForAd(tableWithCustomerIDs)
	local whereEnoughMoneyForAd = {}
	for k, Ad in pairs(tableWithCustomerIDs) do 
		if self.m_SanNewsAds["Ads"][Ad]["moneyPerAd"] <= 0 then
			table.insert (whereEnoughMoneyForAd, self.m_SanNewsAds["Ads"][Ad]["customerID"])
		elseif self.m_SanNewsAds["Ads"][Ad]["customerType"] == "Company" then
			local theCustomerObj = CompanyManager:getSingleton():getFromId(self.m_SanNewsAds["Ads"][Ad]["customerUniqueID"])
			if theCustomerObj:getMoney() >= self.m_SanNewsAds["Ads"][Ad]["moneyPerAd"] then 
				table.insert(whereEnoughMoneyForAd, self.m_SanNewsAds["Ads"][Ad]["customerID"])
			end
		elseif self.m_SanNewsAds["Ads"][Ad]["customerType"] == "Faction" then 
			local theCustomerObj = FactionManager:getSingleton():getFromId(self.m_SanNewsAds["Ads"][Ad]["customerUniqueID"])
			if theCustomerObj:getMoney() >= self.m_SanNewsAds["Ads"][Ad]["moneyPerAd"] then 
				table.insert(whereEnoughMoneyForAd, self.m_SanNewsAds["Ads"][Ad]["customerID"])
			end
		elseif self.m_SanNewsAds["Ads"][Ad]["customerType"] == "Group" then 
			local theCustomerObj = GroupManager:getSingleton():getFromId(self.m_SanNewsAds["Ads"][Ad]["customerUniqueID"])
			if theCustomerObj:getMoney() >= self.m_SanNewsAds["Ads"][Ad]["moneyPerAd"] then 
				table.insert(whereEnoughMoneyForAd, self.m_SanNewsAds["Ads"][Ad]["customerID"])
			end
		elseif self.m_SanNewsAds["Ads"][Ad]["customerType"] == "Player" then
			local currentPlayerMoney = BankAccount.loadByOwner(self.m_SanNewsAds["Ads"][Ad]["customerUniqueID"], 1):getMoney()
			if currentPlayerMoney >= self.m_SanNewsAds["Ads"][Ad]["moneyPerAd"] then 
				table.insert(whereEnoughMoneyForAd, self.m_SanNewsAds["Ads"][Ad]["customerID"])
			end
		else
		end
	end
	if #whereEnoughMoneyForAd >= 1 then
		return whereEnoughMoneyForAd
	else
		return false 
	end 
end

function SanNews:getRandomCustomerID(tableWithCustomerIDs)
	math.randomseed(os.time())
	math.random(); math.random();

	local randomAdToBeDeliveredRandomizer = math.random(#tableWithCustomerIDs)
	local randomAdToBeDelivered = tableWithCustomerIDs[randomAdToBeDeliveredRandomizer]

	return randomAdToBeDelivered
end

function SanNews:addLatestAdStatistics(customerID, currentTime)
	local hours = currentTime.hour 
	local minutes = currentTime.minute 
	local seconds = currentTime.second
	local year = currentTime.year 
	local month = currentTime.month
	local monthDay = currentTime.monthday

	self.m_SanNewsAds["Ads"][customerID]["lastDeliveryDate"] = string.format("%04d-%02d-%02d", year+1900, month+1, monthDay)
	self.m_SanNewsAds["Ads"][customerID]["lastDeliveryTime"] = string.format("%02d:%02d:%02d", hours, minutes, seconds)
	self.m_SanNewsAds["Ads"][customerID]["timesDelivered"] = self.m_SanNewsAds["Ads"][customerID]["timesDelivered"] + 1
	self.m_SanNewsAds["Ads"][customerID]["deliveredThisDay"] = self.m_SanNewsAds["Ads"][customerID]["deliveredThisDay"] + 1
	sql:queryExec("UPDATE ??_sannewsads SET lastDeliveryDate = ?, lastDeliveryTime = ?, timesDelivered = ?, deliveredThisDay = ? WHERE customerID = ?", sql:getPrefix(), self.m_SanNewsAds["Ads"][customerID]["lastDeliveryDate"], self.m_SanNewsAds["Ads"][customerID]["lastDeliveryTime"], self.m_SanNewsAds["Ads"][customerID]["timesDelivered"], self.m_SanNewsAds["Ads"][customerID]["deliveredThisDay"], customerID)
end

function SanNews:transferMoneyForAdDelivery(customerID)
	if self.m_SanNewsAds["Ads"][customerID]["moneyPerAd"] ~= 0 then 
		local sanNewsBankAccount = CompanyManager:getSingleton():getFromId(3)

		local customerBankAccount
		if self.m_SanNewsAds["Ads"][customerID]["customerType"] == "Company" then 
			customerBankAccount = CompanyManager:getSingleton():getFromId(self.m_SanNewsAds["Ads"][customerID]["customerUniqueID"])
		elseif self.m_SanNewsAds["Ads"][customerID]["customerType"] == "Faction" then 
			customerBankAccount = FactionManager:getSingleton():getFromId(self.m_SanNewsAds["Ads"][customerID]["customerUniqueID"])
		elseif self.m_SanNewsAds["Ads"][customerID]["customerType"] == "Group" then
			customerBankAccount = GroupManager:getSingleton():getFromId(self.m_SanNewsAds["Ads"][customerID]["customerUniqueID"])
		elseif self.m_SanNewsAds["Ads"][customerID]["customerType"] == "Player" then
			customerBankAccount = BankAccount.loadByOwner(self.m_SanNewsAds["Ads"][customerID]["customerUniqueID"], 1)
		else
			return
		end

		customerBankAccount:transferMoney(sanNewsBankAccount, self.m_SanNewsAds["Ads"][customerID]["moneyPerAd"], self.m_SanNewsAds["Ads"][customerID]["customerName"], "San News", "Werbung")
		customerBankAccount:save()
		sanNewsBankAccount:save()
	end
end

function SanNews:outputAd(customerID, playersInEnglish, playersInGerman)
	local adLinesToShowInGerman = {}
	local adLinesToShowInEnglish = {}
	local adLinesInGerman = 0
	local adLinesInEnglish = 0
	local endOfGermanAds = false 
	local endOfEnglishAds = false

	for k, v in ipairs(self.m_SanNewsAds["Ads"][customerID]["adText"]) do
		if v ~= "" then 
			table.insert(adLinesToShowInGerman, v)
			adLinesInGerman = adLinesInGerman + 1
		end
	end
	
	for k, v in ipairs(self.m_SanNewsAds["Ads"][customerID]["adTextEN"]) do
		if v ~= "" then 
			table.insert(adLinesToShowInEnglish, v)
			adLinesInEnglish = adLinesInEnglish + 1
		end
	end

	local adLanguageFallback = false 
	if adLinesInEnglish <= 0 then 
		adLanguageFallback = true 
	end

	self.m_SanNewsAds["Settings"]["isAdDeliveryRunning"] = true

	triggerClientEvent(root, "sanNewsAdsSound", resourceRoot)

	outputChatBox("#FFFFFF▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁", root, 255, 200, 20, true)
	outputChatBox(_("#FFFFFFWerbung │ #67D68E%s", player, self.m_SanNewsAds["Ads"][customerID]["customerName"]), root, 255, 200, 20, true)
	outputChatBox("#FFFFFF▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔", root, 255, 200, 20, true)

	if adLinesInGerman <= 0 and adLinesInEnglish <= 0 then return end

	local currentAdDeliveredLines = 1

	local adDeliveryTimer = setTimer(function ()
		if adLinesInGerman >= currentAdDeliveredLines then 
			outputChatBox(("#67D68E%s"):format(adLinesToShowInGerman[currentAdDeliveredLines]), playersInGerman, 255, 200, 20, true)
		end
		if adLinesInGerman < currentAdDeliveredLines and endOfGermanAds == false then
			if adLanguageFallback then 
				outputChatBox("#FFFFFF▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁", root, 255, 200, 20, true)
			else
				outputChatBox("#FFFFFF▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁", playersInGerman, 255, 200, 20, true)
			end
			endOfGermanAds = true
		end
		if adLanguageFallback then 
			if adLinesInGerman >= currentAdDeliveredLines then 
				outputChatBox(("#67D68E%s"):format(adLinesToShowInGerman[currentAdDeliveredLines]), playersInEnglish, 255, 200, 20, true)
			end
		else
			if adLinesInEnglish >= currentAdDeliveredLines then 
				outputChatBox(("#67D68E%s"):format(adLinesToShowInEnglish[currentAdDeliveredLines]), playersInEnglish, 255, 200, 20, true)
			end
			if adLinesInEnglish < currentAdDeliveredLines and endOfEnglishAds == false then
				outputChatBox("#FFFFFF▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁", playersInEnglish, 255, 200, 20, true)
				endOfEnglishAds = true
			end
		end
		if currentAdDeliveredLines >= 6 then 
			self.m_SanNewsAds["Settings"]["isAdDeliveryRunning"] = false
		end
		currentAdDeliveredLines = currentAdDeliveredLines + 1
	end, self.m_SanNewsAds["Ads"][customerID]["deliveringSpeed"] * 1000, 6)
end

function SanNews:deliverAds()
	if self.m_SanNewsAds["Settings"]["AdsActive"] == 0 then return end

	if self.m_IsEventMode then return end

	if AdminEventManager:getSingleton():isEventRunning() then return end

	if table.size(self.m_SanNewsAds["Ads"]) <= 0 then return	end

	local everyCustomer = {}
	for k, v in pairs(self.m_SanNewsAds["Ads"]) do 
		table.insert(everyCustomer, self.m_SanNewsAds["Ads"][k]["customerID"])
	end

	local whereActive = self:whereAdIsActive(everyCustomer)
	if not whereActive then return end 

	local whereMoneyPerAdIsZeroOrWherePaymentAccepted = self:whereMoneyPerAdIsZeroOrWherePaymentAccepted(whereActive)
	if not whereMoneyPerAdIsZeroOrWherePaymentAccepted then return end

	local whereEnoughPlayersOnline = self:whereEnoughPlayersAreOnline(whereMoneyPerAdIsZeroOrWherePaymentAccepted)
	if not whereEnoughPlayersOnline then return end 

	local playersInEnglish, playersInGerman = self:getTablesWithPlayersInEnglishAndPlayersInGerman()

	local currentTime = getRealTime()
	
	local whereInsideTimeframe = self:whereAdIsInsideTimeFrame(whereEnoughPlayersOnline, currentTime)
	if not whereInsideTimeframe then return end

	local whereMaxPerDayLimitNotReached = self:whereAdDayLimitIsNotReached(whereInsideTimeframe, currentTime)
	if not whereMaxPerDayLimitNotReached then return end

	local whereEnoughMoneyForAd = self:whereEnoughMoneyForAd(whereMaxPerDayLimitNotReached)
	if not whereEnoughMoneyForAd then return end

	local randomCustomerID = self:getRandomCustomerID(whereEnoughMoneyForAd)

	self:addLatestAdStatistics(randomCustomerID, currentTime)

	self:transferMoneyForAdDelivery(randomCustomerID)

	self:outputAd(randomCustomerID, playersInEnglish, playersInGerman)
end

function SanNews:forceAd(customerID, withConditions)
	if client then 
		if client:getCompany() ~= self then 
			return 
		end
		if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "seeAdsForceAds") then return end
		
		if self.m_IsEventMode then 
			client:sendError(_("Event-Modus aktiviert. Werbung kann deshalb nicht geschaltet werden.", client))
			return 
		end

		if AdminEventManager:getSingleton():isEventRunning() then 
			client:sendError(_("Während Admin-Events können Werbungen nicht geschaltet werden.", client))
			return
		end

		if self.m_SanNewsAds["Settings"]["isAdDeliveryRunning"] then 
			client:sendError(_("Es wird gerade bereits eine Werbung geschaltet.", client))
			return 
		end
		
		if self.m_SanNewsAds["Settings"]["currentForcedAdCooldown"] then 
			client:sendError(_("Werbeschaltungen können nur alle 5 Minuten erzwungen werden.", client))
			return
		end
		if tonumber(customerID) == nil then return end
		if self.m_SanNewsAds["Ads"][customerID] then 
			local currentTime = getRealTime()
			if withConditions then 
				local whereActive = self:whereAdIsActive({customerID})
				if not whereActive then
					client:sendError(_("Bedingungen sind nicht erfüllt.", client))
					return
				end 

				local whereMoneyPerAdIsZeroOrWherePaymentAccepted = self:whereMoneyPerAdIsZeroOrWherePaymentAccepted(whereActive)
				if not whereMoneyPerAdIsZeroOrWherePaymentAccepted then 
					client:sendError(_("Bedingungen sind nicht erfüllt.", client))
					return
				end

				local whereEnoughPlayersOnline = self:whereEnoughPlayersAreOnline(whereMoneyPerAdIsZeroOrWherePaymentAccepted)
				if not whereEnoughPlayersOnline then 
					client:sendError(_("Bedingungen sind nicht erfüllt.", client))
					return
				end 

				local whereInsideTimeframe = self:whereAdIsInsideTimeFrame(whereEnoughPlayersOnline, currentTime)
				if not whereInsideTimeframe then 
					client:sendError(_("Bedingungen sind nicht erfüllt.", client))
					return
				end

				local whereMaxPerDayLimitNotReached = self:whereAdDayLimitIsNotReached(whereInsideTimeframe, currentTime)
				if not whereMaxPerDayLimitNotReached then 
					client:sendError(_("Bedingungen sind nicht erfüllt.", client))
					return
				end

				local whereEnoughMoneyForAd = self:whereEnoughMoneyForAd(whereMaxPerDayLimitNotReached)
				if not whereEnoughMoneyForAd then 
					client:sendError(_("Bedingungen sind nicht erfüllt.", client))
					return
				end

				self:transferMoneyForAdDelivery(customerID)

				self:addLatestAdStatistics(customerID, currentTime)
			end
			
			playersInEnglish, playersInGerman = self:getTablesWithPlayersInEnglishAndPlayersInGerman()
			
			self:outputAd(customerID, playersInEnglish, playersInGerman)
			
			client:triggerEvent("updateAdData", self.m_SanNewsAds)
			
			self.m_SanNewsAds["Settings"]["currentForcedAdCooldown"] = true
			local forcedAdCooldownTimer = setTimer(function()
				self.m_SanNewsAds["Settings"]["currentForcedAdCooldown"] = false
			end, 1000 * 60 * 5, 1)
		end
	end
end

function SanNews:AdsUpdateToClient()
	if client then 
		if client:getCompany() ~= self then
        	return
    	end
		if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "seeAdsForceAds") then return end
		client:triggerEvent("sanNewsAdsLoadForClient", self.m_SanNewsAds)
	end
end

function SanNews:AdsUpdateFromClient(table)
	if client then 
		if client:getCompany() ~= self then
        	return
    	end
		if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "editAds") then return end
		if not table then return end

		if tonumber(table["customerID"]) == nil then return end 
		local customerID = table["customerID"]

		for k, v in ipairs(table["DE"]) do 
			if string.len(table["DE"][k]) <= 240 then 
				self.m_SanNewsAds["Ads"][customerID]["adText"][k] = table["DE"][k]
			else
				return 
			end
		end
		
		for k, v in ipairs(table["EN"]) do 
			if string.len(table["EN"][k]) <= 240 then 
				self.m_SanNewsAds["Ads"][customerID]["adTextEN"][k] = table["EN"][k]
			else
				return 
			end
		end

		local jsonAdText = toJSON(self.m_SanNewsAds["Ads"][customerID]["adText"])
		local jsonAdTextEN = toJSON(self.m_SanNewsAds["Ads"][customerID]["adTextEN"])

		sql:queryExec("UPDATE ??_sannewsads SET adText = ?, adTextEN = ? WHERE customerID = ?", sql:getPrefix(), jsonAdText, jsonAdTextEN, customerID)
		client:sendSuccess(_("Änderungen gespeichert.", client))
	end
end

function SanNews:CreateNewAdCustomerFromClient(customerTypeA, customerUniqueIDA)
	if client then 
		if client:getCompany() ~= self then
        	return
    	end
		if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "editAds") then return end
		local availableCustomerTypes = {"Faction","Company","Group","Player"}
		local customerTypeCheck = false
		for k, v in pairs(availableCustomerTypes) do 
			if customerTypeA == availableCustomerTypes[k] then 
				customerTypeCheck = true
			end
		end 
		if customerTypeCheck == false then return end 

		if tonumber(customerUniqueIDA) == nil then return end 

		local name

		if customerTypeA == "Faction" then 
			local fac = FactionManager:getSingleton():getFromId(customerUniqueIDA)
			if fac then 	
				name = fac:getShortName()
			else 
				return
			end
		elseif customerTypeA == "Company" then 
			local com = CompanyManager:getSingleton():getFromId(customerUniqueIDA)
			if com then 
				name = com:getShortName()
			else
				return
			end
		elseif customerTypeA == "Group" then 
			local gro = GroupManager:getSingleton():getFromId(customerUniqueIDA)
			if gro then 
				name = gro:getName()	
			else
				return
			end
		elseif customerTypeA == "Player" then 
			local pla = Account.getNameFromId(customerUniqueIDA)
			if pla then 
				name = pla 
			else
				return
			end
		else
			return
		end

		local currentNumberOfEntries = 0
		for k,v in pairs(self.m_SanNewsAds["Ads"]) do 
			if self.m_SanNewsAds["Ads"][k]["customerID"] > currentNumberOfEntries then 
				currentNumberOfEntries = self.m_SanNewsAds["Ads"][k]["customerID"]
			end
		end
		
		local newCustomerID
		if currentNumberOfEntries == 0 then 
			newCustomerID = 1
		else
			local currentLastEntry = self.m_SanNewsAds["Ads"][currentNumberOfEntries]["customerID"]
			newCustomerID = currentLastEntry + 1
		end 

		local preparedAdText = {
			[1] = "",
			[2] = "",
			[3] = "",
			[4] = "",
			[5] = ""
		}
		local preparedAdTextEN = {
			[1] = "",
			[2] = "",
			[3] = "",
			[4] = "",
			[5] = ""
		}

		local preparedPaymentAcceptance = {
			paymentAccepted = 0,
			paymentAcceptedByPlayerID = -1,
			paymentAcceptanceDate = "",
			cancelationByPlayerID = -1,
			cancelationDate = ""
		}

		local jsonAdText = toJSON(preparedAdText)
		local jsonAdTextEN = toJSON(preparedAdTextEN)
		local jsonPaymentAcceptance = toJSON(preparedPaymentAcceptance)
		
		self.m_SanNewsAds["Ads"][newCustomerID] = {
			customerID = newCustomerID,
			customerName = name,
			minPlayersOnlineToDeliverAds = 1,
			deliveringSpeed = 1,
			isActive = false,
			moneyPerAd = 0,
			adStartTimeEveryDay = 0,
			adEndTimeEveryDay = 0,
			lastDeliveryDate = "0000-00-00",
			lastDeliveryTime = "00:00:00",
			timesDelivered = 0,
			customerType = customerTypeA,
			customerUniqueID = customerUniqueIDA,
			maxPerDay = 3,
			deliveredThisDay = 0,
			adText = {
				[1] = "",
				[2] = "",
				[3] = "",
				[4] = "",
				[5] = "",
			},
			adTextEN = {
				[1] = "",
				[2] = "",
				[3] = "",
				[4] = "",
				[5] = "",
			},
			paymentAcceptance = {
				paymentAccepted = 0,
				paymentAcceptedByPlayerID = -1,
				paymentAcceptanceDate = "",
				cancelationByPlayerID = -1,
				cancelationDate = ""				
			}
		}

		local aa = fromboolean(self.m_SanNewsAds["Ads"][newCustomerID]["isActive"])
		sql:queryExec("INSERT INTO ??_sannewsads (customerID, minPlayersOnlineToDeliverAds, deliveringSpeed, isActive, moneyPerAd, adStartTimeEveryDay, adEndTimeEveryDay, adText, adTextEN, paymentAcceptance, lastDeliveryDate, lastDeliveryTime, timesDelivered, customerType, customerUniqueID, maxPerDay, deliveredThisDay) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", sql:getPrefix(), self.m_SanNewsAds["Ads"][newCustomerID]["customerID"], self.m_SanNewsAds["Ads"][newCustomerID]["minPlayersOnlineToDeliverAds"], self.m_SanNewsAds["Ads"][newCustomerID]["deliveringSpeed"], aa, self.m_SanNewsAds["Ads"][newCustomerID]["moneyPerAd"], self.m_SanNewsAds["Ads"][newCustomerID]["adStartTimeEveryDay"], self.m_SanNewsAds["Ads"][newCustomerID]["adEndTimeEveryDay"], jsonAdText, jsonAdTextEN, jsonPaymentAcceptance, self.m_SanNewsAds["Ads"][newCustomerID]["lastDeliveryDate"], self.m_SanNewsAds["Ads"][newCustomerID]["lastDeliveryTime"], self.m_SanNewsAds["Ads"][newCustomerID]["timesDelivered"], self.m_SanNewsAds["Ads"][newCustomerID]["customerType"], self.m_SanNewsAds["Ads"][newCustomerID]["customerUniqueID"], self.m_SanNewsAds["Ads"][newCustomerID]["maxPerDay"], self.m_SanNewsAds["Ads"][newCustomerID]["deliveredThisDay"])

		client:sendSuccess(_("Kunde hinzugefügt.", client))

		self:AdsUpdateToClient()
	end
end

function SanNews:RemoveAdCustomerFromClient(id)
	if client then
		if client:getCompany() ~= self then
        	return
    	end 
		if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "editAds") then return end
		if not id then return end
		if tonumber(id) == nil then return end
		if self.m_SanNewsAds["Ads"][id] then
			if self.m_SanNewsAds["Ads"][id]["customerID"] == id then 
				self.m_SanNewsAds["Ads"][id] = nil 
				sql:queryExec("DELETE FROM ??_sannewsads WHERE customerID = ?", sql:getPrefix(), id)
				client:sendSuccess(_("Kunde entfernt.", client))
				self:AdsUpdateToClient()
			else 
				return
			end
		end
	end
end

function SanNews:AdsSaveSettingsForCustomerFromClient(sendTable)
	if client then 
		if client:getCompany() ~= self then
        	return
    	end
		if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "editAds") then return end
		if not sendTable then return end 

		local minPlayerChangerOptions = SN_AD_MIN_NUMBER_OF_PLAYERS_ONLINE_TO_DELIVER_AD_OPTIONS
		local speedOfDeliveryChangerOptions = SN_AD_INTERVAL_BETWEEN_AD_LINES_IN_SECONDS_OPTIONS
		local timeChangerOptions = SN_AD_TIME_HOUR_OPTIONS
		local maxPerDayChangerOptions = SN_AD_MAX_NUMBER_OF_AD_PER_DAY_PER_CUSTOMER_OPTIONS

		local changesSaved = false

		for k,v in pairs(sendTable) do
			if not sendTable[k]["custID"] then return end
			if sendTable[k]["custID"] == nil then return end
			if not self.m_SanNewsAds["Ads"][sendTable[k]["custID"]] then return end
			if self.m_SanNewsAds["Ads"][sendTable[k]["custID"]]["customerID"] ~= sendTable[k]["custID"] then return end

			local customerID = sendTable[k]["custID"]

			local notOnlyIsActiveHasChanged = false
			
			if sendTable[k]["isActive"] == true or sendTable[k]["isActive"] == false then 
				self.m_SanNewsAds["Ads"][customerID]["isActive"] = sendTable[k]["isActive"]
			end

			if tonumber(sendTable[k]["moneyPerAd"]) ~= nil then
				if tonumber(sendTable[k]["moneyPerAd"]) >= 0 and tonumber(sendTable[k]["moneyPerAd"]) <= 99999 then 
					if self.m_SanNewsAds["Ads"][customerID]["moneyPerAd"] ~= tonumber(sendTable[k]["moneyPerAd"]) then 
						notOnlyIsActiveHasChanged = true 
					end
					self.m_SanNewsAds["Ads"][customerID]["moneyPerAd"] = tonumber(sendTable[k]["moneyPerAd"])
				end
			end
			
			if tonumber(sendTable[k]["minPlayersOnlineToDeliverAds"]) ~= nil then
				for i = 1, #minPlayerChangerOptions do 
					if sendTable[k]["minPlayersOnlineToDeliverAds"] == minPlayerChangerOptions[i] then 
						if self.m_SanNewsAds["Ads"][customerID]["minPlayersOnlineToDeliverAds"] ~= tonumber(sendTable[k]["minPlayersOnlineToDeliverAds"]) then 
							notOnlyIsActiveHasChanged = true
						end
						self.m_SanNewsAds["Ads"][customerID]["minPlayersOnlineToDeliverAds"] = tonumber(sendTable[k]["minPlayersOnlineToDeliverAds"])
					end
				end
			end
			
			if tonumber(sendTable[k]["deliveringSpeed"]) ~= nil then
				for i = 1, #speedOfDeliveryChangerOptions do 
					if sendTable[k]["deliveringSpeed"] == speedOfDeliveryChangerOptions[i] then 
						if self.m_SanNewsAds["Ads"][customerID]["deliveringSpeed"] ~= tonumber(sendTable[k]["deliveringSpeed"]) then 
							notOnlyIsActiveHasChanged = true
						end
						self.m_SanNewsAds["Ads"][customerID]["deliveringSpeed"] = tonumber(sendTable[k]["deliveringSpeed"])
					end
				end
			end
			
			if tonumber(sendTable[k]["adStartTimeEveryDay"]) ~= nil then
				for i = 1, #timeChangerOptions do 
					if sendTable[k]["adStartTimeEveryDay"] == timeChangerOptions[i] then 
						if self.m_SanNewsAds["Ads"][customerID]["adStartTimeEveryDay"] ~= tonumber(sendTable[k]["adStartTimeEveryDay"]) then 
							notOnlyIsActiveHasChanged = true 
						end
						self.m_SanNewsAds["Ads"][customerID]["adStartTimeEveryDay"] = tonumber(sendTable[k]["adStartTimeEveryDay"])
					end
				end
			end

			if tonumber(sendTable[k]["adEndTimeEveryDay"]) ~= nil then
				for i = 1, #timeChangerOptions do 
					if sendTable[k]["adEndTimeEveryDay"] == timeChangerOptions[i] then 
						if self.m_SanNewsAds["Ads"][customerID]["adEndTimeEveryDay"] ~= tonumber(sendTable[k]["adEndTimeEveryDay"]) then 
							notOnlyIsActiveHasChanged = true 
						end
						self.m_SanNewsAds["Ads"][customerID]["adEndTimeEveryDay"] = tonumber(sendTable[k]["adEndTimeEveryDay"])
					end
				end
			end

			if tonumber(sendTable[k]["maxPerDay"]) ~= nil then
				for i = 1, #maxPerDayChangerOptions do 
					if sendTable[k]["maxPerDay"] == maxPerDayChangerOptions[i] then 
						if self.m_SanNewsAds["Ads"][customerID]["maxPerDay"] ~= tonumber(sendTable[k]["maxPerDay"]) then 
							notOnlyIsActiveHasChanged = true 
						end
						self.m_SanNewsAds["Ads"][customerID]["maxPerDay"] = tonumber(sendTable[k]["maxPerDay"])
					end
				end
			end

			local aa
			if self.m_SanNewsAds["Ads"][customerID]["isActive"] then 
				aa = 1
			else
				aa = 0
			end

			if notOnlyIsActiveHasChanged then 
				self.m_SanNewsAds["Ads"][customerID]["paymentAcceptance"] = {
					paymentAccepted = 0,
					paymentAcceptedByPlayerID = -1,
					paymentAcceptanceDate = "",
					cancelationByPlayerID = -1,
					cancelationDate = ""				
				}

				local paymentAcceptanceJSON = toJSON(self.m_SanNewsAds["Ads"][customerID]["paymentAcceptance"])
			
				sql:queryExec("UPDATE ??_sannewsads SET isActive = ?, moneyPerAd = ?, minPlayersOnlineToDeliverAds = ?, deliveringSpeed = ?, adStartTimeEveryDay = ?, adEndTimeEveryDay = ?, maxPerDay = ?, paymentAcceptance = ? WHERE customerID = ?", sql:getPrefix(), aa, self.m_SanNewsAds["Ads"][customerID]["moneyPerAd"], self.m_SanNewsAds["Ads"][customerID]["minPlayersOnlineToDeliverAds"], self.m_SanNewsAds["Ads"][customerID]["deliveringSpeed"], self.m_SanNewsAds["Ads"][customerID]["adStartTimeEveryDay"], self.m_SanNewsAds["Ads"][customerID]["adEndTimeEveryDay"], self.m_SanNewsAds["Ads"][customerID]["maxPerDay"], paymentAcceptanceJSON, customerID)
			
			else
				sql:queryExec("UPDATE ??_sannewsads SET isActive = ?, moneyPerAd = ?, minPlayersOnlineToDeliverAds = ?, deliveringSpeed = ?, adStartTimeEveryDay = ?, adEndTimeEveryDay = ?, maxPerDay = ? WHERE customerID = ?", sql:getPrefix(), aa, self.m_SanNewsAds["Ads"][customerID]["moneyPerAd"], self.m_SanNewsAds["Ads"][customerID]["minPlayersOnlineToDeliverAds"], self.m_SanNewsAds["Ads"][customerID]["deliveringSpeed"], self.m_SanNewsAds["Ads"][customerID]["adStartTimeEveryDay"], self.m_SanNewsAds["Ads"][customerID]["adEndTimeEveryDay"], self.m_SanNewsAds["Ads"][customerID]["maxPerDay"], customerID)
			end
			changesSaved = true
		end
		if changesSaved then 
			client:sendSuccess(_("Änderungen gespeichert.", client))
		end
		client:triggerEvent("updateAdData", self.m_SanNewsAds)
	else
	end
end

function SanNews:AdSearchPlayer(name)
	if client then 
		if client:getCompany() ~= self then
        	return
    	end
		if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "editAds") then return end
        local resultPlayers = {}
        local result = sql:queryFetch("SELECT Id, Name FROM ??_account WHERE Name LIKE ?;", sql:getPrefix(), ("%%%s%%"):format(name))
        for i, row in pairs(result) do
            resultPlayers[row.Id] = row.Name
        end
        client:triggerEvent("sanNewsAdsReceiveSearchedPlayers", resultPlayers)
    end
end

function SanNews:AdSearchGroup(name)
	if client then
		if client:getCompany() ~= self then
        	return
    	end
		if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "editAds") then return end
        local resultGroups = {}
        local result = sql:queryFetch("SELECT Id, Name FROM ??_groups WHERE Name LIKE ?;", sql:getPrefix(), ("%%%s%%"):format(name))
        for i, row in pairs(result) do
            resultGroups[row.Id] = row.Name
        end
        client:triggerEvent("sanNewsAdsReceiveSearchedGroups", resultGroups)
    end
end 

function SanNews:getContractData()
	if client then 
			local sendData = {
				Faction = false,
				Company = false,
				Group = false,
				Player = false
			}
			
			local faction = client:getFaction()
			local company = client:getCompany()
			local group = client:getGroup()

			local preparedTable = {}
			if faction then 
				preparedTable["Faction"] = faction
			end
			if company then 
				preparedTable["Company"] = company
			end
			if group then 
				preparedTable["Group"] = group
			end
			preparedTable["Player"] = client

			for k, v in pairs(self.m_SanNewsAds["Ads"]) do 
				if self.m_SanNewsAds["Ads"][k]["moneyPerAd"] > 0 then
					for l, w in pairs(preparedTable) do 
						if l == self.m_SanNewsAds["Ads"][k]["customerType"] then
							if w:getId() == self.m_SanNewsAds["Ads"][k]["customerUniqueID"] then 
									local paymentStatus
									if self.m_SanNewsAds["Ads"][k]["paymentAcceptance"]["paymentAccepted"] == 0 then
										paymentStatus = 0
									else
										paymentStatus = 1
									end
									sendData[l] = {
										customerID = self.m_SanNewsAds["Ads"][k]["customerID"],
										customerUniqueID = self.m_SanNewsAds["Ads"][k]["customerUniqueID"],
										customerType = self.m_SanNewsAds["Ads"][k]["customerType"],
										customerName = self.m_SanNewsAds["Ads"][k]["customerName"],
										customerPay = self.m_SanNewsAds["Ads"][k]["moneyPerAd"],
										customerPaymentStatus = paymentStatus,
										maxPerDay = self.m_SanNewsAds["Ads"][k]["maxPerDay"],
										minPlayers = self.m_SanNewsAds["Ads"][k]["minPlayersOnlineToDeliverAds"],
										startTime = self.m_SanNewsAds["Ads"][k]["adStartTimeEveryDay"],
										endTime = self.m_SanNewsAds["Ads"][k]["adEndTimeEveryDay"]
									}
									if l ~= "Player" then 
										if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, string.lower(l), "authAdPayment") then 
											sendData[l] = false
										end
									end
							end
						end
					end
				end
			end
			client:triggerEvent("receiveContractData", sendData)
	end
end

function SanNews:AcceptAdPayment(table)
	if client then 
		local customerID = table["customerID"]

		if tonumber(customerID) == nil then return end
		if self.m_SanNewsAds["Ads"][customerID] then 
			if table["customerUniqueID"] ~= self.m_SanNewsAds["Ads"][customerID]["customerUniqueID"] then return end
			if table["customerType"] ~= self.m_SanNewsAds["Ads"][customerID]["customerType"] then return end

			if table["customerType"] == "Faction" or table["customerType"] == "Company" or table["customerType"] == "Group" then 
				if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, string.lower(table["customerType"]), "authAdPayment") then return end
			elseif table["customerType"] == "Player" then 
				--
			else
				return
			end
			
			if table["customerPaymentStatus"] == 1 then 
				self.m_SanNewsAds["Ads"][customerID]["paymentAcceptance"]["paymentAccepted"] = 1
				self.m_SanNewsAds["Ads"][customerID]["paymentAcceptance"]["paymentAcceptedByPlayerID"] = client:getId()
				local currentTime = getRealTime()
				local year = currentTime.year 
				local month = currentTime.month
				local monthDay = currentTime.monthday
				self.m_SanNewsAds["Ads"][customerID]["paymentAcceptance"]["paymentAcceptanceDate"] = year+1900 .. "-" .. month+1 .. "-" .. monthDay
				self.m_SanNewsAds["Ads"][customerID]["paymentAcceptance"]["cancelationByPlayerID"] = -1
				self.m_SanNewsAds["Ads"][customerID]["paymentAcceptance"]["cancelationDate"] = ""

				local jsonPaymentAcceptance = toJSON(self.m_SanNewsAds["Ads"][customerID]["paymentAcceptance"])

				sql:queryExec("UPDATE ??_sannewsads SET paymentAcceptance = ? WHERE customerID = ?", sql:getPrefix(), jsonPaymentAcceptance, customerID)
				
				client:sendSuccess(_("Zahlung autorisiert.", client))
				
				self:getContractData()
			
			elseif table["customerPaymentStatus"] == 0 then 
				self.m_SanNewsAds["Ads"][customerID]["paymentAcceptance"]["paymentAccepted"] = 0
				self.m_SanNewsAds["Ads"][customerID]["paymentAcceptance"]["cancelationByPlayerID"] = client:getId()
				local currentTime = getRealTime()
				local year = currentTime.year 
				local month = currentTime.month
				local monthDay = currentTime.monthday
				self.m_SanNewsAds["Ads"][customerID]["paymentAcceptance"]["cancelationDate"] = year+1900 .. "-" .. month+1 .. "-" .. monthDay
				self.m_SanNewsAds["Ads"][customerID]["paymentAcceptance"]["paymentAcceptedByPlayerID"] = -1
				self.m_SanNewsAds["Ads"][customerID]["paymentAcceptance"]["paymentAcceptanceDate"] = ""

				local jsonPaymentAcceptance = toJSON(self.m_SanNewsAds["Ads"][customerID]["paymentAcceptance"])

				sql:queryExec("UPDATE ??_sannewsads SET paymentAcceptance = ? WHERE customerID = ?", sql:getPrefix(), jsonPaymentAcceptance, customerID)

				client:sendSuccess(_("Zahlung deautorisiert.", client))

				self:getContractData()
			else
				return 
			end
		end
	end
end

function SanNews:onBarrierHit(player)
    if player:getCompany() ~= self then
        return false
    end
    return true
end

function SanNews:Event_news(player, cmd, ...)
	if player:getCompany() == self then
		if player:isCompanyDuty() then 
			if not self.m_IsEventMode then 
				player:sendError(_("Event-Modus muss aktiviert werden.", player))
				return
			end
			local argTable = { ... }
			local text = table.concat ( argTable , " " )
			outputChatBox(_("#FE8D14Reporter %s:#FEDD42 %s", player, player.name, text), root, 255, 200, 20, true)

    		local receivedPlayers = {}
			for k, targetPlayer in pairs(PlayerManager:getSingleton():getReadyPlayers()) do
				if targetPlayer ~= player then
					if targetPlayer:isLoggedIn() then
						receivedPlayers[#receivedPlayers+1] = targetPlayer
					end
				end
			end
			StatisticsLogger:getSingleton():addChatLog(player, "news", text, receivedPlayers)
		else
			player:sendError(_("Du bist nicht im Dienst!", player))
		end
	end
end

function SanNews:Event_startInterview(target)
	if client:getCompany() == self then
		if client:isCompanyDuty() then 
			if not self.m_IsEventMode then 
				player:sendError(_("Event-Modus muss aktiviert werden.", player))
				return
			end
			if not self.m_isInterview then
				self.m_isInterview = true
				self.m_InterviewColshape = createColSphere(client.position, 4)
				self.m_InterviewColshape:attach(client)

				client:sendInfo(_("Du hast ein Interview mit %s gestartet!", client, target.name))
				target:sendInfo(_("Reporter %s hat ein Interview mit dir gestartet!", target, client.name))
				target:sendShortMessage(_("Interview: Alles was du im Chat schreibst ist nun öffentlich! (Außnahme: @l [text])", target))
				self:addInterviewPlayer(client)
				self:addInterviewPlayer(target)
			else
				client:sendError(_("Es findet bereits ein Interview statt!", client))
			end
		else
			client:sendError(_("Du bist nicht im Dienst!", client))
		end
	end
end

function SanNews:addInterviewPlayer(player)
	table.insert(self.m_InterviewPlayer, player)
	player:setPublicSync("inInterview", true)
end

function SanNews:Event_stopInterview(target)
	if client:getCompany() == self then
		if client:isCompanyDuty() then
			client:sendInfo(_("Du hast das Interview mit %s beendet!", client, target.name))
			target:sendInfo(_("Reporter %s hat das Interview mit dir beendet!", target, client.name))
			self:stopInterview()
		else
			client:sendError(_("Du bist nicht im Dienst!", client))
		end
	end
end

function SanNews:Event_onPlayerQuit()
	if table.find(self.m_InterviewPlayer, source) then
		for index, player in pairs(self.m_InterviewPlayer) do
			player:sendInfo(_("Interview beendet! Ein Spieler ist offline gegangen!", player))
		end
		self:stopInterview()
	end
end

function SanNews:onInterviewColshapeLeave(leaveElement)
	if table.find(self.m_InterviewPlayer, leaveElement) then
		for index, player in pairs(self.m_InterviewPlayer) do
			player:sendInfo(_("Interview beendet! Ihr habt euch zu weit entfernt!", player))
		end
		self:stopInterview()
	end
end

function SanNews:stopInterview()
	for index, player in pairs(self.m_InterviewPlayer) do
		player:setPublicSync("inInterview", false)
	end
	self.m_isInterview = false
	self.m_InterviewPlayer = {}
	self.m_InterviewColshape:destroy()
end

function SanNews:Event_onPlayerChat(player, text, type)
	if type == 0 then
		if table.find(self.m_InterviewPlayer, player) then
			if text:sub(1, 2):lower() ~= "@l" then
				if player:getCompany() == self and player:isCompanyDuty() then
					outputChatBox(_("#FE8D14Reporter %s:#FEDD42 %s", player, player.name, text), root, 255, 200, 20, true)
				else
					outputChatBox(_("#FE8D14[Interview] %s:#FEDD42 %s", player, player.name, text), root, 255, 200, 20, true)
				end

				local receivedPlayers = {}
				for k, targetPlayer in pairs(getElementsByType("player")) do
					if targetPlayer ~= player then
						if targetPlayer:isLoggedIn() then
							receivedPlayers[#receivedPlayers+1] = targetPlayer
						end
					end
				end
				StatisticsLogger:getSingleton():addChatLog(player, "interview", text, receivedPlayers)
				return true
			end
		end
	end
end

function SanNews:Event_advertisement(senderIndex, text, color, duration)
	local length = text:len()
	if length <= 50 and length >= 5 then
		local durationExtra = (AD_DURATIONS[duration] - 20) * 2
		local colorMultiplicator = 1
		if color ~= "Schwarz" then
			colorMultiplicator = 2
		end

		local costs = (length*AD_COST_PER_CHAR + AD_COST + durationExtra) * colorMultiplicator

		if (client:getPlayTime() / 60) >= AD_MIN_PLAYTIME then
			if client:getBankMoney() >= costs then
				if self.m_NextAd < getRealTime().timestamp then
					client:transferBankMoney({self, nil, true}, costs, "San News Ad", "Company", "Ads")
					self.m_NextAd = getRealTime().timestamp + AD_DURATIONS[duration] + AD_BREAK_TIME
					StatisticsLogger:getSingleton():addAdvert(client, text)

					local sender = {referenz = "player", name = client:getName()}
					if senderIndex == 2 and client:getGroup() and client:getGroup():getName() then
						sender = {referenz = "group", name = client:getGroup():getName(), number = client:getGroup():getPhoneNumber()}
					elseif senderIndex == 3 and client:getFaction() and client:getFaction():getShortName() then
						sender = {referenz = "faction", name = client:getFaction():getShortName(), number = client:getFaction():getPhoneNumber()}
					elseif senderIndex == 4 and client:getCompany() and client:getCompany():getShortName() then
						sender = {referenz = "company", name = client:getCompany():getShortName(), number = client:getCompany():getPhoneNumber()}
					end

					triggerClientEvent("showAd", client, sender, text, color, duration)
				else
					local next = self.m_NextAd - getRealTime().timestamp
					client:sendError(_("Die nächste Werbung kann erst in %d Sekunden gesendet werden!", client, next))
				end
			else
				client:sendError(_("Du hast zu wenig Geld dabei! (%s$)", client, costs))
			end
		else
			client:sendError(_("Du benötigst dafür mindestens %d Spielstunden!", client, AD_MIN_PLAYTIME))
		end
	end
end

function SanNews:Event_toggleMessage()
	if self.m_SanNewsMessageEnabled then
		self.m_SanNewsMessageEnabled = false
		self:sendShortMessage(("%s hat /sannews deaktiviert!"):format(client:getName()))
	else
		self.m_SanNewsMessageEnabled = true
		self:sendShortMessage(("%s hat /sannews aktiviert!"):format(client:getName()))
	end
end

function SanNews:Event_startStreetrace()
	if PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "startStreetRace") then
		if not EventManager:getSingleton():isEvent(self.m_RunningEvent) then
			self.m_RunningEvent = EventManager:getSingleton():openRandomEvent()
			self:addLog(client, "Events", "hat ein Straßenrennen gestartet!")
		else
			client:sendError("Es läuft bereits ein Event!")
		end
	else
		client:sendError(_("Du bist nicht berechtigt ein Straßenrennen zu starten!", client))
	end
end

function SanNews:Event_addBlip(posX, posY, text)
	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "addBlip") then
		client:sendError("Du bist nicht berechtigt Marker zu erstellen!")
		return
	end

	local id = self:getId()
	local color = {companyColors[id].r, companyColors[id].g, companyColors[id].b}
	local blipName = ("San News - %s"):format(text or "Marker")
	local blip = Blip:new("Marker.png", posX, posY, root, 10000, color)
	blip:setDisplayText(blipName, BLIP_CATEGORY.Default)
	table.insert(self.m_Blips, blip)

	self:addLog(client, "Marker", ("hat einen Marker erstellt: %s"):format(blipName))
	--PlayerManager:getSingleton():sendShortMessage("Die San News hat einen Ort auf der Karte markiert!", ("San News - %s"):format(text or "Marker"), color, 15000)
end

function SanNews:Event_deleteBlips()
	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "addBlip") then
		client:sendError("Du bist nicht berechtigt Marker zu entfernen!")
		return
	end

	for _, blip in pairs(self.m_Blips) do
		blip:delete()
	end
	self.m_Blips = {}

	client:sendInfo("Alle Blips entfernt!")
end

function SanNews:Event_sanNewsMessage(player, cmd, ...)
	if self.m_SanNewsMessageEnabled then
		local argTable = {...}
		local msg = table.concat(argTable, " ")
		StatisticsLogger:getSingleton():addChatLog(player, "sannews", msg, self:getOnlinePlayers())
		self:sendMessage(("#9cff00[SanNews-Nachricht] %s: #FFFFFF%s"):format(player:getName(), msg), 255, 255 ,0, true)
		player:sendMessage(("#9cff00[Msg an Sannews]: #FFFFFF%s"):format(msg), 255, 255 ,0, true)
	else
		player:sendError(_("Die SanNews hat /sannews derzeit deaktiviert!", player))
	end
end