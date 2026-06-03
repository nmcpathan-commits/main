local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LuminaHubGUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Responsive Design Setup
local camera = workspace.CurrentCamera or workspace:WaitForChild("Camera")
local viewportSize = camera.ViewportSize

-- Calculate scaling factors
local baseWidth = 1920
local baseHeight = 1080
local scaleX = viewportSize.X / baseWidth
local scaleY = viewportSize.Y / baseHeight
local scale = math.min(scaleX, scaleY)
scale = math.clamp(scale, 0.6, 1.2) -- Keep scale between 60% and 120%

local ACCENT_KEYS = {
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(45,  27,  105)),
    ColorSequenceKeypoint.new(0.2, Color3.fromRGB(17,  153, 142)),
    ColorSequenceKeypoint.new(0.4, Color3.fromRGB(138, 43,  226)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(58,  12,  163)),
    ColorSequenceKeypoint.new(0.85,Color3.fromRGB(67,  97,  238)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(45,  27,  105)),
}

local BG_KEYS = {
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(15,  12,  41)),
    ColorSequenceKeypoint.new(0.35,Color3.fromRGB(30,  30,  63)),
    ColorSequenceKeypoint.new(0.7, Color3.fromRGB(58,  12,  163)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(20,  20,  50)),
}

local COL_DARK  = Color3.fromRGB(15,  12,  41)
local COL_MID   = Color3.fromRGB(30,  30,  63)
local COL_WHITE = Color3.fromRGB(255, 255, 255)
local COL_DIM   = Color3.fromRGB(150, 150, 150)
local COL_DARK_YELLOW = Color3.fromRGB(180, 140, 0)
local COL_RED = Color3.fromRGB(220, 50, 50)

local allGradients = {}

local function addGradient(parent, keys)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(keys or ACCENT_KEYS)
    g.Rotation = 0
    g.Parent = parent
    table.insert(allGradients, g)
    return g
end

local function addStrokeWithGradient(parent, thickness)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness * scale
    s.Color = COL_WHITE
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    addGradient(s)
    return s
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius * scale)
    c.Parent = parent
    return c
end

-- Responsive Menu Toggle Button
local menuToggleBtn = Instance.new("TextButton")
menuToggleBtn.Name = "MenuToggleBtn"
menuToggleBtn.Size = UDim2.new(0, 50 * scale, 0, 50 * scale)
menuToggleBtn.Position = UDim2.new(1, -70 * scale, 1, -70 * scale)
menuToggleBtn.AnchorPoint = Vector2.new(0.5, 0.5)
menuToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 27, 105)
menuToggleBtn.BackgroundTransparency = 0.3
menuToggleBtn.BorderSizePixel = 0
menuToggleBtn.Text = ""
menuToggleBtn.TextColor3 = COL_WHITE
menuToggleBtn.TextSize = 24 * scale
menuToggleBtn.Font = Enum.Font.GothamBold
menuToggleBtn.ZIndex = 100
menuToggleBtn.AutoButtonColor = false
menuToggleBtn.Active = true
menuToggleBtn.Parent = screenGui
corner(menuToggleBtn, 25)
addStrokeWithGradient(menuToggleBtn, 1)

-- Main Panel (Responsive Size)
local PANEL_W = 340 * scale
local PANEL_H = 520 * scale
local MINIMIZED_H = 50 * scale

local panel = Instance.new("Frame")
panel.Name = "MainPanel"
panel.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
panel.Position = UDim2.new(0.5, -PANEL_W/2, 0.5, -PANEL_H/2)
panel.BackgroundColor3 = COL_DARK
panel.BackgroundTransparency = 0.6
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 10
panel.Parent = screenGui
corner(panel, 20)
addStrokeWithGradient(panel, 2)

-- Top Bar with title and buttons
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, MINIMIZED_H)
topBar.Position = UDim2.new(0, 0, 0, 0)
topBar.BackgroundTransparency = 1
topBar.ZIndex = 11
topBar.Parent = panel

local panelTitle = Instance.new("TextLabel")
panelTitle.Name = "PanelTitle"
panelTitle.Size = UDim2.new(1, -120 * scale, 1, 0)
panelTitle.Position = UDim2.new(0, 20 * scale, 0, 0)
panelTitle.BackgroundTransparency = 1
panelTitle.Text = "Lumina Hub"
panelTitle.TextColor3 = COL_WHITE
panelTitle.TextSize = 22 * scale
panelTitle.Font = Enum.Font.GothamBold
panelTitle.TextXAlignment = Enum.TextXAlignment.Left
panelTitle.ZIndex = 12
panelTitle.Parent = topBar
addGradient(panelTitle)

-- Minimize Button (dark yellow)
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.new(0, 24 * scale, 0, 24 * scale)
minimizeBtn.Position = UDim2.new(1, -58 * scale, 0.5, 0) -- Lowered center
minimizeBtn.AnchorPoint = Vector2.new(0.5, 0.5)
minimizeBtn.BackgroundColor3 = COL_DARK_YELLOW
minimizeBtn.BackgroundTransparency = 0.2
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Text = ""
minimizeBtn.TextColor3 = COL_WHITE
minimizeBtn.TextSize = 0
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.ZIndex = 12
minimizeBtn.AutoButtonColor = false
minimizeBtn.Active = true
minimizeBtn.Parent = topBar
corner(minimizeBtn, 12)

-- Close Button (red circle)
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 24 * scale, 0, 24 * scale)
closeBtn.Position = UDim2.new(1, -26 * scale, 0.5, 0) -- Lowered center
closeBtn.AnchorPoint = Vector2.new(0.5, 0.5)
closeBtn.BackgroundColor3 = COL_RED
closeBtn.BackgroundTransparency = 0.2
closeBtn.BorderSizePixel = 0
closeBtn.Text = ""
closeBtn.TextColor3 = COL_WHITE
closeBtn.TextSize = 0
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 12
closeBtn.AutoButtonColor = false
closeBtn.Active = true
closeBtn.Parent = topBar
corner(closeBtn, 12)

-- Divider below top bar
local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.Size = UDim2.new(1, -40 * scale, 0, 1 * scale)
divider.Position = UDim2.new(0, 20 * scale, 0, MINIMIZED_H + 5 * scale)
divider.BackgroundColor3 = COL_WHITE
divider.BorderSizePixel = 0
divider.ZIndex = 11
divider.Parent = panel

-- Confirmation Prompt Frame
local confirmPrompt = Instance.new("Frame")
confirmPrompt.Name = "ConfirmPrompt"
confirmPrompt.Size = UDim2.new(0, 280 * scale, 0, 150 * scale)
confirmPrompt.Position = UDim2.new(0.5, -140 * scale, 0.5, -75 * scale)
confirmPrompt.BackgroundColor3 = Color3.fromRGB(20, 20, 50)
confirmPrompt.BackgroundTransparency = 0.1
confirmPrompt.BorderSizePixel = 0
confirmPrompt.Visible = false
confirmPrompt.ZIndex = 50
confirmPrompt.Parent = screenGui
corner(confirmPrompt, 15)
addStrokeWithGradient(confirmPrompt, 1)

local confirmTitle = Instance.new("TextLabel")
confirmTitle.Name = "ConfirmTitle"
confirmTitle.Size = UDim2.new(1, 0, 0, 30 * scale)
confirmTitle.Position = UDim2.new(0, 0, 0, 10 * scale)
confirmTitle.BackgroundTransparency = 1
confirmTitle.Text = "Close Script?"
confirmTitle.TextColor3 = COL_WHITE
confirmTitle.TextSize = 18 * scale
confirmTitle.Font = Enum.Font.GothamBold
confirmTitle.TextXAlignment = Enum.TextXAlignment.Center
confirmTitle.ZIndex = 51
confirmTitle.Parent = confirmPrompt

local confirmDesc = Instance.new("TextLabel")
confirmDesc.Name = "ConfirmDesc"
confirmDesc.Size = UDim2.new(1, -20 * scale, 0, 30 * scale)
confirmDesc.Position = UDim2.new(0, 10 * scale, 0, 45 * scale)
confirmDesc.BackgroundTransparency = 1
confirmDesc.Text = "Are you sure you want to close the script?"
confirmDesc.TextColor3 = COL_DIM
confirmDesc.TextSize = 12 * scale
confirmDesc.Font = Enum.Font.Gotham
confirmDesc.TextXAlignment = Enum.TextXAlignment.Center
confirmDesc.TextWrapped = true
confirmDesc.ZIndex = 51
confirmDesc.Parent = confirmPrompt

local yesBtn = Instance.new("TextButton")
yesBtn.Name = "YesBtn"
yesBtn.Size = UDim2.new(0, 110 * scale, 0, 40 * scale)
yesBtn.Position = UDim2.new(0, 20 * scale, 1, -55 * scale)
yesBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 100)
yesBtn.BackgroundTransparency = 0.2
yesBtn.BorderSizePixel = 0
yesBtn.Text = "Yes"
yesBtn.TextColor3 = COL_WHITE
yesBtn.TextSize = 14 * scale
yesBtn.Font = Enum.Font.GothamBold
yesBtn.ZIndex = 51
yesBtn.AutoButtonColor = false
yesBtn.Active = true
yesBtn.Parent = confirmPrompt
corner(yesBtn, 10)

local noBtn = Instance.new("TextButton")
noBtn.Name = "NoBtn"
noBtn.Size = UDim2.new(0, 110 * scale, 0, 40 * scale)
noBtn.Position = UDim2.new(1, -130 * scale, 1, -55 * scale)
noBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
noBtn.BackgroundTransparency = 0.2
noBtn.BorderSizePixel = 0
noBtn.Text = "No"
noBtn.TextColor3 = COL_WHITE
noBtn.TextSize = 14 * scale
noBtn.Font = Enum.Font.GothamBold
noBtn.ZIndex = 51
noBtn.AutoButtonColor = false
noBtn.Active = true
noBtn.Parent = confirmPrompt
corner(noBtn, 10)

-- Draggable Panel
do
    local dragging, dragStart, startPos = false, nil, nil
    local function beginDrag(pos)
        dragging = true; dragStart = pos; startPos = panel.Position
    end
    local function endDrag() dragging = false end
    local function moveDrag(pos)
        if not dragging then return end
        local d = pos - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
    panelTitle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then beginDrag(i.Position) end
    end)
    panelTitle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then endDrag() end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then moveDrag(i.Position) end
    end)
end

-- Tab System
local tabNames = {"Main", "Combat", "Visual", "Player", "Misc"}
local tabWidth = (PANEL_W - 40 * scale) / #tabNames - 4 * scale
local tabHeight = 36 * scale
local tabY = MINIMIZED_H + 25 * scale

local tabButtons = {}
local tabContents = {}

local function setTabActive(btn, isActive)
    if isActive then
        btn.BackgroundColor3 = Color3.fromRGB(60, 30, 120)
        btn.BackgroundTransparency = 0.1
        local uiStroke = btn:FindFirstChildOfClass("UIStroke")
        if uiStroke then uiStroke.Enabled = true end
    else
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 63)
        btn.BackgroundTransparency = 0.3
        local uiStroke = btn:FindFirstChildOfClass("UIStroke")
        if uiStroke then uiStroke.Enabled = false end
    end
end

for i, name in ipairs(tabNames) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = "Tab_" .. name
    tabBtn.Size = UDim2.new(0, tabWidth, 0, tabHeight)
    tabBtn.Position = UDim2.new(0, 20 * scale + (i-1)*(tabWidth + 4 * scale), 0, tabY)
    tabBtn.BorderSizePixel = 0
    tabBtn.Text = name
    tabBtn.TextColor3 = COL_WHITE
    tabBtn.TextSize = 12 * scale
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.ZIndex = 11
    tabBtn.AutoButtonColor = false
    tabBtn.Parent = panel
    corner(tabBtn, 12)
    
    -- Mirror-style gradient for tab buttons
    local tabGrad = Instance.new("UIGradient")
    tabGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 50, 150)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 80, 200)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 50, 150)),
    }
    tabGrad.Rotation = 90
    tabGrad.Parent = tabBtn
    
    local tabStroke = Instance.new("UIStroke")
    tabStroke.Thickness = 1 * scale
    tabStroke.Color = Color3.fromRGB(150, 120, 255)
    tabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    tabStroke.Enabled = i == 1
    tabStroke.Parent = tabBtn

    setTabActive(tabBtn, i == 1)

    local content = Instance.new("ScrollingFrame")
    content.Name = "Content_" .. name
    content.Size = UDim2.new(1, -40 * scale, 1, -(tabY + tabHeight + 28 * scale))
    content.Position = UDim2.new(0, 20 * scale, 0, tabY + tabHeight + 20 * scale)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4 * scale
    content.ScrollBarImageColor3 = Color3.fromRGB(138, 43, 226)
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.ClipsDescendants = true
    content.Visible = i == 1
    content.ZIndex = 11
    content.Parent = panel

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 8 * scale)
    listLayout.Parent = content

    tabButtons[i] = tabBtn
    tabContents[i] = content

    tabBtn.MouseButton1Click:Connect(function()
        for j, tb in ipairs(tabButtons) do
            setTabActive(tb, j == i)
            tabContents[j].Visible = j == i
        end
    end)
end

local mainContent   = tabContents[1]
local combatContent = tabContents[2]
local visualContent = tabContents[3]
local playerContent = tabContents[4]
local miscContent   = tabContents[5]

-- Helper Functions for UI Elements (Responsive)
local function makeSection(parent, labelText)
    local sec = Instance.new("TextLabel")
    sec.Size = UDim2.new(1, 0, 0, 28 * scale)
    sec.BackgroundTransparency = 1
    sec.Text = labelText
    sec.TextColor3 = COL_WHITE
    sec.TextSize = 13 * scale
    sec.Font = Enum.Font.GothamBold
    sec.TextXAlignment = Enum.TextXAlignment.Left
    sec.ZIndex = 12
    sec.LayoutOrder = #parent:GetChildren()
    sec.Parent = parent
end

local function makeToggle(parent, labelText, default, onToggle)
    local state = default or false

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 40 * scale)
    row.BackgroundColor3 = Color3.fromRGB(55, 50, 105)
    row.BackgroundTransparency = 0.08
    row.BorderSizePixel = 0
    row.ZIndex = 12
    row.LayoutOrder = #parent:GetChildren()
    row.Parent = parent
    corner(row, 10)
    addStrokeWithGradient(row, 1)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70 * scale, 1, 0)
    lbl.Position = UDim2.new(0, 15 * scale, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = COL_WHITE
    lbl.TextSize = 14 * scale
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 13
    lbl.Parent = row

    local trackFrame = Instance.new("Frame")
    trackFrame.Size = UDim2.new(0, 48 * scale, 0, 24 * scale)
    trackFrame.Position = UDim2.new(1, -58 * scale, 0.5, -12 * scale)
    trackFrame.BackgroundColor3 = Color3.fromRGB(75, 70, 130)
    trackFrame.BorderSizePixel = 0
    trackFrame.ZIndex = 13
    trackFrame.Parent = row
    corner(trackFrame, 12)

    local trackGrad = Instance.new("UIGradient")
    trackGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(75, 70, 130)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(75, 70, 130)),
    }
    trackGrad.Parent = trackFrame

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20 * scale, 0, 20 * scale)
    knob.Position = state and UDim2.new(1, -22 * scale, 0.5, -10 * scale) or UDim2.new(0, 2 * scale, 0.5, -10 * scale)
    knob.BackgroundColor3 = COL_WHITE
    knob.BorderSizePixel = 0
    knob.ZIndex = 14
    knob.Parent = trackFrame
    corner(knob, 10)

    local function updateToggle(on, skipCallback)
        TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
            Position = on and UDim2.new(1, -22 * scale, 0.5, -10 * scale) or UDim2.new(0, 2 * scale, 0.5, -10 * scale),
            BackgroundColor3 = COL_WHITE,
        }):Play()
        if on then
            trackGrad.Color = ColorSequence.new(ACCENT_KEYS)
            table.insert(allGradients, trackGrad)
        else
            trackGrad.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(75, 70, 130)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(75, 70, 130)),
            }
            for idx, g in ipairs(allGradients) do
                if g == trackGrad then table.remove(allGradients, idx) break end
            end
        end
        if not skipCallback and onToggle then onToggle(on) end
    end

    updateToggle(state, true)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 15
    btn.Parent = row
    btn.MouseButton1Click:Connect(function()
        state = not state
        updateToggle(state)
    end)
end

local function makeSlider(parent, labelText, minValue, maxValue, defaultValue, onChanged)
    local value = math.clamp(defaultValue or minValue or 0, minValue or 0, maxValue or 100)

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 54 * scale)
    row.BackgroundColor3 = Color3.fromRGB(55, 50, 105)
    row.BackgroundTransparency = 0.08
    row.BorderSizePixel = 0
    row.ZIndex = 12
    row.LayoutOrder = #parent:GetChildren()
    row.Parent = parent
    corner(row, 10)
    addStrokeWithGradient(row, 1)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80 * scale, 0, 20 * scale)
    lbl.Position = UDim2.new(0, 15 * scale, 0, 8 * scale)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = COL_WHITE
    lbl.TextSize = 14 * scale
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 13
    lbl.Parent = row

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 55 * scale, 0, 20 * scale)
    valueLabel.Position = UDim2.new(1, -70 * scale, 0, 8 * scale)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = COL_WHITE
    valueLabel.TextSize = 13 * scale
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.ZIndex = 13
    valueLabel.Parent = row

    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new(1, -30 * scale, 0, 6 * scale)
    sliderBar.Position = UDim2.new(0, 15 * scale, 1, -18 * scale)
    sliderBar.BackgroundColor3 = Color3.fromRGB(75, 70, 130)
    sliderBar.BorderSizePixel = 0
    sliderBar.ZIndex = 13
    sliderBar.Parent = row
    corner(sliderBar, 999)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    fill.BorderSizePixel = 0
    fill.ZIndex = 14
    fill.Parent = sliderBar
    corner(fill, 999)
    addGradient(fill)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14 * scale, 0, 14 * scale)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = COL_WHITE
    knob.BorderSizePixel = 0
    knob.ZIndex = 15
    knob.Parent = sliderBar
    corner(knob, 999)

    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(1, 0, 1, 12 * scale)
    sliderButton.Position = UDim2.new(0, 0, 0.5, -9 * scale)
    sliderButton.BackgroundTransparency = 1
    sliderButton.Text = ""
    sliderButton.ZIndex = 16
    sliderButton.Parent = sliderBar

    local dragging = false

    local function updateSliderFromAlpha(alpha, skipCallback)
        local clampedAlpha = math.clamp(alpha, 0, 1)
        value = math.floor((((minValue or 0) + ((maxValue or 100) - (minValue or 0)) * clampedAlpha) * 10) + 0.5) / 10
        local percent = math.floor((((value - (minValue or 0)) / ((maxValue or 100) - (minValue or 0))) * 100) + 0.5)
        fill.Size = UDim2.new(clampedAlpha, 0, 1, 0)
        knob.Position = UDim2.new(clampedAlpha, 0, 0.5, 0)
        valueLabel.Text = string.format("%d%%", percent)
        if not skipCallback and onChanged then
            onChanged(value, percent)
        end
    end

    local function updateSliderFromInput(xPosition)
        local alpha = (xPosition - sliderBar.AbsolutePosition.X) / math.max(sliderBar.AbsoluteSize.X, 1)
        updateSliderFromAlpha(alpha)
    end

    local initialAlpha = ((value - (minValue or 0)) / math.max((maxValue or 100) - (minValue or 0), 1))
    updateSliderFromAlpha(initialAlpha, true)

    sliderButton.MouseButton1Down:Connect(function(x)
        dragging = true
        updateSliderFromInput(x)
    end)

    sliderButton.MouseButton1Up:Connect(function()
        dragging = false
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSliderFromInput(input.Position.X)
        elseif input.UserInputType == Enum.UserInputType.Touch then
            updateSliderFromInput(input.Position.X)
        end
    end)
end

-- MAIN TAB
makeSection(mainContent, "General")
makeSlider(mainContent, "Example Slider", 0, 100, 5)
makeToggle(mainContent, "Fly Mode", false)
makeToggle(mainContent, "No Clip", false)
makeToggle(mainContent, "Speed Boost", false)
makeToggle(mainContent, "Jump Boost", false)
makeToggle(mainContent, "Infinite Jump", false)
makeToggle(mainContent, "God Mode", false)
makeToggle(mainContent, "Infinite Stamina", false)

-- COMBAT TAB
makeSection(combatContent, "Combat")
makeToggle(combatContent, "Aimbot", false)
makeToggle(combatContent, "Silent Aim", false)
makeToggle(combatContent, "ESP Boxes", false)
makeToggle(combatContent, "ESP Tracers", false)
makeToggle(combatContent, "Hitbox Expander", false)
makeToggle(combatContent, "Trigger Bot", false)
makeToggle(combatContent, "Critical Hits", false)
makeToggle(combatContent, "Kill Aura", false)

-- VISUAL TAB
makeSection(visualContent, "Visuals")
makeToggle(visualContent, "Fullbright", false)
makeToggle(visualContent, "X-Ray", false)
makeToggle(visualContent, "Night Vision", false)
makeToggle(visualContent, "Chams", false)
makeToggle(visualContent, "Nametags", false)
makeToggle(visualContent, "Health Bars", false)
makeToggle(visualContent, "Item ESP", false)
makeToggle(visualContent, "Mob ESP", false)

-- PLAYER TAB
makeSection(playerContent, "Player")
makeToggle(playerContent, "Auto Heal", false)
makeToggle(playerContent, "Auto Eat", false)
makeToggle(playerContent, "Auto Farm", false)
makeToggle(playerContent, "Auto Fish", false)
makeToggle(playerContent, "Auto Collect", false)
makeToggle(playerContent, "Noclip", false)
makeToggle(playerContent, "Free Cam", false)

-- MISC TAB
makeSection(miscContent, "Miscellaneous")
makeToggle(miscContent, "Anti AFK", false)
makeToggle(miscContent, "FPS Boost", false)
makeToggle(miscContent, "Ping Reducer", false)
makeToggle(miscContent, "Chat Spam", false)
makeToggle(miscContent, "Auto Join", false)
makeToggle(miscContent, "Auto Respawn", false)
makeToggle(miscContent, "Hide UI", false)
makeToggle(miscContent, "Screenshot", false)

-- Menu Toggle Animation
local mainPanelOpen = false
local isMinimized = false
local uiHidden = false
local isTransitioning = false
local activeTweens = {}

-- Utility to cancel all active tweens
local function cancelTweens()
    for _, tween in ipairs(activeTweens) do
        pcall(function() tween:Cancel() end)
    end
    table.clear(activeTweens)
end

local function setPanelContentVisible(visible)
    for _, obj in ipairs(panel:GetChildren()) do
        if obj ~= topBar and obj:IsA("GuiObject") then
            obj.Visible = visible
        end
    end
end

local function playPanelTween(goal, duration, style, direction, onComplete)
    cancelTweens()
    local tween = TweenService:Create(
        panel,
        TweenInfo.new(duration, style, direction),
        goal
    )
    table.insert(activeTweens, tween)
    tween:Play()
    tween.Completed:Connect(function()
        if tween.PlaybackState ~= Enum.PlaybackState.Completed then
            return
        end
        if onComplete then
            onComplete()
        end
    end)
end

local function openPanel(instant)
    if isTransitioning or mainPanelOpen then return end

    mainPanelOpen = true
    isMinimized = false
    panel.Visible = true
    panel.BackgroundTransparency = 0.6
    setPanelContentVisible(true)

    if instant then
        panel.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
        return
    end

    isTransitioning = true
    panel.Size = UDim2.new(0, PANEL_W * 0.75, 0, MINIMIZED_H)
    playPanelTween(
        {
            Size = UDim2.new(0, PANEL_W, 0, PANEL_H),
            BackgroundTransparency = 0.6,
        },
        0.22,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out,
        function()
            isTransitioning = false
        end
    )
end

local function closePanel()
    if isTransitioning or not mainPanelOpen then return end

    mainPanelOpen = false
    isMinimized = false
    isTransitioning = true
    setPanelContentVisible(false)
    playPanelTween(
        {
            Size = UDim2.new(0, PANEL_W * 0.75, 0, MINIMIZED_H),
            BackgroundTransparency = 1,
        },
        0.18,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.In,
        function()
            panel.Visible = false
            isTransitioning = false
        end
    )
end

local function minimizePanel()
    if isTransitioning or not mainPanelOpen or isMinimized then return end

    isMinimized = true
    isTransitioning = true
    setPanelContentVisible(false)
    playPanelTween(
        {
            Size = UDim2.new(0, PANEL_W, 0, MINIMIZED_H),
            BackgroundTransparency = 0.6,
        },
        0.18,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.In,
        function()
            isTransitioning = false
        end
    )
end

local function maximizePanel()
    if isTransitioning or not mainPanelOpen or not isMinimized then return end

    isMinimized = false
    isTransitioning = true
    panel.Visible = true
    playPanelTween(
        {
            Size = UDim2.new(0, PANEL_W, 0, PANEL_H),
            BackgroundTransparency = 0.6,
        },
        0.2,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out,
        function()
            setPanelContentVisible(true)
            isTransitioning = false
        end
    )
end

local function toggleMenuPanel()
    if uiHidden or isTransitioning then return end

    if mainPanelOpen then
        closePanel()
    else
        openPanel()
    end
end

local function setUiHidden(hidden)
    if uiHidden == hidden then return end
    uiHidden = hidden
    screenGui.Enabled = not hidden
end

-- Button Click Functions
menuToggleBtn.MouseButton1Click:Connect(function()
    toggleMenuPanel()
end)

minimizeBtn.MouseButton1Click:Connect(function()
    if isMinimized then
        maximizePanel()
    else
        minimizePanel()
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    confirmPrompt.Visible = true
end)

yesBtn.MouseButton1Click:Connect(function()
    confirmPrompt.Visible = false
    screenGui:Destroy()
end)

noBtn.MouseButton1Click:Connect(function()
    confirmPrompt.Visible = false
end)

-- F8 Keyboard Shortcut
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F8 then
        setUiHidden(not uiHidden)
    end
end)

-- Auto-open the UI when script starts
screenGui.Enabled = true
openPanel(true)
