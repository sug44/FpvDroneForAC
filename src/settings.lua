local M = {
    path = ac.dirname().."/settings/settings.json",
    presetsPath = ac.dirname().."/settings/presets/",
    presets = {},
    notDeletablePresetsMap = { defaultNoInput = true, dualshock4 = true, xbox360 = true },
    settings = {},
    finalizer = newproxy(true),
}
-- this saves settings in the json file when the game closes gracefully
getmetatable(M.finalizer).__gc = function(_) M:saveSettings() end

function M:load()
    local settings = JSON.parse(io.load(self.path))

    -- check if settings file exists and is not empty
    if not (settings and settings.inputDeviceGUID) then
        self:loadPreset("defaultNoInput")
        return
    end

    table.clear(self.settings)
    for k,v in pairs(settings) do
        self.settings[k] = v
    end

    Input:updateInputDevice()
end

function M:loadPreset(presetName)
    local preset = io.load(self.presetsPath .. presetName .. ".json")
    if preset then
        io.save(self.path, preset)
        self:load()
    end
end

function M:savePreset(presetName)
    io.save(self.presetsPath .. presetName .. ".json", JSON.stringify(self.settings), true)
end

function M:deletePreset(presetName)
    io.deleteFile(self.presetsPath..presetName..".json")
end

function M:updatePresets()
    table.clear(self.presets)
    io.scanDir(self.presetsPath, "*.json", function (fileName)
        table.insert(self.presets, fileName:match("%w*"))
    end)
end

function M:saveSettings()
    if self.settings.inputDeviceGUID then -- check if settings were loaded
        io.save(self.path, JSON.stringify(self.settings), true)
    end
end

setmetatable(M, {
    __index = M.settings,
    __newindex = M.settings
})

return M
