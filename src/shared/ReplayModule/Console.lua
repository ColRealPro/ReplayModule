local console = {}
local ShowLogs = true --game:GetService("RunService"):IsStudio()
local IsStudio = game:GetService("RunService"):IsStudio()

local function FixTable(tbl, index, indent)
	if IsStudio then
		return tbl
	end
	if not index then
		index = 1
	end
	local result = (indent and string.rep("  ", index - 1) or "") .. "{\n"
	local iterated = false
	for k, v in pairs(tbl) do
		iterated = true
		-- Check the key type (ignore any numerical keys - assume its an array)
		local array = true
		if type(k) == "string" then
			array = false
			result = result .. string.rep("  ", index) .. '["' .. k .. '"]' .. " = "
		end

		-- Check the value type
		if type(v) == "table" then
			result = result .. FixTable(v, index + 1, array)
		elseif type(v) == "boolean" then
			result = result .. tostring(v)
		else
			result = result .. '"' .. tostring(v) .. '"'
		end
		result = result .. ",\n"
	end
	-- Remove leading commas from the result
	if result ~= "" and iterated then
		result = result:sub(1, result:len() - 2)
		result = result .. "\n"
	end
	return result .. string.rep("  ", index - 1) .. "}"
end

function console.log(...)
	if not ShowLogs then
		return
	end
	local Splits = string.split(string.split(debug.traceback(2), "\n")[3], ".")
	local prefix = "[" .. string.split(Splits[#Splits], " ")[1] .. "]"

	local args = { ... }
	for i, v in args do
		if typeof(v) == "table" then
			args[i] = FixTable(v)
		end
	end

	print(prefix, table.unpack(args))
end

function console.warn(...)
	if not ShowLogs then
		return
	end
	local Splits = string.split(string.split(debug.traceback(2), "\n")[3], ".")
	local prefix = "[" .. string.split(Splits[#Splits], " ")[1] .. "]"

	local args = { ... }
	for i, v in args do
		if typeof(v) == "table" then
			args[i] = FixTable(v)
		end
	end

	warn(prefix, table.unpack(args))
end

function console.writeEnv()
	local fenv = getfenv(2)
	fenv.print = console.log
	fenv.warn = console.warn
end

return console
