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
		theAds = {},
		theSettings = {
			AdsMainTimerObj = false,
			AdsMainTimer = 20,
			AdsActive = 1
		}
	}
	
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

	addRemoteEvents{"sanNewsStartInterview", "sanNewsStopInterview", "sanNewsAdvertisement", "sanNewsToggleMessage", "sanNewsStartStreetrace", "sanNewsAddBlip", "sanNewsDeleteBlips", "sanNewsSendAdDataToClient", "sanNewsGetAdDataFromClient", "sanNewsAdsSaveSettingsForCustomerFromClient", "sanNewsCreateNewCustomerFromClient", "sanNewsRemoveCustomerFromClient", "SanNewsAdsSearchPlayer", "SanNewsAdsSearchGroup", "sanNewsAdsRefreshCustomers", "sanNewsAdSettings"}
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

	addCommandHandler("news", bind(self.Event_news, self))
	addCommandHandler("sannews", bind(self.Event_sanNewsMessage, self), false, false)
end

function SanNews:destructor()

end

function SanNews:loadAllAdData()
	local result = sql:queryFetch("SELECT * FROM ??_sannewsads", sql:getPrefix())
	if not result then return end	-- ### Überflüssig? Was passiert bei fehlerhafter SQL-Abfrage?

	local adSettings = sql:queryFetch("SELECT * FROM ??_sannewssettings", sql:getPrefix())
	if not adSettings then return end	-- ### Überflüssig? Was passiert bei fehlerhafter SQL-Abfrage?

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

		self.m_SanNewsAds["theAds"][row.customerID] = {
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
			}
		} 
	end

	for k, row in pairs(adSettings) do
		if k == 1 then 
			self.m_SanNewsAds["theSettings"]["AdsMainTimer"] = tonumber(row.AdsMainTimer)
			self.m_SanNewsAds["theSettings"]["AdsActive"] = tonumber(row.AdsActive)
		end
	end
end

function SanNews:AdRefreshCustomers()
	if client then 
		if client:getCompany() ~= self then
        	return
    	end
		if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "editAds") then return end
		self.m_SanNewsAds["theAds"] = {}
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
		local intervalOptions = {5,10,15,20,30,60,120}

		for i = 1, #intervalOptions do 
			if data[1] == intervalOptions[i] then 
				self.m_SanNewsAds["theSettings"]["AdsMainTimer"] = data[1]
			end
		end

		if data[2] == 0 then 
			self.m_SanNewsAds["theSettings"]["AdsActive"] = 0
		elseif data[2] == 1 then 
			self.m_SanNewsAds["theSettings"]["AdsActive"] = 1
		else
			return 
		end

		sql:queryExec("UPDATE ??_sannewssettings SET AdsActive = ?, AdsMainTimer = ?", sql:getPrefix(), self.m_SanNewsAds["theSettings"]["AdsActive"], self.m_SanNewsAds["theSettings"]["AdsMainTimer"])

		client:sendSuccess(_("Änderungen gespeichert.", client))

		if self.m_SanNewsAds["theSettings"]["AdsActive"] == 0 then 
			if isTimer(self.m_SanNewsAds["theSettings"]["AdsMainTimerObj"]) then killTimer(self.m_SanNewsAds["theSettings"]["AdsMainTimerObj"]) end
		else
			self:InitTimeManagement()
		end

		self:AdsUpdateToClient()
	end
end

function SanNews:InitTimeManagement()
	if isTimer(self.m_SanNewsAds["theSettings"]["AdsMainTimerObj"]) then killTimer(self.m_SanNewsAds["theSettings"]["AdsMainTimerObj"]) end
	self.m_SanNewsAds["theSettings"]["AdsMainTimerObj"] = setTimer(function ()
		self:deliverAds()
	end, self.m_SanNewsAds["theSettings"]["AdsMainTimer"] * 60 * 1000, 0)
end

function SanNews:deliverAds()
	if self.m_SanNewsAds["theSettings"]["AdsActive"] == 0 then return end

	if AdminEventManager:getSingleton():isEventRunning() then return end

	if table.size(self.m_SanNewsAds["theAds"]) <= 0 then
		return
	end

	local whereActive = {}
	for k, Ad in pairs(self.m_SanNewsAds["theAds"]) do 
		if self.m_SanNewsAds["theAds"][k]["isActive"] then 
			table.insert(whereActive, self.m_SanNewsAds["theAds"][k]["customerID"])
		end
	end
	if #whereActive < 1 then return end

	local currentPlayerCount = 0
	local playersInEnglish = {}
	local playersInGerman = {}
	for k, player in pairs(getElementsByType("player")) do 
		if player:getLocale() == "en" then 
			table.insert(playersInEnglish, player)
		end
		if player:getLocale() == "de" then 
			table.insert(playersInGerman, player)
		end
		currentPlayerCount = currentPlayerCount + 1
	end

	local whereEnoughPlayersOnline = {}
	for k, Ad in pairs(whereActive) do 
		if currentPlayerCount >= self.m_SanNewsAds["theAds"][Ad]["minPlayersOnlineToDeliverAds"] then 
			table.insert(whereEnoughPlayersOnline, self.m_SanNewsAds["theAds"][Ad]["customerID"])
		end
	end
	if #whereEnoughPlayersOnline < 1 then return end

	local theTime = getRealTime()
	local hours = theTime.hour 
	local minutes = theTime.minute 
	local seconds = theTime.second
	local year = theTime.year 
	local month = theTime.month
	local monthDay = theTime.monthday

	local whereInsideTimeframe = {}
	for k, Ad in pairs(whereEnoughPlayersOnline) do 
		local startTime1 = self.m_SanNewsAds["theAds"][Ad]["adStartTimeEveryDay"]
		local endTime1 = self.m_SanNewsAds["theAds"][Ad]["adEndTimeEveryDay"]
		
		if startTime1 == endTime1 then 
			table.insert(whereInsideTimeframe, self.m_SanNewsAds["theAds"][Ad]["customerID"])
		elseif startTime1 < endTime1 then 
			if startTime1 <= hours and endTime1 > hours then 
				table.insert(whereInsideTimeframe, self.m_SanNewsAds["theAds"][Ad]["customerID"])
			end
		elseif startTime1 > endTime1 then 
			if startTime1 <= hours and hours < 24 then 
				table.insert(whereInsideTimeframe, self.m_SanNewsAds["theAds"][Ad]["customerID"])
			elseif hours < endTime1 and hours >= 0 then 
				table.insert(whereInsideTimeframe, self.m_SanNewsAds["theAds"][Ad]["customerID"])
			elseif endTime == 0 and hours == 23 then 
				table.insert(whereInsideTimeframe, self.m_SanNewsAds["theAds"][Ad]["customerID"])
			else 
			end
		else
		end
	end
	if #whereInsideTimeframe < 1 then return end

	local currentDate = string.format("%04d-%02d-%02d", year+1900, month+1, monthDay)
	local whereMaxPerDayLimitNotReached = {}
	for k, Ad in pairs(whereInsideTimeframe) do 
		if currentDate ~= self.m_SanNewsAds["theAds"][Ad]["lastDeliveryDate"] then 
			self.m_SanNewsAds["theAds"][Ad]["deliveredThisDay"] = 0
		end
		if self.m_SanNewsAds["theAds"][Ad]["maxPerDay"] > self.m_SanNewsAds["theAds"][Ad]["deliveredThisDay"] then
			table.insert(whereMaxPerDayLimitNotReached, self.m_SanNewsAds["theAds"][Ad]["customerID"])
		end 
	end
	if #whereMaxPerDayLimitNotReached < 1 then return end

	local finalAdCandidates = {}
	for k, Ad in pairs(whereMaxPerDayLimitNotReached) do 
		if self.m_SanNewsAds["theAds"][Ad]["moneyPerAd"] == 0 then
			table.insert (finalAdCandidates, self.m_SanNewsAds["theAds"][Ad]["customerID"])
		elseif self.m_SanNewsAds["theAds"][Ad]["customerType"] == "Company" then
			local theCustomerObj = CompanyManager:getSingleton():getFromId(self.m_SanNewsAds["theAds"][Ad]["customerUniqueID"])
			if not theCustomerObj then return end		-- if-exists-Abfrage überflüssig? ###
			if theCustomerObj:getMoney() >= self.m_SanNewsAds["theAds"][Ad]["moneyPerAd"] then 
				table.insert(finalAdCandidates, self.m_SanNewsAds["theAds"][Ad]["customerID"])
			end
		elseif self.m_SanNewsAds["theAds"][Ad]["customerType"] == "Faction" then 
			local theCustomerObj = FactionManager:getSingleton():getFromId(self.m_SanNewsAds["theAds"][Ad]["customerUniqueID"])
			if not theCustomerObj then return end		-- if-exists-Abfrage überflüssig? ###
			if theCustomerObj:getMoney() >= self.m_SanNewsAds["theAds"][Ad]["moneyPerAd"] then 
				table.insert(finalAdCandidates, self.m_SanNewsAds["theAds"][Ad]["customerID"])
			end
		elseif self.m_SanNewsAds["theAds"][Ad]["customerType"] == "Group" then 
			local theCustomerObj = GroupManager:getSingleton():getFromId(self.m_SanNewsAds["theAds"][Ad]["customerUniqueID"])
			if not theCustomerObj then return end		-- if-exists-Abfrage überflüssig? ###
			if theCustomerObj:getMoney() >= self.m_SanNewsAds["theAds"][Ad]["moneyPerAd"] then 
				table.insert(finalAdCandidates, self.m_SanNewsAds["theAds"][Ad]["customerID"])
			end
		elseif self.m_SanNewsAds["theAds"][Ad]["customerType"] == "Player" then
			local currentPlayerMoney = BankAccount.loadByOwner(self.m_SanNewsAds["theAds"][Ad]["customerUniqueID"], 1):getMoney()
			if not currentPlayerMoney then return end		-- if-exists-Abfrage überflüssig? ###
			if currentPlayerMoney >= self.m_SanNewsAds["theAds"][Ad]["moneyPerAd"] then 
				table.insert(finalAdCandidates, self.m_SanNewsAds["theAds"][Ad]["customerID"])
			end
		else
		end
	end
	if #finalAdCandidates < 1 then return end 

	math.randomseed(os.time())
	math.random(); math.random();

	local randomAdToBeDeliveredRandomizer = math.random(#finalAdCandidates)
	local randomAdToBeDelivered = finalAdCandidates[randomAdToBeDeliveredRandomizer]

	self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["lastDeliveryDate"] = string.format("%04d-%02d-%02d", year+1900, month+1, monthDay)
	self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["lastDeliveryTime"] = string.format("%02d:%02d:%02d", hours, minutes, seconds)
	self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["timesDelivered"] = self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["timesDelivered"] + 1
	self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["deliveredThisDay"] = self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["deliveredThisDay"] + 1
	sql:queryExec("UPDATE ??_sannewsads SET lastDeliveryDate = ?, lastDeliveryTime = ?, timesDelivered = ?, deliveredThisDay = ? WHERE customerID = ?", sql:getPrefix(), self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["lastDeliveryDate"], self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["lastDeliveryTime"], self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["timesDelivered"], self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["deliveredThisDay"], randomAdToBeDelivered)
	
	if self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["moneyPerAd"] ~= 0 then 
		local theRecipient = "San News"
		local sanNewsObj = CompanyManager:getSingleton():getFromName(theRecipient) and CompanyManager:getSingleton():getFromName(theRecipient):getId() or false
		if not sanNewsObj then return end		-- if-exists-Abfrage überflüssig? ###
		local sanNewsBankAccount = BankAccount.loadByOwner(sanNewsObj, 3)
		if not sanNewsBankAccount then return end 		-- if-exists-Abfrage überflüssig? ###

		local customerBankAccount
		if self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["customerType"] == "Company" then 
			customerBankAccount = BankAccount.loadByOwner(self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["customerUniqueID"], 3)
		elseif self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["customerType"] == "Faction" then 
			if self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["customerUniqueID"] == 1 or self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["customerUniqueID"] == 2 or self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["customerUniqueID"] == 3 then
				customerBankAccount = FactionState:getSingleton().m_BankAccountServer
			else
				customerBankAccount = BankAccount.loadByOwner(self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["customerUniqueID"], 2)
			end
			customerBankAccount = BankAccount.loadByOwner(self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["customerUniqueID"], 2)
		elseif self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["customerType"] == "Group" then
			customerBankAccount = BankAccount.loadByOwner(self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["customerUniqueID"], 8)
		elseif self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["customerType"] == "Player" then
			customerBankAccount = BankAccount.loadByOwner(self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["customerUniqueID"], 1)
		else
			return
		end

		customerBankAccount:transferMoney(sanNewsBankAccount, self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["moneyPerAd"], self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["customerName"], "San News", "Werbung")
		customerBankAccount:save()
		sanNewsBankAccount:save()

		-- ### Transfer loggen oder wird es automatisch geloggt?
	end

	local adLinesToShowInGerman = {}
	local adLinesToShowInEnglish = {}
	local adLinesInGerman = 0
	local adLinesInEnglish = 0
	local endOfGermanAds = false 
	local endOfEnglishAds = false

	for k, v in ipairs(self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["adText"]) do
		if v ~= "" then 
			table.insert(adLinesToShowInGerman, v)
			adLinesInGerman = adLinesInGerman + 1
		end
	end
	
	for k, v in ipairs(self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["adTextEN"]) do
		if v ~= "" then 
			table.insert(adLinesToShowInEnglish, v)
			adLinesInEnglish = adLinesInEnglish + 1
		end
	end

	local adLanguageFallback = false 
	if adLinesInEnglish <= 0 then 
		adLanguageFallback = true 
	end

	triggerClientEvent(root, "sanNewsAdsSound", root)

	outputChatBox("#FFFFFF▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁", root, 255, 200, 20, true)
	outputChatBox("#FFFFFFWerbung │ #67D68E" .. self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["customerName"], playersInGerman, 255, 200, 20, true)
	outputChatBox("#FFFFFFAd │ #67D68E" .. self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["customerName"], playersInEnglish, 255, 200, 20, true)
	outputChatBox("#FFFFFF▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔", root, 255, 200, 20, true)

	if adLinesInGerman <= 0 and adLinesInEnglish <= 0 then return end

	local currentAdDeliveredLines = 1

	if isTimer(adDeliveryTimer) then killTimer(adDeliveryTimer) end
	local adDeliveryTimer = setTimer(function ()
		if adLinesInGerman >= currentAdDeliveredLines then 
			outputChatBox("#67D68E" .. adLinesToShowInGerman[currentAdDeliveredLines], playersInGerman, 255, 200, 20, true)
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
				outputChatBox("#67D68E" .. adLinesToShowInGerman[currentAdDeliveredLines], playersInEnglish, 255, 200, 20, true)
			end
		else
			if adLinesInEnglish >= currentAdDeliveredLines then 
				outputChatBox("#67D68E" .. adLinesToShowInEnglish[currentAdDeliveredLines], playersInEnglish, 255, 200, 20, true)
			end
			if adLinesInEnglish < currentAdDeliveredLines and endOfEnglishAds == false then
				outputChatBox("#FFFFFF▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁", playersInEnglish, 255, 200, 20, true)
				endOfEnglishAds = true
			end
		end
		currentAdDeliveredLines = currentAdDeliveredLines + 1
	end, self.m_SanNewsAds["theAds"][randomAdToBeDelivered]["deliveringSpeed"] * 1000, 6)
end

function SanNews:AdsUpdateToClient()
	if client then 
		if client:getCompany() ~= self then
        	return
    	end
		if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "editAds") then return end
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
				self.m_SanNewsAds["theAds"][customerID]["adText"][k] = table["DE"][k]
			else
				return 
			end
		end
		
		for k, v in ipairs(table["EN"]) do 
			if string.len(table["EN"][k]) <= 240 then 
				self.m_SanNewsAds["theAds"][customerID]["adTextEN"][k] = table["EN"][k]
			else
				return 
			end
		end

		-- ### More sanitization?

		local jsonAdText = toJSON(self.m_SanNewsAds["theAds"][customerID]["adText"])
		local jsonAdTextEN = toJSON(self.m_SanNewsAds["theAds"][customerID]["adTextEN"])

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
		for k,v in pairs(self.m_SanNewsAds["theAds"]) do 
			if self.m_SanNewsAds["theAds"][k]["customerID"] > currentNumberOfEntries then 
				currentNumberOfEntries = self.m_SanNewsAds["theAds"][k]["customerID"]
			end
		end
		
		local newCustomerID
		if currentNumberOfEntries == 0 then 
			newCustomerID = 1
		else
			local currentLastEntry = self.m_SanNewsAds["theAds"][currentNumberOfEntries]["customerID"]
			newCustomerID = currentLastEntry + 1
		end 

		local preparedAdText = {
			[1] = "fdg",
			[2] = "dfg",
			[3] = "dfg",
			[4] = "dfg",
			[5] = "dfg"
		}
		local preparedAdTextEN = {
			[1] = "",
			[2] = "",
			[3] = "",
			[4] = "",
			[5] = ""
		}

		local jsonAdText = toJSON(preparedAdText)
		local jsonAdTextEN = toJSON(preparedAdTextEN)
		
		self.m_SanNewsAds["theAds"][newCustomerID] = {
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
			}
		}

		local aa = fromboolean(self.m_SanNewsAds["theAds"][newCustomerID]["isActive"])
		sql:queryExec("INSERT INTO ??_sannewsads (customerID, customerName, minPlayersOnlineToDeliverAds, deliveringSpeed, isActive, moneyPerAd, adStartTimeEveryDay, adEndTimeEveryDay, adText, adTextEN, lastDeliveryDate, lastDeliveryTime, timesDelivered, customerType, customerUniqueID, maxPerDay, deliveredThisDay) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", sql:getPrefix(), self.m_SanNewsAds["theAds"][newCustomerID]["customerID"], self.m_SanNewsAds["theAds"][newCustomerID]["customerName"], self.m_SanNewsAds["theAds"][newCustomerID]["minPlayersOnlineToDeliverAds"], self.m_SanNewsAds["theAds"][newCustomerID]["deliveringSpeed"], aa, self.m_SanNewsAds["theAds"][newCustomerID]["moneyPerAd"], self.m_SanNewsAds["theAds"][newCustomerID]["adStartTimeEveryDay"], self.m_SanNewsAds["theAds"][newCustomerID]["adEndTimeEveryDay"], jsonAdText, jsonAdTextEN, self.m_SanNewsAds["theAds"][newCustomerID]["lastDeliveryDate"], self.m_SanNewsAds["theAds"][newCustomerID]["lastDeliveryTime"], self.m_SanNewsAds["theAds"][newCustomerID]["timesDelivered"], self.m_SanNewsAds["theAds"][newCustomerID]["customerType"], self.m_SanNewsAds["theAds"][newCustomerID]["customerUniqueID"], self.m_SanNewsAds["theAds"][newCustomerID]["maxPerDay"], self.m_SanNewsAds["theAds"][newCustomerID]["deliveredThisDay"])

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
		if self.m_SanNewsAds["theAds"][id]["customerID"] == id then 
			self.m_SanNewsAds["theAds"][id] = nil 
			sql:queryExec("DELETE FROM ??_sannewsads WHERE customerID = ?", sql:getPrefix(), id)
			self:AdsUpdateToClient()
		else 
			return
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

		local minPlayerChangerOptions = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,25,30}
		local speedOfDeliveryChangerOptions = {1,2,3,4,5}
		local timeChangerOptions = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23}
		local maxPerDayChangerOptions = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}

		for k,v in pairs(sendTable) do
			if not sendTable[k]["custID"] then return end
			if sendTable[k]["custID"] == nil then return end
			if not self.m_SanNewsAds["theAds"][sendTable[k]["custID"]] then return end

			local customerID = sendTable[k]["custID"]
			
			if sendTable[k]["isActive"] == true or sendTable[k]["isActive"] == false then 
				self.m_SanNewsAds["theAds"][customerID]["isActive"] = sendTable[k]["isActive"]
			end

			if tonumber(sendTable[k]["moneyPerAd"]) ~= nil then
				if tonumber(sendTable[k]["moneyPerAd"]) >= 0 then 
					self.m_SanNewsAds["theAds"][customerID]["moneyPerAd"] = tonumber(sendTable[k]["moneyPerAd"])
				end
			end
			
			if tonumber(sendTable[k]["minPlayersOnlineToDeliverAds"]) ~= nil then
				for i = 1, #minPlayerChangerOptions do 
					if sendTable[k]["minPlayersOnlineToDeliverAds"] == minPlayerChangerOptions[i] then 
						self.m_SanNewsAds["theAds"][customerID]["minPlayersOnlineToDeliverAds"] = tonumber(sendTable[k]["minPlayersOnlineToDeliverAds"])
					end
				end
			end
			
			if tonumber(sendTable[k]["deliveringSpeed"]) ~= nil then
				for i = 1, #speedOfDeliveryChangerOptions do 
					if sendTable[k]["deliveringSpeed"] == speedOfDeliveryChangerOptions[i] then 
						self.m_SanNewsAds["theAds"][customerID]["deliveringSpeed"] = tonumber(sendTable[k]["deliveringSpeed"])
					end
				end
			end
			
			if tonumber(sendTable[k]["adStartTimeEveryDay"]) ~= nil then
				for i = 1, #timeChangerOptions do 
					if sendTable[k]["adStartTimeEveryDay"] == timeChangerOptions[i] then 
						self.m_SanNewsAds["theAds"][customerID]["adStartTimeEveryDay"] = tonumber(sendTable[k]["adStartTimeEveryDay"])
					end
				end
			end

			if tonumber(sendTable[k]["adEndTimeEveryDay"]) ~= nil then
				for i = 1, #timeChangerOptions do 
					if sendTable[k]["adEndTimeEveryDay"] == timeChangerOptions[i] then 
						self.m_SanNewsAds["theAds"][customerID]["adEndTimeEveryDay"] = tonumber(sendTable[k]["adEndTimeEveryDay"])
					end
				end
			end

			if tonumber(sendTable[k]["maxPerDay"]) ~= nil then
				for i = 1, #maxPerDayChangerOptions do 
					if sendTable[k]["maxPerDay"] == maxPerDayChangerOptions[i] then 
						self.m_SanNewsAds["theAds"][customerID]["maxPerDay"] = tonumber(sendTable[k]["maxPerDay"])
					end
				end
			end

			local aa
			if self.m_SanNewsAds["theAds"][customerID]["isActive"] then 
				aa = 1
			else
				aa = 0
			end
			
			sql:queryExec("UPDATE ??_sannewsads SET isActive = ?, moneyPerAd = ?, minPlayersOnlineToDeliverAds = ?, deliveringSpeed = ?, adStartTimeEveryDay = ?, adEndTimeEveryDay = ?, maxPerDay = ? WHERE customerID = ?", sql:getPrefix(), aa, self.m_SanNewsAds["theAds"][customerID]["moneyPerAd"], self.m_SanNewsAds["theAds"][customerID]["minPlayersOnlineToDeliverAds"], self.m_SanNewsAds["theAds"][customerID]["deliveringSpeed"], self.m_SanNewsAds["theAds"][customerID]["adStartTimeEveryDay"], self.m_SanNewsAds["theAds"][customerID]["adEndTimeEveryDay"], self.m_SanNewsAds["theAds"][customerID]["maxPerDay"], customerID)
		
			client:sendSuccess(_("Änderungen gespeichert.", client))
		end
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

function SanNews:onBarrierHit(player)
    if player:getCompany() ~= self then
        return false
    end
    return true
end

function SanNews:Event_news(player, cmd, ...)
	if player:getCompany() == self then
		if player:isCompanyDuty() then
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
function tranlsate(player, string)
	if player:getLocale() == "de" then
		return string
	end

	return translations[string] or string
end