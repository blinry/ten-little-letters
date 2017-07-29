--- Scaleinator - perfect pixels for all!
--
-- This platform- and framework-independent module makes scaling your games and programs to different screens much easier.  
-- With this module, you can get a screen of any aspect ratio inside the actual window, with properly scaled elements.  
-- Apache 2 licensed source code: https://gitlab.com/Zatherz/scaleinator.
--
-- Note: these functions are case insensitive, meaning that 'scaleinator.EditMode', 'scaleinator.editmode' and 'scaleinator.editMode' will all do the same thing.
-- You can even use snake case ('scaleinator.edit_mode')!
-- @module scaleinator
local scaleinator = setmetatable({}, {
       __index = function(self, key)
                if type(key) == "string" then
                        return self and rawget(self, key:gsub("_", ""):lower())
                end
        end
})

--- Create a screen scale object that contains all the functions of scaleinator except create (call them using the :function() syntax to pass "self" automatically).
-- @return table (screen scale object)
function scaleinator.create()
	return setmetatable({
		prop = {
			yhandling = "+",
                        firstscreen = {
                                w = nil,
                                h = nil
                        },
			screen = {
				w = nil,
				h = nil
			},
			currentmode = nil,
			factor = {
				w = nil,
				h = nil
			},
			box = {
                                w = nil,
				h = nil
			},
			translate = {
				x = nil,
				y = nil
			},
			modes = {}
		},
		updateresolution = scaleinator.updateresolution,
                update = scaleinator.update,
		newmode = scaleinator.newmode,
		getmode = scaleinator.getmode,
		setmode = scaleinator.setmode,
		editmode = scaleinator.editmode,
		process = scaleinator.process,
		getfactor = scaleinator.getfactor,
                getoriginalfactor = scaleinator.getoriginalfactor,
                getresizefactor = scaleinator.getresizefactor,
		getbox = scaleinator.getbox,
		getboxw = scaleinator.getboxw,
		getboxh = scaleinator.getboxh,
		gettranslation = scaleinator.gettranslation,
		gettranslationx = scaleinator.gettranslationx,
		gettranslationy = scaleinator.gettranslationy,
		setyhandling = scaleinator.setyhandling
	}, {
       		__index = function(self, key)
	                if type(key) == "string" then
	                        return self and rawget(self, key:gsub("_", ""):lower())
	                end
	        end
	})
end

--- Create a new mode (and set it to be the current mode if no current mode has been set yet).
-- @param self The calling object.
-- @param name Name of the mode, can be anything you like (but a string is preferred).
-- @param w Base width of the screen, in other words, the width in the aspect ratio.
-- @param h Base height of the screen, in other words, the height in the aspect ratio.
-- @return nil
-- @function newMode
function scaleinator.newmode(self, name, w, h)
	local modetoadd = {mode = name, w = w, h = h}
	table.insert(self.prop.modes, modetoadd)
	if not self.prop.currentmode then
		self.prop.currentmode = modetoadd
	end
end
--- Get a mode (or nil if none is found).
-- @param self The calling object.
-- @param name Name of the mode to search (to match the name from newmode()).
-- @return nil
-- @function getMode
function scaleinator.getmode(self, name)
	for key, mode in ipairs(self.prop.modes) do
		if mode.mode == name then
			return mode
		end
	end
end
--- Set the current mode.
-- @param self The calling object.
-- @param name Name of the mode, the same thing you put in newmode().
-- @return nil
-- @function setMode
function scaleinator.setmode(self, name)
	local mode = self:getmode(name)
	if not mode then
		error("mode " .. name .. " does not exist")
	else
		self.prop.currentmode = mode
	end
end
--- Edit a mode.
-- @param self The calling object.
-- @param name Name of the mode, the same thing you put in newmode().
-- @param w Base width of the screen, in other words, the width in the aspect ratio.
-- @param h Base height of the screen, in other words, the height in the aspect ratio.
-- @return nil
-- @function editMode
function scaleinator.editmode(self, name, w, h)
	local mode = self:getmode(name)
	if not mode then
		error("mode " .. name .. " does not exist")
	else
		mode.w = w
		mode.h = h
	end
end
--- Update the stored resolution of the screen.
-- @param self The calling object.
-- @param w Width of the screen.
-- @param h Height of the screen.
-- @return nil
-- @function updateResolution
function scaleinator.updateresolution(self, w, h)
        if not self.prop.firstscreen.w then
                self.prop.firstscreen.w = w
                self.prop.firstscreen.h = h
        end
        self.prop.screen.w = w
        self.prop.screen.h = h
end

--- Process (calculate) the data.
-- Populates the scale factors, box size and translation coordinates.
-- @param self The calling object
-- @return nil
-- @function process
function scaleinator.process(self)
	if not (self.prop.screen.w and self.prop.screen.h and self.prop.currentmode and self.prop.currentmode.w and self.prop.currentmode.h and self.prop.yhandling) then
		error("object not prepared for processing (make sure to add and set a mode, then update the resolution before processing)")
	end
	self.prop.factor.w = math.floor(self.prop.screen.w / (self.prop.currentmode.w))
	self.prop.factor.h = math.floor(self.prop.screen.h / (self.prop.currentmode.h))
	if self.prop.factor.h < self.prop.factor.w then
		self.prop.factor.w = self.prop.factor.h
	elseif self.prop.factor.h > self.prop.factor.w then
		self.prop.factor.h = self.prop.factor.w
	end
	self.prop.box.w = self.prop.currentmode.w * self.prop.factor.w
	self.prop.box.h = self.prop.currentmode.h * self.prop.factor.h
	self.prop.translate.x = math.floor((self.prop.screen.w - self.prop.box.w) / 2)
	self.prop.translate.y = math.floor((self.prop.screen.h - self.prop.box.h) / 2)
	if self.prop.yhandling == "-" then
		self.prop.translate.y = -self.prop.translate.y
	end
end

--- Update the resolution and process.
-- Merges updateresolution and process functions.
-- @param self The calling object.
-- @param w Width of the screen.
-- @param h Height of the screen.
-- @return nil
-- @function update
function scaleinator.update(self, w, h)
        self:updateresolution(w, h)
        self:process()
end

--- Get the scale factor.
-- The factor is always an integer multiplication of the mode's width and height.
-- @param self The calling object.
-- @return integer (scale factor)
-- @function getFactor
function scaleinator.getfactor(self)
        return self.prop.factor.w
end

--- Get the original scale factor.
-- The original scale factor is the aspect ratio scale factor of the first resolution set with updateresolution().
-- @param self The calling object.
-- @return integer (scale factor)
-- @function getOriginalFactor
function scaleinator.getoriginalfactor(self)
        return math.floor(self.prop.firstscreen.w / (self.prop.currentmode.w))
end

--- Get the resize scale factor.
-- The resize scale factor is the factor of difference between the current scale factor and the original scale factor.
-- @param self The calling object.
-- @return integer (scale factor)
-- @function getResizeFactor
function scaleinator.getresizefactor(self)
        return self:getfactor() / self:getoriginalfactor()
end

--- Get the size of the biggest box possible that fits in the window and has the aspect ratio of the mode.
-- @param self The calling object.
-- @return integer (width), integer (height)
-- @function getBox
function scaleinator.getbox(self)
	return self.prop.box.w, self.prop.box.h
end
--- Get the width of the biggest box possible that fits in the window and has the aspect ratio of the mode.
-- @param self The calling object.
-- @return integer (width)
-- @function getBoxW
function scaleinator.getboxw(self)
	return self.prop.box.w
end
--- Get the height of the biggest box possible that fits in the window and has the aspect ratio of the mode.
-- @param self The calling object.
-- @return integer (height)
-- @function getBoxH
function scaleinator.getboxh(self)
	return self.prop.box.h
end
--- Get the number of pixels you need to translate the box by to center it on the screen.
-- @param self The calling object.
-- @return integer (X coordinate translation), integer (Y coordinate translation)
-- @function getTranslation
function scaleinator.gettranslation(self)
	return self.prop.translate.x, self.prop.translate.y
end
--- Get the number of pixels you need to translate the box by in the X coordinate to center it on the screen.
-- @param self The calling object.
-- @return integer (X coordinate translation)
-- @function getTranslationX
function scaleinator.gettranslationx(self)
	return self.prop.translate.x
end
--- Get the number of pixels you need to translate the box by in the Y coordinate to center it on the screen.
-- @param self The calling object.
-- @return integer (Y coordinate translation)
-- @function getTranslationY
function scaleinator.gettranslationy(self)
	return self.prop.translate.y
end
--- Set the handling of Y translation (whether moving an object down in your code subtracts from or adds to the Y value).
-- @param self The calling object.
-- @param handling Handling method ("+" means adding to the Y value when moving down, "-" means subtracting from it).
-- @return nil
-- @function setYHandling
function scaleinator.setyhandling(self, handling)
	if handling == "-" or handling == "+" then
		self.prop.yhandling = handling
	else
		error("wrong yhandling (only \"-\" and \"+\" are accepted)")
	end
end

return scaleinator
