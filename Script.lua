-- =====================================================================================
-- ⚡ SPEED ULTRA v2026 — v2.1
-- Correção de estabilidade + respawn + execução duplicada
-- PRINCIPAL: controle de velocidade
-- Padrão: 255
-- =====================================================================================

if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(0.3)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local jogador = Players.LocalPlayer
local PlayerGui = jogador:WaitForChild("PlayerGui", 30)

if not PlayerGui then
    return
end

-- =====================================================================================
-- ♻️ LIMPEZA DA EXECUÇÃO ANTERIOR
-- =====================================================================================

local function obterAmbienteGlobal()
    local ok, env = pcall(function()
        return getgenv()
    end)

    if ok and type(env) == "table" then
        return env
    end

    return _G
end

local ambienteGlobal = obterAmbienteGlobal()

if type(ambienteGlobal.RipLoderSpeedUltraCleanup) == "function" then
    pcall(ambienteGlobal.RipLoderSpeedUltraCleanup)
end

-- =====================================================================================
-- 🎯 ESTADO
-- =====================================================================================

local personagemAtual
local humanoideAtual
local rootPartAtual

local velocidadeAlvo = 255

local conexaoWalkSpeed
local conexaoDescendente
local conexaoMovimento
local conexaoCharacterAdded
local conexaoTituloInputBegan
local conexaoInputChanged
local conexaoInputEnded

local ativo = true
local arrastando = false
local toqueAtual
local toqueInicial = Vector2.zero
local posicaoInicial = UDim2.new(0.05, 0, 0.4, 0)

-- =====================================================================================
-- 🖥️ INTERFACE
-- =====================================================================================

local antigaGui = PlayerGui:FindFirstChild("PainelVelocidadeDefinitivo2026")
if antigaGui then
    antigaGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PainelVelocidadeDefinitivo2026"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 75)
frame.Position = posicaoInicial
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 8)
frameCorner.Parent = frame

local linhaCima = Instance.new("Frame")
linhaCima.Size = UDim2.new(1, 0, 0, 3)
linhaCima.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
linhaCima.BorderSizePixel = 0
linhaCima.Parent = frame

local linhaCorner = Instance.new("UICorner")
linhaCorner.CornerRadius = UDim.new(0, 8)
linhaCorner.Parent = linhaCima

local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, 0, 0, 25)
titulo.Position = UDim2.new(0, 0, 0, 3)
titulo.BackgroundTransparency = 1
titulo.Text = "⚡ SPEED ULTRA v2026"
titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
titulo.Font = Enum.Font.SourceSansBold
titulo.TextSize = 12
titulo.Parent = frame

local caixaVelocidade = Instance.new("TextBox")
caixaVelocidade.Size = UDim2.new(0, 75, 0, 30)
caixaVelocidade.Position = UDim2.new(0, 10, 0, 35)
caixaVelocidade.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
caixaVelocidade.BorderSizePixel = 0
caixaVelocidade.Text = "255"
caixaVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
caixaVelocidade.Font = Enum.Font.SourceSans
caixaVelocidade.TextSize = 16
caixaVelocidade.ClearTextOnFocus = false
caixaVelocidade.Parent = frame

local caixaCorner = Instance.new("UICorner")
caixaCorner.CornerRadius = UDim.new(0, 5)
caixaCorner.Parent = caixaVelocidade

local botaoVelocidade = Instance.new("TextButton")
botaoVelocidade.Size = UDim2.new(0, 80, 0, 30)
botaoVelocidade.Position = UDim2.new(0, 90, 0, 35)
botaoVelocidade.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
botaoVelocidade.BorderSizePixel = 0
botaoVelocidade.Text = "TRAVAR VEL."
botaoVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
botaoVelocidade.Font = Enum.Font.SourceSansBold
botaoVelocidade.TextSize = 12
botaoVelocidade.Parent = frame

local botaoCorner = Instance.new("UICorner")
botaoCorner.CornerRadius = UDim.new(0, 5)
botaoCorner.Parent = botaoVelocidade

-- =====================================================================================
-- 🧹 LIMPEZA DE CONEXÕES
-- =====================================================================================

local function desconectar(conexao)
    if conexao then
        pcall(function()
            conexao:Disconnect()
        end)
    end
end

local function limparConexoesPersonagem()
    desconectar(conexaoWalkSpeed)
    conexaoWalkSpeed = nil

    desconectar(conexaoDescendente)
    conexaoDescendente = nil
end

-- =====================================================================================
-- ⚙️ PARTE OPCIONAL DE OBJETOS LEVES
-- Mantida da base para não alterar o objetivo do projeto.
-- =====================================================================================

local function tornarObjetoLeve(objeto)
    if not objeto or not objeto.Parent then
        return
    end

    local nome = string.lower(objeto.Name)

    if not objeto:IsA("Tool")
        and not string.find(nome, "ovo", 1, true)
        and not string.find(nome, "egg", 1, true) then
        return
    end

    local function aplicar(peca)
        if not peca:IsA("BasePart") then
            return
        end

        pcall(function()
            peca.Massless = true
            peca.CustomPhysicalProperties = PhysicalProperties.new(
                0.0001,
                0,
                0,
                0,
                0
            )
        end)
    end

    aplicar(objeto)

    for _, peca in ipairs(objeto:GetDescendants()) do
        aplicar(peca)
    end
end

-- =====================================================================================
-- 👤 PREPARAÇÃO DO PERSONAGEM
-- IMPORTANTE: NÃO desconecta o loop principal de velocidade.
-- =====================================================================================

local function prepararPersonagem(personagem)
    if not personagem then
        return
    end

    limparConexoesPersonagem()

    personagemAtual = personagem
    humanoideAtual = personagem:WaitForChild("Humanoid", 15)
    rootPartAtual = personagem:WaitForChild("HumanoidRootPart", 15)

    if personagemAtual ~= personagem then
        return
    end

    for _, objeto in ipairs(personagem:GetChildren()) do
        tornarObjetoLeve(objeto)
    end

    conexaoDescendente = personagem.DescendantAdded:Connect(function(objeto)
        tornarObjetoLeve(objeto)
    end)

    if humanoideAtual then
        humanoideAtual.WalkSpeed = velocidadeAlvo

        conexaoWalkSpeed = humanoideAtual:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if not ativo then
                return
            end

            if humanoideAtual
                and humanoideAtual.Parent
                and humanoideAtual.WalkSpeed ~= velocidadeAlvo then
                humanoideAtual.WalkSpeed = velocidadeAlvo
            end
        end)
    end
end

-- =====================================================================================
-- ⚡ CONTROLE PRINCIPAL DE VELOCIDADE
-- Esta é a parte PRINCIPAL e foi preservada.
-- =====================================================================================

conexaoMovimento = RunService.PreSimulation:Connect(function(deltaTime)
    if not ativo then
        return
    end

    local hum = humanoideAtual
    local root = rootPartAtual

    if not hum
        or not root
        or not hum.Parent
        or not root.Parent
        or hum.Health <= 0 then
        return
    end

    -- Mantém WalkSpeed sincronizado.
    if hum.WalkSpeed ~= velocidadeAlvo then
        hum.WalkSpeed = velocidadeAlvo
    end

    local direcao = hum.MoveDirection
    local dt = math.max(deltaTime, 0)

    if direcao.Magnitude > 0 then
        local direcaoUnit = direcao.Unit
        local atual = root.AssemblyLinearVelocity
        local alvoX = direcaoUnit.X * velocidadeAlvo
        local alvoZ = direcaoUnit.Z * velocidadeAlvo

        -- Suavização preservada da base.
        local suavizacao = 1 - math.exp(-50 * dt)

        root.AssemblyLinearVelocity = Vector3.new(
            atual.X + (alvoX - atual.X) * suavizacao,
            atual.Y,
            atual.Z + (alvoZ - atual.Z) * suavizacao
        )
    else
        local atual = root.AssemblyLinearVelocity
        local suavizacaoParada = 1 - math.exp(-12 * dt)

        root.AssemblyLinearVelocity = Vector3.new(
            atual.X * (1 - suavizacaoParada),
            atual.Y,
            atual.Z * (1 - suavizacaoParada)
        )
    end
end)

-- =====================================================================================
-- 🎛️ BOTÃO DE VELOCIDADE
-- =====================================================================================

local function atualizarVelocidade()
    local valor = tonumber(caixaVelocidade.Text)

    if not valor
        or valor ~= valor
        or valor == math.huge
        or valor == -math.huge then
        caixaVelocidade.Text = tostring(velocidadeAlvo)
        return
    end

    velocidadeAlvo = math.clamp(valor, 0, 1000)
    caixaVelocidade.Text = tostring(velocidadeAlvo)

    if humanoideAtual and humanoideAtual.Parent then
        humanoideAtual.WalkSpeed = velocidadeAlvo
    end

    botaoVelocidade.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    botaoVelocidade.TextColor3 = Color3.fromRGB(0, 0, 0)

    task.delay(0.08, function()
        if botaoVelocidade and botaoVelocidade.Parent then
            botaoVelocidade.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
            botaoVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end)
end

botaoVelocidade.Activated:Connect(atualizarVelocidade)

-- =====================================================================================
-- 🔄 RESPAWN
-- =====================================================================================

conexaoCharacterAdded = jogador.CharacterAdded:Connect(function(novoPersonagem)
    task.wait(0.15)

    if ativo then
        prepararPersonagem(novoPersonagem)
    end
end)

if jogador.Character then
    prepararPersonagem(jogador.Character)
end

-- =====================================================================================
-- 📱 ARRASTAR PAINEL
-- Mantido simples e compatível com toque/mouse.
-- =====================================================================================

conexaoTituloInputBegan = titulo.InputBegan:Connect(function(input)
    local tipo = input.UserInputType

    if tipo == Enum.UserInputType.Touch
        or tipo == Enum.UserInputType.MouseButton1 then

        arrastando = true
        toqueAtual = input

        toqueInicial = Vector2.new(
            input.Position.X,
            input.Position.Y
        )

        posicaoInicial = frame.Position
    end
end)

conexaoInputChanged = UserInputService.InputChanged:Connect(function(input)
    if not arrastando then
        return
    end

    local tipo = input.UserInputType

    if tipo == Enum.UserInputType.Touch
        or tipo == Enum.UserInputType.MouseMovement then

        local diferencaX = input.Position.X - toqueInicial.X
        local diferencaY = input.Position.Y - toqueInicial.Y

        frame.Position = UDim2.new(
            posicaoInicial.X.Scale,
            posicaoInicial.X.Offset + diferencaX,
            posicaoInicial.Y.Scale,
            posicaoInicial.Y.Offset + diferencaY
        )
    end
end)

conexaoInputEnded = UserInputService.InputEnded:Connect(function(input)
    local tipo = input.UserInputType

    if tipo == Enum.UserInputType.Touch
        or tipo == Enum.UserInputType.MouseButton1 then
        if toqueAtual == nil or input == toqueAtual then
            arrastando = false
            toqueAtual = nil
        end
    end
end)

-- =====================================================================================
-- 🧹 CLEANUP GLOBAL
-- Permite uma nova execução sem deixar esta instância rodando.
-- =====================================================================================

local function cleanup()
    if not ativo then
        return
    end

    ativo = false
    arrastando = false
    toqueAtual = nil

    limparConexoesPersonagem()

    desconectar(conexaoMovimento)
    conexaoMovimento = nil

    desconectar(conexaoCharacterAdded)
    conexaoCharacterAdded = nil

    desconectar(conexaoTituloInputBegan)
    conexaoTituloInputBegan = nil

    desconectar(conexaoInputChanged)
    conexaoInputChanged = nil

    desconectar(conexaoInputEnded)
    conexaoInputEnded = nil

    if screenGui then
        pcall(function()
            screenGui:Destroy()
        end)
    end

    if ambienteGlobal.RipLoderSpeedUltraCleanup == cleanup then
        ambienteGlobal.RipLoderSpeedUltraCleanup = nil
    end
end

ambienteGlobal.RipLoderSpeedUltraCleanup = cleanup

-- =====================================================================================
-- ✅ FIM — v2.1
-- =====================================================================================
