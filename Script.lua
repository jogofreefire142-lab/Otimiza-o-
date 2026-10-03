-- SCRIPT SUPREMO 2026 - ULTRA OTIMIZADO (ZERO TRAVAMENTO)
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

-- Valores padrão (Livre para configurar o tanto que quiser no menu)
_G.VelocidadeSalva = 260
_G.PuloSalvo = 80

-- Remove GUIs antigas para liberar memória RAM do celular
if CoreGui:FindFirstChild("MenuOtimizado2026") then
    CoreGui["MenuOtimizado2026"]:Destroy()
end

-- 1. SISTEMA AUTOMÁTICO ANTI-CHAT (PROTEÇÃO DE CONTA)
pcall(function()
    local textChatService = game:GetService("TextChatService")
    if textChatService and textChatService:FindFirstChild("ChatWindowConfiguration") then
        textChatService.ChatWindowConfiguration.Enabled = false
        textChatService.ChatInputBarConfiguration.Enabled = false
    end
end)

-- 2. CRIAÇÃO DA INTERFACE VISUAL PREMIUM E LEVE
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MenuOtimizado2026"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 190, 0, 150)
MainFrame.Position = UDim2.new(0.4, 0, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = false -- Começa fechado para não dar lag na tela
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local Borda = Instance.new("UIStroke", MainFrame)
Borda.Color = Color3.fromRGB(0, 255, 150)
Borda.Thickness = 2

-- Botão Redondo de Abrir/Fechar
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

Instance.new("UICorner", MenuToggle).CornerRadius = UDim.new(0, 50)
local ToggleStroke = Instance.new("UIStroke", MenuToggle)
ToggleStroke.Color = Color3.fromRGB(255, 255, 255)
ToggleStroke.Thickness = 1.5

-- FUNÇÃO DE ARRASTO NATIVA ULTRA LEVE (Touch e Mouse)
local function ConfigurarArrastoLeve(guiObject)
    local dragging, dragInput, dragStart, startPos
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true dragStart = input.Position startPos = guiObject.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
ConfigurarArrastoLeve(MainFrame)
ConfigurarArrastoLeve(MenuToggle)

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

-- Inputs do Menu
local LabelSpeed = Instance.new("TextLabel")
LabelSpeed.Size = UDim2.new(1, 0, 0.2, 0)
LabelSpeed.Position = UDim2.new(0, 0, 0.05, 0)
LabelSpeed.Text = "⚡ Digite a Velocidade:"
LabelSpeed.TextColor3 = Color3.fromRGB(255, 255, 255)
LabelSpeed.BackgroundTransparency = 1
LabelSpeed.TextSize = 13
LabelSpeed.Font = Enum.Font.SourceSansBold
LabelSpeed.Parent = MainFrame

local InputSpeed = Instance.new("TextBox")
InputSpeed.Size = UDim2.new(0.8, 0, 0.2, 0)
InputSpeed.Position = UDim2.new(0.1, 0, 0.25, 0)
InputSpeed.Text = tostring(_G.VelocidadeSalva)
InputSpeed.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
InputSpeed.TextColor3 = Color3.fromRGB(0, 255, 100)
InputSpeed.Font = Enum.Font.SourceSansBold
InputSpeed.TextSize = 15
InputSpeed.Parent = MainFrame
Instance.new("UICorner", InputSpeed).CornerRadius = UDim.new(0, 4)

local LabelJump = Instance.new("TextLabel")
LabelJump.Size = UDim2.new(1, 0, 0.2, 0)
LabelJump.Position = UDim2.new(0, 0, 0.5, 0)
LabelJump.Text = "🚀 Altura do Pulo:"
LabelJump.TextColor3 = Color3.fromRGB(255, 255, 255)
LabelJump.BackgroundTransparency = 1
LabelJump.TextSize = 13
LabelJump.Font = Enum.Font.SourceSansBold
LabelJump.Parent = MainFrame

local InputJump = Instance.new("TextBox")
InputJump.Size = UDim2.new(0.8, 0, 0.2, 0)
InputJump.Position = UDim2.new(0.1, 0, 0.7, 0)
InputJump.Text = tostring(_G.PuloSalvo)
InputJump.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
InputJump.TextColor3 = Color3.fromRGB(0, 255, 100)
InputJump.Font = Enum.Font.SourceSansBold
InputJump.TextSize = 15
InputJump.Parent = MainFrame
Instance.new("UICorner", InputJump).CornerRadius = UDim.new(0, 4)

-- 3. MOTOR BASEADO EM EVENTOS (MÁXIMA OTIMIZAÇÃO - ZERO LAG)
local function ConectarPersonagem(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    local function ForcarValores()
        humanoid.UseJumpPower = true
        if humanoid.WalkSpeed ~= _G.VelocidadeSalva then
            humanoid.WalkSpeed = _G.VelocidadeSalva
        end
        if humanoid.JumpPower ~= _G.PuloSalvo then
            humanoid.JumpPower = _G.PuloSalvo
        end
    end

    -- Aplica os valores imediatamente
    ForcarValores()

    -- Em vez de um loop infinito, o script só acorda se a velocidade mudar
    humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(ForcarValores)
    humanoid:GetPropertyChangedSignal("JumpPower"):Connect(ForcarValores)
end

-- Gerenciamento de Foco dos Inputs
InputSpeed.FocusLost:Connect(function()
    local val = tonumber(InputSpeed.Text)
    if val then _G.VelocidadeSalva = val else InputSpeed.Text = tostring(_G.VelocidadeSalva) end
    if Player.Character then ConectarPersonagem(Player.Character) end
end)

InputJump.FocusLost:Connect(function()
    local val = tonumber(InputJump.Text)
    if val then _G.PuloSalvo = val else InputJump.Text = tostring(_G.PuloSalvo) end
    if Player.Character then ConectarPersonagem(Player.Character) end
end)

-- Ativa ao entrar e sempre que renascer
if Player.Character then ConectarPersonagem(Player.Character) end
Player.CharacterAdded:Connect(ConectarPersonagem)
