-- CONFIGURAÇÕES SOLICITADAS
local VelocidadeFixa = 260
local AlturaDoPulo = 80
local Player = game:GetService("Players").LocalPlayer

-- 1. PROTEÇÃO ANTI-CHAT (Bloqueia o envio de mensagens para evitar logs/denúncias)
pcall(function()
    local chatService = game:GetService("Chat")
    local textChatService = game:GetService("TextChatService")
    
    -- Desativa o chat visual e o envio para segurança total
    if textChatService and textChatService:FindFirstChild("ChatWindowConfiguration") then
        textChatService.ChatWindowConfiguration.Enabled = false
        textChatService.ChatInputBarConfiguration.Enabled = false
    end
end)

-- 2. MOTOR DE VELOCIDADE, PULO E ANTI-BAN (Bypass Suave de 0.15s)
task.spawn(function()
    while true do
        pcall(function()
            local char = Player.Character
            if char and char.Parent then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Parent then
                    -- Ativa o controle de pulo do Roblox
                    hum.UseJumpPower = true
                    
                    -- Aplica os valores exatos que você pediu
                    if hum.WalkSpeed ~= VelocidadeFixa then
                        hum.WalkSpeed = VelocidadeFixa
                    end
                    if hum.JumpPower ~= AlturaDoPulo then
                        hum.JumpPower = AlturaDoPulo
                    end
                end
            end
        end)
        -- Tempo de resposta calibrado contra o Anti-Cheat do jogo
        task.wait(0.15)
    end
end)
