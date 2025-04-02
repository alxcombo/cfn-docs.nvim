# cfn-docs.nvim

A Neovim plugin for accessing AWS CloudFormation documentation directly from your editor.

## Features

- Generate documentation URLs for CloudFormation resources
- Open documentation in browser or terminal
- Copy documentation URLs to clipboard
- Support for LSP integration

## Installation and Configuration

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
  {
    "alxcombo/cfn-docs.nvim"
    config = function()
      require("cfn-docs").setup({
        verbosity = 0,
        use_w3m = true,
        keymaps = {
          show_doc = "<leader>cfs",
          copy_doc = "<leader>cfc",
        },
      })
    end,
  },
}
```

## Usage

The plugin provides commands to access CloudFormation documentation:

- `:CfnDocs` - Open documentation for the resource under cursor
- `:CfnDocsCopy` - Copy documentation URL to clipboard

## Configuration

```lua
require('cfn-docs').setup({
  -- Configuration options
  verbosity = 1,       -- 0: errors only, 1: basic info, 2: debug
  use_w3m = false,     -- Use w3m for terminal viewing (if available)
  browser_cmd = nil,   -- Custom browser command (nil for system default)
})
```

## Development

### Running Tests

```bash
# Run tests with minimal output (just success/failure counts)
make test

# Run tests with verbose output (shows test names and details)
make test-verbose

# Run tests with pretty UTF symbols
make test-pretty
```

## License

MIT
