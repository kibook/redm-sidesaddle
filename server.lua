RegisterCommand("sidesaddle", function(source, args, raw)
	TriggerClientEvent("sidesaddle", source, args[1])
end, true)
