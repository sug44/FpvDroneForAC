-- CSP looks for a file with the name of the mod folder.
-- if mod path is "assettocorsa/apps/lua/FpvDrone" it will look for "FpvDrone.lua".
-- If mod is cloned from github with the default name this file will run instead, so call the actual file
dofile(ac.dirname().."/FpvDrone.lua")
