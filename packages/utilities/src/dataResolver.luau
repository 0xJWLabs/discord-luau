local net = require("@lune/net")
local base64 = require("./base64")

local DataResolver = {}

function DataResolver.resolveImage(image: string?, content_type: string?): string?
	if not image or typeof(image) ~= "string" then
		return nil
	end
	if typeof(image) == "string" and string.sub(image, 1, 5) == "data:" then
		return image
	end

	local req = net.request({
		method = "GET",
		headers = {
			["Content-Type"] = content_type or "image/png",
		},
		url = image,
	})

	if req.ok then
		return `data:{content_type or "image/png"};base64,{base64.encode(req.body)}`
	else
		warn(`Data Resolver: {req.statusMessage}`)
		warn(`Data Resolver: {req.statusCode}`)
		warn(`Data Resolver: {req.body}`)
	end

	return nil
end

return DataResolver
