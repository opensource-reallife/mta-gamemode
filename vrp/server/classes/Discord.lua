-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Discord.lua
-- *  PURPOSE:     Discord API-class
-- *
-- ****************************************************************************
Discord = inherit(Singleton) 

function Discord:constructor()
	-- Meldungen zusätzlich loggen (ControlPanel → Übersicht „Breaking News“), auch im Debug-Modus ohne Discord
	sqlLogs:queryExec("CREATE TABLE IF NOT EXISTS ??_BreakingNews (Id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY, Type VARCHAR(16) NOT NULL, Text VARCHAR(500) NOT NULL, Date DATETIME NOT NULL, KEY TypeDate (Type, Date))", sqlLogs:getPrefix())
end

-- Discord-Erwähnungen von Rollen (<@&Id>) im Log durch das Kürzel der Fraktion ersetzen
function Discord:logNews(newsType, text)
	local clean = tostring(text):gsub("<@&(%d+)>", function(roleId)
		for _, faction in pairs(FactionManager.Map or {}) do
			if tostring(faction.m_DiscordRole) == roleId then return faction.m_Name_Short or faction:getName() end
		end
		return "?"
	end)
	sqlLogs:queryExec("INSERT INTO ??_BreakingNews (Type, Text, Date) VALUES (?, ?, NOW())", sqlLogs:getPrefix(), newsType, clean:sub(1, 500))
end


function Discord:destructor() 

end

function Discord:outputBreakingNews( text ) 
	self:logNews("action", text)
	if not DEBUG then
		local postData = 
		{
			queueName = "Discord Breaking-News",
			connectionAttempts = 3,
			connectTimeout = 5000,
			formFields = 
			{
				content=text,
				username="Breaking News",
			},
		}
		fetchRemote ( Config.get("DISCORD_WEBHOOK_URL"), postData, function() end )
	else 
		outputDebugString("Discord Breaking-News was not sent ( Debug-Mode )", 3)
	end
end

function Discord:outputGangwarNews( text )
	self:logNews("gangwar", text)
	if not DEBUG then
		local postData = 
		{
			queueName = "Discord Gangwar-Notifications",
			connectionAttempts = 3,
			connectTimeout = 5000,
			formFields = 
			{
				content=text,
				username="Gangwar Notifications",
			},
		}
		fetchRemote ( Config.get("DISCORD_WEBHOOK_URL_GW"), postData, function() end )
	else 
		outputDebugString("Discord Gangwar-Notification was not sent ( Debug-Mode )", 3)
	end
end
