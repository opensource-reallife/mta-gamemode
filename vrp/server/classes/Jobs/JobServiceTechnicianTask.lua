-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Jobs/JobServiceTechnicianTask.lua
-- *  PURPOSE:     Super service technician task class
-- *
-- ****************************************************************************
JobServiceTechnicianTask = inherit(Object)

addEvent("serviceTechnicianQuestionsRetrieve", true)

function JobServiceTechnicianTask:constructor(player)
    local position = self:getRandomCoordinates()
    self.m_Marker = createMarker(position, "cylinder", 2, 255, 255, 0, 200, player)
    self.m_Blip = Blip:new("Marker.png", position.x, position.y, player, 9999)
    self.m_Blip:setColor(BLIP_COLOR_CONSTANTS.Red)
	self.m_Blip:setDisplayText(_"Kunde")
    self.m_Player = player

    addEventHandler("onMarkerHit", self.m_Marker, function(hitElement, matchingDimension)
        if player == hitElement and matchingDimension then
            local vehicle = hitElement:getOccupiedVehicle()
            if vehicle and vehicle == hitElement.jobVehicle then
                hitElement:triggerEvent("openServiceTechnicianQuestionGraphicUserInterface", self:getQuestionSet(hitElement))
                vehicle:setFrozen(true)
                vehicle:setFrozen(false)
            else
                hitElement:sendError(_("Du bist in keinem Jobfahrzeug!", hitelement))
            end
        end
    end)

    self.m_OnQuestionsAnsweredBind = bind(self.onQuestionsAnswered, self)
    addEventHandler("serviceTechnicianQuestionsRetrieve", player, self.m_OnQuestionsAnsweredBind)
end

function JobServiceTechnicianTask:destructor()
    self.m_Marker:destroy()
    self.m_Blip:delete()
    removeEventHandler("serviceTechnicianQuestionsRetrieve", self.m_Player, self.m_OnQuestionsAnsweredBind)
end

function JobServiceTechnicianTask:getRandomCoordinates()
    return Vector3(JobServiceTechnician:getSingleton().m_Positions[math.random(1, #JobServiceTechnician:getSingleton().m_Positions)])
end

function JobServiceTechnicianTask:getQuestionSet(player)
	return Randomizer:getRandomOf(Randomizer:get(1, 3), JobServiceTechnician:getSingleton().m_Questions)
end

function JobServiceTechnicianTask:onQuestionsAnswered(result)
    if source ~= client then return end
    if client ~= self.m_Player then return end
    if not result then return end

    local player = source
    local answerCount = #result
    local correctAnswers = 0
    local questions = JobServiceTechnician:getSingleton().m_Questions
    local playerLocale = player:getLocale()
    local answerMap = {}

    for _, questionData in pairs(questions) do
        local questionLocaleData = questionData[playerLocale]
        for _, answerData in pairs(questionLocaleData) do
            if type(answerData) == "table" and answerData[2] then
                answerMap[answerData[1]] = true
            end
        end
    end

    for _, answerPlayer in pairs(result) do
        if answerMap[answerPlayer] then
            correctAnswers = correctAnswers + 1
        end
    end

    if correctAnswers > 0 then
        local pay = math.floor((50 * JOB_PAY_MULTIPLICATOR * JobServiceTechnician:getSingleton():getMultiplicator()) * (Randomizer:get(90, 110) / 100) / answerCount * correctAnswers)
		local points = math.round(pay / 50 * JOB_EXTRA_POINT_FACTOR)
		player:givePoints(points)
		StatisticsLogger:getSingleton():addJobLog(player, "jobServiceTechnician", nil, pay, nil, nil, points)
		JobServiceTechnician:getSingleton().m_BankAccount:transferMoney({player, true}, pay, _("Servicetechniker-Job", player), "Job", "ServiceTechnician")
        if correctAnswers < answerCount then
            player:sendSuccess(_("Du konntest einen Teil der Probleme lösen! Kehre zum Büro zurück, um eine neue Aufgabe zu erhalten.", player))
        else
            player:sendSuccess(_("Du konntest alle Probleme lösen! Kehre zum Büro zurück, um eine neue Aufgabe zu erhalten.", player))
        end
    else
        player:sendError(_("Du konntest dem Kunden nicht helfen! Kehre zum Büro zurück, um eine neue Aufgabe zu erhalten.", player))
    end

    self.m_Marker:destroy()
    self.m_Marker = createMarker(932.00, -1723.53, 12.6, "cylinder", 2, 255, 255, 0, 200, player)
    self.m_Blip:delete()
    self.m_Blip = Blip:new("Marker.png", 932.00, -1723.53, player, 9999)
    self.m_Blip:setColor(BLIP_COLOR_CONSTANTS.Red)
	self.m_Blip:setDisplayText(_"Büro")

    addEventHandler("onMarkerHit", self.m_Marker, function(hitElement, matchingDimension)
        if player == hitElement and matchingDimension then
            local vehicle = hitElement:getOccupiedVehicle()
            if vehicle and vehicle == hitElement.jobVehicle then
                vehicle:setFrozen(true)
                vehicle:setFrozen(false)
                player:sendInfo(_("Du hast eine neue Aufgabe erhalten! Begib dich zur Markierung auf der Karte.", player))
                JobServiceTechnician:getSingleton():nextTask(player)
            else
                hitElement:sendError(_("Du bist in keinem Jobfahrzeug!", hitelement))
            end
        end
    end)
end