local Colors = require("./colors")

local function resolveColor(color: Colors.ColorResolvable): number?
	local resolvedColor

	if typeof(color) == "string" then
		if string.lower(color) == "random" then
			return math.floor(math.random() * (0xffffff + 1))
		end
		if color == "Default" then
			return 0
		end
		local hex = color:match("^#?([%da-fA-F][%da-fA-F][%da-fA-F])$")
			or color:match("^#?([%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F])$")

		if hex then
			if #hex == 3 then
				hex = hex:sub(1, 1):rep(2) .. hex:sub(2, 2):rep(2) .. hex:sub(3, 3):rep(2)
			end

			return tonumber(hex, 16) :: number
		end

		resolvedColor = Colors[color]
	elseif typeof(color) == "table" then
		resolvedColor = bit32.lshift(color[1], 16) + bit32.lshift(color[2], 8) + color[3]
	else
		resolvedColor = color
	end

	if resolvedColor and resolvedColor > 0 and resolvedColor <= 0xffffff then
		return resolvedColor
	end

	return nil
end

return resolveColor
