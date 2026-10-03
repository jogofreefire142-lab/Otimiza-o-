-- SCRIPT UNIVERSAL MULTIPLATAFORMA - REVISADO E CONFIRMADO 2026
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

-- Valores memorizados padrão
_G.VelocidadeSalva = 260
_G.PuloSalvo = 110
_G.AntiMonstroAtivo = true

-- Limpa execuções duplicadas para evitar crash
if CoreGui:FindFirstChild("ScriptConfirmado2026") then
    CoreGui["ScriptConfirmado2026"]:Destroy()
end

-- INTERFACE PRINCIPAL
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ScriptConfirmado2026"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 190, 0, 170)
MainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = false -- Começa fechado para liberar a tela
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local UIBorder = Instance.new("UIStroke")
UIBorder.Color = Color3.fromRGB(0, 255, 150)
UIBorder.Thickness = 2
UIBorder.Parent = MainFrame

-- BOTÃO REDONDO FLUTUANTE (ABRIR/FECHAR)
local MenuToggle = Instance.new("TextButton")
MenuToggle.Size = UDim2.new(0, 45, 0, 45)
MenuToggle.Position = UDim2.new(0.05, 0, 0.2, 0)
MenuToggle.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
MenuToggle.TextColor3 = Color3.fromRGB(15, 15, 15)
MenuToggle.Text = "MENU"
MenuToggle.Font = Enum.Font.SourceSansBold
MenuToggle.TextSize = 12
MenuToggle.Active = true
MenuToggle.Parent = ScreenGui

Instance.new("UICorner", MenuToggle).CornerRadius = UDim.new(0, 50)
local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(255, 255, 255)
ToggleStroke.Thickness = 1.5
ToggleStroke.Parent = MenuToggle

-- CORREÇÃO DO ARRASTO: SISTEMA DE TRAVA ESTÁVEL (TOUCH E MOUSE)
local function AplicarArrastoSeguro(guiFrame)
    local dragging, dragInput, dragStart, startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        guiFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    guiFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    guiFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Ativa o arrasto corrigido em ambas as interfaces
AplicarArrastoSeguro(MainFrame)
AplicarArrastoSeguro(MenuToggle)

-- Alternador de Visibilidade
MenuToggle.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    if MainFrame.Visible then
        MenuToggle.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        MenuToggle.Text = "X"
    else
        MenuToggle.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
        MenuToggle.Text = "MENU"
    end
end)

-- Botão de Destruição (X)
local DestroyBtn = Instance.new("TextButton")
DestroyBtn.Size = UDim2.new(0, 25, 0, 25)
DestroyBtn.Position = UDim2.new(0.83, 0, 0.05, 0)
DestroyBtn.BackgroundTransparency = 1
DestroyBtn.Text = "X"
DestroyBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
DestroyBtn.TextSize = 16
DestroyBtn.Font = Enum.Font.SourceSansBold
DestroyBtn.Parent = MainFrame

DestroyBtn.MouseButton1Click:Connect(function()
    _G.AntiMonstroAtivo = false
    ScreenGui:Destroy()
end)

-- Textos e Caixas de Texto (Inputs)
local LabelSpeed = Instance.new("TextLabel")
LabelSpeed.Size = UDim2.new(1, 0, 0.12, 0)
LabelSpeed.Position = UDim2.new(0, 0, 0.08, 0)
LabelSpeed.Text = "⚡ Velocidade:"
LabelSpeed.TextColor3 = Color3.fromRGB(230, 230, 230)
LabelSpeed.BackgroundTransparency = 1
LabelSpeed.Parent = MainFrame

local InputSpeed = Instance.new("TextBox")
InputSpeed.Size = UDim2.new(0.8, 0, 0.15, 0)
InputSpeed.Position = UDim2.new(0.1, 0, 0.22, 0)
InputSpeed.Text = tostring(_G.VelocidadeSalva)
InputSpeed.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
InputSpeed.TextColor3 = Color3.fromRGB(0, 255, 100)
InputSpeed.Font = Enum.Font.SourceSansBold
InputSpeed.Parent = MainFrame
Instance.new("UICorner", InputSpeed).CornerRadius = UDim.new(0, 4)

local LabelJump = Instance.new("TextLabel")
LabelJump.Size = UDim2.new(1, 0, 0.12, 0)
LabelJump.Position = UDim2.new(0, 0, 0.40, 0)
LabelJump.Text = "🚀 Altura do Pulo:"
LabelJump.TextColor3 = Color3.fromRGB(230, 230, 230)
LabelJump.BackgroundTransparency = 1
LabelJump.Parent = MainFrame

local InputJump = Instance.new("TextBox")
InputJump.Size = UDim2.new(0.8, 0, 0.15, 0)
InputJump.Position = UDim2.new(0.1, 0, 0.54, 0)
InputJump.Text = tostring(_G.PuloSalvo)
InputJump.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
InputJump.TextColor3 = Color3.fromRGB(0, 255, 100)
InputJump.Font = Enum.Font.SourceSansBold
InputJump.Parent = MainFrame
Instance.new("UICorner", InputJump).CornerRadius = UDim.new(0, 4)

local AntiMonstroBtn = Instance.new("TextButton")
AntiMonstroBtn.Size = UDim2.new(0.8, 0, 0.16, 0)
AntiMonstroBtn.Position = UDim2.new(0.1, 0, 0.76, 0)
AntiMonstroBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
AntiMonstroBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AntiMonstroBtn.Text = "🛡️ Anti-Mãe: LIGADO"
AntiMonstroBtn.Font = Enum.Font.SourceSansBold
AntiMonstroBtn.TextSize = 12
AntiMonstroBtn.Parent = MainFrame
Instance.new("UICorner", AntiMonstroBtn).CornerRadius = UDim.new(0, 5)

AntiMonstroBtn.MouseButton1Click:Connect(function()
    _G.AntiMonstroAtivo = not _G.AntiMonstroAtivo
    AntiMonstroBtn.Text = _G.AntiMonstroAtivo and "🛡️ Anti-Mãe: LIGADO" or "❌ Anti-Mãe: DESLIGADO"
    AntiMonstroBtn.BackgroundColor3 = _G.AntiMonstroAtivo and Color3.fromRGB(255, 100, 0) or Color3.fromRGB(70, 70, 80)
end)

-- Sincronização dos Valores
InputSpeed.FocusLost:Connect(function()
    local val = tonumber(InputSpeed.Text)
    if val then _G.VelocidadeSalva = math.clamp(val, 16, 400) else InputSpeed.Text = tostring(_G.VelocidadeSalva) end
end)

InputJump.FocusLost:Connect(function()
    local val = tonumber(InputJump.Text)
    if val then _G.PuloSalvo = math.clamp(val, 30, 250) else InputJump.Text = tostring(_G.PuloSalvo) end
end)

-- ENGINES ATIVAS (MANTÉM AS MUDANÇAS)
RunService.Stepped:Connect(function()
    pcall(function()
        local char = Player.Character
        if char and char.Parent and _G.AntiMonstroAtivo then
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)
end)

task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        pcall(function()
            local char = Player.Character
            if char and char.Parent then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local rootPart = char:FindFirstChild("HumanoidRootPart")
                
                if hum and hum.Parent then
                    hum.UseJumpPower = true
                    if hum.WalkSpeed ~= _G.VelocidadeSalva then hum.WalkSpeed = _G.VelocidadeSalva end
                    if hum.JumpPower ~= _G.PuloSalvo then hum.JumpPower = _G.PuloSalvo end
                end
                
                if rootPart and rootPart.Position.Y < -60 then
                    rootPart.CFrame = CFrame.new(0, 25, 0)
                    task.wait(0.1)
                end
            end
        end)
        task.wait(0.15)
    end
end)
