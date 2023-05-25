local directory = ac.dirname()
Settings = {}
Settings.config = ac.INIConfig.load(directory .. "/config.ini", ac.INIFormat.Extended)

function Settings:update()
    for section in pairs(self.config.sections) do
        for key in pairs(self.config.sections[section]) do
            local typeAndValue = self.config:get(section, key, {})
            if typeAndValue[1] == "number" then self[key] = tonumber(typeAndValue[2]) end
            if typeAndValue[1] == "boolean" then self[key] = typeAndValue[2] == "true" end
            if typeAndValue[1] == "string" then self[key] = tostring(typeAndValue[2]) end
            if typeAndValue[1] == "table" then self[key] = table.slice(typeAndValue, 2) end
        end
    end

    local foundController = false
    for i = 0, ac.getJoystickCount() do
        if ac.getJoystickName(i) == self.inputDeviceName then
            foundController = true
            self.inputDevice = i
        end
    end
    if not foundController then
        self.inputDevice = 0
    end
end
Settings:update()

function Settings:set(section, key, value)
    self[key] = value
    self.config:set(section, key, { type(value), type(value) == "table" and table.unpack(value) or tostring(value)}):save(self.config.filename)
end

function Settings:loadFrom(filename)
    io.save(directory .. "/config.ini", io.load(directory .. "/presets/" .. filename .. ".ini"))
    self.config = ac.INIConfig.load(directory .. "/config.ini", ac.INIFormat.Extended)
    self:update()
end

function Settings:saveTo(filename)
    io.save(directory .. "/presets/" .. filename .. ".ini", self.config:serialize())
end
