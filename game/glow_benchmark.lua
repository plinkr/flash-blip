local Settings = require("settings")

local GlowBenchmark = {
  glow_testing = false,
  glow_start_time = 0,
  glow_warmup_end = 0,
  glow_test_end = 0,
  glow_frame_count = 0,
  glow_notice_message = "",
  glow_notice_timer = 0,
  glow_needs_benchmark = false,
  on_glow_disabled = nil,
}

function GlowBenchmark.init()
  GlowBenchmark.glow_needs_benchmark = Settings.IS_GLOW_ENABLED
    and (Settings.IS_MOBILE or Settings.IS_WEB)
    and not Settings.HAS_PASSED_GLOW_TEST
end

function GlowBenchmark.set_on_glow_disabled(callback)
  GlowBenchmark.on_glow_disabled = callback
end

function GlowBenchmark.start()
  GlowBenchmark.glow_testing = true
  local now = love.timer.getTime()
  GlowBenchmark.glow_start_time = now
  GlowBenchmark.glow_warmup_end = now + 0.5
  GlowBenchmark.glow_test_end = now + 3.0
  GlowBenchmark.glow_frame_count = 0
  GlowBenchmark.glow_notice_message = ""
  GlowBenchmark.glow_notice_timer = 0
  GlowBenchmark.glow_needs_benchmark = false
end

function GlowBenchmark.stop()
  GlowBenchmark.glow_testing = false
  GlowBenchmark.glow_needs_benchmark = false
end

function GlowBenchmark.is_benchmark_needed()
  return GlowBenchmark.glow_needs_benchmark
end

function GlowBenchmark.is_testing()
  return GlowBenchmark.glow_testing
end

function GlowBenchmark.get_notice()
  return GlowBenchmark.glow_notice_message
end

function GlowBenchmark.get_notice_timer()
  return GlowBenchmark.glow_notice_timer
end

function GlowBenchmark._disable()
  Settings.IS_GLOW_ENABLED = false
  Settings.HAS_PASSED_GLOW_TEST = false
  Settings.save_debounced()
  if GlowBenchmark.on_glow_disabled then
    GlowBenchmark.on_glow_disabled()
  end
  GlowBenchmark.glow_testing = false
  GlowBenchmark.glow_needs_benchmark = false
  GlowBenchmark.glow_notice_message = "GLOW DISABLED: UNSUPPORTED / LOW FPS"
  GlowBenchmark.glow_notice_timer = 4.0
end

function GlowBenchmark.update(dt)
  if GlowBenchmark.glow_notice_timer > 0 then
    GlowBenchmark.glow_notice_timer = GlowBenchmark.glow_notice_timer - dt
  end

  if not GlowBenchmark.glow_testing then
    return
  end

  local now = love.timer.getTime()
  local total_elapsed = now - GlowBenchmark.glow_start_time

  -- Warmup phase (first 0.5 seconds of wall time)
  if now < GlowBenchmark.glow_warmup_end then
    return
  end

  GlowBenchmark.glow_frame_count = GlowBenchmark.glow_frame_count + 1
  local sample_elapsed = now - GlowBenchmark.glow_warmup_end

  -- Check FPS continuously after 0.3 seconds of active sampling
  if sample_elapsed >= 0.3 then
    local real_fps = GlowBenchmark.glow_frame_count / sample_elapsed
    if real_fps < 25 then
      GlowBenchmark._disable()
      return
    end
  end

  -- maximum 3.0 seconds total wall time for testing
  if total_elapsed >= 3.0 then
    if sample_elapsed > 0 then
      local final_fps = GlowBenchmark.glow_frame_count / sample_elapsed
      if final_fps < 25 then
        GlowBenchmark._disable()
        return
      end
    end

    GlowBenchmark.glow_notice_message = "GLOW SUPPORTED"
    GlowBenchmark.glow_notice_timer = 2.0
    Settings.HAS_PASSED_GLOW_TEST = true
    Settings.save_debounced()
    GlowBenchmark.glow_testing = false
    GlowBenchmark.glow_needs_benchmark = false
    return
  end
end

function GlowBenchmark.draw() end

return GlowBenchmark
