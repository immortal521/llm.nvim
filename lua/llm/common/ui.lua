local Popup = require("nui.popup")
local conf = require("llm.config")
local LOG = require("llm.common.log")

local ui = {}

function ui.FlexibleWindow(str, enter_flexible_win, user_opts)
  local text = vim.split(str, "\n")
  local width = 0
  local height = #text
  local max_win_width = math.floor(vim.o.columns * 0.7)
  local max_win_height = math.floor(vim.o.lines * 0.7)
  for i, line in ipairs(text) do
    if vim.api.nvim_strwidth(line) > width then
      width = vim.api.nvim_strwidth(line)
      if width > max_win_width then
        height = height + 1
      end
    end
    text[i] = "" .. line
  end

  local win_width = math.min(width, max_win_width)
  local win_height = math.min(height, max_win_height)
  if win_width < 1 or win_height < 1 then
    LOG:ERROR(
      string.format("Unable to create a window with width %s and height %s.", tostring(win_width), tostring(win_height))
    )
    return nil
  end

  local opts = {
    relative = "cursor",
    position = {
      row = -2,
      col = 0,
    },
    size = {
      height = win_height,
      width = win_width,
    },
    enter = enter_flexible_win,
    focusable = true,
    zindex = 50,
    border = {
      style = "rounded",
    },
    win_options = {
      winblend = 0,
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    },
  }

  opts = vim.tbl_deep_extend("force", opts, user_opts or {})
  local flexible_box = Popup(opts)

  vim.api.nvim_buf_set_lines(flexible_box.bufnr, 0, -1, false, text)
  return flexible_box
end

function ui.wait_ui_opts(win_opts)
  local ui_width = vim.api.nvim_strwidth(conf.configs.spinner.text[1])
  local opts = {
    relative = "cursor",
    position = {
      row = -1,
      col = 1,
    },
    size = {
      height = 1,
      width = ui_width,
    },
    enter = false,
    focusable = true,
    zindex = 50,
    border = {
      style = "none",
    },
    win_options = {
      winblend = 0,
      winhighlight = "Normal:NONE,FloatBorder:FloatBorder",
    },
  }
  opts = vim.tbl_deep_extend("force", opts, win_opts or {})
  return opts
end

function ui.show_spinner(waiting_state)
  local spinner_frames = conf.configs.spinner.text
  local spinner_hl = conf.configs.spinner.hl
  local frame = 1

  local timer = vim.loop.new_timer()
  timer:start(
    0,
    100,
    vim.schedule_wrap(function()
      if waiting_state.box then
        waiting_state.box:unmount()
        if not waiting_state.finish then
          waiting_state.box = Popup(waiting_state.box_opts)
          waiting_state.box:mount()
          waiting_state.bufnr = waiting_state.box.bufnr
          waiting_state.winid = waiting_state.box.winid
        end
      end
      if not vim.api.nvim_win_is_valid(waiting_state.winid) then
        timer:stop()
        return
      end

      vim.api.nvim_buf_set_lines(waiting_state.bufnr, 0, -1, false, { spinner_frames[frame] })
      vim.api.nvim_buf_add_highlight(waiting_state.bufnr, -1, spinner_hl, 0, 0, -1)

      frame = frame % #spinner_frames + 1
    end)
  )
end
return ui
