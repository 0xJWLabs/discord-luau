export type Colors = {
	Default: number,
	White: number,
	Aqua: number,
	Green: number,
	Blue: number,
	Yellow: number,
	Purple: number,
	LuminousVividPink: number,
	Fuchsia: number,
	Gold: number,
	Orange: number,
	Red: number,
	Grey: number,
	Navy: number,
	DarkAqua: number,
	DarkGreen: number,
	DarkBlue: number,
	DarkPurple: number,
	DarkVividPink: number,
	DarkGold: number,
	DarkOrange: number,
	DarkRed: number,
	DarkGrey: number,
	DarkerGrey: number,
	LightGrey: number,
	DarkNavy: number,
	Blurple: number,
	Greyple: number,
	DarkButNotBlack: number,
	NotQuiteBlack: number,
}

export type Color =
	"Default"
	| "White"
	| "Aqua"
	| "Green"
	| "Blue"
	| "Yellow"
	| "Purple"
	| "LuminousVividPink"
	| "Fuchsia"
	| "Gold"
	| "Orange"
	| "Red"
	| "Grey"
	| "Navy"
	| "DarkAqua"
	| "DarkGreen"
	| "DarkBlue"
	| "DarkPurple"
	| "DarkVividPink"
	| "DarkGold"
	| "DarkOrange"
	| "DarkRed"
	| "DarkGrey"
	| "DarkerGrey"
	| "LightGrey"
	| "DarkNavy"
	| "Blurple"
	| "Greyple"
	| "DarkButNotBlack"
	| "NotQuiteBlack"

local Colors: Colors = {
	Default = 0x000000, -- rgb(0,0,0)
	White = 0xFFFFFF, -- rgb(255,255,255)
	Aqua = 0x1ABC9C, -- rgb(26,188,156)
	Green = 0x57F287, -- rgb(87,242,135)
	Blue = 0x3498DB, -- rgb(52,152,219)
	Yellow = 0xFEE75C, -- rgb(254,231,92)
	Purple = 0x9B59B6, -- rgb(155,89,182)
	LuminousVividPink = 0xE91E63, -- rgb(233,30,99)
	Fuchsia = 0xEB459E, -- rgb(235,69,158)
	Gold = 0xF1C40F, -- rgb(241,196,15)
	Orange = 0xE67E22, -- rgb(230,126,34)
	Red = 0xED4245, -- rgb(237,66,69)
	Grey = 0x95A5A6, -- rgb(149,165,166)
	Navy = 0x34495E, -- rgb(52,73,94)
	DarkAqua = 0x11806A, -- rgb(17,128,106)
	DarkGreen = 0x1F8B4C, -- rgb(31,139,76)
	DarkBlue = 0x206694, -- rgb(32,102,148)
	DarkPurple = 0x71368A, -- rgb(113,54,138)
	DarkVividPink = 0xAD1457, -- rgb(173,20,87)
	DarkGold = 0xC27C0E, -- rgb(194,124,14)
	DarkOrange = 0xA84300, -- rgb(168,67,0)
	DarkRed = 0x992D22, -- rgb(153,45,34)
	DarkGrey = 0x979C9F, -- rgb(151,156,159)
	DarkerGrey = 0x7F8C8D, -- rgb(127,140,141)
	LightGrey = 0xBCC0C0, -- rgb(188,192,192)
	DarkNavy = 0x2C3E50, -- rgb(44,62,80)
	Blurple = 0x5865F2, -- rgb(88,101,242)
	Greyple = 0x99AAB5, -- rgb(153,170,181)
	DarkButNotBlack = 0x2C2F33, -- rgb(44,47,51)
	NotQuiteBlack = 0x23272A, -- rgb(35,39,42)
}

export type ColorResolvable = string | number | Color | { number }

return Colors
