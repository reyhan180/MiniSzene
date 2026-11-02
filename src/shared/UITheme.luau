-- Gemeinsames UI-Styling für alle Guis (ShopGui, RoundGui, AnnouncementGui, FeedbackGui).
-- Farben, Schriften, Größen und kleine Bau-Helfer an einer Stelle.

local UITheme = {}

UITheme.COLORS = {
	Panel = Color3.fromRGB(30, 34, 42),
	Row = Color3.fromRGB(45, 50, 60),
	Text = Color3.fromRGB(240, 240, 240),
	Muted = Color3.fromRGB(165, 170, 180),
	Accent = Color3.fromRGB(255, 200, 70),
	Buy = Color3.fromRGB(60, 170, 90),
	Disabled = Color3.fromRGB(90, 95, 105),
	Success = Color3.fromRGB(90, 220, 120),
	Error = Color3.fromRGB(235, 90, 80),
	Lobby = Color3.fromRGB(110, 170, 255),
	Gold = Color3.fromRGB(255, 215, 90),
	Stroke = Color3.fromRGB(0, 0, 0),
}

UITheme.PANEL_TRANSPARENCY = 0.1

UITheme.FONTS = {
	Regular = Enum.Font.GothamMedium,
	Bold = Enum.Font.GothamBold,
	Heavy = Enum.Font.GothamBlack,
}

UITheme.TEXT_SIZE = {
	Small = 14,
	Body = 16,
	Heading = 18,
	Title = 22,
}

UITheme.CORNER = {
	Small = 6,
	Medium = 8,
	Large = 10,
}

-- Mindestgröße für Touch-Ziele (Buttons) in Pixeln
UITheme.TOUCH_TARGET = 44

-- ===== Bau-Helfer =====

function UITheme.addCorner(parent: Instance, radius: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or UITheme.CORNER.Medium)
	corner.Parent = parent
	return corner
end

function UITheme.addPadding(parent: Instance, pixels: number)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, pixels)
	padding.PaddingBottom = UDim.new(0, pixels)
	padding.PaddingLeft = UDim.new(0, pixels)
	padding.PaddingRight = UDim.new(0, pixels)
	padding.Parent = parent
	return padding
end

function UITheme.makePanel(name: string, parent: Instance?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundColor3 = UITheme.COLORS.Panel
	frame.BackgroundTransparency = UITheme.PANEL_TRANSPARENCY
	frame.BorderSizePixel = 0
	UITheme.addCorner(frame, UITheme.CORNER.Large)
	frame.Parent = parent
	return frame
end

function UITheme.makeLabel(name: string, text: string, textSize: number?, parent: Instance?): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.BackgroundTransparency = 1
	label.TextColor3 = UITheme.COLORS.Text
	label.Font = UITheme.FONTS.Regular
	label.TextSize = textSize or UITheme.TEXT_SIZE.Body
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = parent
	return label
end

function UITheme.makeButton(name: string, text: string, color: Color3, parent: Instance?): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.BackgroundColor3 = color
	button.TextColor3 = UITheme.COLORS.Text
	button.Font = UITheme.FONTS.Bold
	button.TextSize = UITheme.TEXT_SIZE.Body
	button.AutoButtonColor = true
	button.BorderSizePixel = 0
	UITheme.addCorner(button, UITheme.CORNER.Small)
	button.Parent = parent
	return button
end

return UITheme
