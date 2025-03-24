describe("get_resource_type", function()
	local cfn_docs
	local mock = {
		lsp_responses = {},
		cursor_position = { line = 0, character = 0 }
	}

	before_each(function()
		-- Load the module
		package.loaded["cfn-docs"] = nil
		cfn_docs = require("cfn-docs")

		-- Configure the plugin
		cfn_docs.setup({
			verbosity = 2, -- Verbose for testing
		})

		-- Save original functions
		mock.original_buf_request_sync = vim.lsp.buf_request_sync
		mock.original_make_position_params = vim.lsp.util.make_position_params
		mock.original_get_resource_type = _G.get_resource_type

		-- Mock LSP position params
		vim.lsp.util.make_position_params = function()
			return {
				position = mock.cursor_position
			}
		end

		-- Mock LSP response
		vim.lsp.buf_request_sync = function(_, _, _, _)
			return mock.lsp_responses
		end

		-- Override the global get_resource_type function
		_G.get_resource_type = function()
			-- Récupère les paramètres de position pour la requête
			local clients = vim.lsp.get_clients({ bufnr = 0 })
			local position_encoding = (clients[1] and clients[1].offset_encoding) or "utf-16"

			local params = vim.lsp.util.make_position_params(0, position_encoding)
			-- Envoie une requête LSP avec les paramètres complets
			local result = vim.lsp.buf_request_sync(0, "textDocument/documentSymbol", params, 1000)

			if not result or vim.tbl_isempty(result) then
				return nil
			end

			local cursor_line = params.position.line

			-- Fonction pour trouver la ressource sous le curseur
			local function find_resource_at_cursor(symbols)
				for _, symbol in ipairs(symbols or {}) do
					local range = symbol.range or symbol.selectionRange
					if range and range.start.line <= cursor_line and range["end"].line >= cursor_line then
						-- Si le symbole est "Resources", chercher plus profondément
						if symbol.name == "Resources" and symbol.children then
							return find_resource_at_cursor(symbol.children)
						end

						-- Retourne uniquement si c'est une ressource individuelle
						if symbol.children then
							return symbol
						end
					end
				end
				return nil
			end

			-- Fonction pour trouver le champ Type dans une ressource donnée
			local function find_type_in_resource(resource)
				for _, child in ipairs(resource.children or {}) do
					if child.name == "Type" then
						return child.detail or child.name
					end
				end
				return nil
			end

			-- Parcourt les résultats pour trouver la ressource et son champ Type
			for _, res in pairs(result) do
				if res.result then
					local resource = find_resource_at_cursor(res.result)
					if resource then
						-- Une fois la ressource trouvée, cherchez le champ Type
						return find_type_in_resource(resource)
					end
				end
			end

			return nil
		end

		-- Reset mocks
		mock.lsp_responses = {}
		mock.cursor_position = { line = 0, character = 0 }
	end)

	after_each(function()
		-- Restore original functions
		vim.lsp.buf_request_sync = mock.original_buf_request_sync
		vim.lsp.util.make_position_params = mock.original_make_position_params
		_G.get_resource_type = mock.original_get_resource_type
	end)

	it("should return nil when LSP returns no results", function()
		-- Set empty LSP response
		mock.lsp_responses = {}

		-- Call the function
		local resource_type = _G.get_resource_type()

		-- Verify result
		assert.is_nil(resource_type)
	end)

	it("should return the resource type when cursor is on a resource", function()
		-- Set cursor position
		mock.cursor_position = { line = 5, character = 10 }

		-- Set mock LSP response with a resource
		mock.lsp_responses = {
			{
				result = {
					{
						name = "Resources",
						range = {
							start = { line = 0 },
							["end"] = { line = 20 }
						},
						children = {
							{
								name = "MyBucket",
								range = {
									start = { line = 3 },
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

		-- Call the function
		local resource_type = _G.get_resource_type()

		-- Verify result
		assert.are.equal("AWS::S3::Bucket", resource_type)
	end)
	
	it("should return nil when cursor is not on a resource", function()
		-- Set cursor position outside any resource
		mock.cursor_position = { line = 15, character = 10 }

		-- Set mock LSP response with a resource that doesn't cover the cursor position
		mock.lsp_responses = {
			{
				result = {
					{
						name = "Resources",
						range = {
							start = { line = 0 },
							["end"] = { line = 20 }
						},
						children = {
							{
								name = "MyBucket",
								range = {
									start = { line = 3 },
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

		-- Call the function
		local resource_type = _G.get_resource_type()

		-- Verify result
		assert.is_nil(resource_type)
	end)
	
	it("should handle nested resources correctly", function()
		-- Set cursor position
		mock.cursor_position = { line = 7, character = 10 }

		-- Set mock LSP response with nested resources
		mock.lsp_responses = {
			{
				result = {
					{
						name = "Resources",
						range = {
							start = { line = 0 },
							["end"] = { line = 30 }
						},
						children = {
							{
								name = "ParentResource",
								range = {
									start = { line = 2 },
									["end"] = { line = 25 }
								},
								children = {
									{
										name = "Type",
										detail = "AWS::CloudFormation::Stack"
									},
									{
										name = "NestedResource",
										range = {
											start = { line = 6 },
											["end"] = { line = 15 }
										},
										children = {
											{
												name = "Type",
												detail = "AWS::Lambda::Function"
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}

		-- Call the function
		local resource_type = _G.get_resource_type()

		-- Verify result - should find the parent resource type since cursor is on line 7
		assert.are.equal("AWS::CloudFormation::Stack", resource_type)
	end)
	
	it("should handle multiple resources and find the correct one", function()
		-- Set cursor position
		mock.cursor_position = { line = 25, character = 10 }

		-- Set mock LSP response with multiple resources
		mock.lsp_responses = {
			{
				result = {
					{
						name = "Resources",
						range = {
							start = { line = 0 },
							["end"] = { line = 50 }
						},
						children = {
							{
								name = "FirstResource",
								range = {
									start = { line = 2 },
									["end"] = { line = 10 }
								},
								children = {
									{
										name = "Type",
										detail = "AWS::S3::Bucket"
									}
								}
							},
							{
								name = "SecondResource",
								range = {
									start = { line = 12 },
									["end"] = { line = 20 }
								},
								children = {
									{
										name = "Type",
										detail = "AWS::EC2::Instance"
									}
								}
							},
							{
								name = "ThirdResource",
								range = {
									start = { line = 22 },
									["end"] = { line = 30 }
								},
								children = {
									{
										name = "Type",
										detail = "AWS::DynamoDB::Table"
									}
								}
							}
						}
					}
				}
			}
		}

		-- Call the function
		local resource_type = _G.get_resource_type()

		-- Verify result - should find the third resource type since cursor is on line 25
		assert.are.equal("AWS::DynamoDB::Table", resource_type)
	end)
	
	it("should handle resource without Type field", function()
		-- Set cursor position
		mock.cursor_position = { line = 5, character = 10 }

		-- Set mock LSP response with a resource missing Type field
		mock.lsp_responses = {
			{
				result = {
					{
						name = "Resources",
						range = {
							start = { line = 0 },
							["end"] = { line = 20 }
						},
						children = {
							{
								name = "InvalidResource",
								range = {
									start = { line = 3 },
									["end"] = { line = 10 }
								},
								children = {
									{
										name = "Properties",
										detail = "Some properties"
									}
									-- No Type field here
								}
							}
						}
					}
				}
			}
		}

		-- Call the function
		local resource_type = _G.get_resource_type()

		-- Verify result - should return nil when Type field is missing
		assert.is_nil(resource_type)
	end)
end)
