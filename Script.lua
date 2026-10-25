--[[
    SPEED ULTRA V9.5 — 2026
    Base inicial modernizada com Rayfield Gen2.

    Incluído nesta versão:
      • UI responsiva com abas e temas;
      • salvamento de preferências pela configuração do Rayfield;
      • otimização VISUAL local e reversível de partículas, trails, fumaça e fogo;
      • opção para desativar BlurEffect e DepthOfFieldEffect enquanto a otimização estiver ativa;
      • monitoramento somente de leitura do personagem, saúde, WalkSpeed, FPS aproximado e possíveis marcadores de carry;
      • encerramento que tenta restaurar as propriedades visuais modificadas;
      • checklist manual revisada para Update 10 — Halloween Part 2, com fonte comunitária identificada;
      • seletor manual de objetivos de ovos/evento (não controla o personagem);
      • novas opções para Beam, Sparkles, Bloom e SunRays;
      • indicador aproximado de FPS e informações básicas do dispositivo;
      • varredura incremental para reduzir picos de memória;
      • controle de intensidade que evita reiniciar a varredura a cada movimento;
      • token de inicialização antecipado para não abrir abas duplicadas ao reexecutar;
      • restauração/encerramento da sessão anterior e verificação do token após esperas;
      • aviso explícito de que não existe modo Anti-Ban implementado nem garantia contra punições.

    Nota: não altera WalkSpeed, colisões, massa ou física do jogo. Não automatiza
    coleta, teleporte ou interação em servidores públicos. Para mecânicas de movimento
    e entrega de ovos num jogo próprio, implemente a lógica autorizada no servidor.
    Segurança: a instância única é proteção contra conflito local, NÃO é Anti-Ban.
    Compatibilidade: a UI remota usa loadstring e tenta game:HttpGet com fallback
    request/http_request quando disponível. Exige um ambiente que permita executar
    Lua remoto; não é um LocalScript padrão do Roblox Studio.
]]

-- =========================================================
-- BOOTSTRAP / INSTÂNCIA ÚNICA
-- Registra a nova execução ANTES de qualquer espera ou download.
-- Uma execução nova invalida a anterior; a anterior destrói sua janela
-- assim que retoma caso estivesse no meio do carregamento remoto.
-- =========================================================

local Env = _G
pcall(function()
    if type(getgenv) == "function" then
        local env = getgenv()
        if type(env) == "table" then
            Env = env
        end
    end
end)

local REGISTRY_KEY = "__SPEED_ULTRA_INSTANCE"
local BOOT_KEY = "__SPEED_ULTRA_BOOT_RECORD"

local PreviousBoot = Env[BOOT_KEY]
if type(PreviousBoot) == "table" then
    PreviousBoot.cancelled = true

    if type(PreviousBoot.cleanup) == "function" then
        pcall(PreviousBoot.cleanup, "RELOAD")
    elseif PreviousBoot.window then
        pcall(function()
            local oldWindow = PreviousBoot.window
            if type(oldWindow.Destroy) == "function" then
                oldWindow:Destroy()
            elseif type(oldWindow.Unload) == "function" then
                oldWindow:Unload()
            end
        end)
    end
end

local OldCleanup = Env[REGISTRY_KEY]
if type(OldCleanup) == "function"
    and not (type(PreviousBoot) == "table" and PreviousBoot.cleanup == OldCleanup)
then
    pcall(OldCleanup, "RELOAD")
end

local Boot = {
    cancelled = false,
    cleanup = nil,
    window = nil,
}
Env[BOOT_KEY] = Boot

local function IsCurrentBoot()
    return not Boot.cancelled and Env[BOOT_KEY] == Boot
end

local function ReleaseBootReservation()
    if Env[BOOT_KEY] == Boot then
        Boot.cancelled = true
        Env[BOOT_KEY] = nil
    end
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end
if not IsCurrentBoot() then
    return
end

task.wait(0.1)
if not IsCurrentBoot() then
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

if not RunService:IsClient() then
    ReleaseBootReservation()
    return
end
if not IsCurrentBoot() then
    return
end

local Player = Players.LocalPlayer
if not Player then
    ReleaseBootReservation()
    return
end
if not IsCurrentBoot() then
    return
end

-- =========================================================
-- CARREGAMENTO DA UI
-- Fonte oficial Rayfield Gen2: https://sirius.menu/gen2
-- =========================================================

local Rayfield
local function FetchRemoteSource(url)
    local errors = {}

    -- Caminho preferido, igual ao exemplo oficial do Rayfield Gen2.
    local gameHttpOk, gameHttpBody = pcall(function()
        return game:HttpGet(url)
    end)
    if gameHttpOk and type(gameHttpBody) == "string" and #gameHttpBody > 0 then
        return gameHttpBody
    end
    errors[#errors + 1] = "game:HttpGet não retornou conteúdo"

    -- Fallback opcional para ambientes que fornecem request/http_request.
    local requestFunction
    pcall(function() requestFunction = request end)
    if type(requestFunction) ~= "function" then
        pcall(function() requestFunction = http_request end)
    end

    if type(requestFunction) == "function" then
        local requestOk, response = pcall(function()
            return requestFunction({ Url = url, Method = "GET" })
        end)
        if requestOk and type(response) == "table"
            and type(response.Body) == "string" and #response.Body > 0
            and (response.Success ~= false)
        then
            return response.Body
        end
        errors[#errors + 1] = "request/http_request falhou"
    end

    error(table.concat(errors, "; "))
end

local loadOk, loadResult = pcall(function()
    if type(loadstring) ~= "function" then
        error("Este ambiente não disponibiliza loadstring; não é possível iniciar o Rayfield remoto.")
    end

    local source = FetchRemoteSource("https://sirius.menu/gen2")
    if not IsCurrentBoot() then
        return nil
    end

    local compileOk, chunkOrError = pcall(loadstring, source)
    if not compileOk or type(chunkOrError) ~= "function" then
        error("Não foi possível compilar a biblioteca Rayfield Gen2: " .. tostring(chunkOrError))
    end
    if not IsCurrentBoot() then
        return nil
    end
    return chunkOrError()
end)

if not IsCurrentBoot() then
    return
end

if loadOk then
    Rayfield = loadResult
else
    warn("[SPEED ULTRA V9.5] Não foi possível carregar Rayfield Gen2: " .. tostring(loadResult))
    ReleaseBootReservation()
    return
end

if type(Rayfield) ~= "table" or type(Rayfield.CreateWindow) ~= "function" then
    warn("[SPEED ULTRA V9.5] Rayfield Gen2 não retornou uma API válida; a interface não foi iniciada.")
    ReleaseBootReservation()
    return
end

-- =========================================================
-- CONFIGURAÇÃO / ESTADO
-- =========================================================

local Config = {
    ReductionPercent = 35,
    OptimizeParticles = true,
    OptimizeTrails = true,
    OptimizeAtmospherics = true,
    OptimizeBeams = true,
    DisableSparkles = false,
    DisablePostEffects = true,
    ReduceBloomSunRays = true,
    ScanBudgetObjects = 120,
    MaxScanSeconds = 12,
    CarryMonitorInterval = 2.5,
    CarryAttributes = {
        "Carrying", "IsCarrying", "HasCarry", "CarryingObject",
        "IsCarryingObject", "Holding", "IsHolding", "HasObject"
    },
    CarryTags = {
        "Carry", "Carried", "CarryObject", "Carrying", "Held", "HeavyObject"
    }
}

local State = {
    Alive = true,
    Cleaning = false,
    UIReady = false,
    ControlsUpdating = false,
    VisualOptimization = false,
    Optimizing = false,
    CollectingPending = false,
    PendingDrainRunning = false,
    OptimizeToken = 0,
    -- Chaves fracas evitam reter instâncias temporárias de efeitos já destruídos.
    OriginalProperties = setmetatable({}, { __mode = "k" }),
    ProcessedObjects = setmetatable({}, { __mode = "k" }),
    PendingObjects = setmetatable({}, { __mode = "k" }),
    Stats = {
        ObjectsVisited = 0,
        CompatibleEffects = 0,
        LastDuration = 0,
        LastPartial = false,
        FPS = 0,
        FPSUpdatedAt = 0,
    },
    MonitorCarry = true,
    LastCarryDetected = false,
    LastCarryObject = nil,
    CurrentCharacter = nil,
    CurrentHumanoid = nil,
    CurrentRoot = nil,
}

local Connections = {}
local Window
local StatusText
local OperationText
local VisualToggle
local ReductionSlider
local ParticlesToggle
local TrailsToggle
local AtmosphericsToggle
local PostEffectsToggle
local BeamsToggle
local SparklesToggle
local BloomSunRaysToggle
local FpsText
local DeviceText
local ObjectiveText
local ObjectiveDropdown

local function AddConnection(connection)
    Connections[#Connections + 1] = connection
    return connection
end

local function DisconnectAll()
    for _, connection in ipairs(Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(Connections)
end

local function UpdateStatus(text)
    if not State.Alive or not StatusText then
        return
    end
    pcall(function()
        StatusText:Set(text)
    end)
end

local function UpdateOperationStatus(text)
    if not State.Alive or not OperationText then
        return
    end
    pcall(function()
        OperationText:Set(text)
    end)
end

-- =========================================================
-- OTIMIZAÇÃO VISUAL REVERSÍVEL
-- =========================================================

local function SaveOriginal(object, property, value)
    if not object then
        return
    end

    local record = State.OriginalProperties[object]
    if not record then
        record = {}
        State.OriginalProperties[object] = record
    end

    if record[property] == nil then
        record[property] = value
    end
end

local function GetOriginal(object, property)
    local record = State.OriginalProperties[object]
    if record and record[property] ~= nil then
        return record[property]
    end

    local value
    local ok = pcall(function()
        value = object[property]
    end)
    if not ok then
        return nil
    end

    SaveOriginal(object, property, value)
    return value
end

local function RestoreVisualProperties()
    for object, properties in pairs(State.OriginalProperties) do
        if object then
            for property, value in pairs(properties) do
                pcall(function()
                    object[property] = value
                end)
            end
        end
    end

    table.clear(State.OriginalProperties)
    table.clear(State.ProcessedObjects)
    table.clear(State.PendingObjects)
end

local function ApplyObjectOptimization(object)
    if not object or not object.Parent or not State.VisualOptimization then
        return false
    end

    if State.ProcessedObjects[object] then
        return false
    end

    local reduction = math.clamp(Config.ReductionPercent / 100, 0, 0.70)
    local keepFactor = 1 - reduction
    local matched = false

    pcall(function()
        if Config.OptimizeParticles and object:IsA("ParticleEmitter") then
            local originalRate = GetOriginal(object, "Rate")
            if type(originalRate) == "number" and originalRate > 0 then
                object.Rate = math.max(0, originalRate * keepFactor)
                matched = true
            end

        elseif Config.OptimizeTrails and object:IsA("Trail") then
            local originalLifetime = GetOriginal(object, "Lifetime")
            if type(originalLifetime) == "number" and originalLifetime > 0 then
                -- Roblox Trail.Lifetime aceita valores desde 0.01; nunca aumente
                -- um trail originalmente menor que 0.05s.
                object.Lifetime = math.max(0.01, originalLifetime * keepFactor)
                matched = true
            end

        elseif Config.OptimizeBeams and object:IsA("Beam") then
            local originalWidth0 = GetOriginal(object, "Width0")
            local originalWidth1 = GetOriginal(object, "Width1")
            if type(originalWidth0) == "number" and originalWidth0 > 0 then
                object.Width0 = originalWidth0 * keepFactor
                matched = true
            end
            if type(originalWidth1) == "number" and originalWidth1 > 0 then
                object.Width1 = originalWidth1 * keepFactor
                matched = true
            end

        elseif Config.DisableSparkles and object:IsA("Sparkles") then
            local originalEnabled = GetOriginal(object, "Enabled")
            if originalEnabled ~= nil then
                object.Enabled = false
                matched = true
            end

        elseif Config.OptimizeAtmospherics and object:IsA("Smoke") then
            local originalOpacity = GetOriginal(object, "Opacity")
            local originalSize = GetOriginal(object, "Size")
            if type(originalOpacity) == "number" then
                object.Opacity = math.clamp(originalOpacity * keepFactor, 0, 1)
                matched = true
            end
            if type(originalSize) == "number" and originalSize > 0 then
                object.Size = math.max(0.1, originalSize * (1 - reduction * 0.5))
                matched = true
            end

        elseif Config.OptimizeAtmospherics and object:IsA("Fire") then
            local originalSize = GetOriginal(object, "Size")
            local originalHeat = GetOriginal(object, "Heat")
            if type(originalSize) == "number" and originalSize > 0 then
                object.Size = math.max(0.1, originalSize * (1 - reduction * 0.5))
                matched = true
            end
            if type(originalHeat) == "number" then
                object.Heat = originalHeat * keepFactor
                matched = true
            end

        elseif Config.DisablePostEffects
            and (object:IsA("BlurEffect") or object:IsA("DepthOfFieldEffect")) then
            local originalEnabled = GetOriginal(object, "Enabled")
            if originalEnabled ~= nil then
                object.Enabled = false
                matched = true
            end

        elseif Config.ReduceBloomSunRays and object:IsA("BloomEffect") then
            local originalIntensity = GetOriginal(object, "Intensity")
            if type(originalIntensity) == "number" then
                object.Intensity = math.clamp(originalIntensity * keepFactor, 0, 1)
                matched = true
            end

        elseif Config.ReduceBloomSunRays and object:IsA("SunRaysEffect") then
            local originalIntensity = GetOriginal(object, "Intensity")
            if type(originalIntensity) == "number" then
                object.Intensity = math.clamp(originalIntensity * keepFactor, 0, 1)
                matched = true
            end
        end
    end)

    if matched then
        State.ProcessedObjects[object] = true
    end
    return matched
end

local function StartPendingDrain()
    if not State.Alive
        or not State.VisualOptimization
        or State.Optimizing
        or State.PendingDrainRunning
    then
        return
    end

    State.PendingDrainRunning = true
    local token = State.OptimizeToken

    task.spawn(function()
        local processed = 0
        local batchSize = math.max(30, math.floor(tonumber(Config.ScanBudgetObjects) or 120))

        while State.Alive
            and State.VisualOptimization
            and token == State.OptimizeToken
        do
            local batch = {}
            for object in pairs(State.PendingObjects) do
                State.PendingObjects[object] = nil
                batch[#batch + 1] = object
                if #batch >= batchSize then
                    break
                end
            end

            if #batch == 0 then
                break
            end

            for _, object in ipairs(batch) do
                if not State.Alive or token ~= State.OptimizeToken or not State.VisualOptimization then
                    break
                end
                State.Stats.ObjectsVisited += 1
                if ApplyObjectOptimization(object) then
                    State.Stats.CompatibleEffects += 1
                end
                processed += 1
            end

            if processed >= batchSize then
                processed = 0
                RunService.Heartbeat:Wait()
            end
        end

        State.PendingDrainRunning = false
        -- Se outro ciclo de otimização começou enquanto este worker aguardava
        -- Heartbeat, deixe o ciclo atual decidir quando a fila pode ser drenada.
        if State.Alive
            and State.VisualOptimization
            and not State.Optimizing
            and next(State.PendingObjects) ~= nil
        then
            StartPendingDrain()
        end
    end)
end

local function SetVisualOptimization(enabled)
    if not State.Alive then
        return
    end

    State.VisualOptimization = enabled == true
    State.OptimizeToken += 1
    local token = State.OptimizeToken
    State.Optimizing = false
    State.CollectingPending = false

    -- Restaura antes de reaplicar para que sliders e categorias não acumulem reduções.
    RestoreVisualProperties()

    if not State.VisualOptimization then
        UpdateOperationStatus("Otimização visual: DESATIVADA\nAs propriedades guardadas foram restauradas.")
        return
    end

    State.Stats.ObjectsVisited = 0
    State.Stats.CompatibleEffects = 0
    State.Stats.LastDuration = 0
    State.Stats.LastPartial = false
    State.Optimizing = true
    State.CollectingPending = true
    UpdateOperationStatus("Otimização visual: preparando...\nProcessamento incremental em lotes.")

    task.spawn(function()
        local startedAt = os.clock()
        local processed = 0
        local partial = false
        local batchSize = math.max(30, math.floor(tonumber(Config.ScanBudgetObjects) or 120))
        local maxSeconds = math.max(2, tonumber(Config.MaxScanSeconds) or 12)
        local stack = { Workspace, Lighting }

        while #stack > 0 do
            if not State.Alive or token ~= State.OptimizeToken or not State.VisualOptimization then
                return
            end

            if os.clock() - startedAt >= maxSeconds then
                partial = true
                break
            end

            local parent = stack[#stack]
            stack[#stack] = nil
            local children
            local okChildren = pcall(function()
                children = parent:GetChildren()
            end)

            if okChildren and children then
                for _, object in ipairs(children) do
                    if not State.Alive or token ~= State.OptimizeToken or not State.VisualOptimization then
                        return
                    end

                    if os.clock() - startedAt >= maxSeconds then
                        partial = true
                        break
                    end

                    stack[#stack + 1] = object
                    State.Stats.ObjectsVisited += 1
                    if ApplyObjectOptimization(object) then
                        State.Stats.CompatibleEffects += 1
                    end
                    processed += 1

                    if processed >= batchSize then
                        processed = 0
                        RunService.Heartbeat:Wait()
                    end
                end
            else
                -- Não declare sucesso completo quando uma parte não pôde ser lida.
                partial = true
            end

            if partial then
                break
            end
        end

        -- Esvazia a fila de objetos surgidos durante a varredura, em lotes limitados.
        State.CollectingPending = false
        while next(State.PendingObjects) ~= nil do
            if not State.Alive or token ~= State.OptimizeToken or not State.VisualOptimization then
                return
            end

            local batch = {}
            for object in pairs(State.PendingObjects) do
                State.PendingObjects[object] = nil
                batch[#batch + 1] = object
                if #batch >= batchSize then
                    break
                end
            end

            for _, object in ipairs(batch) do
                if not State.Alive or token ~= State.OptimizeToken or not State.VisualOptimization then
                    return
                end
                State.Stats.ObjectsVisited += 1
                if ApplyObjectOptimization(object) then
                    State.Stats.CompatibleEffects += 1
                end
                processed += 1
                if processed >= batchSize then
                    processed = 0
                    RunService.Heartbeat:Wait()
                end
            end
        end

        if not State.Alive or token ~= State.OptimizeToken then
            return
        end

        State.Optimizing = false
        State.Stats.LastDuration = os.clock() - startedAt
        State.Stats.LastPartial = partial

        UpdateOperationStatus(string.format(
            "Otimização visual: %s\nIntensidade configurada: %d%%\nEfeitos compatíveis: %d • Objetos visitados: %d\nDuração: %.2fs",
            partial and "PARCIAL" or "ATIVA",
            Config.ReductionPercent,
            State.Stats.CompatibleEffects,
            State.Stats.ObjectsVisited,
            State.Stats.LastDuration
        ))

        if next(State.PendingObjects) ~= nil then
            StartPendingDrain()
        end
    end)
end

local function OnVisualDescendantAdded(object)
    if not State.Alive or not State.VisualOptimization or not object then
        return
    end

    State.PendingObjects[object] = true
    if not State.Optimizing then
        StartPendingDrain()
    end
end

-- =========================================================
-- MONITORAMENTO DE CARRY (SOMENTE LEITURA)
-- =========================================================

local function HasCarryMarker(object)
    if not object then
        return false
    end

    for _, attributeName in ipairs(Config.CarryAttributes) do
        local value
        local ok = pcall(function()
            value = object:GetAttribute(attributeName)
        end)

        if ok then
            if value == true then
                return true
            end
            if type(value) == "number" and value > 0 then
                return true
            end
            if type(value) == "string" then
                local marker = string.lower(string.gsub(value, "%s+", ""))
                if marker ~= "" and marker ~= "false" and marker ~= "none"
                    and marker ~= "nil" and marker ~= "0" then
                    return true
                end
            end
        end
    end

    for _, tagName in ipairs(Config.CarryTags) do
        local tagged = false
        pcall(function()
            tagged = CollectionService:HasTag(object, tagName)
        end)
        if tagged then
            return true
        end
    end

    return false
end

local function DetectCarryMarker()
    local character = Player.Character
    if not character or not character.Parent then
        return false, nil
    end

    if HasCarryMarker(Player) then
        return true, Player
    end
    if HasCarryMarker(character) then
        return true, character
    end

    local ok, descendants = pcall(function()
        return character:GetDescendants()
    end)
    if not ok or not descendants then
        return false, nil
    end

    -- Uma única passagem pelos descendentes reduz trabalho repetido do monitor.
    for _, object in ipairs(descendants) do
        if HasCarryMarker(object) then
            return true, object
        end

        -- Alguns sistemas de carry conectam a montagem ao personagem por weld/constraint.
        if object:IsA("WeldConstraint") or object:IsA("Weld") or object:IsA("Motor6D") then
            local part0, part1
            pcall(function()
                part0 = object.Part0
                part1 = object.Part1
            end)

            if part0 and part1 then
                local in0 = part0:IsDescendantOf(character)
                local in1 = part1:IsDescendantOf(character)
                if in0 ~= in1 then
                    return true, in0 and part1 or part0
                end
            end
        end
    end

    return false, nil
end

-- =========================================================
-- INTERFACE RAYFIELD GEN2
-- =========================================================

if not IsCurrentBoot() then
    return
end

local WindowCreateOk, CreatedWindow = pcall(function()
    return Rayfield:CreateWindow({
        name = "SPEED ULTRA V9.5",
        subtitle = "2026 • Mobile Edition",
        sidebarLayout = true,
        theme = "amethyst",
        showName = "SPEED ULTRA",
        showIconOnly = false,
        configuration = {
            autoSave = true,
            autoLoad = true,
            -- Nome anterior mantido para reaproveitar as preferências da V9.4.
            fileName = "SpeedUltraV9_4_2026",
            customFolder = "SpeedUltra"
        }
    })
end)

if not WindowCreateOk or not CreatedWindow then
    warn("[SPEED ULTRA V9.5] Falha ao criar a janela Rayfield: " .. tostring(CreatedWindow))
    ReleaseBootReservation()
    return
end

Window = CreatedWindow
Boot.window = Window
if not IsCurrentBoot() then
    pcall(function()
        if Window and type(Window.Destroy) == "function" then
            Window:Destroy()
        elseif Window and type(Window.Unload) == "function" then
            Window:Unload()
        end
    end)
    return
end

local HomeTab = Window:CreateTab({ name = "Início", icon = "house" })
local PerformanceTab = Window:CreateTab({ name = "Desempenho", icon = "gauge" })
local CarryTab = Window:CreateTab({ name = "Carry", icon = "package" })
local FarmTab = Window:CreateTab({ name = "Objetivos", icon = "egg" })
local EventTab = Window:CreateTab({ name = "Evento", icon = "calendar-days" })
local SettingsTab = Window:CreateTab({ name = "Interface", icon = "palette" })

HomeTab:CreateText({
    name = "SPEED ULTRA V9.5 • 2026",
    text = "Interface modernizada para celular. O painel monitora o personagem e oferece ajustes visuais locais reversíveis."
})

StatusText = HomeTab:CreateText({
    name = "Diagnóstico local",
    text = "Iniciando monitoramento..."
})

HomeTab:CreateText({
    name = "Sobre esta versão",
    text = "A otimização visual altera apenas propriedades gráficas locais selecionadas. O resultado depende dos efeitos existentes no mapa; a porcentagem é a intensidade configurada, não uma promessa de aumento de FPS."
})

-- Planejador manual de objetivos. Esta aba não controla movimento, interação,
-- teleporte ou coleta; serve apenas para registrar uma meta e mostrar uma dica.
local ManualGoal = "Ovo de maior valor (manual)"
local ObjectiveDescriptions = {
    ["Ovo de maior valor (manual)"] = "Compare os valores mostrados pelo próprio jogo e escolha o alvo manualmente. Não lê inventários ocultos nem calcula valores não expostos pela interface.",
    ["Ovo do evento (manual)"] = "Confira o bioma, a loja e os requisitos do evento dentro do jogo. Esta seleção só registra sua meta atual.",
    ["Ovo Enchanted Forest (manual)"] = "Meta manual para a Floresta Encantada. Guia comunitário relata uma missão de 20 ovos do bioma para o Wisp; confirme no painel do jogo.",
    ["Halloween Dimension Egg (manual)"] = "Meta manual para ovos da Halloween Dimension. Confirme preço, disponibilidade e recompensa diretamente na loja do evento.",
    ["Manor Key (manual)"] = "Rota comunitária relatada: Phantom Express até Forgotten Town, redemoinho verde e pesca subterrânea com Haunted Rod; depois use a chave na Manor Door. A chance de drop não está confirmada.",
}

FarmTab:CreateText({
    name = "Acompanhamento manual",
    text = "Organiza o objetivo escolhido e suas etapas. Não executa auto-farm, teleporte, coleta automática nem chamadas remotas de gameplay."
})

ObjectiveText = FarmTab:CreateText({
    name = "Objetivo e orientação",
    text = ObjectiveDescriptions[ManualGoal]
})

ObjectiveDropdown = FarmTab:CreateDropdown({
    name = "Escolher objetivo",
    description = "Escolha um objetivo para acompanhar manualmente.",
    options = {
        "Ovo de maior valor (manual)",
        "Ovo do evento (manual)",
        "Ovo Enchanted Forest (manual)",
        "Halloween Dimension Egg (manual)",
        "Manor Key (manual)",
    },
    value = ManualGoal,
    flag = "ManualObjectiveV94",
    callback = function(value)
        if type(value) ~= "string" then return end
        ManualGoal = value
        if ObjectiveText then
            pcall(function()
                ObjectiveText:Set(ObjectiveDescriptions[value] or "Objetivo selecionado. Consulte as instruções dentro do jogo.")
            end)
        end
    end
})

FarmTab:CreateToggle({
    name = "Etapa manual: objetivo conferido",
    description = "Marque depois de verificar o alvo na experiência.",
    value = false,
    flag = "ManualObjectiveConfirmedV94",
    callback = function(value) end
})

FarmTab:CreateToggle({
    name = "Etapa manual: ovo recolhido normalmente",
    description = "Apenas checklist; não aciona prompts nem eventos remotos.",
    value = false,
    flag = "ManualEggCollectedV94",
    callback = function(value) end
})

FarmTab:CreateToggle({
    name = "Etapa manual: retorno à base concluído",
    description = "Marque depois de concluir pessoalmente o transporte no jogo.",
    value = false,
    flag = "ManualEggReturnedV94",
    callback = function(value) end
})

OperationText = PerformanceTab:CreateText({
    name = "Resultado da otimização",
    text = "Pronto. Ative a otimização para iniciar uma varredura reversível."
})

VisualToggle = PerformanceTab:CreateToggle({
    name = "Otimização visual local",
    description = "Reduz os tipos de efeitos escolhidos; pode ser desfeita.",
    value = false,
    flag = "VisualOptimization",
    callback = function(value)
        if not State.UIReady or State.ControlsUpdating then
            State.VisualOptimization = value == true
            return
        end
        SetVisualOptimization(value)
    end
})

ReductionSlider = PerformanceTab:CreateSlider({
    name = "Intensidade da redução",
    description = "Percentual aplicado aos parâmetros selecionados; não representa ganho garantido de desempenho.",
    range = { 10, 70 },
    increment = 5,
    suffix = "%",
    value = Config.ReductionPercent,
    flag = "ReductionPercent",
    callback = function(value, dragging)
        if type(value) == "number" then
            Config.ReductionPercent = math.clamp(math.floor(value + 0.5), 10, 70)
            -- Rayfield Gen2 informa dragging=true enquanto o utilizador move
            -- o slider. Só reinicia a varredura quando ele solta o controle.
            if State.UIReady and not State.ControlsUpdating and State.VisualOptimization and not dragging then
                SetVisualOptimization(true)
            end
        end
    end
})

ParticlesToggle = PerformanceTab:CreateToggle({
    name = "Reduzir partículas",
    description = "Ajusta a taxa de emissão dos ParticleEmitter selecionados.",
    value = Config.OptimizeParticles,
    flag = "OptimizeParticles",
    callback = function(value)
        Config.OptimizeParticles = value == true
        if State.UIReady and not State.ControlsUpdating and State.VisualOptimization then
            SetVisualOptimization(true)
        end
    end
})

TrailsToggle = PerformanceTab:CreateToggle({
    name = "Reduzir trails",
    description = "Diminui o tempo dos segmentos dos Trails selecionados.",
    value = Config.OptimizeTrails,
    flag = "OptimizeTrails",
    callback = function(value)
        Config.OptimizeTrails = value == true
        if State.UIReady and not State.ControlsUpdating and State.VisualOptimization then
            SetVisualOptimization(true)
        end
    end
})

AtmosphericsToggle = PerformanceTab:CreateToggle({
    name = "Reduzir fumaça e fogo",
    description = "Diminui parâmetros visuais de Smoke e Fire.",
    value = Config.OptimizeAtmospherics,
    flag = "OptimizeAtmospherics",
    callback = function(value)
        Config.OptimizeAtmospherics = value == true
        if State.UIReady and not State.ControlsUpdating and State.VisualOptimization then
            SetVisualOptimization(true)
        end
    end
})

PostEffectsToggle = PerformanceTab:CreateToggle({
    name = "Desativar Blur / Depth of Field",
    description = "Quando a otimização estiver ativa, desliga esses dois pós-efeitos e guarda o estado original.",
    value = true,
    flag = "DisablePostEffects",
    callback = function(value)
        Config.DisablePostEffects = value == true
        if State.UIReady and not State.ControlsUpdating and State.VisualOptimization then
            SetVisualOptimization(true)
        end
    end
})

BeamsToggle = PerformanceTab:CreateToggle({
    name = "Reduzir espessura de Beam",
    description = "Reduz Width0/Width1 e restaura os valores originais quando desativado.",
    value = true,
    flag = "OptimizeBeams",
    callback = function(value)
        Config.OptimizeBeams = value == true
        if State.UIReady and not State.ControlsUpdating and State.VisualOptimization then
            SetVisualOptimization(true)
        end
    end
})

SparklesToggle = PerformanceTab:CreateToggle({
    name = "Desativar Sparkles",
    description = "Desativa temporariamente Sparkles e guarda o Enabled original.",
    value = false,
    flag = "DisableSparkles",
    callback = function(value)
        Config.DisableSparkles = value == true
        if State.UIReady and not State.ControlsUpdating and State.VisualOptimization then
            SetVisualOptimization(true)
        end
    end
})

BloomSunRaysToggle = PerformanceTab:CreateToggle({
    name = "Reduzir Bloom / SunRays",
    description = "Reduz a intensidade destes pós-efeitos sem desligá-los completamente.",
    value = true,
    flag = "ReduceBloomSunRays",
    callback = function(value)
        Config.ReduceBloomSunRays = value == true
        if State.UIReady and not State.ControlsUpdating and State.VisualOptimization then
            SetVisualOptimization(true)
        end
    end
})

FpsText = PerformanceTab:CreateText({
    name = "Monitor local",
    text = "FPS aproximado: calculando..."
})

PerformanceTab:CreateButton({
    name = "Restaurar efeitos visuais",
    description = "Desliga a otimização e tenta restaurar todas as propriedades guardadas.",
    callback = function()
        if VisualToggle then
            VisualToggle:Set(false)
        else
            SetVisualOptimization(false)
        end
    end
})

PerformanceTab:CreateButton({
    name = "Reexaminar efeitos",
    description = "Reaplica as opções atuais em uma nova varredura incremental.",
    callback = function()
        if State.VisualOptimization then
            SetVisualOptimization(true)
        else
            UpdateOperationStatus("Ative primeiro a otimização visual para reexaminar os efeitos.")
        end
    end
})

EventTab:CreateText({
    name = "Update 10 — Halloween Part 2 (24/10/2026)",
    text = "Fonte comunitária consultada em 25/10/2026; não é documentação oficial do desenvolvedor. O Update 10 relata Abandoned Manor, Manor Key, a luta Pumpkin Brute → Pumpkin King e a fusão Cursed Monarch Divine. Uma fonte comunitária lista a janela da Part 2 até 25/10/2026 16:34 UTC (13:34 em Brasília), mas confirme a disponibilidade no próprio jogo; nomes e mecânicas podem estar incompletos."
})

EventTab:CreateText({
    name = "Manor Key — rota relatada",
    text = "1) Tenha acesso ao Phantom Express. 2) Vá a Forgotten Town. 3) Entre no redemoinho verde. 4) Pesque na área subterrânea com Haunted Rod até obter Manor Key. 5) Volte à Abandoned Manor e interaja com a Manor Door acorrentada. A chave não garante abrir o portal do chefe: são entradas distintas. A chance de drop não foi confirmada."
})

EventTab:CreateToggle({
    name = "Etapa: acesso ao Phantom Express verificado",
    description = "Checklist manual persistente.", value = false,
    flag = "V94_Halloween_PhantomExpress", callback = function(value) end
})
EventTab:CreateToggle({
    name = "Etapa: Manor Key obtida",
    description = "Marque depois de confirmar o item no inventário.", value = false,
    flag = "V94_Halloween_ManorKey", callback = function(value) end
})
EventTab:CreateToggle({
    name = "Etapa: Manor Door aberta",
    description = "Não confunda a porta da mansão com o portal do chefe.", value = false,
    flag = "V94_Halloween_ManorDoor", callback = function(value) end
})

EventTab:CreateText({
    name = "Chefe e Boss Mastery",
    text = "O guia comunitário descreve uma luta em duas fases: Pumpkin Brute seguida de Pumpkin King. Ele relata 1 Boss Kill = 1 Mastery e 65 tiers; confira o contador e resgate recompensas dentro do jogo. Nenhuma chance do drop Divine foi confirmada."
})
EventTab:CreateToggle({
    name = "Etapa: vitória e recompensa conferidas",
    description = "Marque só depois de verificar o contador/recompensa no jogo.", value = false,
    flag = "V94_Halloween_BossMastery", callback = function(value) end
})

EventTab:CreateText({
    name = "Cursed Monarch Divine — receita relatada",
    text = "Guia independente mostra 2 Ghost Fish — Eternal e 2 Voidseer Pumpkin — Divine no altar da mansão. O consumo dos itens, a distribuição entre jogadores e a possibilidade de fazer solo não estão confirmados; confira o altar antes de usar itens raros."
})
EventTab:CreateToggle({
    name = "Etapa: receita conferida diretamente no altar",
    description = "A checklist não executa fusões nem consome itens.", value = false,
    flag = "V94_Halloween_FusionRecipe", callback = function(value) end
})

EventTab:CreateText({
    name = "Perfil visual do evento",
    text = "O preset abaixo ajusta efeitos visuais locais. Não movimenta o personagem nem executa coleta/teleporte automáticos."
})

EventTab:CreateButton({
    name = "Ativar perfil Halloween Part 2",
    description = "Aplica um preset visual local de 50%; pode ser desfeito.",
    callback = function()
        State.ControlsUpdating = true
        Config.ReductionPercent = 50
        Config.DisablePostEffects = true
        Config.OptimizeBeams = true
        Config.DisableSparkles = true
        Config.ReduceBloomSunRays = true
        if ReductionSlider then pcall(function() ReductionSlider:Set(50) end) end
        if ParticlesToggle then pcall(function() ParticlesToggle:Set(true) end) end
        if TrailsToggle then pcall(function() TrailsToggle:Set(true) end) end
        if AtmosphericsToggle then pcall(function() AtmosphericsToggle:Set(true) end) end
        if PostEffectsToggle then pcall(function() PostEffectsToggle:Set(true) end) end
        if BeamsToggle then pcall(function() BeamsToggle:Set(true) end) end
        if SparklesToggle then pcall(function() SparklesToggle:Set(true) end) end
        if BloomSunRaysToggle then pcall(function() BloomSunRaysToggle:Set(true) end) end
        if VisualToggle then pcall(function() VisualToggle:Set(true) end) end
        State.ControlsUpdating = false
        SetVisualOptimization(true)
    end
})

EventTab:CreateButton({
    name = "Restaurar visual original",
    description = "Desativa o perfil e restaura as propriedades visuais guardadas.",
    callback = function()
        State.ControlsUpdating = true
        if VisualToggle then pcall(function() VisualToggle:Set(false) end) end
        State.ControlsUpdating = false
        SetVisualOptimization(false)
    end
})

CarryTab:CreateText({
    name = "Monitor do carry",
    text = "O monitor é somente de leitura. Ele tenta identificar atributos, tags e constraints comuns, mas cada jogo pode usar um sistema diferente."
})

local CarryStatusText = CarryTab:CreateText({
    name = "Estado detectado",
    text = "Aguardando primeira leitura..."
})

CarryTab:CreateToggle({
    name = "Monitorar carry",
    description = "Consulta possíveis marcadores do personagem sem modificar objetos ou física.",
    value = true,
    flag = "MonitorCarry",
    callback = function(value)
        State.MonitorCarry = value == true
        if not State.MonitorCarry then
            State.LastCarryDetected = false
            State.LastCarryObject = nil
            if CarryStatusText then
                CarryStatusText:Set("Monitoramento desativado.")
            end
        end
    end
})

SettingsTab:CreateText({
    name = "Tema e preferências",
    text = "O Rayfield guarda as opções com suporte à configuração do ambiente. Em certos executores, o salvamento persistente pode depender das permissões de arquivo disponíveis."
})

SettingsTab:CreateText({
    name = "Instância única / recarga limpa",
    text = "Ao executar o script novamente, a execução anterior é invalidada, os monitores são desconectados, as propriedades visuais salvas são restauradas e a janela antiga é fechada antes de a nova sessão continuar. Se a primeira execução ainda estiver carregando a UI, ela verifica o token e aborta quando retoma."
})

SettingsTab:CreateText({
    name = "Aviso de segurança da conta",
    text = "Este script NÃO tem Anti-Ban e não tenta ocultar execução nem contornar o anti-cheat. Nenhuma opção local pode garantir imunidade a suspensão. A instância única evita abas duplicadas e conflitos locais; não reduz nem remove o risco relacionado ao uso de clientes modificados ou executores."
})

DeviceText = SettingsTab:CreateText({
    name = "Dispositivo",
    text = "Aguardando informações locais..."
})

SettingsTab:CreateButton({
    name = "Tema roxo (Amethyst)",
    callback = function()
        pcall(function()
            Window:ChangeTheme("amethyst")
        end)
    end
})

SettingsTab:CreateButton({
    name = "Tema carmesim (Rose)",
    callback = function()
        pcall(function()
            Window:ChangeTheme("rose")
        end)
    end
})

SettingsTab:CreateButton({
    name = "Encerrar e restaurar",
    description = "Fecha a interface, encerra os monitores e restaura as propriedades visuais salvas.",
    callback = function()
        local cleanup = Env[REGISTRY_KEY]
        if type(cleanup) == "function" then
            cleanup("USER_UNLOAD")
        end
    end
})

-- Se outra execução começou enquanto a UI estava sendo construída, não conecte monitores.
if not IsCurrentBoot() then
    pcall(function()
        if Window and type(Window.Destroy) == "function" then
            Window:Destroy()
        elseif Window and type(Window.Unload) == "function" then
            Window:Unload()
        end
    end)
    return
end

-- Registra os eventos de efeitos somente depois de a UI ter sido construída.
AddConnection(Workspace.DescendantAdded:Connect(OnVisualDescendantAdded))
AddConnection(Lighting.DescendantAdded:Connect(OnVisualDescendantAdded))

-- Os listeners estão conectados; o início de uma otimização restaurada pela configuração
-- acontece depois que todos os controles foram criados e State.UIReady foi ativado.

-- =========================================================
-- MONITOR PRINCIPAL
-- =========================================================

local function RefreshCharacterReferences()
    local character = Player.Character
    State.CurrentCharacter = character
    State.CurrentHumanoid = nil
    State.CurrentRoot = nil

    if not character then
        return
    end

    pcall(function()
        State.CurrentHumanoid = character:FindFirstChildOfClass("Humanoid")
        State.CurrentRoot = character:FindFirstChild("HumanoidRootPart")
    end)
end

local function BuildDiagnosticText()
    RefreshCharacterReferences()

    local character = State.CurrentCharacter
    local humanoid = State.CurrentHumanoid
    local root = State.CurrentRoot

    if not character then
        return "Personagem: aguardando spawn\nFPS aproximado: " .. tostring(State.Stats.FPS) .. "\nOtimização visual: " .. (State.VisualOptimization and "ATIVA" or "DESATIVADA")
    end

    local healthText = "indisponível"
    local speedText = "indisponível"

    if humanoid and humanoid.Parent then
        pcall(function()
            healthText = string.format("%.0f / %.0f", humanoid.Health, humanoid.MaxHealth)
            speedText = string.format("%.1f", humanoid.WalkSpeed)
        end)
    end

    local rootText = (root and root.Parent) and "OK" or "aguardando"
    local optimizationText = State.Optimizing and "PROCESSANDO" or (State.VisualOptimization and "ATIVA" or "DESATIVADA")

    return string.format(
        "Personagem: OK\nHumanoid: %s\nSaúde: %s\nWalkSpeed (leitura): %s\nRootPart: %s\nFPS aproximado: %d\nOtimização visual: %s",
        (humanoid and humanoid.Parent) and "OK" or "aguardando",
        healthText,
        speedText,
        rootText,
        State.Stats.FPS,
        optimizationText
    )
end

AddConnection(Player.CharacterAdded:Connect(function()
    task.wait(0.25)
    RefreshCharacterReferences()
end))

AddConnection(Player.CharacterRemoving:Connect(function()
    State.CurrentCharacter = nil
    State.CurrentHumanoid = nil
    State.CurrentRoot = nil
end))

-- Medição aproximada de quadros por segundo. Não representa FPS garantido nem ping.
local fpsFrames = 0
local fpsWindowStart = os.clock()
AddConnection(RunService.RenderStepped:Connect(function()
    if not State.Alive then
        return
    end

    fpsFrames += 1
    local now = os.clock()
    local elapsed = now - fpsWindowStart
    if elapsed >= 1 then
        State.Stats.FPS = math.clamp(math.floor((fpsFrames / elapsed) + 0.5), 0, 1000)
        State.Stats.FPSUpdatedAt = now
        fpsFrames = 0
        fpsWindowStart = now

        if FpsText then
            pcall(function()
                FpsText:Set(string.format("FPS aproximado (RenderStepped): %d\nNão é uma medição de ping nem uma garantia de desempenho.", State.Stats.FPS))
            end)
        end
    end
end))

local function RefreshDeviceText()
    if not DeviceText then
        return
    end

    local touch = "indisponível"
    local cameraText = "indisponível"
    pcall(function()
        touch = UserInputService.TouchEnabled and "Toque detectado" or "Sem toque detectado"
    end)
    pcall(function()
        local camera = Workspace.CurrentCamera
        if camera then
            local viewport = camera.ViewportSize
            cameraText = string.format("%d × %d", math.floor(viewport.X), math.floor(viewport.Y))
        end
    end)

    pcall(function()
        DeviceText:Set("Entrada: " .. touch .. "\nResolução da viewport: " .. cameraText)
    end)
end

RefreshDeviceText()
AddConnection(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    task.defer(RefreshDeviceText)
end))

task.spawn(function()
    while State.Alive do
        task.wait(Config.CarryMonitorInterval)
        if not State.Alive then
            break
        end

        UpdateStatus(BuildDiagnosticText())

        if State.MonitorCarry and CarryStatusText then
            local carrying, object = false, nil
            local ok = pcall(function()
                carrying, object = DetectCarryMarker()
            end)

            if ok and carrying then
                State.LastCarryDetected = true
                State.LastCarryObject = object
                local objectName = "objeto não identificado"
                pcall(function()
                    objectName = object.Name
                end)
                CarryStatusText:Set("Possível carry detectado: " .. tostring(objectName) .. "\nA detecção é experimental e depende dos marcadores usados pelo jogo.")
            elseif ok then
                State.LastCarryDetected = false
                State.LastCarryObject = nil
                CarryStatusText:Set("Nenhum marcador de carry detectado.\nIsso não garante que o jogo não esteja transportando um objeto.")
            else
                CarryStatusText:Set("Não foi possível ler os marcadores de carry nesta atualização.")
            end
        end
    end
end)

-- =========================================================
-- LIMPEZA / AUTODESTRUIÇÃO
-- =========================================================

local function Cleanup(reason)
    if State.Cleaning then
        return
    end

    State.Cleaning = true
    State.Alive = false
    State.VisualOptimization = false
    State.OptimizeToken += 1
    State.Optimizing = false
    State.CollectingPending = false

    pcall(RestoreVisualProperties)
    DisconnectAll()

    if Env[REGISTRY_KEY] == Cleanup then
        Env[REGISTRY_KEY] = nil
    end
    if Boot.cleanup == Cleanup then
        Boot.cleanup = nil
    end
    if Env[BOOT_KEY] == Boot then
        Boot.cancelled = true
        Env[BOOT_KEY] = nil
    end

    pcall(function()
        if Window and type(Window.Destroy) == "function" then
            Window:Destroy()
        elseif Window and type(Window.Unload) == "function" then
            Window:Unload()
        elseif type(Rayfield.Destroy) == "function" then
            Rayfield:Destroy()
        end
    end)

    if reason and reason ~= "USER_UNLOAD" and reason ~= "RELOAD" then
        warn("[SPEED ULTRA V9.5] Encerrado: " .. tostring(reason))
    end
end

Boot.cleanup = Cleanup
Env[REGISTRY_KEY] = Cleanup

RefreshCharacterReferences()
UpdateStatus(BuildDiagnosticText())

State.UIReady = true
if State.VisualOptimization then
    SetVisualOptimization(true)
end

print("[SPEED ULTRA V9.5] Inicializado com Rayfield Gen2; instância única ativa.")
