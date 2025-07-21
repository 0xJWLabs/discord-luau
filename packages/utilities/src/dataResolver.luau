local net = require("@lune/net")
local base64 = require("./base64")

local DataResolver = {}

function DataResolver.resolveBase64(data: string, content_type: string?)
	local contentType = content_type or "image/jpg"

	return `data:{content_type};base64,{base64.encode(data)}`
end

function DataResolver.resolveImage(image: string?, content_type: string?): string?
	if not image then
		return nil
	end
	if typeof(image) == "string" and string.sub(image, 1, 5) == "data:" then
		return image
	end

	local request = net.request({
		url = image,
		method = "GET",
		headers = {
			["Content-Type"] = content_type or "image/jpg",
		},
	})

	if request.ok then
		return DataResolver.resolveImage(request.body, content_type)
	end

	return nil
end

return DataResolver
