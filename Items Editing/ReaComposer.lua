-- @ReaComposer - chordtrack for Reaper
-- @version 1.5.3
-- @author Dragonetti
-- @link forum https://forum.cockos.com/showthread.php?t=267849
-- @about
--   CHORDTRACK for REAPER


---------------------------------------------------------
----Header
---------------------------------------------------------
--[[
@description eGUI - A Lua GUI library for REAPER
@about
  #### eGUI - A Lua GUI library for Cockos Reaper
  
  A mod of Eugen27771's original Lua GUI Template for Reaper
  
  Additional code by Lokasenna and Stephane
  Additional code by Lokasenna and Stephane

  Plus Small Tweaks code  by Daniel Lumertz:
  -  Added the Status Bar by Robert (helper)
  -  Knob Tweaks ( off set obey min value now ) (still need to make a option to logarimitc)
  -  Sliders Tweaks ( How the round was made ) (still need to make a option to logarimitc)
  -  Option to float and integer to sliders and knobs
  
  #### Features
  - Layers
  - Buttons
  - Checklists
  - Dropdown Lists
  - Knobs
  - Frames
  - Horizontal & Vertical Sliders
  - Horizontal & Vertical Range Sliders
  - Radio Buttons
  - Textboxes
  - Resizable
  - Modularised for import to other scripts
  - Licenced under the GPL v3
@link Forum Thread http://reaper.fm
@noindex
@version 2.0
@author RobU
@changelog
  v2.0
  Forked from EUGEN27771's GUI for Lua
  Modularised
  Refactoring of original code
  Added Vertical Range Slider widget
  Added Textbox widget
  Added polar coordinate support to Knob widgets
  Added Min/Max/Step attributes to all widgets
  Added mousewheel support to range sliders
  Added Layers/Tabs
  Removed dynamic zoom-by-drag
  Added symetrical fixed-step zoom (eg 80%, 90%, 100%...)
  Rewrote Radio Button and Checkbox initialisation and drawing code
  Improved general readability (variable naming, etc.)
  Added standard colour tables (e.g - e.col_red, e.col_grey5, etc.)
--]]
--------------------------------------------------------------------------------
-- eGUI Global variables
--------------------------------------------------------------------------------
-- All eGUI code is stored in this table, which is imported by the calling script. 
e = {}
e.gScale = 1; e.gScaleState = false; e.gActiveLayer = 1

-- eGUI colours
e.col_red     = {.78, .21, .23, .50}
e.col_orange  = {.90, .60, .10, .35}
e.col_yellow  = {.80, .80, .10, .25}
e.col_green   = {.27, .61, .36, .25}
e.col_green1  = {.27, .61, .36, .35}
e.col_green2  = {.40, .61, .61, .40}
e.col_green3  = {.27, .61, .36, .50}
e.col_blue    = {.27, .43, .58, .50}
e.col_grey4   = {.30, .30, .30, .30}
e.col_grey5   = {.50, .50, .50, .50}
e.col_grey6   = {.60, .60, .60, .60}
e.col_grey7   = {.70, .70, .70, .70}
e.col_grey8   = {.80, .80, .80, .80}
e.col_grey9   = {.90, .90, .90, .90}
e.col_greym   = {.50, .50, .50, .90}
 
-- common shared Windows and Mac sans-serif fonts
e.Arial     = "Arial"
e.Lucinda   = "Lucinda Sans Unicode"
e.Tahoma    = "Tahoma"
e.Trebuchet = "Trebuchet MS"
e.Verdana   = "Verdana"
e.MSSans    = "MS Sans Serif"
--------------------------------------------------------------------------------
-- eGUI Utility functions
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- wrap(n, max) - returns n wrapped between 0 and max
--------------------------------------------------------------------------------
function e.wrap(n, max)
  n = n % max
  if (n < 1) then
    n = n + max
  end
  return n
end
--------------------------------------------------------------------------------
-- RGB2Packed(r, g, b) - returns a packed rgb value
--------------------------------------------------------------------------------
function e.RGB2Packed(r, g, b)
  local floor = math.floor
    g = (g << 8)
    b = (b << 16)
  return floor(r + g + b)
end
--------------------------------------------------------------------------------
-- Packed2RGB(p) - returns r, g, b from a packed rgb value
--------------------------------------------------------------------------------
function e.Packed2RGB(p)
  local floor = math.floor
  local b, lsb, g, lsg, r = 0, 0, 0, 0, 0
  b = (p >> 16);  lsb = (b << 16);  p = p - lsb
  g = (p >> 8);    lsg = (g << 8);    p = p - lsg
  return floor(p), floor(g), floor(b)
end
--------------------------------------------------------------------------------
-- RGB2Dec(r, g, b) - takes 8 bit r, g, b values, returns decimal (0 to 1)
--------------------------------------------------------------------------------
function e.RGB2Dec(r, g, b)
  if r < 0 or r > 255 then r = wrap(r, 255) end
  if g < 0 or g > 255 then g = wrap(g, 255) end
  if b < 0 or b > 255 then b = wrap(b, 255) end
  return r/255, g/255, b/255
end
--------------------------------------------------------------------------------
-- Cart2Polar(x_pos, y_pos, orig_x, orig_y) - returns radius and angle
--------------------------------------------------------------------------------
function e.Cart2Polar(p_x, p_y, orig_x, orig_y)
  local x, y = p_x - orig_x, p_y - orig_y
  local radius = (x^2 + y^2) ^ 0.5
  local angle = math.deg(math.atan(y, x))
  if angle < 0 then angle = angle + 360 end
  return radius, angle
end
--------------------------------------------------------------------------------
-- Polar2Cart(radias, angle, orig_x, orig_y) - returns x_pos and y_pos
--------------------------------------------------------------------------------
function e.Polar2Cart(radius, angle, orig_x, orig_y)
  local angle = angle * math.pi
  local x, y = radius * math.cos(angle), radius * math.sin(angle)
  return x + orig_x, y + orig_y
end
--------------------------------------------------------------------------------
-- Round to a number of decimals
--------------------------------------------------------------------------------
function round(number, decimals)
  local power = 10^decimals
  return math.floor(number * power) / power
end
--------------------------------------------------------------------------------
-- Round to a number of decimals
--------------------------------------------------------------------------------
function Normalize(val, max, min)
  local x = (val - min) / (max - min)
  return x
end
--------------------------------------------------------------------------------
-- Element Class
--------------------------------------------------------------------------------
e.Element = {}
function e.Element:new(tab, x,y,w,h, rgba, label, font, font_sz, font_rgba, val1, val2, min, max, step)
  local elm = {}
  local bf = 0
  if tab[1] == 0 then  -- convert the tabs table to a bitfield
    bf = 0
  else   
    for i = 1, #tab do
  bf = bf + (1 << tab[i])
    end
  end
  elm.tab = bf
  elm.def_xywh = {x,y,w,h, font_sz} -- default coordinates, used for zoom and some Element initialisation
  elm.x, elm.y, elm.w, elm.h = x, y, w, h -- position and size
  elm.r, elm.g, elm.b, elm.a = table.unpack(rgba) -- Element colour
  elm.label, elm.font, elm.font_sz, elm.font_rgba  = label, font, font_sz, font_rgba -- all things fonty
  elm.val1 = val1;  elm.val2 = val2 -- general purpose variables or tables
  elm.min, elm.max, elm.step = min, max, step -- for incrementing or decrementing values
  elm.help = ""
  setmetatable(elm, self)
  self.__index = self
  return elm
end
--------------------------------------------------------------------------------
-- Element Class Methods
--------------------------------------------------------------------------------
function e.Element:update_zoom() -- generic e.Element scaling
  if not e.gScaleState then return end
  self.x = math.ceil(self.def_xywh[1] * e.gScale)  -- update x position
  self.w = math.ceil(self.def_xywh[3] * e.gScale) -- update width
  self.y = math.ceil(self.def_xywh[2] * e.gScale) -- update y position
  self.h = math.ceil(self.def_xywh[4] * e.gScale) -- update height
  if self.font_sz then -- required for the Frame e.Element which has no font defined
    self.font_sz = math.max(10, self.def_xywh[5] * e.gScale) -- update font
    self.font_sz = math.min(28, self.font_sz)
  end   
  
end
--------------------------------------------------------------------------------
function e.Element:pointIN(p_x, p_y)
  return p_x >= self.x and p_x <= self.x + self.w and p_y >= self.y and p_y <= self.y + self.h
end
--------------------------------------------------------------------------------
function e.Element:mouseIN()
  return gfx.mouse_cap & 1 == 0 and self:pointIN(gfx.mouse_x, gfx.mouse_y)
end
--------------------------------------------------------------------------------
function e.Element:mouseLDown()
  return gfx.mouse_cap & 1 == 1 and self:pointIN(gMouseOX, gMouseOY)
end
--------------------------------------------------------------------------------
function e.Element:mouseUp()
  return gfx.mouse_cap & 1 == 0 and self:pointIN(gMouseOX, gMouseOY)
end
--------------------------------------------------------------------------------
function e.Element:mouseLClick()
  return gfx.mouse_cap & 1 == 0 and gLastMouseCap & 1 == 1 and
  self:pointIN(gfx.mouse_x, gfx.mouse_y) and self:pointIN(gMouseOX, gMouseOY)         
end
--------------------------------------------------------------------------------
function e.Element:mouseRClick()
  return gfx.mouse_cap & 2 == 0 and gLastMouseCap & 2 == 2 and
  self:pointIN(gfx.mouse_x, gfx.mouse_y) and self:pointIN(gMouseOX, gMouseOY)         
end
--------------------------------------------------------------------------------
function e.Element:mouseRDown()
  return gfx.mouse_cap & 2 == 2 and self:pointIN(gMouseOX, gMouseOY)
end
--------------------------------------------------------------------------------
function e.Element:mouseMDown()
  return gfx.mouse_cap & 64 == 64 and self:pointIN(gMouseOX, gMouseOY)
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function e.Element:draw_frame() -- generic e.Element frame drawing
  gfx.rect(self.x, self.y, self.w, self.h, false) -- frame1
  gfx.roundrect(self.x, self.y, self.w - 1, self.h - 1, 3, true) -- frame2         
end

-------------------------------------------------------------------------------

function e.Element:Display(help_text)
  if self:mouseIN() or self:mouseLDown()  == true  then 
    gfx.setfont(4, dispfont , dispfont_size)
    gfx.x, gfx.y = dispx + 5, dispy + 20 
    gfx.set(table.unpack(disprgba)) 
    gfx.drawstr(help_text)
  end
end
----------------------------------------------------------------------------------
--Different classes
---------------------------------------------------------------------------------




--------------------------------------------------------------------------------
-- Metatable funtion for child classes(args = Child, Parent Class)
--------------------------------------------------------------------------------
function e.extended(Child, Parent)
  setmetatable(Child, {__index = Parent}) 
end
--------------------------------------------------------------------------------
-- Create Element Child Classes
-- Button, Checkbox, Droplist, Frame, Knob, Sliders, Textbox
--------------------------------------------------------------------------------
-- removed local <elm>

e.Button = {};       e.extended(e.Button, e.Element)

e.Droplist = {};     e.extended(e.Droplist, e.Element)
e.Droplist1 = {};     e.extended(e.Droplist1, e.Element)
e.Frame = {};        e.extended(e.Frame, e.Element)
e.Knob = {};         e.extended(e.Knob, e.Element)
e.Rad_Button = {};   e.extended(e.Rad_Button, e.Element)
e.H_Rng_Slider = {}; e.extended(e.H_Rng_Slider, e.Element)
e.V_Rng_Slider = {}; e.extended(e.V_Rng_Slider, e.Element)
e.Slider = {};       e.extended(e.Slider, e.Element)
e.Horz_Slider = {};  e.extended(e.Horz_Slider, e.Slider)
e.Vert_Slider = {};  e.extended(e.Vert_Slider, e.Slider)
e.Textbox = {};      e.extended(e.Textbox, e.Element)
e.Status = {};      e.extended(e.Status, e.Element)





--------------------------------------------------------------------------------
--  Status Class Methods
--------------------------------------------------------------------------------
function e.Status:new(tab, x,y,w,h, rgba, label, font, font_sz, font_rgba, val1, val2, min, max, step)
  local elm = {}
  local bf = 0
  if tab[1] == 0 then  -- convert the tabs table to a bitfield
    bf = 0
  else   
    for i = 1, #tab do
  bf = bf + (1 << tab[i])
    end
  end
  elm.tab = bf
  elm.def_xywh = {x,y,w,h, font_sz} -- default coordinates, used for zoom and some Element initialisation
  elm.x, elm.y, elm.w, elm.h = x, y, w, h -- position and size
  dispx, dispy = x , y 
  dispfont_size = font_sz
  dispfont = font
  disprgba = font_rgba
  elm.r, elm.g, elm.b, elm.a = table.unpack(rgba) -- Element colour
  elm.label, elm.font, elm.font_sz, elm.font_rgba  = label, font, font_sz, font_rgba -- all things fonty
  elm.val1 = val1;  elm.val2 = val2 -- general purpose variables or tables
  elm.min, elm.max, elm.step = min, max, step -- for incrementing or decrementing values
  elm.help = "This is a mouse over help text box"
  setmetatable(elm, self)
  self.__index = self

  return elm
end

function e.Status:draw()
  if e.gScaleState == true then -- update the font  and dispx for other elements
    dispx = math.ceil(self.def_xywh[1] * e.gScale)
    dispy = math.ceil(self.def_xywh[2] * e.gScale)
    self.font_sz = math.max(10, self.def_xywh[5] * e.gScale) -- update font
    self.font_sz = math.min(28, self.font_sz)
    dispfont_size = self.font_sz
   end
  self:update_zoom()  
  self:Display(self.help)

  --Draw title
  --[[
  gfx.set(self.r,self.g,self.b)
  gfx.x, gfx.y = self.x+3, self.y
  gfx.setfont(4, e.Arial , self.font_sz)
  gfx.drawstr(self.label)
  ]]

  --Draw frame
  gfx.set(self.r,self.g,self.b)---gfx.set(self.r, self.g, self.b)
  gfx.roundrect(self.x, self.y+17, self.w, self.h, 4, true)
  gfx.roundrect(self.x+1, self.y+18, self.w-2, self.h-2,true)

end




--------------------------------------------------------------------------------
-- Button Class Methods
--------------------------------------------------------------------------------
function e.Button:draw_body()
  gfx.rect(self.x, self.y, self.w, self.h, true)
end
--------------------------------------------------------------------------------
function e.Button:draw_label()
  local labelWidth, labelHeight = gfx.measurestr(self.label)
  gfx.x = self.x + (self.w - labelWidth) / 2
  gfx.y = self.y + (self.h - labelHeight) / 2
  gfx.drawstr(self.label)
end
---------------------------------------------------------------------------------
function e.Button:draw()
  self:update_zoom() 
  if (self.tab & (1 << e.gActiveLayer)) == 0 and self.tab ~= 0 then return end
  self:Display(self.help)
  local a = self.a -- local alpha value for highlight
  -- Get mouse state  
  if self:mouseIN()     then a = a + 0.1 end  -- if in e.Element, increase opacity
  if self:mouseLDown()  then a = a + 0.2 end  -- if e.Element clicked, increase opacity more
  -- in elm L_up (released and was previously pressed), run onLClick (user defined)
  if self:mouseLClick() and self.onLClick then self.onLClick() end
  -- in elm R_up (released and was previously pressed), run onRClick (user defined)
  if self:mouseRClick() and self.onRClick then self.onRClick() end
  gfx.set(self.r, self.g, self.b, a) -- set e.Element color
  self:draw_body()
  self:draw_frame()
  gfx.set(table.unpack(self.font_rgba)) -- set label color
  gfx.setfont(1, self.font, self.font_sz) -- set label font & size
  self:draw_label()
end

--------------------------------------------------------------------------------
-- Droplist Class Methods
--------------------------------------------------------------------------------
function e.Droplist:set_norm_val_m_wheel()
  if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
  if gfx.mouse_wheel < 0 then self.val1 = math.min(self.val1 + 1, #self.val2) end
  if gfx.mouse_wheel > 0 then self.val1 = math.max(self.val1 - 1, 1) end
  return true
end
--------------------------------------------------------------------------------
function e.Droplist:set_val1()
  local x, y, w, h  = self.x, self.y, self.w, self.h
  local val = self.val1
  local menu_tb = self.val2
  local menu_str = ""
  for i = 1, #menu_tb, 1 do
    if i ~= val then menu_str = menu_str .. menu_tb[i] .. "|"
    else menu_str = menu_str .. "!" .. menu_tb[i] .. "|" -- add check
    end
  end
  gfx.x = self.x; gfx.y = self.y + self.h
  local new_val = gfx.showmenu(menu_str) -- show Droplist menu
  if new_val > 0 then self.val1 = new_val end
end
--------------------------------------------------------------------------------
function e.Droplist:draw_body()
  gfx.rect(self.x, self.y, self.w, self.h, true)
end
--------------------------------------------------------------------------------
function e.Droplist:draw_label()
  local labelW, labelH = gfx.measurestr(self.label)
  local pad = 5
  gfx.x = self.x + ((self.w / 2) - (labelW / 2))
  gfx.y = self.y - ((labelH) + (labelH / 3))
  gfx.drawstr(self.label)
end
--------------------------------------------------------------------------------
function e.Droplist:draw_val()
  local x, y, w, h  = self.x, self.y, self.w, self.h
  local val = self.val2[self.val1]
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x + ((w / 2) - (val_w / 2))
  gfx.y = y + (h - val_h) / 2
  gfx.drawstr(val)
end
--------------------------------------------------------------------------------
function e.Droplist:draw()
  self:update_zoom() -- check and update if window resized
  if (self.tab & (1 << e.gActiveLayer)) == 0 and self.tab ~= 0 then return end 
  self:Display(self.help)
  local a = self.a -- local alpha value for highlighting the e.Element
  if self:mouseIN() then a = a + 0.1 -- if in e.Element, increase opacity
    if self:set_norm_val_m_wheel() then
  if self.onLClick then self.onLClick() end 
    end 
  end
  if self:mouseLDown() then a = a + 0.2 end -- if e.Element clicked, increase opacity more
  -- in elm L_up(released and was previously pressed)
  if self:mouseLClick() then self:set_val1()
    if self:mouseLClick() and self.onLClick then self.onLClick() end
  end
  -- right click support
  if self:mouseRClick() and self.onRClick then self.onRClick() end
  -- Draw combo body, frame
  gfx.set(self.r, self.g, self.b, a) -- set the drawing colour for the e.Element
  self:draw_body()
  self:draw_frame()
  -- Draw label
  gfx.set(table.unpack(self.font_rgba))   -- set label color
  gfx.setfont(1, self.font, self.font_sz) -- set label font
  self:draw_label() -- draw label
  self:draw_val() -- draw val
end

--================================================================================
-- Droplist1 Class Methods
--================================================================================

--------------------------------------------------------------------------------
function e.Droplist1:set_val1()
  local x, y, w, h  = self.x, self.y, self.w, self.h
  local val = 1        --eigentlich stand hier self.val1
  local menu_tb = self.val2
  local menu_str = ""
  for i = 1, #menu_tb, 1 do
    if i ~= val then menu_str = menu_str .. menu_tb[i] .. "|"
    else menu_str = menu_str .. "!" .. menu_tb[i] .. "|" -- add check
   end
  end
  gfx.x = self.x; gfx.y = self.y + self.h
  local new_val = gfx.showmenu(menu_str) -- show Droplist menu
  if new_val > 0 then self.val1 = new_val end
end
--------------------------------------------------------------------------------
function e.Droplist1:draw_body()
  gfx.rect(self.x, self.y, self.w, self.h, true)
end
--------------------------------------------------------------------------------

function e.Droplist1:draw_label()
  local labelWidth, labelHeight = gfx.measurestr(self.label)
  gfx.x = self.x + (self.w - labelWidth) / 2
  gfx.y = self.y + (self.h - labelHeight) / 2
  gfx.drawstr(self.label)
end
--------------------------------------------------------------------------------
function e.Droplist1:draw_val()
  local x, y, w, h  = self.x, self.y, self.w, self.h
  local val = self.val2[self.val1]
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x + ((w / 2) - (val_w / 2))
  gfx.y = y + (h - val_h) / 2
  gfx.drawstr(val)
end
--------------------------------------------------------------------------------
function e.Droplist1:draw()
  self:update_zoom() -- check and update if window resized
  if (self.tab & (1 << e.gActiveLayer)) == 0 and self.tab ~= 0 then return end 
  self:Display(self.help)
  local a = self.a -- local alpha value for highlighting the e.Element
  if self:mouseIN() then a = a + 0.1 -- if in e.Element, increase opacity
   -- if self:set_norm_val_m_wheel() then
--  if self.onLClick then self.onLClick() end 
   -- end 
  end
  if self:mouseLDown() then a = a + 0.2 end -- if e.Element clicked, increase opacity more
  -- in elm L_up(released and was previously pressed)
  if self:mouseLClick() then self:set_val1()
    if self:mouseLClick() and self.onLClick then self.onLClick() end
  end
  -- right click support
  if self:mouseRClick() and self.onRClick then self.onRClick() end
  -- Draw combo body, frame
  gfx.set(self.r, self.g, self.b, a) -- set the drawing colour for the e.Element
  self:draw_body()
  self:draw_frame()
  -- Draw label
  gfx.set(table.unpack(self.font_rgba))   -- set label color
  gfx.setfont(1, self.font, self.font_sz) -- set label font
  self:draw_label() -- draw label
--  self:draw_val() -- draw val
end
--==================================================================================
--==================================================================================
-- Frame Class Methods
--------------------------------------------------------------------------------
function e.Frame:draw()
  self:update_zoom() -- check and update if window resized
  if (self.tab & (1 << e.gActiveLayer)) == 0 and self.tab ~= 0 then return end 
  local a  = self.a -- local alpha value required for highlighting the e.Element
  if self:mouseIN() then a = a + 0.1 end -- if in e.Element, increase opacity
  gfx.set(self.r, self.g, self.b, a) -- set the drawing colour for the e.Element
  self:draw_frame()
end
--------------------------------------------------------------------------------
-- Knob Class Methods
--------------------------------------------------------------------------------
function e.Knob:pointIN(p_x, p_y)
  local radius, angle = e.Cart2Polar(p_x, p_y, self.ox, self.oy)
  return radius <= self.radius
end
--------------------------------------------------------------------------------
function e.Knob:set_val1()
  local val, K = 0, 5 -- val = temp value; K = coefficient(when Ctrl pressed)
  if Ctrl then 
    val = self.val1 + ((gLastMouseY-gfx.mouse_y) / (self.h * (2*K))) * self.max
  else 
    val = self.val1 + ((gLastMouseY-gfx.mouse_y) / (self.h * K)) * self.max
  end
  if val < self.min then val = self.min elseif val > self.max then val = self.max end
  self.val1 = val
end
--------------------------------------------------------------------------------
function e.Knob:set_norm_val_m_wheel()
  if gfx.mouse_wheel == 0 then return end  -- return if m_wheel = 0
  if gfx.mouse_wheel > 0 then self.val1 = math.min(self.val1 + self.step, self.max) end
  if gfx.mouse_wheel < 0 then self.val1 = math.max(self.val1 - self.step, self.min) end
  return true
end
--------------------------------------------------------------------------------
function e.Knob:draw_body()
  local floor = math.floor
  local radius = self.w / 2
  local ox, oy = self.x + self.w / 2, self.y + self.h / 2 -- knob centre origin
  local mx, my = floor(gfx.mouse_x), floor(gfx.mouse_y) -- get the mouse pos - debug only
  local r1, ang = e.Cart2Polar(mx, my, ox, oy) -- debug only
  gfx.circle(ox, oy, radius / 2, true) -- inner  
  gfx.circle(ox, oy, radius, false, true); gfx.circle(ox, oy, radius-0.5, false, true) -- outer
  local pi = math.pi
  local offs = pi + pi / 4 -- quarter of a circle offset to start of range
  local val1 = 1.5 * pi * Normalize(self.val1, self.max, self.min)  -- offset 
  local ang1, ang2 = offs - 0.01, offs + val1  
  for i = 1, 10 do -- draw outer circle value range
    gfx.arc(ox, oy, radius - 1, ang1, ang2, true)
    radius = radius - 0.5
  end
end
--------------------------------------------------------------------------------
function e.Knob:draw_label()
  local labelWidth, labelHeight = gfx.measurestr(self.label)
  gfx.x = self.ox - labelWidth / 2; gfx.y = self.oy + self.radius + (labelHeight / 2)
  gfx.drawstr(self.label)
end
--------------------------------------------------------------------------------
function e.Knob:draw_val()
  if self.int == false then -- for float 
    self.val1 = round(self.val1, 2) -- round self.val1 to a max 2 decimals number
    local strW, strH = gfx.measurestr(self.val1 )
    gfx.x = self.ox - (strW / 2)
    gfx.y = self.oy - (strH / 2) 
    gfx.drawstr(self.val1) -- draw knob Value
  else -- for int
    local val = math.floor(self.val1)
    local strW, strH = gfx.measurestr(val)
    gfx.x = self.ox - (strW / 2)
    gfx.y = self.oy - (strH / 2) 
    self.val = val
    gfx.drawstr(val) -- draw knob Value
  end
--[[   local str = string.format("%.0f", self.val1) -- Original
  local strW, strH = gfx.measurestr(str)
  gfx.x = self.ox - (strW / 2)
  gfx.y = self.oy - (strH / 2) 
  gfx.drawstr(str) -- draw knob Value ]]
end
--------------------------------------------------------------------------------
function e.Knob:draw()
  self:update_zoom() -- check and update if window resized
  if (self.tab & (1 << e.gActiveLayer)) == 0 and self.tab ~= 0 then return end 
  local a = self.a -- local alpha for highlighting the e.Element
  -- set additional knob specific state
  self.radius = self.w / 2
  self.ox, self.oy = self.x + self.w / 2, self.y + self.h / 2
  self:Display(self.help)
  if self:mouseIN() then a = a + 0.1 -- if in e.Element, increase opacity
    if self:set_norm_val_m_wheel() then 
  if self.onMove then self.onMove() end 
    end  
  end
  if self:mouseLDown() then a = a + 0.2 -- if e.Element clicked, increase opacity more 
    self:set_val1()
    if self.onMove then self.onMove() end 
  end
  if self:mouseRClick() and self.onRClick then self.onRClick() end -- if mouseR clicked and released, execute onRClick()
  gfx.set(self.r, self.g, self.b, a + 0.1) -- set the drawing colour for the e.Element
  self:draw_body()
  gfx.set(table.unpack(self.font_rgba)) -- set label color
  gfx.setfont(1, self.font, self.font_sz) -- set label font
  self:draw_label() -- draw label(if need)
  self:draw_val() -- draw value
end
--------------------------------------------------------------------------------
--  Radio Button Class Methods
--------------------------------------------------------------------------------
function e.Rad_Button:update_zoom() -- handle window zooming
  if not e.gScaleState then return end
  -- zoom font  
  self.font_sz = math.max(10, self.def_xywh[5] * e.gScale)
  self.font_sz = math.min(28, self.font_sz)
  -- zoom x pos, y pos 
  self.x = math.ceil(self.def_xywh[1] * e.gScale)
  self.y = math.ceil(self.def_xywh[2] * e.gScale)
  -- zoom checkboxes
  self.cbox_w = math.ceil(self.def_xywh[6] * e.gScale)
  self.cbox_h = math.ceil(self.def_xywh[7] * e.gScale)   
  -- zoom width
  local str_w, str_h, max_w = 0, 0, 0
  gfx.setfont(1, self.font, self.font_sz)
  for i = 1, #self.val2 do
    str_w, str_h = gfx.measurestr(self.val2[i])
    if str_w > max_w then max_w = str_w end  
  end
  self.def_xywh[3] = max_w + self.cbox_w + 15
  self.w = math.ceil(self.def_xywh[3])
  -- zoom height  
  self.def_xywh[4] = self.cbox_h * #self.val2
  self.h = math.ceil(self.def_xywh[4]) -- * gZoomH) --scale) 
end
--------------------------------------------------------------------------------
function e.Rad_Button:set_norm_val_m_wheel()
  if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
  if gfx.mouse_wheel < 0 then self.val1 = math.min(self.val1 + 1, #self.val2) end
  if gfx.mouse_wheel > 0 then self.val1 = math.max(self.val1 - 1, 1) end
  return true
end
--------------------------------------------------------------------------------
function e.Rad_Button:set_val1()
  local y, h = self.y + 2, self.h - 4 -- padding
  local tOptions = self.val2
  local val = math.floor(((gfx.mouse_y - y) / h) * #tOptions) + 1
  if val < 1 then val = 1 elseif val > #tOptions then val = #tOptions end
  self.val1 = val
end
--------------------------------------------------------------------------------
function e.Rad_Button:draw_body()
  local x, y = self.x + 2, self.y -- padding
  local padSize = .25 * e.gScale -- more padding...
  local r = self.cbox_w / 3
  local centerOffset = ((self.cbox_w - (2 * r)) / 2)
  -- adjust the options to be centered
  cx, cy = x + centerOffset, y + centerOffset
  for i = 1, #self.val2 do
    local optY = cy + ((i - 1) * self.cbox_w)
    gfx.circle(cx + r, optY + r, r, false)
    gfx.circle(cx + r, optY + r, r - padSize, false, true)
    if i == self.val1 then
     gfx.circle(cx + r, optY + r, r, true) -- big circle  
  gfx.circle(cx + r, optY + r, r * 0.5, true) -- small circle
  gfx.circle(cx + r, optY + r, r * 0.5, false) -- small frame
    end
  end
end
--------------------------------------------------------------------------------
function e.Rad_Button:draw_vals()
  local x, y, optY = self.x -22, self.y + 34 -- padding
  local tOptions = self.val2 -- table of options
  -- to match up with the options
  local r = self.cbox_w / 3
  local centerOffset = ((self.optSpacing - (2 * r)) / 2)
  cx, cy = x + self.cbox_w + centerOffset, y + centerOffset
  for i = 1, #tOptions do
    optY = cy + ((i - 1) * self.cbox_w)
    gfx.x, gfx.y = cx, optY
    gfx.drawstr(tOptions[i])
  end
end
--------------------------------------------------------------------------------
function e.Rad_Button:draw_label()
  local x, y = self.x, self.y + 10 -- padding
  local optSpacing = self.optSpacing
  -- to match up with the first option
  local r = self.cbox_w / 3
  local centerOffset = ((self.cbox_w - (2 * r)) / 2)
  y = y + centerOffset
  local labelWidth, labelHeight = gfx.measurestr(self.label)
  gfx.x = x + centerOffset-- labelWidth - 5
  gfx.y = self.y + self.h + labelHeight / 2 
  gfx.drawstr(self.label) 
end
--------------------------------------------------------------------------------
function e.Rad_Button:draw()
  while not self.setup do -- on first run, set the correct width and height
    local str_w, str_h, max_w = 0, 0, 0  
    self.cbox_w, self.cbox_h = self.w, self.h
    gfx.setfont(1, self.font, self.font_sz)
    for i = 1, #self.val2 do
  str_w, str_h = gfx.measurestr(self.val2[i])      
  if str_w > max_w then max_w = str_w end
    end
    self.def_xywh[3] = self.cbox_w + max_w + 15; self.w = self.def_xywh[3]
    self.def_xywh[4] = self.cbox_h * #self.val2; self.h = self.def_xywh[4]
    self.def_xywh[6] = self.cbox_w; self.def_xywh[7] = self.cbox_h
    self.setup = true
  end
  self:update_zoom() -- check and update if window resized
  if (self.tab & (1 << e.gActiveLayer)) == 0 and self.tab ~= 0 then return end 
  self:Display(self.help)
  local a = self.a -- local alpha value required for highlighting the e.Element
  self.optSpacing = (self.h / (#self.val2 or 1)) -- e.Element height / number of options
  if self:mouseIN() then a = a + 0 -- if in e.Element, increase opacity 
    if self:set_norm_val_m_wheel() then 
  if self.onLClick then self.onLClick() end 
    end 
  end
  -- in elm L_up(released and was previously pressed)
  if self:mouseLDown() then a = a + 0.2 end -- if e.Element clicked, increase opacity more
  -- in elm L_up(released and was previously pressed)
  if self:mouseLClick() then 
    self:set_val1()
    if self.onLClick then self.onLClick() end -- if mouseL clicked and released, execute onLClick()
  end
  if self:mouseRClick() and self.onRClick then self.onRClick() end -- if mouseR clicked and released, execute onRClick()
  gfx.set(self.r, self.g, self.b, a) -- set the drawing colour for the e.Element
  -- self:draw_frame()  -- looks better without the frame
  self:draw_body()
  gfx.set(table.unpack(self.font_rgba)) -- set label color
  gfx.setfont(1, self.font, self.font_sz) -- set label font 
  self:draw_vals()
  self:draw_label()
end

--------------------------------------------------------------------------------
--  Textbox Class Methods
--------------------------------------------------------------------------------
function e.Textbox:draw_body()
  gfx.rect(self.x, self.y, self.w, self.h, true)
end
--------------------------------------------------------------------------------
function e.Textbox:draw_label()
  local labelWidth, labelHeight = gfx.measurestr(self.label)
  gfx.x = self.x + (self.w - labelWidth) / 2
  gfx.y = self.y + (self.h - labelHeight) / 2
  gfx.drawstr(self.label)
end
--------------------------------------------------------------------------------
function e.Textbox:draw()
  self:update_zoom() -- check and update if window resized
  if (self.tab & (1 << e.gActiveLayer)) == 0 and self.tab ~= 0 then return end
  self:Display(self.help)
  -- in elm R_up (released and was previously pressed), run onRClick (user defined)
  if self:mouseRClick() and self.onRClick then self.onRClick() end
  gfx.set(self.r, self.g, self.b, self.a) -- set the drawing colour for the e.Element
  self:draw_body()
  self:draw_frame()
  gfx.set(table.unpack(self.font_rgba)) -- set label color
  gfx.setfont(1, self.font, self.font_sz) -- set label font
  self:draw_label()
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--For Saving ExtState
--------------------------------------------------------------------------------
-- Pickle table serialization - Steve Dekorte, http://www.dekorte.com, Apr 2000
--------------------------------------------------------------------------------
function pickle(t)
  return Pickle:clone():pickle_(t)
end
--------------------------------------------------------------------------------
Pickle = {
  clone = function (t) local nt = {}
  for i, v in pairs(t) do 
    nt[i] = v 
  end
  return nt 
end 
}
--------------------------------------------------------------------------------
function Pickle:pickle_(root)
  if type(root) ~= "table" then 
    error("can only pickle tables, not " .. type(root) .. "s")
  end
  self._tableToRef = {}
  self._refToTable = {}
  local savecount = 0
  self:ref_(root)
  local s = ""
  while #self._refToTable > savecount do
    savecount = savecount + 1
    local t = self._refToTable[savecount]
    s = s .. "{\n"
    for i, v in pairs(t) do
      s = string.format("%s[%s]=%s,\n", s, self:value_(i), self:value_(v))
    end
  s = s .. "},\n"
  end
  return string.format("{%s}", s)
end
--------------------------------------------------------------------------------
function Pickle:value_(v)
  local vtype = type(v)
  if     vtype == "string" then return string.format("%q", v)
  elseif vtype == "number" then return v
  elseif vtype == "boolean" then return tostring(v)
  elseif vtype == "table" then return "{"..self:ref_(v).."}"
  else error("pickle a " .. type(v) .. " is not supported")
  end 
end
--------------------------------------------------------------------------------
function Pickle:ref_(t)
  local ref = self._tableToRef[t]
  if not ref then 
    if t == self then error("can't pickle the pickle class") end
    table.insert(self._refToTable, t)
    ref = #self._refToTable
    self._tableToRef[t] = ref
  end
  return ref
end
--------------------------------------------------------------------------------
-- unpickle
--------------------------------------------------------------------------------
function unpickle(s)
  if type(s) ~= "string" then
    error("can't unpickle a " .. type(s) .. ", only strings")
  end
  local gentables = load("return " .. s)
  local tables = gentables()
  for tnum = 1, #tables do
    local t = tables[tnum]
    local tcopy = {}
    for i, v in pairs(t) do tcopy[i] = v end
    for i, v in pairs(tcopy) do
      local ni, nv
      if type(i) == "table" then ni = tables[i[1]] else ni = i end
      if type(v) == "table" then nv = tables[v[1]] else nv = v end
      t[i] = nil
      t[ni] = nv
    end
  end
  return tables[1]
end






---------------------------------------------------------
----User Configs
---------------------------------------------------------

---------------------------------------------------------
----Script Variables
---------------------------------------------------------
script = {}
script.name = "Script Gui" -- for setting the Extstate where some configs are saved within reaper
script.x = 10 
script.y = 10
script.d = 0
script.w = 2000
script.h = 240
script.def_zoom = 4 
script.zoomF = true

pExtState = {} -- Reaper project ext state table, put in this table what you want to save and load like pExtState.activeLayer = e.gActiveLayer
pExtStateStr = "" -- pickled string. a nom a nom a nom...
---------------------------------------------------------
----Functions
---------------------------------------------------------

--function reaperDoFile(file) local info = debug.getinfo(1,'S'); script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]; dofile(script_path .. file) end
--reaperDoFile("dl_gui.lua")

function save() -- Saves pExtState table in the project
  pExtStateStr = pickle(pExtState)
  reaper.SetProjExtState(0, script.name, "pExtState", pExtStateStr )
end

function update()
  d,x,y,w,h=gfx.dock(-1,0,0,0,0)
  pExtState.x = x
  pExtState.y = y
  pExtState.d = d
end

function Msg(something)
  reaper.ShowConsoleMsg('\n'..tostring(something))
end

_, grid, save_swing, save_swing_amt = reaper.GetSetProjectGrid(0, false)  --- grid setting to 16tel
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------FUNCTIONS---------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--==================================================================================================================
--============================= Length_SEQ_Input=====================================================================
--=======================================================================================================================
function length_input()
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end


function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end


ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then Msg("no items selected")return
end
retval, rhymx = reaper.GetUserInputs( "input2length", 2,"1=1grid  2=2grid  etc.,1 /factor", "1111111111111111,1" )


 name = {rhymx:match("^([^,]+),([^,]+)$")}
rhym1 = name[1]
factor = name[2] 

if rhym1 == nil then return end


rhy = (rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1
..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1
..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1
..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1
..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1
..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1
..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1
..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1
..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1
..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1
)

anzahl = string.len(rhy)


for i = 1,anzahl do
 Table_Rhy = {}    
    
  for i=1,anzahl do Table_Rhy[i] = tonumber(string.sub(rhy,i,i)) end
end

for a=1,100 do

ItemsSel = {}  
Idx = 1 

otherItems = {} 
counter = 1

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))
  
ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do
  item = reaper.GetSelectedMediaItem(0, i)
  take = reaper.GetActiveTake(item) 

  local thisTrack = reaper.GetMediaItem_Track(item)

  if thisTrack == mainTrack then
    
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].oldPlayrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].oldLength = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
     
  
    
    start = ItemsSel[1].oldPosition  
    grid_end = reaper.BR_GetNextGridDivision( start)      
    grid_length = grid_end - start 
   
   
    old_length = ItemsSel[Idx].oldLength 
    playrate = ItemsSel[Idx].oldPlayrate

    new_length = Table_Rhy[Idx] * grid_length/factor  --new length created from the table values x grid_length
    new_rate = ItemsSel[Idx].oldPlayrate*(old_length/new_length)

  
    ItemsSel[Idx].newLength = new_length
    ItemsSel[Idx].newRate = new_rate
 

    reaper.SetMediaItemInfo_Value(item, "D_LENGTH",new_length)
    reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", new_rate)

    Idx = Idx + 1 -- 1-based table in Lua 

  else
    otherItems[counter] = {
  item = item,
  take = take,
  track = thisTrack,
    }

    counter = counter + 1
  end
  
end

for i = 2, Idx - 1 do

  --grabs items
  local prevItem = ItemsSel[i-1].thisItem
  local thisItem = ItemsSel[i].thisItem

  --grabs previous item's info
  local prevStart = reaper.GetMediaItemInfo_Value(prevItem, "D_POSITION")
  local prevLen = reaper.GetMediaItemInfo_Value(prevItem, "D_LENGTH")
  local prevEnd = prevStart + prevLen


  ItemsSel[i].newStart = prevEnd


  reaper.SetMediaItemInfo_Value(thisItem, "D_POSITION", prevEnd) --sets item to be at the end of the previous item
end

local index = 1
for i = 1, counter - 1 do
  if index > Idx - 1 then index = 1 end

  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_POSITION", ItemsSel[index].newStart or ItemsSel[index].oldPosition) 
  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_LENGTH", ItemsSel[index].newLength)
  reaper.SetMediaItemTakeInfo_Value(otherItems[i].take, "D_PLAYRATE", ItemsSel[index].newRate)

  index = index + 1  
end

reaper.PreventUIRefresh(-1) 
reaper.UpdateArrange()
reaper.Undo_EndBlock("Input2Length", -1)
reaper.SetCursorContext(1,0)

end
end
---------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------LENGHT_RANDOM------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

--- random_length within the time selection depending on grid----
----- script by  jkuk,dragonetti and solger -------
---https://forum.cockos.com/showthread.php?p=2285825#post2285825

------------------------------------------------
function length_random_x()

ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

reaper.PreventUIRefresh(1)   

for a=1,100 do
ItemsSel = {}  
Idx = 1 
 
otherItems = {} 
counter = 1

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))
  
ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do
  item = reaper.GetSelectedMediaItem(0, i)
  take = reaper.GetActiveTake(item) 

  local thisTrack = reaper.GetMediaItem_Track(item)

  if thisTrack == mainTrack then
    
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].oldPlayrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].oldLength = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
    
    start = ItemsSel[1].oldPosition  
    grid_end = reaper.BR_GetNextGridDivision( start)      
    grid_length = grid_end - start
   
    
   Grids = {"1","2"}   
 
    Rand = Grids[math.random(1,#Grids)]   
    number = tonumber(Rand)       
   
    old_length = ItemsSel[Idx].oldLength 
    playrate = ItemsSel[Idx].oldPlayrate
    new_length = number * grid_length --new length randomly created from the table values x grid_length
    new_rate = ItemsSel[Idx].oldPlayrate*(old_length/new_length)

  
    ItemsSel[Idx].newLength = new_length
    ItemsSel[Idx].newRate = new_rate


    reaper.SetMediaItemInfo_Value(item, "D_LENGTH",new_length)
    reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", new_rate)

    Idx = Idx + 1 -- 1-based table in Lua 

  else
    otherItems[counter] = {
  item = item,
  take = take,
  track = thisTrack,
    }

    counter = counter + 1
  end
  
end


for i = 2, Idx - 1 do

  --grabs items
  local prevItem = ItemsSel[i-1].thisItem
  local thisItem = ItemsSel[i].thisItem

  --grabs previous item's info
  local prevStart = reaper.GetMediaItemInfo_Value(prevItem, "D_POSITION")
  local prevLen = reaper.GetMediaItemInfo_Value(prevItem, "D_LENGTH")
  local prevEnd = prevStart + prevLen


  ItemsSel[i].newStart = prevEnd


  reaper.SetMediaItemInfo_Value(thisItem, "D_POSITION", prevEnd) --sets item to be at the end of the previous item
end


local index = 1
for i = 1, counter - 1 do
  if index > Idx - 1 then index = 1 end

  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_POSITION", ItemsSel[index].newStart or ItemsSel[index].oldPosition) 
  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_LENGTH", ItemsSel[index].newLength)
  reaper.SetMediaItemTakeInfo_Value(otherItems[i].take, "D_PLAYRATE", ItemsSel[index].newRate)

  index = index + 1  
end


reaper.PreventUIRefresh(-1) 
reaper.UpdateArrange()
reaper.Undo_EndBlock("Item Random Position", -1)
reaper.SetCursorContext(1,0)

end


--[[
   * Тест только на windows  /  Test only on windows.
   * Отчет об ошибке: Если обнаружите какие либо ошибки, то сообщите по одной из указанных ссылок ниже (*Website)
   * Bug Reports: If you find any errors, please report one of the links below (*Website)
   *
   * Category:    Item
   * Description: Delete selected items outside time selection
   * Author:      Archie
   * Version:     1.02
   * Описание:    Удаление выбранных элементов вне времени выбора
   * Website:     http://forum.cockos.com/showthread.php?t=212819
   *              http://rmmedia.ru/threads/134701/
   * DONATION:    http://money.yandex.ru/to/410018003906628
   * DONATION:    http://paypal.me/ReaArchie?locale.x=ru_RU
   * Customer:    Archie(---)
   * Gave idea:   Archie(---)
   * Extension:   Reaper 6.03+ http://www.reaper.fm/
   * Changelog:
   *              v.1.0 [10.02.20]
   *                  + initialе
--]]
    --======================================================================================
    --////////////// SCRIPT \\\\\\\\\\\\\\  SCRIPT  //////////////  SCRIPT  \\\\\\\\\\\\\\\\
    --======================================================================================


    -------------------------------------------------------
    local function no_undo()reaper.defer(function()end)end;
    -------------------------------------------------------


    -------------------------------------------------------
    local function DeleteMediaItem(item);
    if item then;
    local tr = reaper.GetMediaItem_Track(item);
    reaper.DeleteTrackMediaItem(tr,item);
    end;
    end;
    -------------------------------------------------------


    local CountSelItem = reaper.CountSelectedMediaItems(0);
    if CountSelItem == 0 then no_undo() return end;


    local timeSelStart,timeSelEnd = reaper.GetSet_LoopTimeRange(0,0,0,0,0); -- В Аранже
    if timeSelStart == timeSelEnd then no_undo() return end;

    local Undo;

    for i = CountSelItem-1,0,-1 do;

    local SelItem = reaper.GetSelectedMediaItem(0,i);
    local PosIt = reaper.GetMediaItemInfo_Value(SelItem,"D_POSITION");
    local LenIt = reaper.GetMediaItemInfo_Value(SelItem,"D_LENGTH");
    local EndIt = PosIt + LenIt;

    if PosIt < timeSelEnd and EndIt > timeSelStart then;

    if not Undo then reaper.Undo_BeginBlock()Undo=1 end;

    if PosIt < timeSelEnd and EndIt > timeSelEnd then;
        local Right = reaper.SplitMediaItem(SelItem,timeSelEnd);
        if Right then
        DeleteMediaItem(Right);
        end
    end

    if PosIt < timeSelStart and EndIt > timeSelStart then;
        local Left = reaper.SplitMediaItem(SelItem,timeSelStart);
        if Left then
        DeleteMediaItem(SelItem);
        end
    end;
    else;
    if not Undo then reaper.Undo_BeginBlock()Undo=1 end;
    DeleteMediaItem(SelItem);
    end;
    end;


    if Undo then;
    reaper.Undo_EndBlock("Delete selected items outside time selection",-1);
    else;
    no_undo();
    end;
    reaper.UpdateArrange();



end
--============================================================================================================
--=================================== RESET_RATE_LENGTH  =====================================================
--============================================================================================================

function reset_rate_length()

-- local function Msg(str)
--  reaper.ShowConsoleMsg(tostring(str) .. "\n")
--end


reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

ItemsSel = {}
Idx = 1

otherItems = {} 
counter = 1

loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  )

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))

ItemsSelCount = reaper.CountSelectedMediaItems(0)

for i = 0, ItemsSelCount - 1 do
  item = reaper.GetSelectedMediaItem(0, i)
  take = reaper.GetActiveTake(item) 

  local thisTrack = reaper.GetMediaItem_Track(item)

  if thisTrack == mainTrack then
   
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
  --  ItemsSel[Idx].oldPlayrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].oldLength = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
    
    _,grid = reaper.GetSetProjectGrid( 0, false )
    start = ItemsSel[1].oldPosition  
    grid_end = reaper.BR_GetNextGridDivision( start)      
    grid_length = grid_end - start
    
    source = reaper.GetMediaItemTake_Source( take ) reaper.GetMediaItemTake_Source( take ) 
   source_length, lengthIsQN = reaper.GetMediaSourceLength( source )
  
  _,bpm1 = reaper.GetMediaFileMetadata(source,"Generic:BPM")
     _, _, tempo = reaper.TimeMap_GetTimeSigAtTime( 0, start )
     
     if bpm1 == ""
     then 
     play_factor = 1
     new_length = source_length*(60/tempo)
     
     else
     
     play_factor = tempo/bpm1
     new_length = source_length/play_factor
     
     end
  
    old_length = ItemsSel[Idx].oldLength
    playrate = ItemsSel[Idx].oldPlayrate
    
    
    
    ItemsSel[Idx].newLength = new_length
    ItemsSel[Idx].newRate = play_factor

    reaper.SetMediaItemInfo_Value(item, "D_LENGTH",new_length)
    reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", play_factor)

    Idx = Idx + 1 -- 1-based table in Lua 

  else
    otherItems[counter] = {
  item = item,
  take = take,
  track = thisTrack,
    }

    counter = counter + 1
  end
end
 
for i = 2, Idx - 1 do

  --grabs items
  local prevItem = ItemsSel[i-1].thisItem
  local thisItem = ItemsSel[i].thisItem

  --grabs previous item's info
  local prevStart = reaper.GetMediaItemInfo_Value(prevItem, "D_POSITION")
  local prevLen = reaper.GetMediaItemInfo_Value(prevItem, "D_LENGTH")
  local prevEnd = prevStart + prevLen

  ItemsSel[i].newStart = prevEnd

  reaper.SetMediaItemInfo_Value(thisItem, "D_POSITION", prevEnd) --sets item to be at the end of the previous item
end

local index = 1
for i = 1, counter - 1 do
  if index > Idx - 1 then index = 1 end

  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_POSITION", ItemsSel[index].newStart or ItemsSel[index].oldPosition)
  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_LENGTH", ItemsSel[index].newLength)
  reaper.SetMediaItemTakeInfo_Value(otherItems[i].take, "D_PLAYRATE", ItemsSel[index].newRate)

  index = index + 1
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock("reset_rate_length", -1)
reaper.SetCursorContext(1,0)
--Msg(source_length)
end


--============================================================================================================
--=================================== LENGTH_TO_GRID  =====================================================
--============================================================================================================
--set item_length to one grid_length--
function length_to_grid_x()

-----------------------------------
    local tbl={};
    local timeSelStart,timeSelEnd = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
    if timeSelStart~=timeSelEnd then;
    reaper.PreventUIRefresh(19862675);
    for i = 1, reaper.CountMediaItems(0)do;
    local item = reaper.GetMediaItem(0,i-1);
    local pos = reaper.GetMediaItemInfo_Value(item,"D_POSITION");
    if pos >= timeSelEnd then;
        tbl[#tbl+1]={};tbl[#tbl].item=item;tbl[#tbl].pos=pos;
    end;
    end; 
    end;
    -----------------------------------
local function Msg(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end

   
   ItemsSel = {}
   
   ItemsSelCount = reaper.CountSelectedMediaItems(0)  
   for i = 0, ItemsSelCount - 1 do      
     item = reaper.GetSelectedMediaItem(0, i)  
     take = reaper.GetActiveTake(item) 
   
     Idx = i + 1 -- 1-based table in Lua    
     ItemsSel[Idx] = {} 
     ItemsSel[Idx].thisItem = item
     ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
     ItemsSel[Idx].playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
     ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
   
     tempo = reaper.Master_GetTempo(0)
     
     factor = 120 / tempo
     
     start = ItemsSel[1].position 

     _,grid = reaper.GetSetProjectGrid(0, false)
   
     ppq = reaper.MIDI_GetPPQPosFromProjQN(take, 1+reaper.MIDI_GetProjQNFromPPQPos(take, 0))
     new_length = grid*2*factor

     old_length = ItemsSel[Idx].length
     playrate = ItemsSel[Idx].playrate
   
     new_rate = ItemsSel[Idx].playrate*(old_length/new_length)

     reaper.SetMediaItemInfo_Value(item, "D_LENGTH",new_length)
     reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", playrate)

   end
reaper.SetCursorContext(1,0)
end 



--============================================================================================================
--===================================       LENGTH_HALF  =====================================================
--============================================================================================================
--- random_length within the time selection depending on grid----
----- script by  jkuk,dragonetti and solger -------
---https://forum.cockos.com/showthread.php?p=2285825#post2285825
function length_half()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
------------------------------------------------ 
-- local function Msg(str)
--  reaper.ShowConsoleMsg(tostring(str) .. "\n")
--end


reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

ItemsSel = {}
Idx = 1

otherItems = {} 
counter = 1

loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  )

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do
  item = reaper.GetSelectedMediaItem(0, i)
  take = reaper.GetActiveTake(item) 

  local thisTrack = reaper.GetMediaItem_Track(item)

  if thisTrack == mainTrack then
   
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    if take ~=  nil then
       
        ItemsSel[Idx].oldPlayrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
       end
    ItemsSel[Idx].oldLength = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
    
    _,grid = reaper.GetSetProjectGrid( 0, false )
    start = ItemsSel[1].oldPosition  
    grid_end = reaper.BR_GetNextGridDivision( start)      
    grid_length = grid_end - start
  
    
    Grids = {"2"} 
    Rand = Grids[math.random(1,#Grids)]  
    number = tonumber(Rand) 
    
    
   

    old_length = ItemsSel[Idx].oldLength
    playrate = ItemsSel[Idx].oldPlayrate
    if playrate ~= nil then
        new_rate = ItemsSel[Idx].oldPlayrate*number
        end
    
    
    new_length = old_length/number
    


    ItemsSel[Idx].newLength = new_length
    ItemsSel[Idx].newRate = new_rate


    reaper.SetMediaItemInfo_Value(item, "D_LENGTH",new_length)
    if take ~= nil then
        reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", new_rate)
      end

    Idx = Idx + 1 -- 1-based table in Lua 

  else
    otherItems[counter] = {
  item = item,
  take = take,
  track = thisTrack,
    }

    counter = counter + 1
  end
end
 
for i = 2, Idx - 1 do

  --grabs items
  local prevItem = ItemsSel[i-1].thisItem
  local thisItem = ItemsSel[i].thisItem
  

  --grabs previous item's info
  local prevStart = reaper.GetMediaItemInfo_Value(prevItem, "D_POSITION")
  local prevLen = reaper.GetMediaItemInfo_Value(prevItem, "D_LENGTH")
  local prevEnd = prevStart + prevLen


  ItemsSel[i].newStart = prevEnd


  reaper.SetMediaItemInfo_Value(thisItem, "D_POSITION", prevEnd) --sets item to be at the end of the previous item
end

local index = 1
for i = 1, counter - 1 do
  if index > Idx - 1 then index = 1 end

  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_POSITION", ItemsSel[index].newStart or ItemsSel[index].oldPosition)
  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_LENGTH", ItemsSel[index].newLength)
  reaper.SetMediaItemTakeInfo_Value(otherItems[i].take, "D_PLAYRATE", ItemsSel[index].newRate)

  index = index + 1
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Item Random Position", -1)

end
--Msg(grid)


--============================================================================================================
--=================================== LENGTH_DOUBLE  =====================================================
--============================================================================================================
--- random_length within the time selection depending on grid----
----- script by  jkuk,dragonetti and solger -------
---https://forum.cockos.com/showthread.php?p=2285825#post2285825
function length_double()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
------------------------------------------------ 
-- local function Msg(str)
--  reaper.ShowConsoleMsg(tostring(str) .. "\n")
--end


reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

ItemsSel = {}
Idx = 1

otherItems = {} 
counter = 1

loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  )

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))


ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do
  item = reaper.GetSelectedMediaItem(0, i)
  take = reaper.GetActiveTake(item) 

  local thisTrack = reaper.GetMediaItem_Track(item)

  if thisTrack == mainTrack then
   
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    
    if take ~=  nil then
   
    ItemsSel[Idx].oldPlayrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
   end
    ItemsSel[Idx].oldLength = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
    
    _,grid = reaper.GetSetProjectGrid( 0, false )
    start = ItemsSel[1].oldPosition  
    grid_end = reaper.BR_GetNextGridDivision( start)      
    grid_length = grid_end - start
  
    
    Grids = {"0.5"} 
    Rand = Grids[math.random(1,#Grids)]  
    number = tonumber(Rand) 
    --number = 2*grid
    
   

    old_length = ItemsSel[Idx].oldLength
    playrate = ItemsSel[Idx].oldPlayrate
    
    if playrate ~= nil then
    new_rate = ItemsSel[Idx].oldPlayrate*number
    end
    new_length = old_length/number


    ItemsSel[Idx].newLength = new_length
    ItemsSel[Idx].newRate = new_rate


    reaper.SetMediaItemInfo_Value(item, "D_LENGTH",new_length)
    
    if take ~= nil then
    reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", new_rate)
  end
    Idx = Idx + 1 -- 1-based table in Lua 

  else
    otherItems[counter] = {
  item = item,
  take = take,
  track = thisTrack,
    }

    counter = counter + 1
  end
end

for i = 2, Idx - 1 do

  --grabs items
  local prevItem = ItemsSel[i-1].thisItem
  local thisItem = ItemsSel[i].thisItem

  --grabs previous item's info
  local prevStart = reaper.GetMediaItemInfo_Value(prevItem, "D_POSITION")
  local prevLen = reaper.GetMediaItemInfo_Value(prevItem, "D_LENGTH")
  local prevEnd = prevStart + prevLen


  ItemsSel[i].newStart = prevEnd


  reaper.SetMediaItemInfo_Value(thisItem, "D_POSITION", prevEnd) --sets item to be at the end of the previous item
end

local index = 1
for i = 1, counter - 1 do
  if index > Idx - 1 then index = 1 end

  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_POSITION", ItemsSel[index].newStart or ItemsSel[index].oldPosition)
  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_LENGTH", ItemsSel[index].newLength)
  reaper.SetMediaItemTakeInfo_Value(otherItems[i].take, "D_PLAYRATE", ItemsSel[index].newRate)

  index = index + 1
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Item Random Position", -1)

end
--Msg(grid)

--========================================================================================================================
--=================================== LENGTH_TRIPLET  ====================================================================
--========================================================================================================================
--- random_length within the time selection depending on grid----
----- script by  jkuk,dragonetti and solger -------
---https://forum.cockos.com/showthread.php?p=2285825#post2285825
function length_triplet()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
------------------------------------------------ 
-- local function Msg(str)
--  reaper.ShowConsoleMsg(tostring(str) .. "\n")
--end


reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

ItemsSel = {}
Idx = 1

otherItems = {} 
counter = 1

loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  )

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do
  item = reaper.GetSelectedMediaItem(0, i)
  take = reaper.GetActiveTake(item) 

  local thisTrack = reaper.GetMediaItem_Track(item)

  if thisTrack == mainTrack then
   
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].oldPlayrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].oldLength = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
    
    _,grid = reaper.GetSetProjectGrid( 0, false )
    start = ItemsSel[1].oldPosition  
    grid_end = reaper.BR_GetNextGridDivision( start)      
    grid_length = grid_end - start
  
    
    Grids = {"1.5"} 
    Rand = Grids[math.random(1,#Grids)]  
    number = tonumber(Rand) 
    --number = 2*grid
    
   

    old_length = ItemsSel[Idx].oldLength
    playrate = ItemsSel[Idx].oldPlayrate
    
    new_rate = ItemsSel[Idx].oldPlayrate*number
    new_length = old_length/number
    


    ItemsSel[Idx].newLength = new_length
    ItemsSel[Idx].newRate = new_rate


    reaper.SetMediaItemInfo_Value(item, "D_LENGTH",new_length)
    reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", new_rate)

    Idx = Idx + 1 -- 1-based table in Lua 

  else
    otherItems[counter] = {
  item = item,
  take = take,
  track = thisTrack,
    }

    counter = counter + 1
  end
end
 
for i = 2, Idx - 1 do

  --grabs items
  local prevItem = ItemsSel[i-1].thisItem
  local thisItem = ItemsSel[i].thisItem

  --grabs previous item's info
  local prevStart = reaper.GetMediaItemInfo_Value(prevItem, "D_POSITION")
  local prevLen = reaper.GetMediaItemInfo_Value(prevItem, "D_LENGTH")
  local prevEnd = prevStart + prevLen


  ItemsSel[i].newStart = prevEnd


  reaper.SetMediaItemInfo_Value(thisItem, "D_POSITION", prevEnd) --sets item to be at the end of the previous item
end

local index = 1
for i = 1, counter - 1 do
  if index > Idx - 1 then index = 1 end

  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_POSITION", ItemsSel[index].newStart or ItemsSel[index].oldPosition)
  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_LENGTH", ItemsSel[index].newLength)
  reaper.SetMediaItemTakeInfo_Value(otherItems[i].take, "D_PLAYRATE", ItemsSel[index].newRate)

  index = index + 1
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Item Random Position", -1)

end
--Msg(grid)
--========================================================================================================================
--=================================== RATE_RESET  ====================================================================
--========================================================================================================================
function rate_reset()

ItemsSel = {}

ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  
  take = reaper.GetActiveTake(item)
  source =  reaper.GetMediaItemTake_Source( take )
   
  Idx = i + 1 -- 1-based table in Lua      
  ItemsSel[Idx] = {}  
  ItemsSel[Idx].thisItem = item 
  ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" ) 
  ItemsSel[Idx].playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE") 
  ItemsSel[Idx].pitch =  reaper.GetMediaItemTakeInfo_Value( take, "D_PITCH" )
  ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH") 
  ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS") 
  ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source )
  ItemsSel[Idx].source = reaper.GetMediaItemTake_Source(take)
  
   start = ItemsSel[1].position   
   old_playrate = ItemsSel[Idx].playrate
  
   source = reaper.GetMediaItemTake_Source( take ) 
   source_length, lengthIsQN = reaper.GetMediaSourceLength( source )
   
   _,bpm1 = reaper.GetMediaFileMetadata(source,"Generic:BPM")
   _, _, tempo = reaper.TimeMap_GetTimeSigAtTime( 0, start )
  
   if bpm1 == "" then
   -- bpm1 = 120
    reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE",1)
  else
  
  playrate_factor = tempo/bpm1
     
  reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE",playrate_factor )
  
end
end 

reaper.UpdateTimeline()  

reaper.UpdateArrange()

end  


--========================================================================================================================
--=================================== RATE_TRIPLET    ====================================================================
--========================================================================================================================
function rate_triplet()

--function rate_random()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
reaper.PreventUIRefresh(1)   

for a=1,1 do
ItemsSel = {}  
Idx = 1  
 
otherItems = {} 
counter = 1

loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  )

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))
  
ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do
    item = reaper.GetSelectedMediaItem(0, i)
    take = reaper.GetActiveTake(item)
  source =  reaper.GetMediaItemTake_Source( take )
     bpm = tonumber(({reaper.CF_GetMediaSourceMetadata( source, "BPM", "" )})[2]) or
   tonumber(({reaper.CF_GetMediaSourceMetadata( src, "bpm", "" )})[2])
  _, comment = reaper.GetMediaFileMetadata(source, "XMP:dm/logComment" )       
 
  local thisTrack = reaper.GetMediaItem_Track(item)
 --if comment ~= "phrase" then break end
  if thisTrack == mainTrack then
     
    
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )+0.005
    ItemsSel[Idx].old_rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source )
    
    start = ItemsSel[1].oldPosition  
   
   rates = {"0.750"}
   Rand = rates[math.random(1,#rates)]    
   number = tonumber(Rand) 
  
   source = reaper.GetMediaItemTake_Source( take ) reaper.GetMediaItemTake_Source( take ) 
   source_length, lengthIsQN = reaper.GetMediaSourceLength( source )
  
  _,bpm1 = reaper.GetMediaFileMetadata(source,"Generic:BPM")
     _, _, tempo = reaper.TimeMap_GetTimeSigAtTime( 0, start )
     
     if bpm1 == "" then
     marker=reaper.FindTempoTimeSigMarker(0, start )
     retval, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = reaper.GetTempoTimeSigMarker( 0, marker )
     bpm1 = bpm
       
       end
     
   playrate_factor = tempo/bpm1
    old_length = ItemsSel[Idx].oldLength
  playrate = ItemsSel[Idx].old_rate
  new_rate = playrate_factor * number
   ItemsSel[Idx].newRate = new_rate

    reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", new_rate)

    Idx = Idx + 1 -- 1-based table in Lua 

  else
    otherItems[counter] = {
  item = item,
  take = take,
  track = thisTrack,
    } 

    counter = counter + 1
  end 
end
 
for i = 2, Idx - 1 do 

  --grabs items
  local prevItem = ItemsSel[i-1].thisItem
  local thisItem = ItemsSel[i].thisItem

  --grabs previous item's info
  local prevStart = reaper.GetMediaItemInfo_Value(prevItem, "D_POSITION")

  ItemsSel[i].newStart = prevEnd

end

--if comment ~= "phrase" then break end

local index = 1
for i = 1, counter - 1 do
  if index > Idx - 1 then index = 1 end

  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_POSITION", ItemsSel[index].newStart or ItemsSel[index].oldPosition) 
  reaper.SetMediaItemTakeInfo_Value(otherItems[i].take, "D_PLAYRATE", ItemsSel[index].newRate)

  index = index + 1  
end

reaper.PreventUIRefresh(-1) 
reaper.UpdateArrange()
reaper.Undo_EndBlock("Item Random Position", -1)

if endposi == loop_end then break end
end

end    


--========================================================================================================================
--=================================== RATE_HALF       ====================================================================
--========================================================================================================================
function rate_half()

--function rate_random()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
reaper.PreventUIRefresh(1)   

for a=1,1 do
ItemsSel = {}  
Idx = 1  
 
otherItems = {} 
counter = 1

loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  )

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))
  
ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do
    item = reaper.GetSelectedMediaItem(0, i)
    take = reaper.GetActiveTake(item)
  source =  reaper.GetMediaItemTake_Source( take )
     bpm = tonumber(({reaper.CF_GetMediaSourceMetadata( source, "BPM", "" )})[2]) or
   tonumber(({reaper.CF_GetMediaSourceMetadata( src, "bpm", "" )})[2])
  _, comment = reaper.GetMediaFileMetadata(source, "XMP:dm/logComment" )       
 
  local thisTrack = reaper.GetMediaItem_Track(item)
 --if comment ~= "phrase" then break end
  if thisTrack == mainTrack then
     
    
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].old_rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source )
    
    start = ItemsSel[1].oldPosition  
   
   rates = {"0.5"}
   Rand = rates[math.random(1,#rates)]    
   number = tonumber(Rand) 
  
   source = reaper.GetMediaItemTake_Source( take ) reaper.GetMediaItemTake_Source( take ) 
   source_length, lengthIsQN = reaper.GetMediaSourceLength( source )
  
  _,bpm1 = reaper.GetMediaFileMetadata(source,"Generic:BPM")
     _, _, tempo = reaper.TimeMap_GetTimeSigAtTime( 0, start )
     
     if bpm1 == "" then
       bpm1 = 120
       end
   playrate_factor = tempo/bpm1
    old_length = ItemsSel[Idx].oldLength
  playrate = ItemsSel[Idx].old_rate
  new_rate = playrate * number
   ItemsSel[Idx].newRate = new_rate

    reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", new_rate)

    Idx = Idx + 1 -- 1-based table in Lua 

  else
    otherItems[counter] = {
  item = item,
  take = take,
  track = thisTrack,
    } 

    counter = counter + 1
  end 
end
 
for i = 2, Idx - 1 do 

  --grabs items
  local prevItem = ItemsSel[i-1].thisItem
  local thisItem = ItemsSel[i].thisItem

  --grabs previous item's info
  local prevStart = reaper.GetMediaItemInfo_Value(prevItem, "D_POSITION")

  ItemsSel[i].newStart = prevEnd

end

--if comment ~= "phrase" then break end

local index = 1
for i = 1, counter - 1 do
  if index > Idx - 1 then index = 1 end

  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_POSITION", ItemsSel[index].newStart or ItemsSel[index].oldPosition) 
  reaper.SetMediaItemTakeInfo_Value(otherItems[i].take, "D_PLAYRATE", ItemsSel[index].newRate)

  index = index + 1  
end

reaper.PreventUIRefresh(-1) 
reaper.UpdateArrange()
reaper.Undo_EndBlock("Item Random Position", -1)

if endposi == loop_end then break end
end

end  


--========================================================================================================================
--===================================  RATE_TO_RIGHT  ====================================================================
--========================================================================================================================
function rate_double()
--function rate_random()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
reaper.PreventUIRefresh(1)   

for a=1,1 do
ItemsSel = {}  
Idx = 1  
 
otherItems = {} 
counter = 1

loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  )

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))
  
ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do
    item = reaper.GetSelectedMediaItem(0, i)
    take = reaper.GetActiveTake(item)
  source =  reaper.GetMediaItemTake_Source( take )
     bpm = tonumber(({reaper.CF_GetMediaSourceMetadata( source, "BPM", "" )})[2]) or
   tonumber(({reaper.CF_GetMediaSourceMetadata( src, "bpm", "" )})[2])
  _, comment = reaper.GetMediaFileMetadata(source, "XMP:dm/logComment" )       
 
  local thisTrack = reaper.GetMediaItem_Track(item)
 --if comment ~= "phrase" then break end
  if thisTrack == mainTrack then
     
    
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].old_rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source )
    
    start = ItemsSel[1].oldPosition  
   
   rates = {"2.0"}
   Rand = rates[math.random(1,#rates)]    
   number = tonumber(Rand) 
  
   source = reaper.GetMediaItemTake_Source( take ) reaper.GetMediaItemTake_Source( take ) 
   source_length, lengthIsQN = reaper.GetMediaSourceLength( source )
  
  _,bpm1 = reaper.GetMediaFileMetadata(source,"Generic:BPM")
     _, _, tempo = reaper.TimeMap_GetTimeSigAtTime( 0, start )
     
     if bpm1 == "" then
  bpm1 = 120
  end
     
   playrate_factor = tempo/bpm1
    old_length = ItemsSel[Idx].oldLength
  playrate = ItemsSel[Idx].old_rate
  new_rate = playrate * number
   ItemsSel[Idx].newRate = new_rate

    reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", new_rate)

    Idx = Idx + 1 -- 1-based table in Lua 

  else
    otherItems[counter] = {
  item = item,
  take = take,
  track = thisTrack,
    } 

    counter = counter + 1
  end 
end
 
for i = 2, Idx - 1 do 

  --grabs items
  local prevItem = ItemsSel[i-1].thisItem
  local thisItem = ItemsSel[i].thisItem

  --grabs previous item's info
  local prevStart = reaper.GetMediaItemInfo_Value(prevItem, "D_POSITION")

  ItemsSel[i].newStart = prevEnd

end

--if comment ~= "phrase" then break end

local index = 1
for i = 1, counter - 1 do
  if index > Idx - 1 then index = 1 end

  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_POSITION", ItemsSel[index].newStart or ItemsSel[index].oldPosition) 
  reaper.SetMediaItemTakeInfo_Value(otherItems[i].take, "D_PLAYRATE", ItemsSel[index].newRate)

  index = index + 1  
end

reaper.PreventUIRefresh(-1) 
reaper.UpdateArrange()
reaper.Undo_EndBlock("Item Random Position", -1)

if endposi == loop_end then break end
end


end



--========================================================================================================================
--=================================== RATE_RANDOM_WITHOUT_CHANGING_LENGTH  ===============================================
--========================================================================================================================

--function Msg(variable)
--  reaper.ShowConsoleMsg(tostring(variable).."\n")
--end

function rate_random()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
reaper.PreventUIRefresh(1)   

for a=1,1 do
ItemsSel = {}  
Idx = 1  
 
otherItems = {} 
counter = 1

loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  )

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))
  
ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do
    item = reaper.GetSelectedMediaItem(0, i)
    take = reaper.GetActiveTake(item)
  source =  reaper.GetMediaItemTake_Source( take )
     bpm = tonumber(({reaper.CF_GetMediaSourceMetadata( source, "BPM", "" )})[2]) or
       tonumber(({reaper.CF_GetMediaSourceMetadata( src, "bpm", "" )})[2])
  _, comment = reaper.GetMediaFileMetadata(source, "XMP:dm/logComment" )       
 
  local thisTrack = reaper.GetMediaItem_Track(item)
 --if comment ~= "phrase" then break end
  if thisTrack == mainTrack then
     
    
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )+0.005
    ItemsSel[Idx].old_rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source )
    
    start = ItemsSel[1].oldPosition  
   
   rates = {"1.5","2.0","1","0.75","0.5","0.667"}
   Rand = rates[math.random(1,#rates)]    
   number = tonumber(Rand) 
  
   source = reaper.GetMediaItemTake_Source( take ) reaper.GetMediaItemTake_Source( take ) 
   source_length, lengthIsQN = reaper.GetMediaSourceLength( source )
      
      _,bpm1 = reaper.GetMediaFileMetadata(source,"Generic:BPM")
     _, _, tempo = reaper.TimeMap_GetTimeSigAtTime( 0, start )
     
     if bpm1 == "" then
       playrate_factor = 1
       else
     
   playrate_factor = tempo/bpm1
   end
    old_length = ItemsSel[Idx].oldLength
      playrate = ItemsSel[Idx].oldPlayrate
      new_rate = playrate_factor * number
   ItemsSel[Idx].newRate = new_rate

    reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", new_rate)

    Idx = Idx + 1 -- 1-based table in Lua 

  else
    otherItems[counter] = {
  item = item,
  take = take,
  track = thisTrack,
    } 

    counter = counter + 1
  end 
end
 
for i = 2, Idx - 1 do 

  --grabs items
  local prevItem = ItemsSel[i-1].thisItem
  local thisItem = ItemsSel[i].thisItem

  --grabs previous item's info
  local prevStart = reaper.GetMediaItemInfo_Value(prevItem, "D_POSITION")

  ItemsSel[i].newStart = prevEnd

end

--if comment ~= "phrase" then break end

local index = 1
for i = 1, counter - 1 do
  if index > Idx - 1 then index = 1 end

  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_POSITION", ItemsSel[index].newStart or ItemsSel[index].oldPosition) 
  reaper.SetMediaItemTakeInfo_Value(otherItems[i].take, "D_PLAYRATE", ItemsSel[index].newRate)

  index = index + 1  
end

reaper.PreventUIRefresh(-1) 
reaper.UpdateArrange()
reaper.Undo_EndBlock("Item Random Position", -1)

if endposi == loop_end then break end
end

end
--========================================================================================================================
--=================================== STARTOFFS_LEFT_ONE_GRID  ==================================================================
--========================================================================================================================

-- @description Move item content left one grid unit
-- @version 1.0
-- @author me2beats
-- @changelog
--  + init
function start_left()
local r = reaper; local function nothing() end; local function bla() r.defer(nothing) end

local items = r.CountSelectedMediaItems()
if items == 0 then bla() return end

r.Undo_BeginBlock()
r.ApplyNudge(0, 0, 4, 2, -1, 0, 0)
r.Undo_EndBlock('move item content left one grid unit', -1)
end
--========================================================================================================================
--=================================== STARTOFFS_RIGHT_ONE_GRID  ==================================================================
--========================================================================================================================

-- @description Move item content right one grid unit
-- @version 1.0
-- @author me2beats
-- @changelog
--  + init
function start_right()
local r = reaper; local function nothing() end; local function bla() r.defer(nothing) end

local items = r.CountSelectedMediaItems()
if items == 0 then bla() return end

r.Undo_BeginBlock()
r.ApplyNudge(0, 0, 4, 2, 1, 0, 0)
r.Undo_EndBlock('move item content right one grid unit', -1)
end




--========================================================================================================================
--=================================== RANDOM_STARTOFFS  ==================================================================
--========================================================================================================================

----- script by dragonetti ----



function random_startoffs_x()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

reaper.PreventUIRefresh(1)   

for a=1,1 do
ItemsSel = {}  
Idx = 1  
 
otherItems = {} 
counter = 1

loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  )

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))
  
ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do
    item = reaper.GetSelectedMediaItem(0, i)
    take = reaper.GetActiveTake(item)
  source =  reaper.GetMediaItemTake_Source( take )
     bpm = tonumber(({reaper.CF_GetMediaSourceMetadata( source, "BPM", "" )})[2]) or
       tonumber(({reaper.CF_GetMediaSourceMetadata( src, "bpm", "" )})[2])
  _, comment = reaper.GetMediaFileMetadata(source, "XMP:dm/logComment" )    
  
  if bpm == nil then bpm = 120 end
 
  local thisTrack = reaper.GetMediaItem_Track(item)
 --if comment ~= "phrase" then break end
  if thisTrack == mainTrack then
     
    
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source )
    
    start = ItemsSel[1].oldPosition  
    grid_end = reaper.BR_GetNextGridDivision( start)      
    grid_length = grid_end - start
  -----
  length = ItemsSel[Idx].source_length
    note_start = ItemsSel[Idx].startoffs
    onebar = ItemsSel[Idx].startoffs + 2.5
    
    
    _, grid, save_swing, save_swing_amt = reaper.GetSetProjectGrid(proj, false) -- backup current grid settings
   
    bpm1 = reaper.TimeMap2_GetDividedBpmAtTime( 0, start )
    
    if bpm == 120 then bpm = bpm1
    else bpm = bpm end
    
   timing = (60/bpm) * 4
    
   grid_length = (grid * timing)      -- one bar at tempo 96bpm = 2.5 s
    
    factor = (length/grid_length)
    factor1 = math.floor(factor+0.5)
    rand_factor = math.random (1,factor1)
   new_start = rand_factor * grid_length
   -----    

 
    ItemsSel[Idx].newRate = new_start


  
    reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", new_start)

    Idx = Idx + 1 -- 1-based table in Lua 

  else
    otherItems[counter] = {
  item = item,
  take = take,
  track = thisTrack,
    } 

    counter = counter + 1
  end 
end
 
for i = 2, Idx - 1 do 

  --grabs items
  local prevItem = ItemsSel[i-1].thisItem
  local thisItem = ItemsSel[i].thisItem

  --grabs previous item's info
  local prevStart = reaper.GetMediaItemInfo_Value(prevItem, "D_POSITION")


  ItemsSel[i].newStart = prevEnd



end

--if comment ~= "phrase" then break end

local index = 1
for i = 1, counter - 1 do
  if index > Idx - 1 then index = 1 end

  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_POSITION", ItemsSel[index].newStart or ItemsSel[index].oldPosition) 

  reaper.SetMediaItemTakeInfo_Value(otherItems[i].take, "D_STARTOFFS", ItemsSel[index].newRate)

  index = index + 1  
end

reaper.PreventUIRefresh(-1) 
reaper.UpdateArrange()
reaper.Undo_EndBlock("Item Random Position", -1)

if endposi == loop_end then break end
end

end


--================================================================================================================================
--======================================= PHRASE_BUILDER_1RIGHT =========================================================================
--================================================================================================================================
-- phrase_builder 
--  Thanks MusoBob
-- Display a message in the console for debugging
--function phrase_builder_x()
-- phrase_builder 
--  Thanks MusoBob
-- Display a message in the console for debugging

function phrase_1_right()

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end

  
function get_chord_notes(r)  

   item0 =  reaper.GetTrackMediaItem(ctrack,r )
      _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
      
    if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
     if string.find(item_notes, "/") then
        root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
     else
        root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
     end
       
       if not chord or #chord == 0 then chord = "Maj" end
       if not slash then slash = "" end
   
    note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D" then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E" then note1 = 4
  elseif root == "F" then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G" then note1 = 7 
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A" then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B" then note1 = -1
  if not root then end
  end
  

  note2 = 0
  

  if string.find(",Maj,M,maj7", ","..chord..",", 1, true)       then note2=0  end  -- ionian
  if string.find(",m7,min7,-7,min6", ","..chord..",", 1, true)  then note2=-2 end  -- dorian 
  if string.find(",m7b9,", ","..chord..",", 1, true)            then note2=-4 end  -- phrygian
  if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=-4 end  -- lydian
  if string.find(",7,dom,", ","..chord..",", 1, true)           then note2=-7 end  -- mixolydian  
  if string.find(",m,", ","..chord..",", 1, true)               then note2=3  end  -- aeloian  
  if string.find(",m7b5,m7-5,", ","..chord..",", 1, true)       then note2=1  end  -- lokrian 
  
end


--MAIN---------------------------------------------------------------
function main()

  commandID2 = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
  reaper.Main_OnCommand(commandID2, 0) -- SWS: Select only track(s) with selected item(s) _SWS_SELTRKWITEM

       items = reaper.CountMediaItems(0)
  sel_tracks = reaper.CountSelectedTracks(0) 
  
  for i = 0, sel_tracks -1  do
  
  
    track = reaper.GetSelectedTrack(0,(sel_tracks-1)-i)
  
    track_number = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" ) 
    
    ctrack = getTrackByName("chordtrack")
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
            reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
        else -- track == nil/no track with that name was
     
    num_chords = reaper.CountTrackMediaItems(ctrack)

    for r = 0, num_chords -1 do -- regions loop start    
    
           chord_item = reaper.GetTrackMediaItem(ctrack, r )
                  pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
               length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
               rgnend = pos+length  
  
  for x = 0, items -1 do -- items loop start
   
   media_item = reaper.GetMediaItem( 0, x )
   
   selected_item = reaper.IsMediaItemSelected(media_item) 
   
   if selected_item then
   
    current_item = reaper.GetMediaItem( 0, x )
    item_start = reaper.GetMediaItemInfo_Value( current_item, "D_POSITION")+0.01
    
    --Does item start within region
    ctrack = getTrackByName("chordtrack")
    
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
        reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
    else -- track == nil/no track with that name was
          num_chords = reaper.CountTrackMediaItems(ctrack)
          
    if item_start >= pos and item_start < rgnend then 
      
      get_chord_notes(r) -- get the chord notes for current region
      

      if i == 0 and reaper.GetMediaItem_Track( current_item ) == track then
      
      take = reaper.GetActiveTake(current_item)
    source =  reaper.GetMediaItemTake_Source( take )
    _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
    
        if key == "C" or key == "Am" or key == "" then transpo = 0
       elseif key == "C#" or key == "A#m"then transpo = -1
       elseif key == "Db" or key == "Bbm"then transpo = -1
       elseif key == "D"  or key == "Bm"then transpo = -2
       elseif key == "Eb" or key == "Cm"then transpo = -3
        elseif key == "E" or key == "C#m"then transpo = -4
        elseif key == "F" or key == "Dm"then transpo = -5
       elseif key == "F#" or key == "D#m"then transpo = -6
       elseif key == "Gb" or key == "Ebm"then transpo = -6
        elseif key == "G" or key == "Em"then transpo = -7 
       elseif key == "G#" or key == "E#m"then transpo = -8
       elseif key == "Ab" or key == "Fm"then transpo = -8 
        elseif key == "A" or key == "F#m"then transpo = -9
        elseif key == "Bb" or key == "Gm"then transpo = -10
        elseif key == "B" or key == "G#m"then transpo = -11
        elseif key == "Cb" or key == "Abm"then transpo = -11
       if not key then end
       end
  
    
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note1+note2+transpo+7) -- phrase transpose
      
    
    end
    reaper.UpdateItemInProject(current_item)
      end
    end
   end
  end -- items loop end
    end -- regions loop end
  end
  end  
 end 
main()  
  

::skip:: 
  
  
end

--================================================================================================================================
--======================================= PHRASE_BUILDER_2LEFT =========================================================================
--================================================================================================================================
-- phrase_builder 
--  Thanks MusoBob
-- Display a message in the console for debugging
--function phrase_builder_x()
-- phrase_builder 
--  Thanks MusoBob
-- Display a message in the console for debugging

function phrase_2_left()

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end

  
function get_chord_notes(r)  

   item0 =  reaper.GetTrackMediaItem(ctrack,r )
      _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
      
    if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
     if string.find(item_notes, "/") then
        root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
     else
        root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
     end
       
       if not chord or #chord == 0 then chord = "Maj" end
       if not slash then slash = "" end
   
    note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D" then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E" then note1 = 4
  elseif root == "F" then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G" then note1 = 7 
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A" then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B" then note1 = -1
  if not root then end
  end
  

  note2 = 0
  

  if string.find(",Maj,M,maj7", ","..chord..",", 1, true)       then note2=0  end  -- ionian
  if string.find(",m7,min7,-7,min6", ","..chord..",", 1, true)  then note2=-2 end  -- dorian 
  if string.find(",m7b9,", ","..chord..",", 1, true)            then note2=-4 end  -- phrygian
  if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=-4 end  -- lydian
  if string.find(",7,dom,", ","..chord..",", 1, true)           then note2=-7 end  -- mixolydian  
  if string.find(",m,", ","..chord..",", 1, true)               then note2=3  end  -- aeloian  
  if string.find(",m7b5,m7-5,", ","..chord..",", 1, true)       then note2=1  end  -- lokrian 
  
end


--MAIN---------------------------------------------------------------
function main()

  commandID2 = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
  reaper.Main_OnCommand(commandID2, 0) -- SWS: Select only track(s) with selected item(s) _SWS_SELTRKWITEM

       items = reaper.CountMediaItems(0)
  sel_tracks = reaper.CountSelectedTracks(0) 
  
  for i = 0, sel_tracks -1  do
  
  
    track = reaper.GetSelectedTrack(0,(sel_tracks-1)-i)
  
    track_number = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" ) 
    
    ctrack = getTrackByName("chordtrack")
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
            reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
        else -- track == nil/no track with that name was
     
    num_chords = reaper.CountTrackMediaItems(ctrack)

    for r = 0, num_chords -1 do -- regions loop start    
    
           chord_item = reaper.GetTrackMediaItem(ctrack, r )
                  pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
               length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
               rgnend = pos+length  
  
  for x = 0, items -1 do -- items loop start
   
   media_item = reaper.GetMediaItem( 0, x )
   
   selected_item = reaper.IsMediaItemSelected(media_item) 
   
   if selected_item then
   
    current_item = reaper.GetMediaItem( 0, x )
    item_start = reaper.GetMediaItemInfo_Value( current_item, "D_POSITION")
    
    --Does item start within region
    ctrack = getTrackByName("chordtrack")
    
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
        reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
    else -- track == nil/no track with that name was
          num_chords = reaper.CountTrackMediaItems(ctrack)
          
    if item_start >= pos and item_start < rgnend then 
      
      get_chord_notes(r) -- get the chord notes for current region
      

      if i == 0 and reaper.GetMediaItem_Track( current_item ) == track then
      
      take = reaper.GetActiveTake(current_item)
    source =  reaper.GetMediaItemTake_Source( take )
    _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
    
        if key == "C" or key == "Am" or key == "" then transpo = 0
       elseif key == "C#" or key == "A#m"then transpo = -1
       elseif key == "Db" or key == "Bbm"then transpo = -1
       elseif key == "D"  or key == "Bm"then transpo = -2
       elseif key == "Eb" or key == "Cm"then transpo = -3
        elseif key == "E" or key == "C#m"then transpo = -4
        elseif key == "F" or key == "Dm"then transpo = -5
       elseif key == "F#" or key == "D#m"then transpo = -6
       elseif key == "Gb" or key == "Ebm"then transpo = -6
        elseif key == "G" or key == "Em"then transpo = -7 
       elseif key == "G#" or key == "E#m"then transpo = -8
       elseif key == "Ab" or key == "Fm"then transpo = -8 
        elseif key == "A" or key == "F#m"then transpo = -9
        elseif key == "Bb" or key == "Gm"then transpo = -10
        elseif key == "B" or key == "G#m"then transpo = -11
        elseif key == "Cb" or key == "Abm"then transpo = -11
       if not key then end
       end
  
    
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note1+note2+transpo-2) -- phrase transpose
      
    
    end
    reaper.UpdateItemInProject(current_item)
      end
    end
   end
  end -- items loop end
    end -- regions loop end
  end
  end  
 end 
main()  
  

::skip:: 
  
  
end

--================================================================================================================================
--======================================= PHRASE_BUILDER_2_RIGHT =========================================================================
--================================================================================================================================
-- phrase_builder 
--  Thanks MusoBob
-- Display a message in the console for debugging
--function phrase_builder_x()
-- phrase_builder 
--  Thanks MusoBob
-- Display a message in the console for debugging

function phrase_2_right()

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end

  
function get_chord_notes(r)  

   item0 =  reaper.GetTrackMediaItem(ctrack,r )
      _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
      
    if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
     if string.find(item_notes, "/") then
        root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
     else
        root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
     end
       
       if not chord or #chord == 0 then chord = "Maj" end
       if not slash then slash = "" end
   
    note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D" then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E" then note1 = 4
  elseif root == "F" then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G" then note1 = 7 
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A" then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B" then note1 = -1
  if not root then end
  end
  

  note2 = 0
  

  if string.find(",Maj,M,maj7", ","..chord..",", 1, true)       then note2=0  end  -- ionian
  if string.find(",m7,min7,-7,min6", ","..chord..",", 1, true)  then note2=-2 end  -- dorian 
  if string.find(",m7b9,", ","..chord..",", 1, true)            then note2=-4 end  -- phrygian
  if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=-4 end  -- lydian
  if string.find(",7,dom,", ","..chord..",", 1, true)           then note2=-7 end  -- mixolydian  
  if string.find(",m,", ","..chord..",", 1, true)               then note2=3  end  -- aeloian  
  if string.find(",m7b5,m7-5,", ","..chord..",", 1, true)       then note2=1  end  -- lokrian 
  
end


--MAIN---------------------------------------------------------------
function main()

  commandID2 = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
  reaper.Main_OnCommand(commandID2, 0) -- SWS: Select only track(s) with selected item(s) _SWS_SELTRKWITEM

       items = reaper.CountMediaItems(0)
  sel_tracks = reaper.CountSelectedTracks(0) 
  
  for i = 0, sel_tracks -1  do
  
  
    track = reaper.GetSelectedTrack(0,(sel_tracks-1)-i)
  
    track_number = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" ) 
    
    ctrack = getTrackByName("chordtrack")
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
            reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
        else -- track == nil/no track with that name was
     
    num_chords = reaper.CountTrackMediaItems(ctrack)

    for r = 0, num_chords -1 do -- regions loop start    
    
           chord_item = reaper.GetTrackMediaItem(ctrack, r )
                  pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
               length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
               rgnend = pos+length  
  
  for x = 0, items -1 do -- items loop start
   
   media_item = reaper.GetMediaItem( 0, x )
   
   selected_item = reaper.IsMediaItemSelected(media_item) 
   
   if selected_item then
   
    current_item = reaper.GetMediaItem( 0, x )
    item_start = reaper.GetMediaItemInfo_Value( current_item, "D_POSITION")
    
    --Does item start within region
    ctrack = getTrackByName("chordtrack")
    
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
        reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
    else -- track == nil/no track with that name was
          num_chords = reaper.CountTrackMediaItems(ctrack)
          
    if item_start >= pos and item_start < rgnend then 
      
      get_chord_notes(r) -- get the chord notes for current region
      

      if i == 0 and reaper.GetMediaItem_Track( current_item ) == track then
      
      take = reaper.GetActiveTake(current_item)
    source =  reaper.GetMediaItemTake_Source( take )
    _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
    
        if key == "C" or key == "Am" or key == "" then transpo = 0
       elseif key == "C#" or key == "A#m"then transpo = -1
       elseif key == "Db" or key == "Bbm"then transpo = -1
       elseif key == "D"  or key == "Bm"then transpo = -2
       elseif key == "Eb" or key == "Cm"then transpo = -3
        elseif key == "E" or key == "C#m"then transpo = -4
        elseif key == "F" or key == "Dm"then transpo = -5
       elseif key == "F#" or key == "D#m"then transpo = -6
       elseif key == "Gb" or key == "Ebm"then transpo = -6
        elseif key == "G" or key == "Em"then transpo = -7 
       elseif key == "G#" or key == "E#m"then transpo = -8
       elseif key == "Ab" or key == "Fm"then transpo = -8 
        elseif key == "A" or key == "F#m"then transpo = -9
        elseif key == "Bb" or key == "Gm"then transpo = -10
        elseif key == "B" or key == "G#m"then transpo = -11
        elseif key == "Cb" or key == "Abm"then transpo = -11
       if not key then end
       end
  
    
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note1+note2+transpo+2) -- phrase transpose
      
    
    end
    reaper.UpdateItemInProject(current_item)
      end
    end
   end
  end -- items loop end
    end -- regions loop end
  end
  end  
 end 
main()  
  

::skip:: 
  
  
end

--================================================================================================================================
--======================================= PHRASE_BUILDER_1RIGHT =========================================================================
--================================================================================================================================
-- phrase_builder 
--  Thanks MusoBob
-- Display a message in the console for debugging
--function phrase_builder_x()
-- phrase_builder 
--  Thanks MusoBob
-- Display a message in the console for debugging

function phrase_builder()

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end

  
function get_chord_notes(r)  

   item0 =  reaper.GetTrackMediaItem(ctrack,r )
      _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
      
    if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
     if string.find(item_notes, "/") then
        root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
     else
        root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
     end
       
       if not chord or #chord == 0 then chord = "Maj" end
       if not slash then slash = "" end
   
    note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D" then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E" then note1 = 4
  elseif root == "F" then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G" then note1 = 7 
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A" then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B" then note1 = -1
  if not root then end
  end
  

  note2 = 0
  

  if string.find(",Maj,M,maj7", ","..chord..",", 1, true)       then note2=0  end  -- ionian
  if string.find(",m7,min7,-7,min6", ","..chord..",", 1, true)  then note2=-2 end  -- dorian 
  if string.find(",m7b9,", ","..chord..",", 1, true)            then note2=-4 end  -- phrygian
  if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=-4 end  -- lydian
  if string.find(",7,dom,", ","..chord..",", 1, true)           then note2=-7 end  -- mixolydian  
  if string.find(",m,", ","..chord..",", 1, true)               then note2=3  end  -- aeloian  
  if string.find(",m7b5,m7-5,", ","..chord..",", 1, true)       then note2=1  end  -- lokrian 
  
end


--MAIN---------------------------------------------------------------
function main()

  commandID2 = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
  reaper.Main_OnCommand(commandID2, 0) -- SWS: Select only track(s) with selected item(s) _SWS_SELTRKWITEM

       items = reaper.CountMediaItems(0)
  sel_tracks = reaper.CountSelectedTracks(0) 
  
  for i = 0, sel_tracks -1  do
  
  
    track = reaper.GetSelectedTrack(0,(sel_tracks-1)-i)
  
    track_number = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" ) 
    
    ctrack = getTrackByName("chordtrack")
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
            reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
        else -- track == nil/no track with that name was
     
    num_chords = reaper.CountTrackMediaItems(ctrack)

    for r = 0, num_chords -1 do -- regions loop start    
    
           chord_item = reaper.GetTrackMediaItem(ctrack, r )
                  pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
               length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
               rgnend = pos+length  
  
  for x = 0, items -1 do -- items loop start
   
   media_item = reaper.GetMediaItem( 0, x )
   
   selected_item = reaper.IsMediaItemSelected(media_item) 
   
   if selected_item then
   
    current_item = reaper.GetMediaItem( 0, x )
    item_start = reaper.GetMediaItemInfo_Value( current_item, "D_POSITION")
    
    --Does item start within region
    ctrack = getTrackByName("chordtrack")
    
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
        reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
    else -- track == nil/no track with that name was
          num_chords = reaper.CountTrackMediaItems(ctrack)
          
    if item_start >= pos and item_start < rgnend then 
      
      get_chord_notes(r) -- get the chord notes for current region
      

      if i == 0 and reaper.GetMediaItem_Track( current_item ) == track then
      
      take = reaper.GetActiveTake(current_item)
    source =  reaper.GetMediaItemTake_Source( take )
    _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
    
        if key == "C" or key == "Am" or key == "" then transpo = 0
       elseif key == "C#" or key == "A#m"then transpo = -1
       elseif key == "Db" or key == "Bbm"then transpo = -1
       elseif key == "D"  or key == "Bm"then transpo = -2
       elseif key == "Eb" or key == "Cm"then transpo = -3
        elseif key == "E" or key == "C#m"then transpo = -4
        elseif key == "F" or key == "Dm"then transpo = -5
       elseif key == "F#" or key == "D#m"then transpo = -6
       elseif key == "Gb" or key == "Ebm"then transpo = -6
        elseif key == "G" or key == "Em"then transpo = -7 
       elseif key == "G#" or key == "E#m"then transpo = -8
       elseif key == "Ab" or key == "Fm"then transpo = -8 
        elseif key == "A" or key == "F#m"then transpo = -9
        elseif key == "Bb" or key == "Gm"then transpo = -10
        elseif key == "B" or key == "G#m"then transpo = -11
        elseif key == "Cb" or key == "Abm"then transpo = -11
       if not key then end
       end
  
    
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note1+note2+transpo) -- phrase transpose
      
    
    end
    reaper.UpdateItemInProject(current_item)
      end
    end
   end
  end -- items loop end
    end -- regions loop end
  end
  end  
 end 
main()  
  

::skip:: 
  
  
end

--================================================================================================================================
--======================================= PHRASE_BUILDER_1_LEFT =========================================================================
--================================================================================================================================
-- phrase_builder 
--  Thanks MusoBob
-- Display a message in the console for debugging
--function phrase_builder_x()
-- phrase_builder 
--  Thanks MusoBob
-- Display a message in the console for debugging

function phrase_1_left()

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end

  
function get_chord_notes(r)  

   item0 =  reaper.GetTrackMediaItem(ctrack,r )
      _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
      
    if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
     if string.find(item_notes, "/") then
        root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
     else
        root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
     end
       
       if not chord or #chord == 0 then chord = "Maj" end
       if not slash then slash = "" end
   
    note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D" then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E" then note1 = 4
  elseif root == "F" then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G" then note1 = 7 
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A" then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B" then note1 = -1
  if not root then end
  end
  

  note2 = 0
  

  if string.find(",Maj,M,maj7", ","..chord..",", 1, true)       then note2=0  end  -- ionian
  if string.find(",m7,min7,-7,min6", ","..chord..",", 1, true)  then note2=-2 end  -- dorian 
  if string.find(",m7b9,", ","..chord..",", 1, true)            then note2=-4 end  -- phrygian
  if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=-4 end  -- lydian
  if string.find(",7,dom,", ","..chord..",", 1, true)           then note2=-7 end  -- mixolydian  
  if string.find(",m,", ","..chord..",", 1, true)               then note2=3  end  -- aeloian  
  if string.find(",m7b5,m7-5,", ","..chord..",", 1, true)       then note2=1  end  -- lokrian 
  
end


--MAIN---------------------------------------------------------------
function main()

  commandID2 = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
  reaper.Main_OnCommand(commandID2, 0) -- SWS: Select only track(s) with selected item(s) _SWS_SELTRKWITEM

       items = reaper.CountMediaItems(0)
  sel_tracks = reaper.CountSelectedTracks(0) 
  
  for i = 0, sel_tracks -1  do
  
  
    track = reaper.GetSelectedTrack(0,(sel_tracks-1)-i)
  
    track_number = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" ) 
    
    ctrack = getTrackByName("chordtrack")
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
            reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
        else -- track == nil/no track with that name was
     
    num_chords = reaper.CountTrackMediaItems(ctrack)

    for r = 0, num_chords -1 do -- regions loop start    
    
           chord_item = reaper.GetTrackMediaItem(ctrack, r )
                  pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
               length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
               rgnend = pos+length  
  
  for x = 0, items -1 do -- items loop start
   
   media_item = reaper.GetMediaItem( 0, x )
   
   selected_item = reaper.IsMediaItemSelected(media_item) 
   
   if selected_item then
   
    current_item = reaper.GetMediaItem( 0, x )
    item_start = reaper.GetMediaItemInfo_Value( current_item, "D_POSITION")
    
    --Does item start within region
    ctrack = getTrackByName("chordtrack")
    
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
        reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
    else -- track == nil/no track with that name was
          num_chords = reaper.CountTrackMediaItems(ctrack)
          
    if item_start >= pos and item_start < rgnend then 
      
      get_chord_notes(r) -- get the chord notes for current region
      

      if i == 0 and reaper.GetMediaItem_Track( current_item ) == track then
      
      take = reaper.GetActiveTake(current_item)
    source =  reaper.GetMediaItemTake_Source( take )
    _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
    
        if key == "C" or key == "Am" or key == "" then transpo = 0
       elseif key == "C#" or key == "A#m"then transpo = -1
       elseif key == "Db" or key == "Bbm"then transpo = -1
       elseif key == "D"  or key == "Bm"then transpo = -2
       elseif key == "Eb" or key == "Cm"then transpo = -3
        elseif key == "E" or key == "C#m"then transpo = -4
        elseif key == "F" or key == "Dm"then transpo = -5
       elseif key == "F#" or key == "D#m"then transpo = -6
       elseif key == "Gb" or key == "Ebm"then transpo = -6
        elseif key == "G" or key == "Em"then transpo = -7 
       elseif key == "G#" or key == "E#m"then transpo = -8
       elseif key == "Ab" or key == "Fm"then transpo = -8 
        elseif key == "A" or key == "F#m"then transpo = -9
        elseif key == "Bb" or key == "Gm"then transpo = -10
        elseif key == "B" or key == "G#m"then transpo = -11
        elseif key == "Cb" or key == "Abm"then transpo = -11
       if not key then end
       end
  
    
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note1+note2+transpo-5) -- phrase transpose
      
    
    end
    reaper.UpdateItemInProject(current_item)
      end
    end
   end
  end -- items loop end
    end -- regions loop end
  end
  end  
 end 
main()  
  

::skip:: 
  
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------set_rate_1_and length to source-------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------
function rate_1_length_source()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

reaper.Main_OnCommand(40652,0)
sel_items = reaper.CountSelectedMediaItems(0)
if sel_items < 1 then
  return
end

for i = 0, sel_items - 1 do
     item = reaper.GetSelectedMediaItem(0, i)
     take = reaper.GetActiveTake(item, 0)
   _, bpm = reaper.GetMediaFileMetadata(source, "XMP:dm/tempo" ) -- consideration of the original key Metadata from wav file "Key" 
   _,bpm1 = reaper.GetMediaFileMetadata(source,"Generic:BPM")
   rate = bpm/bpm1

   sourcelength, lengthIsQN = reaper.GetMediaSourceLength(reaper.GetMediaItemTake_Source(take))
    
     reaper.SetMediaItemInfo_Value( item,"D_LENGTH" , sourcelength*rate )
end
end
----------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------RESET_CONTENT------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------
------- 
function reset_content()

ItemsSel = {}

ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  take = reaper.GetActiveTake(item)   
    
  Idx = i + 1 -- 1-based table in Lua    
  ItemsSel[Idx] = {}
  ItemsSel[Idx].thisItem = item
  ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
  ItemsSel[Idx].playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
  ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")


 -- onebar = ItemsSel[Idx].startoffs + 2



 
  reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS",0)
 
end 
reaper.UpdateArrange()
 
end
--===========================================================================================================================================
--================================random_source_length_to_source_length======================================================================
--===========================================================================================================================================
------script--- random_source_length_to_source_length---
---script idea - dragonetti --
--thanks to MusoBob
-- and code parts of .. mpl,me2beats 

-----------------------------------------------------------  key minus transpo ------------------------------------------------
function random_source_length_x()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

ItemsSel = {} 

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  
  take = reaper.GetActiveTake(item)
  source =  reaper.GetMediaItemTake_Source( take )
    
    Idx = i + 1 -- 1-based table in Lua      
    ItemsSel[Idx] = {}
    ItemsSel[Idx].thisItem = item 
    ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
    ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH") 
    ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")  
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source ) 
 
 
    old_pitch = ItemsSel[Idx].pitch

     
_, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
           if key == "C" or key == "Am" or key == "" then transpo = 0
          elseif key == "C#" or key == "A#m"then transpo = -1
          elseif key == "Db" or key == "Bbm"then transpo = -1
          elseif key == "D"  or key == "Bm"then transpo = -2
          elseif key == "Eb" or key == "Cm"then transpo = -3
           elseif key == "E" or key == "C#m"then transpo = -4
           elseif key == "F" or key == "Dm"then transpo = -5
          elseif key == "F#" or key == "D#m"then transpo = -6
          elseif key == "Gb" or key == "Ebm"then transpo = -6
           elseif key == "G" or key == "Em"then transpo = -7 
          elseif key == "G#" or key == "E#m"then transpo = -8
          elseif key == "Ab" or key == "Fm"then transpo = -8 
           elseif key == "A" or key == "F#m"then transpo = -9
           elseif key == "Bb" or key == "Gm"then transpo = -10
           elseif key == "B" or key == "G#m"then transpo = -11
           elseif key == "Cb" or key == "Abm"then transpo = -11
          if not key then end
          end                
       _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
      
   

  reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", old_pitch - transpo )
  
 

end
-----------------------------------------------------------------------------------------------------------------------------
----------- Switch item source file to random in folder -- by ---    me2beats -------



local r = reaper; local function nothing() end; local function bla() r.defer(nothing) end

function shuffle(array)

  function swap(array, index1, index2)
    array[index1], array[index2] = array[index2], array[index1]
  end

  local counter = #array
  while counter > 1 do
    local index = math.random(counter)
    swap(array, index, counter)
    counter = counter - 1
  end
end

local items = r.CountSelectedMediaItems()
if items == 0 then bla() return end


r.Undo_BeginBlock()
r.PreventUIRefresh(1)

--r.Main_OnCommand(40440,0)

for j = 0, r.CountSelectedMediaItems()-1 do
  local it = r.GetSelectedMediaItem(0,j)
  
  
  local tk = r.GetActiveTake(it)
  if not tk then goto cnt end
  if r.TakeIsMIDI(tk) then goto cnt end
  local src = r.GetMediaItemTake_Source(tk)
  if not src then goto cnt end
  local src_fn = r.GetMediaSourceFileName(src, '')
  local folder = src_fn:match[[(.*)\]]

  local clonedsource

  local pos, new_fn, files
  pos = r.GetExtState(folder, 'pos')
  if not (pos and pos ~= '') then
  
    local t = {}
    for i = 0, 10000 do
  local fn = r.EnumerateFiles(folder, i)
  if not fn or fn == '' then break end
  if fn:match'%.wav$' or fn:match'%.mp3$' or fn:match'%.aiff$' then
    t[#t+1] = folder..[[\]]..fn
  end
    end

    files = #t
    shuffle(t)
    
  
    for i = 1, files do
  local ext_key = tostring(i)
  r.SetExtState(folder, ext_key, t[i], 0)
    end

    r.SetExtState(folder, 'pos', 1, 0)
    r.SetExtState(folder, 'files', files, 0)
    pos = 1
    new_fn = t[1]
  else
    files = tonumber(r.GetExtState(folder, 'files'))
    pos = tonumber(r.GetExtState(folder, 'pos'))
    local f
    for i = 1, files do
  if pos <= files-1 then pos = pos+1 else pos = 1 end
  new_fn = r.GetExtState(folder, tostring(pos))
  if r.file_exists(new_fn) then f = pos break end
    end
    if not f then new_fn = nil
    else
  r.SetExtState(folder, 'pos', pos, 0)
    end

  end
  
  if new_fn then
    clonedsource = r.PCM_Source_CreateFromFile(new_fn)
    r.SetMediaItemTake_Source(tk, clonedsource)
    r.GetSetMediaItemTakeInfo_String(tk, 'P_NAME', new_fn:match[[.*\(.*)]], 1)
    r.UpdateItemInProject(it)
  end 
  
  ::cnt::
  
end
--reaper.Main_OnCommand(42228,0) --Item: Set item start/end to source media start/end --
r.Main_OnCommand(40439,0)   -- Item: Set selected media online --
r.Main_OnCommand(40047,0)  -- Peaks: Build any missing peaks --
r.PreventUIRefresh(-1)

r.Undo_EndBlock('Switch item source', -1)
--------------------------------------------------------------------------------------


------------------------------- mirror script by dragonetti, MusoBob ( source mpl script)---------------------------------

sel_item_count = reaper.CountSelectedMediaItems( 0 )

for i = 0, sel_item_count - 1 do
  item = reaper.GetSelectedMediaItem(0, i)
  take = reaper.GetActiveTake(item, 0)

   sourcelength, lengthIsQN = reaper.GetMediaSourceLength(reaper.GetMediaItemTake_Source(take))
           rate = reaper.GetMediaItemTakeInfo_Value( take, "D_PLAYRATE" )
     reaper.SetMediaItemInfo_Value( item,"D_LENGTH" , sourcelength/rate )   -- new source length to item length --
end

item_table_source_filename = {}
item_table_source_start = {}
item_table_source_length = {}
item_table_playrate = {}
item_table_source_pos = {}
item_table_source = {}
item_table_color = {}
table_mute = {}
item_ptrs = {}
itemCount = 1
other_items = {}
otherCount = 1
item_table_mute = {}

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))
for selitem = 0, (reaper.CountSelectedMediaItems(0)-1) do
   
   thisItem = reaper.GetSelectedMediaItem(0 , selitem )
   thisTrack = reaper.GetMediaItem_Track(thisItem)
   item = reaper.GetMediaItem(1, selitem )
   take = reaper.GetActiveTake(item)

  
  if thisTrack == mainTrack then
    item_ptrs[itemCount] =  thisItem
    itemCount = itemCount 
  
  else
    other_items[otherCount] = {
  item = thisItem,
  track = thisTrack,
    }

    otherCount = otherCount + 1
  end
end
reaper.Main_OnCommand(40297,0)

commandID = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
reaper.Main_OnCommand(commandID, 0)
name = reaper.ReverseNamedCommandLookup(commandID) 

sel_track_count =  reaper.CountSelectedTracks(0 )
upper_track = reaper.GetSelectedTrack( 0, 0 )

reaper.CountSelectedMediaItems(0)

for xselitem = 0, (reaper.CountSelectedMediaItems(0)-1) do
   upper_item = reaper.GetTrackMediaItem( upper_track, xselitem )
   first_item = reaper.GetSelectedMediaItem(0 , 0)
   xthisItem = reaper.GetSelectedMediaItem(0 , xselitem)
   xtake =  reaper.GetActiveTake(xthisItem )
    
    mute =  reaper.GetMediaItemInfo_Value(xthisItem, "B_MUTE" )
   color = reaper.GetMediaItemInfo_Value(xthisItem, "I_CUSTOMCOLOR" )
  source_pos = reaper.GetMediaItemInfo_Value( xthisItem, "D_POSITION" )
  source = reaper.GetMediaItemTake_Source(xtake)
   playrate = reaper.GetMediaItemTakeInfo_Value( xtake, "D_PLAYRATE" )
   source_length = reaper.GetMediaItemInfo_Value( xthisItem, "D_LENGTH" )
   source_start = reaper.GetMediaItemTakeInfo_Value( xtake, "D_STARTOFFS" )
   retval, source_filename = reaper.GetSetMediaItemTakeInfo_String(xtake, "P_NAME", "", 0)
   
  table.insert(item_table_mute, mute)
  table.insert(item_table_color, color)
  table.insert(item_table_source, source)
  table.insert(item_table_source_pos, source_pos)
  table.insert(item_table_playrate, playrate)
  table.insert(item_table_source_length, source_length)
  table.insert(item_table_source_start, source_start)
  table.insert(item_table_source_filename, source_filename)
  
end

---mute------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_mute)
  
  if item_table_mute[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "B_MUTE",item_table_mute[ptid])
  end
end
local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_mute[index] then
    index = 1
  end

  reaper.SetMediaItemInfo_Value(other_items[i].item, "B_MUTE", item_table_mute[index] )
  index = index + 1
end
---- color ---
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_color)
  
  if item_table_color[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "I_CUSTOMCOLOR",item_table_color[ptid])
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_color[index] then
    index = 1
  end

  reaper.SetMediaItemInfo_Value(other_items[i].item, "I_CUSTOMCOLOR", item_table_color[index] )
  index = index + 1
end
-------- source -------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_source)
  
  if item_table_source[ptid] then
    reaper.SetMediaItemTake_Source(reaper.GetActiveTake(item_ptrs[i]), item_table_source[ptid])
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_source[index] then
    index = 1
  end

  reaper.SetMediaItemTake_Source(reaper.GetActiveTake(other_items[i].item),  item_table_source[index] )
  index = index + 1
end
------------ position -----------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_source_pos)
  
  if item_table_source_pos[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i],"D_POSITION" ,item_table_source_pos[ptid])
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_source_pos[index] then
    index = 1
  end

  reaper.SetMediaItemInfo_Value(other_items[i].item,"D_POSITION" ,  item_table_source_pos[index] )
  index = index + 1
end

-------- playrate -------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_playrate)
  
  if item_table_playrate[ptid] then
    reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(item_ptrs[i]),"D_PLAYRATE", item_table_playrate[ptid])
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_playrate[index] then
    index = 1
  end

  reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(other_items[i].item),"D_PLAYRATE",  item_table_playrate[index] )
  index = index + 1
end

---------length------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_source_length)
  
  if item_table_source_length[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "D_LENGTH",item_table_source_length[ptid])
  end
end
local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_source_length[index] then
    index = 1
  end

  reaper.SetMediaItemInfo_Value(other_items[i].item, "D_LENGTH", item_table_source_length[index] )
  index = index + 1
end

-------- startoffs -------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_source_start)
  
  if item_table_source_start[ptid] then
    reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(item_ptrs[i]),"D_STARTOFFS", item_table_source_start[ptid])
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_source_start[index] then
    index = 1
  end

  reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(other_items[i].item),"D_STARTOFFS",  item_table_source_start[index] )
  index = index + 1
end

-------- filename -------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_source_filename)
  
  if item_table_source_filename[ptid] then
    reaper.GetSetMediaItemTakeInfo_String(reaper.GetActiveTake(item_ptrs[i]),"P_NAME", item_table_source_filename[ptid],1)
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_source_filename[index] then
    index = 1
  end

  reaper.GetSetMediaItemTakeInfo_String(reaper.GetActiveTake(other_items[i].item),"P_NAME",  item_table_source_filename[index],1 )
  index = index + 1
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

------------------------------------------------   key plus transpo  --------------------------------

ItemsSel = {} 

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  
  take = reaper.GetActiveTake(item)
  source =  reaper.GetMediaItemTake_Source( take )
    
    Idx = i + 1 -- 1-based table in Lua      
    ItemsSel[Idx] = {}
    ItemsSel[Idx].thisItem = item 
    ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
    ItemsSel[Idx].playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH") 
    ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")  
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source ) 
 
 
    old_pitch = ItemsSel[Idx].pitch
    old_playrate =  ItemsSel[Idx].playrate
    pos = ItemsSel[Idx].position
     
_, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
           if key == "C" or key == "Am" or key == "" then transpo = 0
          elseif key == "C#" or key == "A#m"then transpo = -1
          elseif key == "Db" or key == "Bbm"then transpo = -1
          elseif key == "D"  or key == "Bm"then transpo = -2
          elseif key == "Eb" or key == "Cm"then transpo = -3
           elseif key == "E" or key == "C#m"then transpo = -4
           elseif key == "F" or key == "Dm"then transpo = -5
          elseif key == "F#" or key == "D#m"then transpo = -6
          elseif key == "Gb" or key == "Ebm"then transpo = -6
           elseif key == "G" or key == "Em"then transpo = -7 
          elseif key == "G#" or key == "E#m"then transpo = -8
          elseif key == "Ab" or key == "Fm"then transpo = -8 
           elseif key == "A" or key == "F#m"then transpo = -9
           elseif key == "Bb" or key == "Gm"then transpo = -10
           elseif key == "B" or key == "G#m"then transpo = -11
           elseif key == "Cb" or key == "Abm"then transpo = -11
          if not key then end
          end                
       _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
       reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", old_pitch + transpo )
       
end                   

startOut, endOut = reaper.GetSet_LoopTimeRange(false, true, 0, 0, false)

 newstart = startOut
 newend = endOut




---]]----------------------- items together depending on regions and columns -- MusoBob ---------------
function items_together()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

  first_item = reaper.GetSelectedMediaItem(0, 0)
  
  
  item_t = {}

  item_count = reaper.CountSelectedMediaItems(0)
  
    -- main action
    for i = 2, item_count do
  item = reaper.GetSelectedMediaItem(0, i-1)
  if item ~= nil then
    prev_item = reaper.GetSelectedMediaItem(0, i-2)
    prev_item_pos = reaper.GetMediaItemInfo_Value(prev_item, "D_POSITION")
    prev_item_len = reaper.GetMediaItemInfo_Value(prev_item, "D_LENGTH")
    newpos = prev_item_pos + prev_item_len
    reaper.SetMediaItemInfo_Value(item, "D_POSITION", newpos)
    
    
  end  
     end 
  end
  
  


function count_regions()

  sel_item_count = reaper.CountSelectedMediaItems( 0 )
  first_item = reaper.GetSelectedMediaItem(0, 0) -- first selected item
  items_track = reaper.GetMediaItemTrack( first_item )
  
  reaper.Main_OnCommand( 40297, 0 ) -- Track: Unselect all tracks
  reaper.SetTrackSelected( items_track, 1 )
  
  first_item_num = reaper.GetMediaItemInfo_Value(first_item, "IP_ITEMNUMBER")
  first_item_start = reaper.GetMediaItemInfo_Value( first_item, "D_POSITION" )
  last_item = reaper.GetSelectedMediaItem(0, sel_item_count-1) 
  last_item_start = reaper.GetMediaItemInfo_Value( last_item, "D_POSITION" )
  item_count =  reaper.CountMediaItems( 0 )
  
  sel_item_table = {}
  
  for i = 0, item_count -1 do
    
    item = reaper.GetMediaItem( 0, i )
    is_sel = reaper.IsMediaItemSelected( item )
    if is_sel then 
  item_num = reaper.GetMediaItemInfo_Value(item, "IP_ITEMNUMBER")
    
  table.insert(sel_item_table, item_num)
    end
  end  
  
  reaper.Main_OnCommand( 40289, 0 ) -- Item: Unselect all items
  
  markeridx, first_region = reaper.GetLastMarkerAndCurRegion( 0, first_item_start )
  markeridx, last_region = reaper.GetLastMarkerAndCurRegion( 0, last_item_start )     
  
  
  for i = first_region, last_region do 
  
    retval, isrgnOut, posOut, rgnendOut, nameOut, markrgnindexnumberOut, colorOut = reaper.EnumProjectMarkers3(0, i)
    start_time, end_time = reaper.GetSet_LoopTimeRange(true, true, posOut, rgnendOut, 0)
    
    reaper.Main_OnCommand( 40718, 0 ) -- Item: Select all items on selected tracks in current time selection
    items_together()
    
  end
  
  reaper.Main_OnCommand( 40289, 0 ) -- Item: Unselect all items
  reaper.Main_OnCommand( 40635, 0 ) -- Time selection: Remove time selection

end 


function count_tracks()

  item_count =  reaper.CountMediaItems( 0 )
  sel_item_count1 = reaper.CountSelectedMediaItems( 0 )
  all_sel_item_table = {}
  
  for i = 0, item_count -1 do
    
    item = reaper.GetMediaItem( 0, i )
    is_sel = reaper.IsMediaItemSelected( item )
    if is_sel then
  
  table.insert(all_sel_item_table, i)
    end
  end 

  reaper.Main_OnCommand( 40297, 0 ) -- Track: Unselect all tracks

  for i = 0, item_count -1 do
    
    item = reaper.GetMediaItem( 0, i )
    is_sel = reaper.IsMediaItemSelected( item )
    if is_sel then 
  
  item_track = reaper.GetMediaItemTrack( item )
  reaper.SetTrackSelected( item_track, 1 )
    
    end
  end 
  
  track_count =  reaper.CountTracks( 0 )
  sel_track_table = {}
  for t = 0, track_count -1 do
    
    trackid = reaper.GetTrack( 0, t )
    
    is_track_sel = reaper.IsTrackSelected( trackid )
    if is_track_sel then
  
  table.insert(sel_track_table,t)
    end
  end
  
  sel_track_count = reaper.CountSelectedTracks2( 0, 0 )
  
  for s = 1, sel_track_count do
  
    reaper.Main_OnCommand( 40289, 0 ) -- Item: Unselect all items
    trackid = reaper.GetTrack( 0, sel_track_table[s] )
    reaper.SetOnlyTrackSelected( trackid )
    
    for ic = 1, sel_item_count1 do
  
  item = reaper.GetMediaItem( 0, all_sel_item_table[ic] )
  item_track = reaper.GetMediaItemTrack(item)
  
  if trackid == item_track then
  
    reaper.SetMediaItemSelected( item, 1 )
  end
    end
    
    count_regions()
    
  end 
  ------------------------------------------------------------
  -----------------------------------------------------
  ---------------------------------------------
  reaper.Main_OnCommand( 40289, 0 ) -- Item: Unselect all items
  reaper.Main_OnCommand( 40635, 0 ) -- Time selection: Remove time selection
  
  for i = 1, sel_item_count1 do
  
    item = reaper.GetMediaItem( 0, all_sel_item_table[i] )
    reaper.SetMediaItemSelected( item, 1 )
    
  end
end

count_tracks()
reaper.Main_OnCommand(1068,0 ) -- toggle loop on/off

startOut, endOut = reaper.GetSet_LoopTimeRange(true, true, newstart, newend, true)
reaper.Main_OnCommand(1068,0 )   -- toggle loop on/off
reaper.UpdateArrange()

 
end
--=============================================================================================================
--============================== shuffle_startoffs================================================================
--===============================================================================================================
---------------------------------------------------------------------------------------
--- random_length within the time selection depending on grid----
----- script by  jkuk,dragonetti and solger -------
---https://forum.cockos.com/showthread.php?p=2285825#post2285825

function shuffle_startoffs()

--function Msg(variable)
--  reaper.ShowConsoleMsg(tostring(variable).."\n")
--end
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end


reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

ItemsSel = {}
Idx = 1

otherItems = {} 
counter = 1

loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  )

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))


ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do
  item = reaper.GetSelectedMediaItem(0, i)
  take = reaper.GetActiveTake(item) 

  local thisTrack = reaper.GetMediaItem_Track(item)

  if thisTrack == mainTrack then
   
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].oldPlayrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].oldStartoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    ItemsSel[Idx].oldLength = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
    
    start = ItemsSel[1].oldPosition  
    
    _, grid, save_swing, save_swing_amt = reaper.GetSetProjectGrid(proj, false) -- backup current grid settings   
   
  source = reaper.GetMediaItemTake_Source( take ) 
  source_length, lengthIsQN = reaper.GetMediaSourceLength( source )
     --_, bpm = reaper.GetMediaFileMetadata(source, "XMP:dm/tempo" ) -- consideration of the original key Metadata from wav file "Key" 
  _,bpm1 = reaper.GetMediaFileMetadata(source,"Generic:BPM")
  
  if bpm1 =="" then 
  
   
     --  new_rate = 1
    marker=reaper.FindTempoTimeSigMarker(0, start )
    retval, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = reaper.GetTempoTimeSigMarker( 0, marker )
    bpm1 = bpm
  -- source_length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )*(bpm/120)
   grid_length = grid*2 *120/bpm
   bar_length = 120/bpm
     --  new_rate = 1
    else
    
   bar_length = 240/bpm1
   grid_length = (grid * bar_length)      -- one bar at tempo 96bpm = 2.5 s
end   
    --    if grid_length > source_length then return end
  --  rand_factor = math.random(rand_factor)
  --  new_start = rand_factor * grid_length
     -- rand_factor = (source_length*new_rate)/grid_length  
    

    new_length = ItemsSel[Idx].oldLength
    new_rate = ItemsSel[Idx].oldPlayrate
   -- new_startoffs = ItemsSel[Idx].oldStartoffs + new_start
    

    
   rand_factor = (source_length*new_rate)/grid_length 
   rand_factor_new = math.floor(rand_factor)
   factor_x = math.random(0,rand_factor_new)
   new_startoffs = factor_x*grid_length
    
    ItemsSel[Idx].newLength = new_length
    ItemsSel[Idx].newRate = new_rate
    ItemsSel[Idx].newStartoffs = new_startoffs
    

    reaper.SetMediaItemInfo_Value(item, "D_LENGTH",new_length)
    reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", new_rate)
   reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", new_startoffs)

    Idx = Idx + 1 -- 1-based table in Lua 

  else
    otherItems[counter] = {
  item = item,
  take = take,
  track = thisTrack,
    }

    counter = counter + 1
  end
end

for i = 2, Idx - 1 do

  --grabs items
  local prevItem = ItemsSel[i-1].thisItem
  local thisItem = ItemsSel[i].thisItem
  

  --grabs previous item's info
  local prevStart = reaper.GetMediaItemInfo_Value(prevItem, "D_POSITION")
  local prevLen = reaper.GetMediaItemInfo_Value(prevItem, "D_LENGTH")
  local prevEnd = prevStart + prevLen


  ItemsSel[i].newStart = prevEnd



end

local index = 1
for i = 1, counter - 1 do
  if index > Idx - 1 then index = 1 end


  reaper.SetMediaItemTakeInfo_Value(otherItems[i].take, "D_STARTOFFS", ItemsSel[index].newStartoffs)

  index = index + 1
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Item Random Position", -1)

--Msg(grid_length)
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------- random source ----------------------------------------------
----------------------------------------------------------------------------------------------------------



function random_source_x()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

ItemsSel = {} 

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  reaper.SetMediaItemInfo_Value( item, "B_LOOPSRC", 0)  ---loop source off -----
  take = reaper.GetActiveTake(item)
  source =  reaper.GetMediaItemTake_Source( take )
    
    Idx = i + 1 -- 1-based table in Lua      
    ItemsSel[Idx] = {}
    ItemsSel[Idx].thisItem = item 
    ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
    ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH") 
    ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")  
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source ) 
 
 
    old_pitch = ItemsSel[Idx].pitch

     
_, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
           if key == "C" or key == "Am" or key == "" then transpo = 0
          elseif key == "C#" or key == "A#m"then transpo = -1
          elseif key == "Db" or key == "Bbm"then transpo = -1
          elseif key == "D"  or key == "Bm"then transpo = -2
          elseif key == "Eb" or key == "Cm"then transpo = -3
           elseif key == "E" or key == "C#m"then transpo = -4
           elseif key == "F" or key == "Dm"then transpo = -5
          elseif key == "F#" or key == "D#m"then transpo = -6
          elseif key == "Gb" or key == "Ebm"then transpo = -6
           elseif key == "G" or key == "Em"then transpo = -7 
          elseif key == "G#" or key == "E#m"then transpo = -8
          elseif key == "Ab" or key == "Fm"then transpo = -8 
           elseif key == "A" or key == "F#m"then transpo = -9
           elseif key == "Bb" or key == "Gm"then transpo = -10
           elseif key == "B" or key == "G#m"then transpo = -11
           elseif key == "Cb" or key == "Abm"then transpo = -11
          if not key then end
          end                
       _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
      
   

  reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", old_pitch - transpo )
  
 

end

----------- Switch item source file to random in folder -- by ---    me2beats -------------------------------------------------------



local r = reaper; local function nothing() end; local function bla() r.defer(nothing) end

function shuffle(array)

  function swap(array, index1, index2)
    array[index1], array[index2] = array[index2], array[index1]
  end

  local counter = #array
  while counter > 1 do
    local index = math.random(counter)
    swap(array, index, counter)
    counter = counter - 1
  end
end

local items = r.CountSelectedMediaItems()
if items == 0 then bla() return end


r.Undo_BeginBlock()
r.PreventUIRefresh(1)

--r.Main_OnCommand(40440,0)

for j = 0, r.CountSelectedMediaItems()-1 do
  local it = r.GetSelectedMediaItem(0,j)
  
  
  local tk = r.GetActiveTake(it)
  if not tk then goto cnt end
  if r.TakeIsMIDI(tk) then goto cnt end
  local src = r.GetMediaItemTake_Source(tk)
  if not src then goto cnt end
  local src_fn = r.GetMediaSourceFileName(src, '')
  local folder = src_fn:match[[(.*)\]]

  local clonedsource

  local pos, new_fn, files
  pos = r.GetExtState(folder, 'pos')
  if not (pos and pos ~= '') then
  
    local t = {}
    for i = 0, 10000 do
  local fn = r.EnumerateFiles(folder, i)
  if not fn or fn == '' then break end
  if fn:match'%.wav$' or fn:match'%.mp3$' or fn:match'%.aiff$' then
    t[#t+1] = folder..[[\]]..fn
  end
    end

    files = #t
    shuffle(t)
    
  
    for i = 1, files do
  local ext_key = tostring(i)
  r.SetExtState(folder, ext_key, t[i], 0)
    end

    r.SetExtState(folder, 'pos', 1, 0)
    r.SetExtState(folder, 'files', files, 0)
    pos = 1
    new_fn = t[1]
  else
    files = tonumber(r.GetExtState(folder, 'files'))
    pos = tonumber(r.GetExtState(folder, 'pos'))
    local f
    for i = 1, files do
  if pos <= files-1 then pos = pos+1 else pos = 1 end
  new_fn = r.GetExtState(folder, tostring(pos))
  if r.file_exists(new_fn) then f = pos break end
    end
    if not f then new_fn = nil
    else
  r.SetExtState(folder, 'pos', pos, 0)
    end

  end
  
  if new_fn then
    clonedsource = r.PCM_Source_CreateFromFile(new_fn)
    r.SetMediaItemTake_Source(tk, clonedsource)
    r.GetSetMediaItemTakeInfo_String(tk, 'P_NAME', new_fn:match[[.*\(.*)]], 1)
    r.UpdateItemInProject(it)
  end 
  
  ::cnt::
  
end
--reaper.Main_OnCommand(42228,0) --Item: Set item start/end to source media start/end --
r.Main_OnCommand(40439,0)   -- Item: Set selected media online --
r.Main_OnCommand(40047,0)  -- Peaks: Build any missing peaks --
r.PreventUIRefresh(-1)

r.Undo_EndBlock('Switch item source', -1)
--------------------------------------------------------------------------------------


------------------------------- mirror script by dragonetti ( source mpl script)---------------------------------

sel_item_count = (reaper.CountSelectedMediaItems( 0 ))

item_table_source_filename = {}
item_table_source_start = {}
item_table_source_length = {}
item_table_playrate = {}
item_table_source_pos = {}
item_table_source = {}
item_table_color = {}
table_mute = {}
item_ptrs = {}
itemCount = 1
other_items = {}
otherCount = 1
item_table_mute = {}

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))
for selitem = 0, (reaper.CountSelectedMediaItems(0)-1) do
   
   thisItem = reaper.GetSelectedMediaItem(0 , selitem )
   thisTrack = reaper.GetMediaItem_Track(thisItem)
   item = reaper.GetMediaItem(1, selitem )
   take = reaper.GetActiveTake(item)

  
  if thisTrack == mainTrack then
    item_ptrs[itemCount] =  thisItem
    itemCount = itemCount 
  
  else
    other_items[otherCount] = {
  item = thisItem,
  track = thisTrack,
    }

    otherCount = otherCount + 1
  end
end
reaper.Main_OnCommand(40297,0)

commandID = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
reaper.Main_OnCommand(commandID, 0)
name = reaper.ReverseNamedCommandLookup(commandID) 

sel_track_count =  reaper.CountSelectedTracks(0 )
upper_track = reaper.GetSelectedTrack( 0, 0 )

reaper.CountSelectedMediaItems(0)

for xselitem = 0, (reaper.CountSelectedMediaItems(0)-1) do
   upper_item = reaper.GetTrackMediaItem( upper_track, xselitem )
   first_item = reaper.GetSelectedMediaItem(0 , 0)
   xthisItem = reaper.GetSelectedMediaItem(0 , xselitem)
   xtake =  reaper.GetActiveTake(xthisItem )
    
    mute =  reaper.GetMediaItemInfo_Value(xthisItem, "B_MUTE" )
   color = reaper.GetMediaItemInfo_Value(xthisItem, "I_CUSTOMCOLOR" )
  source_pos = reaper.GetMediaItemInfo_Value( xthisItem, "D_POSITION" )
  source = reaper.GetMediaItemTake_Source(xtake)
   playrate = reaper.GetMediaItemTakeInfo_Value( xtake, "D_PLAYRATE" )
   source_length = reaper.GetMediaItemInfo_Value( xthisItem, "D_LENGTH" )
   source_start = reaper.GetMediaItemTakeInfo_Value( xtake, "D_STARTOFFS" )
   retval, source_filename = reaper.GetSetMediaItemTakeInfo_String(xtake, "P_NAME", "", 0)
   
  table.insert(item_table_mute, mute)
  table.insert(item_table_color, color)
  table.insert(item_table_source, source)
  table.insert(item_table_source_pos, source_pos)
  table.insert(item_table_playrate, playrate)
  table.insert(item_table_source_length, source_length)
  table.insert(item_table_source_start, source_start)
  table.insert(item_table_source_filename, source_filename)
  
end


--------------------------------------------------------

---mute------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_mute)
  
  if item_table_mute[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "B_MUTE",item_table_mute[ptid])
  end
end
local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_mute[index] then
    index = 1
  end

  reaper.SetMediaItemInfo_Value(other_items[i].item, "B_MUTE", item_table_mute[index] )
  index = index + 1
end
---- color ---
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_color)
  
  if item_table_color[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "I_CUSTOMCOLOR",item_table_color[ptid])
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_color[index] then
    index = 1
  end

  reaper.SetMediaItemInfo_Value(other_items[i].item, "I_CUSTOMCOLOR", item_table_color[index] )
  index = index + 1
end
-------- source -------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_source)
  
  if item_table_source[ptid] then
    reaper.SetMediaItemTake_Source(reaper.GetActiveTake(item_ptrs[i]), item_table_source[ptid])
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_source[index] then
    index = 1
  end

  reaper.SetMediaItemTake_Source(reaper.GetActiveTake(other_items[i].item),  item_table_source[index] )
  index = index + 1
end
------------ position -----------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_source_pos)
  
  if item_table_source_pos[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i],"D_POSITION" ,item_table_source_pos[ptid])
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_source_pos[index] then
    index = 1
  end

  reaper.SetMediaItemInfo_Value(other_items[i].item,"D_POSITION" ,  item_table_source_pos[index] )
  index = index + 1
end

-------- playrate -------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_playrate)
  
  if item_table_playrate[ptid] then
    reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(item_ptrs[i]),"D_PLAYRATE", item_table_playrate[ptid])
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_playrate[index] then
    index = 1
  end

  reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(other_items[i].item),"D_PLAYRATE",  item_table_playrate[index] )
  index = index + 1
end

---------length------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_source_length)
  
  if item_table_source_length[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "D_LENGTH",item_table_source_length[ptid])
  end
end
local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_source_length[index] then
    index = 1
  end

  reaper.SetMediaItemInfo_Value(other_items[i].item, "D_LENGTH", item_table_source_length[index] )
  index = index + 1
end

-------- startoffs -------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_source_start)
  
  if item_table_source_start[ptid] then
    reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(item_ptrs[i]),"D_STARTOFFS", item_table_source_start[ptid])
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_source_start[index] then
    index = 1
  end

  reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(other_items[i].item),"D_STARTOFFS",  item_table_source_start[index] )
  index = index + 1
end

-------- filename -------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_source_filename)
  
  if item_table_source_filename[ptid] then
    reaper.GetSetMediaItemTakeInfo_String(reaper.GetActiveTake(item_ptrs[i]),"P_NAME", item_table_source_filename[ptid],1)
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_source_filename[index] then
    index = 1
  end

  reaper.GetSetMediaItemTakeInfo_String(reaper.GetActiveTake(other_items[i].item),"P_NAME",  item_table_source_filename[index],1 )
  index = index + 1
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

------------------------------------------------   key plus transpo  --------------------------------

ItemsSel = {} 

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  
  take = reaper.GetActiveTake(item)
  source =  reaper.GetMediaItemTake_Source( take )
    
    Idx = i + 1 -- 1-based table in Lua      
    ItemsSel[Idx] = {}
    ItemsSel[Idx].thisItem = item 
    ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
    ItemsSel[Idx].playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH") 
    ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")  
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source ) 
 
 
    old_pitch = ItemsSel[Idx].pitch
    old_playrate =  ItemsSel[Idx].playrate
    pos = ItemsSel[Idx].position
     
_, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
           if key == "C" or key == "Am" or key == "" then transpo = 0
          elseif key == "C#" or key == "A#m"then transpo = -1
          elseif key == "Db" or key == "Bbm"then transpo = -1
          elseif key == "D"  or key == "Bm"then transpo = -2
          elseif key == "Eb" or key == "Cm"then transpo = -3
           elseif key == "E" or key == "C#m"then transpo = -4
           elseif key == "F" or key == "Dm"then transpo = -5
          elseif key == "F#" or key == "D#m"then transpo = -6
          elseif key == "Gb" or key == "Ebm"then transpo = -6
           elseif key == "G" or key == "Em"then transpo = -7 
          elseif key == "G#" or key == "E#m"then transpo = -8
          elseif key == "Ab" or key == "Fm"then transpo = -8 
           elseif key == "A" or key == "F#m"then transpo = -9
           elseif key == "Bb" or key == "Gm"then transpo = -10
           elseif key == "B" or key == "G#m"then transpo = -11
           elseif key == "Cb" or key == "Abm"then transpo = -11
          if not key then end
          end                
       _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
       reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", old_pitch + transpo )
       
end                   


  
reaper.UpdateArrange() -- Update the arrangement (often needed)
 
reaper.PreventUIRefresh(-1)

end
--========================================================================================================================
--=========================================SCALE BUILDER =================================================================
--=======================================================================================================================

function scale_builder()



function Msg(variable) 
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end
function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end
ctrack = getTrackByName("chordtrack")
if ctrack == nil then Msg("no chordtrack")return end

ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then Msg("select items")return
end

retval, seq = reaper.GetUserInputs( "scale sequenzer", 2,"seq(q-i) mute=o  octa=(a-k),semi(1-8)//     accent(1,0)", "qeteqete,10001000" )

 
Table_Seq = {string.sub(seq,1,1),string.sub(seq,2,2),string.sub(seq,3,3),string.sub(seq,4,4),string.sub(seq,5,5)
,string.sub(seq,6,6),string.sub(seq,7,7),string.sub(seq,8,8)}

Table_Vel = {string.sub(seq,10,10),string.sub(seq,11,11),string.sub(seq,12,12),string.sub(seq,13,13),string.sub(seq,14,14)
,string.sub(seq,15,15),string.sub(seq,16,16),string.sub(seq,17,17)}


seq1w ="note"..tostring(Table_Seq[1])
seq2w ="note"..tostring(Table_Seq[2])
seq3w ="note"..tostring(Table_Seq[3])
seq4w ="note"..tostring(Table_Seq[4])
seq5w ="note"..tostring(Table_Seq[5])
seq6w ="note"..tostring(Table_Seq[6])
seq7w ="note"..tostring(Table_Seq[7])
seq8w ="note"..tostring(Table_Seq[8])

velo1s ="vel"..tostring(Table_Vel[1])
velo2s ="vel"..tostring(Table_Vel[2])
velo3s ="vel"..tostring(Table_Vel[3])
velo4s ="vel"..tostring(Table_Vel[4])
velo5s ="vel"..tostring(Table_Vel[5])
velo6s ="vel"..tostring(Table_Vel[6])
velo7s ="vel"..tostring(Table_Vel[7])
velo8s ="vel"..tostring(Table_Vel[8])
 
function get_chord_notes(chord_region)  

          item0 =  reaper.GetTrackMediaItem(ctrack,chord_region )
 _, region_name = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
            pos = reaper.GetMediaItemInfo_Value( item0, "D_POSITION" )-0.05
         length = reaper.GetMediaItemInfo_Value( item0, "D_LENGTH" )
     region_end = pos+length      
    

 --   retval, isrgn, region_pos, region_end, region_name, region_index, region_color = reaper.EnumProjectMarkers3( 0, chord_region)
     
  if string.match( region_name, "@.*") then next_region() end -- skip region marked @ ignore     
   if string.find(region_name, "/") then
      root, chord, slash = string.match(region_name, "(%w[#b]?)(.*)(/%a[#b]?)$")
   else
      root, chord = string.match(region_name, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
   end

     
     if not chord then Msg("Can't recognize a chord") end 
     if #chord == 0 then chord = "Maj" end
     if not slash then slash = "" end
  

  note_root = 0 
  -- 60 = C3
  if root == "C" then note_root = 0
  elseif root == "C#" then note_root = 1
  elseif root == "Db" then note_root = 1 
  elseif root == "D" then note_root = 2
  elseif root == "D#" then note_root = 3 
  elseif root == "Eb" then note_root = 3
  elseif root == "E" then note_root = 4
  elseif root == "F" then note_root = 5
  elseif root == "F#" then note_root = 6
  elseif root == "Gb" then note_root = 6
  elseif root == "G" then note_root = 7 
  elseif root == "G#" then note_root = 8
  elseif root == "Ab" then note_root = 8
  elseif root == "A" then note_root = 9
  elseif root == "A#" then note_root = 10
  elseif root == "Bb" then note_root = 10
  elseif root == "B" then note_root = 11
  if not root then end
  end
  




  
    if string.find(",Maj7,maj7,Maj7,Maj,M,M7,", ","..chord..",", 1, true) then notew=2  notee=4  noter=5  notet=7  notez=9  noteu=11  end -- Ionian 
    if string.find(",m7,min7,-7,", ","..chord..",", 1, true)              then notew=2  notee=3  noter=5  notet=7  notez=9  noteu=10  end -- Dorian
    if string.find(",m7b9,m7b9b13", ","..chord..",", 1, true)             then notew=1  notee=3  noter=5  notet=7  notez=8  noteu=10  end -- Phrygian
    if string.find(",maj7#11,maj#11,", ","..chord..",", 1, true)          then notew=2  notee=4  noter=6  notet=7  notez=9  noteu=11  end -- Lydian
    if string.find(",7,dom,9,13,", ","..chord..",", 1, true)              then notew=2  notee=4  noter=5  notet=7  notez=9  noteu=10  end -- Mixolydian
    if string.find(",m,min,", ","..chord..",", 1, true)                   then notew=2  notee=3  noter=5  notet=7  notez=8  noteu=10  end -- Aeolian
    if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true)           then notew=1  notee=3  noter=5  notet=6  notez=8  noteu=10  end -- Locrian
  
  

        
end

function deselect_items()
 
  get_chord_notes(region_num)
  
  un_item = reaper.GetSelectedMediaItem( 0, 0 )
  
  item_number = reaper.GetMediaItemInfo_Value( un_item, "IP_ITEMNUMBER" )
  
  for d = item_number, item_number+reg_item_count do-- -1 do
    
    un_item = reaper.GetSelectedMediaItem( 0, 0 )
    reaper.SetMediaItemSelected( un_item, 0 )
    reaper.UpdateItemInProject(un_item)
    if region_num == num_regions then goto break_loop end
    
    last_item_reg = reaper.GetSelectedMediaItem( 0, 0 )
    
    if not last_item_reg then break end
    
    last_item_pos = reaper.GetMediaItemInfo_Value( last_item_reg, "D_POSITION")
   
    if last_item_pos >= region_end then break end
    
    
    
  end

  
  
  main()
  
::break_loop::  
end  

--MAIN---------------------------------------------------------------
function main()
     ctrack = getTrackByName("chordtrack")
   
    num_regions = reaper.CountTrackMediaItems(ctrack)
   
   for r = 0, num_regions -1 do -- regions loop start 
                   chord_item = reaper.GetTrackMediaItem(ctrack, r )
                          pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
                       length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
                       rgnend = pos+length      
   
    
  --    retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, r )
    --  akkord = get_chord_notes(num_regions)

    items = 0
    items = reaper.CountSelectedMediaItems(0)
    
    if items == 0 then goto finish end

    count_items = 1
    
    first_item = reaper.GetSelectedMediaItem( 0, 0 )
    
    first_item_pos = reaper.GetMediaItemInfo_Value( first_item, "D_POSITION")+0.001
  
    last_item = reaper.GetSelectedMediaItem( 0, items -1 )
    
    last_item_pos = reaper.GetMediaItemInfo_Value( last_item, "D_POSITION")+0.001    
    
     
  
 
    
    for rs = 0, num_regions -1 do -- regions start loop  
                       chord_item = reaper.GetTrackMediaItem(ctrack, rs )
                              pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
                           length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
                           rgnend = pos+length      
  

  
  region_num = rs
  

  
  if first_item_pos >= pos and first_item_pos < rgnend then break end
    end 
    
    for re = 0, num_regions -1 do -- regions end loop start 
    chord_item = reaper.GetTrackMediaItem(ctrack, re )
           pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
        length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
        rgnend = pos+length      
      
  

  
  last_region = re
--  Msg(re)
  if last_item_pos <= pos and last_item_pos >= rgnend then break end
    end    
 
 
 get_chord_notes(region_num)
  
  for i = 0, items -1 do -- region items loop start
  
    count_item =  reaper.GetSelectedMediaItem(0, i )
    take =  reaper.GetActiveTake( count_item )
     
     
    chord_item = reaper.GetTrackMediaItem(ctrack, region_num )
           pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
        length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
        rgnend = pos+length   
        

     
    last_reg_item = reaper.GetMediaItemInfo_Value( count_item, "D_POSITION")
     
    reg_item_count = i
    
    if last_reg_item >= rgnend then break end 
    
  end 
    
            noteq=0
            notei=12
            noteo=99
            notey=notez
            note1=noteq-1
            note2=notew-1
            note3=notee-1
            note5=noter+1
            note6=notet+1
            note7=notez+1
            note9=notei+1
            notea=noteq-12
            notes=notew-12
            noted=notee-12
            notef=noter-12
            noteg=notet-12
            noteh=notez-12
            notej=noteu-12
            notek=notei-12

  
         seq1=_G[seq1w]
         seq2=_G[seq2w]
         seq3=_G[seq3w]
         seq4=_G[seq4w]
         seq5=_G[seq5w]
         seq6=_G[seq6w]
         seq7=_G[seq7w]
         seq8=_G[seq8w]
         
         if seq1==nil then seq1=0 end
         if seq2==nil then seq2=12 end
         if seq3==nil then seq3=-12 end
         if seq4==nil then seq4=0 end
         if seq5==nil then seq5=12 end
         if seq6==nil then seq6=-12 end
         if seq7==nil then seq7=0 end
         if seq8==nil then seq8=12 end
         
  

   vel0 = 100
   vel1 = 126
     
    
    velo1=_G[velo1s]
    velo2=_G[velo2s]
    velo3=_G[velo3s]
    velo4=_G[velo4s] 
    velo5=_G[velo5s]
    velo6=_G[velo6s]
    velo7=_G[velo7s]
    velo8=_G[velo8s]
    
   if velo1==nil then velo1=65 end
   if velo2==nil then velo2=78 end
   if velo3==nil then velo3=100 end
   if velo4==nil then velo4=126 end
   if velo5==nil then velo5=44 end
   if velo6==nil then velo6=65 end
   if velo7==nil then velo7=77 end
   if velo8==nil then velo8=90 end
    
  ic = 0
      
  for i = 0, reg_item_count do -- set items loop start
  
      chord_item = reaper.GetTrackMediaItem(ctrack, region_num )
             pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )+0.001
          length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
          rgnend = pos+length 


      
  pitch = 0

      item0 =  reaper.GetSelectedMediaItem(0, ic )
      if not item0 then break end
      item_start = reaper.GetMediaItemInfo_Value( item0, "D_POSITION")+0.001
      if item_start > rgnend then break end  
      take0 = reaper.GetActiveTake(item0)
      source =  reaper.GetMediaItemTake_Source( take0)         
      _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
      if key == "C" or key == "c" or key == "Am" or key == "" then transpo = 0
      elseif key == "C#" or key == "A#m"then transpo = -1
      elseif key == "Db" or key == "Bbm"then transpo = -1
      elseif key == "D"  or key == "d"  or key == "Bm"then transpo = -2
      elseif key == "Eb" or key == "Cm"then transpo = -3
      elseif key == "E" or key == "e" or key == "C#m"then transpo = -4
      elseif key == "F" or key == "f" or key == "Dm"then transpo = -5 
      elseif key == "F#" or key == "D#m"then transpo = -6
      elseif key == "Gb" or key == "Ebm"then transpo = -6
      elseif key == "G" or key == "g" or key == "Em"then transpo = -7 
      elseif key == "G#" or key == "E#m"then transpo = -8 
      elseif key == "Ab" or key == "Fm"then transpo = -8 
      elseif key == "A" or key == "a" or key == "F#m"then transpo = -9
      elseif key == "Bb" or key == "Gm"then transpo = -10
      elseif key == "B" or key == "b" or key == "G#m"then transpo = -11
      elseif key == "Cb" or key == "Abm"then transpo = -11
    if not key then end
      end 
      if seq1==99 then 
      reaper.SetMediaItemInfo_Value(item0, "B_MUTE",1)
     else
           
      reaper.SetMediaItemTakeInfo_Value(take0, 'D_PITCH',seq1+note_root+transpo)
      reaper.MIDI_SetNote( take0,0, selectedIn, mutedIn, startppqposIn, endppqposIn, chanIn, pitchIn,velo1, noSortIn )
      end
     ic=ic+1
      reaper.UpdateItemInProject(item0)
      
      item1 = reaper.GetSelectedMediaItem(0, ic )
      if not item1 then break end
      item_start = reaper.GetMediaItemInfo_Value( item1, "D_POSITION")+0.001
      if item_start > rgnend then break end          
      take1 = reaper.GetActiveTake(item1)
      source =  reaper.GetMediaItemTake_Source( take1)         
      _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
      if key == "C" or key == "c" or key == "Am" or key == "" then transpo = 0
      elseif key == "C#" or key == "A#m"then transpo = -1
      elseif key == "Db" or key == "Bbm"then transpo = -1
      elseif key == "D"  or key == "d"  or key == "Bm"then transpo = -2
      elseif key == "Eb" or key == "Cm"then transpo = -3
      elseif key == "E" or key == "e" or key == "C#m"then transpo = -4
      elseif key == "F" or key == "f" or key == "Dm"then transpo = -5
      elseif key == "F#" or key == "D#m"then transpo = -6
      elseif key == "Gb" or key == "Ebm"then transpo = -6
      elseif key == "G" or key == "g" or key == "Em"then transpo = -7 
      elseif key == "G#" or key == "E#m"then transpo = -8
      elseif key == "Ab" or key == "Fm"then transpo = -8 
      elseif key == "A" or key == "a" or key == "F#m"then transpo = -9
      elseif key == "Bb" or key == "Gm"then transpo = -10
      elseif key == "B" or key == "b" or key == "G#m"then transpo = -11
      elseif key == "Cb" or key == "Abm"then transpo = -11
    if not key then end 
      end 
      if seq2==99 then 
            reaper.SetMediaItemInfo_Value(item1, "B_MUTE",1)
           else
      reaper.SetMediaItemTakeInfo_Value(take1, 'D_PITCH',seq2+note_root+transpo)
      reaper.MIDI_SetNote( take1,0, selectedIn, mutedIn, startppqposIn, endppqposIn, chanIn, pitchIn,velo2, noSortIn )
      end
      ic=ic+1
      reaper.UpdateItemInProject(item1)
      
      item2 =  reaper.GetSelectedMediaItem(0, ic )
      if not item2 then break end
      item_start = reaper.GetMediaItemInfo_Value( item2, "D_POSITION")+0.001
      if item_start > rgnend then break end
      take2 = reaper.GetActiveTake(item2)
      source =  reaper.GetMediaItemTake_Source( take2)         
      _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
      if key == "C" or key == "c" or key == "Am" or key == "" then transpo = 0
      elseif key == "C#" or key == "A#m"then transpo = -1
      elseif key == "Db" or key == "Bbm"then transpo = -1
      elseif key == "D"  or key == "d"  or key == "Bm"then transpo = -2
      elseif key == "Eb" or key == "Cm"then transpo = -3
      elseif key == "E" or key == "e" or key == "C#m"then transpo = -4
      elseif key == "F" or key == "f" or key == "Dm"then transpo = -5
      elseif key == "F#" or key == "D#m"then transpo = -6
      elseif key == "Gb" or key == "Ebm"then transpo = -6
      elseif key == "G" or key == "g" or key == "Em"then transpo = -7 
      elseif key == "G#" or key == "E#m"then transpo = -8
      elseif key == "Ab" or key == "Fm"then transpo = -8 
      elseif key == "A" or key == "a" or key == "F#m"then transpo = -9
      elseif key == "Bb" or key == "Gm"then transpo = -10
      elseif key == "B" or key == "b" or key == "G#m"then transpo = -11
      elseif key == "Cb" or key == "Abm"then transpo = -11
    if not key then end
      end
      if seq3==99 then 
            reaper.SetMediaItemInfo_Value(item2, "B_MUTE",1)
           else
   
      reaper.SetMediaItemTakeInfo_Value(take2, 'D_PITCH',seq3+note_root+transpo)
      reaper.MIDI_SetNote( take2,0, selectedIn, mutedIn, startppqposIn, endppqposIn, chanIn, pitchIn,velo3, noSortIn )
      end
      ic=ic+1
      reaper.UpdateItemInProject(item2)
      
      item3 = reaper.GetSelectedMediaItem(0, ic )
      if not item3 then break end
      item_start = reaper.GetMediaItemInfo_Value( item3, "D_POSITION")+0.001
      if item_start > rgnend then break end
      take3 = reaper.GetActiveTake(item3)
      source =  reaper.GetMediaItemTake_Source( take3)         
      _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
      if key == "C" or key == "c" or key == "Am" or key == "" then transpo = 0
      elseif key == "C#" or key == "A#m"then transpo = -1
      elseif key == "Db" or key == "Bbm"then transpo = -1
      elseif key == "D"  or key == "d"  or key == "Bm"then transpo = -2
      elseif key == "Eb" or key == "Cm"then transpo = -3
      elseif key == "E" or key == "e" or key == "C#m"then transpo = -4
      elseif key == "F" or key == "f" or key == "Dm"then transpo = -5
      elseif key == "F#" or key == "D#m"then transpo = -6
      elseif key == "Gb" or key == "Ebm"then transpo = -6 
      elseif key == "G" or key == "g" or key == "Em"then transpo = -7 
      elseif key == "G#" or key == "E#m"then transpo = -8
      elseif key == "Ab" or key == "Fm"then transpo = -8 
      elseif key == "A" or key == "a" or key == "F#m"then transpo = -9
      elseif key == "Bb" or key == "Gm"then transpo = -10
      elseif key == "B" or key == "b" or key == "G#m"then transpo = -11
      elseif key == "Cb" or key == "Abm"then transpo = -11
    if not key then end
      end 
      if seq4==99 then 
            reaper.SetMediaItemInfo_Value(item3, "B_MUTE",1)
           else
      reaper.SetMediaItemTakeInfo_Value(take3, 'D_PITCH',seq4+note_root+transpo)
      reaper.MIDI_SetNote( take3,0, selectedIn, mutedIn, startppqposIn, endppqposIn, chanIn, pitchIn,velo4, noSortIn )
      end
      ic=ic+1
      reaper.UpdateItemInProject(item3)
      
      item4 =  reaper.GetSelectedMediaItem(0, ic )
      if not item4 then break end
      item_start = reaper.GetMediaItemInfo_Value( item4, "D_POSITION")+0.001
      if item_start > rgnend then break end
      take4 = reaper.GetActiveTake(item4)
      source =  reaper.GetMediaItemTake_Source( take4)         
      _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
      if key == "C" or key == "c" or key == "Am" or key == "" then transpo = 0
      elseif key == "C#" or key == "A#m"then transpo = -1
      elseif key == "Db" or key == "Bbm"then transpo = -1
      elseif key == "D"  or key == "d"  or key == "Bm"then transpo = -2
      elseif key == "Eb" or key == "Cm"then transpo = -3
      elseif key == "E" or key == "e" or key == "C#m"then transpo = -4
      elseif key == "F" or key == "f" or key == "Dm"then transpo = -5
      elseif key == "F#" or key == "D#m"then transpo = -6
      elseif key == "Gb" or key == "Ebm"then transpo = -6
      elseif key == "G" or key == "g" or key == "Em"then transpo = -7 
      elseif key == "G#" or key == "E#m"then transpo = -8
      elseif key == "Ab" or key == "Fm"then transpo = -8 
      elseif key == "A" or key == "a" or key == "F#m"then transpo = -9
      elseif key == "Bb" or key == "Gm"then transpo = -10
      elseif key == "B" or key == "b" or key == "G#m"then transpo = -11
      elseif key == "Cb" or key == "Abm"then transpo = -11
    if not key then end
      end 
      if seq5==99 then 
            reaper.SetMediaItemInfo_Value(item4, "B_MUTE",1)
           else
      reaper.SetMediaItemTakeInfo_Value(take4, 'D_PITCH',seq5+note_root+transpo)
      reaper.MIDI_SetNote( take4,0, selectedIn, mutedIn, startppqposIn, endppqposIn, chanIn, pitchIn,velo5, noSortIn )
      end
      ic=ic+1
      reaper.UpdateItemInProject(item4)
      
      item5 = reaper.GetSelectedMediaItem(0, ic )
      if not item5 then break end
      item_start = reaper.GetMediaItemInfo_Value( item5, "D_POSITION")+0.001
      if item_start > rgnend then break end
      take5 = reaper.GetActiveTake(item5)
      source =  reaper.GetMediaItemTake_Source( take5)         
      _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
      if key == "C" or key == "c" or key == "Am" or key == "" then transpo = 0
      elseif key == "C#" or key == "A#m"then transpo = -1
      elseif key == "Db" or key == "Bbm"then transpo = -1
      elseif key == "D"  or key == "d"  or key == "Bm"then transpo = -2
      elseif key == "Eb" or key == "Cm"then transpo = -3
      elseif key == "E" or key == "e" or key == "C#m"then transpo = -4
      elseif key == "F" or key == "f" or key == "Dm"then transpo = -5
      elseif key == "F#" or key == "D#m"then transpo = -6
      elseif key == "Gb" or key == "Ebm"then transpo = -6
      elseif key == "G" or key == "g" or key == "Em"then transpo = -7 
      elseif key == "G#" or key == "E#m"then transpo = -8
      elseif key == "Ab" or key == "Fm"then transpo = -8 
      elseif key == "A" or key == "a" or key == "F#m"then transpo = -9
      elseif key == "Bb" or key == "Gm"then transpo = -10
      elseif key == "B" or key == "b" or key == "G#m"then transpo = -11
      elseif key == "Cb" or key == "Abm"then transpo = -11
    if not key then end
      end
      if seq6==99 then 
            reaper.SetMediaItemInfo_Value(item5, "B_MUTE",1)
           else
      reaper.SetMediaItemTakeInfo_Value(take5, 'D_PITCH',seq6+note_root+transpo)
      reaper.MIDI_SetNote( take5,0, selectedIn, mutedIn, startppqposIn, endppqposIn, chanIn, pitchIn,velo6, noSortIn )
      end
      ic=ic+1
      reaper.UpdateItemInProject(item5)
      
      item6 =  reaper.GetSelectedMediaItem(0, ic )
      if not item6 then break end
      item_start = reaper.GetMediaItemInfo_Value( item6, "D_POSITION")+0.001
      if item_start > rgnend then break end
      take6 = reaper.GetActiveTake(item6)
      source =  reaper.GetMediaItemTake_Source( take6)         
      _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
      if key == "C" or key == "c" or key == "Am" or key == "" then transpo = 0
      elseif key == "C#" or key == "A#m"then transpo = -1
      elseif key == "Db" or key == "Bbm"then transpo = -1
      elseif key == "D"  or key == "d"  or key == "Bm"then transpo = -2
      elseif key == "Eb" or key == "Cm"then transpo = -3
      elseif key == "E" or key == "e" or key == "C#m"then transpo = -4
      elseif key == "F" or key == "f" or key == "Dm"then transpo = -5
      elseif key == "F#" or key == "D#m"then transpo = -6
      elseif key == "Gb" or key == "Ebm"then transpo = -6
      elseif key == "G" or key == "g" or key == "Em"then transpo = -7 
      elseif key == "G#" or key == "E#m"then transpo = -8
      elseif key == "Ab" or key == "Fm"then transpo = -8 
      elseif key == "A" or key == "a" or key == "F#m"then transpo = -9
      elseif key == "Bb" or key == "Gm"then transpo = -10
      elseif key == "B" or key == "b" or key == "G#m"then transpo = -11
      elseif key == "Cb" or key == "Abm"then transpo = -11 
    if not key then end
      end
      if seq7==99 then 
            reaper.SetMediaItemInfo_Value(item6, "B_MUTE",1)
           else
      reaper.SetMediaItemTakeInfo_Value(take6, 'D_PITCH',seq7+note_root+transpo)
      reaper.MIDI_SetNote( take6,0, selectedIn, mutedIn, startppqposIn, endppqposIn, chanIn, pitchIn,velo7, noSortIn )
      end
      ic=ic+1
      reaper.UpdateItemInProject(item6)
    
      item7 =  reaper.GetSelectedMediaItem(0, ic )
      if not item7 then break end
      item_start = reaper.GetMediaItemInfo_Value( item7, "D_POSITION")+0.001
      if item_start > rgnend then break end
      take7 = reaper.GetActiveTake(item7)
      source =  reaper.GetMediaItemTake_Source( take7)         
      _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
      if key == "C" or key == "c" or key == "Am" or key == "" then transpo = 0
      elseif key == "C#" or key == "A#m"then transpo = -1
      elseif key == "Db" or key == "Bbm"then transpo = -1
      elseif key == "D"  or key == "d"  or key == "Bm"then transpo = -2
      elseif key == "Eb" or key == "Cm"then transpo = -3
      elseif key == "E" or key == "e" or key == "C#m"then transpo = -4
      elseif key == "F" or key == "f" or key == "Dm"then transpo = -5
      elseif key == "F#" or key == "D#m"then transpo = -6
      elseif key == "Gb" or key == "Ebm"then transpo = -6
      elseif key == "G" or key == "g" or key == "Em"then transpo = -7 
      elseif key == "G#" or key == "E#m"then transpo = -8 
      elseif key == "Ab" or key == "Fm"then transpo = -8 
      elseif key == "A" or key == "a" or key == "F#m"then transpo = -9
      elseif key == "Bb" or key == "Gm"then transpo = -10
      elseif key == "B" or key == "b" or key == "G#m"then transpo = -11
      elseif key == "Cb" or key == "Abm"then transpo = -11 
    if not key then end
      end
      if seq8==99 then 
            reaper.SetMediaItemInfo_Value(item7, "B_MUTE",1)
           else
      reaper.SetMediaItemTakeInfo_Value(take7, 'D_PITCH',seq8+note_root+transpo)
      reaper.MIDI_SetNote( take7,0, selectedIn, mutedIn, startppqposIn, endppqposIn, chanIn, pitchIn,velo8, noSortIn )
      end
      ic=ic+1
      reaper.UpdateItemInProject(item7)      
      
  
  end -- items loop end
end     
  
    deselect_items()
    
::finish::  
end  

item_stop = 1
count_items = 0
  
main() 


end
--===========================================================================================================================
--============================================ CHORD_BUILDER ==================================================================
--============================================================================================================================
--Thanks MusoBob


--function Msg(variable)
--  reaper.ShowConsoleMsg(tostring(variable).."\n") 
  
--end

function chord_builder() 
-- cliffon track by name
function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end


function pitch_compensation(current_item) -- compensate audi items with different source pitches -- metadata key must set

          take = reaper.GetActiveTake(current_item)
        source =  reaper.GetMediaItemTake_Source( take )
        _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
        
               if key == "C" or key == "c" or key == "Am" or key == "" then transpo = 0
           elseif key == "C#" or key == "A#m"then transpo = -1
           elseif key == "Db" or key == "Bbm"then transpo = -1
           elseif key == "D"  or key == "d"  or key == "Bm"then transpo = -2
           elseif key == "Eb" or key == "Cm"then transpo = -3
           elseif key == "E" or key == "e" or key == "C#m"then transpo = -4
           elseif key == "F" or key == "f" or key == "Dm"then transpo = -5
           elseif key == "F#" or key == "D#m"then transpo = -6
           elseif key == "Gb" or key == "Ebm"then transpo = -6
           elseif key == "G" or key == "g" or key == "Em"then transpo = -7 
           elseif key == "G#" or key == "E#m"then transpo = -8
           elseif key == "Ab" or key == "Fm"then transpo = -8 
           elseif key == "A" or key == "a" or key == "F#m"then transpo = -9
           elseif key == "Bb" or key == "Gm"then transpo = -10
           elseif key == "B" or key == "b" or key == "G#m"then transpo = -11
           elseif key == "Cb" or key == "Abm"then transpo = -11
           if not key then end
           end         
end

function get_chord_notes(r) 

            item0 =  reaper.GetTrackMediaItem(ctrack,r )
    _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
    
  if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
   if string.find(item_notes, "/") then
      root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
   else
      root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
   end
     
     if not chord or #chord == 0 then chord = "Maj" end
     if not slash then slash = "" end

  note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D"  then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E"  then note1 = 4
  elseif root == "F"  then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G"  then note1 = -5
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A"  then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B"  then note1 = -1
  if not root then end
  end
  
  slashnote = 255
  -- 48 = C2

  if slash == "/C" then slashnote = -12
  elseif slash == "/C#" then slashnote = -11
  elseif slash == "/Db" then slashnote = -11
  elseif slash == "/D" then slashnote = -10
  elseif slash == "/D#" then slashnote = -9
  elseif slash == "/Eb" then slashnote = -9
  elseif slash == "/E" then slashnote = -8
  elseif slash == "/F" then slashnote = -7
  elseif slash == "/F#" then slashnote = -6
  elseif slash == "/Gb" then slashnote = -6
  elseif slash == "/G" then slashnote = -5
  elseif slash == "/G#" then slashnote = -4
  elseif slash == "/Ab" then slashnote = -4
  elseif slash == "/A" then slashnote = -3
  elseif slash == "/A#" then slashnote = -2
  elseif slash == "/Bb" then slashnote = -2
  elseif slash == "/B" then slashnote = -1
  if not slash then slashnote = 255 end
  end

  note2 = 255
  note3 = 255
  note4 = 255
  note5 = 255
  note6 = 255
  note7 = 255

  if string.find(",Maj,maj7,", ","..chord..",", 1, true) then note2=4  note3=7 note4=12 end      
  if string.find(",m,min,-,", ","..chord..",", 1, true) then note2=3  note3=7 note4=12 end      
  if string.find(",dim,m-5,mb5,m(b5),0,", ","..chord..",", 1, true) then note2=3  note3=6 note4=12 end   
  if string.find(",aug,+,+5,(#5),", ","..chord..",", 1, true) then note2=4  note3=8 end   
  if string.find(",-5,(b5),", ","..chord..",", 1, true) then note2=4  note3=6 end   
  if string.find(",sus2,", ","..chord..",", 1, true) then note2=2  note3=7 end   
  if string.find(",sus4,sus,(sus4),", ","..chord..",", 1, true) then note2=5  note3=7 end   
  if string.find(",5,", ","..chord..",", 1, true) then note2=7 note3=12 end   
  if string.find(",5add7,5/7,", ","..chord..",", 1, true) then note2=7  note3=10 note4=10 end   
  if string.find(",add2,(add2),", ","..chord..",", 1, true) then note2=2  note3=4  note4=7 end   
  if string.find(",add4,(add4),", ","..chord..",", 1, true) then note2=4  note3=5  note4=7 end   
  if string.find(",madd4,m(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7 end   
  if string.find(",11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17 end  
  if string.find(",11sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17 end  
  if string.find(",m11,min11,-11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17 end  
  if string.find(",Maj11,maj11,M11,Maj7(add11),M7(add11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=17 end     
  if string.find(",mMaj11,minmaj11,mM11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17 end  
  if string.find(",aug11,9+11,9aug11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
  if string.find(",augm11, m9#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18 end  
  if string.find(",11b5,11-5,11(b5),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17 end  
  if string.find(",11#5,11+5,11(#5),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17 end  
  if string.find(",11b9,11-9,11(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17 end  
  if string.find(",11#9,11+9,11(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17 end  
  if string.find(",11b5b9,11-5-9,11(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17 end  
  if string.find(",11#5b9,11+5-9,11(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17 end  
  if string.find(",11b5#9,11-5+9,11(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17 end  
  if string.find(",11#5#9,11+5+9,11(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17 end  
  if string.find(",m11b5,m11-5,m11(b5),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17 end  
  if string.find(",m11#5,m11+5,m11(#5),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17 end  
  if string.find(",m11b9,m11-9,m11(b9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17 end  
  if string.find(",m11#9,m11+9,m11(#9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17 end  
  if string.find(",m11b5b9,m11-5-9,m11(b5b9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17 end
  if string.find(",m11#5b9,m11+5-9,m11(#5b9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17 end
  if string.find(",m11b5#9,m11-5+9,m11(b5#9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17 end
  if string.find(",m11#5#9,m11+5+9,m11(#5#9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17 end
  if string.find(",Maj11b5,maj11b5,maj11-5,maj11(b5),", ","..chord..",", 1, true)    then note2=4  note3=6  note4=11  note5=14  note6=17 end
  if string.find(",Maj11#5,maj11#5,maj11+5,maj11(#5),", ","..chord..",", 1, true)    then note2=4  note3=8  note4=11  note5=14  note6=17 end
  if string.find(",Maj11b9,maj11b9,maj11-9,maj11(b9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13  note6=17 end
  if string.find(",Maj11#9,maj11#9,maj11+9,maj11(#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15  note6=17 end
  if string.find(",Maj11b5b9,maj11b5b9,maj11-5-9,maj11(b5b9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=13  note6=17 end
  if string.find(",Maj11#5b9,maj11#5b9,maj11+5-9,maj11(#5b9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=13  note6=17 end
  if string.find(",Maj11b5#9,maj11b5#9,maj11-5+9,maj11(b5#9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=15  note6=17 end
  if string.find(",Maj11#5#9,maj11#5#9,maj11+5+9,maj11(#5#9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=15  note6=17 end
  if string.find(",13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",m13,min13,-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",Maj13,maj13,M13,Maj7(add13),M7(add13),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",mMaj13,minmaj13,mM13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",13b5,13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",13#5,13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",13b9,13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13#9,13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
  if string.find(",13b5b9,13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13#5b9,13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13b5#9,13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13#5#9,13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13b9#11,13-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18  note7=21 end  
  if string.find(",m13b5,m13-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",m13#5,m13+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",m13b9,m13-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",m13#9,m13+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",m13b5b9,m13-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",m13#5b9,m13+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",m13b5#9,m13-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",m13#5#9,m13+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13b5,maj13b5,maj13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",Maj13#5,maj13#5,maj13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",Maj13b9,maj13b9,maj13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=13  note6=17  note7=21 end  
  if string.find(",Maj13#9,maj13#9,maj13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13b5b9,maj13b5b9,maj13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13  note6=17  note7=21 end  
  if string.find(",Maj13#5b9,maj13#5b9,maj13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13  note6=17  note7=21 end  
  if string.find(",Maj13b5#9,maj13b5#9,maj13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13#5#9,maj13#5#9,maj13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13#11,maj13#11,maj13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18  note7=21 end  
  if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",m13#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",13sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",6,M6,Maj6,maj6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9 end   
  if string.find(",m6,min6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9 end   
  if string.find(",6add4,6/4,6(add4),Maj6(add4),M6(add4),", ","..chord..",", 1, true)    then note2=4  note3=5  note4=7  note5=9 end   
  if string.find(",m6add4,m6/4,m6(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=9 end   
  if string.find(",69,6add9,6/9,6(add9),Maj6(add9),M6(add9),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=14 end  
  if string.find(",m6add9,m6/9,m6(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
  if string.find(",6sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=9 end   
  if string.find(",6sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=9 end   
  if string.find(",6add11,6/11,6(add11),Maj6(add11),M6(add11),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=17 end  
  if string.find(",m6add11,m6/11,m6(add11),m6(add11),", ","..chord..",", 1, true)    then note2=3  note3=7  note4=9  note5=17 end  
  if string.find(",7,dom,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=12 note6=16 note7=19 end   
  if string.find(",7add2,", ","..chord..",", 1, true) then note2=2  note3=4  note4=7  note5=10 end  
  if string.find(",7add4,", ","..chord..",", 1, true) then note2=4  note3=5  note4=7  note5=10 end  
  if string.find(",m7,min7,-7,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10 note5=12 note6=15 note7=19 end  
  if string.find(",m7add4,", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=10 end  
  if string.find(",Maj7,maj7,Maj7,M7,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11 end   
  if string.find(",dim7,07,", ","..chord..",", 1, true) then note2=3  note3=6  note4=9 end   
  if string.find(",mMaj7,minmaj7,mmaj7,min/maj7,mM7,m(addM7),m(+7),-(M7),m(maj7),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11 end    
  if string.find(",7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=10 end   
  if string.find(",7sus4,7sus,7sus11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10 end   
  if string.find(",Maj7sus2,maj7sus2,M7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=11 end    
  if string.find(",Maj7sus4,maj7sus4,M7sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11 end    
  if string.find(",aug7,+7,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
  if string.find(",7b5,7-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 end   
  if string.find(",7#5,7+5,7+,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
  if string.find(",m7b5,m7-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10 end   
  if string.find(",m7#5,m7+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10 end   
  if string.find(",Maj7b5,maj7b5,maj7-5,M7b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11 end   
  if string.find(",Maj7#5,maj7#5,maj7+5,M7+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11 end   
  if string.find(",7b9,7-9,7(addb9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13 end  
  if string.find(",7#9,7+9,7(add#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
  if string.find(",m7b9, m7-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13 end  
  if string.find(",m7#9, m7+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15 end  
  if string.find(",Maj7b9,maj7b9,maj7-9,maj7(addb9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13 end 
  if string.find(",Maj7#9,maj7#9,maj7+9,maj7(add#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15 end 
  if string.find(",7b9b13,7-9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=20 end  
  if string.find(",m7b9b13, m7-9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=20 end
  if string.find(",7b13,7-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
  if string.find(",m7b13,m7-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=20 end  
  if string.find(",7#9b13,7+9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=20 end  
  if string.find(",m7#9b13,m7+9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=20 end  
  if string.find(",7b5b9,7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13 end  
  if string.find(",7b5#9,7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15 end  
  if string.find(",7#5b9,7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13 end  
  if string.find(",7#5#9,7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15 end  
  if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18 end  
  if string.find(",7add6,7/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10 end  
  if string.find(",7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=17 end  
  if string.find(",7add13,7/13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=21 end  
  if string.find(",m7add11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=17 end  
  if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13 end  
  if string.find(",m7b5#9,m7-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15 end  
  if string.find(",m7#5b9,m7+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13 end  
  if string.find(",m7#5#9,m7+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15 end  
  if string.find(",m7#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=18 end  
  if string.find(",Maj7b5b9,maj7b5b9,maj7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13 end 
  if string.find(",Maj7b5#9,maj7b5#9,maj7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15 end 
  if string.find(",Maj7#5b9,maj7#5b9,maj7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13 end 
  if string.find(",Maj7#5#9,maj7#5#9,maj7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15 end 
  if string.find(",Maj7add11,maj7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=17 end  
  if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=18 end  
  if string.find(",9,7(add9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=16  note7=19 end
  if string.find(",m9,min9,-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14 end  
  if string.find(",Maj9,maj9,M9,Maj7(add9),M7(add9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=14 end 
  if string.find(",Maj9sus4,maj9sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11  note5=14 end  
  if string.find(",mMaj9,minmaj9,mmaj9,min/maj9,mM9,m(addM9),m(+9),-(M9),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11  note5=14 end 
  if string.find(",9sus4,9sus,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 end  
  if string.find(",aug9,+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
  if string.find(",9add6,9/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10  note6=14 end  
  if string.find(",m9add6,m9/6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
  if string.find(",9b5,9-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14 end  
  if string.find(",9#5,9+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14 end  
  if string.find(",m9b5,m9-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14 end  
  if string.find(",m9#5,m9+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14 end  
  if string.find(",Maj9b5,maj9b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14 end  
  if string.find(",Maj9#5,maj9#5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14 end  
  if string.find(",Maj9#11,maj9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18 end  
  if string.find(",b9#11,-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18 end  
  if string.find(",add9,2,", ","..chord..",", 1, true) then note2=4  note3=7  note4=14 end   
  if string.find(",madd9,m(add9),-(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=14 end   
  if string.find(",add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=17 end   
  if string.find(",madd11,m(add11),-(add11),", ","..chord..",", 1, true) then note2=3  note3=7  note4=17 end    
  if string.find(",(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=13 end   
  if string.find(",(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=15 end   
  if string.find(",(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=13 end   
  if string.find(",(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=13 end   
  if string.find(",(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=15 end   
  if string.find(",(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=15 end   
  if string.find(",m(b9), mb9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=13 end   
  if string.find(",m(#9), m#9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=15 end   
  if string.find(",m(b5b9), mb5b9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=13 end   
  if string.find(",m(#5b9), m#5b9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=13 end   
  if string.find(",m(b5#9), mb5#9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=15 end   
  if string.find(",m(#5#9), m#5#9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=15 end   
  if string.find(",m(#11), m#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=18 end   
  if string.find(",(#11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=18 end   
  if string.find(",m#5,", ","..chord..",", 1, true) then note2=3  note3=8 end   
  if string.find(",maug,augaddm3,augadd(m3),", ","..chord..",", 1, true) then note2=3  note3=7 note4=8 end  
  if string.find(",13#9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
  if string.find(",13#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",13susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",13susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=21 end  
  if string.find(",13susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=21 end  
  if string.find(",13sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=17  note6=21 end  
  if string.find(",13sus#5b9,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13sus#5b9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=18  note7=21 end  
  if string.find(",13sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
  if string.find(",13sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end
  if string.find(",13sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13sus#9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=21 end  
  if string.find(",13sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",7b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 note5=17  note6=20 end   
  if string.find(",7b5#9b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=20 end  
  if string.find(",7#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=18 end  
  if string.find(",7#5#9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=18 end  
  if string.find(",7#5b9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=18 end  
  if string.find(",7#9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18 note7=20 end  
  if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=18 end   
  if string.find(",7#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18  note6=20 end  
  if string.find(",7susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10 end   
  if string.find(",7susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13 end  
  if string.find(",7b5b9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=20 end  
  if string.find(",7susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=20 end  
  if string.find(",7susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15 end  
  if string.find(",7susb5#9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=20 end  
  if string.find(",7susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13 end  
  if string.find(",7susb9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=20 end  
  if string.find(",7susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18 end  
  if string.find(",7susb9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=20 end  
  if string.find(",7susb13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=20 end  
  if string.find(",7sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10 end   
  if string.find(",7sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end  
  if string.find(",7sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
  if string.find(",7sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15 end  
  if string.find(",7sus#9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=20 end  
  if string.find(",7sus#9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=20 end  
  if string.find(",7sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18 end  
  if string.find(",7sus#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18  note6=20 end  
  if string.find(",9b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=20 end  
  if string.find(",9b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
  if string.find(",9#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=18 end  
  if string.find(",9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
  if string.find(",9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=20 end  
  if string.find(",9susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  end  
  if string.find(",9susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14 note6=20 end  
  if string.find(",9sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 note6=18 end  
  if string.find(",9susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=15 end  
  if string.find(",9sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=14  note6=18 end   
  if string.find(",quartal,", ","..chord..",", 1, true) then note2=5  note3=10  note4=15 end
  if string.find(",sowhat,", ","..chord..",", 1, true) then note2=5  note3=10  note4=16 end
  
end


--MAIN---------------------------------------------------------------
function main()
       
  commandID2 = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
  reaper.Main_OnCommand(commandID2, 0) -- SWS: Select only track(s) with selected item(s) _SWS_SELTRKWITEM

       items = reaper.CountMediaItems(0)
  sel_tracks = reaper.CountSelectedTracks(0) 
 

  for x = 0, items -1 do -- items loop start
   
      media_item = reaper.GetMediaItem( 0, x )
   selected_item = reaper.IsMediaItemSelected(media_item) 

   if selected_item then
   
    current_item = reaper.GetMediaItem( 0, x )
      item_start = (reaper.GetMediaItemInfo_Value( current_item, "D_POSITION"))+0.001 
 
    --Does item start within region 
    ctrack = getTrackByName("chordtrack")
    
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
    reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
     
    else -- track == nil/no track with that name was
      num_chords = reaper.CountTrackMediaItems(ctrack)
      
    end
    for r = 0, num_chords -1 do -- regions loop start 
               
               chord_item = reaper.GetTrackMediaItem(ctrack, r )
                      pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
                   length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
                   rgnend = pos+length  
 
    if item_start  >= pos and item_start < rgnend then 

      get_chord_notes(r) -- get the chord notes for current region
      
      for i = 0, sel_tracks -1  do
         
      track = reaper.GetSelectedTrack(0,(sel_tracks-1)-i)
      
     
      if i == 0 and reaper.GetMediaItem_Track( current_item ) == track then
      
      pitch_compensation(current_item)
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note1+transpo) -- chord root  
      reaper.UpdateItemInProject(current_item)
      end
      
      if i == 1 and reaper.GetMediaItem_Track( current_item ) == track then
      
      pitch_compensation(current_item)
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note2+note1+transpo) -- chord root   
      reaper.UpdateItemInProject(current_item)
      end
      
      if i == 2 and reaper.GetMediaItem_Track( current_item ) == track then
      
      pitch_compensation(current_item)
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note3+note1+transpo) -- chord root   
      reaper.UpdateItemInProject(current_item)
      end
      
      if i == 3 and reaper.GetMediaItem_Track( current_item ) == track then
      
      pitch_compensation(current_item)
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note4+note1+transpo) -- chord root   
      reaper.UpdateItemInProject(current_item)
      end
      
      if i == 4 and reaper.GetMediaItem_Track( current_item ) == track then
      
      pitch_compensation(current_item)
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note5+note1+transpo) -- chord root   
      reaper.UpdateItemInProject(current_item)
      end          
      
      if i == 5 and reaper.GetMediaItem_Track( current_item ) == track then
      
      pitch_compensation(current_item)
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note6+note1+transpo) -- chord root   
      reaper.UpdateItemInProject(current_item)
      end          
      
      if i == 6 and reaper.GetMediaItem_Track( current_item ) == track then
      
      pitch_compensation(current_item)
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note7+note1+transpo) -- chord root   
      reaper.UpdateItemInProject(current_item)
       end          
     end
    end
   end -- items loop end
  end -- regions loop end
  end
  end  
  


  
main()  
  
reaper.Main_OnCommand(40297,0)   

::skip:: 
end  

--=======================================================================================================
--================================ scale_previous ===========================================================
--=======================================================================================================

-- Display a message in the console for debugging
--function Msg(variable)
--  reaper.ShowConsoleMsg(tostring(variable).."\n")
--end
function scale_previous()
-- cliffon track by name
function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end


ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return 
end
 

 
function get_chord_notes(ir)  
            item0 =  reaper.GetTrackMediaItem( ctrack,ir )
   _, region_name = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false)
   
  
    
  if string.match( region_name, "@.*") then next_region() end -- skip region marked @ ignore     
   if string.find(region_name, "/") then
      root, chord, slash = string.match(region_name, "(%w[#b]?)(.*)(/%a[#b]?)$")
   else
      root, chord = string.match(region_name, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
   end

     
     if not chord or #chord == 0 then chord = "Maj" end
     if not slash then slash = "" end
  

  note1 = 0 
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D" then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E" then note1 = 4
  elseif root == "F" then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G" then note1 = 7
  elseif root == "G#" then note1 = 8
  elseif root == "Ab" then note1 = 8
  elseif root == "A" then note1 = 9
  elseif root == "A#" then note1 = 10
  elseif root == "Bb" then note1 = 10
  elseif root == "B" then note1 = 11
  if not root then end
  end
  
  Ionian     = {-48,-46,-44,-43,-41,-39,-37,-36,-34,-32,-31,-29,-27,-25,-24,-22,-20,-19,-17,-15,-13,-12,-10,-8,-7,-5,-3,-1,0,2,4,5,7,9,11,12,14,16,17,19,21,23,24,26,28,29,31,33,35,36,38,40,41,43,45,47,48}
  Dorian     = {-48,-46,-45,-43,-41,-39,-38,-36,-34,-33,-31,-29,-27,-26,-24,-22,-21,-19,-17,-15,-14,-12,-10,-9,-7,-5,-3,-2,0,2,3,5,7,9,10,12,14,15,17,19,21,22,24,26,27,29,31,33,34,36,38,39,41,43,45,46,48}
  Phrygian   = {-48,-47,-45,-43,-41,-40,-38,-36,-35,-33,-31,-29,-28,-26,-24,-23,-21,-19,-17,-16,-14,-12,-11,-9,-7,-5,-4,-2,0,1,3,5,7,8,10,12,13,15,17,19,20,22,24,25,27,29,31,32,34,36,37,39,41,43,44,46,48}
  Lydian     = {-48,-46,-44,-42,-41,-39,-37,-36,-34,-32,-30,-29,-27,-25,-24,-22,-20,-18,-17,-15,-13,-12,-10,-8,-6,-5,-3,-1,0,2,4,6,7,9,11,12,14,16,18,19,21,23,24,26,28,30,31,33,35,36,38,40,42,43,45,47,48}
  Mixolydian = {-48,-46,-44,-43,-41,-39,-38,-36,-34,-32,-31,-29,-27,-26,-24,-22,-20,-19,-17,-15,-14,-12,-10,-8,-7,-5,-3,-2,0,2,4,5,7,9,10,12,14,16,17,19,21,22,24,26,28,29,31,33,34,36,38,40,41,43,45,46,48}
  Aeolian    = {-48,-46,-45,-43,-41,-40,-38,-36,-34,-33,-31,-29,-28,-26,-24,-22,-21,-19,-17,-16,-14,-12,-10,-9,-7,-5,-4,-2,0,2,3,5,7,8,10,12,14,15,17,19,20,22,24,26,27,29,31,32,34,36,38,39,41,43,44,46,48}
  Locrian    = {-48,-47,-45,-43,-42,-40,-38,-36,-35,-33,-31,-30,-28,-26,-24,-23,-21,-19,-18,-16,-14,-12,-11,-9,-7,-6,-4,-2,0,1,3,5,6,8,10,12,13,15,17,18,21,22,24,25,27,29,30,32,34,36,37,39,41,42,44,46,48}


  if string.find(",Maj7,maj7,Maj7,Maj,M,M7,", ","..chord..",", 1, true) then note2=2  note3=4  note4=5  note5=7  note6=9  note7=11 scale = Ionian end -- Ionian 
  if string.find(",m7,min7,-7,", ","..chord..",", 1, true)              then note2=2  note3=3  note4=5  note5=7  note6=9  note7=10 scale = Dorian end -- Dorian
  if string.find(",m7b9,", ","..chord..",", 1, true)                    then note2=1  note3=3  note4=5  note5=7  note6=8  note7=10 scale = Phrygian end -- Phrygian
  if string.find(",maj7#11,maj#11,", ","..chord..",", 1, true)          then note2=2  note3=4  note4=6  note5=7  note6=9  note7=11 scale = Lydian end -- Lydian
  if string.find(",7,dom,9,13,", ","..chord..",", 1, true)              then note2=2  note3=4  note4=5  note5=7  note6=9  note7=10 scale = Mixolydian end -- Mixolydian
  if string.find(",m,min,", ","..chord..",", 1, true)                   then note2=2  note3=3  note4=5  note5=7  note6=8  note7=10 scale = Aeolian end -- Aeolian
  if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true)           then note2=1  note3=3  note4=5  note5=6  note6=8  note7=10 scale = Locrian end -- Locrian


end


--MAIN---------------------------------------------------------------
function main()

          items = 0
          items = reaper.CountSelectedMediaItems(0)
         ctrack = getTrackByName("chordtrack")
    num_regions = reaper.CountTrackMediaItems( ctrack)
   
    if items == 0 then goto finish end
   
   
    for i = 0, items-1 do
    
  sel_item = reaper.GetSelectedMediaItem( 0, i )
  item_pos = reaper.GetMediaItemInfo_Value( sel_item, "D_POSITION")
  
  for ir = 0, num_regions -1 do -- regions end loop start 
  
     itemx = reaper.GetTrackMediaItem(ctrack, ir )
       pos = reaper.GetMediaItemInfo_Value( itemx, "D_POSITION" )
    length = reaper.GetMediaItemInfo_Value( itemx, "D_LENGTH" )
    rgnend = pos+length
   
   item_region = ir
   
    if item_pos >= pos and item_pos < rgnend then break end
  end
  
        take = reaper.GetActiveTake(sel_item)
      source = reaper.GetMediaItemTake_Source( take )
      _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
      
          if key == "C" or key == "Am" or key == "" then transpo = 0
         elseif key == "C#" or key == "A#m"then transpo = -1
         elseif key == "Db" or key == "Bbm"then transpo = -1
         elseif key == "D"  or key == "Bm"then transpo = -2
         elseif key == "Eb" or key == "Cm"then transpo = -3
          elseif key == "E" or key == "C#m"then transpo = -4
          elseif key == "F" or key == "Dm"then transpo = -5
         elseif key == "F#" or key == "D#m"then transpo = -6
         elseif key == "Gb" or key == "Ebm"then transpo = -6
          elseif key == "G" or key == "Em"then transpo = -7 
         elseif key == "G#" or key == "E#m"then transpo = -8
         elseif key == "Ab" or key == "Fm"then transpo = -8 
          elseif key == "A" or key == "F#m"then transpo = -9
          elseif key == "Bb" or key == "Gm"then transpo = -10
          elseif key == "B" or key == "G#m"then transpo = -11
          elseif key == "Cb" or key == "Abm"then transpo = -11
         if not key then end
         end
     
  
  get_chord_notes(item_region)
  
    match=0
       
    for s = 1, 57 do
    
      if not sel_item then break end
      sel_take = reaper.GetActiveTake(sel_item)
      item_pitch = reaper.GetMediaItemTakeInfo_Value(sel_take, 'D_PITCH')  

      if (item_pitch-transpo)-note1 == scale[s] then 
        match=1  
        
        new_pitch = scale[s-1]+note1+transpo 
        reaper.SetMediaItemTakeInfo_Value(sel_take, 'D_PITCH',new_pitch)
        reaper.UpdateItemInProject(sel_item)
        break
      end
      
    end
    
     if match==0 then
      new_pitch = item_pitch-1
    reaper.SetMediaItemTakeInfo_Value(sel_take, 'D_PITCH',new_pitch)
    reaper.UpdateItemInProject(sel_item)
      end
      
  end
  ::finish::  
  end


  
main() 

end
  
  






--=======================================================================================================
--================================ scale_next ===========================================================
--=======================================================================================================

-- Display a message in the console for debugging
--function Msg(variable)
--  reaper.ShowConsoleMsg(tostring(variable).."\n")
--end
function scale_next()
-- cliffon track by name
function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end


ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return 
end
 

 
function get_chord_notes(ir)  
            item0 =  reaper.GetTrackMediaItem( ctrack,ir )
   _, region_name = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false)
   
   
    
  if string.match( region_name, "@.*") then next_region() end -- skip region marked @ ignore     
   if string.find(region_name, "/") then
      root, chord, slash = string.match(region_name, "(%w[#b]?)(.*)(/%a[#b]?)$")
   else
      root, chord = string.match(region_name, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
   end

     
     if not chord or #chord == 0 then chord = "Maj" end
     if not slash then slash = "" end
  

  note1 = 0 
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D" then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E" then note1 = 4
  elseif root == "F" then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G" then note1 = 7
  elseif root == "G#" then note1 = 8
  elseif root == "Ab" then note1 = 8
  elseif root == "A" then note1 = 9
  elseif root == "A#" then note1 = 10
  elseif root == "Bb" then note1 = 10
  elseif root == "B" then note1 = 11
  if not root then end
  end
  
  Ionian     = {-48,-46,-44,-43,-41,-39,-37,-36,-34,-32,-31,-29,-27,-25,-24,-22,-20,-19,-17,-15,-13,-12,-10,-8,-7,-5,-3,-1,0,2,4,5,7,9,11,12,14,16,17,19,21,23,24,26,28,29,31,33,35,36,38,40,41,43,45,47,48}
  Dorian     = {-48,-46,-45,-43,-41,-39,-38,-36,-34,-33,-31,-29,-27,-26,-24,-22,-21,-19,-17,-15,-14,-12,-10,-9,-7,-5,-3,-2,0,2,3,5,7,9,10,12,14,15,17,19,21,22,24,26,27,29,31,33,34,36,38,39,41,43,45,46,48}
  Phrygian   = {-48,-47,-45,-43,-41,-40,-38,-36,-35,-33,-31,-29,-28,-26,-24,-23,-21,-19,-17,-16,-14,-12,-11,-9,-7,-5,-4,-2,0,1,3,5,7,8,10,12,13,15,17,19,20,22,24,25,27,29,31,32,34,36,37,39,41,43,44,46,48}
  Lydian     = {-48,-46,-44,-42,-41,-39,-37,-36,-34,-32,-30,-29,-27,-25,-24,-22,-20,-18,-17,-15,-13,-12,-10,-8,-6,-5,-3,-1,0,2,4,6,7,9,11,12,14,16,18,19,21,23,24,26,28,30,31,33,35,36,38,40,42,43,45,47,48}
  Mixolydian = {-48,-46,-44,-43,-41,-39,-38,-36,-34,-32,-31,-29,-27,-26,-24,-22,-20,-19,-17,-15,-14,-12,-10,-8,-7,-5,-3,-2,0,2,4,5,7,9,10,12,14,16,17,19,21,22,24,26,28,29,31,33,34,36,38,40,41,43,45,46,48}
  Aeolian    = {-48,-46,-45,-43,-41,-40,-38,-36,-34,-33,-31,-29,-28,-26,-24,-22,-21,-19,-17,-16,-14,-12,-10,-9,-7,-5,-4,-2,0,2,3,5,7,8,10,12,14,15,17,19,20,22,24,26,27,29,31,32,34,36,38,39,41,43,44,46,48}
  Locrian    = {-48,-47,-45,-43,-42,-40,-38,-36,-35,-33,-31,-30,-28,-26,-24,-23,-21,-19,-18,-16,-14,-12,-11,-9,-7,-6,-4,-2,0,1,3,5,6,8,10,12,13,15,17,18,21,22,24,25,27,29,30,32,34,36,37,39,41,42,44,46,48}


  if string.find(",Maj7,maj7,Maj7,Maj,M,M7,", ","..chord..",", 1, true) then note2=2  note3=4  note4=5  note5=7  note6=9  note7=11 scale = Ionian end -- Ionian 
  if string.find(",m7,min7,-7,", ","..chord..",", 1, true)              then note2=2  note3=3  note4=5  note5=7  note6=9  note7=10 scale = Dorian end -- Dorian
  if string.find(",m7b9,", ","..chord..",", 1, true)                    then note2=1  note3=3  note4=5  note5=7  note6=8  note7=10 scale = Phrygian end -- Phrygian
  if string.find(",maj7#11,maj#11,", ","..chord..",", 1, true)          then note2=2  note3=4  note4=6  note5=7  note6=9  note7=11 scale = Lydian end -- Lydian
  if string.find(",7,dom,9,13,", ","..chord..",", 1, true)              then note2=2  note3=4  note4=5  note5=7  note6=9  note7=10 scale = Mixolydian end -- Mixolydian
  if string.find(",m,min,", ","..chord..",", 1, true)                   then note2=2  note3=3  note4=5  note5=7  note6=8  note7=10 scale = Aeolian end -- Aeolian
  if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true)           then note2=1  note3=3  note4=5  note5=6  note6=8  note7=10 scale = Locrian end -- Locrian


end


--MAIN---------------------------------------------------------------
function main()

          items = 0
          items = reaper.CountSelectedMediaItems(0)
         ctrack = getTrackByName("chordtrack")
    num_regions = reaper.CountTrackMediaItems( ctrack)
   
    if items == 0 then goto finish end
   
   
    for i = 0, items-1 do
    
  sel_item = reaper.GetSelectedMediaItem( 0, i )
  item_pos = reaper.GetMediaItemInfo_Value( sel_item, "D_POSITION")
  
  for ir = 0, num_regions -1 do -- regions end loop start 
  
     itemx = reaper.GetTrackMediaItem(ctrack, ir )
       pos = reaper.GetMediaItemInfo_Value( itemx, "D_POSITION" )
    length = reaper.GetMediaItemInfo_Value( itemx, "D_LENGTH" )
    rgnend = pos+length
   
   item_region = ir
   
    if item_pos >= pos and item_pos < rgnend then break end
  end
  
        take = reaper.GetActiveTake(sel_item)
      source = reaper.GetMediaItemTake_Source( take )
      _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
      
          if key == "C" or key == "Am" or key == "" then transpo = 0
         elseif key == "C#" or key == "A#m"then transpo = -1
         elseif key == "Db" or key == "Bbm"then transpo = -1
         elseif key == "D"  or key == "Bm"then transpo = -2
         elseif key == "Eb" or key == "Cm"then transpo = -3
          elseif key == "E" or key == "C#m"then transpo = -4
          elseif key == "F" or key == "Dm"then transpo = -5
         elseif key == "F#" or key == "D#m"then transpo = -6
         elseif key == "Gb" or key == "Ebm"then transpo = -6
          elseif key == "G" or key == "Em"then transpo = -7 
         elseif key == "G#" or key == "E#m"then transpo = -8
         elseif key == "Ab" or key == "Fm"then transpo = -8 
          elseif key == "A" or key == "F#m"then transpo = -9
          elseif key == "Bb" or key == "Gm"then transpo = -10
          elseif key == "B" or key == "G#m"then transpo = -11
          elseif key == "Cb" or key == "Abm"then transpo = -11
         if not key then end
         end
     
  
  get_chord_notes(item_region)
  
    match=0
       
    for s = 1, 57 do
    
      if not sel_item then break end
      sel_take = reaper.GetActiveTake(sel_item)
      item_pitch = reaper.GetMediaItemTakeInfo_Value(sel_take, 'D_PITCH')  

      if (item_pitch-transpo)-note1 == scale[s] then 
        match=1  
        
        new_pitch = scale[s+1]+note1+transpo 
        reaper.SetMediaItemTakeInfo_Value(sel_take, 'D_PITCH',new_pitch)
        reaper.UpdateItemInProject(sel_item)
        break
      end
      
    end
    
     if match==0 then
      new_pitch = item_pitch+1
    reaper.SetMediaItemTakeInfo_Value(sel_take, 'D_PITCH',new_pitch)
    reaper.UpdateItemInProject(sel_item)
      end
      
  end
  ::finish::  
  end


  
main() 

end
  





-----------------------------------------------------------------------------------------------------
--------------------------------------------chord_down--------------------------------------------------
-----------------------------------------------------------------------------------------------------
function chord_down_x()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

reaper.Undo_BeginBlock()

reaper.PreventUIRefresh(1)
-----------------------------------------------------------  key minus transpo ------------------------------------------------

ItemsSel = {} 

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  
  take = reaper.GetActiveTake(item)
  source =  reaper.GetMediaItemTake_Source( take )
    
    Idx = i + 1 -- 1-based table in Lua      
    ItemsSel[Idx] = {}
    ItemsSel[Idx].thisItem = item 
    ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
    ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH") 
    ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")  
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source ) 
 
 
    old_pitch = ItemsSel[Idx].pitch

     
_, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
           if key == "C" or key == "Am" or key == "" then transpo = 0
          elseif key == "C#" or key == "A#m"then transpo = -1
          elseif key == "Db" or key == "Bbm"then transpo = -1
          elseif key == "D"  or key == "Bm"then transpo = -2
          elseif key == "Eb" or key == "Cm"then transpo = -3
           elseif key == "E" or key == "C#m"then transpo = -4
           elseif key == "F" or key == "Dm"then transpo = -5
          elseif key == "F#" or key == "D#m"then transpo = -6
          elseif key == "Gb" or key == "Ebm"then transpo = -6
           elseif key == "G" or key == "Em"then transpo = -7 
          elseif key == "G#" or key == "E#m"then transpo = -8
          elseif key == "Ab" or key == "Fm"then transpo = -8 
           elseif key == "A" or key == "F#m"then transpo = -9
           elseif key == "Bb" or key == "Gm"then transpo = -10
           elseif key == "B" or key == "G#m"then transpo = -11
           elseif key == "Cb" or key == "Abm"then transpo = -11
          if not key then end
          end                
       _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
      
   

  reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", old_pitch - transpo )
  
 

end
-----------------------------------------------------------------------------------------------------------------------------
--sorts whatever array that is passed to it in descending order (highest to lowest)
function bubbleSort(A)
  local n = #A
  local swapped = false

  repeat
    swapped = false

    for i = 2, n do
  if A[i-1] > A[i] then
    A[i] , A[i-1] = A[i-1] , A[i]
    swapped = true
  end
    end
  until not swapped

  return A
end


--main code
groups = {}
counter = 0
prevTrack = nil
isFirstTrack = true

--loop through and organize items into a multidimensional array
for i = 0, reaper.CountSelectedMediaItems() - 1 do
  local thisItem = reaper.GetSelectedMediaItem(0, i)
  local thisTake = reaper.GetActiveTake(thisItem)

  if thisTake then
    local thisTrack = reaper.GetMediaItem_Track(thisItem)

    if thisTrack == prevTrack then
  if isFirstTrack then table.insert(groups, {takes = {}, pitches = {}}) end
  counter = counter + 1
    else
  if i == 0 then table.insert(groups, {takes = {}, pitches = {}}) else isFirstTrack = false end
  counter = 1
    end

    table.insert(groups[counter].takes, thisTake)
    table.insert(groups[counter].pitches, reaper.GetMediaItemTakeInfo_Value(thisTake, "D_PITCH"))

    prevTrack = thisTrack
  end
end


for i = 1, #groups do
  local tempPitches = groups[i].pitches

  pitchesNum = #tempPitches

  tempPitches = bubbleSort(tempPitches) --sorts all of the pitches so highest is first
  lowestPitch = tempPitches[pitchesNum] - 12 --sets the highest pitch as an octave higher than whatever the lowest pitch is

  --loops through all of the pitches to make sure the lowest pitch raised by an octave isn't already in the list of pitches
    --if it is, it will raise the next lowest pitch by an octave and check - repeating this step until it breaks out
  isEqual = false
  nextIndex = pitchesNum

  while true do
    for j = nextIndex-1, 1, -1 do
  if tempPitches[j] == lowestPitch then
    isEqual = true
    break
  end
    end

    if isEqual == true then
  nextIndex = nextIndex - 1
  lowestPitch = tempPitches[nextIndex] - 12 

  isEqual = false
    else
  break
    end

    if nextIndex < 1 then break end --check to break out of the while in case something goes wrong and everything is equal
  end

  tempPitches[pitchesNum] = lowestPitch --sets the lowest pitch to whatever the highest pitch became
  tempPitches = bubbleSort(tempPitches) --resorts all of the pitches so highest is first

  pitchesNum = pitchesNum + 1

  --go through and change the pitches in the current grouping
  local tempTakes = groups[i].takes
  for j = 1, #tempTakes do
    reaper.SetMediaItemTakeInfo_Value(tempTakes[j], "D_PITCH", tempPitches[pitchesNum - j])
  end
end
------------------------------------------------   key plus transpo  --------------------------------

ItemsSel = {} 

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  
  take = reaper.GetActiveTake(item)
  source =  reaper.GetMediaItemTake_Source( take )
    
    Idx = i + 1 -- 1-based table in Lua      
    ItemsSel[Idx] = {}
    ItemsSel[Idx].thisItem = item 
    ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
    ItemsSel[Idx].playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH") 
    ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")  
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source ) 
 
 
    old_pitch = ItemsSel[Idx].pitch
    old_playrate =  ItemsSel[Idx].playrate
    pos = ItemsSel[Idx].position
     
_, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
           if key == "C" or key == "Am" or key == "" then transpo = 0
          elseif key == "C#" or key == "A#m"then transpo = -1
          elseif key == "Db" or key == "Bbm"then transpo = -1
          elseif key == "D"  or key == "Bm"then transpo = -2
          elseif key == "Eb" or key == "Cm"then transpo = -3
           elseif key == "E" or key == "C#m"then transpo = -4
           elseif key == "F" or key == "Dm"then transpo = -5
          elseif key == "F#" or key == "D#m"then transpo = -6
          elseif key == "Gb" or key == "Ebm"then transpo = -6
           elseif key == "G" or key == "Em"then transpo = -7 
          elseif key == "G#" or key == "E#m"then transpo = -8
          elseif key == "Ab" or key == "Fm"then transpo = -8 
           elseif key == "A" or key == "F#m"then transpo = -9
           elseif key == "Bb" or key == "Gm"then transpo = -10
           elseif key == "B" or key == "G#m"then transpo = -11
           elseif key == "Cb" or key == "Abm"then transpo = -11
          if not key then end
          end                
       _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
       reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", old_pitch + transpo )
       
end                   
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

reaper.Undo_EndBlock("Swap Pitches Down", -1)
end
------------------------------------------------------------------------------------------------------
--------------------------------------chord_up-------------------------------------------------------
-----------------------------------------------------------------------------------------------------
function chord_up_x()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

reaper.Undo_BeginBlock()

reaper.PreventUIRefresh(1)
-----------------------------------------------------------  key minus transpo ------------------------------------------------

ItemsSel = {} 

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  
  
  
  take = reaper.GetActiveTake(item)
  source =  reaper.GetMediaItemTake_Source( take )
    
    Idx = i + 1 -- 1-based table in Lua      
    ItemsSel[Idx] = {}
    ItemsSel[Idx].thisItem = item 
    ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
    ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH") 
    ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")  
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source ) 
 
 
    old_pitch = ItemsSel[Idx].pitch

     
_, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
           if key == "C" or key == "Am" or key == "" then transpo = 0
          elseif key == "C#" or key == "A#m"then transpo = -1
          elseif key == "Db" or key == "Bbm"then transpo = -1
          elseif key == "D"  or key == "Bm"then transpo = -2
          elseif key == "Eb" or key == "Cm"then transpo = -3
           elseif key == "E" or key == "C#m"then transpo = -4
           elseif key == "F" or key == "Dm"then transpo = -5
          elseif key == "F#" or key == "D#m"then transpo = -6
          elseif key == "Gb" or key == "Ebm"then transpo = -6
           elseif key == "G" or key == "Em"then transpo = -7 
          elseif key == "G#" or key == "E#m"then transpo = -8
          elseif key == "Ab" or key == "Fm"then transpo = -8 
           elseif key == "A" or key == "F#m"then transpo = -9
           elseif key == "Bb" or key == "Gm"then transpo = -10
           elseif key == "B" or key == "G#m"then transpo = -11
           elseif key == "Cb" or key == "Abm"then transpo = -11
          if not key then end
          end                
       _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
      
   

  reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", old_pitch - transpo )
  
 

end
-----------------------------------------------------------------------------------------------------------------------------
--sorts whatever array that is passed to it in descending order (highest to lowest)
function bubbleSort(A)
  local n = #A
  local swapped = false

  repeat
    swapped = false

    for i = 2, n do
  if A[i-1] < A[i] then
    A[i-1] , A[i] = A[i] , A[i-1]
    swapped = true
  end
    end
  until not swapped

  return A
end


--main code
groups = {}
counter = 0
prevTrack = nil
isFirstTrack = true

--loop through and organize items into a multidimensional array
for i = 0, reaper.CountSelectedMediaItems() - 1 do
  local thisItem = reaper.GetSelectedMediaItem(0, i)
  local thisTake = reaper.GetActiveTake(thisItem)

  if thisTake then
    local thisTrack = reaper.GetMediaItem_Track(thisItem)

    if thisTrack == prevTrack then
  if isFirstTrack then table.insert(groups, {takes = {}, pitches = {}}) end
  counter = counter + 1
    else
  if i == 0 then table.insert(groups, {takes = {}, pitches = {}}) else isFirstTrack = false end
  counter = 1
    end

    table.insert(groups[counter].takes, thisTake)
    table.insert(groups[counter].pitches, reaper.GetMediaItemTakeInfo_Value(thisTake, "D_PITCH"))

    prevTrack = thisTrack
  end
end


for i = 1, #groups do
  local tempPitches = groups[i].pitches

  pitchesNum = #tempPitches

  tempPitches = bubbleSort(tempPitches) --sorts all of the pitches so highest is first
  highestPitch = tempPitches[pitchesNum] + 12 --sets the highest pitch as an octave higher than whatever the lowest pitch is

  --loops through all of the pitches to make sure the lowest pitch raised by an octave isn't already in the list of pitches
    --if it is, it will raise the next lowest pitch by an octave and check - repeating this step until it breaks out
  isEqual = false
  nextIndex = pitchesNum

  while true do
    for j = nextIndex-1, 1, -1 do
  if tempPitches[j] == highestPitch then
    isEqual = true
    break
  end
    end

    if isEqual == true then
  nextIndex = nextIndex - 1
  highestPitch = tempPitches[nextIndex] + 12

  isEqual = false
    else
  break
    end

    if nextIndex < 1 then break end --check to break out of the while in case something goes wrong and everything is equal
  end

  tempPitches[pitchesNum] = highestPitch --sets the lowest pitch to whatever the highest pitch became
  tempPitches = bubbleSort(tempPitches) --resorts all of the pitches so highest is first

  --go through and change the pitches in the current grouping
  local tempTakes = groups[i].takes
  for j = 1, #tempTakes do
    reaper.SetMediaItemTakeInfo_Value(tempTakes[j], "D_PITCH", tempPitches[j])
  end
end
------------------------------------------------   key plus transpo  --------------------------------

ItemsSel = {} 

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  
  take = reaper.GetActiveTake(item)
  source =  reaper.GetMediaItemTake_Source( take )
    
    Idx = i + 1 -- 1-based table in Lua      
    ItemsSel[Idx] = {}
    ItemsSel[Idx].thisItem = item 
    ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
    ItemsSel[Idx].playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH") 
    ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")  
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source ) 
 
 
    old_pitch = ItemsSel[Idx].pitch
    old_playrate =  ItemsSel[Idx].playrate
    pos = ItemsSel[Idx].position
     
_, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
           if key == "C" or key == "Am" or key == "" then transpo = 0
          elseif key == "C#" or key == "A#m"then transpo = -1
          elseif key == "Db" or key == "Bbm"then transpo = -1
          elseif key == "D"  or key == "Bm"then transpo = -2
          elseif key == "Eb" or key == "Cm"then transpo = -3
          elseif key == "E"  or key == "C#m"then transpo = -4
          elseif key == "F"  or key == "Dm"then transpo = -5
          elseif key == "F#" or key == "D#m"then transpo = -6
          elseif key == "Gb" or key == "Ebm"then transpo = -6
          elseif key == "G"  or key == "Em"then transpo = -7 
          elseif key == "G#" or key == "E#m"then transpo = -8
          elseif key == "Ab" or key == "Fm"then transpo = -8 
          elseif key == "A"  or key == "F#m"then transpo = -9
          elseif key == "Bb" or key == "Gm"then transpo = -10
          elseif key == "B"  or key == "G#m"then transpo = -11
          elseif key == "Cb" or key == "Abm"then transpo = -11
          if not key then end
          end                
       _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
       reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", old_pitch + transpo )
       
end                   
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

reaper.Undo_EndBlock("Swap Pitches Up", -1)


end
------------------------------------------------------------------------------------------------------
---------------------------------------Pitch invers----------------------------------------------------------
------------------------------------------------------------------------------------------------------
--diatonic_inversion_
--script by MusoBob and dragonetti
function pitch_invers_x()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

 
function get_chord_notes(chord_region)  

    retval, isrgn, region_pos, region_end, region_name, region_index, region_color = reaper.EnumProjectMarkers3( 0, chord_region)
     
  if string.match( region_name, "@.*") then next_region() end -- skip region marked @ ignore     
   if string.find(region_name, "/") then
      root, chord, slash = string.match(region_name, "(%w[#b]?)(.*)(/%a[#b]?)$")
   else
      root, chord = string.match(region_name, "(%w[#b]?)(.*)$") slashnote = 0 slash = "" 
   end

  
     if not chord or #chord == 0 then chord = "Maj" end
     if not slash then slash = "" end
  
   item =  reaper.GetSelectedMediaItem(0, 0 )
   take = reaper.GetActiveTake(item)
 source =  reaper.GetMediaItemTake_Source( take )
 _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key"
 
  if key == "C" or key == "Am" or key == "" then transpo = 0
  elseif key == "C#" or key == "A#m"then transpo = -1
  elseif key == "Db" or key == "Bbm"then transpo = -1
  elseif key == "D"  or key == "Bm"then transpo = -2
  elseif key == "Eb" or key == "Cm"then transpo = -3
  elseif key == "E" or key == "C#m"then transpo = -4
  elseif key == "F" or key == "Dm"then transpo = -5
  elseif key == "F#" or key == "D#m"then transpo = -6
  elseif key == "Gb" or key == "Ebm"then transpo = -6
  elseif key == "G" or key == "Em"then transpo = -7 
  elseif key == "G#" or key == "E#m"then transpo = -8
  elseif key == "Ab" or key == "Fm"then transpo = -8 
  elseif key == "A" or key == "F#m"then transpo = -9
  elseif key == "Bb" or key == "Gm"then transpo = -10
  elseif key == "B" or key == "G#m"then transpo = -11
  elseif key == "Cb" or key == "Abm"then transpo = -11
   if not key then end
   end
 
  note1 = 0 
  -- 60 = C3
  if root == "C" then note1 = 0 + transpo
  elseif root == "C#" then note1 = 1 + transpo
  elseif root == "Db" then note1 = 1 + transpo
  elseif root == "D" then note1 = 2 + transpo
  elseif root == "D#" then note1 = 3 + transpo
  elseif root == "Eb" then note1 = 3 + transpo
  elseif root == "E" then note1 = 4 + transpo
  elseif root == "F" then note1 = 5 + transpo
  elseif root == "F#" then note1 = 6 + transpo
  elseif root == "Gb" then note1 = 6 + transpo
  elseif root == "G" then note1 = 7 + transpo
  elseif root == "G#" then note1 = 8 + transpo
  elseif root == "Ab" then note1 = 8 + transpo
  elseif root == "A" then note1 = 9 + transpo
  elseif root == "A#" then note1 = 10 + transpo
  elseif root == "Bb" then note1 = 10 + transpo
  elseif root == "B" then note1 = 11 + transpo
  if not root then end
  end
  
  

  Ionian     = {-48,-46,-44,-43,-41,-39,-37,-36,-34,-32,-31,-29,-27,-25,-24,-22,-20,-19,-17,-15,-13,-12,-10,-8,-7,-5,-3,-1,0,2,4,5,7,9,11,12,14,16,17,19,21,23,24,26,28,29,31,33,35,36,38,40,41,43,45,47,48}
  Dorian     = {-48,-46,-45,-43,-41,-39,-38,-36,-34,-33,-31,-29,-27,-26,-24,-22,-21,-19,-17,-15,-14,-12,-10,-9,-7,-5,-3,-2,0,2,3,5,7,9,10,12,14,15,17,19,21,22,24,26,27,29,31,33,34,36,38,39,41,43,45,46,48}
  Phrygian   = {-48,-47,-45,-43,-41,-40,-38,-36,-35,-33,-31,-29,-28,-26,-24,-23,-21,-19,-17,-16,-14,-12,-11,-9,-7,-5,-4,-2,0,1,3,5,7,8,10,12,13,15,17,19,20,22,24,25,27,29,31,32,34,36,37,39,41,43,44,46,48}
  Lydian     = {-48,-46,-44,-42,-41,-39,-37,-36,-34,-32,-30,-29,-27,-25,-24,-22,-20,-18,-17,-15,-13,-12,-10,-8,-6,-5,-3,-1,0,2,4,6,7,9,11,12,14,16,18,19,21,23,24,26,28,30,31,33,35,36,38,40,42,43,45,47,48}
  Mixolydian = {-48,-46,-44,-43,-41,-39,-38,-36,-34,-32,-31,-29,-27,-26,-24,-22,-20,-19,-17,-15,-14,-12,-10,-8,-7,-5,-3,-2,0,2,4,5,7,9,10,12,14,16,17,19,21,22,24,26,28,29,31,33,34,36,38,40,41,43,45,46,48}
  Aeolian    = {-48,-46,-45,-43,-41,-40,-38,-36,-34,-33,-31,-29,-28,-26,-24,-22,-21,-19,-17,-16,-14,-12,-10,-9,-7,-5,-4,-2,0,2,3,5,7,8,10,12,14,15,17,19,20,22,24,26,27,29,31,32,34,36,38,39,41,43,44,46,48}
  Locrian    = {-48,-47,-45,-43,-42,-40,-38,-36,-35,-33,-31,-30,-28,-26,-24,-23,-21,-19,-18,-16,-14,-12,-11,-9,-7,-6,-4,-2,0,1,3,5,6,8,10,12,13,15,17,18,20,22,24,25,27,29,30,32,34,36,37,39,41,42,44,46,48}
  
  
  if string.find(",Maj7,maj7,Maj7,Maj,M,M7,", ","..chord..",", 1, true) then note2=2  note3=4  note4=5  note5=7  note6=9  note7=11 scale = Ionian     end -- Ionian  
  if string.find(",m7,min7,-7,", ","..chord..",", 1, true)              then note2=2  note3=3  note4=5  note5=7  note6=9  note7=10 scale = Dorian     end -- Dorian
  if string.find(",m7b9,", ","..chord..",", 1, true)                    then note2=1  note3=3  note4=5  note5=7  note6=8  note7=10 scale = Phrygian   end -- Phrygian 
  if string.find(",maj7#11,maj#11,", ","..chord..",", 1, true)          then note2=2  note3=4  note4=6  note5=7  note6=9  note7=11 scale = Lydian     end -- Lydian
  if string.find(",7,dom,9,13,", ","..chord..",", 1, true)              then note2=2  note3=4  note4=5  note5=7  note6=9  note7=10 scale = Mixolydian end -- Mixolydian
  if string.find(",m,min,", ","..chord..",", 1, true)                   then note2=2  note3=3  note4=5  note5=7  note6=8  note7=10 scale = Aeolian    end -- Aeolian
  if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true)           then note2=1  note3=3  note4=5  note5=6  note6=8  note7=10 scale = Locrian    end -- Locrian


end


--MAIN---------------------------------------------------------------
function main()

    pitch = {}

    items = 0
    items = reaper.CountSelectedMediaItems(0)
    retval, num_markers, num_regions = reaper.CountProjectMarkers(0)
    --Msg("items="..items)
    if items == 0 then goto finish end
    
    for i = 0, items -1 do
    
  sel_item = reaper.GetSelectedMediaItem( 0, i )
  
  item_pos = reaper.GetMediaItemInfo_Value( sel_item, "D_POSITION")
  
  for ir = 0, num_regions -1 do -- regions end loop start 
    
    retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, ir )
    
    item_region = ir
    
    if item_pos >= pos and item_pos < rgnend then break end
  end
  
  get_chord_notes(item_region)
  
    
  for s = 1, 57 do
  
    if not sel_item then break end
    sel_take = reaper.GetActiveTake(sel_item) 
    item_pitch = reaper.GetMediaItemTakeInfo_Value(sel_take, 'D_PITCH')          
     
    if item_pitch-note1 == scale[s] then 
      new_pitch = scale[#scale + 1 - s]+note1
   
      reaper.SetMediaItemTakeInfo_Value(sel_take, 'D_PITCH',new_pitch)
      reaper.UpdateItemInProject(sel_item)
       
   
      break 
    end
    
  end
  
    end      

::finish::  
end  


main() 

end
  

----------------------------------------------------------------------------------------------------
---------------------------------pitch_compressor------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--- over 12 pitch trans -12 ---
---script by dragonetti---

function pitch_comp_x()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

--- select items with grid length ---




 item_count = reaper.CountSelectedMediaItems(0)
    for i = item_count - 1, 0, -1 do
     --   for i=0, item_count - 1 do
     item = reaper.GetSelectedMediaItem( 0, i )
     take =  reaper.GetActiveTake( item )
    length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )

  pitch =  reaper.GetMediaItemTakeInfo_Value( take, "D_PITCH" )
  tempo = reaper.Master_GetTempo(0)   
  factor = 120 / tempo
   _,grid = reaper.GetSetProjectGrid(0, false)
  grid_length = (grid*2*factor)
  
  
    if pitch > 11 then
     reaper.SetMediaItemTakeInfo_Value( take, "D_PITCH", pitch -12)
     elseif pitch < -11 then
     reaper.SetMediaItemTakeInfo_Value( take, "D_PITCH", pitch +12)
  
end
end


reaper.UpdateArrange()
    
end
    
--=================================================================================================
--========================================= pitch_plus_7 ============================================
--=================================================================================================

function pitch_plus_7()
ItemsSel = {}

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  
  take = reaper.GetActiveTake(item)
  source =  reaper.GetMediaItemTake_Source( take )
   
  Idx = i + 1 -- 1-based table in Lua      
  ItemsSel[Idx] = {}  
  ItemsSel[Idx].thisItem = item 
  ItemsSel[Idx].pitch =  reaper.GetMediaItemTakeInfo_Value( take, "D_PITCH" )

  pitch =  ItemsSel[Idx].pitch  
 
  reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", pitch+7)

end 

reaper.UpdateTimeline()  
reaper.UpdateArrange()
end  

--=================================================================================================
--========================================= pitch_minus_7 ============================================
--=================================================================================================

function pitch_minus_7()
ItemsSel = {}

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  
  take = reaper.GetActiveTake(item)
  source =  reaper.GetMediaItemTake_Source( take )
   
  Idx = i + 1 -- 1-based table in Lua      
  ItemsSel[Idx] = {}  
  ItemsSel[Idx].thisItem = item 
  ItemsSel[Idx].pitch =  reaper.GetMediaItemTakeInfo_Value( take, "D_PITCH" )

  pitch =  ItemsSel[Idx].pitch  
 
  reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", pitch-7)

end 

reaper.UpdateTimeline()  
reaper.UpdateArrange()
end      
----------------------------------------------------------------------------------------------------
-------------------------------------pitch rand in scale---------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Display a message in the console for debugging
function pitch_rand_x()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
 
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end
 
function get_chord_notes(r)  

   item0 =  reaper.GetTrackMediaItem(ctrack,r )
      _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
      
    if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
     if string.find(item_notes, "/") then
        root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
     else
        root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
     end
       
       if not chord or #chord == 0 then chord = "Maj" end
       if not slash then slash = "" end
  

  note1 = 0 
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D" then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E" then note1 = 4
  elseif root == "F" then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G" then note1 = 7
  elseif root == "G#" then note1 = 8
  elseif root == "Ab" then note1 = 8
  elseif root == "A" then note1 = 9
  elseif root == "A#" then note1 = 10
  elseif root == "Bb" then note1 = 10
  elseif root == "B" then note1 = 11
  if not root then end
  end
  
  Ionian     = {-48,-46,-44,-43,-41,-39,-37,-36,-34,-32,-31,-29,-27,-25,-24,-22,-20,-19,-17,-15,-13,-12,-10,-8,-7,-5,-3,-1,0,2,4,5,7,9,11,12,14,16,17,19,21,23,24,26,28,29,31,33,35,36,38,40,41,43,45,47,48}
  Dorian     = {-48,-46,-45,-43,-41,-39,-38,-36,-34,-33,-31,-29,-27,-26,-24,-22,-21,-19,-17,-15,-14,-12,-10,-9,-7,-5,-3,-2,0,2,3,5,7,9,10,12,14,15,17,19,21,22,24,26,27,29,31,33,34,36,38,39,41,43,45,46,48}
  Phrygian   = {-48,-47,-45,-43,-41,-40,-38,-36,-35,-33,-31,-29,-28,-26,-24,-23,-21,-19,-17,-16,-14,-12,-11,-9,-7,-5,-4,-2,0,1,3,5,7,8,10,12,13,15,17,19,20,22,24,25,27,29,31,32,34,36,37,39,41,43,44,46,48}
  Lydian     = {-48,-46,-44,-42,-41,-39,-37,-36,-34,-32,-30,-29,-27,-25,-24,-22,-20,-18,-17,-15,-13,-12,-10,-8,-6,-5,-3,-1,0,2,4,6,7,9,11,12,14,16,18,19,21,23,24,26,28,30,31,33,35,36,38,40,42,43,45,47,48}
  Mixolydian = {-48,-46,-44,-43,-41,-39,-38,-36,-34,-32,-31,-29,-27,-26,-24,-22,-20,-19,-17,-15,-14,-12,-10,-8,-7,-5,-3,-2,0,2,4,5,7,9,10,12,14,16,17,19,21,22,24,26,28,29,31,33,34,36,38,40,41,43,45,46,48}
  Aeolian    = {-48,-46,-45,-43,-41,-40,-38,-36,-34,-33,-31,-29,-28,-26,-24,-22,-21,-19,-17,-16,-14,-12,-10,-9,-7,-5,-4,-2,0,2,3,5,7,8,10,12,14,15,17,19,20,22,24,26,27,29,31,32,34,36,38,39,41,43,44,46,48}
  Locrian    = {-48,-47,-45,-43,-42,-40,-38,-36,-35,-33,-31,-30,-28,-26,-24,-23,-21,-19,-18,-16,-14,-12,-11,-9,-7,-6,-4,-2,0,1,3,5,6,8,10,12,13,15,17,18,21,22,24,25,27,29,30,32,34,36,37,39,41,42,44,46,48}


  if string.find(",Maj7,maj7,Maj7,Maj,M,M7,", ","..chord..",", 1, true) then note2=2  note3=4  note4=5  note5=7  note6=9  note7=11 scale = Ionian end -- Ionian 
  if string.find(",m7,min7,-7,", ","..chord..",", 1, true)              then note2=2  note3=3  note4=5  note5=7  note6=9  note7=10 scale = Dorian end -- Dorian
  if string.find(",m7b9,", ","..chord..",", 1, true)                    then note2=1  note3=3  note4=5  note5=7  note6=8  note7=10 scale = Phrygian end -- Phrygian
  if string.find(",maj7#11,maj#11,", ","..chord..",", 1, true)          then note2=2  note3=4  note4=6  note5=7  note6=9  note7=11 scale = Lydian end -- Lydian
  if string.find(",7,dom,9,13,", ","..chord..",", 1, true)              then note2=2  note3=4  note4=5  note5=7  note6=9  note7=10 scale = Mixolydian end -- Mixolydian
  if string.find(",m,min,", ","..chord..",", 1, true)                   then note2=2  note3=3  note4=5  note5=7  note6=8  note7=10 scale = Aeolian end -- Aeolian
  if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true)           then note2=1  note3=3  note4=5  note5=6  note6=8  note7=10 scale = Locrian end -- Locrian


end


--MAIN---------------------------------------------------------------
function main()

    items = 0
    items = reaper.CountSelectedMediaItems(0)
    retval, num_markers, num_regions = reaper.CountProjectMarkers(0)
    --Msg("items="..items) 
 --   if items == 0 then goto finish end 
    
    for i = 0, items -1 do 
    
  sel_item = reaper.GetSelectedMediaItem( 0, i )
  
  item_pos = reaper.GetMediaItemInfo_Value( sel_item, "D_POSITION")+0.005
  
 ctrack = getTrackByName("chordtrack")
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
            reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
        else -- track == nil/no track with that name was
     
    num_chords = reaper.CountTrackMediaItems(ctrack)
 
    for r = 0, num_chords -1 do -- regions loop start    
    
           chord_item = reaper.GetTrackMediaItem(ctrack, r )
                  pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
               length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
               rgnend = pos+length  
  
    take = reaper.GetActiveTake(sel_item)
  source =  reaper.GetMediaItemTake_Source( take )
  _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
  
      if key == "C" or key == "Am" or key == "" then transpo = 0
     elseif key == "C#" or key == "A#m"then transpo = -1
     elseif key == "Db" or key == "Bbm"then transpo = -1
     elseif key == "D"  or key == "Bm"then transpo = -2
     elseif key == "Eb" or key == "Cm"then transpo = -3
      elseif key == "E" or key == "C#m"then transpo = -4
      elseif key == "F" or key == "Dm"then transpo = -5
     elseif key == "F#" or key == "D#m"then transpo = -6
     elseif key == "Gb" or key == "Ebm"then transpo = -6
      elseif key == "G" or key == "Em"then transpo = -7 
     elseif key == "G#" or key == "E#m"then transpo = -8
     elseif key == "Ab" or key == "Fm"then transpo = -8 
      elseif key == "A" or key == "F#m"then transpo = -9
      elseif key == "Bb" or key == "Gm"then transpo = -10
      elseif key == "B" or key == "G#m"then transpo = -11
      elseif key == "Cb" or key == "Abm"then transpo = -11
     if not key then end
     end
  
  get_chord_notes(r)
    
    for s = 1, 57 do
  if not sel_item then break end
  sel_take = reaper.GetActiveTake(sel_item)
  item_pitch = reaper.GetMediaItemTakeInfo_Value(sel_take, 'D_PITCH')
  source =  reaper.GetMediaItemTake_Source(sel_take )
  
    scale_notes ={-12,-12,0,0,0,-12,note3,note5,-note5,-note5,note3,note5,note2,note4,note6,note7,12,12,12}
    
    rand = scale_notes [math.random(1,#scale_notes)]    
  
    new_pitch = rand + transpo +note1
    reaper.SetMediaItemTakeInfo_Value(sel_take, 'D_PITCH',new_pitch) 
    reaper.UpdateItemInProject(sel_item)
    break
  end
  end
  end
  end
  end
  ::finish::  



  
main() 
--Msg(rand) 
end
---------------------------------------------------------------------------------------------------
 --[[
   * Тест только на windows  /  Test only on windows.
   * Отчет об ошибке: Если обнаружите какие либо ошибки, то сообщите по одной из указанных ссылок ниже (*Website)
   * Bug Reports: If you find any errors, please report one of the links below (*Website)
   *
   * Category:    Item
   * Description: Item; invert select items on its tracks in time selection.lua
   * Author:      Archie
   * Version:     1.03
   * О скрипте:   инвертировать выделенные элементы на своих дорожках во временном выделении  
   * Website:     http://forum.cockos.com/showthread.php?t=212819
   *              http://rmmedia.ru/threads/134701/
   *              http://vk.com/reaarchie
   * DONATION:    http://money.yandex.ru/to/410018003906628
   * DONATION:    http://paypal.me/ReaArchie?locale.x=ru_RU
   * Customer:    Dragonetti(cocos Forum) http://forum.cockos.com/showpost.php?p=2303125&postcount=10
   * Gave idea:   Dragonetti(cocos Forum)
   * Extension:   Reaper 6.10+ http://www.reaper.fm/
   *              SWS v.2.10.0 http://www.sws-extension.org/index.php
   * Changelog:
   *              v.1.02 [140620]
   *                  + fixes bug

   *              v.1.0 [10620]
   *                  + initialе
--]]
    --======================================================================================
    --////////////  НАСТРОЙКИ  \\\\\\\\\\\\  SETTINGS  ////////////  НАСТРОЙКИ  \\\\\\\\\\\\
    --======================================================================================
function select_all_items()
    local MODE = 0;
    -- = 0; Left: count items by end
    -- = 1; Left: count items by position
        -----------------------------
    -- = 0; Слева: подсчет предметов по окончанию
    -- = 1; Слева: подсчет предметов по позициям

    --======================================================================================
    --////////////// SCRIPT \\\\\\\\\\\\\\  SCRIPT  //////////////  SCRIPT  \\\\\\\\\\\\\\\\
    --======================================================================================


    --=====================================================
    local function no_undo()reaper.defer(function()end)end;
    --=====================================================

    local timeSelStart,timeSelEnd = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
    if timeSelStart==timeSelEnd then no_undo();return end;

    local CountSelItems = reaper.CountSelectedMediaItems(0);
    if CountSelItems == 0 then no_undo();return end;

    local t = {};
    local tbl = {};
    for i = 1, CountSelItems do;
    local itemSel = reaper.GetSelectedMediaItem(0,i-1);
    local pos = reaper.GetMediaItemInfo_Value(itemSel,"D_POSITION");
    local len = reaper.GetMediaItemInfo_Value(itemSel,"D_LENGTH");
    if MODE == 1 then len = 0.000000001 end;
    if pos < timeSelEnd and pos+len > timeSelStart then;
    local track = reaper.GetMediaItem_Track(itemSel);
    if not t[tostring(track)]then;
        t[tostring(track)]=track;
        tbl[#tbl+1] = track;
    end;
    end;
    end;


    if #tbl > 0 then;

    reaper.PreventUIRefresh(9978458);
    reaper.Undo_BeginBlock();

    for i = 1, #tbl do;
    local CountTrackItem = reaper.CountTrackMediaItems(tbl[i]);
    for i2 = 1, CountTrackItem do;
        local item = reaper.GetTrackMediaItem(tbl[i],i2-1);
        local pos = reaper.GetMediaItemInfo_Value(item,"D_POSITION");
        local len = reaper.GetMediaItemInfo_Value(item,"D_LENGTH");
        if MODE == 1 then len = 0.000000001 end;
        if pos < timeSelEnd and pos+len > timeSelStart then;
        local sel = reaper.GetMediaItemInfo_Value(item,"B_UISEL");
        reaper.SetMediaItemInfo_Value(item,"B_UISEL",1);
        elseif pos > timeSelEnd then;
        break;
        end;
    end;
    end;

    reaper.PreventUIRefresh(-9978458);
    reaper.Undo_EndBlock('invert select items on its tracks in time selection',-1);
    reaper.UpdateArrange();
    end;
end;



----------------------------------------------------------------------------------------------------
-------------------------------SELECT_10-------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function select_10_x(hallo)
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

reaper.PreventUIRefresh(1)

local function Msg(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end


math.randomseed(os.time())

sequenzen = {hallo}   
seq = sequenzen[math.random(1,#sequenzen)]   

item_ptrs = {}
itemCount = 1
other_items = {}
otherCount = 1

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))

for selitem = 1, reaper.CountSelectedMediaItems(0) do
  local thisItem = reaper.GetSelectedMediaItem(0 , selitem - 1)
  local thisTrack = reaper.GetMediaItem_Track(thisItem)

  if thisTrack == mainTrack then
    item_ptrs[itemCount] =  thisItem
    itemCount = itemCount + 1
  
  else
    other_items[otherCount] = {
  item = thisItem,
  track = thisTrack,
    }

    otherCount = otherCount + 1
  end
end


parsed_t = {}

for char in seq:gmatch('%a') do 
  local val = 0

  if char=='s' then val = 1 end 

  parsed_t[#parsed_t+1] = val 
end

for i = 1, itemCount - 1 do 
  local ptid = (1+ (i-1)%#parsed_t)

  if parsed_t[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "B_UISEL",parsed_t[ptid]) 
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not parsed_t[index] then
    index = 1
  end


  reaper.SetMediaItemInfo_Value(other_items[i].item, "B_UISEL",parsed_t[index])

  index = index + 1
end


reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
end


----------------------------------------------------------------------------------------------------
------------------------Select_1000-----------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function select_1000_x()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
reaper.PreventUIRefresh(1)

local function Msg(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end


sequenzen = {"suuu"}   
seq = sequenzen[math.random(1,#sequenzen)]   


item_ptrs = {}
itemCount = 1
other_items = {}
otherCount = 1

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))

for selitem = 1, reaper.CountSelectedMediaItems(0) do
  local thisItem = reaper.GetSelectedMediaItem(0 , selitem - 1)
  local thisTrack = reaper.GetMediaItem_Track(thisItem)

  if thisTrack == mainTrack then
    item_ptrs[itemCount] =  thisItem
    itemCount = itemCount + 1
  
  else
    other_items[otherCount] = {
  item = thisItem,
  track = thisTrack,
    }

    otherCount = otherCount + 1
  end
end



parsed_t = {}

for char in seq:gmatch('%a') do 
  local val = 0

  if char=='s' then val = 1 end 

  parsed_t[#parsed_t+1] = val 
end

for i = 1, itemCount - 1 do 
  local ptid = (1+ (i-1)%#parsed_t)

  if parsed_t[ptid] then
 
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "B_UISEL",parsed_t[ptid])
 
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not parsed_t[index] then
    index = 1
  end


  reaper.SetMediaItemInfo_Value(other_items[i].item, "B_UISEL",parsed_t[index])

  index = index + 1
end


reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

end
----------------------------------------------------------------------------------------------------
-----------------------------------SELECT_100----------------------------------------------
----------------------------------------------------------------------------------------------------
function select_100_x()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
reaper.PreventUIRefresh(1)

local function Msg(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end




sequenzen = {"suu"}   
seq = sequenzen[math.random(1,#sequenzen)]   

item_ptrs = {}
itemCount = 1
other_items = {}
otherCount = 1

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))

for selitem = 1, reaper.CountSelectedMediaItems(0) do
  local thisItem = reaper.GetSelectedMediaItem(0 , selitem - 1)
  local thisTrack = reaper.GetMediaItem_Track(thisItem)

  if thisTrack == mainTrack then
    item_ptrs[itemCount] =  thisItem
    itemCount = itemCount + 1
  
  else
    other_items[otherCount] = {
  item = thisItem,
  track = thisTrack,
    }

    otherCount = otherCount + 1
  end
end


parsed_t = {}

for char in seq:gmatch('%a') do 
  local val = 0

  if char=='s' then val = 1 end 

  parsed_t[#parsed_t+1] = val 
end

for i = 1, itemCount - 1 do 
  local ptid = (1+ (i-1)%#parsed_t)

  if parsed_t[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "B_UISEL",parsed_t[ptid]) 
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not parsed_t[index] then
    index = 1
  end


  reaper.SetMediaItemInfo_Value(other_items[i].item, "B_UISEL",parsed_t[index])

  index = index + 1
end


reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

end

--=========================================================================================================
--===================== SELECT_ONLY_ON_GRID ========================================================
--=========================================================================================================
function select_only_on_grid()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end


 item_count = reaper.CountSelectedMediaItems(0)
     for i = item_count - 1, 0, -1 do
  --   for i=0, item_count - 1 do
  item = reaper.GetSelectedMediaItem( 0, i )
     
 
 start =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
  starty  =     math.floor(start)
      y = string.sub(starty,1,6)
  
    closest_grid = reaper.BR_GetClosestGridDivision( start )
    
 
     mult = 10^(3)
    hallo =math.floor(closest_grid * mult + 0.5) / mult
    starty =math.floor(start * mult + 0.5) / mult
 
   
 
    
    if starty ~= hallo then
 
     reaper.SetMediaItemInfo_Value( item, "B_UISEL", 0 )
   
 end
 end
 
 reaper.UpdateArrange()
    
end
--=================================================================================================================
--============================= SELECT_ROOT_NOTE ==================================================================
--=================================================================================================================
-- Display a message in the console for debugging
function select_root_note()
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end



  
function get_chord_notes(r)  

   item0 =  reaper.GetTrackMediaItem(ctrack,r )
      _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
      
    if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
     if string.find(item_notes, "/") then
        root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
     else
        root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
     end
       
       if not chord or #chord == 0 then chord = "Maj" end
       if not slash then slash = "" end

  note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D" then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E" then note1 = 4
  elseif root == "F" then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G" then note1 = -5
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A" then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B" then note1 = -1
  if not root then end
  end
  
  slashnote = 255
  -- 48 = C2

  if slash == "/C" then slashnote = -12
  elseif slash == "/C#" then slashnote = -11
  elseif slash == "/Db" then slashnote = -11
  elseif slash == "/D" then slashnote = -10
  elseif slash == "/D#" then slashnote = -9
  elseif slash == "/Eb" then slashnote = -9
  elseif slash == "/E" then slashnote = -8
  elseif slash == "/F" then slashnote = -7
  elseif slash == "/F#" then slashnote = -6
  elseif slash == "/Gb" then slashnote = -6
  elseif slash == "/G" then slashnote = -5
  elseif slash == "/G#" then slashnote = -4
  elseif slash == "/Ab" then slashnote = -4
  elseif slash == "/A" then slashnote = -3
  elseif slash == "/A#" then slashnote = -2
  elseif slash == "/Bb" then slashnote = -2
  elseif slash == "/B" then slashnote = -1
  if not slash then slashnote = 255 end
  end

  note2 = 255
  note3 = 255
  note4 = 255
  note5 = 255
  note6 = 255
  note7 = 255

  if string.find(",Maj,maj7,", ","..chord..",", 1, true) then note2=4  note3=7 note4=12 end      
  if string.find(",m,min,-,", ","..chord..",", 1, true) then note2=3  note3=7 note4=12 end      
  if string.find(",dim,m-5,mb5,m(b5),0,", ","..chord..",", 1, true) then note2=3  note3=6 note4=12 end   
  if string.find(",aug,+,+5,(#5),", ","..chord..",", 1, true) then note2=4  note3=8 end   
  if string.find(",-5,(b5),", ","..chord..",", 1, true) then note2=4  note3=6 end   
  if string.find(",sus2,", ","..chord..",", 1, true) then note2=2  note3=7 end   
  if string.find(",sus4,sus,(sus4),", ","..chord..",", 1, true) then note2=5  note3=7 end   
  if string.find(",5,", ","..chord..",", 1, true) then note2=7 note3=12 end   
  if string.find(",5add7,5/7,", ","..chord..",", 1, true) then note2=7  note3=10 note4=10 end   
  if string.find(",add2,(add2),", ","..chord..",", 1, true) then note2=2  note3=4  note4=7 end   
  if string.find(",add4,(add4),", ","..chord..",", 1, true) then note2=4  note3=5  note4=7 end   
  if string.find(",madd4,m(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7 end   
  if string.find(",11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17 end  
  if string.find(",11sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17 end  
  if string.find(",m11,min11,-11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17 end  
  if string.find(",Maj11,maj11,M11,Maj7(add11),M7(add11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=17 end     
  if string.find(",mMaj11,minmaj11,mM11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17 end  
  if string.find(",aug11,9+11,9aug11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
  if string.find(",augm11, m9#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18 end  
  if string.find(",11b5,11-5,11(b5),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17 end  
  if string.find(",11#5,11+5,11(#5),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17 end  
  if string.find(",11b9,11-9,11(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17 end  
  if string.find(",11#9,11+9,11(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17 end  
  if string.find(",11b5b9,11-5-9,11(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17 end  
  if string.find(",11#5b9,11+5-9,11(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17 end  
  if string.find(",11b5#9,11-5+9,11(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17 end  
  if string.find(",11#5#9,11+5+9,11(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17 end  
  if string.find(",m11b5,m11-5,m11(b5),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17 end  
  if string.find(",m11#5,m11+5,m11(#5),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17 end  
  if string.find(",m11b9,m11-9,m11(b9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17 end  
  if string.find(",m11#9,m11+9,m11(#9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17 end  
  if string.find(",m11b5b9,m11-5-9,m11(b5b9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17 end
  if string.find(",m11#5b9,m11+5-9,m11(#5b9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17 end
  if string.find(",m11b5#9,m11-5+9,m11(b5#9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17 end
  if string.find(",m11#5#9,m11+5+9,m11(#5#9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17 end
  if string.find(",Maj11b5,maj11b5,maj11-5,maj11(b5),", ","..chord..",", 1, true)    then note2=4  note3=6  note4=11  note5=14  note6=17 end
  if string.find(",Maj11#5,maj11#5,maj11+5,maj11(#5),", ","..chord..",", 1, true)    then note2=4  note3=8  note4=11  note5=14  note6=17 end
  if string.find(",Maj11b9,maj11b9,maj11-9,maj11(b9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13  note6=17 end
  if string.find(",Maj11#9,maj11#9,maj11+9,maj11(#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15  note6=17 end
  if string.find(",Maj11b5b9,maj11b5b9,maj11-5-9,maj11(b5b9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=13  note6=17 end
  if string.find(",Maj11#5b9,maj11#5b9,maj11+5-9,maj11(#5b9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=13  note6=17 end
  if string.find(",Maj11b5#9,maj11b5#9,maj11-5+9,maj11(b5#9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=15  note6=17 end
  if string.find(",Maj11#5#9,maj11#5#9,maj11+5+9,maj11(#5#9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=15  note6=17 end
  if string.find(",13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",m13,min13,-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",Maj13,maj13,M13,Maj7(add13),M7(add13),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",mMaj13,minmaj13,mM13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",13b5,13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",13#5,13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",13b9,13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13#9,13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
  if string.find(",13b5b9,13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13#5b9,13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13b5#9,13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13#5#9,13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13b9#11,13-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18  note7=21 end  
  if string.find(",m13b5,m13-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",m13#5,m13+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",m13b9,m13-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",m13#9,m13+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",m13b5b9,m13-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",m13#5b9,m13+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",m13b5#9,m13-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",m13#5#9,m13+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13b5,maj13b5,maj13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",Maj13#5,maj13#5,maj13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",Maj13b9,maj13b9,maj13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=13  note6=17  note7=21 end  
  if string.find(",Maj13#9,maj13#9,maj13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13b5b9,maj13b5b9,maj13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13  note6=17  note7=21 end  
  if string.find(",Maj13#5b9,maj13#5b9,maj13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13  note6=17  note7=21 end  
  if string.find(",Maj13b5#9,maj13b5#9,maj13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13#5#9,maj13#5#9,maj13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13#11,maj13#11,maj13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18  note7=21 end  
  if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",m13#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",13sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",6,M6,Maj6,maj6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9 end   
  if string.find(",m6,min6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9 end   
  if string.find(",6add4,6/4,6(add4),Maj6(add4),M6(add4),", ","..chord..",", 1, true)    then note2=4  note3=5  note4=7  note5=9 end   
  if string.find(",m6add4,m6/4,m6(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=9 end   
  if string.find(",69,6add9,6/9,6(add9),Maj6(add9),M6(add9),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=14 end  
  if string.find(",m6add9,m6/9,m6(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
  if string.find(",6sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=9 end   
  if string.find(",6sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=9 end   
  if string.find(",6add11,6/11,6(add11),Maj6(add11),M6(add11),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=17 end  
  if string.find(",m6add11,m6/11,m6(add11),m6(add11),", ","..chord..",", 1, true)    then note2=3  note3=7  note4=9  note5=17 end  
  if string.find(",7,dom,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=12 note6=16 note7=19 end   
  if string.find(",7add2,", ","..chord..",", 1, true) then note2=2  note3=4  note4=7  note5=10 end  
  if string.find(",7add4,", ","..chord..",", 1, true) then note2=4  note3=5  note4=7  note5=10 end  
  if string.find(",m7,min7,-7,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10 note5=12 note6=15 note7=19 end  
  if string.find(",m7add4,", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=10 end  
  if string.find(",Maj7,maj7,Maj7,M7,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11 end   
  if string.find(",dim7,07,", ","..chord..",", 1, true) then note2=3  note3=6  note4=9 end   
  if string.find(",mMaj7,minmaj7,mmaj7,min/maj7,mM7,m(addM7),m(+7),-(M7),m(maj7),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11 end    
  if string.find(",7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=10 end   
  if string.find(",7sus4,7sus,7sus11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10 end   
  if string.find(",Maj7sus2,maj7sus2,M7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=11 end    
  if string.find(",Maj7sus4,maj7sus4,M7sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11 end    
  if string.find(",aug7,+7,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
  if string.find(",7b5,7-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 end   
  if string.find(",7#5,7+5,7+,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
  if string.find(",m7b5,m7-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10 end   
  if string.find(",m7#5,m7+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10 end   
  if string.find(",Maj7b5,maj7b5,maj7-5,M7b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11 end   
  if string.find(",Maj7#5,maj7#5,maj7+5,M7+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11 end   
  if string.find(",7b9,7-9,7(addb9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13 end  
  if string.find(",7#9,7+9,7(add#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
  if string.find(",m7b9, m7-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13 end  
  if string.find(",m7#9, m7+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15 end  
  if string.find(",Maj7b9,maj7b9,maj7-9,maj7(addb9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13 end 
  if string.find(",Maj7#9,maj7#9,maj7+9,maj7(add#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15 end 
  if string.find(",7b9b13,7-9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=20 end  
  if string.find(",m7b9b13, m7-9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=20 end
  if string.find(",7b13,7-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
  if string.find(",m7b13,m7-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=20 end  
  if string.find(",7#9b13,7+9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=20 end  
  if string.find(",m7#9b13,m7+9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=20 end  
  if string.find(",7b5b9,7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13 end  
  if string.find(",7b5#9,7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15 end  
  if string.find(",7#5b9,7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13 end  
  if string.find(",7#5#9,7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15 end  
  if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18 end  
  if string.find(",7add6,7/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10 end  
  if string.find(",7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=17 end  
  if string.find(",7add13,7/13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=21 end  
  if string.find(",m7add11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=17 end  
  if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13 end  
  if string.find(",m7b5#9,m7-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15 end  
  if string.find(",m7#5b9,m7+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13 end  
  if string.find(",m7#5#9,m7+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15 end  
  if string.find(",m7#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=18 end  
  if string.find(",Maj7b5b9,maj7b5b9,maj7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13 end 
  if string.find(",Maj7b5#9,maj7b5#9,maj7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15 end 
  if string.find(",Maj7#5b9,maj7#5b9,maj7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13 end 
  if string.find(",Maj7#5#9,maj7#5#9,maj7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15 end 
  if string.find(",Maj7add11,maj7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=17 end  
  if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=18 end  
  if string.find(",9,7(add9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=16  note7=19 end
  if string.find(",m9,min9,-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14 end  
  if string.find(",Maj9,maj9,M9,Maj7(add9),M7(add9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=14 end 
  if string.find(",Maj9sus4,maj9sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11  note5=14 end  
  if string.find(",mMaj9,minmaj9,mmaj9,min/maj9,mM9,m(addM9),m(+9),-(M9),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11  note5=14 end 
  if string.find(",9sus4,9sus,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 end  
  if string.find(",aug9,+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
  if string.find(",9add6,9/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10  note6=14 end  
  if string.find(",m9add6,m9/6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
  if string.find(",9b5,9-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14 end  
  if string.find(",9#5,9+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14 end  
  if string.find(",m9b5,m9-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14 end  
  if string.find(",m9#5,m9+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14 end  
  if string.find(",Maj9b5,maj9b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14 end  
  if string.find(",Maj9#5,maj9#5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14 end  
  if string.find(",Maj9#11,maj9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18 end  
  if string.find(",b9#11,-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18 end  
  if string.find(",add9,2,", ","..chord..",", 1, true) then note2=4  note3=7  note4=14 end   
  if string.find(",madd9,m(add9),-(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=14 end   
  if string.find(",add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=17 end   
  if string.find(",madd11,m(add11),-(add11),", ","..chord..",", 1, true) then note2=3  note3=7  note4=17 end    
  if string.find(",(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=13 end   
  if string.find(",(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=15 end   
  if string.find(",(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=13 end   
  if string.find(",(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=13 end   
  if string.find(",(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=15 end   
  if string.find(",(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=15 end   
  if string.find(",m(b9), mb9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=13 end   
  if string.find(",m(#9), m#9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=15 end   
  if string.find(",m(b5b9), mb5b9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=13 end   
  if string.find(",m(#5b9), m#5b9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=13 end   
  if string.find(",m(b5#9), mb5#9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=15 end   
  if string.find(",m(#5#9), m#5#9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=15 end   
  if string.find(",m(#11), m#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=18 end   
  if string.find(",(#11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=18 end   
  if string.find(",m#5,", ","..chord..",", 1, true) then note2=3  note3=8 end   
  if string.find(",maug,augaddm3,augadd(m3),", ","..chord..",", 1, true) then note2=3  note3=7 note4=8 end  
  if string.find(",13#9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
  if string.find(",13#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",13susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",13susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=21 end  
  if string.find(",13susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=21 end  
  if string.find(",13sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=17  note6=21 end  
  if string.find(",13sus#5b9,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13sus#5b9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=18  note7=21 end  
  if string.find(",13sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
  if string.find(",13sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end
  if string.find(",13sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13sus#9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=21 end  
  if string.find(",13sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",7b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 note5=17  note6=20 end   
  if string.find(",7b5#9b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=20 end  
  if string.find(",7#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=18 end  
  if string.find(",7#5#9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=18 end  
  if string.find(",7#5b9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=18 end  
  if string.find(",7#9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18 note7=20 end  
  if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=18 end   
  if string.find(",7#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18  note6=20 end  
  if string.find(",7susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10 end   
  if string.find(",7susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13 end  
  if string.find(",7b5b9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=20 end  
  if string.find(",7susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=20 end  
  if string.find(",7susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15 end  
  if string.find(",7susb5#9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=20 end  
  if string.find(",7susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13 end  
  if string.find(",7susb9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=20 end  
  if string.find(",7susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18 end  
  if string.find(",7susb9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=20 end  
  if string.find(",7susb13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=20 end  
  if string.find(",7sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10 end   
  if string.find(",7sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end  
  if string.find(",7sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
  if string.find(",7sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15 end  
  if string.find(",7sus#9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=20 end  
  if string.find(",7sus#9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=20 end  
  if string.find(",7sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18 end  
  if string.find(",7sus#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18  note6=20 end  
  if string.find(",9b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=20 end  
  if string.find(",9b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
  if string.find(",9#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=18 end  
  if string.find(",9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
  if string.find(",9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=20 end  
  if string.find(",9susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  end  
  if string.find(",9susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14 note6=20 end  
  if string.find(",9sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 note6=18 end  
  if string.find(",9susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=15 end  
  if string.find(",9sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=14  note6=18 end   
  if string.find(",quartal,", ","..chord..",", 1, true) then note2=5  note3=10  note4=15 end
  if string.find(",sowhat,", ","..chord..",", 1, true) then note2=5  note3=10  note4=16 end
  

end



--MAIN---------------------------------------------------------------
function main()

  commandID2 = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
  reaper.Main_OnCommand(commandID2, 0) -- SWS: Select only track(s) with selected item(s) _SWS_SELTRKWITEM

  items = reaper.CountMediaItems(0)
  
  sel_tracks = reaper.CountSelectedTracks(0) 
  
 ctrack = getTrackByName("chordtrack")
    
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
    reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
     
    else -- track == nil/no track with that name was
      num_chords = reaper.CountTrackMediaItems(ctrack)
      
    end

    for r = 0, num_chords -1 do -- regions loop start    
    
  chord_item = reaper.GetTrackMediaItem(ctrack, r )
                        pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
                     length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
                     rgnend = pos+length  
  
  for x = 0, items -1 do -- items loop start
   
   media_item = reaper.GetMediaItem( 0, x )
   
   selected_item = reaper.IsMediaItemSelected(media_item) 
   
   if selected_item then
    
    current_item = reaper.GetMediaItem( 0, x )
  
    item_start = (reaper.GetMediaItemInfo_Value( current_item, "D_POSITION"))+0.1
    
    --Does item start within region
    
    if item_start  >= pos and item_start < rgnend then 
      --Msg("r "..r) 
      --Msg("markrgnindexnumber ".. markrgnindexnumber)
     get_chord_notes(r) -- get the chord notes for current region
      

      
      
    take = reaper.GetActiveTake(current_item)
     take = reaper.GetActiveTake(current_item)
        source =  reaper.GetMediaItemTake_Source( take )
        _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
        
            if key == "C" or key == "c" or key == "Am" or key == "" then transpo = 0
                   elseif key == "C#" or key == "A#m"then transpo = -1
                   elseif key == "Db" or key == "Bbm"then transpo = -1
                   elseif key == "D"  or key == "d"  or key == "Bm"then transpo = -2
                   elseif key == "Eb" or key == "Cm"then transpo = -3
                    elseif key == "E" or key == "e" or key == "C#m"then transpo = -4 
                    elseif key == "F" or key == "f" or key == "Dm"then transpo = -5
                   elseif key == "F#" or key == "D#m"then transpo = -6
                   elseif key == "Gb" or key == "Ebm"then transpo = -6
                    elseif key == "G" or key == "g" or key == "Em"then transpo = -7 
                   elseif key == "G#" or key == "E#m"then transpo = -8
                   elseif key == "Ab" or key == "Fm"then transpo = -8 
                    elseif key == "A" or key == "a" or key == "F#m"then transpo = -9
                    elseif key == "Bb" or key == "Gm"then transpo = -10
                    elseif key == "B" or key == "b" or key == "G#m"then transpo = -11
                    elseif key == "Cb" or key == "Abm"then transpo = -11
                   if not key then end
                   end         
       
       
     old_pitch = reaper.GetMediaItemTakeInfo_Value(take, 'D_PITCH')
     root_note = old_pitch - transpo - note1
     if root_note ~=0  and root_note ~=12 then  reaper.SetMediaItemInfo_Value( current_item, "B_UISEL", 0 )
      --   elseif root_note ~=-12 then reaper.SetMediaItemInfo_Value( current_item, "B_UISEL", 0 ) 
     
    reaper.UpdateItemInProject(current_item)
      end
    --  if root_note ~= 0  then  reaper.SetMediaItemInfo_Value( current_item, "B_UISEL", 0 )
     
      end          
     
      end       
        
    end
   end
   
  end -- items loop end
   -- regions loop end
  
 
  
 

  
main()  
  
reaper.Main_OnCommand(40297,0)   


::skip:: 
  

--Msg(root_note)

end
--=================================================================================================================
--====================== pattern select ===========================================================================
--=================================================================================================================

--thanks mpl
function pattern_select()

ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then Msg("no selected items")return
end
reaper.PreventUIRefresh(1)

local function Msg(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end

retval, seq1 = reaper.GetUserInputs( "pattern select", 1,"1=select 0=unselect", "01" )

item_ptrs = {}
itemCount = 1
other_items = {}
otherCount = 1

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))

for selitem = 1, reaper.CountSelectedMediaItems(0) do
  local thisItem = reaper.GetSelectedMediaItem(0 , selitem - 1)
  local thisTrack = reaper.GetMediaItem_Track(thisItem)

  if thisTrack == mainTrack then
    item_ptrs[itemCount] =  thisItem
    itemCount = itemCount + 1
  
  else
    other_items[otherCount] = {
  item = thisItem,
  track = thisTrack,
    }

    otherCount = otherCount + 1
  end
end



parsed_t = {}

for char in seq1:gmatch('%d') do 
  local val = 0

  if char=='1' then val = 1 end 

  parsed_t[#parsed_t+1] = val 
end

for i = 1, itemCount - 1 do 
  local ptid = (1+ (i-1)%#parsed_t)

  if parsed_t[ptid] then
 
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "B_UISEL",parsed_t[ptid])
 
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not parsed_t[index] then
    index = 1
  end


  reaper.SetMediaItemInfo_Value(other_items[i].item, "B_UISEL",parsed_t[index])

  index = index + 1
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

end
--=================================================================================================================
--===================== INVERT_SELECTION_IN TIME SELECTION ========================================================
--=================================================================================================================
 --[[
   * Тест только на windows  /  Test only on windows.
   * Отчет об ошибке: Если обнаружите какие либо ошибки, то сообщите по одной из указанных ссылок ниже (*Website)
   * Bug Reports: If you find any errors, please report one of the links below (*Website)
   *
   * Category:    Item
   * Description: Item; invert select items on its tracks in time selection.lua
   * Author:      Archie
   * Version:     1.03
   * О скрипте:   инвертировать выделенные элементы на своих дорожках во временном выделении  
   * Website:     http://forum.cockos.com/showthread.php?t=212819
   *              http://rmmedia.ru/threads/134701/
   *              http://vk.com/reaarchie
   * DONATION:    http://money.yandex.ru/to/410018003906628
   * DONATION:    http://paypal.me/ReaArchie?locale.x=ru_RU
   * Customer:    Dragonetti(cocos Forum) http://forum.cockos.com/showpost.php?p=2303125&postcount=10
   * Gave idea:   Dragonetti(cocos Forum)
   * Extension:   Reaper 6.10+ http://www.reaper.fm/
   *              SWS v.2.10.0 http://www.sws-extension.org/index.php
   * Changelog:
   *              v.1.02 [140620]
   *                  + fixes bug

   *              v.1.0 [10620]
   *                  + initialе
--]]
    --======================================================================================
    --////////////  НАСТРОЙКИ  \\\\\\\\\\\\  SETTINGS  ////////////  НАСТРОЙКИ  \\\\\\\\\\\\
    --======================================================================================
function invert_item_selection()
    local MODE = 0;
    -- = 0; Left: count items by end
    -- = 1; Left: count items by position
        -----------------------------
    -- = 0; Слева: подсчет предметов по окончанию
    -- = 1; Слева: подсчет предметов по позициям

    --======================================================================================
    --////////////// SCRIPT \\\\\\\\\\\\\\  SCRIPT  //////////////  SCRIPT  \\\\\\\\\\\\\\\\
    --======================================================================================


    --=====================================================
    local function no_undo()reaper.defer(function()end)end;
    --=====================================================

    local timeSelStart,timeSelEnd = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
    if timeSelStart==timeSelEnd then no_undo();return end;

    local CountSelItems = reaper.CountSelectedMediaItems(0);
    if CountSelItems == 0 then no_undo();return end;

    local t = {};
    local tbl = {};
    for i = 1, CountSelItems do;
    local itemSel = reaper.GetSelectedMediaItem(0,i-1);
    local pos = reaper.GetMediaItemInfo_Value(itemSel,"D_POSITION");
    local len = reaper.GetMediaItemInfo_Value(itemSel,"D_LENGTH");
    if MODE == 1 then len = 0.000000001 end;
    if pos < timeSelEnd and pos+len > timeSelStart then;
    local track = reaper.GetMediaItem_Track(itemSel);
    if not t[tostring(track)]then;
        t[tostring(track)]=track;
        tbl[#tbl+1] = track;
    end;
    end;
    end;


    if #tbl > 0 then;

    reaper.PreventUIRefresh(9978458);
    reaper.Undo_BeginBlock();

    for i = 1, #tbl do;
    local CountTrackItem = reaper.CountTrackMediaItems(tbl[i]);
    for i2 = 1, CountTrackItem do;
        local item = reaper.GetTrackMediaItem(tbl[i],i2-1);
        local pos = reaper.GetMediaItemInfo_Value(item,"D_POSITION");
        local len = reaper.GetMediaItemInfo_Value(item,"D_LENGTH");
        if MODE == 1 then len = 0.000000001 end;
        if pos < timeSelEnd and pos+len > timeSelStart then;
        local sel = reaper.GetMediaItemInfo_Value(item,"B_UISEL");
        reaper.SetMediaItemInfo_Value(item,"B_UISEL",math.abs(sel-1));
        elseif pos > timeSelEnd then;
        break;
        end;
    end;
    end;

    reaper.PreventUIRefresh(-9978458);
    reaper.Undo_EndBlock('invert select items on its tracks in time selection',-1);
    reaper.UpdateArrange();
    end;

end;

--=================================================================================================================
--===================== SELECT_PREV_ITEM ========================================================
--=================================================================================================================
--[[
   * Тест только на windows  /  Test only on windows.
   * Отчет об ошибке: Если обнаружите какие либо ошибки, то сообщите по одной из указанных ссылок ниже (*Website)
   * Bug Reports: If you find any errors, please report one of the links below (*Website)
   *
   * Category:    Item
   * Description: Select Previous item in track
   * Author:      Archie
   * Version:     1.02
   * Описание:    Выберите предыдущий элемент в треке
   * Website:     http://forum.cockos.com/showthread.php?t=212819
   *              http://rmmedia.ru/threads/134701/
   * DONATION:    http://money.yandex.ru/to/410018003906628
   * DONATION:    http://paypal.me/ReaArchie?locale.x=ru_RU
   * Customer:    Archie(Rmm)
   * Gave idea:   borisuperful(Rmm)
   * Extension:   Reaper 6.03+ http://www.reaper.fm/
   *              SWS v.2.10.0 http://www.sws-extension.org/index.php
   * Changelog:
   *              v.1.0 [07.02.20]
   *                  + initialе
--]]
    --======================================================================================
    --////////////// SCRIPT \\\\\\\\\\\\\\  SCRIPT  //////////////  SCRIPT  \\\\\\\\\\\\\\\\
    --======================================================================================

function select_prev_item()


    ------------------------------------------------------
    local function no_undo()reaper.defer(function()end)end;
    -------------------------------------------------------


    local CountSelitem = reaper.CountSelectedMediaItems(0);
    if CountSelitem == 0 then no_undo() return end;


    local CountTrack = reaper.CountTracks(0);
    if CountTrack == 0 then no_undo() return end;

    reaper.Undo_BeginBlock();
    reaper.PreventUIRefresh(1);

    for i = 1,CountTrack do;
    local track = reaper.GetTrack(0,i-1);

    ---
    local CountTrItem = reaper.CountTrackMediaItems(track);
    local sel2,item2;
    for i = 1,CountTrItem do;

    local item = reaper.GetTrackMediaItem(track,i-1);
    local take = reaper.GetActiveTake(item);

    local sel = reaper.GetMediaItemInfo_Value(item,'B_UISEL');

    if sel == 1 and sel2 == 0 then;
    reaper.SetMediaItemInfo_Value(item2,'B_UISEL',1);
    reaper.SetMediaItemInfo_Value(item,'B_UISEL',0);
  sel = 0;
    end;
    sel2 = sel;
    item2 = item;
    end;
    ---
    end;

    reaper.PreventUIRefresh(1);
    reaper.Undo_EndBlock('Select Previous item in track',-1);

    reaper.UpdateArrange();

end;

--=================================================================================================================
--===================== SELECT_NEXT_ITEM ========================================================
--=================================================================================================================
--[[
   * Тест только на windows  /  Test only on windows.
   * Отчет об ошибке: Если обнаружите какие либо ошибки, то сообщите по одной из указанных ссылок ниже (*Website)
   * Bug Reports: If you find any errors, please report one of the links below (*Website)
   *
   * Category:    Item
   * Description: Select Next item in track
   * Author:      Archie
   * Version:     1.02
   * Описание:    Выберите следующий пункт в треке
   * Website:     http://forum.cockos.com/showthread.php?t=212819
   *              http://rmmedia.ru/threads/134701/
   * DONATION:    http://money.yandex.ru/to/410018003906628
   * DONATION:    http://paypal.me/ReaArchie?locale.x=ru_RU
   * Customer:    Archie(Rmm)
   * Gave idea:   borisuperful(Rmm)
   * Extension:   Reaper 6.03+ http://www.reaper.fm/
   *              SWS v.2.10.0 http://www.sws-extension.org/index.php
   * Changelog:
   *              v.1.0 [07.02.20]
   *                  + initialе
--]]
    --======================================================================================
    --////////////// SCRIPT \\\\\\\\\\\\\\  SCRIPT  //////////////  SCRIPT  \\\\\\\\\\\\\\\\
    --======================================================================================

function select_next_item()



    ------------------------------------------------------
    local function no_undo()reaper.defer(function()end)end;
    -------------------------------------------------------


    local CountSelitem = reaper.CountSelectedMediaItems(0);
    if CountSelitem == 0 then no_undo() return end;


    local CountTrack = reaper.CountTracks(0);
    if CountTrack == 0 then no_undo() return end;

    reaper.Undo_BeginBlock();
    reaper.PreventUIRefresh(1);

    for i = 1,CountTrack do;
    local track = reaper.GetTrack(0,i-1);

    ---
    local CountTrItem = reaper.CountTrackMediaItems(track);
    local sel2,item2;
    for i = CountTrItem-1,0,-1 do;

    local item = reaper.GetTrackMediaItem(track,i);
    local take = reaper.GetActiveTake(item);

    local sel = reaper.GetMediaItemInfo_Value(item,'B_UISEL');

    if sel == 1 and sel2 == 0 then;
        reaper.SetMediaItemInfo_Value(item2,'B_UISEL',1);
        reaper.SetMediaItemInfo_Value(item,'B_UISEL',0);
        sel = 0;
    end;
    sel2 = sel;
    item2 = item;
    end;
    ---
    end;

    reaper.PreventUIRefresh(1);
    reaper.Undo_EndBlock('Select Next item in track',-1);

    reaper.UpdateArrange();

end;

--====================================================================================================
--============================== SELECT_CHORD =======================================================
--====================================================================================================
function select_chord()

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end

 
    --Does item start within region 
    ctrack = getTrackByName("chordtrack")
    
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
    reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
     
    else -- track == nil/no track with that name was
      num_chords = reaper.CountTrackMediaItems(ctrack)
      
    end
   


--Archie
--]]
    --======================================================================================
    --////////////// SCRIPT \\\\\\\\\\\\\\  SCRIPT  //////////////  SCRIPT  \\\\\\\\\\\\\\\\
    --======================================================================================

  --  function select_region()

    local CountSelItem = reaper.CountSelectedMediaItems(0);
    if CountSelItem == 0 then  return end;


    cursor_pos = reaper.GetCursorPosition()
 --   _, regionidx = reaper.GetLastMarkerAndCurRegion( 0, cursor_pos )
 --   retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( regionidx )

      for r = 0, num_chords -1 do -- regions loop start 
               
               chord_item = reaper.GetTrackMediaItem(ctrack, r )
                      xpos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
                   length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
                   xrgnend = xpos+length  
 
    if cursor_pos  >= xpos and cursor_pos < xrgnend then 
     pos = xpos
     rgnend = xrgnend

        

end
end


    for i = CountSelItem-1,0,-1 do;

        local SelItem = reaper.GetSelectedMediaItem(0,i);
        local PosIt = reaper.GetMediaItemInfo_Value(SelItem,"D_POSITION")+0.05;
        local LenIt = reaper.GetMediaItemInfo_Value(SelItem,"D_LENGTH");
        local EndIt = PosIt + (LenIt-0.1);

        if PosIt < rgnend and EndIt > pos then;


            if PosIt < rgnend and EndIt > rgnend then;
                local Right = reaper.SplitMediaItem(SelItem,rgnend);
                if Right then
                    reaper.SetMediaItemInfo_Value( Right, "B_UISEL", 0 );
                end
            end

            if PosIt < pos and EndIt > pos then;
                local Left = reaper.SplitMediaItem(SelItem,pos);
                if Left then
                    reaper.SetMediaItemInfo_Value( Left, "B_UISEL", 0 );
                end
            end;
        else;
         
            reaper.SetMediaItemInfo_Value( SelItem, "B_UISEL", 0 );
        end;
    end;


 
    reaper.UpdateArrange();


end

----------------------------------------------------------------------------------------------------
---------------------------------SELECT_HIGH_PITCH-----------------------------------------------------------
----------------------------------------------------------------------------------------------------
function select_high_pitch_x()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local items, winner = {}

reaper.Undo_BeginBlock()

for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
  local item = reaper.GetSelectedMediaItem(nil, i)
  local take = reaper.GetActiveTake(item) 
  local pitch = reaper.GetMediaItemTakeInfo_Value(take, 'D_PITCH')
  if not winner or pitch > winner.pitch then
    winner = { item=item, pitch=pitch }
  end
  table.insert(items, item)
end

for _, item in ipairs(items) do   
  if item ~= winner.item then
    reaper.SetMediaItemSelected(item, false)
  end
end

reaper.UpdateArrange()
reaper.Undo_EndBlock(script_name, 0)
end
----------------------------------------------------------------------------------------------------
-----------------------------UNMUTE-----------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function unmute_x()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
reaper.PreventUIRefresh(1)

local function Msg(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end


math.randomseed(os.time())

sequenzen = {"s"}   
seq = sequenzen[math.random(1,#sequenzen)]   

item_ptrs = {}
itemCount = 1
other_items = {}
otherCount = 1

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))

for selitem = 1, reaper.CountSelectedMediaItems(0) do
  local thisItem = reaper.GetSelectedMediaItem(0 , selitem - 1)
  local thisTrack = reaper.GetMediaItem_Track(thisItem)

  if thisTrack == mainTrack then
    item_ptrs[itemCount] =  thisItem
    itemCount = itemCount + 1
  
  else
    other_items[otherCount] = {
  item = thisItem,
  track = thisTrack,
    }

    otherCount = otherCount + 1
  end
end


parsed_t = {}

for char in seq:gmatch('%a') do 
  local val = 0

  if char=='u' then val = 1 end 

  parsed_t[#parsed_t+1] = val 
end

for i = 1, itemCount - 1 do 
  local ptid = (1+ (i-1)%#parsed_t)

  if parsed_t[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "B_MUTE",parsed_t[ptid]) 
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not parsed_t[index] then
    index = 1
  end


  reaper.SetMediaItemInfo_Value(other_items[i].item, "B_MUTE",parsed_t[index])

  index = index + 1
end


reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
end
----------------------------------------------------------------------------------------------------
-------------------------MUTE_RANDOM--------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function mute_rand_x()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
reaper.PreventUIRefresh(1)

local function Msg(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end


math.randomseed(os.time())

sequenzen = {"umuuuuuu","muuuuuuuu","ummum","muummmu"}   
seq = sequenzen[math.random(1,#sequenzen)]   

item_ptrs = {}
itemCount = 1
other_items = {}
otherCount = 1

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))

for selitem = 1, reaper.CountSelectedMediaItems(0) do
  local thisItem = reaper.GetSelectedMediaItem(0 , selitem - 1)
  local thisTrack = reaper.GetMediaItem_Track(thisItem)

  if thisTrack == mainTrack then
    item_ptrs[itemCount] =  thisItem
    itemCount = itemCount + 1
  
  else
    other_items[otherCount] = {
  item = thisItem,
  track = thisTrack,
    }

    otherCount = otherCount + 1
  end
end


parsed_t = {}

for char in seq:gmatch('%a') do 
  local val = 0

  if char=='m' then val = 1 end 

  parsed_t[#parsed_t+1] = val 
end

for i = 1, itemCount - 1 do 
  local ptid = (1+ (i-1)%#parsed_t)

  if parsed_t[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "B_MUTE",parsed_t[ptid]) 
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not parsed_t[index] then
    index = 1
  end


  reaper.SetMediaItemInfo_Value(other_items[i].item, "B_MUTE",parsed_t[index])

  index = index + 1
end


reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
end
----------------------------------------------------------------------------------------------------
-------------------------INVERT_SELECTED------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- invert selection item in time selection
function invert_selection()    
    local timeSelStart,timeSelEnd = reaper.GetSet_LoopTimeRange(0,0,0,0,0)
    if timeSelStart~=timeSelEnd then
    
    local CountItems = reaper.CountMediaItems(0)
    if CountItems > 0 then;
    for i = 1, CountItems do;
        local track = reaper.GetSelectedTrack(0,0)
        local CountTrItems = reaper.CountTrackMediaItems(track)
        local selc_item = reaper.GetSelectedMediaItem( 0, i-1 )
        local item = reaper.GetMediaItem(0,i-1)
        local pos = reaper.GetMediaItemInfo_Value(CountTrItems,"D_POSITION")
        local len = reaper.GetMediaItemInfo_Value(selc_item,"D_LENGTH")
        if pos < timeSelEnd and pos+len > timeSelStart then
        reaper.SetMediaItemInfo_Value(item,"B_UISEL",math.abs(reaper.GetMediaItemInfo_Value(selc_item,"B_UISEL")-1))
        end;
    end;
    end;
    end;
    
    reaper.UpdateArrange();
end
--======================================================================================================================================
--============================================ SHUFFLE_ORDER =============================================================================
--==========================================================================================================================================
--[[
 * ReaScript Name: Shuffle order of selected items columns keeping snap offset positions and parent tracks
 * About: This works nicely only if there is as many items selected on each track, as it works on item selected ID on track and not "visual" columns
 * Author: X-Raym
 * Author URI: https://www.extremraym.com
 * Repository: GitHub > X-Raym > REAPER-ReaScripts
 * Repository URI: https://github.com/X-Raym/REAPER-ReaScripts
 * Licence: GPL v3
 * Forum Thread: Script (Lua): Shuffle Items
 * Forum Thread URI: http://forum.cockos.com/showthread.php?t=159961
 * REAPER: 5.0
 * Version: 2.0
--]]

--[[
 * Changelog:
 * v2.0 (2021-01-07)
  + new core
  # remove group support
 * v1.1 (2016-01-07)
  + Preserve grouping if groups active. Treat first selected item (in position) in each group as group leader (other are ignored during the alignement).
 * v1.0 (2015-06-09)
  + Initial Release
--]]

-------------------------------------------------------------
function shuffle_order()
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

-------------------------------------------------------------

-- SHUFFLE TABLE FUNCTION
-- https://gist.github.com/Uradamus/10323382
function shuffle(t)
  local tbl = {}
  for i = 1, #t do
    tbl[i] = t[i]
  end
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  if do_tables_match( t, tbl ) then -- MOD: be sure tables are different
    --tbl = shuffle(t)
  end
  return tbl
end

function do_tables_match( a, b )
  return table.concat(a) == table.concat(b)
end


-------------------------------------------------------------
function Main()

  -- Get Columns of Selected Items
  columns = {} -- Original minimum positions and list of items for each columns
  positions = {} -- Minimum positions of items snap for each columns
  local column = 0

  for i = 0, count_sel_items - 1 do

    local item = reaper.GetSelectedMediaItem(0,i)
    local track = reaper.GetMediaItemTrack( item )
    local track_id = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER")

    if track_id ~= last_track_id then column = 0 end -- reset column counter
    column = column + 1 -- increment column

    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_snap = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
    local item_possnap = item_pos + item_snap

    if not columns[column] then
      columns[column] = {min_possnap = item_possnap, items = {} }
    else
      columns[column].min_possnap = math.min( columns[column].min_possnap, item_possnap )
    end
    positions[column] = columns[column].min_possnap
    table.insert(columns[column].items, item)

    last_track_id = track_id

  end

  if #columns > 1 then --  No need if there is only one column
    positions = shuffle( positions )

    for i, column in ipairs( columns ) do
      offset = positions[i] - column.min_possnap
      for j, item in ipairs( column.items ) do
        local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        reaper.SetMediaItemInfo_Value(item, "D_POSITION", item_pos + offset)
      end
    end

  end

end

-- INIT -----------------------------------------------------

count_sel_items = reaper.CountSelectedMediaItems(0)

if count_sel_items > 1 then

  reaper.PreventUIRefresh(1)

  reaper.Undo_BeginBlock()

  Main()

  reaper.Undo_EndBlock("Shuffle order of selected items columns keeping snap offset positions and parent tracks", -1)

  reaper.PreventUIRefresh(-1)

  reaper.UpdateArrange()

end


-- Xenakios/SWS: Reposition selected items.
-- Convert to Lua from SWS C++



function GetSelectedMediaItemsOnTrack(tr)
  items = {}
  for j = 0, reaper.GetTrackNumMediaItems(tr)-1 do
    local item = reaper.GetTrackMediaItem(tr, j)
    if reaper.GetMediaItemInfo_Value(item, "B_UISEL") == 1 then items[#items+1] = item end
  end
  return items
end

function hallo()


  bEnd = true   -- Start = false, End = true

  for i = 0, reaper.CountTracks(0)-1 do
    track = reaper.CSurf_TrackFromID(i + 1, false)
    items = GetSelectedMediaItemsOnTrack(track)
    for j = 2, #items do
      dPrevItemStart = reaper.GetMediaItemInfo_Value(items[j-1], "D_POSITION")
      dNewPos = dPrevItemStart 
      if (bEnd) then
        dNewPos = dNewPos + reaper.GetMediaItemInfo_Value(items[j-1], "D_LENGTH")
      end
      reaper.SetMediaItemInfo_Value(items[j], "D_POSITION", dNewPos)
    end
  end
end

hallo()

end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------ORDER_PITCH---------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 --[[
  * ReaScript Name: Sort selected items by pitch (ascending)
  * Description:    Sorts selected items from shortest to longest
  * Instructions:   - Select items
  *                 - Run the script
  * Screenshot: 
  * Notes: 
  * Category: 
  * Author: Mordi & spk77 , changed by dragonetti
  * Author URI:
  * Licence: GPL v3
  * Forum Thread: 
  * Forum Thread URL:
  * Version: 1.0
  * REAPER:
  * Extensions:
]]
 

--[[
 Changelog:
 * v1.0 (2016-06-26)
    + Changed script to only work on selected items.
]]
function order_pitch()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

function get_item_lengths()
  local t={}
  for i=1, reaper.CountSelectedMediaItems(0) do
    t[i] = {}
    local item = reaper.GetSelectedMediaItem(0, i-1)
    if item ~= nil then 
  t[i].item = item  
  t[i].len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  take = reaper.GetActiveTake(item)
  t[i].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
    end
  end
  return t
end

sort_func = function(a,b) -- https://forums.coronalabs.com/topic/37595-nested-sorting-on-multi-dimensional-array/
      if (a.pitch < b.pitch) then
        -- primary sort on length -> a before b
        return true
      --[[
      elseif (a.len > b.len) then
        -- primary sort on length -> b before a
        return false
      else
        -- primary sort tied, resolve w secondary sort on position
        return a.position < b.position
      --]]
      end
    end
      
function sort_items_by_length()
  local data = get_item_lengths()
  if #data == 0 then return end
  local pos = reaper.GetMediaItemInfo_Value(data[1].item, "D_POSITION") -- get first item pos
  
  table.sort(data, sort_func)
  
  for i=1, #data do
    local l = data[i].len
    reaper.SetMediaItemInfo_Value(data[i].item, "D_POSITION", pos)
    pos=pos+l
  end
  reaper.UpdateArrange()
  reaper.Undo_OnStateChangeEx("Sort items by length (ascending)", -1, -1)
end

sort_items_by_length()

end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------ORDER_RATE---------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 --[[
  * ReaScript Name: Sort selected items by pitch (ascending)
  * Description:    Sorts selected items from shortest to longest
  * Instructions:   - Select items
  *                 - Run the script
  * Screenshot: 
  * Notes: 
  * Category: 
  * Author: Mordi & spk77 , changed by dragonetti
  * Author URI:
  * Licence: GPL v3
  * Forum Thread: 
  * Forum Thread URL:
  * Version: 1.0
  * REAPER:
  * Extensions:
]]
 

--[[
 Changelog:
 * v1.0 (2016-06-26)
    + Changed script to only work on selected items.
]]
function order_rate()

ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
function get_item_lengths()
  local t={}
  for i=1, reaper.CountSelectedMediaItems(0) do
    t[i] = {}
    local item = reaper.GetSelectedMediaItem(0, i-1)
    if item ~= nil then 
  t[i].item = item  
  t[i].len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  take = reaper.GetActiveTake(item)
  t[i].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
  t[i].rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    end
  end
  return t
end

sort_func = function(a,b) -- https://forums.coronalabs.com/topic/37595-nested-sorting-on-multi-dimensional-array/
      if (a.rate < b.rate) then
        -- primary sort on length -> a before b
        return true
      end
    end
      
function sort_items_by_length()
  local data = get_item_lengths()
  if #data == 0 then return end
  local pos = reaper.GetMediaItemInfo_Value(data[1].item, "D_POSITION") -- get first item pos
  
  table.sort(data, sort_func)
  
  for i=1, #data do
    local l = data[i].len
    reaper.SetMediaItemInfo_Value(data[i].item, "D_POSITION", pos)
    pos=pos+l
  end
  reaper.UpdateArrange()
  reaper.Undo_OnStateChangeEx("Sort items by length (ascending)", -1, -1)
end

sort_items_by_length()
end
--==================================================================================================================
--============================== MIDI_RAND ===========================================================
--===================================================================================================================
function midi_rand()
--function Msg(variable)
--  reaper.ShowConsoleMsg(tostring(variable).."\n")
--end
reaper.Main_OnCommand(40006,0)
math.randomseed(os.time())
cursor = reaper.GetCursorPosition()          
bpm = reaper.TimeMap2_GetDividedBpmAtTime(0, cursor )
bar_length = 240/bpm
_, grid, save_swing, save_swing_amt = reaper.GetSetProjectGrid(0, false)
grid_length = bar_length*grid
note_quantity = 1/grid
bar_ppq = 3840
grid_ppq = 3840/note_quantity
accent = note_quantity/4
--velocity_rand = math.random(100,127)

random_anzahl = math.random(0,note_quantity-1)

rand1=math.random(0,random_anzahl)
rand2=math.random(0,random_anzahl)
rand3=math.random(0,random_anzahl)
rand4=math.random(0,random_anzahl)
rand5=math.random(0,random_anzahl)
rand6=math.random(0,random_anzahl)
rand7=math.random(0,random_anzahl)
rand8=math.random(0,random_anzahl)
rand9=math.random(0,random_anzahl)
rand10=math.random(0,random_anzahl)
velocity_values={126,100}
 velo = velocity_values[math.random(1,#velocity_values)] 

muted_table={false,true}
muted = muted_table[math.random(1,#muted_table)]
--function generate_midi()
for i=0, reaper.CountSelectedTracks(0) do
--velocity_rand = math.random(100,127)
track =  reaper.GetSelectedTrack2( 0, i, 0 )
if track == nil then
    return
    end

midiItem = reaper.CreateNewMIDIItemInProj(track, cursor,1)
reaper.SetMediaItemSelected(midiItem, true)
reaper.SetMediaItemInfo_Value(midiItem, "B_LOOPSRC",1)
midiTake = reaper.GetActiveTake(midiItem)
item_length=reaper.MIDI_GetProjTimeFromPPQPos( midiTake,cursor+bar_length) 
 reaper.SetMediaItemLength( midiItem,cursor+bar_length, true )
reaper.SetMediaItemInfo_Value( midiItem, "D_LENGTH", bar_length )



for var = 1,note_quantity
 do
if var == accent+1 then do
reaper.MIDI_InsertNote(midiTake, true,false, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 127)
end
elseif var == 2*accent+1 then do
reaper.MIDI_InsertNote(midiTake, true,false, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 127)
end
elseif var == 3*accent+1 then do
reaper.MIDI_InsertNote(midiTake, true,false, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 127)
end
elseif var == 4*accent+1 then do
reaper.MIDI_InsertNote(midiTake, true,false, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 127)
end 

elseif var == rand1  then do 
reaper.MIDI_InsertNote(midiTake, true,true, (var-1)*grid_ppq, grid_ppq*(var), 1, 60,100)
end
elseif var == rand2 then do 
reaper.MIDI_InsertNote(midiTake, true,true, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 100)
end
elseif var == rand3 then do
reaper.MIDI_InsertNote(midiTake, true,true, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 100)
end
elseif var == rand4 then do
reaper.MIDI_InsertNote(midiTake, true,true, (var-1)*grid_ppq, grid_ppq*(var), 1, 60,100)   
end 
elseif var == rand5 then do 
reaper.MIDI_InsertNote(midiTake, true,true, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 100)
end
elseif var == rand6 then do
reaper.MIDI_InsertNote(midiTake, true,true, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 100)
end
elseif var == rand7 then do
reaper.MIDI_InsertNote(midiTake, true,true, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 100)
end
elseif var == rand8 then do
reaper.MIDI_InsertNote(midiTake, true,true, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 100)
end
elseif var == rand9 then do
reaper.MIDI_InsertNote(midiTake, true,true, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 100)
end 
elseif var == rand10 then do
reaper.MIDI_InsertNote(midiTake, true,true, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 100)
end

else

reaper.MIDI_InsertNote(midiTake, true,false, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 100)

end


end
reaper.GetSetMediaItemTakeInfo_String(midiTake, 'P_NAME',72, true)

reaper.SetMediaItemInfo_Value(midiItem, 'I_CUSTOMCOLOR', reaper.ColorToNative(201,3,57)|0x1000000  )



--Msg(note_quantity)

end
end

--==================================================================================================================
--============================== MIDI_RAND 2===========================================================
--===================================================================================================================
function midi_rand2()
--function Msg(variable)
-- reaper.ShowConsoleMsg(tostring(variable).."\n")
--end

reaper.Main_OnCommand(40006,0) --delete selected items

cursor = reaper.GetCursorPosition() 
start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false) 

bpm = reaper.TimeMap2_GetDividedBpmAtTime(0, cursor )
bar_length = 240/bpm
_, grid, save_swing, save_swing_amt = reaper.GetSetProjectGrid(0, false)

grid_length = bar_length*grid
note_quantity = 1/grid
qn = note_quantity/4
bar_ppq = 3840 
grid_ppq = 3840/note_quantity
accent = note_quantity/4

factor = {1,2,3,4,1,1}


n1 = grid_ppq*factor[math.random(1,#factor)]
n2 = grid_ppq*factor[math.random(1,#factor)]
n3 = grid_ppq*factor[math.random(1,#factor)]
n4 = grid_ppq*factor[math.random(1,#factor)] 
n5 = grid_ppq*factor[math.random(1,#factor)]
n6 = grid_ppq*factor[math.random(1,#factor)]
n7 = grid_ppq*factor[math.random(1,#factor)]
n8 = grid_ppq*factor[math.random(1,#factor)]
n9 = grid_ppq*factor[math.random(1,#factor)]
n10 = grid_ppq*factor[math.random(1,#factor)]

s1 = n1/grid_ppq*grid_length
s2 = n2/grid_ppq*grid_length
s3 = n3/grid_ppq*grid_length
s4 = n4/grid_ppq*grid_length
s5 = n5/grid_ppq*grid_length
s6 = n6/grid_ppq*grid_length
s7 = n7/grid_ppq*grid_length
s8 = n8/grid_ppq*grid_length
s9 = n9/grid_ppq*grid_length
s10 = n10/grid_ppq*grid_length

velo = {80,90,110,120}

v1 = velo[math.random(1,#velo)]
v2 = velo[math.random(1,#velo)]
v3 = velo[math.random(1,#velo)]
v4 = velo[math.random(1,#velo)]
v5 = velo[math.random(1,#velo)]
v6 = velo[math.random(1,#velo)]
v7 = velo[math.random(1,#velo)]
v8 = velo[math.random(1,#velo)]
v9 = velo[math.random(1,#velo)]
v10 = velo[math.random(1,#velo)]


velocity_values={126,100}
velo = velocity_values[math.random(1,#velocity_values)] 

muted_table={false,true}
muted = muted_table[math.random(1,#muted_table)]

for i=0, reaper.CountSelectedTracks(0) do   
track =  reaper.GetSelectedTrack2( 0, i, 0 )  
if track == nil then
    return
    end 
    
midiItem1 = reaper.CreateNewMIDIItemInProj(track, cursor,1)
reaper.SetMediaItemSelected(midiItem1, true)
reaper.SetMediaItemInfo_Value(midiItem1, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem1, "D_LENGTH", s1 ) 
midiTake1 = reaper.GetActiveTake(midiItem1)
reaper.MIDI_InsertNote(midiTake1, true,muted, 0,n1, 1, 60, v1)
reaper.SetMediaItemSelected(midiItem1, true)

midiItem2 = reaper.CreateNewMIDIItemInProj(track,cursor+s1,1)
reaper.SetMediaItemSelected(midiItem2, true)
reaper.SetMediaItemInfo_Value(midiItem2, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem2, "D_LENGTH", s2 ) 
midiTake2 = reaper.GetActiveTake(midiItem2)
reaper.MIDI_InsertNote(midiTake2, true,false, 0,n2, 1, 60, v2)
reaper.SetMediaItemSelected(midiItem2, true)

midiItem3 = reaper.CreateNewMIDIItemInProj(track,cursor+s1+s2,1)
reaper.SetMediaItemSelected(midiItem3, true)
reaper.SetMediaItemInfo_Value(midiItem3, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem3, "D_LENGTH", s3 ) 
midiTake3 = reaper.GetActiveTake(midiItem3)
reaper.MIDI_InsertNote(midiTake3, true,false, 0,n3, 1, 60, v3)
reaper.SetMediaItemSelected(midiItem3, true)

midiItem4 = reaper.CreateNewMIDIItemInProj(track,cursor+s1+s2+s3,1)
reaper.SetMediaItemSelected(midiItem4, true)
reaper.SetMediaItemInfo_Value(midiItem4, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem4, "D_LENGTH", s4 ) 
midiTake4 = reaper.GetActiveTake(midiItem4)
reaper.MIDI_InsertNote(midiTake4, true,false, 0,n4, 1, 60, v4)
reaper.SetMediaItemSelected(midiItem4, true)

midiItem5 = reaper.CreateNewMIDIItemInProj(track,cursor+s1+s2+s3+s4,1)
reaper.SetMediaItemSelected(midiItem5, true)
reaper.SetMediaItemInfo_Value(midiItem5, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem5, "D_LENGTH", s5 ) 
midiTake5 = reaper.GetActiveTake(midiItem5)
reaper.MIDI_InsertNote(midiTake5, true,false, 0,n5, 1, 60, v5)
reaper.SetMediaItemSelected(midiItem5, true)

midiItem6 = reaper.CreateNewMIDIItemInProj(track,cursor+s1+s2+s3+s4+s5,1)
reaper.SetMediaItemSelected(midiItem6, true)
reaper.SetMediaItemInfo_Value(midiItem6, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem6, "D_LENGTH", s6 ) 
midiTake6 = reaper.GetActiveTake(midiItem6)
reaper.MIDI_InsertNote(midiTake6, true,false, 0,n6, 1, 60, v6)
reaper.SetMediaItemSelected(midiItem6, true)

midiItem7 = reaper.CreateNewMIDIItemInProj(track,cursor+s1+s2+s3+s4+s5+s6,1)
reaper.SetMediaItemSelected(midiItem7, true)
reaper.SetMediaItemInfo_Value(midiItem7, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem7, "D_LENGTH", s7 )  
midiTake7 = reaper.GetActiveTake(midiItem7)
reaper.MIDI_InsertNote(midiTake7, true,false, 0,n7, 1, 60, v7)
reaper.SetMediaItemSelected(midiItem7, true)

midiItem8 = reaper.CreateNewMIDIItemInProj(track,cursor+s1+s2+s3+s4+s5+s6+s7,1)
reaper.SetMediaItemSelected(midiItem8, true)
reaper.SetMediaItemInfo_Value(midiItem8, "B_LOOPSRC",1) 
reaper.SetMediaItemInfo_Value( midiItem8, "D_LENGTH", s8 ) 
midiTake8 = reaper.GetActiveTake(midiItem8)
midiTake8 = reaper.GetActiveTake(midiItem8)
reaper.MIDI_InsertNote(midiTake8, true,false, 0,n8, 1, 60, v8)
reaper.SetMediaItemSelected(midiItem8, true)

midiItem9 = reaper.CreateNewMIDIItemInProj(track,cursor+s1+s2+s3+s4+s5+s6+s7+s8,1)
reaper.SetMediaItemSelected(midiItem9, true)
reaper.SetMediaItemInfo_Value(midiItem9, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem9, "D_LENGTH", s9 ) 
midiTake9 = reaper.GetActiveTake(midiItem9)
reaper.MIDI_InsertNote(midiTake9, true,false, 0,n9, 1, 60, v9)
reaper.SetMediaItemSelected(midiItem9, true)

midiItem10 = reaper.CreateNewMIDIItemInProj(track,cursor+s1+s2+s3+s4+s5+s6+s7+s8+s9,1)
reaper.SetMediaItemSelected(midiItem10, true)
reaper.SetMediaItemInfo_Value(midiItem10, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem10, "D_LENGTH", s10 ) 
midiTake10 = reaper.GetActiveTake(midiItem10)
reaper.MIDI_InsertNote(midiTake10, true,false, 0,n10, 1, 60, v10)
reaper.SetMediaItemSelected(midiItem10, true)


end
 
end
--==================================================================================================================
--============================== MIDI_PATTERN 3===========================================================
--===================================================================================================================
function midi_pattern3()
function midi_pattern()
function Msg(variable)
 reaper.ShowConsoleMsg(tostring(variable).."\n")
end



reaper.Main_OnCommand(40289,0) -- unselect all items
reaper.Main_OnCommand(40718,0) -- Item: Select all items on selected tracks in current time selection
reaper.Main_OnCommand(40006,0) -- Item: Remove items

cursor = reaper.GetCursorPosition() 
start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false) 
 
bpm = reaper.TimeMap2_GetDividedBpmAtTime(0, cursor )
bar_length = 240/bpm
_, grid, save_swing, save_swing_amt = reaper.GetSetProjectGrid(0, false)

grid_length = bar_length*grid 
note_quantity = 1/grid
qn = note_quantity/4
bar_ppq = 3840 
grid_ppq = 3840/note_quantity
accent = note_quantity/4  
retval, rhy = reaper.GetUserInputs( "16 notes", 1,"seq(1-16)  1=1grid  2=2grid  etc.", "1111111111111111" )

Table_Rhy = {string.sub(rhy,1,1),string.sub(rhy,2,2),string.sub(rhy,3,3),string.sub(rhy,4,4),string.sub(rhy,5,5)
,string.sub(rhy,6,6),string.sub(rhy,7,7),string.sub(rhy,8,8),string.sub(rhy,9,9),string.sub(rhy,10,10),string.sub(rhy,11,11)
,string.sub(rhy,12,12),string.sub(rhy,13,13),string.sub(rhy,14,14),string.sub(rhy,15,15),string.sub(rhy,16,16)}



rhy1a ="rhy"..tostring(Table_Rhy[1])
rhy2a ="rhy"..tostring(Table_Rhy[2])
rhy3a ="rhy"..tostring(Table_Rhy[3])
rhy4a ="rhy"..tostring(Table_Rhy[4])
rhy5a ="rhy"..tostring(Table_Rhy[5])
rhy6a ="rhy"..tostring(Table_Rhy[6])
rhy7a ="rhy"..tostring(Table_Rhy[7])
rhy8a ="rhy"..tostring(Table_Rhy[8])
rhy9a ="rhy"..tostring(Table_Rhy[9])
rhy10a ="rhy"..tostring(Table_Rhy[10])
rhy11a ="rhy"..tostring(Table_Rhy[11])
rhy12a ="rhy"..tostring(Table_Rhy[12])
rhy13a ="rhy"..tostring(Table_Rhy[13])
rhy14a ="rhy"..tostring(Table_Rhy[14])
rhy15a ="rhy"..tostring(Table_Rhy[15])
rhy16a ="rhy"..tostring(Table_Rhy[16])

rhy0=2
rhy9=grid_ppq*9
rhy8=grid_ppq*8
rhy7=grid_ppq*7
rhy6=grid_ppq*6
rhy5=grid_ppq*5
rhy4=grid_ppq*4
rhy3=grid_ppq*3
rhy2=grid_ppq*2
rhy1=grid_ppq*1

rhy=99





n1 = _G[rhy1a]
n2 = _G[rhy2a]
n3 = _G[rhy3a]
n4 = _G[rhy4a]
n5 = _G[rhy5a]
n6 = _G[rhy6a]
n7 = _G[rhy7a]
n8 = _G[rhy8a]
n9 = _G[rhy9a]
n10 = _G[rhy10a]
n11 = _G[rhy11a]
n12 = _G[rhy12a]
n13 = _G[rhy13a]
n14 = _G[rhy14a]
n15 = _G[rhy15a]
n16 = _G[rhy16a]

m1=false
m2=false
m3=false
m4=false
m5=false
m6=false
m7=false
m8=false
m9=false
m10=false
m11=false
m12=false
m13=false
m14=false
m15=false
m16=false

if n1==2 then  m1=true n1=grid_ppq end
if n2==2 then  m2=true n2=grid_ppq end
if n3==2 then  m3=true n3=grid_ppq end
if n4==2 then  m4=true n4=grid_ppq end
if n5==2 then  m5=true n5=grid_ppq end 
if n6==2 then  m6=true n6=grid_ppq end
if n7==2 then  m7=true n7=grid_ppq end
if n8==2 then  m8=true n8=grid_ppq end
if n9==2 then  m9=true n9=grid_ppq end
if n10==2 then m10=true n10=grid_ppq end
if n11==2 then m11=true n11=grid_ppq end
if n12==2 then m12=true n12=grid_ppq end
if n13==2 then m13=true n13=grid_ppq end
if n14==2 then m14=true n14=grid_ppq end
if n15==2 then m15=true n15=grid_ppq end
if n16==2 then m16=true n16=grid_ppq end



if n2==99 then  n2=n1 n3=n1 n4=n1 n5=n1 n6=n1 n7=n1 n8=n1  n9=n1 n10=n1  n11=n1 n12=n1 n13=n1  n14=n1 n15=n1  n16=n1 
                m2=m1 m3=m1 m3=m1 m4=m1 m5=m1 m6=m1 m7=m1 m8=m1 m9=m1 m10=m1 m11=m1 m12=m1 m13=m1 m14=m1 m15=m1 m16=m1 end
if n3==99 then  n3=n1 n4=n2 n5=n1 n6=n2 n7=n1 n8=n2 n9=n1 n10=n2  n11=n1 n12=n2 n13=n1  n14=n2 n15=n1  n16=n2 
                m3=m1 m4=m2 m5=m1 m6=m2 m7=m1 m8=m2 m9=m1 m10=m2 m11=m1 m12=m2 m13=m1 m14=m2 m15=m1 m16=m2 end
if n4==99 then  n4=n1 n5=n2 n6=n3 n7=n1 n8=n2 n9=n3 n10=n1 n11=n2 n12=n3 n13=n1 n14=n2 n15=n3  n16=n1 
                m4=m1 m5=m2 m6=m3 m7=m1 m8=m2 m9=m3 m10=m1 m11=m2 m12=m3 m13=m1 m14=m2 m15=m3 m16=m1 end
if n5==99 then  n5=n1 n6=n2 n7=n3 n8=n4 n9=n1 n10=n2 n11=n3 n12=n4 n13=n1 n14=n2 n15=n3 n16=n4 
                m5=m1 m6=m2 m7=m3 m8=m4 m9=m1 m10=m2 m11=m3 m12=m4 m13=m1 m14=m2 m15=m3 m16=m4 end
if n6==99 then  n6=n1 n7=n2 n8=n3 n9=n4 n10=n5 n11=n1 n12=n2 n13=n3 n14=n4 n15=n5 n16=n1 
                m6=m1 m7=m2 m8=m3 m9=m4 m10=m5 m11=m1 m12=m2 m13=m3 m14=m4 m15=m5 m16=m1 end
if n7==99 then  n7=n1 n8=n2 n9=n3 n10=n4 n11=n5 n12=n6 n13=n1 n14=n2 n15=n3 n16=n4 
                m7=m1 m8=m2 m9=m3 m10=m4 m11=m5 m12=m6 m13=m1 m14=m2 m15=m3 m16=m4 end
if n8==99 then  n8=n1 n9=n2 n10=n3 n11=n4 n12=n5 n13=n6 n14=n7 n15=n1 n16=n2 
                m8=m1 m9=m2 m10=m3 m11=m4 m12=m5 m13=m6 m14=m7 m15=m1 m16=m2 end
if n9==99 then  n9=n1 n10=n2 n11=n3 n12=n4 n13=n5 n14=n6 n15=n7 n16=n8 
                m9=m1 m10=m2 m11=m3 m12=m4 m13=m5 m14=m6 m15=m7 m16=m8 end
if n10==99 then n10=n1 n11=n2 n12=n3 n13=n4 n14=n5 n15=n6 n16=n7 
                m10=m1 m11=m2 m12=m3 m13=m4 m14=m5 m15=m6 m16=m7 end
if n11==99 then n11=n1 n12=n2 n13=n3 n14=n4 n15=n5 n16=n6 
                m11=m1 m12=m2 m13=m3 m14=m4 m15=m5 m16=m6 end
if n12==99 then n12=n1 n13=n2 n14=n3 n15=n4 n16=n5 
                m12=m1 m13=m2 m14=m3 m15=m4 m16=m5 end
if n13==99 then n13=n1 n14=n2 n15=n3 n16=n4 
                m13=m1 m14=m2 m15=m3 m16=m4 end
if n14==99 then n14=n1 n15=n2 n16=n3 
                m14=m1 m15=m2 m16=m3 end
if n15==99 then n15=n1 n16=n2 
                m15=m1 m16=m2 end
if n16==99 then n16=n1 
                m16=m1 end


s1 = n1/grid_ppq*grid_length
s2 = n2/grid_ppq*grid_length
s3 = n3/grid_ppq*grid_length
s4 = n4/grid_ppq*grid_length
s5 = n5/grid_ppq*grid_length
s6 = n6/grid_ppq*grid_length
s7 = n7/grid_ppq*grid_length
s8 = n8/grid_ppq*grid_length
s9 = n9/grid_ppq*grid_length
s10 = n10/grid_ppq*grid_length
s11 = n11/grid_ppq*grid_length
s12 = n12/grid_ppq*grid_length
s13 = n13/grid_ppq*grid_length
s14 = n14/grid_ppq*grid_length
s15 = n15/grid_ppq*grid_length
s16 = n16/grid_ppq*grid_length

velo = {80,90,110,120}

v1 = velo[math.random(1,#velo)]
v2 = velo[math.random(1,#velo)]
v3 = velo[math.random(1,#velo)]
v4 = velo[math.random(1,#velo)]
v5 = velo[math.random(1,#velo)]
v6 = velo[math.random(1,#velo)]
v7 = velo[math.random(1,#velo)]
v8 = velo[math.random(1,#velo)]
v9 = velo[math.random(1,#velo)]
v10 = velo[math.random(1,#velo)]
v11 = velo[math.random(1,#velo)]
v12 = velo[math.random(1,#velo)]
v13 = velo[math.random(1,#velo)]
v14 = velo[math.random(1,#velo)]
v15 = velo[math.random(1,#velo)]
v16 = velo[math.random(1,#velo)]


velocity_values={126,100}
velo = velocity_values[math.random(1,#velocity_values)] 

for i=0, reaper.CountSelectedTracks(0) do   
track =  reaper.GetSelectedTrack2( 0, i, 0 )  
if track == nil then
    return
    end 

midiItem1 = reaper.CreateNewMIDIItemInProj(track, start_time,1)
reaper.SetMediaItemSelected(midiItem1, true)
reaper.SetMediaItemInfo_Value(midiItem1, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem1, "D_LENGTH", s1 ) 
midiTake1 = reaper.GetActiveTake(midiItem1)
reaper.MIDI_InsertNote(midiTake1, true,m1, 0,n1, 1, 60, v1)
reaper.SetMediaItemSelected(midiItem1, true)

midiItem2 = reaper.CreateNewMIDIItemInProj(track,start_time+s1,1)
reaper.SetMediaItemSelected(midiItem2, true)
reaper.SetMediaItemInfo_Value(midiItem2, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem2, "D_LENGTH", s2 ) 
midiTake2 = reaper.GetActiveTake(midiItem2)
reaper.MIDI_InsertNote(midiTake2, true,m2, 0,n2, 1, 60, v2)
reaper.SetMediaItemSelected(midiItem2, true)

midiItem3 = reaper.CreateNewMIDIItemInProj(track,start_time+s1+s2,1)
reaper.SetMediaItemSelected(midiItem3, true)
reaper.SetMediaItemInfo_Value(midiItem3, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem3, "D_LENGTH", s3 ) 
midiTake3 = reaper.GetActiveTake(midiItem3)
reaper.MIDI_InsertNote(midiTake3, true,m3, 0,n3, 1, 60, v3)
reaper.SetMediaItemSelected(midiItem3, true)

midiItem4 = reaper.CreateNewMIDIItemInProj(track,start_time+s1+s2+s3,1)
reaper.SetMediaItemSelected(midiItem4, true)
reaper.SetMediaItemInfo_Value(midiItem4, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem4, "D_LENGTH", s4 ) 
midiTake4 = reaper.GetActiveTake(midiItem4)
reaper.MIDI_InsertNote(midiTake4, true,m4, 0,n4, 1, 60, v4)
reaper.SetMediaItemSelected(midiItem4, true)

midiItem5 = reaper.CreateNewMIDIItemInProj(track,start_time+s1+s2+s3+s4,1)
reaper.SetMediaItemSelected(midiItem5, true)
reaper.SetMediaItemInfo_Value(midiItem5, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem5, "D_LENGTH", s5 ) 
midiTake5 = reaper.GetActiveTake(midiItem5)
reaper.MIDI_InsertNote(midiTake5, true,m5, 0,n5, 1, 60, v5)
reaper.SetMediaItemSelected(midiItem5, true)

midiItem6 = reaper.CreateNewMIDIItemInProj(track,start_time+s1+s2+s3+s4+s5,1)
reaper.SetMediaItemSelected(midiItem6, true)
reaper.SetMediaItemInfo_Value(midiItem6, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem6, "D_LENGTH", s6 ) 
midiTake6 = reaper.GetActiveTake(midiItem6)
reaper.MIDI_InsertNote(midiTake6, true,m6, 0,n6, 1, 60, v6)
reaper.SetMediaItemSelected(midiItem6, true)

midiItem7 = reaper.CreateNewMIDIItemInProj(track,start_time+s1+s2+s3+s4+s5+s6,1)
reaper.SetMediaItemSelected(midiItem7, true)
reaper.SetMediaItemInfo_Value(midiItem7, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem7, "D_LENGTH", s7 )  
midiTake7 = reaper.GetActiveTake(midiItem7)
reaper.MIDI_InsertNote(midiTake7, true,m7, 0,n7, 1, 60, v7)
reaper.SetMediaItemSelected(midiItem7, true)

midiItem8 = reaper.CreateNewMIDIItemInProj(track,start_time+s1+s2+s3+s4+s5+s6+s7,1)
reaper.SetMediaItemSelected(midiItem8, true)
reaper.SetMediaItemInfo_Value(midiItem8, "B_LOOPSRC",1) 
reaper.SetMediaItemInfo_Value( midiItem8, "D_LENGTH", s8 ) 
midiTake8 = reaper.GetActiveTake(midiItem8)
midiTake8 = reaper.GetActiveTake(midiItem8)
reaper.MIDI_InsertNote(midiTake8, true,m8, 0,n8, 1, 60, v8)
reaper.SetMediaItemSelected(midiItem8, true)

midiItem9 = reaper.CreateNewMIDIItemInProj(track,start_time+s1+s2+s3+s4+s5+s6+s7+s8,1)
reaper.SetMediaItemSelected(midiItem9, true)
reaper.SetMediaItemInfo_Value(midiItem9, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem9, "D_LENGTH", s9 ) 
midiTake9 = reaper.GetActiveTake(midiItem9)
reaper.MIDI_InsertNote(midiTake9, true,m9, 0,n9, 1, 60, v9)
reaper.SetMediaItemSelected(midiItem9, true)

midiItem10 = reaper.CreateNewMIDIItemInProj(track,start_time+s1+s2+s3+s4+s5+s6+s7+s8+s9,1)
reaper.SetMediaItemSelected(midiItem10, true)
reaper.SetMediaItemInfo_Value(midiItem10, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem10, "D_LENGTH", s10 ) 
midiTake10 = reaper.GetActiveTake(midiItem10)
reaper.MIDI_InsertNote(midiTake10, true,m10, 0,n10, 1, 60, v10)
reaper.SetMediaItemSelected(midiItem10, true)

midiItem11 = reaper.CreateNewMIDIItemInProj(track,start_time+s1+s2+s3+s4+s5+s6+s7+s8+s9+s10,1)
reaper.SetMediaItemSelected(midiItem11, true)
reaper.SetMediaItemInfo_Value(midiItem11, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem11, "D_LENGTH", s11 ) 
midiTake11 = reaper.GetActiveTake(midiItem11)
reaper.MIDI_InsertNote(midiTake11, true,m11, 0,n11, 1, 60, v11)
reaper.SetMediaItemSelected(midiItem11, true)

midiItem12 = reaper.CreateNewMIDIItemInProj(track,start_time+s1+s2+s3+s4+s5+s6+s7+s8+s9+s10+s11,1)
reaper.SetMediaItemSelected(midiItem12, true)
reaper.SetMediaItemInfo_Value(midiItem12, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem12, "D_LENGTH", s12 ) 
midiTake12 = reaper.GetActiveTake(midiItem12)
reaper.MIDI_InsertNote(midiTake12, true,m12, 0,n12, 1, 60, v12)
reaper.SetMediaItemSelected(midiItem12, true)

midiItem13 = reaper.CreateNewMIDIItemInProj(track,start_time+s1+s2+s3+s4+s5+s6+s7+s8+s9+s10+s11+s12,1)
reaper.SetMediaItemSelected(midiItem13, true)
reaper.SetMediaItemInfo_Value(midiItem13, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem13, "D_LENGTH", s13 ) 
midiTake13 = reaper.GetActiveTake(midiItem13)
reaper.MIDI_InsertNote(midiTake13, true,m13, 0,n13, 1, 60, v13)
reaper.SetMediaItemSelected(midiItem13, true)

midiItem14 = reaper.CreateNewMIDIItemInProj(track,start_time+s1+s2+s3+s4+s5+s6+s7+s8+s9+s10+s11+s12+s13,1)
reaper.SetMediaItemSelected(midiItem14, true)
reaper.SetMediaItemInfo_Value(midiItem14, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem14, "D_LENGTH", s14 ) 
midiTake14 = reaper.GetActiveTake(midiItem14)
reaper.MIDI_InsertNote(midiTake14, true,m14, 0,n14, 1, 60, v14)
reaper.SetMediaItemSelected(midiItem14, true)

midiItem15 = reaper.CreateNewMIDIItemInProj(track,start_time+s1+s2+s3+s4+s5+s6+s7+s8+s9+s10+s11+s12+s13+s14,1)
reaper.SetMediaItemSelected(midiItem15, true)
reaper.SetMediaItemInfo_Value(midiItem15, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem15, "D_LENGTH", s15 ) 
midiTake15 = reaper.GetActiveTake(midiItem15)
reaper.MIDI_InsertNote(midiTake15, true,m15, 0,n15, 1, 60, v15)
reaper.SetMediaItemSelected(midiItem15, true)


midiItem16 = reaper.CreateNewMIDIItemInProj(track,start_time+s1+s2+s3+s4+s5+s6+s7+s8+s9+s10+s11+s12+s13+s14+s15,1)
reaper.SetMediaItemSelected(midiItem16, true)
reaper.SetMediaItemInfo_Value(midiItem16, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem16, "D_LENGTH", s16 ) 
midiTake16 = reaper.GetActiveTake(midiItem16)
reaper.MIDI_InsertNote(midiTake16, true,m16, 0,n16, 1, 60, v16)
reaper.SetMediaItemSelected(midiItem16, true)

end
end

-- mpl Script: mpl_Duplicate items until end of time selection.lua

function fill_ST()    -- get source length
      local items_t = {}
      local bound_st, bound_end = math.huge, -math.huge
      for selitem =1,  reaper.CountSelectedMediaItems( 0 )/reaper.CountSelectedTracks( 0 ) do
        local itemx = reaper.GetSelectedMediaItem( 0, selitem-1 )
        items_t[#items_t+1] = itemx
        local posx = reaper.GetMediaItemInfo_Value( itemx, 'D_POSITION' )
        local lenx = reaper.GetMediaItemInfo_Value( itemx, 'D_LENGTH' )
        bound_st = math.min(bound_st, posx)
        bound_end = math.max(bound_end, posx+lenx) 
      end
      local bound_len = bound_end - bound_st-10^-14
      if bound_len > 10^15 then return end
      
    -- get duplicates count
      local copies = (math.floor((end_time - bound_st) / bound_len)-1)+1
     
    if copies >= 0 then do
    -- share duplicates
      reaper.ApplyNudge( 0,--project, 
                  0,--nudgeflag, 
                  5,--nudgewhat, 
                  21,--nudgeunits, 
                  1,--value, 
                  0,--reverse, 
                  copies)--copies )) 
                  
end
end     
       
end   

    
midi_pattern()
fill_ST()
-- @description Unselect items not within time selection
-- @author Edgemeal
-- @version 1.0
-- @link Forum https://forum.cockos.com/showthread.php?t=223042
-- @about Only a part of an item needs to be within the time selection

local s_time, e_time = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
if s_time == e_time then return end

function ItemInTime(item)
  local s = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
  local e = s + reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
  if e > s_time and e < e_time then return false end
  if s < e_time and e < e_time then return false end
  return true
end

reaper.Undo_BeginBlock(0)
local item_count = reaper.CountSelectedMediaItems(0)
for i = item_count-1, 0, -1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  reaper.SetMediaItemSelected(item, ItemInTime(item))
end
reaper.Undo_EndBlock('Unselect items not within time selection', -1)
reaper.UpdateArrange()

reaper.Main_OnCommand(40006,0) -- remove items
reaper.Main_OnCommand(40718,0) -- Item: Select all items on selected tracks in current time selection
end
--============================================================================================================================
--======================================= DETECT_MIDI_CHORDS =================================================================
--============================================================================================================================
-- Notation Events Chords to Regions
-- juliansader https://forum.cockos.com/member.php?u=14710
function detect_midi_chords()
function CreateTextItem(track, position, length, text, color)

  local item = reaper.AddMediaItemToTrack(track)

  reaper.SetMediaItemInfo_Value(item, "D_POSITION", position)
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)

  if text ~= nil then
    reaper.ULT_SetMediaItemNote(item, text)
  end

  if color ~= nil then
    reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)
  end

  return item

end


function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)

    if ok and trackName == name then
      return track -- found it! stopping the search here
    end
  end
end

 ctrack = getTrackByName("chordtrack")
 if ctrack == nil then 
 
-- create chordtrack 
create_track = reaper.NamedCommandLookup("_SWS_CREATETRK1")
reaper.Main_OnCommand(create_track,0)
 ctrack = reaper.GetTrack( 0, 0 )
 reaper.GetSetMediaTrackInfo_String(ctrack, 'P_NAME', 'chordtrack', true)
 reaper.SetMediaTrackInfo_Value( ctrack, "I_WNDH", 50 )
 reaper.SetMediaTrackInfo_Value(ctrack, "I_HEIGHTOVERRIDE", 32)
 reaper.SetMediaTrackInfo_Value(ctrack, "B_HEIGHTLOCK", 1)
 reaper.SetMediaTrackInfo_Value( ctrack, "I_RECARM", 1 )
 reaper.SetMediaTrackInfo_Value( ctrack, "I_RECINPUT", 4096 | 0 | (62 << 5) )
 color = reaper.ColorToNative(95,175,178)
 reaper.SetTrackColor(ctrack, color)

end 
 
reaper.Undo_BeginBlock2(0)
reaper.Main_OnCommand(40644,0)
reaper.Main_OnCommand(42432,0)
--reaper.Main_OnCommand(40421,0) --Item: Select all items in track 40421
sel_item =  reaper.GetSelectedMediaItem( 0, 0 )
--if not sel_item then reaper.MB("Selct Item", "Attention",0) end
if not sel_item then return end
item_length = reaper.GetMediaItemInfo_Value( sel_item, "D_LENGTH" )
item_pos = reaper.GetMediaItemInfo_Value( sel_item, "D_POSITION" )
end_pos = item_pos + item_length
reaper.Main_OnCommand(40153,0) --Item: Open in built-in MIDI editor (set default behavior in preferences) 40153
hwnd = reaper.MIDIEditor_GetActive()
--reaper.MIDIEditor_OnCommand( hwnd, 40954 ) --Mode: Notation3
reaper.MIDIEditor_OnCommand( hwnd, 41281 ) --Notation: Identify chords on editor grid

reaper.SN_FocusMIDIEditor()
reaper.MIDIEditor_OnCommand(40954,0) --Mode: Notation3
reaper.MIDIEditor_OnCommand(41281,0) --Notation: Identify chords on editor grid

  
take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
reaper.MIDI_Sort(take)
MIDIOK, MIDI = reaper.MIDI_GetAllEvts(take, "")
tChords = {}
stringPos, ticks = 1, 0
while stringPos < MIDI:len() do
    offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDI, stringPos)
    ticks = ticks + offset
    if msg:byte(1) == 0xFF then
    chord = msg:match("text (.+)")
    if chord then
    tChords[#tChords+1] = {chord = chord, ticks = ticks}
    end
    end
end
midi_note_end = 0
_, notecnt = reaper.MIDI_CountEvts( take )
for i = 1, notecnt do
  local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( take, i-1 )

  if endppqpos > midi_note_end then
   midi_note_end = endppqpos
  end
end
midi_note_end_time = reaper.MIDI_GetProjTimeFromPPQPos( take, midi_note_end )


tChords[#tChords+1] = {ticks = ticks}
for i = 1, #tChords do
    tChords[i].time = reaper.MIDI_GetProjTimeFromPPQPos(take, tChords[i].ticks)
end
for i = 1, #tChords-1 do
    -- Set Region Color RGB > reaper.ColorToNative(55,118,235)
  if tChords[i].chord ~= last_chord then
   chord_name = tChords[i].chord
   if chord_name == "C6" then chord_name = "Am" end
   if chord_name == "C#6" then chord_name = "A#m" end
   if chord_name == "D6" then chord_name = "Bm" end
  if chord_name == "D#6" then chord_name = "Cm" end
   if chord_name == "E6" then chord_name = "C#m" end
   if chord_name == "F6" then chord_name = "Dm" end
   if chord_name == "F#6" then chord_name = "D#m" end
   if chord_name == "G6" then chord_name = "Em" end
   if chord_name == "G#6" then chord_name = "Fm" end
   if chord_name == "A6" then chord_name = "F#m" end
  if chord_name == "A#6" then chord_name = "Gm" end
   if chord_name == "B6" then chord_name = "G#m" end
   
   time_end = tChords[i+1].time
   
   if tChords[i+1].time > midi_note_end_time then time_end = midi_note_end_time end
   
   CreateTextItem(ctrack,tChords[i].time,time_end - tChords[i].time,chord_name)
   
   last_chord = tChords[i].chord
    end
end     


commandID2 = reaper.NamedCommandLookup("_SWSMARKERLIST13")
--reaper.Main_OnCommand(commandID2, 0) -- SWS: Convert markers to regions
reaper.Undo_EndBlock2(0, "Chords from midi item", -1)
reaper.MIDIEditor_OnCommand( hwnd, 2 ) --File: Close window
end

-- =================================================================================
--============================== REVERSE_ITEMS ======================================
--=====================================================================================

function reverse_items()

reverse_item = reaper.NamedCommandLookup("_XENAKIOS_REVORDSELITEMS")

reaper.Main_OnCommand(reverse_item,0)  -- reverse item

-- Xenakios/SWS: Reposition selected items.
-- Convert to Lua from SWS C++


function GetSelectedMediaItemsOnTrack(tr)
  items = {}
  for j = 0, reaper.GetTrackNumMediaItems(tr)-1 do
    local item = reaper.GetTrackMediaItem(tr, j)
    if reaper.GetMediaItemInfo_Value(item, "B_UISEL") == 1 then items[#items+1] = item end
  end
  return items
end

function main()


  bEnd = true   -- Start = false, End = true

  for i = 0, reaper.CountTracks(0)-1 do
    track = reaper.CSurf_TrackFromID(i + 1, false)
    items = GetSelectedMediaItemsOnTrack(track)
    for j = 2, #items do
      dPrevItemStart = reaper.GetMediaItemInfo_Value(items[j-1], "D_POSITION")
      dNewPos = dPrevItemStart 
      if (bEnd) then
        dNewPos = dNewPos + reaper.GetMediaItemInfo_Value(items[j-1], "D_LENGTH")
      end
      reaper.SetMediaItemInfo_Value(items[j], "D_POSITION", dNewPos)
    end
  end
end

main()

end

--================================================================================================================================
--======================================== CREATE_REGION =========================================================================
--================================================================================================================================
-- @description Rename region at edit cursor after the first selected item
-- @author amagalma
-- @version 1.00
-- @link https://forum.cockos.com/showpost.php?p=2358410&postcount=20
-- @donation https://www.paypal.me/amagalma
function create_region()
reaper.Main_OnCommand(40348,0)
reaper.Main_OnCommand(40318,0)


local msg = "Please, select an item "

local item = reaper.GetSelectedMediaItem( 0, 0 )
if not item then
  reaper.MB( msg, "No item selected!", 0 )
  return
end

local _, rg_idx = reaper.GetLastMarkerAndCurRegion( 0,  reaper.GetCursorPositionEx( 0 ) )
if rg_idx == -1 then
  reaper.MB( msg, "Edit cursor not inside a region!", 0 )
  return
end

local it_name
local take = reaper.GetActiveTake( item )
if take then
  it_name = reaper.GetTakeName( take )
else
  it_name = ({reaper.GetSetMediaItemInfo_String( item, "P_NOTES", "", false )})[2]
end
local _, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, rg_idx )
--if name == it_name then return end
col_blu = reaper.ColorToNative(55,55, 55)|0x1000000
local ok = reaper.SetProjectMarker4( 0, markrgnindexnumber, isrgn, pos, rgnend, "",col_blu, 0)
if ok then
  reaper.Undo_OnStateChangeEx2( 0, "Name region after selected item", 8, -1 )
end
reaper.Main_OnCommand(40616,0)
end

--========================================================================================================================
--==================================== chordsymbol_trans_up ====================================================================
--========================================================================================================================
function chordsymbol_trans_up()

       function Msg(m)                         --  function: console output alias for debugging
     reaper.ShowConsoleMsg(tostring(m) .. '\n')
       end
    
   
   function getTrackByName(name)
     for trackIndex = 0, reaper.CountTracks(0) - 1 do
        tracko = reaper.GetTrack(0, trackIndex)
       local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)
   
       if ok and trackName == name then
         return tracko -- found it! stopping the search here
       end 
     end
   end  
   
   
   function chord_up(item_notes)
     chord, p = nil, 0
     root, chord = string.match(item_notes, "(%w[#b]?)(.*)$")
     switches = string.match( item_notes, "-%a.*")
     
     if string.match( item_notes, "@.*") then root = "" chord = "" i=i +1 end -- skip region marked @ ignore
     if item_notes == "" then root = "" chord = "" i=i +1 end
     if string.find(item_notes, "-%a.*")  == 1 then root = "" chord = "" end  
    
     var = chord
   
     if     root == "C"  then root_up = "C#"
     elseif root == "C#" then root_up = "D"
     elseif root == "Db" then root_up = "D"
     elseif root == "D"  then root_up = "D#"
     elseif root == "D#" then root_up = "E"
     elseif root == "Eb" then root_up = "E"
     elseif root == "E"  then root_up = "F"
     elseif root == "F"  then root_up = "F#"
     elseif root == "F#" then root_up = "G"
     elseif root == "Gb" then root_up = "G"
     elseif root == "G"  then root_up = "G#"
     elseif root == "G#" then root_up = "A"
     elseif root == "Ab" then root_up = "A"
     elseif root == "A"  then root_up = "A#"
     elseif root == "A#" then root_up = "B"
     elseif root == "Bb" then root_up = "B"
     elseif root == "B"  then root_up = "C"
     if not root then end
   end  
   end
   
   
                   ctrack = getTrackByName("chordtrack")
             count_chords = reaper.CountTrackMediaItems(ctrack)
     start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
              count_items = reaper.CountSelectedMediaItems(0)
           for  y = 0, count_chords-1 do
               chord_item =  reaper.GetTrackMediaItem(ctrack, y )  
              is_selected = reaper.IsMediaItemSelected(chord_item)
          end
          
    
     if count_items - count_chords >= 0 or count_items == 0 then
   
     for i=0, count_chords -1 do
   
           chord_item = reaper.GetTrackMediaItem(ctrack,i )
          is_selected = reaper.IsMediaItemSelected(chord_item)
        _, item_notes = reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", "", false) 
                  pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
               length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
               rgnend = pos+length  
               
             
       if  pos >= start_time and pos < end_time then   
       chord_up(item_notes)
       reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", root_up..chord, true)
       end
       end
      
       else
      
          for  x = 0, count_chords-1 do
          chord_item = reaper.GetMediaItem(0,x)    
          is_selected = reaper.IsMediaItemSelected(chord_item )
              if is_selected == true then
           
            _, item_notes = reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", "", false) 
       
             chord_up(item_notes)
             reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", root_up..chord, true)
   end
    end 
   end
    
   
     reaper.UpdateArrange()
     
   
                                                                                    
end
-- =======================================================================================
--================== CHORD_RIGHT =========================================================
--=========================================================================================
function chordsymbol_right()
    function Msg(m)                         --  function: console output alias for debugging
  reaper.ShowConsoleMsg(tostring(m) .. '\n')
    end
 

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end  


function chord_up(item_notes)
  chord, p = nil, 0
  root, chord = string.match(item_notes, "(%w[#b]?)(.*)$")
  switches = string.match( item_notes, "-%a.*")
  
  if string.match( item_notes, "@.*") then root = "" chord = "" i=i +1 end -- skip region marked @ ignore
  if item_notes == "" then root = "" chord = "" i=i +1 end
  if string.find(item_notes, "-%a.*")  == 1 then root = "" chord = "" end  
 
  var = chord

        if     chord == ""        then chord_right = "maj7"
        elseif chord == "maj7"    then chord_right = "maj7#11"
        elseif chord == "maj7#11" then chord_right = "m"
        elseif chord == "m"       then chord_right = "m7"
        elseif chord == "m7"      then chord_right = "m7b9"
        elseif chord == "m7b9"    then chord_right = "m7b5b9"
        elseif chord == "m7b5b9"  then chord_right = "7"
        elseif chord == "7"       then chord_right = "9"
        elseif chord == "9"       then chord_right = "7b9"
        elseif chord == "7b9"     then chord_right = "7#9"
        elseif chord == "7#9"     then chord_right = ""
        elseif chord == nil then return end 
        
        if not root then end
        end


                ctrack = getTrackByName("chordtrack")
          count_chords = reaper.CountTrackMediaItems(ctrack)
  start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
           count_items = reaper.CountSelectedMediaItems(0)
        for  y = 0, count_chords-1 do
            chord_item =  reaper.GetTrackMediaItem(ctrack, y )  
           is_selected = reaper.IsMediaItemSelected(chord_item)
       end
       
 
  if count_items - count_chords >= 0 or count_items == 0 then

  for i=0, count_chords -1 do

        chord_item = reaper.GetTrackMediaItem(ctrack,i )
       is_selected = reaper.IsMediaItemSelected(chord_item)
     _, item_notes = reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", "", false) 
               pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
            length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
            rgnend = pos+length  
            
          
    if  pos >= start_time and pos < end_time then   
    chord_up(item_notes)
    reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", root..chord_right, true)
    end
    end
   
    else
   
       for  x = 0, count_chords-1 do
       chord_item = reaper.GetMediaItem(0,x)    
       is_selected = reaper.IsMediaItemSelected(chord_item )
           if is_selected == true then
        
         _, item_notes = reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", "", false) 
    
          chord_up(item_notes)
          if chord_right == nil then return end 
          reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", root..chord_right, true)
end
 end 
end
 

  reaper.UpdateArrange()
  
end


--========================================================================================
--====================== create_chordtrack ===============================================
--========================================================================================
function create_chordtrack()
-- cliffon track by name
--function Msg(variable)
--  reaper.ShowConsoleMsg(tostring(variable).."\n")
--end

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)

    if ok and trackName == name then
      return track -- found it! stopping the search here
    end
  end
end

local track = getTrackByName("chordtrack")

if track  then 

selected_track = reaper.GetSelectedTrack(0,0 )
IDX_ctrack = reaper.CSurf_TrackToID(track, 0 )
if selected_track then
 IDX = reaper.CSurf_TrackToID(selected_track, 0 )
reaper.Main_OnCommand(40297,0) --Track: Unselect (clear selection of) all tracks
ctrack = getTrackByName("chordtrack")
IDX_ctrack = reaper.CSurf_TrackToID(ctrack, 0 )

reaper.SetOnlyTrackSelected( ctrack )
reaper.ReorderSelectedTracks(IDX-1, 0 )
IDX_ctrack = reaper.CSurf_TrackToID(track, 0 )

elseif  IDX_ctrack >1 then
ctrack = getTrackByName("chordtrack")
reaper.SetOnlyTrackSelected( ctrack )
reaper.ReorderSelectedTracks(0, 0 )

else
ctrack = getTrackByName("chordtrack")
reaper.SetOnlyTrackSelected( ctrack )
reaper.Main_OnCommand(40913,0) --Track: Vertical scroll selected tracks into view

end
end
local track = getTrackByName("chordtrack")
if track == nil then do


--if ctrack == nil then
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_CREATETRK1"),0)-- insert track at top
ctrack=reaper.GetSelectedTrack( 0, 0 )
reaper.GetSetMediaTrackInfo_String(ctrack, "P_NAME", "chordtrack", true)
reaper.SetMediaTrackInfo_Value( ctrack, "I_WNDH", 50 )
if ctrack then 
reaper.SetMediaTrackInfo_Value(ctrack, "I_HEIGHTOVERRIDE", 32)
reaper.SetMediaTrackInfo_Value(ctrack, "B_HEIGHTLOCK", 1)
reaper.SetMediaTrackInfo_Value( ctrack, "I_RECARM", 1 )
reaper.SetMediaTrackInfo_Value( ctrack, "I_RECINPUT", 4096 | 0 | (62 << 5) )

  color = reaper.ColorToNative(95,175,178)
  reaper.SetTrackColor(ctrack, color)


  
end
end
end

reaper.Main_OnCommand(40297,0)
reaper.PreventUIRefresh(1)
end
--========================================================================================================================
--==================================== chordsymbol_trans_down ====================================================================
--========================================================================================================================
function chordsymbol_trans_down()
        function Msg(m)                         --  function: console output alias for debugging
      reaper.ShowConsoleMsg(tostring(m) .. '\n')
        end
     
    
    function getTrackByName(name)
      for trackIndex = 0, reaper.CountTracks(0) - 1 do
         tracko = reaper.GetTrack(0, trackIndex)
        local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)
    
        if ok and trackName == name then
          return tracko -- found it! stopping the search here
        end 
      end
    end  
    
    
    function chord_up(item_notes)
      chord, p = nil, 0
      root, chord = string.match(item_notes, "(%w[#b]?)(.*)$")
      switches = string.match( item_notes, "-%a.*")
      
      if string.match( item_notes, "@.*") then root = "" chord = "" i=i +1 end -- skip region marked @ ignore
      if item_notes == "" then root = "" chord = "" i=i +1 end
      if string.find(item_notes, "-%a.*")  == 1 then root = "" chord = "" end  
     
      var = chord
    
     if     root == "C"  then root_down = "B"
            elseif root == "C#" then root_down = "C"
            elseif root == "Db" then root_down = "C"
            elseif root == "D"  then root_down = "Db"
            elseif root == "D#" then root_down = "D"
            elseif root == "Eb" then root_down = "D"
            elseif root == "E"  then root_down = "Eb"
            elseif root == "F"  then root_down = "E"
            elseif root == "F#" then root_down = "F"
            elseif root == "Gb" then root_down = "F"
            elseif root == "G"  then root_down = "Gb"
            elseif root == "G#" then root_down = "G"
            elseif root == "Ab" then root_down = "G"
            elseif root == "A"  then root_down = "Ab"
            elseif root == "A#" then root_down = "A"
            elseif root == "Bb" then root_down = "A"
            elseif root == "B"  then root_down = "Bb"
            if not root then end
            end
    end
    
    
                    ctrack = getTrackByName("chordtrack")
              count_chords = reaper.CountTrackMediaItems(ctrack)
      start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
               count_items = reaper.CountSelectedMediaItems(0)
            for  y = 0, count_chords-1 do
                chord_item =  reaper.GetTrackMediaItem(ctrack, y )  
               is_selected = reaper.IsMediaItemSelected(chord_item)
           end
           
     
      if count_items - count_chords >= 0 or count_items == 0 then
    
      for i=0, count_chords -1 do
    
            chord_item = reaper.GetTrackMediaItem(ctrack,i )
           is_selected = reaper.IsMediaItemSelected(chord_item)
         _, item_notes = reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", "", false) 
                   pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
                length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
                rgnend = pos+length  
                
              
        if  pos >= start_time and pos < end_time then   
        chord_up(item_notes)
        reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", root_down..chord, true)
        end
        end
       
        else
       
           for  x = 0, count_chords-1 do
           chord_item = reaper.GetMediaItem(0,x)    
           is_selected = reaper.IsMediaItemSelected(chord_item )
               if is_selected == true then
            
             _, item_notes = reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", "", false) 
        
              chord_up(item_notes)
              reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", root_down..chord, true)
    end
     end 
    end
     
    
      reaper.UpdateArrange()
      
    
                                                                                       
                                                                                   
end
--==========================================================================================================
--========================== create_random_chord ===========================================================
--==========================================================================================================
--function Msg(variable)
--  reaper.ShowConsoleMsg(tostring(variable).."\n")
--end
function random_chord()

--function Msg(variable)
--  reaper.ShowConsoleMsg(tostring(variable).."\n")
--end


chords = {[1]={"C","G","Am","F"},
          [2]={"C","F","G","F"},
          [3]={"Dm7","G7","Cmaj7"},
          [4]={"C","Am","F","G"},
          [5]={"C","Am","Dm","G"},
          [6]={"C","F","Am","G"},
          [7]={"C","Em","F","G"},
          [8]={"C","F","C","G"},
          [9]={"C","F","Dm","G"}}

cursor = reaper.GetCursorPosition()
bar = 4*(reaper.TimeMap_QNToTime_abs(0, 1 ))
 
function create_region(region_name1,region_name2,region_name3,region_name4)
   color = reaper.ColorToNative(55,55, 55)|0x1000000 
   
  reaper.AddProjectMarker2(0, true, cursor, (cursor+bar),  region_name1, -1, color)
  reaper.AddProjectMarker2(0, true, (cursor+bar), (cursor+2*bar),  region_name2, -1, color)
  if region_name3 == nil then return
      else
  reaper.AddProjectMarker2(0, true, (cursor+2*bar), (cursor+3*bar), region_name3, -1, color)
  if region_name4 == nil then return
    else
  reaper.AddProjectMarker2(0, true, (cursor+3*bar),(cursor+4*bar), region_name4, -1, color)
  
end  
end
end
math.randomseed(os.time())
a = math.random(1,9)


create_region(chords[a][1],chords[a][2],chords[a][3],chords[a][4])

--Msg(chords[1][1])

end
--====================================================================
--================ CT _ create_subdominant ===================================
--====================================================================

function create_subdominant()
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n") 
  
end



function get_chord_notes(item0) 
       if item0 == nil then return end      
    _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
  if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
   if string.find(item_notes, "/") then
      root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
   else
      root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
   end
     
     if not chord or #chord == 0 then chord = "Maj" end
     if not slash then slash = "" end

  note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D"  then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E"  then note1 = 4
  elseif root == "F"  then note1 = -7
  elseif root == "F#" then note1 = -6
  elseif root == "Gb" then note1 = -6
  elseif root == "G"  then note1 = -5
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A"  then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B"  then note1 = -1
  if not root then end
  end
  
  slashnote = 255
  -- 48 = C2

  if slash == "/C" then slashnote = -12
  elseif slash == "/C#" then slashnote = -11
  elseif slash == "/Db" then slashnote = -11
  elseif slash == "/D" then slashnote = -10
  elseif slash == "/D#" then slashnote = -9
  elseif slash == "/Eb" then slashnote = -9
  elseif slash == "/E" then slashnote = -8
  elseif slash == "/F" then slashnote = -7
  elseif slash == "/F#" then slashnote = -6
  elseif slash == "/Gb" then slashnote = -6
  elseif slash == "/G" then slashnote = -5
  elseif slash == "/G#" then slashnote = -4
  elseif slash == "/Ab" then slashnote = -4
  elseif slash == "/A" then slashnote = -3
  elseif slash == "/A#" then slashnote = -2
  elseif slash == "/Bb" then slashnote = -2
  elseif slash == "/B" then slashnote = -1
  if not slash then slashnote = 255 end
  end

  note2 = 255
  note3 = 255
  note4 = 255
  note5 = 12
  note6 = 12
  note7 = 12

    if string.find(",Maj,maj7,", ","..chord..",", 1, true) then note2=4  note3=7 note4=12 end      
    if string.find(",m,min,-,", ","..chord..",", 1, true) then note2=3  note3=7 note4=12 end      
    if string.find(",dim,m-5,mb5,m(b5),0,", ","..chord..",", 1, true) then note2=3  note3=6 note4=12 end   
    if string.find(",aug,+,+5,(#5),", ","..chord..",", 1, true) then note2=4  note3=8 end   
    if string.find(",-5,(b5),", ","..chord..",", 1, true) then note2=4  note3=6 end   
    if string.find(",sus2,", ","..chord..",", 1, true) then note2=2  note3=7 end   
    if string.find(",sus4,sus,(sus4),", ","..chord..",", 1, true) then note2=5  note3=7 end   
    if string.find(",5,", ","..chord..",", 1, true) then note2=7 note3=12 end   
    if string.find(",5add7,5/7,", ","..chord..",", 1, true) then note2=7  note3=10 note4=10 end   
    if string.find(",add2,(add2),", ","..chord..",", 1, true) then note2=2  note3=4  note4=7 end   
    if string.find(",add4,(add4),", ","..chord..",", 1, true) then note2=4  note3=5  note4=7 end   
    if string.find(",madd4,m(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7 end   
    if string.find(",11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",11sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",m11,min11,-11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",Maj11,maj11,M11,Maj7(add11),M7(add11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=17 end     
    if string.find(",mMaj11,minmaj11,mM11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17 end  
    if string.find(",aug11,9+11,9aug11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",augm11, m9#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",11b5,11-5,11(b5),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17 end  
    if string.find(",11#5,11+5,11(#5),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17 end  
    if string.find(",11b9,11-9,11(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17 end  
    if string.find(",11#9,11+9,11(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17 end  
    if string.find(",11b5b9,11-5-9,11(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17 end  
    if string.find(",11#5b9,11+5-9,11(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17 end  
    if string.find(",11b5#9,11-5+9,11(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17 end  
    if string.find(",11#5#9,11+5+9,11(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17 end  
    if string.find(",m11b5,m11-5,m11(b5),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17 end  
    if string.find(",m11#5,m11+5,m11(#5),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17 end  
    if string.find(",m11b9,m11-9,m11(b9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17 end  
    if string.find(",m11#9,m11+9,m11(#9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17 end  
    if string.find(",m11b5b9,m11-5-9,m11(b5b9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17 end
    if string.find(",m11#5b9,m11+5-9,m11(#5b9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17 end
    if string.find(",m11b5#9,m11-5+9,m11(b5#9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17 end
    if string.find(",m11#5#9,m11+5+9,m11(#5#9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17 end
    if string.find(",Maj11b5,maj11b5,maj11-5,maj11(b5),", ","..chord..",", 1, true)    then note2=4  note3=6  note4=11  note5=14  note6=17 end
    if string.find(",Maj11#5,maj11#5,maj11+5,maj11(#5),", ","..chord..",", 1, true)    then note2=4  note3=8  note4=11  note5=14  note6=17 end
    if string.find(",Maj11b9,maj11b9,maj11-9,maj11(b9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13  note6=17 end
    if string.find(",Maj11#9,maj11#9,maj11+9,maj11(#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15  note6=17 end
    if string.find(",Maj11b5b9,maj11b5b9,maj11-5-9,maj11(b5b9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=13  note6=17 end
    if string.find(",Maj11#5b9,maj11#5b9,maj11+5-9,maj11(#5b9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=13  note6=17 end
    if string.find(",Maj11b5#9,maj11b5#9,maj11-5+9,maj11(b5#9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=15  note6=17 end
    if string.find(",Maj11#5#9,maj11#5#9,maj11+5+9,maj11(#5#9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=15  note6=17 end
    if string.find(",13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13,min13,-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13,maj13,M13,Maj7(add13),M7(add13),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",mMaj13,minmaj13,mM13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",13b5,13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13#5,13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13b9,13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13#9,13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13b5b9,13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13#5b9,13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13b5#9,13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13#5#9,13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13b9#11,13-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",m13b5,m13-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13#5,m13+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13b9,m13-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13#9,m13+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",m13b5b9,m13-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13#5b9,m13+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13b5#9,m13-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",m13#5#9,m13+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13b5,maj13b5,maj13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13#5,maj13#5,maj13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13b9,maj13b9,maj13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13#9,maj13#9,maj13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13b5b9,maj13b5b9,maj13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13#5b9,maj13#5b9,maj13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13b5#9,maj13b5#9,maj13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13#5#9,maj13#5#9,maj13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13#11,maj13#11,maj13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18  note7=21 end  
    if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",m13#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",13sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",6,M6,Maj6,maj6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9 end   
    if string.find(",m6,min6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9 end   
    if string.find(",6add4,6/4,6(add4),Maj6(add4),M6(add4),", ","..chord..",", 1, true)    then note2=4  note3=5  note4=7  note5=9 end   
    if string.find(",m6add4,m6/4,m6(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=9 end   
    if string.find(",69,6add9,6/9,6(add9),Maj6(add9),M6(add9),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=14 end  
    if string.find(",m6add9,m6/9,m6(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
    if string.find(",6sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=9 end   
    if string.find(",6sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=9 end   
    if string.find(",6add11,6/11,6(add11),Maj6(add11),M6(add11),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=17 end  
    if string.find(",m6add11,m6/11,m6(add11),m6(add11),", ","..chord..",", 1, true)    then note2=3  note3=7  note4=9  note5=17 end  
    if string.find(",7,dom,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=12 note6=16 note7=19 end   
    if string.find(",7add2,", ","..chord..",", 1, true) then note2=2  note3=4  note4=7  note5=10 end  
    if string.find(",7add4,", ","..chord..",", 1, true) then note2=4  note3=5  note4=7  note5=10 end  
    if string.find(",m7,min7,-7,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10 note5=12 note6=15 note7=19 end  
    if string.find(",m7add4,", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=10 end  
    if string.find(",Maj7,maj7,Maj7,M7,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11 end   
    if string.find(",dim7,07,", ","..chord..",", 1, true) then note2=3  note3=6  note4=9 end   
    if string.find(",mMaj7,minmaj7,mmaj7,min/maj7,mM7,m(addM7),m(+7),-(M7),m(maj7),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11 end    
    if string.find(",7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=10 end   
    if string.find(",7sus4,7sus,7sus11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10 end   
    if string.find(",Maj7sus2,maj7sus2,M7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=11 end    
    if string.find(",Maj7sus4,maj7sus4,M7sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11 end    
    if string.find(",aug7,+7,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
    if string.find(",7b5,7-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 end   
    if string.find(",7#5,7+5,7+,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
    if string.find(",m7b5,m7-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10 end   
    if string.find(",m7#5,m7+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10 end   
    if string.find(",Maj7b5,maj7b5,maj7-5,M7b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11 end   
    if string.find(",Maj7#5,maj7#5,maj7+5,M7+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11 end   
    if string.find(",7b9,7-9,7(addb9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13 end  
    if string.find(",7#9,7+9,7(add#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
    if string.find(",m7b9, m7-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13 end  
    if string.find(",m7#9, m7+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15 end  
    if string.find(",Maj7b9,maj7b9,maj7-9,maj7(addb9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13 end 
    if string.find(",Maj7#9,maj7#9,maj7+9,maj7(add#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15 end 
    if string.find(",7b9b13,7-9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=20 end  
    if string.find(",m7b9b13, m7-9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=20 end
    if string.find(",7b13,7-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",m7b13,m7-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",7#9b13,7+9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",m7#9b13,m7+9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",7b5b9,7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13 end  
    if string.find(",7b5#9,7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15 end  
    if string.find(",7#5b9,7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13 end  
    if string.find(",7#5#9,7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15 end  
    if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18 end  
    if string.find(",7add6,7/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10 end  
    if string.find(",7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=17 end  
    if string.find(",7add13,7/13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=21 end  
    if string.find(",m7add11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=17 end  
    if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13 end  
    if string.find(",m7b5#9,m7-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15 end  
    if string.find(",m7#5b9,m7+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13 end  
    if string.find(",m7#5#9,m7+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15 end  
    if string.find(",m7#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=18 end  
    if string.find(",Maj7b5b9,maj7b5b9,maj7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13 end 
    if string.find(",Maj7b5#9,maj7b5#9,maj7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15 end 
    if string.find(",Maj7#5b9,maj7#5b9,maj7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13 end 
    if string.find(",Maj7#5#9,maj7#5#9,maj7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15 end 
    if string.find(",Maj7add11,maj7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=17 end  
    if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=18 end  
    if string.find(",9,7(add9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=16  note7=19 end
    if string.find(",m9,min9,-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14 end  
    if string.find(",Maj9,maj9,M9,Maj7(add9),M7(add9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=14 end 
    if string.find(",Maj9sus4,maj9sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11  note5=14 end  
    if string.find(",mMaj9,minmaj9,mmaj9,min/maj9,mM9,m(addM9),m(+9),-(M9),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11  note5=14 end 
    if string.find(",9sus4,9sus,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 end  
    if string.find(",aug9,+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
    if string.find(",9add6,9/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10  note6=14 end  
    if string.find(",m9add6,m9/6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
    if string.find(",9b5,9-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14 end  
    if string.find(",9#5,9+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14 end  
    if string.find(",m9b5,m9-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14 end  
    if string.find(",m9#5,m9+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14 end  
    if string.find(",Maj9b5,maj9b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14 end  
    if string.find(",Maj9#5,maj9#5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14 end  
    if string.find(",Maj9#11,maj9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18 end  
    if string.find(",b9#11,-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18 end  
    if string.find(",add9,2,", ","..chord..",", 1, true) then note2=4  note3=7  note4=14 end   
    if string.find(",madd9,m(add9),-(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=14 end   
    if string.find(",add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=17 end   
    if string.find(",madd11,m(add11),-(add11),", ","..chord..",", 1, true) then note2=3  note3=7  note4=17 end    
    if string.find(",(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=13 end   
    if string.find(",(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=15 end   
    if string.find(",(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=13 end   
    if string.find(",(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=13 end   
    if string.find(",(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=15 end   
    if string.find(",(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=15 end   
    if string.find(",m(b9), mb9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=13 end   
    if string.find(",m(#9), m#9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=15 end   
    if string.find(",m(b5b9), mb5b9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=13 end   
    if string.find(",m(#5b9), m#5b9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=13 end   
    if string.find(",m(b5#9), mb5#9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=15 end   
    if string.find(",m(#5#9), m#5#9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=15 end   
    if string.find(",m(#11), m#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=18 end   
    if string.find(",(#11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=18 end   
    if string.find(",m#5,", ","..chord..",", 1, true) then note2=3  note3=8 end   
    if string.find(",maug,augaddm3,augadd(m3),", ","..chord..",", 1, true) then note2=3  note3=7 note4=8 end  
    if string.find(",13#9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",13susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=21 end  
    if string.find(",13susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",13sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=17  note6=21 end  
    if string.find(",13sus#5b9,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13sus#5b9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",13sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
    if string.find(",13sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end
    if string.find(",13sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13sus#9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",7b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 note5=17  note6=20 end   
    if string.find(",7b5#9b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=20 end  
    if string.find(",7#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=18 end  
    if string.find(",7#5#9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=18 end  
    if string.find(",7#5b9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=18 end  
    if string.find(",7#9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18 note7=20 end  
    if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=18 end   
    if string.find(",7#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18  note6=20 end  
    if string.find(",7susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10 end   
    if string.find(",7susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13 end  
    if string.find(",7b5b9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=20 end  
    if string.find(",7susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=20 end  
    if string.find(",7susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15 end  
    if string.find(",7susb5#9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=20 end  
    if string.find(",7susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13 end  
    if string.find(",7susb9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=20 end  
    if string.find(",7susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18 end  
    if string.find(",7susb9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=20 end  
    if string.find(",7susb13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=20 end  
    if string.find(",7sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10 end   
    if string.find(",7sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end  
    if string.find(",7sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
    if string.find(",7sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15 end  
    if string.find(",7sus#9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",7sus#9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=20 end  
    if string.find(",7sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18 end  
    if string.find(",7sus#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18  note6=20 end  
    if string.find(",9b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=20 end  
    if string.find(",9b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",9#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=18 end  
    if string.find(",9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=20 end  
    if string.find(",9susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  end  
    if string.find(",9susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14 note6=20 end  
    if string.find(",9sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 note6=18 end  
    if string.find(",9susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=15 end  
    if string.find(",9sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=14  note6=18 end   
    if string.find(",quartal,", ","..chord..",", 1, true) then note2=5  note3=10  note4=15 end
    if string.find(",sowhat,", ","..chord..",", 1, true) then note2=5  note3=10  note4=16 end     

  
end


--MAIN---------------------------------------------------------------
function main()
       
             sel_item = reaper.CountSelectedMediaItems(0)
             
             if sel_item ~= 1 then return end
           
           if sel_item == nil then return end  
               item1 = reaper.GetSelectedMediaItem(0,1) 
               item0 =  reaper.GetSelectedMediaItem(0,0)
               length = reaper.GetMediaItemInfo_Value( item0, "D_LENGTH" )
               reaper.SetMediaItemInfo_Value( item0, "D_LENGTH", length/2 )
               reaper.Main_OnCommand(41295,0) -- duplicate item
               reaper.Main_OnCommand(41128,0) -- select previous item
 
  
      get_chord_notes(item0)
      
         
                if root == "C"  then sub_dominant = "Bb"
            elseif root == "C#" then sub_dominant = "B"
            elseif root == "Db" then sub_dominant = "Cb"
            elseif root == "D"  then sub_dominant = "C"
            elseif root == "D#" then sub_dominant = "C#"
            elseif root == "Eb" then sub_dominant = "Db"
            elseif root == "E"  then sub_dominant = "D"
            elseif root == "F"  then sub_dominant = "Eb"
            elseif root == "F#" then sub_dominant = "E"
            elseif root == "Gb" then sub_dominant = "Fb"
            elseif root == "G"  then sub_dominant = "F"
            elseif root == "G#" then sub_dominant = "F#"
            elseif root == "Ab" then sub_dominant = "Gb"
            elseif root == "A"  then sub_dominant = "G"
            elseif root == "A#" then sub_dominant = "G#"
            elseif root == "Bb" then sub_dominant = "Ab"
            elseif root == "B"  then sub_dominant = "A"
            if not root then end
            end
       
        
               
          sel_itemx = reaper.CountSelectedMediaItems(0)
          itemx = reaper.GetSelectedMediaItem(0,0)
          
      reaper.GetSetMediaItemInfo_String(itemx, "P_NOTES",sub_dominant, true)
      reaper.Main_OnCommand(40289,0)
      end

  
main() 

end

--======================================================================================
--=============================== CT _ minor subdominant ================================
--===========================================================================================

-- Variantische Modulation über MollSubDominante
function minor_subdominant()
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n") 
  
end


function get_chord_notes(item0) 
       if item0 == nil then return end      
    _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
  if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
   if string.find(item_notes, "/") then
      root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
   else
      root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
   end
     
     if not chord or #chord == 0 then chord = "Maj" end
     if not slash then slash = "" end

  note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D"  then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E"  then note1 = 4
  elseif root == "F"  then note1 = -7
  elseif root == "F#" then note1 = -6
  elseif root == "Gb" then note1 = -6
  elseif root == "G"  then note1 = -5
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A"  then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B"  then note1 = -1
  if not root then end
  end
  
  slashnote = 255
  -- 48 = C2

  if slash == "/C" then slashnote = -12
  elseif slash == "/C#" then slashnote = -11
  elseif slash == "/Db" then slashnote = -11
  elseif slash == "/D" then slashnote = -10
  elseif slash == "/D#" then slashnote = -9
  elseif slash == "/Eb" then slashnote = -9
  elseif slash == "/E" then slashnote = -8
  elseif slash == "/F" then slashnote = -7
  elseif slash == "/F#" then slashnote = -6
  elseif slash == "/Gb" then slashnote = -6
  elseif slash == "/G" then slashnote = -5
  elseif slash == "/G#" then slashnote = -4
  elseif slash == "/Ab" then slashnote = -4
  elseif slash == "/A" then slashnote = -3
  elseif slash == "/A#" then slashnote = -2
  elseif slash == "/Bb" then slashnote = -2
  elseif slash == "/B" then slashnote = -1
  if not slash then slashnote = 255 end
  end

  note2 = 255
  note3 = 255
  note4 = 255
  note5 = 12
  note6 = 12
  note7 = 12

    if string.find(",Maj,maj7,", ","..chord..",", 1, true) then note2=4  note3=7 note4=12 end      
    if string.find(",m,min,-,", ","..chord..",", 1, true) then note2=3  note3=7 note4=12 end      
    if string.find(",dim,m-5,mb5,m(b5),0,", ","..chord..",", 1, true) then note2=3  note3=6 note4=12 end   
    if string.find(",aug,+,+5,(#5),", ","..chord..",", 1, true) then note2=4  note3=8 end   
    if string.find(",-5,(b5),", ","..chord..",", 1, true) then note2=4  note3=6 end   
    if string.find(",sus2,", ","..chord..",", 1, true) then note2=2  note3=7 end   
    if string.find(",sus4,sus,(sus4),", ","..chord..",", 1, true) then note2=5  note3=7 end   
    if string.find(",5,", ","..chord..",", 1, true) then note2=7 note3=12 end   
    if string.find(",5add7,5/7,", ","..chord..",", 1, true) then note2=7  note3=10 note4=10 end   
    if string.find(",add2,(add2),", ","..chord..",", 1, true) then note2=2  note3=4  note4=7 end   
    if string.find(",add4,(add4),", ","..chord..",", 1, true) then note2=4  note3=5  note4=7 end   
    if string.find(",madd4,m(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7 end   
    if string.find(",11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",11sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",m11,min11,-11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",Maj11,maj11,M11,Maj7(add11),M7(add11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=17 end     
    if string.find(",mMaj11,minmaj11,mM11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17 end  
    if string.find(",aug11,9+11,9aug11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",augm11, m9#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",11b5,11-5,11(b5),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17 end  
    if string.find(",11#5,11+5,11(#5),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17 end  
    if string.find(",11b9,11-9,11(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17 end  
    if string.find(",11#9,11+9,11(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17 end  
    if string.find(",11b5b9,11-5-9,11(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17 end  
    if string.find(",11#5b9,11+5-9,11(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17 end  
    if string.find(",11b5#9,11-5+9,11(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17 end  
    if string.find(",11#5#9,11+5+9,11(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17 end  
    if string.find(",m11b5,m11-5,m11(b5),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17 end  
    if string.find(",m11#5,m11+5,m11(#5),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17 end  
    if string.find(",m11b9,m11-9,m11(b9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17 end  
    if string.find(",m11#9,m11+9,m11(#9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17 end  
    if string.find(",m11b5b9,m11-5-9,m11(b5b9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17 end
    if string.find(",m11#5b9,m11+5-9,m11(#5b9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17 end
    if string.find(",m11b5#9,m11-5+9,m11(b5#9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17 end
    if string.find(",m11#5#9,m11+5+9,m11(#5#9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17 end
    if string.find(",Maj11b5,maj11b5,maj11-5,maj11(b5),", ","..chord..",", 1, true)    then note2=4  note3=6  note4=11  note5=14  note6=17 end
    if string.find(",Maj11#5,maj11#5,maj11+5,maj11(#5),", ","..chord..",", 1, true)    then note2=4  note3=8  note4=11  note5=14  note6=17 end
    if string.find(",Maj11b9,maj11b9,maj11-9,maj11(b9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13  note6=17 end
    if string.find(",Maj11#9,maj11#9,maj11+9,maj11(#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15  note6=17 end
    if string.find(",Maj11b5b9,maj11b5b9,maj11-5-9,maj11(b5b9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=13  note6=17 end
    if string.find(",Maj11#5b9,maj11#5b9,maj11+5-9,maj11(#5b9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=13  note6=17 end
    if string.find(",Maj11b5#9,maj11b5#9,maj11-5+9,maj11(b5#9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=15  note6=17 end
    if string.find(",Maj11#5#9,maj11#5#9,maj11+5+9,maj11(#5#9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=15  note6=17 end
    if string.find(",13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13,min13,-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13,maj13,M13,Maj7(add13),M7(add13),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",mMaj13,minmaj13,mM13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",13b5,13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13#5,13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13b9,13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13#9,13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13b5b9,13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13#5b9,13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13b5#9,13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13#5#9,13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13b9#11,13-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",m13b5,m13-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13#5,m13+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13b9,m13-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13#9,m13+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",m13b5b9,m13-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13#5b9,m13+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13b5#9,m13-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",m13#5#9,m13+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13b5,maj13b5,maj13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13#5,maj13#5,maj13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13b9,maj13b9,maj13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13#9,maj13#9,maj13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13b5b9,maj13b5b9,maj13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13#5b9,maj13#5b9,maj13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13b5#9,maj13b5#9,maj13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13#5#9,maj13#5#9,maj13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13#11,maj13#11,maj13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18  note7=21 end  
    if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",m13#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",13sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",6,M6,Maj6,maj6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9 end   
    if string.find(",m6,min6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9 end   
    if string.find(",6add4,6/4,6(add4),Maj6(add4),M6(add4),", ","..chord..",", 1, true)    then note2=4  note3=5  note4=7  note5=9 end   
    if string.find(",m6add4,m6/4,m6(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=9 end   
    if string.find(",69,6add9,6/9,6(add9),Maj6(add9),M6(add9),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=14 end  
    if string.find(",m6add9,m6/9,m6(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
    if string.find(",6sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=9 end   
    if string.find(",6sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=9 end   
    if string.find(",6add11,6/11,6(add11),Maj6(add11),M6(add11),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=17 end  
    if string.find(",m6add11,m6/11,m6(add11),m6(add11),", ","..chord..",", 1, true)    then note2=3  note3=7  note4=9  note5=17 end  
    if string.find(",7,dom,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=12 note6=16 note7=19 end   
    if string.find(",7add2,", ","..chord..",", 1, true) then note2=2  note3=4  note4=7  note5=10 end  
    if string.find(",7add4,", ","..chord..",", 1, true) then note2=4  note3=5  note4=7  note5=10 end  
    if string.find(",m7,min7,-7,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10 note5=12 note6=15 note7=19 end  
    if string.find(",m7add4,", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=10 end  
    if string.find(",Maj7,maj7,Maj7,M7,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11 end   
    if string.find(",dim7,07,", ","..chord..",", 1, true) then note2=3  note3=6  note4=9 end   
    if string.find(",mMaj7,minmaj7,mmaj7,min/maj7,mM7,m(addM7),m(+7),-(M7),m(maj7),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11 end    
    if string.find(",7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=10 end   
    if string.find(",7sus4,7sus,7sus11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10 end   
    if string.find(",Maj7sus2,maj7sus2,M7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=11 end    
    if string.find(",Maj7sus4,maj7sus4,M7sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11 end    
    if string.find(",aug7,+7,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
    if string.find(",7b5,7-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 end   
    if string.find(",7#5,7+5,7+,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
    if string.find(",m7b5,m7-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10 end   
    if string.find(",m7#5,m7+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10 end   
    if string.find(",Maj7b5,maj7b5,maj7-5,M7b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11 end   
    if string.find(",Maj7#5,maj7#5,maj7+5,M7+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11 end   
    if string.find(",7b9,7-9,7(addb9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13 end  
    if string.find(",7#9,7+9,7(add#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
    if string.find(",m7b9, m7-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13 end  
    if string.find(",m7#9, m7+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15 end  
    if string.find(",Maj7b9,maj7b9,maj7-9,maj7(addb9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13 end 
    if string.find(",Maj7#9,maj7#9,maj7+9,maj7(add#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15 end 
    if string.find(",7b9b13,7-9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=20 end  
    if string.find(",m7b9b13, m7-9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=20 end
    if string.find(",7b13,7-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",m7b13,m7-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",7#9b13,7+9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",m7#9b13,m7+9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",7b5b9,7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13 end  
    if string.find(",7b5#9,7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15 end  
    if string.find(",7#5b9,7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13 end  
    if string.find(",7#5#9,7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15 end  
    if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18 end  
    if string.find(",7add6,7/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10 end  
    if string.find(",7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=17 end  
    if string.find(",7add13,7/13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=21 end  
    if string.find(",m7add11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=17 end  
    if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13 end  
    if string.find(",m7b5#9,m7-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15 end  
    if string.find(",m7#5b9,m7+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13 end  
    if string.find(",m7#5#9,m7+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15 end  
    if string.find(",m7#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=18 end  
    if string.find(",Maj7b5b9,maj7b5b9,maj7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13 end 
    if string.find(",Maj7b5#9,maj7b5#9,maj7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15 end 
    if string.find(",Maj7#5b9,maj7#5b9,maj7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13 end 
    if string.find(",Maj7#5#9,maj7#5#9,maj7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15 end 
    if string.find(",Maj7add11,maj7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=17 end  
    if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=18 end  
    if string.find(",9,7(add9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=16  note7=19 end
    if string.find(",m9,min9,-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14 end  
    if string.find(",Maj9,maj9,M9,Maj7(add9),M7(add9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=14 end 
    if string.find(",Maj9sus4,maj9sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11  note5=14 end  
    if string.find(",mMaj9,minmaj9,mmaj9,min/maj9,mM9,m(addM9),m(+9),-(M9),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11  note5=14 end 
    if string.find(",9sus4,9sus,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 end  
    if string.find(",aug9,+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
    if string.find(",9add6,9/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10  note6=14 end  
    if string.find(",m9add6,m9/6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
    if string.find(",9b5,9-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14 end  
    if string.find(",9#5,9+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14 end  
    if string.find(",m9b5,m9-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14 end  
    if string.find(",m9#5,m9+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14 end  
    if string.find(",Maj9b5,maj9b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14 end  
    if string.find(",Maj9#5,maj9#5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14 end  
    if string.find(",Maj9#11,maj9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18 end  
    if string.find(",b9#11,-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18 end  
    if string.find(",add9,2,", ","..chord..",", 1, true) then note2=4  note3=7  note4=14 end   
    if string.find(",madd9,m(add9),-(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=14 end   
    if string.find(",add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=17 end   
    if string.find(",madd11,m(add11),-(add11),", ","..chord..",", 1, true) then note2=3  note3=7  note4=17 end    
    if string.find(",(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=13 end   
    if string.find(",(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=15 end   
    if string.find(",(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=13 end   
    if string.find(",(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=13 end   
    if string.find(",(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=15 end   
    if string.find(",(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=15 end   
    if string.find(",m(b9), mb9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=13 end   
    if string.find(",m(#9), m#9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=15 end   
    if string.find(",m(b5b9), mb5b9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=13 end   
    if string.find(",m(#5b9), m#5b9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=13 end   
    if string.find(",m(b5#9), mb5#9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=15 end   
    if string.find(",m(#5#9), m#5#9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=15 end   
    if string.find(",m(#11), m#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=18 end   
    if string.find(",(#11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=18 end   
    if string.find(",m#5,", ","..chord..",", 1, true) then note2=3  note3=8 end   
    if string.find(",maug,augaddm3,augadd(m3),", ","..chord..",", 1, true) then note2=3  note3=7 note4=8 end  
    if string.find(",13#9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",13susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=21 end  
    if string.find(",13susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",13sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=17  note6=21 end  
    if string.find(",13sus#5b9,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13sus#5b9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",13sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
    if string.find(",13sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end
    if string.find(",13sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13sus#9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",7b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 note5=17  note6=20 end   
    if string.find(",7b5#9b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=20 end  
    if string.find(",7#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=18 end  
    if string.find(",7#5#9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=18 end  
    if string.find(",7#5b9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=18 end  
    if string.find(",7#9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18 note7=20 end  
    if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=18 end   
    if string.find(",7#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18  note6=20 end  
    if string.find(",7susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10 end   
    if string.find(",7susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13 end  
    if string.find(",7b5b9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=20 end  
    if string.find(",7susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=20 end  
    if string.find(",7susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15 end  
    if string.find(",7susb5#9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=20 end  
    if string.find(",7susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13 end  
    if string.find(",7susb9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=20 end  
    if string.find(",7susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18 end  
    if string.find(",7susb9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=20 end  
    if string.find(",7susb13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=20 end  
    if string.find(",7sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10 end   
    if string.find(",7sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end  
    if string.find(",7sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
    if string.find(",7sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15 end  
    if string.find(",7sus#9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",7sus#9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=20 end  
    if string.find(",7sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18 end  
    if string.find(",7sus#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18  note6=20 end  
    if string.find(",9b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=20 end  
    if string.find(",9b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",9#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=18 end  
    if string.find(",9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=20 end  
    if string.find(",9susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  end  
    if string.find(",9susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14 note6=20 end  
    if string.find(",9sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 note6=18 end  
    if string.find(",9susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=15 end  
    if string.find(",9sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=14  note6=18 end   
    if string.find(",quartal,", ","..chord..",", 1, true) then note2=5  note3=10  note4=15 end
    if string.find(",sowhat,", ","..chord..",", 1, true) then note2=5  note3=10  note4=16 end     

  
end

      if root == "C"  then circle = 1
  elseif root == "C#" then circle = 8
  elseif root == "Db" then circle = 8
  elseif root == "D"  then circle = 3
  elseif root == "D#" then circle = 10
  elseif root == "Eb" then circle = 10
  elseif root == "E"  then circle = 5
  elseif root == "F"  then circle = 12
  elseif root == "F#" then circle = 7
  elseif root == "Gb" then circle = 7
  elseif root == "G"  then circle = 2
  elseif root == "G#" then circle = 9
  elseif root == "Ab" then circle = 9
  elseif root == "A"  then circle = 4
  elseif root == "A#" then circle = 11
  elseif root == "Bb" then circle = 11
  elseif root == "B"  then circle = 6
  if not root then end
  end


--MAIN---------------------------------------------------------------
function main()
       
             sel_item = reaper.CountSelectedMediaItems(0)
             
             if sel_item ~= 2 then return end
             if sel_item == nil then return end  
               item1 =  reaper.GetSelectedMediaItem(0,1) 
               item0 =  reaper.GetSelectedMediaItem(0,0)
               
      get_chord_notes(item0) 
            if root == "C"  then circle0 = 1
        elseif root == "C#" then circle0 = 8
        elseif root == "Db" then circle0 = 8
        elseif root == "D"  then circle0 = 3
        elseif root == "D#" then circle0 = 10
        elseif root == "Eb" then circle0 = 10
        elseif root == "E"  then circle0 = 5
        elseif root == "F"  then circle0 = 12
        elseif root == "F#" then circle0 = 7
        elseif root == "Gb" then circle0 = 7
        elseif root == "G"  then circle0 = 2
        elseif root == "G#" then circle0 = 9
        elseif root == "Ab" then circle0 = 9
        elseif root == "A"  then circle0 = 4
        elseif root == "A#" then circle0 = 11
        elseif root == "Bb" then circle0 = 11
        elseif root == "B"  then circle0 = 6
        if not root then end
        end
        
      get_chord_notes(item1)
            if root == "C"  then circle1 = 1 
        elseif root == "C#" then circle1 = 8
        elseif root == "Db" then circle1 = 8
        elseif root == "D"  then circle1 = 3
        elseif root == "D#" then circle1 = 10
        elseif root == "Eb" then circle1 = 10
        elseif root == "E"  then circle1 = 5
        elseif root == "F"  then circle1 = 12
        elseif root == "F#" then circle1 = 7
        elseif root == "Gb" then circle1 = 7
        elseif root == "G"  then circle1 = 2
        elseif root == "G#" then circle1 = 9
        elseif root == "Ab" then circle1 = 9
        elseif root == "A"  then circle1 = 4
        elseif root == "A#" then circle1 = 11
        elseif root == "Bb" then circle1 = 11
        elseif root == "B"  then circle1 = 6
        if not root then end
        end
      
     xxx = circle1 - circle0
   -- Msg(xxx)
     if xxx==1 or xxx==2 or xxx==10 or xxx==11 or xxx==-1  or xxx==-2 or xxx==-10 or xxx==-11 or xxx==6 or xxx==-6 then Msg("Chords not suitable \nFor keys that are more than 3 fifths apart.")return end
     yyy = 0
     
         if xxx == 3 then  yyy = circle1
     elseif xxx == 4 then  yyy = circle1
     elseif xxx == 5 then  yyy = circle1
     elseif xxx == 7 then  yyy = circle0
     elseif xxx == 8 then  yyy = circle0
     elseif xxx == 9 then  yyy = circle0
     elseif xxx == -3 then  yyy = circle0
     elseif xxx == -4 then  yyy = circle0
     elseif xxx == -5 then  yyy = circle0
     elseif xxx == -7 then  yyy = circle1
     elseif xxx == -8 then  yyy = circle1
     elseif xxx == -9 then  yyy = circle1
     end 
     
   -- Msg(yyy)
         
                if yyy == 1 then root = "C"
            elseif yyy == 2 then root = "G"
            elseif yyy == 3 then root = "D"
            elseif yyy == 4 then root = "A"
            elseif yyy == 5 then root = "E"
            elseif yyy == 6 then root = "B"
            elseif yyy == 7 then root = "F#"
            elseif yyy == 8 then root = "Db"
            elseif yyy == 9 then root = "Ab"
            elseif yyy == 10 then root = "Eb"
            elseif yyy == 11 then root = "Bb"
            elseif yyy == 12 then root = "F"
            
            end
              
         
                if root == "C"  then moll_sub_dom = "F"
            elseif root == "C#" then moll_sub_dom = "F#"
            elseif root == "Db" then moll_sub_dom = "Gb"
            elseif root == "D"  then moll_sub_dom = "G"
            elseif root == "D#" then moll_sub_dom = "G#"
            elseif root == "Eb" then moll_sub_dom = "Ab"
            elseif root == "E"  then moll_sub_dom = "A"
            elseif root == "F"  then moll_sub_dom = "Bb"
            elseif root == "F#" then moll_sub_dom = "B"
            elseif root == "Gb" then moll_sub_dom = "Cb"
            elseif root == "G"  then moll_sub_dom = "C"
            elseif root == "G#" then moll_sub_dom = "C#"
            elseif root == "Ab" then moll_sub_dom = "Db"
            elseif root == "A"  then moll_sub_dom = "D"
            elseif root == "A#" then moll_sub_dom = "D#"
            elseif root == "Bb" then moll_sub_dom = "Eb"
            elseif root == "B"  then moll_sub_dom = "E"
            if not root then end
            end
       
     --  Msg(root)
          item0 =  reaper.GetSelectedMediaItem(0,0)
                    length = reaper.GetMediaItemInfo_Value( item0, "D_LENGTH" )
                   reaper.SetMediaItemInfo_Value( item0, "D_LENGTH", length/2 ) 
          item1 =  reaper.GetSelectedMediaItem(0,1)
                   reaper.SetMediaItemInfo_Value( item1, "B_UISEL",0)
                   reaper.Main_OnCommand(41295,0) -- duplicate item
            
               
          sel_itemx = reaper.CountSelectedMediaItems(0)
          itemx = reaper.GetSelectedMediaItem(0,0)
          
      reaper.GetSetMediaItemInfo_String(itemx, "P_NOTES", moll_sub_dom.."m", true)
      end
   
 
  
main() 


end



--====================================================================
--================ CT _ create_parallel ===================================
--====================================================================

function create_parallel()
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n") 
  
end



function get_chord_notes(item0) 
       if item0 == nil then return end      
    _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
  if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
   if string.find(item_notes, "/") then
      root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
   else
      root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
   end
     
     if not chord or #chord == 0 then chord = "Maj" end
     if not slash then slash = "" end

  note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D"  then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E"  then note1 = 4
  elseif root == "F"  then note1 = -7
  elseif root == "F#" then note1 = -6
  elseif root == "Gb" then note1 = -6
  elseif root == "G"  then note1 = -5
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A"  then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B"  then note1 = -1
  if not root then end
  end
  
  slashnote = 255
  -- 48 = C2

  if slash == "/C" then slashnote = -12
  elseif slash == "/C#" then slashnote = -11
  elseif slash == "/Db" then slashnote = -11
  elseif slash == "/D" then slashnote = -10
  elseif slash == "/D#" then slashnote = -9
  elseif slash == "/Eb" then slashnote = -9
  elseif slash == "/E" then slashnote = -8
  elseif slash == "/F" then slashnote = -7
  elseif slash == "/F#" then slashnote = -6
  elseif slash == "/Gb" then slashnote = -6
  elseif slash == "/G" then slashnote = -5
  elseif slash == "/G#" then slashnote = -4
  elseif slash == "/Ab" then slashnote = -4
  elseif slash == "/A" then slashnote = -3
  elseif slash == "/A#" then slashnote = -2
  elseif slash == "/Bb" then slashnote = -2
  elseif slash == "/B" then slashnote = -1
  if not slash then slashnote = 255 end
  end

  note2 = 255
  note3 = 255
  note4 = 255
  note5 = 12
  note6 = 12
  note7 = 12

    if string.find(",Maj,maj7,", ","..chord..",", 1, true) then note2=4  note3=7 note4=12 end      
    if string.find(",m,min,-,", ","..chord..",", 1, true) then note2=3  note3=7 note4=12 end      
    if string.find(",dim,m-5,mb5,m(b5),0,", ","..chord..",", 1, true) then note2=3  note3=6 note4=12 end   
    if string.find(",aug,+,+5,(#5),", ","..chord..",", 1, true) then note2=4  note3=8 end   
    if string.find(",-5,(b5),", ","..chord..",", 1, true) then note2=4  note3=6 end   
    if string.find(",sus2,", ","..chord..",", 1, true) then note2=2  note3=7 end   
    if string.find(",sus4,sus,(sus4),", ","..chord..",", 1, true) then note2=5  note3=7 end   
    if string.find(",5,", ","..chord..",", 1, true) then note2=7 note3=12 end   
    if string.find(",5add7,5/7,", ","..chord..",", 1, true) then note2=7  note3=10 note4=10 end   
    if string.find(",add2,(add2),", ","..chord..",", 1, true) then note2=2  note3=4  note4=7 end   
    if string.find(",add4,(add4),", ","..chord..",", 1, true) then note2=4  note3=5  note4=7 end   
    if string.find(",madd4,m(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7 end   
    if string.find(",11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",11sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",m11,min11,-11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",Maj11,maj11,M11,Maj7(add11),M7(add11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=17 end     
    if string.find(",mMaj11,minmaj11,mM11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17 end  
    if string.find(",aug11,9+11,9aug11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",augm11, m9#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",11b5,11-5,11(b5),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17 end  
    if string.find(",11#5,11+5,11(#5),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17 end  
    if string.find(",11b9,11-9,11(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17 end  
    if string.find(",11#9,11+9,11(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17 end  
    if string.find(",11b5b9,11-5-9,11(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17 end  
    if string.find(",11#5b9,11+5-9,11(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17 end  
    if string.find(",11b5#9,11-5+9,11(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17 end  
    if string.find(",11#5#9,11+5+9,11(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17 end  
    if string.find(",m11b5,m11-5,m11(b5),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17 end  
    if string.find(",m11#5,m11+5,m11(#5),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17 end  
    if string.find(",m11b9,m11-9,m11(b9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17 end  
    if string.find(",m11#9,m11+9,m11(#9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17 end  
    if string.find(",m11b5b9,m11-5-9,m11(b5b9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17 end
    if string.find(",m11#5b9,m11+5-9,m11(#5b9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17 end
    if string.find(",m11b5#9,m11-5+9,m11(b5#9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17 end
    if string.find(",m11#5#9,m11+5+9,m11(#5#9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17 end
    if string.find(",Maj11b5,maj11b5,maj11-5,maj11(b5),", ","..chord..",", 1, true)    then note2=4  note3=6  note4=11  note5=14  note6=17 end
    if string.find(",Maj11#5,maj11#5,maj11+5,maj11(#5),", ","..chord..",", 1, true)    then note2=4  note3=8  note4=11  note5=14  note6=17 end
    if string.find(",Maj11b9,maj11b9,maj11-9,maj11(b9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13  note6=17 end
    if string.find(",Maj11#9,maj11#9,maj11+9,maj11(#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15  note6=17 end
    if string.find(",Maj11b5b9,maj11b5b9,maj11-5-9,maj11(b5b9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=13  note6=17 end
    if string.find(",Maj11#5b9,maj11#5b9,maj11+5-9,maj11(#5b9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=13  note6=17 end
    if string.find(",Maj11b5#9,maj11b5#9,maj11-5+9,maj11(b5#9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=15  note6=17 end
    if string.find(",Maj11#5#9,maj11#5#9,maj11+5+9,maj11(#5#9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=15  note6=17 end
    if string.find(",13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13,min13,-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13,maj13,M13,Maj7(add13),M7(add13),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",mMaj13,minmaj13,mM13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",13b5,13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13#5,13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13b9,13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13#9,13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13b5b9,13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13#5b9,13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13b5#9,13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13#5#9,13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13b9#11,13-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",m13b5,m13-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13#5,m13+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13b9,m13-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13#9,m13+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",m13b5b9,m13-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13#5b9,m13+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13b5#9,m13-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",m13#5#9,m13+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13b5,maj13b5,maj13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13#5,maj13#5,maj13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13b9,maj13b9,maj13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13#9,maj13#9,maj13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13b5b9,maj13b5b9,maj13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13#5b9,maj13#5b9,maj13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13b5#9,maj13b5#9,maj13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13#5#9,maj13#5#9,maj13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13#11,maj13#11,maj13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18  note7=21 end  
    if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",m13#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",13sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",6,M6,Maj6,maj6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9 end   
    if string.find(",m6,min6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9 end   
    if string.find(",6add4,6/4,6(add4),Maj6(add4),M6(add4),", ","..chord..",", 1, true)    then note2=4  note3=5  note4=7  note5=9 end   
    if string.find(",m6add4,m6/4,m6(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=9 end   
    if string.find(",69,6add9,6/9,6(add9),Maj6(add9),M6(add9),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=14 end  
    if string.find(",m6add9,m6/9,m6(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
    if string.find(",6sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=9 end   
    if string.find(",6sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=9 end   
    if string.find(",6add11,6/11,6(add11),Maj6(add11),M6(add11),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=17 end  
    if string.find(",m6add11,m6/11,m6(add11),m6(add11),", ","..chord..",", 1, true)    then note2=3  note3=7  note4=9  note5=17 end  
    if string.find(",7,dom,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=12 note6=16 note7=19 end   
    if string.find(",7add2,", ","..chord..",", 1, true) then note2=2  note3=4  note4=7  note5=10 end  
    if string.find(",7add4,", ","..chord..",", 1, true) then note2=4  note3=5  note4=7  note5=10 end  
    if string.find(",m7,min7,-7,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10 note5=12 note6=15 note7=19 end  
    if string.find(",m7add4,", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=10 end  
    if string.find(",Maj7,maj7,Maj7,M7,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11 end   
    if string.find(",dim7,07,", ","..chord..",", 1, true) then note2=3  note3=6  note4=9 end   
    if string.find(",mMaj7,minmaj7,mmaj7,min/maj7,mM7,m(addM7),m(+7),-(M7),m(maj7),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11 end    
    if string.find(",7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=10 end   
    if string.find(",7sus4,7sus,7sus11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10 end   
    if string.find(",Maj7sus2,maj7sus2,M7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=11 end    
    if string.find(",Maj7sus4,maj7sus4,M7sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11 end    
    if string.find(",aug7,+7,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
    if string.find(",7b5,7-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 end   
    if string.find(",7#5,7+5,7+,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
    if string.find(",m7b5,m7-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10 end   
    if string.find(",m7#5,m7+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10 end   
    if string.find(",Maj7b5,maj7b5,maj7-5,M7b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11 end   
    if string.find(",Maj7#5,maj7#5,maj7+5,M7+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11 end   
    if string.find(",7b9,7-9,7(addb9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13 end  
    if string.find(",7#9,7+9,7(add#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
    if string.find(",m7b9, m7-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13 end  
    if string.find(",m7#9, m7+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15 end  
    if string.find(",Maj7b9,maj7b9,maj7-9,maj7(addb9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13 end 
    if string.find(",Maj7#9,maj7#9,maj7+9,maj7(add#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15 end 
    if string.find(",7b9b13,7-9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=20 end  
    if string.find(",m7b9b13, m7-9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=20 end
    if string.find(",7b13,7-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",m7b13,m7-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",7#9b13,7+9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",m7#9b13,m7+9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",7b5b9,7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13 end  
    if string.find(",7b5#9,7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15 end  
    if string.find(",7#5b9,7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13 end  
    if string.find(",7#5#9,7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15 end  
    if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18 end  
    if string.find(",7add6,7/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10 end  
    if string.find(",7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=17 end  
    if string.find(",7add13,7/13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=21 end  
    if string.find(",m7add11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=17 end  
    if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13 end  
    if string.find(",m7b5#9,m7-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15 end  
    if string.find(",m7#5b9,m7+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13 end  
    if string.find(",m7#5#9,m7+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15 end  
    if string.find(",m7#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=18 end  
    if string.find(",Maj7b5b9,maj7b5b9,maj7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13 end 
    if string.find(",Maj7b5#9,maj7b5#9,maj7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15 end 
    if string.find(",Maj7#5b9,maj7#5b9,maj7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13 end 
    if string.find(",Maj7#5#9,maj7#5#9,maj7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15 end 
    if string.find(",Maj7add11,maj7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=17 end  
    if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=18 end  
    if string.find(",9,7(add9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=16  note7=19 end
    if string.find(",m9,min9,-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14 end  
    if string.find(",Maj9,maj9,M9,Maj7(add9),M7(add9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=14 end 
    if string.find(",Maj9sus4,maj9sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11  note5=14 end  
    if string.find(",mMaj9,minmaj9,mmaj9,min/maj9,mM9,m(addM9),m(+9),-(M9),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11  note5=14 end 
    if string.find(",9sus4,9sus,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 end  
    if string.find(",aug9,+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
    if string.find(",9add6,9/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10  note6=14 end  
    if string.find(",m9add6,m9/6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
    if string.find(",9b5,9-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14 end  
    if string.find(",9#5,9+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14 end  
    if string.find(",m9b5,m9-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14 end  
    if string.find(",m9#5,m9+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14 end  
    if string.find(",Maj9b5,maj9b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14 end  
    if string.find(",Maj9#5,maj9#5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14 end  
    if string.find(",Maj9#11,maj9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18 end  
    if string.find(",b9#11,-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18 end  
    if string.find(",add9,2,", ","..chord..",", 1, true) then note2=4  note3=7  note4=14 end   
    if string.find(",madd9,m(add9),-(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=14 end   
    if string.find(",add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=17 end   
    if string.find(",madd11,m(add11),-(add11),", ","..chord..",", 1, true) then note2=3  note3=7  note4=17 end    
    if string.find(",(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=13 end   
    if string.find(",(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=15 end   
    if string.find(",(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=13 end   
    if string.find(",(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=13 end   
    if string.find(",(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=15 end   
    if string.find(",(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=15 end   
    if string.find(",m(b9), mb9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=13 end   
    if string.find(",m(#9), m#9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=15 end   
    if string.find(",m(b5b9), mb5b9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=13 end   
    if string.find(",m(#5b9), m#5b9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=13 end   
    if string.find(",m(b5#9), mb5#9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=15 end   
    if string.find(",m(#5#9), m#5#9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=15 end   
    if string.find(",m(#11), m#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=18 end   
    if string.find(",(#11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=18 end   
    if string.find(",m#5,", ","..chord..",", 1, true) then note2=3  note3=8 end   
    if string.find(",maug,augaddm3,augadd(m3),", ","..chord..",", 1, true) then note2=3  note3=7 note4=8 end  
    if string.find(",13#9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",13susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=21 end  
    if string.find(",13susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",13sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=17  note6=21 end  
    if string.find(",13sus#5b9,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13sus#5b9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",13sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
    if string.find(",13sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end
    if string.find(",13sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13sus#9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",7b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 note5=17  note6=20 end   
    if string.find(",7b5#9b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=20 end  
    if string.find(",7#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=18 end  
    if string.find(",7#5#9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=18 end  
    if string.find(",7#5b9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=18 end  
    if string.find(",7#9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18 note7=20 end  
    if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=18 end   
    if string.find(",7#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18  note6=20 end  
    if string.find(",7susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10 end   
    if string.find(",7susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13 end  
    if string.find(",7b5b9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=20 end  
    if string.find(",7susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=20 end  
    if string.find(",7susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15 end  
    if string.find(",7susb5#9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=20 end  
    if string.find(",7susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13 end  
    if string.find(",7susb9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=20 end  
    if string.find(",7susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18 end  
    if string.find(",7susb9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=20 end  
    if string.find(",7susb13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=20 end  
    if string.find(",7sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10 end   
    if string.find(",7sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end  
    if string.find(",7sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
    if string.find(",7sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15 end  
    if string.find(",7sus#9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",7sus#9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=20 end  
    if string.find(",7sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18 end  
    if string.find(",7sus#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18  note6=20 end  
    if string.find(",9b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=20 end  
    if string.find(",9b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",9#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=18 end  
    if string.find(",9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=20 end  
    if string.find(",9susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  end  
    if string.find(",9susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14 note6=20 end  
    if string.find(",9sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 note6=18 end  
    if string.find(",9susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=15 end  
    if string.find(",9sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=14  note6=18 end   
    if string.find(",quartal,", ","..chord..",", 1, true) then note2=5  note3=10  note4=15 end
    if string.find(",sowhat,", ","..chord..",", 1, true) then note2=5  note3=10  note4=16 end     

  
end


--MAIN---------------------------------------------------------------
function main()
       
             sel_item = reaper.CountSelectedMediaItems(0)
             
             if sel_item ~= 1 then return end
             if sel_item == nil then return end  
             
               item0 =  reaper.GetSelectedMediaItem(0,0)
             
  
      get_chord_notes(item0)
      
               if chord == "" or chord == "maj" or chord == "maj7" or chord == "Maj" or chord == "m" or chord == "m7" or chord == "-" or chord == "-7" then 
      
                if chord == "" or chord == "maj" or chord == "maj7" or chord == "Maj" then pa_chord = "m" 
         
                if root == "C"  then parallel = "A"
            elseif root == "C#" then parallel = "A#"
            elseif root == "Db" then parallel = "Cb"
            elseif root == "D"  then parallel = "B"
            elseif root == "D#" then parallel = "B#"
            elseif root == "Eb" then parallel = "C"
            elseif root == "E"  then parallel = "C#"
            elseif root == "F"  then parallel = "D"
            elseif root == "F#" then parallel = "D#"
            elseif root == "Gb" then parallel = "Eb"
            elseif root == "G"  then parallel = "E"
            elseif root == "G#" then parallel = "E#"
            elseif root == "Ab" then parallel = "F"
            elseif root == "A"  then parallel = "F#"
            elseif root == "A#" then parallel = "G"
            elseif root == "Bb" then parallel = "G"
            elseif root == "B"  then parallel = "G#"
            if not root then end
            end
            end
            
            if chord == "m" or chord == "m7" or chord == "-" or chord == "-7" then pa_chord = "" 
                     
                            if root == "A"  then parallel = "C"
                        elseif root == "A#" then parallel = "C#"
                        elseif root == "Cb" then parallel = "Db"
                        elseif root == "B"  then parallel = "D"
                        elseif root == "B#" then parallel = "D#"
                        elseif root == "C"  then parallel = "Eb"
                        elseif root == "C#" then parallel = "E"
                        elseif root == "D"  then parallel = "F"
                        elseif root == "D#" then parallel = "F#"
                        elseif root == "Eb" then parallel = "Gb"
                        elseif root == "E"  then parallel = "G"
                        elseif root == "E#" then parallel = "G#"
                        elseif root == "F" then parallel = "Ab"
                        elseif root == "F#"  then parallel = "A"
                        elseif root == "G" then parallel = "Bb"
                        elseif root == "G#"  then parallel = "B"
                        if not root then end
                        end
                        end
       
        
               
          sel_itemx = reaper.CountSelectedMediaItems(0)
         itemx = reaper.GetSelectedMediaItem(0,0)
          
      reaper.GetSetMediaItemInfo_String(itemx, "P_NOTES",parallel..pa_chord, true)
      reaper.UpdateArrange()
  
else return end    
end


main() 

end

--====================================================================
--================ CT _ sudden dominant ===================================
--====================================================================

function sudden_dominant()
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n") 
  
end



function get_chord_notes(item0) 
       if item0 == nil then return end      
    _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
  if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
   if string.find(item_notes, "/") then
      root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
   else
      root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
   end
     
     if not chord or #chord == 0 then chord = "Maj" end
     if not slash then slash = "" end

  note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D"  then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E"  then note1 = 4
  elseif root == "F"  then note1 = -7
  elseif root == "F#" then note1 = -6
  elseif root == "Gb" then note1 = -6
  elseif root == "G"  then note1 = -5
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A"  then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B"  then note1 = -1
  if not root then end
  end
  
  slashnote = 255
  -- 48 = C2

  if slash == "/C" then slashnote = -12
  elseif slash == "/C#" then slashnote = -11
  elseif slash == "/Db" then slashnote = -11
  elseif slash == "/D" then slashnote = -10
  elseif slash == "/D#" then slashnote = -9
  elseif slash == "/Eb" then slashnote = -9
  elseif slash == "/E" then slashnote = -8
  elseif slash == "/F" then slashnote = -7
  elseif slash == "/F#" then slashnote = -6
  elseif slash == "/Gb" then slashnote = -6
  elseif slash == "/G" then slashnote = -5
  elseif slash == "/G#" then slashnote = -4
  elseif slash == "/Ab" then slashnote = -4
  elseif slash == "/A" then slashnote = -3
  elseif slash == "/A#" then slashnote = -2
  elseif slash == "/Bb" then slashnote = -2
  elseif slash == "/B" then slashnote = -1
  if not slash then slashnote = 255 end
  end

  note2 = 255
  note3 = 255
  note4 = 255
  note5 = 12
  note6 = 12
  note7 = 12

    if string.find(",Maj,maj7,", ","..chord..",", 1, true) then note2=4  note3=7 note4=12 end      
    if string.find(",m,min,-,", ","..chord..",", 1, true) then note2=3  note3=7 note4=12 end      
    if string.find(",dim,m-5,mb5,m(b5),0,", ","..chord..",", 1, true) then note2=3  note3=6 note4=12 end   
    if string.find(",aug,+,+5,(#5),", ","..chord..",", 1, true) then note2=4  note3=8 end   
    if string.find(",-5,(b5),", ","..chord..",", 1, true) then note2=4  note3=6 end   
    if string.find(",sus2,", ","..chord..",", 1, true) then note2=2  note3=7 end   
    if string.find(",sus4,sus,(sus4),", ","..chord..",", 1, true) then note2=5  note3=7 end   
    if string.find(",5,", ","..chord..",", 1, true) then note2=7 note3=12 end   
    if string.find(",5add7,5/7,", ","..chord..",", 1, true) then note2=7  note3=10 note4=10 end   
    if string.find(",add2,(add2),", ","..chord..",", 1, true) then note2=2  note3=4  note4=7 end   
    if string.find(",add4,(add4),", ","..chord..",", 1, true) then note2=4  note3=5  note4=7 end   
    if string.find(",madd4,m(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7 end   
    if string.find(",11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",11sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",m11,min11,-11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",Maj11,maj11,M11,Maj7(add11),M7(add11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=17 end     
    if string.find(",mMaj11,minmaj11,mM11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17 end  
    if string.find(",aug11,9+11,9aug11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",augm11, m9#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",11b5,11-5,11(b5),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17 end  
    if string.find(",11#5,11+5,11(#5),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17 end  
    if string.find(",11b9,11-9,11(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17 end  
    if string.find(",11#9,11+9,11(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17 end  
    if string.find(",11b5b9,11-5-9,11(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17 end  
    if string.find(",11#5b9,11+5-9,11(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17 end  
    if string.find(",11b5#9,11-5+9,11(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17 end  
    if string.find(",11#5#9,11+5+9,11(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17 end  
    if string.find(",m11b5,m11-5,m11(b5),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17 end  
    if string.find(",m11#5,m11+5,m11(#5),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17 end  
    if string.find(",m11b9,m11-9,m11(b9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17 end  
    if string.find(",m11#9,m11+9,m11(#9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17 end  
    if string.find(",m11b5b9,m11-5-9,m11(b5b9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17 end
    if string.find(",m11#5b9,m11+5-9,m11(#5b9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17 end
    if string.find(",m11b5#9,m11-5+9,m11(b5#9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17 end
    if string.find(",m11#5#9,m11+5+9,m11(#5#9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17 end
    if string.find(",Maj11b5,maj11b5,maj11-5,maj11(b5),", ","..chord..",", 1, true)    then note2=4  note3=6  note4=11  note5=14  note6=17 end
    if string.find(",Maj11#5,maj11#5,maj11+5,maj11(#5),", ","..chord..",", 1, true)    then note2=4  note3=8  note4=11  note5=14  note6=17 end
    if string.find(",Maj11b9,maj11b9,maj11-9,maj11(b9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13  note6=17 end
    if string.find(",Maj11#9,maj11#9,maj11+9,maj11(#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15  note6=17 end
    if string.find(",Maj11b5b9,maj11b5b9,maj11-5-9,maj11(b5b9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=13  note6=17 end
    if string.find(",Maj11#5b9,maj11#5b9,maj11+5-9,maj11(#5b9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=13  note6=17 end
    if string.find(",Maj11b5#9,maj11b5#9,maj11-5+9,maj11(b5#9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=15  note6=17 end
    if string.find(",Maj11#5#9,maj11#5#9,maj11+5+9,maj11(#5#9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=15  note6=17 end
    if string.find(",13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13,min13,-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13,maj13,M13,Maj7(add13),M7(add13),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",mMaj13,minmaj13,mM13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",13b5,13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13#5,13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13b9,13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13#9,13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13b5b9,13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13#5b9,13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13b5#9,13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13#5#9,13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13b9#11,13-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",m13b5,m13-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13#5,m13+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13b9,m13-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13#9,m13+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",m13b5b9,m13-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13#5b9,m13+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13b5#9,m13-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",m13#5#9,m13+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13b5,maj13b5,maj13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13#5,maj13#5,maj13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13b9,maj13b9,maj13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13#9,maj13#9,maj13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13b5b9,maj13b5b9,maj13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13#5b9,maj13#5b9,maj13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13b5#9,maj13b5#9,maj13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13#5#9,maj13#5#9,maj13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13#11,maj13#11,maj13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18  note7=21 end  
    if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",m13#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",13sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",6,M6,Maj6,maj6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9 end   
    if string.find(",m6,min6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9 end   
    if string.find(",6add4,6/4,6(add4),Maj6(add4),M6(add4),", ","..chord..",", 1, true)    then note2=4  note3=5  note4=7  note5=9 end   
    if string.find(",m6add4,m6/4,m6(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=9 end   
    if string.find(",69,6add9,6/9,6(add9),Maj6(add9),M6(add9),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=14 end  
    if string.find(",m6add9,m6/9,m6(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
    if string.find(",6sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=9 end   
    if string.find(",6sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=9 end   
    if string.find(",6add11,6/11,6(add11),Maj6(add11),M6(add11),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=17 end  
    if string.find(",m6add11,m6/11,m6(add11),m6(add11),", ","..chord..",", 1, true)    then note2=3  note3=7  note4=9  note5=17 end  
    if string.find(",7,dom,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=12 note6=16 note7=19 end   
    if string.find(",7add2,", ","..chord..",", 1, true) then note2=2  note3=4  note4=7  note5=10 end  
    if string.find(",7add4,", ","..chord..",", 1, true) then note2=4  note3=5  note4=7  note5=10 end  
    if string.find(",m7,min7,-7,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10 note5=12 note6=15 note7=19 end  
    if string.find(",m7add4,", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=10 end  
    if string.find(",Maj7,maj7,Maj7,M7,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11 end   
    if string.find(",dim7,07,", ","..chord..",", 1, true) then note2=3  note3=6  note4=9 end   
    if string.find(",mMaj7,minmaj7,mmaj7,min/maj7,mM7,m(addM7),m(+7),-(M7),m(maj7),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11 end    
    if string.find(",7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=10 end   
    if string.find(",7sus4,7sus,7sus11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10 end   
    if string.find(",Maj7sus2,maj7sus2,M7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=11 end    
    if string.find(",Maj7sus4,maj7sus4,M7sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11 end    
    if string.find(",aug7,+7,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
    if string.find(",7b5,7-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 end   
    if string.find(",7#5,7+5,7+,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
    if string.find(",m7b5,m7-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10 end   
    if string.find(",m7#5,m7+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10 end   
    if string.find(",Maj7b5,maj7b5,maj7-5,M7b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11 end   
    if string.find(",Maj7#5,maj7#5,maj7+5,M7+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11 end   
    if string.find(",7b9,7-9,7(addb9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13 end  
    if string.find(",7#9,7+9,7(add#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
    if string.find(",m7b9, m7-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13 end  
    if string.find(",m7#9, m7+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15 end  
    if string.find(",Maj7b9,maj7b9,maj7-9,maj7(addb9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13 end 
    if string.find(",Maj7#9,maj7#9,maj7+9,maj7(add#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15 end 
    if string.find(",7b9b13,7-9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=20 end  
    if string.find(",m7b9b13, m7-9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=20 end
    if string.find(",7b13,7-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",m7b13,m7-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",7#9b13,7+9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",m7#9b13,m7+9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",7b5b9,7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13 end  
    if string.find(",7b5#9,7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15 end  
    if string.find(",7#5b9,7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13 end  
    if string.find(",7#5#9,7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15 end  
    if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18 end  
    if string.find(",7add6,7/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10 end  
    if string.find(",7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=17 end  
    if string.find(",7add13,7/13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=21 end  
    if string.find(",m7add11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=17 end  
    if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13 end  
    if string.find(",m7b5#9,m7-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15 end  
    if string.find(",m7#5b9,m7+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13 end  
    if string.find(",m7#5#9,m7+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15 end  
    if string.find(",m7#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=18 end  
    if string.find(",Maj7b5b9,maj7b5b9,maj7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13 end 
    if string.find(",Maj7b5#9,maj7b5#9,maj7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15 end 
    if string.find(",Maj7#5b9,maj7#5b9,maj7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13 end 
    if string.find(",Maj7#5#9,maj7#5#9,maj7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15 end 
    if string.find(",Maj7add11,maj7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=17 end  
    if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=18 end  
    if string.find(",9,7(add9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=16  note7=19 end
    if string.find(",m9,min9,-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14 end  
    if string.find(",Maj9,maj9,M9,Maj7(add9),M7(add9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=14 end 
    if string.find(",Maj9sus4,maj9sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11  note5=14 end  
    if string.find(",mMaj9,minmaj9,mmaj9,min/maj9,mM9,m(addM9),m(+9),-(M9),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11  note5=14 end 
    if string.find(",9sus4,9sus,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 end  
    if string.find(",aug9,+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
    if string.find(",9add6,9/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10  note6=14 end  
    if string.find(",m9add6,m9/6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
    if string.find(",9b5,9-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14 end  
    if string.find(",9#5,9+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14 end  
    if string.find(",m9b5,m9-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14 end  
    if string.find(",m9#5,m9+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14 end  
    if string.find(",Maj9b5,maj9b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14 end  
    if string.find(",Maj9#5,maj9#5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14 end  
    if string.find(",Maj9#11,maj9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18 end  
    if string.find(",b9#11,-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18 end  
    if string.find(",add9,2,", ","..chord..",", 1, true) then note2=4  note3=7  note4=14 end   
    if string.find(",madd9,m(add9),-(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=14 end   
    if string.find(",add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=17 end   
    if string.find(",madd11,m(add11),-(add11),", ","..chord..",", 1, true) then note2=3  note3=7  note4=17 end    
    if string.find(",(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=13 end   
    if string.find(",(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=15 end   
    if string.find(",(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=13 end   
    if string.find(",(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=13 end   
    if string.find(",(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=15 end   
    if string.find(",(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=15 end   
    if string.find(",m(b9), mb9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=13 end   
    if string.find(",m(#9), m#9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=15 end   
    if string.find(",m(b5b9), mb5b9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=13 end   
    if string.find(",m(#5b9), m#5b9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=13 end   
    if string.find(",m(b5#9), mb5#9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=15 end   
    if string.find(",m(#5#9), m#5#9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=15 end   
    if string.find(",m(#11), m#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=18 end   
    if string.find(",(#11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=18 end   
    if string.find(",m#5,", ","..chord..",", 1, true) then note2=3  note3=8 end   
    if string.find(",maug,augaddm3,augadd(m3),", ","..chord..",", 1, true) then note2=3  note3=7 note4=8 end  
    if string.find(",13#9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",13susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=21 end  
    if string.find(",13susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",13sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=17  note6=21 end  
    if string.find(",13sus#5b9,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13sus#5b9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",13sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
    if string.find(",13sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end
    if string.find(",13sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13sus#9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",7b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 note5=17  note6=20 end   
    if string.find(",7b5#9b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=20 end  
    if string.find(",7#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=18 end  
    if string.find(",7#5#9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=18 end  
    if string.find(",7#5b9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=18 end  
    if string.find(",7#9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18 note7=20 end  
    if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=18 end   
    if string.find(",7#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18  note6=20 end  
    if string.find(",7susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10 end   
    if string.find(",7susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13 end  
    if string.find(",7b5b9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=20 end  
    if string.find(",7susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=20 end  
    if string.find(",7susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15 end  
    if string.find(",7susb5#9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=20 end  
    if string.find(",7susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13 end  
    if string.find(",7susb9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=20 end  
    if string.find(",7susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18 end  
    if string.find(",7susb9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=20 end  
    if string.find(",7susb13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=20 end  
    if string.find(",7sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10 end   
    if string.find(",7sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end  
    if string.find(",7sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
    if string.find(",7sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15 end  
    if string.find(",7sus#9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",7sus#9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=20 end  
    if string.find(",7sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18 end  
    if string.find(",7sus#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18  note6=20 end  
    if string.find(",9b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=20 end  
    if string.find(",9b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",9#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=18 end  
    if string.find(",9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=20 end  
    if string.find(",9susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  end  
    if string.find(",9susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14 note6=20 end  
    if string.find(",9sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 note6=18 end  
    if string.find(",9susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=15 end  
    if string.find(",9sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=14  note6=18 end   
    if string.find(",quartal,", ","..chord..",", 1, true) then note2=5  note3=10  note4=15 end
    if string.find(",sowhat,", ","..chord..",", 1, true) then note2=5  note3=10  note4=16 end     

  
end


--MAIN---------------------------------------------------------------
function main()
       
             sel_item = reaper.CountSelectedMediaItems(0)
             
             if sel_item ~= 2 then return end
           
           if sel_item == nil then return end  
               item1 = reaper.GetSelectedMediaItem(0,1) 
               item0 =  reaper.GetSelectedMediaItem(0,0)
               length = reaper.GetMediaItemInfo_Value( item0, "D_LENGTH" )
               reaper.SetMediaItemInfo_Value( item0, "D_LENGTH", length/2 )
 
     -- get_chord_notes(item0) 
      get_chord_notes(item1)
      
          
          
      
         item1 =  reaper.GetSelectedMediaItem(0,1)
         reaper.SetMediaItemInfo_Value( item1, "B_UISEL",0)
         reaper.Main_OnCommand(41295,0) -- duplicate item
         
                if root == "C"  then root_dominant = "G"
            elseif root == "C#" then root_dominant = "G#"
            elseif root == "Db" then root_dominant = "Ab"
            elseif root == "D"  then root_dominant = "A"
            elseif root == "D#" then root_dominant = "A#"
            elseif root == "Eb" then root_dominant = "Bb"
            elseif root == "E"  then root_dominant = "B"
            elseif root == "F"  then root_dominant = "C"
            elseif root == "F#" then root_dominant = "C#"
            elseif root == "Gb" then root_dominant = "Db"
            elseif root == "G"  then root_dominant = "D"
            elseif root == "G#" then root_dominant = "D#"
            elseif root == "Ab" then root_dominant = "Eb"
            elseif root == "A"  then root_dominant = "E"
            elseif root == "A#" then root_dominant = "E#"
            elseif root == "Bb" then root_dominant = "F"
            elseif root == "B"  then root_dominant = "F#"
            if not root then end
            end
       
        
               
          sel_itemx = reaper.CountSelectedMediaItems(0)
          itemx = reaper.GetSelectedMediaItem(0,0)
          
      reaper.GetSetMediaItemInfo_String(itemx, "P_NOTES", root_dominant.."7", true)
      end

  
main() 

end

--==========================================================================================================
--========================== chord_progression ===========================================================
--==========================================================================================================

function chord_progression(a)
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end
reaper.Undo_BeginBlock2(0)

-- x-raym create text item
function CreateTextItem(track, position, length, text, color)
   if track ==  nil then return end
  local item = reaper.AddMediaItemToTrack(track)

  reaper.SetMediaItemInfo_Value(item, "D_POSITION", position)
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)

  if text ~= nil then
    reaper.ULT_SetMediaItemNote(item, text)
  end

  if color ~= nil then
    reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)
  end

  return item

end

--cfillion track by name
function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)

    if ok and trackName == name then
      return track -- found it! stopping the search here
    end
  end
end

if ctrack == nil then Msg("no chordtrack") end
 ctrack = getTrackByName("chordtrack")

if ctrack then -- if a track named "Structure" was found
  reaper.SetOnlyTrackSelected(ctrack)
end

reaper.Main_OnCommand(40289,0) -- Item: Unselect (clear selection of) all items
reaper.Main_OnCommand(40718,0) -- Item: Select all items on selected tracks in current time selection
reaper.Main_OnCommand(40006,0) -- Item: Remove selected area of items
start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
if ctrack then
count_items = reaper.CountTrackMediaItems(ctrack)
end


bpm = reaper.TimeMap2_GetDividedBpmAtTime(0, start_time )
reaper.SetEditCurPos(start_time, false, false )
reaper.Main_OnCommand(41042,0) -- move cursor one measure
one_bar = tonumber((reaper.GetCursorPosition()-start_time))
bar = math.floor(one_bar*10000000000)/10000000000


     c = {[1]={"C",1,"G",1,"Am",1,"Em",1,"F",1,"C",1,"F",1,"G",1}, -- Pachelbel`s Canon progression 
          [2]={"C",1,"Am",1,"F",1,"G",1}, -- 50s progression - I-vi-IV-V
          [3]={"Dm",1,"G",1,"C",1,"C",1}, -- Cadence progression - ii-V-I
          [4]={"C",1,"C",1,"F",1,"G",1},  -- Happy progression - I-I-IV-V
          [5]={"Am",1,"F",1,"C",1,"G",1}, -- Sad 1 progression  vi-IV-I-V
          [6]={"Am",1,"Em",1,"G",1,"F",1}, -- Sad 2 progression  vi-iii-V-IV
          [7]={"Cm",1,"Gm",1,"Bb",1,"Fm",1}, -- Sad 3 progression  i-v-bVII-iv
          [8]={"Cm",1,"Gm",1,"Bb",1,"F",1}, -- sadder progression  i-v-bVII-IV
          [9]={"Am",1,"G",1,"F",1,"G",1}, -- Uplifting progression vi-V-IV-V
         [10]={"C",1,"Bb",1,"Ab",1,"G",1},-- Andalusian Cadence progression I-bVII-BVI-V
         [11]={"C",1,"F",1,"Am",1,"G",1},-- Storyteller progression vi-V-IV-V
         [12]={"C",1,"Dm",1,"C",1,"F",1},-- Bass Player progression
         [13]={"F",1,"C",1,"G",1,"G",1}, -- Journey progression 
         [14]={"F",1,"G",1,"E",1,"Am",1},-- Secondary Dominants progression
         [15]={"Am",1,"Dm",1,"G",1,"C",1},-- Circle progression 
         [16]={"F",1,"Fm",1,"C",1,"C",1},-- Minor Change progression 
         [17]={"C",1,"F",1,"G",1,"G",1},-- La Bamba progression 
         [18]={"C",1,"Ab",1,"Am",1,"G",1},-- Epic progression 
         [19]={"C",4,"F",2,"C",2,"G",1,"F",1,"C",1,"G",1},-- Blues 12-bar progression 
         [20]={"C",1,"F",1,"C",2,"F",2,"C",2,"G",1,"F",1,"C",1,"G",1},-- Blues 12-bar V2 progression vi-V-IV-V
         [21]={"C",1,"Am",1,"Em",1,"D",1},-- Pop 1 progression 
         [22]={"C",1,"G",1,"Am",1,"F",1},-- Pop 2 progression 
         [23]={"C",1,"F",1,"C",1,"G+",1},-- Rock 1 progression 
         [24]={"Cm",1,"Ab",1,"Fm",1,"Fm",1},-- Rock 2 progression 
         [25]={"F",1,"G",1,"Am",1,"C",1},-- Rock 3 progression 
         [26]={"C",1,"C",1,"Bb",1,"F",1},-- Rock 4 progression 
         [27]={"C",1,"G",1,"Dm",1,"F",1},-- Rock 5 progression 
         [28]={"Dm7",1,"G7",1,"Cmaj7",2},-- Jazz 1 
         [29]={"Dm7b5",1,"G7",1,"Cm7",2},-- Jazz 2
         [30]={"Cmaj7",1,"Am7",1,"Dm7",1,"G7",1},-- Jazz 3
         [31]={"Cm7",1,"Am7b5",1,"Dm7b5",1,"G7",1},-- Jazz 4
         [32]={"Em7",1,"A7",1,"Dm7",1,"G7",1},-- Jazz 5
         [33]={"Cmaj7",1,"C#dim7",1,"Dm7",1,"G7",1},-- Jazz 6
         [34]={"Cmaj7",1,"F7",1,"Em7",1,"A7",1},-- Jazz 7
         [35]={"Ebm7",1,"Ab7",1,"Dm7",1,"G7",1,"Cmaj7",2},-- Jazz 8
         [36]={"Dm7",1,"Db7",1,"Cmaj7",2},-- Jazz 9
         [37]={"Cm",1,"Ab",1,"Cm",1,"Gm",1}, -- Trap progression
         [38]={"G",0.5,"Eb",0.5,"C",1}}-- Würm progression 

       
        
        c_name_1 = c[a][1]
        st1 = start_time
        length1 = bar*(c[a][2])
        CreateTextItem(ctrack,st1,length1,c_name_1)
      
        
        c_name_2 = c[a][3]
        st2 = start_time+bar*(c[a][2])
        length2 = bar*(c[a][4])
        CreateTextItem(ctrack,st2,length2,c_name_2)
        
        if c[a][6] == nil then return
        else
                  
        c_name_3 = c[a][5]
        st3 = start_time+bar*(c[a][2]+c[a][4])
        length3 = bar*(c[a][6])
        CreateTextItem(ctrack,st3,length3,c_name_3)
        
        if c[a][8] == nil then return
        else
        
        c_name_4 = c[a][7]
        st4 = start_time+bar*(c[a][2]+c[a][4]+c[a][6])
        length4 = bar*(c[a][8])
        CreateTextItem(ctrack,st4,length4,c_name_4)
        
        if c[a][10] == nil then return
        else
        
        c_name_5 = c[a][9]
        st5 = start_time+bar*(c[a][2]+c[a][4]+c[a][6]+c[a][8])
        length5 = bar*(c[a][10])
        CreateTextItem(ctrack,st5,length5,c_name_5)
        
        if c[a][12] == nil then return
        else
        
        c_name_6 = c[a][11]
        st6 = start_time+bar*(c[a][2]+c[a][4]+c[a][6]+c[a][8]+c[a][10])
        length6 = bar*(c[a][12])
        CreateTextItem(ctrack,st6,length6,c_name_6)
        
        if c[a][14] == nil then return
        else
        
        
        c_name_7 = c[a][13]
        st7 = start_time+bar*(c[a][2]+c[a][4]+c[a][6]+c[a][8]+c[a][10]+c[a][12])
        length7 = bar*(c[a][14])
        CreateTextItem(ctrack,st7,length7,c_name_7)
        
        if c[a][16] == nil then return
        else
        
        
        c_name_8 = c[a][15]
        st8 = start_time+bar*(c[a][2]+c[a][4]+c[a][6]+c[a][8]+c[a][10]+c[a][12]+c[a][14])
        length8 = bar*(c[a][16])
        CreateTextItem(ctrack,st8,length8,c_name_8)
        
        if c[a][18] == nil then return
        else
        
        c_name_9 = c[a][18]
        st9 = start_time+bar*(c[a][2]+c[a][4]+c[a][6]+c[a][8]+c[a][10]+c[a][12]+c[a][14]+c[a][16])
        length9 = bar*(c[a][18])
        CreateTextItem(ctrack,st9,length9,c_name_9)
        
        if c[a][20] == nil then return
        else       
        
        c_name_10 = c[a][21]
        st10 = start_time+bar*(c[a][2]+c[a][4]+c[a][6]+c[a][8]+c[a][10]+c[a][12]+c[a][14]+c[a][16]+c[a][18])
        length10 = bar*(c[a][20])
        CreateTextItem(ctrack,st10,length10,c_name_10)
        
        if c[a][22] == nil then return
        else      
        
        
        c_name_11 = c[a][23]
        st11 = start_time+bar*(c[a][2]+c[a][4]+c[a][6]+c[a][8]+c[a][10]+c[a][12]+c[a][14]+c[a][16]+c[a][18]+c[a][20])
        length11 = bar*(c[a][22])
        CreateTextItem(ctrack,st11,length11,c_name_11)
        
        if c[a][24] == nil then return
        else          
        
        
        c_name_12 = c[a][25]
        st12 = start_time+bar*(c[a][2]+c[a][4]+c[a][6]+c[a][8]+c[a][10]+c[a][12]+c[a][14]+c[a][16]+c[a][18]+c[a][20]+c[a][22])
        length12 = bar*(c[a][24])
        CreateTextItem(ctrack,st12,length12,c_name_12)
        
        reaper.Main_OnCommand(40718,0)
end        
end
end
end
end
end
end
end
end
end
reaper.Main_OnCommand(40718,0)

commandID2 = reaper.NamedCommandLookup("_SWSMARKERLIST13")
--reaper.Main_OnCommand(commandID2, 0) -- SWS: Convert markers to regions
reaper.Undo_EndBlock2(0, "Chords from midi item", -1)
reaper.MIDIEditor_OnCommand( hwnd, 2 ) --File: Close window
end
----------------------------------------------------------------------------------------------------------
------------------------------------delete_region_in Time_selection-----------------------------------------------------------
---------------------------------------------------------------------------------------------------------
function delete_region_in_time_selection()
function bla() end 
  function nothing() reaper.defer(bla) end
  
  local get_start, get_end = reaper.GetSet_LoopTimeRange2(0,false,false,0,0,false)
  if get_end-get_start == 0 then
    nothing() return
  end
  local retval, num_markers, num_regions = reaper.CountProjectMarkers(0)
  if num_regions == 0 then
    nothing() return 
  end
  
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  
  local t_regions = {}

  for i=0, num_markers + num_regions - 1 do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers2(0, i)
    if isrgn == true then
  if pos >= get_start and rgnend <= get_end+0.005 then
    t_regions[#t_regions+1] = markrgnindexnumber
  end
    end
  end
  
  for i=1, #t_regions do
    reaper.DeleteProjectMarker(0, t_regions[i], true)
  end

  reaper.UpdateTimeline()
  reaper.Undo_EndBlock("Delete all regions that have start and end points within the timeselections", -1)
  reaper.PreventUIRefresh(-1)
end  

--------------------------------------------------------------------------------------------------------------
-----------------------------------OTHERS import XML --------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-------- imports suitable xml for the audio track---------
-- script by dragonetti and jkooks ----
function import_xml()
selItemsCount = reaper.CountSelectedMediaItems(0)
if selItemsCount == nil then return end
function bla() end 
  function nothing() reaper.defer(bla) end
reaper.Main_OnCommand(40421,0) -- select all items of the selected track

selItemsTable = {}

selItemsCount = reaper.CountSelectedMediaItems(0)

for i = 0, selItemsCount - 1 do

 local item = reaper.GetSelectedMediaItem(0, i)
 local take = reaper.GetActiveTake(item)
 local source = reaper.GetMediaItemTake_Source( take )
  src_bpm = tonumber(({reaper.CF_GetMediaSourceMetadata( source, "BPM", "" )})[2]) or
   tonumber(({reaper.CF_GetMediaSourceMetadata( source, "bpm", "" )})[2])
 local nameandpath = reaper.GetMediaSourceFileName(source, "",512 )
 local name =   string.sub(nameandpath,1, -5) ..".musicxml"  
 
   
 
  tableIdx = i + 1 -- 1-based table in Lua
  selItemsTable[tableIdx] = {}
  selItemsTable[tableIdx].name = name
  selItemsTable[tableIdx].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
  selItemsTable[tableIdx].playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  selItemsTable[tableIdx].startoffs = reaper.GetMediaItemTakeInfo_Value( take, "D_STARTOFFS" )
  selItemsTable[tableIdx].position = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
  selItemsTable[tableIdx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
  
  
end
if selItemsCount ~= nil then 
reaper.Main_OnCommand(40289,0) --unselect all items
reaper.Main_OnCommand(40001,0) --insert new track
end
 
    
for tableIdx,v in pairs(selItemsTable) do
 reaper.InsertMedia(selItemsTable[tableIdx].name,8)

CountMusicxml = reaper.CountSelectedMediaItems(0) 

end
if selItemsCount ~= nil then
SelTrack = reaper.GetSelectedTrack(0,0)
reaper.GetSetMediaTrackInfo_String(SelTrack, "P_NAME", "musicxml", true)
reaper.SetMediaTrackInfo_Value(SelTrack, "I_HEIGHTOVERRIDE", 100)  
end 

CountXml = reaper.CountSelectedMediaItems(0)

XmlItemCount = reaper.CountTrackMediaItems(SelTrack)             
for i = 0, XmlItemCount - 1 do

ItemXml = reaper.GetTrackMediaItem(SelTrack, i)
TakeXml = reaper.GetMediaItemTake( ItemXml,0 ) 

----------------------------------------------------------------------



reaper.BR_SetMidiTakeTempoInfo( TakeXml, true, src_bpm, src_bpm, 0 ) 

---------------------------------------------------------------------------

--i + 1 cause your array is based on 1

reaper.SetMediaItemTakeInfo_Value(TakeXml, "D_PITCH",selItemsTable[i+1].pitch)
reaper.SetMediaItemTakeInfo_Value(TakeXml, "D_PLAYRATE",selItemsTable[i+1].playrate)
reaper.SetMediaItemTakeInfo_Value(TakeXml, "D_STARTOFFS",selItemsTable[i+1].startoffs)
reaper.SetMediaItemInfo_Value(ItemXml, "D_POSITION",selItemsTable[i+1].position )
reaper.SetMediaItemInfo_Value(ItemXml, "D_LENGTH",selItemsTable[i+1].length )
reaper.SetMediaItemSelected(ItemXml, true)

end
if selItemsCount ~= nil then 
reaper.Main_OnCommand(41737,0) 
reaper.Main_OnCommand(41588,0) ---glue items----
end
local start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false) -- focus to time selection

if start_time ~= end_time then
  reaper.SetEditCurPos2(0, start_time, 1, 0)
end
end

--==================================================================================================================
--============================== OTHER_Generate_MIDI_NOTE ===========================================================
--===================================================================================================================

--end
function generate_midi()


--function generate_midi()
for i=0, reaper.CountSelectedTracks(0) do
--  track = reaper.GetSelectedTrack(0, i)





colors = {0x01000000, 0x01ffffff, 0x01ff0000, 0x0100ffff, 0x01ff00ff, 0x0100ff00,
          0x010000ff, 0x01ffff00, 0x01ff7f00, 0x017f3f00, 0x01ff7f7f, 0x013f3f3f,
          0x017f7f7f, 0x017fff7f, 0x017f7fff, 0x01bfbfbf}

starttime, endtime = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)

_, grid, save_swing, save_swing_amt = reaper.GetSetProjectGrid(0, false)
qnotetime = 240*grid / reaper.Master_GetTempo()
factor = (endtime - starttime)/qnotetime

if starttime == endtime then -- no time selection exists

   -- check if a mediaItem is selected, and if so take its start & end times and delete it
   if reaper.CountSelectedMediaItems() == 0 then
      starttime = reaper.GetCursorPosition()
      endtime = starttime + qnotetime
   else
      selectedItem = reaper.GetSelectedMediaItem(0, 0)
      starttime = reaper.GetMediaItemInfo_Value(selectedItem, "D_POSITION")
      endtime = starttime + reaper.GetMediaItemInfo_Value(selectedItem, "D_LENGTH")
      reaper.DeleteTrackMediaItem(track, selectedItem)
   end      
end

length = (endtime - starttime)
track =  reaper.GetSelectedTrack2( 0, i, 0 )
if track == nil then
    return
    end
cursor = reaper.GetCursorPosition()
midiItem = reaper.CreateNewMIDIItemInProj(track, starttime, starttime+grid)
midiTake = reaper.GetActiveTake(midiItem)
cursor = reaper.GetCursorPosition()
reaper.MIDI_InsertNote(midiTake, true, false, 0, 960*grid*4, 1, 72, 127)

reaper.SetMediaItemInfo_Value(midiItem, "B_LOOPSRC", 1)
reaper.SetMediaItemInfo_Value(midiItem, "B_UISEL", 1)
reaper.SetMediaItemLength(midiItem, length, false)
reaper.GetSetMediaItemTakeInfo_String(midiTake, 'P_NAME',72, true)

reaper.SetMediaItemInfo_Value(midiItem, 'I_CUSTOMCOLOR', reaper.ColorToNative(201,3,57)|0x1000000  )
reaper.Main_OnCommand(40932,0) --split at grod
end

   -------------------------------------------------------
    local function no_undo()reaper.defer(function()end)end;
    -------------------------------------------------------

 
    -------------------------------------------------------
    local function DeleteMediaItem(item);
        if item then;
            local tr = reaper.GetMediaItem_Track(item);
            reaper.DeleteTrackMediaItem(tr,item);
        end;
    end;
    -------------------------------------------------------


    local CountSelItem = reaper.CountSelectedMediaItems(0);
    if CountSelItem == 0 then no_undo() return end;


    local timeSelStart,timeSelEnd = reaper.GetSet_LoopTimeRange(0,0,0,0,0); -- В Аранже
    if timeSelStart == timeSelEnd then no_undo() return end;

    local Undo;

    for i = CountSelItem-1,0,-1 do;

        local SelItem = reaper.GetSelectedMediaItem(0,i);
        local PosIt = reaper.GetMediaItemInfo_Value(SelItem,"D_POSITION");
        local LenIt = reaper.GetMediaItemInfo_Value(SelItem,"D_LENGTH");
        local EndIt = PosIt + LenIt;

        if PosIt < timeSelEnd and EndIt > timeSelStart then;

            if not Undo then reaper.Undo_BeginBlock()Undo=1 end;

            if PosIt < timeSelEnd and EndIt > timeSelEnd then;
                local Right = reaper.SplitMediaItem(SelItem,timeSelEnd);
                if Right then
                    DeleteMediaItem(Right);
                end
            end

            if PosIt < timeSelStart and EndIt > timeSelStart then;
                local Left = reaper.SplitMediaItem(SelItem,timeSelStart);
                if Left then
                    DeleteMediaItem(SelItem);
                end
            end;
        else;
            if not Undo then reaper.Undo_BeginBlock()Undo=1 end;
            DeleteMediaItem(SelItem);
        end;
    end;


    if Undo then;
        reaper.Undo_EndBlock("Delete selected items outside time selection",-1);
    else;
        no_undo();
    end;
    reaper.UpdateArrange();
Msg(track)
::ending::



end
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----GUi Elements
---------------------------------------------------------

-- Here you define the buttons etc that will be in your AMAZING GUI
--                    e.Element:new(tab, x,y,w,h, rgba, label, font, font_sz, font_rgba, val1, val2, min, max, step)

local b=260
local a=10
local c=76
----------------------------- GRID--------------------------------------------------------------------------------------

--local rad_but_1T     = e.Rad_Button:new(  {1},     10 ,  56, 34,   22,    e.col_grey5,  "", e.Arial, 14, e.col_grey8,   {0, 1, 1}, {"1T"}, 0, 12 , 1); rad_but_1T.help = ""
--local rad_but_2T     = e.Rad_Button:new(  {1},     50 ,  56, 34,   22,    e.col_grey5,  "", e.Arial, 14, e.col_grey8,   {0, 1, 1}, {"1/2T"}, 0, 12 , 1); rad_but_2T.help = ""
--local rad_but_4T     = e.Rad_Button:new(  {1},     90 ,  56, 34,   22,    e.col_grey5,  "", e.Arial, 14, e.col_grey8,   {0, 1, 1}, {"1/4T"}, 0, 12 , 1); rad_but_4T.help = ""
--local rad_but_8T     = e.Rad_Button:new(  {1},     130 , 56, 34,   22,    e.col_grey5,  "", e.Arial, 14, e.col_grey8,   {0, 1, 1}, {"1/8T"}, 0, 12 , 1); rad_but_8T.help = ""
--local rad_but_16T     = e.Rad_Button:new(  {1},    170 , 56, 34,   22,    e.col_grey5,  "", e.Arial, 14, e.col_grey8,   {0, 1, 1}, {"1/16T"}, 0, 12 , 1); rad_but_16T.help = ""
--local rad_but_32T     = e.Rad_Button:new(  {1},    210 , 56, 34,   22,    e.col_grey5,  "", e.Arial, 14, e.col_grey8,   {0, 1, 1}, {"1/32T"}, 0, 12 , 1); rad_but_32T.help = ""
--local rad_but_1     = e.Rad_Button:new(  {1},     10 ,  108, 34,   22,    e.col_grey5,  "", e.Arial, 14, e.col_grey8,   {0, 1, 1}, {"1"}, 0, 12 , 1); rad_but_1.help = ""
--local rad_but_2     = e.Rad_Button:new(  {1},     50 ,  108, 34,   22,    e.col_grey5,  "", e.Arial, 14, e.col_grey8,   {0, 1, 1}, {"1/2"}, 0, 12 , 1); rad_but_2.help = ""
--local rad_but_4     = e.Rad_Button:new(  {1},     90 ,  108, 34,   22,    e.col_grey5,  "", e.Arial, 14, e.col_grey8,   {0, 1, 1}, {"1/4"}, 0, 12 , 1); rad_but_4.help = ""
--local rad_but_8     = e.Rad_Button:new(  {1},     130 , 108, 34,   22,    e.col_grey5,  "", e.Arial, 14, e.col_grey8,   {0, 1, 1}, {"1/8"}, 0, 12 , 1); rad_but_8.help = ""
--local rad_but_16     = e.Rad_Button:new(  {1},    170 , 108, 34,   22,    e.col_grey5,  "", e.Arial, 14, e.col_grey8,   {0, 1, 1}, {"1/16"}, 0, 12 , 1); rad_but_16.help = ""
--local rad_but_32     = e.Rad_Button:new(  {1},    210 , 108, 34,   22,    e.col_grey5,  "", e.Arial, 14, e.col_grey8,   {0, 1, 1}, {"1/32"}, 0, 12 , 1); rad_but_32.help = ""

local btn_grid1   = e.Button:new({1},b-208,a+10,100,32, e.col_grey4, "GRID",e.Arial,14, e.col_grey8); btn_grid1.help = "open grid and snap settings"

if grid==1.0 then grids = 1 
elseif grid==0.5 then grids = 2 
elseif grid==0.25 then grids = 3 
elseif grid==0.125 then grids = 4 
elseif grid==0.0625 then grids = 5 
elseif grid==0.03125 then grids = 6 
else grids =5 end




local GridDrop = e.Droplist:new( {1},b- 208 , 54, 100,   100, e.col_grey4, "", e.Arial, 24, e.col_grey8,grids, 
     {"        1", "    1/2", "    1/4", "    1/8","  1/16","  1/32","      1T","  1/2T","  1/4T","  1/8T","1/16T","1/32T"}); GridDrop.help = "grid settings"
     
----------------------- LENGTH -------------------------------------------------
local btn_length          = e.Button:new({1},b-104,a+10,100,32, e.col_grey4, "LENGTH",e.Arial,15, e.col_grey8); btn_length.help = "reset length"
local btn_length_grid     = e.Button:new({1},b-36,a+78,32,32, e.col_grey4, "grid",e.Arial,15, e.col_grey8); btn_length_grid.help = "selected items to grid length"
local btn_length_half      = e.Button:new({1},b-70,a+44,32,32, e.col_grey4, "◄",e.Arial,24, e.col_grey8); btn_length_half.help = "length half"
local btn_length_double    = e.Button:new({1},b-36,a+44,32,32, e.col_grey4, "►",e.Arial,24, e.col_grey8); btn_length_half.help = "length double"
local btn_length_triplet   = e.Button:new({1},b-104,a+44,32,32, e.col_grey4, "tripl",e.Arial,15, e.col_grey8); btn_length_triplet.help = "triple length"
local btn_split_at_grid   = e.Button:new({1},b-104,a+78,66,32, e.col_grey4, "split at grid",e.Arial,14, e.col_grey8); btn_split_at_grid.help = "split at grid"
local btn_length_rand     = e.Button:new({1},b-104,a+112,32,32, e.col_grey4, "rand",e.Arial,15, e.col_grey8); btn_length_rand.help = "random length depending on grid \ndelete items outside the time selection"
local btn_length_input     = e.Button:new({1},b-70,a+112,66,32, e.col_grey4, "SEQ_IN",e.Arial,15, e.col_grey8); btn_length_input.help = "The lengths of the selected items are changed sequentially by digits. \nfactor divides the values by the input"




----------------------------RATE--------------------------------------------------------------------------------
local btn_rate            = e.Button:new({1},b+10,a+10,66,32, e.col_grey4, "RATE",e.Arial,15, e.col_grey8);            btn_rate.help = "reset rate"
local btn_rate_triplet    = e.Button:new({1},b+10,a+44,66,32, e.col_grey4, "triplet",e.Arial,15, e.col_grey8); btn_rate_triplet.help = "playrate to 0.750(triplet)"
local btn_rate_half       = e.Button:new({1},b+10,a+78,32,32, e.col_grey4, "◄",e.Arial,24, e.col_grey8);          btn_rate_half.help = "2x playrate"
local btn_rate_double     = e.Button:new({1},b+44,a+78,32,32, e.col_grey4, "►",e.Arial,24, e.col_grey8);        btn_rate_double.help = "0.5x playrate"
local btn_rate_random     = e.Button:new({1},b+10,a+112,66,32, e.col_grey4, "random",e.Arial,15, e.col_grey8);  btn_rate_random.help = "random rate without changing length"


-------------------------------- SOURCE --------------------------------------------------------
local btn_source =       e.Button:new({1},b+90,a+10,66,32, e.col_grey4, "SOURCE",e.Arial,14, e.col_grey8); btn_source.help = ""
local btn_source_left =  e.Button:new({1},b+90,a+44,32,32, e.col_grey4, "◄",e.Arial,24, e.col_grey8); btn_source_left.help = "Switch item source file to previous in folder "
local btn_source_right = e.Button:new({1},b+124,a+44,32,32, e.col_grey4, "►",e.Arial,24, e.col_grey8); btn_source_right.help = "Switch item source file to next in folder "
local btn_source_rand =  e.Button:new({1},b+90,a+78,66,32, e.col_grey4, "rand src",e.Arial,15,e.col_grey8); btn_source_rand.help = "switch item source file to random in folder\nold source length "
local btn_source_rand2 = e.Button:new({1},b+90,a+112,66,32, e.col_grey4, "rand src.",e.Arial,15,e.col_grey8); btn_source_rand2.help = "switch item source file to random in folder\nnew source length "

-------------------------------- CONTENT --------------------------------------------------------
local btn_startoffs =       e.Button:new({1},b+166,a+10,66,32, e.col_grey4, "CONTENT",e.Arial,14, e.col_grey8); btn_startoffs.help = "reset content to start 0"
local btn_start_left =  e.Button:new({1},b+166,a+44,32,32, e.col_grey4, "◄",e.Arial,24, e.col_grey8); btn_start_left.help = "content one grid left"
local btn_start_right = e.Button:new({1},b+200,a+44,32,32, e.col_grey4, "►",e.Arial,24, e.col_grey8); btn_start_right.help = "content one grid right"
local btn_start_rand =  e.Button:new({1},b+166,a+78,66,32, e.col_grey4, "rand",e.Arial,15,e.col_grey8); btn_start_rand.help = "content start random depending on grid"


------------------------PHRASE-------------------------------------------------------------

local btn_phrase        = e.Button:new(  {1},    b+c+170,a+10,66,32,   e.col_red,  "PHRASE", e.Arial, 16, e.col_grey8); btn_phrase.help = "phrase depending on chord"
local btn_phrase_left   = e.Button:new(  {1},    b+c+170,a+44,32,32,   e.col_grey4,  "◄", e.Arial, 24, e.col_grey8); btn_phrase_left.help = "transpose phrase one fifth to left "
local btn_phrase_right  = e.Button:new(  {1},    b+c+204,a+44,32,32,   e.col_grey4,  "►", e.Arial, 24, e.col_grey8); btn_phrase_right.help = "transpose phrase one fifth to right"
local btn_phrase_2left  = e.Button:new(  {1},    b+c+170,a+78,32,32,   e.col_grey4,  "◄", e.Arial, 24, e.col_grey8); btn_phrase_2left.help = "transpose phrase two fifth to left"
local btn_phrase_2right = e.Button:new(  {1},    b+c+204,a+78,32,32,   e.col_grey4,  "►",      e.Arial, 24, e.col_grey8); btn_phrase_2right.help = "transpose phrase two fifth to right"
--local btn_phrase_rand   = e.Button:new(  {1},    b+c+170,a+112,66,32,  e.col_grey4,  "random", e.Arial, 14, e.col_grey8); btn_phrase_rand.help = "shuffles startoffs depending on grid"


-------------------------------- SCALE --------------------------------------------------------
local btn_scale       = e.Button:new({1},b+c+250,a+10,66,32, e.col_yellow, "SCALE",e.Arial,15, e.col_grey8); btn_scale.help = 
"q,w,e,r... = scale tones     1,0 accent  \n1,2,3... = scale tones +1 \na,s,d... =scale tones -12"
local btn_scale_left  = e.Button:new({1},b+c+250,a+44,32,32, e.col_grey4, "◄",e.Arial,24, e.col_grey8); btn_scale_left.help = "shifts the selected items in the scale by one tone to the left \nfor example c,e,g,b(Cmaj7) becomes b,d,f,a(Bdim)"
local btn_scale_right = e.Button:new({1},b+c+284,a+44,32,32, e.col_grey4, "►",e.Arial,24, e.col_grey8); btn_scale_right.help = "shifts the selected items in the scale by one tone to the right \nfor example c,e,g,b(Cmaj7) becomes d,f,a,c(Dm7)"
local btn_chord       = e.Button:new({1},b+c+250,a+78,66,32, e.col_orange, "CHORD",e.Arial,15,e.col_grey8); btn_chord.help = "pitch items depending on chord"
local btn_chord_up    = e.Button:new({1},b+c+284,a+112,32,32, e.col_grey4, "▲",e.Arial,24, e.col_grey8); btn_chord_up.help = "an inversion of the chord upwards"
local btn_chord_down  = e.Button:new({1},b+c+250,a+112,32,32, e.col_grey4, "▼",e.Arial,24, e.col_grey8); btn_chord_down.help = "an inversion of the chord downwards"



-------------------------------- PITCH --------------------------------------------------------
local btn_pitch         = e.Button:new({1},b+c+330,a+10,100,32, e.col_grey4, "PITCH",e.Arial,15, e.col_grey8); btn_pitch.help = "reset pitch"
local btn_pitch_invers  = e.Button:new({1},b+c+364,a+112,32,32, e.col_grey4, "inv.",e.Arial,15, e.col_grey8); btn_pitch_invers.help = "the scale tones are inverted \nexample(Cmaj7): c e g becomes c a f"
local btn_pitch_com     = e.Button:new({1},b+c+398,a+112,32,32, e.col_grey4, "comp",e.Arial,12, e.col_grey8); btn_pitch_com.help = "pitch above +12 is octaved down \npitch below -12 is octaved up"
local btn_pitch_plus12  = e.Button:new({1},b+c+398,a+44,32,32, e.col_grey4, "+12",e.Arial,15, e.col_grey8); btn_pitch_plus12.help = "pitch +12"
local btn_pitch_minus12 = e.Button:new({1},b+c+398,a+78,32,32, e.col_grey4, "-12",e.Arial,15, e.col_grey8); btn_pitch_minus12.help = "pitch -12"
local btn_pitch_plus1   = e.Button:new({1},b+c+330,a+44,32,32, e.col_grey4, "+1",e.Arial,15, e.col_grey8); btn_pitch_plus1.help = "pitch +1"
local btn_pitch_minus1  = e.Button:new({1},b+c+330,a+78,32,32, e.col_grey4, "-1",e.Arial,15, e.col_grey8); btn_pitch_minus1.help = "pitch-1"
local btn_pitch_plus7   = e.Button:new({1},b+c+364,a+44,32,32, e.col_grey4, "+7",e.Arial,15, e.col_grey8); btn_pitch_plus7.help = "pitch +7"
local btn_pitch_minus7  = e.Button:new({1},b+c+364,a+78,32,32, e.col_grey4, "-7",e.Arial,15, e.col_grey8); btn_pitch_minus7.help = "pitch-7"
local btn_pitch_rand    = e.Button:new({1},b+c+330,a+112,32,32, e.col_grey4, "rand",e.Arial,15, e.col_grey8); btn_pitch_rand.help = "pitch is transposed randomly but within the scale"

-------------------------------- SELECT --------------------------------------------------------
local btn_select_all_items  = e.Button:new({1},b+c+440,a+10,100,32, e.col_grey4, "SELECT",e.Arial,15, e.col_grey8); btn_select_all_items.help = "select all items from selected items tracks"
local btn_select_chord       = e.Button:new({1},b+c+508,a+44,32,32,  e.col_grey4, "chord",e.Arial,14,   e.col_grey8); btn_select_chord.help = "Select only the selected items that are in the chord range \nunder which the cursor is positioned."
local btn_select_next_item  = e.Button:new({1},b+c+508,a+78,32,32,  e.col_grey4, "►",e.Arial,24,    e.col_grey8); btn_select_next_item.help = "select next item"
local btn_select_prev_item  = e.Button:new({1},b+c+440,a+78,32,32,  e.col_grey4, "◄",e.Arial,24,    e.col_grey8); btn_select_prev_item.help = "select previous item"
local btn_select_011        = e.Button:new({1},b+c+508,a+78,32,32,  e.col_grey4, "011",e.Arial,15,    e.col_grey8); btn_select_011.help = "select"
local btn_select_invert     = e.Button:new({1},b+c+474,a+78,32,32,  e.col_grey4, "inv.",e.Arial,15,    e.col_grey8); btn_select_invert.help = "invert selection in time selection"
local btn_select_root_note  = e.Button:new({1},b+c+474,a+112,32,32, e.col_grey4, "root",e.Arial,15, e.col_grey8); btn_select_root_note.help = "select root note"
local btn_select_on_grid    = e.Button:new({1},b+c+508,a+112,32,32, e.col_grey4, "grid",e.Arial,15, e.col_grey8); btn_select_on_grid.help = "only selects items that start on the grid "
local btn_sequenz_select    = e.Button:new({1},b+c+440,a+44,66,32,  e.col_grey4, "sequenz", e.Arial, 14, e.col_grey8); btn_sequenz_select.help = "1=select 0=unselect , make your own pattern \nonly selected items!!"

-------------------------------- MUTE --------------------------------------------------------
local btn_mute      = e.Button:new({1},b+c+550,a+10,66,32, e.col_grey4, "MUTE",e.Arial,15, e.col_grey8); btn_mute.help = "selected items will be muted"
local btn_unmute    = e.Button:new({1},b+c+550,a+78,64,32, e.col_grey4, "unmute",e.Arial,18, e.col_grey8); btn_unmute.help = "selected items will be unmuted"
local btn_mute_rand = e.Button:new({1},b+c+550,a+112,64,32, e.col_grey4, "rand",e.Arial,18, e.col_grey8); btn_mute_rand.help = "selected items will be randomly muted"

-------------------------------- ORDER --------------------------------------------------------
local btn_order         = e.Button:new({1},b+c+624,a+10,66,32, e.col_grey4, "ORDER",e.Arial,15, e.col_grey8); btn_order.help = "phrase depending on chord"
local btn_order_reverse = e.Button:new({1},b+c+624,a+78,66,32, e.col_grey4, "reverse",e.Arial,15, e.col_grey8); btn_order_reverse.help = "reverses the order"
local btn_order_rate    = e.Button:new({1},b+c+624,a+44,32,32, e.col_grey4, "rate",e.Arial,15, e.col_grey8); btn_order_rate.help = "order playrate (ascending)"
local btn_order_pitch   = e.Button:new({1},b+c+658,a+44,32,32, e.col_grey4, "pitch",e.Arial,15, e.col_grey8); btn_order_pitch.help = "Sort selected items by pitch (ascending)"
local btn_order_rand    = e.Button:new({1},b+c+624,a+112,66,32, e.col_grey4, "random",e.Arial,15, e.col_grey8); btn_order_rand.help = "the order of the selected items is changed randomly"

---------------------------------- MIDI ---------------------------------------------------------
local btn_midi          = e.Button:new({1},b+c+696,a+10,66,32,  e.col_green1, "MIDI",e.Arial,15, e.col_grey8)  ; btn_midi.help = "generate midi items with note(C)  on selected tracks \nin time selection "
local btn_midi_single          = e.Button:new({1},b+c+696,a+44,66,32,  e.col_grey4, "SEQ",e.Arial,15, e.col_grey8)  ; btn_midi_single.help = 
"the length of the note is determined by digits\n1=1grid 2=2grid etc. 0=mute1grid\ndepending on grid setting on selected tracks at time selection"
local btn_midi_pattern          = e.Button:new({1},b+c+696,a+78,66,32,  e.col_grey4, "patt.2",e.Arial,15, e.col_grey8)  ; btn_midi_pattern.help = "create random one bar pattern from cursor on selected tracks"
local btn_midi_rand          = e.Button:new({1},b+c+696,a+112,66,32,  e.col_grey4, "patt.1",e.Arial,15, e.col_grey8)  ; btn_midi_rand.help = "create random one bar pattern from cursor on selected tracks"

-------------------------------- CHORDTRACK --------------------------------------------------------
local btn_chordtrack             = e.Button:new({1},b+c+71+696,a+10,134,32, e.col_green2, "CHORDTRACK",e.Arial,15, e.col_grey8)   ; btn_chordtrack.help = "Creates a chordtrack at the top \nif already available - move above selected track"
local btn_chordsymbol_trans_up   = e.Button:new({1},b+c+71+730,a+44,32,32,  e.col_grey4, "▲",e.Arial,15, e.col_grey8)        ; btn_chordsymbol_trans_up.help = "transposes all regions within the time selection up by 1 semitone"
local btn_detect_chord           = e.Button:new({1},b+c+71+696,a+44,32,32,  e.col_grey4, "det.",e.Arial,15, e.col_grey8)   ; btn_detect_chord.help = "chord detection for selected midi items "
local btn_chordsymbol_trans_down = e.Button:new({1},b+c+71+730,a+78,32,32,  e.col_grey4, "▼",e.Arial,15, e.col_grey8)        ; btn_chordsymbol_trans_down.help = "transposes all regions within the time selection down by 1 semitone"
local btn_chordsymbol_right      = e.Button:new({1},b+c+71+696,a+78,32,32,  e.col_grey4, "►",e.Arial,15, e.col_grey8)        ; btn_chordsymbol_right.help = ""
--local btn_chord_prog_rand        = e.Button:new({1},b+c+71+764,a+78,32,32,  e.col_grey4, "rand",e.Arial,15, e.col_grey8)   ; btn_chord_prog_rand.help = "insert random chord progression from cursor position"
local ModulaDrop             = e.Droplist1:new( {1},b+c+71+696,a+112,66,32, e.col_grey4, "modulation", e.Arial, 13, e.col_grey8,1, 
{"","sudden dominant (2items)","minor subdominant (2items)", "subdominant (1items)","parallel key (1item)"}) ; ModulaDrop.help = "the chordtrack can be manipulated here"
local ChordDrop = e.Droplist1:new( {1},b+c+71+764,a+44,66,32, e.col_grey4, "chord prog.", e.Arial, 13, e.col_grey8, 1, 
                  {"","Pachelbel`s Canon  -  C G Am Em F C F G ",
"50s progression  -  C Am F G",
"Cadence progression  -  Dm G C",
"Happy progression  -  C C F G",
"Sad 1 progression  -  Am F C G",
"Sad 2 progression  -  Am Em G F",
"Sad 3 progression  -  Cm Gm Bb Fm",
"Sadder progression  -  Cm Gm Bb F",
"Uplifting progression  -  Am G F G",
"Andalusian Cadence progression  -  Cm Bb Ab G",
"Storyteller progression  -  C F Am G",
"Bass Player progression  -  C Dm C F",
"Journey progression  -  F C G G",
"Secondary Dominants progression  -  F G E Am",
"Circle progression  -  Am Dm G C",
"Minor Change progression  -  F Fm C C",
"La Bamba progression  -  C F G F",
"Epic progression  -  C Ab G G",
"Blues 12-bar progression  -  C(4x) F(2x) C(2x) G F C G",
"Blues 12-bar V2 progression  -  C F C C F F C C G F C G",
"Pop 1 progression  -  C Am Em D",
"Pop 2 progression  -  C G Am F",
"Rock 1 progression  -  C F C G+",
"Rock 2 progression  -  Cm Ab Fm Fm",
"Rock 3 progression  -  F G Am C",
"Rock 4 progression  -  C C Bb F",
"Rock 5 progression  -  C G Dm F",
"Jazz 1  -  ii V I ",
"Jazz 2  -  ii V i",
"Jazz 3  -  I vi ii V",
"Jazz 4  -  i vi ii V",
"Jazz 5  -  iii vi ii V",
"Jazz 6  -  I #idim ii V",
"Jazz 7  -  I IV iii VI",
"Jazz 8  -  #ii #V ii V I",
"Jazz 9  -  ii Tri Sub of V I",
"Trap progression  -  Cm Ab Cm Gm",
"Würm progression  -  G Eb C C"}); 
                    ChordDrop.help = "insert chord progression from time selection start"

-------------------------------- OTHER --------------------------------------------------------
local btn_other         = e.Button:new({1},b+c+106+800,a+10,66,32, e.col_grey4, "OTHER",e.Arial,15, e.col_grey8) ; btn_other.help = "OTHER"
local btn_import_xml    = e.Button:new({1},b+c+106+800,a+44,66,32, e.col_grey4, "XML",e.Arial,18, e.col_grey8)     ; 
btn_import_xml.help     = "import appropriate xml file (if available)\nselect track and don't allow import midi tempo.."
local btn_random_color  = e.Button:new   ({1},b+c+106+800,a+78,66,32, e.col_grey4, "color",e.Arial,18, e.col_grey8)   ; btn_random_color.help = "colors the selected track and its items with a random color"


-----------------------------------------------------------------------------------------------------
local zoomDrop = e.Droplist:new( {1},    10 , 156, 34,   22, e.col_grey4, "", e.Arial, 14, e.col_grey8, 4, {"70%", "80%", "90%", "100%", "110%", "120%", "140%", "160%", "180%", "200%"}); zoomDrop.help = 'popup: Do you want increase the GUI Size ? \nYou can make it bigger or less bigger here, it is saved in proj extstate'
local Status   = e.Status:new ({1}, b+c+170,150,500,60, e.col_grey4, "Info", e.Arial, 20, e.col_grey8) 

--------------------------------
----GUi Actions----------------------
--------------------------------------------

------------------------------------------------------------------------------------------------------
----------GRID-------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

btn_grid1.onLClick = function()reaper.Main_OnCommand(40071,0) 
end 
btn_length_grid.onLClick = function()length_to_grid_x()
end 

reset_rate = reaper.NamedCommandLookup("_SWS_RESETRATE")
btn_rate.onLClick = function()reaper.Main_OnCommand(reset_rate,0)
end 
  
------------------------------------------------------------------------------------------------------
----------LENGTH-------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

btn_length.onLClick = function()reset_rate_length()
end
btn_length_input.onLClick = function()length_input()
end 
btn_length_half.onLClick = function()length_half()
end
btn_length_double.onLClick = function()length_double()
end 
btn_length_triplet.onLClick = function()length_triplet()
end 
btn_length_grid.onLClick = function()length_to_grid_x()
end 
btn_length_rand.onLClick = function()length_random_x()
end   
btn_split_at_grid.onLClick = function()reaper.Main_OnCommand(41119,0)  reaper.Main_OnCommand(40932,0)
end

-----------------------------------------------------------------------------------------------------
-----------------------------------RATE------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

btn_rate.onLClick = function()rate_reset()
end
btn_rate_triplet.onLClick = function()rate_triplet()
end 
btn_rate_half.onLClick = function()rate_double()
end
btn_rate_double.onLClick = function()rate_half()
end
btn_rate_random.onLClick = function()rate_random()
end

------------------------------------------------------------------------------------------------------
----------SOURCE-------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

next_source = reaper.NamedCommandLookup("_XENAKIOS_SISFTNEXTIF")
prev_source = reaper.NamedCommandLookup("_XENAKIOS_SISFTPREVIF")

btn_source_left.onLClick = function()reaper.Main_OnCommand(prev_source,0)
end 
btn_source_right.onLClick = function()reaper.Main_OnCommand(next_source,0)
end
btn_source_rand.onLClick = function()random_source_x()
end
btn_source_rand2.onLClick = function()random_source_length_x()
end   
btn_chord_down.onLClick = function()chord_down_x()
end 
------------------------------------------------------------------------------------------------------
----------CONTENT-------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

btn_startoffs.onLClick = function()reset_content() 
end
btn_start_left.onLClick = function()start_left()
end 
btn_start_right.onLClick = function()start_right()
end
btn_start_rand.onLClick = function()random_startoffs_x()
end

------------------------------------------------------------------------------------------------------
----------PHRASE-------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

btn_phrase.onLClick = function()phrase_builder() 
end 
btn_phrase_left.onLClick = function()phrase_1_left()
end 
btn_phrase_right.onLClick = function()phrase_1_right()
end
btn_phrase_2left.onLClick = function()phrase_2_left()
end 
btn_phrase_2right.onLClick = function()phrase_2_right()
end   
   
------------------------------------------------------------------------------------------------------
---------- SCALE -------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

btn_scale.onLClick = function()scale_builder() 
end 
btn_scale_right.onLClick = function()scale_next()
end 
btn_scale_left.onLClick = function()scale_previous()
end
------------------------------------------------------------------------------------------------------
---------- CHORD -------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

btn_chord.onLClick = function()chord_builder()
end 
btn_chord_up.onLClick = function()chord_up_x()
end   
btn_chord_down.onLClick = function()chord_down_x()
end     
------------------------------------------------------------------------------------------------------
----------PITCH -------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

btn_pitch.onLClick = function() reaper.Main_OnCommand(40653,0) 
end 
btn_pitch_invers.onLClick = function()pitch_invers_x()
end 
btn_pitch_com.onLClick = function()pitch_comp_x()
end
btn_pitch_rand.onLClick = function()pitch_rand_x()
end
btn_pitch_plus12.onLClick = function() reaper.Main_OnCommand(40515,0) 
end 
btn_pitch_minus12.onLClick = function() reaper.Main_OnCommand(40516,0)
end   
btn_pitch_plus1.onLClick = function() reaper.Main_OnCommand(40204,0)
end
btn_pitch_minus1.onLClick = function() reaper.Main_OnCommand(40205,0)
end 
btn_pitch_plus7.onLClick = function() pitch_plus_7()
end
btn_pitch_minus7.onLClick = function() pitch_minus_7()
end

------------------------------------------------------------------------------------------------------
----------SELECT-------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
btn_sequenz_select.onLClick = function()pattern_select()
end
btn_pitch.onLClick = function() reaper.Main_OnCommand(40653,0) 
end 
btn_select_all_items.onLClick = function()select_all_items()
end
btn_select_chord.onLClick = function()select_chord()
end
btn_select_invert.onLClick = function()invert_item_selection()
end
btn_select_next_item.onLClick = function() select_next_item()
end 
btn_select_prev_item.onLClick = function() select_prev_item()
end 
btn_select_root_note.onLClick = function() select_root_note()
end
btn_select_on_grid.onLClick = function() select_only_on_grid()
end

------------------------------------------------------------------------------------------------------
----------MUTE-------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

btn_mute.onLClick = function() reaper.Main_OnCommand(40175,0) 
end 
btn_unmute.onLClick = function()unmute_x()
end 
btn_mute_rand.onLClick = function()mute_rand_x()
end

------------------------------------------------------------------------------------------------------
----------ORDER-------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------


btn_order_reverse.onLClick = function()reverse_items()
end 
btn_order_rand.onLClick = function()shuffle_order()
end 
--btn_order_snap.onLClick = function() item_snap_together()
--end
btn_order_pitch.onLClick = function() order_pitch() 
end
btn_order_rate.onLClick = function() order_rate()
end  

---------------------------------------------------------------------------------------------------------------
----------------- MIDI ----------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
btn_midi.onLClick = function()generate_midi()
end 
btn_midi_single.onLClick = function()midi_pattern3()
end 
btn_midi_pattern.onLClick = function()midi_rand2()
end 
btn_midi_rand.onLClick = function()midi_rand()
end 

------------------------------------------------------------------------------------------------------
----------CHORDTRACK-------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
btn_chordtrack.onLClick = function() create_chordtrack()
end
btn_chordsymbol_trans_up.onLClick = function()chordsymbol_trans_up()
end 
btn_chordsymbol_trans_down.onLClick = function()chordsymbol_trans_down()
end 
btn_chordsymbol_right.onLClick = function()chordsymbol_right()
end 

--math.randomseed(os.time())
--btn_chord_prog_rand.onLClick = function()chord_progression(math.random(1,34))

--end 



----------------------------------------------------------------------------------
---------------------------OTHER---------------------------------------------------
------------------------------------------------------------------------------------
btn_import_xml.onLClick = function()import_xml()
end
btn_random_color.onLClick = function()reaper.Main_OnCommand(40357,0) reaper.Main_OnCommand(40707,0)
end
btn_detect_chord.onLClick = function() detect_midi_chords()
end

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

zoomDrop.onLClick = function() -- window scaling

    if zoomDrop.val1 ==  1 then e.gScale = 0.7
    elseif zoomDrop.val1 ==  2 then e.gScale = 0.8
    elseif zoomDrop.val1 ==  3 then e.gScale = 0.9
    elseif zoomDrop.val1 ==  4 then e.gScale = 1  
    elseif zoomDrop.val1 ==  5 then e.gScale = 1.1
    elseif zoomDrop.val1 ==  6 then e.gScale = 1.2
    elseif zoomDrop.val1 ==  7 then e.gScale = 1.4
    elseif zoomDrop.val1 ==  8 then e.gScale = 1.6
    elseif zoomDrop.val1 ==  9 then e.gScale = 1.8
    elseif zoomDrop.val1 == 10 then e.gScale = 2.0
    elseif zoomDrop.val1 == 11 then e.gScale = 2.0
    elseif zoomDrop.val1 == 12 then e.gScale = 2.0
    end
  -- Save state, close and reopen GFX window
  if not pExtState.x then
    __, script.x, script.y, __, __ = gfx.dock(-1,0,0,0,0)
  else
    -- set project ext state
    pExtState.zoomDrop = zoomDrop.val1
    
    
  end
  script.zoomF = true
end

GridDrop.onLClick = function() -- window scaling

    if GridDrop.val1 ==  1 then reaper.Main_OnCommand(40781,0)
    elseif GridDrop.val1 ==  2 then reaper.Main_OnCommand(40780,0)
    elseif GridDrop.val1 ==  3 then reaper.Main_OnCommand(40779,0)
    elseif GridDrop.val1 ==  4 then reaper.Main_OnCommand(40778,0)
    elseif GridDrop.val1 ==  5 then reaper.Main_OnCommand(40776,0)
    elseif GridDrop.val1 ==  6 then reaper.Main_OnCommand(40775,0)
    elseif GridDrop.val1 ==  7 then reaper.Main_OnCommand(42007,0)
    elseif GridDrop.val1 ==  8 then reaper.Main_OnCommand(42000,0)
    elseif GridDrop.val1 ==  9 then reaper.Main_OnCommand(41214,0)
    elseif GridDrop.val1 == 10 then reaper.Main_OnCommand(40777,0)
    elseif GridDrop.val1 == 11 then reaper.Main_OnCommand(41213,0)
    elseif GridDrop.val1 == 12 then reaper.Main_OnCommand(41212,0)
    end
end

ChordDrop.onLClick = function() -- window scaling

    if ChordDrop.val1 ==  1 then chord_progression(1)
    elseif ChordDrop.val1 ==  2 then chord_progression(2)
    elseif ChordDrop.val1 ==  3 then chord_progression(3)
    elseif ChordDrop.val1 ==  4 then chord_progression(4)
    elseif ChordDrop.val1 ==  5 then chord_progression(5)
    elseif ChordDrop.val1 ==  6 then chord_progression(6)
    elseif ChordDrop.val1 ==  7 then chord_progression(7)
    elseif ChordDrop.val1 ==  8 then chord_progression(8)
    elseif ChordDrop.val1 ==  9 then chord_progression(9)
    elseif ChordDrop.val1 == 10 then chord_progression(10)
    elseif ChordDrop.val1 == 11 then chord_progression(11)
    elseif ChordDrop.val1 == 12 then chord_progression(12)
    elseif ChordDrop.val1 == 13 then chord_progression(13)
    elseif ChordDrop.val1 == 14 then chord_progression(14)
    elseif ChordDrop.val1 == 15 then chord_progression(15)
    elseif ChordDrop.val1 == 16 then chord_progression(16)
    elseif ChordDrop.val1 == 17 then chord_progression(17)
    elseif ChordDrop.val1 == 18 then chord_progression(18)
    elseif ChordDrop.val1 == 19 then chord_progression(19)
    elseif ChordDrop.val1 == 20 then chord_progression(20)
    elseif ChordDrop.val1 == 21 then chord_progression(21)
    elseif ChordDrop.val1 == 22 then chord_progression(22)
    elseif ChordDrop.val1 == 23 then chord_progression(23)
    elseif ChordDrop.val1 == 24 then chord_progression(24)
    elseif ChordDrop.val1 == 25 then chord_progression(25)
    elseif ChordDrop.val1 == 26 then chord_progression(26)
    elseif ChordDrop.val1 == 27 then chord_progression(27)
    elseif ChordDrop.val1 == 28 then chord_progression(28)
    elseif ChordDrop.val1 == 29 then chord_progression(29)
    elseif ChordDrop.val1 == 30 then chord_progression(30)
    elseif ChordDrop.val1 == 31 then chord_progression(31)
    elseif ChordDrop.val1 == 32 then chord_progression(32)
    elseif ChordDrop.val1 == 33 then chord_progression(33)
    elseif ChordDrop.val1 == 34 then chord_progression(34)
    elseif ChordDrop.val1 == 35 then chord_progression(35)
    elseif ChordDrop.val1 == 36 then chord_progression(36)
    elseif ChordDrop.val1 == 37 then chord_progression(37)
    elseif ChordDrop.val1 == 38 then chord_progression(38)
end
end


ModulaDrop.onLClick = function() -- window scaling
    if ModulaDrop.val1 ==  1 then sudden_dominant()
    elseif ModulaDrop.val1 ==  2 then minor_subdominant()
    elseif ModulaDrop.val1 ==  3 then create_subdominant()
    elseif ModulaDrop.val1 ==  4 then create_parallel()
    end
    end
---------------------------------------------------------
----GUi Draw function
---------------------------------------------------------
t_Buttons = {btn_grid1,button01,button02,btn_grid_32,btn_grid,btn_grid_32T,btn_grid_16,btn_grid_8,btn_grid_4,btn_grid_2,btn_grid_1,btn_grid_16T,btn_grid_8T,btn_grid_4T,btn_grid_2T,
btn_grid_1T,btn_grid4T,btn_grid8T,btn_grid16T,btn_grid32T,
btn_length,btn_length_half,btn_length_double,btn_length_triplet,btn_length_grid,btn_length_src,btn_split_at_grid,btn_length_input,
btn_rate,btn_rate_triplet,btn_rate_half,btn_rate_double,btn_rate_grid,btn_rate_random,btn_length_rand,btn_phrase,btn_phrase_left,btn_phrase_right,
btn_phrase_2left,btn_phrase_2right,btn_phrase_rand,btn_source,btn_source_left,btn_source_right,btn_source_rand,btn_reset_content,btn_source_rand2,
btn_startoffs,btn_start_left,btn_start_right,btn_start_rand,btn_start_reset,btn_start_rand2,
btn_scale,btn_scale_left,btn_scale_right,btn_chord,btn_chord_up,btn_chord_down,
btn_pitch,btn_pitch_invers,btn_pitch_com,btn_pitch_plus12,btn_pitch_minus12,btn_pitch_plus1,btn_pitch_minus1,btn_pitch_rand,btn_pitch_plus7,btn_pitch_minus7,
btn_select_on_grid,btn_select_invert,btn_select,btn_select_next_item,btn_select_root_note,btn_select_chord,btn_sequenz_select,
btn_select_prev_item,btn_select_all_items,
btn_mute,btn_unmute,btn_mute_rand,btn_order,btn_order_reverse,btn_order_invers,btn_order_snap,btn_order_rand,btn_order_rate,btn_order_pitch,btn_order_low,
btn_chordtrack,btn_midi_single,btn_midi_pattern,btn_midi_rand,btn_midi,
btn_detect_chord,btn_chordsymbol_trans_up,btn_chordsymbol_trans_down,btn_chordsymbol_right,btn_region_color,btn_chord_prog_rand,btn_other,btn_import_xml,btn_random_color}

sliders = {intslider, floatslider, h_slider_ranger, v_slider_ranger }

other_things = {frame, knob, check, zoomDrop,GridDrop,ChordDrop,ModulaDrop,sequenz_select, rad_but, Text,grid_drop,btn_grid_32,rad_but_1,rad_but_2,rad_but_4,rad_but_8,rad_but_16,rad_but_32,rad_but_1T,rad_but_2T,rad_but_4T,rad_but_8T,rad_but_16T,rad_but_32T }

s = {Status}
--------------------------------------------------------------
-- Define DrawGUI action that will be called in the Main action -- Put here the objects to be draw, in a list or their_name:draw
function DrawGUI() 
  for key, ss in pairs(s) do ss:draw() end
  for key, slid in pairs(sliders) do slid:draw() end  
  for key, v in pairs(other_things) do v:draw() end    
  for key, btn in pairs(t_Buttons) do btn:draw() end
end
---------------------------------------------------------
----Init GFX
---------------------------------------------------------

function SetDefaultWindowOpts()
  if pExtState.zoomDrop then
    zoomDrop.val1 = pExtState.zoomDrop
    zoomDrop.onLClick()
  end
  if pExtState.x or pExtState.y or pExtState.d then
    script.x = pExtState.x
    script.y = pExtState.y
    script.d = pExtState.d
  end
 
  --  rad_but_16.val1 = 1
 --   rad_but_16.onLClick()
     end


-- Get the retina scale
local OS = reaper.GetOS()
scale, gfx.ext_retina = 1, 1 -- init with 1
font_size = 18

function InitGFX()
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
if scale ~= gfx.ext_retina then -- dpi changed (either initially or from the user moving the window or the OS changing
    scale = gfx.ext_retina
    gfx.setfont(1, "Arial", font_size * (1+scale)*0.5)
    -- Resize manually gfx window, if not MacOS
    if OS ~= "OSX64" and OS ~= "OSX32" and OS ~= "macOS-arm64" then
      gfx.init("", desired_width*scale, desired_height*scale)
    end
  end
------------------------------------------------------------------
------------------------------------------------------------
  ----Load extstate:
  __, pExtStateStr = reaper.GetProjExtState(0, script.name, "pExtState")
  if pExtStateStr ~= "" then
    pExtState = unpickle(pExtStateStr)
  end 
  ------------------------------
  ----  Set script.xyd, script.zoom if found in extstate 
  SetDefaultWindowOpts()
  local R,G,B = 50,50,50               -- 0..255 form
  local Wnd_bgd = R + G*256 + B*65536  -- red+green*256+blue*65536 
  gfx.clear = Wnd_bgd
  
  gfx.init("ReaComposer",script.w * e.gScale,script.h * e.gScale,script.d,script.x,script.y)
  gfx.dock(769) -- top
  -----------------
  -- Last mouse position and state:
  gLastMouseCap, gLastMouseX, gLastMouseY = 0, 0, 0
  gMouseOX, gMouseOY = -1, -1
end
---------------------------------------------------------
----Main Loop
---------------------------------------------------------
function MainLoop()
  -- Update mouse state and position
  if gfx.mouse_cap & 1 == 1   and gLastMouseCap & 1  == 0 or    -- L mouse
     gfx.mouse_cap & 2 == 2   and gLastMouseCap & 2  == 0 or    -- R mouse
     gfx.mouse_cap & 64 == 64 and gLastMouseCap & 64 == 0 then  -- M mouse
     gMouseOX, gMouseOY = gfx.mouse_x, gfx.mouse_y 
  end
  -- Set modifier keys
  Ctrl  = gfx.mouse_cap & 4  == 4
  Shift = gfx.mouse_cap & 8  == 8
  Alt   = gfx.mouse_cap & 16 == 16
  
  
  char = gfx.getchar()
  if char == 32 then reaper.Main_OnCommand(40044, 0) end -- Get passthrough key for play/stop (spacebar)
  if char ~= -1 and char ~= 27 then     -- Defer 'MainLoop' if not explicitly quiting (esc)
    reaper.defer(MainLoop) 
  else
    update()
    save()
  end
  
  -- if resized, set scale flag and reset gfx
  if script.zoomF == true then
    e.gScaleState = true
    update()
    save()
    gfx.quit()
    InitGFX()
    script.zoomF = false
  end     
  
  DrawGUI()-- Update Reaper GFX
  e.gScaleState = false  
  -- You can Do things based on results of Draw actions here:

  -----------
  gfx.update() -- Updates GUI
  ------------------------------------------------
  -- Save last mouse state since GUI was refreshed
  gLastMouseCap = gfx.mouse_cap
  gLastMouseX, gLastMouseY = gfx.mouse_x, gfx.mouse_y
  gfx.mouse_wheel = 0 -- reset gfx.mouse_wheel
end

---------------------------------------------------------
----Script
---------------------------------------------------------
InitGFX()
MainLoop()
--reaper.atexit(save)
