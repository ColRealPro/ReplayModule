-- // Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- // Modules
local Console = require(script.Parent.Console)
local Compression = require(script.Parent.Compression)
Console.writeEnv()

local Replay = {}
Replay.__index = Replay

type RecordingData = {
    recordingId: string,
    framerate: number,
    time: number,
    totalFrames: number,
    recordingSize: number,
    trackedData: {[number]: {[number]: string}},
    eventData: {[number]: {[number]: string}},
    additionalData: {[string]: any}
}

type Replay = {
    _data: RecordingData,
    _currentTime: number,
    _eventConnections: {[string]: {(any) -> nil}},
    _playing: boolean,
    _rigs: {[number]: Model},
    _heartbeat: RBXScriptConnection,
    _startTime: number,
    _lastFrame: number
}

function Replay.from(Data: string) : Replay
    local self: Replay = setmetatable({}, Replay)

    print("Reading recording data")
    
    -- // Internal

    self._data = HttpService:JSONDecode(Compression.decompress(Data))
    self._currentTime = 0
    self._startTime = 0
    self._lastFrame = 0
    self._playing = false
    self._eventConnections = {}
    self._rigs = {}
    self._heartbeat = nil
    
    return self
end

function Replay:Play()
    local self: Replay = self
    if self._playing then
        warn("Already playing!")
        return
    end
    
    self._playing = true

    print("Preparing replay playback")
    
    for frame, data in self._data.trackedData do
        for userid in data do
            if not self._rigs[userid] then
                local Character = Players:CreateHumanoidModelFromUserId(userid)
                Character.PrimaryPart.Anchored = true
                self._rigs[userid] = {
                    Rig = Character,
                    Animations = {}
                }
            end
        end
    end

    print("Starting replay playback")

    self._startTime = os.clock()
    self._heartbeat = RunService.Heartbeat:Connect(function()
        self._currentTime = os.clock() - self._startTime

        local Frame = math.floor(self._currentTime * self._data.framerate)
        local LerpTime = (self._currentTime * self._data.framerate) - Frame
        local FrameData = self._data.trackedData[Frame]
        local EventData = self._data.eventData[Frame]

        -- if self._lastFrame == Frame then
        --     return
        -- end
        self._lastFrame = Frame

        if not FrameData then return end

        local LastFrame = self._data.trackedData[Frame - 1] or FrameData
        for userid: number, data: string in FrameData do
            if self._rigs[userid].Rig.Parent == nil then
                self._rigs[userid].Rig.Parent = workspace
            end
            local LastData = LastFrame[userid]

            
            local CFData = data:split(";")[1]
            local LastCFData = LastData:split(";")[1]
            
            local LastPos = CFrame.new(table.unpack(LastCFData:split(" ")))
            local GoalPos = CFrame.new(table.unpack(CFData:split(" ")))
            local Pos = LastPos:Lerp(GoalPos, LerpTime)
            self._rigs[userid].Rig:PivotTo(Pos)

            local AnimationData = data:split(";")[2]
            local Animations = AnimationData:split(" ")

            local Animator = self._rigs[userid].Rig:FindFirstChild("Animator", true)

            for _, anim: string in Animations do
                local AnimationTrack = self._rigs[userid].Animations[anim]
                if not AnimationTrack then
                    local Animation = Instance.new("Animation")
                    Animation.AnimationId = anim:split("-")[1]

                    local Track = Animator:LoadAnimation(Animation)
                    Track.Priority = Enum.AnimationPriority[anim:split("-")[2]]

                    self._rigs[userid].Animations[anim] = Track

                    AnimationTrack = Track
                end

                if not table.find(Animator:GetPlayingAnimationTracks(), AnimationTrack) then
                    AnimationTrack:Play()
                end
            end

            for _, anim: AnimationTrack in Animator:GetPlayingAnimationTracks() do
                if not table.find(Animations, anim.Animation.AnimationId .. "-" .. anim.Priority.Name) then
                    anim:Stop()
                end
            end
        end

        if Frame == self._data.totalFrames then
            self:Stop()
        end
    end)
end

function Replay:Stop()
    if not self._playing then
        warn("Not playing!")
        return
    end

    print("Cleaning up")

    self._playing = false
    self._heartbeat:Disconnect()
    
    for _, rig in self._rigs do
        rig.Rig:Destroy()
    end
    table.clear(self._rigs)
end

function Replay:OnEvent(EventName: string, Callback: (any) -> nil)
    if not self._eventConnections[EventName] then
        self._eventConnections[EventName] = {}
    end

    table.insert(self._eventConnections[EventName], Callback)
end

return Replay
