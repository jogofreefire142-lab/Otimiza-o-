--[[
    SPEED ULTRA V11.0 — 2026
    Refatoração auditada: leitura de Speed separada de WalkSpeed e diagnóstico de objetos para o detector.
    Código único para o Roube um Ovo: ovos/ESP informativo, acompanhamento de eventos,
    leitura local de Speed e otimização visual reversível; mantém a interface existente.
    Revisão de catálogo/evento em 26/10/2026 a partir da página Roblox e guias comunitários.
    Repositórios que prometem auto-farm foram tratados como referência não verificada quando
    não publicam o arquivo executável; não foram copiados teleportes nem remotes de roubo.

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
      • ESP visual de ovos reconhecidos, com nome/raridade/distância e contorno occlusion-safe;
      • agendamento único para detector/ESP, com limpeza dos marcadores ao desligar ou encerrar;
      • controle de intensidade que evita reiniciar a varredura a cada movimento;
      • token de inicialização antecipado para não abrir abas duplicadas ao reexecutar;
      • restauração/encerramento da sessão anterior e verificação do token após esperas;
      • aviso explícito de que não existe modo Anti-Ban implementado nem garantia contra punições;
      • abas reorganizadas e atalhos para ações frequentes;
      • leitura recursiva da estatística Speed e meta de acompanhamento; controle WalkSpeed separado para projeto próprio (8–1000 via servidor autorizado);

    Nota: o ESP só destaca ovos identificáveis que a busca já vê; não lê dados ocultos. O botão de diagnóstico ajuda a mapear nomes/caminhos reais quando o detector não encontra o objeto.
    Não altera WalkSpeed, colisões, massa ou física do jogo público. O limite 1000 só é aceito pelo script de servidor autorizado incluído no final deste TXT para uma experiência própria; ele não cria um RemoteEvent no Roube um Ovo oficial. Não automatiza coleta,
    teleporte ou interação em servidores públicos. Para mecânicas de movimento
    e entrega de ovos num jogo próprio, implemente a lógica autorizada no servidor.
    Segurança: a instância única é proteção contra conflito local, NÃO é Anti-Ban.
    O seletor de velocidade não altera jogos públicos: só envia uma solicitação ao
    RemoteEvent documentado no script de servidor fornecido separadamente, com lista
    de autorização. Sem esse servidor no seu próprio jogo, a opção explica que está indisponível.
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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

    local compileOk, chunkOrError, compileMessage = pcall(loadstring, source)
    if not compileOk then
        error("Falha no compilador ao carregar Rayfield Gen2: " .. tostring(chunkOrError))
    end
    if type(chunkOrError) ~= "function" then
        error("A fonte remota não compilou para uma função: " .. tostring(compileMessage or chunkOrError))
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
    warn("[SPEED ULTRA V11.0] Não foi possível carregar Rayfield Gen2: " .. tostring(loadResult))
    ReleaseBootReservation()
    return
end

if type(Rayfield) ~= "table" or type(Rayfield.CreateWindow) ~= "function" then
    warn("[SPEED ULTRA V11.0] Rayfield Gen2 não retornou uma API válida; a interface não foi iniciada.")
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
    ScanBudgetObjects = 60,
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
local CarryStatusText
local SpeedStatusText
local CurrentSpeedText
local SpeedGoalText
local SpeedGoalInput
local SpeedSlider
local RefreshSpeedReadout -- forward declaration so UI callbacks can call it safely
local UpdateSpeedGoalDisplay
local CurrentGameSpeedValue = nil
local CurrentGameSpeedPath = nil
local DesiredGameSpeedGoal = 2500000
local RuntimeDiagnosticsText
local EggScanText
local EggScanRangeSlider
local EggScanAutoToggle
local EggScanAutoEnabled = false
local EggScanRunning = false
local EggScanToken = 0
local EggScanRange = 120
local DesiredProjectSpeed = 16
local SpeedRequestPending = false
local SpeedRequestSerial = 0
local RestoreVisualProperties
local ClearEggEspVisuals
local EggEspStatusText
local EggDiagnosticText
local EggDiagnosticRunning = false
local EggEspEnabled = false
local EggEspObjects = setmetatable({}, { __mode = "k" })
local EggScanSchedulerToken = 0
local SPEED_REQUEST_REMOTE = "SpeedUltraAuthorizedSpeedRequest"
local SPEED_RESULT_REMOTE = "SpeedUltraAuthorizedSpeedResult"
local SpeedResultBound = false

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

-- Cleanup provisório: fica registrado antes da construção da interface. Se uma
-- segunda execução chegar durante a inicialização, esta rotina cancela workers,
-- desconecta listeners já criados e fecha a janela parcial.
local function EarlyCleanup(reason)
    if State.Cleaning then
        -- Idempotência: mesmo em chamadas repetidas, não deixe conexões residuais.
        DisconnectAll()
        return
    end

    State.Cleaning = true
    State.Alive = false
    EggScanAutoEnabled = false
    EggEspEnabled = false
    EggScanToken += 1
    EggScanSchedulerToken += 1
    if ClearEggEspVisuals then pcall(ClearEggEspVisuals) end
    State.VisualOptimization = false
    State.OptimizeToken += 1
    State.Optimizing = false
    State.CollectingPending = false

    if RestoreVisualProperties then
        pcall(RestoreVisualProperties)
    end
    DisconnectAll()

    if Env[REGISTRY_KEY] == EarlyCleanup then
        Env[REGISTRY_KEY] = nil
    end
    if Boot.cleanup == EarlyCleanup then
        Boot.cleanup = nil
    end
    if Env[BOOT_KEY] == Boot then
        Boot.cancelled = true
        Env[BOOT_KEY] = nil
    end

    pcall(function()
        local target = Window or Boot.window
        if target and type(target.Destroy) == "function" then
            target:Destroy()
        elseif target and type(target.Unload) == "function" then
            target:Unload()
        end
    end)
end

Boot.cleanup = EarlyCleanup
Env[REGISTRY_KEY] = EarlyCleanup

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

local function UpdateSpeedStatus(text)
    if not State.Alive or not SpeedStatusText then
        return
    end
    pcall(function()
        SpeedStatusText:Set(text)
    end)
end

UpdateSpeedGoalDisplay = function()
    if not SpeedGoalText or not State.Alive then return end
    local target = math.max(0, math.floor(tonumber(DesiredGameSpeedGoal) or 0))
    local current = CurrentGameSpeedValue
    local message
    if type(current) ~= "number" then
        message = string.format(
            "Meta escolhida: %.0f Speed\nAinda não encontrei a estatística real do jogo no cliente. Isso pode significar que ela não é replicada como Value/atributo ou que o nome mudou.",
            target
        )
    elseif current >= target then
        message = string.format(
            "Speed atual detectada: %.0f\nMeta: %.0f\nMeta atingida. Fonte: %s",
            current, target, tostring(CurrentGameSpeedPath or "origem não identificada")
        )
    else
        message = string.format(
            "Speed atual detectada: %.0f\nMeta: %.0f\nFaltam: %.0f Speed\nFonte: %s",
            current, target, target - current, tostring(CurrentGameSpeedPath or "origem não identificada")
        )
    end
    pcall(function() SpeedGoalText:Set(message) end)
end

local function BindSpeedResultRemote()
    if SpeedResultBound then
        return
    end

    local remote = ReplicatedStorage:FindFirstChild(SPEED_RESULT_REMOTE)
    if not remote or not remote:IsA("RemoteEvent") then
        return
    end

    SpeedResultBound = true
    AddConnection(remote.OnClientEvent:Connect(function(success, appliedSpeed, message)
        if not State.Alive then
            return
        end

        SpeedRequestPending = false
        SpeedRequestSerial += 1 -- invalida qualquer temporizador de timeout pendente
        if success == true and type(appliedSpeed) == "number" then
            UpdateSpeedStatus(string.format("CONFIRMADO PELO SERVIDOR: %.0f studs/s. %s", appliedSpeed, tostring(message or "")))
        else
            UpdateSpeedStatus("PEDIDO RECUSADO: " .. tostring(message or "sem detalhe"))
        end
    end))
end

local function RequestProjectSpeed(speed)
    if not State.Alive or not IsCurrentBoot() then
        return
    end
    if SpeedRequestPending then
        UpdateSpeedStatus("Já existe um pedido aguardando resposta. Espere a confirmação ou o aviso de timeout.")
        return
    end

    local normalized = tonumber(speed)
    if not normalized or normalized ~= normalized or normalized == math.huge or normalized == -math.huge then
        UpdateSpeedStatus("Valor inválido. Escolha entre 8 e 1000.")
        return
    end
    normalized = math.clamp(math.floor(normalized + 0.5), 8, 1000)

    local remote = ReplicatedStorage:FindFirstChild(SPEED_REQUEST_REMOTE)
    if not remote or not remote:IsA("RemoteEvent") then
        UpdateSpeedStatus("INDISPONÍVEL: falta o RemoteEvent do servidor no seu próprio jogo. Esta opção não altera Roube um Ovo público.")
        return
    end

    BindSpeedResultRemote()
    SpeedRequestSerial += 1
    local requestSerial = SpeedRequestSerial
    SpeedRequestPending = true

    local ok, err = pcall(function()
        remote:FireServer(normalized)
    end)
    if not ok then
        SpeedRequestPending = false
        UpdateSpeedStatus("FALHA AO ENVIAR: " .. tostring(err))
        return
    end

    UpdateSpeedStatus(string.format("Pedido de %.0f studs/s enviado; aguardando confirmação do servidor...", normalized))
    task.delay(4, function()
        if State.Alive and SpeedRequestPending and SpeedRequestSerial == requestSerial then
            SpeedRequestPending = false
            UpdateSpeedStatus("SEM CONFIRMAÇÃO após 4 s. Verifique se o Script de servidor está em ServerScriptService e se você está autorizado.")
        end
    end)
end

-- Liga o retorno do servidor mesmo se os RemoteEvents forem replicados após a UI.
AddConnection(ReplicatedStorage.ChildAdded:Connect(function(child)
    if child.Name == SPEED_RESULT_REMOTE and child:IsA("RemoteEvent") then
        task.defer(BindSpeedResultRemote)
    end
end))

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

RestoreVisualProperties = function()
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


-- Agrupa mudanças de controles próximas para evitar reiniciar a varredura visual
-- várias vezes em sequência. A lógica visual original permanece intacta.
local VisualRebuildSerial = 0
local function ScheduleVisualRebuild()
    VisualRebuildSerial += 1
    local serial = VisualRebuildSerial
    task.delay(0.20, function()
        if State.Alive and serial == VisualRebuildSerial and State.VisualOptimization then
            SetVisualOptimization(true)
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
        name = "SPEED ULTRA V11.0",
        subtitle = "2026 • Mobile Edition • V11.0",
        sidebarLayout = true,
        theme = "amethyst",
        showName = "SPEED ULTRA",
        showIconOnly = false,
        configuration = {
            autoSave = true,
            autoLoad = true,
            -- Nome estável mantido para reaproveitar as preferências salvas anteriormente.
            fileName = "SpeedUltraV9_4_2026",
            customFolder = "SpeedUltra"
        }
    })
end)

if not WindowCreateOk or not CreatedWindow then
    warn("[SPEED ULTRA V11.0] Falha ao criar a janela Rayfield: " .. tostring(CreatedWindow))
    ReleaseBootReservation()
    return
end

Window = CreatedWindow
Boot.window = Window
if not IsCurrentBoot() then
    State.Alive = false
    State.OptimizeToken += 1
    pcall(function()
        if RestoreVisualProperties then RestoreVisualProperties() end
    end)
    DisconnectAll()
    pcall(function()
        if Window and type(Window.Destroy) == "function" then
            Window:Destroy()
        elseif Window and type(Window.Unload) == "function" then
            Window:Unload()
        end
    end)
    return
end

-- =========================================================
-- DETECTOR INFORMATIVO DE OVOS PRÓXIMOS (SOMENTE LEITURA)
-- Uma busca manual por vez; atualização automática é opcional e vem desligada.
-- Só lista objetos cujo nome/metadados parecem indicar ovo, dentro da câmera,
-- do raio selecionado e com linha de visão aproximada. Não interage com o jogo.
-- =========================================================
local EggCatalog = {
    -- Nomes/biomas de referência. Lista conferida em guia comunitário atualizado em 26/10/2026;
    -- requisitos e disponibilidade podem mudar e devem ser confirmados no jogo.
    { key = "chicken egg", name = "Chicken Egg", hint = "Forest / área inicial; listado no índice comunitário como ovo do Forest Guardian." },
    { key = "swan egg", name = "Swan Egg", hint = "Lake: guia comunitário lista requisito de 900 Speed; confirme o portal/guardião no jogo." },
    { key = "scorpion egg", name = "Scorpion Egg", hint = "Desert: guia comunitário lista requisito de 10.000 Speed; confirme no jogo." },
    { key = "tiger egg", name = "Tiger Egg", hint = "Jungle: guia comunitário lista requisito de 40.000 Speed; confirme no jogo." },
    { key = "yeti egg", name = "Yeti Egg", hint = "Snow: guia comunitário lista requisito de 170.000 Speed; confirme no jogo." },
    { key = "hellhound egg", name = "Hellhound Egg", hint = "Volcano: guia comunitário lista requisito de 700.000 Speed; confirme no jogo." },
    { key = "chicken", name = "Chicken / Forest", hint = "Pet Index comunitário: Chicken aparece como Common; $1/s foi observado na ficha, não é raridade do ovo." },
    { key = "bird", name = "Bird / Forest", hint = "Nome no índice comunitário parcial; raridade e renda não confirmadas na fonte consultada." },
    { key = "owl", name = "Owl / Forest", hint = "Nome no índice comunitário parcial; raridade e renda não confirmadas na fonte consultada." },
    { key = "raccoon", name = "Raccoon / Forest", hint = "Nome no índice comunitário parcial; raridade e renda não confirmadas na fonte consultada." },
    { key = "frog", name = "Frog / Lake", hint = "Primeiro nome visível no índice comunitário parcial de Lake; confirme o rótulo do modelo no jogo." },
    { key = "tiger", name = "Tiger / Jungle", hint = "Perseguição na região Jungle é relatada em gameplay comunitário; não inferir preço nem raridade." },
    { key = "yeti", name = "Yeti / área de gelo", hint = "Nome associado à área de gelo/Yeti em guias de gameplay; confirme a identificação dentro da experiência." },
    { key = "scorpion", name = "Scorpion / Volcano (relato)", hint = "Um relato comunitário associa um alvo em escala de escorpião a Volcano; não é confirmação de um ovo com esse nome." },
    { key = "whale", name = "Whale / Abyss Ocean (relato)", hint = "Guia comunitário relata ovos em escala de baleia na área Abyss Ocean; o nome exato do ovo não foi confirmado." },
    { key = "t-rex", name = "T-Rex / Prehistoric", hint = "Alvo dinossauro/T-Rex relatado em gameplay da região Prehistoric; confira o nome exato exibido pelo jogo." },
    { key = "cosmic king", name = "Cosmic King / região final", hint = "Nome da região final relatado pela comunidade; os requisitos variam e não devem ser tratados como fixos." },
    { key = "cherry blossom egg", name = "Cherry Blossom Egg", hint = "Conteúdo do Update 1 segundo ao histórico comunitário de atualizações; disponibilidade atual a confirmar." },
    { key = "monster egg", name = "Monster Egg", hint = "Associado ao Update 2/Titan Temple em histórico comunitário; confira loja e rótulo atuais." },
    { key = "rift egg", name = "Rift Egg", hint = "Associado ao Update 3/Rifts em histórico comunitário; preço e disponibilidade não são fixados aqui." },
    { key = "luminous egg", name = "Luminous Egg", hint = "Associado ao Update 4/Angels vs Demons em guias comunitários; confirme no jogo." },
    { key = "experiment #001", name = "Experiment #001", hint = "Update 5/Samples e Experiment Shop em guia comunitário; confirmação e custo dependem da loja atual." },
    { key = "experiment #013", name = "Experiment #013", hint = "Update 5/Samples e Experiment Shop em guia comunitário; confirmação e custo dependem da loja atual." },
    { key = "extinction egg", name = "Extinction Egg", hint = "Associado ao Update 6/Dr. Scramble's Revenge em histórico comunitário; confirme o requisito na experiência." },
    { key = "enchanted forest", name = "Enchanted Forest", hint = "Update 7; guias comunitários descrevem Wisp e Butterfly Bloom. Não representa uma raridade de ovo." },
    { key = "halloween dimension egg", name = "Halloween Dimension Egg", hint = "Ovo do evento Halloween comprado com Candy Corn segundo registro comunitário; o calendário da Part 2 terminou em 25/10/2026." },
    { key = "halloween egg", name = "Halloween Egg", hint = "Ovo separado do Halloween Dimension Egg; guias comunitários descrevem a loja/loja Robux. Confirme se ainda está acessível." },
    { key = "candy corn", name = "Candy Corn", hint = "Pode designar a moeda do Halloween ou um pet do Halloween Dimension Egg; confira o contexto do rótulo no jogo." },
    { key = "hollow bat", name = "Hollow Bat", hint = "Nome listado em guia comunitário do Halloween Dimension Egg; chance/preço devem ser confirmados no painel atual." },
    { key = "scarecrow", name = "Scarecrow", hint = "Nome listado em guia comunitário do Halloween Dimension Egg; chance/preço devem ser confirmados no painel atual." },
    { key = "pumpkin golem", name = "Pumpkin Golem", hint = "Nome listado em guia comunitário do Halloween Dimension Egg; chance/preço devem ser confirmados no painel atual." },
    { key = "soul phantom", name = "Soul Phantom", hint = "Nome listado em guia comunitário do Halloween Dimension Egg; chance/preço devem ser confirmados no painel atual." },
}

local function LowerText(value)
    return string.lower(tostring(value or ""))
end

local function EggNameHint(object)
    local result = ""
    pcall(function() result = tostring(object.Name or "") end)
    local displayAttributes = { "DisplayName", "EggName", "EggType" }
    for _, attributeName in ipairs(displayAttributes) do
        local value
        pcall(function() value = object:GetAttribute(attributeName) end)
        if type(value) == "string" and value ~= "" then
            result = value
            break
        end
    end
    return result
end

local function NormalizeCatalogText(value)
    return LowerText(value):gsub("[^%w]", "")
end

local function MatchesEggCatalogName(value)
    local name = LowerText(value)
    local compactName = NormalizeCatalogText(value)
    if name == "" or compactName == "" then return false end
    for _, entry in ipairs(EggCatalog) do
        local key = LowerText(entry.key)
        local normalizedKey = key:gsub("%s+event egg$", ""):gsub("%s+egg$", "")
        local compactKey = NormalizeCatalogText(key)
        local compactNormalizedKey = NormalizeCatalogText(normalizedKey)
        if key ~= "" and string.find(name, key, 1, true) then
            return true
        end
        if compactKey ~= "" and string.find(compactName, compactKey, 1, true) then
            return true
        end
        if #compactNormalizedKey >= 4
            and string.find(compactName, compactNormalizedKey, 1, true) then
            return true
        end
    end
    return false
end

local function HasEggMarker(object)
    if not object then return false end
    local name = LowerText(object.Name)
    if string.find(name, "egg", 1, true) or string.find(name, "ovo", 1, true) then
        return true
    end

    local isEgg, eggName, eggType
    pcall(function()
        isEgg = object:GetAttribute("IsEgg")
        eggName = object:GetAttribute("EggName")
        eggType = object:GetAttribute("EggType")
    end)
    if isEgg == true or (type(eggName) == "string" and eggName ~= "")
        or (type(eggType) == "string" and eggType ~= "") then
        return true
    end

    -- Primeiro, aceita modelos dentro de pastas explicitamente chamadas Eggs/Ovos.
    -- Isso evita depender exclusivamente do nome da peça individual.
    local parent = object.Parent
    for _ = 1, 6 do
        if not parent or parent == Workspace then break end
        local parentName = LowerText(parent.Name)
        local parentIsContainer = false
        pcall(function() parentIsContainer = parent:IsA("Folder") end)
        if parentIsContainer and (parentName == "eggs" or parentName == "ovo"
            or parentName == "ovos" or parentName == "fieldeggs"
            or parentName == "field_eggs" or parentName == "eggspawns"
            or parentName == "egg_spawns") then
            return true
        end
        parent = parent.Parent
    end

    -- Alguns modelos de campo são nomeados pelo animal, dentro de EggWorld/FieldEggs.
    -- Só trata como candidato se o nome corresponder ao catálogo e houver um contêiner conhecido.
    local current = object
    local hasKnownModelName = false
    for _ = 1, 8 do
        if not current or current == Workspace then break end
        local isModel = false
        pcall(function() isModel = current:IsA("Model") end)
        if isModel and MatchesEggCatalogName(EggNameHint(current)) then
            hasKnownModelName = true
            break
        end
        current = current.Parent
    end
    if hasKnownModelName then
        parent = object.Parent
        for _ = 1, 8 do
            if not parent or parent == Workspace then break end
            local parentName = LowerText(parent.Name)
            if parentName == "eggworld" or parentName == "field_egg" or parentName == "fieldeggs"
                or parentName == "field_eggs" or parentName == "egg_spawns" or parentName == "eggspawns" then
                return true
            end
            parent = parent.Parent
        end
    end
    return false
end

local function ResolveEggCandidate(object)
    local current = object
    local partCandidate = nil
    for _ = 1, 8 do
        if not current or current == Workspace then break end
        local classIsModel, classIsPart = false, false
        pcall(function()
            classIsModel = current:IsA("Model")
            classIsPart = current:IsA("BasePart")
        end)
        if (classIsModel or classIsPart) and HasEggMarker(current) then
            if classIsModel then return current end
            if not partCandidate then partCandidate = current end
        end
        current = current.Parent
    end
    return partCandidate
end

local function EggWorldPosition(object)
    local position
    local ok = pcall(function()
        if object:IsA("Model") then
            position = object:GetPivot().Position
        elseif object:IsA("BasePart") then
            position = object.Position
        end
    end)
    if ok then return position end
    return nil
end

local function EggRarityHint(object, displayName)
    local rarity
    pcall(function() rarity = object:GetAttribute("Rarity") end)
    if type(rarity) == "string" and rarity ~= "" then
        return rarity .. " (atributo visível)"
    end
    local name = LowerText(displayName)
    for _, label in ipairs({ "secret", "eternal", "divine", "mythic", "mythical", "legendary", "epic", "rare", "common" }) do
        if string.find(name, label, 1, true) then return label:gsub("^%l", string.upper) .. " (inferido do nome)" end
    end
    return "raridade não exposta"
end

local function EggCatalogHint(displayName)
    local name = LowerText(displayName)
    local compactName = NormalizeCatalogText(displayName)
    for _, entry in ipairs(EggCatalog) do
        local key = LowerText(entry.key)
        local speciesKey = key:gsub("%s+event egg$", ""):gsub("%s+egg$", "")
        local compactKey = NormalizeCatalogText(key)
        local compactSpecies = NormalizeCatalogText(speciesKey)
        if string.find(name, key, 1, true)
            or (speciesKey ~= "" and string.find(name, speciesKey, 1, true))
            or (compactKey ~= "" and string.find(compactName, compactKey, 1, true))
            or (#compactSpecies >= 4 and string.find(compactName, compactSpecies, 1, true)) then
            return entry.name .. " — " .. entry.hint
        end
    end
    return "Sem correspondência específica no catálogo; confira o nome/preço na loja ou placa do jogo."
end

local function IsEggInView(candidate, position, camera, character)
    local projected, onScreen = camera:WorldToViewportPoint(position)
    if not onScreen or projected.Z <= 0 then return false end

    -- Confere aproximadamente a linha de visão para não anunciar ovos atrás de paredes.
    local origin = camera.CFrame.Position
    local direction = position - origin
    if direction.Magnitude <= 0 then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = character and { character } or {}
    params.IgnoreWater = true
    local hit = Workspace:Raycast(origin, direction, params)
    if not hit then return true end
    return hit.Instance == candidate or hit.Instance:IsDescendantOf(candidate)
end

-- ESP local de ovos VISÍVEIS. Usa apenas objetos/atributos replicados acessíveis ao cliente;
-- não consulta remotes de gameplay, inventário oculto nem desenha deliberadamente através de paredes.
local function GetEggEspPart(candidate)
    local part
    local ok = pcall(function()
        if candidate:IsA("BasePart") then
            part = candidate
        elseif candidate:IsA("Model") then
            part = candidate.PrimaryPart or candidate:FindFirstChildWhichIsA("BasePart", true)
        end
    end)
    if ok then return part end
    return nil
end

local function RemoveEggEsp(candidate)
    local record = EggEspObjects[candidate]
    if not record then return end
    if record.highlight then pcall(function() record.highlight:Destroy() end) end
    if record.billboard then pcall(function() record.billboard:Destroy() end) end
    EggEspObjects[candidate] = nil
end

ClearEggEspVisuals = function()
    for candidate in pairs(EggEspObjects) do
        RemoveEggEsp(candidate)
    end
    if EggEspStatusText and State.Alive then
        pcall(function() EggEspStatusText:Set("ESP de ovos desligado; os marcadores locais foram removidos.") end)
    end
end

local function UpsertEggEsp(item)
    local candidate = item and item.object
    if not candidate or not candidate.Parent then return false end

    local playerGui = Player:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return false end

    local record = EggEspObjects[candidate]
    if not record then
        record = { candidate = candidate, lastSeen = os.clock() }
        EggEspObjects[candidate] = record
    end

    if not record.highlight or not record.highlight.Parent then
        local highlight = Instance.new("Highlight")
        highlight.Name = "SpeedUltraEggESPHighlight"
        highlight.Adornee = candidate
        highlight.FillTransparency = 1
        highlight.OutlineColor = Color3.fromRGB(196, 146, 255)
        highlight.OutlineTransparency = 0.08
        pcall(function() highlight.DepthMode = Enum.HighlightDepthMode.Occluded end)
        -- Client-created Workspace descendants remain local to this client.
        highlight.Parent = Workspace
        record.highlight = highlight
    else
        pcall(function() record.highlight.Adornee = candidate end)
    end

    local part = GetEggEspPart(candidate)
    if part then
        if not record.billboard or not record.billboard.Parent then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "SpeedUltraEggESPLabel"
            billboard.Adornee = part
            billboard.Size = UDim2.new(0, 210, 0, 48)
            billboard.StudsOffset = Vector3.new(0, 2.35, 0)
            billboard.LightInfluence = 0
            billboard.MaxDistance = math.max(30, EggScanRange + 20)
            billboard.AlwaysOnTop = false -- não desenha por cima de paredes
            billboard.Enabled = true

            local label = Instance.new("TextLabel")
            label.Name = "Text"
            label.BackgroundColor3 = Color3.fromRGB(47, 22, 72)
            label.BackgroundTransparency = 0.18
            label.BorderSizePixel = 0
            label.Size = UDim2.fromScale(1, 1)
            label.Font = Enum.Font.GothamSemibold
            label.TextColor3 = Color3.fromRGB(255, 245, 255)
            label.TextStrokeTransparency = 0.5
            label.TextSize = 12
            label.TextWrapped = true
            label.TextXAlignment = Enum.TextXAlignment.Center
            label.TextYAlignment = Enum.TextYAlignment.Center
            label.Parent = billboard

            billboard.Parent = playerGui
            record.billboard = billboard
            record.label = label
            record.part = part
        else
            if record.part ~= part then
                pcall(function() record.billboard.Adornee = part end)
                record.part = part
            end
        end

        if record.label then
            local distance = type(item.distance) == "number" and item.distance or 0
            local rarity = tostring(item.rarity or "raridade não exposta")
            local name = tostring(item.name or "Ovo sem nome exposto")
            pcall(function()
                record.label.Text = string.format("%s\n%s • %.0f studs", name, rarity, distance)
                record.billboard.MaxDistance = math.max(30, EggScanRange + 20)
            end)
        end
    end

    record.lastSeen = os.clock()
    return true
end

local function ApplyEggEspFromScan(found, partial)
    if not EggEspEnabled then return end
    local seen = {}
    local displayed = 0
    -- Keep a safe margin under Roblox's 255 Highlight client limit.
    local maxHighlights = 60
    for i = 1, math.min(#found, maxHighlights) do
        local item = found[i]
        if item.object then
            local ok, applied = pcall(UpsertEggEsp, item)
            if ok and applied then
                seen[item.object] = true
                displayed += 1
            end
        end
    end

    local now = os.clock()
    for candidate, record in pairs(EggEspObjects) do
        local stale = not candidate.Parent or (now - (record.lastSeen or 0)) > 30
        if stale or (not partial and not seen[candidate]) then
            RemoveEggEsp(candidate)
        end
    end

    if EggEspStatusText then
        local note = partial and "Busca parcial; os resultados anteriores podem continuar até a próxima busca completa." or "Marcadores atualizados com a última busca completa."
        pcall(function()
            EggEspStatusText:Set(string.format("ESP: %d ovos identificados com contorno/rótulo local. %s", displayed, note))
        end)
    end
end

local function PerformEggScan(token)
    if not State.Alive or EggScanRunning then return end
    EggScanRunning = true

    local function finish(text)
        EggScanRunning = false
        if State.Alive and token == EggScanToken and EggScanText then
            pcall(function() EggScanText:Set(text) end)
        end
    end

    local camera = Workspace.CurrentCamera
    local character = Player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not camera or not root then
        finish("Aguardando câmera/personagem. Tente escanear novamente após o spawn.")
        return
    end

    -- Não chamar Workspace:GetDescendants(): ele aloca uma lista grande de uma vez.
    -- A travessia por níveis permite ceder execução e limitar o trabalho por busca.
    local MAX_SCAN_SECONDS = 10
    local MAX_SCAN_OBJECTS = 30000
    local BATCH_SIZE = 80
    local startedAt = os.clock()
    local stack = { Workspace }
    local seen = {}
    local found = {}
    local checked = 0
    local partial = false
    local raycasts = 0
    local MAX_RAYCASTS = 250

    while #stack > 0 do
        if not State.Alive or token ~= EggScanToken then
            EggScanRunning = false
            return
        end
        if checked >= MAX_SCAN_OBJECTS or (os.clock() - startedAt) >= MAX_SCAN_SECONDS then
            partial = true
            break
        end

        local parent = stack[#stack]
        stack[#stack] = nil
        local children
        local childrenOk = pcall(function()
            children = parent:GetChildren()
        end)
        if not childrenOk or type(children) ~= "table" then
            partial = true
        else
            for _, object in ipairs(children) do
                if not State.Alive or token ~= EggScanToken then
                    EggScanRunning = false
                    return
                end

                checked += 1
                stack[#stack + 1] = object

                local isModelOrPart = false
                pcall(function()
                    isModelOrPart = object:IsA("Model") or object:IsA("BasePart")
                end)
                if isModelOrPart and HasEggMarker(object) then
                    local candidate = ResolveEggCandidate(object)
                    if candidate and candidate.Parent and not seen[candidate]
                        and not (character and candidate:IsDescendantOf(character)) then
                        seen[candidate] = true
                        local position = EggWorldPosition(candidate)
                        if position then
                            local distance = (position - root.Position).Magnitude
                            if distance <= EggScanRange then
                                local projected, onScreen = camera:WorldToViewportPoint(position)
                                if onScreen and projected.Z > 0 then
                                    local visible = false
                                    if raycasts < MAX_RAYCASTS then
                                        raycasts += 1
                                        local okVisible, visibleResult = pcall(IsEggInView, candidate, position, camera, character)
                                        visible = okVisible and visibleResult == true
                                    else
                                        -- Deixa de fazer raycast depois do limite para evitar pico de CPU.
                                        -- Como esses candidatos não foram confirmados, o resultado é parcial.
                                        visible = false
                                        partial = true
                                    end
                                    if visible then
                                        local displayName = EggNameHint(candidate)
                                        found[#found + 1] = {
                                            object = candidate,
                                            position = position,
                                            name = displayName ~= "" and displayName or "Ovo sem nome exposto",
                                            rarity = EggRarityHint(candidate, displayName),
                                            distance = distance,
                                            hint = EggCatalogHint(displayName),
                                        }
                                    end
                                end
                            end
                        end
                    end
                end

                if checked % BATCH_SIZE == 0 then
                    task.wait(0.025)
                    if (os.clock() - startedAt) >= MAX_SCAN_SECONDS then
                        partial = true
                        break
                    end
                end
                if checked >= MAX_SCAN_OBJECTS then
                    partial = true
                    break
                end
            end
        end
    end

    table.sort(found, function(a, b) return a.distance < b.distance end)
    local statusPrefix = partial and "Busca PARCIAL" or "Busca concluída"
    local duration = os.clock() - startedAt
    ApplyEggEspFromScan(found, partial)
    if #found == 0 then
        local extra = partial
            and "O limite de segurança foi alcançado; repita a busca se o ovo não apareceu."
            or "Nenhum ovo identificável visível foi encontrado nesta busca."
        finish(string.format(
            "%s • %d objetos examinados • %.1fs\n%s\nLimite: nomes/atributos não expostos ao cliente não podem ser identificados; isso não prova que não existam ovos.",
            statusPrefix, checked, duration, extra
        ))
        return
    end

    local lines = { string.format("%s • %d objetos examinados • %d ovos identificados (até 8 exibidos) • %.1fs", statusPrefix, checked, #found, duration) }
    for i = 1, math.min(8, #found) do
        local item = found[i]
        lines[#lines + 1] = string.format("%d. %s • %s • %.0f studs\n   %s", i, item.name, item.rarity, item.distance, item.hint)
    end
    if partial then
        lines[#lines + 1] = "A busca atingiu o limite de segurança e pode ter deixado objetos sem examinar. Toque para repetir."
    end
    lines[#lines + 1] = "Somente leitura: não coleta, não se move e não consulta dados ocultos do servidor."
    finish(table.concat(lines, "\n"))
end


-- Se uma instância destruída ou uma API do jogo lançar erro no meio da busca,
-- destrava o detector e mostra a falha em vez de deixar a opção presa em "buscando".
local function SafePerformEggScan(token)
    local ok, err = pcall(PerformEggScan, token)
    if not ok then
        EggScanRunning = false
        if State.Alive and token == EggScanToken and EggScanText then
            pcall(function()
                EggScanText:Set("A busca foi interrompida por um erro local: " .. tostring(err))
            end)
        end
    end
end

local function ScanEggsOnce()
    if EggScanRunning then
        if EggScanText then pcall(function() EggScanText:Set("A busca anterior ainda está em andamento.") end) end
        return
    end
    local token = EggScanToken
    task.spawn(function() SafePerformEggScan(token) end)
end

local function RefreshEggScanScheduler()
    EggScanSchedulerToken += 1
    local schedulerToken = EggScanSchedulerToken
    if not State.Alive or (not EggScanAutoEnabled and not EggEspEnabled) then return end

    task.spawn(function()
        while State.Alive and schedulerToken == EggScanSchedulerToken
            and (EggScanAutoEnabled or EggEspEnabled) do
            -- Wait for an older scan cancelled by a toggle to release its running flag.
            while State.Alive and EggScanRunning and schedulerToken == EggScanSchedulerToken do
                task.wait(0.1)
            end
            if not State.Alive or schedulerToken ~= EggScanSchedulerToken
                or (not EggScanAutoEnabled and not EggEspEnabled) then
                return
            end
            local scanToken = EggScanToken
            SafePerformEggScan(scanToken)
            local interval = EggEspEnabled and 10 or 15
            for _ = 1, interval do
                if not State.Alive or schedulerToken ~= EggScanSchedulerToken
                    or (not EggScanAutoEnabled and not EggEspEnabled) then
                    return
                end
                task.wait(1)
            end
        end
    end)
end

local function SetEggAutoScan(enabled)
    EggScanAutoEnabled = enabled == true
    EggScanToken += 1
    RefreshEggScanScheduler()
    if not EggScanAutoEnabled and not EggEspEnabled and EggScanText then
        pcall(function() EggScanText:Set("Atualização automática desligada. Use ‘Escanear ovos visíveis agora’ para uma busca manual.") end)
    end
end

local function SetEggEspEnabled(enabled)
    EggEspEnabled = enabled == true
    EggScanToken += 1
    if not EggEspEnabled then
        if ClearEggEspVisuals then pcall(ClearEggEspVisuals) end
        if EggEspStatusText then pcall(function() EggEspStatusText:Set("ESP de ovos desligado.") end) end
    end
    RefreshEggScanScheduler()
    if EggEspEnabled and EggEspStatusText then
        pcall(function() EggEspStatusText:Set("ESP ligado: procurando ovos identificáveis e visíveis; primeira leitura em andamento.") end)
    end
end

local function GetShortInstancePath(instance, maxParents)
    local names = {}
    local current = instance
    local count = 0
    while current and count < (maxParents or 6) do
        local ok, name = pcall(function() return current.Name end)
        names[#names + 1] = ok and tostring(name) or "?"
        current = current.Parent
        count += 1
    end
    local reversed = {}
    for i = #names, 1, -1 do reversed[#reversed + 1] = names[i] end
    return table.concat(reversed, ".")
end

local function DiagnoseEggHierarchy()
    if EggDiagnosticRunning or not State.Alive then
        if EggDiagnosticText then pcall(function() EggDiagnosticText:Set("Diagnóstico já está rodando; aguarde o resultado.") end) end
        return
    end
    EggDiagnosticRunning = true
    if EggDiagnosticText then pcall(function() EggDiagnosticText:Set("Inspecionando os nomes visíveis no Workspace em lotes...") end) end

    task.spawn(function()
        local startedAt = os.clock()
        local stack = { Workspace }
        local inspected = 0
        local maxObjects = 14000
        local maxSeconds = 6
        local matches = {}
        local seenNames = {}
        local partial = false
        local keywords = { "egg", "ovo", "nest", "ninho", "spawn", "chicken", "swan", "scorpion", "tiger", "yeti", "hellhound", "frog", "halloween", "voidseer", "pumpkin" }

        while #stack > 0 do
            if not State.Alive then EggDiagnosticRunning = false; return end
            if inspected >= maxObjects or os.clock() - startedAt >= maxSeconds then
                partial = true
                break
            end
            local parent = stack[#stack]
            stack[#stack] = nil
            local children
            local okChildren = pcall(function() children = parent:GetChildren() end)
            if okChildren and type(children) == "table" then
                for _, object in ipairs(children) do
                    inspected += 1
                    stack[#stack + 1] = object
                    local className = ""
                    pcall(function()
                        if object:IsA("Model") then className = "Model"
                        elseif object:IsA("BasePart") then className = "BasePart"
                        elseif object:IsA("Folder") then className = "Folder" end
                    end)
                    if className == "Model" or className == "BasePart" or className == "Folder" then
                        local objectName = EggNameHint(object)
                        local lowerName = LowerText(objectName)
                        local candidate = false
                        for _, keyword in ipairs(keywords) do
                            if string.find(lowerName, keyword, 1, true) then candidate = true; break end
                        end
                        if not candidate and (className == "Model" or className == "BasePart") then
                            candidate = MatchesEggCatalogName(objectName)
                        end
                        if candidate then
                            local path = GetShortInstancePath(object, 7)
                            local key = className .. "|" .. path
                            if not seenNames[key] then
                                seenNames[key] = true
                                matches[#matches + 1] = className .. " | " .. path
                            end
                        end
                    end
                    if inspected % 100 == 0 then
                        task.wait(0.01)
                        if os.clock() - startedAt >= maxSeconds then partial = true; break end
                    end
                    if inspected >= maxObjects then partial = true; break end
                end
            end
            if partial then break end
        end

        table.sort(matches)
        local lines = {
            string.format("Diagnóstico da estrutura: %d objetos examinados em %.1fs%s", inspected, os.clock() - startedAt, partial and " (parcial; limite atingido)" or ""),
            string.format("Caminhos candidatos encontrados: %d", #matches),
        }
        for i = 1, math.min(24, #matches) do lines[#lines + 1] = string.format("%d. %s", i, matches[i]) end
        if #matches == 0 then
            lines[#lines + 1] = "Nenhum nome candidato foi exposto nesta busca. Isso explica por que o detector não identificou ovos com as regras atuais; não significa que o jogo não tenha ovos."
        end
        lines[#lines + 1] = "Envie este texto se o detector não reconhecer um ovo visível; ele ajuda a ajustar as regras ao nome real sem adivinhar a estrutura do jogo."
        if EggDiagnosticText and State.Alive then pcall(function() EggDiagnosticText:Set(table.concat(lines, "\n")) end) end
        EggDiagnosticRunning = false
    end)
end

local function BuildInterface()
-- Grupos da barra lateral para ficar fácil achar cada função no celular.
Window:CreateSection({ name = "Principal" })
local HomeTab = Window:CreateTab({ name = "Início", icon = "house" })
local SpeedTab = Window:CreateTab({ name = "Velocidade", icon = "gauge" })

Window:CreateSection({ name = "Ferramentas" })
local PerformanceTab = Window:CreateTab({ name = "Desempenho", icon = "zap" })
local CarryTab = Window:CreateTab({ name = "Monitor", icon = "activity" })

Window:CreateSection({ name = "Objetivos" })
local FarmTab = Window:CreateTab({ name = "Ovos", icon = "egg" })
local EventTab = Window:CreateTab({ name = "Evento", icon = "calendar-days" })

Window:CreateSection({ name = "Configuração" })
local SettingsTab = Window:CreateTab({ name = "Configurações", icon = "settings" })

HomeTab:CreateSection({ name = "Comece por aqui" })
HomeTab:CreateText({
    name = "SPEED ULTRA V11.0 • 2026",
    text = "V11.0: leitura recursiva da estatística Speed quando exposta, meta de Speed separada de WalkSpeed, diagnóstico da hierarquia dos ovos, catálogo comunitário, assistente de eventos e otimização visual reversível. Use os atalhos abaixo para as ações mais frequentes."
})

StatusText = HomeTab:CreateText({
    name = "Diagnóstico local",
    text = "Iniciando monitoramento..."
})

HomeTab:CreateText({
    name = "Sobre esta versão",
    text = "A otimização visual altera apenas propriedades gráficas locais selecionadas. O resultado depende dos efeitos existentes no mapa; a porcentagem é a intensidade configurada, não uma promessa de aumento de FPS."
})

HomeTab:CreateSection({ name = "Atalhos rápidos" })
HomeTab:CreateButton({
    name = "Ativar otimização visual",
    description = "Liga o conjunto de efeitos definido na aba Desempenho.",
    callback = function()
        if VisualToggle then
            pcall(function() VisualToggle:Set(true) end)
        else
            SetVisualOptimization(true)
        end
    end
})
HomeTab:CreateButton({
    name = "Restaurar visual original",
    description = "Desfaz as alterações visuais que o script guardou.",
    callback = function()
        if VisualToggle then
            pcall(function() VisualToggle:Set(false) end)
        else
            SetVisualOptimization(false)
        end
    end
})

-- O Speed de progressão do jogo NÃO é a mesma propriedade que Humanoid.WalkSpeed.
-- Esta primeira seção acompanha a estatística real se estiver replicada ao cliente.
SpeedTab:CreateSection({ name = "Speed real do jogo — acompanhamento" })
SpeedTab:CreateText({
    name = "Diferença importante",
    text = "No Steal an Egg, a estatística Speed é a progressão que você aumenta na esteira e usa para liberar biomas. WalkSpeed é a velocidade de caminhada em studs/s. Este acompanhamento pode ler Speed quando o jogo a expõe, mas não altera a estatística do servidor."
})
CurrentSpeedText = SpeedTab:CreateText({
    name = "Speed real / WalkSpeed",
    text = "Procurando a estatística replicada do jogo..."
})
SpeedGoalText = SpeedTab:CreateText({
    name = "Progresso até a meta",
    text = "Meta inicial: 2.500.000 Speed. Atualize a leitura para comparar com a sua estatística atual."
})
SpeedGoalInput = SpeedTab:CreateInput({
    name = "Definir meta de Speed (número exato)",
    description = "Define uma meta de acompanhamento, não muda a estatística do servidor. Digite somente dígitos, por exemplo 2500000.",
    placeholder = "2500000",
    value = tostring(DesiredGameSpeedGoal),
    numeric = true,
    removeTextAfterFocusLost = false,
    callback = function(text)
        local normalized = tostring(text or ""):gsub("%s+", "")
        local target = tonumber(normalized)
        if not target or target ~= target or target == math.huge or target == -math.huge or target < 0 or target > 1000000000000000 then
            UpdateSpeedStatus("Meta inválida. Digite um número entre 0 e 1000000000000000, sem separadores.")
            if SpeedGoalInput then pcall(function() SpeedGoalInput:Set(tostring(DesiredGameSpeedGoal)) end) end
            return
        end
        DesiredGameSpeedGoal = math.floor(target + 0.5)
        UpdateSpeedGoalDisplay()
        UpdateSpeedStatus(string.format("Meta de acompanhamento definida: %.0f Speed. Isso não altera a estatística do jogo.", DesiredGameSpeedGoal))
    end
})
SpeedTab:CreateButton({
    name = "Atualizar leitura de Speed",
    description = "Procura novamente a estatística em atributos/ValueObjects replicados e tenta ler o painel de Speed visível.",
    callback = function()
        if RefreshSpeedReadout then
            RefreshSpeedReadout()
            UpdateSpeedGoalDisplay()
            UpdateSpeedStatus("Leitura de Speed atualizada. Confira a fonte exibida e compare com sua meta.")
        else
            UpdateSpeedStatus("Leitura ainda não pronta; aguarde o personagem carregar.")
        end
    end
})
SpeedTab:CreateButton({
    name = "Como aumentar Speed no jogo",
    description = "Mostra o método normal de progressão.",
    callback = function()
        UpdateSpeedStatus("Para aumentar a estatística Speed no Steal an Egg, use a esteira e os upgrades disponíveis no próprio jogo. O valor de WalkSpeed não substitui esse requisito.")
    end
})

-- Controle de WalkSpeed exclusivamente para uma experiência própria com servidor autorizado.
SpeedTab:CreateSection({ name = "WalkSpeed — somente projeto próprio" })
SpeedTab:CreateText({
    name = "Controle autorizado",
    text = "O controle abaixo envia um pedido ao RemoteEvent criado pelo Script de servidor fornecido no final deste TXT. Ele só funciona na sua própria experiência, com o servidor instalado e jogador autorizado; não altera o Steal an Egg público."
})
SpeedStatusText = SpeedTab:CreateText({
    name = "Estado do pedido autorizado",
    text = "Disponível somente em uma experiência sua com o Script de servidor instalado."
})
SpeedSlider = SpeedTab:CreateSlider({
    name = "WalkSpeed desejada (projeto próprio)",
    description = "8–1000 studs/s. Valores altos podem deixar o personagem incontrolável; o servidor deve validar a autorização.",
    range = { 8, 1000 },
    increment = 1,
    suffix = " studs/s",
    value = DesiredProjectSpeed,
    flag = "AuthorizedProjectSpeedV110",
    callback = function(value)
        if type(value) ~= "number" then return end
        DesiredProjectSpeed = math.clamp(math.floor(value + 0.5), 8, 1000)
        UpdateSpeedStatus(string.format("Selecionado: %d studs/s. Só é aplicado se o servidor autorizado do seu próprio projeto estiver instalado.", DesiredProjectSpeed))
    end
})
SpeedTab:CreateButton({
    name = "Aplicar WalkSpeed no meu projeto",
    description = "Envia a solicitação ao RemoteEvent que o script de servidor seguro cria.",
    callback = function() RequestProjectSpeed(DesiredProjectSpeed) end
})
SpeedTab:CreateButton({
    name = "Restaurar WalkSpeed padrão (16)",
    description = "Solicita ao servidor autorizado a velocidade padrão de 16 studs/s.",
    callback = function()
        DesiredProjectSpeed = 16
        if SpeedSlider then pcall(function() SpeedSlider:Set(16) end) end
        RequestProjectSpeed(16)
    end
})
BindSpeedResultRemote()

-- Detector e catálogo de ovos: informativo, com varredura manual como padrão.
FarmTab:CreateSection({ name = "Detector de ovos visíveis" })
FarmTab:CreateText({
    name = "Como o detector e o ESP funcionam",
    text = "Procura modelos/peças identificáveis dentro da câmera, do raio configurado e com linha de visão aproximada. O ESP desenha contorno e rótulo locais somente para ovos reconhecidos; não desenha através de paredes nem lê inventário oculto. Se a experiência não expuser nome/atributos ao cliente, a identificação pode falhar."
})
EggEspStatusText = FarmTab:CreateText({
    name = "Estado do ESP de ovos",
    text = "ESP desligado. Ligue para destacar ovos identificados pela busca visual."
})
FarmTab:CreateToggle({
    name = "ESP visual de ovos identificáveis",
    description = "Contorno e rótulo com nome/raridade disponível/distância. Apenas objetos já identificados e visíveis; não é um radar através de paredes.",
    value = false,
    flag = "V101_EggESPVisible",
    callback = function(value) SetEggEspEnabled(value == true) end
})
EggScanRangeSlider = FarmTab:CreateSlider({
    name = "Raio da busca",
    description = "Distância máxima para incluir ovos próximos; aumentar o raio não revela objetos fora da área carregada pelo jogo.",
    range = { 30, 250 },
    increment = 10,
    suffix = " studs",
    value = EggScanRange,
    flag = "V99_EggScanRange",
    callback = function(value)
        if type(value) == "number" then EggScanRange = math.clamp(math.floor(value / 10 + 0.5) * 10, 30, 250) end
    end
})
EggScanText = FarmTab:CreateText({
    name = "Resultado do detector",
    text = "Ainda não foi feita uma busca. Toque em ‘Escanear ovos visíveis agora’."
})
FarmTab:CreateButton({
    name = "Escanear ovos visíveis agora",
    description = "Faz uma busca incremental limitada por tempo e quantidade de objetos para reduzir picos de processamento; pode informar resultado parcial.",
    callback = function() ScanEggsOnce() end
})
EggDiagnosticText = FarmTab:CreateText({
    name = "Diagnóstico da estrutura dos ovos",
    text = "Ainda não executado. Use o botão de diagnóstico se a busca não encontrar um ovo que está visível no jogo."
})
FarmTab:CreateButton({
    name = "Diagnosticar nomes reais dos objetos",
    description = "Inspeciona nomes e caminhos visíveis no Workspace para descobrir por que um ovo não foi reconhecido; não interage com o jogo.",
    callback = function() DiagnoseEggHierarchy() end
})
EggScanAutoToggle = FarmTab:CreateToggle({
    name = "Atualizar detector automaticamente",
    description = "Atualiza em intervalos controlados: 10 s com ESP ligado, ou 15 s com apenas a atualização automática.",
    value = false,
    flag = "V99_EggAutoScan",
    callback = function(value) SetEggAutoScan(value == true) end
})
FarmTab:CreateText({
    name = "Catálogo de referência — não é um radar de spawn",
    text = "Referência revisada para Steal An Egg: Chicken, Bird, Owl e Raccoon aparecem no índice comunitário parcial de Forest; Frog aparece em Lake. Guias de gameplay relatam Tiger/Jungle, Yeti/área de gelo, Scorpion/Volcano, alvos em escala de baleia no Abyss Ocean e T-Rex/Prehistoric, mas nem todos são nomes literais de ovos. O histórico comunitário também lista Cherry Blossom Egg, Monster Egg, Rift Egg, Luminous Egg, Experiment #001/#013, Extinction Egg e ovos de Halloween. O detector só confirma o nome/atributos que o cliente realmente vê; preço, raridade e disponibilidade precisam ser conferidos na experiência."
})

-- Planejador manual de objetivos. Esta aba não controla movimento, interação,
-- teleporte ou coleta; serve apenas para registrar uma meta e mostrar uma dica.
local ManualGoal = "Ovo de maior valor (manual)"
local ObjectiveDescriptions = {
    ["Ovo de maior valor (manual)"] = "Compare os valores mostrados pelo próprio jogo e escolha o alvo manualmente. Não lê inventários ocultos nem calcula valores não expostos pela interface.",
    ["Ovo do evento (manual)"] = "Confira o bioma, a loja e os requisitos do evento dentro do jogo. Esta seleção só registra sua meta atual.",
    ["Ovo Enchanted Forest (manual)"] = "Meta manual para a Floresta Encantada. Guia comunitário relata uma missão de 20 ovos do bioma para o Wisp; confirme no painel do jogo.",
    ["Halloween Dimension Egg (manual)"] = "Meta manual para ovos da Halloween Dimension. Confirme preço, disponibilidade e recompensa diretamente na loja do evento.",
    ["Candy Corn / ovo do evento (manual)"] = "Guia comunitário relata Candy Corn por retornos de ovos e derrotas de monstros, trocadas no grande pumpkin do spawn de Halloween. Confirme o objetivo e a loja no jogo.",
    ["Extinction Egg (manual)"] = "Update 6: consulte a loja/recompensa da área de Dr. Scramble; preço e disponibilidade devem ser confirmados no jogo.",
    ["Experiment #001 / #013 (manual)"] = "Update 5: os guias relacionam esses ovos à Experiment Shop e a Samples. Verifique custo e requisitos da loja atual.",
    ["Luminous Egg (manual)"] = "Update 4: conteúdo de Angels vs Demons segundo guias comunitários; confirme se ainda está disponível e o custo atual.",
    ["Manor Key (manual)"] = "Rota comunitária: Phantom Express → Forgotten Town → redemoinho verde → área subterrânea → pescar com Haunted Rod até obter Manor Key → Abandoned Manor/Manor Door. A chance de drop não foi confirmada.",
}
local ObjectiveSteps = { confirmed = false, collected = false, returned = false }
local ObjectiveToggleControls = {}
local ObjectiveProgressText
local RefreshObjectiveProgress

FarmTab:CreateSection({ name = "Escolher meta" })
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
        "Candy Corn / ovo do evento (manual)",
        "Extinction Egg (manual)",
        "Experiment #001 / #013 (manual)",
        "Luminous Egg (manual)",
        "Manor Key (manual)",
    },
    value = ManualGoal,
    flag = "ManualObjectiveV94",
    callback = function(value)
        if type(value) ~= "string" then return end
        local changedGoal = ManualGoal ~= value
        ManualGoal = value
        if ObjectiveText then
            pcall(function()
                ObjectiveText:Set(ObjectiveDescriptions[value] or "Objetivo selecionado. Consulte as instruções dentro do jogo.")
            end)
        end
        if changedGoal and ObjectiveSteps then
            -- O progresso de um alvo não deve ser reutilizado ao selecionar outro.
            ObjectiveSteps.confirmed = false
            ObjectiveSteps.collected = false
            ObjectiveSteps.returned = false
            for _, control in ipairs(ObjectiveToggleControls or {}) do
                pcall(function() control:Set(false) end)
            end
            if RefreshObjectiveProgress then RefreshObjectiveProgress() end
        end
    end
})

ObjectiveProgressText = FarmTab:CreateText({
    name = "Progresso da meta",
    text = "0/3 etapas concluídas"
})
RefreshObjectiveProgress = function()
    local completed = 0
    for _, done in pairs(ObjectiveSteps) do
        if done then completed += 1 end
    end
    if ObjectiveProgressText then
        pcall(function()
            ObjectiveProgressText:Set(string.format("%d/3 etapas concluídas", completed))
        end)
    end
end

ObjectiveToggleControls[#ObjectiveToggleControls + 1] = FarmTab:CreateToggle({
    name = "Etapa manual: objetivo conferido",
    description = "Marque depois de verificar o alvo na experiência.",
    value = false,
    forgetState = true,
    callback = function(value)
        ObjectiveSteps.confirmed = value == true
        RefreshObjectiveProgress()
    end
})

ObjectiveToggleControls[#ObjectiveToggleControls + 1] = FarmTab:CreateToggle({
    name = "Etapa manual: ovo recolhido normalmente",
    description = "Apenas checklist; não aciona prompts nem eventos remotos.",
    value = false,
    forgetState = true,
    callback = function(value)
        ObjectiveSteps.collected = value == true
        RefreshObjectiveProgress()
    end
})

ObjectiveToggleControls[#ObjectiveToggleControls + 1] = FarmTab:CreateToggle({
    name = "Etapa manual: retorno à base concluído",
    description = "Marque depois de concluir pessoalmente o transporte no jogo.",
    value = false,
    forgetState = true,
    callback = function(value)
        ObjectiveSteps.returned = value == true
        RefreshObjectiveProgress()
    end
})

FarmTab:CreateButton({
    name = "Limpar progresso da meta",
    description = "Desmarca as etapas manuais para não misturar o progresso entre objetivos.",
    callback = function()
        for _, control in ipairs(ObjectiveToggleControls) do
            pcall(function() control:Set(false) end)
        end
        ObjectiveSteps.confirmed = false
        ObjectiveSteps.collected = false
        ObjectiveSteps.returned = false
        RefreshObjectiveProgress()
    end
})

PerformanceTab:CreateSection({ name = "Ativar e ajustar" })
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
                ScheduleVisualRebuild()
            end
        end
    end
})

PerformanceTab:CreateSection({ name = "Tipos de efeito" })
ParticlesToggle = PerformanceTab:CreateToggle({
    name = "Reduzir partículas",
    description = "Ajusta a taxa de emissão dos ParticleEmitter selecionados.",
    value = Config.OptimizeParticles,
    flag = "OptimizeParticles",
    callback = function(value)
        Config.OptimizeParticles = value == true
        if State.UIReady and not State.ControlsUpdating and State.VisualOptimization then
            ScheduleVisualRebuild()
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
            ScheduleVisualRebuild()
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
            ScheduleVisualRebuild()
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
            ScheduleVisualRebuild()
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
            ScheduleVisualRebuild()
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
            ScheduleVisualRebuild()
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
            ScheduleVisualRebuild()
        end
    end
})

PerformanceTab:CreateSection({ name = "Ações e diagnóstico" })
PerformanceTab:CreateButton({
    name = "Perfil de leveza forte (70%)",
    description = "Aplica a redução visual mais alta oferecida por este script, ativando todas as categorias suportadas. É local e reversível; pode alterar bastante a aparência e não garante ganho fixo de desempenho.",
    callback = function()
        State.ControlsUpdating = true
        Config.ReductionPercent = 70
        Config.OptimizeParticles = true
        Config.OptimizeTrails = true
        Config.OptimizeAtmospherics = true
        Config.OptimizeBeams = true
        Config.DisableSparkles = true
        Config.DisablePostEffects = true
        Config.ReduceBloomSunRays = true
        if ReductionSlider then pcall(function() ReductionSlider:Set(70) end) end
        if ParticlesToggle then pcall(function() ParticlesToggle:Set(true) end) end
        if TrailsToggle then pcall(function() TrailsToggle:Set(true) end) end
        if AtmosphericsToggle then pcall(function() AtmosphericsToggle:Set(true) end) end
        if BeamsToggle then pcall(function() BeamsToggle:Set(true) end) end
        if SparklesToggle then pcall(function() SparklesToggle:Set(true) end) end
        if PostEffectsToggle then pcall(function() PostEffectsToggle:Set(true) end) end
        if BloomSunRaysToggle then pcall(function() BloomSunRaysToggle:Set(true) end) end
        if VisualToggle then pcall(function() VisualToggle:Set(true) end) end
        State.ControlsUpdating = false
        SetVisualOptimization(true)
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

EventTab:CreateSection({ name = "Halloween Part 2 — Update 10" })
EventTab:CreateText({
    name = "Status da janela publicada",
    text = "A listagem pública da janela de Halloween Part 2 terminou em 25/10/2026, mas guias comunitários atualizados em 26/10 ainda descrevem as etapas do Update 10 e a rota da Manor Key. O fim da janela publicada não prova, por si só, que cada objeto do Update 10 esteja desativado. Confira o portal, o trem, a mansão e os painéis do evento nesta sessão; a rota abaixo é um guia comunitário, não confirmação de disponibilidade em tempo real."
})

EventTab:CreateText({
    name = "Ovos e moeda do Halloween",
    text = "Guias comunitários do Update 9 descrevem dois itens diferentes: Halloween Egg da loja e Halloween Dimension Egg comprado com Candy Corn. Candy Corn também é relatado como moeda obtida ao devolver ovos e derrotar monstros, com troca na abóbora gigante do spawn. Preços e chances vieram de capturas/relatos comunitários, não de consulta ao vivo; confirme se o portal e o painel de troca ainda estão ativos antes de gastar recursos."
})

EventTab:CreateText({
    name = "Pré-requisitos relatados",
    text = "Antes da Manor Key, os guias indicam concluir a cadeia de Echo, obter a Haunted Rod e o Phantom Express Ticket. Se o jogo não oferecer a viagem, confira os objetivos da parte anterior e as mensagens atuais do próprio jogo."
})

EventTab:CreateText({
    name = "Rota da Manor Key",
    text = "Rota comunitária do Update 10: 1) confirme que possui Phantom Express Ticket e Haunted Rod; 2) embarque no Phantom Express; 3) em Forgotten Town, procure o redemoinho verde; 4) entre na área subterrânea e pesque com Haunted Rod até obter Manor Key; 5) volte à Abandoned Manor e use a interação normal na Manor Door. A chance de obter a chave e o número de tentativas não estão confirmados. A porta e a entrada do chefe podem ser objetivos diferentes."
})

local EventSteps = { prerequisite = false, phantom = false, key = false, door = false, boss = false, recipe = false }
local EventToggleControls = {}
local EventProgressText = EventTab:CreateText({
    name = "Progresso do evento",
    text = "0/6 etapas confirmadas manualmente"
})
local function RefreshEventProgress()
    local completed = 0
    for _, done in pairs(EventSteps) do
        if done then completed += 1 end
    end
    if EventProgressText then
        pcall(function()
            EventProgressText:Set(string.format("%d/6 etapas confirmadas manualmente", completed))
        end)
    end
end

EventToggleControls[#EventToggleControls + 1] = EventTab:CreateToggle({
    name = "Etapa 1: pré-requisitos conferidos",
    description = "Marque quando a cadeia de Echo, Haunted Rod e Phantom Express Ticket estiverem conferidos no jogo.",
    value = false,
    flag = "V98_Halloween_Prerequisites",
    callback = function(value)
        EventSteps.prerequisite = value == true
        RefreshEventProgress()
    end
})
EventToggleControls[#EventToggleControls + 1] = EventTab:CreateToggle({
    name = "Etapa 2: viagem até Forgotten Town",
    description = "Confirme a viagem e a localização do redemoinho verde manualmente.",
    value = false,
    flag = "V94_Halloween_PhantomExpress",
    callback = function(value)
        EventSteps.phantom = value == true
        RefreshEventProgress()
    end
})
EventToggleControls[#EventToggleControls + 1] = EventTab:CreateToggle({
    name = "Etapa 3: Manor Key obtida",
    description = "Marque somente depois de confirmar a chave no inventário.",
    value = false,
    flag = "V94_Halloween_ManorKey",
    callback = function(value)
        EventSteps.key = value == true
        RefreshEventProgress()
    end
})
EventToggleControls[#EventToggleControls + 1] = EventTab:CreateToggle({
    name = "Etapa 4: Manor Door aberta",
    description = "A checklist não interage com portas nem consome itens.",
    value = false,
    flag = "V94_Halloween_ManorDoor",
    callback = function(value)
        EventSteps.door = value == true
        RefreshEventProgress()
    end
})

EventTab:CreateText({
    name = "Chefe e Boss Mastery — relatos da comunidade",
    text = "Guias de jogadores descrevem duas fases, Pumpkin Brute e depois Pumpkin King. Em algumas gravações, é preciso limpar raízes que bloqueiam os canhões e dispará-los conforme os avisos da arena. Os guias relatam uma trilha de até 65 níveis de Boss Mastery, mas verifique o contador e resgate cada recompensa dentro do jogo; nomes, requisitos exatos e chances não são garantidos."
})
EventToggleControls[#EventToggleControls + 1] = EventTab:CreateToggle({
    name = "Etapa 5: chefe e recompensas conferidos",
    description = "Marque depois de verificar a vitória e as recompensas disponíveis na tela Boss Mastery.",
    value = false,
    flag = "V94_Halloween_BossMastery",
    callback = function(value)
        EventSteps.boss = value == true
        RefreshEventProgress()
    end
})

EventTab:CreateText({
    name = "Fusão Cursed Monarch — confirme antes de usar pets",
    text = "As fontes comunitárias divergem na forma de nomear a segunda peça (Voidseer Pumpkin ou Divine Voidseer) e não confirmam o consumo, a contribuição por jogador nem a posse do resultado. Uma gravação mostra quatro pedestais com dois Ghost Fish e dois Voidseer Pumpkins. Leia os rótulos no altar dentro do jogo e NÃO use pets raros com base apenas nesta checklist."
})
EventToggleControls[#EventToggleControls + 1] = EventTab:CreateToggle({
    name = "Etapa 6: receita lida no altar",
    description = "Marca apenas que você conferiu os rótulos atuais no jogo; não executa fusões.",
    value = false,
    flag = "V94_Halloween_FusionRecipe",
    callback = function(value)
        EventSteps.recipe = value == true
        RefreshEventProgress()
    end
})

EventTab:CreateButton({
    name = "Limpar checklist do evento",
    description = "Desmarca as seis etapas para começar um acompanhamento novo.",
    callback = function()
        for _, control in ipairs(EventToggleControls) do
            pcall(function() control:Set(false) end)
        end
        for key in pairs(EventSteps) do EventSteps[key] = false end
        RefreshEventProgress()
    end
})

EventTab:CreateText({
    name = "Perfil visual do evento",
    text = "Este preset só ajusta efeitos gráficos locais para reduzir obstruções visuais. Não movimenta o personagem, não coleta ovos e não teleporta."
})

EventTab:CreateButton({
    name = "Ativar perfil visual Halloween",
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

CarryTab:CreateSection({ name = "Estado do personagem e transporte" })
CarryTab:CreateText({
    name = "Monitor do carry",
    text = "O monitor é somente de leitura. Ele tenta identificar atributos, tags e constraints comuns, mas cada jogo pode usar um sistema diferente."
})

CarryStatusText = CarryTab:CreateText({
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

SettingsTab:CreateSection({ name = "Aparência" })
SettingsTab:CreateText({
    name = "Tema e preferências",
    text = "O Rayfield guarda as opções com suporte à configuração do ambiente. Em certos executores, o salvamento persistente pode depender das permissões de arquivo disponíveis."
})

SettingsTab:CreateSection({ name = "Sessão e segurança" })
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

RuntimeDiagnosticsText = SettingsTab:CreateText({
    name = "Autodiagnóstico",
    text = "Execute o teste após a inicialização para verificar os recursos disponíveis."
})

SettingsTab:CreateButton({
    name = "Executar diagnóstico agora",
    description = "Verifica personagem, UI, remotes do projeto próprio e estado da otimização local.",
    callback = function()
        local character = Player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local requestRemote = ReplicatedStorage:FindFirstChild(SPEED_REQUEST_REMOTE)
        local resultRemote = ReplicatedStorage:FindFirstChild(SPEED_RESULT_REMOTE)
        local viewportText = "indisponível"
        pcall(function()
            local camera = Workspace.CurrentCamera
            if camera then
                local viewport = camera.ViewportSize
                viewportText = string.format("%d x %d", math.floor(viewport.X), math.floor(viewport.Y))
            end
        end)

        local report = string.format(
            "UI: %s\nPersonagem: %s\nHumanoid: %s\nRootPart: %s\nWalkSpeed (leitura): %s\nRemote de pedido: %s\nRemote de retorno: %s\nOtimização: %s\nFPS aprox.: %d\nViewport: %s",
            (Window and State.Alive) and "ativa" or "inativa",
            character and character.Parent and "presente" or "ausente",
            humanoid and humanoid.Parent and "presente" or "ausente",
            root and root.Parent and "presente" or "ausente",
            (humanoid and humanoid.Parent) and string.format("%.1f", humanoid.WalkSpeed) or "indisponível",
            requestRemote and requestRemote:IsA("RemoteEvent") and "encontrado" or "ausente",
            resultRemote and resultRemote:IsA("RemoteEvent") and "encontrado" or "ausente",
            State.Optimizing and "processando" or (State.VisualOptimization and "ativa" or "desativada"),
            State.Stats.FPS,
            viewportText
        )
        if RuntimeDiagnosticsText then
            pcall(function() RuntimeDiagnosticsText:Set(report) end)
        end
        UpdateStatus("Autodiagnóstico concluído. Consulte Configurações > Autodiagnóstico.")
    end
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

end

local uiBuildOk, uiBuildError = xpcall(BuildInterface, function(err)
    local ok, trace = pcall(function()
        return debug.traceback(tostring(err), 2)
    end)
    return ok and trace or tostring(err)
end)

if not uiBuildOk then
    warn("[SPEED ULTRA V11.0] Falha ao construir a interface: " .. tostring(uiBuildError))
    EarlyCleanup("UI_BUILD_FAILED")
    return
end

-- Se outra execução começou enquanto a UI estava sendo construída, não conecte monitores.
if not IsCurrentBoot() then
    -- Se a execução foi invalidada durante a montagem da UI, descarte listeners
    -- e restaure qualquer propriedade que eventualmente tenha sido tocada.
    pcall(function()
        if RestoreVisualProperties then RestoreVisualProperties() end
    end)
    State.Alive = false
    State.OptimizeToken += 1
    DisconnectAll()
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

local function NormalizeSpeedStatName(value)
    return LowerText(value):gsub("[^%w]", "")
end

local SPEED_STAT_PRIORITY = {
    speed = 1,
    speedpower = 2,
    currentspeed = 3,
    totalspeed = 4,
    speedstat = 5,
    speedvalue = 6,
    speedamount = 7,
}

local function ParseSpeedNumber(value)
    if type(value) == "number" then
        if value == value and value ~= math.huge and value ~= -math.huge then return value end
        return nil
    end
    if type(value) ~= "string" then return nil end
    local raw = value:lower():gsub("%s+", "")
    -- Aceita separadores comuns em HUDs: 2,500,000 e 2.500.000; preserva 2.5M.
    if raw:match("^%d+%.%d%d%d(%.%d%d%d)+$") then
        raw = raw:gsub("%.", "")
    else
        raw = raw:gsub(",", "")
    end
    local numText, suffix = raw:match("^([%d%.]+)([kmb]?)$")
    if not numText then return nil end
    local number = tonumber(numText)
    if not number then return nil end
    if suffix == "k" then number *= 1000
    elseif suffix == "m" then number *= 1000000
    elseif suffix == "b" then number *= 1000000000 end
    return number
end

local function ReadReplicatedGameSpeed()
    -- Pesquisa recursivamente no Player/leaderstats/Data; o script não escreve nestes valores.
    local objects = { Player }
    local okDesc, descendants = pcall(function() return Player:GetDescendants() end)
    if okDesc and type(descendants) == "table" then
        for _, object in ipairs(descendants) do objects[#objects + 1] = object end
    end

    local candidates = {}
    local function addCandidate(name, rawValue, path, isAttribute)
        local key = NormalizeSpeedStatName(name)
        local priority = SPEED_STAT_PRIORITY[key]
        local number = ParseSpeedNumber(rawValue)
        if priority and number ~= nil then
            candidates[#candidates + 1] = {
                name = tostring(name), value = number, path = path,
                priority = priority, attribute = isAttribute == true,
            }
        end
    end

    for _, object in ipairs(objects) do
        local name = ""
        pcall(function() name = object.Name end)
        local path = name
        pcall(function() path = object:GetFullName() end)

        local isValue = false
        pcall(function() isValue = object:IsA("ValueBase") end)
        if isValue then
            local value
            pcall(function() value = object.Value end)
            addCandidate(name, value, path, false)
        end

        local attributes
        pcall(function() attributes = object:GetAttributes() end)
        if type(attributes) == "table" then
            for attributeName, attributeValue in pairs(attributes) do
                addCandidate(attributeName, attributeValue, path .. ".<attr:" .. tostring(attributeName) .. ">", true)
            end
        end
    end

    table.sort(candidates, function(a, b)
        if a.priority ~= b.priority then return a.priority < b.priority end
        if a.attribute ~= b.attribute then return not a.attribute end
        return #a.path < #b.path
    end)
    if #candidates > 0 then return candidates[1] end

    -- Fallback somente de leitura: tenta extrair Speed de um texto de HUD visível ao cliente.
    local playerGui = Player:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        local guiDescendants
        local okGui = pcall(function() guiDescendants = playerGui:GetDescendants() end)
        if okGui and type(guiDescendants) == "table" then
            for _, object in ipairs(guiDescendants) do
                local isText = false
                pcall(function() isText = object:IsA("TextLabel") or object:IsA("TextButton") end)
                if isText then
                    local labelName, content = "", ""
                    pcall(function() labelName = object.Name end)
                    pcall(function() content = object.Text end)
                    local normalizedName = NormalizeSpeedStatName(labelName)
                    local lowerContent = tostring(content or ""):lower()
                    local looksLikeOurReadout = string.find(lowerContent, "origem:", 1, true)
                        or string.find(lowerContent, "meta escolhida:", 1, true)
                        or string.find(lowerContent, "meta:", 1, true)
                        or string.find(lowerContent, "faltam:", 1, true)
                    if string.find(normalizedName, "speed", 1, true)
                        and not string.find(normalizedName, "speedultra", 1, true)
                        and not looksLikeOurReadout then
                        local compact = tostring(content or ""):lower():gsub(",", "")
                        local raw = compact:match("speed[^%d]*([%d%.]+%s*[kmb]?)")
                            or compact:match("^%s*([%d%.]+%s*[kmb]?)%s*$")
                        local number = raw and ParseSpeedNumber(raw:gsub("%s+", "")) or nil
                        if number ~= nil then
                            local path = labelName
                            pcall(function() path = object:GetFullName() end)
                            return { name = labelName, value = number, path = path, priority = 99, attribute = false, fromHud = true }
                        end
                    end
                end
            end
        end
    end
    return nil
end

RefreshSpeedReadout = function()
    if not CurrentSpeedText or not State.Alive then return end
    local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    local walkSpeed = nil
    if humanoid and humanoid.Parent then pcall(function() walkSpeed = humanoid.WalkSpeed end) end

    local gameSpeed = ReadReplicatedGameSpeed()
    local parts = {}
    if gameSpeed and type(gameSpeed.value) == "number" then
        CurrentGameSpeedValue = gameSpeed.value
        CurrentGameSpeedPath = gameSpeed.path
        parts[#parts + 1] = string.format("Speed do jogo: %.0f (origem: %s)", gameSpeed.value, tostring(gameSpeed.path or "não identificada"))
    else
        CurrentGameSpeedValue = nil
        CurrentGameSpeedPath = nil
        parts[#parts + 1] = "Speed do jogo: não localizada em dados/atributos/textos do HUD expostos ao cliente"
    end
    if type(walkSpeed) == "number" then
        parts[#parts + 1] = string.format("WalkSpeed: %.1f studs/s (propriedade separada)", walkSpeed)
    end
    pcall(function() CurrentSpeedText:Set(table.concat(parts, "\n")) end)
    UpdateSpeedGoalDisplay()
end

local function BuildDiagnosticText()
    RefreshCharacterReferences()
    RefreshSpeedReadout()

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
    if State.Alive and IsCurrentBoot() then
        RefreshCharacterReferences()
        RefreshSpeedReadout()
    end
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
    EggScanAutoEnabled = false
    EggEspEnabled = false
    EggScanToken += 1
    EggScanSchedulerToken += 1
    if ClearEggEspVisuals then pcall(ClearEggEspVisuals) end
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
        warn("[SPEED ULTRA V11.0] Encerrado: " .. tostring(reason))
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

print("[SPEED ULTRA V11.0] Inicializado com Rayfield Gen2; ESP de ovos visíveis disponível; instância única ativa.")

--[=[
==========================================================================
APÊNDICE — SCRIPT DE SERVIDOR PARA EXPERIÊNCIA PRÓPRIA (NÃO EXECUTAR NO DELTA)
==========================================================================
INSTRUÇÕES:
1. Este código NÃO controla a experiência pública Roube um Ovo.
2. Para usar velocidade até 1000 no SEU jogo, copie somente o código abaixo
   para um Script em ServerScriptService no Roblox Studio.
3. Em jogo de grupo, adicione os UserIds autorizados em AUTHORIZED_USER_IDS.
4. WalkSpeed 1000 pode tornar o personagem incontrolável e causar problemas
   de física/replicação. O teto é configurável; comece com valores menores.

--- CÓDIGO DO SCRIPT DE SERVIDOR ---
-- SpeedUltraAuthorizedSpeed.server.lua
-- Instale este Script em ServerScriptService SOMENTE no seu próprio jogo Roblox.
-- Ele habilita o controle da aba "Velocidade" da UI V11.0 por um RemoteEvent autorizado.
-- Por padrão, somente o proprietário de uma experiência de usuário pode alterar a velocidade.
-- Em experiências de grupo, acrescente UserIds autorizados à tabela abaixo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REQUEST_REMOTE_NAME = "SpeedUltraAuthorizedSpeedRequest"
local RESULT_REMOTE_NAME = "SpeedUltraAuthorizedSpeedResult"
local DEFAULT_SPEED = 16
local MIN_SPEED = 8
local MAX_SPEED = 1000
local REQUEST_COOLDOWN = 0.25

-- Para experiências pertencentes a grupo, adicione aqui os UserIds dos administradores.
-- Exemplo: [123456789] = true,
local AUTHORIZED_USER_IDS = {
}

local function getOrCreateRemoteEvent(name)
    local existing = ReplicatedStorage:FindFirstChild(name)
    if existing then
        assert(existing:IsA("RemoteEvent"), name .. " já existe, mas não é RemoteEvent")
        return existing
    end

    local remote = Instance.new("RemoteEvent")
    remote.Name = name
    remote.Parent = ReplicatedStorage
    return remote
end

local RequestRemote = getOrCreateRemoteEvent(REQUEST_REMOTE_NAME)
local ResultRemote = getOrCreateRemoteEvent(RESULT_REMOTE_NAME)

local requestedSpeeds = {}
local lastRequestAt = {}

local function isAuthorized(player)
    if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
        return true
    end
    return AUTHORIZED_USER_IDS[player.UserId] == true
end

local function sendResult(player, success, speed, message)
    if player and player.Parent == Players then
        ResultRemote:FireClient(player, success, speed, message)
    end
end

local function applySpeed(player, character, speed)
    if not player or not character or player.Character ~= character then
        return false, "Personagem indisponível. Tente novamente depois do respawn."
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false, "Humanoid ainda não está pronto. Tente novamente."
    end

    humanoid.WalkSpeed = speed
    return true, string.format("Velocidade aplicada pelo servidor: %d studs/s.", speed)
end

RequestRemote.OnServerEvent:Connect(function(player, requestedValue)
    if not isAuthorized(player) then
        sendResult(player, false, nil, "Ajuste reservado ao proprietário ou a UserIds autorizados neste projeto.")
        return
    end

    local now = os.clock()
    local last = lastRequestAt[player.UserId] or 0
    if now - last < REQUEST_COOLDOWN then
        sendResult(player, false, nil, "Aguarde um instante antes de solicitar outra alteração.")
        return
    end
    lastRequestAt[player.UserId] = now

    if type(requestedValue) ~= "number"
        or requestedValue ~= requestedValue
        or requestedValue == math.huge
        or requestedValue == -math.huge
    then
        sendResult(player, false, nil, "Valor inválido. Escolha um número entre 8 e 1000.")
        return
    end

    local speed = math.clamp(math.floor(requestedValue + 0.5), MIN_SPEED, MAX_SPEED)
    local character = player.Character
    local success, message = applySpeed(player, character, speed)
    if not success then
        sendResult(player, false, nil, message)
        return
    end

    requestedSpeeds[player.UserId] = speed
    sendResult(player, true, speed, message)
end)

local function onCharacterAdded(player, character)
    local speed = requestedSpeeds[player.UserId]
    if not speed then
        return
    end

    task.spawn(function()
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not humanoid or player.Character ~= character or not player.Parent then
            return
        end
        if isAuthorized(player) then
            humanoid.WalkSpeed = speed
        end
    end)
end

local function bindPlayer(player)
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(player, character)
    end)
    if player.Character then
        onCharacterAdded(player, player.Character)
    end
end

Players.PlayerAdded:Connect(bindPlayer)
for _, player in ipairs(Players:GetPlayers()) do
    bindPlayer(player)
end

Players.PlayerRemoving:Connect(function(player)
    requestedSpeeds[player.UserId] = nil
    lastRequestAt[player.UserId] = nil
end)

print("[SpeedUltra V11.0] Servidor autorizado iniciado. Limites de WalkSpeed: " .. MIN_SPEED .. "–" .. MAX_SPEED .. ".")

--- FIM DO CÓDIGO DO SCRIPT DE SERVIDOR ---
]=]
