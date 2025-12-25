--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                   VXEZE HUB - KAITUN EDITION                  ║
    ║                      TheForge Auto Script                     ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    HƯỚNG DẪN SỬ DỤNG:
    1. Chỉnh sửa KaitunConfig bên dưới theo ý muốn
    2. Execute script
    3. Script sẽ tự động chạy theo config
    
    Overlay UI sẽ hiển thị trạng thái real-time ở giữa màn hình
]]

-- ==================== WEBHOOK ====================
WebhookConfig = {
    Url = "https://webhook.lewisakura.moe/api/webhooks/1453362570160246890/OuEXHE_nDXviKq7VXxTGdahGfLG31JDKDUuP9NEhwK1kDhWjd1mNGjeN7GtdvRaySneX",
    ScriptName = "Vxeze Hub | Kaitun Edition",
    EmbedColor = 65280
}

function sendWebhookNotification()
    httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not httpRequest then return end
    if getgenv().KaitunWebhookSent then return end  -- Anti-spam: chỉ gửi 1 lần
    getgenv().KaitunWebhookSent = true

    HttpService = game:GetService("HttpService")
    player = game:GetService("Players").LocalPlayer

    executorName = "Unknown"
    if identifyexecutor then
        executorName = identifyexecutor()
    end

    payload = {
        ["username"] = "Kaitun Logger",
        ["avatar_url"] = "https://i.imgur.com/AfFp7pu.png",
        ["embeds"] = {{
            ["title"] = "Script Executed: " .. WebhookConfig.ScriptName,
            ["color"] = WebhookConfig.EmbedColor,
            ["fields"] = {
                {
                    ["name"] = "User Info",
                    ["value"] = string.format("Display: %s\nUser: %s\nID: %s", player.DisplayName, player.Name, tostring(player.UserId)),
                    ["inline"] = true
                },
                {
                    ["name"] = "Game Info",
                    ["value"] = string.format("Place ID: %s\nJob ID: %s", tostring(game.PlaceId), game.JobId),
                    ["inline"] = true
                },
                {
                    ["name"] = "Executor",
                    ["value"] = executorName,
                    ["inline"] = false
                }
            },
            ["footer"] = {
                ["text"] = "Time: " .. os.date("%c")
            }
        }}
    }

    httpRequest({
        Url = WebhookConfig.Url,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode(payload)
    })
end

task.spawn(function()
    pcall(sendWebhookNotification)
end)

-- ==================== KAITUN CONFIG ====================
getgenv().KaitunConfig = getgenv().KaitunConfig or {
    Enabled = true,
    
    -- ================ AUTO FARM ROCK ================
    AutoFarm = {
        Enabled = true,
        RockTypes = {"Pebble", "Rock", "Boulder"},
        Tool = "Auto",
        Mode = "Down",
        Highlight = true,
        Duration = 300, -- Farm rock trong 300 giây đến monster
        RotationCount = 5 -- Farm mỗi loại rock 5 lần rồi chuyển loại
    },
    
    -- ================ AUTO FARM MONSTER ================
    AutoMonsterFarm = {
        Enabled = false,
        MonsterTypes = {"Zombie", "EliteZombie"},
        Highlight = true,
        Duration = 300, -- Farm monster trong 300 giây đến material
        RotationCount = 5 -- Farm mỗi loại monster 5 lần
    },
    
    -- ================ AUTO FARM MATERIAL ================
    AutoMaterialFarm = {
        Enabled = false,
        Materials = {"Tiny Essence", "Small Essence"},  -- Có thể nhập nhiều loại
        Duration = 300,
        RotationCount = 5  -- Farm mỗi loại material 5 lần
    },
    
    -- ================ AUTO SELL ================
    AutoSell = {
        Enabled = false,
        Ores = {"Stone", "Sand Stone", "Copper"},
        Materials = {},
        Interval = 60,
        ByRank = false,
        Ranks = {"Common"}
    },
    
    -- ================ MISC ================
    Misc = {
        FullBright = true,
        NoFog = true,
        AutoRemoveLava = true,
        OreEsp = true
    },
    KeepKaitun = true
}

-- ==================== SERVICES ====================
Players = game:GetService("Players")
TweenService = game:GetService("TweenService")
RunService = game:GetService("RunService")
ReplicatedStorage = game:GetService("ReplicatedStorage")
Workspace = game:GetService("Workspace")
Lighting = game:GetService("Lighting")

LocalPlayer = Players.LocalPlayer
playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ==================== OVERLAY UI ====================
function saveSettings()
    if not isfile or not writefile then return end
    local HttpService = game:GetService("HttpService")
    local success, json = pcall(function()
        return HttpService:JSONEncode(getgenv().KaitunConfig)
    end)
    if success then
        -- Inject filter state into config before saving
        getgenv().KaitunConfig.AutoFarm = getgenv().KaitunConfig.AutoFarm or {}
        getgenv().KaitunConfig.AutoFarm.Filters = State.rockFilters
        
        local success2, json2 = pcall(function() return HttpService:JSONEncode(getgenv().KaitunConfig) end)
        if success2 then writefile("KaitunConfig.json", json2) end
    end
end

-- Auto Save Loop (Every 0.1s)
task.spawn(function()
    while true do
        saveSettings()
        task.wait(0.1)
    end
end)

function TRIGGER_KEEP_KAITUN()
    if not getgenv().KaitunConfig.KeepKaitun then return end
    
    -- Save Config Immediately
    saveSettings()
    
    -- Queue Loader for next join
    local queue_on_teleport = queue_on_teleport or (syn and syn.queue_on_teleport)
    if queue_on_teleport then
        queue_on_teleport([[
            task.wait(5)
            if isfile and isfile("Kaitun Loader.txt") then
                loadstring(readfile("Kaitun Loader.txt"))()
            else
                loadstring(game:HttpGet("https://pandadevelopment.net/virtual/file/14c2cd0c9cad3dcb"))()
            end
        ]])
    end
    
    -- Attempt Rejoin continuously
    local TeleportService = game:GetService("TeleportService")
    while true do
        pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
        task.wait(0.5)
    end
end

-- Detect Kick/Disconnect
task.spawn(function()
    local promptOverlay = game:GetService("CoreGui"):WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay")
    promptOverlay.ChildAdded:Connect(function(child)
        if child.Name == 'ErrorPrompt' then
            TRIGGER_KEEP_KAITUN()
        end
    end)
end)

_G.KaitunOverlay = _G.KaitunOverlay or {}

_G.KaitunOverlay.Status = "Idle"
_G.KaitunOverlay.Target = ""
_G.KaitunOverlay.Progress = ""
_G.KaitunOverlay.Runtime = 0
_G.KaitunOverlay.StartTime = tick()
_G.KaitunOverlay.SoldCount = {}

-- Xóa UI cũ nếu có
existingOverlay = playerGui:FindFirstChild("KaitunOverlayGui")
if existingOverlay then existingOverlay:Destroy() end

-- Tạo ScreenGui
OverlayGui = Instance.new("ScreenGui")
OverlayGui.Name = "KaitunOverlayGui"
OverlayGui.ResetOnSpawn = false
OverlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
OverlayGui.Parent = playerGui

-- Main Frame - Glassmorphism style
MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 160)
MainFrame.Position = UDim2.new(0.5, -160, 0.15, 0) -- Gần top center
MainFrame.AnchorPoint = Vector2.new(0, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BackgroundTransparency = 0.15
MainFrame.Parent = OverlayGui

MainFrameCorner = Instance.new("UICorner")
MainFrameCorner.CornerRadius = UDim.new(0, 12)
MainFrameCorner.Parent = MainFrame

-- Neon Stroke
MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 255, 255)
MainStroke.Thickness = 2
MainStroke.Transparency = 0.3
MainStroke.Parent = MainFrame

-- Title
TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Size = UDim2.new(1, 0, 0, 35)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundColor3 = Color3.fromRGB(0, 200, 200)
TitleLabel.BackgroundTransparency = 0.7
TitleLabel.BorderSizePixel = 0
TitleLabel.Text = "VXEZE HUB"
TitleLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
TitleLabel.TextSize = 18
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Parent = MainFrame

TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleLabel

-- Status Label
StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "Status"
StatusLabel.Size = UDim2.new(1, -20, 0, 20)
StatusLabel.Position = UDim2.new(0, 10, 0, 42)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Idle"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 14
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

-- Target Label
TargetLabel = Instance.new("TextLabel")
TargetLabel.Name = "Target"
TargetLabel.Size = UDim2.new(1, -20, 0, 20)
TargetLabel.Position = UDim2.new(0, 10, 0, 62)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = "Target: -"
TargetLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
TargetLabel.TextSize = 13
TargetLabel.Font = Enum.Font.Gotham
TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetLabel.Parent = MainFrame

-- Progress Label
ProgressLabel = Instance.new("TextLabel")
ProgressLabel.Name = "Progress"
ProgressLabel.Size = UDim2.new(1, -20, 0, 20)
ProgressLabel.Position = UDim2.new(0, 10, 0, 82)
ProgressLabel.BackgroundTransparency = 1
ProgressLabel.Text = "Progress: -"
ProgressLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
ProgressLabel.TextSize = 13
ProgressLabel.Font = Enum.Font.Gotham
ProgressLabel.TextXAlignment = Enum.TextXAlignment.Left
ProgressLabel.Parent = MainFrame

-- Divider
Divider = Instance.new("Frame")
Divider.Name = "Divider"
Divider.Size = UDim2.new(1, -20, 0, 1)
Divider.Position = UDim2.new(0, 10, 0, 108)
Divider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
Divider.BorderSizePixel = 0
Divider.Parent = MainFrame

-- Stats Label
StatsLabel = Instance.new("TextLabel")
StatsLabel.Name = "Stats"
StatsLabel.Size = UDim2.new(1, -20, 0, 20)
StatsLabel.Position = UDim2.new(0, 10, 0, 115)
StatsLabel.BackgroundTransparency = 1
StatsLabel.Text = "Sold: 0 | Runtime: 00:00:00"
StatsLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
StatsLabel.TextSize = 12
StatsLabel.Font = Enum.Font.Gotham
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
StatsLabel.Parent = MainFrame

-- Close Button
CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.BackgroundTransparency = 0.5
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = MainFrame

CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 6)
CloseBtnCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Discord Button
DiscordBtn = Instance.new("TextButton")
DiscordBtn.Name = "DiscordBtn"
DiscordBtn.Size = UDim2.new(0, 70, 0, 25)
DiscordBtn.Position = UDim2.new(1, -105, 0, 5)
DiscordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242) -- Discord color
DiscordBtn.BackgroundTransparency = 0.3
DiscordBtn.Text = "Discord"
DiscordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DiscordBtn.TextSize = 12
DiscordBtn.Font = Enum.Font.GothamBold
DiscordBtn.Parent = MainFrame

DiscordBtnCorner = Instance.new("UICorner")
DiscordBtnCorner.CornerRadius = UDim.new(0, 6)
DiscordBtnCorner.Parent = DiscordBtn

DiscordBtn.MouseButton1Click:Connect(function()
    discordLink = "https://discord.gg/gqDwwxcpN"
    if setclipboard then
        setclipboard(discordLink)
        DiscordBtn.Text = "Copied!"
        
        -- Game notification
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "VXEZE HUB",
                Text = "Discord link copied to clipboard!",
                Duration = 3
            })
        end)
        
        task.delay(1.5, function()
            DiscordBtn.Text = "Discord"
        end)
    else
        print("[KAITUN] Discord: " .. discordLink)
    end
end)

-- Draggable
dragging = false
dragInput = nil
dragStart = nil
startPos = nil

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ==================== OVERLAY UPDATE FUNCTION ====================
_G.UpdateOverlay = function(status, target, progress)
    _G.KaitunOverlay.Status = status or _G.KaitunOverlay.Status
    _G.KaitunOverlay.Target = target or _G.KaitunOverlay.Target
    _G.KaitunOverlay.Progress = progress or _G.KaitunOverlay.Progress
end

-- Update loop
task.spawn(function()
    while OverlayGui and OverlayGui.Parent do
        task.wait(0.5)
        pcall(function()
            runtime = tick() - _G.KaitunOverlay.StartTime
            hours = math.floor(runtime / 3600)
            minutes = math.floor((runtime % 3600) / 60)
            seconds = math.floor(runtime % 60)
            timeStr = string.format("%02d:%02d:%02d", hours, minutes, seconds)
            
            StatusLabel.Text = "Status: " .. (_G.KaitunOverlay.Status or "Idle")
            TargetLabel.Text = "Target: " .. (_G.KaitunOverlay.Target ~= "" and _G.KaitunOverlay.Target or "-")
            ProgressLabel.Text = "Progress: " .. (_G.KaitunOverlay.Progress ~= "" and _G.KaitunOverlay.Progress or "-")
            
            soldTotal = 0
            for _, v in pairs(_G.KaitunOverlay.SoldCount) do soldTotal = soldTotal + v end
            StatsLabel.Text = "Sold: " .. soldTotal .. " | Runtime: " .. timeStr
            
            -- Glow effect khi đang hoạt động
            if _G.KaitunOverlay.Status ~= "Idle" then
                MainStroke.Color = Color3.fromRGB(0, 255, 255)
                MainStroke.Transparency = 0.1
            else
                MainStroke.Color = Color3.fromRGB(100, 100, 100)
                MainStroke.Transparency = 0.5
            end
        end)
    end
end)

-- ==================== SETTINGS PANEL V2 (WORKING VERSION) ====================
-- Xóa panel cũ nếu có
local existingGui = playerGui:FindFirstChild("KaitunSettingsV2")
if existingGui then existingGui:Destroy() end

-- Tạo ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KaitunSettingsV2"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = playerGui

-- Toggle Button (Nút mũi tên bên phải)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 30, 0, 80)
ToggleBtn.Position = UDim2.new(1, -30, 0.5, -40)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
ToggleBtn.BackgroundTransparency = 0.1
ToggleBtn.Text = "◀"
ToggleBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
ToggleBtn.TextSize = 20
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = ScreenGui

local ToggleBtnCorner = Instance.new("UICorner")
ToggleBtnCorner.CornerRadius = UDim.new(0, 8)
ToggleBtnCorner.Parent = ToggleBtn

local ToggleBtnStroke = Instance.new("UIStroke")
ToggleBtnStroke.Color = Color3.fromRGB(0, 200, 200)
ToggleBtnStroke.Thickness = 2
ToggleBtnStroke.Parent = ToggleBtn

-- Main Panel Frame
local MainPanel = Instance.new("Frame")
MainPanel.Name = "MainPanel"
MainPanel.Size = UDim2.new(0, 280, 0, 450)
MainPanel.Position = UDim2.new(1, 0, 0.5, -225)
MainPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
MainPanel.BackgroundTransparency = 0.05
MainPanel.ClipsDescendants = true
MainPanel.Parent = ScreenGui

local MainPanelCorner = Instance.new("UICorner")
MainPanelCorner.CornerRadius = UDim.new(0, 12)
MainPanelCorner.Parent = MainPanel

local MainPanelStroke = Instance.new("UIStroke")
MainPanelStroke.Color = Color3.fromRGB(0, 255, 255)
MainPanelStroke.Thickness = 2
MainPanelStroke.Parent = MainPanel

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(0, 180, 180)
TitleBar.BackgroundTransparency = 0.5
TitleBar.Parent = MainPanel

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "KAITUN SETTINGS"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Parent = TitleBar

-- Tab Container
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(1, -10, 0, 35)
TabContainer.Position = UDim2.new(0, 5, 0, 45)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = MainPanel

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 5)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabContainer

-- Content ScrollingFrame
local ContentScroll = Instance.new("ScrollingFrame")
ContentScroll.Name = "ContentScroll"
ContentScroll.Size = UDim2.new(1, -10, 1, -95)
ContentScroll.Position = UDim2.new(0, 5, 0, 85)
ContentScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
ContentScroll.BackgroundTransparency = 0.5
ContentScroll.BorderSizePixel = 0
ContentScroll.ScrollBarThickness = 5
ContentScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 200)
ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentScroll.Parent = MainPanel

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 8)
ContentCorner.Parent = ContentScroll

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 4)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = ContentScroll

local ContentPadding = Instance.new("UIPadding")
ContentPadding.PaddingTop = UDim.new(0, 5)
ContentPadding.PaddingLeft = UDim.new(0, 5)
ContentPadding.PaddingRight = UDim.new(0, 5)
ContentPadding.Parent = ContentScroll

-- Panel State
local PanelState = {
    isOpen = false,
    currentTab = "Ore",
    checkboxes = {}
}

-- Create Tab Button
local function CreateTabButton(name, displayText)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 62, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    btn.BackgroundTransparency = 0.3
    btn.Text = displayText
    btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.Parent = TabContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    return btn
end

local OreTab = CreateTabButton("Ore", "Ore")
OreTab.LayoutOrder = 1
local MonsterTab = CreateTabButton("Monster", "Monster")
MonsterTab.LayoutOrder = 2
local MaterialTab = CreateTabButton("Material", "Material")
MaterialTab.LayoutOrder = 3
local SellTab = CreateTabButton("Sell", "Sell")
SellTab.LayoutOrder = 4

-- Filter Window Removed by User Request


-- Create Checkbox
local function CreateCheckbox(id, displayName, tabName, initialState, onToggle, buildExtraContent)
    local container = Instance.new("Frame")
    -- Height will be dynamic, but starts at 30
    container.Size = UDim2.new(1, -10, 0, 30)
    container.ClipsDescendants = true -- Important for accordion effect
    container.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    container.BackgroundTransparency = 0.4
    container.Parent = ContentScroll
    container.Visible = (tabName == PanelState.currentTab)
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 6)
    containerCorner.Parent = container
    
    local checkBtn = Instance.new("TextButton")
    checkBtn.Name = "CheckBtn"
    checkBtn.Size = UDim2.new(0, 22, 0, 22)
    checkBtn.Position = UDim2.new(0, 5, 0, 4) -- Fixed top offset instead of 0.5 scale
    checkBtn.BackgroundColor3 = initialState and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 80)
    checkBtn.Text = initialState and "✓" or ""
    checkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    checkBtn.TextSize = 16
    checkBtn.Font = Enum.Font.GothamBold
    checkBtn.Parent = container
    
    local checkCorner = Instance.new("UICorner")
    checkCorner.CornerRadius = UDim.new(0, 5)
    checkCorner.Parent = checkBtn
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -40, 0, 30) -- Fixed height
    label.Position = UDim2.new(0, 32, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = displayName
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    container:SetAttribute("IsChecked", initialState)
    container:SetAttribute("TabName", tabName)
    
    checkBtn.MouseButton1Click:Connect(function()
        local currentState = container:GetAttribute("IsChecked")
        local newState = not currentState
        container:SetAttribute("IsChecked", newState)
        
        checkBtn.BackgroundColor3 = newState and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 80)
        checkBtn.Text = newState and "✓" or ""
        
        if onToggle then
            onToggle(newState)
        end
    end)
    
    if buildExtraContent then
        local settingsBtn = Instance.new("TextButton")
        settingsBtn.Name = "SettingsBtn"
        settingsBtn.Size = UDim2.new(0, 22, 0, 22)
        settingsBtn.Position = UDim2.new(1, -27, 0, 4) -- Top right relative
        settingsBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        settingsBtn.Text = "⚙"
        settingsBtn.TextColor3 = Color3.fromRGB(200, 200, 255)
        settingsBtn.Parent = container
        
        local sCorner = Instance.new("UICorner")
        sCorner.CornerRadius = UDim.new(0, 5)
        sCorner.Parent = settingsBtn
        
        local isExpanded = false
        local extraContentFrame = nil
        
        settingsBtn.MouseButton1Click:Connect(function()
            isExpanded = not isExpanded
            settingsBtn.TextColor3 = isExpanded and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(200, 200, 255)
            
            if isExpanded then
                -- Create expanded area
                extraContentFrame = Instance.new("Frame")
                extraContentFrame.Name = "ExtraContent"
                extraContentFrame.Size = UDim2.new(1, 0, 0, 0) -- Height will be set by builder
                extraContentFrame.Position = UDim2.new(0, 0, 0, 32)
                extraContentFrame.BackgroundTransparency = 1
                extraContentFrame.Parent = container
                
                local contentHeight = buildExtraContent(extraContentFrame)
                container.Size = UDim2.new(1, -10, 0, 30 + contentHeight + 5)
                settingsBtn.Text = "▲"
            else
                -- Collapse
                if extraContentFrame then extraContentFrame:Destroy() end
                container.Size = UDim2.new(1, -10, 0, 30)
                settingsBtn.Text = "⚙"
            end
            
            -- Force update update layout
            task.wait()
             ContentScroll.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10)
        end)
    end
    
    PanelState.checkboxes[id] = container
    return container
end

-- Switch Tab
local function SwitchTab(tabName)
    PanelState.currentTab = tabName
    
    OreTab.BackgroundColor3 = (tabName == "Ore") and Color3.fromRGB(0, 180, 180) or Color3.fromRGB(40, 40, 60)
    OreTab.TextColor3 = (tabName == "Ore") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
    MonsterTab.BackgroundColor3 = (tabName == "Monster") and Color3.fromRGB(0, 180, 180) or Color3.fromRGB(40, 40, 60)
    MonsterTab.TextColor3 = (tabName == "Monster") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
    MaterialTab.BackgroundColor3 = (tabName == "Material") and Color3.fromRGB(0, 180, 180) or Color3.fromRGB(40, 40, 60)
    MaterialTab.TextColor3 = (tabName == "Material") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
    SellTab.BackgroundColor3 = (tabName == "Sell") and Color3.fromRGB(0, 180, 180) or Color3.fromRGB(40, 40, 60)
    SellTab.TextColor3 = (tabName == "Sell") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
    
    for id, container in pairs(PanelState.checkboxes) do
        local containerTab = container:GetAttribute("TabName")
        container.Visible = (containerTab == tabName)
    end
    
    task.wait()
    ContentScroll.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10)
end

-- Toggle Panel
local function TogglePanel()
    PanelState.isOpen = not PanelState.isOpen
    
    local targetPanelPos = PanelState.isOpen and UDim2.new(1, -285, 0.5, -225) or UDim2.new(1, 0, 0.5, -225)
    local targetBtnPos = PanelState.isOpen and UDim2.new(1, -315, 0.5, -40) or UDim2.new(1, -30, 0.5, -40)
    
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(MainPanel, tweenInfo, {Position = targetPanelPos}):Play()
    TweenService:Create(ToggleBtn, tweenInfo, {Position = targetBtnPos}):Play()
    ToggleBtn.Text = PanelState.isOpen and "▶" or "◀"
end

-- Connect buttons
OreTab.MouseButton1Click:Connect(function() SwitchTab("Ore") end)
MonsterTab.MouseButton1Click:Connect(function() SwitchTab("Monster") end)
MaterialTab.MouseButton1Click:Connect(function() SwitchTab("Material") end)
SellTab.MouseButton1Click:Connect(function() SwitchTab("Sell") end)
ToggleBtn.MouseButton1Click:Connect(TogglePanel)

-- (Checkboxes will be populated after Static Data is defined)


-- ==================== STATE TABLE ====================
State = {
    isAutoFarmEnabled = false,
    isHighlightEnabled = false,
    isAutoSelectTool = false,
    isMonsterHighlightEnabled = false,
    isAutoMonsterFarmEnabled = false,
    isAutoMaterialFarmEnabled = false,
    isAutoSellOreEnabled = false,
    isAutoSellMaterialEnabled = false,
    isFullBrightEnabled = false,
    isNoFogEnabled = false,
    isAutoRemoveLavaEnabled = true,
    tpWalkSpeed = 1,
    tpWalkSpeed = 1,
    selectedRockTypes = {},
    rockFilters = {}, -- { ["Pebble"] = { ["Copper"]=true, ["Stone"]=false } }
    selectedTool = "Pickaxe",
    selectedMonsterTypes = {},
    selectedMonsterTypes = {},
    selectedMaterial = "Tiny Essence",
    selectedMaterialMonsters = {},
    selectedFarmMode = "Down",
    selectedSellOres = {},
    selectedSellMaterials = {},
    sellOreQuantity = 99,
    sellMaterialQuantity = 99,
    sellInterval = 60,
    sellSessionInitialized = false
}

-- Connection variables
currentRock = nil
currentMonster = nil
currentMaterialMonster = nil
activeHighlights = {}
activeMonsterHighlights = {}

flyBodyGyro = nil
flyBodyVelocity = nil
noClipConnection = nil
antiJitterConnection = nil
holdPositionConnection = nil

monsterFlyBodyGyro = nil
monsterFlyBodyVelocity = nil
monsterNoClipConnection = nil
monsterAntiJitterConnection = nil
monsterHoldPositionConnection = nil

materialFarmHoldPositionConnection = nil

-- ==================== ROTATION STATE ====================
RotationState = {
    -- Target rotation (xen kẽ giữa các target trong cùng loại farm)
    currentRockTypeIndex = 1,
    currentMonsterTypeIndex = 1,
    currentMaterialIndex = 1,
    rockFarmCount = 0,
    monsterFarmCount = 0,
    materialFarmCount = 0,
    
    -- Track last farmed to avoid counting multiple times
    lastFarmedRock = nil,
    lastFarmedMonster = nil,
    lastFarmedMaterialMonster = nil,
    
    -- Phase rotation (xen kẽ giữa Rock/Monster/Material farm theo thời gian)
    currentPhase = "Rock",  -- "Rock", "Monster", "Material"
    phaseStartTime = 0,
    
    -- Farm types lists (sẽ được populate từ config)
    rockTypesList = {},
    monsterTypesList = {},
    materialTypesList = {}
}

-- ==================== STATIC DATA ====================
FarmTypes = {
    "Pebble", "Rock", "Boulder", "Lucky Block",
    "Basalt Rock", "Basalt Core", "Basalt Vein", "Volcanic Rock",
    "Earth Crystal", "Cyan Crystal", "Crimson Crystal", "Violet Crystal",
    "Light Crystal"
}

MonsterTypes = {
    "Zombie", "EliteZombie", "Delver Zombie", "Brute Zombie",
    "Bomber", "Skeleton Rogue", "Axe Skeleton", "Deathaxe Skeleton",
    "Elite Rogue Skeleton", "Elite Deathaxe Skeleton", "Reaper",
    "Blight Pyromancer", "Slime", "Blazing Slime"
}

SellOreTypes = {
    "Stone", "Sand Stone", "Copper", "Iron", "Tin", "Silver", "Gold", "Platinum",
    "Cobalt", "Titanium", "Lapis Lazuli", "Quartz", "Amethyst", "Topaz", "Diamond", 
    "Sapphire", "Ruby", "Emerald", "Cuprite", "Eye Ore", "Rivalite", "Uranium", "Mythril"
}

MaterialDropMonsters = {
    ["Tiny Essence"] = {"Zombie", "EliteZombie", "Delver Zombie", "Skeleton Rogue"},
    ["Small Essence"] = {"Zombie", "EliteZombie", "Delver Zombie", "Skeleton Rogue"},
    ["Medium Essence"] = {"Zombie", "EliteZombie", "Delver Zombie", "Brute Zombie", "Bomber", "Skeleton Rogue", "Axe Skeleton", "Slime"},
    ["Large Essence"] = {"Brute Zombie", "Bomber", "Axe Skeleton", "Deathaxe Skeleton", "Slime"},
    ["Greater Essence"] = {"Elite Rogue Skeleton", "Deathaxe Skeleton", "Elite Deathaxe Skeleton", "Reaper", "Slime"},
    ["Superior Essence"] = {"Elite Rogue Skeleton", "Elite Deathaxe Skeleton", "Reaper", "Blazing Slime"},
    ["Epic Essence"] = {"Elite Rogue Skeleton", "Deathaxe Skeleton", "Elite Deathaxe Skeleton", "Reaper", "Blazing Slime"}
}

OreRarityMap = {
    Stone = "Common", ["Sand Stone"] = "Common", Copper = "Common", Iron = "Common",
    Tin = "Uncommon", Silver = "Uncommon", Gold = "Uncommon",
    Platinum = "Rare", Cobalt = "Uncommon", Titanium = "Uncommon",
    Quartz = "Rare", Amethyst = "Rare", Topaz = "Rare", Diamond = "Rare", Sapphire = "Rare",
    Ruby = "Epic", Emerald = "Epic", Cuprite = "Epic", Rivalite = "Epic",
    Uranium = "Legendary", Mythril = "Legendary", ["Eye Ore"] = "Legendary"
}

-- ==================== POPULATE SETTINGS PANEL ====================
MaterialsList = {"Tiny Essence", "Small Essence", "Medium Essence", "Large Essence", "Greater Essence", "Superior Essence", "Epic Essence"}

-- Populate Ore checkboxes
for _, oreName in ipairs(FarmTypes) do
    isChecked = getgenv().KaitunConfig and getgenv().KaitunConfig.AutoFarm and table.find(getgenv().KaitunConfig.AutoFarm.RockTypes or {}, oreName) ~= nil
    CreateCheckbox("ore_" .. oreName, oreName, "Ore", isChecked, function(isOn)
        -- Sync với State
        if isOn then
            State.selectedRockTypes[oreName] = true
        else
            State.selectedRockTypes[oreName] = nil
        end
        -- Sync với KaitunConfig
        if getgenv().KaitunConfig and getgenv().KaitunConfig.AutoFarm then
            if not getgenv().KaitunConfig.AutoFarm.RockTypes then
                getgenv().KaitunConfig.AutoFarm.RockTypes = {}
            end
            if isOn then
                if not table.find(getgenv().KaitunConfig.AutoFarm.RockTypes, oreName) then
                    table.insert(getgenv().KaitunConfig.AutoFarm.RockTypes, oreName)
                end
            else
                for i, v in ipairs(getgenv().KaitunConfig.AutoFarm.RockTypes) do
                    if v == oreName then
                        table.remove(getgenv().KaitunConfig.AutoFarm.RockTypes, i)
                        break
                    end
                end
            end
            RotationState.rockTypesList = getgenv().KaitunConfig.AutoFarm.RockTypes
            RotationState.currentRockTypeIndex = 1
            RotationState.rockFarmCount = 0
        end
    end, function(parentFrame)
        -- Builder function for Dropdown Filter
        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 2)
        listLayout.Parent = parentFrame
        
        -- Get current filter or default
        local currentFilter = State.rockFilters[oreName] or {}
        local isFirstInit = (State.rockFilters[oreName] == nil)
        
        -- Initialize defaults if first time
        if isFirstInit then
            if not State.rockFilters[oreName] then State.rockFilters[oreName] = {} end
            for _, ore in ipairs(SellOreTypes) do
               State.rockFilters[oreName][ore] = true
            end
            currentFilter = State.rockFilters[oreName]
        end

        for _, subOre in ipairs(SellOreTypes) do
            local isSelected = currentFilter[subOre]
            if isSelected == nil then isSelected = false end -- Default false if new item? Or true? user request implies we uncheck what we dont want.
            
            local item = Instance.new("Frame")
            item.Size = UDim2.new(1, -20, 0, 25)
            item.Position = UDim2.new(0, 20, 0, 0) -- Indent
            item.BackgroundTransparency = 1
            item.Parent = parentFrame
            
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, 18, 0, 18)
            btn.Position = UDim2.new(0, 0, 0, 3)
            btn.BackgroundColor3 = isSelected and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(40, 40, 50)
            btn.Text = ""
            btn.Parent = item
            
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            
            local lbl = Instance.new("TextLabel")
            lbl.Position = UDim2.new(0, 24, 0, 0)
            lbl.Size = UDim2.new(1, -24, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = subOre
            lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 11
            lbl.Parent = item
            
            btn.MouseButton1Click:Connect(function()
                isSelected = not isSelected
                btn.BackgroundColor3 = isSelected and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(40, 40, 50)
                State.rockFilters[oreName][subOre] = isSelected
            end)
        end
        return listLayout.AbsoluteContentSize.Y
    end)
end

-- Populate Monster checkboxes
for _, monsterName in ipairs(MonsterTypes) do
    isChecked = getgenv().KaitunConfig and getgenv().KaitunConfig.AutoMonsterFarm and table.find(getgenv().KaitunConfig.AutoMonsterFarm.MonsterTypes or {}, monsterName) ~= nil
    CreateCheckbox("monster_" .. monsterName, monsterName, "Monster", isChecked, function(isOn)
        if isOn then
            State.selectedMonsterTypes[monsterName] = true
        else
            State.selectedMonsterTypes[monsterName] = nil
        end
        if getgenv().KaitunConfig and getgenv().KaitunConfig.AutoMonsterFarm then
            if not getgenv().KaitunConfig.AutoMonsterFarm.MonsterTypes then
                getgenv().KaitunConfig.AutoMonsterFarm.MonsterTypes = {}
            end
            if isOn then
                if not table.find(getgenv().KaitunConfig.AutoMonsterFarm.MonsterTypes, monsterName) then
                    table.insert(getgenv().KaitunConfig.AutoMonsterFarm.MonsterTypes, monsterName)
                end
            else
                for i, v in ipairs(getgenv().KaitunConfig.AutoMonsterFarm.MonsterTypes) do
                    if v == monsterName then
                        table.remove(getgenv().KaitunConfig.AutoMonsterFarm.MonsterTypes, i)
                        break
                    end
                end
            end
            RotationState.monsterTypesList = getgenv().KaitunConfig.AutoMonsterFarm.MonsterTypes
            RotationState.currentMonsterTypeIndex = 1
            RotationState.monsterFarmCount = 0
        end
    end)
end

-- Populate Material checkboxes
for _, matName in ipairs(MaterialsList) do
    isChecked = getgenv().KaitunConfig and getgenv().KaitunConfig.AutoMaterialFarm and table.find(getgenv().KaitunConfig.AutoMaterialFarm.Materials or {}, matName) ~= nil
    CreateCheckbox("material_" .. matName, matName, "Material", isChecked, function(isOn)
        if not getgenv().KaitunConfig.AutoMaterialFarm then
            getgenv().KaitunConfig.AutoMaterialFarm = {Materials = {}}
        end
        if not getgenv().KaitunConfig.AutoMaterialFarm.Materials then
            getgenv().KaitunConfig.AutoMaterialFarm.Materials = {}
        end
        if isOn then
            if not table.find(getgenv().KaitunConfig.AutoMaterialFarm.Materials, matName) then
                table.insert(getgenv().KaitunConfig.AutoMaterialFarm.Materials, matName)
            end
        else
            for i, v in ipairs(getgenv().KaitunConfig.AutoMaterialFarm.Materials) do
                if v == matName then
                    table.remove(getgenv().KaitunConfig.AutoMaterialFarm.Materials, i)
                    break
                end
            end
        end
        RotationState.materialTypesList = getgenv().KaitunConfig.AutoMaterialFarm.Materials
        RotationState.currentMaterialIndex = 1
        RotationState.materialFarmCount = 0
        if #RotationState.materialTypesList > 0 then
            State.selectedMaterial = RotationState.materialTypesList[1]
        end
    end)
end

-- Populate Sell Ore checkboxes
for _, oreName in ipairs(SellOreTypes) do
    isChecked = getgenv().KaitunConfig and getgenv().KaitunConfig.AutoSell and table.find(getgenv().KaitunConfig.AutoSell.Ores or {}, oreName) ~= nil
    CreateCheckbox("sell_ore_" .. oreName, oreName, "Sell", isChecked, function(isOn)
        if isOn then
            State.selectedSellOres[oreName] = true
        else
            State.selectedSellOres[oreName] = nil
        end
        if getgenv().KaitunConfig and getgenv().KaitunConfig.AutoSell then
            if not getgenv().KaitunConfig.AutoSell.Ores then
                getgenv().KaitunConfig.AutoSell.Ores = {}
            end
            if isOn then
                if not table.find(getgenv().KaitunConfig.AutoSell.Ores, oreName) then
                    table.insert(getgenv().KaitunConfig.AutoSell.Ores, oreName)
                end
            else
                for i, v in ipairs(getgenv().KaitunConfig.AutoSell.Ores) do
                    if v == oreName then
                        table.remove(getgenv().KaitunConfig.AutoSell.Ores, i)
                        break
                    end
                end
            end
        end
    end)
end

-- Populate Sell Material checkboxes
for _, matName in ipairs(MaterialsList) do
    isChecked = getgenv().KaitunConfig and getgenv().KaitunConfig.AutoSell and table.find(getgenv().KaitunConfig.AutoSell.Materials or {}, matName) ~= nil
    CreateCheckbox("sell_mat_" .. matName, matName .. " (Sell)", "Sell", isChecked, function(isOn)
        if isOn then
            State.selectedSellMaterials[matName] = true
        else
            State.selectedSellMaterials[matName] = nil
        end
        if getgenv().KaitunConfig and getgenv().KaitunConfig.AutoSell then
            if not getgenv().KaitunConfig.AutoSell.Materials then
                getgenv().KaitunConfig.AutoSell.Materials = {}
            end
            if isOn then
                if not table.find(getgenv().KaitunConfig.AutoSell.Materials, matName) then
                    table.insert(getgenv().KaitunConfig.AutoSell.Materials, matName)
                end
            else
                for i, v in ipairs(getgenv().KaitunConfig.AutoSell.Materials) do
                    if v == matName then
                        table.remove(getgenv().KaitunConfig.AutoSell.Materials, i)
                        break
                    end
                end
            end
        end
    end)
end

-- Initialize first tab
SwitchTab("Ore")

-- ==================== ROCK FARM FUNCTIONS ====================
function findAllRocks()
    rocks = {}
    rocksFolder = Workspace:FindFirstChild("Rocks")
    if rocksFolder then
        for _, child in pairs(rocksFolder:GetDescendants()) do
            if State.selectedRockTypes[child.Name] and (child:IsA("BasePart") or child:IsA("Model")) then
                table.insert(rocks, child)
            end
        end
    end
    return rocks
end

function getRockPosition(rock)
    if rock:IsA("Model") then
        primaryPart = rock.PrimaryPart or rock:FindFirstChildWhichIsA("BasePart")
        if primaryPart then return primaryPart.Position end
    elseif rock:IsA("BasePart") then
        return rock.Position
    end
    return nil
end

function getRockPart(rock)
    if rock:IsA("Model") then
        return rock.PrimaryPart or rock:FindFirstChildWhichIsA("BasePart")
    elseif rock:IsA("BasePart") then
        return rock
    end
    return nil
end

function getRockHP(rock)
    infoFrame = rock:FindFirstChild("infoFrame")
    if not infoFrame then return nil end
    frame = infoFrame:FindFirstChild("Frame")
    if not frame then return nil end
    rockHP = frame:FindFirstChild("rockHP")
    if not rockHP then return nil end
    hpText = rockHP.Text
    if hpText then
        hp = tonumber(hpText:match("[%d%.]+"))
        return hp
    end
    return nil
end

function isRockValid(rock)
    if rock == nil then return false end
    if not rock.Parent then return false end
    hp = getRockHP(rock)
    if hp ~= nil and hp <= 0 then return false end
    
    -- Filter check
    -- Filter check
    if State.rockFilters and State.rockFilters[rock.Name] then
         local foundValidOre = false
         local hasOreAttribute = false
         
         -- Helper to check filter
         local function checkAttr(obj)
             local oreAttr = obj:GetAttribute("Ore")
             if oreAttr then
                 hasOreAttribute = true
                 if State.rockFilters[rock.Name][oreAttr] == true then
                     foundValidOre = true
                 end
             end
         end
         
         -- Check rock itself
         checkAttr(rock)
         
         -- Check descendants if not found yet
         if not foundValidOre then
             for _, child in pairs(rock:GetDescendants()) do
                 checkAttr(child)
                 if foundValidOre then break end
             end
         end
         
         -- If rock has ores but none match filter, return false
         if hasOreAttribute and not foundValidOre then
             return false
         end
    end
    
    return true
end

PLAYER_SKIP_DISTANCE = 5

function isOtherPlayerNearRock(rock)
    rockPos = getRockPosition(rock)
    if not rockPos then return false end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            character = player.Character
            if character then
                humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    distance = (humanoidRootPart.Position - rockPos).Magnitude
                    if distance <= PLAYER_SKIP_DISTANCE then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function findNearestRock()
    rocks = findAllRocks()
    character = LocalPlayer.Character
    if not character then return nil end
    humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    playerPos = humanoidRootPart.Position
    nearestRock = nil
    nearestDistance = math.huge
    for _, rock in pairs(rocks) do
        rockPos = getRockPosition(rock)
        if rockPos then
            if isRockValid(rock) and not isOtherPlayerNearRock(rock) then
                distance = (rockPos - playerPos).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestRock = rock
                end
            end
        end
    end
    return nearestRock
end

ROCK_OFFSET_DOWN = -3
ROCK_OFFSET_UP = 6

function getRockOffset()
    if State.selectedFarmMode == "Up" then
        return ROCK_OFFSET_UP
    end
    return ROCK_OFFSET_DOWN
end

function enableFly(character)
    humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    if flyBodyGyro then flyBodyGyro:Destroy() end
    if flyBodyVelocity then flyBodyVelocity:Destroy() end
    
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyGyro.P = 1000000
    flyBodyGyro.D = 100
    flyBodyGyro.Parent = humanoidRootPart
    
    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.Parent = humanoidRootPart
end

function disableFly()
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
    if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
end

function enableNoClip(character)
    if noClipConnection then noClipConnection:Disconnect() end
    -- Prevent camera collision
    LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
    
    noClipConnection = RunService.Stepped:Connect(function()
        if character and character:FindFirstChild("Humanoid") then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

function disableNoClip()
    if noClipConnection then noClipConnection:Disconnect() noClipConnection = nil end
end

function enablePlatformStand(character)
    humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true
    end
end

function disablePlatformStand(character)
    humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = false
    end
end

function enableAntiJitter(character)
    if antiJitterConnection then antiJitterConnection:Disconnect() end
    humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    antiJitterConnection = RunService.RenderStepped:Connect(function()
        if humanoidRootPart and humanoidRootPart.Parent then
            humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            humanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
        end
    end)
end

function disableAntiJitter()
    if antiJitterConnection then antiJitterConnection:Disconnect() antiJitterConnection = nil end
end

function tweenToRock(rock)
    character = LocalPlayer.Character
    if not character then return false end
    humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    rockPos = getRockPosition(rock)
    if not rockPos then return false end
    distance = (rockPos - humanoidRootPart.Position).Magnitude
    tweenTime = distance / 45
    
    targetPos = rockPos + Vector3.new(0, getRockOffset(), 0)
    rotationAngle = State.selectedFarmMode == "Up" and math.rad(-90) or math.rad(90)
    lookUpCFrame = CFrame.new(targetPos) * CFrame.Angles(rotationAngle, 0, 0)
    
    tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
    tween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = lookUpCFrame})
    tween:Play()
    tween.Completed:Wait()
    return true
end

function holdPositionBelowRock(rock)
    if holdPositionConnection then holdPositionConnection:Disconnect() end
    character = LocalPlayer.Character
    if not character then return end
    humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    holdPositionConnection = RunService.Heartbeat:Connect(function()
        if not State.isAutoFarmEnabled or not isRockValid(rock) then
            if holdPositionConnection then holdPositionConnection:Disconnect() holdPositionConnection = nil end
            return
        end
        rockPos = getRockPosition(rock)
        if rockPos then
            targetPos = rockPos + Vector3.new(0, getRockOffset(), 0)
            rotationAngle = State.selectedFarmMode == "Up" and math.rad(-90) or math.rad(90)
            lookUpCFrame = CFrame.new(targetPos) * CFrame.Angles(rotationAngle, 0, 0)
            humanoidRootPart.CFrame = lookUpCFrame
            if flyBodyGyro then
                flyBodyGyro.CFrame = lookUpCFrame
            end
        end
    end)
end

function stopHoldPosition()
    if holdPositionConnection then holdPositionConnection:Disconnect() holdPositionConnection = nil end
end

function activatePickaxe()
    pcall(function()
        toolArg = State.selectedTool
        if State.selectedTool == "Weapon" then
            toolArg = "Weapon"
        end
        args = {toolArg}
        ReplicatedStorage:WaitForChild("Shared")
            :WaitForChild("Packages")
            :WaitForChild("Knit")
            :WaitForChild("Services")
            :WaitForChild("ToolService")
            :WaitForChild("RF")
            :WaitForChild("ToolActivated")
            :InvokeServer(unpack(args))
    end)
end

function getBackpackPickaxes()
    pickaxes = {"Weapon"}
    backpack = LocalPlayer:FindFirstChild("Backpack")
    character = LocalPlayer.Character
    if backpack then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and string.find(tool.Name, "Pickaxe") then
                table.insert(pickaxes, tool.Name)
            end
        end
    end
    if character then
        for _, tool in pairs(character:GetChildren()) do
            if tool:IsA("Tool") and string.find(tool.Name, "Pickaxe") then
                if not table.find(pickaxes, tool.Name) then
                    table.insert(pickaxes, tool.Name)
                end
            end
        end
    end
    return pickaxes
end

function selectBestPickaxe()
    pickaxes = getBackpackPickaxes()
    if #pickaxes > 0 then
        return pickaxes[#pickaxes]
    end
    return "Pickaxe"
end

-- ==================== HIGHLIGHT FUNCTIONS ====================
function clearAllHighlights()
    for _, highlight in pairs(activeHighlights) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    activeHighlights = {}
end

function createHighlight(rock)
    part = getRockPart(rock)
    if not part then return nil end
    existingHighlight = part:FindFirstChild("RockHighlight")
    if existingHighlight then return existingHighlight end
    highlight = Instance.new("Highlight")
    highlight.Name = "RockHighlight"
    highlight.Adornee = rock:IsA("Model") and rock or part
    highlight.FillColor = Color3.fromRGB(0, 255, 100)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = part
    table.insert(activeHighlights, highlight)
    return highlight
end

function updateHighlights()
    clearAllHighlights()
    if not State.isHighlightEnabled then return end
    rocks = findAllRocks()
    for _, rock in pairs(rocks) do
        createHighlight(rock)
    end
end

-- ==================== ORE ESP V2 FUNCTIONS ====================
ESP_RANGE = 200

function CreateOrUpdateESP(part, oreName)
    local Billboard = part:FindFirstChild("OreESP_BG")
    if not Billboard then
        Billboard = Instance.new("BillboardGui")
        Billboard.Name = "OreESP_BG"
        Billboard.Size = UDim2.new(0, 120, 0, 50)
        Billboard.StudsOffset = Vector3.new(0, 4, 0)
        Billboard.AlwaysOnTop = true
        Billboard.Parent = part
        
        local TextLabel = Instance.new("TextLabel")
        TextLabel.Name = "Label"
        TextLabel.Size = UDim2.new(1, 0, 1, 0)
        TextLabel.BackgroundTransparency = 0.5
        TextLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        TextLabel.TextStrokeTransparency = 0
        TextLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel.Font = Enum.Font.GothamBold
        TextLabel.TextScaled = true
        TextLabel.Parent = Billboard
    end
    Billboard.Label.Text = "Ore: " .. tostring(oreName)
end

function RemoveESP(part)
    local Billboard = part:FindFirstChild("OreESP_BG")
    if Billboard then Billboard:Destroy() end
end

function ScanOres()
    if not State.isOreEspEnabled then return end
    
    local PlayerPos = nil
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        PlayerPos = LocalPlayer.Character.HumanoidRootPart.Position
    end
    if not PlayerPos then return end
    
    local RocksFolder = Workspace:FindFirstChild("Rocks")
    if not RocksFolder then return end
    
    for _, Island in pairs(RocksFolder:GetChildren()) do
        for _, Rock in pairs(Island:GetChildren()) do
            pcall(function()
                for _, Child in pairs(Rock:GetDescendants()) do
                    local OreValue = Child:GetAttribute("Ore")
                    if OreValue then
                        local PartPos = nil
                        if Child:IsA("BasePart") then PartPos = Child.Position
                        elseif Child:IsA("Model") and Child.PrimaryPart then PartPos = Child.PrimaryPart.Position
                        elseif Child.Parent:IsA("BasePart") then PartPos = Child.Parent.Position end
                        
                        if PartPos then
                            local Distance = (PartPos - PlayerPos).Magnitude
                            local TargetPart = Child
                            if not Child:IsA("BasePart") then TargetPart = Child.Parent end
                            
                            if Distance <= ESP_RANGE then
                                CreateOrUpdateESP(TargetPart, OreValue)
                            else
                                RemoveESP(TargetPart)
                            end
                        end
                    end
                end
            end)
        end
    end
end

-- Ore ESP Loop
task.spawn(function()
    while true do
        pcall(ScanOres)
        task.wait(0.25) -- Run every 0.25s to save performance
    end
end)

-- ==================== MONSTER FARM FUNCTIONS ====================
function findAllMonsters()
    monsters = {}
    livingFolder = Workspace:FindFirstChild("Living")
    if livingFolder then
        for _, child in pairs(livingFolder:GetChildren()) do
            monsterName = child.Name:gsub("%d+", "")
            if State.selectedMonsterTypes[monsterName] then
                table.insert(monsters, child)
            end
        end
    end
    return monsters
end

function getMonsterPart(monster)
    if monster:IsA("Model") then
        return monster.PrimaryPart or monster:FindFirstChild("HumanoidRootPart") or monster:FindFirstChildWhichIsA("BasePart")
    elseif monster:IsA("BasePart") then
        return monster
    end
    return nil
end

function getMonsterPosition(monster)
    if monster:IsA("Model") then
        hrp = monster:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp.Position end
        primaryPart = monster.PrimaryPart or monster:FindFirstChildWhichIsA("BasePart")
        if primaryPart then return primaryPart.Position end
    elseif monster:IsA("BasePart") then
        return monster.Position
    end
    return nil
end

function getMonsterHP(monster)
    hrp = monster:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    infoFrame = hrp:FindFirstChild("infoFrame")
    if not infoFrame then return nil end
    frame = infoFrame:FindFirstChild("Frame")
    if not frame then return nil end
    rockHP = frame:FindFirstChild("rockHP")
    if not rockHP then return nil end
    hpText = rockHP.Text
    if hpText then
        hp = tonumber(hpText:match("[%d%.]+"))
        return hp
    end
    return nil
end

function isMonsterValid(monster)
    if monster == nil then return false end
    if not monster.Parent then return false end
    hp = getMonsterHP(monster)
    if hp ~= nil and hp <= 0 then return false end
    return true
end

function findNearestMonster()
    monsters = findAllMonsters()
    character = LocalPlayer.Character
    if not character then return nil end
    humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    playerPos = humanoidRootPart.Position
    nearestMonster = nil
    nearestDistance = math.huge
    for _, monster in pairs(monsters) do
        if isMonsterValid(monster) then
            monsterPos = getMonsterPosition(monster)
            if monsterPos then
                distance = (monsterPos - playerPos).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestMonster = monster
                end
            end
        end
    end
    return nearestMonster
end

MONSTER_OFFSET_DOWN = -6
MONSTER_OFFSET_UP = 8

function getMonsterOffset()
    if State.selectedFarmMode == "Up" then
        return MONSTER_OFFSET_UP
    end
    return MONSTER_OFFSET_DOWN
end

function enableMonsterFly(character)
    humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    if monsterFlyBodyGyro then monsterFlyBodyGyro:Destroy() end
    if monsterFlyBodyVelocity then monsterFlyBodyVelocity:Destroy() end
    monsterFlyBodyGyro = Instance.new("BodyGyro")
    monsterFlyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    monsterFlyBodyGyro.P = 1000000
    monsterFlyBodyGyro.D = 100
    monsterFlyBodyGyro.Parent = humanoidRootPart
    monsterFlyBodyVelocity = Instance.new("BodyVelocity")
    monsterFlyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    monsterFlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    monsterFlyBodyVelocity.Parent = humanoidRootPart
end

function disableMonsterFly()
    if monsterFlyBodyGyro then monsterFlyBodyGyro:Destroy() monsterFlyBodyGyro = nil end
    if monsterFlyBodyVelocity then monsterFlyBodyVelocity:Destroy() monsterFlyBodyVelocity = nil end
end

function enableMonsterNoClip(character)
    if monsterNoClipConnection then monsterNoClipConnection:Disconnect() end
    monsterNoClipConnection = RunService.Stepped:Connect(function()
        if character and character:FindFirstChild("Humanoid") then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

function disableMonsterNoClip()
    if monsterNoClipConnection then monsterNoClipConnection:Disconnect() monsterNoClipConnection = nil end
end

function enableMonsterAntiJitter(character)
    if monsterAntiJitterConnection then monsterAntiJitterConnection:Disconnect() end
    humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    monsterAntiJitterConnection = RunService.RenderStepped:Connect(function()
        if humanoidRootPart and humanoidRootPart.Parent then
            humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            humanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
        end
    end)
end

function disableMonsterAntiJitter()
    if monsterAntiJitterConnection then monsterAntiJitterConnection:Disconnect() monsterAntiJitterConnection = nil end
end

function tweenToMonster(monster)
    character = LocalPlayer.Character
    if not character then return false end
    humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    monsterPos = getMonsterPosition(monster)
    if not monsterPos then return false end
    distance = (monsterPos - humanoidRootPart.Position).Magnitude
    tweenTime = distance / 45
    targetPos = monsterPos + Vector3.new(0, getMonsterOffset(), 0)
    rotationAngle = State.selectedFarmMode == "Up" and math.rad(-90) or math.rad(90)
    lookUpCFrame = CFrame.new(targetPos) * CFrame.Angles(rotationAngle, 0, 0)
    tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
    tween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = lookUpCFrame})
    tween:Play()
    tween.Completed:Wait()
    return true
end

function holdPositionBelowMonster(monster)
    if monsterHoldPositionConnection then monsterHoldPositionConnection:Disconnect() end
    character = LocalPlayer.Character
    if not character then return end
    humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    monsterHoldPositionConnection = RunService.Heartbeat:Connect(function()
        if not State.isAutoMonsterFarmEnabled or not isMonsterValid(monster) then
            if monsterHoldPositionConnection then monsterHoldPositionConnection:Disconnect() monsterHoldPositionConnection = nil end
            return
        end
        monsterPos = getMonsterPosition(monster)
        if monsterPos then
            targetPos = monsterPos + Vector3.new(0, getMonsterOffset(), 0)
            rotationAngle = State.selectedFarmMode == "Up" and math.rad(-90) or math.rad(90)
            lookUpCFrame = CFrame.new(targetPos) * CFrame.Angles(rotationAngle, 0, 0)
            humanoidRootPart.CFrame = lookUpCFrame
            if monsterFlyBodyGyro then
                monsterFlyBodyGyro.CFrame = lookUpCFrame
            end
        end
    end)
end

function stopMonsterHoldPosition()
    if monsterHoldPositionConnection then monsterHoldPositionConnection:Disconnect() monsterHoldPositionConnection = nil end
end

function activateWeapon()
    pcall(function()
        args = {"Weapon"}
        ReplicatedStorage:WaitForChild("Shared")
            :WaitForChild("Packages")
            :WaitForChild("Knit")
            :WaitForChild("Services")
            :WaitForChild("ToolService")
            :WaitForChild("RF")
            :WaitForChild("ToolActivated")
            :InvokeServer(unpack(args))
    end)
end

-- ==================== SELL FUNCTIONS ====================
function getSellReplicaData()
    replicaData = nil
    pcall(function()
        Knit = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Knit"))
        PlayerController = Knit.GetController("PlayerController")
        if PlayerController and PlayerController.Replica then
            replicaData = PlayerController.Replica.Data
        end
    end)
    return replicaData
end

function initializeSellSession()
    if State.sellSessionInitialized then return true end
    
    success = pcall(function()
        greedyCey = Workspace:WaitForChild("Proximity", 5):WaitForChild("Greedy Cey", 5)
        if not greedyCey then error("Greedy Cey not found") end
        
        npcPos = nil
        if greedyCey.PrimaryPart then
            npcPos = greedyCey.PrimaryPart.Position
        elseif greedyCey:FindFirstChild("HumanoidRootPart") then
            npcPos = greedyCey.HumanoidRootPart.Position
        else
            for _, part in pairs(greedyCey:GetDescendants()) do
                if part:IsA("BasePart") then
                    npcPos = part.Position
                    break
                end
            end
        end
        
        character = LocalPlayer.Character
        hrp = character and character:FindFirstChild("HumanoidRootPart")
        
        if npcPos and hrp then
            targetCFrame = CFrame.new(npcPos + Vector3.new(0, 3, 3), npcPos)
            distance = (npcPos - hrp.Position).Magnitude
            tweenTime = math.clamp(distance / 80, 0.5, 5)
            tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
            
            humanoid = character:FindFirstChild("Humanoid")
            if humanoid then humanoid.PlatformStand = true end
            hrp.Anchored = true
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            
            tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
            tween:Play()
            tween.Completed:Wait()
            
            hrp.Anchored = false
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            if humanoid then humanoid.PlatformStand = false end
            
            task.wait(0.3)
        end
        
        ReplicatedStorage.Shared.Packages.Knit.Services.ProximityService.RF.Dialogue:InvokeServer(greedyCey)
        task.wait(0.2)
        ReplicatedStorage.Shared.Packages.Knit.Services.DialogueService.RE.DialogueEvent:FireServer("Opened")
    end)
    
    task.wait(2)
    pcall(function()
        ReplicatedStorage.Shared.Packages.Knit.Services.DialogueService.RE.DialogueEvent:FireServer("Closed")
    end)
    
    if success then
        State.sellSessionInitialized = true
    end
    return success
end

function sellItems(basket)
    if not next(basket) then return false end
    
    if not State.sellSessionInitialized then
        initializeSellSession()
    end
    
    return pcall(function()
        ReplicatedStorage.Shared.Packages.Knit.Services.DialogueService.RF.RunCommand
            :InvokeServer("SellConfirm", {Basket = basket})
    end)
end

function buildOreBasket()
    basket = {}
    for oreName, isSelected in pairs(State.selectedSellOres) do
        if isSelected then
            basket[oreName] = State.sellOreQuantity
        end
    end
    return basket
end

function buildMaterialBasket()
    basket = {}
    for matName, isSelected in pairs(State.selectedSellMaterials) do
        if isSelected then
            basket[matName] = State.sellMaterialQuantity
        end
    end
    return basket
end

-- ==================== MISC FUNCTIONS ====================
function enableFullBright()
    pcall(function()
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") then v.Density = 0 end
        end
    end)
end

function disableFullBright()
    pcall(function()
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.FogEnd = 1000
        Lighting.GlobalShadows = true
    end)
end

function enableNoFog()
    pcall(function()
        Lighting.FogStart = 0
        Lighting.FogEnd = 100000000
        Lighting.FogColor = Color3.fromRGB(255, 255, 255)
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") then 
                v.Density = 0 
                v.Offset = 0
            end
        end
    end)
end

function removeAllLava()
    count = 0
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            name = obj.Name:lower()
            isCrackedLava = obj.Material == Enum.Material.CrackedLava
            isNeonOrange = obj.BrickColor == BrickColor.new("Bright orange") and obj.Material == Enum.Material.Neon
            if name:find("lava") or isCrackedLava or isNeonOrange then
                obj.CanCollide = false
                obj.CanTouch = false
                obj.Transparency = 1
                count = count + 1
            end
        end
    end
    return count
end

-- ==================== APPLY KAITUN CONFIG ====================
function applyKaitunConfig()
    cfg = getgenv().KaitunConfig
    if not cfg or not cfg.Enabled then return end
    
    -- Apply Auto Farm Rock
    if cfg.AutoFarm and cfg.AutoFarm.Enabled then
        State.selectedRockTypes = {}
        for _, rockType in ipairs(cfg.AutoFarm.RockTypes or {}) do
            State.selectedRockTypes[rockType] = true
        end
        State.selectedFarmMode = cfg.AutoFarm.Mode or "Down"
        State.isHighlightEnabled = cfg.AutoFarm.Highlight or false
        
        if cfg.AutoFarm.Tool == "Auto" then
            State.selectedTool = selectBestPickaxe()
        else
            State.selectedTool = cfg.AutoFarm.Tool
        end
        
        -- Load Filters
        if cfg.AutoFarm.Filters then
             State.rockFilters = cfg.AutoFarm.Filters
        else
             State.rockFilters = {}
        end
        
        State.isAutoFarmEnabled = true
    end
    
    -- Apply Auto Monster Farm
    if cfg.AutoMonsterFarm and cfg.AutoMonsterFarm.Enabled then
        State.selectedMonsterTypes = {}
        for _, monsterType in ipairs(cfg.AutoMonsterFarm.MonsterTypes or {}) do
            State.selectedMonsterTypes[monsterType] = true
        end
        State.isMonsterHighlightEnabled = cfg.AutoMonsterFarm.Highlight or false
        State.isAutoMonsterFarmEnabled = true
    end
    
    -- Apply Auto Material Farm
    if cfg.AutoMaterialFarm and cfg.AutoMaterialFarm.Enabled then
        State.selectedMaterial = cfg.AutoMaterialFarm.Material or "Tiny Essence"
        State.selectedMaterialMonsters = MaterialDropMonsters[State.selectedMaterial] or {"Zombie"}
        State.isAutoMaterialFarmEnabled = true
    end
    
    -- Apply Auto Sell
    if cfg.AutoSell and cfg.AutoSell.Enabled then
        State.selectedSellOres = {}
        for _, ore in ipairs(cfg.AutoSell.Ores or {}) do
            State.selectedSellOres[ore] = true
        end
        State.selectedSellMaterials = {}
        for _, mat in ipairs(cfg.AutoSell.Materials or {}) do
            State.selectedSellMaterials[mat] = true
        end
        State.sellInterval = cfg.AutoSell.Interval or 60
        
        -- By Rank
        if cfg.AutoSell.ByRank then
            for _, rank in ipairs(cfg.AutoSell.Ranks or {"Common"}) do
                for ore, oreRank in pairs(OreRarityMap) do
                    if oreRank == rank then
                        State.selectedSellOres[ore] = true
                    end
                end
            end
        end
        
        State.isAutoSellOreEnabled = true
        State.isAutoSellMaterialEnabled = #(cfg.AutoSell.Materials or {}) > 0
    end
    
    -- Apply Misc
    if cfg.Misc then
        if cfg.Misc.FullBright then enableFullBright() end
        if cfg.Misc.NoFog then enableNoFog() end
        if cfg.Misc.AutoRemoveLava then removeAllLava() end
        State.isOreEspEnabled = cfg.Misc.OreEsp or false
    end
end

-- ==================== ROTATION HELPER FUNCTIONS ====================
function getCurrentRockType()
    cfg = getgenv().KaitunConfig
    if not cfg or not cfg.AutoFarm or not cfg.AutoFarm.RockTypes then return nil end
    if #RotationState.rockTypesList == 0 then
        RotationState.rockTypesList = cfg.AutoFarm.RockTypes
    end
    if #RotationState.rockTypesList == 0 then return nil end
    return RotationState.rockTypesList[RotationState.currentRockTypeIndex]
end

function getCurrentMonsterType()
    cfg = getgenv().KaitunConfig
    if not cfg or not cfg.AutoMonsterFarm or not cfg.AutoMonsterFarm.MonsterTypes then return nil end
    if #RotationState.monsterTypesList == 0 then
        RotationState.monsterTypesList = cfg.AutoMonsterFarm.MonsterTypes
    end
    if #RotationState.monsterTypesList == 0 then return nil end
    return RotationState.monsterTypesList[RotationState.currentMonsterTypeIndex]
end

function rotateRockType()
    cfg = getgenv().KaitunConfig
    rotationCount = (cfg and cfg.AutoFarm and cfg.AutoFarm.RotationCount) or 5
    
    RotationState.rockFarmCount = RotationState.rockFarmCount + 1
    if RotationState.rockFarmCount >= rotationCount then
        RotationState.rockFarmCount = 0
        RotationState.currentRockTypeIndex = RotationState.currentRockTypeIndex + 1
        if RotationState.currentRockTypeIndex > #RotationState.rockTypesList then
            RotationState.currentRockTypeIndex = 1
        end
        -- Update State.selectedRockTypes to only include current type
        newType = getCurrentRockType()
        if newType then
            State.selectedRockTypes = {[newType] = true}
        end
    end
end

function rotateMonsterType()
    cfg = getgenv().KaitunConfig
    rotationCount = (cfg and cfg.AutoMonsterFarm and cfg.AutoMonsterFarm.RotationCount) or 5
    
    RotationState.monsterFarmCount = RotationState.monsterFarmCount + 1
    if RotationState.monsterFarmCount >= rotationCount then
        RotationState.monsterFarmCount = 0
        RotationState.currentMonsterTypeIndex = RotationState.currentMonsterTypeIndex + 1
        if RotationState.currentMonsterTypeIndex > #RotationState.monsterTypesList then
            RotationState.currentMonsterTypeIndex = 1
        end
        -- Update State.selectedMonsterTypes to only include current type
        newType = getCurrentMonsterType()
        if newType then
            State.selectedMonsterTypes = {[newType] = true}
        end
    end
end

function getCurrentMaterialType()
    cfg = getgenv().KaitunConfig
    if not cfg or not cfg.AutoMaterialFarm then return nil end
    
    -- Support cả Materials array và Material string (backward compatibility)
    materials = cfg.AutoMaterialFarm.Materials or {cfg.AutoMaterialFarm.Material}
    if type(materials) == "string" then materials = {materials} end
    
    if #RotationState.materialTypesList == 0 then
        RotationState.materialTypesList = materials
    end
    if #RotationState.materialTypesList == 0 then return nil end
    return RotationState.materialTypesList[RotationState.currentMaterialIndex]
end

function rotateMaterialType()
    cfg = getgenv().KaitunConfig
    rotationCount = (cfg and cfg.AutoMaterialFarm and cfg.AutoMaterialFarm.RotationCount) or 5
    
    -- Skip rotation if only 1 type
    if #RotationState.materialTypesList <= 1 then return end
    
    RotationState.materialFarmCount = RotationState.materialFarmCount + 1
    if RotationState.materialFarmCount >= rotationCount then
        RotationState.materialFarmCount = 0
        RotationState.currentMaterialIndex = RotationState.currentMaterialIndex + 1
        if RotationState.currentMaterialIndex > #RotationState.materialTypesList then
            RotationState.currentMaterialIndex = 1
        end
        -- Update State.selectedMaterial
        State.selectedMaterial = getCurrentMaterialType()
    end
end

function checkPhaseRotation()
    cfg = getgenv().KaitunConfig
    if not cfg then return end
    
    elapsed = tick() - RotationState.phaseStartTime
    
    if RotationState.currentPhase == "Rock" then
        if elapsed >= (cfg.AutoFarm and cfg.AutoFarm.Duration or 300) then
            -- Switch to Monster phase if enabled, else Material, else loop back
            if cfg.AutoMonsterFarm and cfg.AutoMonsterFarm.Enabled then
                switchToPhase("Monster")
            elseif cfg.AutoMaterialFarm and cfg.AutoMaterialFarm.Enabled then
                switchToPhase("Material")
            else
                RotationState.phaseStartTime = tick() -- Reset timer
            end
        end
    elseif RotationState.currentPhase == "Monster" then
        if elapsed >= (cfg.AutoMonsterFarm and cfg.AutoMonsterFarm.Duration or 300) then
            if cfg.AutoMaterialFarm and cfg.AutoMaterialFarm.Enabled then
                switchToPhase("Material")
            elseif cfg.AutoFarm and cfg.AutoFarm.Enabled then
                switchToPhase("Rock")
            else
                RotationState.phaseStartTime = tick()
            end
        end
    elseif RotationState.currentPhase == "Material" then
        if elapsed >= (cfg.AutoMaterialFarm and cfg.AutoMaterialFarm.Duration or 300) then
            if cfg.AutoFarm and cfg.AutoFarm.Enabled then
                switchToPhase("Rock")
            elseif cfg.AutoMonsterFarm and cfg.AutoMonsterFarm.Enabled then
                switchToPhase("Monster")
            else
                RotationState.phaseStartTime = tick()
            end
        end
    end
end

function switchToPhase(newPhase)
    RotationState.currentPhase = newPhase
    RotationState.phaseStartTime = tick()
    
    -- Reset current targets
    currentRock = nil
    currentMonster = nil
    stopHoldPosition()
    stopMonsterHoldPosition()
    
    -- Update State based on phase
    character = LocalPlayer.Character
    if newPhase == "Rock" then
        State.isAutoFarmEnabled = true
        State.isAutoMonsterFarmEnabled = false
        State.isAutoMaterialFarmEnabled = false
        if character then
            enableFly(character)
            enableNoClip(character)
            enableAntiJitter(character)
        end
        _G.UpdateOverlay("Phase: Rock", getCurrentRockType() or "-", "Starting...")
    elseif newPhase == "Monster" then
        State.isAutoFarmEnabled = false
        State.isAutoMonsterFarmEnabled = true
        State.isAutoMaterialFarmEnabled = false
        if character then
            enableMonsterFly(character)
            enableMonsterNoClip(character)
            enableMonsterAntiJitter(character)
        end
        _G.UpdateOverlay("Phase: Monster", getCurrentMonsterType() or "-", "Starting...")
    elseif newPhase == "Material" then
        State.isAutoFarmEnabled = false
        State.isAutoMonsterFarmEnabled = false
        State.isAutoMaterialFarmEnabled = true
        if character then
            enableMonsterFly(character)
            enableMonsterNoClip(character)
            enableMonsterAntiJitter(character)
        end
        _G.UpdateOverlay("Phase: Material", State.selectedMaterial or "-", "Starting...")
    end
end

function initializeRotation()
    cfg = getgenv().KaitunConfig
    if not cfg then return end
    
    -- Populate rotation lists
    if cfg.AutoFarm and cfg.AutoFarm.RockTypes then
        RotationState.rockTypesList = cfg.AutoFarm.RockTypes
    end
    if cfg.AutoMonsterFarm and cfg.AutoMonsterFarm.MonsterTypes then
        RotationState.monsterTypesList = cfg.AutoMonsterFarm.MonsterTypes
    end
    
    -- Set initial single target
    firstRock = getCurrentRockType()
    if firstRock then
        State.selectedRockTypes = {[firstRock] = true}
    end
    firstMonster = getCurrentMonsterType()
    if firstMonster then
        State.selectedMonsterTypes = {[firstMonster] = true}
    end
    
    -- Determine starting phase
    if cfg.AutoFarm and cfg.AutoFarm.Enabled then
        RotationState.currentPhase = "Rock"
    elseif cfg.AutoMonsterFarm and cfg.AutoMonsterFarm.Enabled then
        RotationState.currentPhase = "Monster"
    elseif cfg.AutoMaterialFarm and cfg.AutoMaterialFarm.Enabled then
        RotationState.currentPhase = "Material"
    end
    
    RotationState.phaseStartTime = tick()
end

-- ==================== MAIN AUTO LOOPS ====================
-- Phase Rotation Controller
task.spawn(function()
    while true do
        task.wait(1)
        cfg = getgenv().KaitunConfig
        if cfg and cfg.Rotation and cfg.Rotation.Enabled then
            checkPhaseRotation()
        end
    end
end)

-- Rock Farm Loop
task.spawn(function()
    while true do
        task.wait(0.1)
        if State.isAutoFarmEnabled then
            pcall(function()
                character = LocalPlayer.Character
                if character then
                    enablePlatformStand(character)
                end
                
                currentType = getCurrentRockType()
                
                if not isRockValid(currentRock) then
                    -- Determine why it's invalid (Mined or Filtered?)
                    local isFiltered = false
                    if currentRock and currentRock.Parent then
                         local hp = getRockHP(currentRock)
                         if hp and hp > 0 then
                             isFiltered = true
                         end
                    end

                    -- Only count if we actually had a rock and it's now destroyed (not just filtered)
                    if not isFiltered and currentRock ~= nil and currentRock ~= RotationState.lastFarmedRock then
                        RotationState.lastFarmedRock = currentRock
                        rotateRockType()
                        currentType = getCurrentRockType()
                    end
                    
                    stopHoldPosition()
                    currentRock = findNearestRock()
                    if currentRock then
                        rotationCount = (getgenv().KaitunConfig and getgenv().KaitunConfig.AutoFarm and getgenv().KaitunConfig.AutoFarm.RotationCount) or 5
                        _G.UpdateOverlay("Auto Farm Rock", currentType or currentRock.Name, "Moving... [" .. (RotationState.rockFarmCount) .. "/" .. rotationCount .. "]")
                        tweenToRock(currentRock)
                        holdPositionBelowRock(currentRock)
                        task.wait(0.2)
                    else
                        _G.UpdateOverlay("Auto Farm Rock", currentType or "-", "Searching...")
                    end
                end
                
                if isRockValid(currentRock) then
                    rotationCount = (getgenv().KaitunConfig and getgenv().KaitunConfig.AutoFarm and getgenv().KaitunConfig.AutoFarm.RotationCount) or 5
                    _G.UpdateOverlay("Auto Farm Rock", currentType or currentRock.Name, "Mining... [" .. (RotationState.rockFarmCount) .. "/" .. rotationCount .. "]")
                    activatePickaxe()
                end
            end)
        else
            if _G.KaitunOverlay.Status == "Auto Farm Rock" then
                _G.UpdateOverlay("Idle", "", "")
            end
        end
    end
end)

-- Monster Farm Loop
task.spawn(function()
    while true do
        task.wait(0.1)
        if State.isAutoMonsterFarmEnabled then
            pcall(function()
                character = LocalPlayer.Character
                if character then
                    enablePlatformStand(character)
                end
                
                currentType = getCurrentMonsterType()
                
                if not isMonsterValid(currentMonster) then
                    -- Only count if we actually had a monster and it's now dead
                    if currentMonster ~= nil and currentMonster ~= RotationState.lastFarmedMonster then
                        RotationState.lastFarmedMonster = currentMonster
                        rotateMonsterType()
                        currentType = getCurrentMonsterType()
                    end
                    
                    stopMonsterHoldPosition()
                    currentMonster = findNearestMonster()
                    if currentMonster then
                        monsterName = currentMonster.Name:gsub("%d+", "")
                        rotationCount = (getgenv().KaitunConfig and getgenv().KaitunConfig.AutoMonsterFarm and getgenv().KaitunConfig.AutoMonsterFarm.RotationCount) or 5
                        _G.UpdateOverlay("Auto Farm Monster", currentType or monsterName, "Moving... [" .. (RotationState.monsterFarmCount) .. "/" .. rotationCount .. "]")
                        tweenToMonster(currentMonster)
                        holdPositionBelowMonster(currentMonster)
                        task.wait(0.2)
                    else
                        _G.UpdateOverlay("Auto Farm Monster", currentType or "-", "Searching...")
                    end
                end
                
                if isMonsterValid(currentMonster) then
                    monsterName = currentMonster.Name:gsub("%d+", "")
                    rotationCount = (getgenv().KaitunConfig and getgenv().KaitunConfig.AutoMonsterFarm and getgenv().KaitunConfig.AutoMonsterFarm.RotationCount) or 5
                    _G.UpdateOverlay("Auto Farm Monster", currentType or monsterName, "Attacking... [" .. (RotationState.monsterFarmCount) .. "/" .. rotationCount .. "]")
                    activateWeapon()
                end
            end)
        else
            if _G.KaitunOverlay.Status == "Auto Farm Monster" then
                _G.UpdateOverlay("Idle", "", "")
            end
        end
    end
end)

-- Material Farm Loop (farm monster để lấy material)
task.spawn(function()
    while true do
        task.wait(0.1)
        if State.isAutoMaterialFarmEnabled then
            pcall(function()
                character = LocalPlayer.Character
                if character then
                    enablePlatformStand(character)
                end
                
                -- Get current material type
                currentMaterialType = getCurrentMaterialType() or State.selectedMaterial
                materialMonsters = MaterialDropMonsters[currentMaterialType] or {"Zombie"}
                
                if not isMonsterValid(currentMaterialMonster) then
                    -- Only count if we had a monster and it's now dead
                    if currentMaterialMonster ~= nil and currentMaterialMonster ~= RotationState.lastFarmedMaterialMonster then
                        RotationState.lastFarmedMaterialMonster = currentMaterialMonster
                        rotateMaterialType()
                        currentMaterialType = getCurrentMaterialType() or State.selectedMaterial
                        materialMonsters = MaterialDropMonsters[currentMaterialType] or {"Zombie"}
                    end
                    
                    stopMonsterHoldPosition()
                    
                    -- Find nearest monster that drops material
                    currentMaterialMonster = nil
                    nearestDistance = math.huge
                    livingFolder = Workspace:FindFirstChild("Living")
                    if livingFolder then
                        for _, child in pairs(livingFolder:GetChildren()) do
                            monsterName = child.Name:gsub("%d+", "")
                            for _, validMonster in pairs(materialMonsters) do
                                if monsterName == validMonster then
                                    hp = getMonsterHP(child)
                                    if hp == nil or hp > 0 then
                                        monsterPos = getMonsterPosition(child)
                                        if monsterPos then
                                            hrp = character and character:FindFirstChild("HumanoidRootPart")
                                            if hrp then
                                                dist = (monsterPos - hrp.Position).Magnitude
                                                if dist < nearestDistance then
                                                    nearestDistance = dist
                                                    currentMaterialMonster = child
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    if currentMaterialMonster then
                        monsterName = currentMaterialMonster.Name:gsub("%d+", "")
                        rotationCount = (getgenv().KaitunConfig and getgenv().KaitunConfig.AutoMaterialFarm and getgenv().KaitunConfig.AutoMaterialFarm.RotationCount) or 5
                        _G.UpdateOverlay("Auto Farm Material", currentMaterialType, "Moving... [" .. (RotationState.materialFarmCount) .. "/" .. rotationCount .. "]")
                        tweenToMonster(currentMaterialMonster)
                        holdPositionBelowMonster(currentMaterialMonster)
                        task.wait(0.2)
                    else
                        _G.UpdateOverlay("Auto Farm Material", currentMaterialType, "Searching...")
                    end
                end
                
                if isMonsterValid(currentMaterialMonster) then
                    monsterName = currentMaterialMonster.Name:gsub("%d+", "")
                    rotationCount = (getgenv().KaitunConfig and getgenv().KaitunConfig.AutoMaterialFarm and getgenv().KaitunConfig.AutoMaterialFarm.RotationCount) or 5
                    _G.UpdateOverlay("Auto Farm Material", currentMaterialType, "Attacking... [" .. (RotationState.materialFarmCount) .. "/" .. rotationCount .. "]")
                    activateWeapon()
                end
            end)
        else
            if _G.KaitunOverlay.Status == "Auto Farm Material" then
                _G.UpdateOverlay("Idle", "", "")
            end
        end
    end
end)

-- Sell Loop
task.spawn(function()
    while true do
        task.wait(State.sellInterval or 60)
        if State.isAutoSellOreEnabled or State.isAutoSellMaterialEnabled then
            pcall(function()
                sold = false
                if State.isAutoSellOreEnabled and next(buildOreBasket()) then
                    _G.UpdateOverlay("Auto Sell", "Ores", "Selling...")
                    sellItems(buildOreBasket())
                    sold = true
                end
                if State.isAutoSellMaterialEnabled and next(buildMaterialBasket()) then
                    _G.UpdateOverlay("Auto Sell", "Materials", "Selling...")
                    sellItems(buildMaterialBasket())
                    sold = true
                end
                if sold then
                    _G.KaitunOverlay.SoldCount["total"] = (_G.KaitunOverlay.SoldCount["total"] or 0) + 1
                end
            end)
        end
    end
end)

-- Highlight Update Loop
task.spawn(function()
    while true do
        task.wait(2)
        if State.isHighlightEnabled then
            updateHighlights()
        end
    end
end)

-- Lava Auto Remove
Workspace.DescendantAdded:Connect(function(obj)
    if State.isAutoRemoveLavaEnabled and obj:IsA("BasePart") then
        task.wait(0.1)
        name = obj.Name:lower()
        isCrackedLava = obj.Material == Enum.Material.CrackedLava
        isNeonOrange = obj.BrickColor == BrickColor.new("Bright orange") and obj.Material == Enum.Material.Neon
        if name:find("lava") or isCrackedLava or isNeonOrange then
            obj.CanCollide = false
            obj.CanTouch = false
            obj.Transparency = 1
        end
    end
end)

-- ==================== START KAITUN ====================
task.spawn(function()
    task.wait(1) -- Wait for game to load
    
    cfg = getgenv().KaitunConfig
    if cfg and cfg.Enabled then
        -- Apply Misc FIRST (before anything else)
        if cfg.Misc then
            if cfg.Misc.FullBright then 
                enableFullBright() 
                print("[KAITUN] FullBright enabled")
            end
            if cfg.Misc.NoFog then 
                enableNoFog() 
                print("[KAITUN] NoFog enabled")
            end
            if cfg.Misc.AutoRemoveLava then 
                removeAllLava() 
                State.isAutoRemoveLavaEnabled = true
                print("[KAITUN] Lava removed")
            end
        end
        
        -- Initialize sell session (tween to Greedy Cey + open/close dialog)
        _G.UpdateOverlay("Initializing", "Sell Session", "Tween to NPC...")
        initializeSellSession()
        _G.UpdateOverlay("Idle", "", "Ready")
        
        -- Apply config
        applyKaitunConfig()
        
        -- Initialize rotation system
        initializeRotation()
        
        -- Enable farm systems
        character = LocalPlayer.Character
        if State.isAutoFarmEnabled and character then
            enableFly(character)
            enableNoClip(character)
            enablePlatformStand(character)
            enableAntiJitter(character)
        end
        
        if State.isAutoMonsterFarmEnabled and character then
            enableMonsterFly(character)
            enableMonsterNoClip(character)
            enablePlatformStand(character)
            enableMonsterAntiJitter(character)
        end
        
        print("[VXEZE HUB - KAITUN] Config applied successfully!")
        print("[VXEZE HUB - KAITUN] Auto Farm: " .. tostring(State.isAutoFarmEnabled))
        print("[VXEZE HUB - KAITUN] Auto Monster: " .. tostring(State.isAutoMonsterFarmEnabled))
        print("[VXEZE HUB - KAITUN] Auto Sell: " .. tostring(State.isAutoSellOreEnabled))
    else
        _G.UpdateOverlay("Idle", "", "Config disabled")
        print("[VXEZE HUB - KAITUN] Config disabled or not set")
    end
end)

-- Respawn handler
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if State.isAutoFarmEnabled then
        enableFly(char)
        enableNoClip(char)
        enablePlatformStand(char)
        enableAntiJitter(char)
    end
    if State.isAutoMonsterFarmEnabled then
        enableMonsterFly(char)
        enableMonsterNoClip(char)
        enablePlatformStand(char)
        enableMonsterAntiJitter(char)
    end
    if State.isAutoRemoveLavaEnabled then
        task.wait(2)
        removeAllLava()
    end
end)

print("═══════════════════════════════════════════")
print("    VXEZE HUB - KAITUN EDITION LOADED!")
print("    Modify KaitunConfig to customize")
print("═══════════════════════════════════════════")
