-- CONFIGURAÇÃO CALIBRADA E PROTEGIDA CONTRA RESETS
local VelocidadeFixa = 260
local AlturaDoPulo = 80
local Player = game:GetService("Players").LocalPlayer

-- Loop seguro em segundo plano que força os valores continuamente
task.spawn(function()
    while true do
        pcall(function()
            local char = Player.Character
            if char and char.Parent then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Parent then
                    -- Ativa o sistema de força de pulo customizada
                    hum.UseJumpPower = true
                    
                    -- Corrige e força os valores caso o jogo tente resetá-los
                    if hum.WalkSpeed ~= VelocidadeFixa then
                        hum.WalkSpeed = VelocidadeFixa
                    end
                    if hum.JumpPower ~= AlturaDoPulo then
                        hum.JumpPower = AlturaDoPulo
                    end
                end
            end
        end)
        task.wait(0.1) -- Ritmo perfeito para não dar lag e vencer o anti-cheat do jogo
    end
end)
