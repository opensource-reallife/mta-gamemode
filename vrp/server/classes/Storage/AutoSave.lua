AutoSave = inherit(Singleton)
AutoSave.Interval = 5 * 60 * 1000
AutoSave.BatchSize = 25

function AutoSave:constructor()
	self.m_Queue = {}
	setTimer(bind(self.start, self), AutoSave.Interval, 0)
end

function AutoSave:add(object, method)
	self.m_Queue[#self.m_Queue + 1] = {object, method}
end

function AutoSave:start()
	if self.m_Timer then return end

	for _, player in pairs(getElementsByType("player")) do
		self:add(player, function(player) if isElement(player) and player:isLoggedIn() then player:save() end end)
	end

	for _, faction in pairs(FactionManager.Map) do
		self:add(faction, function(faction) if faction.m_BankAccount then faction.m_BankAccount:save() end faction:save() end)
	end

	for _, company in pairs(CompanyManager.Map) do
		self:add(company, function(company) if company.m_BankAccount then company.m_BankAccount:save() end company:save() end)
	end

	for _, group in pairs(GroupManager.Map) do
		self:add(group, Group.save)
	end

	for _, row in pairs(BankServer.Map) do
		self:add(row[3], BankAccount.save)
	end

	for _, house in pairs(HouseManager.Map) do
		self:add(house, House.save)
	end

	for _, shop in pairs(ShopManager.Map) do
		self:add(shop, function(shop) shop:save() end)
	end

	for _, shop in pairs(ShopManager.VehicleShopsMap) do
		self:add(shop, function(shop) shop:save() end)
	end

	for _, plant in pairs(GrowableManager.Map) do
		self:add(plant, Growable.save)
	end

	local vehicleManager = VehicleManager:getSingleton()
	for _, owners in pairs({vehicleManager.m_FactionVehicles, vehicleManager.m_CompanyVehicles, vehicleManager.m_GroupVehicles}) do
		for _, vehicles in pairs(owners) do
			for _, vehicle in pairs(vehicles) do
				self:add(vehicle, function(vehicle) if isElement(vehicle) then vehicle:save() end end)
			end
		end
	end

	self.m_Timer = setTimer(bind(self.process, self), 50, 0)
end

function AutoSave:process()
	for i = 1, AutoSave.BatchSize do
		local job = table.remove(self.m_Queue)
		if not job then
			killTimer(self.m_Timer)
			self.m_Timer = nil
			return
		end

		local success, err = pcall(job[2], job[1])
		if not success then
			outputDebugString("AutoSave: " .. tostring(err), 1)
		end
	end
end
