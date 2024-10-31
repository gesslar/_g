---@diagnostic disable-next-line: undefined-global
local mod = mod or {}
local script_name = "colour"
function mod.new(parent)
  local instance = { parent = parent, ___ = (function(p)
      while p.parent do p = p.parent end
      return p
    end)(parent)
  }

  --- Interpolates between two RGB colours based on a step value. Functionally,
  --- it takes two colours and returns a third colour somewhere between the
  --- two colours, based on the step value. Generally used to fade between two
  --- colours. The step value is the current transition percentage as a whole
  --- number between the two colours, with 0 being the first colour and 100 being
  --- the second colour.
  ---
  --- @example
  --- ```lua
  --- colour:interpolate({255, 0, 0}, {0, 0, 255}, 50)
  --- -- {127, 0, 127}
  --- ```
  --- @param rgb1 table - The first RGB colour as a table with three elements: red, green, and blue.
  --- @param rgb2 table - The second RGB colour as a table with three elements: red, green, and blue.
  --- @param step number - The step value between 1 and 100.
  --- @return table - The interpolated RGB colour as a table with three elements: red, green, and blue.
  function instance:interpolate(rgb1, rgb2, step)
    self.___.valid:rgb_table(rgb1, 1, false)
    self.___.valid:rgb_table(rgb2, 2, false)
    self.___.valid:type(step, "number", 3, false)
    self.___.valid:test(step >= 0 and step <= 100,  step, 3, "Invalid step " ..
    "value " .. step .. " given. Step value must be between 0 and 100.")

    local r1, g1, b1 = rgb1[1], rgb1[2], rgb1[3]
    local r2, g2, b2 = rgb2[1], rgb2[2], rgb2[3]

    local factor = step / 100

    local r, g, b = math.floor(r1 + (r2 - r1) * factor + 0.5),
                    math.floor(g1 + (g2 - g1) * factor + 0.5),
                    math.floor(b1 + (b2 - b1) * factor + 0.5)

    return { r, g, b }
  end

  --- Determines if a colour is a light colour.
  --- @param rgb table - The RGB colour as a table with three elements: red, green, and blue.
  --- @return boolean - True if the colour is light, false otherwise.
  ---
  --- @example
  --- ```lua
  --- colour:is_light({255, 255, 255})
  --- -- true
  --- ```
  function instance:is_light(rgb)
    self.___.valid:rgb_table(rgb, 1, false)

    local r = rgb[1] / 255
    local g = rgb[2] / 255
    local b = rgb[3] / 255
    local luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
    return luminance > 0.5
  end

  --- Lightens or darkens a colour by a given amount.
  ---
  --- @param rgb table - The RGB colour as a table with three elements: red, green, and blue.
  --- @param amount number - The amount to adjust the colour by.
  --- @param lighten boolean - Whether to lighten (true) or darken (false) the colour.
  --- @return table - The adjusted RGB colour as a table with three elements: red, green, and blue.
  function instance:adjust_colour(rgb, amount, lighten)
    self.___.valid:rgb_table(rgb, 1, false)
    self.___.valid:type(amount, "number", 2, true)

    amount = self.___.number:clamp(amount or 30, 0, 255)

    local factor = lighten and 1 or -1

    return {
      self.___.number:clamp(rgb[1] + factor * amount, 0, 255),
      self.___.number:clamp(rgb[2] + factor * amount, 0, 255),
      self.___.number:clamp(rgb[3] + factor * amount, 0, 255)
    }
  end

  --- Lightens a colour by a given amount.
  ---
  --- @param rgb table - The RGB colour as a table with three elements: red, green, and blue.
  --- @param amount number - The amount to lighten the colour by. (Optional, defaults to 30)
  --- @return table - The lightened RGB colour as a table with three elements: red, green, and blue.
  ---
  --- @example
  --- ```lua
  --- colour:lighten({100,100,100},50)
  --- -- {150, 150, 150}
  --- ```
  function instance:lighten(rgb, amount)
    return self:adjust_colour(rgb, amount, true)
  end

  --- Darkens a colour by a given amount.
  ---
  --- @param rgb table - The RGB colour as a table with three elements: red, green, and blue.
  --- @param amount number - The amount to darken the colour by. (Optional, defaults to 30)
  --- @return table - The darkened RGB colour as a table with three elements: red, green, and blue.
  ---
  --- @example
  --- ```lua
  --- colour:darken({100,100,100},50)
  --- -- {50, 50, 50}
  --- ```
  function instance:darken(rgb, amount)
    return self:adjust_colour(rgb, amount, false)
  end

  --- Lightens or darkens the first colour by a given amount based on a comparison with the second colour.
  --- If the colours are already contrasting, the original colour is returned.
  --- @param rgb_compare table - The first RGB colour as a table with three elements: red, green, and blue.
  --- @param rgb_colour table - The second RGB colour as a table with three elements: red, green, and blue.
  --- @param amount number - The amount to lighten or darken the colour by. (Optional, defaults to 85)
  --- @return table - The adjusted RGB colour as a table with three elements: red, green, and blue. Unless the colours are already constrasted, in which case the original colour is returned.
  ---
  --- @example
  --- ```lua
  --- colour:lighten_or_darken({100,100,100}, {255,255,255}, 50)
  --- -- {100, 100, 100}
  ---
  --- -- If you want to a light or dark version of the same colour, you can use this:
  --- -- This is useful if you aren't sure what the colour is, but you want to
  --- -- have a contrasting shade.
  --- colour:lighten_or_darken({255,255,255}, {255,255,255}, 50)
  --- -- {205, 205, 205}
  --- ```
  function instance:lighten_or_darken(rgb_colour, rgb_compare, amount)
    self.___.valid:type(amount, "number", 3, true)

    amount = amount or 85

    local colour_is_light = self:is_light(rgb_colour) and 1 or 0
    local compare_is_light = self:is_light(rgb_compare) and 1 or 0

    if colour_is_light > compare_is_light then
      return self:darken(rgb_colour, amount)
    elseif colour_is_light < compare_is_light then
      return self:lighten(rgb_colour, amount)
    else
      return rgb_colour
    end
  end

  --- Returns the complementary colour of a given colour.
  --- @example
  --- ```lua
  --- colour:complementary({ 150, 150, 150 })
  --- -- { 105, 105, 105 }
  --- ```
  --- @param rgb table - The RGB colour as a table with three elements: red, green, and blue.
  --- @return table - The complementary RGB colour as a table with three elements: red, green, and blue.
  function instance:complementary(rgb)
    self.___.valid:rgb_table(rgb, 1, false)

    return { 255 - rgb[1], 255 - rgb[2], 255 - rgb[3] }
  end

  --- Converts a colour to its grayscale equivalent.
  --- @example
  --- ```lua
  --- colour:grayscale({ 35, 50, 100 })
  --- -- { 62, 62, 62 }
  --- ```
  --- @param rgb table - The RGB colour as a table with three elements: red, green, and blue.
  --- @return table - The grayscale RGB colour as a table with three elements: red, green, and blue.
  function instance:grayscale(rgb)
    self.___.valid:rgb_table(rgb, 1, false)

    local gray = math.floor((rgb[1] + rgb[2] + rgb[3]) / 3 + 0.5)
    return { gray, gray, gray }
  end

  --- Adjusts the saturation of a colour by a given factor.
  --- @example
  --- ```lua
  --- colour:adjust_saturation({ 35, 50, 100 }, 0.5)
  --- -- { 48, 55, 80 }
  --- ```
  --- @param rgb table - The RGB colour as a table with three elements: red, green, and blue.
  --- @param factor number - A factor between 0 (fully desaturated) and 1 (fully saturated).
  --- @return table - The adjusted RGB colour as a table with three elements: red, green, and blue.
  function instance:adjust_saturation(rgb, factor)
    self.___.valid:rgb_table(rgb, 1, false)
    self.___.valid:type(factor, "number", 2, true)

    local gray = (rgb[1] + rgb[2] + rgb[3]) / 3
    return {
      math.floor(gray + (rgb[1] - gray) * factor),
      math.floor(gray + (rgb[2] - gray) * factor),
      math.floor(gray + (rgb[3] - gray) * factor)
    }
  end

  --- Generates a random RGB colour.
  --- @example
  --- ```lua
  --- colour:random()
  --- -- { 123, 45, 67 }
  --- ```
  --- @return table - A random RGB colour as a table with three elements: red, green, and blue.
  function instance:random()
    return { math.random(0, 255), math.random(0, 255), math.random(0, 255) }
  end

  --- Generates a random shade of a given colour within a range.
  --- @example
  --- ```lua
  --- colour:random_shade({ 100, 100, 100 }, 50)
  --- -- { 150, 150, 150 }
  --- ```
  --- @param rgb table - The RGB colour as a table with three elements: red, green, and blue.
  --- @param range number - The range to adjust the colour by (e.g., 50 means +/- 50 for R, G, and B). (Optional, defaults to 50)
  --- @return table - A random RGB colour that is a shade of the given colour.
  function instance:random_shade(rgb, range)
    self.___.valid:rgb_table(rgb, 1, false)
    self.___.valid:type(range, "number", 2, true)

    range = range or 50

    local r = math.random(math.max(0, rgb[1] - range), math.min(255, rgb[1] + range))
    local g = math.random(math.max(0, rgb[2] - range), math.min(255, rgb[2] + range))
    local b = math.random(math.max(0, rgb[3] - range), math.min(255, rgb[3] + range))
    return { r, g, b }
  end

  --- Generates the triad colours of a given colour. Does not return the
  --- original colour, but two returned colours that are considered tritones of
  --- the original colour.
  --- @example
  --- ```lua
  --- colour:generate_triad({ 100, 100, 100 })
  --- -- { { 15, 204, 204 }, { 100, 204, 204 } }
  --- ```
  --- @param rgb table - The RGB colour as a table with three elements: red, green, and blue.
  --- @return table - A table of RGB colours that are the triad of the given colour.
  function instance:generate_triad(rgb)
    self.___.valid:rgb_table(rgb, 1, false)

    local angle = 120
    local h = (rgb[1] / 255 + angle / 360) % 1
    local s = 0.8
    local v = 0.8

    local h1 = (h + 1 / 3) % 1
    local h2 = (h - 1 / 3) % 1

    local rgb1 = { h1 * 255, s * 255, v * 255 }
    local rgb2 = { h2 * 255, s * 255, v * 255 }

    return { rgb1, rgb2 }
  end

  return instance
end

-- Let Glu know we're here
raiseEvent("glu_module_loaded", script_name, mod)

return mod
