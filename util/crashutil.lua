local crashutil = {}


-- When added as a *member variable*, will automatically tostring the target
-- and get printed in fullstacks.
crashutil.FwdToString = Class(function(self, target)
    self.target = target
end)
function crashutil.FwdToString:__tostring()
    return tostring(self.target)
end


-- When added as a *member variable*, will automatically call function to get
-- the string printed in fullstacks.
crashutil.FuncToString = Class(function(self, fn)
    self.fn = fn
end)
function crashutil.FuncToString:__tostring()
    return self.fn()
end



return crashutil
