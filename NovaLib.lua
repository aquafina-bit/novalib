--[[
    ███╗   ██╗ ██████╗ ██╗   ██╗ █████╗
    ████╗  ██║██╔═══██╗██║   ██║██╔══██╗
    ██╔██╗ ██║██║   ██║██║   ██║███████║
    ██║╚██╗██║██║   ██║╚██╗ ██╔╝██╔══██║
    ██║ ╚████║╚██████╔╝ ╚████╔╝ ██║  ██║
    ╚═╝  ╚═══╝ ╚═════╝   ╚═══╝  ╚═╝  ╚═╝
    Nova UI Library v2.0
    A revamped Roblox UI library — sleek, modern, fully featured.
    Inspired by Rayfield. Rebuilt from the ground up.
--]]

local Nova = {}
Nova.__index = Nova
Nova.Version = "2.0.0"

------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local TextService      = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

------------------------------------------------------------------------
-- Theme
------------------------------------------------------------------------
Nova.Theme = {
    -- Backgrounds
    BG           = Color3.fromRGB(11, 11, 17),
    BG2          = Color3.fromRGB(16, 16, 25),
    BG3          = Color3.fromRGB(22, 22, 34),
    BG4          = Color3.fromRGB(28, 28, 44),
    -- Accent (electric indigo + violet)
    Accent       = Color3.fromRGB(108, 99, 255),
    AccentLight  = Color3.fromRGB(150, 143, 255),
    AccentDark   = Color3.fromRGB(72, 64, 200),
    AccentGlow   = Color3.fromRGB(108, 99, 255),
    -- Text
    TextPrimary  = Color3.fromRGB(242, 242, 255),
    TextSub      = Color3.fromRGB(155, 155, 195),
    TextMuted    = Color3.fromRGB(85, 85, 115),
    -- Borders
    Border       = Color3.fromRGB(38, 38, 58),
    BorderBright = Color3.fromRGB(70, 70, 105),
    -- States
    Success      = Color3.fromRGB(52, 211, 153),
    Danger       = Color3.fromRGB(248, 113, 113),
    Warning      = Color3.fromRGB(251, 191, 36),
    Info         = Color3.fromRGB(96, 165, 250),
    -- Elements
    ElementBG    = Color3.fromRGB(19, 19, 30),
    ElementHover = Color3.fromRGB(26, 26, 42),
    ToggleOff    = Color3.fromRGB(38, 38, 60),
    SliderTrack  = Color3.fromRGB(30, 30, 50),
}

------------------------------------------------------------------------
-- Utilities
------------------------------------------------------------------------
local function tween(obj, props, t, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(t or 0.22, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, trans)
    local s = Instance.new("UIStroke")
    s.Color = color or Nova.Theme.Border
    s.Thickness = thickness or 1
    s.Transparency = trans or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function padding(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft   = UDim.new(0, left   or 0)
    p.PaddingRight  = UDim.new(0, right  or 0)
    p.Parent = parent
    return p
end

local function new(class, props, parent)
    local i = Instance.new(class)
    for k,v in pairs(props or {}) do i[k] = v end
    if parent then i.Parent = parent end
    return i
end

local function listLayout(parent, pad, align, sort)
    return new("UIListLayout", {
        Padding = UDim.new(0, pad or 4),
        HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
        SortOrder = sort or Enum.SortOrder.LayoutOrder,
    }, parent)
end

local function draggable(frame, handle)
    local drag, startMouse, startPos = false, nil, nil
    handle = handle or frame

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            drag = true
            startMouse = input.Position
            startPos  = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then drag = false end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if drag and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startMouse
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function glow(parent, color, size)
    -- soft drop-shadow using ImageLabel
    local g = new("ImageLabel", {
        Name = "Glow",
        Size = UDim2.new(1, size or 30, 1, size or 30),
        Position = UDim2.new(0, -(size or 30)/2, 0, -(size or 30)/2),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5028857084",
        ImageColor3 = color or Color3.fromRGB(0,0,0),
        ImageTransparency = 0.82,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(24, 24, 276, 276),
        ZIndex = 0,
    }, parent)
    return g
end

------------------------------------------------------------------------
-- ScreenGui factory
------------------------------------------------------------------------
local function makeGui(name)
    local existing = CoreGui:FindFirstChild(name)
    if existing then existing:Destroy() end
    local gui = new("ScreenGui", {
        Name = name,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
    })
    local ok = pcall(function() gui.Parent = CoreGui end)
    if not ok then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    return gui
end

------------------------------------------------------------------------
-- NOTIFICATION SYSTEM
------------------------------------------------------------------------
local notifGui = nil
local notifContainer = nil

local function ensureNotifGui()
    if notifGui and notifGui.Parent then return end
    notifGui = makeGui("NovaNotifications")
    notifContainer = new("Frame", {
        Name = "Container",
        Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(1, -310, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, notifGui)
    listLayout(notifContainer, 8)
    padding(notifContainer, 16, 16, 0, 0)
end

function Nova:Notify(config)
    config = config or {}
    local title    = config.Title    or "Notification"
    local desc     = config.Description or ""
    local duration = config.Duration or 4
    local ntype    = config.Type     or "info"  -- info | success | danger | warning

    ensureNotifGui()

    local typeColors = {
        info    = Nova.Theme.Info,
        success = Nova.Theme.Success,
        danger  = Nova.Theme.Danger,
        warning = Nova.Theme.Warning,
    }
    local accentColor = typeColors[ntype] or Nova.Theme.Accent

    local Card = new("Frame", {
        Name = "Notif",
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundColor3 = Nova.Theme.BG2,
        ClipsDescendants = true,
    }, notifContainer)
    corner(Card, 10)
    stroke(Card, accentColor, 1, 0.4)
    glow(Card, accentColor, 20)

    -- Accent strip on left
    local strip = new("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
    }, Card)
    corner(strip, 3)

    -- Title
    new("TextLabel", {
        Size = UDim2.new(1, -20, 0, 22),
        Position = UDim2.new(0, 14, 0, 10),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Nova.Theme.TextPrimary,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Card)

    -- Description
    new("TextLabel", {
        Size = UDim2.new(1, -20, 0, 28),
        Position = UDim2.new(0, 14, 0, 32),
        BackgroundTransparency = 1,
        Text = desc,
        TextColor3 = Nova.Theme.TextSub,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
    }, Card)

    -- Progress bar
    local progBG = new("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = Nova.Theme.BG4,
        BorderSizePixel = 0,
    }, Card)
    local prog = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
    }, progBG)

    -- Slide in
    Card.Position = UDim2.new(1, 10, 0, 0)
    tween(Card, {Position = UDim2.new(0, 0, 0, 0)}, 0.35, Enum.EasingStyle.Back)
    tween(prog, {Size = UDim2.new(0, 0, 1, 0)}, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        tween(Card, {Position = UDim2.new(1, 10, 0, 0)}, 0.3)
        task.wait(0.31)
        Card:Destroy()
    end)
end

------------------------------------------------------------------------
-- WINDOW
------------------------------------------------------------------------
function Nova:CreateWindow(config)
    config = config or {}
    local title        = config.Title        or "Nova"
    local subtitle     = config.Subtitle     or "v2.0"
    local size         = config.Size         or UDim2.new(0, 580, 0, 420)
    local centerPos    = UDim2.new(0.5, -290, 0.5, -210)
    local toggleKey    = config.ToggleKey    or Enum.KeyCode.RightControl
    local theme        = Nova.Theme

    local ScreenGui = makeGui("NovaUI_" .. title:gsub("%W",""))

    --------------------------------------------------------------------
    -- Root frame
    --------------------------------------------------------------------
    local Root = new("Frame", {
        Name = "Root",
        Size = size,
        Position = centerPos,
        BackgroundColor3 = theme.BG,
        BorderSizePixel = 0,
        ClipsDescendants = false,
    }, ScreenGui)
    corner(Root, 14)
    stroke(Root, theme.Border, 1.5)
    glow(Root, Color3.fromRGB(108,99,255), 40)

    -- Subtle BG gradient
    local bgGrad = new("UIGradient", {
        Rotation = 145,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(14,14,22)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(9,9,15)),
        }),
    }, Root)

    -- Noise texture for depth
    new("ImageLabel", {
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://9968344802",
        ImageTransparency = 0.97,
        ScaleType = Enum.ScaleType.Tile,
        TileSize = UDim2.new(0, 100, 0, 100),
        ZIndex = 0,
        ClipsDescendants = true,
    }, Root)

    --------------------------------------------------------------------
    -- Top bar
    --------------------------------------------------------------------
    local TopBar = new("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = theme.BG2,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, Root)
    corner(TopBar, 14)
    -- mask bottom half of corners
    new("Frame", {
        Size = UDim2.new(1,0,0,14),
        Position = UDim2.new(0,0,1,-14),
        BackgroundColor3 = theme.BG2,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, TopBar)

    new("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(21,21,34)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(16,16,26)),
        }),
    }, TopBar)

    -- Accent line at bottom of topbar
    local accentLine = new("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0,0,1,-1),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 6,
    }, TopBar)
    new("UIGradient", {
        Rotation = 0,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(108,99,255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(168,85,247)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(108,99,255)),
        }),
    }, accentLine)

    -- Logo/icon dot
    local logoDot = new("Frame", {
        Size = UDim2.new(0,8,0,8),
        Position = UDim2.new(0,16,0.5,-4),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 6,
    }, TopBar)
    corner(logoDot, 4)

    -- Title label
    new("TextLabel", {
        Size = UDim2.new(0,160,0,22),
        Position = UDim2.new(0,32,0.5,-11),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = theme.TextPrimary,
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
    }, TopBar)

    -- Subtitle label
    new("TextLabel", {
        Size = UDim2.new(0,200,0,14),
        Position = UDim2.new(0,32,0.5,9),
        BackgroundTransparency = 1,
        Text = subtitle,
        TextColor3 = theme.TextMuted,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
    }, TopBar)

    -- Window controls (close, minimize)
    local function makeWinBtn(xOff, bgColor, symbol)
        local btn = new("TextButton", {
            Size = UDim2.new(0,26,0,26),
            Position = UDim2.new(1, xOff, 0.5,-13),
            BackgroundColor3 = bgColor,
            BackgroundTransparency = 0.55,
            Text = symbol,
            TextColor3 = bgColor,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            ZIndex = 7,
        }, TopBar)
        corner(btn, 7)
        btn.MouseEnter:Connect(function()  tween(btn, {BackgroundTransparency=0.1}, 0.15) end)
        btn.MouseLeave:Connect(function()  tween(btn, {BackgroundTransparency=0.55}, 0.15) end)
        return btn
    end

    local CloseBtn = makeWinBtn(-14, theme.Danger, "✕")
    local MinBtn   = makeWinBtn(-46, theme.Warning, "−")

    CloseBtn.MouseButton1Click:Connect(function()
        tween(Root, {Size=UDim2.new(0,size.X.Offset,0,0), Position=UDim2.new(Root.Position.X.Scale, Root.Position.X.Offset, Root.Position.Y.Scale, Root.Position.Y.Offset + size.Y.Offset/2)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.wait(0.31)
        ScreenGui:Destroy()
    end)

    local hidden = false
    local function toggleHide()
        hidden = not hidden
        if hidden then
            tween(Root, {Size=UDim2.new(0,size.X.Offset,0,50)}, 0.25, Enum.EasingStyle.Quart)
        else
            tween(Root, {Size=size}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end
    end
    MinBtn.MouseButton1Click:Connect(toggleHide)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == toggleKey then toggleHide() end
    end)

    draggable(Root, TopBar)

    --------------------------------------------------------------------
    -- Left sidebar (tab list)
    --------------------------------------------------------------------
    local Sidebar = new("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 135, 1, -52),
        Position = UDim2.new(0, 0, 0, 52),
        BackgroundColor3 = theme.BG2,
        BorderSizePixel = 0,
        ZIndex = 3,
        ClipsDescendants = true,
    }, Root)
    -- bottom-left round corner only
    corner(Sidebar, 14)
    new("Frame", {
        Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,0,0),
        BackgroundColor3=theme.BG2, BorderSizePixel=0, ZIndex=3
    }, Sidebar)
    new("Frame", {
        Size=UDim2.new(0,14,1,0), Position=UDim2.new(1,-14,0,0),
        BackgroundColor3=theme.BG2, BorderSizePixel=0, ZIndex=3
    }, Sidebar)

    new("UIGradient", {
        Rotation = 180,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(18,18,29)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(13,13,21)),
        }),
    }, Sidebar)

    -- Vertical divider
    local divider = new("Frame", {
        Size = UDim2.new(0,1,1,-52),
        Position = UDim2.new(0,135,0,52),
        BackgroundColor3 = theme.Border,
        BorderSizePixel = 0,
        ZIndex = 4,
    }, Root)

    -- Tab scroll list
    local TabList = new("ScrollingFrame", {
        Size = UDim2.new(1,-8,1,-10),
        Position = UDim2.new(0,4,0,6),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 4,
    }, Sidebar)
    listLayout(TabList, 4, Enum.HorizontalAlignment.Center)
    padding(TabList, 6, 6, 0, 0)

    -- Version badge at bottom of sidebar
    new("TextLabel", {
        Size = UDim2.new(1,0,0,18),
        Position = UDim2.new(0,0,1,-20),
        BackgroundTransparency = 1,
        Text = "Nova v"..Nova.Version,
        TextColor3 = theme.TextMuted,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 4,
    }, Sidebar)

    --------------------------------------------------------------------
    -- Content area
    --------------------------------------------------------------------
    local ContentArea = new("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1,-139,1,-52),
        Position = UDim2.new(0,138,0,52),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 3,
        ClipsDescendants = true,
    }, Root)

    --------------------------------------------------------------------
    -- Section header helper
    --------------------------------------------------------------------
    local function makeSectionHeader(parent, text)
        local wrap = new("Frame", {
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            ZIndex = 4,
        }, parent)
        new("TextLabel", {
            Size = UDim2.new(1,-10,1,0),
            Position = UDim2.new(0,5,0,0),
            BackgroundTransparency = 1,
            Text = text:upper(),
            TextColor3 = theme.Accent,
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
        }, wrap)
        local line = new("Frame", {
            Size = UDim2.new(1,-10,0,1),
            Position = UDim2.new(0,5,1,-1),
            BackgroundColor3 = theme.Border,
            BorderSizePixel = 0,
            ZIndex = 5,
        }, wrap)
        return wrap
    end

    -- Entrance animation
    Root.Size = UDim2.new(0,size.X.Offset,0,0)
    Root.BackgroundTransparency = 1
    tween(Root, {Size=size, BackgroundTransparency=0}, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    --------------------------------------------------------------------
    -- Window Object
    --------------------------------------------------------------------
    local Window = {_tabs={}, _activeTab=nil, _gui=ScreenGui}

    local function activateTab(tabBtn, tabPage)
        -- Deactivate previous
        if Window._activeTab then
            local prev = Window._activeTab
            tween(prev.btn, {BackgroundColor3=theme.BG3, BackgroundTransparency=0.6}, 0.2)
            if prev.btn:FindFirstChild("Label") then
                tween(prev.btn.Label, {TextColor3=theme.TextSub}, 0.2)
            end
            if prev.btn:FindFirstChild("Bar") then
                tween(prev.btn.Bar, {BackgroundTransparency=1}, 0.2)
            end
            prev.page.Visible = false
        end
        -- Activate new
        Window._activeTab = {btn=tabBtn, page=tabPage}
        tween(tabBtn, {BackgroundColor3=theme.Accent, BackgroundTransparency=0.78}, 0.2)
        if tabBtn:FindFirstChild("Label") then
            tween(tabBtn.Label, {TextColor3=theme.AccentLight}, 0.2)
        end
        if tabBtn:FindFirstChild("Bar") then
            tween(tabBtn.Bar, {BackgroundTransparency=0}, 0.2)
        end
        tabPage.Visible = true
    end

    ------------------------------------------------------------------
    -- CreateTab
    ------------------------------------------------------------------
    function Window:CreateTab(config)
        config = config or {}
        local name = config.Name or "Tab"
        local icon = config.Icon or ""

        -- Tab button
        local TBtn = new("TextButton", {
            Name = "Tab_"..name,
            Size = UDim2.new(1,-10,0,38),
            BackgroundColor3 = theme.BG3,
            BackgroundTransparency = 0.6,
            Text = "",
            ZIndex = 5,
        }, TabList)
        corner(TBtn, 8)

        if icon ~= "" then
            new("ImageLabel", {
                Size = UDim2.new(0,16,0,16),
                Position = UDim2.new(0,10,0.5,-8),
                BackgroundTransparency = 1,
                Image = icon,
                ImageColor3 = theme.TextSub,
                ZIndex = 6,
            }, TBtn)
        end

        local lbl = new("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1,-(icon~="" and 32 or 12),1,0),
            Position = UDim2.new(0,(icon~="" and 32 or 10),0,0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = theme.TextSub,
            TextSize = 12,
            Font = Enum.Font.GothamSemibold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6,
        }, TBtn)

        -- Active indicator bar
        local bar = new("Frame", {
            Name = "Bar",
            Size = UDim2.new(0,3,0.55,0),
            Position = UDim2.new(0,0,0.225,0),
            BackgroundColor3 = theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 6,
        }, TBtn)
        corner(bar, 2)

        -- Page
        local Page = new("ScrollingFrame", {
            Name = "Page_"..name,
            Size = UDim2.new(1,-6,1,-6),
            Position = UDim2.new(0,3,0,3),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = theme.Accent,
            CanvasSize = UDim2.new(0,0,0,0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            ZIndex = 4,
        }, ContentArea)
        listLayout(Page, 5)
        padding(Page, 6, 10, 4, 6)

        -- Hover
        TBtn.MouseEnter:Connect(function()
            if Window._activeTab and Window._activeTab.btn == TBtn then return end
            tween(TBtn, {BackgroundTransparency=0.35}, 0.15)
        end)
        TBtn.MouseLeave:Connect(function()
            if Window._activeTab and Window._activeTab.btn == TBtn then return end
            tween(TBtn, {BackgroundTransparency=0.6}, 0.15)
        end)
        TBtn.MouseButton1Click:Connect(function()
            activateTab(TBtn, Page)
        end)

        -- Auto-activate first tab
        if #Window._tabs == 0 then
            activateTab(TBtn, Page)
        end
        table.insert(Window._tabs, {btn=TBtn, page=Page})

        ----------------------------------------------------------------
        -- Tab Object
        ----------------------------------------------------------------
        local Tab = {}

        -- ---- SECTION ----
        function Tab:AddSection(config)
            config = config or {}
            local sname = config.Name or "Section"
            makeSectionHeader(Page, sname)
        end

        -- ---- LABEL ----
        function Tab:AddLabel(config)
            config = config or {}
            local text = config.Text or ""
            local lf = new("Frame", {
                Size = UDim2.new(1,0,0,30),
                BackgroundTransparency = 1,
            }, Page)
            new("TextLabel", {
                Size = UDim2.new(1,-10,1,0),
                Position = UDim2.new(0,5,0,0),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = theme.TextSub,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                ZIndex = 5,
            }, lf)
            local LabelObj = {}
            function LabelObj:Set(t) lf:FindFirstChildWhichIsA("TextLabel").Text = t end
            return LabelObj
        end

        -- ---- BUTTON ----
        function Tab:AddButton(config)
            config = config or {}
            local bname    = config.Name     or "Button"
            local desc     = config.Description or ""
            local callback = config.Callback or function() end

            local BFrame = new("Frame", {
                Size = UDim2.new(1,0,0,44),
                BackgroundColor3 = theme.ElementBG,
                BorderSizePixel = 0,
                ZIndex = 4,
            }, Page)
            corner(BFrame, 9)
            stroke(BFrame, theme.Border, 1)

            local BBtn = new("TextButton", {
                Size = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 5,
            }, BFrame)

            new("TextLabel", {
                Size = UDim2.new(1,-16,0,18),
                Position = UDim2.new(0,12,0,7),
                BackgroundTransparency = 1,
                Text = bname,
                TextColor3 = theme.TextPrimary,
                TextSize = 13,
                Font = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 6,
            }, BFrame)

            if desc ~= "" then
                new("TextLabel", {
                    Size = UDim2.new(1,-16,0,14),
                    Position = UDim2.new(0,12,0,25),
                    BackgroundTransparency = 1,
                    Text = desc,
                    TextColor3 = theme.TextMuted,
                    TextSize = 10,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6,
                }, BFrame)
            end

            -- Arrow icon
            new("TextLabel", {
                Size = UDim2.new(0,20,1,0),
                Position = UDim2.new(1,-28,0,0),
                BackgroundTransparency = 1,
                Text = "›",
                TextColor3 = theme.Accent,
                TextSize = 20,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 6,
            }, BFrame)

            BBtn.MouseEnter:Connect(function()
                tween(BFrame, {BackgroundColor3=theme.ElementHover}, 0.15)
            end)
            BBtn.MouseLeave:Connect(function()
                tween(BFrame, {BackgroundColor3=theme.ElementBG}, 0.15)
            end)
            BBtn.MouseButton1Click:Connect(function()
                tween(BFrame, {BackgroundColor3=theme.BG4}, 0.08)
                task.wait(0.08)
                tween(BFrame, {BackgroundColor3=theme.ElementBG}, 0.15)
                local ok, err = pcall(callback)
                if not ok then warn("[Nova] Button callback error: "..tostring(err)) end
            end)

            return {Frame=BFrame}
        end

        -- ---- TOGGLE ----
        function Tab:AddToggle(config)
            config = config or {}
            local tname    = config.Name     or "Toggle"
            local desc     = config.Description or ""
            local default  = config.Default  or false
            local callback = config.Callback or function() end
            local flag     = config.Flag     or nil

            local state = default

            local TFrame = new("Frame", {
                Size = UDim2.new(1,0,0,44),
                BackgroundColor3 = theme.ElementBG,
                BorderSizePixel = 0,
                ZIndex = 4,
            }, Page)
            corner(TFrame, 9)
            stroke(TFrame, theme.Border, 1)

            new("TextLabel", {
                Size = UDim2.new(1,-60,0,18),
                Position = UDim2.new(0,12,0,7),
                BackgroundTransparency = 1,
                Text = tname,
                TextColor3 = theme.TextPrimary,
                TextSize = 13,
                Font = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
            }, TFrame)

            if desc ~= "" then
                new("TextLabel", {
                    Size = UDim2.new(1,-60,0,14),
                    Position = UDim2.new(0,12,0,25),
                    BackgroundTransparency = 1,
                    Text = desc,
                    TextColor3 = theme.TextMuted,
                    TextSize = 10,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 5,
                }, TFrame)
            end

            -- Toggle track
            local Track = new("Frame", {
                Size = UDim2.new(0,42,0,22),
                Position = UDim2.new(1,-54,0.5,-11),
                BackgroundColor3 = state and theme.Accent or theme.ToggleOff,
                BorderSizePixel = 0,
                ZIndex = 5,
            }, TFrame)
            corner(Track, 11)
            stroke(Track, state and theme.Accent or theme.Border, 1, 0.3)

            -- Track gradient
            local trackGrad = new("UIGradient", {
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(180,180,180)),
                }),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.15),
                    NumberSequenceKeypoint.new(1, 0.45),
                }),
            }, Track)

            -- Thumb
            local Thumb = new("Frame", {
                Size = UDim2.new(0,16,0,16),
                Position = UDim2.new(0, state and 22 or 4, 0.5,-8),
                BackgroundColor3 = Color3.fromRGB(255,255,255),
                BorderSizePixel = 0,
                ZIndex = 6,
            }, Track)
            corner(Thumb, 8)
            -- Thumb shadow
            new("UIGradient", {
                Rotation = 135,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(200,200,220)),
                }),
            }, Thumb)

            -- Click zone
            local Clickable = new("TextButton", {
                Size = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 7,
            }, TFrame)

            local ToggleObj = {Value=state}

            local function setState(val, silent)
                state = val
                ToggleObj.Value = val
                if flag then Nova.Flags[flag] = val end
                tween(Track, {BackgroundColor3 = val and theme.Accent or theme.ToggleOff}, 0.22)
                tween(Thumb, {Position = UDim2.new(0, val and 22 or 4, 0.5, -8)}, 0.22, Enum.EasingStyle.Back)
                local s = Track:FindFirstChildWhichIsA("UIStroke")
                if s then tween(s, {Color = val and theme.Accent or theme.Border}, 0.22) end
                if not silent then
                    local ok, err = pcall(callback, val)
                    if not ok then warn("[Nova] Toggle callback: "..tostring(err)) end
                end
            end

            Clickable.MouseEnter:Connect(function()
                tween(TFrame, {BackgroundColor3=theme.ElementHover}, 0.15)
            end)
            Clickable.MouseLeave:Connect(function()
                tween(TFrame, {BackgroundColor3=theme.ElementBG}, 0.15)
            end)
            Clickable.MouseButton1Click:Connect(function()
                setState(not state)
            end)

            if default then setState(true, true) end

            function ToggleObj:Set(val) setState(val, false) end
            function ToggleObj:Get() return state end

            return ToggleObj
        end

        -- ---- SLIDER ----
        function Tab:AddSlider(config)
            config = config or {}
            local sname    = config.Name     or "Slider"
            local desc     = config.Description or ""
            local min      = config.Min      or 0
            local max      = config.Max      or 100
            local default  = config.Default  or min
            local step     = config.Step     or 1
            local suffix   = config.Suffix   or ""
            local callback = config.Callback or function() end
            local flag     = config.Flag     or nil

            local value = math.clamp(default, min, max)

            local SFrame = new("Frame", {
                Size = UDim2.new(1,0,0,54),
                BackgroundColor3 = theme.ElementBG,
                BorderSizePixel = 0,
                ZIndex = 4,
            }, Page)
            corner(SFrame, 9)
            stroke(SFrame, theme.Border, 1)

            local nameLabel = new("TextLabel", {
                Size = UDim2.new(1,-90,0,18),
                Position = UDim2.new(0,12,0,7),
                BackgroundTransparency = 1,
                Text = sname,
                TextColor3 = theme.TextPrimary,
                TextSize = 13,
                Font = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
            }, SFrame)

            local valLabel = new("TextLabel", {
                Size = UDim2.new(0,80,0,18),
                Position = UDim2.new(1,-90,0,7),
                BackgroundTransparency = 1,
                Text = tostring(value)..suffix,
                TextColor3 = theme.AccentLight,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 5,
            }, SFrame)

            -- Track bg
            local TrackBG = new("Frame", {
                Size = UDim2.new(1,-24,0,6),
                Position = UDim2.new(0,12,0,34),
                BackgroundColor3 = theme.SliderTrack,
                BorderSizePixel = 0,
                ZIndex = 5,
            }, SFrame)
            corner(TrackBG, 3)

            -- Fill
            local pct = (value-min)/(max-min)
            local Fill = new("Frame", {
                Size = UDim2.new(pct, 0, 1, 0),
                BackgroundColor3 = theme.Accent,
                BorderSizePixel = 0,
                ZIndex = 6,
            }, TrackBG)
            corner(Fill, 3)
            new("UIGradient", {
                Rotation = 0,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(108,99,255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(168,85,247)),
                }),
            }, Fill)

            -- Handle
            local Handle = new("Frame", {
                Size = UDim2.new(0,14,0,14),
                Position = UDim2.new(pct, -7, 0.5,-7),
                BackgroundColor3 = Color3.fromRGB(255,255,255),
                BorderSizePixel = 0,
                ZIndex = 7,
            }, TrackBG)
            corner(Handle, 7)

            local SliderObj = {Value=value}

            local function setValue(val, silent)
                val = math.clamp(math.round(val/step)*step, min, max)
                value = val
                SliderObj.Value = val
                if flag then Nova.Flags[flag] = val end
                local p = (val-min)/(max-min)
                tween(Fill, {Size=UDim2.new(p,0,1,0)}, 0.1)
                tween(Handle, {Position=UDim2.new(p,-7,0.5,-7)}, 0.1)
                valLabel.Text = tostring(val)..suffix
                if not silent then
                    local ok,err = pcall(callback, val)
                    if not ok then warn("[Nova] Slider callback: "..tostring(err)) end
                end
            end

            local sliding = false
            local ClickZone = new("TextButton", {
                Size = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1,
                Text = "", ZIndex = 8,
            }, SFrame)

            ClickZone.MouseButton1Down:Connect(function()
                sliding = true
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliding = false
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    local trackAbs = TrackBG.AbsolutePosition
                    local trackW   = TrackBG.AbsoluteSize.X
                    local mx       = inp.Position.X
                    local rel      = math.clamp((mx - trackAbs.X)/trackW, 0, 1)
                    setValue(min + rel*(max-min))
                end
            end)

            ClickZone.MouseEnter:Connect(function()
                tween(SFrame, {BackgroundColor3=theme.ElementHover}, 0.15)
            end)
            ClickZone.MouseLeave:Connect(function()
                tween(SFrame, {BackgroundColor3=theme.ElementBG}, 0.15)
            end)

            setValue(default, true)

            function SliderObj:Set(val) setValue(val, false) end
            function SliderObj:Get() return value end
            return SliderObj
        end

        -- ---- DROPDOWN ----
        function Tab:AddDropdown(config)
            config = config or {}
            local dname    = config.Name     or "Dropdown"
            local options  = config.Options  or {}
            local default  = config.Default  or nil
            local callback = config.Callback or function() end
            local flag     = config.Flag     or nil

            local selected = default
            local opened   = false

            local DFrame = new("Frame", {
                Size = UDim2.new(1,0,0,44),
                BackgroundColor3 = theme.ElementBG,
                BorderSizePixel = 0,
                ZIndex = 10,
                ClipsDescendants = false,
            }, Page)
            corner(DFrame, 9)
            stroke(DFrame, theme.Border, 1)

            new("TextLabel", {
                Size = UDim2.new(1,-55,0,44),
                Position = UDim2.new(0,12,0,0),
                BackgroundTransparency = 1,
                Text = dname,
                TextColor3 = theme.TextPrimary,
                TextSize = 13,
                Font = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 11,
            }, DFrame)

            local selLabel = new("TextLabel", {
                Size = UDim2.new(0,100,0,44),
                Position = UDim2.new(1,-115,0,0),
                BackgroundTransparency = 1,
                Text = selected or "Select...",
                TextColor3 = selected and theme.AccentLight or theme.TextMuted,
                TextSize = 11,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 11,
            }, DFrame)

            -- Arrow
            local arrow = new("TextLabel", {
                Size = UDim2.new(0,20,0,44),
                Position = UDim2.new(1,-24,0,0),
                BackgroundTransparency = 1,
                Text = "▾",
                TextColor3 = theme.Accent,
                TextSize = 14,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 11,
            }, DFrame)

            -- Dropdown list
            local DropList = new("Frame", {
                Size = UDim2.new(1,0,0,0),
                Position = UDim2.new(0,0,1,4),
                BackgroundColor3 = theme.BG3,
                BorderSizePixel = 0,
                ZIndex = 20,
                ClipsDescendants = true,
            }, DFrame)
            corner(DropList, 8)
            stroke(DropList, theme.Border, 1)

            local DropScroll = new("ScrollingFrame", {
                Size = UDim2.new(1,-4,1,-4),
                Position = UDim2.new(0,2,0,2),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = theme.Accent,
                CanvasSize = UDim2.new(0,0,0,0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ZIndex = 21,
            }, DropList)
            listLayout(DropScroll, 2, Enum.HorizontalAlignment.Center)
            padding(DropScroll, 4, 4, 0, 0)

            local DropObj = {Value=selected}

            local function closeDropdown()
                opened = false
                tween(DropList, {Size=UDim2.new(1,0,0,0)}, 0.2, Enum.EasingStyle.Quart)
                tween(arrow, {Rotation=0}, 0.2)
            end

            local function setSelected(val)
                selected = val
                DropObj.Value = val
                if flag then Nova.Flags[flag] = val end
                selLabel.Text = val
                tween(selLabel, {TextColor3=theme.AccentLight}, 0.15)
                closeDropdown()
                local ok,err = pcall(callback, val)
                if not ok then warn("[Nova] Dropdown callback: "..tostring(err)) end
            end

            local function buildOptions()
                for _, child in ipairs(DropScroll:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, opt in ipairs(options) do
                    local optBtn = new("TextButton", {
                        Size = UDim2.new(1,-6,0,30),
                        BackgroundColor3 = opt==selected and theme.BG4 or theme.BG3,
                        BackgroundTransparency = 0,
                        Text = opt,
                        TextColor3 = opt==selected and theme.AccentLight or theme.TextSub,
                        TextSize = 12,
                        Font = opt==selected and Enum.Font.GothamSemibold or Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 22,
                    }, DropScroll)
                    corner(optBtn, 6)
                    padding(optBtn, 0,0,10,0)
                    optBtn.MouseEnter:Connect(function()
                        tween(optBtn, {BackgroundColor3=theme.ElementHover}, 0.1)
                    end)
                    optBtn.MouseLeave:Connect(function()
                        tween(optBtn, {BackgroundColor3=opt==selected and theme.BG4 or theme.BG3}, 0.1)
                    end)
                    optBtn.MouseButton1Click:Connect(function()
                        setSelected(opt)
                        buildOptions()
                    end)
                end
            end
            buildOptions()

            local HeaderBtn = new("TextButton", {
                Size = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1,
                Text = "", ZIndex = 12,
            }, DFrame)

            HeaderBtn.MouseEnter:Connect(function()
                tween(DFrame, {BackgroundColor3=theme.ElementHover}, 0.15)
            end)
            HeaderBtn.MouseLeave:Connect(function()
                tween(DFrame, {BackgroundColor3=theme.ElementBG}, 0.15)
            end)
            HeaderBtn.MouseButton1Click:Connect(function()
                opened = not opened
                if opened then
                    local itemH = math.min(#options, 5) * 34 + 8
                    tween(DropList, {Size=UDim2.new(1,0,0,itemH)}, 0.25, Enum.EasingStyle.Back)
                    tween(arrow, {Rotation=180}, 0.2)
                else
                    closeDropdown()
                end
            end)

            function DropObj:Set(val)
                selected = val
                self.Value = val
                selLabel.Text = val
                buildOptions()
            end
            function DropObj:Refresh(opts)
                options = opts
                buildOptions()
            end
            return DropObj
        end

        -- ---- TEXT INPUT ----
        function Tab:AddTextbox(config)
            config = config or {}
            local iname    = config.Name        or "Textbox"
            local ph       = config.Placeholder or "Type here..."
            local default  = config.Default     or ""
            local callback = config.Callback    or function() end
            local flag     = config.Flag        or nil

            local IFrame = new("Frame", {
                Size = UDim2.new(1,0,0,44),
                BackgroundColor3 = theme.ElementBG,
                BorderSizePixel = 0,
                ZIndex = 4,
            }, Page)
            corner(IFrame, 9)
            stroke(IFrame, theme.Border, 1)

            new("TextLabel", {
                Size = UDim2.new(0.45,0,0,44),
                Position = UDim2.new(0,12,0,0),
                BackgroundTransparency = 1,
                Text = iname,
                TextColor3 = theme.TextPrimary,
                TextSize = 13,
                Font = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
            }, IFrame)

            local inputBG = new("Frame", {
                Size = UDim2.new(0.5,-16,0,26),
                Position = UDim2.new(0.5,4,0.5,-13),
                BackgroundColor3 = theme.BG4,
                BorderSizePixel = 0,
                ZIndex = 5,
            }, IFrame)
            corner(inputBG, 6)
            stroke(inputBG, theme.Border, 1)

            local box = new("TextBox", {
                Size = UDim2.new(1,-12,1,0),
                Position = UDim2.new(0,6,0,0),
                BackgroundTransparency = 1,
                Text = default,
                PlaceholderText = ph,
                PlaceholderColor3 = theme.TextMuted,
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                ZIndex = 6,
            }, inputBG)

            box.Focused:Connect(function()
                tween(inputBG, {BackgroundColor3=theme.BG3}, 0.15)
                local s = inputBG:FindFirstChildWhichIsA("UIStroke")
                if s then tween(s, {Color=theme.Accent}, 0.15) end
            end)
            box.FocusLost:Connect(function(enter)
                tween(inputBG, {BackgroundColor3=theme.BG4}, 0.15)
                local s = inputBG:FindFirstChildWhichIsA("UIStroke")
                if s then tween(s, {Color=theme.Border}, 0.15) end
                if flag then Nova.Flags[flag] = box.Text end
                local ok,err = pcall(callback, box.Text, enter)
                if not ok then warn("[Nova] Textbox callback: "..tostring(err)) end
            end)

            local InputObj = {Value=default}
            function InputObj:Set(t) box.Text = t end
            function InputObj:Get() return box.Text end
            return InputObj
        end

        -- ---- KEYBIND ----
        function Tab:AddKeybind(config)
            config = config or {}
            local kname    = config.Name     or "Keybind"
            local default  = config.Default  or Enum.KeyCode.Unknown
            local callback = config.Callback or function() end
            local flag     = config.Flag     or nil

            local bound = default
            local listening = false

            local KFrame = new("Frame", {
                Size = UDim2.new(1,0,0,44),
                BackgroundColor3 = theme.ElementBG,
                BorderSizePixel = 0,
                ZIndex = 4,
            }, Page)
            corner(KFrame, 9)
            stroke(KFrame, theme.Border, 1)

            new("TextLabel", {
                Size = UDim2.new(1,-100,0,44),
                Position = UDim2.new(0,12,0,0),
                BackgroundTransparency = 1,
                Text = kname,
                TextColor3 = theme.TextPrimary,
                TextSize = 13,
                Font = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
            }, KFrame)

            local keyBG = new("Frame", {
                Size = UDim2.new(0,80,0,26),
                Position = UDim2.new(1,-90,0.5,-13),
                BackgroundColor3 = theme.BG4,
                BorderSizePixel = 0,
                ZIndex = 5,
            }, KFrame)
            corner(keyBG, 6)
            stroke(keyBG, theme.Border, 1)

            local keyLabel = new("TextButton", {
                Size = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1,
                Text = bound.Name,
                TextColor3 = theme.AccentLight,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                ZIndex = 6,
            }, keyBG)

            keyLabel.MouseButton1Click:Connect(function()
                listening = true
                keyLabel.Text = "..."
                tween(keyBG, {BackgroundColor3=theme.BG3}, 0.15)
                local s = keyBG:FindFirstChildWhichIsA("UIStroke")
                if s then tween(s, {Color=theme.Accent}, 0.15) end
            end)

            UserInputService.InputBegan:Connect(function(input, gpe)
                if not listening then
                    if input.KeyCode == bound then
                        local ok,err = pcall(callback, bound)
                        if not ok then warn("[Nova] Keybind callback: "..tostring(err)) end
                    end
                    return
                end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    listening = false
                    bound = input.KeyCode
                    if flag then Nova.Flags[flag] = bound end
                    keyLabel.Text = bound.Name
                    tween(keyBG, {BackgroundColor3=theme.BG4}, 0.15)
                    local s = keyBG:FindFirstChildWhichIsA("UIStroke")
                    if s then tween(s, {Color=theme.Border}, 0.15) end
                end
            end)

            local BindObj = {Value=bound}
            function BindObj:Set(k) bound = k BindObj.Value = k keyLabel.Text = k.Name end
            function BindObj:Get() return bound end
            return BindObj
        end

        -- ---- COLOR PICKER ----
        function Tab:AddColorpicker(config)
            config = config or {}
            local cname    = config.Name     or "Color"
            local default  = config.Default  or Color3.fromRGB(255,255,255)
            local callback = config.Callback or function() end
            local flag     = config.Flag     or nil

            local color = default
            local opened = false

            local CFrame = new("Frame", {
                Size = UDim2.new(1,0,0,44),
                BackgroundColor3 = theme.ElementBG,
                BorderSizePixel = 0,
                ZIndex = 4,
                ClipsDescendants = false,
            }, Page)
            corner(CFrame, 9)
            stroke(CFrame, theme.Border, 1)

            new("TextLabel", {
                Size = UDim2.new(1,-60,0,44),
                Position = UDim2.new(0,12,0,0),
                BackgroundTransparency = 1,
                Text = cname,
                TextColor3 = theme.TextPrimary,
                TextSize = 13,
                Font = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
            }, CFrame)

            local preview = new("Frame", {
                Size = UDim2.new(0,28,0,28),
                Position = UDim2.new(1,-40,0.5,-14),
                BackgroundColor3 = color,
                BorderSizePixel = 0,
                ZIndex = 5,
            }, CFrame)
            corner(preview, 6)
            stroke(preview, theme.Border, 1)

            -- Simple hue strip picker panel
            local Panel = new("Frame", {
                Size = UDim2.new(1,0,0,0),
                Position = UDim2.new(0,0,1,4),
                BackgroundColor3 = theme.BG3,
                BorderSizePixel = 0,
                ZIndex = 15,
                ClipsDescendants = true,
            }, CFrame)
            corner(Panel, 8)
            stroke(Panel, theme.Border, 1)

            local hueBar = new("Frame", {
                Size = UDim2.new(1,-16,0,16),
                Position = UDim2.new(0,8,0,8),
                BackgroundColor3 = Color3.fromRGB(255,255,255),
                BorderSizePixel = 0,
                ZIndex = 16,
            }, Panel)
            corner(hueBar, 4)
            new("UIGradient", {
                Rotation = 0,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0,    Color3.fromRGB(255,0,0)),
                    ColorSequenceKeypoint.new(0.166, Color3.fromRGB(255,165,0)),
                    ColorSequenceKeypoint.new(0.333, Color3.fromRGB(255,255,0)),
                    ColorSequenceKeypoint.new(0.5,   Color3.fromRGB(0,255,0)),
                    ColorSequenceKeypoint.new(0.666, Color3.fromRGB(0,0,255)),
                    ColorSequenceKeypoint.new(0.833, Color3.fromRGB(148,0,211)),
                    ColorSequenceKeypoint.new(1,     Color3.fromRGB(255,0,0)),
                }),
            }, hueBar)

            -- Hue cursor
            local hueCursor = new("Frame", {
                Size = UDim2.new(0,6,1,4),
                Position = UDim2.new(0,-3,0,-2),
                BackgroundColor3 = Color3.fromRGB(255,255,255),
                BorderSizePixel = 0,
                ZIndex = 17,
            }, hueBar)
            corner(hueCursor, 3)
            stroke(hueCursor, theme.Border, 1)

            -- Hex label
            local hexLabel = new("TextLabel", {
                Size = UDim2.new(1,-16,0,20),
                Position = UDim2.new(0,8,0,30),
                BackgroundTransparency = 1,
                Text = string.format("#%02X%02X%02X", math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255)),
                TextColor3 = theme.TextSub,
                TextSize = 11,
                Font = Enum.Font.Code,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 16,
            }, Panel)

            local ColorObj = {Value=color}

            local function setColor(c, silent)
                color = c
                ColorObj.Value = c
                if flag then Nova.Flags[flag] = c end
                preview.BackgroundColor3 = c
                hexLabel.Text = string.format("#%02X%02X%02X", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
                if not silent then
                    local ok,err = pcall(callback, c)
                    if not ok then warn("[Nova] Colorpicker callback: "..tostring(err)) end
                end
            end

            -- Hue drag
            local hueDragging = false
            hueBar.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    hueDragging = true
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    hueDragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if hueDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    local rel = math.clamp((inp.Position.X - hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X,0,1)
                    hueCursor.Position = UDim2.new(rel,-3,0,-2)
                    setColor(Color3.fromHSV(rel, 1, 1))
                end
            end)

            local toggle = new("TextButton", {
                Size = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1,
                Text = "", ZIndex = 6,
            }, CFrame)

            toggle.MouseButton1Click:Connect(function()
                opened = not opened
                if opened then
                    tween(Panel, {Size=UDim2.new(1,0,0,58)}, 0.25, Enum.EasingStyle.Back)
                else
                    tween(Panel, {Size=UDim2.new(1,0,0,0)}, 0.2)
                end
            end)
            toggle.MouseEnter:Connect(function() tween(CFrame, {BackgroundColor3=theme.ElementHover}, 0.15) end)
            toggle.MouseLeave:Connect(function() tween(CFrame, {BackgroundColor3=theme.ElementBG}, 0.15) end)

            setColor(default, true)

            function ColorObj:Set(c) setColor(c, false) end
            function ColorObj:Get() return color end
            return ColorObj
        end

        return Tab
    end -- CreateTab

    ------------------------------------------------------------------
    -- Destroy
    ------------------------------------------------------------------
    function Window:Destroy()
        ScreenGui:Destroy()
    end

    return Window
end -- CreateWindow

------------------------------------------------------------------------
-- Flags (shared state store)
------------------------------------------------------------------------
Nova.Flags = {}

------------------------------------------------------------------------
-- Return
------------------------------------------------------------------------
return Nova
