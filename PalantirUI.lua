-- ============================================================
-- PalantirX UI Library (Standalone) – исправленная версия
-- ============================================================

local PalantirUI = {}
PalantirUI.__index = PalantirUI

local function GetTextBounds(text, font, size, maxWidth)
    local textService = game:GetService("TextService")
    local bounds = textService:GetTextSize(text, size, font, Vector2.new(maxWidth or 1920, math.huge))
    return bounds.X, bounds.Y
end

local function createScreenGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "PalantirUI_Gui"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    -- Защита GUI
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui) end
        if protectgui then protectgui(gui) end
    end)
    gui.Parent = game:GetService("CoreGui")
    return gui
end

local Library = {
    ScreenGui = nil,
    Registry = {},
    RegistryMap = {},
    Font = Font.fromEnum(Enum.Font.Gotham),
    FontColor = Color3.fromRGB(220, 220, 220),
    MainColor = Color3.fromRGB(18, 18, 18),
    BackgroundColor = Color3.fromRGB(10, 10, 10),
    AccentColor = Color3.fromRGB(255, 255, 255),
    OutlineColor = Color3.fromRGB(45, 45, 45),
    RiskColor = Color3.fromRGB(255, 65, 65),
    UnsafeColor = Color3.fromRGB(240, 200, 50),
    SelfClipColor = Color3.fromRGB(180, 60, 220),
    Black = Color3.new(0, 0, 0),
    NotifSoundId = "rbxassetid://4590657391",
    NotifSoundVolume = 0.5,
    ClickSoundId = "rbxassetid://6895079853",
    ClickSoundVolume = 0.3,
    TypeSoundId = "rbxassetid://9114221726",
    TypeSoundVolume = 0.15,
    OpenedFrames = {},
    DependencyBoxes = {},
    Signals = {},
    _RiskToggles = {},
    ToggleKeybind = nil,
    ColorClipboard = nil,
}

function Library:PlayNotifSound()
    if not self._sound then
        self._sound = Instance.new("Sound")
        self._sound.SoundId = self.NotifSoundId
        self._sound.Volume = self.NotifSoundVolume
        self._sound.Parent = game:GetService("SoundService")
    end
    self._sound:Play()
end

function Library:PlayClickSound()
    if not self._clickSound then
        self._clickSound = Instance.new("Sound")
        self._clickSound.SoundId = self.ClickSoundId
        self._clickSound.Volume = self.ClickSoundVolume
        self._clickSound.Parent = game:GetService("SoundService")
    end
    self._clickSound:Play()
end

function Library:PlayTypeSound()
    if not self._typeSound then
        self._typeSound = Instance.new("Sound")
        self._typeSound.SoundId = self.TypeSoundId
        self._typeSound.Volume = self.TypeSoundVolume
        self._typeSound.Parent = game:GetService("SoundService")
    end
    self._typeSound:Play()
end

function Library:Create(obj, properties)
    if type(obj) == "string" then
        obj = Instance.new(obj)
    end
    for key, value in pairs(properties) do
        obj[key] = value
    end
    return obj
end

function Library:AddToRegistry(instance, properties, hud)
    local entry = { Instance = instance, Properties = properties }
    table.insert(self.Registry, entry)
    self.RegistryMap[instance] = entry
    return entry
end

function Library:UpdateColors()
    for _, entry in ipairs(self.Registry) do
        local inst = entry.Instance
        local props = entry.Properties
        for key, val in pairs(props) do
            if type(val) == "string" then
                inst[key] = self[val]
            elseif type(val) == "function" then
                inst[key] = val()
            end
        end
    end
end

function Library:CreateLabel(properties, hud)
    local label = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = self.Font,
        TextColor3 = self.FontColor,
        TextSize = 16,
        TextStrokeTransparency = 1,
    })
    for key, val in pairs(properties) do
        label[key] = val
    end
    self:AddToRegistry(label, { TextColor3 = "FontColor" }, hud)
    return label
end

function Library:AddGradient(instance, rotation)
    local grad = Instance.new("UIGradient")
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 0.15)
    })
    grad.Rotation = rotation or 90
    grad.Parent = instance
    return grad
end

function Library:MakeDraggable(frame, headerHeight)
    headerHeight = headerHeight or 0
    local dragging = false
    local dragStart, startPos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if headerHeight > 0 then
                local mousePos = input.Position
                local absPos = frame.AbsolutePosition
                if mousePos.Y - absPos.Y <= headerHeight then
                    dragging = true
                    dragStart = input.Position
                    startPos = frame.Position
                end
            else
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
            end
        end
    end)

    frame.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

function Library:Notify(text, duration, level)
    if shared and shared.Palantir and shared.Palantir.silent then return end
    duration = duration or 3
    level = level or "info"
    local colors = {
        info = self.AccentColor,
        warning = Color3.fromRGB(230, 185, 50),
        error = Color3.fromRGB(220, 60, 60),
        success = Color3.fromRGB(80, 220, 120)
    }
    local color = colors[level] or self.AccentColor

    if not self.NotificationArea then
        self.NotificationArea = self:Create("Frame", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0, 16, 0, 16),
            Size = UDim2.new(0, 260, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 100,
            Parent = self.ScreenGui
        })
        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 6)
        layout.Parent = self.NotificationArea
    end

    local container = self:Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        ZIndex = 100,
        Parent = self.NotificationArea
    })

    local inner = self:Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderSizePixel = 0,
        Position = UDim2.new(-1, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        ClipsDescendants = true,
        ZIndex = 100,
        Parent = container
    })

    Instance.new("UICorner").Parent = inner
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(40, 40, 40)
    stroke.Thickness = 1
    stroke.Parent = inner

    local leftBar = self:Create("Frame", {
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, 0),
        ZIndex = 105,
        Parent = inner
    })
    Instance.new("UICorner").Parent = leftBar

    local label = self:CreateLabel({
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -18, 1, -3),
        Text = text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        ZIndex = 103,
        Parent = inner
    })

    local tween = game:GetService("TweenService")
    local appear = tween:Create(inner, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    })
    appear:Play()

    self:PlayNotifSound()

    local progress = self:Create("Frame", {
        BackgroundColor3 = color,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 2),
        ZIndex = 104,
        Parent = inner
    })

    task.spawn(function()
        task.wait(duration)
        local disappear = tween:Create(inner, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(-1, 0, 0, 0)
        })
        disappear:Play()
        task.wait(0.3)
        container:Destroy()
    end)

    inner.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            container:Destroy()
        end
    end)
end

function Library:CreateWindow(settings)
    settings = settings or {}
    local title = settings.Title or "Window"
    local size = settings.Size or UDim2.fromOffset(680, 620)
    local pos = settings.Position or UDim2.fromOffset(175, 50)
    if settings.Center then
        pos = UDim2.fromScale(0.5, 0.5)
        settings.AnchorPoint = Vector2.new(0.5, 0.5)
    end

    if not self.ScreenGui then
        self.ScreenGui = createScreenGui()
    end

    local window = self:Create("Frame", {
        AnchorPoint = settings.AnchorPoint,
        BackgroundColor3 = self.MainColor,
        BorderSizePixel = 0,
        Position = pos,
        Size = size,
        Visible = false,
        ZIndex = 1,
        Parent = self.ScreenGui
    })
    self:AddToRegistry(window, { BackgroundColor3 = "MainColor" })

    local stroke = Instance.new("UIStroke")
    stroke.Color = self.OutlineColor
    stroke.Thickness = 2
    stroke.Parent = window
    self:AddToRegistry(stroke, { Color = "OutlineColor" })

    self:AddGradient(window)

    local titleBar = self:Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 36),
        ZIndex = 3,
        Parent = window
    })
    self:AddToRegistry(titleBar, { BackgroundColor3 = "MainColor" })

    local accentLine = self:Create("Frame", {
        BackgroundColor3 = self.AccentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, 0),
        ZIndex = 5,
        Parent = titleBar
    })
    self:AddToRegistry(accentLine, { BackgroundColor3 = "AccentColor" })

    local titleLabel = self:CreateLabel({
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -28, 1, 0),
        Text = title,
        TextSize = 15,
        RichText = true,
        TextColor3 = Color3.new(1, 1, 1),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
        Parent = titleBar
    })
    self:AddToRegistry(titleLabel, { TextColor3 = "AccentColor" })

    self:MakeDraggable(window, 36)

    local mainContainer = self:Create("Frame", {
        BackgroundColor3 = self.MainColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 36),
        Size = UDim2.new(1, 0, 1, -36),
        ZIndex = 1,
        Parent = window
    })
    self:AddToRegistry(mainContainer, { BackgroundColor3 = "MainColor" })

    local tabHeader = self:Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 2),
        Size = UDim2.new(1, -16, 0, 28),
        ZIndex = 1,
        Parent = mainContainer
    })

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 0)
    tabLayout.Parent = tabHeader

    local tabIndicator = self:Create("Frame", {
        BackgroundColor3 = self.AccentColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, 28),
        Size = UDim2.new(0, 0, 0, 2),
        ZIndex = 5,
        Parent = mainContainer
    })
    self:AddToRegistry(tabIndicator, { BackgroundColor3 = "AccentColor" })

    local contentArea = self:Create("Frame", {
        BackgroundColor3 = self.BackgroundColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, 32),
        Size = UDim2.new(1, -16, 1, -38),
        ZIndex = 2,
        Parent = mainContainer
    })
    self:AddToRegistry(contentArea, { BackgroundColor3 = "BackgroundColor" })
    self:AddGradient(contentArea)

    local windowObj = {
        Tabs = {},
        Holder = window,
        Content = contentArea,
        TabHeader = tabHeader,
        TabIndicator = tabIndicator,
        TitleLabel = titleLabel,
        _visible = false,
        SetWindowTitle = function(self, newTitle)
            titleLabel.Text = newTitle
        end,
        Toggle = function(self)
            self._visible = not self._visible
            window.Visible = self._visible
            -- Если окно скрыто, закрываем все открытые выпадающие списки и т.д.
            if not self._visible then
                for frame, _ in pairs(self.OpenedFrames) do
                    if frame and frame.Visible then
                        frame.Visible = false
                    end
                end
                self.OpenedFrames = {}
            end
        end,
        Show = function(self)
            self._visible = true
            window.Visible = true
        end,
        Hide = function(self)
            self._visible = false
            window.Visible = false
            for frame, _ in pairs(self.OpenedFrames) do
                if frame and frame.Visible then
                    frame.Visible = false
                end
            end
            self.OpenedFrames = {}
        end,
        AddTab = function(self, name)
            local tabButton = self:Create("Frame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1 / (#self.Tabs + 1), 0, 1, 0),
                ZIndex = 1,
                Parent = tabHeader
            })
            table.insert(self.Tabs, tabButton)
            for i, btn in ipairs(self.Tabs) do
                btn.Size = UDim2.new(1 / #self.Tabs, 0, 1, 0)
            end

            local label = self:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0),
                Text = name,
                TextSize = 14,
                ZIndex = 1,
                Parent = tabButton
            })

            local tabContent = self:Create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 1, 0),
                Visible = false,
                ZIndex = 2,
                Parent = contentArea
            })

            local leftCol = self:Create("ScrollingFrame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 7, 0, 7),
                Size = UDim2.new(0.5, -10, 1, -14),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 0,
                ZIndex = 2,
                Parent = tabContent
            })
            local rightCol = self:Create("ScrollingFrame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0.5, 5, 0, 7),
                Size = UDim2.new(0.5, -10, 1, -14),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 0,
                ZIndex = 2,
                Parent = tabContent
            })

            for _, col in ipairs({leftCol, rightCol}) do
                local layout = col:FindFirstChildOfClass("UIListLayout") or Instance.new("UIListLayout")
                layout.Padding = UDim.new(0, 8)
                layout.FillDirection = Enum.FillDirection.Vertical
                layout.SortOrder = Enum.SortOrder.LayoutOrder
                layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                layout.Parent = col
                layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    col.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y)
                end)
            end

            local tabObj = {
                Name = name,
                TabButton = tabButton,
                TabButtonLabel = label,
                TabFrame = tabContent,
                LeftCol = leftCol,
                RightCol = rightCol,
                Groupboxes = {},
                Tabboxes = {},
                GroupboxCount = 0,
                TabboxCount = 0,
                ShowTab = function(self)
                    for _, t in pairs(windowObj.Tabs) do
                        if t ~= tabObj then t:HideTab() end
                    end
                    label.TextColor3 = Library.AccentColor
                    Library:AddToRegistry(label, { TextColor3 = "AccentColor" })
                    tabContent.Visible = true
                    local btnPos = tabButton.AbsolutePosition.X
                    local headerPos = tabHeader.AbsolutePosition.X
                    local btnSize = tabButton.AbsoluteSize.X
                    tabIndicator.Position = UDim2.new(0, 8 + (btnPos - headerPos), 0, 28)
                    tabIndicator.Size = UDim2.new(0, btnSize, 0, 2)
                end,
                HideTab = function(self)
                    label.TextColor3 = Library.FontColor
                    Library:AddToRegistry(label, { TextColor3 = "FontColor" })
                    tabContent.Visible = false
                end,
                AddLeftGroupbox = function(self, name)
                    return self:AddGroupbox(name, 1)
                end,
                AddRightGroupbox = function(self, name)
                    return self:AddGroupbox(name, 2)
                end,
                AddDynamicGroupbox = function(self, name)
                    if (self.GroupboxCount % 2) == 0 then
                        return self:AddLeftGroupbox(name)
                    else
                        return self:AddRightGroupbox(name)
                    end
                end,
                AddGroupbox = function(self, name, side)
                    side = side or 1
                    local col = side == 1 and leftCol or rightCol
                    local box = self:Create("Frame", {
                        BackgroundColor3 = Library.MainColor,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, 28),
                        ZIndex = 2,
                        Parent = col
                    })
                    Library:AddToRegistry(box, { BackgroundColor3 = "MainColor" })
                    local strokeBox = Instance.new("UIStroke")
                    strokeBox.Color = Library.OutlineColor
                    strokeBox.Thickness = 1
                    strokeBox.Parent = box
                    Library:AddToRegistry(strokeBox, { Color = "OutlineColor" })
                    Library:AddGradient(box)

                    local titleLabel2 = Library:CreateLabel({
                        Size = UDim2.new(1, 0, 0, 24),
                        Position = UDim2.new(0, 8, 0, 0),
                        Text = name,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 5,
                        Parent = box
                    })
                    Library:AddToRegistry(titleLabel2, { TextColor3 = "AccentColor" })
                    titleLabel2.TextColor3 = Library.AccentColor

                    local line = self:Create("Frame", {
                        BackgroundColor3 = Color3.fromRGB(45, 45, 45),
                        BorderSizePixel = 0,
                        Position = UDim2.new(0, 4, 0, 23),
                        Size = UDim2.new(1, -8, 0, 1),
                        ZIndex = 5,
                        Parent = box
                    })

                    local content = self:Create("Frame", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 6, 0, 24),
                        Size = UDim2.new(1, -8, 1, -24),
                        ZIndex = 1,
                        Parent = box
                    })

                    local layoutBox = Instance.new("UIListLayout")
                    layoutBox.FillDirection = Enum.FillDirection.Vertical
                    layoutBox.SortOrder = Enum.SortOrder.LayoutOrder
                    layoutBox.Parent = content

                    local groupObj = {
                        Container = content,
                        BoxFrame = box,
                        Resize = function(self)
                            local height = 0
                            for _, child in ipairs(content:GetChildren()) do
                                if child:IsA("Frame") and child.Visible then
                                    height = height + child.Size.Y.Offset
                                end
                            end
                            box.Size = UDim2.new(1, 0, 0, 24 + height + 8)
                        end,
                        AddBlank = function(self, size)
                            local blank = self:Create("Frame", {
                                BackgroundTransparency = 1,
                                Size = UDim2.new(1, 0, 0, size),
                                ZIndex = 1,
                                Parent = self.Container
                            })
                            return blank
                        end,
                        AddLabel = function(self, text, wrap)
                            local labelObj = Library:CreateLabel({
                                Size = UDim2.new(1, -4, 0, 15),
                                Text = text,
                                TextSize = 14,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                TextWrapped = wrap or false,
                                ZIndex = 5,
                                Parent = self.Container
                            })
                            if wrap then
                                local _, h = GetTextBounds(text, Library.Font, 14, labelObj.AbsoluteSize.X)
                                labelObj.Size = UDim2.new(1, -4, 0, h)
                            end
                            self:AddBlank(5)
                            self:Resize()
                            return { TextLabel = labelObj, SetText = function(self, newText)
                                labelObj.Text = newText
                                if wrap then
                                    local _, h = GetTextBounds(newText, Library.Font, 14, labelObj.AbsoluteSize.X)
                                    labelObj.Size = UDim2.new(1, -4, 0, h)
                                end
                                groupObj:Resize()
                            end }
                        end,
                        AddDivider = function(self)
                            self:AddBlank(4)
                            local div = self:Create("Frame", {
                                BackgroundColor3 = Library.OutlineColor,
                                BorderSizePixel = 0,
                                Size = UDim2.new(1, -8, 0, 1),
                                ZIndex = 5,
                                Parent = self.Container
                            })
                            Library:AddToRegistry(div, { BackgroundColor3 = "OutlineColor" })
                            self:AddBlank(4)
                            self:Resize()
                        end,
                        AddButton = function(self, data)
                            local btnObj = {}
                            local button = self:Create("Frame", {
                                BackgroundColor3 = Library.BackgroundColor,
                                BorderSizePixel = 0,
                                Size = UDim2.new(1, -4, 0, 24),
                                ZIndex = 5,
                                Parent = self.Container
                            })
                            Library:AddToRegistry(button, { BackgroundColor3 = "BackgroundColor" })
                            Instance.new("UICorner").Parent = button
                            Library:AddGradient(button)

                            local labelBtn = Library:CreateLabel({
                                Size = UDim2.new(1, 0, 1, 0),
                                Text = data.Text or "Button",
                                TextSize = 13,
                                ZIndex = 6,
                                Parent = button
                            })

                            button.MouseEnter:Connect(function()
                                local tween = game:GetService("TweenService")
                                tween:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = Library.AccentColor }):Play()
                                labelBtn.TextColor3 = Library.MainColor
                            end)
                            button.MouseLeave:Connect(function()
                                local tween = game:GetService("TweenService")
                                tween:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = Library.BackgroundColor }):Play()
                                labelBtn.TextColor3 = Library.FontColor
                            end)

                            local func = data.Func or function() end
                            local doubleClick = data.DoubleClick or false
                            local doubleText = data.DoubleClickText or "Are you sure?"
                            local locked = false

                            button.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    if Library:MouseIsOverOpenedFrame() then return end
                                    Library:PlayClickSound()
                                    if doubleClick then
                                        if locked then return end
                                        locked = true
                                        labelBtn.Text = doubleText
                                        Library:AddToRegistry(labelBtn, { TextColor3 = "AccentColor" })
                                        task.wait(2)
                                        locked = false
                                        labelBtn.Text = data.Text
                                        Library:AddToRegistry(labelBtn, { TextColor3 = "FontColor" })
                                    else
                                        func()
                                    end
                                end
                            end)

                            self:AddBlank(5)
                            self:Resize()
                            return btnObj
                        end,
                        AddToggle = function(self, id, data)
                            local toggleObj = {}
                            data = data or {}
                            local default = data.Default or false
                            toggleObj.Value = default
                            toggleObj.Callback = data.Callback or function() end
                            toggleObj.Type = "Toggle"
                            toggleObj.Text = data.Text or "Toggle"

                            local container = self:Create("Frame", {
                                BackgroundTransparency = 1,
                                Size = UDim2.new(1, 0, 0, 20),
                                ZIndex = 5,
                                Parent = self.Container
                            })

                            local toggleFrame = self:Create("Frame", {
                                BackgroundColor3 = Library.OutlineColor,
                                BorderSizePixel = 0,
                                Position = UDim2.new(0, 0, 0.5, 0),
                                AnchorPoint = Vector2.new(0, 0.5),
                                Size = UDim2.new(0, 28, 0, 14),
                                ZIndex = 5,
                                Parent = container
                            })
                            Library:AddToRegistry(toggleFrame, { BackgroundColor3 = "OutlineColor" })
                            Instance.new("UICorner").Parent = toggleFrame

                            local innerCircle = self:Create("Frame", {
                                BackgroundColor3 = Color3.new(1, 1, 1),
                                BorderSizePixel = 0,
                                Position = UDim2.new(0, 2, 0.5, 0),
                                AnchorPoint = Vector2.new(0, 0.5),
                                Size = UDim2.new(0, 10, 0, 10),
                                ZIndex = 6,
                                Parent = toggleFrame
                            })
                            Instance.new("UICorner").Parent = innerCircle

                            local labelToggle = Library:CreateLabel({
                                Size = UDim2.new(1, -36, 1, 0),
                                Position = UDim2.new(0, 34, 0, 0),
                                Text = toggleObj.Text,
                                TextSize = 14,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                ZIndex = 6,
                                Parent = container
                            })

                            local clickArea = self:Create("Frame", {
                                BackgroundTransparency = 1,
                                Size = UDim2.new(1, 0, 1, 0),
                                ZIndex = 8,
                                Parent = container
                            })

                            function toggleObj:SetValue(val)
                                val = not not val
                                self.Value = val
                                self:Display()
                                self.Callback(val)
                                if self.Changed then self.Changed(val) end
                            end

                            function toggleObj:Display()
                                local targetColor = self.Value and Library.AccentColor or Library.OutlineColor
                                local tween = game:GetService("TweenService")
                                tween:Create(toggleFrame, TweenInfo.new(0.15), { BackgroundColor3 = targetColor }):Play()
                                tween:Create(innerCircle, TweenInfo.new(0.15), {
                                    Position = self.Value and UDim2.new(0, 16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                                }):Play()
                                Library:AddToRegistry(toggleFrame, { BackgroundColor3 = self.Value and "AccentColor" or "OutlineColor" })
                            end

                            clickArea.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    if Library:MouseIsOverOpenedFrame() then return end
                                    Library:PlayClickSound()
                                    toggleObj:SetValue(not toggleObj.Value)
                                end
                            end)

                            toggleObj:Display()
                            self:AddBlank(7)
                            self:Resize()

                            if id then
                                _G.Toggles = _G.Toggles or {}
                                _G.Toggles[id] = toggleObj
                            end
                            return toggleObj
                        end,
                        AddSlider = function(self, id, data)
                            local sliderObj = {}
                            data = data or {}
                            local min = data.Min or 0
                            local max = data.Max or 100
                            local default = data.Default or 50
                            local rounding = data.Rounding or 0
                            local suffix = data.Suffix or ""
                            local text = data.Text or "Slider"

                            sliderObj.Value = default
                            sliderObj.Min = min
                            sliderObj.Max = max
                            sliderObj.Rounding = rounding
                            sliderObj.Callback = data.Callback or function() end

                            local container = self:Create("Frame", {
                                BackgroundTransparency = 1,
                                Size = UDim2.new(1, 0, 0, data.Compact and 14 or 20),
                                ZIndex = 5,
                                Parent = self.Container
                            })

                            if not data.Compact then
                                local labelSlider = Library:CreateLabel({
                                    Size = UDim2.new(1, 0, 0, 10),
                                    Text = text,
                                    TextSize = 14,
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    TextYAlignment = Enum.TextYAlignment.Bottom,
                                    ZIndex = 5,
                                    Parent = container
                                })
                                self:AddBlank(3)
                            end

                            local sliderFrame = self:Create("Frame", {
                                BackgroundColor3 = Library.BackgroundColor,
                                BorderSizePixel = 0,
                                Size = UDim2.new(1, -4, 0, 14),
                                ZIndex = 5,
                                Parent = container
                            })
                            Library:AddToRegistry(sliderFrame, { BackgroundColor3 = "BackgroundColor" })
                            Instance.new("UICorner").Parent = sliderFrame
                            Library:AddGradient(sliderFrame)

                            local fill = self:Create("Frame", {
                                BackgroundColor3 = Library.AccentColor,
                                BorderSizePixel = 0,
                                Size = UDim2.new(0, 0, 1, 0),
                                ZIndex = 7,
                                Parent = sliderFrame
                            })
                            Library:AddToRegistry(fill, { BackgroundColor3 = "AccentColor" })
                            Instance.new("UICorner").Parent = fill
                            Library:AddGradient(fill)

                            local valueLabel = Library:CreateLabel({
                                Position = UDim2.new(1, 0, 0.5, 0),
                                AnchorPoint = Vector2.new(1, 0.5),
                                Size = UDim2.new(0, 0, 0, 0),
                                Text = tostring(default) .. suffix,
                                TextSize = 13,
                                ZIndex = 8,
                                Parent = sliderFrame
                            })

                            function sliderObj:Display()
                                local val = self.Value
                                local ratio = (val - min) / (max - min)
                                fill.Size = UDim2.new(ratio, 0, 1, 0)
                                valueLabel.Text = tostring(val) .. suffix
                                local bounds = GetTextBounds(valueLabel.Text, Library.Font, 13)
                                valueLabel.Size = UDim2.new(0, bounds, 0, 14)
                            end

                            function sliderObj:SetValue(val)
                                val = math.clamp(val, min, max)
                                if rounding > 0 then
                                    val = tonumber(string.format("%." .. rounding .. "f", val))
                                end
                                self.Value = val
                                self:Display()
                                self.Callback(val)
                                if self.Changed then self.Changed(val) end
                            end

                            local dragging = false
                            sliderFrame.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    dragging = true
                                    local mouseX = input.Position.X
                                    local absX = sliderFrame.AbsolutePosition.X
                                    local width = sliderFrame.AbsoluteSize.X
                                    local ratio = math.clamp((mouseX - absX) / width, 0, 1)
                                    local val = min + (max - min) * ratio
                                    sliderObj:SetValue(val)
                                end
                            end)

                            game:GetService("UserInputService").InputChanged:Connect(function(input)
                                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                                    local mouseX = input.Position.X
                                    local absX = sliderFrame.AbsolutePosition.X
                                    local width = sliderFrame.AbsoluteSize.X
                                    local ratio = math.clamp((mouseX - absX) / width, 0, 1)
                                    local val = min + (max - min) * ratio
                                    sliderObj:SetValue(val)
                                end
                            end)

                            game:GetService("UserInputService").InputEnded:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    dragging = false
                                end
                            end)

                            sliderObj:Display()
                            self:AddBlank(6)
                            self:Resize()

                            if id then
                                _G.Options = _G.Options or {}
                                _G.Options[id] = sliderObj
                            end
                            return sliderObj
                        end,
                        AddDropdown = function(self, id, data)
                            local dropdownObj = {}
                            data = data or {}
                            local values = data.Values or {}
                            local default = data.Default or values[1] or ""
                            local multi = data.Multi or false
                            local text = data.Text or "Dropdown"
                            local allowNull = data.AllowNull or false

                            dropdownObj.Values = values
                            dropdownObj.Value = multi and {} or default
                            dropdownObj.Multi = multi
                            dropdownObj.Callback = data.Callback or function() end

                            local container = self:Create("Frame", {
                                BackgroundTransparency = 1,
                                Size = UDim2.new(1, 0, 0, data.Compact and 20 or 30),
                                ZIndex = 5,
                                Parent = self.Container
                            })

                            if not data.Compact then
                                local labelDrop = Library:CreateLabel({
                                    Size = UDim2.new(1, 0, 0, 10),
                                    Text = text,
                                    TextSize = 14,
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    TextYAlignment = Enum.TextYAlignment.Bottom,
                                    ZIndex = 5,
                                    Parent = container
                                })
                                self:AddBlank(3)
                            end

                            local dropdownFrame = self:Create("Frame", {
                                BackgroundColor3 = Library.BackgroundColor,
                                BorderSizePixel = 0,
                                Size = UDim2.new(1, -4, 0, 24),
                                ZIndex = 5,
                                Parent = container
                            })
                            Library:AddToRegistry(dropdownFrame, { BackgroundColor3 = "BackgroundColor" })
                            Instance.new("UICorner").Parent = dropdownFrame
                            Library:AddGradient(dropdownFrame)

                            local arrow = self:Create("ImageLabel", {
                                AnchorPoint = Vector2.new(0, 0.5),
                                BackgroundTransparency = 1,
                                Position = UDim2.new(1, -18, 0.5, 0),
                                Size = UDim2.new(0, 12, 0, 12),
                                Image = "http://www.roblox.com/asset/?id=6282522798",
                                ZIndex = 8,
                                Parent = dropdownFrame
                            })

                            local selectedText = Library:CreateLabel({
                                Position = UDim2.new(0, 8, 0, 0),
                                Size = UDim2.new(1, -24, 1, 0),
                                Text = multi and "" or tostring(default),
                                TextSize = 13,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                TextWrapped = true,
                                ZIndex = 7,
                                Parent = dropdownFrame
                            })

                            local dropdownList = self:Create("Frame", {
                                BackgroundColor3 = Library.BackgroundColor,
                                BorderSizePixel = 0,
                                ZIndex = 20,
                                Visible = false,
                                ClipsDescendants = true,
                                Position = UDim2.new(0, 0, 0, 0),
                                Size = UDim2.new(1, 0, 0, 0),
                                Parent = dropdownFrame
                            })
                            Library:AddToRegistry(dropdownList, { BackgroundColor3 = "BackgroundColor" })
                            Instance.new("UICorner").Parent = dropdownList
                            local strokeDrop = Instance.new("UIStroke")
                            strokeDrop.Color = Library.OutlineColor
                            strokeDrop.Thickness = 1
                            strokeDrop.Parent = dropdownList
                            Library:AddToRegistry(strokeDrop, { Color = "OutlineColor" })

                            local listLayout = Instance.new("UIListLayout")
                            listLayout.FillDirection = Enum.FillDirection.Vertical
                            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
                            listLayout.Padding = UDim.new(0, 0)
                            listLayout.Parent = dropdownList

                            local function updateDisplay()
                                if multi then
                                    local texts = {}
                                    for k, v in pairs(dropdownObj.Value) do
                                        if v then table.insert(texts, k) end
                                    end
                                    selectedText.Text = table.concat(texts, ", ")
                                    if #texts == 0 then selectedText.Text = "--" end
                                else
                                    selectedText.Text = dropdownObj.Value or "--"
                                end
                            end

                            function dropdownObj:Build()
                                for _, child in ipairs(dropdownList:GetChildren()) do
                                    if child:IsA("Frame") then child:Destroy() end
                                end
                                local height = 0
                                for _, val in ipairs(values) do
                                    local item = self:Create("Frame", {
                                        BackgroundColor3 = Library.BackgroundColor,
                                        BorderSizePixel = 0,
                                        Size = UDim2.new(1, 0, 0, 22),
                                        ZIndex = 21,
                                        Parent = dropdownList
                                    })
                                    Library:AddToRegistry(item, { BackgroundColor3 = "BackgroundColor" })
                                    local itemLabel = Library:CreateLabel({
                                        Size = UDim2.new(1, -10, 1, 0),
                                        Position = UDim2.new(0, 8, 0, 0),
                                        Text = val,
                                        TextSize = 13,
                                        TextXAlignment = Enum.TextXAlignment.Left,
                                        ZIndex = 22,
                                        Parent = item
                                    })
                                    local isSelected = multi and dropdownObj.Value[val] or dropdownObj.Value == val
                                    itemLabel.TextColor3 = isSelected and Library.AccentColor or Library.FontColor
                                    Library:AddToRegistry(itemLabel, { TextColor3 = isSelected and "AccentColor" or "FontColor" })

                                    item.InputBegan:Connect(function(input)
                                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                            Library:PlayClickSound()
                                            if multi then
                                                dropdownObj.Value[val] = not dropdownObj.Value[val]
                                            else
                                                dropdownObj.Value = val
                                            end
                                            dropdownObj:Build()
                                            updateDisplay()
                                            dropdownObj.Callback(dropdownObj.Value)
                                            if dropdownObj.Changed then dropdownObj.Changed(dropdownObj.Value) end
                                        end
                                    end)
                                    height = height + 22
                                end
                                dropdownList.Size = UDim2.new(1, 0, 0, height + 2)
                            end

                            function dropdownObj:SetValues(newValues)
                                values = newValues or {}
                                dropdownObj.Values = values
                                dropdownObj:Build()
                            end

                            function dropdownObj:SetValue(newVal)
                                if multi then
                                    dropdownObj.Value = {}
                                    for _, v in ipairs(newVal or {}) do
                                        if table.find(values, v) then
                                            dropdownObj.Value[v] = true
                                        end
                                    end
                                else
                                    if table.find(values, newVal) then
                                        dropdownObj.Value = newVal
                                    elseif allowNull then
                                        dropdownObj.Value = nil
                                    end
                                end
                                dropdownObj:Build()
                                updateDisplay()
                                dropdownObj.Callback(dropdownObj.Value)
                                if dropdownObj.Changed then dropdownObj.Changed(dropdownObj.Value) end
                            end

                            dropdownFrame.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    if Library:MouseIsOverOpenedFrame() then return end
                                    Library:PlayClickSound()
                                    dropdownList.Visible = not dropdownList.Visible
                                    if dropdownList.Visible then
                                        Library.OpenedFrames[dropdownList] = true
                                        dropdownList.Position = UDim2.new(0, 0, 0, dropdownFrame.Size.Y.Offset + 2)
                                        dropdownList.Size = UDim2.new(1, 0, 0, 0)
                                        local tween = game:GetService("TweenService")
                                        tween:Create(dropdownList, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                                            Size = UDim2.new(1, 0, 0, height + 2)
                                        }):Play()
                                    else
                                        Library.OpenedFrames[dropdownList] = nil
                                        local tween = game:GetService("TweenService")
                                        tween:Create(dropdownList, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                                            Size = UDim2.new(1, 0, 0, 0)
                                        }):Play()
                                        task.wait(0.1)
                                        dropdownList.Visible = false
                                    end
                                end
                            end)

                            dropdownObj:Build()
                            updateDisplay()
                            self:AddBlank(5)
                            self:Resize()
                            if id then
                                _G.Options = _G.Options or {}
                                _G.Options[id] = dropdownObj
                            end
                            return dropdownObj
                        end,
                        AddInput = function(self, id, data)
                            local inputObj = {}
                            data = data or {}
                            local default = data.Default or ""
                            local placeholder = data.Placeholder or ""
                            local numeric = data.Numeric or false
                            local callback = data.Callback or function() end

                            inputObj.Value = default
                            inputObj.Callback = callback

                            local container = self:Create("Frame", {
                                BackgroundTransparency = 1,
                                Size = UDim2.new(1, 0, 0, 15 + 24 + 5),
                                ZIndex = 5,
                                Parent = self.Container
                            })

                            local labelInput = Library:CreateLabel({
                                Size = UDim2.new(1, 0, 0, 15),
                                Text = data.Text or "Input",
                                TextSize = 14,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                ZIndex = 5,
                                Parent = container
                            })

                            local inputFrame = self:Create("Frame", {
                                BackgroundColor3 = Library.BackgroundColor,
                                BorderSizePixel = 0,
                                Size = UDim2.new(1, -4, 0, 24),
                                ZIndex = 5,
                                Parent = container
                            })
                            Library:AddToRegistry(inputFrame, { BackgroundColor3 = "BackgroundColor" })
                            Instance.new("UICorner").Parent = inputFrame
                            Library:AddGradient(inputFrame)

                            local textBox = self:Create("TextBox", {
                                BackgroundTransparency = 1,
                                Position = UDim2.new(0, 5, 0, 0),
                                Size = UDim2.new(1, -5, 1, 0),
                                FontFace = Library.Font,
                                PlaceholderText = placeholder,
                                Text = default,
                                TextColor3 = Library.FontColor,
                                TextSize = 14,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                ZIndex = 7,
                                Parent = inputFrame
                            })
                            Library:AddToRegistry(textBox, { TextColor3 = "FontColor" })

                            textBox:GetPropertyChangedSignal("Text"):Connect(function()
                                local val = textBox.Text
                                if numeric and val ~= "" and not tonumber(val) then
                                    textBox.Text = inputObj.Value
                                    return
                                end
                                inputObj.Value = val
                                callback(val)
                                if inputObj.Changed then inputObj.Changed(val) end
                            end)

                            self:AddBlank(5)
                            self:Resize()
                            if id then
                                _G.Options = _G.Options or {}
                                _G.Options[id] = inputObj
                            end
                            return inputObj
                        end,
                        AddTabbox = function(self, name, side)
                            side = side or 1
                            local col = side == 1 and leftCol or rightCol
                            local tabboxObj = { Tabs = {}, ParentTab = self }

                            local box = self:Create("Frame", {
                                BackgroundColor3 = Library.MainColor,
                                BorderSizePixel = 0,
                                Size = UDim2.new(1, 0, 0, 0),
                                ZIndex = 2,
                                Parent = col
                            })
                            Library:AddToRegistry(box, { BackgroundColor3 = "MainColor" })
                            Instance.new("UIStroke").Parent = box
                            Library:AddGradient(box)

                            local header = self:Create("Frame", {
                                BackgroundTransparency = 1,
                                Position = UDim2.new(0, 4, 0, 2),
                                Size = UDim2.new(1, -8, 0, 22),
                                ZIndex = 5,
                                Parent = box
                            })
                            local headerLayout = Instance.new("UIListLayout")
                            headerLayout.FillDirection = Enum.FillDirection.Horizontal
                            headerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
                            headerLayout.SortOrder = Enum.SortOrder.LayoutOrder
                            headerLayout.Padding = UDim.new(0, 0)
                            headerLayout.Parent = header

                            local indicator = self:Create("Frame", {
                                BackgroundColor3 = Library.AccentColor,
                                BorderSizePixel = 0,
                                Position = UDim2.new(0, 0, 0, 22),
                                Size = UDim2.new(0, 0, 0, 2),
                                ZIndex = 10,
                                Parent = box
                            })
                            Library:AddToRegistry(indicator, { BackgroundColor3 = "AccentColor" })

                            local contentAreaTabbox = self:Create("Frame", {
                                BackgroundTransparency = 1,
                                Position = UDim2.new(0, 6, 0, 26),
                                Size = UDim2.new(1, -8, 1, -26),
                                ZIndex = 1,
                                Parent = box
                            })
                            local layoutContent = Instance.new("UIListLayout")
                            layoutContent.FillDirection = Enum.FillDirection.Vertical
                            layoutContent.SortOrder = Enum.SortOrder.LayoutOrder
                            layoutContent.Parent = contentAreaTabbox

                            function tabboxObj:AddTab(tabName)
                                local tabButton = self:Create("Frame", {
                                    BackgroundTransparency = 1,
                                    BorderSizePixel = 0,
                                    Size = UDim2.new(1 / (#self.Tabs + 1), 0, 1, 0),
                                    ZIndex = 6,
                                    Parent = header
                                })
                                table.insert(self.Tabs, tabButton)
                                for i, btn in ipairs(self.Tabs) do
                                    btn.Size = UDim2.new(1 / #self.Tabs, 0, 1, 0)
                                end

                                local labelTab = Library:CreateLabel({
                                    Size = UDim2.new(1, 0, 1, 0),
                                    Text = tabName,
                                    TextSize = 13,
                                    TextXAlignment = Enum.TextXAlignment.Center,
                                    ZIndex = 7,
                                    Parent = tabButton
                                })

                                local tabContent = self:Create("Frame", {
                                    BackgroundTransparency = 1,
                                    Size = UDim2.new(1, 0, 1, 0),
                                    Visible = false,
                                    ZIndex = 1,
                                    Parent = contentAreaTabbox
                                })
                                local layoutTab = Instance.new("UIListLayout")
                                layoutTab.FillDirection = Enum.FillDirection.Vertical
                                layoutTab.SortOrder = Enum.SortOrder.LayoutOrder
                                layoutTab.Parent = tabContent

                                local tabObj = {
                                    Container = tabContent,
                                    BoxFrame = box,
                                    Show = function(self)
                                        for _, t in pairs(tabboxObj.Tabs) do
                                            if t ~= tabObj then t:Hide() end
                                        end
                                        labelTab.TextColor3 = Library.AccentColor
                                        Library:AddToRegistry(labelTab, { TextColor3 = "AccentColor" })
                                        tabContent.Visible = true
                                        local btnPos = tabButton.AbsolutePosition.X
                                        local headerPos = header.AbsolutePosition.X
                                        local btnSize = tabButton.AbsoluteSize.X
                                        indicator.Position = UDim2.new(0, (btnPos - headerPos) + 4, 0, 22)
                                        indicator.Size = UDim2.new(0, btnSize, 0, 2)
                                        self:Resize()
                                    end,
                                    Hide = function(self)
                                        labelTab.TextColor3 = Library.FontColor
                                        Library:AddToRegistry(labelTab, { TextColor3 = "FontColor" })
                                        tabContent.Visible = false
                                    end,
                                    Resize = function(self)
                                        local height = 0
                                        for _, child in ipairs(tabContent:GetChildren()) do
                                            if child:IsA("Frame") and child.Visible then
                                                height = height + child.Size.Y.Offset
                                            end
                                        end
                                        box.Size = UDim2.new(1, 0, 0, 26 + height + 8)
                                    end,
                                    AddBlank = function(self, size)
                                        local blank = self:Create("Frame", {
                                            BackgroundTransparency = 1,
                                            Size = UDim2.new(1, 0, 0, size),
                                            ZIndex = 1,
                                            Parent = self.Container
                                        })
                                        return blank
                                    end,
                                    AddLabel = function(self, text, wrap)
                                        return groupObj:AddLabel(text, wrap)
                                    end,
                                    AddDivider = function(self)
                                        return groupObj:AddDivider()
                                    end,
                                    AddButton = function(self, data)
                                        return groupObj:AddButton(data)
                                    end,
                                    AddToggle = function(self, id, data)
                                        return groupObj:AddToggle(id, data)
                                    end,
                                    AddSlider = function(self, id, data)
                                        return groupObj:AddSlider(id, data)
                                    end,
                                    AddDropdown = function(self, id, data)
                                        return groupObj:AddDropdown(id, data)
                                    end,
                                    AddInput = function(self, id, data)
                                        return groupObj:AddInput(id, data)
                                    end,
                                }
                                setmetatable(tabObj, { __index = groupObj })
                                tabObj.Container = tabContent
                                tabObj.BoxFrame = box
                                tabObj:AddBlank(3)
                                tabObj:Resize()
                                if #self.Tabs == 1 then tabObj:Show() end
                                return tabObj
                            end

                            self.TabboxCount = self.TabboxCount + 1
                            self.Tabboxes[#self.Tabboxes + 1] = tabboxObj
                            self:AddBlank(3)
                            self:Resize()
                            return tabboxObj
                        end,
                    }

                    local parentGroup = groupObj

                    groupObj.AddTabbox = function(self, name, side)
                        return self:AddTabbox(name, side)
                    end
                    groupObj.AddLeftTabbox = function(self, name)
                        return self:AddTabbox(name, 1)
                    end
                    groupObj.AddRightTabbox = function(self, name)
                        return self:AddTabbox(name, 2)
                    end
                    groupObj.AddDynamicTabbox = function(self, name)
                        if (self.TabboxCount % 2) == 0 then
                            return self:AddLeftTabbox(name)
                        else
                            return self:AddRightTabbox(name)
                        end
                    end

                    self.GroupboxCount = self.GroupboxCount + 1
                    self.Groupboxes[name] = groupObj
                    groupObj:AddBlank(3)
                    groupObj:Resize()
                    return groupObj
                end,
            }

            tabButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Library:PlayClickSound()
                    tabObj:ShowTab()
                end
            end)

            if #self.Tabs == 1 then
                tabObj:ShowTab()
            end

            return tabObj
        end
    }

    function Library:MouseIsOverOpenedFrame()
        local mouse = game:GetService("Players").LocalPlayer:GetMouse()
        for frame, _ in pairs(self.OpenedFrames) do
            if frame and frame.Visible then
                local pos = frame.AbsolutePosition
                local size = frame.AbsoluteSize
                if mouse.X >= pos.X and mouse.X <= pos.X + size.X and
                   mouse.Y >= pos.Y and mouse.Y <= pos.Y + size.Y then
                    return true
                end
            end
        end
        return false
    end

    return windowObj
end

_G.PalantirUI = Library
print("PalantirUI Library loaded successfully!")
