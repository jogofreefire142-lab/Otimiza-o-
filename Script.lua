local NomeDoArquivo = "SanguineArt_2026_Auto.txt"
_G.Config = { EspAtivo = false, AutoGhoul = false, TargetSkills = false, AutoKen = false }

if isfile and isfile(NomeDoArquivo) then
    local textoSalvo = readfile(NomeDoArquivo)
    local carregar = game:GetService("HttpService"):JSONDecode(textoSalvo)
    if carregar then _G.Config = carregar end
end

local function SalvarConfiguracoes()
    if writefile then
        local textoParaSalvar = game:GetService("HttpService"):JSONEncode(_G.Config)
        writefile(NomeDoArquivo, textoParaSalvar)
    end
end

local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TitleLabel = Instance.new("TextLabel")
local ToggleButton = Instance.new("TextButton")
local EspButton = Instance.new("TextButton")
local GhoulButton = Instance.new("TextButton")
local SkillsButton = Instance.new("TextButton")
local KenButton = Instance.new("TextButton")

ScreenGui.Parent = game:GetService("CoreGui")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 10, 20)
MainFrame.Position = UDim2.new(0.5, -90, 0.35, -90)
MainFrame.Size = UDim2.new(0, 180, 0, 190)
MainFrame.Visible = true
Instance.new("UICorner", MainFrame)

TitleLabel.Parent = MainFrame
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "SANGUINE BYPASS 2026"
TitleLabel.TextColor3 = Color3.fromRGB(160, 32, 240)
TitleLabel.TextSize = 12
TitleLabel.Font = Enum.Font.SourceSansBold

local function AtualizarInterface()
    EspButton.BackgroundColor3 = _G.Config.EspAtivo and Color3.fromRGB(160, 32, 240) or Color3.fromRGB(30, 25, 35)
    EspButton.Text = _G.Config.EspAtivo and "ESP Status: LIGADO" or "ESP Status: DESLIGADO"
    
    GhoulButton.BackgroundColor3 = _G.Config.AutoGhoul and Color3.fromRGB(160, 32, 240) or Color3.fromRGB(30, 25, 35)
    GhoulButton.Text = _G.Config.AutoGhoul and "Auto-Ghoul: LIGADO" or "Auto-Ghoul: DESLIGADO"
    
    SkillsButton.BackgroundColor3 = _G.Config.TargetSkills and Color3.fromRGB(160, 32, 240) or Color3.fromRGB(30, 25, 35)
    SkillsButton.Text = _G.Config.TargetSkills and "Skills no Alvo: LIGADO" or "Skills no Alvo: DESLIGADO"

    KenButton.BackgroundColor3 = _G.Config.AutoKen and Color3.fromRGB(160, 32, 240) or Color3.fromRGB(30, 25, 35)
    KenButton.Text = _G.Config.AutoKen and "Auto-Observation: LIGADO" or "Auto-Observation: DESLIGADO"
end

local bLista = {{EspButton, 0.2}, {GhoulButton, 0.4}, {SkillsButton, 0.6}, {KenButton, 0.8}}
for _, b in pairs(bLista) do
    b.Parent = MainFrame
    b.Position = UDim2.new(0.08, 0, b, 0)
    b.Size = UDim2.new(0, 150, 0, 25)
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 11
    b.Font = Enum.Font.SourceSansBold
    Instance.new("UICorner", b)
end

EspButton.MouseButton1Click:Connect(function()
    _G.Config.EspAtivo = not _G.Config.EspAtivo
    SalvarConfiguracoes()
    AtualizarInterface()
    if not _G.Config.EspAtivo then
        for _, p in pairs(game.Players:GetPlayers()) do
            pcall(function() p.Character.Head.EspTag:Destroy() end)
        end
    end
end)

GhoulButton.MouseButton1Click:Connect(function()
    _G.Config.AutoGhoul = not _G.Config.AutoGhoul
    SalvarConfiguracoes()
    AtualizarInterface()
end)

SkillsButton.MouseButton1Click:Connect(function()
    _G.Config.TargetSkills = not _G.Config.TargetSkills
    SalvarConfiguracoes()
    AtualizarInterface()
end)

KenButton.MouseButton1Click:Connect(function()
    _G.Config.AutoKen = not _G.Config.AutoKen
    SalvarConfiguracoes()
    AtualizarInterface()
end)

AtualizarInterface()

ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 25, 35)
ToggleButton.Position = UDim2.new(0.02, 0, 0.12, 0)
ToggleButton.Size = UDim2.new(0, 50, 0, 25)
ToggleButton.Text = "OCULTAR"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 10
ToggleButton.Font = Enum.Font.SourceSansBold
Instance.new("UICorner", ToggleButton)

ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    ToggleButton.Text = MainFrame.Visible and "OCULTAR" or "MOSTRAR"
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if _G.Config.EspAtivo then
            pcall(function()
                for _, p in pairs(game.Players:GetPlayers()) do
                    if p ~= game.Players.LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") then
                        local head = p.Character.Head
                        local tag = head:FindFirstChild("EspTag") or Instance.new("BillboardGui")
                        if not head:FindFirstChild("EspTag") then
                            tag.Name = "EspTag"
                            tag.Size = UDim2.new(0, 200, 0, 50)
                            tag.AlwaysOnTop = true
                            tag.ExtentsOffset = Vector3.new(0, 3, 0)
                            local tl = Instance.new("TextLabel", tag)
                            tl.Size = UDim2.new(1, 0, 1, 0)
                            tl.BackgroundTransparency = 1
                            tl.TextColor3 = Color3.fromRGB(160, 32, 240)
                            tl.TextSize = 11
                            tl.Font = Enum.Font.SourceSansBold
                            tag.Parent = head
                        end
                        tag.TextLabel.Text = p.Name .. "\n❤️ HP: " .. math.floor(p.Character.Humanoid.Health)
                    end
                end
            end)
        end
    end
end)

local function encontrarAlvoPvP()
    local menorDistancia = 85
    local alvoMaisProximo = nil
    pcall(function()
        local meuHrp = game.Players.LocalPlayer.Character.HumanoidRootPart
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= game.Players.LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (meuHrp.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if dist < menorDistancia then
                    menorDistancia = dist
                    alvoMaisProximo = p
                end
            end
        end
    end)
    return alvoMaisProximo
end

task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.Config.TargetSkills then
            pcall(function()
                local alvo = encontrarAlvoPvP()
                local char = game.Players.LocalPlayer.Character
                if alvo and char:FindFirstChildOfClass("Tool") then
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool:FindFirstChild("RemoteEvent") or tool:FindFirstChild("RemoteFunction") then
                        local localizacaoInimigo = alvo.Character.HumanoidRootPart.CFrame
                        local vim = game:GetService("VirtualInputManager")
                        vim:SendKeyEvent(true, Enum.KeyCode.Z, false, game)
                        task.wait(0.05)
                        vim:SendKeyEvent(true, Enum.KeyCode.Y, false, game)
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.3)
        if _G.Config.AutoGhoul then
            pcall(function()
                local hum = game.Players.LocalPlayer.Character.Humanoid
                if hum.Health < hum.MaxHealth and encontrarAlvoPvP() then
                    local vim = game:GetService("VirtualInputManager")
                    vim:SendKeyEvent(true, Enum.KeyCode.T, false, game)
                    vim:SendKeyEvent(true, Enum.KeyCode.Y, false, game)
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.4)
        if _G.Config.AutoKen then
            pcall(function()
                local player = game.Players.LocalPlayer
                local ativo = player.PlayerGui:FindFirstChild("ScreenGui") and player.PlayerGui.ScreenGui:FindFirstChild("ImageLabel")
                if not ativo and encontrarAlvoPvP() then
                    local vim = game:GetService("VirtualInputManager")
                    vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(10)
        pcall(function()
            for _, v in pairs(game:GetService("Workspace"):GetChildren()) do
                if v.Name == "Effect" or v.Name == "Particle" or v:IsA("Debris") then v:Destroy() end
            end
        end)
    end
end)
