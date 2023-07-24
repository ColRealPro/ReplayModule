local ReplayModule = {}
local Recording = require(script.Recording)
local Replay = require(script.Replay)
local Console = require(script.Console)

function ReplayModule.newRecording()
    return Recording.new()
end

function ReplayModule.newReplayFrom(Data: string)
    return Replay.from(Data)
end

return ReplayModule
