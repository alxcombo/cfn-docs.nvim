describe("cfn-docs", function()
	local cfn_docs
	local mock = {
		notifications = {},
		clipboard = "",
		urls = {},
		commands = {},
		http_responses = {},
		resource_type = nil,
	}

	-- Liste des types de ressources CloudFormation pour les tests
	local aws_resource_types = {
		"AWS::EC2::Instance",
		"AWS::S3::Bucket",
		"AWS::IAM::Role",
		"AWS::Lambda::Function",
		"AWS::DynamoDB::Table",
		"AWS::CloudWatch::Alarm",
		"AWS::RDS::DBInstance",
		"AWS::SNS::Topic",
		"AWS::SQS::Queue",
		"AWS::ApiGateway::RestApi",
		"AWS::ECS::Cluster",
		"AWS::KMS::Key",
		"AWS::StepFunctions::StateMachine",
		"AWS::CloudFront::Distribution",
		"AWS::EKS::Cluster",
		"AWS::ElastiCache::CacheCluster",
		"AWS::SecretsManager::Secret",
		"AWS::Glue::Job",
		"AWS::Athena::WorkGroup",
		"AWS::SageMaker::NotebookInstance",
		"AWS::Batch::ComputeEnvironment",
		"AWS::CodeBuild::Project",
		"AWS::ElasticLoadBalancingV2::LoadBalancer",
		"AWS::ElasticBeanstalk::Application",
		"AWS::Redshift::Cluster",
		"AWS::Config::ConfigRule",
		"AWS::CloudFormation::Stack",
		"AWS::GuardDuty::Detector",
		"AWS::Inspector::AssessmentTarget",
		"AWS::Kinesis::Stream",
		"AWS::AutoScaling::AutoScalingGroup",
		"AWS::AutoScaling::LaunchConfiguration",
		"AWS::AutoScaling::ScalingPolicy",
		"AWS::Backup::BackupPlan",
		"AWS::Backup::BackupVault",
		"AWS::CloudTrail::Trail",
		"AWS::Cognito::UserPool",
		"AWS::Cognito::UserPoolClient",
		"AWS::DocDB::DBCluster",
		"AWS::DynamoDB::GlobalTable",
		"AWS::ElasticLoadBalancing::LoadBalancer",
		"AWS::ElasticLoadBalancingV2::TargetGroup",
		"AWS::ElasticLoadBalancingV2::Listener",
		"AWS::ElasticLoadBalancingV2::ListenerRule",
		"AWS::IoT::Thing",
		"AWS::IoT::TopicRule",
		"AWS::Lambda::Permission",
		"AWS::Logs::LogGroup",
		"AWS::Logs::MetricFilter",
		"AWS::RDS::DBCluster",
		"AWS::RDS::DBClusterParameterGroup",
		"AWS::RDS::DBSubnetGroup",
		"AWS::Route53::HostedZone",
		"AWS::Route53::RecordSet",
		"AWS::Route53Resolver::ResolverRule",
		"AWS::S3::AccessPoint",
		"AWS::S3::StorageLens",
		"AWS::ServiceCatalog::Portfolio",
		"AWS::StepFunctions::Activity",
		"AWS::Transfer::User",
		"AWS::WAF::Rule",
		"AWS::WAFv2::RuleGroup",
		"AWS::WAFRegional::WebACL",
		"AWS::WAFv2::WebACL",
		"AWS::WorkSpaces::Workspace"
	}

	before_each(function()
		-- Load the module
		package.loaded["cfn-docs"] = nil
		package.loaded["plenary.curl"] = nil
		cfn_docs = require("cfn-docs")

		-- Configure the plugin
		cfn_docs.setup({
			verbosity = 2, -- Verbose for testing
			use_w3m = false, -- Disable w3m for testing
		})

		-- Save original functions
		mock.original_notify = vim.notify
		mock.original_system = vim.fn.system
		mock.original_cmd = vim.cmd

		-- Mock notifications
		vim.notify = function(msg, level, opts)
			table.insert(mock.notifications, {
				message = msg,
				level = level,
				opts = opts,
			})
		end

		-- Mock clipboard
		vim.fn.system = function(cmd, input)
			if type(cmd) == "string" and cmd:match("win32yank.exe") then
				mock.clipboard = input
				return ""
			end
			return mock.original_system(cmd, input)
		end

		-- Mock vim.cmd to capture commands
		vim.cmd = function(command)
			if type(command) == "string" then
				table.insert(mock.commands, command)
			end
			return mock.original_cmd(command)
		end

		-- Mock plenary.curl for HTTP requests
		package.loaded["plenary.curl"] = {
			get = function(opts)
				local url = opts.url
				table.insert(mock.urls, url)

				-- Return mock response based on URL
				local response = mock.http_responses[url]
					or {
						status = 200,
						body = "<html><body>Mock AWS documentation</body></html>",
					}

				return response
			end,
		}

		-- Reset mocks
		mock.notifications = {}
		mock.clipboard = ""
		mock.urls = {}
		mock.commands = {}
		mock.http_responses = {}
		mock.resource_type = nil

		-- Override the get_resource_type function to return a controlled value
		local original_get_resource_type = _G.get_resource_type
		_G.get_resource_type = function()
			return mock.resource_type
		end
	end)

	after_each(function()
		-- Restore original functions
		vim.notify = mock.original_notify
		vim.fn.system = mock.original_system
		vim.cmd = mock.original_cmd
	end)

	describe("basic functionality", function()
		it("should be able to load the plugin", function()
			assert.is_not_nil(cfn_docs)
			assert.is_not_nil(cfn_docs.setup)
		end)
	end)

	describe("show_documentation", function()
		it("should show notification with URL when use_w3m is false", function()
			-- Mock the generate_cloudformation_doc_url function
			cfn_docs.generate_cloudformation_doc_url = function()
				return "https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html"
			end

			-- Configure the plugin to not use w3m
			cfn_docs.config.use_w3m = false

			-- Call the function
			cfn_docs.show_documentation()

			-- Verify notification was sent with the URL
			assert.are.equal(1, #mock.notifications)
			assert.are.equal(
				"Documentation URL: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html",
				mock.notifications[1].message
			)

			-- Verify no w3m command was executed
			assert.are.equal(0, #mock.commands)
		end)

		it("should open w3m with URL when use_w3m is true", function()
			-- Mock the generate_cloudformation_doc_url function
			cfn_docs.generate_cloudformation_doc_url = function()
				return "https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html"
			end

			-- Configure the plugin to use w3m
			cfn_docs.config.use_w3m = true

			-- Call the function
			cfn_docs.show_documentation()

			-- Verify w3m command was executed with the URL
			assert.are.equal(1, #mock.commands)
			assert.are.equal(
				"W3mVSplit https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html",
				mock.commands[1]
			)

			-- Verify no notification was sent
			assert.are.equal(0, #mock.notifications)
		end)
	end)

	describe("copy_cloudformation_doc_url", function()
		it("should copy URL to clipboard", function()
			-- Mock the generate_cloudformation_doc_url function
			cfn_docs.generate_cloudformation_doc_url = function()
				return "https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html"
			end

			-- Call the function
			cfn_docs.copy_cloudformation_doc_url()

			-- Verify clipboard content
			assert.are.equal(
				"https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html",
				mock.clipboard
			)

			-- Verify notification
			assert.are.equal(1, #mock.notifications)
			assert.are.equal(
				"Copied URL: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html",
				mock.notifications[1].message
			)
		end)
	end)

	describe("send_notification", function()
		it("should send notification with default level and options", function()
			-- Call the function with just a message
			cfn_docs.send_notification("Test message")
			
			-- Verify notification was sent
			assert.are.equal(1, #mock.notifications)
			assert.are.equal("Test message", mock.notifications[1].message)
			assert.are.equal(vim.log.levels.INFO, mock.notifications[1].level)
			assert.are.equal("Notification", mock.notifications[1].opts.title)
			assert.are.equal(3000, mock.notifications[1].opts.timeout)
		end)
		
		it("should send notification with custom level", function()
			-- Call the function with custom level
			cfn_docs.send_notification("Warning message", "warn")
			
			-- Verify notification was sent with correct level
			assert.are.equal(1, #mock.notifications)
			assert.are.equal("Warning message", mock.notifications[1].message)
			assert.are.equal(vim.log.levels.WARN, mock.notifications[1].level)
		end)
		
		it("should send notification with custom options", function()
			-- Call the function with custom options
			cfn_docs.send_notification("Error message", "error", {
				title = "Custom Title",
				timeout = 5000
			})
			
			-- Verify notification was sent with correct options
			assert.are.equal(1, #mock.notifications)
			assert.are.equal("Error message", mock.notifications[1].message)
			assert.are.equal(vim.log.levels.ERROR, mock.notifications[1].level)
			assert.are.equal("Custom Title", mock.notifications[1].opts.title)
			assert.are.equal(5000, mock.notifications[1].opts.timeout)
		end)
		
		it("should handle invalid notification level", function()
			-- Call the function with invalid level
			cfn_docs.send_notification("Test with invalid level", "not_a_valid_level")
			
			-- Verify notification defaults to INFO level
			assert.are.equal(1, #mock.notifications)
			assert.are.equal("Test with invalid level", mock.notifications[1].message)
			assert.are.equal(vim.log.levels.INFO, mock.notifications[1].level)
		end)
	end)

	describe("generate_cloudformation_doc_url", function()
		-- Expose the private get_resource_type function for testing
		before_each(function()
			-- Make a copy of the original function
			local original_generate_url = cfn_docs.generate_cloudformation_doc_url

			-- Override the function to expose the private get_resource_type
			cfn_docs.generate_cloudformation_doc_url = function()
				-- Call the original function with our mocked resource type
				local resource_type = _G.get_resource_type()

				if not resource_type then
					cfn_docs.send_notification("Resource Type not found.", "warn")
					return
				end

				-- Supprimer le préfixe "AWS::" si présent
				local type_without_prefix = resource_type:gsub("^AWS::", "")
				-- Transformer le type en chemin pour l'URL
				local type_path = type_without_prefix:gsub("::", "-"):lower()
				local url = "https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-"
					.. type_path
					.. ".html"

				-- Validate URL
				local http = require("plenary.curl")
				local response = http.get({ url = url, timeout = 3000 })
				if not response or response.status ~= 200 then
					return
				end

				return url
			end
		end)

		it("should return nil when resource type is not found", function()
			-- Set mock resource type to nil
			mock.resource_type = nil

			-- Call the function
			local url = cfn_docs.generate_cloudformation_doc_url()

			-- Verify result
			assert.is_nil(url)

			-- Verify notification
			assert.are.equal(1, #mock.notifications)
			assert.are.equal("Resource Type not found.", mock.notifications[1].message)
		end)

		it("should generate correct URL for S3 bucket", function()
			-- Set mock resource type
			mock.resource_type = "AWS::S3::Bucket"

			-- Call the function
			local url = cfn_docs.generate_cloudformation_doc_url()

			-- Verify result
			assert.are.equal(
				"https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html",
				url
			)

			-- Verify HTTP request was made
			assert.are.equal(1, #mock.urls)
			assert.are.equal(
				"https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html",
				mock.urls[1]
			)
		end)

		it("should generate correct URL for EC2 instance", function()
			-- Set mock resource type
			mock.resource_type = "AWS::EC2::Instance"

			-- Call the function
			local url = cfn_docs.generate_cloudformation_doc_url()

			-- Verify result
			assert.are.equal(
				"https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-instance.html",
				url
			)
		end)

		it("should handle resource types without AWS:: prefix", function()
			-- Set mock resource type without AWS:: prefix
			mock.resource_type = "S3::Bucket"

			-- Call the function
			local url = cfn_docs.generate_cloudformation_doc_url()

			-- Verify result
			assert.are.equal(
				"https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html",
				url
			)
		end)

		it("should return nil for invalid URLs", function()
			-- Set mock resource type
			mock.resource_type = "AWS::NonExistent::Resource"

			-- Configure HTTP response for this URL
			mock.http_responses["https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-nonexistent-resource.html"] =
				{
					status = 404,
					body = "<html><body>Not Found</body></html>",
				}

			-- Call the function
			local url = cfn_docs.generate_cloudformation_doc_url()

			-- Verify result
			assert.is_nil(url)
		end)
		
		-- Tests pour différents types de ressources CloudFormation
		it("should generate correct URLs for various CloudFormation resource types", function()
			-- Sélectionner des types de ressources à tester, incluant des noms simples et complexes
			local test_resources = {
				-- Ressources standard
				"AWS::DynamoDB::Table",
				"AWS::Lambda::Function",
				"AWS::CloudWatch::Alarm",
				"AWS::SNS::Topic",
				"AWS::ApiGateway::RestApi",
				"AWS::ECS::Cluster",
				"AWS::CloudFront::Distribution",
				"AWS::Cognito::UserPool",
				"AWS::Route53::HostedZone",
				"AWS::WAFv2::WebACL",
				
				-- Ressources avec des noms plus complexes
				"AWS::ElasticLoadBalancingV2::ListenerRule",
				"AWS::RDS::DBClusterParameterGroup",
				"AWS::Route53Resolver::ResolverRule"
			}
			
			for _, resource_type in ipairs(test_resources) do
				-- Set mock resource type
				mock.resource_type = resource_type
				
				-- Generate expected URL
				local type_without_prefix = resource_type:gsub("^AWS::", "")
				local type_path = type_without_prefix:gsub("::", "-"):lower()
				local expected_url = "https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-" .. type_path .. ".html"
				
				-- Reset URLs tracking
				mock.urls = {}
				
				-- Call the function
				local url = cfn_docs.generate_cloudformation_doc_url()
				
				-- Verify result
				assert.are.equal(expected_url, url)
				
				-- Verify HTTP request was made
				assert.are.equal(1, #mock.urls)
				assert.are.equal(expected_url, mock.urls[1])
			end
		end)
	end)
end)
