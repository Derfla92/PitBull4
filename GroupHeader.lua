local _G = _G
local PitBull4 = _G.PitBull4

--- Make a group header.
-- @param group the name for the group. Also acts as a unique identifier.
-- @usage local header = PitBull4:MakeGroupHeader("Monkey")
function PitBull4:MakeGroupHeader(group)
	--@alpha@
	expect(group, 'typeof', 'string')
	--@end-alpha@
	
	local header_name = "PitBull4_Groups_" .. group
	
	local header = _G[header_name]
	if not header then
		header = CreateFrame("Frame", header_name, UIParent, "SecureGroupHeaderTemplate")
		header:Hide() -- it will be shown later and attributes being set won't cause lag
		header:SetFrameStrata(PitBull4.UNITFRAME_STRATA)
		header:SetFrameLevel(PitBull4.UNITFRAME_LEVEL - 1)
		
		header.name = group
		
		local group_db = PitBull4.db.profile.groups[group]
		header.group_db = group_db
		
		self:ConvertIntoGroupHeader(header)
	end
	
	header:Show()
end
PitBull4.MakeGroupHeader = PitBull4:OutOfCombatWrapper(PitBull4.MakeGroupHeader)

local GroupHeader = {}
PitBull4.GroupHeader = GroupHeader
local GroupHeader__scripts = {}
PitBull4.GroupHeader__scripts = GroupHeader__scripts

local MemberUnitFrame = PitBull4.MemberUnitFrame
local MemberUnitFrame__scripts = PitBull4.MemberUnitFrame__scripts

--- Force an update on the group header.
-- This is just a wrapper for SecureGroupHeader_Update.
-- @usage header:Update()
function GroupHeader:Update()
	SecureGroupHeader_Update(self)
end
GroupHeader.Update = PitBull4:OutOfCombatWrapper(GroupHeader.Update)

--- Send :Update to all member frames.
-- @args ... the arguments to send along with :Update
-- @usage header:UpdateMembers(true, true)
function GroupHeader:UpdateMembers(...)
	for i, frame in ipairs(self) do
		frame:Update(...)
	end
end

function GroupHeader:ProxySetAttribute(key, value)
	if self:GetAttribute(key) ~= value then
		self:SetAttribute(key, value)
	end
end

local DIRECTION_TO_POINT = {
	down_right = "TOP",
	down_left = "TOP",
	up_right = "BOTTOM",
	up_left = "BOTTOM",
	right_down = "LEFT",
	right_up = "LEFT",
	left_down = "RIGHT",
	left_up = "RIGHT",
}

local DIRECTION_TO_COLUMN_ANCHOR_POINT = {
	down_right = "LEFT",
	down_left = "RIGHT",
	up_right = "LEFT",
	up_left = "RIGHT",
	right_down = "TOP",
	right_up = "BOTTOM",
	left_down = "TOP",
	left_up = "BOTTOM",
}

local DIRECTION_TO_HORIZONTAL_SPACING_MULTIPLIER = {
	down_right = 1,
	down_left = -1,
	up_right = 1,
	up_left = -1,
	right_down = 1,
	right_up = 1,
	left_down = -1,
	left_up = -1,
}

local DIRECTION_TO_VERTICAL_SPACING_MULTIPLIER = {
	down_right = -1,
	down_left = -1,
	up_right = 1,
	up_left = 1,
	right_down = -1,
	right_up = 1,
	left_down = -1,
	left_up = 1,
}

--- Recheck the group-based settings of the group header, including sorting, position, what units are shown.
-- @param dont_refresh_children don't call :RefreshLayout on the child frames
-- @usage header:RefreshGroup()
function GroupHeader:RefreshGroup(dont_refresh_children)
	local group_db = self.group_db
	
	local layout = group_db.layout
	self.layout = layout
	
	local layout_db = PitBull4.db.profile.layouts[layout]
	self.layout_db = layout_db
	
	local unit_group = group_db.unit_group
	if self.unit_group ~= unit_group then
		local old_unit_group = self.unit_group
		local old_super_unit_group = self.super_unit_group
		self.unit_group = unit_group
		local party_based = unit_group:sub(1, 5) == "party"
		--@alpha@
		if not party_based then
			expect(unit_group:sub(1, 4), '==', "raid")
		end
		--@end-alpha@
	
		if party_based then
			self.super_unit_group = "party"
			self.unitsuffix = unit_group:sub(6)
			self:ProxySetAttribute("showRaid", nil)
			self:ProxySetAttribute("showParty", true)
		else
			self.super_unit_group = "raid"
			self.unitsuffix = unit_group:sub(5)
			self:ProxySetAttribute("showParty", nil)
			self:ProxySetAttribute("showRaid", true)
		end
		if self.unitsuffix == "" then
			self.unitsuffix = nil
		end
	
		local is_wacky = PitBull4.Utils.IsWackyUnitGroup(unit_group)
		self.is_wacky = is_wacky
		
		if old_unit_group then
			PitBull4.unit_group_to_headers[old_unit_group][self] = nil
			PitBull4.super_unit_group_to_headers[old_super_unit_group][self] = nil
			
			for i, frame in ipairs(self) do
				frame:ProxySetAttribute("unitsuffix", self.unitsuffix)
			end
		end
		PitBull4.unit_group_to_headers[unit_group][self] = true
		PitBull4.super_unit_group_to_headers[self.super_unit_group][self] = true
	end
	
	self:SetScale(layout_db.scale * group_db.scale)
	local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
	
	local direction = group_db.direction
	local point = DIRECTION_TO_POINT[direction]
	
	self:ProxySetAttribute("point", point)
	if point == "LEFT" or point == "RIGHT" then
		self:ProxySetAttribute("xOffset", group_db.horizontal_spacing * DIRECTION_TO_HORIZONTAL_SPACING_MULTIPLIER[direction])
		self:ProxySetAttribute("yOffset", 0)
		self:ProxySetAttribute("columnSpacing", group_db.vertical_spacing)
	else
		self:ProxySetAttribute("xOffset", 0)
		self:ProxySetAttribute("yOffset", group_db.vertical_spacing * DIRECTION_TO_VERTICAL_SPACING_MULTIPLIER[direction])
		self:ProxySetAttribute("columnSpacing", group_db.horizontal_spacing)
	end
	self:ProxySetAttribute("sortMethod", group_db.sort_method)
	self:ProxySetAttribute("sortDir", group_db.sort_direction)
	self:ProxySetAttribute("template", "SecureUnitButtonTemplate")
	self:ProxySetAttribute("templateType", "Button")
	self:ProxySetAttribute("groupBy", nil) -- or "GROUP", "CLASS", "ROLE"
	self:ProxySetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
	self:ProxySetAttribute("unitsPerColumn", group_db.units_per_column)
	self:ProxySetAttribute("maxColumns", MAX_RAID_MEMBERS)
	self:ProxySetAttribute("startingIndex", 1)
	self:ProxySetAttribute("columnAnchorPoint", DIRECTION_TO_COLUMN_ANCHOR_POINT[direction])
	self:ProxySetAttribute("useOwnerUnit", 1)
	
	self:ForceUnitFrameCreation()
	self:AssignFakeUnitIDs()
	
	self:ClearAllPoints()
	
	local x_diff, y_diff = 0, 0
	if point == "TOP" then
		y_diff = self[1]:GetHeight() / 2
	elseif point == "BOTTOM" then
		y_diff = -self[1]:GetHeight() / 2
	elseif point == "LEFT" then
		x_diff = -self[1]:GetWidth() / 2
	elseif point == "RIGHT" then
		x_diff = self[1]:GetWidth() / 2
	end
	self:SetPoint(point, UIParent, "CENTER", group_db.position_x / scale + x_diff, group_db.position_y / scale + y_diff)
	
	if not dont_refresh_children then
		for i, frame in ipairs(self) do
			frame:RefreshLayout()
		end
	end
end
GroupHeader.RefreshGroup = PitBull4:OutOfCombatWrapper(GroupHeader.RefreshGroup)

--- Recheck the layout of the group header, refreshing the layout of all members.
-- @param dont_refresh_children don't call :RefreshLayout on the child frames
-- @usage header:RefreshLayout()
function GroupHeader:RefreshLayout(dont_refresh_children)
	local group_db = self.group_db

	local layout = group_db.layout
	self.layout = layout
	
	local layout_db = PitBull4.db.profile.layouts[layout]
	self.layout_db = layout_db
	
	self:SetScale(layout_db.scale * group_db.scale)
	
	if not dont_refresh_children then
		for i, frame in ipairs(self) do
			frame:RefreshLayout()
		end
	end
end
GroupHeader.RefreshLayout = PitBull4:OutOfCombatWrapper(GroupHeader.RefreshLayout)

--- Initialize a member frame. This should be called once per member frame immediately following the frame's creation.
-- @usage header:InitializeConfigFunction(frame)
function GroupHeader:InitialConfigFunction(frame)
	self[#self+1] = frame
	frame.header = self
	frame.is_singleton = false
	frame.classification = self.name
	frame.classification_db = self.group_db
	frame.is_wacky = self.is_wacky
	
	if self.unitsuffix then
		frame:ProxySetAttribute("unitsuffix", self.unitsuffix)
	end
	
	local layout = self.group_db.layout
	frame.layout = layout
	
	PitBull4:ConvertIntoUnitFrame(frame)
	
	local layout_db = PitBull4.db.profile.layouts[layout]
	frame.layout_db = layout_db
	
	frame:ProxySetAttribute("initial-width", layout_db.size_x * self.group_db.size_x)
	frame:ProxySetAttribute("initial-height", layout_db.size_y * self.group_db.size_y)
	frame:ProxySetAttribute("initial-unitWatch", true)
	
	frame:RefreshLayout()
end

--- Force num unit frames to be created on the group header, even if those units don't exist.
-- Note: this is a hack to get around a Blizzard bug preventing frames from being initialized properly while in combat.
-- @usage header:ForceUnitFrameCreation()
function GroupHeader:ForceUnitFrameCreation()
	local num = self.super_unit_group == "raid" and MAX_RAID_MEMBERS or MAX_PARTY_MEMBERS
	for _, frame in ipairs(self) do
		if frame:GetAttribute("unit") and UnitExists(frame:GetAttribute("unit")) then
			num = num - 1
		end
	end
	
	local maxColumns = self:GetAttribute("maxColumns")
	local unitsPerColumn = self:GetAttribute("unitsPerColumn")
	local startingIndex = self:GetAttribute("startingIndex")
	if maxColumns == nil then
		self:ProxySetAttribute("maxColumns", 1)
		self:ProxySetAttribute("unitsPerColumn", num)
	end
	self:ProxySetAttribute("startingIndex", -num + 1)
	
	SecureGroupHeader_Update(self)
	
	self:ProxySetAttribute("maxColumns", maxColumns)
	self:ProxySetAttribute("unitsPerColumn", unitsPerColumn)
	self:ProxySetAttribute("startingIndex", startingIndex)
	
	SecureGroupHeader_Update(self)
	
	-- this is done because the previous hack can mess up some unit references
	for i, frame in ipairs(self) do
		local unit = SecureButton_GetUnit(frame)
		if unit ~= frame.unit then
			frame.unit = unit
			frame:Update()
		end
	end
end
GroupHeader.ForceUnitFrameCreation = PitBull4:OutOfCombatWrapper(GroupHeader.ForceUnitFrameCreation)

local function hook_SecureGroupHeader_Update()
	hook_SecureGroupHeader_Update = nil
	hooksecurefunc("SecureGroupHeader_Update", function(self)
		if not PitBull4.all_headers[self] then
			return
		end
		self:AssignFakeUnitIDs()
	end)
end

function GroupHeader:AssignFakeUnitIDs()
	if not self.force_show then
		return
	end

	local super_unit_group = self.super_unit_group
	
	local current_group_num = 0
	
	local start, finish, step = 1, #self, 1
	
	if self:GetAttribute("sortDir") == "DESC" then
		start, finish, step = finish, start, -1
	end
	
	for i = start, finish, step do
		local frame = self[i]
		
		if not frame.guid then
			local old_unit = frame:GetAttribute("unit")
			local unit
			
			repeat
				current_group_num = current_group_num + 1
				unit = super_unit_group .. current_group_num
			until not UnitExists(unit)	
			
			if old_unit ~= unit then
				frame:SetAttribute("unit", unit)
				frame:Update()
			end
		end
	end
end
GroupHeader.AssignFakeUnitIDs = PitBull4:OutOfCombatWrapper(GroupHeader.AssignFakeUnitIDs)

function GroupHeader:ForceShow()
	if self.force_show then
		return
	end
	if hook_SecureGroupHeader_Update then
		hook_SecureGroupHeader_Update()
	end
	self.force_show = true
	self:AssignFakeUnitIDs()
	for _, frame in ipairs(self) do
		frame:ForceShow()
		frame:Update(true, true)
	end
end
GroupHeader.ForceShow = PitBull4:OutOfCombatWrapper(GroupHeader.ForceShow)

function GroupHeader:UnforceShow()
	if not self.force_show then
		return
	end
	self.force_show = nil
	for _, frame in ipairs(self) do
		frame:UnforceShow()
		frame:Update(true, true)
	end
end
GroupHeader.UnforceShow = PitBull4:OutOfCombatWrapper(GroupHeader.UnforceShow)

function GroupHeader:Rename(name)
	if self.name == name then
		return
	end
	
	local old_header_name = "PitBull4_Groups_" .. self.name
	local new_header_name = "PitBull4_Groups_" .. name
	
	PitBull4.name_to_header[self.name] = nil
	PitBull4.name_to_header[name] = self
	_G[old_header_name] = nil
	_G[new_header_name] = self
	self.name = name
	
	for i, frame in ipairs(self) do
		frame.classification = name
	end
end

local moving_frame = nil
function MemberUnitFrame__scripts:OnDragStart()
	if PitBull4.db.profile.lock_movement or InCombatLockdown() then
		return
	end
	
	moving_frame = self
	LibStub("LibSimpleSticky-1.0"):StartMoving(self.header, PitBull4.all_frames_list, 0, 0, 0, 0)
end

function MemberUnitFrame__scripts:OnDragStop()
	if not moving_frame then return end
	moving_frame = nil
	local header = self.header
	LibStub("LibSimpleSticky-1.0"):StopMoving(header)
	
	local ui_scale = UIParent:GetEffectiveScale()
	local scale = header[1]:GetEffectiveScale() / ui_scale
	
	local x, y = header[1]:GetCenter()
	x, y = x * scale, y * scale
	
	x = x - GetScreenWidth()/2
	y = y - GetScreenHeight()/2
	
	header.group_db.position_x = x
	header.group_db.position_y = y
	
	LibStub("AceConfigRegistry-3.0"):NotifyChange("PitBull4")
	
	header:RefreshLayout(true)
end

LibStub("AceEvent-3.0").RegisterEvent("PitBull4-MemberUnitFrame:OnDragStop", "PLAYER_REGEN_DISABLED", function()
	if moving_frame then
		MemberUnitFrame__scripts.OnDragStop(moving_frame)
	end
end)

--- Reset the size of the unit frame, not position as that is handled through the group header.
-- @usage frame:RefixSizeAndPosition()
function MemberUnitFrame:RefixSizeAndPosition()
	local layout_db = self.layout_db
	local classification_db = self.classification_db
	
	self:SetWidth(layout_db.size_x * classification_db.size_x)
	self:SetHeight(layout_db.size_y * classification_db.size_y)
end
MemberUnitFrame.RefixSizeAndPosition = PitBull4:OutOfCombatWrapper(MemberUnitFrame.RefixSizeAndPosition)

--- Add the proper functions and scripts to a SecureGroupHeaderTemplate or SecureGroupPetHeaderTemplate, as well as some initialization.
-- @param frame a Frame which inherits from SecureGroupHeaderTemplate or SecureGroupPetHeaderTemplate
-- @usage PitBull4:ConvertIntoGroupHeader(header)
function PitBull4:ConvertIntoGroupHeader(header)
	--@alpha@
	expect(header, 'typeof', 'frame')
	expect(header, 'frametype', 'Frame')
	--@end-alpha@
	
	self.all_headers[header] = true
	self.name_to_header[header.name] = header
	
	for k, v in pairs(GroupHeader__scripts) do
		header:SetScript(k, v)
	end
	
	for k, v in pairs(GroupHeader) do
		header[k] = v
	end
	
	-- this is done to pass self in properly
	function header.initialConfigFunction(...)
		return header:InitialConfigFunction(...)
	end
	
	header:RefreshGroup()
	
	header:SetMovable(true)
	
	header:ForceUnitFrameCreation()
end
