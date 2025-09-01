--[=[
	@class Utilities

	Interface for the discord-luau Utilities package
]=]

local colors = require("@self/colors")

export type Colors = colors.Colors
export type Color = colors.Color
export type ColorResolvable = colors.ColorResolvable

return {
	validateKebabCase = require("@self/validateKebabCase"),
	createGuid = require("@self/createGuid"),
	coroutineRun = require("@self/coroutine/run"),
	tableReflect = require("@self/table/reflect"),
	dataResolver = require("@self/dataResolver"),
	resolveColor = require("@self/resolveColor"),
}
