--!native
--!optimize 2
--!divine-intellect
-- COPYRIGHT (c) 2024 - DLLDECOMPILE BY ROLUAU

local service = setmetatable({}, {
	__index = function(self, index)
		local Service = game:GetService(index) or settings():GetService(index) or UserSettings():GetService(index)
		self[index] = Service
		return Service
	end,
})

-- Defensive replacement for the original string_find wrapper
local function string_find(s, pattern)
	-- Ensure pattern is a string; plain matching requires a string pattern.
	if type(pattern) ~= "string" then
		return nil
	end

	-- If s is already a string, use it directly.
	if type(s) ~= "string" then
		-- nil -> treat as not found
		if s == nil then
			return nil
		end

		-- Try to coerce to string safely; some userdata may error when tostring'd.
		local ok, str = pcall(tostring, s)
		if not ok or type(str) ~= "string" then
			return nil
		end
		s = str
	end

	-- Use explicit start index 1 and plain matching (fourth arg true)
	return string.find(s, pattern, 1, true)
end

local function ArrayToDictionary(t, hydridMode, valueOverride)
	local tmp = {}

	if hydridMode then
		for some1, some2 in pairs(t) do
			if type(some1) == "number" then
				tmp[some2] = valueOverride or true
			elseif type(some2) == "table" then
				tmp[some1] = ArrayToDictionary(some2, hydridMode) -- Some1 is Class, Some2 is Name
			else
				tmp[some1] = some2
			end
		end
	else
		for _, key in ipairs(t) do
			if type(key) == "string" then
				tmp[key] = true
			end
		end
	end

	return tmp
end

local ESCAPES_PATTERN = "[&<>\"'\0\1-\9\11-\12\14-\31\127-\255]" -- * The safe way is to escape all five characters in text. However, the three characters " ' and > needn't be escaped in text
-- %z (\0 aka NULL) might not be needed as Roblox automatically converts it to space everywhere it seems like
-- Characters from: https://create.roblox.com/docs/en-us/ui/rich-text#escape-forms
-- * EscapesPattern should be ordered from most common to least common characters for sake of speed
-- * Might wanna use their numerical codes instead of named codes for reduced file size (Could be an Option)
-- TODO Maybe we should invert the pattern to only allow certain characters (future-proof)
local ESCAPES = {
	["&"] = "&amp;", -- 38
	["<"] = "&lt;", -- 60
	[">"] = "&gt;", -- 62
	['"'] = "&#34;", --  quot
	["'"] = "&#39;", -- apos
	["\0"] = "",
}

for rangeStart, rangeEnd in string.gmatch(ESCAPES_PATTERN, "(.)%-(.)") do
	for charCode = string.byte(rangeStart), string.byte(rangeEnd) do
		ESCAPES[string.char(charCode)] = "&#" .. charCode .. ";"
	end
end

local global_container
do
	local filename = "UniversalMethodFinder"

	local finder
	finder, global_container = loadstring(
		game:HttpGet("https://raw.githubusercontent.com/luau/SomeHub/main/" .. filename .. ".luau", true),
		filename
	)()

	finder({
		-- readbinarystring = 'string.find(...,"bin",nil,true)', -- ! Could match some unwanted stuff (getbinaryindex)
		-- request = 'string.find(...,"request",nil,true) and not string.find(...,"internal",nil,true)',
		base64encode = 'local a={...}local b=a[1]local function c(a,b)return string.find(a,b,nil,true)end;return c(b,"encode")and(c(b,"base64")or c(string.lower(tostring(a[2])),"base64"))',
		decompile = '(string.find(...,"decomp",nil,true) and string.sub(...,#...) ~= "s") or string.find(...,"assembl",nil,true)',
		gethiddenproperty = 'string.find(...,"get",nil,true) and string.find(...,"h",nil,true) and string.find(...,"prop",nil,true) and string.sub(...,#...) ~= "s"',
		gethui = 'string.find(...,"get",nil,true) and string.find(...,"h",nil,true) and string.find(...,"ui",nil,true)',
		getnilinstances = 'string.find(...,"nil",nil,true) and string.find(...,"get",nil,true) and string.sub(...,#...) == "s"', -- ! Could match some unwanted stuff
		getscriptbytecode = 'string.find(...,"get",nil,true) and string.find(...,"bytecode",nil,true)', --  or string.find(...,"dump",nil,true) and string.find(...,"string",nil,true) due to Fluxus (dumpstri[...]
		hash = 'local a={...}local b=a[1]local function c(a,b)return string.find(a,b,nil,true)end;return c(b,"hash")and c(string.lower(tostring(a[2])),"crypt")',
		protectgui = 'string.find(...,"protect",nil,true) and string.find(...,"ui",nil,true) and not string.find(...,"un",nil,true)',
		-- appendfile = 'string.find(...,"file",nil,true) and string.find(...,"append",nil,true)',
		readfile = 'string.find(...,"file",nil,true) and string.find(...,"read",nil,true)',
		writefile = 'string.find(...,"file",nil,true) and string.find(...,"write",nil,true)',
		setthreadidentity = 'string.find(...,"identity",nil,true) and string.find(...,"set",nil,true)',
	}, true, 10)
end

local identify_executor = identifyexecutor or getexecutorname or whatexecutor

local EXECUTOR_NAME = identify_executor()

local gethiddenproperty = global_container.gethiddenproperty
-- local appendfile = global_container.appendfile
local readfile = global_container.readfile
local writefile = global_container.writefile

local getscriptbytecode = global_container.getscriptbytecode -- * A lot of assumptions are made based on whether this function is defined or not. So in certain edge cases, like if the executor defines[...]
local base64encode = global_container.base64encode
local sha384

if not base64encode then
	if not bit32.byteswap or not pcall(bit32.byteswap, 1) then -- Because Fluxus is missing byteswap
		bit32 = table.clone(bit32)

		local function tobit(num)
			num = num % (bit32.bxor(num, 32))
			if 0x80000000 < num then
				num = num - bit32.bxor(num, 32)
			end
			return num
		end

		bit32.byteswap = function(num)
			local BYTE_SIZE = 8
			local MAX_BYTE_VALUE = 255

			num = num % bit32.bxor(2, 32)

			local a = bit32.band(num, MAX_BYTE_VALUE)
			num = bit32.rshift(num, BYTE_SIZE)

			local b = bit32.band(num, MAX_BYTE_VALUE)
			num = bit32.rshift(num, BYTE_SIZE)

			local c = bit32.band(num, MAX_BYTE_VALUE)
			num = bit32.rshift(num, BYTE_SIZE)

			local d = bit32.band(num, MAX_BYTE_VALUE)
			local shifted = bit32.lshift(bit32.lshift(bit32.lshift(a, BYTE_SIZE) + b, BYTE_SIZE) + c, BYTE_SIZE) + d
			local dnum = tobit(shifted)
			return dnum
		end

		table.freeze(bit32)
	end

	-- Credits @Reselim
	local Base64_Encode_Buffer = loadstring(
		game:HttpGet("https://raw.githubusercontent.com/Reselim/Base64/master/Base64.lua", true),
		"Base64"
	)().encode
	base64encode = function(raw)
		return raw == "" and raw or buffer.tostring(Base64_Encode_Buffer(buffer.fromstring(raw)))
	end
end

do
	local hash = global_container.hash

	if hash then
		sha384 = function(data)
			return hash(data, "sha384")
		end
	else
		local filename = "RequireOnlineModule"

		sha384 = loadstring(
			game:HttpGet("https://raw.githubusercontent.com/luau/SomeHub/main/" .. filename .. ".luau", true),
			filename
		)()(4544052033).sha384
	end
end

local custom_decompiler, load_decompiler -- TODO Temporary

if getscriptbytecode then
	-- Credits @roluau
	local decompiler_source

	if
		pcall(function()
			decompiler_source =
				game:HttpGet("https://raw.githubusercontent.com/w-a-e/Advanced-Decompiler-V3/main/init.lua", true)
		end)
	then
		load_decompiler = function(decompTimeout)
			local CONSTANTS = [[
	local ENABLED_REMARKS = {
		NATIVE_REMARK = true,
		INLINE_REMARK = true
	}
	local DECOMPILER_TIMEOUT = ]] .. decompTimeout .. [[
		
	local READER_FLOAT_PRECISION = 7 -- up to 99
	local SHOW_INSTRUCTION_LINES = false
	local SHOW_REFERENCES = true
	local SHOW_OPERATION_NAMES = false
	local SHOW_MISC_OPERATIONS = false
	local LIST_USED_GLOBALS = true
	local RETURN_ELAPSED_TIME = false
	]]
			local _ENV = (getgenv or getrenv or getfenv)()
			local old = _ENV.decompile

			local f = loadstring(
				string.gsub(
					string.gsub(
						decompiler_source,
						"return %(x %% 2^32%) // %(2^disp%)",
						"return math.floor((x %% 2^32) / (2^disp))",
						1
					), -- TODO Temporary fix for macsploit (// operator)
					";;CONSTANTS HERE;;",
					CONSTANTS
				),
				"Advanced-Decompiler-V3"
			)
			if not f then
				return
			end
			f()
			custom_decompiler = _ENV.decompile
			_ENV.decompile = old
		end
	end
end

local SharedStrings = {}
local SharedString_identifiers = setmetatable({
	identifier = 1e15, -- 1 quadrillion, up to 9.(9) quadrillion, in theory this shouldn't ever run out and be enough for all sharedstrings ever imaginable
	-- TODO: worst case, add fallback to str randomizer once numbers run out : )
}, {
	__index = function(self, str)
		local Identifier = base64encode(tostring(self.identifier)) -- tostring is only needed for built-in base64encode, Reselim's doesn't need it as buffers autoconvert
		self.identifier = self.identifier + 1

		self[str] = Identifier -- ? The value of the md5 attribute is a Base64-encoded key. <SharedString> type elements use this key to refer to the value of the string. The value is the text content, whic[...]
		return Identifier
	end,
})

local Type_IDs = {
	string = 0x02,
	boolean = 0x03,
	-- float = 0x05,
	number = 0x06,
	UDim = 0x09,
	UDim2 = 0x0A,
	BrickColor = 0x0E,
	Color3 = 0x0F,
	Vector2 = 0x10,
	Vector3 = 0x11,
	CFrame = 0x14,
	EnumItem = 0x15,
	NumberSequence = 0x17,
	ColorSequence = 0x19,
	NumberRange = 0x1B,
	Rect = 0x1C,
	Font = 0x21,
}
local CFrame_Rotation_IDs = {
	["\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63"] = 0x02,
	["\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0"] = 0x03,
	["\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191"] = 0x05,
	["\0\0\128\63\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\191\0\0\0\0"] = 0x06,
	["\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191"] = 0x07,
	["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0"] = 0x09,
	["\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\63"] = 0x0a,
	["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0"] = 0x0c,
	["\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\63\0\0\0\0\0\0\0\0"] = 0x0d,
	["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0"] = 0x0e,
	["\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\63\0\0\0\0\0\0\0\0"] = 0x10,
	["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\128"] = 0x11,
	["\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191"] = 0x14,
	["\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\128"] = 0x15,
	["\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63"] = 0x17,
	["\0\0\128\191\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\191\0\0\0\128"] = 0x18,
	["\0\0\0\0\0\0\128\63\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63"] = 0x19,
	["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0"] = 0x1b,
	["\0\0\0\0\0\0\128\191\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\191"] = 0x1c,
	["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0"] = 0x1e,
	["\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\191\0\0\0\0\0\0\0\0"] = 0x1f,
	["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\0"] = 0x20,
	["\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\191\0\0\0\0\0\0\0\0"] = 0x22,
	["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\191\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\128"] = 0x23,
}
local Binary_Descriptors
Binary_Descriptors = {
	__SEQUENCE = function(raw, valueFormatter, keypointSize, Envelope)
		local Keypoints = raw.Keypoints
		local Keypoints_n = #Keypoints

		local len = 4 + (keypointSize or 12) * Keypoints_n
		local b = buffer.create(len)
		local offset = 0

		buffer.writeu32(b, offset, Keypoints_n)
		offset = offset + 4

		for _, keypoint in ipairs(Keypoints) do
			buffer.writef32(b, offset, Envelope or keypoint.Envelope)
			offset = offset + 4
			buffer.writef32(b, offset, keypoint.Time)
			offset = offset + 4

			local Value = keypoint.Value
			if valueFormatter then
				offset = offset + valueFormatter(Value, b, offset)
			else
				buffer.writef32(b, offset, Value)
				offset = offset + 4
			end
		end

		return b, len
	end,
	--------------------------------------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------
	["string"] = function(raw)
		local raw_len = #raw
		local len = 4 + raw_len

		local b = buffer.create(len)

		buffer.writeu32(b, 0, raw_len)
		buffer.writestring(b, 4, raw)

		return b, len
	end,
	["boolean"] = function(raw)
		local b = buffer.create(1)

		buffer.writeu8(b, 0, raw and 1 or 0)

		return b, 1
	end,
	["number"] = function(raw) -- double
		local b = buffer.create(8)

		buffer.writef64(b, 0, raw)

		return b, 8
	end,
	["UDim"] = function(raw)
		local b = buffer.create(8)

		buffer.writef32(b, 0, raw.Scale)
		buffer.writei32(b, 4, raw.Offset)

		return b, 8
	end,
	["UDim2"] = function(raw)
		local b = buffer.create(16)

		local Descriptors_UDim = Binary_Descriptors.UDim
		local X = Descriptors_UDim(raw.X)
		buffer.copy(b, 0, X)
		local Y = Descriptors_UDim(raw.Y)
		buffer.copy(b, 8, Y)

		return b, 16
	end,
	["BrickColor"] = function(raw)
		local b = buffer.create(4)

		buffer.writeu32(b, 0, raw.Number)

		return b, 4
	end,
	["Color3"] = function(raw)
		local b = buffer.create(12)

		buffer.writef32(b, 0, raw.R)
		buffer.writef32(b, 4, raw.G)
		buffer.writef32(b, 8, raw.B)

		return b, 12
	end,
	["Vector2"] = function(raw)
		local b = buffer.create(8)

		buffer.writef32(b, 0, raw.X)
		buffer.writef32(b, 4, raw.Y)

		return b, 8
	end,
	["Vector3"] = function(raw)
		local b = buffer.create(12)

		buffer.writef32(b, 0, raw.X)
		buffer.writef32(b, 4, raw.Y)
		buffer.writef32(b, 8, raw.Z)

		return b, 12
	end,
	["CFrame"] = function(raw)
		local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = raw:GetComponents()

		local rotation_ID = CFrame_Rotation_IDs[string.pack("<fffffffff", R00, R01, R02, R10, R11, R12, R20, R21, R22)]

		local len = rotation_ID and 13 or 49
		local b = buffer.create(len)

		-- ? TODO
		-- local write_vector3 = Descriptors.Vector3
		-- local pos = write_vector3(raw.Position)
		-- buffer.copy(b, 0, pos)

		buffer.writef32(b, 0, X)
		buffer.writef32(b, 4, Y)
		buffer.writef32(b, 8, Z)

		if rotation_ID then
			buffer.writeu8(b, 12, rotation_ID)
		else
			buffer.writeu8(b, 12, 0x0)

			-- ? TODO
			-- buffer.copy(b, 13, write_vector3(raw.XVector)) -- R00, R10, R20
			-- buffer.copy(b, 13 + 12, write_vector3(raw.YVector)) -- R01, R11, R21
			-- buffer.copy(b, 13 + 24, write_vector3(raw.ZVector)) -- R02, R12, R22

			buffer.writef32(b, 13, R00)
			buffer.writef32(b, 17, R01)
			buffer.writef32(b, 21, R02)

			buffer.writef32(b, 25, R10)
			buffer.writef32(b, 29, R11)
			buffer.writef32(b, 33, R12)

			buffer.writef32(b, 37, R20)
			buffer.writef32(b, 41, R21)
			buffer.writef32(b, 45, R22)
		end

		return b, len
	end,
	["EnumItem"] = function(raw)
		local b_Name, Name_size = Binary_Descriptors.string(tostring(raw.EnumType))

		local len = Name_size + 4
		local b = buffer.create(len)

		buffer.copy(b, 0, b_Name)
		buffer.writeu32(b, Name_size, raw.Value)

		return b, len
	end,
	["NumberSequence"] = nil,

	["ColorSequence"] = function(raw)
		return Binary_Descriptors.__SEQUENCE(raw, function(color3, b, offset)
			buffer.copy(b, offset, Binary_Descriptors.Color3(color3))
			return 12
		end, 20, 0)
	end,
	["NumberRange"] = function(raw)
		local b = buffer.create(8)

		buffer.writef32(b, 0, raw.Min)
		buffer.writef32(b, 4, raw.Max)

		return b, 8
	end,
	["Rect"] = function(raw)
		local b = buffer.create(16)

		local Descriptors_Vector2 = Binary_Descriptors.Vector2
		local Min = Descriptors_Vector2(raw.Min)
		buffer.copy(b, 0, Min)
		local Max = Descriptors_Vector2(raw.Max)
		buffer.copy(b, 8, Max)

		return b, 16
	end,
	["Font"] = function(raw)
		local Descriptors_string = Binary_Descriptors.string

		local b_Family, Family_size = Descriptors_string(raw.Family)
		local b_CachedFaceId, CachedFaceId_size = Descriptors_string("")

		local len = 3 + Family_size + CachedFaceId_size
		local b = buffer.create(len)

		buffer.writeu16(b, 0, raw.Weight.Value)
		buffer.writeu8(b, 2, raw.Style.Value)

		buffer.copy(b, 3, b_Family)
		buffer.copy(b, 3 + Family_size, b_CachedFaceId)

		return b, len
	end,
}
do
	Binary_Descriptors.NumberSequence = Binary_Descriptors.__SEQUENCE
end

local XML_Descriptors
XML_Descriptors = {
	__APIPRECISION = function(raw, precision)
		if raw == 0 or raw % 1 == 0 then
			return raw
		end

		local Extreme = XML_Descriptors.__EXTREME(raw)
		if Extreme then
			return Extreme
		end

		-- TODO: scientific notation formatting also takes place if value is a decimal (only counts if it starts with 0.) then values like 0.00008 will be formatted as 8.0000000000000006544e-05 ("%.19e"), i[...]
		-- ? The good part is compression of value so less file size BUT at the potential cost of precision loss

		return string.format("%." .. precision .. "f", raw)
	end,
	__BIT = function(...) -- * Credits to Friend (you know yourself)
		local Value = 0

		for i, bit in ipairs({ ... }) do
			if bit then
				Value = Value + 2 ^ (i - 1)
			end
		end

		return Value
	end,
	__CDATA = function(raw) -- ? Normally Roblox doesn't use CDATA unless the string has newline characters (\n); We rather CDATA everything for sake of speed
		return "<![CDATA[" .. raw .. "]]>"
	end,
	__ENUM = function(raw)
		return raw.Value, "token"
	end,
	__EXTREME = function(raw)
		local Extreme
		if raw ~= raw then
			Extreme = "NAN"
		elseif raw == math.huge then
			Extreme = "INF"
		elseif raw == -math.huge then
			Extreme = "-INF"
		end

		return Extreme
	end,
	__EXTREME_RANGE = function(raw)
		return raw ~= raw and "0" or raw -- Normally we should return "-nan(ind)" instead of "0" but this adds more compatibility
	end,
	__MINMAX = function(min, max, descriptor)
		return "<min>" .. descriptor(min) .. "</min><max>" .. descriptor(max) .. "</max>"
	end,
	__PROTECTEDSTRING = function(raw) -- ? its purpose is to "protect" data from being treated as ordinary character data during processing;
		return string_find(raw, "]]>") and string.gsub(raw, ESCAPES_PATTERN, ESCAPES) or XML_Descriptors.__CDATA(raw)
	end,
	__SEQUENCE = function(raw, valueFormatter) --The value is the text content, formatted as a space-separated list of floating point numbers.
		-- tostring(raw) also works (but way slower rn)
		local __EXTREME_RANGE = XML_Descriptors.__EXTREME_RANGE

		local Converted = ""

		for _, keypoint in ipairs(raw.Keypoints) do
			local Value = keypoint.Value

			Converted = Converted .. keypoint.Time .. " " .. (valueFormatter and valueFormatter(Value) or __EXTREME_RANGE(Value) .. " " .. __EXTREME_RANGE(
				keypoint.Envelope
			) .. " ") -- ? Trailing whitespace is only needed for lune compatibility
		end

		return Converted
	end,
	__VECTOR = function(X, Y, Z) -- Each element is a <float>
		local Value = "<X>" .. X .. "</X><Y>" .. Y .. "</Y>" -- There is no Vector without at least two Coordinates.. (Vector1, at least on Roblox)

		if Z then
			Value = Value .. "<Z>" .. Z .. "</Z>"
		end

		return Value
	end,
	--------------------------------------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------
	Axes = function(raw)
		--The text of this element is formatted as an integer between 0 and 7

		return "<axes>" .. XML_Descriptors.__BIT(raw.X, raw.Y, raw.Z) .. "</axes>"
	end,

	-- ? Roblox uses CDATA only for these (try to prove this wrong): CollisionGroupData, SmoothGrid, MaterialColors, PhysicsGrid
	-- ! Assuming all base64 encoded strings won't have newlines

	-- ! 7/7/24
	-- ! Fix for Electron v3
	-- ! Electron v3 'gethiddenproperty' automatically base64 encodes BinaryString values

	BinaryString = EXECUTOR_NAME == "Electron" and function(raw)
		return raw
	end or base64encode,

	BrickColor = function(raw)
		return raw.Number -- * Roblox encodes the tags as "int", but this is not required for Roblox to properly decode the type. For better compatibility, it is preferred that third-party implementations e[...]
	end,
	CFrame = function(raw)
		local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = raw:GetComponents()
		return XML_Descriptors.__VECTOR(X, Y, Z)
			.. "<R00>"
			.. R00
			.. "</R00><R01>"
			.. R01
			.. "</R01><R02>"
			.. R02
			.. "</R02><R10>"
			.. R10
			.. "</R10><R11>"
			.. R11
			.. "</R11><R12>"
			.. R12
			.. "</R12><R20>"
			.. R20
			.. "</R20><R21>"
			.. R21
			.. "</R21><R22>"
			.. R22
			.. "</R22>",
			"CoordinateFrame"
	end,
	Color3 = function(raw) -- Each element is a <float>
		return "<R>" .. raw.R .. "</R><G>" .. raw.G .. "</G><B>" .. raw.B .. "</B>" -- ? It is recommended that Color3 is encoded with elements instead of text.
	end,
	Color3uint8 = function(raw)
		-- https://github.com/rojo-rbx/rbx-dom/blob/master/docs/xml.md#color3uint8

		return 0xFF000000
			+ (math.floor(raw.R * 255) * 0x10000)
			+ (math.floor(raw.G * 255) * 0x100)
			+ math.floor(raw.B * 255) -- ? It is recommended that Color3uint8 is encoded with text instead of elements.

		-- return bit32.bor(
		-- 	bit32.bor(bit32.bor(bit32.lshift(0xFF, 24), bit32.lshift(0xFF * raw.R, 16)), bit32.lshift(0xFF * raw.G, 8)),
		-- 	0xFF * raw.B
		-- )

		-- return tonumber(string.format("0xFF%02X%02X%02X",raw.R*255,raw.G*255,raw.B*255))
	end,
	ColorSequence = function(raw)
		--The value is the text content, formatted as a space-separated list of FLOATing point numbers.

		return XML_Descriptors.__SEQUENCE(raw, function(color3)
			local __EXTREME_RANGE = XML_Descriptors.__EXTREME_RANGE

			return __EXTREME_RANGE(color3.R)
				.. " "
				.. __EXTREME_RANGE(color3.G)
				.. " "
				.. __EXTREME_RANGE(color3.B)
				.. " 0 "
		end)
	end,
	Content = function(raw)
		return raw == "" and "<null></null>" or "<url>" .. XML_Descriptors.string(raw, true) .. "</url>"
	end,
	CoordinateFrame = function(raw)
		return "<CFrame>" .. XML_Descriptors.CFrame(raw) .. "</CFrame>"
	end,
	-- DateTime = function(raw) return raw.UnixTimestampMillis end, -- TODO
	Faces = function(raw)
		-- The text of this element is formatted as an integer between 0 and 63
		return "<faces>"
			.. XML_Descriptors.__BIT(raw.Right, raw.Top, raw.Back, raw.Left, raw.Bottom, raw.Front)
			.. "</faces>"
	end,
	Font = function(raw)
		local FontString = tostring(raw) -- TODO: Temporary fix

		local EmptyWeight = string_find(FontString, "Weight = ,")
		local EmptyStyle = string_find(FontString, "Style =  }")

		return "<Family>"
			.. XML_Descriptors.Content(raw.Family)
			.. "</Family><Weight>"
			.. (EmptyWeight and "" or XML_Descriptors.__ENUM(raw.Weight))
			.. "</Weight><Style>"
			.. (EmptyStyle and "" or raw.Style.Name) -- Weird but this field accepts .Name of enum instead..
			.. "</Style>" --TODO (OPTIONAL ELEMENT): Figure out how to determine (Content) <CachedFaceId><url>rbxasset://fonts/GothamSSm-Medium.otf</url></CachedFaceId>
	end,
	NumberRange = function(raw) -- tostring(raw) also works
		--The value is the text content, formatted as a space-separated list of floating point numbers.
		local __EXTREME_RANGE = XML_Descriptors.__EXTREME_RANGE

		return __EXTREME_RANGE(raw.Min) .. " " .. __EXTREME_RANGE(raw.Max) --[[.. " "]] -- ! This might be required to bypass detections as thats how its formatted usually; __EXTREME_RANGE is not needed her[...]
	end,
	NumberSequence = nil,
	-- NumberSequence = Descriptors.__SEQUENCE,
	PhysicalProperties = function(raw)
		--[[Contains at least one CustomPhysics element, which is interpreted according to the bool type. If this value is true, then the tag also contains an element for each component of the PhysicalPrope[...]

    Density
    Friction
    Elasticity
    FrictionWeight
    ElasticityWeight

The value of each component is represented by the text content formatted as a 32-bit floating point number (see float).]]

		local CustomPhysics
		if raw then
			CustomPhysics = true
		else
			CustomPhysics = false
		end
		CustomPhysics = "<CustomPhysics>" .. XML_Descriptors.bool(CustomPhysics) .. "</CustomPhysics>"

		return raw
				and CustomPhysics .. "<Density>" .. raw.Density .. "</Density><Friction>" .. raw.Friction .. "</Friction><Elasticity>" .. raw.Elasticity .. "</Elasticity><FrictionWeight>" .. raw.FrictionWeight ..[...]
			or CustomPhysics
	end,
	-- ProtectedString = function(raw) return tostring(raw), "ProtectedString" end,
	Ray = function(raw)
		local vector3 = XML_Descriptors.Vector3

		return "<origin>" .. vector3(raw.Origin) .. "</origin><direction>" .. vector3(raw.Direction) .. "</direction>"
	end,
	Rect = function(raw)
		return XML_Descriptors.__MINMAX(raw.Min, raw.Max, XML_Descriptors.Vector2), "Rect2D"
	end,
	Region3 = function(raw) --? Not sure yet (https://github.com/ui0ppk/roblox-master/blob/main/Network/Replicator.cpp#L1306)
		local Translation = raw.CFrame.Position
		local HalfSize = raw.Size * 0.5

		return XML_Descriptors.__MINMAX(
			Translation - HalfSize, -- https://github.com/ui0ppk/roblox-master/blob/main/App/util/Region3.cpp#L38
			Translation + HalfSize, -- https://github.com/ui0ppk/roblox-master/blob/main/App/util/Region3.cpp#L42
			XML_Descriptors.Vector3
		)
	end,
	Region3int16 = function(raw) --? Not sure yet (https://github.com/ui0ppk/roblox-master/blob/main/App/v8tree/EnumProperty.cpp#L346)
		return XML_Descriptors.__MINMAX(raw.Min, raw.Max, XML_Descriptors.Vector3int16)
	end,
	SharedString = function(raw)
		raw = base64encode(raw)

		local Identifier = SharedString_identifiers[raw]

		if SharedStrings[Identifier] == nil then
			SharedStrings[Identifier] = raw
		end

		return Identifier
	end,
	UDim = function(raw)
		--[[
    S: Represents the Scale component. Interpreted as a <float>.
    O: Represents the Offset component. Interpreted as an <int>.
	]]

		return "<S>" .. raw.Scale .. "</S><O>" .. raw.Offset .. "</O>"
	end,
	UDim2 = function(raw)
		--[[
    XS: Represents the X.Scale component. Interpreted as a <float>.
    XO: Represents the X.Offset component. Interpreted as an <int>.
    YS: Represents the Y.Scale component. Interpreted as a <float>.
    YO: Represents the Y.Offset component. Interpreted as an <int>.
	]]

		local X, Y = raw.X, raw.Y

		return "<XS>"
			.. X.Scale
			.. "</XS><XO>"
			.. X.Offset
			.. "</XO><YS>"
			.. Y.Scale
			.. "</YS><YO>"
			.. Y.Offset
			.. "</YO>"
	end,

	-- UniqueId = function(raw)
	--[[
		     UniqueId properties might be random everytime Studio saves a place file
	 and don't have a use right now outside of packages, which SSI doesn't
	 account for anyway. They generate diff noise, so we shouldn't serialize
	 them until we have to.
	]]
	-- https://github.com/MaximumADHD/Roblox-Client-Tracker/blob/roblox/LuaPackages/Packages/_Index/ApolloClientTesting/ApolloClientTesting/utilities/common/makeUniqueId.lua#L62
	-- 	return "" -- ? No idea if this even needs a Descriptor
	-- end,

	Vector2 = function(raw)
		--[[
    X: Represents the X component. Interpreted as a <float>.
    Y: Represents the Y component. Interpreted as a <float>.
	]]
		return XML_Descriptors.__VECTOR(raw.X, raw.Y)
	end,
	Vector2int16 = nil,
	-- Vector2int16 = Descriptors.Vector2, -- except as <int>
	Vector3 = function(raw)
		--[[
    X: Represents the X component. Interpreted as a <float>.
    Y: Represents the Y component. Interpreted as a <float>.
    Z: Represents the Z component. Interpreted as a <float>.
	]]
		return XML_Descriptors.__VECTOR(raw.X, raw.Y, raw.Z)
	end,
	Vector3int16 = nil,
	-- Vector3int16 = Descriptors.Vector3, -- except as <int>\
	bool = function(raw)
		return raw and "true" or "false"
	end,
	double = function(raw) -- Float64
		return XML_Descriptors.__APIPRECISION(raw, 17) --? A precision of at least 17 is required to properly represent a 64-bit floating point value, so this amount is recommended.
	end, -- ? wouldn't float be better as an optimization
	float = function(raw) -- Float32
		return XML_Descriptors.__APIPRECISION(raw, 9) -- ? A precision of at least 9 is required to properly represent a 32-bit floating point value, so this amount is recommended.
	end,
	int = function(raw) -- Int32
		return XML_Descriptors.__EXTREME(raw) or raw
	end,
	int64 = nil,
	string = function(raw, skipEmptyCheck)
		return not skipEmptyCheck and raw == "" and raw
			or string_find(raw, "]]>") and string.gsub(raw, ESCAPES_PATTERN, ESCAPES)
			or XML_Descriptors.__CDATA(string.gsub(raw, "\0", ""))
	end,
}
for descriptorName, redirectName in pairs({
	NumberSequence = "__SEQUENCE",
	Vector2int16 = "Vector2",
	Vector3int16 = "Vector3",
	int64 = "int", -- Int64 (long)
}) do
	XML_Descriptors[descriptorName] = XML_Descriptors[redirectName]
end

local ClassList

do
	local ClassPropertyExceptions = { TriangleMeshPart = ArrayToDictionary({ "CollisionFidelity" }) }

	local function FetchAPI()
		-- * You can also use: https://setup.rbxcdn.com/{https://setup.rbxcdn.com/versionQTStudio}-Full-API-Dump.json
		-- * https://setup.rbxcdn.com/versionQTStudio seems to be a bit behind DeployHistory.txt
		local API_Dump
		if
			not pcall(function()
				local VERSIONS = version()

				local o, r = pcall(readfile, VERSIONS)
				if o and r and r ~= "" then
					API_Dump = r
					return
				end

				local latest_commit = service.HttpService:JSONDecode(
					game:HttpGet(
						"https://api.github.com/search/commits?sort=committer-date&order=desc&q=repo:MaximumADHD/Roblox-Client-Tracker+0."
							.. string.split(VERSIONS, ".")[2],
						true
					)
				).items[1]
				-- print(VERSIONS)
				-- print(latest_commit.commit.message)
				API_Dump = game:HttpGet(
					"https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/"
						.. latest_commit.sha
						.. "/Mini-API-Dump.json",
					true
				)

				writefile(VERSIONS, API_Dump) -- ? To avoid 60 requests / 1 h limit on GitHub Api
			end)
		then
			warn("Failed to get " .. version() .. " API Dump, trying latest..")
			API_Dump = game:HttpGet(
				"https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/Mini-API-Dump.json",
				true
			)
		end

		local classList = {}

		local decoded = service.HttpService:JSONDecode(API_Dump)
		for _, API_Class in ipairs(decoded.Classes) do
			local ClassProperties, ClassProperties_size = {}, 1
			local Class = {
				Properties = ClassProperties,
				Superclass = API_Class.Superclass,
			}

			local ClassTags = API_Class.Tags
			local ClassName = API_Class.Name

			if ClassTags then
				Class.Tags = ArrayToDictionary(ClassTags) -- or {}
			end

			-- ? Check 96ea8b2a755e55a78aedb55a7de7e83980e11077 commit - If a NotScriptableFix is needed that relies on another NotScriptable Property (which doesn't really make sense in the first place)

			local ClassExceptions = ClassPropertyExceptions[ClassName]

			for _, Member in ipairs(API_Class.Members) do
				if Member.MemberType == "Property" then
					local Serialization = Member.Serialization

					if Serialization.CanLoad then -- If Roblox doesn't save it why should we; If Roblox doesn't load it we don't need to save it
						--[[  -- ! CanSave replaces "Tags.Deprecated" check because there are some old properties which are deprecated yet have CanSave. 
						 Example: Humanoid.Health is CanSave false due to Humanoid.Health_XML being CanSave true (obsolete properties basically) - in this case both of them will Load. (aka PropertyPatches)
						 CanSave being on same level as CanLoad also fixes potential issues with overlapping properties like Color, Color3 & Color3uint8 of BasePart, out of which only Color3uint8 should save
						 This also fixes everything in IgnoreClassProperties automatically without need to hardcode :)
						 A very simple fix for many problems that saveinstance scripts encounter!
						--]]
						local PropertyName = Member.Name
						if Serialization.CanSave or ClassExceptions and ClassExceptions[PropertyName] then
							local MemberTags = Member.Tags

							local ValueType = Member.ValueType

							local Special

							if MemberTags then
								MemberTags = ArrayToDictionary(MemberTags)

								Special = MemberTags.NotScriptable
							end
							-- if not Special then
							ClassProperties[ClassProperties_size] = {
								Name = PropertyName,
								Category = ValueType.Category,
								-- Default = Member.Default,
								-- Tags = MemberTags,
								ValueType = ValueType.Name,

								Special = Special,

								CanRead = nil,
							}
							ClassProperties_size = ClassProperties_size + 1
							-- end
						end
					end
				end
			end

			classList[ClassName] = Class
		end

		-- classList.Instance.Properties.Parent = nil -- ? Not sure if this is a better option than filtering through properties to remove this

		return classList
	end

	local ok, result = pcall(FetchAPI)
	if ok then
		ClassList = result
	else
		warn("Failed to load the API Dump")
		warn(result)
		return
	end
end

local inherited_properties = {}
local default_instances = {}
local referents, ref_size = {}, 0 -- ? Roblox encodes all <Item> elements with a referent attribute. Each value is generated by starting with the prefix RBX, followed by a UUID version 4, with - chara[...]

local GLOBAL_ENV = getgenv and getgenv() or _G or shared

--[=[
    @class SynSaveInstance
    Represents the options for saving instances with custom settings using the synsaveinstance function.
]=]

--- @interface CustomOptions table
--- * Structure of the main CustomOptions table.
--- * Note: Aliases take priority over parent option name.
--- @within SynSaveInstance
--- @field __DEBUG_MODE boolean -- Recommended to enable if you wish to help us improve our products and find bugs / issues with it! ___Default:___ false
--- @field ReadMe boolean --___Default:___ true
--- @field SafeMode boolean -- Kicks you before Saving, which prevents you from being detected in any game. ___Default:___ false
--- @field Anonymous boolean -- Cleans the file of any info related to your account like: Name, UserId. This is useful for some games that might store that info in GUIs or other Instances. ___Default:[...]
--- @field ShowStatus boolean -- ___Default:___ true
--- @field mode string -- Change this to invalid mode like "invalid" if you only want ExtraInstances. "optimized" mode is **NOT** supported with *@Object* option. ___Default:___ "optimized"
--- @field noscripts boolean -- ___Aliases:___ `Decompile`. ___Default:___ false
--- @field scriptcache boolean -- ___Default:___ true
[...]
