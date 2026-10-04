local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local velocidadeAtual = 255
local humanoid
local character

local gui = Instance.new("ScreenGui")
gui.Name = "SpeedPanel"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 75)
frame.Position = UDim2.new(0.05, 0, 0.4, 0)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local topLine = Instance.new("Frame")
topLine.Size = UDim2.new(1, 0, 0, 3)
topLine.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
topLine.BorderSizePixel = 0
topLine.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.Position = UDim2.new(0, 0, 0, 3)
title.BackgroundTransparency = 1
title.Text = "SPEED"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.Parent = frame

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0, 75, 0, 30)
speedBox.Position = UDim2.new(0, 10, 0, 35)
speedBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
speedBox.BorderSizePixel = 0
speedBox.Text = "255"
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.Font = Enum.Font.SourceSans
speedBox.TextSize = 16
speedBox.ClearTextOnFocus = false
speedBox.Parent = frame

local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 5)
speedCorner.Parent = speedBox

local speedButton = Instance.new("TextButton")
speedButton.Size = UDim2.new(0, 80, 0, 30)
speedButton.Position = UDim2.new(0, 90, 0, 35)
speedButton.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
speedButton.BorderSizePixel = 0
speedButton.Text = "APLICAR"
speedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
speedButton.Font = Enum.Font.SourceSansBold
speedButton.TextSize = 12
speedButton.Parent = frame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 5)
buttonCorner.Parent = speedButton

local function atualizarPersonagem(char)
	character = char
	humanoid = char:WaitForChild("Humanoid", 10)

	if humanoid then
		humanoid.WalkSpeed = velocidadeAtual
	end
end

if player.Character then
	atualizarPersonagem(player.Character)
end

player.CharacterAdded:Connect(atualizarPersonagem)

speedButton.Activated:Connect(function()
	local valor = tonumber(speedBox.Text)

	if valor then
		valor = math.clamp(valor, 0, 1000)
		velocidadeAtual = valor
		speedBox.Text = tostring(valor)

		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = velocidadeAtual
		end

		speedButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		speedButton.TextColor3 = Color3.fromRGB(0, 0, 0)

		task.wait(0.08)

		if speedButton and speedButton.Parent then
			speedButton.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
			speedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	else
		speedBox.Text = tostring(velocidadeAtual)
	end
end)

humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")

task.spawn(function()
	while gui.Parent do
		if humanoid and humanoid.Parent and humanoid.WalkSpeed ~= velocidadeAtual then
			humanoid.WalkSpeed = velocidadeAtual
		end
		task.wait(0.1)
	end
end)

local arrastando = false
local toqueInicial
local posicaoInicial

title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then

		arrastando = true
		toqueInicial = input.Position
		posicaoInicial = frame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not arrastando then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.Touch
		and input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end

	local delta = input.Position - toqueInicial

	frame.Position = UDim2.new(
		posicaoInicial.X.Scale,
		posicaoInicial.X.Offset + delta.X,
		posicaoInicial.Y.Scale,
		posicaoInicial.Y.Offset + delta.Y
	)
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then

		arrastando = false
	end
end)
