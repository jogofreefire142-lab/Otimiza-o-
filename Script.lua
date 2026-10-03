-- SCRIPT ATUALIZADO: VELOCIDADE TOTALMENTE LIVRE E MENU ARRASTÁVEL
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

-- Valores iniciais (Você pode mudar o tanto que quiser pelo menu)
_G.VelocidadeSalva = 260
_G.PuloSalvo = 80

-- Remove qualquer menu duplicado da tela
if CoreGui:FindFirstChild("MenuVelocidadeLivre") then
    CoreGui["MenuVelocidadeLivre"]:Destroy()
end

-- 1. SISTEMA AUTOMÁTICO ANTI-CHAT (PROTEÇÃO CONTRA BAN)
pcall(function()
    local textChatService = game:GetService("TextChatService")
    if textChatService and textChatService:FindFirstChild("ChatWindowConfiguration") then
        textChatService.ChatWindowConfiguration.Enabled = false
        textChatService.ChatInputBarConfiguration.Enabled = false
    end
end)

-- 2. CRIAÇÃO DA INTERFACE DO MENU (VISÍVEL DE PRIMEIRA)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MenuVelocidadeLivre"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 190, 0, 150)
MainFrame.Position = UDim2.new(0.4, 0, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local Borda = Instance.new("UIStroke", MainFrame)
Borda.Color = Color3.fromRGB(0, 255, 150)
Borda.Thickness = 2

-- FUNÇÃO UNIVERSAL PARA ARRASTAR O MENU EM QUALQUER DISPOSITIVO
local function AtivarArrastoMenu(frame)
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
AtivarArrastoMenu(MainFrame)

-- TEXTO E CAIXA DE CONFIGURAÇÃO DA VELOCIDADE
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

-- TEXTO E CAIXA DE CONFIGURAÇÃO DO PULO
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

-- SISTEMA QUE CAPTURA E SALVA O VALOR QUE VOCÊ QUISER DIRETO NA MEMÓRIA
InputSpeed.FocusLost:Connect(function()
    local val = tonumber(InputSpeed.Text)
    if val then 
        _G.VelocidadeSalva = val -- Completamente livre! Sem travas ou limites.
        InputSpeed.Text = tostring(_G.VelocidadeSalva)
    else 
        InputSpeed.Text = tostring(_G.VelocidadeSalva) 
    end
end)

InputJump.FocusLost:Connect(function()
    local val = tonumber(InputJump.Text)
    if val then 
        _G.PuloSalvo = val 
        InputJump.Text = tostring(_G.PuloSalvo)
    else 
        InputJump.Text = tostring(_G.PuloSalvo) 
    end
end)

-- 3. MOTOR SUPREMO DE REFRESH (Aplica e segura o valor a cada milissegundo)
RunService.RenderStepped:Connect(function()
    pcall(function()
        local char = Player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.UseJumpPower = true
                -- Força o valor exato digitado no menu sem deixar o jogo resetar
                if hum.WalkSpeed ~= _G.VelocidadeSalva then
                    hum.WalkSpeed = _G.VelocidadeSalva
                end
                if hum.JumpPower ~= _G.PuloSalvo then
                    hum.JumpPower = _G.PuloSalvo
                end
            end
        end
    end)
end)
