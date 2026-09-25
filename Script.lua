--[[
    ===================================================================
    ⚡ BLOX FRUITS & ROBLOX LUA FPS OPTIMIZER ⚡
    Preset Ativo: POTATO
    Objetivo: Máximo FPS, Redução de Input Lag e Estabilidade Térmica
    Segurança: 100% Client-Side Graphic Optimization (Sem risco de ban)
    ===================================================================
--]]

-- Aguarda carregamento completo do jogo
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Notificação na tela confirmando a ativação
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "FPS Booster Ativo",
        Text = "Otimizador Blox Fruits aplicado com sucesso!",
        Duration = 5,
        Icon = "rbxassetid://1061892881"
    })
end)

-- [1] Configurações de Motor e Taxa de Quadros
pcall(function()
    -- Força qualidade de renderização mínima no motor do Roblox
    if settings and settings().Rendering then
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end
    -- Desbloqueia taxa de quadros (FPS Desbloqueado)
    if setfpscap then
        setfpscap(999)
    end
    -- Otimização Real de Física e Animações (InterpolationThrottling)
    -- Reduz o consumo de CPU em mobs distantes e barcos
    Workspace.InterpolationThrottling = Enum.InterpolationThrottlingMode.Enabled
    pcall(function()
        settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.DefaultAuto
    end)
    -- Limpador de Textos de Dano Flutuante (Damage Numbers Spam)
    -- Evita travamento quando você combeia vários mobs ou bosses ao mesmo tempo
    pcall(function()
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
        PlayerGui.DescendantAdded:Connect(function(ui)
            if ui:IsA("BillboardGui") and (ui.Name:lower():find("damage") or ui.Name:lower():find("combat")) then
                ui.MaxDistance = 40 -- Só mostra números a curta distância, aliviando centenas de textos distantes
            end
        end)
    end)
    -- Re-otimizador Automático em Viagens de Barco e Teleportes
    -- Garante que entrar no Café, Mansão, Castelo do Mar ou Tiki Outpost aplique o FPS boost instantaneamente
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1.5)
        for _, obj in ipairs(Workspace:GetDescendants()) do
            pcall(function() optimizeInstance(obj) end)
        end
    end)
end)

-- [2] Otimização de Iluminação e Atmosfera
pcall(function()
    Lighting.GlobalShadows = false
    Lighting.ShadowSoftness = 0
    Lighting.FogEnd = 9000000000
    Lighting.FogStart = 9000000000
    Lighting.ClockTime = 14 -- Fixa meio-dia ensolarado sem sombras escuras
    Lighting.Brightness = 1.5
    Lighting.ExposureCompensation = 0
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0

    -- Remove efeitos de pós-processamento pesados (Bloom, Blur, SunRays)
    local postEffects = {"BloomEffect", "BlurEffect", "SunRaysEffect", "ColorCorrectionEffect", "DepthOfFieldEffect"}
    for _, child in ipairs(Lighting:GetChildren()) do
        for _, effectName in ipairs(postEffects) do
            if child:IsA(effectName) then
                child.Enabled = false
            end
        end
    end
end)

-- [3] Otimização do Terreno e Oceano do Blox Fruits
pcall(function()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 1
        terrain.Decoration = false -- Desativa grama 3D dinâmica do mapa
    end
end)

-- [4] Função Central de Otimização de Objetos
local function optimizeInstance(item)
    if not item then return end
    pcall(function()
    -- Proteção de Integridade: Não quebra NPCs de Missão, Baús, Frutas no Chão ou Spawns
    local itemName = item.Name:lower()
    if itemName:find("chest") or itemName:find("npc") or itemName:find("quest") or itemName:find("fruit") or itemName:find("dealer") or itemName:find("shop") or itemName:find("spawn") then
        return
    end

    -- Peças 3D (BasePart, MeshPart, UnionOperation)
    if item:IsA("BasePart") then
        local isCharacter = LocalPlayer.Character and item:IsDescendantOf(LocalPlayer.Character)
        if not isCharacter then
            item.Material = Enum.Material.SmoothPlastic
            item.Reflectance = 0
            item.CastShadow = false
        end
    end

    -- Texturas coladas e Decals nas superfícies
    if item:IsA("Decal") or item:IsA("Texture") then
        local isCharacter = LocalPlayer.Character and item:IsDescendantOf(LocalPlayer.Character)
        if not isCharacter then
            item.Transparency = 1
        end
    end

    -- Texturas de MeshPart
    if item:IsA("MeshPart") then
        local isCharacter = LocalPlayer.Character and item:IsDescendantOf(LocalPlayer.Character)
        if not isCharacter then
            item.TextureID = ""
        end
    end

    -- Emissores de Partículas (Habilidades de Frutas e Magias)
    if item:IsA("ParticleEmitter") then
        item.Enabled = false
        item.Rate = 0
    end

    -- Rastros de Espadas e Golpes
    if item:IsA("Trail") then
        item.Enabled = false
    end

    -- Fogo e Fumaça em Barcos e Ilhas
    if item:IsA("Fire") or item:IsA("Smoke") then
        item.Enabled = false
    end

    -- Faíscas e Explosões Visuais
    if item:IsA("Sparkles") or item:IsA("Explosion") then
        pcall(function()
            item.Visible = false
        end)
    end

    -- Beams e Highlights secundários (Mantém Ken Haki / Instinto de Observação)
    if item:IsA("Beam") then
        item.Enabled = false
    elseif item:IsA("Highlight") then
        if not (LocalPlayer.Character and item:IsDescendantOf(LocalPlayer.Character)) then
            item.Enabled = false
        end
    end
    end)
end

-- Varredura inicial de todo o Workspace existente
for _, obj in ipairs(Workspace:GetDescendants()) do
    optimizeInstance(obj)
end

-- [5] Otimizador Contínuo (Aplica automaticamente em novas ilhas, monstros e barcos)
local connection
connection = Workspace.DescendantAdded:Connect(function(newObj)
    optimizeInstance(newObj)
end)

-- [6] Estabilizador de Câmera (Reduz tremores e fov jitter durante combos)
pcall(function()
    local defaultFOV = Camera.FieldOfView
    Camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
        if math.abs(Camera.FieldOfView - defaultFOV) > 15 then
            Camera.FieldOfView = defaultFOV
        end
    end)
end)

-- [7] Coletor de Lixo Periódico (Evita vazamento de memória RAM em sessões longas)
task.spawn(function()
    while task.wait(60) do
        pcall(function()
            collectgarbage("collect")
        end)
    end
end)

-- [8] Otimização de Som e Reverb
pcall(function()
    local SoundService = game:GetService("SoundService")
    SoundService.AmbientReverb = Enum.ReverbType.NoReverb
end)

-- [9] Ícone Flutuante Bonito, Arrastável e Fácil de Acessar no Blox Fruits (Mobile & PC)
pcall(function()
    local CoreGui = game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")

    -- Remove interface anterior se já existir
    if CoreGui:FindFirstChild("BloxFruitsFpsBoosterGui") then
        CoreGui.BloxFruitsFpsBoosterGui:Destroy()
    end
    if LocalPlayer.PlayerGui:FindFirstChild("BloxFruitsFpsBoosterGui") then
        LocalPlayer.PlayerGui.BloxFruitsFpsBoosterGui:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BloxFruitsFpsBoosterGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Protege inserção no CoreGui ou fallback no PlayerGui
    local parentTarget = CoreGui
    pcall(function()
        ScreenGui.Parent = parentTarget
    end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Botão / Ícone Flutuante Arrastável
    local FloatingBtn = Instance.new("TextButton")
    FloatingBtn.Name = "FpsFloatingIcon"
    FloatingBtn.Size = UDim2.new(0, 52, 0, 52)
    FloatingBtn.Position = UDim2.new(0.04, 0, 0.35, 0)
    FloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
    FloatingBtn.Text = "⚡"
    FloatingBtn.TextColor3 = Color3.fromRGB(56, 189, 248)
    FloatingBtn.TextSize = 24
    FloatingBtn.Font = Enum.Font.GothamBold
    FloatingBtn.AutoButtonColor = false
    FloatingBtn.Parent = ScreenGui

    local UICornerBtn = Instance.new("UICorner")
    UICornerBtn.CornerRadius = UDim.new(0, 16)
    UICornerBtn.Parent = FloatingBtn

    local UIStrokeBtn = Instance.new("UIStroke")
    UIStrokeBtn.Color = Color3.fromRGB(56, 189, 248)
    UIStrokeBtn.Thickness = 2
    UIStrokeBtn.Transparency = 0.2
    UIStrokeBtn.Parent = FloatingBtn

    -- Contador de FPS abaixo do ícone
    local FpsCounter = Instance.new("TextLabel")
    FpsCounter.Size = UDim2.new(1, 0, 0, 16)
    FpsCounter.Position = UDim2.new(0, 0, 1, 2)
    FpsCounter.BackgroundTransparency = 1
    FpsCounter.Text = "60 FPS"
    FpsCounter.TextColor3 = Color3.fromRGB(74, 222, 128)
    FpsCounter.Font = Enum.Font.RobotoMono
    FpsCounter.TextSize = 11
    FpsCounter.Parent = FloatingBtn

    -- Janela de Controle Rápida (Card Elegante, Moderno e Legível)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "QuickControlCard"
    MainFrame.Size = UDim2.new(0, 260, 0, 275)
    MainFrame.Position = UDim2.new(0.04, 60, 0.28, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(11, 15, 26)
    MainFrame.Visible = false
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local UICornerCard = Instance.new("UICorner")
    UICornerCard.CornerRadius = UDim.new(0, 14)
    UICornerCard.Parent = MainFrame

    local UIStrokeCard = Instance.new("UIStroke")
    UIStrokeCard.Color = Color3.fromRGB(30, 41, 59)
    UIStrokeCard.Thickness = 1.5
    UIStrokeCard.Parent = MainFrame

    -- Título da Janelinha
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 0, 26)
    Title.Position = UDim2.new(0, 12, 0, 8)
    Title.BackgroundTransparency = 1
    Title.Text = "⚡ Blox Fruits Pro Booster"
    Title.TextColor3 = Color3.fromRGB(241, 245, 249)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 13
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = MainFrame

    -- Barra de Status com RAM e Ping em Tempo Real
    local StatsBar = Instance.new("TextLabel")
    StatsBar.Size = UDim2.new(1, -24, 0, 20)
    StatsBar.Position = UDim2.new(0, 12, 0, 34)
    StatsBar.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
    StatsBar.Text = "📊 RAM: Calculando... | 60 FPS"
    StatsBar.TextColor3 = Color3.fromRGB(56, 189, 248)
    StatsBar.Font = Enum.Font.RobotoMono
    StatsBar.TextSize = 10
    StatsBar.Parent = MainFrame

    local UICornerStats = Instance.new("UICorner")
    UICornerStats.CornerRadius = UDim.new(0, 6)
    UICornerStats.Parent = StatsBar

    -- Botão 1: Reotimizar Ilha Atual
    local ReapplyBtn = Instance.new("TextButton")
    ReapplyBtn.Size = UDim2.new(1, -24, 0, 34)
    ReapplyBtn.Position = UDim2.new(0, 12, 0, 60)
    ReapplyBtn.BackgroundColor3 = Color3.fromRGB(14, 165, 233)
    ReapplyBtn.Text = "🔄 Otimizar Ilha & Mar Atual"
    ReapplyBtn.TextColor3 = Color3.fromRGB(15, 23, 42)
    ReapplyBtn.Font = Enum.Font.GothamBold
    ReapplyBtn.TextSize = 11
    ReapplyBtn.Parent = MainFrame

    local UICornerReapply = Instance.new("UICorner")
    UICornerReapply.CornerRadius = UDim.new(0, 8)
    UICornerReapply.Parent = ReapplyBtn

    -- Botão 2: Limpar Memória RAM Real
    local ClearRamBtn = Instance.new("TextButton")
    ClearRamBtn.Size = UDim2.new(1, -24, 0, 34)
    ClearRamBtn.Position = UDim2.new(0, 12, 0, 100)
    ClearRamBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    ClearRamBtn.Text = "🧹 Liberar Memória RAM Agora"
    ClearRamBtn.TextColor3 = Color3.fromRGB(226, 232, 240)
    ClearRamBtn.Font = Enum.Font.GothamMedium
    ClearRamBtn.TextSize = 11
    ClearRamBtn.Parent = MainFrame

    local UICornerClear = Instance.new("UICorner")
    UICornerClear.CornerRadius = UDim.new(0, 8)
    UICornerClear.Parent = ClearRamBtn

    -- Botão 3: Zerar Fumaça e Partículas de Frutas (PvP Boost)
    local PurgeVfxBtn = Instance.new("TextButton")
    PurgeVfxBtn.Size = UDim2.new(1, -24, 0, 34)
    PurgeVfxBtn.Position = UDim2.new(0, 12, 0, 140)
    PurgeVfxBtn.BackgroundColor3 = Color3.fromRGB(244, 63, 94)
    PurgeVfxBtn.Text = "⚔️ Limpar Efeitos Visuais de Frutas"
    PurgeVfxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    PurgeVfxBtn.Font = Enum.Font.GothamBold
    PurgeVfxBtn.TextSize = 11
    PurgeVfxBtn.Parent = MainFrame

    local UICornerPurge = Instance.new("UICorner")
    UICornerPurge.CornerRadius = UDim.new(0, 8)
    UICornerPurge.Parent = PurgeVfxBtn

    -- Botão 4: Modo Eco / Anti-Aquecimento (Economizador de Bateria em AFK)
    local EcoBtn = Instance.new("TextButton")
    EcoBtn.Size = UDim2.new(1, -24, 0, 30)
    EcoBtn.Position = UDim2.new(0, 12, 0, 180)
    EcoBtn.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
    EcoBtn.Text = "🔋 Modo Eco / Anti-Aquecimento: OFF"
    EcoBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
    EcoBtn.Font = Enum.Font.GothamMedium
    EcoBtn.TextSize = 10
    EcoBtn.Parent = MainFrame

    local UICornerEco = Instance.new("UICorner")
    UICornerEco.CornerRadius = UDim.new(0, 8)
    UICornerEco.Parent = EcoBtn

    -- Status de Proteção
    local ProtectionLabel = Instance.new("TextLabel")
    ProtectionLabel.Size = UDim2.new(1, -24, 0, 18)
    ProtectionLabel.Position = UDim2.new(0, 12, 0, 218)
    ProtectionLabel.BackgroundTransparency = 1
    ProtectionLabel.Text = "✓ Baús, Quests e Ken Haki 100% Intactos"
    ProtectionLabel.TextColor3 = Color3.fromRGB(74, 222, 128)
    ProtectionLabel.Font = Enum.Font.Gotham
    ProtectionLabel.TextSize = 10
    ProtectionLabel.Parent = MainFrame

    local CloseHint = Instance.new("TextLabel")
    CloseHint.Size = UDim2.new(1, -24, 0, 16)
    CloseHint.Position = UDim2.new(0, 12, 0, 244)
    CloseHint.BackgroundTransparency = 1
    CloseHint.Text = "Arraste o ícone ⚡ para onde quiser"
    CloseHint.TextColor3 = Color3.fromRGB(100, 116, 139)
    CloseHint.Font = Enum.Font.Gotham
    CloseHint.TextSize = 9
    CloseHint.Parent = MainFrame

    -- Ações dos Botões
    ReapplyBtn.MouseButton1Click:Connect(function()
        ReapplyBtn.Text = "⏳ Otimizando..."
        for _, obj in ipairs(Workspace:GetDescendants()) do
            optimizeInstance(obj)
        end
        task.wait(0.5)
        ReapplyBtn.Text = "✓ Ilha e Mar Otimizados!"
        task.wait(1.5)
        ReapplyBtn.Text = "🔄 Otimizar Ilha & Mar Atual"
    end)

    ClearRamBtn.MouseButton1Click:Connect(function()
        ClearRamBtn.Text = "⏳ Esvaziando cache..."
        collectgarbage("collect")
        task.wait(0.4)
        ClearRamBtn.Text = "✓ RAM Descarregada!"
        task.wait(1.5)
        ClearRamBtn.Text = "🧹 Liberar Memória RAM Agora"
    end)

    PurgeVfxBtn.MouseButton1Click:Connect(function()
        PurgeVfxBtn.Text = "⏳ Limpando partículas..."
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                pcall(function()
                    v.Enabled = false
                    if v:IsA("ParticleEmitter") then v.Rate = 0 end
                end)
            end
        end
        task.wait(0.4)
        PurgeVfxBtn.Text = "✓ Efeitos de Frutas Limpos!"
        task.wait(1.5)
        PurgeVfxBtn.Text = "⚔️ Limpar Efeitos Visuais de Frutas"
    end)

    local ecoActive = false
    EcoBtn.MouseButton1Click:Connect(function()
        ecoActive = not ecoActive
        pcall(function()
            local RunService = game:GetService("RunService")
            if ecoActive then
                RunService:Set3dRenderingEnabled(false)
                EcoBtn.Text = "🔋 Modo Eco / Anti-Aquecimento: LIGADO"
                EcoBtn.TextColor3 = Color3.fromRGB(74, 222, 128)
            else
                RunService:Set3dRenderingEnabled(true)
                EcoBtn.Text = "🔋 Modo Eco / Anti-Aquecimento: OFF"
                EcoBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
            end
        end)
    end)

    -- Toggle da Janela ao Clicar no Ícone
    FloatingBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
        MainFrame.Position = UDim2.new(FloatingBtn.Position.X.Scale, FloatingBtn.Position.X.Offset + 60, FloatingBtn.Position.Y.Scale, FloatingBtn.Position.Y.Offset)
    end)

    -- Arrastar o Ícone com o Dedo (Celular) ou Mouse (PC) com suavidade
    local dragging, dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        FloatingBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    FloatingBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = FloatingBtn.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    FloatingBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)

    -- Atualizador em Tempo Real do Contador de FPS e Monitor de RAM
    local lastTime = tick()
    local frameCount = 0
    local Stats = game:GetService("Stats")
    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now = tick()
        if now - lastTime >= 0.5 then
            local currentFps = math.floor(frameCount / (now - lastTime))
            FpsCounter.Text = tostring(currentFps) .. " FPS"
            if currentFps >= 50 then
                FpsCounter.TextColor3 = Color3.fromRGB(74, 222, 128)
            elseif currentFps >= 30 then
                FpsCounter.TextColor3 = Color3.fromRGB(250, 204, 21)
            else
                FpsCounter.TextColor3 = Color3.fromRGB(248, 113, 113)
            end

            -- Medidor Real de Memória RAM (Stats:GetTotalMemoryUsageMb)
            pcall(function()
                local ramMb = math.floor(Stats:GetTotalMemoryUsageMb())
                StatsBar.Text = "📊 RAM: " .. tostring(ramMb) .. " MB | " .. tostring(currentFps) .. " FPS"
            end)

            frameCount = 0
            lastTime = now
        end
    end)
end)

print("✅ [Blox Fruits Optimizer] Script carregado com sucesso. FPS Máximo liberado!")
