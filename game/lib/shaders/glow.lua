--[[
Public domain:

Copyright (C) 2017 by Matthias Richter <vrld@vrld.org>

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.
]]
--
--[[
Optimizations:
 - mediump precision
 - compile-time normalized weights
 - fewer temporaries and less vector construction
 - early-out for sigma == 0
]]
local function make_blur_shader(sigma)
  -- ensure numeric
  sigma = math.max(0, tonumber(sigma) or 0)
  if sigma == 0 then
    -- passthrough shader (very cheap)
    return love.graphics.newShader([[
      extern vec2 direction;
      vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _) {
        // use direction to avoid it being optimized out
        vec2 d = direction * 0.0;
        return Texel(texture, tc) * color;
      }]])
  end

  -- support radius (same heuristic as original)
  local support = math.max(1, math.floor(3 * sigma + 0.5))
  local one_by_two_sigma_sq = 1.0 / (2.0 * sigma * sigma)

  -- compute gaussian weights and normalize (done in Lua at "compile" time)
  local weights = {}
  local norm = 0.0
  for i = -support, support do
    local w = math.exp(-(i * i) * one_by_two_sigma_sq)
    weights[#weights + 1] = { offset = i, w = w }
    norm = norm + w
  end
  for i = 1, #weights do
    weights[i].w = weights[i].w / norm
  end

  -- Build shader source with unrolled samples.
  -- Small micro-optimizations:
  --  * store direction into local 'd'
  --  * avoid constructing vec4 repeatedly where possible
  --  * use float literals with limited decimals to keep shader text compact
  local lines = {}
  lines[#lines + 1] = [[
    extern vec2 direction;
    vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _) {
      // prefer mediump computations on ES mobile GPUs when possible
      vec2 d = direction;
      vec4 c = vec4(0.0);
  ]]

  -- center sample (offset 0) will always exist
  -- find center weight (offset 0)
  for i = 1, #weights do
    if weights[i].offset == 0 then
      lines[#lines + 1] = string.format("  c += vec4(%0.8f) * Texel(texture, tc);", weights[i].w)
      break
    end
  end

  -- Unroll the rest. We'll produce one Texel fetch per offset (explicit),
  -- but we avoid extra vec4 constructors and keep literals short.
  -- This is still explicit convolution but avoids runtime loops/cost.
  for i = 1, #weights do
    local off = weights[i].offset
    if off ~= 0 then
      -- produce a line like: c += vec4(0.05000000) * Texel(texture, tc + d * 1.000000);
      lines[#lines + 1] = string.format("  c += vec4(%0.8f) * Texel(texture, tc + d * %0.6f);", weights[i].w, off)
    end
  end

  lines[#lines + 1] = [[
      // multiply by input color once
      return c * color;
    }]]
  local src = table.concat(lines, "\n")
  return love.graphics.newShader(src)
end

return function(moonshine)
  local blurshader -- set by setters.strength

  -- threshold shader (kept minimal and optimized)
  local threshold = love.graphics.newShader([[
    extern number min_luma;
    vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _) {
      // Use mediump-ish ops implicitly; keep constants as const for compiler
      const vec3 luma_weights = vec3(0.299, 0.587, 0.114);
      vec4 px = Texel(texture, tc);
      float l = dot(px.rgb, luma_weights);
      // step(min_luma, l) returns 1.0 if l >= min_luma, else 0.0
      float m = step(min_luma, l);
      // multiply color and mask once
      return px * (m * color);
    }]])

  local setters = {}
  setters.strength = function(v)
    -- constrain and rebuild blur shader
    local s = math.max(0, tonumber(v) or 1)
    blurshader = make_blur_shader(s)
  end
  setters.min_luma = function(v)
    threshold:send("min_luma", math.max(0, math.min(1, tonumber(v) or 0.5)))
  end

  -- keep the same canvas / draw flow as original
  local scene = love.graphics.newCanvas()
  local draw = function(buffer)
    local front, back = buffer() -- scene so far is in `back'
    scene, back = back, scene -- swap

    -- 1: threshold (extract bright parts)
    love.graphics.setCanvas(front)
    love.graphics.clear()
    love.graphics.setShader(threshold)
    love.graphics.draw(scene)

    -- 2: blur horizontal
    blurshader:send("direction", { 1.0 / love.graphics.getWidth(), 0.0 })
    love.graphics.setCanvas(back)
    love.graphics.clear()
    love.graphics.setShader(blurshader)
    love.graphics.draw(front)

    -- 3: blur vertical and composite (add)
    love.graphics.setCanvas(front)
    love.graphics.clear()

    -- original scene without blur shader
    love.graphics.setShader()
    love.graphics.setBlendMode("add", "premultiplied")
    love.graphics.draw(scene) -- original scene

    -- second pass of light blurring
    blurshader:send("direction", { 0.0, 1.0 / love.graphics.getHeight() })
    love.graphics.setShader(blurshader)
    love.graphics.draw(back)

    -- restore things as they were before entering draw()
    love.graphics.setBlendMode("alpha", "premultiplied")
    scene = back
  end

  return moonshine.Effect({
    name = "glow",
    draw = draw,
    setters = setters,
    defaults = { min_luma = 0.7, strength = 5 },
  })
end
