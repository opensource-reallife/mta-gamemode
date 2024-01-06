-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Jobs/JobServiceTechnician.lua
-- *  PURPOSE:     Service technician job class
-- *
-- ****************************************************************************
JobServiceTechnician = inherit(Job)

function JobServiceTechnician:constructor()
    Job.constructor(self)
	self.m_BankAccount = BankServer.get("job.service_technician")
    self.m_Tasks = { }

	self.m_VehicleSpawner = VehicleSpawner:new(931.86, -1715.1, 12.6, {413}, 90, bind(Job.requireVehicle, self))
	self.m_VehicleSpawner.m_Hook:register(bind(self.onVehicleSpawn, self))
	self.m_VehicleSpawner:disable()

    self.m_Questions = { }
    local result = sql:queryFetch("SELECT * FROM ??_job_servicetechnician_questions", sql:getPrefix())
	for i, row in pairs(result) do
		self.m_Questions[row.Id] = {
            ["de"] = {
                row.Question,
                {row.CorrectAnswer, true},
                {row.FalseAnswer1, false},
                {row.FalseAnswer2, false},
                {row.FalseAnswer3, false}
            },
            ["en"] = {
                row.Question_EN,
                {row.CorrectAnswer_EN, true},
                {row.FalseAnswer1_EN, false},
                {row.FalseAnswer2_EN, false},
                {row.FalseAnswer3_EN, false}
            }
        }
    end

    self.m_Positions = {
        {929.06, -1499.16, 12.60},
        {970.35, -1481.99, 12.60},
        {789.48, -1427.52, 12.55},
        {683.81, -1413.40, 12.57},
        {507.46, -1372.28, 15.13},
        {438.70, -1311.48, 14.13},
        {294.27, -1422.25, 13.03},
        {315.81, -1621.64, 32.37},
        {457.21, -1500.12, 30.05},
        {1041.35, -946.01, 41.81},
        {1143.62, -1251.15, 13.81},
        {1279.38, -1308.96, 12.35},
        {1543.36, -1168.58, 23.08},
        {1790.93, -1166.09, 22.83},
        {2241.30, -1317.43, 22.98},
        {2388.71, -1540.81, 23.00},
        {2569.54, -1490.86, 24.02},
        {2481.14, -1748.76, 12.55},
        {2227.48, -1996.55, 12.55},
        {1971.64, -2019.55, 12.55},
    }
end

function JobServiceTechnician:start(player)
    player:sendInfo(_("Job angenommen! Gehe zum roten Marker um ein Fahrzeug zu erhalten.", player))
    self.m_VehicleSpawner:toggleForPlayer(player, true)
end

function JobServiceTechnician:stop(player)
    self.m_VehicleSpawner:toggleForPlayer(player, false)
    self:destroyJobVehicle(player)
    if self.m_Tasks[player] then self.m_Tasks[player]:delete() end
end

function JobServiceTechnician:onVehicleSpawn(player,vehicleModel,vehicle)
	self:registerJobVehicle(player, vehicle, true, true)
    self:nextTask(player)
    player:sendInfo(_("Begib dich nun zum Kunden. Folge dazu der Markierung auf der Karte.", player))
end

function JobServiceTechnician:nextTask(player)
    if self.m_Tasks[player] then self.m_Tasks[player]:delete() end
    self.m_Tasks[player] = JobServiceTechnicianTask:new(player)
end