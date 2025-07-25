local future = require("../luau_packages/future")
local stdPolyfills = require("../lune_packages/std_polyfills")
local apiTypes = require("../lune_packages/api_types")
local state = require("../lune_packages/state")
local rest = require("../lune_packages/rest")
local logger = require("../lune_packages/logger")
local emitter = require("../luau_packages/emitter")
local classes = require("../lune_packages/classes")
local builders = require("../lune_packages/builders")

local DISCORD_VERSION = 10

--[=[
	@class DiscordLuau.Client
	@__index Prototype

	Top level documentation for the Discord-Luau library, welcome! 👋

	This package will represent the entrypoint to your adventure using Discord-Luau, through this package you'll generate
	a discord Client object, this client Object enables you to write discord bots for the Discord API.

	```luau
	local DiscordLuau = require("/path/to/discord-luau")
	local Client = DiscordLuau.Client -- This module!

	local discordClient = Client.new({
		token = env.DISCORD_BOT_TOKEN,
		reconnect = env.IS_PRODUCTION,
		intents = 513, -- Guild, GuildMessages
	})

	discordBot:login(env.DISCORD_BOT_TOKEN):await()

	print(`Client has connected: '{discordClient.user.username}'`)
	```
]=]
local Client = {}

Client.Interface = {}
Client.Prototype = {}

--[=[
	@within DiscordLuau.Client

	Queries the Discord Gateway for bot information.
	
	This function sends a request to the Discord Gateway to retrieve information
	about the bot, such as the recommended number of shards and session start limit.
]=]
function Client.Prototype.queryGatewayInformation(self: Client): future.FutureLike<string, apiTypes.GetGatewayBotResponse>
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.gateway.getGatewayBotAsync(request):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk()
	end) :: future.FutureLike<string, apiTypes.GetGatewayBotResponse>
end

--[=[
	@within DiscordLuau.Client

	Connects the bot to the Discord gateway asynchronously.

	This function performs the following steps:
	1. Queries gateway information
	2. Asserts that the query was successful
	3. Connects to the WebSocket using the obtained gateway information

	Returns a async that resolves when the connection is established.
]=]
function Client.Prototype.login(self: Client, token: string): future.FutureLike<string, nil>
  self.state:setToken(token)
	return future.Future.new(function()
		local gatewayInformation = self:queryGatewayInformation():await()

		assert(gatewayInformation:isOk(), gatewayInformation:unwrapErr())

		self.state.webSocketManager.onAllShardsReady:listen(function(data)
			local application = classes.application.application.new(self.state, data.payload.d.application)
			local user = classes.user.new(data.payload.d.user)

			self.application = application
			self.user = user

			self.state:setApplicationId(application.id)

			self.onAllShardsReady:invoke()
		end)

		self.state.webSocketManager.onDispatch:listen(function(object: {
			shardId: number,
			event: apiTypes.ReceiveEvent,
			payload: apiTypes.Payload<unknown>,
		})
			if object.event == apiTypes.gateway.receiveEvents["Ready"] then
				self.onReady:invoke(object.shardId)
			elseif object.event == apiTypes.gateway.receiveEvents["MessageCreate"] then
				local typedObject = object.payload :: apiTypes.MessageCreatePayload

				self.onMessage:invoke(classes.message.message.new(self.state, typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["MessageUpdate"] then
				local typedObject = object.payload :: apiTypes.MessageUpdatePayload

				self.onMessageChanged:invoke(classes.message.message.new(self.state, typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["MessageDelete"] then
				local typedObject = object.payload :: apiTypes.MessageDeletePayload

				self.onMessageDeleted:invoke({
					messageId = typedObject.d.id,
					channelId = typedObject.d.channel_id,
					guildId = typedObject.d.guild_id,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["MessageDeleteBulk"] then
				local typedObject = object.payload :: apiTypes.MessageDeleteBulkPayload

				self.onMessageBulkDeleted:invoke({
					channelId = typedObject.d.channel_id,
					guildId = typedObject.d.guild_id,
					ids = typedObject.d.ids,
				})
			elseif object.event == apiTypes.gateway.receiveEvents["ChannelCreate"] then
				local typedObject = object.payload :: apiTypes.CreateChannelPayload

				self.state.cache.channels:set(typedObject.d.id :: apiTypes.Snowflake, typedObject.d)

				if typedObject.d.type == 0 then
					self.onTextChannelCreate:invoke(classes.channels.types.guildText.new(self.state, typedObject.d))
				elseif typedObject.d.type == 1 then
					self.onDMChannelCreate:invoke(classes.channels.types.dm.new(self.state, typedObject.d))
				elseif typedObject.d.type == 2 then
					self.onVoiceChannelCreate:invoke(classes.channels.types.guildVoice.new(self.state, typedObject.d))
				elseif typedObject.d.type == 3 then
					self.onGroupDMChannelCreate:invoke(classes.channels.types.groupDm.new(self.state, typedObject.d))
				elseif typedObject.d.type == 4 then
					self.onCategoryChannelCreate:invoke(
						classes.channels.types.guildCategory.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 5 then
					self.onAnnouncementChannelCreate:invoke(
						classes.channels.types.guildAnnouncement.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 13 then
					self.onStageVoiceChannelCreate:invoke(
						classes.channels.types.guildStageVoice.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 14 then
					self.onDirectoryChannelCreate:invoke(
						classes.channels.types.guildDirectory.new(self.state, typedObject.d)
					)
				end
			elseif object.event == apiTypes.gateway.receiveEvents["ChannelUpdate"] then
				local typedObject = object.payload :: apiTypes.UpdateChannelPayload

				self.state.cache.channels:set(typedObject.d.id :: apiTypes.Snowflake, typedObject.d)

				if typedObject.d.type == 0 then
					self.onTextChannelUpdated:invoke(classes.channels.types.guildText.new(self.state, typedObject.d))
				elseif typedObject.d.type == 1 then
					self.onDMChannelUpdated:invoke(classes.channels.types.dm.new(self.state, typedObject.d))
				elseif typedObject.d.type == 2 then
					self.onVoiceChannelUpdated:invoke(classes.channels.types.guildVoice.new(self.state, typedObject.d))
				elseif typedObject.d.type == 3 then
					self.onGroupDMChannelUpdated:invoke(classes.channels.types.groupDm.new(self.state, typedObject.d))
				elseif typedObject.d.type == 4 then
					self.onCategoryChannelUpdated:invoke(
						classes.channels.types.guildCategory.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 5 then
					self.onAnnouncementChannelUpdated:invoke(
						classes.channels.types.guildAnnouncement.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 13 then
					self.onStageVoiceChannelUpdated:invoke(
						classes.channels.types.guildStageVoice.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 14 then
					self.onDirectoryChannelUpdated:invoke(
						classes.channels.types.guildDirectory.new(self.state, typedObject.d)
					)
				end
			elseif object.event == apiTypes.gateway.receiveEvents["ChannelDelete"] then
				local typedObject = object.payload :: apiTypes.DeleteChannelPayload

				if typedObject.d.type == 0 then
					self.onTextChannelDeleted:invoke(classes.channels.types.guildText.new(self.state, typedObject.d))
				elseif typedObject.d.type == 1 then
					self.onDMChannelDeleted:invoke(classes.channels.types.dm.new(self.state, typedObject.d))
				elseif typedObject.d.type == 2 then
					self.onVoiceChannelDeleted:invoke(classes.channels.types.guildVoice.new(self.state, typedObject.d))
				elseif typedObject.d.type == 3 then
					self.onGroupDMChannelDeleted:invoke(classes.channels.types.groupDm.new(self.state, typedObject.d))
				elseif typedObject.d.type == 4 then
					self.onCategoryChannelDeleted:invoke(
						classes.channels.types.guildCategory.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 5 then
					self.onAnnouncementChannelDeleted:invoke(
						classes.channels.types.guildAnnouncement.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 13 then
					self.onStageVoiceChannelDeleted:invoke(
						classes.channels.types.guildStageVoice.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 14 then
					self.onDirectoryChannelDeleted:invoke(
						classes.channels.types.guildDirectory.new(self.state, typedObject.d)
					)
				end
			elseif object.event == apiTypes.gateway.receiveEvents["ChannelPinsUpdate"] then
				local typedObject = object.payload :: apiTypes.ChannelPinsUpdatePayload

				self.onChannelPinsUpdate:invoke({
					channelId = typedObject.d.channel_id,
					guildId = typedObject.d.guild_id,
					lastPinTimestamp = typedObject.d.last_pin_timestamp
						and stdPolyfills.datetime.fromIsoDate(typedObject.d.last_pin_timestamp),
				})
			elseif object.event == apiTypes.gateway.receiveEvents["UserUpdate"] then
				local typedObject = object.payload :: apiTypes.UserUpdatePayload

				self.state.cache.users:set(typedObject.d.id :: apiTypes.Snowflake, typedObject.d)

				self.onUserUpdated:invoke(classes.user.new(typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["GuildCreate"] then
				local typedObject = object.payload :: apiTypes.GuildCreatePayload

				if typedObject.d.unavailable then
					self.onGuildCreate:invoke(
						classes.guild.unavailableGuild.new(self.state, typedObject.d.id :: string)
					)
				else
					-- fixme: using 'any' below because otherwise typedObject.d doesn't work with apiTypes.GuildObject?
					local guildData = typedObject.d :: any

					self.state.cache.guilds:set(typedObject.d.id :: apiTypes.Snowflake, guildData)

					self.onGuildCreate:invoke(classes.guild.guild.new(self.state, guildData))
				end
			elseif object.event == apiTypes.gateway.receiveEvents["GuildUpdate"] then
				local typedObject = object.payload :: apiTypes.GuildUpdatePayload

				self.state.cache.guilds:set(typedObject.d.id :: apiTypes.Snowflake, typedObject.d)

				self.onGuildUpdate:invoke(classes.guild.guild.new(self.state, typedObject.d))
			elseif object.event == apiTypes.gateway.receiveEvents["GuildDelete"] then
				local typedObject = object.payload :: apiTypes.GuildDeletePayload

				self.onGuildDelete:invoke(classes.guild.unavailableGuild.new(self.state, typedObject.d.id))
			elseif object.event == apiTypes.gateway.receiveEvents["GuildBanAdd"] then
				local typedObject = object.payload :: apiTypes.GuildBanAddPayload

				self.state.cache.users:set(typedObject.d.user.id :: apiTypes.Snowflake, typedObject.d.user)

				self.onGuildMemberBanned:invoke({
					guildId = typedObject.d.guild_id,
					user = classes.user.new(typedObject.d.user),
				})
			elseif object.event == apiTypes.gateway.receiveEvents["GuildBanRemove"] then
				local typedObject = object.payload :: apiTypes.GuildBanRemovePayload

				self.state.cache.users:set(typedObject.d.user.id :: apiTypes.Snowflake, typedObject.d.user)

				self.onGuildMemberUnbanned:invoke({
					guildId = typedObject.d.guild_id,
					user = classes.user.new(typedObject.d.user),
				})
			elseif object.event == apiTypes.gateway.receiveEvents["GuildMemberAdd"] then
				local typedObject = object.payload :: apiTypes.GuildMemberAddPayload

				self.onGuildMemberJoined:invoke({
					guildId = typedObject.d.guild_id,
					member = classes.guild.member.new(self.state, typedObject.d.guild_id, typedObject.d),
				})
			elseif object.event == apiTypes.gateway.receiveEvents["GuildMemberRemove"] then
				local typedObject = object.payload :: apiTypes.GuildMemberRemovePayload

				self.onGuildMemberLeft:invoke({
					guildId = typedObject.d.guild_id,
					user = classes.user.new(typedObject.d.user),
				})
			elseif object.event == apiTypes.gateway.receiveEvents["GuildMemberUpdate"] then
				local typedObject = object.payload :: apiTypes.GuildMemberUpdatePayload

				self.onGuildMemberUpdated:invoke({
					guildId = typedObject.d.guild_id,
					roles = typedObject.d.roles,
					user = classes.user.new(typedObject.d.user),
					nick = typedObject.d.nick,
					avatar = typedObject.d.avatar,
					joinedAt = typedObject.d.joined_at and stdPolyfills.datetime.fromIsoDate(typedObject.d.joined_at),
					premiumSince = typedObject.d.premium_since
						and stdPolyfills.datetime.fromIsoDate(typedObject.d.premium_since),
					deaf = typedObject.d.deaf,
					mute = typedObject.d.mute,
					pending = typedObject.d.pending,
					communicationDisabledUntil = typedObject.d.communication_disabled_until
						and stdPolyfills.datetime.fromIsoDate(typedObject.d.communication_disabled_until),
				})
			elseif object.event == apiTypes.gateway.receiveEvents["InteractionCreate"] then
				local typedObject = object.payload :: apiTypes.InteractionCreatePayload

				if typedObject.d.type == 1 then
					self.onPingInteraction:invoke(classes.interaction.types.ping.new(self.state, typedObject.d))
				elseif typedObject.d.type == 2 then
					self.onCommandInteraction:invoke(classes.interaction.types.command.new(self.state, typedObject.d))
				elseif typedObject.d.type == 3 then
					self.onComponentInteraction:invoke(
						classes.interaction.types.component.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 4 then
					self.onAutocompleteInteraction:invoke(
						classes.interaction.types.autocomplete.new(self.state, typedObject.d)
					)
				elseif typedObject.d.type == 5 then
					self.onModalInteraction:invoke(classes.interaction.types.modal.new(self.state, typedObject.d))
				else
					error(`Unknown interaction type: {typedObject.d.type}`)
				end
			end
		end)

		self.state.webSocketManager:connectAsync(gatewayInformation:unwrapOk()):poll()
		self.state.webSocketManager.onConnected:wait()

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within DiscordLuau.Client

	Returns the classes.guild object for the given id. If with_counts is set to true, this endpoint will also return
	approximate_member_count and approximate_presence_count for the classes.guild.
]=]
function Client.Prototype.getGuildAsync(
	self: Client,
	guildId: string,
	withCount: boolean?
): future.FutureLike<string, classes.Guild>
	return future.Future.new(function()
		local cachedGuildData = self.state.cache.guilds:get(guildId)

		if cachedGuildData then
			return classes.guild.guild.new(self.state, cachedGuildData)
		end

		local request = self.state.rest:newRequest()

		local response = rest.guild
			.getGuildAsync(request, guildId, {
				withCounts = withCount,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return classes.guild.guild.new(self.state, response:unwrapOk())
	end) :: future.FutureLike<string, classes.Guild>
end

--[=[
	@within DiscordLuau.Client

	Returns a channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a channel.
	The channel type is determined by the generic type parameter T.
]=]
function Client.Prototype.getChannelAsync<T>(self: Client, channelId: string): future.FutureLike<string, classes.Channel>
	return future.Future.new(function()
		local cachedChannelIdData = self.state.cache.channels:get(channelId)

		if cachedChannelIdData then
			return classes.channels.construct(self.state, cachedChannelIdData) :: any
		end

		local request = self.state.rest:newRequest()

		local response = rest.channel.getChannelAsync(request, channelId):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return classes.channels.construct(self.state, response:unwrapOk()) :: any
	end) :: future.FutureLike<string, classes.Channel>
end

--[=[
	@within DiscordLuau.Client

	Returns a DM channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a DM channel.
]=]
function Client.Prototype.getDMChannelAsync(self: Client, channelId: string): future.FutureLike<string, classes.DM>
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.DM>
end

--[=[
	@within DiscordLuau.Client

	Returns a Group DM channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a Group DM channel.
]=]
function Client.Prototype.getGroupDMChannelAsync(self: Client, channelId: string): future.FutureLike<string, classes.GroupDM>
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.GroupDM>
end

--[=[
	@within DiscordLuau.Client

	Returns an announcement channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about an announcement channel.
]=]
function Client.Prototype.getAnnouncementChannelAsync(
	self: Client,
	channelId: string
): future.FutureLike<string, classes.GuildAnnouncement>
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.GuildAnnouncement>
end

--[=[
	@within DiscordLuau.Client

	Returns a category channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a category channel.
]=]
function Client.Prototype.getCategoryChannelAsync(
	self: Client,
	channelId: string
): future.FutureLike<string, classes.GuildCategory>
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.GuildCategory>
end

--[=[
	@within DiscordLuau.Client

	Returns a directory channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a directory channel.
]=]
function Client.Prototype.getDirectoryChannelAsync(
	self: Client,
	channelId: string
): future.FutureLike<string, classes.GuildDirectory>
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.GuildDirectory>
end

--[=[
	@within DiscordLuau.Client

	Returns a stage voice channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a stage voice channel.
]=]
function Client.Prototype.getStageVCChannelAsync(
	self: Client,
	channelId: string
): future.FutureLike<string, classes.GuildStageVoice>
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.GuildStageVoice>
end

--[=[
	@within DiscordLuau.Client

	Returns a text channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a text channel.
]=]
function Client.Prototype.getTextChannelAsync(self: Client, channelId: string): future.FutureLike<string, classes.GuildText>
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.GuildText>
end

--[=[
	@within DiscordLuau.Client

	Returns a text channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a text channel.
]=]
function Client.Prototype.getForumChannelAsync(
	self: Client,
	channelId: string
): future.FutureLike<string, classes.ThreadForum>
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.ThreadForum>
end

--[=[
	@within DiscordLuau.Client

	Returns a text channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a text channel.
]=]
function Client.Prototype.getMediaChannelAsync(
	self: Client,
	channelId: string
): future.FutureLike<string, classes.ThreadMedia>
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.ThreadMedia>
end

--[=[
	@within DiscordLuau.Client

	Returns a user object for the given user ID.

	This function sends a request to the Discord API to retrieve information about a user. 
]=]
function Client.Prototype.getUserAsync(self: Client, userId: string): future.FutureLike<string, classes.User>
	return future.Future.new(function()
		local cachedUserData = self.state.cache.users:get(userId)

		if cachedUserData then
			return classes.user.new(cachedUserData)
		end

		local request = self.state.rest:newRequest()

		local response = rest.user.getUserAsync(request, userId):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local data = response:unwrapOk()

		self.state.cache.users:set(userId, data)

		return classes.user.new(data)
	end) :: future.FutureLike<string, classes.User>
end

--[=[
	@within DiscordLuau.Client

	Will create a new Guild instance, returns this instance.
]=]
function Client.Prototype.createGuildAsync(
	self: Client,
	guildData: builders.guildJSON & {
		name: string,
	}
): future.FutureLike<string, classes.Guild>
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.createGuildAsync(request, guildData :: any):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return classes.guild.guild.new(self.state, response:unwrapOk()) :: any
	end) :: future.FutureLike<string, classes.Guild>
end

--[=[
	@within DiscordLuau.Client

	Will set the Log Level for the bot, and all instantiated objects within the bot.
]=]
function Client.Prototype.setLogLevel(self: Client, logLevel: logger.LogLevel)
	self.logger:setLogLevel(logLevel)

	self.state.webSocketManager.logger:setLogLevel(logLevel)
	self.state.rest.logger:setLogLevel(logLevel)

	for _, shard in self.state.webSocketManager.shards do
		shard.logger:setLogLevel(logLevel)
	end
end

--[=[
	@within DiscordLuau.Client

	Returns a voice channel object for the given channel ID.

	This function sends a request to the Discord API to retrieve information about a voice channel.
]=]
function Client.Prototype.getVoiceChannelAsync(self: Client, channelId: string): future.FutureLike<string, classes.GuildVoice>
	return future.Future.new(function()
		local channel = self:getChannelAsync(channelId):await():unwrapOk()

		return channel :: any
	end) :: future.FutureLike<string, classes.GuildVoice>
end

--[=[
	@within DiscordLuau.Client

	Returns a webhook object for the given webhookId and optional webhookToken.

	This function sends a request to the Discord API to retrieve information about a webhook.
]=]
function Client.Prototype.getWebhookAsync(
	self: Client,
	webhookId: string,
	webhookToken: string?
): future.FutureLike<string, classes.Webhook>
	return future.Future.new(function()
		local request = self.state.rest:newRequest()
		local response = webhookToken
				and rest.webhook.getWebhookWithTokenAsync(request, webhookId, webhookToken):await()
			or rest.webhook.getWebhookAsync(request, webhookId):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return classes.webhook.new(self.state, response:unwrapOk())
	end) :: future.FutureLike<string, classes.Webhook>
end

--[=[
	@within DiscordLuau.Client

	Allows you to set the presence for the Discord Bot.

	:::caution
		Because discord-luau is currently unable to capture when the user cancels the program, we can't close the current
		websocket, which causes us to enter this Zombified state..

		Due to this zombified state - presences may be delayed, or won't render immediately
	:::
]=]
function Client.Prototype.setPresenceAsync(self: Client, presence: builders.presenceJSON)
	return self.state.webSocketManager:sendAsync(apiTypes.gateway.opcodes.PresenceUpdate, presence)
end

--[=[
	@within DiscordLuau.Client

	Construct a new DiscordLuau object
]=]
function Client.Interface.new(options: {
	intents: number | { apiTypes.Intent },
	reconnect: boolean?,
	logLevel: logger.LogLevel?,
	globalRatelimit: number?,
})
  if typeof(options.intents) == "table" then
    options.intents = builders.intents.new(options.intents):build()
  end

	local self = setmetatable(
		{
			state = state.state.new({
				token = nil,
				intents = options.intents :: number,
				logLevel = options.logLevel,
				version = DISCORD_VERSION,
				reconnect = options.reconnect or false,
				globalRatelimit = options.globalRatelimit or 50,
			}),

			logger = logger.new("Bot"),

			onReady = emitter.new(),
			onAllShardsReady = emitter.new(),
			onMessage = emitter.new(),
			onMessageChanged = emitter.new(),
			onMessageDeleted = emitter.new(),
			onMessageBulkDeleted = emitter.new(),

			onGroupDMChannelCreate = emitter.new(),
			onCategoryChannelCreate = emitter.new(),
			onAnnouncementChannelCreate = emitter.new(),
			onDirectoryChannelCreate = emitter.new(),
			onDMChannelCreate = emitter.new(),
			onTextChannelCreate = emitter.new(),
			onVoiceChannelCreate = emitter.new(),
			onStageVoiceChannelCreate = emitter.new(),

			onGroupDMChannelUpdated = emitter.new(),
			onCategoryChannelUpdated = emitter.new(),
			onAnnouncementChannelUpdated = emitter.new(),
			onDirectoryChannelUpdated = emitter.new(),
			onDMChannelUpdated = emitter.new(),
			onTextChannelUpdated = emitter.new(),
			onVoiceChannelUpdated = emitter.new(),
			onStageVoiceChannelUpdated = emitter.new(),

			onGroupDMChannelDeleted = emitter.new(),
			onCategoryChannelDeleted = emitter.new(),
			onAnnouncementChannelDeleted = emitter.new(),
			onDirectoryChannelDeleted = emitter.new(),
			onDMChannelDeleted = emitter.new(),
			onTextChannelDeleted = emitter.new(),
			onVoiceChannelDeleted = emitter.new(),
			onStageVoiceChannelDeleted = emitter.new(),

			onUserUpdated = emitter.new(),
			onChannelPinsUpdate = emitter.new(),

			onGuildCreate = emitter.new(),
			onGuildUpdate = emitter.new(),
			onGuildDelete = emitter.new(),

			onGuildMemberBanned = emitter.new(),
			onGuildMemberUnbanned = emitter.new(),

			onGuildMemberJoined = emitter.new(),
			onGuildMemberLeft = emitter.new(),
			onGuildMemberUpdated = emitter.new(),

			onPingInteraction = emitter.new(),
			onCommandInteraction = emitter.new(),
			onComponentInteraction = emitter.new(),
			onAutocompleteInteraction = emitter.new(),
			onModalInteraction = emitter.new(),
		} :: Client,
		{ __index = Client.Prototype }
	)

	if options.logLevel then
		self:setLogLevel(options.logLevel)
	end

	return self
end

export type Client =
	typeof(Client.Prototype)
	& {
		--[=[
			@prop state State.State
			@within DiscordLuau.Client
		]=]
		state: state.State,

		--[=[
			@prop logger Logger
			@within DiscordLuau.Client
		]=]
		logger: logger.Logger,

		--[=[
			@prop application Classes.Application?
			@within DiscordLuau.Client
		]=]
		application: classes.Application?,

		--[=[
			@prop user Classes.User?
			@within DiscordLuau.Client
		]=]
		user: classes.User?,

		--[=[
			@prop onReady Emitter<number>
			@within DiscordLuau.Client
		]=]
		onReady: emitter.Emitter<number>,

		--[=[
			@prop onAllShardsReady Emitter<()>
			@within DiscordLuau.Client
		]=]
		onAllShardsReady: emitter.Emitter<()>,

		--[=[
			@prop onMessage Emitter<Classes.Message>
			@within DiscordLuau.Client
		]=]
		onMessage: emitter.Emitter<classes.Message>,

		--[=[
			@prop onMessageChanged Emitter<Classes.Message>
			@within DiscordLuau.Client
		]=]
		onMessageChanged: emitter.Emitter<classes.Message>,

		--[=[
			@prop onMessageDeleted Emitter<{ messageId: apiTypes.Snowflake, channelId: apiTypes.Snowflake, guildId: apiTypes.Snowflake }>
			@within DiscordLuau.Client
		]=]
		onMessageDeleted: emitter.Emitter<{ messageId: apiTypes.Snowflake, channelId: apiTypes.Snowflake, guildId: apiTypes.Snowflake }>,

		--[=[
			@prop onMessageBulkDeleted Emitter<{ channelId: string, guildId: string, ids: { string } }>
			@within DiscordLuau.Client
		]=]
		onMessageBulkDeleted: emitter.Emitter<{ channelId: string, guildId: string, ids: { string } }>,

		--[=[
			@prop onGroupDMChannelCreate Emitter<Classes.GroupDM>
			@within DiscordLuau.Client
		]=]
		onGroupDMChannelCreate: emitter.Emitter<classes.GroupDM>,

		--[=[
			@prop onCategoryChannelCreate Emitter<Classes.GuildCategory>
			@within DiscordLuau.Client
		]=]
		onCategoryChannelCreate: emitter.Emitter<classes.GuildCategory>,

		--[=[
			@prop onAnnouncementChannelCreate Emitter<Classes.GuildAnnouncement>
			@within DiscordLuau.Client
		]=]
		onAnnouncementChannelCreate: emitter.Emitter<classes.GuildAnnouncement>,

		--[=[
			@prop onDirectoryChannelCreate Emitter<Classes.GuildDirectory>
			@within DiscordLuau.Client
		]=]
		onDirectoryChannelCreate: emitter.Emitter<classes.GuildDirectory>,

		--[=[
			@prop onDMChannelCreate Emitter<Classes.DM>
			@within DiscordLuau.Client
		]=]
		onDMChannelCreate: emitter.Emitter<classes.DM>,

		--[=[
			@prop onTextChannelCreate Emitter<Classes.GuildText>
			@within DiscordLuau.Client
		]=]
		onTextChannelCreate: emitter.Emitter<classes.GuildText>,

		--[=[
			@prop onVoiceChannelCreate Emitter<Classes.GuildVoice>
			@within DiscordLuau.Client
		]=]
		onVoiceChannelCreate: emitter.Emitter<classes.GuildVoice>,

		--[=[
			@prop onStageVoiceChannelCreate Emitter<Classes.GuildStageVoice>
			@within DiscordLuau.Client
		]=]
		onStageVoiceChannelCreate: emitter.Emitter<classes.GuildStageVoice>,

		--[=[
			@prop onGroupDMChannelUpdated Emitter<Classes.GroupDM>
			@within DiscordLuau.Client
		]=]
		onGroupDMChannelUpdated: emitter.Emitter<classes.GroupDM>,

		--[=[
			@prop onCategoryChannelUpdated Emitter<Classes.GuildCategory>
			@within DiscordLuau.Client
		]=]
		onCategoryChannelUpdated: emitter.Emitter<classes.GuildCategory>,

		--[=[
			@prop onAnnouncementChannelUpdated Emitter<Classes.GuildAnnouncement>
			@within DiscordLuau.Client
		]=]
		onAnnouncementChannelUpdated: emitter.Emitter<classes.GuildAnnouncement>,

		--[=[
			@prop onDirectoryChannelUpdated Emitter<Classes.GuildDirectory>
			@within DiscordLuau.Client
		]=]
		onDirectoryChannelUpdated: emitter.Emitter<classes.GuildDirectory>,

		--[=[
			@prop onDMChannelUpdated Emitter<Classes.DM>
			@within DiscordLuau.Client
		]=]
		onDMChannelUpdated: emitter.Emitter<classes.DM>,

		--[=[
			@prop onTextChannelUpdated Emitter<Classes.GuildText>
			@within DiscordLuau.Client
		]=]
		onTextChannelUpdated: emitter.Emitter<classes.GuildText>,

		--[=[
			@prop onVoiceChannelUpdated Emitter<Classes.GuildVoice>
			@within DiscordLuau.Client
		]=]
		onVoiceChannelUpdated: emitter.Emitter<classes.GuildVoice>,

		--[=[
			@prop onStageVoiceChannelUpdated Emitter<Classes.GuildStageVoice>
			@within DiscordLuau.Client
		]=]
		onStageVoiceChannelUpdated: emitter.Emitter<classes.GuildStageVoice>,

		--[=[
			@prop onGroupDMChannelDeleted Emitter<Classes.GroupDM>
			@within DiscordLuau.Client
		]=]
		onGroupDMChannelDeleted: emitter.Emitter<classes.GroupDM>,

		--[=[
			@prop onCategoryChannelDeleted Emitter<Classes.GuildCategory>
			@within DiscordLuau.Client
		]=]
		onCategoryChannelDeleted: emitter.Emitter<classes.GuildCategory>,

		--[=[
			@prop onAnnouncementChannelDeleted Emitter<Classes.GuildAnnouncement>
			@within DiscordLuau.Client
		]=]
		onAnnouncementChannelDeleted: emitter.Emitter<classes.GuildAnnouncement>,

		--[=[
			@prop onDirectoryChannelDeleted Emitter<Classes.GuildDirectory>
			@within DiscordLuau.Client
		]=]
		onDirectoryChannelDeleted: emitter.Emitter<classes.GuildDirectory>,

		--[=[
			@prop onDMChannelDeleted Emitter<Classes.DM>
			@within DiscordLuau.Client
		]=]
		onDMChannelDeleted: emitter.Emitter<classes.DM>,

		--[=[
			@prop onTextChannelDeleted Emitter<Classes.GuildText>
			@within DiscordLuau.Client
		]=]
		onTextChannelDeleted: emitter.Emitter<classes.GuildText>,

		--[=[
			@prop onVoiceChannelDeleted Emitter<Classes.GuildVoice>
			@within DiscordLuau.Client
		]=]
		onVoiceChannelDeleted: emitter.Emitter<classes.GuildVoice>,

		--[=[
			@prop onStageVoiceChannelDeleted Emitter<Classes.GuildStageVoice>
			@within DiscordLuau.Client
		]=]
		onStageVoiceChannelDeleted: emitter.Emitter<classes.GuildStageVoice>,

		--[=[
			@prop onUserUpdated Emitter<Classes.User>
			@within DiscordLuau.Client
		]=]
		onUserUpdated: emitter.Emitter<classes.User>,

		--[=[
			@prop onChannelPinsUpdate Emitter<{ guildId: string, channelId: string, lastPinTimestamp: stdPolyfills.DateTime? }>
			@within DiscordLuau.Client
		]=]
		onChannelPinsUpdate: emitter.Emitter<{ guildId: string, channelId: string, lastPinTimestamp: stdPolyfills.DateTime? }>,

		--[=[
			@prop onGuildCreate Emitter<classes.UnavailableGuild | classes.Guild>
			@within DiscordLuau.Client
		]=]
		onGuildCreate: emitter.Emitter<classes.UnavailableGuild | classes.Guild>,

		--[=[
			@prop onGuildUpdate Emitter<Classes.Guild>
			@within DiscordLuau.Client
		]=]
		onGuildUpdate: emitter.Emitter<classes.Guild>,

		--[=[
			@prop onGuildDelete Emitter<Classes.UnavailableGuild>
			@within DiscordLuau.Client
		]=]
		onGuildDelete: emitter.Emitter<classes.UnavailableGuild>,

		--[=[
			@prop onGuildMemberBanned Emitter<{ guildId: string, user: classes.User }>
			@within DiscordLuau.Client
		]=]
		onGuildMemberBanned: emitter.Emitter<{ guildId: string, user: classes.User }>,

		--[=[
			@prop onGuildMemberUnbanned Emitter<{ guildId: string, user: classes.User }>
			@within DiscordLuau.Client
		]=]
		onGuildMemberUnbanned: emitter.Emitter<{ guildId: string, user: classes.User }>,

		--[=[
			@prop onGuildMemberJoined Emitter<Classes.GuildMember & { guildId: string }>
			@within DiscordLuau.Client
		]=]
		onGuildMemberJoined: emitter.Emitter<classes.GuildMember & { guildId: string }>,

		--[=[
			@prop onGuildMemberLeft Emitter<{ guildId: string, user: classes.User }>
			@within DiscordLuau.Client
		]=]
		onGuildMemberLeft: emitter.Emitter<{ guildId: string, user: classes.User }>,

		--[=[
			@prop onGuildMemberUpdated Emitter<{guildId: stringroles: { string },user: classes.User,nick: string?,avatar: string,joinedAt: stdPolyfills.DateTime,premiumSince: stdPolyfills.DateTime,deaf: boolean?,mute: boolean?,pending: boolean?,communicationDisabledUntil: stdPolyfills.DateTime?,}>
			@within DiscordLuau.Client
		]=]
		onGuildMemberUpdated: emitter.Emitter<{
			guildId: string,
			roles: { string },
			user: classes.User,
			nick: string?,
			avatar: string,
			joinedAt: stdPolyfills.DateTime,
			premiumSince: stdPolyfills.DateTime,
			deaf: boolean?,
			mute: boolean?,
			pending: boolean?,
			communicationDisabledUntil: stdPolyfills.DateTime?,
		}>,

		--[=[
			@prop onPingInteraction Emitter<Classes.Ping>
			@within DiscordLuau.Client
		]=]
		onPingInteraction: emitter.Emitter<classes.Ping>,

		--[=[
			@prop onCommandInteraction Emitter<Classes.TypesCommand>
			@within DiscordLuau.Client
		]=]
		onCommandInteraction: emitter.Emitter<classes.TypesCommand>,

		--[=[
			@prop onComponentInteraction Emitter<Classes.Component>
			@within DiscordLuau.Client
		]=]
		onComponentInteraction: emitter.Emitter<classes.Component>,

		--[=[
			@prop onAutocompleteInteraction Emitter<Classes.Autocomplete>
			@within DiscordLuau.Client
		]=]
		onAutocompleteInteraction: emitter.Emitter<classes.Autocomplete>,

		--[=[
			@prop onModalInteraction Emitter<Classes.Modal>
			@within DiscordLuau.Client
		]=]
		onModalInteraction: emitter.Emitter<classes.Modal>,
	}

return Client.Interface
