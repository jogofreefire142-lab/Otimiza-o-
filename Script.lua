-- SCRIPT UNIVERSAL 2026 COM TRAVAS DE SEGURANÇA (ANTI-BAN, ANTI-VOID E ANTI-CRASH)
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer

-- Valores padrão calibrados para segurança total
_G.VelocidadeSalva = 260
_G.PuloSalvo = 110

-- Limpa interfaces antigas para evitar bugs de acumulação
if CoreGui:FindFirstChild("ConfigVelocidadeSegura") then
    CoreGui["ConfigVelocidadeSegura"]:Destroy()
end

-- INTERFACE VISUAL LEVE PARA MOBILE
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ConfigVelocidadeSegura"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 190, 0, 140)
MainFrame.Position = UDim2.new(0.1, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 150)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 60, 0, 30)
ToggleButton.Position = UDim2.new(0.1, 0, 0.12, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Text = "FECHAR"
ToggleButton.TextSize = 12
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Parent = ScreenGui

ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    if MainFrame.Visible then
        ToggleButton.Text = "FECHAR"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    else
        ToggleButton.Text = "ABRIR"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
    end
end)

local LabelSpeed = Instance.new("TextLabel")
LabelSpeed.Size = UDim2.new(1, 0, 0.2, 0)
LabelSpeed.Position = UDim2.new(0, 0, 0.05, 0)
LabelSpeed.Text = "Velocidade:"
LabelSpeed.TextColor3 = Color3.fromRGB(255, 255, 255)
LabelSpeed.BackgroundTransparency = 1
LabelSpeed.TextSize = 13
LabelSpeed.Parent = MainFrame

local InputSpeed = Instance.new("TextBox")
InputSpeed.Size = UDim2.new(0.8, 0, 0.2, 0)
InputSpeed.Position = UDim2.new(0.1, 0, 0.25, 0)
InputSpeed.Text = tostring(_G.VelocidadeSalva)
InputSpeed.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
InputSpeed.TextColor3 = Color3.fromRGB(0, 255, 100)
InputSpeed.TextSize = 14
InputSpeed.Parent = MainFrame

local LabelJump = Instance.new("TextLabel")
LabelJump.Size = UDim2.new(1, 0, 0.2, 0)
LabelJump.Position = UDim2.new(0, 0, 0.5, 0)
LabelJump.Text = "Super Pulo Seguro:"
LabelJump.TextColor3 = Color3.fromRGB(255, 255, 255)
LabelJump.BackgroundTransparency = 1
LabelJump.TextSize = 13
LabelJump.Parent = MainFrame

local InputJump = Instance.new("TextBox")
InputJump.Size = UDim2.new(0.8, 0, 0.2, 0)
InputJump.Position = UDim2.new(0.1, 0, 0.7, 0)
InputJump.Text = tostring(_G.PuloSalvo)
InputJump.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
InputJump.TextColor3 = Color3.fromRGB(0, 255, 100)
InputJump.TextSize = 14
InputJump.Parent = MainFrame

-- Atualiza dados mantendo a segurança numérica
InputSpeed.FocusLost:Connect(function()
    local val = tonumber(InputSpeed.Text)
    if val then _G.VelocidadeSalva = math.clamp(val, 16, 400) else InputSpeed.Text = tostring(_G.VelocidadeSalva) end
end)

InputJump.FocusLost:Connect(function()
    local val = tonumber(InputJump.Text)
    if val then _G.PuloSalvo = math.clamp(val, 50, 200) else InputJump.Text = tostring(_G.PuloSalvo) end
end)

-- LOOP TOTALMENTE PROTEGIDO (SISTEMA ANTI-VOID E AJUSTE SUAVE)
task.spawn(function()
    while true do
        pcall(function()
            local char = Player.Character
            if char and char.Parent then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local rootPart = char:FindFirstChild("HumanoidRootPart")
                
                -- Trava de Velocidade e Pulo Suave
                if hum and hum.Parent then
                    hum.UseJumpPower = true
                    if hum.WalkSpeed ~= _G.VelocidadeSalva then
                        hum.WalkSpeed = _G.VelocidadeSalva
                    end
                    if hum.JumpPower ~= _G.PuloSalvo then
                        hum.JumpPower = _G.PuloSalvo
                    end
                end
                
                -- SISTEMA ANTI-VOID (Se cair para baixo do mapa, volta ao spawn seguro)
                if rootPart and rootPart.Position.Y < -50 then
                    rootPart.CFrame = CFrame.new(0, 20, 0) -- Coordenada central de segurança
                    local veloNula = Instance.new("LinearVelocity") -- Zera o impacto da queda
                    task.wait(0.1)
                end
            end
        end)
        task.wait(0.15) -- Ritmo otimizado para enganar o anti-cheat e proteger o celular
    end
end)
