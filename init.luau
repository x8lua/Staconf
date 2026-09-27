-- Reusable Cascade shell. Application state and tab content belong to the caller.
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local CASCADE_URL = "https://github.com/cascadeui/Cascade/releases/latest/download/dist.luau"
local ASSET_URL = "https://raw.githubusercontent.com/x8lua/Staconf/main/assets/"
local Staconf = {}
Staconf.__index = Staconf

local function raw(value)
    return typeof(value) == "Instance" and value or value and value.__instance
end

local function round(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
end

local function windowSize(gui, size)
    if size then return size end
    if not UserInputService.TouchEnabled then return UDim2.fromOffset(800, 520) end
    local bounds = gui.AbsoluteSize
    if bounds.X < 100 or bounds.Y < 100 then
        local camera = workspace.CurrentCamera
        bounds = camera and camera.ViewportSize or Vector2.new(600, 380)
    end
    return UDim2.fromOffset(math.floor(math.min(520, bounds.X * 0.84)),
        math.floor(math.min(360, bounds.Y * 0.72)))
end

function Staconf:Asset(fileName)
    if not fileName then return nil end
    if fileName:find("^rbxassetid://") then return fileName end
    local url = self.AssetBaseUrl .. fileName
    if type(getcustomasset) ~= "function" or type(writefile) ~= "function" then return url end
    local path = self.CacheRoot .. "/assets/" .. fileName
    if type(isfile) ~= "function" or not isfile(path) then
        local ok, data = pcall(function() return game:HttpGetAsync(url) end)
        if ok and type(data) == "string" and #data > 0 then
            if type(makefolder) == "function" then
                pcall(makefolder, self.CacheRoot)
                pcall(makefolder, self.CacheRoot .. "/assets")
                local folder = self.CacheRoot .. "/assets"
                for segment in fileName:gmatch("([^/]+)/") do
                    folder = folder .. "/" .. segment
                    pcall(makefolder, folder)
                end
            end
            pcall(writefile, path, data)
        end
    end
    local ok, asset = pcall(getcustomasset, path)
    return ok and asset or url
end

function Staconf:_connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self._connections, connection)
    return connection
end

function Staconf:_applyFont(object)
    if not self._fontFamily or not object then return end
    if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
        local face = object.FontFace
        object.FontFace = Font.new(self._fontFamily, face.Weight, face.Style)
    end
end

function Staconf:LoadFontFamily(files)
    files = files or {"regular.otf", "medium.otf", "bold.otf"}
    if type(getcustomasset) ~= "function" or type(writefile) ~= "function" then return false end
    local folder = self.CacheRoot .. "/fonts"
    pcall(makefolder, self.CacheRoot)
    pcall(makefolder, folder)
    for _, fileName in ipairs(files) do
        local path = folder .. "/" .. fileName
        if type(isfile) ~= "function" or not isfile(path) then
            local ok, data = pcall(function() return game:HttpGetAsync(self.AssetBaseUrl .. "fonts/" .. fileName) end)
            if ok and type(data) == "string" and #data > 0 then pcall(writefile, path, data) end
        end
    end
    local ok, family = pcall(function()
        local regular = folder .. "/regular.otf"
        assert(type(isfile) == "function" and isfile(regular), "regular font unavailable")
        return getcustomasset(regular)
    end)
    if ok then self._fontFamily = family end
    return ok
end

function Staconf:ApplyFont(root)
    root = root or self.App.__instance
    self:_applyFont(root)
    for _, object in ipairs(root:GetDescendants()) do self:_applyFont(object) end
end

function Staconf:ShowBoot()
    if self._destroyed then return nil end
    if self._boot then return self._boot end
    local body = raw(self.Window.Structures.Body)
    local overlay = Instance.new("CanvasGroup")
    overlay.Name = "StacOnfBootOverlay"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 50000
    overlay.Parent = body
    round(overlay, 16)
    local logo = Instance.new("ImageLabel")
    logo.Name = "SplashLogo"
    local image = self.BootImage or self:Asset(self.BootImageFile)
    logo.Image = image or ""
    logo.AnchorPoint = Vector2.new(0.5, 0.5)
    logo.Position = UDim2.new(0.5, 0, 0.42, -10)
    logo.Size = UserInputService.TouchEnabled and UDim2.new(1, -36, 0.68, 0) or UDim2.fromOffset(480, 270)
    logo.ScaleType = Enum.ScaleType.Fit
    logo.BackgroundTransparency = 1
    logo.Visible = image ~= nil
    logo.Parent = overlay
    if not image then
        local title = Instance.new("TextLabel")
        title.Name = "BootTitle"
        title.AnchorPoint = Vector2.new(0.5, 0.5)
        title.Position = UDim2.new(0.5, 0, 0.42, -10)
        title.Size = UDim2.new(1, -36, 0, 90)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.Text = self.Title
        title.TextSize = UserInputService.TouchEnabled and 30 or 42
        title.TextScaled = false
        title.TextWrapped = true
        title.TextColor3 = Color3.fromRGB(245, 246, 250)
        title.Parent = overlay
    end
    local track = Instance.new("Frame")
    track.Name = "ProgressTrack"
    track.AnchorPoint = Vector2.new(0.5, 0.5)
    track.Position = UDim2.new(0.5, 0, 0.42, 85)
    track.Size = UDim2.fromOffset(260, 5)
    track.BackgroundColor3 = Color3.fromRGB(48, 48, 52)
    track.BackgroundTransparency = 1
    track.BorderSizePixel = 0
    track.Visible = false
    track.Parent = overlay
    round(track, 5)
    local fill = Instance.new("Frame")
    fill.Name = "ProgressFill"
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = self.ProgressColor
    fill.BackgroundTransparency = 1
    fill.BorderSizePixel = 0
    fill.Parent = track
    round(fill, 5)
    self._boot = {Overlay = overlay, Fill = fill}
    if self.BootSoundId then
        local sound = Instance.new("Sound")
        sound.Name = "StacOnfBootSfx"
        sound.SoundId = self.BootSoundId
        sound.Volume = self.BootSoundVolume
        sound.Parent = SoundService
        self._bootSound = sound
        pcall(function() game:GetService("ContentProvider"):PreloadAsync({sound}) end)
        sound:Play()
    end
    return self._boot
end

function Staconf:SetBootProgress(progress)
    local boot = self._boot
    if not boot or not boot.Fill.Parent then return end
    TweenService:Create(boot.Fill, TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Size = UDim2.fromScale(math.clamp(tonumber(progress) or 0, 0, 1), 1)}):Play()
end

function Staconf:RevealBootProgress()
    local boot = self._boot
    if not boot or not boot.Overlay.Parent then return end
    local track = boot.Fill.Parent
    track.Visible = true
    TweenService:Create(track, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0}):Play()
    TweenService:Create(boot.Fill, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0}):Play()
end

function Staconf:FinishBoot()
    local boot = self._boot
    if not boot or not boot.Overlay.Parent then return end
    self:SetBootProgress(1)
    local tween = TweenService:Create(boot.Overlay, TweenInfo.new(0.55, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
        {GroupTransparency = 1})
    local sound = self._bootSound
    self._bootSound = nil
    tween.Completed:Once(function()
        if boot.Overlay.Parent then boot.Overlay:Destroy() end
        if sound and sound.Parent then sound:Destroy() end
    end)
    tween:Play()
    self._boot = nil
end

function Staconf:_noticeHost()
    if self._destroyed then return end
    if self._noticeGui and self._noticeGui.Parent then return end
    local gui = Instance.new("ScreenGui")
    gui.Name = self.Name .. "Notifications"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 1000
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.Parent = self.App.__instance.Parent
    local host = Instance.new("Frame")
    host.AnchorPoint = Vector2.new(1, 0)
    host.Position = UDim2.new(1, -16, 0, 14)
    host.Size = UDim2.new(1, -32, 0, 0)
    host.AutomaticSize = Enum.AutomaticSize.Y
    host.BackgroundTransparency = 1
    host.Parent = gui
    local hostLimit = Instance.new("UISizeConstraint")
    hostLimit.MaxSize = Vector2.new(360, 10000)
    hostLimit.Parent = host
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = host
    self._noticeGui, self._noticeHostFrame = gui, host
end

function Staconf:Notify(options)
    if self._destroyed then return nil end
    options = options or {}
    self:_noticeHost()
    local light = self.Mode == "Light"
    local card = Instance.new("CanvasGroup")
    card.Name = "Notification"
    card.Size = UDim2.new(1, 0, 0, 104)
    card.BackgroundColor3 = light and Color3.fromRGB(235, 242, 247) or Color3.fromRGB(201, 228, 232)
    card.BackgroundTransparency = 0.06
    card.BorderSizePixel = 0
    card.GroupTransparency = 1
    card.Parent = self._noticeHostFrame
    round(card, 23)
    local rim = Instance.new("UIStroke")
    rim.Color = Color3.fromRGB(235, 242, 255)
    rim.Transparency = 0.72
    rim.Thickness = 1
    rim.Parent = card
    local iconFrame = Instance.new("Frame")
    iconFrame.Name = "AppIcon"
    iconFrame.Size = UDim2.fromOffset(38, 38)
    iconFrame.Position = UDim2.new(0, 16, 0.5, -19)
    iconFrame.BackgroundColor3 = Color3.fromRGB(31, 37, 49)
    iconFrame.BorderSizePixel = 0
    iconFrame.Parent = card
    round(iconFrame, 10)
    local icon = Instance.new("ImageLabel")
    icon.BackgroundTransparency = 1
    icon.Size = UDim2.fromOffset(24, 24)
    icon.Position = UDim2.fromOffset(7, 7)
    icon.Image = options.Icon or self.Cascade.Symbols.sliderHorizontal3
    icon.ImageColor3 = Color3.fromRGB(209, 192, 255)
    icon.Parent = iconFrame
    for index, content in ipairs({options.App or self.Title, options.Title or "Notification", options.Subtitle or options.Description or ""}) do
        local label = Instance.new("TextLabel")
        label.Position = UDim2.fromOffset(68, index == 1 and 13 or index == 2 and 32 or 51)
        label.Size = UDim2.new(1, -84, 0, index == 3 and 43 or 20)
        label.BackgroundTransparency = 1
        label.Font = index == 1 and Enum.Font.GothamBold or Enum.Font.Gotham
        label.TextSize = index == 1 and 14 or 15
        label.TextWrapped = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextColor3 = Color3.fromRGB(31, 37, 49)
        label.Text = tostring(content)
        label.Parent = card
    end
    local dismiss = Instance.new("TextButton")
    dismiss.Text = ""
    dismiss.BackgroundTransparency = 1
    dismiss.Size = UDim2.fromScale(1, 1)
    dismiss.AutoButtonColor = false
    dismiss.Parent = card
    dismiss.Activated:Connect(function() if card.Parent then card:Destroy() end end)
    if light then card.BackgroundColor3 = Color3.fromRGB(235, 242, 247) end
    TweenService:Create(card, TweenInfo.new(0.22), {GroupTransparency = 0}):Play()
    task.delay(tonumber(options.Duration) or 4, function()
        if self._destroyed or not card.Parent then return end
        local tween = TweenService:Create(card, TweenInfo.new(0.22), {GroupTransparency = 1})
        tween.Completed:Once(function() if card.Parent then card:Destroy() end end)
        tween:Play()
    end)
    return card
end

function Staconf:Dialog(options)
    if self._destroyed then return nil end
    options = options or {}
    local gui = Instance.new("ScreenGui")
    gui.Name = self.Name .. "Dialog"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 10000
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.Parent = self.App.__instance.Parent
    table.insert(self._dialogs, gui)
    local dim = Instance.new("TextButton")
    dim.Text = ""
    dim.AutoButtonColor = false
    dim.Size = UDim2.fromScale(1, 1)
    dim.BackgroundColor3 = Color3.new(0, 0, 0)
    dim.BackgroundTransparency = options.DimBackground == false and 1 or 0.4
    dim.Parent = gui
    local card = Instance.new("ScrollingFrame")
    card.Name = "DialogCard"
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.fromScale(0.5, 0.5)
    local viewport = gui.AbsoluteSize
    if viewport.X < 100 or viewport.Y < 100 then
        local camera = workspace.CurrentCamera
        viewport = camera and camera.ViewportSize or Vector2.new(600, 380)
    end
    local maxWidth = math.max(1, viewport.X - 32)
    card.Size = UDim2.fromOffset(math.min(math.clamp(tonumber(options.Width) or 420, 260, 560), maxWidth), 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.AutomaticCanvasSize = Enum.AutomaticSize.Y
    card.CanvasSize = UDim2.fromOffset(0, 0)
    card.ScrollBarThickness = 3
    card.BackgroundColor3 = self.Mode == "Light" and Color3.fromRGB(250, 250, 252) or Color3.fromRGB(29, 31, 40)
    card.BorderSizePixel = 0
    card.Parent = gui
    round(card, 20)
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = self.Mode == "Light" and Color3.fromRGB(214, 218, 227) or Color3.fromRGB(83, 88, 104)
    cardStroke.Transparency = 0.32
    cardStroke.Thickness = 1
    cardStroke.Parent = card
    local sizeLimit = Instance.new("UISizeConstraint")
    sizeLimit.MaxSize = Vector2.new(maxWidth, math.max(1, viewport.Y - 32))
    sizeLimit.Parent = card
    local function fitDialog()
        if not gui.Parent then return end
        local bounds = gui.AbsoluteSize
        if bounds.X < 100 or bounds.Y < 100 then return end
        local safeWidth = math.max(1, bounds.X - 32)
        card.Size = UDim2.fromOffset(math.min(math.clamp(tonumber(options.Width) or 420, 260, 560), safeWidth), 0)
        sizeLimit.MaxSize = Vector2.new(safeWidth, math.max(1, bounds.Y - 32))
    end
    gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitDialog)
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 24)
    padding.PaddingBottom = UDim.new(0, 20)
    padding.PaddingLeft = UDim.new(0, 24)
    padding.PaddingRight = UDim.new(0, 24)
    padding.Parent = card
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 14)
    layout.Parent = card
    for index, content in ipairs({options.Title or self.Title, options.Description or ""}) do
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 0)
        label.AutomaticSize = Enum.AutomaticSize.Y
        label.BackgroundTransparency = 1
        label.Font = index == 1 and Enum.Font.GothamBold or Enum.Font.Gotham
        label.TextSize = index == 1 and 19 or 14
        label.TextWrapped = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextColor3 = self.Mode == "Light" and Color3.fromRGB(27, 29, 36) or Color3.fromRGB(240, 242, 248)
        label.Text = tostring(content)
        label.Parent = card
    end
    local buttons = Instance.new("Frame")
    local actions = options.Buttons or {{Text = "OK", Style = "Primary"}}
    local stacked = #actions > 2 or maxWidth < 340
    buttons.Size = UDim2.new(1, 0, 0, stacked and (#actions * 38 + math.max(0, #actions - 1) * 8) or 38)
    buttons.BackgroundTransparency = 1
    buttons.Parent = card
    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = stacked and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
    buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    buttonLayout.Padding = UDim.new(0, 8)
    buttonLayout.Parent = buttons
    local closed = false
    local function close()
        if closed then return end
        closed = true
        gui:Destroy()
    end
    if options.Modal == false then dim.MouseButton1Click:Connect(close) end
    for _, action in ipairs(actions) do
        local button = Instance.new("TextButton")
        button.Size = stacked and UDim2.new(1, 0, 0, 38) or UDim2.fromOffset(96, 38)
        button.Text = tostring(action.Text or "OK")
        button.Font = Enum.Font.GothamMedium
        button.TextSize = 14
        button.TextColor3 = Color3.new(1, 1, 1)
        button.BackgroundColor3 = action.Style == "Primary" and Color3.fromRGB(0, 122, 255) or Color3.fromRGB(72, 76, 89)
        button.BorderSizePixel = 0
        button.Parent = buttons
        round(button, 10)
        button.MouseButton1Click:Connect(function()
            close()
            if action.Callback then task.spawn(action.Callback) end
        end)
    end
    return {Gui = gui, Close = close}
end

function Staconf:AddTab(options)
    options = options or {}
    if not options.Icon and self._chromeEnabled then
        local name = tostring(options.Title or ""):lower()
        local icons = {settings = "gearshape", combat = "shield", movement = "figure",
            visuals = "squareGrid2x2", staff = "personCropCircle", prison = "house"}
        options.Icon = self.Cascade.Symbols[icons[name] or "squareGrid2x2"]
    end
    local tab = self.Window:Tab(options)
    if self._chromeEnabled then self:_styleSidebarItem(raw(tab.Structures.Body)) end
    return tab
end

function Staconf:SetVisible(visible)
    if self._destroyed or not self.App.__instance.Parent then return end
    self.App.__instance.Enabled = visible == true
    -- Cascade's camera blur does not follow ScreenGui.Enabled.
    self.Window.UIBlur = visible == true and self._blurWanted or false
end

function Staconf:SetTheme(mode, accent)
    if mode == "Dark" or mode == "Light" then
        self.Mode = mode
        self.App.Theme = self.Cascade.Themes[mode]
    end
    if accent and self.Cascade.Accents[accent] then
        self.App.Accent = self.Cascade.Accents[accent]
        self._accentName = accent
    end
    self._accentColor = self.Cascade.Accents[self._accentName][self.Mode].Selection
    if self._chromeEnabled then self:_applyChrome() end
end

function Staconf:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    if self._bootSound then self._bootSound:Destroy() end
    if self._boot and self._boot.Overlay.Parent then self._boot.Overlay:Destroy() end
    if self._noticeGui then self._noticeGui:Destroy() end
    if self._tooltipGui then self._tooltipGui:Destroy() end
    for _, connection in ipairs(self._connections or {}) do connection:Disconnect() end
    table.clear(self._connections or {})
    for _, dialog in ipairs(self._dialogs) do if dialog.Parent then dialog:Destroy() end end
    if self.App.__instance.Parent then self.App.__instance:Destroy() end
    if self._onDestroy then pcall(self._onDestroy, self) end
end

function Staconf:Tooltip(target, text)
    if not target or self._destroyed then return end
    if not self._tooltipGui or not self._tooltipGui.Parent then
        local gui = Instance.new("ScreenGui")
        gui.Name = self.Name .. "Tooltips"
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 20000
        gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
        gui.Parent = self.App.__instance.Parent
        local card = Instance.new("Frame")
        card.Name = "TooltipCard"
        card.AutomaticSize = Enum.AutomaticSize.XY
        card.Visible = false
        card.AnchorPoint = Vector2.new(0.5, 1)
        card.BackgroundColor3 = Color3.fromRGB(28, 30, 38)
        card.BackgroundTransparency = 0.05
        card.BorderSizePixel = 0
        card.ZIndex = 20000
        card.Parent = gui
        round(card, 8)
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 6); padding.PaddingBottom = UDim.new(0, 6)
        padding.PaddingLeft = UDim.new(0, 10); padding.PaddingRight = UDim.new(0, 10)
        padding.Parent = card
        local label = Instance.new("TextLabel")
        label.Name = "Content"
        label.AutomaticSize = Enum.AutomaticSize.XY
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 12
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextWrapped = true
        label.Text = ""
        label.Parent = card
        self._tooltipGui, self._tooltipCard, self._tooltipLabel = gui, card, label
    end
    local card, label = self._tooltipCard, self._tooltipLabel
    local hoverThread
    local function hide()
        if hoverThread then pcall(task.cancel, hoverThread); hoverThread = nil end
        if card then card.Visible = false end
    end
    self:_connect(target.MouseEnter, function()
        if hoverThread then pcall(task.cancel, hoverThread) end
        hoverThread = task.delay(0.45, function()
            if self._destroyed or not target:IsDescendantOf(game) then return end
            label.Text = tostring(text or "")
            local p, s = target.AbsolutePosition, target.AbsoluteSize
            local owner = self.App.__instance.AbsolutePosition
            card.Position = UDim2.fromOffset(p.X - owner.X + s.X / 2, p.Y - owner.Y - 6)
            card.Visible = true
        end)
    end)
    self:_connect(target.MouseLeave, hide)
end

function Staconf:AttachTooltips(entries)
    for target, text in pairs(entries or {}) do self:Tooltip(target, text) end
end

function Staconf:_applyChrome()
    local structures = self.Window.Structures
    local body = raw(structures.Body)
    if not body then return end
    local bodyCorner = body:FindFirstChildOfClass("UICorner")
    if bodyCorner then bodyCorner.CornerRadius = UDim.new(0, 22) end
    local light = self.Mode == "Light"
    local sidebar = raw(structures.SidebarMargins)
    local content = raw(structures.ContentBody)
    if sidebar then
        sidebar.BackgroundColor3 = light and Color3.fromRGB(239, 241, 246) or Color3.fromRGB(20, 22, 31)
        sidebar.BackgroundTransparency = 0.08
    end
    if content then
        content.BackgroundColor3 = light and Color3.fromRGB(250, 251, 253) or Color3.fromRGB(27, 28, 32)
        content.BackgroundTransparency = 0.03
        local corner = content:FindFirstChildOfClass("UICorner")
        if corner then corner.CornerRadius = UDim.new(0, 0) end
    end
    local separator = raw(structures.Separator)
    if separator then separator.Visible = false end
    local inner = raw(structures.Sidebar)
    if inner then
        local shadow = inner:FindFirstChild("Shadow", true)
        if shadow then shadow.Visible = false end
    end
    local list = raw(structures.SidebarList)
    if list then
        local layout = list:FindFirstChildOfClass("UIListLayout")
        if layout then layout.Padding = UDim.new(0, 2) end
        for _, item in ipairs(list:GetChildren()) do
            self:_styleSidebarItem(item)
        end
    end
    if self._shell then
        local shell = self._shell
        shell.Sidebar.BackgroundColor3 = light and Color3.fromRGB(236, 239, 244) or Color3.fromRGB(24, 28, 40)
        shell.Content.BackgroundColor3 = light and Color3.fromRGB(249, 250, 252) or Color3.fromRGB(17, 20, 30)
        shell.Search.BackgroundColor3 = light and Color3.fromRGB(247, 248, 250) or Color3.fromRGB(43, 46, 57)
        shell.ProfileTitle.TextColor3 = light and Color3.fromRGB(37, 40, 48) or Color3.fromRGB(244, 245, 249)
        shell.ProfileSubtitle.TextColor3 = light and Color3.fromRGB(108, 113, 125) or Color3.fromRGB(169, 174, 189)
    end
end

function Staconf:_styleSidebarItem(item)
    if not item or item.Name ~= "SidebarItem" or not item:IsA("GuiObject") then return end
    item.Size = UDim2.new(1, 0, 0, UserInputService.TouchEnabled and 44 or 34)
    local corner = item:FindFirstChildOfClass("UICorner")
    if corner then corner.CornerRadius = UDim.new(0, 8) end
    local leading = item:FindFirstChild("Leading")
    local title = leading and leading:FindFirstChild("Title")
    if title then
        title.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium)
        title.TextSize = 14
        title.Size = UDim2.new(1, -8, 0, 24)
    end
    if leading then
        leading.Size = UDim2.new(1, 0, 0, 24)
        leading.AutomaticSize = Enum.AutomaticSize.None
        local layout = leading:FindFirstChildOfClass("UIListLayout")
        if layout then layout.Padding = UDim.new(0, 8) end
    end
    local trailing = item:FindFirstChild("Trailing")
    if trailing then trailing.Visible = false end
    local symbol = leading and leading:FindFirstChild("Symbol")
    if symbol and symbol.Visible then
        symbol.Size = UDim2.fromOffset(20, 20)
        symbol.ScaleType = Enum.ScaleType.Fit
    end
    if symbol and symbol.Visible and not leading:FindFirstChild("BadgeBackground") then
        local badge = Instance.new("Frame")
        badge.Name = "BadgeBackground"
        badge.Size = UDim2.fromOffset(22, 22)
        badge.LayoutOrder = 1
        badge.BorderSizePixel = 0
        badge.BackgroundColor3 = self._accentColor
        badge.Parent = leading
        round(badge, 6)
        symbol.Parent = badge
        symbol.AnchorPoint = Vector2.new(0.5, 0.5)
        symbol.Position = UDim2.fromScale(0.5, 0.5)
    end
    local function refresh()
        if not item.Parent then return end
        local selected = item.BackgroundTransparency < 0.5
        local light = self.Mode == "Light"
        item.BackgroundColor3 = selected and
            (light and Color3.fromRGB(218, 225, 238) or self._accentColor) or
            (light and Color3.fromRGB(239, 241, 246) or Color3.fromRGB(20, 22, 31))
        if title then
            title.TextColor3 = selected and (light and Color3.fromRGB(27, 31, 40) or Color3.new(1, 1, 1))
                or (light and Color3.fromRGB(75, 80, 94) or Color3.fromRGB(220, 223, 233))
        end
        if symbol and symbol.Visible then symbol.ImageColor3 = selected and Color3.new(1, 1, 1) or self._accentColor end
    end
    if not item:GetAttribute("StaconfStyled") then
        item:SetAttribute("StaconfStyled", true)
        self:_connect(item:GetPropertyChangedSignal("BackgroundTransparency"), refresh)
    end
    refresh()
end

function Staconf:_installShell(options)
    if self._shell then return true end
    local structures = self.Window.Structures
    local body = raw(structures.Body)
    local sidebar = raw(structures.SidebarMargins)
    local margins = raw(structures.Sidebar)
    local content = raw(structures.ContentBody)
    local page = raw(structures.Content)
    local list = raw(structures.SidebarList)
    local ignore = raw(structures.LayoutIgnore)
    local search = structures.Titlebar and structures.Titlebar.SearchField
    local searchBody = search and raw(search.Body)
    if not (body and sidebar and margins and content and page and list and ignore and searchBody) then return false end

    local surface = Instance.new("CanvasGroup")
    surface.Name = "ChromeSurface"
    surface.Size = UDim2.fromScale(1, 1)
    surface.BackgroundTransparency = 1
    surface.BorderSizePixel = 0
    surface.ClipsDescendants = false
    surface.Parent = ignore
    round(surface, 22)
    local surfaceScale = Instance.new("UIScale")
    surfaceScale.Name = "ResponsiveChromeScale"
    surfaceScale.Parent = surface
    local layout = body:FindFirstChildOfClass("UIListLayout")
    if layout then layout.Parent = surface end
    sidebar.Parent = surface
    content.Parent = surface
    local separator = raw(structures.Separator)
    if separator then separator.Parent = surface; separator.Visible = false end
    body.BackgroundTransparency = 1

    searchBody.Name = "SidebarSearch"
    searchBody.Parent = margins
    searchBody.AutomaticSize = Enum.AutomaticSize.None
    searchBody.Position = UDim2.fromOffset(12, 52)
    searchBody.Size = UDim2.new(1, -24, 0, UserInputService.TouchEnabled and 44 or 32)
    local searchCorner = searchBody:FindFirstChildOfClass("UICorner")
    if searchCorner then searchCorner.CornerRadius = UDim.new(0, 24) end
    local searchField = raw(search.Field)
    if searchField then searchField.Size = UDim2.new(1, -28, 1, 0); searchField.TextSize = 14 end
    local searchLayout = searchBody:FindFirstChildOfClass("UIListLayout")
    if searchLayout then searchLayout.Padding = UDim.new(0, 6); searchLayout.VerticalAlignment = Enum.VerticalAlignment.Center end
    local searchPadding = searchBody:FindFirstChildOfClass("UIPadding")
    if searchPadding then
        searchPadding.PaddingLeft = UDim.new(0, 10)
        searchPadding.PaddingRight = UDim.new(0, 10)
    end

    local profile = Instance.new("TextButton")
    profile.Name = "ProfilePanel"
    profile.Position = UDim2.fromOffset(12, UserInputService.TouchEnabled and 104 or 94)
    profile.Size = UDim2.new(1, -24, 0, 56)
    profile.BackgroundTransparency = 1
    profile.BorderSizePixel = 0
    profile.AutoButtonColor = false
    profile.Text = ""
    profile.Parent = margins
    round(profile, 10)
    local avatar = Instance.new("ImageLabel")
    avatar.Name = "Avatar"
    avatar.Position = UDim2.fromOffset(6, 11)
    avatar.Size = UDim2.fromOffset(34, 34)
    avatar.BackgroundTransparency = 1
    local player = game:GetService("Players").LocalPlayer
    avatar.Image = player and ("rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150") or ""
    avatar.Parent = profile
    round(avatar, 17)
    local function profileText(name, value, y, size)
        local label = Instance.new("TextLabel")
        label.Name = name
        label.Position = UDim2.fromOffset(50, y)
        label.Size = UDim2.new(1, -54, 0, 20)
        label.BackgroundTransparency = 1
        label.Font = name == "Title" and Enum.Font.GothamBold or Enum.Font.Gotham
        label.TextSize = size
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.Text = value
        label.Parent = profile
        return label
    end
    local title = profileText("Title", options.ProfileTitle or (player and player.DisplayName) or "Guest", 7, 15)
    local subtitle = profileText("Subtitle", options.ProfileSubtitle or (player and ("@" .. player.Name)) or "Profile", 27, 11)
    profile.Active = type(options.OnProfile) == "function"
    if profile.Active then self:_connect(profile.Activated, options.OnProfile) end
    self:_connect(profile.MouseEnter, function()
        if profile.Active then profile.BackgroundTransparency = 0.94 end
    end)
    self:_connect(profile.MouseLeave, function() profile.BackgroundTransparency = 1 end)

    local function align()
        if self._destroyed or not body.Parent then return end
        local size = body.AbsoluteSize
        if size.X < 1 or size.Y < 1 then return end
        local scale = UserInputService.TouchEnabled and 1 or math.clamp(math.min(size.X / 800, size.Y / 520), 0.8, 1)
        local logicalWidth, logicalHeight = size.X / scale, size.Y / scale
        surfaceScale.Scale = scale
        local sidebarWidth = math.clamp(math.floor(logicalWidth * 0.34), 150, 230)
        sidebar.Size = UDim2.fromOffset(sidebarWidth, logicalHeight)
        margins.Size = UDim2.fromOffset(sidebarWidth, logicalHeight)
        content.Size = UDim2.fromOffset(math.max(0, logicalWidth - sidebarWidth), logicalHeight)
        page.Size = UDim2.new(1, 0, 1, -52)
        list.Position = UDim2.fromOffset(0, UserInputService.TouchEnabled and 168 or 158)
        list.Size = UDim2.new(1, 0, 1, -(UserInputService.TouchEnabled and 176 or 166))
        surface.Size = UDim2.fromOffset(logicalWidth, logicalHeight)
    end
    self._shell = {Surface = surface, Sidebar = sidebar, Content = content, Search = searchBody,
        Profile = profile, ProfileTitle = title, ProfileSubtitle = subtitle}
    self:_connect(body:GetPropertyChangedSignal("AbsoluteSize"), align)
    task.defer(align)
    return true
end

function Staconf:InstallChrome(options)
    options = options or {}
    if self._destroyed then return end
    self._chromeOptions = options
    local installed = self:_installShell(options)
    if not installed and not self._shell then warn("Staconf: Cascade shell structure unavailable") end
    self:_applyChrome()
    self:ApplyFont()
    if self._chromeInstalled then
        if options.Tooltips then self:AttachTooltips(options.Tooltips) end
        return self
    end
    self._chromeInstalled = true
    local root = self.App.__instance
    for _, object in ipairs(root:GetDescendants()) do
        if object.Name == "SidebarItem" then self:_styleSidebarItem(object) end
        self:_styleVisual(object)
    end
    self:_connect(root.DescendantAdded, function(object)
        if object.Name == "SidebarItem" then task.defer(function() self:_styleSidebarItem(object) end) end
        self:_applyFont(object)
        task.defer(function() if object.Parent and not self._destroyed then self:_styleVisual(object) end end)
    end)
    self:_installVerticalScroll()
    if options.Tooltips then self:AttachTooltips(options.Tooltips) end
    return self
end

function Staconf:_styleVisual(object)
    if not object or not object.Parent then return end
    if object:IsA("UICorner") then
        local name = object.Parent.Name
        if name == "Body" then object.CornerRadius = UDim.new(0, 22)
        elseif name == "ContentBody" or name == "Toolbar" or name == "Sidebar" then
            object.CornerRadius = UDim.new(0, 0)
        elseif name == "SidebarItem" then object.CornerRadius = UDim.new(0, 8) end
    elseif object:IsA("ScrollingFrame") and
        (object.Name == "ContentList" or object.Name == "SidebarList" or object.Name == "SidebarSearchResults") then
        object.ScrollingDirection = Enum.ScrollingDirection.Y
    elseif object.Name == "Disclosure" or object.Name == "SectionHeader" then
        if object:IsA("GuiObject") then object.Visible = false end
    elseif object.Name == "Toggle" and object:IsA("Frame") then
        object.Size = UDim2.fromOffset(38, 22)
        local switch = object:FindFirstChild("Switch")
        if switch and switch:IsA("GuiObject") then switch.Size = UDim2.fromOffset(38, 22) end
    elseif object.Name == "Slider" and object:IsA("ImageLabel") then
        object.Size = UDim2.fromOffset(150, 7)
        local corner = object:FindFirstChildOfClass("UICorner")
        if corner then corner.CornerRadius = UDim.new(0, 4) end
    elseif object.Name == "Toolbar" and object:IsA("Frame") then
        local shadow = object:FindFirstChild("Shadow")
        if shadow then shadow.Visible = false end
    elseif object.Name == "Separator" and object:IsA("GuiObject") then
        object.Visible = false
    end
end

function Staconf:_installVerticalScroll()
    if self._scrollInstalled then return end
    self._scrollInstalled = true
    self:_connect(UserInputService.InputChanged, function(input)
        if self._destroyed or not self.App.__instance.Enabled or input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
        if not (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) then return end
        local cursor = UserInputService:GetMouseLocation()
        local best, area = nil, math.huge
        for _, object in ipairs(self.App.__instance:GetDescendants()) do
            if object:IsA("ScrollingFrame") and object.ScrollingEnabled and object.Visible and
                (object.Name == "ContentList" or object.Name == "SidebarList" or object.Name == "SidebarSearchResults") then
                local p, s = object.AbsolutePosition, object.AbsoluteSize
                if cursor.X >= p.X and cursor.X <= p.X + s.X and cursor.Y >= p.Y and cursor.Y <= p.Y + s.Y then
                    local size = s.X * s.Y
                    if size < area then best, area = object, size end
                end
            end
        end
        if not best then return end
        local before = best.CanvasPosition.Y
        task.delay(0.05, function()
            if self._destroyed or not best.Parent or not self.App.__instance.Enabled then return end
            if math.abs(best.CanvasPosition.Y - before) >= 0.5 then return end
            local maxY = math.max(0, best.AbsoluteCanvasSize.Y - best.AbsoluteWindowSize.Y)
            best.CanvasPosition = Vector2.new(best.CanvasPosition.X, math.clamp(before - input.Position.Z * 48, 0, maxY))
        end)
    end)
end

-- Mirrors the Cascade sidebar's nested section navigation. The host supplies
-- section labels, so the library never needs game-specific tab definitions.
function Staconf:CreateSidebarSections(tab, sections)
    sections = sections or {}
    local item = raw(tab and tab.Structures and tab.Structures.Body)
    local list = raw(self.Window.Structures.SidebarList)
    if not item or not list then return nil end
    local container = Instance.new("Frame")
    container.Name = "SubTabs"
    container.Size = UDim2.new(1, 0, 0, #sections * 28 + 8)
    container.BackgroundTransparency = 1
    container.LayoutOrder = item.LayoutOrder + 1
    container.Parent = list
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 16)
    padding.PaddingRight = UDim.new(0, 4)
    padding.PaddingTop = UDim.new(0, 4)
    padding.Parent = container
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = container
    local buttons = {}
    local function selectButton(selected)
        for _, button in ipairs(buttons) do
            local active = button == selected
            button.BackgroundTransparency = active and 0.6 or 1
            button.BackgroundColor3 = self.Mode == "Light" and Color3.fromRGB(216, 218, 224) or Color3.fromRGB(50, 54, 68)
            button.Title.TextColor3 = active and (self.Mode == "Light" and Color3.fromRGB(24, 26, 32) or Color3.new(1, 1, 1))
                or (self.Mode == "Light" and Color3.fromRGB(108, 113, 125) or Color3.fromRGB(160, 165, 180))
            button.Indicator.BackgroundColor3 = active and self._accentColor or Color3.fromRGB(100, 105, 120)
        end
    end
    for index, definition in ipairs(sections or {}) do
        local label = type(definition) == "table" and (definition.Label or definition.Title) or tostring(definition)
        local target = type(definition) == "table" and (definition.Target or label) or label
        local button = Instance.new("TextButton")
        button.Name = "SubTabItem"
        button.LayoutOrder = index
        button.Size = UDim2.new(1, 0, 0, 26)
        button.BackgroundTransparency = 1
        button.BorderSizePixel = 0
        button.Text = ""
        button.AutoButtonColor = false
        button.Parent = container
        round(button, 6)
        local indicator = Instance.new("Frame")
        indicator.Name = "Indicator"
        indicator.AnchorPoint = Vector2.new(0.5, 0.5)
        indicator.Position = UDim2.new(0, 15, 0.5, 0)
        indicator.Size = UDim2.fromOffset(5, 5)
        indicator.BorderSizePixel = 0
        indicator.Parent = button
        round(indicator, 5)
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Position = UDim2.new(0, 26, 0, 0)
        title.Size = UDim2.new(1, -30, 1, 0)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamMedium
        title.TextSize = 13
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = tostring(label or target)
        title.Parent = button
        table.insert(buttons, button)
        self:_connect(button.Activated, function()
            selectButton(button)
            for _, object in ipairs(self.App.__instance:GetDescendants()) do
                if object:IsA("ScrollingFrame") and object.Name == "ContentList" and object.Visible then
                    for _, section in ipairs(object:GetChildren()) do
                        local heading = section.Name == "PageSection" and section:FindFirstChild("Title", true)
                        if heading and heading:IsA("TextLabel") and heading.Text == target then
                            local offset = section.AbsolutePosition.Y - object.AbsolutePosition.Y + object.CanvasPosition.Y
                            local maxY = math.max(0, object.AbsoluteCanvasSize.Y - object.AbsoluteWindowSize.Y)
                            TweenService:Create(object, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                {CanvasPosition = Vector2.new(0, math.clamp(offset - 8, 0, maxY))}):Play()
                            return
                        end
                    end
                end
            end
        end)
    end
    selectButton(buttons[1])
    return {Root = container, Buttons = buttons}
end

-- Creates a reusable Cascade-style segmented sub-tab strip. Content and state
-- remain owned by the caller; this helper only manages selection visuals.
function Staconf:CreateSubTabs(parent, options)
    options = options or {}
    if self._destroyed then return nil end
    local host = raw(parent) or parent
    if not host or not host:IsA("GuiObject") then return nil end
    local root = Instance.new("Frame")
    root.Name = options.Name or "SubTabs"
    root.Size = options.Size or UDim2.new(1, 0, 0, UserInputService.TouchEnabled and 42 or 36)
    root.BackgroundTransparency = 1
    root.Parent = host
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, options.Padding or 2)
    padding.PaddingRight = UDim.new(0, options.Padding or 2)
    padding.Parent = root
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 6)
    layout.Parent = root
    local entries = {}
    local selected = options.Selected or 1
    local accent = self._accentColor
    local function paint(index)
        selected = index
        for i, entry in ipairs(entries) do
            local active = i == selected
            entry.Button.BackgroundColor3 = active and accent or
                (self.Mode == "Light" and Color3.fromRGB(235, 238, 244) or Color3.fromRGB(37, 40, 50))
            entry.Button.TextColor3 = active and Color3.new(1, 1, 1) or
                (self.Mode == "Light" and Color3.fromRGB(77, 82, 96) or Color3.fromRGB(205, 209, 220))
        end
        if options.OnSelected then options.OnSelected(selected, entries[selected] and entries[selected].Value) end
    end
    for index, value in ipairs(options.Items or {}) do
        local item = type(value) == "table" and value or {Title = tostring(value), Value = value}
        local button = Instance.new("TextButton")
        button.Name = "SubTab"
        button.LayoutOrder = index
        button.Size = UDim2.new(0, item.Width or 112, 1, 0)
        button.AutoButtonColor = false
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamMedium
        button.TextSize = UserInputService.TouchEnabled and 12 or 13
        button.Text = tostring(item.Title or item.Label or item.Value or index)
        button.Parent = root
        round(button, 9)
        local entry = {Button = button, Value = item.Value or item.Title}
        table.insert(entries, entry)
        self:_connect(button.Activated, function()
            paint(index)
            if item.OnSelected then item.OnSelected(entry.Value, index) end
        end)
    end
    paint(math.clamp(selected, 1, math.max(1, #entries)))
    return {
        Root = root,
        Items = entries,
        Select = function(_, index) if entries[index] then paint(index) end end,
        Destroy = function() if root.Parent then root:Destroy() end end,
    }
end

-- Applies the shared liquid-glass fallback without requiring EditableMesh or
-- a private renderer. Callers can replace this with their own renderer later.
function Staconf:CreateGlass(target, options)
    options = options or {}
    local object = raw(target) or target
    if not object or not object:IsA("GuiObject") then return nil end
    local corner = object:FindFirstChild("StaconfGlassCorner") or Instance.new("UICorner")
    corner.Name = "StaconfGlassCorner"
    corner.CornerRadius = UDim.new(0, options.Radius or 18)
    corner.Parent = object
    local stroke = object:FindFirstChild("StaconfGlassStroke") or Instance.new("UIStroke")
    stroke.Name = "StaconfGlassStroke"
    stroke.Color = options.StrokeColor or Color3.fromRGB(255, 255, 255)
    stroke.Transparency = options.StrokeTransparency or 0.78
    stroke.Thickness = options.StrokeThickness or 1
    stroke.Parent = object
    if options.Color then object.BackgroundColor3 = options.Color end
    if options.Transparency ~= nil then object.BackgroundTransparency = options.Transparency end
    return {Object = object, Corner = corner, Stroke = stroke}
end

function Staconf:AddTabIntroduction(tab, options)
    options = options or {}
    local body = raw(tab and tab.Structures and tab.Structures.Body)
    if not body then return nil end
    local card = Instance.new("Frame")
    card.Name = options.Name or "TabIntroduction"
    card.Size = UDim2.new(1, 0, 0, options.Height or 86)
    card.BackgroundColor3 = self.Mode == "Light" and Color3.fromRGB(239, 242, 247) or Color3.fromRGB(31, 34, 44)
    card.BorderSizePixel = 0
    card.LayoutOrder = options.LayoutOrder or -100
    card.Parent = body
    self:CreateGlass(card, {Radius = 16, StrokeTransparency = 0.86})
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(18, 13)
    title.Size = UDim2.new(1, -36, 0, 24)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = self.Mode == "Light" and Color3.fromRGB(28, 31, 40) or Color3.fromRGB(245, 247, 252)
    title.Text = tostring(options.Title or self.Title)
    title.Parent = card
    local description = Instance.new("TextLabel")
    description.BackgroundTransparency = 1
    description.Position = UDim2.fromOffset(18, 40)
    description.Size = UDim2.new(1, -36, 0, 32)
    description.Font = Enum.Font.Gotham
    description.TextSize = 13
    description.TextWrapped = true
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextColor3 = self.Mode == "Light" and Color3.fromRGB(83, 88, 101) or Color3.fromRGB(190, 195, 208)
    description.Text = tostring(options.Description or "")
    description.Parent = card
    return card
end

-- Keeps update callbacks available to the host while intentionally exposing a
-- neutral unavailable page in the general-purpose library.
function Staconf:BuildUpdateTab(options)
    options = options or {}
    self._updateMechanic = {Check = options.Check, Apply = options.Apply, Version = options.Version}
    local tab = self:AddTab({Title = options.Title or "Client Update", Icon = options.Icon, Selected = options.Selected})
    local section = tab:PageSection({Title = options.SectionTitle or "Updates"}):Form()
    local row = self:Row(section, {Title = "Client Update"})
    row:Left():TitleStack({Title = "Client Update", Subtitle = "Unavailable"})
    row:Right():Button({Label = "Unavailable", State = "Secondary"})
    return tab
end

function Staconf:Row(section, options)
    options = options or {}
    return section:Row({SearchIndex = options.Title or options.SearchIndex or ""})
end

local function titledControl(self, section, options, kind, properties)
    local row = self:Row(section, options)
    row:Left():TitleStack({Title = options.Title or kind, Subtitle = options.Subtitle})
    local accessory = row:Right()
    return accessory[kind](accessory, properties), row
end

function Staconf:Toggle(section, options)
    options = options or {}
    return titledControl(self, section, options, "Toggle", {Value = options.Value == true,
        ValueChanged = function(_, value) if options.OnChange then options.OnChange(value) end end})
end

function Staconf:Slider(section, options)
    options = options or {}
    return titledControl(self, section, options, "Slider", {Minimum = options.Minimum or 0,
        Maximum = options.Maximum or 100, Value = options.Value or options.Minimum or 0,
        ValueChanged = function(_, value) if options.OnChange then options.OnChange(value) end end})
end

function Staconf:Dropdown(section, options)
    options = options or {}
    return titledControl(self, section, options, "PopUpButton", {Options = options.Options or {},
        Value = options.Value or 1, ValueChanged = function(_, value)
            local selected = type(value) == "table" and (value.Value or value.Name or value.Label) or value
            local resolved = type(selected) == "number" and options.Options and options.Options[selected] or selected
            if options.OnChange then options.OnChange(resolved or selected) end
        end})
end

function Staconf:TextField(section, options)
    options = options or {}
    return titledControl(self, section, options, "TextField", {Value = options.Value or "",
        Placeholder = options.Placeholder or "", ValueChanged = function(_, value)
            if options.OnChange then options.OnChange(value) end
        end})
end

function Staconf:Keybind(section, options)
    options = options or {}
    return titledControl(self, section, options, "KeybindField", {Value = options.Value or Enum.KeyCode.None,
        ValueChanged = function(_, value) if options.OnChange then options.OnChange(value) end end})
end

function Staconf:Button(section, options)
    options = options or {}
    local row = self:Row(section, options)
    row:Left():TitleStack({Title = options.Title or "Button", Subtitle = options.Subtitle})
    return row:Right():Button({Label = options.Title or "Button", State = options.Style or "Secondary",
        Pushed = function() if options.OnClick then options.OnClick() end end}), row
end

function Staconf.new(options)
    options = options or {}
    local cascade = options.Cascade
    if not cascade then
        cascade = assert(loadstring(game:HttpGetAsync(options.CascadeUrl or CASCADE_URL)))()
    end
    local self = setmetatable({}, Staconf)
    self.Cascade = cascade
    self.Title = options.Title or "StacOnf"
    self.Name = options.Name or "StacOnf"
    self.Mode = options.Theme == "Light" and "Light" or "Dark"
    self.CacheRoot = options.CacheRoot or "Staconf"
    self.AssetBaseUrl = options.AssetBaseUrl or ASSET_URL
    self.BootImage = options.BootImage
    self.BootImageFile = options.BootImageFile
    self.BootSoundId = options.BootSoundId
    self.BootSoundVolume = options.BootSoundVolume or 1
    self.ProgressColor = options.ProgressColor or Color3.fromRGB(245, 245, 247)
    self._connections = {}
    self._dialogs = {}
    self._onDestroy = options.OnDestroy
    local accent = cascade.Accents[options.Accent] and options.Accent or "Blue"
    self._accentName = accent
    self._accentColor = cascade.Accents[accent][self.Mode].Selection
    self.App = cascade.New({WindowPill = options.WindowPill ~= false,
        Theme = cascade.Themes[self.Mode], Accent = cascade.Accents[accent]})
    self.App.__instance.Name = self.Name
    if UserInputService.TouchEnabled then
        pcall(function() self.App.__instance.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets end)
    end
    self.Window = self.App:Window({Title = self.Title, Subtitle = options.Subtitle or "",
        Size = windowSize(self.App.__instance, options.Size), Searching = options.Searching ~= false,
        Draggable = options.Draggable ~= false and not UserInputService.TouchEnabled,
        Resizable = options.Resizable ~= false and not UserInputService.TouchEnabled,
        CanExit = options.CanExit ~= false, CanMinimize = options.CanMinimize ~= false,
        CanZoom = options.CanZoom ~= false and not UserInputService.TouchEnabled,
        Dropshadow = options.Dropshadow ~= false, UIBlur = options.UIBlur ~= false})
    self._blurWanted = options.UIBlur ~= false
    self._chromeEnabled = options.Chrome ~= false
    if self._chromeEnabled then self:InstallChrome(options.ChromeOptions or {}) end
    self.App.__instance.Destroying:Connect(function()
        if not self._destroyed then
            self._destroyed = true
            if self._bootSound then self._bootSound:Destroy(); self._bootSound = nil end
            if self._boot and self._boot.Overlay.Parent then self._boot.Overlay:Destroy() end
            if self._noticeGui then self._noticeGui:Destroy() end
            for _, dialog in ipairs(self._dialogs) do if dialog.Parent then dialog:Destroy() end end
            if self._onDestroy then pcall(self._onDestroy, self) end
        end
    end)
    if options.Boot ~= false then self:ShowBoot() end
    return self
end

return Staconf
