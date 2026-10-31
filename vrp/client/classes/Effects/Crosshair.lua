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
	function(data)
		for kind in pairs(Crosshair.Textures) do
			local item = type(data) == "table" and data[kind]
			if type(item) ~= "table" or not item.url then
				Crosshair.reset(kind)
			elseif not (Crosshair.Active[kind] and Crosshair.Active[kind].hash == item.hash) then
				fetchRemote(item.url,
					function(pixels, errorCode)
						if errorCode == 0 then
							Crosshair.apply(kind, pixels, item.hash)
						end
					end
				)
			end
		end
	end
)
