-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Jobs/JobTreasureSeeker.lua
-- *  PURPOSE:     JobTreasureSeeker job
-- *
-- ****************************************************************************
JobTreasureSeeker = inherit(Job)

function JobTreasureSeeker:constructor()
	Job.constructor(self)
	self.m_BankAccount = BankServer.get("job.treasure_seeker")
	local availableVehicles = {"Reefer"}
	self.m_VehicleSpawner = VehicleSpawner:new(715.41, -1706.50, 1.3, availableVehicles, 135, bind(Job.requireVehicle, self))
	self.m_VehicleSpawner:setSpawnPosition(Vector3(719.79, -1705.18, -0.34), 180)
	self.m_VehicleSpawner:disable()
	self.m_VehicleSpawner.m_Hook:register(bind(self.onVehicleSpawn,self))
	self.m_TakeUpBind = bind(self.takeUp, self)
	self.m_DropBind = bind(self.drop, self)

	self.m_Treasures = {}
	self.m_Vehicles = {}
	self.m_IsTakingUp = {}
	self.m_IsDropping = {}

	self.m_DeliverMarker = createMarker(725.30, -1692.62, -1, "cylinder", 7, 0, 0, 255, 200)
	addEventHandler("onMarkerHit", self.m_DeliverMarker, bind(self.onDeliveryHit, self))
	setElementVisibleTo(self.m_DeliverMarker, root, false)

	self.m_TreasureTypes = {
		[1208] = {["Name"] = "eine Waschmaschine", ["Min"] = 0, ["Max"] = 50, ["Offset"] = -0.9},
		[2912] = {["Name"] = "eine Holzkiste", ["Min"] = 50, ["Max"] = 150, ["Offset"] = -0.9},
		[1291] = {["Name"] = "einen Briefkasten", ["Min"] = 25, ["Max"] = 75, ["Offset"] = -0.9},
		[2972] = {["Name"] = "eine Kiste", ["Min"] = 50, ["Max"] = 150, ["Offset"] = -0.9},
		[3015] = {["Name"] = "eine Waffenkiste", ["Min"] = 150, ["Max"] = 300, ["Scale"] = 2, ["Offset"] = -0.9},
		[3046] = {["Name"] = "ein radioaktives Fass", ["Min"] = 0, ["Max"] = 1000, ["Offset"] = -0.4},
		[1429] = {["Name"] = "einen Fernseher", ["Min"] = 0, ["Max"] = 50, ["Scale"] = 1.5, ["Offset"] = -0.4},
		[1224] = {["Name"] = "eine große Holzkiste", ["Min"] = 100, ["Max"] = 250, ["Offset"] = -0.6},
		[1328] = {["Name"] = "eine Mülltonne", ["Min"] = 25, ["Max"] = 75, ["Offset"] = -0.45},
		[1236] = {["Name"] = "einen Recyclingcontainer", ["Min"] = 75, ["Max"] = 150, ["Offset"] = -0.7},
		[3013] = {["Name"] = "eine Munitionskiste", ["Min"] = 150, ["Max"] = 300, ["Scale"] = 4, ["Offset"] = -0.48},
		[3633] = {["Name"] = "ein paar Ölfässer", ["Min"] = 500, ["Max"] = 750, ["Offset"] = -0.5},
		[1353] = {["Name"] = "eine Klimaanlage", ["Min"] = 0, ["Max"] = 75, ["Offset"] = -0.6},
		[2727] = {["Name"] = "ein Ladenschild", ["Min"] = 100, ["Max"] = 300, ["Offset"] = -0.1},
	}
end

function JobTreasureSeeker:start(player)
	self:generateRandomTreasures(player)
	bindKey(player, "space", "down", self.m_TakeUpBind)
	--bindKey(player, "backspace", "down", self.m_DropBind)
	setElementVisibleTo(self.m_DeliverMarker, player, true)
	self.m_VehicleSpawner:toggleForPlayer(player, true)
end

function JobTreasureSeeker:checkRequirements(player)
	if not (player:getJobLevel() >= JOB_LEVEL_TREASURESEEKER) then
		player:sendError(_("Für diesen Job benötigst du mindestens Joblevel %d", player, JOB_LEVEL_TREASURESEEKER))
		return false
	end
	return true
end

function JobTreasureSeeker:stop(player)
	if player.jobVehicle and isElement(player.jobVehicle) then
		if player.jobVehicle.Engine and isElement(player.jobVehicle.Engine) then
			player.jobVehicle.Engine:detach()
			player.jobVehicle.Engine:destroy()
		end
		if player.jobVehicle.Magnet.Object and isElement(player.jobVehicle.Magnet.Object) then
			player.jobVehicle.Magnet.Object:detach()
			player.jobVehicle.Magnet.Object:destroy()
		end
		if player.jobVehicle.Magnet and isElement(player.jobVehicle.Magnet) then
			player.jobVehicle.Magnet:detach()
			player.jobVehicle.Magnet:destroy()
		end
	end
	nextframe(function() self:destroyJobVehicle(player) end)
	self:removeTreasures(player)
	unbindKey(player, "space", "down", self.m_TakeUpBind)
	--unbindKey(player, "backspace", "down", self.m_DropBind)
	setElementVisibleTo(self.m_DeliverMarker, player, false)
	self.m_VehicleSpawner:toggleForPlayer(player, false)
	self.m_IsTakingUp[player] = false 
	self.m_IsDropping[player] = false
end

function JobTreasureSeeker:onVehicleSpawn(player, vehicleModel, vehicle)
	setVehicleHandling(vehicle, "steeringLock", 70)

	vehicle.Engine = createObject(3013, 0, 0, 0)
	vehicle.Engine:setScale(1.5)
	vehicle.Engine:attach(vehicle, 0, -6.2, 3.5)

	vehicle.Magnet = createObject(1301, 0, 0, 0)
	vehicle.Magnet:setScale(0.5)
	vehicle.Magnet:attach(vehicle, 0, -6.2, 2)

	self:registerJobVehicle(player, vehicle, true, true)

	triggerClientEvent(root, "jobTreasureDrawRope", root, vehicle.Engine, vehicle.Magnet)
	player.m_LastJobAction = getRealTime().timestamp
end

function JobTreasureSeeker:onDeliveryHit(hitElement, dim)
	if dim and hitElement:getType() == "player" then
		if hitElement:getJob() == self then
			if hitElement:getOccupiedVehicle() and hitElement:getOccupiedVehicle() == hitElement.jobVehicle then
				local veh = hitElement:getOccupiedVehicle()
				if veh.Magnet and isElement(veh.Magnet) then
					if veh.Magnet.Object and isElement(veh.Magnet.Object) then
						local model = veh.Magnet.Object:getModel()
						if not self.m_TreasureTypes[model] then return end
						local loan = math.random(self.m_TreasureTypes[model]["Min"], self.m_TreasureTypes[model]["Max"]) * JOB_PAY_MULTIPLICATOR * self:getMultiplicator()
						local duration = getRealTime().timestamp - hitElement.m_LastJobAction
						local points = math.floor(5*JOB_EXTRA_POINT_FACTOR)
						hitElement.m_LastJobAction = getRealTime().timestamp
						StatisticsLogger:getSingleton():addJobLog(hitElement, "jobTreasureSeeker", duration, loan, nil, nil, points)
						self.m_BankAccount:transferMoney({hitElement, true}, loan, "Schatzsucher-Job", "Job", "TreasureSeeker")  --// default loan not loan*2
						hitElement:sendShortMessage(_("Du hast %s für %d$ verkauft!", hitElement, _(self.m_TreasureTypes[model]["Name"], hitElement), loan))
						hitElement:getOccupiedVehicle().Magnet.Object:destroy()
						hitElement:givePoints(points)
						self:loadTreasure(hitElement)
						veh:setFrozen(true)
						veh:setRotation(0, 0, 180)
						veh:setFrozen(false)
					else
						hitElement:sendError(_("Du hast kein Objekt dabei!", hitElement))
					end
				else
					hitElement:sendError(_("Du benutzt ein falsches Boot!", hitElement))
				end
			else
				hitElement:sendError(_("Du bist im falschen Fahrzeug!", hitElement))
			end
		end
	end
end

function JobTreasureSeeker:generateRandomTreasures(player)
	if not self.m_Treasures[player] then
		self.m_Treasures[player] = {}
	end

	for i = 1, 5 do
		self:loadTreasure(player)
	end
end

function JobTreasureSeeker:takeUp(player, key, keyState)
	local veh = player:getOccupiedVehicle()
	if veh and veh == player.jobVehicle and not self.m_IsTakingUp[player] and not self.m_IsDropping[player] then
		if veh:getSpeed() <= 3 then
			for index, col in pairs(self.m_Treasures[player]) do
				if col and isElement(col) and player:isWithinColShape(col) then
					if veh.Magnet and veh.Magnet.Object and isElement(veh.Magnet.Object) then
						player:sendError(_("Du hast bereits ein Objekt am Schiff!\nLade es erst am Startpunkt ab!", player))
						return
					end
					self.m_IsTakingUp[player] = true
					player:sendShortMessage(_("Das gefundene Objekt wird angehoben! Bitte warten!", player))
					local objectModel = self:getRandomTreasureModel()
					veh:setFrozen(true)
					veh.Magnet:detach(veh)

					local matrix = veh.matrix
					local newPos = matrix:transformPosition(Vector3(0, -6.2, 2))
					veh.Magnet:setPosition(newPos)
					veh.Magnet:move(15000, newPos.x, newPos.y, newPos.z-15)

					veh.Magnet.Object = createObject(objectModel, newPos.x, newPos.y, newPos.z-100)
					veh.Magnet.Object:setCollisionsEnabled(false)
					if self.m_TreasureTypes[objectModel]["Scale"] then veh.Magnet.Object:setScale(self.m_TreasureTypes[objectModel]["Scale"]) end

					setTimer(function()
						if isElement(veh) then
							local x, y, z = getElementPosition(veh.Magnet)
							veh.Magnet.Object:attach(veh.Magnet, 0, 0, self.m_TreasureTypes[objectModel]["Offset"])
							veh.Magnet:move(15000, x, y, z+15)
						end
					end, 15000, 1)

					setTimer(function()
						if isElement(veh) then
							veh.Magnet:attach(veh, 0, -6.2, 2)
							player:sendShortMessage(_("Du hast %s gefunden!\nBringe das Fundstück zum Startpunkt!", player, _(self.m_TreasureTypes[objectModel]["Name"], player)), _("Schatzsucher-Job", player))
							veh:setFrozen(false)
							self.m_IsTakingUp[player] = false
						end
					end, 30000, 1)

					if col.DummyObject and isElement(col.DummyObject) then col.DummyObject:destroy() end
					if isElement(col) then col:destroy() end
					table.remove(self.m_Treasures[player], index)
					return
				end
			end
			player:sendError(_("Hier ist kein Objekt!", player))
		else
			player:sendError(_("Das Boot muss dafür stillstehen!", player))
		end
	end
end

function JobTreasureSeeker:drop(player, key, keyState)
	local veh = player:getOccupiedVehicle()
	if veh and veh == player.jobVehicle then
		if veh.Magnet and isElement(veh.Magnet) then
			if veh.Magnet.Object and isElement(veh.Magnet.Object) then
				if not self.m_IsTakingUp[player] and not self.m_IsDropping[player] then
					self.m_IsDropping[player] = true
					local model = veh.Magnet.Object:getModel()
					if not self.m_TreasureTypes[model] then return end
					player.m_LastJobAction = getRealTime().timestamp
					veh.Magnet.Object:detach()
					veh.Magnet.Object:setFrozen(true)
					local x, y, z = getElementPosition(veh.Magnet.Object)
					veh.Magnet.Object:move(1000, x, y, z-10)
					setTimer(function()
						if isElement(veh) then
							veh.Magnet.Object:destroy()
							player:sendInfo(_("Du hast das Objekt zurück ins Meer geworfen!", player))
							self:loadTreasure(player)
							self.m_IsDropping[player] = false
						end
					end, 1000, 1)
				end
			else
				player:sendError(_("Du hast kein Objekt dabei!", player))
			end
		else
			player:sendError(_("Du benutzt ein falsches Boot!", player))
		end
	else
		player:sendError(_("Du bist im falschen Fahrzeug!", player))
	end
end

function JobTreasureSeeker:loadTreasure(player)
	local x, y = math.random(JobTreasureSeeker.Positions[1][1], JobTreasureSeeker.Positions[2][1]), math.random(JobTreasureSeeker.Positions[1][2], JobTreasureSeeker.Positions[2][2])

	local colShape = createColCircle(x, y, 25)
	colShape.DummyObject = createObject(1337, x, y, -20)
	colShape.Player = player

	table.insert(self.m_Treasures[player], colShape)
	setElementData(colShape.DummyObject, "Treasure", player)
	addEventHandler("onColShapeHit", colShape, bind(self.onTreasureHit, self))
end

function JobTreasureSeeker:getRandomTreasureModel()
	local models = {}
	for modelId, key in pairs(self.m_TreasureTypes) do
		table.insert(models, modelId)
	end
	return models[math.random(1, #models)]
end

function JobTreasureSeeker:removeTreasures(player)
	if not self.m_Treasures[player] then return end
	for i, col in ipairs(self.m_Treasures[player]) do
		if col.DummyObject and isElement(col.DummyObject) then col.DummyObject:destroy() end
		if isElement(col) then col:destroy() end
	end

	self.m_Treasures[player] = nil
end

function JobTreasureSeeker:onTreasureHit(hitElement, dim)
	if dim and hitElement == source.Player then
		if hitElement:getOccupiedVehicle() and hitElement:getOccupiedVehicle() == hitElement.jobVehicle then
			hitElement:sendInfo(_("Der Radar registriert ein Objekt unter dir!\nDrücke Leertaste um es hochzuheben!", hitElement))
		end
	end
end

JobTreasureSeeker.Positions = {
	{450, -2552},
	{877, -2111},
}
