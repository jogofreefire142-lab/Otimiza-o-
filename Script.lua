-- SCRIPT VELOCIDADE PERFEITA 2026 - CORRIGIDO E TRAVADO
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

-- Valores exatos e calibrados por você
_G.VelocidadeSalva = 260
_G.PuloSalvo = 80

-- Limpa menus antigos para evitar travamentos
if CoreGui:FindFirstChild("MenuVelocidadePerfeita") then
    CoreGui["MenuVelocidadePerfeita"]:Destroy()
end

-- 1. SISTEMA SEGURO ANTI-CHAT
pcall(function()
    local textChatService = game:GetService("TextChatService")
    if textChatService and textChatService:FindFirstChild("ChatWindowConfiguration") then
        textChatService.ChatWindowConfiguration.Enabled = false
        textChatService.ChatInputBarConfiguration.Enabled = false
    end
end)

-- 2. CRIAÇÃO DA INTERFACE VISUAL (MENU)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MenuVelocidadePerfeita"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 180, 0, 100)
MainFrame.Position = UDim2.new(0.4, 0, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Pode arrastar para qualquer canto da tela
MainFrame.Parent = MainFrame

-- Garante funcionamento do arrasto em telas touch modernos e mouse
local function AtivarArrastoUniversal(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true dragStart = input.Position startPos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
MainFrame.Parent = ScreenGui
AtivarArrastoUniversal(MainFrame)

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local Borda = Instance.new("UIStroke", MainFrame)
Borda.Color = Color3.fromRGB(0, 255, 150)
Borda.Thickness = 2

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
InputSpeed.TextSize = 16
InputSpeed.Parent = MainFrame
Instance.new("UICorner", InputSpeed).CornerRadius = UDim.new(0, 4)

InputSpeed.FocusLost:Connect(function()
    local val = tonumber(InputSpeed.Text)
    if val then 
        _G.VelocidadeSalva = math.clamp(val, 16, 260) -- Limita até 260 para total perfeição e anti-ban
        InputSpeed.Text = tostring(_G.VelocidadeSalva)
    else 
        InputSpeed.Text = tostring(_G.VelocidadeSalva) 
    end
end)

-- 3. MOTOR ULTRA RÁPIDO E CORRIGIDO DE MOVIMENTAÇÃO (ANTI-CHANCE DE FALHA)
RunService.Heartbeat:Connect(function()
    pcall(function()
        local char = Player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            
            if hum and hum.Parent then
                hum.UseJumpPower = true
                hum.WalkSpeed = _G.VelocidadeSalva
                hum.JumpPower = _G.PuloSalvo
                
                -- CORREÇÃO DA VELOCIDADE: Se o personagem estiver andando, aplica força extra direta na física
                if root and hum.MoveDirection.Magnitude > 0 then
                    local direcao = hum.MoveDirection
                    root.AssemblyLinearVelocity = Vector3.new(direcao.X * _G.VelocidadeSalva, root.AssemblyLinearVelocity.Y, direcao.Z * _G.VelocidadeSalva)
                end
            end
        end
    end)
end)
