local _G = _G
local PitBull4 = _G.PitBull4

local AceConfig = LibStub and LibStub("AceConfig-3.0", true)
if not AceConfig then
	LoadAddOn("Ace3")
	AceConfig = LibStub and LibStub("AceConfig-3.0", true)
	if not LibSimpleOptions then
		message(("PitBull4 requires the library %q and will not work without it."):format("AceConfig-3.0"))
		error(("PitBull4 requires the library %q and will not work without it."):format("AceConfig-3.0"))
	end
end
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local OpenConfig

AceConfig:RegisterOptionsTable("PitBull4_Bliz", {
	name = "PitBull Unit Frames 4.0",
	handler = PitBull4,
	type = 'group',
	args = {
		config = {
			name = "Standalone config",
			desc = "Open a standlone config window, allowing you to actually configure PitBull Unit Frames 4.0.",
			type = 'execute',
			func = function()
				OpenConfig()
			end
		}
	},
})
AceConfigDialog:AddToBlizOptions("PitBull4_Bliz", "PitBull Unit Frames 4.0")

do
	for i, cmd in ipairs { "/PitBull4", "/PitBull", "/PB4", "/PB", "/PBUF", "/Pit" } do
		_G["SLASH_PITBULLFOUR" .. (i*2 - 1)] = cmd
		_G["SLASH_PITBULLFOUR" .. (i*2)] = cmd:lower()
	end

	_G.hash_SlashCmdList["PITBULLFOUR"] = nil
	_G.SlashCmdList["PITBULLFOUR"] = function()
		return OpenConfig()
	end
end

PitBull4.Options = {}

function OpenConfig()
	-- redefine it so that we just open up the pane next time
	function OpenConfig()
		AceConfigDialog:Open("PitBull4")
	end
	
	local options = {
		name = "PitBull",
		handler = PitBull4,
		type = 'group',
		args = {
		},
	}
	
	options.args.layout_options = PitBull4.Options.get_layout_options()
	PitBull4.Options.get_layout_options = nil
	
	options.args.unit_options = PitBull4.Options.get_unit_options()
	PitBull4.Options.get_unit_options = nil
	
	AceConfig:RegisterOptionsTable("PitBull4", options)
	AceConfigDialog:SetDefaultSize("PitBull4", 825, 550)
	
	return OpenConfig()
end
