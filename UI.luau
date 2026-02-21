local Fatality = loadstring(game:HttpGet("https://raw.githubusercontent.com/QM80/Fatality-purple/refs/heads/main/src/source.luau"))();

Fatality:Loader({
    Name = "FATALITY",
    Duration = 1
});

local Notification = Fatality:CreateNotifier();

_G.ESP = {
    Enabled = false,
    ShowBoxes = false,
    ShowNames = false,
    ShowTracers = false,
    ShowBoxOutline = false,
    ShowHealth = false,
    ShowHealthText = false,
    ShowFill = false,
    ShowCircle = false,
    ShowCircleOutline = false,
    ShowLine = false,

    
    HealthColorMode = "custom",
    HealthColorFunction = function(healthPercent)
        if healthPercent > 0.7 then
            return Color3.fromRGB(0, 255, 0)
        elseif healthPercent > 0.3 then
            return Color3.fromRGB(255, 165, 0)
        else
            return Color3.fromRGB(255, 0, 0)
        end
    end
}

_G.ESP.Color = Color3.fromRGB(255, 255, 255)

-- FUNCTIONS



local function initESP()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer

    local ESPObjects = {}

    local function newDrawing(type, props)
        local obj = Drawing.new(type)
        for k, v in pairs(props) do
            obj[k] = v
        end
        return obj
    end

    local function createESPElements()
        return {
            BoxOutline = newDrawing("Square", {Visible = false, Thickness = 2, Filled = false, Color = Color3.new(0,0,0)}),
            Box = newDrawing("Square", {Visible = false, Thickness = 1, Filled = false, Color = Color3.new(1,1,1)}),
            Fill = newDrawing("Square", {Visible = false, Thickness = 2, Filled = true, Color = Color3.new(1,1,1)}),
            Name = newDrawing("Text", {Visible = false, Center = true, Outline = true, Size = 16, Font = 2, Color = Color3.new(1,1,1)}),
            Tracer = newDrawing("Line", {Visible = false, Thickness = 1, Color = Color3.new(1,1,1)}),
            HealthBarText = newDrawing("Text", {Visible = false, Center = true, Outline = true, Size = 14, Font = 2, Color = Color3.new(1,1,1)}),
            HealthBarOutline = newDrawing("Line", {Visible = false, Thickness = 4, Color = Color3.new(0,0,0)}),
            HealthBar = newDrawing("Line", {Visible = false, Thickness = 2, Color = Color3.new(0,1,0)}),
            CircleOutline = newDrawing("Circle", {Visible = false, Thickness = 2, Color = Color3.new(0,0,0), Radius = 4}),
            Circle = newDrawing("Circle", {Visible = false, Thickness = 1, Color = Color3.new(1,1,1), Radius = 4}),
            Line = newDrawing("Line", {Visible = false, Thickness = 1, Color = Color3.new(1,1,1)}),
            Skeleton = {
                Head = newDrawing("Line", {Visible = false, Thickness = 1, Color = Color3.new(1,1,1)}),
                Neck = newDrawing("Line", {Visible = false, Thickness = 1, Color = Color3.new(1,1,1)}),
                UpperSpine = newDrawing("Line", {Visible = false, Thickness = 1, Color = Color3.new(1,1,1)}),
                LeftShoulder = newDrawing("Line", {Visible = false, Thickness = 1, Color = Color3.new(1,1,1)}),
                LeftLowerArm = newDrawing("Line", {Visible = false, Thickness = 1, Color = Color3.new(1,1,1)}),
                RightShoulder = newDrawing("Line", {Visible = false, Thickness = 1, Color = Color3.new(1,1,1)}),
                RightLowerArm = newDrawing("Line", {Visible = false, Thickness = 1, Color = Color3.new(1,1,1)}),
                LeftHip = newDrawing("Line", {Visible = false, Thickness = 1, Color = Color3.new(1,1,1)}),
                LeftLowerLeg = newDrawing("Line", {Visible = false, Thickness = 1, Color = Color3.new(1,1,1)}),
                RightHip = newDrawing("Line", {Visible = false, Thickness = 1, Color = Color3.new(1,1,1)}),
                RightLowerLeg = newDrawing("Line", {Visible = false, Thickness = 1, Color = Color3.new(1,1,1)}),
            }
        }
    end

    local function getBoxScreenPoints(cframe, size)
        local half = size / 2
        local points = {}
        local visible = true
        for x = -1,1,2 do
            for y = -1,1,2 do
                for z = -1,1,2 do
                    local corner = cframe * Vector3.new(half.X*x, half.Y*y, half.Z*z)
                    local screenPos, onScreen = Camera:WorldToViewportPoint(corner)
                    if not onScreen then visible = false end
                    table.insert(points, Vector2.new(screenPos.X, screenPos.Y))
                end
            end
        end
        return points, visible
    end

    local function hideAll(data)
        data.Fill.Visible = false
        data.Box.Visible = false
        data.BoxOutline.Visible = false
        data.Name.Visible = false
        data.Tracer.Visible = false
        data.HealthBarText.Visible = false
        data.HealthBar.Visible = false
        data.HealthBarOutline.Visible = false
        data.Circle.Visible = false
        data.CircleOutline.Visible = false
        data.Line.Visible = false
        for _, line in pairs(data.Skeleton) do
            line.Visible = false
        end
    end

    RunService.RenderStepped:Connect(function()
        if not _G.ESP.Enabled then
            for _, data in pairs(ESPObjects) do
                hideAll(data)
            end
            return
        end

        local baseColor = _G.ESP.Color
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local character = player.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if character and humanoid and humanoid.Health > 0 then
                    local success, cframe, size = pcall(character.GetBoundingBox, character)
                    if success and cframe and size then
                        local points, visible = getBoxScreenPoints(cframe, size)
                        if not visible then
                            if ESPObjects[player.Name] then
                                hideAll(ESPObjects[player.Name])
                            end
                        else
                            local data = ESPObjects[player.Name] or createESPElements()
                            ESPObjects[player.Name] = data

                            local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
                            for _, pt in ipairs(points) do
                                minX = math.min(minX, pt.X)
                                minY = math.min(minY, pt.Y)
                                maxX = math.max(maxX, pt.X)
                                maxY = math.max(maxY, pt.Y)
                            end

                            local boxWidth, boxHeight = maxX - minX, maxY - minY
                            local slimWidth = boxWidth * 0.7
                            local slimX = minX + (boxWidth - slimWidth) / 2
                            local healthRatio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)

                            if _G.ESP.ShowLine then
                                local function getScreen(partName)
                                    local part = character:FindFirstChild(partName)
                                    if not part then return nil end
                                    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                                    if not onScreen then return nil end
                                    return Vector2.new(pos.X, pos.Y)
                                end

                                local function drawBone(line, fromName, toName)
                                    local a = getScreen(fromName)
                                    local b = getScreen(toName)
                                    if a and b then
                                        line.From = a
                                        line.To = b
                                        line.Color = baseColor
                                        line.Visible = true
                                    else
                                        line.Visible = false
                                    end
                                end

                                local s = data.Skeleton
                                local isR15 = character:FindFirstChild("UpperTorso") ~= nil

                            if isR15 then
                                drawBone(s.Head,          "Head",          "UpperTorso")
                                drawBone(s.UpperSpine,    "UpperTorso",    "LowerTorso")
                                drawBone(s.LeftShoulder,  "UpperTorso",    "LeftUpperArm")
                                drawBone(s.LeftLowerArm,  "LeftUpperArm",  "LeftLowerArm")
                                drawBone(s.RightShoulder, "UpperTorso",    "RightUpperArm")
                                drawBone(s.RightLowerArm, "RightUpperArm", "RightLowerArm")
                                drawBone(s.LeftHip,       "LowerTorso",    "LeftUpperLeg")
                                drawBone(s.LeftLowerLeg,  "LeftUpperLeg",  "LeftLowerLeg")
                                drawBone(s.RightHip,      "LowerTorso",    "RightUpperLeg")
                                drawBone(s.RightLowerLeg, "RightUpperLeg", "RightLowerLeg")
                            else
                                drawBone(s.Head,          "Head",             "Torso")
                                drawBone(s.UpperSpine,    "Torso",            "HumanoidRootPart")
                                drawBone(s.LeftShoulder,  "Torso",            "Left Arm")
                                drawBone(s.LeftLowerArm,  "Left Arm",         "Left Hand")
                                drawBone(s.RightShoulder, "Torso",            "Right Arm")
                                drawBone(s.RightLowerArm, "Right Arm",        "Right Hand")
                                drawBone(s.LeftHip,       "HumanoidRootPart", "Left Leg")
                                drawBone(s.LeftLowerLeg,  "Left Leg",         "Left Foot")
                                drawBone(s.RightHip,      "HumanoidRootPart", "Right Leg")
                                drawBone(s.RightLowerLeg, "Right Leg",        "Right Foot")
                            end
                                else
                                for _, line in pairs(data.Skeleton) do
                                    line.Visible = false
                                end
                            end


                            if _G.ESP.ShowBoxes then
                                data.Box.Visible = true
                                data.Box.Position = Vector2.new(slimX, minY)
                                data.Box.Size = Vector2.new(slimWidth, boxHeight)
                                data.Box.Color = baseColor
                            else
                                data.Box.Visible = false
                            end

                            if _G.ESP.ShowBoxOutline then
                                data.BoxOutline.Visible = true
                                data.BoxOutline.Position = Vector2.new(slimX, minY)
                                data.BoxOutline.Size = Vector2.new(slimWidth , boxHeight)
                                data.BoxOutline.Color = Color3.new(0,0,0)
                            else
                                data.BoxOutline.Visible = false
                            end

                            if _G.ESP.ShowFill then
                                data.Fill.Visible = true
                                data.Fill.Position = Vector2.new(slimX, minY)
                                data.Fill.Size = Vector2.new(slimWidth, boxHeight)
                                data.Fill.Color = baseColor
                                data.Fill.Transparency = 0.5
                            else
                                data.Fill.Visible = false
                            end

                            if _G.ESP.ShowCircle then
                                local head = character:FindFirstChild("Head")
                                if head then
                                    local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
                                    if headOnScreen then
                                        data.Circle.Visible = true
                                        data.Circle.Position = Vector2.new(headPos.X, headPos.Y)
                                        data.Circle.Radius = math.clamp(1000 / headPos.Z, 5, 30)
                                        data.Circle.Color = baseColor
                                    else
                                        data.Circle.Visible = false
                                    end
                                end
                            else
                                data.Circle.Visible = false
                            end

                            if _G.ESP.ShowCircleOutline then
                                local head = character:FindFirstChild("Head")
                                if head then
                                    local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
                                    if headOnScreen then
                                        data.CircleOutline.Visible = true
                                        data.CircleOutline.Position = Vector2.new(headPos.X, headPos.Y)
                                        data.CircleOutline.Radius = math.clamp(1000 / headPos.Z, 5, 30)
                                        data.CircleOutline.Color = Color3.new(0,0,0)
                                    else
                                        data.CircleOutline.Visible = false
                                    end
                                end
                            else
                                data.CircleOutline.Visible = false
                            end
                            

                            if _G.ESP.ShowNames then
                                data.Name.Visible = true
                                data.Name.Text = player.Name
                                data.Name.Position = Vector2.new(slimX + slimWidth/2, minY - 20)
                                data.Name.Color = baseColor
                            else
                                data.Name.Visible = false
                            end

                            if _G.ESP.ShowTracers then
                                data.Tracer.Visible = true
                                data.Tracer.From = screenCenter
                                data.Tracer.To = Vector2.new(slimX + slimWidth/2, maxY)
                                data.Tracer.Color = baseColor
                            else
                                data.Tracer.Visible = false
                            end
                            
                            if _G.ESP.ShowHealthText then
                                data.HealthBarText.Visible = true
                                data.HealthBarText.Text = math.floor(humanoid.Health) .. " / " .. math.floor(humanoid.MaxHealth)
                                data.HealthBarText.Position = Vector2.new(slimX + slimWidth/2, maxY + 5)
                                data.HealthBarText.Color = baseColor
                            else
                                data.HealthBarText.Visible = false
                            end

                            if _G.ESP.ShowHealth then
                                local barHeight = boxHeight * healthRatio
                                data.HealthBar.Visible = true
                                data.HealthBarOutline.Visible = true

                                if _G.ESP.HealthColorMode == "custom" and _G.ESP.HealthColorFunction then
                                    data.HealthBar.Color = _G.ESP.HealthColorFunction(healthRatio)
                                else
                                    data.HealthBar.Color = baseColor
                                end

                                data.HealthBarOutline.Color = Color3.new(0, 0, 0) -- always set, outside the if

                                data.HealthBar.From = Vector2.new(slimX - 6, maxY)
                                data.HealthBar.To = Vector2.new(slimX - 6, maxY - barHeight)
                                data.HealthBarOutline.From = Vector2.new(slimX - 6, maxY)
                                data.HealthBarOutline.To = Vector2.new(slimX - 6, maxY - barHeight)
                            else
                                data.HealthBar.Visible = false
                                data.HealthBarOutline.Visible = false
                            end
                        end
                    end
                else
                    if ESPObjects[player.Name] then
                        hideAll(ESPObjects[player.Name])
                    end
                end
            end
        end
    end)

        Players.PlayerRemoving:Connect(function(player)
        if ESPObjects[player.Name] then
            for _, obj in pairs(ESPObjects[player.Name]) do
                if typeof(obj) == "table" then
                    for _, line in pairs(obj) do
                        line:Remove()
                    end
                else
                    obj:Remove()
                end
            end
            ESPObjects[player.Name] = nil
        end
    end)
end

initESP()

--------------------

Notification:Notify({
    Title = "FATALITY",
    Content = "Hello, "..game.Players.LocalPlayer.DisplayName..' Welcome back!',
    Icon = "clipboard"
})

local Window = Fatality.new({
    Name = "FATALITY",
    Scale = UDim2.new(0, 750, 0, 500),
    Keybind = "RightControl",
    Expire = "never",
});


------------------ESP TAB---------------------
local ESP = Window:AddMenu({
    Name = "ESP",
    Icon = "eye"
})

local esp = ESP:AddSection({
    Position = 'left',
    Name = "ESP Settings"
})

esp:AddToggle({
    Name = "Enable ESP",
    Default = false,
    Option = false,
    Callback = function(value)
        _G.ESP.Enabled = value
    end,
})

esp:AddToggle({
    Name = "Enable boxes",
    Default = false,
    Option = false,
    Callback = function(value)
        _G.ESP.ShowBoxes = value
    end,
})

esp:AddToggle({
    Name = "Enable Box Outline",
    Default = false,
    Option = false,
    Callback = function(value)
        _G.ESP.ShowBoxOutline = value
    end,
})

esp:AddToggle({
    Name = "Enable Fill",
    Default = false,
    Option = false,
    Callback = function(value)
        _G.ESP.ShowFill = value
    end,
})

esp:AddToggle({
    Name = "Enable health bar",
    Default = false,
    Option = false,
    Callback = function(value)
        _G.ESP.ShowHealth = value
    end,
})

esp:AddToggle({
    Name = "Enable health bar text",
    Default = false,
    Option = false,
    Callback = function(value)
        _G.ESP.ShowHealthText = value
    end,
})

esp:AddToggle({
    Name = "Enable name",
    Default = false,
    Option = false,
    Callback = function(value)
        _G.ESP.ShowNames = value
    end,
})

esp:AddToggle({
    Name = "Enable tracers",
    Default = false,
    Option = false,
    Callback = function(value)
        _G.ESP.ShowTracers = value
    end,
})

esp:AddToggle({
    Name = "Enable Skeleton",
    Default = false,
    Option = false,
    Callback = function(value)
        _G.ESP.ShowLine = value
    end,
})

esp:AddToggle({
    Name = "Enable Head circle",
    Default = false,
    Option = false,
    Callback = function(value)
        _G.ESP.ShowCircle = value
    end,
})
esp:AddToggle({
    Name = "Enable Circle Outline",
    Default = false,
    Option = false,
    Callback = function(value)
        _G.ESP.ShowCircleOutline = value
    end,
})


esp:AddColorPicker({
	Name = "ESP Color",
	Default = Color3.fromRGB(255,255,255),
	Callback = function(value)
		_G.ESP.Color = value
	end,
})

------------------------- WORLD TAB --------------------------

local Lighting = game:GetService("Lighting")


local world = Window:AddMenu({
    Name = "World",
    Icon = "globe"
})

local lighting = world:AddSection({
    Name = "Lighting",
    Position = "left"
})

local fullbrightEnabled = false
local originalAmbient = Lighting.Ambient
local originalBottom = Lighting.ColorShift_Bottom
local originalTop = Lighting.ColorShift_Top
local fullbrightConnection = nil

lighting:AddToggle({
    Name = "Fullbright",
    Default = false,
    Option = false,
    Callback = function(value)
        fullbrightEnabled = value
        if value then
            originalAmbient = Lighting.Ambient
            originalBottom = Lighting.ColorShift_Bottom
            originalTop = Lighting.ColorShift_Top
            Lighting.Ambient = Color3.new(1,1,1)
            Lighting.ColorShift_Bottom = Color3.new(1,1,1)
            Lighting.ColorShift_Top = Color3.new(1,1,1)
            fullbrightConnection = Lighting.LightingChanged:Connect(function()
                if fullbrightEnabled then
                    Lighting.Ambient = Color3.new(1,1,1)
                    Lighting.ColorShift_Bottom = Color3.new(1,1,1)
                    Lighting.ColorShift_Top = Color3.new(1,1,1)
                end
            end)
        else
            if fullbrightConnection then
                fullbrightConnection:Disconnect()
                fullbrightConnection = nil
            end
            Lighting.Ambient = originalAmbient
            Lighting.ColorShift_Bottom = originalBottom
            Lighting.ColorShift_Top = originalTop
        end
    end,
})

-- Lighting end --

local ambience = world:AddSection({
    Name = "Ambience",
    Position = "Left"
})

local Lighting = game:GetService("Lighting")
local ambient_color = Color3.fromRGB(255, 255, 255)

ambience:AddColorPicker({
    Name = "Ambient Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(value)
        ambient_color = value
    end,
})

ambience:AddToggle({
    Name = "Enable Ambient Color",
    Default = false,
    Option = false,
    Callback = function(value)
        if value then
            Lighting.Ambient = ambient_color
        else
            Lighting.Ambient = Color3.fromRGB(0, 0, 0)
        end
    end,
})

-- Ambience end

fg.Parent = Lighting

local fog = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)

local fog_density = 0

local fogs = world:AddSection({
    Name = "Fog",
    Position = "center"
})

local originalDensity = fog.Density
local fogConnection = nil

fogs:AddSlider({
	Name = "Fog density",
	Min = 0,
	Max = 1,
	Round = 3,
	Default = 0.3,
	Callback = function(value)
        fog_density = value
    end,
})

fogs:AddToggle({
    Name = "Enable Fog",
    Default = false,
    Option = false,
    Callback = function(value)
        if value then
            originalDensity = fog.Density
            fog.Density = fog_density
            fogConnection = fog:GetPropertyChangedSignal("Density"):Connect(function()
                if fog.Density ~= fog_density then
                    fog.Density = fog_density
                end
            end)
        else
            if fogConnection then
                fogConnection:Disconnect()
                fogConnection = nil
            end
            fog.Density = originalDensity
        end
    end,
})
