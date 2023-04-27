local directory = ac.dirname()
SSettings = {}
SSettings.config = ac.INIConfig.load(directory .. "/config.ini", ac.INIFormat.Extended)

function SSettings:update()
  for section in pairs(self.config.sections) do
    for key in pairs(self.config.sections[section]) do
      self[key] = self.config:get(section, key, -1) -- 1e9=true -1e9=false (sorry)
      if self[key] == -1e9 then self[key] = false end
      if self[key] == 1e9 then self[key] = true end
    end
  end
  self.squareColor = self.config:get("App", "squareColor", {})
  self.circleColor = self.config:get("App", "circleColor", {})
  self.inputDeviceName = self.config:get("Input", "inputDeviceName", "")
  for i = 0, ac.getJoystickCount(), 1 do
    if ac.getJoystickName(i) == self.inputDeviceName then
      self.inputDevice = i
      return
    end
  end
  self.inputDevice = 0
end

function SSettings:set(section, key, value)
  self[key] = value
  if value == true then value = 1e9 end
  if value == false then value = -1e9 end
  self.config:set(section, key, value):save(self.config.filename)
end

function SSettings:loadFrom(filename)
  io.save(directory .. "/config.ini", io.load(directory .. "/presets/" .. filename .. ".ini"))
  self.config = ac.INIConfig.load(directory .. "/config.ini", ac.INIFormat.Extended)
  self:update()
end

function SSettings:saveTo(filename)
  io.save(directory .. "/presets/" .. filename .. ".ini", self.config:serialize())
end
