
-- Spectral by Aidois
-- LocalScript: StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local SCRIPT_NAME = "SpectralLockOnCamera"
local alive = true
local lockedPlayer = nil
local aimEnabled = false
local showMenu = true

local currentTab = "Aim"
local radius = 250
local smoothness = 0.18
local smoothnessValues = {0, 0.1, 0.2, 0.3, 0.4, 0.5}
local targetPartName = "Head"
local requireVisibility = true
local espEnabled = false
local highlights = {}
local connections = {}

pcall(function()
    RunService:UnbindFromRenderStep(SCRIPT_NAME)
end)

local oldGui = PlayerGui:FindFirstChild("SpectralGUI")
if oldGui then
    oldGui:Destroy()
end

local function addConnection(connection)
    table.insert(connections, connection)
    return connection
end

-- ESP: подсветка игроков
local function removeHighlight(player)
    local highlight = highlights[player]
    if highlight then
        highlight:Destroy()
        highlights[player] = nil
    end
end

local function addHighlight(player)
    if not alive or not espEnabled or player == LocalPlayer then
        return
    end

    local character = player.Character
    if not character then
        return
    end

    removeHighlight(player)

    local highlight = Instance.new("Highlight")
    highlight.Name = "SpectralPlayerESP"
    highlight.Adornee = character
    highlight.FillColor = Color3.new(1, 1, 1)
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.8
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    highlights[player] = highlight
end

local function refreshESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if espEnabled then
                addHighlight(player)
            else
                removeHighlight(player)
            end
        end
    end
end

-- Полностью выключить скрипт
local function cleanup()
    if not alive then
        return
    end

    alive = false
    aimEnabled = false
    lockedPlayer = nil
    espEnabled = false

    pcall(function()
        RunService:UnbindFromRenderStep(SCRIPT_NAME)
    end)

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(connections)

    for player, highlight in pairs(highlights) do
        if highlight then
            highlight:Destroy()
        end
        highlights[player] = nil
    end

    local existingGui = PlayerGui:FindFirstChild("SpectralGUI")
    if existingGui then
        existingGui:Destroy()
    end
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "SpectralGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = PlayerGui

local window = Instance.new("Frame")
window.Name = "Window"
window.Size = UDim2.fromOffset(300, 390)
window.Position = UDim2.new(0, 30, 0.5, -195)
window.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
window.BorderSizePixel = 0
window.Parent = gui

local windowCorner = Instance.new("UICorner")
windowCorner.CornerRadius = UDim.new(0, 10)
windowCorner.Parent = window

local windowStroke = Instance.new("UIStroke")
windowStroke.Color = Color3.fromRGB(110, 110, 140)
windowStroke.Thickness = 1
windowStroke.Parent = window

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -55, 0, 35)
title.Position = UDim2.fromOffset(12, 5)
title.BackgroundTransparency = 1
title.Text = "Spectral"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 22
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = window

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -20, 0, 20)
subtitle.Position = UDim2.fromOffset(12, 36)
subtitle.BackgroundTransparency = 1
subtitle.Text = "by Aidois"
subtitle.TextColor3 = Color3.fromRGB(150, 150, 170)
subtitle.TextSize = 12
subtitle.Font = Enum.Font.Gotham
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = window

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.fromOffset(34, 30)
closeButton.Position = UDim2.new(1, -42, 0, 7)
closeButton.BackgroundColor3 = Color3.fromRGB(150, 45, 55)
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextSize = 18
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = window

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 7)
closeCorner.Parent = closeButton

local function makeButton(parent, text, y, height)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -24, 0, height or 34)
    button.Position = UDim2.fromOffset(12, y)
    button.BackgroundColor3 = Color3.fromRGB(39, 39, 52)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 13
    button.Font = Enum.Font.GothamMedium
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button

    return button
end

-- Вкладки
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -24, 0, 34)
tabBar.Position = UDim2.fromOffset(12, 62)
tabBar.BackgroundTransparency = 1
tabBar.Parent = window

local aimTab = Instance.new("TextButton")
aimTab.Size = UDim2.new(0.5, -4, 1, 0)
aimTab.Position = UDim2.fromOffset(0, 0)
aimTab.BackgroundColor3 = Color3.fromRGB(75, 75, 105)
aimTab.BorderSizePixel = 0
aimTab.Text = "Aim"
aimTab.TextColor3 = Color3.new(1, 1, 1)
aimTab.TextSize = 13
aimTab.Font = Enum.Font.GothamBold
aimTab.Parent = tabBar

local espTab = Instance.new("TextButton")
espTab.Size = UDim2.new(0.5, -4, 1, 0)
espTab.Position = UDim2.new(0.5, 4, 0, 0)
espTab.BackgroundColor3 = Color3.fromRGB(39, 39, 52)
espTab.BorderSizePixel = 0
espTab.Text = "ESP"
espTab.TextColor3 = Color3.new(1, 1, 1)
espTab.TextSize = 13
espTab.Font = Enum.Font.GothamBold
espTab.Parent = tabBar

for _, tab in ipairs({aimTab, espTab}) do
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = tab
end

-- Панель Aim
local aimPanel = Instance.new("Frame")
aimPanel.Size = UDim2.new(1, 0, 1, -105)
aimPanel.Position = UDim2.fromOffset(0, 105)
aimPanel.BackgroundTransparency = 1
aimPanel.Parent = window

local aimButton = makeButton(aimPanel, "Aim: OFF [Q]", 0)
local radiusButton = makeButton(aimPanel, "Радиус: 250 px", 42)
local smoothButton = makeButton(aimPanel, "Плавность: 0.18", 84)
local partButton = makeButton(aimPanel, "Часть цели: Head", 126)
local visibilityButton = makeButton(aimPanel, "Проверка видимости: ON", 168)

local aimHint = Instance.new("TextLabel")
aimHint.Size = UDim2.new(1, -24, 0, 42)
aimHint.Position = UDim2.fromOffset(12, 210)
aimHint.BackgroundTransparency = 1
aimHint.Text = "Q — включить / выключить Aim\n0.00 — мгновенный поворот камеры"
aimHint.TextColor3 = Color3.fromRGB(160, 160, 180)
aimHint.TextSize = 11
aimHint.Font = Enum.Font.Gotham
aimHint.TextWrapped = true
aimHint.Parent = aimPanel

-- Панель ESP
local espPanel = Instance.new("Frame")
espPanel.Size = UDim2.new(1, 0, 1, -105)
espPanel.Position = UDim2.fromOffset(0, 105)
espPanel.BackgroundTransparency = 1
espPanel.Visible = false
espPanel.Parent = window

local espToggleButton = makeButton(espPanel, "ESP: OFF", 0, 38)

local espInfo = Instance.new("TextLabel")
espInfo.Size = UDim2.new(1, -24, 0, 100)
espInfo.Position = UDim2.fromOffset(12, 48)
espInfo.BackgroundTransparency = 1
espInfo.Text = "Белая подсветка игроков\n\nПодсветка видна сквозь стены и обновляется при появлении персонажей."
espInfo.TextColor3 = Color3.fromRGB(190, 190, 205)
espInfo.TextSize = 12
espInfo.Font = Enum.Font.Gotham
espInfo.TextWrapped = true
espInfo.TextYAlignment = Enum.TextYAlignment.Top
espInfo.Parent = espPanel

local function switchTab(tabName)
    if not alive then return end

    currentTab = tabName
    local isAim = tabName == "Aim"

    aimPanel.Visible = isAim
    espPanel.Visible = not isAim

    aimTab.BackgroundColor3 = isAim
        and Color3.fromRGB(75, 75, 105)
        or Color3.fromRGB(39, 39, 52)

    espTab.BackgroundColor3 = not isAim
        and Color3.fromRGB(75, 75, 105)
        or Color3.fromRGB(39, 39, 52)
end

addConnection(closeButton.Activated:Connect(cleanup))

addConnection(aimTab.Activated:Connect(function()
    switchTab("Aim")
end))

addConnection(espTab.Activated:Connect(function()
    switchTab("ESP")
end))

local function updateButtons()
    aimButton.Text = aimEnabled and "Aim: ON [Q]" or "Aim: OFF [Q]"
    radiusButton.Text = "Радиус: " .. radius .. " px"
    smoothButton.Text = string.format("Плавность: %.2f", smoothness)
    partButton.Text = "Часть цели: " .. targetPartName

    visibilityButton.Text = requireVisibility
        and "Проверка видимости: ON"
        or "Проверка видимости: OFF"

    espToggleButton.Text = espEnabled and "ESP: ON" or "ESP: OFF"
end

local function getTargetPart(player)
    local character = player.Character
    if not character then return nil end

    return character:FindFirstChild(targetPartName)
        or character:FindFirstChild("HumanoidRootPart")
end

local function isVisible(part)
    if not requireVisibility then
        return true
    end

    local camera = workspace.CurrentCamera
    if not camera then return false end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}

    local direction = part.Position - camera.CFrame.Position
    local result = workspace:Raycast(
        camera.CFrame.Position,
        direction,
        params
    )

    return result == nil or result.Instance:IsDescendantOf(part.Parent)
end

local function findNearestPlayer()
    local camera = workspace.CurrentCamera
    if not camera then return nil end

    local viewport = camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
    local nearestPlayer = nil
    local nearestDistance = radius

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local humanoid = character
                and character:FindFirstChildOfClass("Humanoid")
            local part = getTargetPart(player)

            if humanoid and humanoid.Health > 0 and part then
                local point, onScreen =
                    camera:WorldToViewportPoint(part.Position)

                if onScreen and point.Z > 0 then
                    local distance = (
                        Vector2.new(point.X, point.Y) - center
                    ).Magnitude

                    if distance < nearestDistance and isVisible(part) then
                        nearestDistance = distance
                        nearestPlayer = player
                    end
                end
            end
        end
    end

    return nearestPlayer
end

local function toggleAim()
    if not alive then return end

    if aimEnabled then
        aimEnabled = false
        lockedPlayer = nil
    else
        lockedPlayer = findNearestPlayer()
        aimEnabled = lockedPlayer ~= nil
    end

    updateButtons()
end

addConnection(aimButton.Activated:Connect(toggleAim))

addConnection(radiusButton.Activated:Connect(function()
    if not alive then return end

    radius = radius + 50
    if radius > 500 then radius = 100 end

    updateButtons()
end))

addConnection(smoothButton.Activated:Connect(function()
    if not alive then return end

    local currentIndex = 1

    for i, value in ipairs(smoothnessValues) do
        if math.abs(value - smoothness) < 0.001 then
            currentIndex = i
            break
        end
    end

    local nextIndex = (currentIndex % #smoothnessValues) + 1
    smoothness = smoothnessValues[nextIndex]
    updateButtons()
end))

addConnection(partButton.Activated:Connect(function()
    if not alive then return end

    targetPartName = targetPartName == "Head"
        and "HumanoidRootPart"
        or "Head"

    updateButtons()
end))

addConnection(visibilityButton.Activated:Connect(function()
    if not alive then return end

    requireVisibility = not requireVisibility
    updateButtons()
end))

addConnection(espToggleButton.Activated:Connect(function()
    if not alive then return end

    espEnabled = not espEnabled
    refreshESP()
    updateButtons()
end))

-- Следим за появлением и удалением персонажей
local function setupPlayer(player)
    if player == LocalPlayer then return end

    addConnection(player.CharacterAdded:Connect(function()
        task.defer(function()
            if alive and espEnabled then
                addHighlight(player)
            end
        end)
    end))

    addConnection(player.CharacterRemoving:Connect(function()
        removeHighlight(player)
    end))
end

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

addConnection(Players.PlayerAdded:Connect(function(player)
    if not alive then return end

    setupPlayer(player)

    if espEnabled and player.Character then
        addHighlight(player)
    end
end))

addConnection(Players.PlayerRemoving:Connect(function(player)
    removeHighlight(player)

    if lockedPlayer == player then
        lockedPlayer = nil
    end
end))

-- Перетаскивание окна за заголовок
local dragging = false
local dragStart
local startPosition

addConnection(title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPosition = window.Position
    end
end))

addConnection(UserInputService.InputChanged:Connect(function(input)
    if not alive or not dragging then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart

        window.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end))

addConnection(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end))

-- Q включает Aim, Ctrl скрывает / показывает меню
addConnection(UserInputService.InputBegan:Connect(function(input, processed)
    if not alive then return end

    if input.KeyCode == Enum.KeyCode.LeftControl
        or input.KeyCode == Enum.KeyCode.RightControl then

        showMenu = not showMenu
        window.Visible = showMenu
        return
    end

    if processed then return end

    if input.KeyCode == Enum.KeyCode.Q then
        toggleAim()
    end
end))

-- Камера обновляется каждый кадр
RunService:BindToRenderStep(
    SCRIPT_NAME,
    Enum.RenderPriority.Camera.Value + 1,
    function(dt)
        if not alive or not aimEnabled then return end

        local camera = workspace.CurrentCamera
        if not camera then return end

        if not lockedPlayer
            or not lockedPlayer.Parent
            or not getTargetPart(lockedPlayer) then

            lockedPlayer = findNearestPlayer()
        end

        local part = lockedPlayer and getTargetPart(lockedPlayer)

        if not part then
            aimEnabled = false
            lockedPlayer = nil
            updateButtons()
            return
        end

        local desiredCFrame = CFrame.lookAt(
            camera.CFrame.Position,
            part.Position
        )

        local alpha

        if smoothness <= 0 then
            alpha = 1
        else
            alpha = 1 - math.pow(
                1 - smoothness,
                math.max(dt, 0) * 60
            )
        end

        camera.CFrame = camera.CFrame:Lerp(desiredCFrame, alpha)
    end
)

switchTab("Aim")
updateButtons()
