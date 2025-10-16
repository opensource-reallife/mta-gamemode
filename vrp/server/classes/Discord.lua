-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Discord.lua
-- *  PURPOSE:     Discord API-class
-- *
-- ****************************************************************************
Discord = inherit(Singleton) 

function Discord:constructor() 
end


function Discord:destructor() 

end

function Discord:outputBreakingNews( text ) 
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
