local coreGui = game:GetService("CoreGui")
local players = game:GetService("Players")
local lighting = game:GetService("Lighting")
local userInputService = game:GetService("UserInputService")
local workspaceService = game:GetService("Workspace")
local tweenService = game:GetService("TweenService")

local localPlayer = players.LocalPlayer or players:GetPropertyChangedSignal("LocalPlayer"):Wait()

local function cleanupExisting()
	local targets = {}
	if typeof(gethui) == "function" then
		pcall(function()
			table.insert(targets, gethui())
		end)
	end
	pcall(function()
		table.insert(targets, coreGui)
	end)
	if localPlayer and localPlayer:FindFirstChild("PlayerGui") then
		table.insert(targets, localPlayer.PlayerGui)
	end
	for _, parent in ipairs(targets) do
		for _, child in ipairs(parent:GetChildren()) do
			if child.Name == "Cascade" then
				pcall(function()
					child:Destroy()
				end)
			end
		end
	end
end

cleanupExisting()

local importUrl = "https://github.com/cascadeui/Cascade/releases/latest/download/dist.luau"
local cascade = loadstring(game:HttpGetAsync(importUrl))()

local function getAsset(fileName, rawUrl)
	local localPath = "Staconf/assets/" .. fileName
	if typeof(getcustomasset) == "function" and typeof(writefile) == "function" then
		local hasFile = (typeof(isfile) == "function" and isfile(localPath))
		if not hasFile then
			local s, data = pcall(function()
				return game:HttpGetAsync(rawUrl)
			end)
			if s and data then
				if typeof(makefolder) == "function" then
					pcall(function()
						makefolder("Staconf")
						makefolder("Staconf/assets")
					end)
				end
				pcall(function()
					writefile(localPath, data)
				end)
			end
		end
		local sAsset, assetId = pcall(function()
			return getcustomasset(localPath)
		end)
		if sAsset and assetId then
			return assetId
		end
	end
	return rawUrl
end

local function titledRow(parent, title, subtitle)
	local row = parent:Row({
		SearchIndex = title,
	})
	row:Left():TitleStack({
		Title = title,
		Subtitle = subtitle,
	})
	return row
end

local app = cascade.New({
	WindowPill = true,
	Theme = cascade.Themes.Dark,
	Accent = cascade.Accents.Blue,
})

local window = app:Window({
	Title = "Cascade Deck",
	Subtitle = "macOS Sequoia Runtime Console",
	Size = userInputService.TouchEnabled and UDim2.fromOffset(600, 380) or UDim2.fromOffset(800, 520),
	Searching = true,
	Draggable = true,
	Resizable = true,
	CanExit = true,
	CanMinimize = true,
	CanZoom = true,
	Dropshadow = true,
	UIBlur = true,
})

local acrylicBlur = lighting:FindFirstChild("CascadeAcrylicBlur")
if not acrylicBlur then
	acrylicBlur = Instance.new("BlurEffect")
	acrylicBlur.Name = "CascadeAcrylicBlur"
	acrylicBlur.Size = 14
	acrylicBlur.Parent = lighting
end

window.Destroying:Connect(function()
	if acrylicBlur and acrylicBlur.Parent then
		acrylicBlur:Destroy()
	end
end)

local minimizeKey = Enum.KeyCode.RightControl
userInputService.InputEnded:Connect(function(input, processed)
	if input.KeyCode == minimizeKey and not processed then
		window.Minimized = not window.Minimized
		if acrylicBlur then
			acrylicBlur.Enabled = not window.Minimized
		end
	end
end)

local currentMode = "Dark"
local currentAccent = "Blue"
local currentCascadeGui = nil

local modeColors = {
	Dark = {
		bodyBg = Color3.fromRGB(16, 18, 25),
		bodyTrans = 0.32,
		contentBg = Color3.fromRGB(14, 16, 22),
		contentTrans = 0.28,
		sidebarTop = Color3.fromRGB(30, 34, 46),
		sidebarBottom = Color3.fromRGB(18, 20, 28),
		sidebarTransTop = 0.35,
		sidebarTransBottom = 0.48,
		separatorBg = Color3.fromRGB(40, 44, 58),
		separatorTrans = 0.4,
	},
	Light = {
		bodyBg = Color3.fromRGB(240, 242, 246),
		bodyTrans = 0.15,
		contentBg = Color3.fromRGB(255, 255, 255),
		contentTrans = 0.08,
		sidebarTop = Color3.fromRGB(255, 255, 255),
		sidebarBottom = Color3.fromRGB(224, 227, 235),
		sidebarTransTop = 0.08,
		sidebarTransBottom = 0.22,
		separatorBg = Color3.fromRGB(218, 221, 227),
		separatorTrans = 0.4,
	},
}

local gradTopVal = Instance.new("Color3Value")
gradTopVal.Value = modeColors.Dark.sidebarTop
local gradBottomVal = Instance.new("Color3Value")
gradBottomVal.Value = modeColors.Dark.sidebarBottom
local gradTopTransVal = Instance.new("NumberValue")
gradTopTransVal.Value = modeColors.Dark.sidebarTransTop
local gradBottomTransVal = Instance.new("NumberValue")
gradBottomTransVal.Value = modeColors.Dark.sidebarTransBottom

local trackedGradients = {}

local function syncGradient(grad)
	if grad and grad.Parent then
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, gradTopVal.Value),
			ColorSequenceKeypoint.new(1, gradBottomVal.Value),
		})
		grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, math.clamp(gradTopTransVal.Value, 0, 1)),
			NumberSequenceKeypoint.new(1, math.clamp(gradBottomTransVal.Value, 0, 1)),
		})
	end
end

local function trackGradient(grad)
	table.insert(trackedGradients, grad)
	syncGradient(grad)
	grad.Destroying:Connect(function()
		for i = #trackedGradients, 1, -1 do
			if trackedGradients[i] == grad then
				table.remove(trackedGradients, i)
			end
		end
	end)
end

local function onGradientValueChanged()
	for _, grad in ipairs(trackedGradients) do
		syncGradient(grad)
	end
end

gradTopVal.Changed:Connect(onGradientValueChanged)
gradBottomVal.Changed:Connect(onGradientValueChanged)
gradTopTransVal.Changed:Connect(onGradientValueChanged)
gradBottomTransVal.Changed:Connect(onGradientValueChanged)

local modalDimmer = nil
local middlePanel = nil
local isModalOpen = false

local function openMiddlePanel()
	if not modalDimmer or not middlePanel then return end
	isModalOpen = true
	modalDimmer.Visible = true
	middlePanel.Visible = true
	modalDimmer.BackgroundTransparency = 1
	local panelScale = middlePanel:FindFirstChildOfClass("UIScale")
	if panelScale then
		panelScale.Scale = 0.92
	end
	tweenService:Create(modalDimmer, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.45,
	}):Play()
	if panelScale then
		tweenService:Create(panelScale, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Scale = 1,
		}):Play()
	end
end

local function closeMiddlePanel()
	if not modalDimmer or not middlePanel then return end
	isModalOpen = false
	tweenService:Create(modalDimmer, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	}):Play()
	local panelScale = middlePanel:FindFirstChildOfClass("UIScale")
	if panelScale then
		local t = tweenService:Create(panelScale, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Scale = 0.92,
		})
		t:Play()
		t.Completed:Connect(function()
			if not isModalOpen then
				modalDimmer.Visible = false
				middlePanel.Visible = false
			end
		end)
	else
		modalDimmer.Visible = false
		middlePanel.Visible = false
	end
end

_G.CascadeOpenMiddlePanel = openMiddlePanel
_G.CascadeCloseMiddlePanel = closeMiddlePanel

local function createMiddlePanel(targetGui)
	local body = targetGui:FindFirstChild("Body", true)
	if not body then return end
	local layoutIgnore = body:FindFirstChild("LayoutIgnore") or body
	if layoutIgnore:FindFirstChild("MiddlePanel") then return end

	modalDimmer = Instance.new("TextButton")
	modalDimmer.Name = "ModalDimmer"
	modalDimmer.Text = ""
	modalDimmer.AutoButtonColor = false
	modalDimmer.BorderSizePixel = 0
	modalDimmer.Size = UDim2.fromScale(1, 1)
	modalDimmer.Position = UDim2.fromScale(0, 0)
	modalDimmer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	modalDimmer.BackgroundTransparency = 1
	modalDimmer.ZIndex = 80
	modalDimmer.Visible = false

	local dimmerCorner = Instance.new("UICorner")
	dimmerCorner.CornerRadius = UDim.new(0, 22)
	dimmerCorner.Parent = modalDimmer

	modalDimmer.MouseButton1Click:Connect(closeMiddlePanel)
	modalDimmer.Parent = layoutIgnore

	middlePanel = Instance.new("Frame")
	middlePanel.Name = "MiddlePanel"
	middlePanel.AnchorPoint = Vector2.new(0.5, 0.5)
	middlePanel.Position = UDim2.new(0.5, 0, 0.5, 0)
	middlePanel.Size = UDim2.new(0, 460, 0, 360)
	middlePanel.ZIndex = 90
	middlePanel.BorderSizePixel = 0
	middlePanel.BackgroundColor3 = (currentMode == "Light" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(30, 32, 42))
	middlePanel.Visible = false

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 18)
	panelCorner.Parent = middlePanel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Thickness = 1
	panelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	panelStroke.Color = (currentMode == "Light" and Color3.fromRGB(218, 220, 226) or Color3.fromRGB(55, 60, 75))
	panelStroke.Parent = middlePanel

	local panelScale = Instance.new("UIScale")
	panelScale.Scale = 1
	panelScale.Parent = middlePanel

	local panelPadding = Instance.new("UIPadding")
	panelPadding.PaddingTop = UDim.new(0, 16)
	panelPadding.PaddingBottom = UDim.new(0, 16)
	panelPadding.PaddingLeft = UDim.new(0, 20)
	panelPadding.PaddingRight = UDim.new(0, 20)
	panelPadding.Parent = middlePanel

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Text = "Pointer Control"
	titleLabel.TextSize = 16
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextColor3 = (currentMode == "Light" and Color3.fromRGB(30, 30, 30) or Color3.fromRGB(255, 255, 255))
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(1, 0, 0, 24)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.Parent = middlePanel

	local formCard = Instance.new("Frame")
	formCard.Name = "FormCard"
	formCard.Size = UDim2.new(1, 0, 0, 240)
	formCard.Position = UDim2.new(0, 0, 0, 32)
	formCard.BorderSizePixel = 0
	formCard.BackgroundColor3 = (currentMode == "Light" and Color3.fromRGB(244, 246, 250) or Color3.fromRGB(20, 22, 30))
	local formCorner = Instance.new("UICorner")
	formCorner.CornerRadius = UDim.new(0, 12)
	formCorner.Parent = formCard

	local formList = Instance.new("UIListLayout")
	formList.FillDirection = Enum.FillDirection.Vertical
	formList.SortOrder = Enum.SortOrder.LayoutOrder
	formList.Parent = formCard

	local function addModalToggleRow(title, defaultVal, order)
		local row = Instance.new("Frame")
		row.Name = "Row_" .. tostring(order)
		row.Size = UDim2.new(1, 0, 0, 44)
		row.BackgroundTransparency = 1
		row.LayoutOrder = order

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 14)
		pad.PaddingRight = UDim.new(0, 14)
		pad.Parent = row

		local lbl = Instance.new("TextLabel")
		lbl.Text = title
		lbl.TextSize = 14
		lbl.Font = Enum.Font.SourceSans
		lbl.TextColor3 = (currentMode == "Light" and Color3.fromRGB(35, 35, 35) or Color3.fromRGB(235, 235, 235))
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.AnchorPoint = Vector2.new(0, 0.5)
		lbl.Position = UDim2.new(0, 0, 0.5, 0)
		lbl.Size = UDim2.new(1, -60, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Parent = row

		local togBtn = Instance.new("TextButton")
		togBtn.Name = "Toggle"
		togBtn.Text = ""
		togBtn.AutoButtonColor = false
		togBtn.AnchorPoint = Vector2.new(1, 0.5)
		togBtn.Position = UDim2.new(1, 0, 0.5, 0)
		togBtn.Size = UDim2.fromOffset(38, 22)
		togBtn.BorderSizePixel = 0
		togBtn.BackgroundColor3 = (defaultVal and Color3.fromRGB(0, 122, 255) or (currentMode == "Light" and Color3.fromRGB(220, 222, 228) or Color3.fromRGB(60, 62, 70)))
		local togCorner = Instance.new("UICorner")
		togCorner.CornerRadius = UDim.new(0, 11)
		togCorner.Parent = togBtn

		local knob = Instance.new("Frame")
		knob.Name = "Knob"
		knob.AnchorPoint = Vector2.new(0, 0.5)
		knob.Position = (defaultVal and UDim2.new(0, 16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0))
		knob.Size = UDim2.fromOffset(20, 18)
		knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		knob.BorderSizePixel = 0
		local knobCorner = Instance.new("UICorner")
		knobCorner.CornerRadius = UDim.new(0, 9)
		knobCorner.Parent = knob

		local val = defaultVal
		togBtn.MouseButton1Click:Connect(function()
			val = not val
			local targetCol = val and Color3.fromRGB(0, 122, 255) or (currentMode == "Light" and Color3.fromRGB(220, 222, 228) or Color3.fromRGB(60, 62, 70))
			local targetPos = val and UDim2.new(0, 16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
			tweenService:Create(togBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundColor3 = targetCol }):Play()
			tweenService:Create(knob, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = targetPos }):Play()
		end)
		knob.Parent = togBtn
		togBtn.Parent = row
		row.Parent = formCard

		local sep = Instance.new("Frame")
		sep.Name = "Sep"
		sep.Size = UDim2.new(1, -28, 0, 1)
		sep.Position = UDim2.new(0, 14, 1, 0)
		sep.BackgroundColor3 = (currentMode == "Light" and Color3.fromRGB(226, 229, 235) or Color3.fromRGB(36, 40, 52))
		sep.BorderSizePixel = 0
		sep.LayoutOrder = order + 1
		sep.Parent = formCard
	end

	addModalToggleRow("Use trackpad for scrolling", true, 1)
	addModalToggleRow("Use inertia when scrolling", true, 3)

	local sliderRow = Instance.new("Frame")
	sliderRow.Name = "Row_Slider"
	sliderRow.Size = UDim2.new(1, 0, 0, 48)
	sliderRow.BackgroundTransparency = 1
	sliderRow.LayoutOrder = 5

	local sPad = Instance.new("UIPadding")
	sPad.PaddingLeft = UDim.new(0, 14)
	sPad.PaddingRight = UDim.new(0, 14)
	sPad.Parent = sliderRow

	local sLbl = Instance.new("TextLabel")
	sLbl.Text = "Scroll speed"
	sLbl.TextSize = 14
	sLbl.Font = Enum.Font.SourceSans
	sLbl.TextColor3 = (currentMode == "Light" and Color3.fromRGB(35, 35, 35) or Color3.fromRGB(235, 235, 235))
	sLbl.TextXAlignment = Enum.TextXAlignment.Left
	sLbl.AnchorPoint = Vector2.new(0, 0.5)
	sLbl.Position = UDim2.new(0, 0, 0.5, 0)
	sLbl.Size = UDim2.new(0, 140, 1, 0)
	sLbl.BackgroundTransparency = 1
	sLbl.Parent = sliderRow

	local sTrack = Instance.new("Frame")
	sTrack.Name = "SliderTrack"
	sTrack.AnchorPoint = Vector2.new(1, 0.5)
	sTrack.Position = UDim2.new(1, -24, 0.5, 0)
	sTrack.Size = UDim2.fromOffset(130, 7)
	sTrack.BackgroundColor3 = (currentMode == "Light" and Color3.fromRGB(218, 221, 228) or Color3.fromRGB(50, 54, 68))
	sTrack.BorderSizePixel = 0
	local sTrackCorner = Instance.new("UICorner")
	sTrackCorner.CornerRadius = UDim.new(0, 4)
	sTrackCorner.Parent = sTrack

	local sFill = Instance.new("Frame")
	sFill.Name = "Fill"
	sFill.Size = UDim2.fromScale(0.6, 1)
	sFill.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
	sFill.BorderSizePixel = 0
	local sFillCorner = Instance.new("UICorner")
	sFillCorner.CornerRadius = UDim.new(0, 4)
	sFillCorner.Parent = sFill
	sFill.Parent = sTrack

	local sThumb = Instance.new("Frame")
	sThumb.Name = "Thumb"
	sThumb.AnchorPoint = Vector2.new(0.5, 0.5)
	sThumb.Position = UDim2.new(1, 0, 0.5, 0)
	sThumb.Size = UDim2.fromOffset(14, 19)
	sThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sThumb.BorderSizePixel = 0
	local sThumbCorner = Instance.new("UICorner")
	sThumbCorner.CornerRadius = UDim.new(0, 7)
	sThumbCorner.Parent = sThumb

	local sThumbStroke = Instance.new("UIStroke")
	sThumbStroke.Thickness = 1
	sThumbStroke.Color = Color3.fromRGB(0, 0, 0)
	sThumbStroke.Transparency = 0.8
	sThumbStroke.Parent = sThumb
	sThumb.Parent = sFill

	local turtleLbl = Instance.new("TextLabel")
	turtleLbl.Text = "🐢"
	turtleLbl.TextSize = 13
	turtleLbl.BackgroundTransparency = 1
	turtleLbl.AnchorPoint = Vector2.new(1, 0.5)
	turtleLbl.Position = UDim2.new(1, -160, 0.5, 0)
	turtleLbl.Size = UDim2.fromOffset(20, 20)
	turtleLbl.Parent = sliderRow

	local hareLbl = Instance.new("TextLabel")
	hareLbl.Text = "🐇"
	hareLbl.TextSize = 13
	hareLbl.BackgroundTransparency = 1
	hareLbl.AnchorPoint = Vector2.new(1, 0.5)
	hareLbl.Position = UDim2.new(1, 0, 0.5, 0)
	hareLbl.Size = UDim2.fromOffset(20, 20)
	hareLbl.Parent = sliderRow

	sTrack.Parent = sliderRow
	sliderRow.Parent = formCard

	local sep2 = Instance.new("Frame")
	sep2.Name = "Sep2"
	sep2.Size = UDim2.new(1, -28, 0, 1)
	sep2.Position = UDim2.new(0, 14, 1, 0)
	sep2.BackgroundColor3 = (currentMode == "Light" and Color3.fromRGB(226, 229, 235) or Color3.fromRGB(36, 40, 52))
	sep2.BorderSizePixel = 0
	sep2.LayoutOrder = 6
	sep2.Parent = formCard

	addModalToggleRow("Use trackpad for dragging", false, 7)

	local dragStyleRow = Instance.new("Frame")
	dragStyleRow.Name = "Row_DragStyle"
	dragStyleRow.Size = UDim2.new(1, 0, 0, 44)
	dragStyleRow.BackgroundTransparency = 1
	dragStyleRow.LayoutOrder = 9

	local dPad = Instance.new("UIPadding")
	dPad.PaddingLeft = UDim.new(0, 14)
	dPad.PaddingRight = UDim.new(0, 14)
	dPad.Parent = dragStyleRow

	local dLbl = Instance.new("TextLabel")
	dLbl.Text = "Dragging style"
	dLbl.TextSize = 14
	dLbl.Font = Enum.Font.SourceSans
	dLbl.TextColor3 = (currentMode == "Light" and Color3.fromRGB(35, 35, 35) or Color3.fromRGB(235, 235, 235))
	dLbl.TextXAlignment = Enum.TextXAlignment.Left
	dLbl.AnchorPoint = Vector2.new(0, 0.5)
	dLbl.Position = UDim2.new(0, 0, 0.5, 0)
	dLbl.Size = UDim2.new(0, 140, 1, 0)
	dLbl.BackgroundTransparency = 1
	dLbl.Parent = dragStyleRow

	local styleVal = Instance.new("TextLabel")
	styleVal.Text = "Without Drag Lock ⬍"
	styleVal.TextSize = 13
	styleVal.Font = Enum.Font.SourceSans
	styleVal.TextColor3 = (currentMode == "Light" and Color3.fromRGB(130, 133, 140) or Color3.fromRGB(150, 155, 170))
	styleVal.TextXAlignment = Enum.TextXAlignment.Right
	styleVal.AnchorPoint = Vector2.new(1, 0.5)
	styleVal.Position = UDim2.new(1, 0, 0.5, 0)
	styleVal.Size = UDim2.new(0, 150, 1, 0)
	styleVal.BackgroundTransparency = 1
	styleVal.Parent = dragStyleRow

	dragStyleRow.Parent = formCard
	formCard.Parent = middlePanel

	local footerBar = Instance.new("Frame")
	footerBar.Name = "Footer"
	footerBar.Size = UDim2.new(1, 0, 0, 36)
	footerBar.Position = UDim2.new(0, 0, 1, -36)
	footerBar.BackgroundTransparency = 1

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Name = "Cancel"
	cancelBtn.Text = "Cancel"
	cancelBtn.TextSize = 13
	cancelBtn.Font = Enum.Font.SourceSans
	cancelBtn.TextColor3 = (currentMode == "Light" and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(240, 240, 240))
	cancelBtn.BackgroundColor3 = (currentMode == "Light" and Color3.fromRGB(236, 238, 244) or Color3.fromRGB(45, 48, 60))
	cancelBtn.BorderSizePixel = 0
	cancelBtn.AnchorPoint = Vector2.new(1, 0.5)
	cancelBtn.Position = UDim2.new(1, -88, 0.5, 0)
	cancelBtn.Size = UDim2.fromOffset(78, 28)
	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 8)
	cCorner.Parent = cancelBtn
	cancelBtn.MouseButton1Click:Connect(closeMiddlePanel)
	cancelBtn.Parent = footerBar

	local okBtn = Instance.new("TextButton")
	okBtn.Name = "OK"
	okBtn.Text = "OK"
	okBtn.TextSize = 13
	okBtn.Font = Enum.Font.SourceSansBold
	okBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	okBtn.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
	okBtn.BorderSizePixel = 0
	okBtn.AnchorPoint = Vector2.new(1, 0.5)
	okBtn.Position = UDim2.new(1, 0, 0.5, 0)
	okBtn.Size = UDim2.fromOffset(78, 28)
	local okCorner = Instance.new("UICorner")
	okCorner.CornerRadius = UDim.new(0, 8)
	okCorner.Parent = okBtn
	okBtn.MouseButton1Click:Connect(closeMiddlePanel)
	okBtn.Parent = footerBar

	footerBar.Parent = middlePanel
	middlePanel.Parent = layoutIgnore
end

local function applyModernVisuals(targetGui)
	currentCascadeGui = targetGui
	local function updateVisual(obj)
		if obj:IsA("UICorner") and obj.CornerRadius.Scale == 0 then
			local off = obj.CornerRadius.Offset
			if off == 10 then
				obj.CornerRadius = UDim.new(0, 22)
			elseif off == 6 then
				obj.CornerRadius = UDim.new(0, 14)
			elseif off == 5 or off == 4 then
				obj.CornerRadius = UDim.new(0, 10)
			end
		elseif obj.Name == "Disclosure" or obj.Name == "SectionHeader" then
			obj.Visible = false
		elseif obj.Name == "Body" and obj:IsA("Frame") then
			local cfg = modeColors[currentMode]
			obj.BackgroundTransparency = cfg.bodyTrans
			obj.BackgroundColor3 = cfg.bodyBg
			createMiddlePanel(targetGui)
		elseif obj.Name == "Sidebar" and obj:IsA("Frame") then
			local corner = obj:FindFirstChild("SidebarCorner")
			if not corner then
				corner = Instance.new("UICorner")
				corner.Name = "SidebarCorner"
				corner.CornerRadius = UDim.new(0, 22)
				corner.Parent = obj
			end
			local filler = obj:FindFirstChild("RightEdgeFiller")
			if not filler then
				filler = Instance.new("Frame")
				filler.Name = "RightEdgeFiller"
				filler.BorderSizePixel = 0
				filler.AnchorPoint = Vector2.new(1, 0)
				filler.Position = UDim2.new(1, 0, 0, 0)
				filler.Size = UDim2.new(0, 32, 1, 0)
				filler.ZIndex = obj.ZIndex
				filler.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				filler.BackgroundTransparency = 0
				filler.Parent = obj
			else
				filler.Size = UDim2.new(0, 32, 1, 0)
			end
			local grad = obj:FindFirstChild("SidebarGradient")
			if not grad then
				grad = Instance.new("UIGradient")
				grad.Name = "SidebarGradient"
				grad.Rotation = 90
				grad.Parent = obj
				trackGradient(grad)
			end
			local fillerGrad = filler:FindFirstChild("FillerGradient")
			if not fillerGrad then
				fillerGrad = Instance.new("UIGradient")
				fillerGrad.Name = "FillerGradient"
				fillerGrad.Rotation = 90
				fillerGrad.Parent = filler
				trackGradient(fillerGrad)
			end
			obj.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			obj.BackgroundTransparency = 0
			filler.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			filler.BackgroundTransparency = 0
		elseif obj.Name == "Toolbar" and obj:IsA("Frame") then
			obj.BackgroundTransparency = 1
		elseif obj.Name == "Separator" and obj:IsA("Frame") then
			local cfg = modeColors[currentMode]
			obj.BackgroundTransparency = cfg.separatorTrans
			obj.BackgroundColor3 = cfg.separatorBg
			obj.ZIndex = 5
		elseif obj.Name == "ContentBody" and obj:IsA("Frame") then
			local cfg = modeColors[currentMode]
			obj.BackgroundTransparency = cfg.contentTrans
			obj.BackgroundColor3 = cfg.contentBg
			local cornerClip = obj:FindFirstChild("CornerClip")
			if cornerClip then
				cornerClip.AnchorPoint = Vector2.new(0, 0)
				cornerClip.Position = UDim2.new(0, 0, 0, 0)
				cornerClip.Size = UDim2.new(0, 32, 1, 0)
				cornerClip.BorderSizePixel = 0
				cornerClip.BackgroundColor3 = cfg.contentBg
				cornerClip.BackgroundTransparency = cfg.contentTrans
				cornerClip.ZIndex = obj.ZIndex
			end
		elseif obj.Name == "Toggle" and obj:IsA("Frame") then
			obj.Size = UDim2.fromOffset(38, 22)
			local sw = obj:FindFirstChild("Switch")
			if sw and sw:IsA("ImageButton") then
				sw.Size = UDim2.fromOffset(38, 22)
				local knob = sw:FindFirstChild("Knob")
				if knob and knob:IsA("ImageLabel") then
					knob.Size = UDim2.fromOffset(20, 18)
					knob.AnchorPoint = Vector2.new(0, 0.5)
					knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					knob.BackgroundTransparency = 0
					knob.ImageTransparency = 1
					local corner = knob:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", knob)
					corner.CornerRadius = UDim.new(0, 9)
					local stroke = knob:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", knob)
					stroke.Thickness = 1
					stroke.Color = Color3.fromRGB(0, 0, 0)
					stroke.Transparency = 0.88
					local fx = knob:FindFirstChild("Effects")
					if fx then fx.Visible = false end

					if not knob:GetAttribute("Tracked") then
						knob:SetAttribute("Tracked", true)
						local updating = false
						local function updatePos()
							if updating then return end
							updating = true
							if knob.Position.X.Offset > 5 or knob.Position.X.Scale > 0.3 then
								knob.Position = UDim2.new(0, 16, 0.5, 0)
							else
								knob.Position = UDim2.new(0, 2, 0.5, 0)
							end
							updating = false
						end
						knob:GetPropertyChangedSignal("Position"):Connect(updatePos)
						updatePos()
					end
				end
			end
		elseif obj.Name == "Slider" and obj:IsA("ImageLabel") then
			obj.Size = UDim2.fromOffset(150, 7)
			local trackCorner = obj:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", obj)
			trackCorner.CornerRadius = UDim.new(0, 4)
			local fill = obj:FindFirstChild("Fill")
			if fill then
				local fillCorner = fill:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", fill)
				fillCorner.CornerRadius = UDim.new(0, 4)
				local thumb = fill:FindFirstChild("Thumb")
				if thumb then
					thumb.Size = UDim2.fromOffset(14, 19)
					thumb.AnchorPoint = Vector2.new(0.5, 0.5)
					thumb.Position = UDim2.new(1, 0, 0.5, 0)
					thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					thumb.BackgroundTransparency = 0
					local thumbCorner = thumb:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", thumb)
					thumbCorner.CornerRadius = UDim.new(0, 7)
					local stroke = thumb:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", thumb)
					stroke.Thickness = 1
					stroke.Color = Color3.fromRGB(0, 0, 0)
					stroke.Transparency = 0.82
					local bg = thumb:FindFirstChild("Background")
					if bg then bg.Visible = false end
					local fx = thumb:FindFirstChild("ThumbEffects")
					if fx then fx.Visible = false end
				end
			end
		elseif obj.Name == "SidebarItem" and (obj:IsA("TextButton") or obj:IsA("Frame")) then
			local leading = obj:FindFirstChild("Leading")
			local titleObj = leading and leading:FindFirstChild("Title")
			local sym = leading and leading:FindFirstChild("Symbol")
			if sym and titleObj and sym:IsA("ImageLabel") then
				local tText = titleObj.Text
				local badgeCol = Color3.fromRGB(0, 122, 255)
				if tText == "Atmosphere" then
					badgeCol = Color3.fromRGB(255, 149, 0)
				elseif tText == "Locomotion" then
					badgeCol = Color3.fromRGB(52, 199, 89)
				elseif tText == "Appearance" then
					badgeCol = Color3.fromRGB(44, 44, 46)
				end
				local badge = leading:FindFirstChild("BadgeBackground")
				if not badge then
					badge = Instance.new("Frame")
					badge.Name = "BadgeBackground"
					badge.Size = UDim2.fromOffset(22, 22)
					badge.AnchorPoint = Vector2.new(0, 0.5)
					badge.Position = UDim2.new(0, 0, 0.5, 0)
					badge.BorderSizePixel = 0
					badge.BackgroundColor3 = badgeCol
					badge.ZIndex = sym.ZIndex
					local bCorner = Instance.new("UICorner")
					bCorner.CornerRadius = UDim.new(0, 6)
					bCorner.Parent = badge
					badge.Parent = leading
					sym.ZIndex = badge.ZIndex + 1
					sym.Size = UDim2.fromOffset(14, 14)
					sym.AnchorPoint = Vector2.new(0.5, 0.5)
					sym.Position = UDim2.fromScale(0.5, 0.5)
					sym.Parent = badge
				else
					badge.BackgroundColor3 = badgeCol
				end
			end
		end
	end

	for _, descendant in ipairs(targetGui:GetDescendants()) do
		updateVisual(descendant)
	end

	targetGui.DescendantAdded:Connect(function(descendant)
		task.defer(updateVisual, descendant)
	end)
end

local function smoothTransition(newMode, newAccentName)
	local tweenInfo = TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local targetGui = currentCascadeGui
	local snapshot = {}

	if targetGui then
		for _, desc in ipairs(targetGui:GetDescendants()) do
			if desc:IsA("GuiObject") and desc.Name ~= "RightEdgeFiller" and desc.Name ~= "Sidebar" then
				local entry = {
					BackgroundColor3 = desc.BackgroundColor3,
					BackgroundTransparency = desc.BackgroundTransparency,
				}
				if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
					entry.TextColor3 = desc.TextColor3
				end
				if desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
					entry.ImageColor3 = desc.ImageColor3
				end
				snapshot[desc] = entry
			end
		end
	end

	if newMode and modeColors[newMode] and newMode ~= currentMode then
		currentMode = newMode
		app.Theme = (newMode == "Dark" and cascade.Themes.Dark or cascade.Themes.Light)
		local cfg = modeColors[newMode]

		tweenService:Create(gradTopVal, tweenInfo, { Value = cfg.sidebarTop }):Play()
		tweenService:Create(gradBottomVal, tweenInfo, { Value = cfg.sidebarBottom }):Play()
		tweenService:Create(gradTopTransVal, tweenInfo, { Value = cfg.sidebarTransTop }):Play()
		tweenService:Create(gradBottomTransVal, tweenInfo, { Value = cfg.sidebarTransBottom }):Play()

		if targetGui then
			local body = targetGui:FindFirstChild("Body", true)
			if body and body:IsA("Frame") then
				tweenService:Create(body, tweenInfo, {
					BackgroundColor3 = cfg.bodyBg,
					BackgroundTransparency = cfg.bodyTrans,
				}):Play()
			end
			local content = targetGui:FindFirstChild("ContentBody", true)
			if content and content:IsA("Frame") then
				tweenService:Create(content, tweenInfo, {
					BackgroundColor3 = cfg.contentBg,
					BackgroundTransparency = cfg.contentTrans,
				}):Play()
			end
			local sep = targetGui:FindFirstChild("Separator", true)
			if sep and sep:IsA("Frame") then
				tweenService:Create(sep, tweenInfo, {
					BackgroundColor3 = cfg.separatorBg,
					BackgroundTransparency = cfg.separatorTrans,
				}):Play()
			end
		end
	end

	if newAccentName and cascade.Accents[newAccentName] and newAccentName ~= currentAccent then
		currentAccent = newAccentName
		app.Accent = cascade.Accents[newAccentName]
	end

	task.defer(function()
		for desc, oldProps in pairs(snapshot) do
			if desc and desc.Parent then
				local props = {}
				if oldProps.BackgroundColor3 and desc.BackgroundColor3 ~= oldProps.BackgroundColor3 then
					local target = desc.BackgroundColor3
					desc.BackgroundColor3 = oldProps.BackgroundColor3
					props.BackgroundColor3 = target
				end
				if oldProps.BackgroundTransparency and math.abs(desc.BackgroundTransparency - oldProps.BackgroundTransparency) > 0.02 then
					local target = desc.BackgroundTransparency
					desc.BackgroundTransparency = oldProps.BackgroundTransparency
					props.BackgroundTransparency = target
				end
				if oldProps.TextColor3 and desc:IsA("TextLabel") and desc.TextColor3 ~= oldProps.TextColor3 then
					local target = desc.TextColor3
					desc.TextColor3 = oldProps.TextColor3
					props.TextColor3 = target
				end
				if oldProps.ImageColor3 and desc:IsA("ImageLabel") and desc.ImageColor3 ~= oldProps.ImageColor3 then
					local target = desc.ImageColor3
					desc.ImageColor3 = oldProps.ImageColor3
					props.ImageColor3 = target
				end
				if next(props) then
					tweenService:Create(desc, tweenInfo, props):Play()
				end
			end
		end
	end)
end

_G.CascadeSmoothTransition = smoothTransition

task.defer(function()
	local targets = {}
	if typeof(gethui) == "function" then
		pcall(function()
			table.insert(targets, gethui())
		end)
	end
	pcall(function()
		table.insert(targets, coreGui)
	end)
	if localPlayer and localPlayer:FindFirstChild("PlayerGui") then
		table.insert(targets, localPlayer.PlayerGui)
	end
	for _, t in ipairs(targets) do
		local c = t:FindFirstChild("Cascade")
		if c then
			applyModernVisuals(c)
			break
		end
	end
end)

do
	local overviewTab = window:Tab({
		Title = "Telemetry",
		Icon = cascade.Symbols.sliderHorizontal3,
		Selected = true,
	})

	local perfSection = overviewTab:PageSection({
		Title = "Performance & Display",
		Subtitle = "Real-time client rendering controls",
	})

	local perfForm = perfSection:Form()

	do
		local row = titledRow(perfForm, "Field Of View", "Dynamically adjust camera projection angle")
		local currentFov = workspaceService.CurrentCamera and workspaceService.CurrentCamera.FieldOfView or 70
		local fovLabel = row:Right():Label({
			Text = tostring(math.floor(currentFov)) .. "°",
		})
		row:Right():Slider({
			Minimum = 60,
			Maximum = 120,
			Value = currentFov,
			ValueChanged = function(self, value)
				local val = math.floor(value)
				fovLabel.Text = tostring(val) .. "°"
				if workspaceService.CurrentCamera then
					workspaceService.CurrentCamera.FieldOfView = val
				end
			end,
		})
	end

	do
		local row = titledRow(perfForm, "Low Latency Rendering", "Bypass redundant post-process sampling")
		row:Right():Toggle({
			Value = true,
			ValueChanged = function(self, value)
				app:Notification({
					App = "Cascade",
					Title = "Pipeline Update",
					Subtitle = "Low Latency Rendering set to " .. tostring(value),
					Duration = 2.5,
				})
			end,
		})
	end

	do
		local row = titledRow(perfForm, "Pointer Control", "Configure gesture acceleration and modal controls")
		row:Right():Button({
			Label = "Pointer Options...",
			State = "Secondary",
			Pushed = function()
				openMiddlePanel()
			end,
		})
	end

	local diagSection = overviewTab:PageSection({
		Title = "Diagnostics & Maintenance",
		Subtitle = "Engine telemetry utilities",
	})

	local diagForm = diagSection:Form()

	do
		local row = titledRow(diagForm, "Telemetry Ping", "Send status handshake to local monitor")
		row:Right():Button({
			Label = "Dispatch",
			State = "Primary",
			Pushed = function()
				local fps = math.floor(1 / (workspaceService:GetRealPhysicsFPS() > 0 and workspaceService:GetRealPhysicsFPS() or 60))
				app:Notification({
					App = "Cascade",
					Title = "Telemetry Echo",
					Subtitle = "Connection solid. Engine heartbeat responsive.",
					Duration = 3,
				})
			end,
		})
	end

	do
		local row = titledRow(diagForm, "Garbage Collector", "Trigger incremental GC cycle to free memory")
		row:Right():Button({
			Label = "Collect GC",
			State = "Destructive",
			Pushed = function()
				local before = gcinfo()
				collectgarbage("collect")
				local after = gcinfo()
				app:Notification({
					App = "Cascade",
					Title = "GC Complete",
					Subtitle = ("Freed ~%d KB of client memory"):format(math.max(0, before - after)),
					Duration = 3.5,
				})
			end,
		})
	end
end

do
	local lightingTab = window:Tab({
		Title = "Atmosphere",
		Icon = cascade.Symbols.sunMax,
	})

	local envSection = lightingTab:PageSection({
		Title = "Lighting Engine",
		Subtitle = "Manipulate world lighting properties in real time",
	})

	local envForm = envSection:Form()

	do
		local row = titledRow(envForm, "Clock Time", "Adjust world time of day")
		local timeLabel = row:Right():Label({
			Text = ("%.1f h"):format(lighting.ClockTime),
		})
		row:Right():Slider({
			Minimum = 0,
			Maximum = 24,
			Value = lighting.ClockTime,
			ValueChanged = function(self, value)
				timeLabel.Text = ("%.1f h"):format(value)
				lighting.ClockTime = value
			end,
		})
	end

	do
		local row = titledRow(envForm, "Global Shadows", "Toggle sunlight occlusion shadows")
		row:Right():Toggle({
			Value = lighting.GlobalShadows,
			ValueChanged = function(self, value)
				lighting.GlobalShadows = value
			end,
		})
	end

	do
		local row = titledRow(envForm, "Atmosphere Preset", "Quick switch ambient grading")
		row:Right():PopUpButton({
			Options = { "Default", "Neon Dusk", "Midnight Void", "Golden Hour" },
			Value = 1,
			ValueChanged = function(self, index)
				local name = self.Options[index]
				if name == "Default" then
					lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
					lighting.Brightness = 2
				elseif name == "Neon Dusk" then
					lighting.OutdoorAmbient = Color3.fromRGB(130, 80, 180)
					lighting.Brightness = 1.5
				elseif name == "Midnight Void" then
					lighting.OutdoorAmbient = Color3.fromRGB(20, 25, 45)
					lighting.Brightness = 0.5
				elseif name == "Golden Hour" then
					lighting.OutdoorAmbient = Color3.fromRGB(255, 170, 90)
					lighting.Brightness = 2.4
				end
				app:Notification({
					App = "Cascade",
					Title = "Lighting Preset",
					Subtitle = "Applied preset: " .. name,
					Duration = 2,
				})
			end,
		})
	end
end

do
	local moveTab = window:Tab({
		Title = "Locomotion",
		Icon = cascade.Symbols.hare,
	})

	local moveSection = moveTab:PageSection({
		Title = "Movement Vectors",
		Subtitle = "Tweak character physics properties",
	})

	local moveForm = moveSection:Form()

	local function getHumanoid()
		local char = localPlayer.Character
		return char and char:FindFirstChildOfClass("Humanoid")
	end

	do
		local row = titledRow(moveForm, "Walk Speed", "Modify character horizontal speed")
		local hum = getHumanoid()
		local curSpeed = hum and hum.WalkSpeed or 16
		local speedLabel = row:Right():Label({
			Text = tostring(math.floor(curSpeed)),
		})
		row:Right():Slider({
			Minimum = 16,
			Maximum = 120,
			Value = curSpeed,
			ValueChanged = function(self, value)
				local val = math.floor(value)
				speedLabel.Text = tostring(val)
				local targetHum = getHumanoid()
				if targetHum then
					targetHum.WalkSpeed = val
				end
			end,
		})
	end

	do
		local row = titledRow(moveForm, "Jump Power", "Modify character vertical velocity impulse")
		local hum = getHumanoid()
		local curJump = hum and hum.JumpPower or 50
		local jumpLabel = row:Right():Label({
			Text = tostring(math.floor(curJump)),
		})
		row:Right():Slider({
			Minimum = 50,
			Maximum = 200,
			Value = curJump,
			ValueChanged = function(self, value)
				local val = math.floor(value)
				jumpLabel.Text = tostring(val)
				local targetHum = getHumanoid()
				if targetHum then
					targetHum.UseJumpPower = true
					targetHum.JumpPower = val
				end
			end,
		})
	end

	do
		local row = titledRow(moveForm, "Reset Locomotion", "Restore original character physics")
		row:Right():Button({
			Label = "Reset to Default",
			State = "Secondary",
			Pushed = function()
				local targetHum = getHumanoid()
				if targetHum then
					targetHum.WalkSpeed = 16
					targetHum.JumpPower = 50
					app:Notification({
						App = "Cascade",
						Title = "Locomotion Reset",
						Subtitle = "WalkSpeed restored to 16, JumpPower to 50",
						Duration = 2,
					})
				end
			end,
		})
	end
end

do
	local appearanceTab = window:Tab({
		Title = "Appearance",
		Icon = getAsset("appearance.png", "https://raw.githubusercontent.com/x8lua/Staconf/main/assets/appearance.png"),
	})

	local modeSection = appearanceTab:PageSection({
		Title = "Appearance",
		Subtitle = "Configure desktop visual presentation",
	})

	local modeForm = modeSection:Form()

	do
		local row = titledRow(modeForm, "Interface Mode", "Select system lighting scheme")
		row:Right():PopUpButton({
			Options = { "Dark", "Light" },
			Value = (currentMode == "Dark" and 1 or 2),
			ValueChanged = function(self, index)
				local mode = self.Options[index]
				smoothTransition(mode, nil)
			end,
		})
	end

	local themeSection = appearanceTab:PageSection({
		Title = "Theme",
		Subtitle = "Accent palette and highlight preferences",
	})

	local themeForm = themeSection:Form()

	local accentList = { "Blue", "Purple", "Pink", "Red", "Orange", "Yellow", "Green", "Graphite" }

	do
		local row = titledRow(themeForm, "Colour", "Tint color applied to active controls and tabs")
		row:Right():PopUpButton({
			Options = accentList,
			Value = 1,
			ValueChanged = function(self, index)
				local selectedName = self.Options[index]
				smoothTransition(nil, selectedName)
			end,
		})
	end

	do
		local row = titledRow(themeForm, "Text Highlight Colour", "Accent tint for selected text elements")
		row:Right():PopUpButton({
			Options = { "Automatic", "Blue", "Purple", "Pink", "Red", "Orange", "Yellow", "Green", "Graphite" },
			Value = 1,
		})
	end

	do
		local row = titledRow(themeForm, "Icon and Widget Style", "Visual presentation of interface elements")
		row:Right():PopUpButton({
			Options = { "Default", "Dark", "Clear", "Tinted" },
			Value = 1,
		})
	end

	do
		local row = titledRow(themeForm, "Folder Colour", "Directory and group container tint")
		row:Right():PopUpButton({
			Options = { "Automatic", "Blue", "Purple", "Pink", "Graphite" },
			Value = 1,
		})
	end

	local fxSection = appearanceTab:PageSection({
		Title = "Window Effects",
		Subtitle = "Frosted glass acrylic blur and ambient occlusion",
	})

	local fxForm = fxSection:Form()

	do
		local row = titledRow(fxForm, "Acrylic Blur", "Sample real-time world glass refraction through sidebar")
		row:Right():Toggle({
			Value = true,
			ValueChanged = function(self, value)
				if acrylicBlur then
					acrylicBlur.Enabled = value
				end
			end,
		})
	end

	do
		local row = titledRow(fxForm, "Window Dropshadow", "Toggle depth shadow around window frame")
		row:Right():Toggle({
			Value = window.Dropshadow,
			ValueChanged = function(self, value)
				window.Dropshadow = value
			end,
		})
	end

	do
		local row = titledRow(fxForm, "Minimize Hotkey", "Keycode to toggle window visibility")
		row:Right():KeybindField({
			Value = minimizeKey,
			ValueChanged = function(self, value)
				minimizeKey = value
				app:Notification({
					App = "Cascade",
					Title = "Hotkey Updated",
					Subtitle = "Minimize hotkey bound to " .. tostring(value.Name),
					Duration = 2.5,
				})
			end,
		})
	end

	do
		local row = titledRow(fxForm, "Pointer Options", "Configure trackpad acceleration and modal panel")
		row:Right():Button({
			Label = "Pointer Options...",
			State = "Secondary",
			Pushed = function()
				openMiddlePanel()
			end,
		})
	end
end

app:Notification({
	App = "Cascade",
	Title = "System Online",
	Subtitle = "Cascade Deck initialized successfully. Press RightControl to toggle.",
	Duration = 4,
})
