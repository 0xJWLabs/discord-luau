local net = require("@lune/net")
local base64 = require("./base64")
local fs = require("@lune/fs")

type ResolvedFile = {
	data: string,
	contentType: string?,
}

local DataResolver = {}

function DataResolver.resolveFile(resource: string): ResolvedFile?
	if typeof(resource) == "string" then
		if string.match(resource, "^https?://") then
			local res = net.request({
				method = "GET",
				url = resource,
			})

			if res.ok then
				return { data = res.body, contentType = res.headers["content-type"] :: string }
			end

			error(`Data Resolver: {res.statusMessage} ({res.statusCode})\n{res.body}`)

			return nil
		else
			if not fs.isFile(resource) then
				error("File not found")
			end

			return { data = fs.readFile(resource) }
		end
	end

	return nil
end

function DataResolver.resolveBase64(resource: string?, content_type: string?): string?
	if resource then
		local contentType = content_type and string.lower(content_type) or "image/jpg"
		return `data:{contentType};base64,{base64.encode(resource)}`
	end

	return resource
end

function DataResolver.resolveImage(image: string?, content_type: string?): string?
	if not image or typeof(image) ~= "string" then
		return nil
	end
	if typeof(image) == "string" and string.sub(image, 1, 5) == "data:" then
		return image
	end

	local file = DataResolver.resolveFile(image)
	return file and DataResolver.resolveBase64(file.data, file.contentType) or nil
end

return DataResolver
