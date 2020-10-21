locals {
  private_databricks_name     = format("%sprivatedatabricks", local.name)
  public_databricks_name      = format("%spublicdatabricks", local.name)
  databricks_nsg_name         = format("%s-databricks-nsg", local.name)
  workspace_name              = format("%sworkspace", local.name)
  managed_resource_group_name = format("%s-managed-rg", azurerm_resource_group.spoke.name)
  init_script                 = "appinsights_logging_init.sh"

  dbfs_ai_core     = format("dbfs:/databricks/appinsights/%s", local.ai_core)
  dbfs_ai_logging  = format("dbfs:/databricks/appinsights/%s", local.ai_logging)
  dbfs_init_script = format("dbfs:/databricks/appinsights/%s", local.init_script)

}


provider "databricks" {
  azure_workspace_name  = azurerm_databricks_workspace.databricks.name
  azure_resource_group  = azurerm_databricks_workspace.databricks.resource_group_name
  azure_client_id       = data.azurerm_client_config.current.client_id
  azure_client_secret   = var.client_secret
  azure_tenant_id       = data.azurerm_client_config.current.tenant_id
  azure_subscription_id = data.azurerm_client_config.current.subscription_id
}

resource "databricks_cluster" "my-cluster" {
  spark_version = "7.3.x-scala2.12"
  node_type_id  = "Standard_DS3_v2"
  num_workers   = 1

  library {
    pypi {
      package = "applicationinsights==0.11.9"
    }
  }

  init_scripts {
    dbfs {
      destination = "dbfs:/databricks/appinsights/appinsights_logging_init.sh"
    }
  }
  depends_on = [
    databricks_dbfs_file.ai_core,
    databricks_dbfs_file.ai_logging,
    databricks_dbfs_file.dbfs_init_script
  ]
}

resource "azurerm_databricks_workspace" "databricks" {
  name                        = local.workspace_name
  resource_group_name         = azurerm_resource_group.spoke.name
  location                    = azurerm_resource_group.spoke.location
  sku                         = "premium"
  managed_resource_group_name = local.managed_resource_group_name
}

resource "databricks_dbfs_file" "ai_core" {
  source               = lookup(data.external.download_ai_core.result, "library")
  content_b64_md5      = md5(filebase64(pathexpand(local.ai_core)))
  path                 = local.dbfs_ai_core
  overwrite            = true
  mkdirs               = true
  validate_remote_file = true

  depends_on = [
    data.external.download_ai_core
  ]
}


resource "databricks_dbfs_file" "ai_logging" {
  source               = lookup(data.external.download_ai_logging.result, "library")
  content_b64_md5      = md5(filebase64(pathexpand(local.ai_logging)))
  path                 = local.dbfs_ai_logging
  overwrite            = true
  mkdirs               = true
  validate_remote_file = true

  depends_on = [
    data.external.download_ai_logging
  ]
}

data "template_file" "databricks_init" {
  template = templatefile("appinsights_logging_init.tpl", {
    ai_key     = data.azurerm_application_insights.ai.instrumentation_key
    oms_id     = data.azurerm_log_analytics_workspace.oms.workspace_id
    oms_key    = data.azurerm_log_analytics_workspace.oms.primary_shared_key
    ai_version = var.ai_jar_version
  })
}

resource "local_file" "databricks_init" {
  filename = pathexpand(local.init_script)
  content  =   templatefile("appinsights_logging_init.tpl", {
    ai_key     = data.azurerm_application_insights.ai.instrumentation_key
    oms_id     = data.azurerm_log_analytics_workspace.oms.workspace_id
    oms_key    = data.azurerm_log_analytics_workspace.oms.primary_shared_key
    ai_version = var.ai_jar_version
  })
}

resource "databricks_dbfs_file" "dbfs_init_script" {
  source               = local_file.databricks_init.filename
  content_b64_md5      = md5(filebase64(pathexpand(local_file.databricks_init.filename)))
  path                 = local.dbfs_init_script
  overwrite            = true
  mkdirs               = true
  validate_remote_file = true

  depends_on = [
      local_file.databricks_init
  ]
}