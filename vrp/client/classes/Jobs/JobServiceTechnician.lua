-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Jobs/JobServiceTechnician.lua
-- *  PURPOSE:     Service technician job class
-- *
-- ****************************************************************************
JobServiceTechnician = inherit(Job)

function JobServiceTechnician:constructor()
    Job.constructor(self, 156, 940.95, -1717.69, 13.96, 90, "ServiceTechnician.png", {173, 216, 230}, "files/images/Jobs/HeaderServiceTechnician.png", _(HelpTextTitles.Jobs.ServiceTechnician):gsub("Job: ", ""), _(HelpTexts.Jobs.ServiceTechnician), LexiconPages.JobServiceTechnician)
    self:setJobLevel(JOB_LEVEL_SERVICETECHNICIAN)
end

function JobServiceTechnician:start()
    -- Show text in help menu
	HelpBar:getSingleton():setLexiconPage(LexiconPages.JobServiceTechnician)
end

function JobServiceTechnician:stop()
    -- Reset text in help menu
    HelpBar:getSingleton():setLexiconPage(nil)
end
