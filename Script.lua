local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
_G.VelocidadeSalva = 260

local ParentGui = nil
if pcall(function() return game:GetService("CoreGui").Name end) then
    ParentGui = game:GetService("CoreGui")
else
    ParentGui = Player:WaitForChild("PlayerGui")
end

if ParentGui:FindFirstChild("MenuVelocidadeFinal2026") then
    ParentGui["MenuVelocidadeFinal2026"]:Destroy()
end

pcall(function()
    local textChatService = game:GetService("TextChatService")
    if textChatService and textChatService:FindFirstChild("ChatWindowConfiguration") then
        textChatService.ChatWindowConfiguration.Enabled = false
        textChatService.ChatInputBarConfiguration.Enabled = false
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MenuVelocidadeFinal2026"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = ParentGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 190, 0, 95)
MainFrame.Position = UDim2.new(0.4, 0, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local CornerFrame = Instance.new("UICorner")
CornerFrame.CornerRadius = UDim.new(0, 10)
CornerFrame.Parent = MainFrame

local Borda = Instance.new("UIStroke")
Borda.Color = Color3.fromRGB(0, 255, 150)
Borda.Thickness = 2
Borda.Parent = MainFrame

local MenuToggle = Instance.new("TextButton")
MenuToggle.Size = UDim2.new(0, 45, 0, 45)
MenuToggle.Position = UDim2.new(0.05, 0, 0.2, 0)
MenuToggle.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
MenuToggle.TextColor3 = Color3.fromRGB(15, 15, 15)
MenuToggle.Text = "MENU"
MenuToggle.Font = Enum.Font.SourceSansBold
MenuToggle.TextSize = 11
MenuToggle.Active = true
MenuToggle.Parent = ScreenGui

local CornerToggle = Instance.new("UICorner")
CornerToggle.CornerRadius = UDim.new(0, 50)
CornerToggle.Parent = MenuToggle

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(255, 255, 255)
ToggleStroke.Thickness = 1.5
ToggleStroke.Parent = MenuToggle

local function ConfigurarArrastoLiso(guiObject)
    local dragging, dragInput, dragStart, startPos
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
ConfigurarArrastoLiso(MainFrame)
ConfigurarArrastoLiso(MenuToggle)

MenuToggle.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    if MainFrame.Visible then
        MenuToggle.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        MenuToggle.Text = "X"
        MenuToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        MenuToggle.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
        MenuToggle.Text = "MENU"
        MenuToggle.TextColor3 = Color3.fromRGB(15, 15, 15)
    end
end)

local LabelSpeed = Instance.new("TextLabel")
LabelSpeed.Size = UDim2.new(1, 0, 0.3, 0)
LabelSpeed.Position = UDim2.new(0, 0, 0.1, 0)
LabelSpeed.Text = "⚡ Ajustar Velocidade:"
LabelSpeed.TextColor3 = Color3.fromRGB(255, 255, 255)
LabelSpeed.BackgroundTransparency = 1
LabelSpeed.TextSize = 13
LabelSpeed.Font = Enum.Font.SourceSansBold
LabelSpeed.Parent = MainFrame

local InputSpeed = Instance.new("TextBox")
InputSpeed.Size = UDim2.new(0.8, 0, 0.35, 0)
InputSpeed.Position = UDim2.new(0.1, 0, 0.45, 0)
InputSpeed.Text = tostring(_G.VelocidadeSalva)
InputSpeed.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
InputSpeed.TextColor3 = Color3.fromRGB(0, 255, 100)
InputSpeed.Font = Enum.Font.SourceSansBold
InputSpeed.TextSize = 15
InputSpeed.Parent = MainFrame

local CornerInput = Instance.new("UICorner")
CornerInput.CornerRadius = UDim.new(0, 4)
CornerInput.Parent = InputSpeed

InputSpeed.FocusLost:Connect(function()
    local val = tonumber(InputSpeed.Text)
    if val then _G.VelocidadeSalva = val else InputSpeed.Text = tostring(_G.VelocidadeSalva) end
end)

local renderConnection
renderConnection = RunService.Heartbeat:Connect(function()
    if not ScreenGui or not ScreenGui.Parent then
        if renderConnection then renderConnection:Disconnect() end
        return
    end
    pcall(function()
        local char = Player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            
            if hum and hum.Parent and root then
                if hum.WalkSpeed ~= 16 then
                    hum.WalkSpeed = 16
                end
                
                if hum.MoveDirection.Magnitude > 0 then
                    root.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
                    
                    local direcao = hum.MoveDirection
                    local velocidadeAtual = root.AssemblyLinearVelocity
                    local velocidadeDesejada = Vector3.new(direcao.X * _G.VelocidadeSalva, velocidadeAtual.Y, direcao.Z * _G.VelocidadeSalva)
                    local mudancaDeVelocidade = velocidadeDesejada - velocidadeAtual
                    
                    local forcaMecanica = mudancaDeVelocidade * root:GetMass()
                    root:ApplyImpulse(Vector3.new(forcaMecanica.X, 0, forcaMecanica.Z))
                end
            end
        end
    end)
end)
