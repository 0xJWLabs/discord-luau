--[=[
	@class Classes.Webhook
	@__index Prototype

	Implementation of the Discord Webhook class in Luau

	https://discord.com/developers/docs/resources/webhook#webhook-object
]=]

local apiTypes = require("../lune_packages/api_types")
local util = require("../lune_packages/util")
local state = require("../lune_packages/state")
local rest = require("../lune_packages/rest")
local future = require("../luau_packages/future")
local message = require("./message/message")
local stdPolyfills = require("../lune_packages/std_polyfills")

local user = require("./user")
local channelBehaviour = require("./channels/behaviour/channel")

local String = stdPolyfills.string

type WebhookModify = {
	name: string?,
	avatar: string?,
	channel: channelBehaviour.ChannelBehaviour?,
	reason: string?,
}

local Webhook = {}

Webhook.Interface = {}
Webhook.Prototype = {}

function Webhook.Prototype.createMessageAsync(self: Webhook, data: apiTypes.ExecuteWebhookRequest)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		request:setFlag("FormdataRequest", true)

		local response = rest.webhook.executeWebhookAsync(request, self.id, self.token :: string, data, {}):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return message.new(self.state, response:unwrapOk())
	end) :: future.FutureLike<string, message.Message>
end

function Webhook.Prototype.edit(self: Webhook, data: WebhookModify): future.FutureLike<string, Webhook>
	return future.Future.new(function()
		local data: WebhookModify = data or {} :: WebhookModify

		if data.avatar and not String.startsWith(data.avatar, "data:") then
			local avatar = util.dataResolver.resolveImage(data.avatar)
			print(avatar)
			if avatar then
				data.avatar = avatar
			end
		end

		local channel = if data.channel and data.channel.id then data.channel.id else data.channel
		local request = self.state.rest:newRequest()
		local response = not self.token
				and rest.webhook
					.modifyWebhookAsync(request, self.id, {
						name = data.name or self.name,
						avatar = data.avatar or self.avatar,
						channel_id = channel or self.channelId,
					}, data.reason)
					:await()
			or rest.webhook
				.modifyWebhookWithTokenAsync(request, self.id, self.token :: string, {
					name = data.name or self.name,
					avatar = data.avatar or self.avatar,
					channel_id = channel or self.channelId,
				}, data.reason)
				:await()

		assert(response:isOk(), tostring(response:unwrapErr()))
		local unwrappedResponse = response:unwrapOk()
		self.name = unwrappedResponse.name
		self.avatar = unwrappedResponse.avatar
		self.channelId = unwrappedResponse.channel_id

		return self
	end) :: future.FutureLike<string, Webhook>
end

--[=[
	@within Classes.Webhook
	@private

	Responsible for syncing data to this webhook object. This is typically called by the API when this object is
	created or updated.
]=]
function Webhook.Prototype.sync(self: Webhook, webhookData: apiTypes.WebhookObject)
	--[=[
		@prop id string
		@within Classes.Webhook
		The unique identifier for this webhook.
	]=]
	self.id = webhookData.id

	--[=[
		@prop type apiTypes.WebhookType
		@within Classes.Webhook
		The type of webhook, indicating its source and behavior.
	]=]
	self.type = apiTypes.webhook.WebhookType[webhookData.type]

	--[=[
		@prop guildId string?
		@within Classes.Webhook
		The ID of the guild this webhook belongs to, if it's a server webhook.
	]=]
	self.guildId = webhookData.guild_id

	--[=[
		@prop channelId string?
		@within Classes.Webhook
		The ID of the channel this webhook is associated with.
	]=]
	self.channelId = webhookData.channel_id

	--[=[
		@prop user Classes.User?
		@within Classes.Webhook
		The user who created this webhook.
	]=]
	self.user = webhookData.user and user.new(webhookData.user)

	--[=[
		@prop name string?
		@within Classes.Webhook
		The name of the webhook.
	]=]
	self.name = webhookData.name

	--[=[
		@prop avatar string?
		@within Classes.Webhook
		The avatar hash of the webhook.
	]=]
	self.avatar = webhookData.avatar

	--[=[
		@prop token string?
		@within Classes.Webhook
		The token used to authenticate webhook requests.
	]=]
	self.token = webhookData.token

	--[=[
		@prop applicationId string?
		@within Classes.Webhook
		The ID of the application that created this webhook.
	]=]
	self.applicationId = webhookData.application_id

	--[=[
		@prop url string?
		@within Classes.Webhook
		The URL used to execute this webhook.
	]=]
	self.url = webhookData.url
end

--[=[
	@within Classes.Webhook
	@private

	Responsible for constructing this class.
]=]
function Webhook.Interface.new(state, webhookData: apiTypes.WebhookObject): Webhook
	local self = setmetatable(
		{
			state = state,
		} :: Webhook,
		{ __index = Webhook.Prototype }
	)

	if webhookData then
		self:sync(webhookData)
	end

	return self
end

export type Webhook = typeof(Webhook.Prototype) & {
	id: apiTypes.Snowflake,
	type: apiTypes.WebhookType,
	guildId: apiTypes.Snowflake?,
	channelId: apiTypes.Snowflake?,
	user: user.User?,
	name: string?,
	avatar: string?,
	token: string?,
	applicationId: apiTypes.Snowflake?,
	url: string?,
} & {
	state: state.State,
}

return Webhook.Interface
