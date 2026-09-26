--[[
=====================================================================
RIP_LODER 2026
Projeto organizado • Luau • Roblox Studio / jogo próprio

BASE:
- Estrutura inspirada no arquivo original fornecido.
- Interface organizada em abas.
- Farm Level com máquina de estados.
- Progressão normal até 2800.
- Suporte a Secret Levels até 3000.
- Movimento legítimo usando Humanoid:MoveTo + PathfindingService.
- Recuperação de personagem / respawn.
- Seleção de missão por nível.
- Seleção de alvo.
- Status em tempo real.
- Configuração centralizada.
- Limpeza de conexões e loops.
- Discord atualizado:
  https://discord.gg/BjmaR2NEA

NÃO INCLUI:
- APIs de executor.
- loadstring/HttpGet para biblioteca externa.
- getgenv/getrawmetatable/newcclosure.
- VirtualInputManager/VirtualUser.
- Teleporte forçado.
- Bring Mobs por alteração de física/rede.
- Bypass de sistemas do jogo.

IMPORTANTE:
Este arquivo foi estruturado para Roblox Studio e para experiências
que você controla. Os callbacks de missão e combate ficam separados
para que o projeto forneça suas próprias regras e RemoteEvents.
=====================================================================
]]

--==============================================================--
-- SERVICES
--==============================================================--

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==============================================================--
-- METADADOS
--==============================================================--

local APP = {
    Name = "Rip_loder",
    Version = "2026.1",
    Discord = "https://discord.gg/BjmaR2NEA",

    NormalCap = 2800,
    MaximumCap = 3000,

    MoveReachedDistance = 7,
    TargetDistance = 24,

    MoveTimeout = 10,
    RetryDelay = 0.35,
    RespawnDelay = 0.75,
    QuestCheckDelay = 0.25,
    AttackInterval = 0.20,
}

--==============================================================--
-- ESTADOS
--==============================================================--

local STATE = {
    IDLE = "Idle",
    STARTING = "Starting",
    READING_LEVEL = "ReadingLevel",
    FINDING_QUEST = "FindingQuest",
    GOING_TO_QUEST = "GoingToQuest",
    STARTING_QUEST = "StartingQuest",
    FINDING_TARGET = "FindingTarget",
    GOING_TO_TARGET = "GoingToTarget",
    FIGHTING = "Fighting",
    TURNING_IN = "TurningIn",
    SECRET_LEVELS = "SecretLevels",
    WAITING_CHARACTER = "WaitingForCharacter",
    WAITING_TARGET = "WaitingForTarget",
    RECOVERING = "Recovering",
    COMPLETE = "Complete",
    ERROR = "Error",
}

--==============================================================--
-- FARM
--==============================================================--

local Farm = {
    Running = false,
    State = STATE.IDLE,

    Level = 0,
    Quest = nil,
    Target = nil,

    QuestProgress = 0,
    QuestRequired = 0,

    Status = "Pronto.",
    Error = nil,

    Thread = nil,

    Connections = {},
}

--==============================================================--
-- CALLBACKS
--==============================================================--

-- Configure estes callbacks para o seu próprio jogo.
local Providers = {
    -- Retorno esperado:
    --
    -- {
    --     Id = "Quest01",
    --     Name = "Quest 01",
    --     MinLevel = 1,
    --     MaxLevel = 20,
    --     QuestPosition = Vector3,
    --     TargetName = "Bandit",
    --     TargetPosition = Vector3,
    --     TurnInPosition = Vector3,
    -- }
    QuestProvider = nil,

    -- Deve retornar um Model/Instance de inimigo válido.
    TargetProvider = nil,

    -- Retorna true quando a missão estiver concluída.
    QuestCompleteProvider = nil,

    -- Inicia a missão do jogo.
    StartQuestProvider = nil,

    -- Executa o ataque do sistema de combate do jogo próprio.
    AttackProvider = nil,

    -- Entrega a missão.
    TurnInProvider = nil,

    -- Secret Levels:
    -- recebe o nível atual e retorna uma descrição do próximo objetivo
    -- ou nil quando nenhum objetivo secreto estiver disponível.
    SecretProvider = nil,
}

--==============================================================--
-- HELPERS
--==============================================================--

local function safeCall(callback, ...)
    if typeof(callback) ~= "function" then
        return false, nil, "callback não configurado"
    end

    local ok, result = pcall(callback, ...)
    if not ok then
        return false, nil, tostring(result)
    end

    return true, result, nil
end

local function setState(state)
    Farm.State = state
end

local function setStatus(text)
    Farm.Status = tostring(text or "")
end

local function clearError()
    Farm.Error = nil
end

local function setError(message)
    Farm.Error = tostring(message or "Erro desconhecido.")
    Farm.Running = false
    setState(STATE.ERROR)
    setStatus("Erro: " .. Farm.Error)
end

local function isAliveHumanoid(humanoid)
    return humanoid
        and humanoid:IsA("Humanoid")
        and humanoid.Health > 0
end

--==============================================================--
-- CHARACTER
--==============================================================--

local function getCharacter()
    local character = LocalPlayer.Character
    if not character then
        return nil, nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    return character, humanoid, root
end

local function characterReady()
    local _, humanoid, root = getCharacter()

    return root ~= nil and isAliveHumanoid(humanoid)
end

local function waitForCharacter()
    while Farm.Running do
        if characterReady() then
            return true
        end

        setState(STATE.WAITING_CHARACTER)
        setStatus("Aguardando personagem...")

        task.wait(APP.RespawnDelay)
    end

    return false
end

--==============================================================--
-- LEVEL
--==============================================================--

local function getLevel()
    -- Compatibilidade com estruturas comuns em jogos próprios.
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")

    if leaderstats then
        local value =
            leaderstats:FindFirstChild("Level")
            or leaderstats:FindFirstChild("level")
            or leaderstats:FindFirstChild("Lvl")

        if value and tonumber(value.Value) then
            return tonumber(value.Value)
        end
    end

    local data = LocalPlayer:FindFirstChild("Data")

    if data then
        local value =
            data:FindFirstChild("Level")
            or data:FindFirstChild("level")
            or data:FindFirstChild("Lvl")

        if value and tonumber(value.Value) then
            return tonumber(value.Value)
        end
    end

    return 0
end

local function refreshLevel()
    Farm.Level = getLevel()
    return Farm.Level
end

local function isNormalComplete(level)
    return level >= APP.NormalCap and level < APP.MaximumCap
end

local function isFullyComplete(level)
    return level >= APP.MaximumCap
end

--==============================================================--
-- QUEST
--==============================================================--

local function validateQuest(quest)
    if typeof(quest) ~= "table" then
        return false, "Quest inválida."
    end

    if quest.QuestPosition and typeof(quest.QuestPosition) ~= "Vector3" then
        return false, "QuestPosition precisa ser Vector3."
    end

    if not quest.TargetName and not quest.TargetPosition then
        return false, "A missão precisa de TargetName ou TargetPosition."
    end

    return true
end

local function findQuest()
    local level = Farm.Level

    if typeof(Providers.QuestProvider) == "function" then
        local ok, quest, err = safeCall(
            Providers.QuestProvider,
            level,
            Farm
        )

        if not ok then
            return nil, err
        end

        local valid, validationError = validateQuest(quest)

        if not valid then
            return nil, validationError
        end

        return quest
    end

    -- Fallback genérico: Workspace.Quests com Attributes.
    local folder = workspace:FindFirstChild("Quests")

    if not folder then
        return nil, "Workspace.Quests não encontrada."
    end

    local candidates = {}

    for _, questInstance in ipairs(folder:GetChildren()) do
        local minLevel = tonumber(questInstance:GetAttribute("MinLevel"))
        local maxLevel = tonumber(questInstance:GetAttribute("MaxLevel"))

        local questPositionPart = questInstance:FindFirstChild("QuestPosition")
        local targetPositionPart = questInstance:FindFirstChild("TargetPosition")

        if minLevel and maxLevel
            and level >= minLevel
            and level <= maxLevel then

            local candidate = {
                Id = questInstance.Name,
                Name = questInstance:GetAttribute("DisplayName") or questInstance.Name,
                MinLevel = minLevel,
                MaxLevel = maxLevel,

                TargetName = questInstance:GetAttribute("TargetName"),

                QuestPosition =
                    questPositionPart and questPositionPart:IsA("BasePart")
                    and questPositionPart.Position
                    or nil,

                TargetPosition =
                    targetPositionPart and targetPositionPart:IsA("BasePart")
                    and targetPositionPart.Position
                    or nil,

                Instance = questInstance,
            }

            local valid = validateQuest(candidate)

            if valid then
                table.insert(candidates, candidate)
            end
        end
    end

    table.sort(candidates, function(a, b)
        return a.MinLevel < b.MinLevel
    end)

    return candidates[1], candidates[1] and nil
        or "Nenhuma missão configurada para este nível."
end

local function startQuest(quest)
    if typeof(Providers.StartQuestProvider) == "function" then
        local ok, result, err = safeCall(
            Providers.StartQuestProvider,
            quest,
            Farm
        )

        if not ok then
            return false, err
        end

        return result ~= false, nil
    end

    -- Fallback genérico para jogo próprio.
    if quest and quest.Instance then
        quest.Instance:SetAttribute("Active", true)
        return true
    end

    return false, "StartQuestProvider não configurado."
end

local function questComplete(quest)
    if typeof(Providers.QuestCompleteProvider) == "function" then
        local ok, result = safeCall(
            Providers.QuestCompleteProvider,
            quest,
            Farm
        )

        return ok and result == true
    end

    if quest and quest.Instance then
        return quest.Instance:GetAttribute("Completed") == true
    end

    return false
end

--==============================================================--
-- TARGET
--==============================================================--

local function getTargetRoot(target)
    if not target then
        return nil
    end

    return target:FindFirstChild("HumanoidRootPart")
        or target.PrimaryPart
end

local function isValidTarget(target)
    if not target then
        return false
    end

    if typeof(target) ~= "Instance" then
        return false
    end

    if not target.Parent then
        return false
    end

    local humanoid = target:FindFirstChildOfClass("Humanoid")

    return isAliveHumanoid(humanoid)
        and getTargetRoot(target) ~= nil
end

local function findTarget()
    local quest = Farm.Quest

    if typeof(Providers.TargetProvider) == "function" then
        local ok, target, err = safeCall(
            Providers.TargetProvider,
            quest,
            Farm
        )

        if not ok then
            return nil, err
        end

        if isValidTarget(target) then
            return target
        end

        return nil
    end

    -- Fallback genérico: Workspace.Enemies.
    local enemies = workspace:FindFirstChild("Enemies")

    if not enemies then
        return nil, "Workspace.Enemies não encontrada."
    end

    local _, _, playerRoot = getCharacter()

    if not playerRoot then
        return nil
    end

    local best
    local bestDistance = math.huge

    for _, enemy in ipairs(enemies:GetChildren()) do
        if quest and quest.TargetName then
            if enemy.Name ~= quest.TargetName then
                continue
            end
        end

        if isValidTarget(enemy) then
            local root = getTargetRoot(enemy)
            local distance = (root.Position - playerRoot.Position).Magnitude

            if distance < bestDistance then
                bestDistance = distance
                best = enemy
            end
        end
    end

    return best
end

--==============================================================--
-- PATHFINDING / MOVEMENT
--==============================================================--

local function moveDirect(humanoid, destination, timeout)
    timeout = timeout or APP.MoveTimeout

    if not humanoid or typeof(destination) ~= "Vector3" then
        return false, "Destino inválido."
    end

    local start = os.clock()

    humanoid:MoveTo(destination)

    while Farm.Running do
        local _, currentHumanoid, root = getCharacter()

        if not currentHumanoid or not root or currentHumanoid.Health <= 0 then
            return false, "Personagem indisponível."
        end

        if (root.Position - destination).Magnitude <= APP.MoveReachedDistance then
            return true
        end

        if os.clock() - start >= timeout then
            return false, "Tempo de movimento excedido."
        end

        -- MoveTo tem um timeout interno; repetir o comando evita
        -- perder o destino em trajetos mais longos.
        currentHumanoid:MoveTo(destination)

        task.wait(0.15)
    end

    return false, "Farm interrompido."
end

local function movePathfinding(destination)
    if typeof(destination) ~= "Vector3" then
        return false, "Destino inválido."
    end

    local _, humanoid, root = getCharacter()

    if not humanoid or not root or humanoid.Health <= 0 then
        return false, "Personagem indisponível."
    end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentCanClimb = true,
        WaypointSpacing = 4,
    })

    local ok, computeError = pcall(function()
        path:ComputeAsync(root.Position, destination)
    end)

    if not ok then
        return moveDirect(humanoid, destination)
    end

    if path.Status ~= Enum.PathStatus.Success then
        return moveDirect(humanoid, destination)
    end

    local waypoints = path:GetWaypoints()

    if #waypoints == 0 then
        return moveDirect(humanoid, destination)
    end

    for index, waypoint in ipairs(waypoints) do
        if not Farm.Running then
            return false, "Farm interrompido."
        end

        local _, currentHumanoid, currentRoot = getCharacter()

        if not currentHumanoid or not currentRoot then
            return false, "Personagem indisponível."
        end

        if currentHumanoid.Health <= 0 then
            return false, "Personagem derrotado."
        end

        if waypoint.Action == Enum.PathWaypointAction.Jump then
            currentHumanoid.Jump = true
        end

        local reached, errorMessage = moveDirect(
            currentHumanoid,
            waypoint.Position,
            APP.MoveTimeout
        )

        if not reached then
            -- Uma nova tentativa pelo caminho direto é mais simples
            -- do que travar o ciclo inteiro.
            if index == #waypoints then
                return false, errorMessage
            end

            local directReached = moveDirect(
                currentHumanoid,
                destination,
                APP.MoveTimeout
            )

            if directReached then
                return true
            end
        end
    end

    return true
end

--==============================================================--
-- COMBAT PROVIDER
--==============================================================--

local function attackTarget(target)
    if not isValidTarget(target) then
        return false, "Alvo inválido."
    end

    if typeof(Providers.AttackProvider) ~= "function" then
        return false, "AttackProvider não configurado."
    end

    local ok, result, err = safeCall(
        Providers.AttackProvider,
        target,
        Farm.Quest,
        Farm
    )

    if not ok then
        return false, err
    end

    return result ~= false, nil
end

--==============================================================--
-- TURN-IN
--==============================================================--

local function turnInQuest(quest)
    if typeof(Providers.TurnInProvider) == "function" then
        local ok, result, err = safeCall(
            Providers.TurnInProvider,
            quest,
            Farm
        )

        if not ok then
            return false, err
        end

        return result ~= false, nil
    end

    return true
end

--==============================================================--
-- SECRET LEVELS
--==============================================================--

local function getSecretObjective()
    if Farm.Level < APP.NormalCap then
        return nil
    end

    if Farm.Level >= APP.MaximumCap then
        return nil
    end

    if typeof(Providers.SecretProvider) ~= "function" then
        return nil
    end

    local ok, result, err = safeCall(
        Providers.SecretProvider,
        Farm.Level,
        Farm
    )

    if not ok then
        return nil, err
    end

    return result
end

--==============================================================--
-- QUEST CYCLE
--==============================================================--

local function resetQuest()
    Farm.Quest = nil
    Farm.Target = nil
    Farm.QuestProgress = 0
    Farm.QuestRequired = 0
end

local function runQuestCycle()
    if not Farm.Quest then
        return
    end

    local quest = Farm.Quest

    -- Quest NPC
    if quest.QuestPosition then
        setState(STATE.GOING_TO_QUEST)
        setStatus("Indo para missão: " .. tostring(quest.Name))

        local reached, errorMessage = movePathfinding(quest.QuestPosition)

        if not reached then
            setStatus("Recalculando caminho...")
            task.wait(APP.RetryDelay)
            return
        end
    end

    -- Start Quest
    setState(STATE.STARTING_QUEST)
    setStatus("Iniciando missão: " .. tostring(quest.Name))

    local started, startError = startQuest(quest)

    if not started then
        setStatus("Não foi possível iniciar a missão: " .. tostring(startError))
        task.wait(APP.RetryDelay)
        return
    end

    -- Target loop
    while Farm.Running and Farm.Quest == quest do
        if questComplete(quest) then
            break
        end

        setState(STATE.FINDING_TARGET)
        setStatus("Procurando alvo...")

        local target, targetError = findTarget()

        if targetError then
            setStatus("Alvo: " .. tostring(targetError))
        end

        if not target then
            Farm.Target = nil
            setState(STATE.WAITING_TARGET)
            setStatus("Aguardando alvo...")
            task.wait(APP.RetryDelay)
            continue
        end

        Farm.Target = target

        local targetRoot = getTargetRoot(target)

        if targetRoot then
            setState(STATE.GOING_TO_TARGET)
            setStatus("Indo até: " .. tostring(target.Name))

            local reached = movePathfinding(targetRoot.Position)

            if not reached then
                Farm.Target = nil
                task.wait(APP.RetryDelay)
                continue
            end
        end

        setState(STATE.FIGHTING)
        setStatus("Combatendo: " .. tostring(target.Name))

        while Farm.Running and isValidTarget(target) do
            if questComplete(quest) then
                break
            end

            local _, humanoid, root = getCharacter()

            if not humanoid or not root or humanoid.Health <= 0 then
                break
            end

            local enemyRoot = getTargetRoot(target)

            if enemyRoot then
                local distance = (root.Position - enemyRoot.Position).Magnitude

                if distance > APP.TargetDistance then
                    humanoid:MoveTo(enemyRoot.Position)
                end
            end

            local attackOk, attackError = attackTarget(target)

            if not attackOk then
                setStatus("Combate aguardando: " .. tostring(attackError))
            end

            task.wait(APP.AttackInterval)
        end

        Farm.Target = nil
        task.wait(APP.RetryDelay)
    end

    -- Turn in
    if Farm.Running and questComplete(quest) then
        setState(STATE.TURNING_IN)
        setStatus("Entregando missão...")

        local success, errorMessage = turnInQuest(quest)

        if not success then
            setStatus("Entrega aguardando: " .. tostring(errorMessage))
        end
    end

    resetQuest()
end

--==============================================================--
-- MAIN LOOP
--==============================================================--

local function farmLoop()
    setState(STATE.STARTING)
    setStatus("Iniciando Rip_loder Farm Level...")
    clearError()

    while Farm.Running do
        if not waitForCharacter() then
            break
        end

        setState(STATE.READING_LEVEL)

        local level = refreshLevel()

        if level <= 0 then
            setStatus("Aguardando nível carregar...")
            task.wait(APP.RetryDelay)
            continue
        end

        -- Máximo absoluto.
        if isFullyComplete(level) then
            setState(STATE.COMPLETE)
            setStatus("Progressão concluída no nível " .. tostring(level) .. ".")
            break
        end

        -- Secret Levels.
        if isNormalComplete(level) then
            setState(STATE.SECRET_LEVELS)

            local objective, secretError = getSecretObjective()

            if secretError then
                setStatus("Secret Levels: " .. tostring(secretError))
                task.wait(APP.RetryDelay)
                continue
            end

            if objective then
                setStatus(
                    "Secret Level: "
                    .. tostring(objective.Name or objective.Id or "Objetivo")
                )

                -- O jogo próprio decide como executar o objetivo.
                if typeof(objective.Run) == "function" then
                    local ok, result = pcall(objective.Run, objective, Farm)

                    if not ok then
                        setStatus("Objetivo secreto falhou: " .. tostring(result))
                    end
                end
            else
                setStatus(
                    "Nível "
                    .. tostring(level)
                    .. " alcançou o limite normal de 2800. "
                    .. "Configure SecretProvider para continuar até 3000."
                )
            end

            task.wait(APP.QuestCheckDelay)
            continue
        end

        -- Quest normal.
        if not Farm.Quest then
            setState(STATE.FINDING_QUEST)
            setStatus("Procurando missão para nível " .. tostring(level) .. "...")

            local quest, questError = findQuest()

            if not quest then
                setStatus("Missão: " .. tostring(questError))
                task.wait(APP.RetryDelay)
                continue
            end

            Farm.Quest = quest
        end

        runQuestCycle()

        task.wait(APP.RetryDelay)
    end

    if Farm.State ~= STATE.COMPLETE
        and Farm.State ~= STATE.ERROR then

        setState(STATE.IDLE)
        setStatus("Farm parado.")
    end
end

local function startFarm()
    if Farm.Running then
        return
    end

    Farm.Running = true
    Farm.Error = nil

    Farm.Thread = task.spawn(function()
        local ok, errorMessage = pcall(farmLoop)

        if not ok then
            setError(errorMessage)
        end
    end)
end

local function stopFarm()
    Farm.Running = false

    Farm.Thread = nil
    resetQuest()

    setState(STATE.IDLE)
    setStatus("Farm parado.")
end

local function toggleFarm()
    if Farm.Running then
        stopFarm()
    else
        startFarm()
    end
end

--==============================================================--
-- UI
--==============================================================--

local oldGui = PlayerGui:FindFirstChild("Rip_loder_UI")
if oldGui then
    oldGui:Destroy()
end

local GUI = Instance.new("ScreenGui")
GUI.Name = "Rip_loder_UI"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent = PlayerGui

local function create(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    object.Parent = parent

    return object
end

local shadow = create("Frame", {
    Name = "Shadow",
    Size = UDim2.fromOffset(560, 385),
    Position = UDim2.new(0.5, -270, 0.5, -185),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.55,
    BorderSizePixel = 0,
}, GUI)

create("UICorner", {
    CornerRadius = UDim.new(0, 16)
}, shadow)

local main = create("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(540, 365),
    Position = UDim2.new(0.5, -270, 0.5, -182),
    BackgroundColor3 = Color3.fromRGB(19, 19, 23),
    BorderSizePixel = 0,
}, GUI)

create("UICorner", {
    CornerRadius = UDim.new(0, 16)
}, main)

create("UIStroke", {
    Thickness = 1,
    Transparency = 0.35,
    Color = Color3.fromRGB(90, 90, 100),
}, main)

local top = create("Frame", {
    Size = UDim2.new(1, 0, 0, 55),
    BackgroundColor3 = Color3.fromRGB(27, 27, 33),
    BorderSizePixel = 0,
}, main)

create("UICorner", {
    CornerRadius = UDim.new(0, 16),
}, top)

create("Frame", {
    Size = UDim2.new(1, 0, 0, 16),
    Position = UDim2.new(0, 0, 1, -16),
    BackgroundColor3 = Color3.fromRGB(27, 27, 33),
    BorderSizePixel = 0,
}, top)

create("TextLabel", {
    Name = "Title",
    Size = UDim2.new(1, -110, 0, 30),
    Position = UDim2.fromOffset(18, 6),
    BackgroundTransparency = 1,
    Text = APP.Name,
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(242, 242, 247),
}, top)

create("TextLabel", {
    Name = "Version",
    Size = UDim2.new(1, -110, 0, 18),
    Position = UDim2.fromOffset(19, 32),
    BackgroundTransparency = 1,
    Text = "2026 • " .. APP.Version,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(155, 155, 165),
}, top)

local close = create("TextButton", {
    Size = UDim2.fromOffset(34, 32),
    Position = UDim2.new(1, -45, 0, 11),
    BackgroundColor3 = Color3.fromRGB(42, 42, 50),
    BorderSizePixel = 0,
    Text = "×",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(235, 235, 240),
    AutoButtonColor = false,
}, top)

create("UICorner", {
    CornerRadius = UDim.new(0, 9)
}, close)

local sidebar = create("Frame", {
    Size = UDim2.new(0, 140, 1, -67),
    Position = UDim2.fromOffset(10, 62),
    BackgroundColor3 = Color3.fromRGB(24, 24, 30),
    BorderSizePixel = 0,
}, main)

create("UICorner", {
    CornerRadius = UDim.new(0, 11)
}, sidebar)

local pages = create("Frame", {
    Size = UDim2.new(1, -160, 1, -67),
    Position = UDim2.fromOffset(150, 62),
    BackgroundTransparency = 1,
}, main)

local tabs = {}
local pagesMap = {}

local function makeTab(name, y)
    local button = create("TextButton", {
        Name = name,
        Size = UDim2.new(1, -16, 0, 42),
        Position = UDim2.fromOffset(8, y),
        BackgroundColor3 = Color3.fromRGB(34, 34, 42),
        BorderSizePixel = 0,
        Text = "  " .. name,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(205, 205, 215),
        AutoButtonColor = false,
    }, sidebar)

    create("UICorner", {
        CornerRadius = UDim.new(0, 9)
    }, button)

    local page = create("Frame", {
        Name = name .. "Page",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
    }, pages)

    tabs[name] = button
    pagesMap[name] = page

    return page
end

local farmingPage = makeTab("Farming", 10)
local infoPage = makeTab("Info", 60)
local settingsPage = makeTab("Settings", 110)

local function showPage(name)
    for tabName, page in pairs(pagesMap) do
        page.Visible = (tabName == name)

        local tab = tabs[tabName]

        if tabName == name then
            tab.BackgroundColor3 = Color3.fromRGB(57, 57, 70)
            tab.TextColor3 = Color3.fromRGB(245, 245, 250)
        else
            tab.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
            tab.TextColor3 = Color3.fromRGB(205, 205, 215)
        end
    end
end

for name, button in pairs(tabs) do
    button.MouseButton1Click:Connect(function()
        showPage(name)
    end)
end

--==============================================================--
-- FARMING PAGE
--==============================================================--

create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 28),
    BackgroundTransparency = 1,
    Text = "Farming",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(242, 242, 247),
}, farmingPage)

local statusBox = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 48),
    Position = UDim2.fromOffset(0, 35),
    BackgroundColor3 = Color3.fromRGB(28, 28, 34),
    BorderSizePixel = 0,
    Text = "Status: Pronto.",
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(215, 215, 223),
}, farmingPage)

create("UICorner", {
    CornerRadius = UDim.new(0, 10)
}, statusBox)

local levelLabel = create("TextLabel", {
    Size = UDim2.new(0.5, -5, 0, 29),
    Position = UDim2.fromOffset(0, 94),
    BackgroundTransparency = 1,
    Text = "Nível: 0",
    Font = Enum.Font.GothamMedium,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(220, 220, 228),
}, farmingPage)

local stateLabel = create("TextLabel", {
    Size = UDim2.new(0.5, -5, 0, 29),
    Position = UDim2.new(0.5, 5, 0, 94),
    BackgroundTransparency = 1,
    Text = "Estado: Idle",
    Font = Enum.Font.GothamMedium,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(220, 220, 228),
}, farmingPage)

local questLabel = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 27),
    Position = UDim2.fromOffset(0, 123),
    BackgroundTransparency = 1,
    Text = "Missão: —",
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(195, 195, 205),
}, farmingPage)

local targetLabel = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 27),
    Position = UDim2.fromOffset(0, 150),
    BackgroundTransparency = 1,
    Text = "Alvo: —",
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(195, 195, 205),
}, farmingPage)

local progressLabel = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 27),
    Position = UDim2.fromOffset(0, 177),
    BackgroundTransparency = 1,
    Text = "Progresso: —",
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(195, 195, 205),
}, farmingPage)

local farmButton = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 48),
    Position = UDim2.new(0, 0, 1, -48),
    BackgroundColor3 = Color3.fromRGB(48, 48, 58),
    BorderSizePixel = 0,
    Text = "FARM LEVEL  •  OFF",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = Color3.fromRGB(240, 240, 245),
    AutoButtonColor = false,
}, farmingPage)

create("UICorner", {
    CornerRadius = UDim.new(0, 10)
}, farmButton)

--==============================================================--
-- INFO PAGE
--==============================================================--

create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundTransparency = 1,
    Text = "Information",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(242, 242, 247),
}, infoPage)

create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 115),
    Position = UDim2.fromOffset(0, 42),
    BackgroundColor3 = Color3.fromRGB(28, 28, 34),
    BorderSizePixel = 0,
    Text =
        APP.Name
        .. "\n\n"
        .. "Versão: " .. APP.Version
        .. "\n"
        .. "Progressão normal: Lv. 1 → 2800"
        .. "\n"
        .. "Secret Levels: Lv. 2801 → 3000"
        .. "\n\n"
        .. "Discord: " .. APP.Discord,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextColor3 = Color3.fromRGB(215, 215, 223),
}, infoPage)

--==============================================================--
-- SETTINGS PAGE
--==============================================================--

create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundTransparency = 1,
    Text = "Settings",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(242, 242, 247),
}, settingsPage)

local compactMode = false

local compactToggle = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 44),
    Position = UDim2.fromOffset(0, 42),
    BackgroundColor3 = Color3.fromRGB(30, 30, 36),
    BorderSizePixel = 0,
    Text = "Compact UI  •  OFF",
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextColor3 = Color3.fromRGB(220, 220, 228),
    AutoButtonColor = false,
}, settingsPage)

create("UICorner", {
    CornerRadius = UDim.new(0, 9)
}, compactToggle)

local function applyCompact()
    if compactMode then
        main.Size = UDim2.fromOffset(480, 325)
        main.Position = UDim2.new(0.5, -240, 0.5, -162)
        shadow.Size = UDim2.fromOffset(500, 345)
        shadow.Position = UDim2.new(0.5, -230, 0.5, -172)

        compactToggle.Text = "Compact UI  •  ON"
    else
        main.Size = UDim2.fromOffset(540, 365)
        main.Position = UDim2.new(0.5, -270, 0.5, -182)
        shadow.Size = UDim2.fromOffset(560, 385)
        shadow.Position = UDim2.new(0.5, -270, 0.5, -185)

        compactToggle.Text = "Compact UI  •  OFF"
    end
end

compactToggle.MouseButton1Click:Connect(function()
    compactMode = not compactMode
    applyCompact()
end)

--==============================================================--
-- OPEN / CLOSE
--==============================================================--

local openButton = create("TextButton", {
    Size = UDim2.fromOffset(50, 50),
    Position = UDim2.fromOffset(18, 180),
    BackgroundColor3 = Color3.fromRGB(25, 25, 31),
    BorderSizePixel = 0,
    Text = "RL",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(240, 240, 245),
    Visible = false,
    AutoButtonColor = false,
}, GUI)

create("UICorner", {
    CornerRadius = UDim.new(1, 0)
}, openButton)

close.MouseButton1Click:Connect(function()
    main.Visible = false
    shadow.Visible = false
    openButton.Visible = true
end)

openButton.MouseButton1Click:Connect(function()
    main.Visible = true
    shadow.Visible = true
    openButton.Visible = false
end)

--==============================================================--
-- DRAG
--==============================================================--

local dragging = false
local dragStart
local startPosition

top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)

top.InputEnded:Connect(function(input)
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

--==============================================================--
-- UI UPDATE
--==============================================================--

local function updateUI()
    levelLabel.Text = "Nível: " .. tostring(Farm.Level)
    stateLabel.Text = "Estado: " .. tostring(Farm.State)
    statusBox.Text = "Status: " .. tostring(Farm.Status)

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

    if Farm.QuestRequired > 0 then
        progressLabel.Text =
            "Progresso: "
            .. tostring(Farm.QuestProgress)
            .. "/"
            .. tostring(Farm.QuestRequired)
    else
        progressLabel.Text = "Progresso: —"
    end

    if Farm.Running then
        farmButton.Text = "FARM LEVEL  •  ON"
        farmButton.BackgroundColor3 = Color3.fromRGB(57, 70, 57)
    else
        farmButton.Text = "FARM LEVEL  •  OFF"
        farmButton.BackgroundColor3 = Color3.fromRGB(48, 48, 58)
    end
end

farmButton.MouseButton1Click:Connect(function()
    toggleFarm()
    updateUI()
end)

task.spawn(function()
    while GUI.Parent do
        Farm.Level = getLevel()
        updateUI()
        task.wait(0.15)
    end
end)

--==============================================================--
-- CHARACTER EVENTS
--==============================================================--

table.insert(Farm.Connections, LocalPlayer.CharacterAdded:Connect(function()
    Farm.Target = nil

    if Farm.Running then
        setState(STATE.WAITING_CHARACTER)
        setStatus("Personagem reaparecendo...")
    end
end))

table.insert(Farm.Connections, LocalPlayer.CharacterRemoving:Connect(function()
    Farm.Target = nil
end))

--==============================================================--
-- CLEANUP
--==============================================================--

GUI.Destroying:Connect(function()
    stopFarm()

    for _, connection in ipairs(Farm.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    Farm.Connections = {}
end)

--==============================================================--
-- INIT
--==============================================================--

showPage("Farming")
updateUI()

--==============================================================--
-- ESTRUTURA DE CONFIGURAÇÃO
--==============================================================--
--
-- Workspace
-- ├── Quests
-- │   ├── Quest01
-- │   │   ├── QuestPosition (Part)
-- │   │   └── TargetPosition (Part) opcional
-- │   │
-- │   └── Quest02
-- │
-- └── Enemies
--     ├── EnemyA
--     │   ├── Humanoid
--     │   └── HumanoidRootPart
--     └── EnemyB
--
-- Attributes em cada Quest:
--
-- MinLevel      number
-- MaxLevel      number
-- TargetName    string
-- DisplayName   string opcional
--
-- Para concluir uma missão sem Provider:
--
-- QuestInstance:SetAttribute("Completed", true)
--
-- Para um projeto próprio, recomenda-se configurar:
--
-- Providers.QuestProvider
-- Providers.TargetProvider
-- Providers.QuestCompleteProvider
-- Providers.StartQuestProvider
-- Providers.AttackProvider
-- Providers.TurnInProvider
-- Providers.SecretProvider
--
-- Exemplo de QuestProvider:
--
-- Providers.QuestProvider = function(level, farm)
--     if level >= 1 and level <= 20 then
--         return {
--             Id = "Quest01",
--             Name = "Quest 01",
--             MinLevel = 1,
--             MaxLevel = 20,
--             QuestPosition = Vector3.new(0, 3, 0),
--             TargetName = "Bandit",
--         }
--     end
--
--     return nil
-- end
--
-- Exemplo de TargetProvider:
--
-- Providers.TargetProvider = function(quest, farm)
--     local enemies = workspace:FindFirstChild("Enemies")
--     if not enemies then
--         return nil
--     end
--
--     for _, enemy in ipairs(enemies:GetChildren()) do
--         if enemy.Name == quest.TargetName then
--             local humanoid = enemy:FindFirstChildOfClass("Humanoid")
--
--             if humanoid and humanoid.Health > 0 then
--                 return enemy
--             end
--         end
--     end
--
--     return nil
-- end
--
-- Exemplo de AttackProvider para o SEU JOGO:
--
-- Providers.AttackProvider = function(target, quest, farm)
--     -- Ligue aqui o sistema de combate da sua própria experiência.
--     -- Exemplo conceitual:
--     -- CombatService:Attack(target)
--     return true
-- end
--
-- SecretProvider deve implementar somente os objetivos do seu jogo.
--
--==============================================================--
-- FIM
--==============================================================--
