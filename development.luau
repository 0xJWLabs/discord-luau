local env = require("@self/.env")

local discordLuau = require("./packages/discord_luau/src")
local builders = require("./packages/builders/src")

print(builders.intents.new({ "Guilds", "GuildMessages" }):build())

local discordBot = discordLuau.Client.new({
	intents = { "Guilds", "GuildMessages" },
	reconnect = true,
	logLevel = "Info",
})

-- discordBot.onAllShardsReady:listen(function()
-- 	local channel = discordBot:getTextChannelAsync("1344070759722647654"):await():unwrapOk()

-- 	channel
-- 		:createMessageAsync({
-- 			content = `Example`,
-- 			attachments = {
-- 				{
-- 					content = "abc",
-- 					filename = "example.txt",
-- 				},
-- 			},
-- 		})
-- 		:await()
-- end)

discordBot:login(env.DISCORD_BOT_TOKEN):await()
