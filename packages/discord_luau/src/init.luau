local client = require("@self/client")

--[=[
	@class DiscordLuau

	Top level documentation for the Discord-Luau library, welcome! 👋

	This package will represent the entrypoint to your adventure using Discord-Luau, through this package you'll generate
	a discord Bot object, this bot Object enables you to write discord bots for the Discord API.

	```luau
	local DiscordLuau = require("/path/to/discord-luau") -- this module!

	-- do something with DiscordLuau
	```
]=]
local DiscordLuau = {}

--[=[
	@prop bot DiscordLuau.bot
	@within DiscordLuau
]=]
DiscordLuau.Client = client
export type Client = client.Client

return DiscordLuau
