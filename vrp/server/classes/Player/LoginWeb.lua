addEvent("accountRegisterCheck", true)
addEventHandler("accountRegisterCheck", root, function(field, value)
	if client:getAccount() or type(field) ~= "string" or type(value) ~= "string" or #value > 50 then return end
	client.m_RegisterChecks = client.m_RegisterChecks or {}
	if client.m_RegisterChecks[field] and getTickCount() - client.m_RegisterChecks[field] < 250 then return end
	client.m_RegisterChecks[field] = getTickCount()

	local ok, code, extra = true, nil, nil
	if field == "name" then
		if not value:match("^[a-zA-Z0-9_.]*$") or #value < 3 or #value > 22 then
			ok, code = false, "name_invalid"
		elseif NameManager:getSingleton():isNameBlocked(value) then
			ok, code = false, "name_blocked"
		elseif sql:queryFetchSingle("SELECT Id FROM ??_account WHERE LCASE(Name) = LCASE(?)", sql:getPrefix(), value) then
			ok, code = false, "name_used"
		end
	elseif field == "email" then
		if not value:match("^[%w._-]+@[%w._-]+%.%w+$") then
			ok, code = false, "email_invalid"
		elseif Account.isEmailUsed(value) then
			ok, code = false, "email_used"
		else
			local player = client
			Account.checkEmailDomain(value, function(domainOk, domainCode)
				if isElement(player) then player:triggerEvent("receiveRegisterCheck", field, value, domainOk, domainCode) end
			end)
			return
		end
	elseif field == "ref" then
		local id, name = Account.getReferrer(value, client:getSerial())
		if id then
			extra = name
		else
			ok, code = false, name
		end
	else
		return
	end
	client:triggerEvent("receiveRegisterCheck", field, value, ok, code, extra)
end)

addEvent("accountPasswordCheck", true)
addEventHandler("accountPasswordCheck", root, function(sha1, seq)
	if client:getAccount() or type(sha1) ~= "string" or not sha1:match("^%x+$") or #sha1 ~= 40 then return end
	local player = client
	if player.m_LastPasswordCheck and getTickCount() - player.m_LastPasswordCheck < 500 then return end
	player.m_LastPasswordCheck = getTickCount()

	sha1 = sha1:upper()
	fetchRemote("https://api.pwnedpasswords.com/range/" .. sha1:sub(1, 5), {connectionAttempts = 1, headers = {["Add-Padding"] = "true"}}, function(data, info)
		if not isElement(player) then return end
		local count = -1
		if info and info.success and data then
			count = 0
			for suffix, amount in data:gmatch("(%x+):(%d+)") do
				if suffix:upper() == sha1:sub(6) then
					count = tonumber(amount)
					break
				end
			end
		end
		player:triggerEvent("receivePasswordCheck", seq, count)
	end)
end)

addEvent("accountPasswordForgot", true)
addEventHandler("accountPasswordForgot", root, function(who)
	if client:getAccount() or type(who) ~= "string" or #who < 3 or #who > 120 then return end
	local player = client
	if player.m_LastPasswordForgot and getTickCount() - player.m_LastPasswordForgot < 10000 then
		player:triggerEvent("receivePasswordForgot", false, 1)
		return
	end
	player.m_LastPasswordForgot = getTickCount()

	local secret = Config.get("CP_SECRET")
	if not secret or secret == "" then
		player:triggerEvent("receivePasswordForgot", false)
		return
	end
	jwtSign(function(token)
		if not token or not isElement(player) then return end
		fetchRemote(CP_WEB_PATH .. "/api_password_forgot.php", {method = "POST", connectionAttempts = 2, formFields = {token = token}}, function(data, info)
			if not isElement(player) then return end
			local result = info and info.success and fromJSON(data)
			if type(result) == "table" and result.ok then
				player:triggerEvent("receivePasswordForgot", true)
			else
				player:triggerEvent("receivePasswordForgot", false, type(result) == "table" and tonumber(result.wait) or nil)
			end
		end)
	end, {["who"] = who, ["ip"] = player:getIP(), ["aud"] = "cp-forgot", ["exp"] = getRealTime().timestamp + 300}, JWT_ALGORITHM_HS256, secret)
end)

addEvent("accountGuestTicket", true)
addEventHandler("accountGuestTicket", root, function(name, text, email, notify, oldSerial)
	if client:getAccount() or type(name) ~= "string" or type(text) ~= "string" or #text > 4000 then return end
	local player = client
	if player.m_LastGuestTicket and getTickCount() - player.m_LastGuestTicket < 30000 then
		player:triggerEvent("receiveGuestTicket", false, "wait", 1)
		return
	end
	player.m_LastGuestTicket = getTickCount()

	local secret = Config.get("CP_SECRET")
	if not secret or secret == "" then
		player:triggerEvent("receiveGuestTicket", false)
		return
	end
	jwtSign(function(token)
		if not token or not isElement(player) then return end
		fetchRemote(CP_WEB_PATH .. "/api_ticket_guest.php", {method = "POST", connectionAttempts = 2, formFields = {token = token}}, function(data, info)
			if not isElement(player) then return end
			local result = info and info.success and fromJSON(data)
			if type(result) == "table" and result.ok then
				player:triggerEvent("receiveGuestTicket", true, result.ref, result.code)
			else
				player.m_LastGuestTicket = nil
				player:triggerEvent("receiveGuestTicket", false, type(result) == "table" and result.error or nil, type(result) == "table" and tonumber(result.wait) or nil)
			end
		end)
	end, {["name"] = name, ["text"] = text, ["email"] = type(email) == "string" and email or "", ["notify"] = notify == true or notify == "true" or notify == "1", ["serial"] = player:getSerial(), ["old_serial"] = type(oldSerial) == "string" and oldSerial:sub(1, 64) or "", ["ip"] = player:getIP(), ["aud"] = "cp-ticket", ["exp"] = getRealTime().timestamp + 300}, JWT_ALGORITHM_HS256, secret)
end)

addEvent("accountSetEmail", true)
addEventHandler("accountSetEmail", root, function(email)
	local player = client
	local pending = player.m_PendingLogin
	if not pending or type(email) ~= "string" then return end
	email = email:gsub("^%s+", ""):gsub("%s+$", "")
	if not Account.isEmailValid(email) then
		player:triggerEvent("receiveSetEmail", false, "email_invalid")
		return
	end
	if Account.isEmailUsed(email) then
		player:triggerEvent("receiveSetEmail", false, "email_used")
		return
	end
	Account.checkEmailDomain(email, function(ok, code)
		if not isElement(player) or player.m_PendingLogin ~= pending then return end
		if not ok then
			player:triggerEvent("receiveSetEmail", false, code)
			return
		end
		sql:queryExec("UPDATE ??_account SET EMail = ? WHERE Id = ?", sql:getPrefix(), email, pending[1])
		Account.notifyCpEmail(pending[1], email)
		player.m_PendingLogin = nil
		player.m_EmailChecked = true
		player:triggerEvent("receiveSetEmail", true)
		Async.create(function() Account.loginSuccess(player, unpack(pending)) end)()
	end)
end)

function Account.notifyCpEmail(id, email)
	local secret = Config.get("CP_SECRET")
	if not secret or secret == "" then return end
	jwtSign(function(token)
		if not token then return end
		fetchRemote(CP_WEB_PATH .. "/api_email_set.php", {method = "POST", connectionAttempts = 2, formFields = {token = token}}, function() end)
	end, {["sub"] = id, ["email"] = email, ["aud"] = "cp-email-set", ["exp"] = getRealTime().timestamp + 300}, JWT_ALGORITHM_HS256, secret)
end