local currentSide
local currentAnim

RegisterNetEvent("sidesaddle")

local function IsPedFullyOnMount(ped, p1)
	return Citizen.InvokeNative(0x95CBC65780DE7EB1, ped, p1)
end

local function isPlayingAnim(ped, anim)
	return IsEntityPlayingAnim(ped, anim.dict, anim.name, anim.flags)
end

local function playAnim(ped, anim)
	if not DoesAnimDictExist(anim.dict) then
		return
	end

	RequestAnimDict(anim.dict)

	while not HasAnimDictLoaded(anim.dict) do
		Citizen.Wait(0)
	end

	TaskPlayAnim(ped, anim.dict, anim.name, 1.0, 1.0, -1, anim.flags, 0.0, false, 0, false, "", false)

	RemoveAnimDict(anim.dict)
end

local function stopAnim(ped, anim)
	StopAnimTask(ped, anim.dict, anim.name, 1.0)
end

AddEventHandler("onResourceStop", function(resourceName)
	if GetCurrentResourceName() == resourceName then
		if currentAnim then
			stopAnim(PlayerPedId(), currentAnim)
		end
	end
end)

AddEventHandler("sidesaddle", function(side)
	currentSide = side

	if currentSide then
		SetResourceKvp("side", side)
	else
		stopAnim(PlayerPedId(), currentAnim)
		currentAnim = nil

		DeleteResourceKvp("side")
	end
end)

Citizen.CreateThread(function()
	currentSide = GetResourceKvpString("side")

	while true do
		local canWait = true

		if currentSide then
			local playerPed = PlayerPedId()

			if IsPedFullyOnMount(playerPed) then
				local mount = GetMount(playerPed)
				local speed = GetEntitySpeedVector(mount, true)

				local mountSpeed
				local mountTurn

				if speed.y < 2.0 then
					mountSpeed = "idle"
				elseif speed.y < 5.0 then
					if speed.z > Config.thresholdZ then
						mountSpeed = "cantern@slope@up"
					elseif speed.z < -Config.thresholdZ then
						mountSpeed = "cantern@slope@down"
					else
						mountSpeed = "cantern"
					end
				else
					if speed.z > Config.thresholdZ then
						mountSpeed = "gallop@slope@up"
					elseif speed.z < -Config.thresholdZ then
						mountSpeed = "gallop@slope@down"
					else
						mountSpeed = "gallop"
					end
				end

				if speed.y < 2.0 then
					mountTurn = "idle"
				elseif speed.x > Config.thresholdX then
					mountTurn = "turn_l2"
				elseif speed.x < -Config.thresholdX then
					mountTurn = "turn_r2"
				else
					mountTurn = "move"
				end

				currentAnim = {
					dict = ("veh_horseback@seat_rear@female@%s@normal@%s"):format(currentSide, mountSpeed),
					name = mountTurn,
					flags = 17
				}

				if currentAnim and not isPlayingAnim(playerPed, currentAnim) then
					playAnim(playerPed, currentAnim)
				end

				canWait = false
			elseif currentAnim then
				stopAnim(playerPed, currentAnim)
				currentAnim = nil
			end
		end

		Citizen.Wait(canWait and 1000 or 100)
	end
end)
