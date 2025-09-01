local Colors = require("./colors")

local function resolveColor(color: Colors.ColorResolvable): number?
	local resolvedColor

	if typeof(color) == "string" then
		local lowerColor = string.lower(color)
		if lowerColor == "random" then
			return math.floor(math.random() * (0xffffff + 1))
		end
		if lowerColor == "default" then
			return 0
		end

		local hex = lowerColor:match("^(#?)(%x+)$")
		if hex then
			local hexValue = hex:gsub(".", function(char)
				return #hex == 3 and char .. char or char
			end)
			return tonumber(hexValue, 16)
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
