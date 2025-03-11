local LOG = require("llm.common.log")
local sess = require("llm.session")
local conf = require("llm.config")
local F = require("llm.common.api")
local diff = require("llm.common.diff_style")
local utils = require("llm.tools.utils")
local state = require("llm.state")
local M = {}

function M.handler(_, _, _, _, _, opts)
  local default_actions = {
    display = function()
      if diff.style == nil then
        diff = diff:update()
      end

      local display_opts = {}
      setmetatable(display_opts, {
        __index = state.summarize_suggestions,
      })
      utils.new_diff(diff, display_opts.pattern, display_opts.ctx, display_opts.assistant_output)
      F.CloseLLM()
    end,
    accept = function()
      if diff and diff.valid then
        diff:accept()
      end
    end,
    reject = function()
      if diff and diff.valid then
        diff:reject()
      end
    end,
    close = function()
      if diff and diff.valid then
        diff:reject()
      end
    end,
  }
  local options = {
    is_codeblock = false,
    inline_assistant = false,
    language = "English",

    display = {
      mapping = {
        mode = "n",
        keys = { "d" },
      },
      action = nil,
    },
    accept = {
      mapping = {
        mode = "n",
        keys = { "Y", "y" },
      },
      action = nil,
    },
    reject = {
      mapping = {
        mode = "n",
        keys = { "N", "n" },
      },
      action = nil,
    },
    close = {
      mapping = {
        mode = "n",
        keys = { "<esc>" },
      },
      action = nil,
    },
  }
  options = vim.tbl_deep_extend("force", options, opts or {})

  local bufnr = F.GetAttach(options)
  LOG:INFO("Attach successfully!")

  for _, k in ipairs({ "accept", "reject", "close" }) do
    utils.set_keymapping(options[k].mapping.mode, options[k].mapping.keys, function()
      default_actions[k]()
      if options[k].action ~= nil then
        options[k].action()
      end
      if k == "close" then
        for _, kk in ipairs({ "accept", "reject", "close" }) do
          utils.clear_keymapping(options[kk].mapping.mode, options[kk].mapping.keys, bufnr)
        end
      end
    end, bufnr)
  end

  if conf.session.status == -1 then
    sess.NewSession()
  end

  local bufnr_list = F.get_chat_ui_bufnr_list()
  for _, ui_bufnr in ipairs(bufnr_list) do
    utils.set_keymapping(options.display.mapping.mode, options.display.mapping.keys, function()
      default_actions.display()
      if options.display.action ~= nil then
        options.display.action()
      end
    end, ui_bufnr)
  end
end

return M
