-- LocalScript (StarterPlayerScripts)

--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

--// Vars
local highlightEnabled = false
local highlightKey = Enum.KeyCode.G
local noclipEnabled = false
local doubleJumpEnabled = false
local canDoubleJump = false
local hasDoubleJumped = false
local doubleJumpPower = 50
local selectedPlayer = nil
local minimized = false

-- Color scheme
local colors = {
    background = Color3.fromRGB(30, 30, 40),
    header = Color3.fromRGB(45, 45, 60),
    primary = Color3.fromRGB(0, 170, 255),
    secondary = Color3.fromRGB(100, 100, 140),
    success = Color3.fromRGB(0, 200, 130),
    danger = Color3.fromRGB(220, 70, 70),
    text = Color3.fromRGB(240, 240, 250),
    mutedText = Color3.fromRGB(180, 180, 200),
    button = Color3.fromRGB(50, 50, 70),
    buttonHover = Color3.fromRGB(65, 65, 90),
    input = Color3.fromRGB(40, 40, 55)
}

-- =========================
-- GUI Setup
-- =========================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ProfessionalMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main container with shadow effect
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 380, 0, 520)
MainFrame.Position = UDim2.new(0, 50, 0, 100)
MainFrame.BackgroundColor3 = colors.background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Shadow effect
local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.Image = "rbxassetid://5554236805"
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(23, 23, 277, 277)
Shadow.Size = UDim2.new(1, 30, 1, 30)
Shadow.Position = UDim2.new(0, -15, 0, -15)
Shadow.BackgroundTransparency = 1
Shadow.ImageTransparency = 0.5
Shadow.ZIndex = -1
Shadow.Parent = MainFrame

-- Rounded corners
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = colors.header
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0, 200, 1, 0)
TitleText.Position = UDim2.new(0, 15, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "✨ Cheat By NMC + NTH"
TitleText.TextColor3 = colors.text
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 16
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 32, 0, 32)
MinBtn.Position = UDim2.new(1, -37, 0, 5)
MinBtn.Text = "–"
MinBtn.TextColor3 = colors.text
MinBtn.BackgroundColor3 = colors.danger
MinBtn.AutoButtonColor = false
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18
MinBtn.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinBtn

-- Hover effect for minimize button
MinBtn.MouseEnter:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(240, 80, 80)}):Play()
end)

MinBtn.MouseLeave:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.2), {BackgroundColor3 = colors.danger}):Play()
end)

-- Container for scrollable contents
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Size = UDim2.new(1, -20, 1, -60)
ContentFrame.Position = UDim2.new(0, 10, 0, 50)
ContentFrame.BackgroundTransparency = 1
ContentFrame.ScrollBarThickness = 6
ContentFrame.ScrollBarImageColor3 = colors.secondary
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentFrame.Parent = MainFrame

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 14)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = ContentFrame

-- Section Label
local function CreateLabel(text)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 28)
    container.BackgroundTransparency = 1
    container.LayoutOrder = #ContentFrame:GetChildren() + 1
    container.Parent = ContentFrame

    local horizontal = Instance.new("Frame")
    horizontal.Size = UDim2.new(1, 0, 1, 0)
    horizontal.BackgroundTransparency = 1
    horizontal.Parent = container

    local lineLeft = Instance.new("Frame")
    lineLeft.Size = UDim2.new(0, 40, 0, 2)
    lineLeft.Position = UDim2.new(0, 0, 0.5, 0)
    lineLeft.AnchorPoint = Vector2.new(0, 0.5)
    lineLeft.BackgroundColor3 = colors.primary
    lineLeft.BorderSizePixel = 0
    lineLeft.Parent = horizontal

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 120, 1, 0)
    lbl.Position = UDim2.new(0, 50, 0, 0)
    lbl.Text = text:upper()
    lbl.TextColor3 = colors.text
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = horizontal

    local lineRight = Instance.new("Frame")
    lineRight.Size = UDim2.new(1, -180, 0, 2)
    lineRight.Position = UDim2.new(0, 170, 0.5, 0)
    lineRight.AnchorPoint = Vector2.new(0, 0.5)
    lineRight.BackgroundColor3 = colors.secondary
    lineRight.BorderSizePixel = 0
    lineRight.Parent = horizontal

    return container
end

-- Checkbox Button
local function CreateCheckBox(text, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundTransparency = 1
    container.LayoutOrder = #ContentFrame:GetChildren() + 1
    container.Parent = ContentFrame
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.Text = ""
    btn.BackgroundColor3 = colors.button
    btn.AutoButtonColor = false
    btn.Parent = container
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    
    local checkBox = Instance.new("Frame")
    checkBox.Size = UDim2.new(0, 22, 0, 22)
    checkBox.Position = UDim2.new(0, 10, 0.5, 0)
    checkBox.AnchorPoint = Vector2.new(0, 0.5)
    checkBox.BackgroundColor3 = colors.input
    checkBox.BorderSizePixel = 0
    checkBox.Parent = btn
    
    local checkCorner = Instance.new("UICorner")
    checkCorner.CornerRadius = UDim.new(0, 6)
    checkCorner.Parent = checkBox
    
    local checkMark = Instance.new("ImageLabel")
    checkMark.Size = UDim2.new(0, 14, 0, 14)
    checkMark.Position = UDim2.new(0.5, 0, 0.5, 0)
    checkMark.AnchorPoint = Vector2.new(0.5, 0.5)
    checkMark.BackgroundTransparency = 1
    checkMark.Image = "rbxassetid://3926305904"
    checkMark.ImageRectOffset = Vector2.new(312, 4)
    checkMark.ImageRectSize = Vector2.new(24, 24)
    checkMark.ImageColor3 = colors.success
    checkMark.Visible = false
    checkMark.Parent = checkBox
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.Position = UDim2.new(0, 40, 0, 0)
    lbl.Text = text
    lbl.TextColor3 = colors.text
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn
    
    local state = false
    
    -- Hover effect
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = colors.buttonHover}):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = colors.button}):Play()
    end)
    
    btn.MouseButton1Click:Connect(function()
        state = not state
        checkMark.Visible = state
        
        if state then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 70, 100)}):Play()
        else
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = colors.button}):Play()
        end
        
        callback(state)
    end)
    
    return btn
end

-- Input field function
local function CreateInputField(placeholder, defaultValue)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 38)
    container.BackgroundTransparency = 1
    container.LayoutOrder = #ContentFrame:GetChildren() + 1
    container.Parent = ContentFrame
    
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, 0, 1, 0)
    input.PlaceholderText = placeholder
    input.Text = defaultValue or ""
    input.BackgroundColor3 = colors.input
    input.TextColor3 = colors.text
    input.Font = Enum.Font.Gotham
    input.TextSize = 14
    input.PlaceholderColor3 = colors.mutedText
    input.ClearTextOnFocus = false
    input.Parent = container
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 8)
    inputCorner.Parent = input
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = input
    
    return input
end

-- Button function
local function CreateButton(text, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 38)
    container.BackgroundTransparency = 1
    container.LayoutOrder = #ContentFrame:GetChildren() + 1
    container.Parent = ContentFrame
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.Text = text
    btn.BackgroundColor3 = colors.primary
    btn.TextColor3 = colors.text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.AutoButtonColor = false
    btn.Parent = container
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    
    -- Hover effect
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 150, 230)}):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = colors.primary}):Play()
    end)
    
    btn.MouseButton1Click:Connect(callback)
    
    return btn
end

-- =========================
-- Highlight Feature
-- =========================
CreateLabel("Highlight")

local highlightCheckbox = CreateCheckBox("Enable Player Highlight", function(state)
    highlightEnabled = state
end)

local keyBox = CreateInputField("Enter key name...", "G")
keyBox.FocusLost:Connect(function()
    local keyName = keyBox.Text:upper()
    if Enum.KeyCode[keyName] then
        highlightKey = Enum.KeyCode[keyName]
        keyBox.Text = keyName
    else
        keyBox.Text = "Invalid Key!"
        task.wait(1)
        keyBox.Text = "G"
        highlightKey = Enum.KeyCode.G
    end
end)

local function applyHighlight(player)
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        if not player.Character:FindFirstChild("PlayerHighlight") then
            local highlight = Instance.new("Highlight")
            highlight.Name = "PlayerHighlight"
            highlight.FillColor = Color3.fromRGB(0, 255, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.Parent = player.Character
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == highlightKey then
        highlightEnabled = not highlightEnabled
        
        -- Update checkbox visually
        local checkMark = highlightCheckbox:FindFirstChildWhichIsA("Frame"):FindFirstChildWhichIsA("ImageLabel")
        if checkMark then
            checkMark.Visible = highlightEnabled
            if highlightEnabled then
                TweenService:Create(highlightCheckbox, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 70, 100)}):Play()
            else
                TweenService:Create(highlightCheckbox, TweenInfo.new(0.2), {BackgroundColor3 = colors.button}):Play()
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if highlightEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                applyHighlight(plr)
            end
        end
    else
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character and plr.Character:FindFirstChild("PlayerHighlight") then
                plr.Character.PlayerHighlight:Destroy()
            end
        end
    end
end)

-- =========================
-- Noclip Feature
-- =========================
CreateLabel("Noclip")

CreateCheckBox("Enable Noclip", function(state)
    noclipEnabled = state
end)

RunService.Stepped:Connect(function()
    if noclipEnabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- =========================
-- WalkSpeed Feature
-- =========================
CreateLabel("Walk Speed")

local speedBox = CreateInputField("Enter walk speed...", tostring(Humanoid.WalkSpeed))

local applyBtn = CreateButton("Apply Speed", function()
    local val = tonumber(speedBox.Text)
    if val then
        Humanoid.WalkSpeed = val
        speedBox.Text = tostring(val)
    else
        speedBox.Text = "Invalid number!"
        task.wait(1)
        speedBox.Text = tostring(Humanoid.WalkSpeed)
    end
end)

-- Warning text below Apply Speed button
local warningContainer = Instance.new("Frame")
warningContainer.Size = UDim2.new(1, 0, 0, 20)
warningContainer.BackgroundTransparency = 1
warningContainer.LayoutOrder = #ContentFrame:GetChildren() + 1
warningContainer.Parent = ContentFrame

local warningText = Instance.new("TextLabel")
warningText.Size = UDim2.new(1, -10, 1, 0)
warningText.Position = UDim2.new(0, 5, 0, 0)
warningText.BackgroundTransparency = 1
warningText.Text = "WARNING: Do not try walking speed in Emergency Hamburg, you may get permanently banned. Thanks!"
warningText.TextColor3 = colors.mutedText
warningText.Font = Enum.Font.Gotham
warningText.TextSize = 11
warningText.TextWrapped = true
warningText.TextXAlignment = Enum.TextXAlignment.Left
warningText.Parent = warningContainer

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = Character:WaitForChild("Humanoid")
    speedBox.Text = tostring(Humanoid.WalkSpeed)
end)

-- =========================
-- Double Jump Feature
-- =========================
CreateLabel("Double Jump")

CreateCheckBox("Enable Double Jump", function(state)
    doubleJumpEnabled = state
end)

Humanoid.StateChanged:Connect(function(_, new)
    if not doubleJumpEnabled then return end
    if new == Enum.HumanoidStateType.Freefall then
        canDoubleJump = true
        hasDoubleJumped = false
    elseif new == Enum.HumanoidStateType.Landed then
        canDoubleJump = false
        hasDoubleJumped = false
    end
end)

UserInputService.JumpRequest:Connect(function()
    if not doubleJumpEnabled then return end
    if canDoubleJump and not hasDoubleJumped then
        hasDoubleJumped = true
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        Humanoid.UseJumpPower = true
        Humanoid.JumpPower = doubleJumpPower
    end
end)

-- =========================
-- Teleport Feature
-- =========================
CreateLabel("Teleport")

local PlayerListFrame = Instance.new("ScrollingFrame")
PlayerListFrame.Size = UDim2.new(1, 0, 0, 160)
PlayerListFrame.BackgroundColor3 = colors.input
PlayerListFrame.ScrollBarThickness = 6
PlayerListFrame.ScrollBarImageColor3 = colors.secondary
PlayerListFrame.LayoutOrder = #ContentFrame:GetChildren() + 1
PlayerListFrame.Parent = ContentFrame

local PlayerListCorner = Instance.new("UICorner")
PlayerListCorner.CornerRadius = UDim.new(0, 8)
PlayerListCorner.Parent = PlayerListFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = PlayerListFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 8)
listPadding.PaddingBottom = UDim.new(0, 8)
listPadding.PaddingLeft = UDim.new(0, 8)
listPadding.PaddingRight = UDim.new(0, 8)
listPadding.Parent = PlayerListFrame

local function refreshPlayerList()
    for _, child in ipairs(PlayerListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -16, 0, 32)
            btn.Text = plr.Name
            btn.BackgroundColor3 = colors.button
            btn.TextColor3 = colors.text
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.AutoButtonColor = false
            btn.Parent = PlayerListFrame
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = btn
            
            -- Hover effect
            btn.MouseEnter:Connect(function()
                if selectedPlayer ~= plr then
                    TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = colors.buttonHover}):Play()
                end
            end)
            
            btn.MouseLeave:Connect(function()
                if selectedPlayer ~= plr then
                    TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = colors.button}):Play()
                end
            end)
            
            btn.MouseButton1Click:Connect(function()
                selectedPlayer = plr
                for _, child in ipairs(PlayerListFrame:GetChildren()) do
                    if child:IsA("TextButton") then
                        if child ~= btn then
                            TweenService:Create(child, TweenInfo.new(0.2), {BackgroundColor3 = colors.button}):Play()
                        end
                    end
                end
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = colors.success}):Play()
            end)
        end
    end
end

refreshPlayerList()
Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)

local TeleportBtn = CreateButton("Teleport to Player", function()
    if selectedPlayer and selectedPlayer.Character and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local target = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and target then
            hrp.CFrame = target.CFrame + Vector3.new(2, 0, 0)
        end
    end
end)

-- =========================
-- Minimize / Restore
-- =========================
local originalSize = MainFrame.Size
local originalPosition = MainFrame.Position

local function toggleMinimize(state)
    if state then
        TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 200, 0, 42)}):Play()
        ContentFrame.Visible = false
        MinBtn.Text = "+"
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = originalSize}):Play()
        ContentFrame.Visible = true
        MinBtn.Text = "–"
    end
    minimized = state
end

MinBtn.MouseButton1Click:Connect(function()
    toggleMinimize(not minimized)
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.Y then
        toggleMinimize(not minimized)
    end
end)
