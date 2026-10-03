-- SCRIPT 1: VELOCIDADE MANUAL E PULO INFINITO (SEM KEY)
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local SpeedInput = Instance.new("TextBox")
local TextLabel = Instance.new("TextLabel")

ScreenGui.Parent = game.CoreGui
Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.Position = UDim2.new(0.1, 0, 0.2, 0)
Frame.Size = UDim2.new(0, 180, 0, 90)
Frame.Active = true
Frame.Draggable = true

TextLabel.Parent = Frame
TextLabel.Size = UDim2.new(1, 0, 0.4, 0)
TextLabel.Text = "Digite a Velocidade:"
TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.BackgroundTransparency = 1

SpeedInput.Parent = Frame
SpeedInput.Position = UDim2.new(0.1, 0, 0.5, 0)
SpeedInput.Size = UDim2.new(0.8, 0, 0.4, 0)
SpeedInput.Text = "150"
SpeedInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SpeedInput.TextColor3 = Color3.fromRGB(0, 255, 100)

-- Mantém a velocidade ativa continuamente sem resetar
game:GetService("RunService").RenderStepped:Connect(function()
    pcall(function()
        local vel = tonumber(SpeedInput.Text) or 16
        local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = vel
        end
    end)
end)

-- Pulo Infinito (Pule repetidamente no ar para voar)
game:GetService("UserInputService").JumpRequest:Connect(function()
    pcall(function()
        game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end)
end)
