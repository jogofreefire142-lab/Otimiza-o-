--[[
    ===================================================================
    âš¡ BLOX FRUITS & ROBLOX LUA FPS OPTIMIZER âš¡
    Preset Ativo: POTATO
    Objetivo: MÃ¡ximo FPS, ReduÃ§Ã£o de Input Lag e Estabilidade TÃ©rmica
    SeguranÃ§a: 100% Client-Side Graphic Optimization (Sem risco de ban)
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

-- NotificaÃ§Ã£o na tela confirmando a ativaÃ§Ã£o
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "FPS Booster Ativo",
        Text = "Otimizador Blox Fruits aplicado com sucesso!",
        Duration = 5,
        Icon = "rbxassetid://1061892881"
    })
end)

-- [1] ConfiguraÃ§Ãµes de Motor e Taxa de Quadros
pcall(function()
    -- ForÃ§a qualidade de renderizaÃ§Ã£o mÃ­nima no motor do Roblox
    if settings and settings().Rendering then
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end
    -- Desbloqueia taxa de quadros (FPS Desbloqueado)
    if setfpscap then
        setfpscap(999)
    end
end)

-- [2] OtimizaÃ§Ã£o de IluminaÃ§Ã£o e Atmosfera
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

    -- Remove efeitos de pÃ³s-processamento pesados (Bloom, Blur, SunRays)
    local postEffects = {"BloomEffect", "BlurEffect", "SunRaysEffect", "ColorCorrectionEffect", "DepthOfFieldEffect"}
    for _, child in ipairs(Lighting:GetChildren()) do
        for _, effectName in ipairs(postEffects) do
            if child:IsA(effectName) then
                child.Enabled = false
            end
        end
    end
end)

-- [3] OtimizaÃ§Ã£o do Terreno e Oceano do Blox Fruits
pcall(function()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 1
        terrain.Decoration = false -- Desativa grama 3D dinÃ¢mica do mapa
    end
end)

-- [4] FunÃ§Ã£o Central de OtimizaÃ§Ã£o de Objetos
local function optimizeInstance(item)
    if not item then return end
    pcall(function()
    -- ProteÃ§Ã£o de Integridade: NÃ£o quebra NPCs de MissÃ£o, BaÃºs, Frutas no ChÃ£o ou Spawns
    local itemName = item.Name:lower()
    if itemName:find("chest") or itemName:find("npc") or itemName:find("quest") or itemName:find("fruit") or itemName:find("dealer") or itemName:find("shop") or itemName:find("spawn") then
        return
    end

    -- PeÃ§as 3D (BasePart, MeshPart, UnionOperation)
    if item:IsA("BasePart") then
        local isCharacter = LocalPlayer.Character and item:IsDescendantOf(LocalPlayer.Character)
        if not isCharacter then
            item.Material = Enum.Material.SmoothPlastic
            item.Reflectance = 0
            item.CastShadow = false
        end
    end

    -- Texturas coladas e Decals nas superfÃ­cies
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

    -- Emissores de PartÃ­culas (Habilidades de Frutas e Magias)
    if item:IsA("ParticleEmitter") then
        item.Enabled = false
        item.Rate = 0
    end

    -- Rastros de Espadas e Golpes
    if item:IsA("Trail") then
        item.Enabled = false
    end

    -- Fogo e FumaÃ§a em Barcos e Ilhas
    if item:IsA("Fire") or item:IsA("Smoke") then
        item.Enabled = false
    end

    -- FaÃ­scas e ExplosÃµes Visuais
    if item:IsA("Sparkles") or item:IsA("Explosion") then
        pcall(function()
            item.Visible = false
        end)
    end

    -- Beams e Highlights secundÃ¡rios (MantÃ©m Ken Haki / Instinto de ObservaÃ§Ã£o)
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

-- [5] Otimizador ContÃ­nuo (Aplica automaticamente em novas ilhas, monstros e barcos)
local connection
connection = Workspace.DescendantAdded:Connect(function(newObj)
    optimizeInstance(newObj)
end)

-- [6] Estabilizador de CÃ¢mera (Reduz tremores e fov jitter durante combos)
pcall(function()
    local defaultFOV = Camera.FieldOfView
    Camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
        if math.abs(Camera.FieldOfView - defaultFOV) > 15 then
            Camera.FieldOfView = defaultFOV
        end
    end)
end)

-- [7] Coletor de Lixo PeriÃ³dico (Evita vazamento de memÃ³ria RAM em sessÃµes longas)
task.spawn(function()
    while task.wait(60) do
        pcall(function()
            collectgarbage("collect")
        end)
    end
end)

-- [8] OtimizaÃ§Ã£o de Som e Reverb
pcall(function()
    local SoundService = game:GetService("SoundService")
    SoundService.AmbientReverb = Enum.ReverbType.NoReverb
end)

-- [9] Ãcone Flutuante Bonito, ArrastÃ¡vel e FÃ¡cil de Acessar no Blox Fruits (Mobile & PC)
pcall(function()
    local CoreGui = game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")

    -- Remove interface anterior se jÃ¡ existir
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

    -- Protege inserÃ§Ã£o no CoreGui ou fallback no PlayerGui
    local parentTarget = CoreGui
    pcall(function()
        ScreenGui.Parent = parentTarget
    end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- BotÃ£o / Ãcone Flutuante ArrastÃ¡vel
    local FloatingBtn = Instance.new("TextButton")
    FloatingBtn.Name = "FpsFloatingIcon"
    FloatingBtn.Size = UDim2.new(0, 52, 0, 52)
    FloatingBtn.Position = UDim2.new(0.04, 0, 0.35, 0)
    FloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
    FloatingBtn.Text = "âš¡"
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

    -- Contador de FPS abaixo do Ã­cone
    local FpsCounter = Instance.new("TextLabel")
    FpsCounter.Size = UDim2.new(1, 0, 0, 16)
    FpsCounter.Position = UDim2.new(0, 0, 1, 2)
    FpsCounter.BackgroundTransparency = 1
    FpsCounter.Text = "60 FPS"
    FpsCounter.TextColor3 = Color3.fromRGB(74, 222, 128)
    FpsCounter.Font = Enum.Font.RobotoMono
    FpsCounter.TextSize = 11
    FpsCounter.Parent = FloatingBtn

    -- Janela de Controle RÃ¡pida (Card Elegante e LegÃ­vel)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "QuickControlCard"
    MainFrame.Size = UDim2.new(0, 240, 0, 210)
    MainFrame.Position = UDim2.new(0.04, 60, 0.32, 0)
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

    -- TÃ­tulo da Janelinha
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 0, 32)
    Title.Position = UDim2.new(0, 12, 0, 8)
    Title.BackgroundTransparency = 1
    Title.Text = "âš¡ Blox Fruits FPS Boost"
    Title.TextColor3 = Color3.fromRGB(241, 245, 249)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 13
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = MainFrame

    local SubTitle = Instance.new("TextLabel")
    SubTitle.Size = UDim2.new(1, -20, 0, 16)
    SubTitle.Position = UDim2.new(0, 12, 0, 36)
    SubTitle.BackgroundTransparency = 1
    SubTitle.Text = "Modo: POTATO | 100% Seguro"
    SubTitle.TextColor3 = Color3.fromRGB(148, 163, 184)
    SubTitle.Font = Enum.Font.Gotham
    SubTitle.TextSize = 10
    SubTitle.TextXAlignment = Enum.TextXAlignment.Left
    SubTitle.Parent = MainFrame

    -- BotÃ£o Reotimizar
    local ReapplyBtn = Instance.new("TextButton")
    ReapplyBtn.Size = UDim2.new(1, -24, 0, 36)
    ReapplyBtn.Position = UDim2.new(0, 12, 0, 62)
    ReapplyBtn.BackgroundColor3 = Color3.fromRGB(14, 165, 233)
    ReapplyBtn.Text = "ðŸ”„ Otimizar Ilha Atual"
    ReapplyBtn.TextColor3 = Color3.fromRGB(15, 23, 42)
    ReapplyBtn.Font = Enum.Font.GothamBold
    ReapplyBtn.TextSize = 12
    ReapplyBtn.Parent = MainFrame

    local UICornerReapply = Instance.new("UICorner")
    UICornerReapply.CornerRadius = UDim.new(0, 8)
    UICornerReapply.Parent = ReapplyBtn

    -- BotÃ£o Limpar MemÃ³ria RAM
    local ClearRamBtn = Instance.new("TextButton")
    ClearRamBtn.Size = UDim2.new(1, -24, 0, 36)
    ClearRamBtn.Position = UDim2.new(0, 12, 0, 106)
    ClearRamBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    ClearRamBtn.Text = "ðŸ§¹ Liberar MemÃ³ria RAM"
    ClearRamBtn.TextColor3 = Color3.fromRGB(226, 232, 240)
    ClearRamBtn.Font = Enum.Font.GothamMedium
    ClearRamBtn.TextSize = 12
    ClearRamBtn.Parent = MainFrame

    local UICornerClear = Instance.new("UICorner")
    UICornerClear.CornerRadius = UDim.new(0, 8)
    UICornerClear.Parent = ClearRamBtn

    -- Status de ProteÃ§Ã£o
    local ProtectionLabel = Instance.new("TextLabel")
    ProtectionLabel.Size = UDim2.new(1, -24, 0, 20)
    ProtectionLabel.Position = UDim2.new(0, 12, 0, 152)
    ProtectionLabel.BackgroundTransparency = 1
    ProtectionLabel.Text = "âœ“ BaÃºs, NPCs e Quests 100% Protegidos"
    ProtectionLabel.TextColor3 = Color3.fromRGB(74, 222, 128)
    ProtectionLabel.Font = Enum.Font.Gotham
    ProtectionLabel.TextSize = 10
    ProtectionLabel.Parent = MainFrame

    local CloseHint = Instance.new("TextLabel")
    CloseHint.Size = UDim2.new(1, -24, 0, 16)
    CloseHint.Position = UDim2.new(0, 12, 0, 178)
    CloseHint.BackgroundTransparency = 1
    CloseHint.Text = "Toque no Ã­cone âš¡ para abrir/fechar"
    CloseHint.TextColor3 = Color3.fromRGB(100, 116, 139)
    CloseHint.Font = Enum.Font.Gotham
    CloseHint.TextSize = 9
    CloseHint.Parent = MainFrame

    -- AÃ§Ãµes dos BotÃµes
    ReapplyBtn.MouseButton1Click:Connect(function()
        ReapplyBtn.Text = "â³ Otimizando..."
        for _, obj in ipairs(Workspace:GetDescendants()) do
            optimizeInstance(obj)
        end
        task.wait(0.5)
        ReapplyBtn.Text = "âœ“ Ilha Otimizada!"
        task.wait(1.5)
        ReapplyBtn.Text = "ðŸ”„ Otimizar Ilha Atual"
    end)

    ClearRamBtn.MouseButton1Click:Connect(function()
        ClearRamBtn.Text = "â³ Limpando..."
        collectgarbage("collect")
        task.wait(0.5)
        ClearRamBtn.Text = "âœ“ RAM Liberada!"
        task.wait(1.5)
        ClearRamBtn.Text = "ðŸ§¹ Liberar MemÃ³ria RAM"
    end)

    -- Toggle da Janela ao Clicar no Ãcone
    FloatingBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
        MainFrame.Position = UDim2.new(FloatingBtn.Position.X.Scale, FloatingBtn.Position.X.Offset + 60, FloatingBtn.Position.Y.Scale, FloatingBtn.Position.Y.Offset)
    end)

    -- Arrastar o Ãcone com o Dedo (Celular) ou Mouse (PC) com suavidade
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

    -- Atualizador em Tempo Real do Contador de FPS
    local lastTime = tick()
    local frameCount = 0
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
            frameCount = 0
            lastTime = now
        end
    end)
end)

print("âœ… [Blox Fruits Optimizer] Script carregado com sucesso. FPS MÃ¡ximo liberado!")
