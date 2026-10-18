local KeySystem = {}
KeySystem.__index = KeySystem

function KeySystem.new(callback)
    local self = setmetatable({}, KeySystem)
    self.callback = callback
    return self
end

function KeySystem:Prompt()
    task.spawn(function()
        task.wait(0.5)
        if self.callback then
            self.callback("skip", { tier = "Default" })
        end
    end)
end

return KeySystem
