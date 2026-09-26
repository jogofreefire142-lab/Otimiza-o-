--[[
    Lux Dog - Farm Completo 2026
    Formato: TXT com código Lua/Luau
    Uso: Roblox Studio / jogo próprio

    OBJETIVOS:
    - Progressão automática por nível.
    - Seleção de missão por nível.
    - Caminho normal usando Humanoid:MoveTo().
    - Localização de alvo dentro da pasta configurada.
    - Ataque através de callback do SEU jogo.
    - Entrega/retorno da missão através de callback.
    - Recuperação quando o personagem respawna.
    - Limite normal + níveis secretos.
    - Sem reset forçado.
    - Sem teleporte exploit.
    - Sem APIs de executor.

    COMO USAR:
    1) Coloque este conteúdo em um ModuleScript no Roblox Studio.
    2) Dê ao ModuleScript o nome "FarmLevelController_2026".
    3) Configure QuestProvider, TargetProvider, AttackProvider e TurnInProvider.
    4) Chame Controller:Start().
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local FarmController = {}
FarmController.__index = FarmController

-- =========================================================
-- CONFIGURAÇÃO
-- =========================================================

FarmController.NORMAL_CAP = 2800
FarmController.SECRET_CAP = 3000

FarmController.DEFAULT_MOVE_REACHED_DISTANCE = 8
FarmController.DEFAULT_TARGET_DISTANCE = 120
FarmController.DEFAULT_RETRY_DELAY = 0.25
FarmController.DEFAULT_RESPAWN_DELAY = 1.0
FarmController.DEFAULT_ATTACK_INTERVAL = 0.15
FarmController.DEFAULT_QUEST_RECHECK = 0.50
FarmController.DEFAULT_STATUS_UPDATE = 0.20

-- Estados internos
FarmController.States = {
    Idle = "Idle",
    Starting = "Starting",
    ReadingLevel = "ReadingLevel",
    ResolvingQuest = "ResolvingQuest",
    GoingToQuest = "GoingToQuest",
    QuestReady = "QuestReady",
    GoingToTarget = "GoingToTarget",
    Fighting = "Fighting",
    WaitingForTarget = "WaitingForTarget",
    TurningIn = "TurningIn",
    NormalCap = "NormalCap",
    SecretLevels = "SecretLevels",
    Complete = "Complete",
    WaitingForCharacter = "WaitingForCharacter",
    Error = "Error",
}

-- =========================================================
-- CONSTRUTOR
-- =========================================================

function FarmController.new(config)
    config = config or {}

    local self = setmetatable({}, FarmController)

    self.Config = {
        MoveReachedDistance = config.MoveReachedDistance or self.DEFAULT_MOVE_REACHED_DISTANCE,
        TargetDistance = config.TargetDistance or self.DEFAULT_TARGET_DISTANCE,
        RetryDelay = config.RetryDelay or self.DEFAULT_RETRY_DELAY,
        RespawnDelay = config.RespawnDelay or self.DEFAULT_RESPAWN_DELAY,
        AttackInterval = config.AttackInterval or self.DEFAULT_ATTACK_INTERVAL,
        QuestRecheck = config.QuestRecheck or self.DEFAULT_QUEST_RECHECK,
        StatusUpdate = config.StatusUpdate or self.DEFAULT_STATUS_UPDATE,

        -- Callbacks do seu jogo.
        QuestProvider = config.QuestProvider,
        TargetProvider = config.TargetProvider,
        AttackProvider = config.AttackProvider,
        TurnInProvider = config.TurnInProvider,

        -- Callback opcional para a interface.
        OnStatus = config.OnStatus,
        OnStateChanged = config.OnStateChanged,
        OnLevelChanged = config.OnLevelChanged,
        OnQuestChanged = config.OnQuestChanged,
        OnTargetChanged = config.OnTargetChanged,
        OnError = config.OnError,
    }

    self.Running = false
    self.State = self.States.Idle
    self.CurrentLevel = 0
    self.CurrentQuest = nil
    self.CurrentTarget = nil
    self.LastStatus = ""
    self.LastError = nil

    self._loopThread = nil
    self._characterConnection = nil
    self._lastStatusTick = 0
    self._lastAttackTick = 0

    return self
end

-- =========================================================
-- UTILITÁRIOS
-- =========================================================

function FarmController:_SetState(newState)
    if self.State == newState then
        return
    end

    self.State = newState

    if typeof(self.Config.OnStateChanged) == "function" then
        pcall(self.Config.OnStateChanged, newState, self)
    end
end

function FarmController:_SetStatus(message)
    message = tostring(message or "")

    if self.LastStatus == message then
        return
    end

    self.LastStatus = message

    if typeof(self.Config.OnStatus) == "function" then
        pcall(self.Config.OnStatus, message, self)
    end
end

function FarmController:_SetError(message)
    self.LastError = tostring(message or "Erro desconhecido")
    self:_SetState(self.States.Error)
    self:_SetStatus("Erro: " .. self.LastError)

    if typeof(self.Config.OnError) == "function" then
        pcall(self.Config.OnError, self.LastError, self)
    end
end

function FarmController:_SetQuest(quest)
    self.CurrentQuest = quest

    if typeof(self.Config.OnQuestChanged) == "function" then
        pcall(self.Config.OnQuestChanged, quest, self)
    end
end

function FarmController:_SetTarget(target)
    self.CurrentTarget = target

    if typeof(self.Config.OnTargetChanged) == "function" then
        pcall(self.Config.OnTargetChanged, target, self)
    end
end

function FarmController:_SetLevel(level)
    level = tonumber(level) or 0

    if self.CurrentLevel ~= level then
        self.CurrentLevel = level

        if typeof(self.Config.OnLevelChanged) == "function" then
            pcall(self.Config.OnLevelChanged, level, self)
        end
    end
end

function FarmController:_SafeCall(callback, ...)
    if typeof(callback) ~= "function" then
        return false, nil, "callback não configurado"
    end

    local ok, result = pcall(callback, ...)
    if not ok then
        return false, nil, tostring(result)
    end

    return true, result, nil
end

-- =========================================================
-- PERSONAGEM
-- =========================================================

function FarmController:GetCharacter()
    if not LocalPlayer then
        return nil, nil, nil
    end

    local character = LocalPlayer.Character
    if not character then
        return nil, nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root then
        return character, humanoid, root
    end

    if humanoid.Health <= 0 then
        return character, humanoid, root
    end

    return character, humanoid, root
end

function FarmController:WaitForCharacter(timeout)
    timeout = tonumber(timeout) or 15

    local startTime = os.clock()

    while self.Running do
        local character, humanoid, root = self:GetCharacter()

        if character and humanoid and root and humanoid.Health > 0 then
            return character, humanoid, root
        end

        if os.clock() - startTime >= timeout then
            return nil, nil, nil
        end

        task.wait(0.2)
    end

    return nil, nil, nil
end

-- =========================================================
-- NÍVEL
-- =========================================================

function FarmController:GetLevel()
    if not LocalPlayer then
        return 0
    end

    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if not leaderstats then
        return 0
    end

    local levelObject =
        leaderstats:FindFirstChild("Level")
        or leaderstats:FindFirstChild("level")
        or leaderstats:FindFirstChild("Lvl")

    if not levelObject then
        return 0
    end

    return tonumber(levelObject.Value) or 0
end

function FarmController:IsNormalCap(level)
    return level >= self.NORMAL_CAP and level < self.SECRET_CAP
end

function FarmController:IsComplete(level)
    return level >= self.SECRET_CAP
end

-- =========================================================
-- MISSÃO
-- =========================================================

-- O QuestProvider do seu jogo deve retornar uma tabela, por exemplo:
-- {
--     Id = "BanditQuest",
--     Name = "Bandit Quest",
--     MinLevel = 1,
--     MaxLevel = 20,
--     QuestPosition = Vector3.new(...),
--     TargetName = "Bandit",
--     TargetPosition = Vector3.new(...),
--     TurnInPosition = Vector3.new(...), -- opcional
-- }

function FarmController:ResolveQuest(level)
    local ok, quest, err = self:_SafeCall(
        self.Config.QuestProvider,
        level,
        self
    )

    if not ok then
        self:_SetError("QuestProvider: " .. tostring(err))
        return nil
    end

    if typeof(quest) ~= "table" then
        self:_SetError("QuestProvider retornou um valor inválido.")
        return nil
    end

    if not quest.QuestPosition then
        self:_SetError("A missão não possui QuestPosition.")
        return nil
    end

    if not quest.TargetName and not quest.TargetPosition then
        self:_SetError("A missão não possui TargetName ou TargetPosition.")
        return nil
    end

    return quest
end

function FarmController:IsQuestActive()
    return self.CurrentQuest ~= nil
end

function FarmController:IsQuestComplete()
    local quest = self.CurrentQuest

    if not quest then
        return false
    end

    -- Permitimos que o próprio jogo informe a conclusão.
    if typeof(quest.IsComplete) == "function" then
        local ok, result = pcall(quest.IsComplete, quest, self)
        return ok and result == true
    end

    if quest.Completed == true then
        return true
    end

    return false
end

-- =========================================================
-- ALVOS
-- =========================================================

function FarmController:IsTargetValid(target)
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
    if humanoid and humanoid.Health <= 0 then
        return false
    end

    return true
end

function FarmController:FindTarget(quest)
    local ok, target, err = self:_SafeCall(
        self.Config.TargetProvider,
        quest,
        self
    )

    if not ok then
        self:_SetStatus("Falha ao procurar alvo: " .. tostring(err))
        return nil
    end

    if target and self:IsTargetValid(target) then
        return target
    end

    return nil
end

-- =========================================================
-- MOVIMENTO NORMAL
-- =========================================================

function FarmController:MoveTo(position, reachedDistance)
    reachedDistance = tonumber(reachedDistance) or self.Config.MoveReachedDistance

    if typeof(position) ~= "Vector3" then
        return false, "posição inválida"
    end

    local character, humanoid, root = self:GetCharacter()

    if not character or not humanoid or not root or humanoid.Health <= 0 then
        return false, "personagem indisponível"
    end

    humanoid:MoveTo(position)

    while self.Running do
        local newCharacter, newHumanoid, newRoot = self:GetCharacter()

        if not newCharacter or not newHumanoid or not newRoot then
            return false, "personagem perdido"
        end

        if newHumanoid.Health <= 0 then
            return false, "personagem derrotado"
        end

        local distance = (newRoot.Position - position).Magnitude

        if distance <= reachedDistance then
            return true
        end

        task.wait(0.1)

        -- Reenvia o MoveTo periodicamente para manter o deslocamento.
        newHumanoid:MoveTo(position)
    end

    return false, "controlador parado"
end

-- =========================================================
-- COMBATE DO SEU JOGO
-- =========================================================

function FarmController:AttackTarget(target, quest)
    if not self:IsTargetValid(target) then
        return false, "alvo inválido"
    end

    local now = os.clock()

    if now - self._lastAttackTick < self.Config.AttackInterval then
        return true
    end

    self._lastAttackTick = now

    local ok, result, err = self:_SafeCall(
        self.Config.AttackProvider,
        target,
        quest,
        self
    )

    if not ok then
        return false, err
    end

    if result == false then
        return false, "AttackProvider recusou o ataque"
    end

    return true
end

-- =========================================================
-- ENTREGA DA MISSÃO
-- =========================================================

function FarmController:TurnInQuest(quest)
    if not quest then
        return false, "missão ausente"
    end

    -- Callback principal do jogo.
    if typeof(self.Config.TurnInProvider) == "function" then
        local ok, result, err = self:_SafeCall(
            self.Config.TurnInProvider,
            quest,
            self
        )

        if not ok then
            return false, err
        end

        return result ~= false
    end

    -- Se não houver callback, consideramos que não há entrega
    -- externa necessária; o próprio jogo pode detectar a conclusão.
    return true
end

-- =========================================================
-- CICLO COMPLETO DA MISSÃO
-- =========================================================

function FarmController:_RunQuestCycle()
    local quest = self.CurrentQuest

    if not quest then
        self:_SetState(self.States.ResolvingQuest)
        return
    end

    -- 1. Ir ao NPC da missão.
    if quest.QuestPosition then
        self:_SetState(self.States.GoingToQuest)
        self:_SetStatus("Indo para a missão: " .. tostring(quest.Name or quest.Id or "Quest"))

        local reached, moveError = self:MoveTo(quest.QuestPosition)

        if not reached then
            self:_SetStatus("Movimento interrompido: " .. tostring(moveError))
            task.wait(self.Config.RetryDelay)
            return
        end
    end

    -- 2. Ativar/iniciar missão.
    self:_SetState(self.States.QuestReady)

    if typeof(quest.Start) == "function" then
        local ok, result = pcall(quest.Start, quest, self)

        if not ok then
            self:_SetStatus("Não foi possível iniciar a missão.")
            task.wait(self.Config.RetryDelay)
            return
        end

        if result == false then
            task.wait(self.Config.QuestRecheck)
            return
        end
    end

    -- 3. Procurar alvo.
    while self.Running and self.CurrentQuest == quest do
        if self:IsQuestComplete() then
            self:_SetState(self.States.TurningIn)
            self:_SetStatus("Missão concluída. Entregando...")
            self:TurnInQuest(quest)
            self:_SetQuest(nil)
            self:_SetTarget(nil)
            return
        end

        local target = self:FindTarget(quest)

        if not target then
            self:_SetState(self.States.WaitingForTarget)
            self:_SetStatus("Aguardando alvo...")
            task.wait(self.Config.RetryDelay)
            continue
        end

        self:_SetTarget(target)

        local targetRoot =
            target:FindFirstChild("HumanoidRootPart")
            or target.PrimaryPart

        -- 4. Ir até o alvo.
        if targetRoot then
            self:_SetState(self.States.GoingToTarget)
            self:_SetStatus("Indo até: " .. tostring(target.Name))

            local reached, moveError = self:MoveTo(
                targetRoot.Position,
                self.Config.MoveReachedDistance
            )

            if not reached then
                self:_SetStatus("Movimento do alvo interrompido: " .. tostring(moveError))
                task.wait(self.Config.RetryDelay)
                continue
            end
        end

        -- 5. Combater.
        self:_SetState(self.States.Fighting)
        self:_SetStatus("Combatendo: " .. tostring(target.Name))

        while self.Running and self:IsTargetValid(target) do
            if self:IsQuestComplete() then
                self:_SetState(self.States.TurningIn)
                self:_SetStatus("Missão concluída. Entregando...")
                self:TurnInQuest(quest)
                self:_SetQuest(nil)
                self:_SetTarget(nil)
                return
            end

            -- Aproximação normal se o alvo se afastar.
            local _, humanoid, root = self:GetCharacter()
            local enemyRoot =
                target:FindFirstChild("HumanoidRootPart")
                or target.PrimaryPart

            if not humanoid or not root or humanoid.Health <= 0 then
                self:_SetState(self.States.WaitingForCharacter)
                return
            end

            if enemyRoot then
                local distance = (root.Position - enemyRoot.Position).Magnitude

                if distance > self.Config.TargetDistance then
                    humanoid:MoveTo(enemyRoot.Position)
                end
            end

            local attackOk, attackError = self:AttackTarget(target, quest)

            if not attackOk then
                self:_SetStatus("Ataque aguardando correção: " .. tostring(attackError))
            end

            task.wait(self.Config.AttackInterval)
        end

        self:_SetTarget(nil)

        -- Volta ao ciclo para buscar o próximo alvo.
        task.wait(self.Config.RetryDelay)
    end
end

-- =========================================================
-- LOOP PRINCIPAL
-- =========================================================

function FarmController:_Run()
    self:_SetState(self.States.Starting)

    while self.Running do
        local character, humanoid, root = self:GetCharacter()

        if not character or not humanoid or not root or humanoid.Health <= 0 then
            self:_SetState(self.States.WaitingForCharacter)
            self:_SetStatus("Aguardando personagem...")

            task.wait(self.Config.RespawnDelay)
            continue
        end

        self:_SetState(self.States.ReadingLevel)

        local level = self:GetLevel()
        self:_SetLevel(level)

        if level <= 0 then
            self:_SetStatus("Nível ainda não disponível...")
            task.wait(self.Config.RetryDelay)
            continue
        end

        if self:IsComplete(level) then
            self:_SetState(self.States.Complete)
            self:_SetStatus("Progressão concluída no nível " .. tostring(level) .. ".")
            break
        end

        if self:IsNormalCap(level) then
            self:_SetState(self.States.SecretLevels)
            self:_SetStatus(
                "Nível " .. tostring(level) ..
                " atingiu o limite normal. Aguardando progressão dos níveis secretos."
            )

            task.wait(self.Config.QuestRecheck)
            continue
        end

        if not self.CurrentQuest then
            self:_SetState(self.States.ResolvingQuest)
            self:_SetStatus("Selecionando missão para nível " .. tostring(level) .. "...")

            local quest = self:ResolveQuest(level)

            if quest then
                self:_SetQuest(quest)
            else
                task.wait(self.Config.RetryDelay)
                continue
            end
        end

        self:_RunQuestCycle()

        -- Pequena pausa para evitar loop excessivo.
        task.wait(self.Config.RetryDelay)
    end

    if self.State ~= self.States.Complete
        and self.State ~= self.States.Error
        and self.State ~= self.States.Idle then
        self:_SetState(self.States.Idle)
    end
end

-- =========================================================
-- START / STOP
-- =========================================================

function FarmController:Start()
    if self.Running then
        return false
    end

    self.Running = true
    self.LastError = nil

    self._loopThread = task.spawn(function()
        self:_Run()
    end)

    return true
end

function FarmController:Stop()
    if not self.Running then
        return false
    end

    self.Running = false

    local _, humanoid = self:GetCharacter()

    if humanoid and humanoid.Health > 0 then
        humanoid:MoveTo(humanoid.RootPart and humanoid.RootPart.Position or Vector3.zero)
    end

    self:_SetTarget(nil)
    self:_SetQuest(nil)
    self:_SetState(self.States.Idle)
    self:_SetStatus("Farm parado.")

    self._loopThread = nil

    return true
end

function FarmController:Toggle()
    if self.Running then
        return self:Stop()
    end

    return self:Start()
end

function FarmController:IsRunning()
    return self.Running
end

function FarmController:GetStatus()
    return {
        Running = self.Running,
        State = self.State,
        Level = self.CurrentLevel,
        Quest = self.CurrentQuest,
        Target = self.CurrentTarget,
        Error = self.LastError,
    }
end

-- =========================================================
-- EXEMPLO DE CONFIGURAÇÃO
-- =========================================================
--
-- Abaixo está um exemplo genérico para o SEU jogo.
-- Adapte nomes/pastas/atributos conforme a estrutura do projeto.
--
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Workspace = game:GetService("Workspace")
--
-- local Controller = FarmController.new({
--
--     QuestProvider = function(level, controller)
--         local questsFolder = Workspace:FindFirstChild("Quests")
--         if not questsFolder then
--             return nil
--         end
--
--         local chosenQuest
--
--         for _, quest in ipairs(questsFolder:GetChildren()) do
--             local minLevel = tonumber(quest:GetAttribute("MinLevel")) or 0
--             local maxLevel = tonumber(quest:GetAttribute("MaxLevel")) or math.huge
--
--             if level >= minLevel and level <= maxLevel then
--                 chosenQuest = quest
--                 break
--             end
--         end
--
--         if not chosenQuest then
--             return nil
--         end
--
--         local questPart = chosenQuest:FindFirstChild("QuestPosition")
--         local targetPosition = chosenQuest:FindFirstChild("TargetPosition")
--
--         return {
--             Id = chosenQuest.Name,
--             Name = chosenQuest:GetAttribute("DisplayName") or chosenQuest.Name,
--             MinLevel = chosenQuest:GetAttribute("MinLevel"),
--             MaxLevel = chosenQuest:GetAttribute("MaxLevel"),
--             QuestPosition = questPart and questPart.Position,
--             TargetPosition = targetPosition and targetPosition.Position,
--             TargetName = chosenQuest:GetAttribute("TargetName"),
--             Completed = false,
--             Start = function()
--                 -- Inicie a missão pelo sistema do seu próprio jogo.
--                 return true
--             end,
--             IsComplete = function(q)
--                 return q.Completed == true
--             end,
--         }
--     end,
--
--     TargetProvider = function(quest, controller)
--         local enemiesFolder = Workspace:FindFirstChild("Enemies")
--         if not enemiesFolder then
--             return nil
--         end
--
--         local character = LocalPlayer.Character
--         local root = character and character:FindFirstChild("HumanoidRootPart")
--
--         if not root then
--             return nil
--         end
--
--         local bestTarget
--         local bestDistance = math.huge
--
--         for _, enemy in ipairs(enemiesFolder:GetChildren()) do
--             if quest.TargetName and enemy.Name ~= quest.TargetName then
--                 continue
--             end
--
--             local enemyRoot =
--                 enemy:FindFirstChild("HumanoidRootPart")
--                 or enemy.PrimaryPart
--
--             local enemyHumanoid = enemy:FindFirstChildOfClass("Humanoid")
--
--             if enemyRoot and enemyHumanoid and enemyHumanoid.Health > 0 then
--                 local distance = (root.Position - enemyRoot.Position).Magnitude
--
--                 if distance < bestDistance then
--                     bestDistance = distance
--                     bestTarget = enemy
--                 end
--             end
--         end
--
--         return bestTarget
--     end,
--
--     AttackProvider = function(target, quest, controller)
--         -- Use o sistema de combate do seu próprio jogo.
--         -- Exemplo:
--         -- local CombatRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Attack")
--         -- CombatRemote:FireServer(target)
--
--         -- Mantido sem implementação específica para evitar
--         -- assumir a arquitetura do seu jogo.
--         return true
--     end,
--
--     TurnInProvider = function(quest, controller)
--         -- Use o sistema de entrega de missão do seu próprio jogo.
--         return true
--     end,
--
--     OnStatus = function(message)
--         print("[Lux Dog Farm]", message)
--     end,
--
--     OnStateChanged = function(state)
--         print("[Lux Dog Farm State]", state)
--     end,
--
--     OnLevelChanged = function(level)
--         print("[Lux Dog Level]", level)
--     end,
-- })
--
-- Controller:Start()
--
-- Para parar:
-- Controller:Stop()
--
-- Para ligar/desligar:
-- Controller:Toggle()

return FarmController
