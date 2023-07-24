-- Module by 1waffle1 and boatbomber, optimized and fixed by iiau
-- https://devforum.roblox.com/t/text-compression/163637/37

local dictionary = {}

-- save builtin libraries 
local char = string.char
local insert = table.insert
local gsub = string.gsub
local pow = math.pow
local sub = string.sub
local concat = table.concat
local rep = string.rep
local clone = table.clone
local gmatch = string.gmatch
local byte = string.byte
local match = string.match

do -- populate dictionary
	local length = 0
	for i = 32, 127 do
		if i ~= 34 and i ~= 92 then
			local c = char(i)
			dictionary[c], dictionary[length] = length, c
			length = length + 1
		end
	end
end

local escapemap_126, escapemap_127 = {}, {}
local unescapemap_126, unescapemap_127 = {}, {}

local blacklisted_126 = { 34, 92, 126, 127 }
for i = 128, 180 do
	insert(blacklisted_126, i)
end

do -- Populate escape map
	-- represents the numbers 1-31, 34, 92, 126 and 127 (35 characters)
	-- https://devforum.roblox.com/t/text-compression/163637/5
	for i = 1, 31 + #blacklisted_126 do
		local b = blacklisted_126[i - 31]
		local s = i + 31

		-- Note: 126 and 127 are magic numbers
		local c = char(b or i)
		local e = char(s + (s >= 34 and 1 or 0) + (s >= 92 and 1 or 0))

		escapemap_126[c] = e
		unescapemap_126[e] = c
	end

	for i = 1, 255 - 181 do
		local c = char(i + 180)
		local s = i + 34
		local e = char(s + (s >= 92 and 1 or 0))

		escapemap_127[c] = e
		unescapemap_127[e] = c
	end
end

local function escape(s)
	-- escape the control characters 0-31, double quote 34, backslash 92 and DEL 127 (34 chars)
	-- escape characters 128-180 (53 chars)
	return gsub(gsub(s, '[%c"\\\127-\180]', function(c)
		return "\126" .. escapemap_126[c]
	end), '[\181-\255]', function(c)
		return "\127" .. escapemap_127[c]
	end)
end
local function unescape(s)
	return gsub(gsub(s, "\127(.)", function(e)
		return unescapemap_127[e]
	end), "\126(.)", function(e)
		return unescapemap_126[e]
	end)
end

local b92Cache = {}
local function tobase92(n)
	local value = b92Cache[n]
	if value then
		return value
	end

	local c = n
	value = ""
	repeat
		local remainder = n % 92
		value = dictionary[remainder] .. value
		n = (n - remainder) / 92
	until n == 0

	b92Cache[c] = value
	return value
end

local b10Cache = {}
local function tobase10(value)
	local n = b10Cache[value]
	if n then
		return n
	end

	n = 0
	for i = 1, #value do
		n = n + pow(92, i - 1) * dictionary[sub(value, -i, -i)]
	end

	b10Cache[value] = n
	return n
end

local function compress(text)
	local dictionaryCopy = clone(dictionary)
	local key, sequence, size = "", {}, #dictionaryCopy
	local width, spans, span = 1, {}, 0
	local function listkey(k)
		local value = dictionaryCopy[k]
		if not value then
			warn(byte(k))
		end
		value = tobase92(value)
		local valueLength = #value
		if valueLength > width then
			width, span, spans[width] = valueLength, 0, span
		end
		insert(sequence, rep(" ", width - valueLength) .. value)
		span += 1
	end
	text = escape(text)
	for i = 1, #text do
		local c = sub(text, i, i)
		local new = key .. c
		if dictionaryCopy[new] then
			key = new
		else
			listkey(key)
			key = c
			size += 1
			dictionaryCopy[new], dictionaryCopy[size] = size, new
		end
	end
	listkey(key)
	spans[width] = span
	return concat(spans, ",") .. "|" .. concat(sequence)
end

local function decompress(text)
	local dictionaryCopy = clone(dictionary)
	local sequence, spans, content = {}, match(text, "(.-)|(.*)")
	local groups, start = {}, 1
	for span in gmatch(spans, "%d+") do
		local width = #groups + 1
		groups[width] = sub(content, start, start + span * width - 1)
		start = start + span * width
	end
	local previous

	for width, group in groups do -- removed ipairs, that slows stuff down
		for value in gmatch(group, rep(".", width)) do
			local entry = dictionaryCopy[tobase10(value)]
			if previous then
				if entry then
					insert(dictionaryCopy, previous .. sub(entry, 1, 1))
				else
					entry = previous .. sub(previous, 1, 1)
					insert(dictionaryCopy, entry)
				end
				insert(sequence, entry)
			else
				sequence[1] = entry
			end
			previous = entry
		end
	end
	return unescape(concat(sequence))
end

return { compress = compress, decompress = decompress }