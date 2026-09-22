--[[
    Sleek Dark UI Library v2
    - Sidebar trái, indicator bar mượt theo tab đang chọn
    - User box dưới sidebar (avatar + tên)
    - Notification system góc màn hình
    - Hover + easing mượt (Quint/Back) trên mọi element
    - Elements: Label, Button, Toggle, Slider, Dropdown, Textbox
    Xem "EXAMPLE USAGE" ở cuối file
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.__index = Library

-- ================= THEME =================
local Theme = {
    Background = Color3.fromRGB(18, 18, 20),
    Sidebar    = Color3.fromRGB(13, 13, 15),
    Section    = Color3.fromRGB(24, 24, 27),
    ElementBG  = Color3.fromRGB(30, 30, 34),
    Stroke     = Color3.fromRGB(42, 42, 47),
    Accent     = Color3.fromRGB(138, 105, 255),
    AccentDim  = Color3.fromRGB(90, 70, 170),
    Text       = Color3.fromRGB(240, 240, 245),
    SubText    = Color3.fromRGB(140, 140, 150),
}

local EASE_OUT = Enum.EasingStyle.Quint
local EASE_POP = Enum.EasingStyle.Back

-- ================= HELPERS =================
local function create(class, props, children)
    local inst = Instance.new(class)
    for prop, value in pairs(props or {}) do inst[prop] = value end
    for _, child in ipairs(children or {}) do child.Parent = inst end
    return inst
end

local function tween(inst, props, time, style, dir)
    return TweenService:Create(inst, TweenInfo.new(time or 0.22, style or EASE_OUT, dir or Enum.EasingDirection.Out), props)
end

local function corner(r) return create("UICorner", { CornerRadius = UDim.new(0, r or 8) }) end
local function stroke(color, thick, transparency)
    return create("UIStroke", { Color = color or Theme.Stroke, Thickness = thick or 1, Transparency = transparency or 0 })
end

local function hoverFx(btn, baseColor, hoverColor)
    btn.MouseEnter:Connect(function() tween(btn, { BackgroundColor3 = hoverColor }, 0.15):Play() end)
    btn.MouseLeave:Connect(function() tween(btn, { BackgroundColor3 = baseColor }, 0.15):Play() end)
end

local function makeDraggable(topbar, frame)
    local dragging, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ================= WINDOW =================
function Library:CreateWindow(config)
    config = config or {}
    local title = config.Title or "UI Library"
    local size = config.Size or UDim2.fromOffset(540, 360)

    local screenGui = create("ScreenGui", {
        Name = "SleekDarkUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = gethui and gethui() or game:GetService("CoreGui"),
    })

    -- Notification holder (top-right)
    local notifHolder = create("Frame", {
        Size = UDim2.new(0, 260, 1, -20),
        Position = UDim2.new(1, -272, 0, 10),
        BackgroundTransparency = 1,
        Parent = screenGui,
    }, { create("UIListLayout", { Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder }) })

    local main = create("Frame", {
        Name = "Main",
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = screenGui,
    }, { corner(10), stroke(Theme.Stroke, 1) })

    -- open animation
    main.Size = UDim2.new(size.X.Scale, size.X.Offset, 0, 0)
    task.defer(function()
        tween(main, { BackgroundTransparency = 0 }, 0.25):Play()
        tween(main, { Size = size }, 0.35, EASE_OUT):Play()
    end)

    local topbar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Sidebar,
        Parent = main,
    }, {
        corner(10),
        create("TextLabel", {
            Text = title, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Text,
            BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -28, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
    })
    makeDraggable(topbar, main)

    -- Sidebar --------------------------------------------------------
    local sidebar = create("Frame", {
        Size = UDim2.new(0, 145, 1, -36),
        Position = UDim2.new(0, 0, 0, 36),
        BackgroundColor3 = Theme.Sidebar,
        Parent = main,
    })

    local tabList = create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -58),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = sidebar,
    }, {
        create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }),
        create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
    })

    -- indicator bar that glides between tabs
    local indicator = create("Frame", {
        Size = UDim2.new(0, 3, 0, 22),
        BackgroundColor3 = Theme.Accent,
        Position = UDim2.new(0, 0, 0, 10),
        Parent = sidebar,
        ZIndex = 5,
    }, { corner(2) })

    -- User box ---------------------------------------------------------
    local userBox = create("Frame", {
        Size = UDim2.new(1, -16, 0, 48),
        Position = UDim2.new(0, 8, 1, -56),
        BackgroundColor3 = Theme.Section,
        Parent = sidebar,
    }, { corner(8), stroke(Theme.Stroke, 1) })

    local avatarUrl = ("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150&format=png"):format(LocalPlayer.UserId)
    create("ImageLabel", {
        Size = UDim2.fromOffset(30, 30), Position = UDim2.new(0, 9, 0.5, -15),
        BackgroundTransparency = 1, Image = avatarUrl, Parent = userBox,
    }, { corner(15) })
    create("TextLabel", {
        Text = LocalPlayer.DisplayName, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.new(0, 46, 0, 7), Size = UDim2.new(1, -54, 0, 14), Parent = userBox,
    })
    create("TextLabel", {
        Text = "@" .. LocalPlayer.Name, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.new(0, 46, 0, 22), Size = UDim2.new(1, -54, 0, 14), Parent = userBox,
    })

    -- Page container -----------------------------------------------------
    local pageContainer = create("Frame", {
        Size = UDim2.new(1, -145, 1, -36),
        Position = UDim2.new(0, 145, 0, 36),
        BackgroundTransparency = 1,
        Parent = main,
    })

    local Window = { Tabs = {} }
    local firstTab = true

    -- Notification API
    function Window:Notify(titleText, body, duration)
        duration = duration or 3
        local notif = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme.Section, BackgroundTransparency = 1,
            Parent = notifHolder, ClipsDescendants = true,
        }, {
            corner(8), stroke(Theme.Stroke, 1, 1),
            create("UIPadding", { PaddingTop = UDim.new(0,10), PaddingBottom = UDim.new(0,10), PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,12) }),
        })
        create("TextLabel", {
            Text = titleText, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.Text,
            BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
            Size = UDim2.new(1, 0, 0, 16), Parent = notif,
        })
        create("TextLabel", {
            Text = body or "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.SubText,
            BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
            Position = UDim2.new(0,0,0,18), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            Parent = notif,
        })
        notif.Position = UDim2.new(1.1, 0, 0, 0)
        tween(notif, { BackgroundTransparency = 0, Position = UDim2.new(0,0,0,0) }, 0.3, EASE_OUT):Play()
        for _, d in ipairs(notif:GetDescendants()) do
            if d:IsA("UIStroke") then tween(d, { Transparency = 0 }, 0.3):Play() end
        end
        task.delay(duration, function()
            local t = tween(notif, { BackgroundTransparency = 1, Position = UDim2.new(1.1, 0, 0, 0) }, 0.25, EASE_OUT)
            t:Play()
            t.Completed:Wait()
            notif:Destroy()
        end)
    end

    function Window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local name = tabConfig.Name or "Tab"

        local button = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Theme.ElementBG,
            BackgroundTransparency = firstTab and 0.4 or 1,
            AutoButtonColor = false,
            Text = "  " .. name,
            Font = firstTab and Enum.Font.GothamBold or Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = firstTab and Theme.Text or Theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = tabList,
        }, { corner(6) })

        local page = create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = firstTab,
            Position = UDim2.new(0, 0, 0, 0),
            Parent = pageContainer,
        }, {
            create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
            create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12) }),
        })

        if firstTab then
            task.defer(function()
                indicator.Position = UDim2.new(0, 0, 0, button.Position.Y.Offset + 10)
            end)
        end
        firstTab = false

        button.MouseEnter:Connect(function()
            if button.TextColor3 ~= Theme.Text then tween(button, { BackgroundTransparency = 0.7 }, 0.15):Play() end
        end)
        button.MouseLeave:Connect(function()
            if button.TextColor3 ~= Theme.Text then tween(button, { BackgroundTransparency = 1 }, 0.15):Play() end
        end)

        button.MouseButton1Click:Connect(function()
            for _, t in pairs(Window.Tabs) do
                t.Page.Visible = false
                tween(t.Button, { BackgroundTransparency = 1 }, 0.18):Play()
                t.Button.Font = Enum.Font.Gotham
                t.Button.TextColor3 = Theme.SubText
            end
            page.Visible = true
            tween(button, { BackgroundTransparency = 0.4 }, 0.18):Play()
            button.Font = Enum.Font.GothamBold
            button.TextColor3 = Theme.Text
            tween(indicator, { Position = UDim2.new(0, 0, 0, button.AbsolutePosition.Y - sidebar.AbsolutePosition.Y + 5) }, 0.25, EASE_OUT):Play()
            page.Position = UDim2.new(0, 8, 0, 0)
            page.BackgroundTransparency = 1
            tween(page, { Position = UDim2.new(0, 0, 0, 0) }, 0.2, EASE_OUT):Play()
        end)

        local Tab = { Button = button, Page = page }

        -- ---------- Elements ----------
        function Tab:AddLabel(text)
            create("TextLabel", {
                Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.SubText,
                BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 18), Parent = page,
            })
        end

        function Tab:AddButton(text, callback)
            local btn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.ElementBG,
                Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Text,
                AutoButtonColor = false, Parent = page,
            }, { corner(7), stroke(Theme.Stroke, 1) })
            hoverFx(btn, Theme.ElementBG, Color3.fromRGB(40, 40, 46))
            btn.MouseButton1Click:Connect(function()
                tween(btn, { BackgroundColor3 = Theme.Accent }, 0.1):Play()
                task.wait(0.1)
                tween(btn, { BackgroundColor3 = Theme.ElementBG }, 0.2):Play()
                if callback then callback() end
            end)
            return btn
        end

        function Tab:AddToggle(text, default, callback)
            local state = default or false
            local holder = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.ElementBG,
                Text = "", AutoButtonColor = false, Parent = page,
            }, { corner(7), stroke(Theme.Stroke, 1) })
            hoverFx(holder, Theme.ElementBG, Color3.fromRGB(40, 40, 46))
            create("TextLabel", {
                Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Text,
                BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -60, 1, 0), Parent = holder,
            })
            local track = create("Frame", {
                Size = UDim2.fromOffset(38, 20), Position = UDim2.new(1, -50, 0.5, -10),
                BackgroundColor3 = state and Theme.Accent or Theme.Section, Parent = holder,
            }, { corner(10) })
            local circle = create("Frame", {
                Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, state and 20 or 2, 0.5, -8),
                BackgroundColor3 = Color3.fromRGB(255,255,255), Parent = track,
            }, { corner(8) })

            holder.MouseButton1Click:Connect(function()
                state = not state
                tween(circle, { Position = UDim2.new(0, state and 20 or 2, 0.5, -8) }, 0.2, EASE_POP):Play()
                tween(track, { BackgroundColor3 = state and Theme.Accent or Theme.Section }, 0.2):Play()
                if callback then callback(state) end
            end)
            return holder
        end

        function Tab:AddSlider(text, min, max, default, callback)
            min, max = min or 0, max or 100
            local value = default or min
            local holder = create("Frame", {
                Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = Theme.ElementBG, Parent = page,
            }, { corner(7), stroke(Theme.Stroke, 1) })
            local label = create("TextLabel", {
                Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Text,
                BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 12, 0, 5), Size = UDim2.new(0.6, 0, 0, 16), Parent = holder,
            })
            local valLabel = create("TextLabel", {
                Text = tostring(value), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Accent,
                BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right,
                Position = UDim2.new(0.6, 0, 0, 5), Size = UDim2.new(0.4, -12, 0, 16), Parent = holder,
            })
            local bar = create("Frame", {
                Size = UDim2.new(1, -24, 0, 5), Position = UDim2.new(0, 12, 0, 30),
                BackgroundColor3 = Theme.Section, Parent = holder,
            }, { corner(3) })
            local fill = create("Frame", {
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = Theme.Accent, Parent = bar,
            }, { corner(3) })
            local knob = create("Frame", {
                Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
                BackgroundColor3 = Color3.fromRGB(255,255,255), Parent = bar, ZIndex = 3,
            }, { corner(6) })

            local dragging = false
            local function setFromInput(x)
                local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * rel)
                fill.Size = UDim2.new(rel, 0, 1, 0)
                knob.Position = UDim2.new(rel, 0, 0.5, 0)
                valLabel.Text = tostring(value)
                if callback then callback(value) end
            end
            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    setFromInput(input.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    setFromInput(input.Position.X)
                end
            end)
            return holder
        end

        function Tab:AddDropdown(text, options, default, callback)
            options = options or {}
            local selected = default or options[1]
            local open = false

            local holder = create("Frame", {
                Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.ElementBG,
                ClipsDescendants = true, Parent = page,
            }, { corner(7), stroke(Theme.Stroke, 1) })

            local head = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = holder,
            })
            create("TextLabel", {
                Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Text,
                BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.5, 0, 0, 34), Parent = head,
            })
            local valueLabel = create("TextLabel", {
                Text = tostring(selected), Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.SubText,
                BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right,
                Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, -30, 0, 34), Parent = head,
            })
            local arrow = create("TextLabel", {
                Text = "▾", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.SubText,
                BackgroundTransparency = 1, Position = UDim2.new(1, -22, 0, 0), Size = UDim2.new(0, 16, 0, 34), Parent = head,
            })

            local list = create("Frame", {
                Position = UDim2.new(0, 6, 0, 36), Size = UDim2.new(1, -12, 0, #options * 26),
                BackgroundTransparency = 1, Parent = holder,
            }, { create("UIListLayout", { Padding = UDim.new(0,2), SortOrder = Enum.SortOrder.LayoutOrder }) })

            for _, opt in ipairs(options) do
                local optBtn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = Theme.Section,
                    Text = "  " .. tostring(opt), Font = Enum.Font.Gotham, TextSize = 12,
                    TextColor3 = Theme.SubText, AutoButtonColor = false,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = list,
                }, { corner(5) })
                hoverFx(optBtn, Theme.Section, Color3.fromRGB(38,38,42))
                optBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    valueLabel.Text = tostring(opt)
                    open = false
                    tween(holder, { Size = UDim2.new(1, 0, 0, 34) }, 0.2, EASE_OUT):Play()
                    tween(arrow, { Rotation = 0 }, 0.2):Play()
                    if callback then callback(opt) end
                end)
            end

            head.MouseButton1Click:Connect(function()
                open = not open
                local targetSize = open and UDim2.new(1, 0, 0, 40 + #options * 26) or UDim2.new(1, 0, 0, 34)
                tween(holder, { Size = targetSize }, 0.22, EASE_OUT):Play()
                tween(arrow, { Rotation = open and 180 or 0 }, 0.22):Play()
            end)
            return holder
        end

        function Tab:AddTextbox(text, placeholder, callback)
            local holder = create("Frame", {
                Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.ElementBG, Parent = page,
            }, { corner(7), stroke(Theme.Stroke, 1) })
            create("TextLabel", {
                Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Text,
                BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.4, 0, 1, 0), Parent = holder,
            })
            local box = create("TextBox", {
                PlaceholderText = placeholder or "", Text = "", Font = Enum.Font.Gotham, TextSize = 13,
                TextColor3 = Theme.Text, BackgroundColor3 = Theme.Section, ClearTextOnFocus = false,
                Position = UDim2.new(0.42, 0, 0.5, -12), Size = UDim2.new(0.55, -12, 0, 24), Parent = holder,
            }, { corner(5), create("UIPadding", { PaddingLeft = UDim.new(0,8) }) })
            box.FocusLost:Connect(function(enterPressed)
                if callback then callback(box.Text, enterPressed) end
            end)
            return holder
        end

        Window.Tabs[#Window.Tabs + 1] = Tab
        return Tab
    end

    return Window
end

-- ================= EXAMPLE USAGE =================
--[[
local Lib = loadstring(game:HttpGet("URL_CUA_BAN"))()
local Window = Lib:CreateWindow({ Title = "My Hub", Size = UDim2.fromOffset(540, 360) })

local MainTab = Window:CreateTab({ Name = "Main" })
MainTab:AddLabel("Cài đặt chung")
MainTab:AddButton("Click me", function() Window:Notify("Đã bấm!", "Button vừa được click.", 3) end)
MainTab:AddToggle("Auto Farm", false, function(v) print("toggle:", v) end)
MainTab:AddSlider("Speed", 0, 100, 16, function(v) print("slider:", v) end)
MainTab:AddDropdown("Mode", {"A", "B", "C"}, "A", function(v) print("dropdown:", v) end)
MainTab:AddTextbox("Note", "type here...", function(text) print("text:", text) end)

local Tab2 = Window:CreateTab({ Name = "Settings" })
Tab2:AddLabel("Tab thứ 2")
]]

return Library
