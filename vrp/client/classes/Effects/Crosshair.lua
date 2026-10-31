Crosshair = {Textures = {normal = "siteM16", sniper = "SNIPERcrosshair"}, Active = {}}

function Crosshair.reset(kind)
	local active = Crosshair.Active[kind]
	if active then
		engineRemoveShaderFromWorldTexture(active.shader, Crosshair.Textures[kind])
		destroyElement(active.shader)
		destroyElement(active.texture)
		Crosshair.Active[kind] = nil
	end
end

function Crosshair.apply(kind, pixels, hash)
	local texture = dxCreateTexture(pixels, "argb", false, "clamp")
	local shader = texture and dxCreateShader("files/shader/texreplace.fx")
	if not shader then
		if texture then destroyElement(texture) end
		return
	end
	Crosshair.reset(kind)
	dxSetShaderValue(shader, "gTexture", texture)
	engineApplyShaderToWorldTexture(shader, Crosshair.Textures[kind])
	Crosshair.Active[kind] = {shader = shader, texture = texture, hash = hash}
end

addRemoteEvents{"crosshairApply"}
addEventHandler("crosshairApply", root,
	function(kind, hash, pixels)
		if not Crosshair.Textures[kind] then return end
		if not pixels then
			Crosshair.reset(kind)
		elseif not (Crosshair.Active[kind] and Crosshair.Active[kind].hash == hash) then
			Crosshair.apply(kind, pixels, hash)
		end
	end
)
