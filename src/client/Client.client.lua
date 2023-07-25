local ReplayModule = require(game.ReplicatedStorage.Shared.ReplayModule)

-- local Recording = ReplayModule.newRecording()

-- Recording:Track(game.Players.LocalPlayer)

-- task.wait(8)

-- Recording:StartRecording()

-- task.wait(10)

-- local Data = Recording:StopRecording()
-- local Replay = ReplayModule.newReplayFrom(Data)

-- Replay:Play()

local Recording

game.Players.LocalPlayer.PlayerGui:WaitForChild("ScreenGui")

game.Players.LocalPlayer.PlayerGui.ScreenGui.rec.MouseButton1Click:Connect(function()
    Recording = ReplayModule.newRecording()
    Recording:Track(game.Players.LocalPlayer)
    Recording:StartRecording()
end)

game.Players.LocalPlayer.PlayerGui.ScreenGui.stop.MouseButton1Click:Connect(function()
    local Data = Recording:StopRecording()
    local Replay = ReplayModule.newReplayFrom(Data)
    Replay:OnEvent("TestEvent", function(Value)
        print("TestEvent:", Value)
    end)
    Replay:Play()
end)

game.Players.LocalPlayer.PlayerGui.ScreenGui.event.MouseButton1Click:Connect(function()
    Recording:RecordEvent("TestEvent", "TestValue")
end)