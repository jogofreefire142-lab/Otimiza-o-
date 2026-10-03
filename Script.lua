-- SCRIPT ATUALIZADO 2026 - UNIVERSAL PARA TODOS OS EXECUTORES E CELULARES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer

-- Memória de salvamento (Valores padrão que você escolheu)
_G.VelocidadeSalva = 260
_G.PuloSalvo = 110

-- Limpa interfaces antigas para não acumular lag
if CoreGui:FindFirstChild("ConfigVelocidade2026") then
    CoreGui["ConfigVelocidade2026"]:Destroy()
end

-- CRIANDO A INTERFACE VISUAL (ADAPTADA PARA MOBILE)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ConfigVelocidade2026"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 190, 0, 140)
MainFrame.Position = UDim2.new(0.1, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 150)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Botão para Minimizar / Esconder o Menu
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 50, 0, 25)
ToggleButton.Position = UDim2.new(0.1, 0, 0.15, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
ToggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
ToggleButton.Text = "ABRIR"
ToggleButton.TextSize = 12
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Parent = ScreenGui

-- Lógica para Abrir/Fechar a janelinha
ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    if MainFrame.Visible then
        ToggleButton.Text = "FECHAR"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    else
        ToggleButton.Text = "OPEN"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
    end
end)
ToggleButton.Text = "FECHAR"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)

-- Texto Velocidade
local LabelSpeed = Instance.new("TextLabel")
LabelSpeed.Size = UDim2.new(1, 0, 0.2, 0)
LabelSpeed.Position = UDim2.new(0, 0, 0.05, 0)
LabelSpeed.Text = "Velocidade:"
LabelSpeed.TextColor3 = Color3.fromRGB(255, 255, 255)
LabelSpeed.BackgroundTransparency = 1
LabelSpeed.TextSize = 13
LabelSpeed.Parent = MainFrame

-- Input Velocidade
local InputSpeed = Instance.new("TextBox")
InputSpeed.Size = UDim2.new(0.8, 0, 0.2, 0)
InputSpeed.Position = UDim2.new(0.1, 0, 0.25, 0)
InputSpeed.Text = tostring(_G.VelocidadeSalva)
InputSpeed.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
InputSpeed.TextColor3 = Color3.fromRGB(0, 255, 100)
InputSpeed.TextSize = 14
InputSpeed.Parent = MainFrame

-- Texto Pulo
local LabelJump = Instance.new("TextLabel")
LabelJump.Size = UDim2.new(1, 0, 0.2, 0)
LabelJump.Position = UDim2.new(0, 0, 0.5, 0)
LabelJump.Text = "Pulo Fixo (Alto):"
LabelJump.TextColor3 = Color3.fromRGB(255, 255, 255)
LabelJump.BackgroundTransparency = 1
LabelJump.TextSize = 13
LabelJump.Parent = MainFrame

-- Input Pulo
local InputJump = Instance.new("TextBox")
InputJump.Size = UDim2.new(0.8, 0, 0.2, 0)
InputJump.Position = UDim2.new(0.1, 0, 0.7, 0)
InputJump.Text = tostring(_G.PuloSalvo)
InputJump.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
InputJump.TextColor3 = Color3.fromRGB(0, 255, 100)
InputJump.TextSize = 14
InputJump.Parent = MainFrame

-- SISTEMA DE SALVAMENTO AUTOMÁTICO
InputSpeed.FocusLost:Connect(function()
    local val = tonumber(InputSpeed.Text)
    if val then _G.VelocidadeSalva = val else InputSpeed.Text = tostring(_G.VelocidadeSalva) end
end)

InputJump.FocusLost:Connect(function()
    local val = tonumber(InputJump.Text)
    if val then _G.PuloSalvo = val else InputJump.Text = tostring(_G.PuloSalvo) end
end)

-- LOOP DE EXECUÇÃO INVIOLÁVEL (MANTÉM OS VALORES MESMO SE MORRER)
RunService.RenderStepped:Connect(function()
    pcall(function()
        local char = Player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.UseJumpPower = true
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
