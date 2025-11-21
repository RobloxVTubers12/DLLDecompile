--!native
--!optimize 2
--!divine-intellect
-- https://discord.gg/wx4ThpAsmw

local function string_find(s, pattern)
	return string.find(s, pattern, nil, true)
end

local function ArrayToDict(t, hydridMode, valueOverride, typeStrict)
	local tmp = {}

	if hydridMode then
		for any1, any2 in t do
			if type(any1) == "number" then
				tmp[any2] = valueOverride or true
			elseif type(any2) == "table" then
				tmp[any1] = ArrayToDict(any2, hydridMode) -- any1 is Class, any2 is Name
			else
				tmp[any1] = any2
			end
		end
	else
		for _, key in t do
			if not typeStrict or typeStrict and type(key) == typeStrict then
				tmp[key] = true
			end
		end
	end

	return tmp
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
		-- cloneref = 'string.find(...,"clone",nil,true) and string.find(...,"ref",nil,true)',
		-- decompile = '(string.find(...,"decomp",nil,true) and string.sub(...,#...) ~= "s")',
		gethiddenproperty = 'string.find(...,"get",nil,true) and string.find(...,"h",nil,true) and string.find(...,"prop",nil,true) and string.sub(...,#...) ~= "s"',
		gethui = 'string.find(...,"get",nil,true) and string.find(...,"h",nil,true) and string.find(...,"ui",nil,true)',
		-- getcon = 'string.find(...,"get",nil,true) and (string.find(...,"conn",nil,true) or string.find(...,"sig",nil,true)) and string.sub(...,#(...))=="s"',
		getnilinstances = 'string.find(...,"nil",nil,true) and string.find(...,"get",nil,true) and string.sub(...,#...) == "s"', -- ! Could match some unwanted stuff
		getscriptbytecode = 'string.find(...,"get",nil,true) and string.find(...,"bytecode",nil,true)', --  or string.find(...,"dump",nil,true) and string.find(...,"string",nil,true) due to Fluxus (dump[...]
		-- hash = 'local a={...}local b=a[1]local function c(a,b)return string.find(a,b,nil,true)end;return c(b,"hash")and c(string.lower(tostring(a[2])),"crypt")',
		protectgui = 'string.find(...,"protect",nil,true) and string.find(...,"ui",nil,true) and not string.find(...,"un",nil,true)',
		setthreadidentity = 'string.find(...,"identity",nil,true) and string.find(...,"set",nil,true)',
	}, true, 10)
end

local identify_executor = identifyexecutor or getexecutorname or whatexecutor

local EXECUTOR_NAME = identify_executor and identify_executor() or ""

-- local cloneref = global_container.cloneref
local gethiddenproperty = global_container.gethiddenproperty

-- These should be universal enough
local appendfile = appendfile
local isfile = isfile
local readfile = readfile
local writefile = writefile

local getscriptbytecode = global_container.getscriptbytecode -- * A lot of assumptions are made based on whether this function is defined or not. So in certain edge cases, like if the executor defines[...]
local base64encode = global_container.base64encode

local service = setmetatable({}, {
	__index = function(self, serviceName)
		local o, s = pcall(Instance.new, serviceName)
		local Service = o and s
			or game:GetService(serviceName)
			or settings():GetService(serviceName)
			or UserSettings():GetService(serviceName)

		-- if cloneref then
		-- 	Service = cloneref(Service)
		-- end
		if Service then
			self[serviceName] = Service
		end
		return Service
	end,
})

local gethiddenproperty_fallback
do -- * Load Region of Déjà Vu
	local UGCValidationService -- = service.UGCValidationService

	gethiddenproperty_fallback = function(instance, propertyName)
		if not UGCValidationService then
			UGCValidationService = service.UGCValidationService
		end
		return UGCValidationService:GetPropertyValue(instance, propertyName) -- TODO Sadly there's no way to tell whether value is actually nil or the function just couldn't read it (always returns nil[...]
		-- TODO `category ~= "Class"` causes WeldConstraint Part1Internal to be read as nil and not get unfiltered. Currently, there are no properties of category "Class" that match the following: NotScript[...]
	end
	if gethiddenproperty then
		local o, r = pcall(gethiddenproperty, workspace, "StreamOutBehavior")
		if not o or r ~= nil and typeof(r) ~= "EnumItem" then -- * Tests if gethiddenproperty is broken
			gethiddenproperty = nil
		else
			o, r = pcall(gethiddenproperty, Instance.new("AnimationRigData", Instance.new("Folder")), "parent") -- * Tests how it reacts to property overlap (shadowing) due to AnimationRigData.parent; expected[...]

			if o and r ~= nil and type(r) ~= "string" then
				gethiddenproperty = nil
			end
		end
	end
	local function benchmark(funcs, ...)
		local ranking = table.create(2)
		for i, f in funcs do
			local start = os.clock()
			for _ = 1, 50 do
				f(...)
			end
			ranking[i] = { t = os.clock() - start, f = f }
		end
		table.sort(ranking, function(a, b)
			return a.t < b.t
		end)
		return ranking[1].f
	end

	local test_str = string.rep("\1\0\0\0\1\2\3\4\5\6\7", 50)

	do
		if not bit32.byteswap or not pcall(bit32.byteswap, 1) then -- Because Fluxus is missing byteswap
			bit32 = table.clone(bit32)

			local function tobit(num)
				num %= (bit32.bxor(num, 32))
				if 0x80000000 < num then
					num -= bit32.bxor(num, 32)
				end
				return num
			end

			bit32.byteswap = function(num)
				local BYTE_SIZE = 8
				local MAX_BYTE_VALUE = 255

				num %= bit32.bxor(2, 32)

				local a = bit32.band(num, MAX_BYTE_VALUE)
				num = bit32.rshift(num, BYTE_SIZE)

				local b = bit32.band(num, MAX_BYTE_VALUE)
				num = bit32.rshift(num, BYTE_SIZE)

				local c = bit32.band(num, MAX_BYTE_VALUE)
				num = bit32.rshift(num, BYTE_SIZE)

				local d = bit32.band(num, MAX_BYTE_VALUE)
				num = tobit(bit32.lshift(bit32.lshift(bit32.lshift(a, BYTE_SIZE) + b, BYTE_SIZE) + c, BYTE_SIZE) + d)
				return num
			end

			table.freeze(bit32)
		end

		-- Credits @daily3014 & @XoifaiI
		local rbxcrypt_base64encode
		pcall(function()
			local b64_enc_buf = loadstring(
				game:HttpGet(
					"https://raw.githubusercontent.com/daily3014/rbx-cryptography/refs/heads/main/src/Utilities/Base64.luau",
					true
				),
				"Base64"
			)().Encode
			rbxcrypt_base64encode = function(raw)
				return buffer.tostring(b64_enc_buf(buffer.fromstring(raw)))
			end
		end)

		local EncodingService = game:GetService("EncodingService")
		local EncodingService_base64encode = function(raw)
			return buffer.tostring(EncodingService:Base64Encode(buffer.fromstring(raw)))
		end

		-- * Tests if base64encode exists and works properly then benchmark it
		if base64encode and base64encode("\1\0\0\0\1") == "AQAAAAE=" then
			if rbxcrypt_base64encode then
				base64encode =
					benchmark({ base64encode, rbxcrypt_base64encode, EncodingService_base64encode }, test_str)
			end
		else
			base64encode = rbxcrypt_base64encode
		end

		assert(base64encode, "base64encode not found")
	end
end

local SharedStrings = {}
local SharedString_identifiers = setmetatable({
	identifier = 1e15, -- 1 quadrillion, up to 9.(9) quadrillion, in theory this shouldn't ever run out and be enough for all sharedstrings ever imaginable
	-- TODO: worst case, add fallback to str randomizer once numbers run out : )
}, {
	__index = function(self, str)
		local Identifier = base64encode(tostring(self.identifier)) -- tostring is only needed for built-in base64encode, Luau base64 implementations don't need it as buffers autoconvert
		self.identifier += 1

		self[str] = Identifier -- ? The value of the md5 attribute is a Base64-encoded key. <SharedString> type elements use this key to refer to the value of the string. The value is the text content,[...]
		return Identifier
	end,
})

local inherited_properties = {}
local default_instances = {}
local referents, ref_size = {}, 0 -- ? Roblox encodes all <Item> elements with a referent attribute. Each value is generated by starting with the prefix RBX, followed by a UUID version 4, with - chara[...]

local function GetRef(instance)
	local ref = referents[instance]
	if not ref then
		ref = ref_size
		referents[instance] = ref
		ref_size += 1
	end
	return ref
end

local function index(self, index_name)
	return self[index_name]
end

local version = version
if not version then
	version = function()
		return "UNKNOWN"
	end
end

local CLIENT_VERSION = tonumber(string.split(version(), ".")[2]) or 9e9 -- Velocity temp fix

local attr_Type_IDs = {
	string = 0x02,
	boolean = 0x03,
	int32 = 0x04,
	-- float = 0x05, -- float32
	number = 0x06, -- float64 (double)
	-- Array = 0x07,
	-- Dictionary = 0x08,
	UDim = 0x09,
	UDim2 = 0x0A,
	Ray = 0x0B,
	Faces = 0x0C,
	Axes = 0x0D,
	BrickColor = 0x0E,
	Color3 = 0x0F,
	Vector2 = 0x10,
	Vector3 = 0x11,
	Vector2int16 = 0x12,
	Vector3int16 = 0x13,
	CFrame = 0x14,
	EnumItem = 0x15,
	NumberSequence = 0x17,
	NumberSequenceKeypoint = 0x18,
	ColorSequence = 0x19,
	ColorSequenceKeypoint = 0x1A,
	NumberRange = 0x1B,
	Rect = 0x1C,
	PhysicalProperties = 0x1D,
	Region3 = 0x1F,
	Region3int16 = 0x20,
	Font = 0x21,
	SecurityCapabilities = 0x22,
	Path2DControlPoint = 0x23,
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
local BASE_CAPABILITIES
pcall(function()
	BASE_CAPABILITIES = SecurityCapabilities.new()
end)
local CAPABILITY_BITS = {
	Plugin = 2 ^ 0, ----------------  0
	LocalUser = 2 ^ 1, -------------  1
	WritePlayer = 2 ^ 2, -----------  2
	RobloxScript = 2 ^ 3, ----------  3
	RobloxEngine = 2 ^ 4, ----------  4
	NotAccessible = 2 ^ 5, ---------  5
	RunClientScript = 2 ^ 8, -------  8
	RunServerScript = 2 ^ 9, -------  9
	Unknown = 2 ^ 10, --------------  10 (0xa)
	AccessOutsideWrite = 2 ^ 11, ---  11 (0xb)
	Unassigned = 2 ^ 15, -----------  15 (0xf)
	AssetRequire = 2 ^ 16, ---------  16 (0x10)
	LoadString = 2 ^ 17, -----------  17 (0x11)
	ScriptGlobals = 2 ^ 18, --------  18 (0x12)
	CreateInstances = 2 ^ 19, ------  19 (0x13)
	Basic = 2 ^ 20, ----------------  20 (0x14)
	Audio = 2 ^ 21, ----------------  21 (0x15)
	DataStore = 2 ^ 22, ------------  22 (0x16)
	Network = 2 ^ 23, --------------  23 (0x17)
	Physics = 2 ^ 24, --------------  24 (0x18)
	UI = 2 ^ 25, -------------------  25 (0x19)
	CSG = 2 ^ 26, ------------------  26 (0x1a)
	Chat = 2 ^ 27, -----------------  27 (0x1b)
	Animation = 2 ^ 28, ------------  28 (0x1c)
	Avatar = 2 ^ 29, ---------------  29 (0x1d)
	Input = 2 ^ 30, ----------------  30 (0x1e)
	Environment = 2 ^ 31, ----------  31 (0x1f)
	RemoteEvent = 2 ^ 32, ----------  32 (0x20)
	LegacySound = 2 ^ 33, ----------  33 (0x21)
	Players = 2 ^ 34, --------------  34 (0x22)
	CapabilityControl = 2 ^ 35, ----  35 (0x23)
	RemoteCommand = 2 ^ 59, --------  59 (0x3b)
	InternalTest = 2 ^ 60, ---------  60 (0x3c), Related to TestingGameScript
	PluginOrOpenCloud = 2 ^ 61, ----  61 (0x3d)
	Assistant = 2 ^ 62, ------------  62 (0x3e)
	-- Restricted = 2 ^ 63, --------  for negative (highest bit for i64)
}

local function __COUNT_CAPABILITY_BITS(raw)
	-- TODO tostring & string.split aren't ideal but this is the only way until the feature is out of the experimental phase (SecurityCapabilities.Contains exists but the Enums that it accepts lacks[...]
	-- ! Seems like both tostring & .Contains ignore high / internal bits (anything above CapabilityControl): RemoteCommand, InternalTest, PluginOrOpenCloud, Assistant. They're present when created [...]
	
	local result = 0
	for _, flag in string.split(tostring(raw), " | ") do
		local bit = CAPABILITY_BITS[flag]
		if bit then
			result += bit
		end
	end
	return result
end

local function __COUNT_BITS(...) -- * Credits to Friend (you know yourself)
	local Value = 0

	for i, bit in { ... } do
		if bit then
			Value += 2 ^ (i - 1)
		end
	end

	return Value
end

local Binary_Descriptors
Binary_Descriptors = {
	__PACK_MULTIPLE = function(descriptor, value1, value2, value3)
		local buf1, size1 = descriptor(value1)
		local buf2, size2 = descriptor(value2)

		local len = size1 + size2
		local buf3, size3

		if value3 ~= nil then
			buf3, size3 = descriptor(value3)
			len += size3
		end

		local b = buffer.create(len)

		buffer.copy(b, 0, buf1)
		buffer.copy(b, size1, buf2)

		if value3 ~= nil then
			buffer.copy(b, size1 + size2, buf3)
		end

		return b, len
	end,
	__construct_Sequence = function(keypoint_handler, keypointSize)
		return function(raw)
			local Keypoints = raw.Keypoints
			local Keypoints_n = #Keypoints

			local len = 4 + keypointSize * Keypoints_n
			local b = buffer.create(len)

			buffer.writeu32(b, 0, Keypoints_n)

			local offset = 4
			for _, keypoint in Keypoints do
				keypoint_handler(keypoint, b, offset)
				offset += keypointSize
			end

			return b, len
		end
	end,
	__writei64 = function(b, offset, raw)
		local low = bit32.band(raw, 0xFFFFFFFF)
		local high = (raw - low) / 0x100000000

		buffer.writei32(b, offset, low)
		buffer.writei32(b, offset + 4, high)
	end,
	__PACK_F32 = nil,
	__PACK_I16 = nil,
	__construct__PACKER = function(float)
		local writeFunc = float and buffer.writef32 or buffer.writei16
		local elementSize = float and 4 or 2

		-- local zbuf, nozbuf = buffer.create(elementSize * 3), buffer.create(elementSize * 2)

		return function(X, Y, Z)
			local len = Z and (elementSize * 3) or (elementSize * 2)
			local b = buffer.create(len)

			writeFunc(b, 0, X)
			writeFunc(b, elementSize, Y)
			if Z then
				writeFunc(b, elementSize * 2, Z)
			end

			return b, len
		end
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
		return Binary_Descriptors.__PACK_MULTIPLE(Binary_Descriptors["UDim"], raw.X, raw.Y)
	end,
	["Ray"] = function(raw)
		return Binary_Descriptors.__PACK_MULTIPLE(Binary_Descriptors["Vector3"], raw.Origin, raw.Direction)
	end,
	["Faces"] = function(raw)
		local b = buffer.create(4)

		buffer.writeu32(b, 0, __COUNT_BITS(raw.Right, raw.Top, raw.Back, raw.Left, raw.Bottom, raw.Front))

		return b, 4
	end,
	["Axes"] = function(raw)
		local b = buffer.create(4)

		buffer.writeu32(b, 0, __COUNT_BITS(raw.X, raw.Y, raw.Z))

		return b, 4
	end,
	["BrickColor"] = function(raw)
		local b = buffer.create(4)

		buffer.writeu32(b, 0, raw.Number)

		return b, 4
	end,
	["Color3"] = function(raw)
		return Binary_Descriptors.__PACK_F32(raw.R, raw.G, raw.B)
	end,
	["Vector2"] = function(raw)
		return Binary_Descriptors.__PACK_F32(raw.X, raw.Y)
	end,
	["Vector3"] = function(raw)
		return Binary_Descriptors.__PACK_F32(raw.X, raw.Y, raw.Z)
	end,
	["Vector2int16"] = function(raw)
		return Binary_Descriptors.__PACK_I16(raw.X, raw.Y)
	end,
	["Vector3int16"] = function(raw)
		return Binary_Descriptors.__PACK_I16(raw.X, raw.Y, raw.Z)
	end,
	["CFrame"] = function(raw)
		local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = raw:GetComponents()
		local rotation_ID
		do
			local b = buffer.create(36)

			buffer.writef32(b, 0, R00)
			buffer.writef32(b, 4, R01)
			buffer.writef32(b, 8, R02)
			buffer.writef32(b, 12, R10)
			buffer.writef32(b, 16, R11)
			buffer.writef32(b, 20, R12)
			buffer.writef32(b, 24, R20)
			buffer.writef32(b, 28, R21)
			buffer.writef32(b, 32, R22)

			rotation_ID = CFrame_Rotation_IDs[buffer.tostring(b)]
		end

		local len = rotation_ID and 13 or 49
		local b = buffer.create(len)

		local __PACK_F32 = Binary_Descriptors.__PACK_F32
		local position = __PACK_F32(X, Y, Z)
		buffer.copy(b, 0, position)
		-- buffer.writef32(b, 0, X)
		-- buffer.writef32(b, 4, Y)
		-- buffer.writef32(b, 8, Z)

		if rotation_ID then
			buffer.writeu8(b, 12, rotation_ID)
		else
			buffer.writeu8(b, 12, 0x0)

			local xBasis = __PACK_F32(R00, R01, R02)
			buffer.copy(b, 13, xBasis)
			local yBasis = __PACK_F32(R10, R11, R12)
			buffer.copy(b, 13 + 12, yBasis)
			local zBasis = __PACK_F32(R20, R21, R22)
			buffer.copy(b, 13 + 24, zBasis)

			-- buffer.writef32(b, 13, R00)
			-- buffer.writef32(b, 17, R01)
			-- buffer.writef32(b, 21, R02)

			-- buffer.writef32(b, 25, R10)
			-- buffer.writef32(b, 29, R11)
			-- buffer.writef32(b, 33, R12)

			-- buffer.writef32(b, 37, R20)
			-- buffer.writef32(b, 41, R21)
			-- buffer.writef32(b, 45, R22)
		end

		return b, len
	end,
	["EnumItem"] = function(raw)
		local b_Name, Name_size = Binary_Descriptors["string"](tostring(raw.EnumType))

		local len = Name_size + 4
		local b = buffer.create(len)

		buffer.copy(b, 0, b_Name)
		buffer.writeu32(b, Name_size, raw.Value)

		return b, len
	end,
	["NumberSequence"] = nil,
	["NumberSequenceKeypoint"] = function(keypoint, b, offset)
		if not b then
			return Binary_Descriptors.__PACK_F32(keypoint.Envelope, keypoint.Time, keypoint.Value)
		end

		buffer.writef32(b, offset, keypoint.Envelope)
		offset += 4
		buffer.writef32(b, offset, keypoint.Time)
		offset += 4
		buffer.writef32(b, offset, keypoint.Value)
	end,
	["ColorSequence"] = nil,
	["ColorSequenceKeypoint"] = function(keypoint, b, offset)
		local Value = Binary_Descriptors["Color3"](keypoint.Value)

		if not b then
			b = buffer.create(20)
			offset = 0
		end

		buffer.writef32(b, offset, 0)
		offset += 4
		buffer.writef32(b, offset, keypoint.Time)
		offset += 4
		buffer.copy(b, offset, Value)

		return b, 20
	end,
	["NumberRange"] = function(raw)
		return Binary_Descriptors.__PACK_F32(raw.Min, raw.Max)
	end,
	["Rect"] = function(raw)
		return Binary_Descriptors.__PACK_MULTIPLE(Binary_Descriptors["Vector2"], raw.Min, raw.Max)
	end,
	["PhysicalProperties"] = function(raw) -- ? Not sure yet (https://github.com/RobloxAPI/spec/blob/master/properties/drafts/AttributesSerializeFull.md#physicalproperties)
		local len = 1
		if raw then
			len += 24
		end
		local b = buffer.create(len)

		buffer.writeu8(b, 0, raw and 3 or 0) -- 3 means it has set CustomPhysicalProperties & has set AcousticAbsorption

		if raw then
			buffer.writef32(b, 1, raw.Density)
			buffer.writef32(b, 5, raw.Friction)
			buffer.writef32(b, 9, raw.Elasticity)
			buffer.writef32(b, 13, raw.FrictionWeight)
			buffer.writef32(b, 17, raw.ElasticityWeight)
			buffer.writef32(b, 21, raw.AcousticAbsorption)
		end

		return b, len
	end,
	["Region3"] = function(raw)
		local Translation = raw.CFrame.Position
		local HalfSize = raw.Size * 0.5

		return Binary_Descriptors.__PACK_MULTIPLE(
			Binary_Descriptors["Vector3"],
			Translation - HalfSize, -- /App/util/Region3.cpp#L38
			Translation + HalfSize -- /App/util/Region3.cpp#L42
		)
	end,
	["Region3int16"] = function(raw)
		return Binary_Descriptors.__PACK_MULTIPLE(Binary_Descriptors["Vector3int16"], raw.Min, raw.Max)
	end,
	["Font"] = 636 < CLIENT_VERSION and function(raw)
		local string__descriptor = Binary_Descriptors["string"]

		local b_Family, Family_size = string__descriptor(raw.Family)
		local b_CachedFaceId, CachedFaceId_size = string__descriptor("")

		local len = 3 + Family_size + CachedFaceId_size
		local b = buffer.create(len)

		local ok_w, weight = pcall(index, raw, "Weight")
		local ok_s, style = pcall(index, raw, "Style")

		buffer.writeu16(b, 0, ok_w and weight.Value or 0)
		buffer.writeu8(b, 2, ok_s and style.Value or 0)

		buffer.copy(b, 3, b_Family)
		buffer.copy(b, 3 + Family_size, b_CachedFaceId)

		return b, len
	end or function(raw)
		local string__descriptor = Binary_Descriptors["string"]

		local b_Family, Family_size = string__descriptor(raw.Family)
		local b_CachedFaceId, CachedFaceId_size = string__descriptor("")

		local len = 3 + Family_size + CachedFaceId_size
		local b = buffer.create(len)

		local FontString = tostring(raw)

		local EmptyWeight = string_find(FontString, "Weight = ,")
		local EmptyStyle = string_find(FontString, "Style =  }")

		buffer.writeu16(b, 0, EmptyWeight and 0 or raw.Weight.Value)
		buffer.writeu8(b, 2, EmptyStyle and 0 or raw.Style.Value)

		buffer.copy(b, 3, b_Family)
		buffer.copy(b, 3 + Family_size, b_CachedFaceId)

		return b, len
	end,
	["SecurityCapabilities"] = function(raw)
		local b = buffer.create(8)

		if raw == BASE_CAPABILITIES then
			return b, 8
		end

		Binary_Descriptors.__writei64(b, 0, __COUNT_CAPABILITY_BITS(raw))

		return b, 8
	end,
	["Path2DControlPoint"] = function(raw)
		return Binary_Descriptors.__PACK_MULTIPLE(
			Binary_Descriptors["UDim2"],
			raw.Position,
			raw.LeftTangent,
			raw.RightTangent
		)
	end,
}

do -- Sequences
	Binary_Descriptors["NumberSequence"] =
		Binary_Descriptors.__construct_Sequence(Binary_Descriptors["NumberSequenceKeypoint"], 12)

	Binary_Descriptors["ColorSequence"] =
		Binary_Descriptors.__construct_Sequence(Binary_Descriptors["ColorSequenceKeypoint"], 20)
end

do -- Vectors
	Binary_Descriptors.__PACK_F32 = Binary_Descriptors.__construct__PACKER(true)

	Binary_Descriptors.__PACK_I16 = Binary_Descriptors.__construct__PACKER()
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

local XML_Descriptors
XML_Descriptors = {
	__CDATA = function(raw) -- ? Normally Roblox doesn't use CDATA unless the string has newline characters (\n); We rather CDATA everything for sake of speed
		return "<![CDATA[" .. raw .. "]]>"
	end,
	__ENUM = function(raw)
		return raw.Value, "token"
	end,
	__NORMALIZE_NUMBER = function(raw)
		if raw ~= raw then
			return "NAN"
		elseif raw == math.huge then
			return "INF"
		elseif raw == -math.huge then
			return "-INF"
		end

		return raw
	end,
	__NORMALIZE_RANGE = function(raw)
		return raw ~= raw and "0" or raw -- Normally we should return "-nan(ind)" instead of "0" but this adds more compatibility
	end,
	__MINMAX = function(min, max, descriptor)
		return "<min>" .. descriptor(min) .. "</min><max>" .. descriptor(max) .. "</max>"
	end,
	__PROTECTEDSTRING = function(raw) -- ? its purpose is to "protect" data from being treated as ordinary character data during processing;
		return string_find(raw, "]]>") and string.gsub(raw, ESCAPES_PATTERN, ESCAPES) or XML_Descriptors.__CDATA(raw)
	end,
	__construct_Sequence = function(keypoint_handler)
		-- The value is the text content, formatted as a space-separated list of floating point numbers.
		-- tostring(raw) also works (but way slower rn)
		-- ? Trailing whitespace after Envelope is needed for lune compatibility
		return function(raw)
			local sequence = ""

			for _, keypoint in raw.Keypoints do
				sequence ..= keypoint_handler(keypoint)
			end

			return sequence
		end
	end,
	__VECTOR = function(X, Y, Z) -- Each element is a <float>
		local Value = "<X>" .. X .. "</X><Y>" .. Y .. "</Y>" -- There is no Vector without at least two Coordinates.. (Vector1, at least on Roblox)

		if Z then
			Value ..= "<Z>" .. Z .. "</Z>"
		end

		return Value
	end,
	--------------------------------------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------
	Axes = function(raw)
		-- The text of this element is formatted as an integer between 0 and 7

		return "<axes>" .. __COUNT_BITS(raw.X, raw.Y, raw.Z) .. "</axes>"
	end,

	-- ! Assuming all base64 encoded strings won't have newlines

	BinaryString = function(raw)
		return raw == "" and "" or base64encode(raw)
	end,

	BrickColor = function(raw)
		return raw.Number -- * Roblox encodes the tags as "int", but this is not required for Roblox to properly decode the type. For better compatibility, it is preferred that third-party implementati[...]
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
		-- ? It is recommended that Color3uint8 is encoded with text instead of elements.

		return 0xFF000000
			+ (math.floor(raw.R * 255) * 0x10000)
			+ (math.floor(raw.G * 255) * 0x100)
			+ math.floor(raw.B * 255)
		-- return bit32.bor(
		-- 	bit32.bor(bit32.bor(bit32.lshift(0xFF, 24), bit32.lshift(0xFF * raw.R, 16)), bit32.lshift(0xFF * raw.G, 8)),
		-- 	0xFF * raw.B
		-- )

		-- return tonumber(string.format("0xFF%02X%02X%02X",raw.R*255,raw.G*255,raw.B*255))
	end,
	ColorSequence = nil,
	ColorSequenceKeypoint = function(keypoint)
		local __NORMALIZE_RANGE = XML_Descriptors.__NORMALIZE_RANGE

		local color3 = keypoint.Value

		return __NORMALIZE_RANGE(keypoint.Time)
			.. " "
			.. __NORMALIZE_RANGE(color3.R)
			.. " "
			.. __NORMALIZE_RANGE(color3.G)
			.. " "
			.. __NORMALIZE_RANGE(color3.B)
			.. " 0 "
	end,
	Content = function(raw) -- TODO Not sure about Object & Opaque, run tests when possible
		local SourceType = raw.SourceType
		return SourceType == Enum.ContentSourceType.None and "<null></null>"
			or SourceType == Enum.ContentSourceType.Uri and "<uri>" .. XML_Descriptors.string(raw.Uri) .. "</uri>"
			or SourceType == Enum.ContentSourceType.Object and "<Ref>" .. GetRef(raw.Object) .. "</Ref>"
			or SourceType == Enum.ContentSourceType.Opaque and "<Ref>" .. GetRef(raw.Opaque) .. "</Ref>"
	end,
	ContentId = function(raw)
		return raw == "" and "<null></null>" or "<url>" .. XML_Descriptors.string(raw) .. "</url>", "Content" -- TODO Remove "Content" str once Roblox fully releases Content DataType
	end,
	CoordinateFrame = function(raw)
		return "<CFrame>" .. XML_Descriptors.CFrame(raw) .. "</CFrame>"
	end,
	-- DateTime = function(raw) return raw.UnixTimestampMillis end, -- ? Not sure
	Faces = function(raw)
		-- The text of this element is formatted as an integer between 0 and 63
		return "<faces>" .. __COUNT_BITS(raw.Right, raw.Top, raw.Back, raw.Left, raw.Bottom, raw.Front) .. "</faces>"
	end,
	Font = 636 < CLIENT_VERSION
			and function(raw)
				-- TODO (OPTIONAL ELEMENT): Figure out how to determine (ContentId) <CachedFaceId><url>rbxasset://fonts/GothamSSm-Medium.otf</url></CachedFaceId>
				--[[
		? game:GetService("TextService"):GetFontMemoryData()
		? rbxasset://fonts/families/{Enum.Font.BuilderSans.Name}.json
		]]

				local ok_w, weight = pcall(index, raw, "Weight")
				local ok_s, style = pcall(index, raw, "Style")

				return "<Family>"
					.. XML_Descriptors.ContentId(raw.Family)
					.. "</Family><Weight>"
					.. (ok_w and XML_Descriptors.__ENUM(weight) or "")
					.. "</Weight><Style>"
					.. (ok_s and style.Name or "") -- Weird but this field accepts .Name of enum instead..
					.. "</Style>"
			end
		or function(raw)
			local FontString = tostring(raw) -- TODO: Temporary fix

			local EmptyWeight = string_find(FontString, "Weight = ,")
			local EmptyStyle = string_find(FontString, "Style =  }")

			return "<Family>"
				.. XML_Descriptors.ContentId(raw.Family)
				.. "</Family><Weight>"
				.. (EmptyWeight and "" or XML_Descriptors.__ENUM(raw.Weight))
				.. "</Weight><Style>"
				.. (EmptyStyle and "" or raw.Style.Name) -- Weird but this field accepts .Name of enum instead..
				.. "</Style>"
		end,
	NetAssetRef = nil,
	NumberRange = function(raw) -- tostring(raw) also works
		-- The value is the text content, formatted as a space-separated list of floating point numbers.
		local __NORMALIZE_RANGE = XML_Descriptors.__NORMALIZE_RANGE

		return __NORMALIZE_RANGE(raw.Min) .. " " .. __NORMALIZE_RANGE(raw.Max) --[[.. " "]] -- ! This might be required for compatibility; __NORMALIZE_RANGE is not needed here but it fixes the issue wh[...]
	end,
	NumberSequence = nil,
	NumberSequenceKeypoint = function(keypoint)
		local __NORMALIZE_RANGE = XML_Descriptors.__NORMALIZE_RANGE

		return __NORMALIZE_RANGE(keypoint.Time)
			.. " "
			.. __NORMALIZE_RANGE(keypoint.Value)
			.. " "
			.. __NORMALIZE_RANGE(keypoint.Envelope)
			.. " "
	end,
	-- Path2DControlPoint = function(raw)  -- ? Not sure
	-- 	local udim2 = XML_Descriptors.UDim2
	-- 	return "<Position>"
	-- 		.. udim2(raw.Position)
	-- 		.. "</Position>"
	-- 		.. "<LeftTangent>"
	-- 		.. udim2(raw.LeftTangent)
	-- 		.. "</LeftTangent>"
	-- 		.. "<RightTangent>"
	-- 		.. udim2(raw.RightTangent)
	-- 		.. "</RightTangent>"
	-- end,

	PhysicalProperties = function(raw)
		--[[
			Contains at least one CustomPhysics element, which is interpreted according to the bool type. If this value is true, then the tag also contains an element for each component of the PhysicalPro[...]
		
			Density
			Friction
			Elasticity
			FrictionWeight
			ElasticityWeight
			AcousticAbsorption

			The value of each component is represented by the text content formatted as a 32-bit floating point number (see float)
		]]

		local CustomPhysics = "<CustomPhysics>" .. XML_Descriptors.bool(raw and true or false) .. "</CustomPhysics>"

		return raw
				and CustomPhysics .. "<Density>" .. raw.Density .. "</Density><Friction>" .. raw.Friction .. "</Friction><Elasticity>" .. raw.Elasticity .. "</Elasticity><FrictionWeight>" .. raw.FrictionWeig[...]
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
	Region3 = function(raw) -- ? Not sure about xml format yet, the math is correct though (/Network/Replicator.cpp#L1306)
		local Translation = raw.CFrame.Position
		local HalfSize = raw.Size * 0.5

		return XML_Descriptors.__MINMAX(
			Translation - HalfSize, -- /App/util/Region3.cpp#L38
			Translation + HalfSize, -- /App/util/Region3.cpp#L42
			XML_Descriptors.Vector3
		)
	end,
}
