if not game:IsLoaded() then
	game.Loaded:Wait()
end

task.wait(0.3)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local jogador = Players.LocalPlayer
if not jogador then
	return
end

local PlayerGui = jogador:WaitForChild("PlayerGui", 30)
if not PlayerGui then
	return
end

local antigo = PlayerGui:FindFirstChild("PainelVelocidadeDefinitivo2026")
if antigo then
	pcall(function()
		antigo:Destroy()
	end)
end

local personagemAtual
local humanoideAtual
local rootPartAtual

local velocidadeAlvo = 255

local conexaoWalkSpeed
local conexaoDescendente
local conexaoMovimento
local conexaoPersonagem
local conexaoArrasteInicio
local conexaoArrasteMudanca
local conexaoArrasteFim

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PainelVelocidadeDefinitivo2026"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 75)
frame.Position = UDim2.new(0.05, 0, 0.4, 0)
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

local function tornarObjetoLeve(objeto)
	if not objeto then
		return
	end

	local nome = string.lower(objeto.Name)

	if not objeto:IsA("Tool")
		and not string.find(nome, "ovo")
		and not string.find(nome, "egg") then
		return
	end

	if objeto:IsA("BasePart") then
		pcall(function()
			objeto.Massless = true
			objeto.CustomPhysicalProperties = PhysicalProperties.new(
				0.0001,
				0,
				0,
				0,
				0
			)
		end)
	end

	for _, peca in ipairs(objeto:GetDescendants()) do
		if peca:IsA("BasePart") then
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
	end
end

local function aplicarVelocidade()
	local hum = humanoideAtual

	if hum and hum.Parent then
		pcall(function()
			hum.WalkSpeed = velocidadeAlvo
		end)
	end
end

local function limparConexoesPersonagem()
	if conexaoWalkSpeed then
		pcall(function()
			conexaoWalkSpeed:Disconnect()
		end)
		conexaoWalkSpeed = nil
	end

	if conexaoDescendente then
		pcall(function()
			conexaoDescendente:Disconnect()
		end)
		conexaoDescendente = nil
	end
end

local function prepararPersonagem(personagem)
	limparConexoesPersonagem()

	personagemAtual = personagem
	humanoideAtual = nil
	rootPartAtual = nil

	if not personagem or not personagem.Parent then
		return
	end

	humanoideAtual = personagem:FindFirstChildOfClass("Humanoid")
		or personagem:WaitForChild("Humanoid", 15)

	rootPartAtual = personagem:FindFirstChild("HumanoidRootPart")
		or personagem:WaitForChild("HumanoidRootPart", 15)

	if humanoideAtual then
		aplicarVelocidade()

		conexaoWalkSpeed = humanoideAtual:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if humanoideAtual
				and humanoideAtual.Parent
				and humanoideAtual.WalkSpeed ~= velocidadeAlvo then
				aplicarVelocidade()
			end
		end)
	end

	for _, objeto in ipairs(personagem:GetChildren()) do
		tornarObjetoLeve(objeto)
	end

	conexaoDescendente = personagem.DescendantAdded:Connect(function(objeto)
		tornarObjetoLeve(objeto)

		if objeto:IsA("Humanoid") then
			humanoideAtual = objeto
			aplicarVelocidade()

			if conexaoWalkSpeed then
				pcall(function()
					conexaoWalkSpeed:Disconnect()
				end)
			end

			conexaoWalkSpeed = objeto:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
				if humanoideAtual
					and humanoideAtual.Parent
					and humanoideAtual.WalkSpeed ~= velocidadeAlvo then
					aplicarVelocidade()
				end
			end)
		elseif objeto:IsA("BasePart") and objeto.Name == "HumanoidRootPart" then
			rootPartAtual = objeto
		end
	end)
end

botaoVelocidade.Activated:Connect(function()
	local valor = tonumber(caixaVelocidade.Text)

	if valor
		and valor == valor
		and valor ~= math.huge
		and valor ~= -math.huge then

		velocidadeAlvo = math.clamp(valor, 0, 1000)
		caixaVelocidade.Text = tostring(velocidadeAlvo)

		aplicarVelocidade()

		botaoVelocidade.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		botaoVelocidade.TextColor3 = Color3.fromRGB(0, 0, 0)

		task.delay(0.08, function()
			if botaoVelocidade and botaoVelocidade.Parent then
				botaoVelocidade.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
				botaoVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end)
	else
		caixaVelocidade.Text = tostring(velocidadeAlvo)
	end
end)

conexaoPersonagem = jogador.CharacterAdded:Connect(function(novoPersonagem)
	task.wait(0.15)

	if novoPersonagem and novoPersonagem.Parent then
		prepararPersonagem(novoPersonagem)
	end
end)

if jogador.Character then
	prepararPersonagem(jogador.Character)
end

local eventoMovimento = RunService.PreSimulation or RunService.Heartbeat

conexaoMovimento = eventoMovimento:Connect(function(deltaTime)
	local hum = humanoideAtual
	local root = rootPartAtual

	if not hum
		or not root
		or not hum.Parent
		or not root.Parent then

		local personagem = jogador.Character

		if personagem
			and personagem.Parent
			and personagem ~= personagemAtual then
			prepararPersonagem(personagem)
		end

		return
	end

	if hum.WalkSpeed ~= velocidadeAlvo then
		pcall(function()
			hum.WalkSpeed = velocidadeAlvo
		end)
	end

	local direcao = hum.MoveDirection

	if direcao.Magnitude > 0 then
		local direcaoUnit = direcao.Unit
		local atual

		pcall(function()
			atual = root.AssemblyLinearVelocity
		end)

		if atual then
			local alvoX = direcaoUnit.X * velocidadeAlvo
			local alvoZ = direcaoUnit.Z * velocidadeAlvo
			local dt = math.max(tonumber(deltaTime) or 0, 0)
			local suavizacao = 1 - math.exp(-50 * dt)

			pcall(function()
				root.AssemblyLinearVelocity = Vector3.new(
					atual.X + (alvoX - atual.X) * suavizacao,
					atual.Y,
					atual.Z + (alvoZ - atual.Z) * suavizacao
				)
			end)
		end
	else
		local atual

		pcall(function()
			atual = root.AssemblyLinearVelocity
		end)

		if atual then
			local dt = math.max(tonumber(deltaTime) or 0, 0)
			local suavizacaoParada = 1 - math.exp(-12 * dt)

			pcall(function()
				root.AssemblyLinearVelocity = Vector3.new(
					atual.X + (0 - atual.X) * suavizacaoParada,
					atual.Y,
					atual.Z + (0 - atual.Z) * suavizacaoParada
				)
			end)
		end
	end
end)

local arrastando = false
local toqueInicial = Vector2.new(0, 0)
local posicaoInicial = frame.Position
local inputArraste

conexaoArrasteInicio = titulo.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then

		arrastando = true
		inputArraste = input

		toqueInicial = Vector2.new(
			input.Position.X,
			input.Position.Y
		)

		posicaoInicial = frame.Position
	end
end)

conexaoArrasteMudanca = UserInputService.InputChanged:Connect(function(input)
	if not arrastando then
		return
	end

	if inputArraste
		and inputArraste.UserInputType == Enum.UserInputType.Touch
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseMovement then

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

conexaoArrasteFim = UserInputService.InputEnded:Connect(function(input)
	if input == inputArraste
		or input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		arrastando = false
		inputArraste = nil
	end
end)
