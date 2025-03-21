# cfn-docs.nvim

A Neovim plugin for accessing AWS CloudFormation documentation directly from your editor.

## Features

- Generate documentation URLs for CloudFormation resources
- Open documentation in browser or terminal
- Copy documentation URLs to clipboard
- Support for LSP integration

## Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'alexandre/cfn-docs.nvim',
  requires = {'nvim-lua/plenary.nvim'},
  config = function()
    require('cfn-docs').setup()
  end
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
# Run tests
make test

# Run tests with verbose output
make test-verbose
```

## License

MIT
