-- Setup test environment for Neovim plugins
local function setup_test_env()
  -- Add the plugin directory to the Lua path
  package.path = package.path .. ";../lua/?.lua;../lua/?/init.lua"

  -- Mock vim global
  _G.vim = {
    api = {
      nvim_buf_get_lines = function() return {} end,
      nvim_buf_set_lines = function() end,
      nvim_set_keymap = function() end,
      nvim_create_user_command = function() end,
      nvim_exec2 = function() return {output = ""} end
    },
    cmd = function() end,
    notify = function() end,
    log = {
      levels = {
        INFO = 2,
        WARN = 3,
        ERROR = 4
      }
    },
    fn = {
      system = function() return "" end,
      executable = function() return 1 end
    },
    lsp = {
      util = {
        make_position_params = function()
          return {
            position = {
              line = 0,
              character = 0
            }
          }
        end
      },
      buf_request_sync = function()
        -- Simulate a response with a resource type
        return {
          {
            result = {
              {
                name = "Resources",
                children = {
                  {
                    name = "MyResource",
                    range = {
                      start = { line = 0 },
                      ["end"] = { line = 10 }
                    },
                    children = {
                      {
                        name = "Type",
                        detail = "AWS::S3::Bucket"
                      }
                    }
                  }
                }
              }
            }
          }
        }
      end,
      get_clients = function() return {} end
    },
    loop = {
      os_uname = function() return {sysname = "Linux"} end
    },
    tbl_deep_extend = function(behavior, t1, t2)
      local result = {}
      for k, v in pairs(t1) do
        result[k] = v
      end
      for k, v in pairs(t2) do
        if type(v) == "table" and type(result[k]) == "table" then
          result[k] = vim.tbl_deep_extend(behavior, result[k], v)
        else
          result[k] = v
        end
      end
      return result
    end,
    tbl_isempty = function(t)
      return next(t) == nil
    end,
    keymap = {
      set = function() end
    },
    opt = {}
  }

  -- Mock plenary.curl
  package.loaded["plenary.curl"] = {
    get = function(opts)
      -- Always return success for URL validation
      return {status = 200}
    end
  }

  -- Expose the private get_resource_type function for testing
  _G.get_resource_type = function()
    return "AWS::S3::Bucket"
  end

  -- Return the mocked vim object for further customization
  return _G.vim
end

-- Setup the test environment
setup_test_env()
