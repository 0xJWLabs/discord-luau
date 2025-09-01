local Builders = require("../../lune_packages/builders")
local apiTypes = require("../../lune_packages/api_types")
local stdPolyfills = require("../../lune_packages/std_polyfills")
local util = require("../../lune_packages/util")

local BuilderEmbed = Builders.embed.embed

local EmbedBuilder = {}

EmbedBuilder.Prototype = {}
EmbedBuilder.Interface = {}

function EmbedBuilder.Prototype.setColor(self: EmbedBuilder, color: util.ColorResolvable): EmbedBuilder
	local resolvedColor = util.resolveColor(color)

	return BuilderEmbed.setColor(self, resolvedColor)
end

function EmbedBuilder.Interface.new(resource: {
	title: string?,
	type: apiTypes.EmbedType?,
	description: string?,
	url: string?,
	timestamp: stdPolyfills.DateTime?,
	color: number?,
	footer: Builders.footerJSON?,
	image: Builders.imageJSON?,
	thumbnail: Builders.thumbnailJSON?,
	video: Builders.videoJSON?,
	provider: Builders.providerJSON?,
	author: Builders.authorJSON?,
	fields: { Builders.fieldJSON },
}?)
	local self = setmetatable(BuilderEmbed.new(resource), {
		__index = EmbedBuilder.Prototype,
	})

	return self
end

export type EmbedBuilder = Builders.Embed & typeof(EmbedBuilder.Prototype)

return EmbedBuilder.Interface
