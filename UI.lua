-- ╔══════════════════════════════════════╗
-- ║         NMC PATHAN  –  UI.lua        ║
-- ╚══════════════════════════════════════╝

local Players         = game:GetService("Players")
local TweenService    = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService      = game:GetService("RunService")

local player     = Players.LocalPlayer
local playerGui  = player:WaitForChild("PlayerGui")

-- Cleanup previous instance if exists
local scriptFlag = "LuminaHub_Cleanup"
if getgenv()[scriptFlag] then
    pcall(getgenv()[scriptFlag])
end

-- Global state tracking
local activeConnections = {}
local activeToggles = {}
local activeWindows = {}
local gradientsLoopRunning = true -- Move here to avoid nil error

-- Firebase integration variables
local FIREBASE_URL = "https://lua-hack-default-rtdb.asia-southeast1.firebasedatabase.app"
local stopFirebaseLoops = false
local myId = tostring(player.UserId)

-- Function to mark user as online/offline on Firebase
local function updateFirebaseStatus(status)
    pcall(function()
        local http = game:GetService("HttpService")
        request({
            Url = FIREBASE_URL .. "/users/" .. myId .. ".json",
            Method = "PATCH",
            Headers = { ["Content-Type"] = "application/json" },
            Body = http:JSONEncode({
                status = status,
                lastSeen = os.date("!%Y-%m-%dT%H:%M:%SZ")
            })
        })
    end)
end

local function cleanupEverything()
    -- Stop Firebase loops
    stopFirebaseLoops = true
    
    -- Stop the gradients loop
    gradientsLoopRunning = false
    
    -- Mark user as offline on Firebase
    updateFirebaseStatus("offline")
    
    -- Cleanup all connections
    for _, conn in ipairs(activeConnections) do
        pcall(function() conn:Disconnect() end)
    end
    activeConnections = {}
    
    -- Cleanup all toggles (call their cleanup)
    for _, toggleObj in ipairs(activeToggles) do
        if toggleObj.State then
            pcall(function() toggleObj:SetState(false) end)
        end
    end
    activeToggles = {}
    
    -- Destroy all windows/screen guis
    for _, gui in ipairs(activeWindows) do
        pcall(function() gui:Destroy() end)
    end
    activeWindows = {}
    
    -- Cleanup ESP highlights
    for targetPlayer, highlight in pairs(highlightObjects or {}) do
        pcall(function()
            if highlight then highlight:Destroy() end
        end)
    end
    highlightObjects = {}
    
    -- Cleanup hitboxes
    stopHitboxLoop()
    resetAllHitboxes()
    
    -- Cleanup noclip
    stopNoclip()
    
    -- Remove the cleanup function from getgenv
    getgenv()[scriptFlag] = nil
end

-- Set our cleanup function for future instances
getgenv()[scriptFlag] = cleanupEverything

-- ───────────────────────────────────────
--  Always On Top Parent Detection (CoreGui / gethui / PlayerGui fallback)
-- ───────────────────────────────────────
local function getSafeGuiParent()
    local success, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if success and coreGui then
        local s, _ = pcall(function()
            local t = Instance.new("Folder")
            t.Parent = coreGui
            t:Destroy()
        end)
        if s then return coreGui end
    end
    
    local s, hui = pcall(function()
        return gethui()
    end)
    if s and hui then return hui end
    
    return playerGui
end

-- ───────────────────────────────────────
--  ScreenGui
-- ───────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "LuminaHubGUI"
screenGui.ResetOnSpawn   = false
screenGui.DisplayOrder   = 2147483647 -- Always on top of all other game menus
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = getSafeGuiParent()
table.insert(activeWindows, screenGui)

-- ───────────────────────────────────────
--  Responsive Scale
-- ───────────────────────────────────────
local camera       = workspace.CurrentCamera or workspace:WaitForChild("Camera")
local viewportSize = camera.ViewportSize
local scale        = math.clamp(math.min(viewportSize.X / 1920, viewportSize.Y / 1080), 0.55, 1.2)

-- ───────────────────────────────────────
--  Colours
-- ───────────────────────────────────────
local ACCENT_KEYS = {
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(45,  27,  105)),
    ColorSequenceKeypoint.new(0.2,  Color3.fromRGB(17,  153, 142)),
    ColorSequenceKeypoint.new(0.4,  Color3.fromRGB(138, 43,  226)),
    ColorSequenceKeypoint.new(0.6,  Color3.fromRGB(58,  12,  163)),
    ColorSequenceKeypoint.new(0.85, Color3.fromRGB(67,  97,  238)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(45,  27,  105)),
}

local COL_DARK        = Color3.fromRGB(15,  12,  41)
local COL_WHITE       = Color3.fromRGB(255, 255, 255)
local COL_DIM         = Color3.fromRGB(150, 150, 150)
local COL_DARK_YELLOW = Color3.fromRGB(180, 140, 0)
local COL_RED         = Color3.fromRGB(220, 50,  50)

-- ───────────────────────────────────────
--  Gradient / Stroke helpers
-- ───────────────────────────────────────
local allGradients = {}

local function addGradient(parent, keys)
    local g = Instance.new("UIGradient")
    g.Color  = ColorSequence.new(keys or ACCENT_KEYS)
    g.Rotation = 0
    g.Parent = parent
    table.insert(allGradients, g)
    return g
end

local function addStrokeWithGradient(parent, thickness)
    local s = Instance.new("UIStroke")
    s.Thickness        = thickness * scale
    s.Color            = COL_WHITE
    s.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
    s.Parent           = parent
    addGradient(s)
    return s
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius * scale)
    c.Parent       = parent
    return c
end

-- ───────────────────────────────────────
--  Description Subtext Helper (Color customized, No animation)
-- ───────────────────────────────────────
local function addDescription(parentFrame, layoutOrder, text, color)
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "Description"
    descLabel.Size = UDim2.new(1, -20 * scale, 0, 0)
    descLabel.Position = UDim2.new(0, 10 * scale, 0, 0)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = text
    descLabel.TextColor3 = color or Color3.fromRGB(150, 150, 160)
    descLabel.TextSize = 11 * scale
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextWrapped = true
    descLabel.LayoutOrder = layoutOrder
    descLabel.AutomaticSize = Enum.AutomaticSize.Y
    descLabel.ZIndex = 12
    descLabel.Parent = parentFrame
    return descLabel
end

-- ───────────────────────────────────────
--  Rotate Gradients Loop (RGB Rainbow Flow)
-- ───────────────────────────────────────
task.spawn(function()
    while gradientsLoopRunning do
        for i = #allGradients, 1, -1 do
            local g = allGradients[i]
            if g and g.Parent then
                pcall(function()
                    g.Rotation = (g.Rotation + 1) % 360
                end)
            else
                table.remove(allGradients, i)
            end
        end
        task.wait(0.03)
    end
end)

-- ───────────────────────────────────────
--  Panel Sizes
-- ───────────────────────────────────────
local PANEL_W        = 340 * scale
local PANEL_H        = 520 * scale
local PANEL_HORIZ_W  = 520 * scale
local PANEL_HORIZ_H  = 340 * scale
local TOPBAR_H       = 50  * scale

-- ───────────────────────────────────────
--  Keybind Registry & Listener System
-- ───────────────────────────────────────
local keybinds = {}
local activeRebind = nil -- Stores the element currently listening for a rebind input

local uisInputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if UserInputService:GetFocusedTextBox() then return end
    
    local key = input.KeyCode
    if key == Enum.KeyCode.Unknown then return end
    
    -- Handle active rebinding
    if activeRebind then
        if key == Enum.KeyCode.Backspace or key == Enum.KeyCode.Escape then
            activeRebind:SetKeybind(nil)
        else
            activeRebind:SetKeybind(key)
        end
        activeRebind = nil
        return
    end
    
    -- Handle triggering keybinds
    for _, kb in ipairs(keybinds) do
        if kb.Key == key then
            task.spawn(function()
                kb.Callback()
            end)
        end
    end
end)
table.insert(activeConnections, uisInputBeganConn)

local function updateKeybindRegistry(element, newKey, callback)
    for i = #keybinds, 1, -1 do
        if keybinds[i].Element == element then
            table.remove(keybinds, i)
        end
    end
    if newKey then
        table.insert(keybinds, {
            Element = element,
            Key = newKey,
            Callback = callback
        })
    end
end

-- ───────────────────────────────────────
--  LuminaHub Library Object
-- ───────────────────────────────────────
local LuminaHub = {}

function LuminaHub:CreateWindow(titleText)
    local Window = {}
    Window.Tabs = {}
    Window.ActiveTab = nil
    
    -- Create Menu Toggle FAB
    local menuToggleBtn = Instance.new("TextButton")
    menuToggleBtn.Name                 = "MenuToggleBtn"
    menuToggleBtn.Size                 = UDim2.new(0, 50 * scale, 0, 50 * scale)
    menuToggleBtn.Position             = UDim2.new(1, -70 * scale, 1, -70 * scale)
    menuToggleBtn.AnchorPoint          = Vector2.new(0.5, 0.5)
    menuToggleBtn.BackgroundColor3     = Color3.fromRGB(45, 27, 105)
    menuToggleBtn.BackgroundTransparency = 0.3
    menuToggleBtn.BorderSizePixel      = 0
    menuToggleBtn.Text                 = "☰"
    menuToggleBtn.TextColor3           = COL_WHITE
    menuToggleBtn.TextSize             = 22 * scale
    menuToggleBtn.Font                 = Enum.Font.GothamBold
    menuToggleBtn.ZIndex               = 100
    menuToggleBtn.AutoButtonColor      = false
    menuToggleBtn.Active               = true
    menuToggleBtn.Parent               = screenGui
    corner(menuToggleBtn, 25)
    addStrokeWithGradient(menuToggleBtn, 1)

    -- Main Panel
    local panel = Instance.new("Frame")
    panel.Name                   = "MainPanel"
    panel.Size                   = UDim2.new(0, PANEL_W, 0, PANEL_H)
    panel.Position               = UDim2.new(0.5, -PANEL_W/2, 0.5, -PANEL_H/2)
    panel.BackgroundColor3       = COL_DARK
    panel.BackgroundTransparency = 0.6
    panel.BorderSizePixel        = 0
    panel.Visible                = false
    panel.ZIndex                 = 10
    panel.ClipsDescendants       = true
    panel.Parent                 = screenGui
    corner(panel, 20)
    addStrokeWithGradient(panel, 2)
    
    Window.Panel = panel

    -- Topbar (Drag zone)
    local topBar = Instance.new("Frame")
    topBar.Name                 = "TopBar"
    topBar.Size                 = UDim2.new(1, 0, 0, TOPBAR_H)
    topBar.Position             = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundTransparency = 1
    topBar.ZIndex               = 11
    topBar.Active               = true
    topBar.Parent               = panel

    local topBarBg = Instance.new("Frame")
    topBarBg.Name                   = "TopBarBg"
    topBarBg.Size                   = UDim2.new(1, 0, 1, 0)
    topBarBg.BackgroundColor3       = Color3.fromRGB(30, 20, 70)
    topBarBg.BackgroundTransparency = 0.5
    topBarBg.BorderSizePixel        = 0
    topBarBg.ZIndex                 = 10
    topBarBg.Parent                 = topBar
    corner(topBarBg, 20)

    -- Title
    local panelTitle = Instance.new("TextLabel")
    panelTitle.Name               = "PanelTitle"
    panelTitle.Size               = UDim2.new(1, -120 * scale, 1, 0)
    panelTitle.Position           = UDim2.new(0, 20 * scale, 0, 0)
    panelTitle.BackgroundTransparency = 1
    panelTitle.Text               = titleText or "NMC PATHAN"
    panelTitle.TextColor3         = COL_WHITE
    panelTitle.TextSize           = 18 * scale
    panelTitle.Font               = Enum.Font.GothamBold
    panelTitle.TextXAlignment     = Enum.TextXAlignment.Left
    panelTitle.ZIndex             = 12
    panelTitle.Parent             = topBar
    addGradient(panelTitle)

    -- Resize Button (Vertical ↔ Horizontal)
    local resizeBtn = Instance.new("TextButton")
    resizeBtn.Name                   = "ResizeBtn"
    resizeBtn.Size                   = UDim2.new(0, 24 * scale, 0, 24 * scale)
    resizeBtn.Position               = UDim2.new(1, -90 * scale, 0.5, 0)
    resizeBtn.AnchorPoint            = Vector2.new(0.5, 0.5)
    resizeBtn.BackgroundColor3       = Color3.fromRGB(138, 43, 226)
    resizeBtn.BackgroundTransparency = 0.2
    resizeBtn.BorderSizePixel        = 0
    resizeBtn.Text                   = "⇌"
    resizeBtn.TextColor3             = COL_WHITE
    resizeBtn.TextSize               = 14 * scale
    resizeBtn.Font                   = Enum.Font.GothamBold
    resizeBtn.ZIndex                 = 12
    resizeBtn.AutoButtonColor        = false
    resizeBtn.Active                 = true
    resizeBtn.Parent                 = topBar
    corner(resizeBtn, 12)
    
    -- Minimize Button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name                   = "MinimizeBtn"
    minimizeBtn.Size                   = UDim2.new(0, 24 * scale, 0, 24 * scale)
    minimizeBtn.Position               = UDim2.new(1, -58 * scale, 0.5, 0)
    minimizeBtn.AnchorPoint            = Vector2.new(0.5, 0.5)
    minimizeBtn.BackgroundColor3       = COL_DARK_YELLOW
    minimizeBtn.BackgroundTransparency = 0.2
    minimizeBtn.BorderSizePixel        = 0
    minimizeBtn.Text                   = ""
    minimizeBtn.ZIndex                 = 12
    minimizeBtn.AutoButtonColor        = false
    minimizeBtn.Active                 = true
    minimizeBtn.Parent                 = topBar
    corner(minimizeBtn, 12)

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name                   = "CloseBtn"
    closeBtn.Size                   = UDim2.new(0, 24 * scale, 0, 24 * scale)
    closeBtn.Position               = UDim2.new(1, -26 * scale, 0.5, 0)
    closeBtn.AnchorPoint            = Vector2.new(0.5, 0.5)
    closeBtn.BackgroundColor3       = COL_RED
    closeBtn.BackgroundTransparency = 0.2
    closeBtn.BorderSizePixel        = 0
    closeBtn.Text                   = ""
    closeBtn.ZIndex                 = 12
    closeBtn.AutoButtonColor        = false
    closeBtn.Active                 = true
    closeBtn.Parent                 = topBar
    corner(closeBtn, 12)

    -- Divider line
    local divider = Instance.new("Frame")
    divider.Name             = "Divider"
    divider.Size             = UDim2.new(1, -40 * scale, 0, 1)
    divider.Position         = UDim2.new(0, 20 * scale, 0, TOPBAR_H + 4 * scale)
    divider.BackgroundColor3 = COL_WHITE
    divider.BackgroundTransparency = 0.6
    divider.BorderSizePixel  = 0
    divider.ZIndex           = 11
    divider.Parent           = panel
    addGradient(divider)

    -- Confirm Close Prompt
    local confirmPrompt = Instance.new("Frame")
    confirmPrompt.Name                   = "ConfirmPrompt"
    confirmPrompt.Size                   = UDim2.new(0, 280 * scale, 0, 150 * scale)
    confirmPrompt.Position               = UDim2.new(0.5, -140 * scale, 0.5, -75 * scale)
    confirmPrompt.BackgroundColor3       = Color3.fromRGB(20, 20, 50)
    confirmPrompt.BackgroundTransparency = 0.1
    confirmPrompt.BorderSizePixel        = 0
    confirmPrompt.Visible                = false
    confirmPrompt.ZIndex                 = 50
    confirmPrompt.Parent                 = screenGui
    corner(confirmPrompt, 15)
    addStrokeWithGradient(confirmPrompt, 1)

    local confirmTitle = Instance.new("TextLabel")
    confirmTitle.Size                 = UDim2.new(1, 0, 0, 30 * scale)
    confirmTitle.Position             = UDim2.new(0, 0, 0, 10 * scale)
    confirmTitle.BackgroundTransparency = 1
    confirmTitle.Text                 = "Close Script?"
    confirmTitle.TextColor3           = COL_WHITE
    confirmTitle.TextSize             = 18 * scale
    confirmTitle.Font               = Enum.Font.GothamBold
    confirmTitle.TextXAlignment       = Enum.TextXAlignment.Center
    confirmTitle.ZIndex               = 51
    confirmTitle.Parent               = confirmPrompt

    local confirmDesc = Instance.new("TextLabel")
    confirmDesc.Size                  = UDim2.new(1, -20 * scale, 0, 40 * scale)
    confirmDesc.Position              = UDim2.new(0, 10 * scale, 0, 45 * scale)
    confirmDesc.BackgroundTransparency = 1
    confirmDesc.Text                  = "Are you sure you want to close the script?"
    confirmDesc.TextColor3            = COL_DIM
    confirmDesc.TextSize              = 12 * scale
    confirmDesc.Font                  = Enum.Font.Gotham
    confirmDesc.TextXAlignment        = Enum.TextXAlignment.Center
    confirmDesc.TextWrapped           = true
    confirmDesc.ZIndex                = 51
    confirmDesc.Parent                = confirmPrompt

    local yesBtn = Instance.new("TextButton")
    yesBtn.Size                   = UDim2.new(0, 110 * scale, 0, 40 * scale)
    yesBtn.Position               = UDim2.new(0, 20 * scale, 1, -55 * scale)
    yesBtn.BackgroundColor3       = Color3.fromRGB(50, 180, 100)
    yesBtn.BackgroundTransparency = 0.2
    yesBtn.BorderSizePixel        = 0
    yesBtn.Text                   = "Yes"
    yesBtn.TextColor3             = COL_WHITE
    yesBtn.TextSize               = 14 * scale
    yesBtn.Font                   = Enum.Font.GothamBold
    yesBtn.ZIndex                 = 51
    yesBtn.AutoButtonColor        = false
    yesBtn.Active                 = true
    yesBtn.Parent                 = confirmPrompt
    corner(yesBtn, 10)

    local noBtn = Instance.new("TextButton")
    noBtn.Size                   = UDim2.new(0, 110 * scale, 0, 40 * scale)
    noBtn.Position               = UDim2.new(1, -130 * scale, 1, -55 * scale)
    noBtn.BackgroundColor3       = Color3.fromRGB(180, 50, 50)
    noBtn.BackgroundTransparency = 0.2
    noBtn.BorderSizePixel        = 0
    noBtn.Text                   = "No"
    noBtn.TextColor3             = COL_WHITE
    noBtn.TextSize               = 14 * scale
    noBtn.Font                   = Enum.Font.GothamBold
    noBtn.ZIndex                 = 51
    noBtn.AutoButtonColor        = false
    noBtn.Active                 = true
    noBtn.Parent                 = confirmPrompt
    corner(noBtn, 10)

    -- Drag Logic
    do
        local dragging   = false
        local dragStart  = nil
        local startPos   = nil

        local function clampPosition(pos)
            local vp     = camera.ViewportSize
            local panelW = panel.AbsoluteSize.X
            local panelH = panel.AbsoluteSize.Y
            local x = math.clamp(pos.X.Offset, 0, math.max(0, vp.X - panelW))
            local y = math.clamp(pos.Y.Offset, 0, math.max(0, vp.Y - panelH))
            return UDim2.new(0, x, 0, y)
        end

        local function beginDrag(pos)
            dragging  = true
            dragStart = pos
            startPos  = UDim2.new(0, panel.AbsolutePosition.X, 0, panel.AbsolutePosition.Y)
        end
        local function endDrag()
            dragging = false
        end
        local function moveDrag(pos)
            if not dragging then return end
            local d = pos - dragStart
            local newPos = UDim2.new(0, startPos.X.Offset + d.X, 0, startPos.Y.Offset + d.Y)
            panel.Position = clampPosition(newPos)
        end

        topBar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                beginDrag(i.Position)
            end
        end)
        topBar.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                endDrag()
            end
        end)
        topBar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch then
                beginDrag(i.Position)
            end
        end)
        topBar.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch then
                endDrag()
            end
        end)
        topBar.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch and dragging then
                moveDrag(i.Position)
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement then
                moveDrag(i.Position)
            end
        end)
    end

    -- Tab System
    local tabHeight     = 36 * scale
    local tabY          = TOPBAR_H + 18 * scale

    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, -40 * scale, 0, tabHeight)
    tabContainer.Position = UDim2.new(0, 20 * scale, 0, tabY)
    tabContainer.BackgroundTransparency = 1
    tabContainer.ZIndex = 11
    tabContainer.Parent = panel

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 4 * scale)
    tabLayout.Parent = tabContainer

    local function realignTabs()
        local count = #Window.Tabs
        if count == 0 then return end
        local totalPadding = (count - 1) * 4 * scale
        local widthScale = 1 / count
        local widthOffset = -totalPadding / count
        for _, tabObj in ipairs(Window.Tabs) do
            tabObj.Button.Size = UDim2.new(widthScale, widthOffset, 1, 0)
        end
    end

    local function setTabActive(btn, isActive)
        if isActive then
            btn.BackgroundColor3       = Color3.fromRGB(60, 30, 120)
            btn.BackgroundTransparency = 0.1
        else
            btn.BackgroundColor3       = Color3.fromRGB(30, 30, 63)
            btn.BackgroundTransparency = 0.3
        end
        local stroke = btn:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Enabled = isActive end
    end

    function Window:CreateTab(name)
        local TabObj = {}
        TabObj.Window = Window
        TabObj.LayoutOrderCounter = 0

        -- Tab button
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name             = "Tab_" .. name
        tabBtn.BorderSizePixel  = 0
        tabBtn.Text             = name
        tabBtn.TextColor3       = COL_WHITE
        tabBtn.TextSize         = 12 * scale
        tabBtn.Font             = Enum.Font.GothamBold
        tabBtn.ZIndex           = 11
        tabBtn.AutoButtonColor  = false
        tabBtn.LayoutOrder      = #Window.Tabs
        tabBtn.Parent           = tabContainer
        corner(tabBtn, 12)

        local tabGrad = Instance.new("UIGradient")
        tabGrad.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(80,  50, 150)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 80, 200)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(80,  50, 150)),
        }
        tabGrad.Rotation = 90
        tabGrad.Parent   = tabBtn

        local tabStroke = Instance.new("UIStroke")
        tabStroke.Thickness       = 1 * scale
        tabStroke.Color           = Color3.fromRGB(150, 120, 255)
        tabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        tabStroke.Enabled         = (#Window.Tabs == 0)
        tabStroke.Parent          = tabBtn

        TabObj.Button = tabBtn

        -- Content ScrollingFrame
        local content = Instance.new("ScrollingFrame")
        content.Name                 = "Content_" .. name
        content.Size                 = UDim2.new(1, -40 * scale, 1, -(tabY + tabHeight + 28 * scale))
        content.Position             = UDim2.new(0, 20 * scale, 0, tabY + tabHeight + 12 * scale)
        content.BackgroundTransparency = 1
        content.BorderSizePixel      = 0
        content.ScrollBarThickness   = 4 * scale
        content.ScrollBarImageColor3 = Color3.fromRGB(138, 43, 226)
        content.CanvasSize           = UDim2.new(0, 0, 0, 0)
        content.AutomaticCanvasSize  = Enum.AutomaticSize.Y
        content.ClipsDescendants     = true
        content.Visible              = (#Window.Tabs == 0)
        content.ZIndex               = 11
        content.Parent               = panel

        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding   = UDim.new(0, 8 * scale)
        listLayout.Parent    = content

        TabObj.ContentFrame = content

        table.insert(Window.Tabs, TabObj)
        realignTabs()

        if not Window.ActiveTab then
            Window.ActiveTab = TabObj
            setTabActive(tabBtn, true)
        else
            setTabActive(tabBtn, false)
        end

        tabBtn.MouseButton1Click:Connect(function()
            for _, t in ipairs(Window.Tabs) do
                setTabActive(t.Button, t == TabObj)
                t.ContentFrame.Visible = (t == TabObj)
            end
            Window.ActiveTab = TabObj
        end)

        -- Helper to create sections
        function TabObj:CreateSection(labelText)
            local sec = Instance.new("TextLabel")
            TabObj.LayoutOrderCounter = TabObj.LayoutOrderCounter + 10
            sec.Size                  = UDim2.new(1, 0, 0, 28 * scale)
            sec.BackgroundTransparency = 1
            sec.Text                  = "▸  " .. labelText
            sec.TextColor3            = COL_WHITE
            sec.TextSize              = 13 * scale
            sec.Font                  = Enum.Font.GothamBold
            sec.TextXAlignment        = Enum.TextXAlignment.Left
            sec.ZIndex                = 12
            sec.LayoutOrder           = TabObj.LayoutOrderCounter
            sec.Parent                = content
            addGradient(sec)
        end

        -- Base functions to add elements
        function TabObj:CreateToggle(options)
            return LuminaHub:CreateToggleElement(content, TabObj, options, false)
        end

        function TabObj:CreateButton(options)
            return LuminaHub:CreateButtonElement(content, TabObj, options, false)
        end

        function TabObj:CreateSlider(options)
            return LuminaHub:CreateSliderElement(content, TabObj, options, false)
        end

        function TabObj:CreateTextBox(options)
            return LuminaHub:CreateTextBoxElement(content, TabObj, options, false)
        end

        return TabObj
    end

    -- Transitions
    local mainPanelOpen  = false
    local isMinimized    = false
    local isTransitioning = false
    local isHorizontal   = false -- false = vertical, true = horizontal
    local activeTweens   = {}

    local function cancelTweens()
        for _, t in ipairs(activeTweens) do
            pcall(function() t:Cancel() end)
        end
        table.clear(activeTweens)
    end

    local function playPanelTween(goal, duration, style, dir, onComplete)
        cancelTweens()
        local t = TweenService:Create(panel, TweenInfo.new(duration, style, dir), goal)
        table.insert(activeTweens, t)
        t:Play()
        t.Completed:Connect(function(state)
            if state == Enum.PlaybackState.Completed and onComplete then
                onComplete()
            end
        end)
    end

    local function openPanel(instant)
        if mainPanelOpen then return end
        mainPanelOpen  = true
        isMinimized    = false
        panel.Visible  = true

        if Window.ActiveTab then
            for _, t in ipairs(Window.Tabs) do
                setTabActive(t.Button, t == Window.ActiveTab)
                t.ContentFrame.Visible = (t == Window.ActiveTab)
            end
        end

        local targetW = isHorizontal and PANEL_HORIZ_W or PANEL_W
        local targetH = isHorizontal and PANEL_HORIZ_H or PANEL_H
        if instant then
            panel.Size                   = UDim2.new(0, targetW, 0, targetH)
            panel.BackgroundTransparency = 0.6
            return
        end

        isTransitioning  = true
        panel.Size       = UDim2.new(0, targetW * 0.8, 0, TOPBAR_H)
        playPanelTween(
            { Size = UDim2.new(0, targetW, 0, targetH), BackgroundTransparency = 0.6 },
            0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
            function() isTransitioning = false end
        )
    end

    local function closePanel()
        if isTransitioning or not mainPanelOpen then return end
        mainPanelOpen   = false
        isMinimized     = false
        isTransitioning = true
        local targetW = isHorizontal and PANEL_HORIZ_W or PANEL_W
        playPanelTween(
            { Size = UDim2.new(0, targetW * 0.8, 0, TOPBAR_H), BackgroundTransparency = 1 },
            0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In,
            function()
                panel.Visible   = false
                isTransitioning = false
            end
        )
    end

    local function minimizePanel()
        if isTransitioning or not mainPanelOpen or isMinimized then return end
        isMinimized     = true
        isTransitioning = true
        local targetW = isHorizontal and PANEL_HORIZ_W or PANEL_W
        playPanelTween(
            { Size = UDim2.new(0, targetW, 0, TOPBAR_H) },
            0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In,
            function() isTransitioning = false end
        )
    end

    local function maximizePanel()
        if isTransitioning or not mainPanelOpen or not isMinimized then return end
        isMinimized     = false
        isTransitioning = true
        local targetW = isHorizontal and PANEL_HORIZ_W or PANEL_W
        local targetH = isHorizontal and PANEL_HORIZ_H or PANEL_H
        playPanelTween(
            { Size = UDim2.new(0, targetW, 0, targetH), BackgroundTransparency = 0.6 },
            0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
            function() isTransitioning = false end
        )
    end
    
    local function togglePanelOrientation()
        if isTransitioning or not mainPanelOpen then return end
        isTransitioning = true
        isHorizontal = not isHorizontal
        
        local targetW, targetH
        if isHorizontal then
            targetW = PANEL_HORIZ_W
            targetH = PANEL_HORIZ_H
        else
            targetW = PANEL_W
            targetH = PANEL_H
        end
        
        -- Keep centered
        local currentSize = panel.AbsoluteSize
        local targetSize = Vector2.new(targetW, targetH)
        local vp = camera.ViewportSize
        local newX = math.clamp(
            panel.AbsolutePosition.X + (currentSize.X - targetSize.X)/2, 
            0, 
            math.max(0, vp.X - targetSize.X)
        )
        local newY = math.clamp(
            panel.AbsolutePosition.Y + (currentSize.Y - targetSize.Y)/2, 
            0, 
            math.max(0, vp.Y - targetSize.Y)
        )
        
        playPanelTween(
            { 
                Size = UDim2.new(0, targetW, 0, targetH),
                Position = UDim2.new(0, newX, 0, newY)
            },
            0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
            function() isTransitioning = false end
        )
    end

    menuToggleBtn.MouseButton1Click:Connect(function()
        if mainPanelOpen then closePanel() else openPanel() end
    end)

    minimizeBtn.MouseButton1Click:Connect(function()
        if isMinimized then maximizePanel() else minimizePanel() end
    end)
    
    resizeBtn.MouseButton1Click:Connect(function()
        togglePanelOrientation()
    end)

    closeBtn.MouseButton1Click:Connect(function()
        confirmPrompt.Visible = true
    end)

    yesBtn.MouseButton1Click:Connect(function()
        cleanupEverything()
    end)

    noBtn.MouseButton1Click:Connect(function()
        confirmPrompt.Visible = false
    end)

    -- F8 toggle
    local f8ToggleConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.F8 then
            screenGui.Enabled = not screenGui.Enabled
        end
    end)
    table.insert(activeConnections, f8ToggleConn)

    openPanel(true)
    return Window
end

-- ───────────────────────────────────────
--  Element Building Core
-- ───────────────────────────────────────

local INACTIVE_TRACK = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(75, 70, 130)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(75, 70, 130)),
}

local function turnOffChildren(elementObj)
    if elementObj.Children then
        for _, child in ipairs(elementObj.Children) do
            if child.Type == "Toggle" and child.State then
                child:SetState(false)
            end
            turnOffChildren(child)
        end
    end
end

-- 1. TOGGLE ELEMENT BUILDER (Row is a TextButton for native Mouse/Touch support)
function LuminaHub:CreateToggleElement(parentFrame, tabObj, options, isSubElement)
    local ToggleObj = {}
    ToggleObj.Type = "Toggle"
    ToggleObj.State = options.Default or false
    ToggleObj.Children = {}
    ToggleObj.Cleanup = nil
    ToggleObj.Keybind = options.Keybind or nil
    ToggleObj.ChildContainer = nil
    ToggleObj.ListHolder = nil
    ToggleObj.LayoutOrderCounter = 0

    local rowHeight = isSubElement and (36 * scale) or (40 * scale)
    local rowBgColor = isSubElement and Color3.fromRGB(45, 40, 85) or Color3.fromRGB(55, 50, 105)
    
    if tabObj then
        tabObj.LayoutOrderCounter = tabObj.LayoutOrderCounter + 10
    end

    local layoutOrder = tabObj and tabObj.LayoutOrderCounter or (options.LayoutOrder or 0)

    local row = Instance.new("TextButton")
    row.Name                   = "Toggle_" .. (options.Name or "Toggle")
    row.Size                   = isSubElement and UDim2.new(1, -20 * scale, 0, rowHeight) or UDim2.new(1, 0, 0, rowHeight)
    row.Position               = isSubElement and UDim2.new(0, 20 * scale, 0, 0) or UDim2.new(0, 0, 0, 0)
    row.BackgroundColor3       = rowBgColor
    row.BackgroundTransparency = 0.08
    row.BorderSizePixel        = 0
    row.Text                   = ""
    row.AutoButtonColor        = false
    row.ZIndex                 = 12
    row.LayoutOrder            = layoutOrder
    row.Parent                 = parentFrame
    corner(row, 10)
    addStrokeWithGradient(row, 1)
    
    ToggleObj.Row = row

    -- Label
    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.new(1, -130 * scale, 1, 0)
    lbl.Position              = UDim2.new(0, 15 * scale, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                  = options.Name or "Toggle"
    lbl.TextColor3            = COL_WHITE
    lbl.TextSize              = isSubElement and (12 * scale) or (14 * scale)
    lbl.Font                  = Enum.Font.GothamBold
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.ZIndex                = 13
    lbl.Parent                = row

    -- Keybind Rebind Button
    local rebindBtn = Instance.new("TextButton")
    rebindBtn.Name = "RebindBtn"
    rebindBtn.Size = UDim2.new(0, 52 * scale, 0, 20 * scale)
    rebindBtn.Position = UDim2.new(1, -114 * scale, 0.5, -10 * scale)
    rebindBtn.BackgroundColor3 = Color3.fromRGB(30, 26, 62)
    rebindBtn.BackgroundTransparency = 0.4
    rebindBtn.Text = ToggleObj.Keybind and ("[ " .. ToggleObj.Keybind.Name .. " ]") or "[ None ]"
    rebindBtn.TextColor3 = COL_DIM
    rebindBtn.TextSize = 10 * scale
    rebindBtn.Font = Enum.Font.GothamBold
    rebindBtn.ZIndex = 15
    rebindBtn.Parent = row
    corner(rebindBtn, 6)
    
    local rebindStroke = Instance.new("UIStroke")
    rebindStroke.Thickness = 1
    rebindStroke.Color = Color3.fromRGB(80, 70, 120)
    rebindStroke.Parent = rebindBtn

    -- Toggle Track
    local trackFrame = Instance.new("Frame")
    trackFrame.Size             = UDim2.new(0, 48 * scale, 0, 24 * scale)
    trackFrame.Position         = UDim2.new(1, -58 * scale, 0.5, -12 * scale)
    trackFrame.BackgroundColor3 = Color3.fromRGB(75, 70, 130)
    trackFrame.BorderSizePixel  = 0
    trackFrame.ZIndex           = 13
    trackFrame.Parent           = row
    corner(trackFrame, 12)

    local trackGrad = Instance.new("UIGradient")
    trackGrad.Color  = INACTIVE_TRACK
    trackGrad.Parent = trackFrame

    -- Toggle Knob
    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 20 * scale, 0, 20 * scale)
    knob.BackgroundColor3 = COL_WHITE
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 14
    knob.Parent           = trackFrame
    corner(knob, 10)

    -- Toggle state update
    local function updateToggle(on, skipCallback)
        ToggleObj.State = on
        TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
            Position = on and UDim2.new(1, -22 * scale, 0.5, -10 * scale)
                           or UDim2.new(0,  2 * scale, 0.5, -10 * scale),
        }):Play()
        if on then
            trackGrad.Color = ColorSequence.new(ACCENT_KEYS)
            if not table.find(allGradients, trackGrad) then
                table.insert(allGradients, trackGrad)
            end
            
            -- Run callback and save clean-up returned function
            if not skipCallback and options.Callback then
                local success, result = pcall(function()
                    return options.Callback(true)
                end)
                if success and typeof(result) == "function" then
                    ToggleObj.Cleanup = result
                end
            end

            -- Display child options
            if ToggleObj.ChildContainer and ToggleObj.ListHolder then
                local ccLayout = ToggleObj.ListHolder:FindFirstChildOfClass("UIListLayout")
                local targetHeight = ccLayout and ccLayout.AbsoluteContentSize.Y or 0
                TweenService:Create(ToggleObj.ChildContainer, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(1, 0, 0, targetHeight)
                }):Play()
            end
        else
            trackGrad.Color = INACTIVE_TRACK
            local idx = table.find(allGradients, trackGrad)
            if idx then
                table.remove(allGradients, idx)
            end

            -- Run cleanup
            if ToggleObj.Cleanup then
                pcall(ToggleObj.Cleanup)
                ToggleObj.Cleanup = nil
            end

            -- Run callback off
            if not skipCallback and options.Callback then
                pcall(options.Callback, false)
            end

            -- Turn off all child options recursively to stop tasks/lag
            turnOffChildren(ToggleObj)

            -- Hide child options
            if ToggleObj.ChildContainer then
                TweenService:Create(ToggleObj.ChildContainer, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Size = UDim2.new(1, 0, 0, 0)
                }):Play()
            end
        end
    end

    function ToggleObj:SetState(on, skipCallback)
        updateToggle(on, skipCallback)
    end

    function ToggleObj:SetKeybind(key)
        ToggleObj.Keybind = key
        rebindBtn.Text = key and ("[ " .. key.Name .. " ]") or "[ None ]"
        rebindBtn.TextColor3 = key and COL_WHITE or COL_DIM
        updateKeybindRegistry(ToggleObj, key, function()
            ToggleObj:SetState(not ToggleObj.State)
        end)
    end

    updateToggle(ToggleObj.State, true)
    if ToggleObj.Keybind then
        ToggleObj:SetKeybind(ToggleObj.Keybind)
    end

    -- Click handler
    row.MouseButton1Click:Connect(function()
        updateToggle(not ToggleObj.State)
    end)

    -- Rebind handler
    rebindBtn.MouseButton1Click:Connect(function()
        if activeRebind == ToggleObj then
            activeRebind = nil
            rebindBtn.Text = ToggleObj.Keybind and ("[ " .. ToggleObj.Keybind.Name .. " ]") or "[ None ]"
            rebindBtn.TextColor3 = ToggleObj.Keybind and COL_WHITE or COL_DIM
        else
            activeRebind = ToggleObj
            rebindBtn.Text = "[ ... ]"
            rebindBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
        end
    end)

    -- Description support
    if options.Description then
        addDescription(parentFrame, layoutOrder + 1, options.Description, options.DescColor)
        if tabObj then
            tabObj.LayoutOrderCounter = tabObj.LayoutOrderCounter + 1
        end
    end

    -- Dynamic Sub Container Builder (Ignored by layout to resolve "Margin Loop")
    local function ensureChildContainer()
        if not ToggleObj.ChildContainer then
            local cc = Instance.new("Frame")
            cc.Name = "Children_" .. (options.Name or "Toggle")
            cc.Size = UDim2.new(1, 0, 0, 0)
            cc.BackgroundTransparency = 1
            cc.BorderSizePixel = 0
            cc.ClipsDescendants = true
            cc.ZIndex = 11
            cc.Parent = parentFrame
            
            local offset = options.Description and 2 or 1
            if tabObj then
                tabObj.LayoutOrderCounter = tabObj.LayoutOrderCounter + 1
            end
            cc.LayoutOrder = row.LayoutOrder + offset

            -- Vertical hierarchy tree line
            local treeLine = Instance.new("Frame")
            treeLine.Name = "TreeLine"
            treeLine.Size = UDim2.new(0, 1.5 * scale, 1, -12 * scale)
            treeLine.Position = UDim2.new(0, 8 * scale, 0, 6 * scale)
            treeLine.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
            treeLine.BackgroundTransparency = 0.5
            treeLine.BorderSizePixel = 0
            treeLine.ZIndex = 11
            treeLine.Parent = cc
            addGradient(treeLine, {
                ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(17, 153, 142))
            })

            -- ListHolder frame: holds the UIListLayout and child items so they do not conflict with TreeLine
            local listHolder = Instance.new("Frame")
            listHolder.Name = "ListHolder"
            listHolder.Size = UDim2.new(1, 0, 1, 0)
            listHolder.BackgroundTransparency = 1
            listHolder.BorderSizePixel = 0
            listHolder.ZIndex = 12
            listHolder.Parent = cc

            local ccLayout = Instance.new("UIListLayout")
            ccLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ccLayout.Padding = UDim.new(0, 6 * scale)
            ccLayout.Parent = listHolder

            ccLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if ToggleObj.State then
                    TweenService:Create(cc, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, ccLayout.AbsoluteContentSize.Y)
                    }):Play()
                end
            end)

            ToggleObj.ChildContainer = cc
            ToggleObj.ListHolder = listHolder
        end
        return ToggleObj.ChildContainer
    end

    -- Child Elements Creation methods (Parented to cc.ListHolder)
    function ToggleObj:CreateToggle(childOptions)
        ensureChildContainer()
        ToggleObj.LayoutOrderCounter = ToggleObj.LayoutOrderCounter + 10
        childOptions.LayoutOrder = ToggleObj.LayoutOrderCounter
        local child = LuminaHub:CreateToggleElement(ToggleObj.ListHolder, nil, childOptions, true)
        table.insert(ToggleObj.Children, child)
        return child
    end

    function ToggleObj:CreateButton(childOptions)
        ensureChildContainer()
        ToggleObj.LayoutOrderCounter = ToggleObj.LayoutOrderCounter + 10
        childOptions.LayoutOrder = ToggleObj.LayoutOrderCounter
        local child = LuminaHub:CreateButtonElement(ToggleObj.ListHolder, nil, childOptions, true)
        table.insert(ToggleObj.Children, child)
        return child
    end

    function ToggleObj:CreateSlider(childOptions)
        ensureChildContainer()
        ToggleObj.LayoutOrderCounter = ToggleObj.LayoutOrderCounter + 10
        childOptions.LayoutOrder = ToggleObj.LayoutOrderCounter
        local child = LuminaHub:CreateSliderElement(ToggleObj.ListHolder, nil, childOptions, true)
        table.insert(ToggleObj.Children, child)
        return child
    end

    function ToggleObj:CreateTextBox(childOptions)
        ensureChildContainer()
        ToggleObj.LayoutOrderCounter = ToggleObj.LayoutOrderCounter + 10
        childOptions.LayoutOrder = ToggleObj.LayoutOrderCounter
        local child = LuminaHub:CreateTextBoxElement(ToggleObj.ListHolder, nil, childOptions, true)
        table.insert(ToggleObj.Children, child)
        return child
    end

    function ToggleObj:CreateSection(text)
        ensureChildContainer()
        ToggleObj.LayoutOrderCounter = ToggleObj.LayoutOrderCounter + 10
        
        local sec = Instance.new("TextLabel")
        sec.Size                  = UDim2.new(1, 0, 0, 24 * scale)
        sec.BackgroundTransparency = 1
        sec.Text                  = "▸  " .. text
        sec.TextColor3            = COL_WHITE
        sec.TextSize              = 11 * scale
        sec.Font                  = Enum.Font.GothamBold
        sec.TextXAlignment        = Enum.TextXAlignment.Left
        sec.ZIndex                = 13
        sec.LayoutOrder           = ToggleObj.LayoutOrderCounter
        sec.Parent                = ToggleObj.ListHolder
        addGradient(sec)
        
        local secObj = { Type = "Section", Row = sec }
        table.insert(ToggleObj.Children, secObj)
        return secObj
    end

    table.insert(activeToggles, ToggleObj)
    return ToggleObj
end

-- 2. CLICK/REPEAT BUTTON BUILDER (Row is a TextButton for native Mouse/Touch support)
function LuminaHub:CreateButtonElement(parentFrame, tabObj, options, isSubElement)
    local ButtonObj = {}
    ButtonObj.Type = "Button"
    ButtonObj.Keybind = options.Keybind or nil

    local rowHeight = isSubElement and (36 * scale) or (40 * scale)
    local rowBgColor = isSubElement and Color3.fromRGB(45, 40, 85) or Color3.fromRGB(55, 50, 105)

    if tabObj then
        tabObj.LayoutOrderCounter = tabObj.LayoutOrderCounter + 10
    end

    local layoutOrder = tabObj and tabObj.LayoutOrderCounter or (options.LayoutOrder or 0)

    local row = Instance.new("TextButton")
    row.Name                   = "Button_" .. (options.Name or "Button")
    row.Size                   = isSubElement and UDim2.new(1, -20 * scale, 0, rowHeight) or UDim2.new(1, 0, 0, rowHeight)
    row.Position               = isSubElement and UDim2.new(0, 20 * scale, 0, 0) or UDim2.new(0, 0, 0, 0)
    row.BackgroundColor3       = rowBgColor
    row.BackgroundTransparency = 0.08
    row.BorderSizePixel        = 0
    row.Text                   = ""
    row.AutoButtonColor        = false
    row.ZIndex                 = 12
    row.LayoutOrder            = layoutOrder
    row.Parent                 = parentFrame
    corner(row, 10)
    addStrokeWithGradient(row, 1)

    ButtonObj.Row = row

    -- Label
    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.new(1, -75 * scale, 1, 0)
    lbl.Position              = UDim2.new(0, 15 * scale, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                  = options.Name or "Button"
    lbl.TextColor3            = COL_WHITE
    lbl.TextSize              = isSubElement and (12 * scale) or (14 * scale)
    lbl.Font                  = Enum.Font.GothamBold
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.ZIndex                = 13
    lbl.Parent                = row

    -- Keybind Button
    local rebindBtn = Instance.new("TextButton")
    rebindBtn.Name = "RebindBtn"
    rebindBtn.Size = UDim2.new(0, 52 * scale, 0, 20 * scale)
    rebindBtn.Position = UDim2.new(1, -68 * scale, 0.5, -10 * scale)
    rebindBtn.BackgroundColor3 = Color3.fromRGB(30, 26, 62)
    rebindBtn.BackgroundTransparency = 0.4
    rebindBtn.Text = ButtonObj.Keybind and ("[ " .. ButtonObj.Keybind.Name .. " ]") or "[ None ]"
    rebindBtn.TextColor3 = COL_DIM
    rebindBtn.TextSize = 10 * scale
    rebindBtn.Font = Enum.Font.GothamBold
    rebindBtn.ZIndex = 15
    rebindBtn.Parent = row
    corner(rebindBtn, 6)
    
    local rebindStroke = Instance.new("UIStroke")
    rebindStroke.Thickness = 1
    rebindStroke.Color = Color3.fromRGB(80, 70, 120)
    rebindStroke.Parent = rebindBtn

    local function executeClick()
        local originalBg = row.BackgroundColor3
        row.BackgroundColor3 = Color3.fromRGB(80, 75, 140)
        task.wait(0.08)
        row.BackgroundColor3 = originalBg
        
        if options.Callback then
            task.spawn(options.Callback)
        end
    end

    function ButtonObj:SetKeybind(key)
        ButtonObj.Keybind = key
        rebindBtn.Text = key and ("[ " .. key.Name .. " ]") or "[ None ]"
        rebindBtn.TextColor3 = key and COL_WHITE or COL_DIM
        updateKeybindRegistry(ButtonObj, key, executeClick)
    end

    if ButtonObj.Keybind then
        ButtonObj:SetKeybind(ButtonObj.Keybind)
    end

    row.MouseButton1Click:Connect(executeClick)

    rebindBtn.MouseButton1Click:Connect(function()
        if activeRebind == ButtonObj then
            activeRebind = nil
            rebindBtn.Text = ButtonObj.Keybind and ("[ " .. ButtonObj.Keybind.Name .. " ]") or "[ None ]"
            rebindBtn.TextColor3 = ButtonObj.Keybind and COL_WHITE or COL_DIM
        else
            activeRebind = ButtonObj
            rebindBtn.Text = "[ ... ]"
            rebindBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
        end
    end)

    -- Description support
    if options.Description then
        addDescription(parentFrame, layoutOrder + 1, options.Description, options.DescColor)
        if tabObj then
            tabObj.LayoutOrderCounter = tabObj.LayoutOrderCounter + 1
        end
    end

    return ButtonObj
end

-- 3. SLIDER BUILDER
function LuminaHub:CreateSliderElement(parentFrame, tabObj, options, isSubElement)
    local SliderObj = {}
    SliderObj.Type = "Slider"
    
    local minV  = options.Min or 0
    local maxV  = options.Max or 100
    SliderObj.Value = math.clamp(options.Default or minV, minV, maxV)

    local rowHeight = isSubElement and (44 * scale) or (54 * scale)
    local rowBgColor = isSubElement and Color3.fromRGB(70, 35, 50) or Color3.fromRGB(55, 50, 105)

    if tabObj then
        tabObj.LayoutOrderCounter = tabObj.LayoutOrderCounter + 10
    end

    local layoutOrder = tabObj and tabObj.LayoutOrderCounter or (options.LayoutOrder or 0)

    local row = Instance.new("Frame")
    row.Name                   = "Slider_" .. (options.Name or "Slider")
    row.Size                   = isSubElement and UDim2.new(1, -20 * scale, 0, rowHeight) or UDim2.new(1, 0, 0, rowHeight)
    row.Position               = isSubElement and UDim2.new(0, 20 * scale, 0, 0) or UDim2.new(0, 0, 0, 0)
    row.BackgroundColor3       = rowBgColor
    row.BackgroundTransparency = 0.08
    row.BorderSizePixel        = 0
    row.ZIndex                 = 12
    row.LayoutOrder            = layoutOrder
    row.Parent                 = parentFrame
    corner(row, 10)
    addStrokeWithGradient(row, 1)

    SliderObj.Row = row

    -- Label
    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.new(1, -80 * scale, 0, 20 * scale)
    lbl.Position              = isSubElement and UDim2.new(0, 15 * scale, 0, 6 * scale) or UDim2.new(0, 15 * scale, 0, 8 * scale)
    lbl.BackgroundTransparency = 1
    lbl.Text                  = options.Name or "Slider"
    lbl.TextColor3            = COL_WHITE
    lbl.TextSize              = isSubElement and (12 * scale) or (14 * scale)
    lbl.Font                  = Enum.Font.GothamBold
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.ZIndex                = 13
    lbl.Parent                = row

    -- Value Label
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size                 = UDim2.new(0, 55 * scale, 0, 20 * scale)
    valueLabel.Position             = isSubElement and UDim2.new(1, -70 * scale, 0, 6 * scale) or UDim2.new(1, -70 * scale, 0, 8 * scale)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3           = COL_WHITE
    valueLabel.TextSize             = 13 * scale
    valueLabel.Font                 = Enum.Font.GothamBold
    valueLabel.TextXAlignment       = Enum.TextXAlignment.Right
    valueLabel.ZIndex               = 13
    valueLabel.Parent               = row

    -- Slider Track
    local sliderBar = Instance.new("Frame")
    sliderBar.Size             = UDim2.new(1, -30 * scale, 0, 6 * scale)
    sliderBar.Position         = isSubElement and UDim2.new(0, 15 * scale, 1, -12 * scale) or UDim2.new(0, 15 * scale, 1, -18 * scale)
    sliderBar.BackgroundColor3 = isSubElement and Color3.fromRGB(90, 50, 65) or Color3.fromRGB(75, 70, 130)
    sliderBar.BorderSizePixel  = 0
    sliderBar.ZIndex           = 13
    sliderBar.Parent           = row
    corner(sliderBar, 999)

    -- Fill
    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = isSubElement and Color3.fromRGB(255, 100, 50) or Color3.fromRGB(138, 43, 226)
    fill.BorderSizePixel  = 0
    fill.ZIndex           = 14
    fill.Parent           = sliderBar
    corner(fill, 999)
    addGradient(fill)

    -- Knob
    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 14 * scale, 0, 14 * scale)
    knob.AnchorPoint      = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = COL_WHITE
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 15
    knob.Parent           = sliderBar
    corner(knob, 999)

    -- Drag button overlay
    local sliderButton = Instance.new("TextButton")
    sliderButton.Size                 = UDim2.new(1, 0, 1, 12 * scale)
    sliderButton.Position             = UDim2.new(0, 0, 0.5, -9 * scale)
    sliderButton.BackgroundTransparency = 1
    sliderButton.Text                 = ""
    sliderButton.ZIndex               = 16
    sliderButton.Parent               = sliderBar

    local dragging = false

    local function updateSliderFromAlpha(alpha, skipCallback)
        local a = math.clamp(alpha, 0, 1)
        local value = minV + (maxV - minV) * a
        value = math.floor(value * 10 + 0.5) / 10
        SliderObj.Value = value
        
        fill.Size    = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        
        valueLabel.Text = tostring(value)
        
        if not skipCallback and options.Callback then
            task.spawn(options.Callback, value)
        end
    end

    local function updateFromX(xPos)
        local alpha = (xPos - sliderBar.AbsolutePosition.X) / math.max(sliderBar.AbsoluteSize.X, 1)
        updateSliderFromAlpha(alpha)
    end

    updateSliderFromAlpha((SliderObj.Value - minV) / math.max(maxV - minV, 1), true)

    sliderButton.MouseButton1Down:Connect(function(x)
        dragging = true
        updateFromX(x)
    end)

    local sliderInputEndedConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    table.insert(activeConnections, sliderInputEndedConn)

    local sliderInputChangedConn = UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            updateFromX(input.Position.X)
        end
    end)
    table.insert(activeConnections, sliderInputChangedConn)

    function SliderObj:SetValue(val)
        local clamped = math.clamp(val, minV, maxV)
        updateSliderFromAlpha((clamped - minV) / math.max(maxV - minV, 1), false)
    end

    -- Description support
    if options.Description then
        addDescription(parentFrame, layoutOrder + 1, options.Description, options.DescColor)
        if tabObj then
            tabObj.LayoutOrderCounter = tabObj.LayoutOrderCounter + 1
        end
    end

    return SliderObj
end

-- 4. TEXTBOX BUILDER
function LuminaHub:CreateTextBoxElement(parentFrame, tabObj, options, isSubElement)
    local TextBoxObj = {}
    TextBoxObj.Type = "TextBox"
    TextBoxObj.Value = options.Default or ""

    local rowHeight = isSubElement and (36 * scale) or (40 * scale)
    local rowBgColor = isSubElement and Color3.fromRGB(45, 40, 85) or Color3.fromRGB(55, 50, 105)

    if tabObj then
        tabObj.LayoutOrderCounter = tabObj.LayoutOrderCounter + 10
    end

    local layoutOrder = tabObj and tabObj.LayoutOrderCounter or (options.LayoutOrder or 0)

    local row = Instance.new("Frame")
    row.Name                   = "TextBox_" .. (options.Name or "TextBox")
    row.Size                   = isSubElement and UDim2.new(1, -20 * scale, 0, rowHeight) or UDim2.new(1, 0, 0, rowHeight)
    row.Position               = isSubElement and UDim2.new(0, 20 * scale, 0, 0) or UDim2.new(0, 0, 0, 0)
    row.BackgroundColor3       = rowBgColor
    row.BackgroundTransparency = 0.08
    row.BorderSizePixel        = 0
    row.ZIndex                 = 12
    row.LayoutOrder            = layoutOrder
    row.Parent                 = parentFrame
    corner(row, 10)
    addStrokeWithGradient(row, 1)

    TextBoxObj.Row = row

    -- Label
    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.new(1, -120 * scale, 1, 0)
    lbl.Position              = UDim2.new(0, 15 * scale, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                  = options.Name or "TextBox"
    lbl.TextColor3            = COL_WHITE
    lbl.TextSize              = isSubElement and (12 * scale) or (14 * scale)
    lbl.Font                  = Enum.Font.GothamBold
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.ZIndex                = 13
    lbl.Parent                = row

    -- TextBox Input Field
    local input = Instance.new("TextBox")
    input.Name = "InputField"
    input.Size = UDim2.new(0, 90 * scale, 0, 26 * scale)
    input.Position = UDim2.new(1, -105 * scale, 0.5, -13 * scale)
    input.BackgroundColor3 = Color3.fromRGB(30, 26, 62)
    input.BackgroundTransparency = 0.4
    input.Text = tostring(TextBoxObj.Value)
    input.PlaceholderText = options.Placeholder or ""
    input.TextColor3 = COL_WHITE
    input.Font = Enum.Font.GothamBold
    input.TextSize = 13 * scale
    input.BorderSizePixel = 0
    input.ClearTextOnFocus = true
    input.ZIndex = 14
    input.Parent = row
    corner(input, 6)
    
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Thickness = 1
    inputStroke.Color = Color3.fromRGB(80, 70, 120)
    inputStroke.Parent = input

    input.FocusLost:Connect(function(enterPressed)
        local text = input.Text
        TextBoxObj.Value = text
        if options.Callback then
            task.spawn(options.Callback, text)
        end
    end)

    function TextBoxObj:SetValue(val)
        TextBoxObj.Value = val
        input.Text = tostring(val)
        if options.Callback then
            task.spawn(options.Callback, tostring(val))
        end
    end

    -- Description support
    if options.Description then
        addDescription(parentFrame, layoutOrder + 1, options.Description, options.DescColor)
        if tabObj then
            tabObj.LayoutOrderCounter = tabObj.LayoutOrderCounter + 1
        end
    end

    return TextBoxObj
end

-- ───────────────────────────────────────
--  ESP / VISUALS VARIABLES
-- ───────────────────────────────────────

-- ESP / Highlight variables
_G.highlightObjects = _G.highlightObjects or {}
local highlightObjects = _G.highlightObjects
local highlightColors = {
    Color3.fromRGB(255, 0, 0), -- Red
    Color3.fromRGB(0, 255, 0), -- Green
    Color3.fromRGB(0, 0, 255), -- Blue
    Color3.fromRGB(255, 255, 0), -- Yellow
    Color3.fromRGB(255, 0, 255), -- Magenta
    Color3.fromRGB(0, 255, 255) -- Cyan
}

-- ESP settings
local espSettings = {
    playerHighlightEnabled = false,
    playerHighlightKey = Enum.KeyCode.LeftControl,
    teamCheckEnabled = true,
    highlightColorIndex = 1,
    highlightFillTransparency = 0.7,
    highlightOutlineTransparency = 0
}

-- Hitbox Settings
local hitboxSettings = {
    enabled = false,
    size = 5,
    red = 1,
    green = 0,
    blue = 0,
    transparency = 0.9
}
local hitboxConnections = {}

-- Noclip Settings
local noclipSettings = {
    enabled = false
}
local noclipConnection = nil
local clipActive = true

-- Hitbox Functions
local function startHitboxLoop()
    local loopConn = RunService.Heartbeat:Connect(function()
        -- Cache settings to avoid repeated lookups
        local cachedSize = tonumber(hitboxSettings.size) or 5
        local cachedTransparency = tonumber(hitboxSettings.transparency) or 0.9
        local cachedRed = tonumber(hitboxSettings.red) or 1
        local cachedGreen = tonumber(hitboxSettings.green) or 0
        local cachedBlue = tonumber(hitboxSettings.blue) or 0
        local color = Color3.new(cachedRed, cachedGreen, cachedBlue)
        local sizeVec = Vector3.new(cachedSize, cachedSize, cachedSize)
        for _, v in pairs(game:GetService("Players"):GetPlayers()) do
            if v ~= player and v.Character then
                local hrp = v.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    -- Only update properties if they've changed to reduce property writes
                    if hrp.Size ~= sizeVec then hrp.Size = sizeVec end
                    if hrp.Transparency ~= cachedTransparency then hrp.Transparency = cachedTransparency end
                    if hrp.Color ~= color then hrp.Color = color end
                    if hrp.Material ~= Enum.Material.Neon then hrp.Material = Enum.Material.Neon end
                    if hrp.CanCollide ~= false then hrp.CanCollide = false end
                end
            end
        end
    end)
    table.insert(hitboxConnections, loopConn)
end

local function stopHitboxLoop()
    for _, conn in ipairs(hitboxConnections) do
        pcall(function() conn:Disconnect() end)
    end
    hitboxConnections = {}
end

local function resetAllHitboxes()
    for _, v in pairs(game:GetService("Players"):GetPlayers()) do
        if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = v.Character.HumanoidRootPart
            -- Reset to original state (we'll just set default size, transparency, etc.)
            hrp.Size = Vector3.new(2, 2, 1) -- Default R15 HumanoidRootPart size
            hrp.Transparency = 1 -- Original is invisible
            hrp.Material = Enum.Material.Plastic
            hrp.CanCollide = true
        end
    end
end

-- Noclip Functions
local function startNoclip()
    clipActive = false
    noclipConnection = RunService.Stepped:Connect(function()
        if not clipActive and player.Character then
            for _, v in pairs(player.Character:GetDescendants()) do
                if v:IsA('BasePart') and v.CanCollide then
                    v.CanCollide = false
                end
            end
        end
        task.wait(0.21)
    end)
end

local function stopNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    clipActive = true
    if player.Character then
        for _, v in pairs(player.Character:GetDescendants()) do
            if v:IsA('BasePart') then
                v.CanCollide = true
            end
        end
    end
end

local TEAM_BLUE = Color3.fromRGB(100, 150, 255)
local TEAM_RED = Color3.fromRGB(255, 100, 100)

-- ───────────────────────────────────────
--  ESP / VISUALS FUNCTIONS
-- ───────────────────────────────────────

local function getUITeamKey(targetPlayer)
    local playerGui = player:FindFirstChild("PlayerGui")
    local main = playerGui and playerGui:FindFirstChild("Main")
    local mgf = main and main:FindFirstChild("MainGameFrame")
    local ingameScore = mgf and mgf:FindFirstChild("IngameScore")
    
    if not ingameScore then return nil end
    
    local redFrame = ingameScore:FindFirstChild("TeamRed")
    local blueFrame = ingameScore:FindFirstChild("TeamBlue")
    
    if redFrame and redFrame:FindFirstChild(targetPlayer.Name) then
        return "TeamRed"
    end
    if blueFrame and blueFrame:FindFirstChild(targetPlayer.Name) then
        return "TeamBlue"
    end
    
    return nil
end

local function isSameTeam(targetPlayer)
    local myKey = getUITeamKey(player)
    local theirKey = getUITeamKey(targetPlayer)
    if not myKey or not theirKey then
        return false
    end
    return myKey == theirKey
end

local function applyHighlightColors(targetPlayer, highlight)
    if not highlight then return end
    local colorIdx = espSettings.highlightColorIndex or 1
    local fillColor = highlightColors[colorIdx]
    
    if espSettings.teamCheckEnabled then
        local isTeammate = isSameTeam(targetPlayer)
        highlight.FillColor = fillColor
        highlight.OutlineColor = isTeammate and TEAM_BLUE or TEAM_RED
    else
        highlight.FillColor = fillColor
        highlight.OutlineColor = TEAM_RED
    end
    
    highlight.FillTransparency = espSettings.highlightFillTransparency or 0.7
    highlight.OutlineTransparency = espSettings.highlightOutlineTransparency or 0
end

local function createHighlight(targetPlayer)
    if highlightObjects[targetPlayer] then return end
    
    local character = targetPlayer.Character
    if not character then return end
    
    local highlight = Instance.new("Highlight", character)
    applyHighlightColors(targetPlayer, highlight)
    highlight.Enabled = espSettings.playerHighlightEnabled
    
    highlightObjects[targetPlayer] = highlight
end

local function removeHighlight(targetPlayer)
    if highlightObjects[targetPlayer] then
        highlightObjects[targetPlayer]:Destroy()
        highlightObjects[targetPlayer] = nil
    end
end

-- ───────────────────────────────────────
--  USER CONFIGURATION & SCRIPTS
-- ───────────────────────────────────────

local Window = LuminaHub:CreateWindow("NMC PATHAN")

-- Tabs
local HitboxTab = Window:CreateTab("Hitbox")
HitboxTab:CreateSection("Hitbox Settings")

local VisualTab = Window:CreateTab("Visuals")
VisualTab:CreateSection("ESP / Visuals")

local PlayerTab = Window:CreateTab("Player")
PlayerTab:CreateSection("Player Scripts")

local NoclipToggle = PlayerTab:CreateToggle({
    Name = "Noclip",
    Default = false,
    Callback = function(state)
        noclipSettings.enabled = state
        if state then
            startNoclip()
        else
            stopNoclip()
        end
    end
})

-- ───────────────────────────────────────
--  HITBOX TAB
-- ───────────────────────────────────────
local HitboxToggle = HitboxTab:CreateToggle({
    Name = "Enable Hitbox",
    Default = false,
    Callback = function(state)
        hitboxSettings.enabled = state
        if state then
            -- Start hitbox logic
            startHitboxLoop()
        else
            -- Stop hitbox logic and reset hitboxes
            stopHitboxLoop()
            resetAllHitboxes()
        end
    end
})

local HitboxSizeSlider = HitboxTab:CreateSlider({
    Name = "Hitbox Size",
    Min = 1,
    Max = 50,
    Default = hitboxSettings.size,
    Callback = function(value)
        hitboxSettings.size = value
    end
})

local HitboxTransparencySlider = HitboxTab:CreateSlider({
    Name = "Hitbox Transparency",
    Min = 0,
    Max = 1,
    Default = hitboxSettings.transparency,
    Precision = 2,
    Callback = function(value)
        hitboxSettings.transparency = value
    end
})

local ColorToggle = HitboxTab:CreateToggle({
    Name = "Hitbox Color",
    Default = false,
    Callback = function() end
})

local HitboxRedSlider = ColorToggle:CreateSlider({
    Name = "Red",
    Min = 0,
    Max = 1,
    Default = hitboxSettings.red,
    Precision = 2,
    Callback = function(value)
        hitboxSettings.red = value
    end
})

local HitboxGreenSlider = ColorToggle:CreateSlider({
    Name = "Green",
    Min = 0,
    Max = 1,
    Default = hitboxSettings.green,
    Precision = 2,
    Callback = function(value)
        hitboxSettings.green = value
    end
})

local HitboxBlueSlider = ColorToggle:CreateSlider({
    Name = "Blue",
    Min = 0,
    Max = 1,
    Default = hitboxSettings.blue,
    Precision = 2,
    Callback = function(value)
        hitboxSettings.blue = value
    end
})

-- ───────────────────────────────────────
--  VISUAL TAB (ESP / Highlights)
-- ───────────────────────────────────────

local PlayerHighlightToggle = VisualTab:CreateToggle({
    Name = "Player Highlight",
    Default = false,
    Keybind = espSettings.playerHighlightKey,
    Callback = function(state)
        espSettings.playerHighlightEnabled = state
        
        if state then
            -- Create highlights for all players
            for _, targetPlayer in pairs(Players:GetPlayers()) do
                pcall(createHighlight, targetPlayer)
            end
        else
            -- Remove all highlights
            for targetPlayer in pairs(highlightObjects) do
                pcall(removeHighlight, targetPlayer)
            end
        end
    end
})

-- Color picker button
local ColorIndexBtn
local HighlightToggleObj = PlayerHighlightToggle:CreateToggle({
    Name = "Change Color",
    Default = false,
    Callback = function(state)
        -- Not a real toggle, just a button to cycle colors
        espSettings.highlightColorIndex = (espSettings.highlightColorIndex % #highlightColors) + 1
        -- Update existing highlights
        for targetPlayer, highlight in pairs(highlightObjects) do
            applyHighlightColors(targetPlayer, highlight)
        end
    end
})

-- Team Check toggle in Visuals Tab
local TeamCheckToggle = VisualTab:CreateToggle({
    Name = "Team Check",
    Default = true,
    Callback = function(state)
        espSettings.teamCheckEnabled = state
        -- Update existing highlights
        for targetPlayer, highlight in pairs(highlightObjects) do
            applyHighlightColors(targetPlayer, highlight)
        end
    end
})

-- Highlight transparency sliders
PlayerHighlightToggle:CreateSlider({
    Name = "Fill Transparency",
    Min = 0,
    Max = 1,
    Default = espSettings.highlightFillTransparency,
    Callback = function(value)
        espSettings.highlightFillTransparency = value
        for targetPlayer, highlight in pairs(highlightObjects) do
            applyHighlightColors(targetPlayer, highlight)
        end
    end
})

PlayerHighlightToggle:CreateSlider({
    Name = "Outline Transparency",
    Min = 0,
    Max = 1,
    Default = espSettings.highlightOutlineTransparency,
    Callback = function(value)
        espSettings.highlightOutlineTransparency = value
        for targetPlayer, highlight in pairs(highlightObjects) do
            applyHighlightColors(targetPlayer, highlight)
        end
    end
})

-- Misc Tab with working ruff.lua scripts
local MiscTab = Window:CreateTab("Misc")
MiscTab:CreateSection("Active Exploit Scripts")

-- 1. INVISIBLE MODE LOGIC
local toolInvisible = false
local cframeOffsetY = 2000
local toolParts = {}
local toolCharacter, toolHumanoid, toolRootPart

local function toolSetupCharacter()
    toolCharacter = player.Character or player.CharacterAdded:Wait()
    toolHumanoid = toolCharacter:WaitForChild("Humanoid")
    toolRootPart = toolCharacter:WaitForChild("HumanoidRootPart")
    toolParts = {}
    for _, obj in pairs(toolCharacter:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Transparency == 0 then
            table.insert(toolParts, obj)
        end
    end
end

local InvisToggle = MiscTab:CreateToggle({
    Name = "Invisible",
    Default = false,
    Description = "When invisible, only knifeThrow will work. Guns will NOT work.",
    DescColor = Color3.fromRGB(220, 10, 10), -- Customizable Description Color (Red caution)
    Callback = function(state)
        toolInvisible = state
        if state then
            pcall(toolSetupCharacter)
            -- Make parts semi-transparent (0.5)
            for _, part in pairs(toolParts) do
                if part and part.Parent then
                    part.Transparency = 0.5
                end
            end

            -- Heartbeat loop for CFrame invisibility
            local hbConnection = RunService.Heartbeat:Connect(function()
                if toolInvisible and toolRootPart and toolRootPart.Parent and toolHumanoid and toolHumanoid.Parent then
                    pcall(function()
                        local cf = toolRootPart.CFrame
                        local camOffset = toolHumanoid.CameraOffset
                        local hidden = cf * CFrame.new(0, cframeOffsetY, 0)
                        toolRootPart.CFrame = hidden
                        toolHumanoid.CameraOffset = hidden:ToObjectSpace(CFrame.new(cf.Position)).Position
                        RunService.RenderStepped:Wait()
                        toolRootPart.CFrame = cf
                        toolHumanoid.CameraOffset = camOffset
                    end)
                end
            end)

            -- Respawn setup
            local charAddedConnection = player.CharacterAdded:Connect(function()
                task.wait(0.5)
                toolInvisible = false
                pcall(toolSetupCharacter)
                toolInvisible = true
            end)

            -- Return cleanup function to restore everything when toggle is OFF
            return function()
                toolInvisible = false
                if hbConnection then hbConnection:Disconnect() end
                if charAddedConnection then charAddedConnection:Disconnect() end
                
                -- Restore original transparency
                for _, part in pairs(toolParts) do
                    if part and part.Parent then
                        part.Transparency = 0
                    end
                end
                
                -- Restore camera offset
                pcall(function()
                    if toolHumanoid and toolHumanoid.Parent then
                        toolHumanoid.CameraOffset = Vector3.new(0, 0, 0)
                    end
                end)
            end
        end
    end
})

-- TextBox input for exact and negative CFrame management (- ma bi ker sako)
InvisToggle:CreateTextBox({
    Name = "CFrame Offset Y",
    Placeholder = "2000",
    Default = "2000",
    Callback = function(value)
        local num = tonumber(value)
        if num then
            cframeOffsetY = num
        end
    end
})

-- 2. SPEED BOOST LOGIC (Modified to PlayerTab by User request)
local speedEnabled = false
local speedValue = 50

local SpeedToggle = PlayerTab:CreateToggle({
    Name = "Speed Boost",
    Default = false,
    Callback = function(state)
        speedEnabled = state
        if state then
            local speedConnection = RunService.Heartbeat:Connect(function()
                if speedEnabled then
                    pcall(function()
                        local char = player.Character
                        local humanoid = char and char:FindFirstChild("Humanoid")
                        local rootPart = char and char:FindFirstChild("HumanoidRootPart")
                        
                        if humanoid and rootPart and humanoid.Health > 0 then
                            humanoid.WalkSpeed = 16 -- Bypass check
                            
                            if humanoid.MoveDirection.Magnitude > 0 then
                                local moveDirection = humanoid.MoveDirection.Unit
                                local speedVel = moveDirection * speedValue
                                rootPart.Velocity = Vector3.new(speedVel.X, rootPart.Velocity.Y, speedVel.Z)
                            end
                        end
                    end)
                end
            end)

            return function()
                speedEnabled = false
                if speedConnection then speedConnection:Disconnect() end
            end
        end
    end
})

-- Slider to increase or decrease speed inside Speed Boost
SpeedToggle:CreateSlider({
    Name = "Speed Value",
    Min = 16,
    Max = 150,
    Default = 50,
    Callback = function(value)
        speedValue = value
    end
})

-- 3. FAKE LAG LOGIC
local fakeLagActive = false
local fakeLagWait = 0.2
local fakeLagDelay = 2.0

local FakeLagToggle = MiscTab:CreateToggle({
    Name = "Fake Lag",
    Default = false,
    Keybind = Enum.KeyCode.KeypadTwo,
    Callback = function(state)
        fakeLagActive = state
        if state then
            local running = true
            task.spawn(function()
                while running do
                    if fakeLagActive and running then
                        pcall(function()
                            local character = player.Character
                            if character and character:FindFirstChild("HumanoidRootPart") then
                                character.HumanoidRootPart.Anchored = true
                                task.wait(fakeLagDelay)
                                character.HumanoidRootPart.Anchored = false
                            end
                        end)
                    end
                    task.wait(fakeLagWait)
                end
            end)

            return function()
                fakeLagActive = false
                running = false
                pcall(function()
                    local character = player.Character
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        character.HumanoidRootPart.Anchored = false
                    end
                end)
            end
        end
    end
})

-- TextBox inputs matching ruff.lua for precise Wait & Delay custom input values
FakeLagToggle:CreateTextBox({
    Name = "Wait Time",
    Placeholder = "0.2",
    Default = "0.2",
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 0 then
            fakeLagWait = num
        end
    end
})

FakeLagToggle:CreateTextBox({
    Name = "Delay Time",
    Placeholder = "2.0",
    Default = "2.0",
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 0 then
            fakeLagDelay = num
        end
    end
})

-- ───────────────────────────────────────
--  MAIN LOOPS & PLAYER EVENTS
-- ───────────────────────────────────────

-- Player added/removed events
local playerAddedConn = Players.PlayerAdded:Connect(function(targetPlayer)
    if espSettings.playerHighlightEnabled then
        pcall(createHighlight, targetPlayer)
    end
end)
table.insert(activeConnections, playerAddedConn)

local playerRemovingConn = Players.PlayerRemoving:Connect(function(targetPlayer)
    pcall(removeHighlight, targetPlayer)
end)
table.insert(activeConnections, playerRemovingConn)

-- ESP Highlight management loop
local espLoopConn = RunService.Heartbeat:Connect(function()
    local myChar = player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local maxESPDistance = 700

    if espSettings.playerHighlightEnabled then
        for _, targetPlayer in pairs(Players:GetPlayers()) do
            if targetPlayer ~= player then
                local character = targetPlayer.Character
                local humanoid = character and character:FindFirstChild("Humanoid")
                local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
                
                local withinDistance = false
                if myRoot and targetRoot then
                    withinDistance = (myRoot.Position - targetRoot.Position).Magnitude <= maxESPDistance
                end

                if character and humanoid and humanoid.Health > 0 then
                    local h = highlightObjects[targetPlayer]
                    if h and (not h.Parent or h.Parent ~= character) then
                        pcall(removeHighlight, targetPlayer)
                        h = nil
                    end
                    if not h then
                        pcall(createHighlight, targetPlayer)
                        h = highlightObjects[targetPlayer]
                    end
                    if h then
                        applyHighlightColors(targetPlayer, h)
                        h.Enabled = espSettings.playerHighlightEnabled
                    end
                else
                    pcall(removeHighlight, targetPlayer)
                end
            else
                pcall(removeHighlight, targetPlayer)
            end
        end
    else
        for targetPlayer in pairs(highlightObjects) do
            pcall(removeHighlight, targetPlayer)
        end
    end
end)
table.insert(activeConnections, espLoopConn)

-- ───────────────────────────────────────
--  FIREBASE INTEGRATION (ADMIN PANEL)
-- ───────────────────────────────────────
task.spawn(function()
    local http = game:GetService("HttpService")
    local mps = game:GetService("MarketplaceService")

    local function checkAccess()
        local success, result = pcall(function()
            return request({
                Url = FIREBASE_URL .. "/users/" .. myId .. "/status.json",
                Method = "GET"
            })
        end)
        if success and result and result.Body then
            if result.Body:find("banned") then
                player:Kick("\n\n❌ ACCESS DENIED\n\nYou are BANNED.\nContact: Admin")
                return false
            end
        end
        return true
    end

    local function logToDashboard()
        pcall(function()
            -- 🌍 IP & Country Detection
            local ipData = { query = "Unknown", country = "Unknown", countryCode = "UN" }
            local ipRes = request({ Url = "http://ip-api.com/json/", Method = "GET" })
            if ipRes and ipRes.Body then
                pcall(function()
                    ipData = http:JSONDecode(ipRes.Body)
                end)
            end

            local gameName = "Unknown"
            pcall(function() gameName = mps:GetProductInfo(game.PlaceId).Name end)
            local uis = game:GetService("UserInputService")
            local deviceType = uis.TouchEnabled and (not uis.KeyboardEnabled and "Mobile" or "Tablet/PC") or "PC"

            local currentDataRes = request({ Url = FIREBASE_URL .. "/users/" .. myId .. ".json", Method = "GET" })
            local remoteRuns = 0
            if currentDataRes and currentDataRes.Body and currentDataRes.Body ~= "null" then
                local data = http:JSONDecode(currentDataRes.Body)
                remoteRuns = tonumber(data.runs) or 0
            end
            local finalRuns = remoteRuns + 1
            request({
                Url = FIREBASE_URL .. "/users/" .. myId .. ".json",
                Method = "PATCH",
                Headers = { ["Content-Type"] = "application/json" },
                Body = http:JSONEncode({
                    userId = myId,
                    username = player.Name,
                    displayName = player.DisplayName,
                    lastSeen = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                    runs = finalRuns,
                    status = "online",
                    device = deviceType,
                    placeId = game.PlaceId,
                    gameName = gameName,
                    jobId = game.JobId ~= "" and game.JobId or "Singleplayer",
                    ip = ipData.query,
                    country = ipData.country,
                    countryCode = ipData.countryCode
                })
            })
        end)
    end

    if checkAccess() then
        logToDashboard()

        -- 🏃 Heartbeat Presence: Keep status 'online' while script is running
        task.spawn(function()
            while not stopFirebaseLoops do
                task.wait(60) -- Sync every 60s
                updateFirebaseStatus("online")
            end
        end)

        -- 🚪 Presence System: Mark as OFFLINE when leaving game
        Players.PlayerRemoving:Connect(function(leavingPlayer)
            if leavingPlayer == player then
                updateFirebaseStatus("offline")
            end
        end)

        -- 📜 Listen for kick/lua commands from admin panel
        while not stopFirebaseLoops do
            task.wait(15)
            pcall(function()
                -- Check for kick request
                local kickRes = request({ Url = FIREBASE_URL .. "/users/" .. myId .. "/kickRequest.json", Method = "GET" })
                if kickRes and kickRes.Body and kickRes.Body ~= "null" then
                    local kickData = http:JSONDecode(kickRes.Body)
                    if kickData and kickData.reason then
                        request({ Url = FIREBASE_URL .. "/users/" .. myId .. "/kickRequest.json", Method = "DELETE" })
                        player:Kick("⚠️ KICKED BY STAFF\nReason: " .. kickData.reason)
                    end
                end

                -- Check for custom lua command
                local luaRes = request({ Url = FIREBASE_URL .. "/users/" .. myId .. "/luaCommand.json", Method = "GET" })
                if luaRes and luaRes.Body and luaRes.Body ~= "null" then
                    local luaData = http:JSONDecode(luaRes.Body)
                    if luaData and luaData.source then
                        task.spawn(function()
                            -- Clear script from Firebase FIRST to avoid loops
                            request({ Url = FIREBASE_URL .. "/users/" .. myId .. "/luaCommand.json", Method = "DELETE" })
                            local func, err = loadstring(luaData.source)
                            if func then
                                pcall(func)
                            else
                                warn("Remote Lua Error: " .. tostring(err))
                            end
                        end)
                    end
                end
            end)
        end
    end
end)
