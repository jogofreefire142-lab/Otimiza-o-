local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
_G.VelocidadeSalva = nil

-- Proteção universal para encontrar a pasta correta de armazenamento da interface (Mobile/PC)
local ParentGui = nil
if pcall(function() return game:GetService("CoreGui").Name end) then
    ParentGui = game:GetService("CoreGui")
else
    ParentGui = Player:WaitForChild("PlayerGui")
end

if ParentGui:FindFirstChild("MiniMenuVelocidade") then
    ParentGui["MiniMenuVelocidade"]:Destroy()
end

-- CRIAÇÃO DA INTERFACE PEQUENA UNIVERSAL
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MiniMenuVelocidade"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = ParentGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 150, 0, 65)
MainFrame.Position = UDim2.new(0.4, 0, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

local CornerFrame = Instance.new("UICorner")
CornerFrame.CornerRadius = UDim.new(0, 8)
CornerFrame.Parent = MainFrame

local Borda = Instance.new("UIStroke")
Borda.Color = Color3.fromRGB(0, 255, 150)
Borda.Thickness = 2
Borda.Parent = MainFrame

-- ARRASTO UNIVERSAL LEVE PARA TOUCH (CELULAR) E MOUSE (PC)
local function AtivarArrasto(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
AtivarArrasto(MainFrame)

local LabelSpeed = Instance.new("TextLabel")
LabelSpeed.Size = UDim2.new(1, 0, 0.4, 0)
LabelSpeed.Position = UDim2.new(0, 0, 0.05, 0)
LabelSpeed.Text = "⚡ Velocidade Sem Limites:"
LabelSpeed.TextColor3 = Color3.fromRGB(255, 255, 255)
LabelSpeed.BackgroundTransparency = 1
LabelSpeed.TextSize = 11
LabelSpeed.Font = Enum.Font.SourceSansBold
LabelSpeed.Parent = MainFrame

local InputSpeed = Instance.new("TextBox")
InputSpeed.Size = UDim2.new(0.8, 0, 0.4, 0)
InputSpeed.Position = UDim2.new(0.1, 0, 0.45, 0)
InputSpeed.Text = ""
InputSpeed.PlaceholderText = "Digite o valor..."
InputSpeed.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
InputSpeed.TextColor3 = Color3.fromRGB(0, 255, 100)
InputSpeed.Font = Enum.Font.SourceSansBold
InputSpeed.TextSize = 14
InputSpeed.Parent = MainFrame

local CornerInput = Instance.new("UICorner")
CornerInput.CornerRadius = UDim.new(0, 4)
CornerInput.Parent = InputSpeed

-- MOTOR REATIVO COMPATÍVEL COM TODOS OS DISPOSITIVOS
local function MonitorarVelocidade(character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if humanoid and _G.VelocidadeSalva then
        humanoid.WalkSpeed = _G.VelocidadeSalva
        
        humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if humanoid and humanoid.Parent and _G.VelocidadeSalva and humanoid.WalkSpeed ~= _G.VelocidadeSalva then
                humanoid.WalkSpeed = _G.VelocidadeSalva
            end
        end)
    end
end

InputSpeed.FocusLost:Connect(function()
    local val = tonumber(InputSpeed.Text)
    if val then 
        _G.VelocidadeSalva = val 
        if Player.Character then
            local hum = Player.Character:FindFirstChildOfClass("Humanoid")
            if hum then 
                hum.WalkSpeed = _G.VelocidadeSalva 
                hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                    if hum and hum.Parent and hum.WalkSpeed ~= _G.VelocidadeSalva then
                        hum.WalkSpeed = _G.VelocidadeSalva
                    end
                end)
            end
        end
    else 
        InputSpeed.Text = _G.VelocidadeSalva and tostring(_G.VelocidadeSalva) or ""
    end
end)

if Player.Character then task.defer(MonitorarVelocidade, Player.Character) end
Player.CharacterAdded:Connect(function(char) task.defer(MonitorarVelocidade, char) end)
