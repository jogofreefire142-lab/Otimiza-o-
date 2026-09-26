--==============================================================--
-- RIP_LODER • INTERFACE ORIGINAL DO PROJETO
-- Esta parte mantém a interface do arquivo original.
-- Alterações de identidade:
--   Title    -> Rip_loder : Blox Fruit
--   SubTitle -> Rip_loder
--   Discord  -> https://discord.gg/BjmaR2NEA
--
-- Não é uma UI nova/refeita.
-- É a estrutura da UI original: Redz V5 Remake,
-- mesmo minimizador, mesmo botão mobile, mesmas abas e ícones.
--==============================================================--

local redzlib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/tlredz/Library/refs/heads/main/redz-V5-remake/main.luau"
))()

local Window = redzlib:MakeWindow({
    Title = "Rip_loder : Blox Fruit",
    SubTitle = "Rip_loder",
    SaveFolder = "rip_loder.json"
})

local Minimizer = Window:NewMinimizer({
    KeyCode = Enum.KeyCode.LeftControl
})

local MobileButton = Minimizer:CreateMobileMinimizer({
    Image = "rbxassetid://127632820302449",
    BackgroundColor3 = Color3.fromRGB(0, 255, 254)
})

local Tabs = {
    Info = Window:MakeTab({
        Title = "Tab Info And Status",
        Icon = "Info"
    }),

    Main = Window:MakeTab({
        Title = "Tab Farming",
        Icon = "rbxassetid://7733960981"
    }),

    Settings = Window:MakeTab({
        Title = "Tab Setting",
        Icon = "rbxassetid://7734053495"
    }),

    Fish = Window:MakeTab({
        Title = "Tab Fishing",
        Icon = "rbxassetid://127664059821666"
    }),

    Quests = Window:MakeTab({
        Title = "Tab Quest And Item",
        Icon = "rbxassetid://13075622619"
    }),

    SeaEvent = Window:MakeTab({
        Title = "Tab Sea Event",
        Icon = "waves"
    }),

    Race = Window:MakeTab({
        Title = "Tab Mirage And Race",
        Icon = "rbxassetid://11162889532"
    }),

    Prehistoric = Window:MakeTab({
        Title = "Tab Volcano Event",
        Icon = "tent"
    }),

    Esp = Window:MakeTab({
        Title = "Tab Stats And Esp",
        Icon = "rbxassetid://7040410130"
    }),

    Raids = Window:MakeTab({
        Title = "Tab Fruit And Raid",
        Icon = "rbxassetid://11155986081"
    }),

    Combat = Window:MakeTab({
        Title = "Tab Local Player",
        Icon = "rbxassetid://13075651575"
    }),

    Travel = Window:MakeTab({
        Title = "Tab Teleport",
        Icon = "locate"
    }),

    Shop = Window:MakeTab({
        Title = "Tab Shopping",
        Icon = "rbxassetid://6031265976"
    }),

    Misc = Window:MakeTab({
        Title = "Tab Miscellaneous",
        Icon = "rbxassetid://10709783577"
    })
}

--==============================================================--
-- INFO / DISCORD
--==============================================================--

Tabs.Info:AddSection("Information")

Tabs.Info:AddDiscordInvite({
    Title = "Rip_loder | Community",
    Description = "Comunidade oficial do Rip_loder.",
    Banner = "rbxassetid://127632820302449",
    Logo = "rbxassetid://127632820302449",
    Invite = "https://discord.gg/BjmaR2NEA",
})

Tabs.Info:AddSection("Status Server")

--==============================================================--
-- FARMING — MESMA ABA DA UI ORIGINAL
--==============================================================--

local WeaponDropdown = Tabs.Main:AddDropdown({
    Name = "Select Weapon",
    Options = {
        "Melee",
        "Sword",
        "Blox Fruit",
        "Gun"
    },
    Default = "Melee",
    Callback = function(Value)
        -- Ligue aqui somente ao sistema do seu próprio jogo.
        _G.ChooseWP = Value
    end
})

local UI_SCALE = Tabs.Main:AddDropdown({
    Name = "UI Scale",
    Options = {
        "Small",
        "Normal",
        "Big"
    },
    Default = "Normal",
    Callback = function(Value)
        local scales = {
            Small = 0.8,
            Normal = 1.0,
            Big = 1.2
        }

        if Window.SetUIScale then
            Window:SetUIScale(scales[Value])
        end
    end
})

Tabs.Main:AddSection("Farming")

local FarmLevel = Tabs.Main:AddToggle({
    Name = "Auto Farm Level",
    Description = "",
    Default = false,
    Callback = function(Value)
        -- O callback deve ser conectado ao Farm Level
        -- legítimo do projeto.
        _G.Level = Value
    end
})

--==============================================================--
-- STATUS / INFORMAÇÕES DO NOVO FARM
--==============================================================--

local LevelStatus = Tabs.Main:AddParagraph(
    "Farm Level",
    "Status: OFF"
)

local function UpdateFarmInterface(running, level, quest, target, state)
    local switch = running and "ON" or "OFF"

    local text =
        "Status: " .. switch
        .. "\nLevel: " .. tostring(level or 0)
        .. "\nQuest: " .. tostring(quest or "—")
        .. "\nTarget: " .. tostring(target or "—")
        .. "\nState: " .. tostring(state or "Idle")

    LevelStatus:SetDesc(text)
end

--==============================================================--
-- FUNÇÃO OPCIONAL DE ATUALIZAÇÃO
--==============================================================--

local function ConnectFarmStatus(Farm)
    task.spawn(function()
        while Window do
            task.wait(0.25)

            if Farm then
                UpdateFarmInterface(
                    Farm.Running,
                    Farm.Level,
                    Farm.Quest and Farm.Quest.Name,
                    Farm.Target and Farm.Target.Name,
                    Farm.State
                )
            end
        end
    end)
end

-- Exemplo:
-- ConnectFarmStatus(Farm)

--==============================================================--
-- FIM DA INTERFACE ORIGINAL
--==============================================================--
