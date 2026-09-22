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
			if child.Name == "StacOnf" or child.Name == "Cascade" then
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

app.__instance.Name = "StacOnf"

local window = app:Window({
	Title = "StacOnf",
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

local acrylicBlur = lighting:FindFirstChild("StacOnfAcrylicBlur")
if not acrylicBlur then
	acrylicBlur = Instance.new("BlurEffect")
	acrylicBlur.Name = "StacOnfAcrylicBlur"
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
local currentStacOnfGui = nil

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
local refreshMiddlePanel
local modalConnections = {}

local function modalConnect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(modalConnections, connection)
	return connection
end

local function openMiddlePanel()
	if refreshMiddlePanel then refreshMiddlePanel() end
	if not modalDimmer or not middlePanel then return end
	isModalOpen = true
	modalDimmer.Visible = true
	middlePanel.Visible = true
	modalDimmer.BackgroundTransparency = 1
	middlePanel.Position = UDim2.new(0.5, 0, 0.5, 24)
	local panelScale = middlePanel:FindFirstChildOfClass("UIScale")
	if panelScale then
		panelScale.Scale = 0.88
	end
	tweenService:Create(modalDimmer, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.45,
	}):Play()
	tweenService:Create(middlePanel, TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}):Play()
	if panelScale then
		tweenService:Create(panelScale, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1,
		}):Play()
	end
	local title = middlePanel:FindFirstChild("Title")
	local form = middlePanel:FindFirstChild("FormCard")
	local footer = middlePanel:FindFirstChild("Footer")
	if title then
		title.Position = UDim2.fromOffset(-12, 0)
		title.TextTransparency = 1
		tweenService:Create(title, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(0, 0), TextTransparency = 0 }):Play()
	end
	if form then
		form.Position = UDim2.new(0, 0, 0, 48)
		task.delay(0.05, function()
			if isModalOpen and form.Parent then tweenService:Create(form, TweenInfo.new(0.34, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 32) }):Play() end
		end)
	end
	if footer then
		footer.Position = UDim2.new(0, 0, 1, -20)
		task.delay(0.1, function()
			if isModalOpen and footer.Parent then tweenService:Create(footer, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 1, -36) }):Play() end
		end)
	end
end

local function closeMiddlePanel()
	if not modalDimmer or not middlePanel then return end
	isModalOpen = false
	tweenService:Create(modalDimmer, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	}):Play()
	tweenService:Create(middlePanel, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 0.5, 18),
	}):Play()
	local panelScale = middlePanel:FindFirstChildOfClass("UIScale")
	if panelScale then
		local t = tweenService:Create(panelScale, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
			Scale = 0.9,
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

_G.StacOnfOpenMiddlePanel = openMiddlePanel
_G.StacOnfCloseMiddlePanel = closeMiddlePanel

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
	panelStroke.Transparency = 0.75
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
	titleLabel.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold)
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
		lbl.TextSize = 15
		lbl.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular)
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
		local knobScale = Instance.new("UIScale")
		knobScale.Parent = knob
		local toggleScale = Instance.new("UIScale")
		toggleScale.Parent = togBtn

		togBtn:SetAttribute("Enabled", defaultVal)
		local val = defaultVal
		togBtn.MouseButton1Click:Connect(function()
			val = not val
			togBtn:SetAttribute("Enabled", val)
			local targetCol = val and Color3.fromRGB(0, 122, 255) or (currentMode == "Light" and Color3.fromRGB(220, 222, 228) or Color3.fromRGB(60, 62, 70))
			local targetPos = val and UDim2.new(0, 16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
			tweenService:Create(togBtn, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundColor3 = targetCol }):Play()
			tweenService:Create(knob, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = targetPos }):Play()
			knobScale.Scale = 0.78
			toggleScale.Scale = 0.92
			tweenService:Create(knobScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			tweenService:Create(toggleScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
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
	sLbl.TextSize = 15
	sLbl.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular)
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
	local sThumbScale = Instance.new("UIScale")
	sThumbScale.Parent = sThumb
	sThumb.Parent = sFill

	local turtleLbl = Instance.new("TextLabel")
	turtleLbl.Text = "−"
	turtleLbl.FontFace = Font.new("rbxassetid://12187365364")
	turtleLbl.TextSize = 13
	turtleLbl.BackgroundTransparency = 1
	turtleLbl.AnchorPoint = Vector2.new(1, 0.5)
	turtleLbl.Position = UDim2.new(1, -160, 0.5, 0)
	turtleLbl.Size = UDim2.fromOffset(20, 20)
	turtleLbl.Parent = sliderRow

	local hareLbl = Instance.new("TextLabel")
	hareLbl.Text = "+"
	hareLbl.FontFace = Font.new("rbxassetid://12187365364")
	hareLbl.TextSize = 13
	hareLbl.BackgroundTransparency = 1
	hareLbl.AnchorPoint = Vector2.new(1, 0.5)
	hareLbl.Position = UDim2.new(1, 0, 0.5, 0)
	hareLbl.Size = UDim2.fromOffset(20, 20)
	hareLbl.Parent = sliderRow

	sTrack.Parent = sliderRow
	local sliderHitbox = Instance.new("TextButton")
	sliderHitbox.Name = "SliderHitbox"
	sliderHitbox.Text = ""
	sliderHitbox.AutoButtonColor = false
	sliderHitbox.BackgroundTransparency = 1
	sliderHitbox.AnchorPoint = Vector2.new(1, 0.5)
	sliderHitbox.Position = UDim2.new(1, -14, 0.5, 0)
	sliderHitbox.Size = UDim2.fromOffset(170, 36)
	sliderHitbox.ZIndex = sTrack.ZIndex + 2
	sliderHitbox.Parent = sliderRow
	local sliderDragging = false
	local function updateSlider(inputX)
		local ratio = math.clamp((inputX - sTrack.AbsolutePosition.X) / math.max(sTrack.AbsoluteSize.X, 1), 0, 1)
		sFill.Size = UDim2.fromScale(ratio, 1)
	end
	modalConnect(sliderHitbox.InputBegan, function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		sliderDragging = true
		updateSlider(input.Position.X)
		tweenService:Create(sThumbScale, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.32 }):Play()
	end)
	modalConnect(userInputService.InputChanged, function(input)
		if not sliderDragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			updateSlider(input.Position.X)
		end
	end)
	modalConnect(userInputService.InputEnded, function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if not sliderDragging then return end
		sliderDragging = false
		tweenService:Create(sThumbScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end)
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
	dLbl.TextSize = 15
	dLbl.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular)
	dLbl.TextColor3 = (currentMode == "Light" and Color3.fromRGB(35, 35, 35) or Color3.fromRGB(235, 235, 235))
	dLbl.TextXAlignment = Enum.TextXAlignment.Left
	dLbl.AnchorPoint = Vector2.new(0, 0.5)
	dLbl.Position = UDim2.new(0, 0, 0.5, 0)
	dLbl.Size = UDim2.new(0, 140, 1, 0)
	dLbl.BackgroundTransparency = 1
	dLbl.Parent = dragStyleRow

	local styleVal = Instance.new("TextLabel")
	styleVal.Text = "Without Drag Lock"
	styleVal.TextSize = 13
	styleVal.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular)
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
	cancelBtn.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular)
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
	okBtn.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold)
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
	local function animateButton(button)
		local scale = Instance.new("UIScale")
		scale.Parent = button
		modalConnect(button.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				tweenService:Create(scale, TweenInfo.new(0.09, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Scale = 0.9 }):Play()
			end
		end)
		modalConnect(button.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				tweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			end
		end)
	end
	animateButton(cancelBtn)
	animateButton(okBtn)

	footerBar.Parent = middlePanel
	middlePanel.Parent = layoutIgnore
	refreshMiddlePanel = function()
		if not middlePanel or not middlePanel.Parent then return end
		local light = currentMode == "Light"
		local primary = light and Color3.fromRGB(37, 40, 48) or Color3.fromRGB(244, 245, 249)
		local secondary = light and Color3.fromRGB(108, 113, 125) or Color3.fromRGB(169, 174, 189)
		local neutral = light and Color3.fromRGB(226, 230, 236) or Color3.fromRGB(43, 46, 57)
		local accents = {Blue=Color3.fromRGB(0,122,255),Purple=Color3.fromRGB(175,82,222),Pink=Color3.fromRGB(255,45,85),Red=Color3.fromRGB(255,59,48),Orange=Color3.fromRGB(255,149,0),Yellow=Color3.fromRGB(255,204,0),Green=Color3.fromRGB(52,199,89),Graphite=Color3.fromRGB(142,142,147)}
		local accent = accents[currentAccent] or accents.Blue
		local info = TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		local function apply(object, properties)
			if middlePanel.Visible then tweenService:Create(object, info, properties):Play() else for property, value in pairs(properties) do object[property] = value end end
		end
		apply(middlePanel, { BackgroundColor3 = light and Color3.fromRGB(255,255,255) or Color3.fromRGB(20,22,29) })
		apply(formCard, { BackgroundColor3 = light and Color3.fromRGB(245,245,247) or Color3.fromRGB(29,31,39) })
		apply(panelStroke, { Color = neutral })
		apply(cancelBtn, { BackgroundColor3 = neutral })
		apply(okBtn, { BackgroundColor3 = accent })
		apply(sTrack, { BackgroundColor3 = neutral })
		apply(sFill, { BackgroundColor3 = accent })
		for _, object in ipairs(middlePanel:GetDescendants()) do
			if object:IsA("TextLabel") or object:IsA("TextButton") then
				apply(object, { TextColor3 = object == okBtn and Color3.new(1,1,1) or primary })
			end
			if object.Name == "Sep" or object.Name == "Sep2" then
				apply(object, { BackgroundColor3 = neutral })
			elseif object.Name == "Toggle" and object:IsA("TextButton") then
				apply(object, { BackgroundColor3 = object:GetAttribute("Enabled") and accent or neutral })
			end
		end
		apply(styleVal, { TextColor3 = secondary })
		apply(turtleLbl, { TextColor3 = secondary })
		apply(hareLbl, { TextColor3 = secondary })
	end
	refreshMiddlePanel()
	modalConnect(middlePanel.Destroying, function()
		for _, connection in ipairs(modalConnections) do connection:Disconnect() end
		table.clear(modalConnections)
		refreshMiddlePanel = nil
	end)
end

local refreshSidebarChrome
local refreshAccountPage
local accountTab
local chromeConnections = {}
local function chromeConnect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(chromeConnections, connection)
	return connection
end

local function crispPopUpButton(parent, options)
	local control = parent:PopUpButton(options)
	local function raw(value)
		return typeof(value) == "Instance" and value or value.__instance
	end
	local structures = control.Structures
	local group = raw(structures.MenuBody)
	local container = raw(structures.MenuContainer)
	local menu = raw(structures.Menu)
	local layer = Instance.new("Frame")
	layer.Name = "DirectMenuLayer"
	layer.BackgroundTransparency = 1
	layer.BorderSizePixel = 0
	layer.Size = UDim2.fromScale(1, 1)
	layer.Visible = group.GroupTransparency < 1
	layer.Parent = container
	menu.Parent = layer
	local button = raw(structures.Body)
	local positioning = false
	local connections = {}
	local function anchorMenu()
		if positioning or not container.Parent then return end
		positioning = true
		local origin = layer.AbsolutePosition
		local bounds = layer.AbsoluteSize
		local buttonPosition = button.AbsolutePosition - origin
		local buttonSize = button.AbsoluteSize
		local menuSize = menu.AbsoluteSize
		local x = buttonPosition.X + buttonSize.X - menuSize.X
		local y = buttonPosition.Y + buttonSize.Y + 6
		if y + menuSize.Y > bounds.Y - 8 then
			y = buttonPosition.Y - menuSize.Y - 6
		end
		menu.Position = UDim2.fromOffset(
			math.round(math.clamp(x, 8, math.max(8, bounds.X - menuSize.X - 8))),
			math.round(math.clamp(y, 8, math.max(8, bounds.Y - menuSize.Y - 8)))
		)
		positioning = false
	end
	for _, entry in ipairs({
		{menu, "Position"}, {menu, "AbsoluteSize"},
		{button, "AbsolutePosition"}, {button, "AbsoluteSize"},
		{layer, "AbsoluteSize"}, {container, "Parent"},
	}) do
		table.insert(connections, entry[1]:GetPropertyChangedSignal(entry[2]):Connect(anchorMenu))
	end
	local visibility = group:GetPropertyChangedSignal("GroupTransparency"):Connect(function()
		layer.Visible = control.Expanded and group.GroupTransparency < 1
		if layer.Visible then anchorMenu() end
	end)
	anchorMenu()
	local destroyed
	destroyed = window.Destroying:Connect(function()
		visibility:Disconnect()
		for _, connection in ipairs(connections) do connection:Disconnect() end
		destroyed:Disconnect()
		container:Destroy()
	end)
	return control
end

local function installSidebarChrome(targetGui)
	local function raw(value) return typeof(value) == "Instance" and value or value.__instance end
	local structures = window.Structures
	local body = raw(structures.Body)
	local sidebar = raw(structures.SidebarMargins)
	local margins = raw(structures.Sidebar)
	local list = raw(structures.SidebarList)
	local content = raw(structures.ContentBody)
	if body:FindFirstChild("ChromeSurface", true) then return end
	local surface = Instance.new("CanvasGroup")
	surface.Name = "ChromeSurface"
	surface.Size = UDim2.fromScale(1, 1)
	surface.BackgroundTransparency = 1
	surface.BorderSizePixel = 0
	surface.Parent = raw(structures.LayoutIgnore)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 22)
	corner.Parent = surface
	local layout = body:FindFirstChildOfClass("UIListLayout")
	if layout then layout.Parent = surface end
	sidebar.Parent = surface
	content.Parent = surface
	local separator = raw(structures.Separator)
	separator.Parent = surface
	separator.Visible = false
	separator.Size = UDim2.new(0, 0, 1, 0)
	local shadow = margins:FindFirstChild("Shadow", true)
	if shadow then shadow.Visible = false end
	local sidebarPadding = margins:FindFirstChildOfClass("UIPadding")
	if sidebarPadding then sidebarPadding.PaddingRight = UDim.new(0, 0) end
	local listLayout = list:FindFirstChildOfClass("UIListLayout")
	if listLayout then listLayout.Padding = UDim.new(0, 2) end
	local listTop = userInputService.TouchEnabled and 172 or 162
	list.Position = UDim2.fromOffset(0, listTop)
	list.Size = UDim2.new(1, 0, 1, -listTop - 8)
	local search = structures.Titlebar.SearchField
	local searchBody, searchField = raw(search.Body), raw(search.Field)
	searchBody.Parent = margins
	searchBody.Name = "SidebarSearch"
	searchBody.AutomaticSize = Enum.AutomaticSize.None
	searchBody.Position = UDim2.fromOffset(12, 52)
	searchBody.Size = UDim2.new(1, -24, 0, userInputService.TouchEnabled and 44 or 32)
	searchField.AutomaticSize = Enum.AutomaticSize.None
	searchField.Size = UDim2.new(1, -36, 1, 0)
	searchField.TextSize = 14
	searchField.TextTruncate = Enum.TextTruncate.AtEnd
	local searchStroke = searchBody:FindFirstChildOfClass("UIStroke")
	if searchStroke then searchStroke.Enabled = false end
	local searchCorner = searchBody:FindFirstChildOfClass("UICorner")
	if searchCorner then searchCorner.CornerRadius = UDim.new(0, 8) end
	local signIn = Instance.new("TextButton")
	signIn.Name = "SignInPanel"
	signIn.Text = ""
	signIn.AutoButtonColor = false
	signIn.BackgroundTransparency = 1
	signIn.BorderSizePixel = 0
	signIn.Position = UDim2.fromOffset(12, userInputService.TouchEnabled and 104 or 94)
	signIn.Size = UDim2.new(1, -24, 0, 56)
	signIn.Parent = margins
	local avatar = Instance.new("Frame")
	avatar.Name = "Avatar"
	avatar.Size = UDim2.fromOffset(34, 34)
	avatar.Position = UDim2.fromOffset(6, 11)
	avatar.BorderSizePixel = 0
	avatar.Parent = signIn
	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(1, 0)
	avatarCorner.Parent = avatar
	for _,spec in ipairs({{12,6,10,10},{7,18,20,12}}) do
		local part = Instance.new("Frame")
		part.Size = UDim2.fromOffset(spec[3], spec[4])
		part.Position = UDim2.fromOffset(spec[1], spec[2])
		part.BorderSizePixel = 0
		part.BackgroundColor3 = Color3.new(1, 1, 1)
		part.Parent = avatar
		local rounding = Instance.new("UICorner")
		rounding.CornerRadius = UDim.new(1, 0)
		rounding.Parent = part
	end
	local function text(name, value, y, size, weight)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Text = value
		label.Size = UDim2.new(1, -53, 0, 20)
		label.Position = UDim2.fromOffset(50, y)
		label.BackgroundTransparency = 1
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.FontFace = Font.new("rbxassetid://12187365364", weight)
		label.TextSize = size
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.Parent = signIn
		return label
	end
	local title = text("Title", "Free User", 7, 15, Enum.FontWeight.SemiBold)
	local subtitle = text("Subtitle", "View account", 27, 11, Enum.FontWeight.Regular)
	chromeConnect(signIn.Activated, function()
		if not accountTab then return end
		accountTab.Selected = true
		if window.addToHistory then window.addToHistory(accountTab.__container) end
		local page = accountTab.Structures.Page
		page = typeof(page) == "Instance" and page or page.__instance
		local header = page:FindFirstChild("AccountHeader", true)
		local information = page:FindFirstChild("AccountInformation", true)
		if header then
			header.Position = UDim2.fromOffset(0, 12)
			tweenService:Create(header, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(0, 0) }):Play()
		end
		if information then
			information.Position = UDim2.fromOffset(16, 182)
			task.delay(0.04, function()
				if information.Parent then tweenService:Create(information, TweenInfo.new(0.34, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(16, 164) }):Play() end
			end)
		end
		task.delay(0.12, function()
			if accountTab.Selected and refreshAccountPage then refreshAccountPage() end
		end)
	end)
	local updating = false
	local function alignContent()
		if updating or not body.Parent then return end
		updating = true
		content.Size = UDim2.new(1, -sidebar.Size.X.Offset, 1, 0)
		separator.Visible = false
		separator.Size = UDim2.new(0, 0, 1, 0)
		updating = false
	end
	chromeConnect(sidebar:GetPropertyChangedSignal("Size"), alignContent)
	chromeConnect(content:GetPropertyChangedSignal("Size"), alignContent)
	chromeConnect(separator:GetPropertyChangedSignal("Visible"), alignContent)
	local function hideClip(obj)
		obj.Visible = false
		chromeConnect(obj:GetPropertyChangedSignal("Visible"), function() if obj.Visible then obj.Visible = false end end)
	end
	for _,name in ipairs({"CornerClip", "CornerClipLeft", "CornerClipRight"}) do
		local object = content:FindFirstChild(name, true)
		if object then hideClip(object) end
	end
	chromeConnect(raw(structures.Cornering):GetPropertyChangedSignal("CornerRadius"), function()
		corner.CornerRadius = window.Maximized and UDim.new(0, 0) or UDim.new(0, 22)
	end)
	local refreshing = false
	refreshSidebarChrome = function()
		if refreshing or not body.Parent then return end
		refreshing = true
		local light = currentMode == "Light"
		body.BackgroundTransparency = 1
		sidebar.BackgroundTransparency = 0
		sidebar.BackgroundColor3 = light and Color3.fromRGB(239, 240, 244) or Color3.fromRGB(29, 31, 39)
		content.BackgroundTransparency = 0
		content.BackgroundColor3 = light and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(20, 22, 29)
		searchBody.BackgroundColor3 = light and Color3.fromRGB(226, 230, 236) or Color3.fromRGB(43, 46, 57)
		searchBody.BackgroundTransparency = 0
		avatar.BackgroundColor3 = light and Color3.fromRGB(173, 179, 188) or Color3.fromRGB(106, 114, 130)
		title.TextColor3 = light and Color3.fromRGB(37, 40, 48) or Color3.fromRGB(244, 245, 249)
		subtitle.TextColor3 = light and Color3.fromRGB(108, 113, 125) or Color3.fromRGB(169, 174, 189)
		alignContent()
		refreshing = false
	end
	for _, object in ipairs({body, sidebar, content, searchBody}) do
		chromeConnect(object:GetPropertyChangedSignal("BackgroundTransparency"), function()
			if refreshSidebarChrome then refreshSidebarChrome() end
		end)
		chromeConnect(object:GetPropertyChangedSignal("BackgroundColor3"), function()
			if refreshSidebarChrome then refreshSidebarChrome() end
		end)
	end
	refreshSidebarChrome()
	chromeConnect(body.Destroying, function()
		for _,connection in ipairs(chromeConnections) do connection:Disconnect() end
		table.clear(chromeConnections)
		refreshSidebarChrome = nil
	end)
end

local function applyModernVisuals(targetGui)
	currentStacOnfGui = targetGui
	local function updateVisual(obj)
		if not obj.Parent then return end
		if obj:IsA("UICorner") then
			local owner = obj.Parent
			if owner.Name == "Body" then obj.CornerRadius = UDim.new(0, 22)
			elseif owner.Name == "ContentBody" or owner.Name == "Toolbar" or owner.Name == "Sidebar" then
				obj.CornerRadius = UDim.new(0, 0)
			elseif owner.Name == "SidebarItem" then obj.CornerRadius = UDim.new(0, 7) end
		elseif obj.Name == "Disclosure" or obj.Name == "SectionHeader" then
			obj.Visible = false
		elseif obj.Name == "RightEdgeFiller" or obj.Name == "CornerClip" or obj.Name == "CornerClipLeft" or obj.Name == "CornerClipRight" then
			if obj:IsA("GuiObject") then obj.Visible = false; obj.BackgroundTransparency = 1 end
		elseif obj.Name == "Body" and obj:IsA("Frame") then
			obj.BackgroundTransparency = 1
			createMiddlePanel(targetGui)
		elseif obj.Name == "Sidebar" and obj:IsA("Frame") then
			obj.BackgroundTransparency = 1
		elseif obj.Name == "Toolbar" and obj:IsA("Frame") then
			obj.BackgroundTransparency = 1
			local shadow = obj:FindFirstChild("Shadow")
			if shadow then shadow.Visible = false end
		elseif obj.Name == "Separator" and obj.Parent.Name == "Body" then
			obj.Visible = false
			obj.Size = UDim2.new(0, 0, 1, 0)
		elseif obj.Name == "ContentBody" and obj:IsA("Frame") then
			obj.BackgroundTransparency = 1
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

					if not knob:GetAttribute("StacOnfMotion") then
						knob:SetAttribute("StacOnfMotion", true)
						local visual = knob:Clone()
						visual.Name = "AnimatedKnob"
						visual.Visible = true
						visual.Parent = sw
						knob.Visible = false
						local function updatePos()
							local progress = math.clamp((knob.Position.X.Offset - 1) / 12, 0, 1)
							visual.Position = UDim2.new(0, 2 + 14 * progress, 0.5, 0)
						end
						chromeConnect(knob:GetPropertyChangedSignal("Position"), updatePos)
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
					thumb.BackgroundTransparency = thumb:GetAttribute("StacOnfMotion") and 1 or 0
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
					if not thumb:GetAttribute("StacOnfMotion") then
						thumb:SetAttribute("StacOnfMotion", true)
						local visual = Instance.new("Frame")
						visual.Name = "AnimatedThumb"
						visual.Size = UDim2.fromScale(1, 1)
						visual.AnchorPoint = Vector2.new(0.5, 0.5)
						visual.Position = UDim2.fromScale(0.5, 0.5)
						visual.BackgroundColor3 = Color3.new(1, 1, 1)
						visual.BorderSizePixel = 0
						visual.ZIndex = thumb.ZIndex
						thumbCorner:Clone().Parent = visual
						stroke:Clone().Parent = visual
						visual.Parent = thumb
						thumb.BackgroundTransparency = 1
						stroke.Enabled = false
						local scale = Instance.new("UIScale")
						scale.Name = "InteractionScale"
						scale.Parent = visual
						local activeTween
						local dragging = false
						local hovering = false
						local function animate()
							if activeTween then activeTween:Cancel(); activeTween:Destroy() end
							activeTween = tweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
								Scale = dragging and 1.24 or (hovering and 1.1 or 1),
							})
							activeTween:Play()
						end
						chromeConnect(thumb.MouseEnter, function() hovering = true; animate() end)
						chromeConnect(thumb.MouseLeave, function() hovering = false; animate() end)
						local dragger = thumb:FindFirstChildOfClass("UIDragDetector")
						if dragger then
							chromeConnect(dragger.DragStart, function() dragging = true; animate() end)
							chromeConnect(dragger.DragEnd, function() dragging = false; animate() end)
						end
						chromeConnect(thumb.Destroying, function()
							if activeTween then activeTween:Cancel(); activeTween:Destroy(); activeTween = nil end
						end)
					end
				end
			end
		elseif obj.Name == "SidebarItem" and (obj:IsA("TextButton") or obj:IsA("Frame")) then
			obj.Size = UDim2.new(1, 0, 0, userInputService.TouchEnabled and 44 or 32)
			local leading = obj:FindFirstChild("Leading")
			local titleObj = leading and leading:FindFirstChild("Title")
			local badge = leading and leading:FindFirstChild("BadgeBackground")
			local sym = leading and (leading:FindFirstChild("Symbol") or (badge and badge:FindFirstChild("Symbol")))
			if titleObj then
				titleObj.FontFace = Font.new(titleObj.FontFace.Family, Enum.FontWeight.SemiBold)
				titleObj.TextSize = 15
				titleObj.Size = UDim2.new(1, -30, 0, 24)
				leading.Size = UDim2.new(1, 0, 0, 24)
				leading.AutomaticSize = Enum.AutomaticSize.None
				local layout = leading:FindFirstChildOfClass("UIListLayout")
				if layout then layout.Padding = UDim.new(0, 8); layout.VerticalAlignment = Enum.VerticalAlignment.Center end
				local trailing = obj:FindFirstChild("Trailing")
				if trailing then trailing.Visible = false end
			end
			if sym and titleObj then
				local colors = {Telemetry=Color3.fromRGB(0,122,255),Atmosphere=Color3.fromRGB(255,149,0),Locomotion=Color3.fromRGB(52,199,89),Appearance=Color3.fromRGB(44,44,46)}
				if not badge then
					badge = Instance.new("Frame")
					badge.Name = "BadgeBackground"
					badge.Size = UDim2.fromOffset(22, 22)
					badge.LayoutOrder = 1
					badge.BorderSizePixel = 0
					badge.Parent = leading
					local corner = Instance.new("UICorner")
					corner.CornerRadius = UDim.new(0, 6)
					corner.Parent = badge
					sym.Parent = badge
				end
				local fullIcon = titleObj.Text == "Appearance" or titleObj.Text == "Settings"
				badge.BackgroundColor3 = colors[titleObj.Text] or colors.Telemetry
				badge.BackgroundTransparency = fullIcon and 1 or 0
				sym.Size = fullIcon and UDim2.fromScale(1, 1) or UDim2.fromOffset(14, 14)
				sym.AnchorPoint = Vector2.new(0.5, 0.5)
				sym.Position = UDim2.fromScale(0.5, 0.5)
				sym.ImageColor3 = Color3.new(1, 1, 1)
				if not sym:GetAttribute("StaconfWhiteSymbol") then
					sym:SetAttribute("StaconfWhiteSymbol", true)
					chromeConnect(sym:GetPropertyChangedSignal("ImageColor3"), function()
						if sym.ImageColor3 ~= Color3.new(1, 1, 1) then sym.ImageColor3 = Color3.new(1, 1, 1) end
					end)
				end
			end
		end
	end

	for _, descendant in ipairs(targetGui:GetDescendants()) do
		updateVisual(descendant)
	end
	installSidebarChrome(targetGui)

	chromeConnect(targetGui.DescendantAdded, function(descendant)
		task.defer(updateVisual, descendant)
	end)
end

local function smoothTransition(newMode, newAccentName)
	local tweenInfo = TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local targetGui = currentStacOnfGui
	local snapshot = {}

	if targetGui then
		for _, desc in ipairs(targetGui:GetDescendants()) do
			if desc:IsA("GuiObject") and desc.Name ~= "RightEdgeFiller" and desc.Name ~= "Sidebar" and desc.Name ~= "Body" and desc.Name ~= "ContentBody" and desc.Name ~= "SidebarSearch" then
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
			if body and body:IsA("Frame") and not refreshSidebarChrome then
				tweenService:Create(body, tweenInfo, {
					BackgroundColor3 = cfg.bodyBg,
					BackgroundTransparency = cfg.bodyTrans,
				}):Play()
			end
			local content = targetGui:FindFirstChild("ContentBody", true)
			if content and content:IsA("Frame") and not refreshSidebarChrome then
				tweenService:Create(content, tweenInfo, {
					BackgroundColor3 = cfg.contentBg,
					BackgroundTransparency = cfg.contentTrans,
				}):Play()
			end
			local sep = targetGui:FindFirstChild("Separator", true)
			if sep and sep:IsA("Frame") and not refreshSidebarChrome then
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

	if refreshSidebarChrome then refreshSidebarChrome() end
	if refreshMiddlePanel then refreshMiddlePanel() end
	if refreshAccountPage then refreshAccountPage() end
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

_G.StacOnfSmoothTransition = smoothTransition

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
		local c = t:FindFirstChild("StacOnf")
		if c then
			applyModernVisuals(c)
			break
		end
	end
end)


local settingRegistry = {}
local settingOrder = {}
local function settingControl(id, parent, kind, options)
	local default = options.Value
	local control = kind == "PopUpButton" and crispPopUpButton(parent, options) or parent[kind](parent, options)
	settingRegistry[id] = { control = control, kind = kind, default = default, minimum = options.Minimum, maximum = options.Maximum, options = options.Options }
	table.insert(settingOrder, id)
	return control
end

local function captureSettings(defaults)
	local values = {}
	for _, id in ipairs(settingOrder) do
		local entry = settingRegistry[id]
		local value = entry.control.Value
		if defaults then value = entry.default end
		values[id] = entry.kind == "KeybindField" and value.Name or value
	end
	return values
end

local function validateSettings(values)
	assert(type(values) == "table", "Invalid settings data")
	local validated = {}
	for _, id in ipairs(settingOrder) do
		local entry = settingRegistry[id]
		local value = values[id]
		if value ~= nil then
			if entry.kind == "Toggle" then
				assert(type(value) == "boolean", "Invalid toggle: " .. id)
			elseif entry.kind == "KeybindField" then
				assert(type(value) == "string", "Invalid key: " .. id)
				local ok, key = pcall(function() return Enum.KeyCode[value] end)
				assert(ok and key and key ~= Enum.KeyCode.Unknown, "Unknown key: " .. id)
				value = key
			else
				assert(type(value) == "number" and value == value and math.abs(value) < math.huge, "Invalid number: " .. id)
				if entry.kind == "PopUpButton" then
					assert(value % 1 == 0 and value >= 1 and value <= #entry.options, "Invalid option: " .. id)
				else
					value = math.clamp(value, entry.minimum, entry.maximum)
				end
			end
			validated[id] = value
		end
	end
	return validated
end

local function applySettings(values)
	local validated = validateSettings(values)
	for _, id in ipairs(settingOrder) do
		if validated[id] ~= nil then settingRegistry[id].control.Value = validated[id] end
	end
end

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
		settingControl("fieldOfView", row:Right(), "Slider", {
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
		settingControl("lowLatency", row:Right(), "Toggle", {
			Value = true,
			ValueChanged = function(self, value)
				app:Notification({
					App = "StacOnf",
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
					App = "StacOnf",
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
					App = "StacOnf",
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
		settingControl("clockTime", row:Right(), "Slider", {
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
		settingControl("globalShadows", row:Right(), "Toggle", {
			Value = lighting.GlobalShadows,
			ValueChanged = function(self, value)
				lighting.GlobalShadows = value
			end,
		})
	end

	do
		local row = titledRow(envForm, "Atmosphere Preset", "Quick switch ambient grading")
		settingControl("atmosphere", row:Right(), "PopUpButton", {
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
					App = "StacOnf",
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
		settingControl("walkSpeed", row:Right(), "Slider", {
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
		settingControl("jumpPower", row:Right(), "Slider", {
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
					settingRegistry.walkSpeed.control.Value = 16
					settingRegistry.jumpPower.control.Value = 50
					app:Notification({
						App = "StacOnf",
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
		settingControl("mode", row:Right(), "PopUpButton", {
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
		settingControl("accent", row:Right(), "PopUpButton", {
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
		settingControl("textHighlight", row:Right(), "PopUpButton", {
			Options = { "Automatic", "Blue", "Purple", "Pink", "Red", "Orange", "Yellow", "Green", "Graphite" },
			Value = 1,
		})
	end

	do
		local row = titledRow(themeForm, "Icon and Widget Style", "Visual presentation of interface elements")
		settingControl("iconStyle", row:Right(), "PopUpButton", {
			Options = { "Default", "Dark", "Clear", "Tinted" },
			Value = 1,
		})
	end

	do
		local row = titledRow(themeForm, "Folder Colour", "Directory and group container tint")
		settingControl("folderColour", row:Right(), "PopUpButton", {
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
		settingControl("blur", row:Right(), "Toggle", {
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
		settingControl("shadow", row:Right(), "Toggle", {
			Value = window.Dropshadow,
			ValueChanged = function(self, value)
				window.Dropshadow = value
			end,
		})
	end

	do
		local row = titledRow(fxForm, "Minimize Hotkey", "Keycode to toggle window visibility")
		settingControl("hotkey", row:Right(), "KeybindField", {
			Value = minimizeKey,
			ValueChanged = function(self, value)
				minimizeKey = value
				app:Notification({
					App = "StacOnf",
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


do
	local settingsTab = window:Tab({
		Title = "Settings",
		Icon = getAsset("config.png", "https://raw.githubusercontent.com/x8lua/Staconf/main/assets/config.png"),
	})
	local form = settingsTab:PageSection({
		Title = "Configuration",
		Subtitle = "Save your setup. Switch profiles whenever you need.",
	}):Form()
	local path = "Staconf/settings-v1.json"
	local http = game:GetService("HttpService")
	local database: any = { version = 1, profiles = {}, autoload = "" }
	local available = typeof(readfile) == "function" and typeof(writefile) == "function" and typeof(isfile) == "function"
	local healthy = true
	local names = {}
	local selected = ""
	local picker
	local startup
	local status
	local refreshing = false
	local pending = ""
	local deadline = 0
	local function report(message)
		if status then status.Text = message end
	end
	local function validName(name)
		name = name:match("^%s*(.-)%s*$")
		assert(#name >= 1 and #name <= 32, "Use 1-32 characters.")
		assert(name:match("^[%w _%-]+$"), "Use letters, numbers, spaces, - or _.")
		return name
	end
	local function readDatabase()
		if not available then return end
		if not isfile(path) then
			database = { version = 1, profiles = {}, autoload = "" }
			return
		end
		local raw = readfile(path)
		assert(#raw <= 1048576, "Settings file is too large.")
		local decoded = http:JSONDecode(raw)
		assert(type(decoded) == "table" and decoded.version == 1 and type(decoded.profiles) == "table", "Unsupported settings file.")
		assert(type(decoded.autoload) == "string", "Invalid startup profile.")
		local count = 0
		for name, profile in pairs(decoded.profiles) do
			assert(type(name) == "string" and validName(name) == name, "Invalid profile name.")
			assert(type(profile) == "table", "Invalid profile.")
			validateSettings(profile.values)
			count += 1
			assert(count <= 100, "Too many profiles.")
		end
		assert(decoded.autoload == "" or decoded.profiles[decoded.autoload], "Startup profile is missing.")
		database = decoded
	end
	local function persist(nextDatabase)
		assert(available, "File storage unavailable in this environment.")
		assert(healthy, "Repair the settings file, then Refresh.")
		if typeof(makefolder) == "function" then
			if typeof(isfolder) ~= "function" or not isfolder("Staconf") then pcall(makefolder, "Staconf") end
		end
		local encoded = http:JSONEncode(nextDatabase)
		if isfile(path) then writefile(path .. ".bak", readfile(path)) end
		writefile(path, encoded)
		assert(readfile(path) == encoded, "Storage verification failed.")
		database = nextDatabase
	end
	local function candidate()
		return { version = 1, profiles = table.clone(database.profiles), autoload = database.autoload }
	end
	local function guarded(action)
		local ok, message = pcall(action)
		if not ok then report((tostring(message):gsub("^.-:%d+: ", ""))) end
	end
	local function refresh(preferred)
		refreshing = true
		table.clear(names)
		for name in pairs(database.profiles) do table.insert(names, name) end
		table.sort(names)
		selected = table.find(names, preferred) and preferred or names[1] or ""
		picker.Options = #names > 0 and table.clone(names) or { "No saved profiles" }
		picker.Value = table.find(names, selected) or 1
		startup.Value = selected ~= "" and database.autoload == selected
		refreshing = false
	end
	local function confirm(action)
		if pending == action and os.clock() < deadline then
			pending = ""
			return true
		end
		pending = action
		deadline = os.clock() + 4
		report("Click again within 4 seconds to " .. action .. ".")
		return false
	end
	local nameField = titledRow(form, "Profile name"):Right():TextField({ Value = "", Placeholder = "My setup" })
	nameField.Structures.Field.Size = UDim2.fromOffset(150, 24)
	picker = crispPopUpButton(titledRow(form, "Saved profiles"):Right(), {
		Options = { "No saved profiles" },
		Value = 1,
		ValueChanged = function(self, index)
			if refreshing or not startup then return end
			selected = self.Options[index] or ""
			if not database.profiles[selected] then selected = "" end
			startup.Value = selected ~= "" and database.autoload == selected
		end,
	})
	titledRow(form, "Save current settings"):Right():Button({
		Label = "Save", State = "Primary",
		Pushed = function()
			guarded(function()
				local name = validName(nameField.Structures.Field.Text)
				if database.profiles[name] and not confirm("overwrite " .. name) then return end
				assert(database.profiles[name] or #names < 100, "Maximum 100 profiles.")
				local nextDatabase = candidate()
				nextDatabase.profiles[name] = { values = captureSettings(), savedAt = os.time() }
				persist(nextDatabase)
				refresh(name)
				report("Saved " .. name .. ".")
			end)
		end,
	})
	titledRow(form, "Apply selected profile"):Right():Button({
		Label = "Load", State = "Secondary",
		Pushed = function()
			guarded(function()
				assert(database.profiles[selected], "Select a saved profile first.")
				applySettings(database.profiles[selected].values)
				report("Loaded " .. selected .. ".")
			end)
		end,
	})
	startup = titledRow(form, "Load on startup", "Automatically apply the selected profile."):Right():Toggle({
		Value = false,
		ValueChanged = function(self, enabled)
			if refreshing then return end
			local expected = selected ~= "" and database.autoload == selected
			if enabled == expected then return end
			guarded(function()
				assert(selected ~= "", "Save a profile first.")
				local nextDatabase = candidate()
				nextDatabase.autoload = enabled and selected or ""
				persist(nextDatabase)
				report(enabled and ("Startup profile: " .. selected) or "Automatic loading disabled.")
			end)
			local actual = selected ~= "" and database.autoload == selected
			if self.Value ~= actual then self.Value = actual end
		end,
	})
	local management = settingsTab:PageSection({ Title = "Manage profiles" }):Form()
	titledRow(management, "Refresh from disk"):Right():Button({
		Label = "Refresh", State = "Secondary",
		Pushed = function()
			guarded(function()
				assert(available, "File storage unavailable in this environment.")
				healthy = false
				readDatabase()
				healthy = true
				refresh(selected)
				report("Profile list refreshed.")
			end)
		end,
	})
	titledRow(management, "Delete selected profile"):Right():Button({
		Label = "Delete", State = "Destructive",
		Pushed = function()
			guarded(function()
				assert(database.profiles[selected], "Select a saved profile first.")
				if not confirm("delete " .. selected) then return end
				local deleted = selected
				local nextDatabase = candidate()
				nextDatabase.profiles[deleted] = nil
				if nextDatabase.autoload == deleted then nextDatabase.autoload = "" end
				persist(nextDatabase)
				refresh("")
				report("Deleted " .. deleted .. ".")
			end)
		end,
	})
	titledRow(management, "Restore session defaults", "Saved profiles are kept."):Right():Button({
		Label = "Reset", State = "Secondary",
		Pushed = function()
			guarded(function()
				if not confirm("reset settings") then return end
				applySettings(captureSettings(true))
				report("Session defaults restored.")
			end)
		end,
	})
	status = management:Row({ SearchIndex = "Storage status" }):Left():Label({ Text = "Profiles are stored locally on this device." })
	local ok, message = pcall(readDatabase)
	healthy = ok
	refresh(database.autoload)
	if not ok then
		report("Could not read profiles. Repair the file, then Refresh.")
		warn("StacOnf settings: " .. tostring(message))
	elseif not available then
		report("File storage unavailable. Profiles cannot be saved.")
	elseif database.autoload ~= "" then
		guarded(function()
			applySettings(database.profiles[database.autoload].values)
			report("Loaded startup profile: " .. database.autoload .. ".")
		end)
	end
end

do
	accountTab = window:Tab({
		Title = "Account",
	})
	local accountButton = accountTab.Structures.Body
	accountButton = typeof(accountButton) == "Instance" and accountButton or accountButton.__instance
	accountButton.Visible = false
	local page = accountTab.Structures.Page
	page = typeof(page) == "Instance" and page or page.__instance
	local pageLayout = page:FindFirstChildOfClass("UIListLayout")
	if pageLayout then pageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center end
	local profile = Instance.new("Frame")
	profile.Name = "ProfileSurface"
	profile.Size = UDim2.new(1, -34, 0, 344)
	profile.BorderSizePixel = 0
	profile.LayoutOrder = 1
	profile.Parent = page
	local profileConstraint = Instance.new("UISizeConstraint")
	profileConstraint.MaxSize = Vector2.new(420, 344)
	profileConstraint.Parent = profile
	local profileCorner = Instance.new("UICorner")
	profileCorner.CornerRadius = UDim.new(0, 16)
	profileCorner.Parent = profile
	local profileLayout = Instance.new("Frame")
	profileLayout.Name = "ProfileLayout"
	profileLayout.Size = UDim2.fromScale(1, 1)
	profileLayout.BackgroundTransparency = 1
	profileLayout.BorderSizePixel = 0
	profileLayout.Parent = profile
	local profileStroke = Instance.new("UIStroke")
	profileStroke.Name = "ProfileStroke"
	profileStroke.Thickness = 1
	profileStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	profileStroke.Parent = profile
	local header = Instance.new("Frame")
	header.Name = "AccountHeader"
	header.Size = UDim2.new(1, 0, 0, 148)
	header.BackgroundTransparency = 1
	header.Parent = profileLayout
	local avatar = Instance.new("Frame")
	avatar.Name = "AccountAvatar"
	avatar.AnchorPoint = Vector2.new(0.5, 0)
	avatar.Position = UDim2.new(0.5, 0, 0, 26)
	avatar.Size = UDim2.fromOffset(84, 84)
	avatar.BorderSizePixel = 0
	avatar.Parent = header
	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(1, 0)
	avatarCorner.Parent = avatar
	local head = Instance.new("Frame")
	head.AnchorPoint = Vector2.new(0.5, 0)
	head.Position = UDim2.new(0.5, 0, 0, 18)
	head.Size = UDim2.fromOffset(26, 26)
	head.BackgroundColor3 = Color3.new(1, 1, 1)
	head.BorderSizePixel = 0
	head.Parent = avatar
	local headCorner = Instance.new("UICorner")
	headCorner.CornerRadius = UDim.new(1, 0)
	headCorner.Parent = head
	local shoulders = Instance.new("Frame")
	shoulders.AnchorPoint = Vector2.new(0.5, 0)
	shoulders.Position = UDim2.new(0.5, 0, 0, 47)
	shoulders.Size = UDim2.fromOffset(48, 28)
	shoulders.BackgroundColor3 = Color3.new(1, 1, 1)
	shoulders.BorderSizePixel = 0
	shoulders.Parent = avatar
	local shouldersCorner = Instance.new("UICorner")
	shouldersCorner.CornerRadius = UDim.new(1, 0)
	shouldersCorner.Parent = shoulders
	local information = Instance.new("Frame")
	information.Name = "AccountInformation"
	information.Position = UDim2.new(0, 16, 0, 164)
	information.Size = UDim2.new(1, -32, 0, 164)
	information.BorderSizePixel = 0
	information.Parent = profileLayout
	local informationCorner = Instance.new("UICorner")
	informationCorner.CornerRadius = UDim.new(0, 12)
	informationCorner.Parent = information
	local values = {
		{"Gakuran Name", "Free User"},
		{"Roblox Username", "Not connected"},
		{"Display Name", "Free User"},
	}
	local valueLabels = {}
	for index, item in ipairs(values) do
		local row = Instance.new("Frame")
		row.Name = "AccountRow" .. index
		row.Position = UDim2.fromOffset(0, (index - 1) * 54)
		row.Size = UDim2.new(1, 0, 0, 54)
		row.BackgroundTransparency = 1
		row.Parent = information
		local label = Instance.new("TextLabel")
		label.Text = item[1]
		label.Position = UDim2.fromOffset(16, 8)
		label.Size = UDim2.new(1, -32, 0, 16)
		label.BackgroundTransparency = 1
		label.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular)
		label.TextSize = 12
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row
		local value = Instance.new("TextLabel")
		value.Text = item[2]
		value.Position = UDim2.fromOffset(16, 25)
		value.Size = UDim2.new(1, -32, 0, 20)
		value.BackgroundTransparency = 1
		value.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular)
		value.TextSize = 15
		value.TextXAlignment = Enum.TextXAlignment.Left
		value.TextTruncate = Enum.TextTruncate.AtEnd
		value.Parent = row
		table.insert(valueLabels, {label, value})
		if index < #values then
			local divider = Instance.new("Frame")
			divider.Name = "AccountDivider"
			divider.Position = UDim2.new(0, 16, 1, -1)
			divider.Size = UDim2.new(1, -32, 0, 1)
			divider.BorderSizePixel = 0
			divider.Parent = row
		end
	end
	local accountRefreshing = false
	refreshAccountPage = function()
		if accountRefreshing then return end
		if not page.Parent then return end
		accountRefreshing = true
		local light = currentMode == "Light"
		local primary = light and Color3.fromRGB(37, 40, 48) or Color3.fromRGB(244, 245, 249)
		local secondary = light and Color3.fromRGB(108, 113, 125) or Color3.fromRGB(169, 174, 189)
		local surface = light and Color3.fromRGB(250, 250, 252) or Color3.fromRGB(26, 28, 36)
		local informationSurface = light and Color3.fromRGB(242, 243, 247) or Color3.fromRGB(34, 37, 47)
		local divider = light and Color3.fromRGB(222, 224, 230) or Color3.fromRGB(52, 55, 67)
		avatar.BackgroundColor3 = light and Color3.fromRGB(173, 179, 188) or Color3.fromRGB(106, 114, 130)
		profile.BackgroundColor3 = surface
		profileStroke.Color = divider
		profileStroke.Transparency = light and 0.35 or 0.55
		information.BackgroundColor3 = informationSurface
		for _, pair in ipairs(valueLabels) do
			pair[1].TextColor3 = secondary
			pair[2].TextColor3 = primary
		end
		for _, object in ipairs(information:GetDescendants()) do
			if object.Name == "AccountDivider" then object.BackgroundColor3 = divider end
		end
		accountRefreshing = false
	end
	refreshAccountPage()
	for _, object in ipairs({profile, information}) do
		chromeConnect(object:GetPropertyChangedSignal("BackgroundColor3"), function()
			if not accountRefreshing then task.defer(refreshAccountPage) end
		end)
	end
end

app:Notification({
	App = "StacOnf",
	Title = "System Online",
	Subtitle = "StacOnf initialized successfully. Press RightControl to toggle.",
	Duration = 4,
})
