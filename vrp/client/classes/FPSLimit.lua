FPSLimit = inherit(Singleton)

function FPSLimit:constructor()
	self:apply()
end

function FPSLimit:getMax()
	local limit = tonumber(resourceRoot:getData("ServerFPSLimit")) or 65
	if limit <= 0 then
		return 240
	end
	return math.max(limit, 65)
end

function FPSLimit:apply()
	local maxLimit = self:getMax()
	local limit = math.clamp(65, tonumber(core:get("HUD", "fpsLimitChoice", maxLimit)) or maxLimit, maxLimit)
	setFPSLimit(limit)
	return limit
end

function FPSLimit:choose(limit)
	local maxLimit = self:getMax()
	limit = math.clamp(65, math.floor(limit + 0.5), maxLimit)
	core:set("HUD", "fpsLimitChoice", limit < maxLimit and limit or nil)
	return self:apply()
end
