local M = {
    path = ac.dirname().."/settings/settings.json",
    presetsPath = ac.dirname().."/settings/presets/",
    presets = {},
    notDeletablePresetsMap = { defaultNoInput = true, dualshock4 = true, xbox360 = true },
    values = {},
}

function M:load()
    local settings = io.load(self.path)
    if not settings then
        self:loadPreset("defaultNoInput")
        return
    end
    for k, v in pairs(JSON.parse(settings)) do
        self.values[k] = v
    end
end

function M:loadPreset(presetName)
    local preset = io.load(self.presetsPath .. presetName .. ".json")
    if preset then
        io.save(self.path, preset)
        self:load()
    end
end

function M:savePreset(presetName)
    io.save(self.presetsPath .. presetName .. ".json", JSON.stringify(self.values), true)
end

function M:deletePreset(presetName)
    if not self.notDeletablePresetsMap[presetName] then
        io.deleteFile(self.presetsPath..presetName..".json")
    end
end

function M:updatePresets()
    table.clear(self.presets)
    io.scanDir(self.presetsPath, "*.json", function (fileName)
        table.insert(self.presets, fileName:match("%w*"))
    end)
end

M:updatePresets()
M:load()

ac.onFolderChanged(M.presetsPath, nil, false, function() M:updatePresets() end)

setmetatable(M, {
    __index = M.values,
    __newindex = function(table, index, value)
        if M.values[index] == nil then
            ac.error(debug.traceback("Tried to add a new key("..index..") to settings"))
            return
        end
        M.values[index] = value
        io.save(M.path, JSON.stringify(M.values), true)
    end
})

return M
