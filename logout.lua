-- LocalScript (StarterPlayerScripts)

--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

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

-- =========================
-- GUI Setup
-- =========================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MainGui"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 360, 0, 540)
MainFrame.Position = UDim2.new(0, 50, 0, 100)
MainFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- drag GUI with mouse
MainFrame.Parent = ScreenGui

-- Rounded corners
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0,12)
UICorner.Parent = MainFrame

-- Container for scrollable contents
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Size = UDim2.new(1, -20, 1, -60)
ContentFrame.Position = UDim2.new(0, 10, 0, 50)
ContentFrame.BackgroundTransparency = 1
ContentFrame.ScrollBarThickness = 6
ContentFrame.Parent = MainFrame

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0,10)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = ContentFrame

-- Title Bar
local TitleBar = Instance.new("TextLabel")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.Position = UDim2.new(0,0,0,0)
TitleBar.BackgroundColor3 = Color3.fromRGB(35,35,35)
TitleBar.Text = "✨ Custom Player Menu"
TitleBar.TextColor3 = Color3.new(1,1,1)
TitleBar.Font = Enum.Font.SourceSansBold
TitleBar.TextSize = 18
TitleBar.Parent = MainFrame

local UICornerTitle = Instance.new("UICorner", TitleBar)
UICornerTitle.CornerRadius = UDim.new(0,12)

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 40, 0, 40)
MinBtn.Position = UDim2.new(1, -45, 0, 0)
MinBtn.Text = "–"
MinBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
MinBtn.TextColor3 = Color3.new(1,1,1)
MinBtn.Font = Enum.Font.SourceSansBold
MinBtn.TextSize = 20
MinBtn.Parent = MainFrame
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0,8)

-- Section Label
local function CreateLabel(text)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -20, 0, 25)
	lbl.Text = "— " .. text .. " —"
	lbl.TextColor3 = Color3.fromRGB(0,200,255)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.SourceSansBold
	lbl.TextSize = 18
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.Parent = ContentFrame
	return lbl
end

-- Checkbox Button
local function CreateCheckBox(text, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 200, 0, 32)
	btn.Text = "[ ] " .. text
	btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.SourceSans
	btn.TextSize = 16
	btn.Parent = ContentFrame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

	local state = false
	btn.MouseButton1Click:Connect(function()
		state = not state
		if state then
			btn.Text = "[✔] " .. text
			btn.BackgroundColor3 = Color3.fromRGB(0,170,100)
		else
			btn.Text = "[ ] " .. text
			btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
		end
		callback(state)
	end)

	return btn
end

-- =========================
-- Highlight Feature
-- =========================
CreateLabel("Highlight")

CreateCheckBox("Enable Highlight", function(state)
	highlightEnabled = state
end)

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(0, 200, 0, 32)
keyBox.Text = "Current Key: G"
keyBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
keyBox.TextColor3 = Color3.new(1,1,1)
keyBox.Font = Enum.Font.SourceSans
keyBox.TextSize = 16
keyBox.Parent = ContentFrame
Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0,8)

keyBox.FocusLost:Connect(function()
	local keyName = keyBox.Text:upper()
	if Enum.KeyCode[keyName] then
		highlightKey = Enum.KeyCode[keyName]
		keyBox.Text = "Current Key: " .. keyName
	else
		keyBox.Text = "Invalid Key!"
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

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0, 200, 0, 32)
speedBox.Text = tostring(Humanoid.WalkSpeed)
speedBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
speedBox.TextColor3 = Color3.new(1,1,1)
speedBox.Font = Enum.Font.SourceSans
speedBox.TextSize = 16
speedBox.Parent = ContentFrame
Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0,8)

local applyBtn = Instance.new("TextButton")
applyBtn.Size = UDim2.new(0, 200, 0, 32)
applyBtn.Text = "Apply Speed"
applyBtn.BackgroundColor3 = Color3.fromRGB(0,170,255)
applyBtn.TextColor3 = Color3.new(1,1,1)
applyBtn.Font = Enum.Font.SourceSansBold
applyBtn.TextSize = 16
applyBtn.Parent = ContentFrame
Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0,8)

applyBtn.MouseButton1Click:Connect(function()
	local val = tonumber(speedBox.Text)
	if val then
		Humanoid.WalkSpeed = val
	end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
	Character = char
	Humanoid = Character:WaitForChild("Humanoid")
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
PlayerListFrame.Size = UDim2.new(0, 220, 0, 150)
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(45,45,45)
PlayerListFrame.ScrollBarThickness = 6
PlayerListFrame.Parent = ContentFrame
Instance.new("UICorner", PlayerListFrame).CornerRadius = UDim.new(0,8)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0,5)
listLayout.Parent = PlayerListFrame

local function refreshPlayerList()
	for _, child in ipairs(PlayerListFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -10, 0, 30)
			btn.Text = plr.Name
			btn.BackgroundColor3 = Color3.fromRGB(80,80,80)
			btn.TextColor3 = Color3.new(1,1,1)
			btn.Parent = PlayerListFrame
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

			btn.MouseButton1Click:Connect(function()
				selectedPlayer = plr
				for _, child in ipairs(PlayerListFrame:GetChildren()) do
					if child:IsA("TextButton") then
						child.BackgroundColor3 = Color3.fromRGB(80,80,80)
					end
				end
				btn.BackgroundColor3 = Color3.fromRGB(0,200,0)
			end)
		end
	end
end

refreshPlayerList()
Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)

local TeleportBtn = Instance.new("TextButton")
TeleportBtn.Size = UDim2.new(0, 200, 0, 32)
TeleportBtn.Text = "Teleport"
TeleportBtn.BackgroundColor3 = Color3.fromRGB(0,170,255)
TeleportBtn.TextColor3 = Color3.new(1,1,1)
TeleportBtn.Font = Enum.Font.SourceSansBold
TeleportBtn.TextSize = 16
TeleportBtn.Parent = ContentFrame
Instance.new("UICorner", TeleportBtn).CornerRadius = UDim.new(0,8)

TeleportBtn.MouseButton1Click:Connect(function()
	if selectedPlayer and selectedPlayer.Character and LocalPlayer.Character then
		local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		local target = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
		if hrp and target then
			hrp.CFrame = target.CFrame + Vector3.new(2,0,0)
		end
	end
end)

-- =========================
-- Minimize / Restore
-- =========================
local originalSize = MainFrame.Size

local function toggleMinimize(state)
	if state then
		MainFrame.Size = UDim2.new(0, 200, 0, 40)
		ContentFrame.Visible = false
	else
		MainFrame.Size = originalSize
		ContentFrame.Visible = true
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
