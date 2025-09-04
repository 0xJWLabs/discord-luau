local serde = require("@lune/serde")
local json = require("./json")

return {
	encode = function(format: "json" | "toml" | "yaml", value: any, pretty: boolean?): string
		return format == "json" and json.serialize(value, pretty) or serde.encode(format, value, pretty)
	end,
	decode = function(format: "json" | "toml" | "yaml", value: buffer | string): any
		return format == "json" and json.deserialize(value :: string) or serde.decode(format, value)
	end,
	compress = serde.compress,
	decompress = serde.decompress,
}
