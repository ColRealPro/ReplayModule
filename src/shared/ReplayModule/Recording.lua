-- // Services
local HttpService = game:GetService("HttpService")

-- // Modules
local Console = require(script.Parent.Console)
local Compression = require(script.Parent.Compression)
Console.writeEnv()

local Recording = {}
Recording.__index = Recording

function Recording.new()
	local self = setmetatable({}, Recording)

	self.Tracking = {}

	-- // Internal
	self._recording = false
	self._currentTime = 0
    self._startTime = 0
	self._lastFrame = 0
	self._totalFrames = 0 
    self._framerate = 15
    self._recordingSize = 0
	self._recordingId = HttpService:GenerateGUID(false)
	self._trackedData = {}
	self._eventData = {}
	self._additionalData = {}
    self._heartbeat = nil

	print("Created recording:", self)

	return self
end

function Recording:StartRecording()
	if self._recording then
		warn("Already recording!")
		return
	end

    self._recording = true
    self._startTime = os.clock()

    self._heartbeat = game:GetService("RunService").Heartbeat:Connect(function()
        local Frame = math.floor((os.clock() - self._startTime) * self._framerate)
        if Frame ~= self._lastFrame then
            self._lastFrame = Frame
            self._totalFrames = Frame
            self._currentTime = os.clock() - self._startTime

            local Data = {}
            for _, player in self.Tracking do
                local Character = player.Character
                if not Character then
                    continue
                end

                local CFValues = table.pack(Character:GetPivot():GetComponents())
                CFValues["n"] = nil

                local Animator: Animator = Character:FindFirstChild("Animator", true)
                local AnimationTracks = Animator:GetPlayingAnimationTracks()
                local AnimationIds = {}

                for _, v in AnimationTracks do
                    table.insert(AnimationIds, v.Animation.AnimationId.."-"..v.Priority.Name)
                end

                for i,v in CFValues do
                    CFValues[i] = math.floor(v * 100) / 100
                end

                local DataString = table.concat(CFValues," ")..";"..table.concat(AnimationIds, " ")
                
                Data[player.UserId] = DataString
            end

            self._trackedData[Frame] = Data
        end
    end)

    print("Recording started (".. self._recordingId ..")")
end

function Recording:RecordEvent(EventName, EventData)
    local Frame = math.floor((os.clock() - self._startTime) * self._framerate)
    if not self._eventData[Frame] then
        self._eventData[Frame] = {}
    end
    table.insert(self._eventData[Frame], {
        name = EventName,
        data = EventData
    })
end

function Recording:StopRecording()
    if not self._recording then
        warn("Not recording!")
        return
    end
    
    self._recording = false
    self._heartbeat:Disconnect()
    self._time = os.clock() - self._startTime

    local DataNonCompresed = {
        recordingId = self._recordingId,
        framerate = self._framerate,
        time = self._time,
        totalFrames = self._totalFrames,
        recordingSize = self._recordingSize,
        trackedData = self._trackedData,
        eventData = self._eventData,
        additionalData = self._additionalData
    }

    local compressStart = os.clock()
    self._compressedData = Compression.compress(HttpService:JSONEncode(DataNonCompresed))
    print("Compression took:", os.clock() - compressStart)
    
    self._recordingSize = self._compressedData:len()

    print("Compression percentage:", HttpService:JSONEncode(self._trackedData):len() / self._compressedData:len() * 100 .. "%")

    print("Recording ended, Size:", self._recordingSize / 1000 .. "kb,", "Data:", self)

    return self._compressedData
end

function Recording:Track(player)
	if table.find(self.Tracking, player) then
		warn(player, "is already being tracked!")
		return
	end

	table.insert(self.Tracking, player)
end

return Recording
