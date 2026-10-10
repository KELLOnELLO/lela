local KeySystem = {}
KeySystem.__index = KeySystem

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local VALID_KEYS = {
    ["220384"] = { tier = "Premium", expires = 0, note = "permanent" },
    ["c2fa-raxcl-12fab"] = { tier = "Lifetime", expires = 0, note = "lifetime" },
}

local SAVE_FILE = "void_key.json"

local Theme = {
    Bg        = Color3.fromRGB(16, 16, 20),
    Panel     = Color3.fromRGB(22, 22, 28),
    PanelLt   = Color3.fromRGB(30, 30, 37),
    Hover     = Color3.fromRGB(40, 40, 48),
    Stroke    = Color3.fromRGB(48, 48, 58),
    Text      = Color3.fromRGB(238, 238, 242),
    Sub       = Color3.fromRGB(140, 140, 155),
    Accent    = Color3.fromRGB(160, 100, 255),
    Red       = Color3.fromRGB(220, 70, 70),
    Green     = Color3.fromRGB(80, 200, 120),
}

local function new(cls, props)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do o[k] = v end
    return o
end

local function corner(p, r)
    return new("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = p })
end

local function stroke(p)
    return new("UIStroke", { Color = Theme.Stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p })
end

local function safeParent(g)
    pcall(function() g.Parent = CoreGui end)
    if not g.Parent then
        pcall(function() g.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
    end
end

local function validate(key)
    if type(key) ~= "string" then return false, nil end
    key = key:gsub("%s+", "")
    local info = VALID_KEYS[key]
    if info then
        return true, info
    end
    return false, nil
end

local function saveKey(key, info)
    if not writefile then return end
    pcall(function()
        writefile(SAVE_FILE, HttpService:JSONEncode({
            key = key,
            tier = info.tier,
            saved = os.time(),
        }))
    end)
end

local function loadSavedKey()
    if not isfile or not isfile(SAVE_FILE) then return nil end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(SAVE_FILE))
    end)
    if ok and data and data.key then
        local valid, info = validate(data.key)
        if valid then
            return data.key, info
        end
    end
    return nil
end

function KeySystem.new(onSuccess)
    local self = setmetatable({}, KeySystem)
    self.OnSuccess = onSuccess
    self.Authenticated = false
    self.Gui = nil
    return self
end

function KeySystem:BuildUI()
    local Gui = new("ScreenGui", {
        Name = "VoidKeySystem",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 200,
    })
    safeParent(Gui)

    local Darken = new("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ZIndex = 1,
        Parent = Gui,
    })

    local Main = new("Frame", {
        Size = UDim2.fromOffset(420, 260),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Bg,
        BorderSizePixel = 0,
        ZIndex = 10,
        Parent = Gui,
    })
    corner(Main, 10)
    stroke(Main)

    local TopBar = new("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = Main,
    })
    corner(TopBar, 10)
    new("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = TopBar,
    })

    local dot = new("Frame", {
        Size = UDim2.fromOffset(8, 8),
        Position = UDim2.new(0, 16, 0.5, -4),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 12,
        Parent = TopBar,
    })
    corner(dot, 4)

    new("TextLabel", {
        Text = "Void | Key System",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 32, 0, 0),
        Size = UDim2.new(1, -40, 1, 0),
        ZIndex = 12,
        Parent = TopBar,
    })

    new("TextLabel", {
        Text = "Enter your access key",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = Theme.Sub,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 30, 0, 70),
        Size = UDim2.new(1, -60, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12,
        Parent = Main,
    })

    local input = new("TextBox", {
        Text = "",
        PlaceholderText = "KEY-HERE",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.Sub,
        BackgroundColor3 = Theme.PanelLt,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 30, 0, 100),
        Size = UDim2.new(1, -60, 0, 38),
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 12,
        Parent = Main,
    })
    corner(input, 6)
    stroke(input)
    new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = input })

    local status = new("TextLabel", {
        Text = "",
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Theme.Sub,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 30, 0, 148),
        Size = UDim2.new(1, -60, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12,
        Parent = Main,
    })

    local submit = new("TextButton", {
        Text = "AUTHENTICATE",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.new(1, 1, 1),
        BackgroundColor3 = Theme.Accent,
        AutoButtonColor = false,
        Position = UDim2.new(0, 30, 1, -70),
        Size = UDim2.new(1, -60, 0, 40),
        ZIndex = 12,
        Parent = Main,
    })
    corner(submit, 6)

    submit.MouseEnter:Connect(function()
        TweenService:Create(submit, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Hover }):Play()
    end)
    submit.MouseLeave:Connect(function()
        TweenService:Create(submit, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Accent }):Play()
    end)

    self.Gui = Gui

    local function attemptAuth()
        local key = input.Text
        local valid, info = validate(key)
        if valid then
            status.Text = "Authenticated | " .. info.tier
            status.TextColor3 = Theme.Green
            saveKey(key, info)
            self.Authenticated = true
            task.wait(0.6)
            Gui:Destroy()
            if self.OnSuccess then
                pcall(self.OnSuccess, key, info)
            end
        else
            status.Text = "Invalid key"
            status.TextColor3 = Theme.Red
            TweenService:Create(Main, TweenInfo.new(0.05), { Position = UDim2.new(0.5, -8, 0.5, 0) }):Play()
            task.wait(0.05)
            TweenService:Create(Main, TweenInfo.new(0.05), { Position = UDim2.new(0.5, 8, 0.5, 0) }):Play()
            task.wait(0.05)
            TweenService:Create(Main, TweenInfo.new(0.05), { Position = UDim2.fromScale(0.5, 0.5) }):Play()
        end
    end

    submit.MouseButton1Click:Connect(attemptAuth)
    input.FocusLost:Connect(function(enter)
        if enter then attemptAuth() end
    end)

    return Gui
end

function KeySystem:Check()
    local key, info = loadSavedKey()
    if key then
        self.Authenticated = true
        if self.OnSuccess then
            pcall(self.OnSuccess, key, info)
        end
        return true
    end
    return false
end

function KeySystem:Prompt()
    if self:Check() then return end
    self:BuildUI()
end

return KeySystem
