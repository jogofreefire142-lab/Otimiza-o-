--[[
    LUX DOG • FARM LEVEL + UI 2026
    Formato: TXT com código Luau

    USO:
    - Roblox Studio / jogo próprio.
    - Coloque este código em um LocalScript dentro de StarterPlayerScripts.
    - A interface é criada automaticamente ao executar.

    IMPORTANTE:
    - O código usa apenas APIs normais do Roblox.
    - O Farm é um framework para jogo próprio.
    - Configure a estrutura Workspace.Quests e Workspace.Enemies
      conforme explicado no fim do arquivo.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

--========================================================--
-- CONFIGURAÇÃO
--========================================================--

local CONFIG = {
    NormalCap = 2800,
    SecretCap = 3000,

    MoveReachedDistance = 8,
    TargetDistance = 25,

    RetryDelay = 0.35,
    CharacterWait = 0.25,
    AttackInterval = 0.20,
}

--========================================================--
-- FARM CONTROLLER
--========================================================--

local Farm = {
    Running = false,
    State = "Idle",

    Level = 0,
    Quest = nil,
    Target = nil,

    Status = "Farm parado.",
    Error = nil,

    Thread = nil,
    Connections = {},
}

local function setState(state)
    Farm.State = state
end

local function setStatus(status)
    Farm.Status = tostring(status or "")
end

local function getCharacter()
    local character = LocalPlayer.Character
    if not character then
        return nil, nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    return character, humanoid, root
end

local function getLevel()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if not leaderstats then
        return 0
    end

    local levelValue =
        leaderstats:FindFirstChild("Level")
        or leaderstats:FindFirstChild("level")
        or leaderstats:FindFirstChild("Lvl")

    if not levelValue then
        return 0
    end

    return tonumber(levelValue.Value) or 0
end

local function validCharacter()
    local _, humanoid, root = getCharacter()

    return humanoid ~= nil
        and root ~= nil
        and humanoid.Health > 0
end

local function moveTo(position, reachedDistance)
    reachedDistance = reachedDistance or CONFIG.MoveReachedDistance

    if typeof(position) ~= "Vector3" then
        return false
    end

    local _, humanoid, root = getCharacter()

    if not humanoid or not root or humanoid.Health <= 0 then
        return false
    end

    humanoid:MoveTo(position)

    local startTime = os.clock()

    while Farm.Running do
        local _, currentHumanoid, currentRoot = getCharacter()

        if not currentHumanoid or not currentRoot then
            return false
        end

        if currentHumanoid.Health <= 0 then
            return false
        end

        if (currentRoot.Position - position).Magnitude <= reachedDistance then
            return true
        end

        if os.clock() - startTime > 30 then
            return false
        end

        currentHumanoid:MoveTo(position)
        task.wait(0.10)
    end

    return false
end

--========================================================--
-- DADOS DE QUEST
--========================================================--

-- Esperado:
--
-- Workspace
-- └── Quests
--     ├── Quest01
--     │   ├── QuestPosition (Part)
--     │   └── TargetPosition (Part)
--     │   [Attributes: MinLevel, MaxLevel, TargetName]
--
-- Uma Quest pode usar:
-- MinLevel = 1
-- MaxLevel = 20
-- TargetName = "Bandit"

local function findQuestForLevel(level)
    local questsFolder = workspace:FindFirstChild("Quests")

    if not questsFolder then
        return nil
    end

    local chosen = nil

    for _, quest in ipairs(questsFolder:GetChildren()) do
        local minLevel = tonumber(quest:GetAttribute("MinLevel")) or 0
        local maxLevel = tonumber(quest:GetAttribute("MaxLevel")) or math.huge

        if level >= minLevel and level <= maxLevel then
            local questPosition = quest:FindFirstChild("QuestPosition")
            local targetPosition = quest:FindFirstChild("TargetPosition")

            if questPosition or targetPosition then
                chosen = {
                    Instance = quest,
                    Id = quest.Name,
                    Name = quest:GetAttribute("DisplayName") or quest.Name,
                    MinLevel = minLevel,
                    MaxLevel = maxLevel,
                    TargetName = quest:GetAttribute("TargetName"),
                    QuestPosition = questPosition and questPosition.Position or nil,
                    TargetPosition = targetPosition and targetPosition.Position or nil,
                }

                break
            end
        end
    end

    return chosen
end

local function findTarget(quest)
    local enemiesFolder = workspace:FindFirstChild("Enemies")

    if not enemiesFolder then
        return nil
    end

    local _, _, playerRoot = getCharacter()
    if not playerRoot then
        return nil
    end

    local nearest = nil
    local nearestDistance = math.huge

    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        local humanoid = enemy:FindFirstChildOfClass("Humanoid")
        local root =
            enemy:FindFirstChild("HumanoidRootPart")
            or enemy.PrimaryPart

        if humanoid and root and humanoid.Health > 0 then
            if not quest.TargetName or enemy.Name == quest.TargetName then
                local distance = (playerRoot.Position - root.Position).Magnitude

                if distance < nearestDistance then
                    nearestDistance = distance
                    nearest = enemy
                end
            end
        end
    end

    return nearest
end

local function targetAlive(target)
    if not target or not target.Parent then
        return false
    end

    local humanoid = target:FindFirstChildOfClass("Humanoid")

    return humanoid ~= nil and humanoid.Health > 0
end

--========================================================--
-- PONTOS DE INTEGRAÇÃO DO JOGO
--========================================================--

local function startQuest(quest)
    -- Integre aqui o sistema de missão do seu próprio jogo.
    --
    -- Exemplo legítimo:
    -- local remote = ReplicatedStorage.Remotes.StartQuest
    -- remote:FireServer(quest.Id)
    --
    -- Não inventamos RemoteEvents porque cada jogo possui
    -- uma arquitetura diferente.

    if quest and quest.Instance then
        quest.Instance:SetAttribute("ActiveForPlayer", true)
    end

    return true
end

local function questComplete(quest)
    if not quest or not quest.Instance then
        return false
    end

    return quest.Instance:GetAttribute("Completed") == true
end

local function attackTarget(target, quest)
    -- Integre aqui o sistema de combate do seu próprio jogo.
    --
    -- Exemplo:
    -- ReplicatedStorage.Remotes.Attack:FireServer(target)
    --
    -- Sem o sistema real do jogo, mantemos a função neutra.

    if not targetAlive(target) then
        return false
    end

    return true
end

local function turnInQuest(quest)
    -- Integre aqui o sistema de entrega da missão do seu jogo.
    return true
end

--========================================================--
-- CICLO DO FARM
--========================================================--

local function runFarm()
    while Farm.Running do

        -- Personagem
        if not validCharacter() then
            setState("WaitingForCharacter")
            setStatus("Aguardando personagem...")
            task.wait(CONFIG.CharacterWait)
            continue
        end

        -- Nível
        setState("ReadingLevel")
        Farm.Level = getLevel()

        if Farm.Level <= 0 then
            setStatus("Aguardando nível...")
            task.wait(CONFIG.RetryDelay)
            continue
        end

        -- Limites
        if Farm.Level >= CONFIG.SecretCap then
            setState("Complete")
            setStatus("Progressão concluída no nível " .. tostring(Farm.Level) .. ".")
            break
        end

        if Farm.Level >= CONFIG.NormalCap then
            setState("SecretLevels")
            setStatus("Aguardando progressão dos níveis secretos...")
            task.wait(0.75)
            continue
        end

        -- Quest
        if not Farm.Quest then
            setState("ResolvingQuest")
            setStatus("Procurando missão para nível " .. tostring(Farm.Level) .. "...")

            Farm.Quest = findQuestForLevel(Farm.Level)

            if not Farm.Quest then
                setStatus("Nenhuma missão configurada para este nível.")
                task.wait(1)
                continue
            end

            startQuest(Farm.Quest)
        end

        -- Ir para NPC/posição da missão
        if Farm.Quest.QuestPosition then
            setState("GoingToQuest")
            setStatus("Indo para: " .. tostring(Farm.Quest.Name))

            if not moveTo(Farm.Quest.QuestPosition) then
                task.wait(CONFIG.RetryDelay)
                continue
            end
        end

        setState("QuestReady")

        -- Procurar alvo
        Farm.Target = findTarget(Farm.Quest)

        if not Farm.Target then
            setState("WaitingForTarget")
            setStatus("Aguardando alvo...")
            task.wait(CONFIG.RetryDelay)
            continue
        end

        -- Ir para alvo
        local targetRoot =
            Farm.Target:FindFirstChild("HumanoidRootPart")
            or Farm.Target.PrimaryPart

        if targetRoot then
            setState("GoingToTarget")
            setStatus("Indo até: " .. tostring(Farm.Target.Name))

            if not moveTo(targetRoot.Position) then
                Farm.Target = nil
                task.wait(CONFIG.RetryDelay)
                continue
            end
        end

        -- Combate
        setState("Fighting")
        setStatus("Combatendo: " .. tostring(Farm.Target.Name))

        while Farm.Running and targetAlive(Farm.Target) do
            if questComplete(Farm.Quest) then
                break
            end

            local _, humanoid, root = getCharacter()

            if not humanoid or not root or humanoid.Health <= 0 then
                break
            end

            local enemyRoot =
                Farm.Target:FindFirstChild("HumanoidRootPart")
                or Farm.Target.PrimaryPart

            if enemyRoot then
                local distance = (root.Position - enemyRoot.Position).Magnitude

                if distance > CONFIG.TargetDistance then
                    humanoid:MoveTo(enemyRoot.Position)
                end
            end

            attackTarget(Farm.Target, Farm.Quest)
            task.wait(CONFIG.AttackInterval)
        end

        -- Entrega
        if Farm.Running and Farm.Quest and questComplete(Farm.Quest) then
            setState("TurningIn")
            setStatus("Entregando missão...")

            turnInQuest(Farm.Quest)
        end

        Farm.Target = nil
        Farm.Quest = nil

        task.wait(CONFIG.RetryDelay)
    end

    if Farm.State ~= "Complete" then
        setState("Idle")
        setStatus("Farm parado.")
    end
end

local function startFarm()
    if Farm.Running then
        return
    end

    Farm.Running = true
    Farm.Error = nil
    setState("Starting")
    setStatus("Iniciando Farm Level...")

    Farm.Thread = task.spawn(function()
        local ok, err = pcall(runFarm)

        if not ok then
            Farm.Error = tostring(err)
            Farm.Running = false
            setState("Error")
            setStatus("Erro: " .. Farm.Error)
        end
    end)
end

local function stopFarm()
    Farm.Running = false
    Farm.Thread = nil

    Farm.Quest = nil
    Farm.Target = nil

    local _, humanoid, root = getCharacter()

    if humanoid and root and humanoid.Health > 0 then
        humanoid:MoveTo(root.Position)
    end

    setState("Idle")
    setStatus("Farm parado.")
end

--========================================================--
-- UI
--========================================================--

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local oldGui = PlayerGui:FindFirstChild("LuxDogFarmUI")
if oldGui then
    oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LuxDogFarmUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

local function make(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    object.Parent = parent
    return object
end

local shadow = make("Frame", {
    Name = "Shadow",
    Size = UDim2.fromOffset(540, 360),
    Position = UDim2.new(0.5, -270, 0.5, -180),
    BackgroundTransparency = 0.65,
    BorderSizePixel = 0,
}, screenGui)

make("UICorner", {
    CornerRadius = UDim.new(0, 14)
}, shadow)

local main = make("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(520, 340),
    Position = UDim2.new(0.5, -260, 0.5, -170),
    BackgroundColor3 = Color3.fromRGB(20, 20, 24),
    BorderSizePixel = 0,
}, screenGui)

make("UICorner", {
    CornerRadius = UDim.new(0, 14)
}, main)

make("UIStroke", {
    Thickness = 1,
    Transparency = 0.35,
    Color = Color3.fromRGB(70, 70, 80)
}, main)

local topBar = make("Frame", {
    Size = UDim2.new(1, 0, 0, 50),
    BackgroundColor3 = Color3.fromRGB(27, 27, 33),
    BorderSizePixel = 0,
}, main)

make("UICorner", {
    CornerRadius = UDim.new(0, 14)
}, topBar)

make("Frame", {
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.new(0, 0, 1, -14),
    BackgroundColor3 = Color3.fromRGB(27, 27, 33),
    BorderSizePixel = 0,
}, topBar)

make("TextLabel", {
    Size = UDim2.fromOffset(180, 50),
    Position = UDim2.fromOffset(18, 0),
    BackgroundTransparency = 1,
    Text = "LUX DOG",
    Font = Enum.Font.GothamBold,
    TextSize = 19,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(240, 240, 245),
}, topBar)

local closeButton = make("TextButton", {
    Size = UDim2.fromOffset(36, 32),
    Position = UDim2.new(1, -46, 0, 9),
    BackgroundColor3 = Color3.fromRGB(38, 38, 46),
    BorderSizePixel = 0,
    Text = "×",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(235, 235, 240),
    AutoButtonColor = false,
}, topBar)

make("UICorner", {
    CornerRadius = UDim.new(0, 9)
}, closeButton)

local sidebar = make("Frame", {
    Size = UDim2.new(0, 135, 1, -62),
    Position = UDim2.fromOffset(10, 56),
    BackgroundColor3 = Color3.fromRGB(25, 25, 30),
    BorderSizePixel = 0,
}, main)

make("UICorner", {
    CornerRadius = UDim.new(0, 11)
}, sidebar)

local content = make("Frame", {
    Size = UDim2.new(1, -155, 1, -62),
    Position = UDim2.fromOffset(145, 56),
    BackgroundTransparency = 1,
}, main)

local tabFarm = make("TextButton", {
    Size = UDim2.new(1, -16, 0, 44),
    Position = UDim2.fromOffset(8, 12),
    BackgroundColor3 = Color3.fromRGB(55, 55, 67),
    BorderSizePixel = 0,
    Text = "  Farming",
    Font = Enum.Font.GothamSemibold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(245, 245, 250),
    AutoButtonColor = false,
}, sidebar)

make("UICorner", {
    CornerRadius = UDim.new(0, 9)
}, tabFarm)

local tabSettings = make("TextButton", {
    Size = UDim2.new(1, -16, 0, 44),
    Position = UDim2.fromOffset(8, 64),
    BackgroundColor3 = Color3.fromRGB(34, 34, 41),
    BorderSizePixel = 0,
    Text = "  Settings",
    Font = Enum.Font.GothamSemibold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(200, 200, 208),
    AutoButtonColor = false,
}, sidebar)

make("UICorner", {
    CornerRadius = UDim.new(0, 9)
}, tabSettings)

local farmPage = make("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
}, content)

local settingsPage = make("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Visible = false,
}, content)

make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundTransparency = 1,
    Text = "Farming",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(240, 240, 245),
}, farmPage)

local statusLabel = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 46),
    Position = UDim2.fromOffset(0, 38),
    BackgroundColor3 = Color3.fromRGB(27, 27, 33),
    BorderSizePixel = 0,
    Text = "Status: Farm parado.",
    Font = Enum.Font.Gotham,
    TextSize = 13,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(215, 215, 222),
}, farmPage)

make("UICorner", {
    CornerRadius = UDim.new(0, 9)
}, statusLabel)

local levelLabel = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.fromOffset(0, 94),
    BackgroundTransparency = 1,
    Text = "Nível: 0",
    Font = Enum.Font.GothamMedium,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(215, 215, 222),
}, farmPage)

local questLabel = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.fromOffset(0, 122),
    BackgroundTransparency = 1,
    Text = "Missão: —",
    Font = Enum.Font.GothamMedium,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(215, 215, 222),
}, farmPage)

local targetLabel = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.fromOffset(0, 150),
    BackgroundTransparency = 1,
    Text = "Alvo: —",
    Font = Enum.Font.GothamMedium,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(215, 215, 222),
}, farmPage)

local stateLabel = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.fromOffset(0, 178),
    BackgroundTransparency = 1,
    Text = "Estado: Idle",
    Font = Enum.Font.GothamMedium,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(215, 215, 222),
}, farmPage)

local farmButton = make("TextButton", {
    Size = UDim2.new(1, 0, 0, 50),
    Position = UDim2.new(0, 0, 1, -50),
    BackgroundColor3 = Color3.fromRGB(47, 47, 58),
    BorderSizePixel = 0,
    Text = "FARM LEVEL  •  OFF",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(240, 240, 245),
    AutoButtonColor = false,
}, farmPage)

make("UICorner", {
    CornerRadius = UDim.new(0, 10)
}, farmButton)

make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundTransparency = 1,
    Text = "Settings",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(240, 240, 245),
}, settingsPage)

make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 52),
    Position = UDim2.fromOffset(0, 45),
    BackgroundColor3 = Color3.fromRGB(27, 27, 33),
    BorderSizePixel = 0,
    Text = "Farm Level\nLimite normal: 2800\nLimite secreto: 3000",
    Font = Enum.Font.Gotham,
    TextSize = 13,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(215, 215, 222),
}, settingsPage)

local openButton = make("TextButton", {
    Size = UDim2.fromOffset(48, 48),
    Position = UDim2.fromOffset(18, 180),
    BackgroundColor3 = Color3.fromRGB(27, 27, 33),
    BorderSizePixel = 0,
    Text = "LD",
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextColor3 = Color3.fromRGB(240, 240, 245),
    Visible = false,
    AutoButtonColor = false,
}, screenGui)

make("UICorner", {
    CornerRadius = UDim.new(1, 0)
}, openButton)

--========================================================--
-- UI ATUALIZAÇÃO
--========================================================--

local function updateUI()
    levelLabel.Text = "Nível: " .. tostring(Farm.Level)

    local questName = "—"
    if Farm.Quest then
        questName = tostring(Farm.Quest.Name or Farm.Quest.Id or "—")
    end

    local targetName = "—"
    if Farm.Target then
        targetName = tostring(Farm.Target.Name or "—")
    end

    questLabel.Text = "Missão: " .. questName
    targetLabel.Text = "Alvo: " .. targetName
    stateLabel.Text = "Estado: " .. tostring(Farm.State)
    statusLabel.Text = "Status: " .. tostring(Farm.Status)

    if Farm.Running then
        farmButton.Text = "FARM LEVEL  •  ON"
        farmButton.BackgroundColor3 = Color3.fromRGB(57, 70, 57)
    else
        farmButton.Text = "FARM LEVEL  •  OFF"
        farmButton.BackgroundColor3 = Color3.fromRGB(47, 47, 58)
    end
end

task.spawn(function()
    while screenGui.Parent do
        Farm.Level = getLevel()
        updateUI()
        task.wait(0.15)
    end
end)

--========================================================--
-- BOTÕES
--========================================================--

farmButton.MouseButton1Click:Connect(function()
    if Farm.Running then
        stopFarm()
    else
        startFarm()
    end

    updateUI()
end)

tabFarm.MouseButton1Click:Connect(function()
    farmPage.Visible = true
    settingsPage.Visible = false

    tabFarm.BackgroundColor3 = Color3.fromRGB(55, 55, 67)
    tabSettings.BackgroundColor3 = Color3.fromRGB(34, 34, 41)
end)

tabSettings.MouseButton1Click:Connect(function()
    farmPage.Visible = false
    settingsPage.Visible = true

    tabFarm.BackgroundColor3 = Color3.fromRGB(34, 34, 41)
    tabSettings.BackgroundColor3 = Color3.fromRGB(55, 55, 67)
end)

local function hideUI()
    main.Visible = false
    shadow.Visible = false
    openButton.Visible = true
end

local function showUI()
    main.Visible = true
    shadow.Visible = true
    openButton.Visible = false
end

closeButton.MouseButton1Click:Connect(hideUI)
openButton.MouseButton1Click:Connect(showUI)

--========================================================--
-- ARRASTAR JANELA
--========================================================--

local dragging = false
local dragStart
local startPosition

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)

topBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - dragStart

    main.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )

    shadow.Position = UDim2.new(
        main.Position.X.Scale,
        main.Position.X.Offset + 10,
        main.Position.Y.Scale,
        main.Position.Y.Offset + 10
    )
end)

--========================================================--
-- RESPAWN / LIMPEZA
--========================================================--

table.insert(Farm.Connections, LocalPlayer.CharacterAdded:Connect(function()
    Farm.Target = nil
    Farm.Quest = nil

    if Farm.Running then
        setState("WaitingForCharacter")
        setStatus("Personagem reaparecendo...")
    end
end))

table.insert(Farm.Connections, LocalPlayer.CharacterRemoving:Connect(function()
    Farm.Target = nil
end))

-- Fechamento limpo quando o GUI for destruído.
screenGui.Destroying:Connect(function()
    Farm.Running = false

    for _, connection in ipairs(Farm.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    Farm.Connections = {}
end)

updateUI()

--========================================================--
-- FIM
--========================================================--

-- ESTRUTURA MÍNIMA PARA TESTAR O FARM:
--
-- Workspace
-- ├── Quests
-- │   └── Quest01
-- │       ├── QuestPosition (Part)
-- │       └── TargetPosition (Part)
-- │       [Attributes]
-- │           MinLevel = 1
-- │           MaxLevel = 20
-- │           TargetName = "Bandit"
-- │           DisplayName = "Bandit Quest"
-- │
-- └── Enemies
--     └── Bandit
--         ├── Humanoid
--         └── HumanoidRootPart
--
-- Para indicar que uma quest terminou no exemplo:
-- Quest01:SetAttribute("Completed", true)
--
-- O sistema de combate real deve ser conectado na função
-- attackTarget(), usando as APIs do seu próprio jogo.
