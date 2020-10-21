locals {
  ai_core    = format("applicationinsights-core-%s.jar", var.ai_jar_version)
  ai_logging = format("applicationinsights-logging-log4j1_2-%s.jar", var.ai_jar_version)
}

data "external" "download_ai_core" {
  program = ["pwsh", "${path.module}/Download-File.ps1", path.module, local.ai_core, var.ai_jar_version]
}

data "external" "download_ai_logging" {
  program = ["pwsh", "${path.module}/Download-File.ps1", path.module, local.ai_logging, var.ai_jar_version]
}

# output "ai_core" {
#   value = data.external.download_ai_core.result
# }

# output "ai_logging" {
#   value = data.external.download_ai_logging.result
# }


# data "http" "example" {
#   url = "https://checkpoint-api.hashicorp.com/v1/check/terraform"

#   # Optional request headers
#   request_headers = {
#     Accept = "application/json"
#   }
# }

# https://github.com/microsoft/ApplicationInsights-Java/releases/download/2.6.2/applicationinsights-agent-2.6.2.jar