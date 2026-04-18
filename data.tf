##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  azure_enabled       = try(var.azure.enabled, false)
  from_secret_enabled = local.azure_enabled && try(var.azure.from_secret, false)
  hoop_connect        = try(var.hoop.enabled, false) && !local.azure_enabled
  psql = local.azure_enabled && local.from_secret_enabled ? {
    host        = jsondecode(data.azurerm_key_vault_secret.azure_creds[0].value)["host"]
    port        = jsondecode(data.azurerm_key_vault_secret.azure_creds[0].value)["port"]
    username    = jsondecode(data.azurerm_key_vault_secret.azure_creds[0].value)["username"]
    password    = jsondecode(data.azurerm_key_vault_secret.azure_creds[0].value)["password"]
    db_name     = jsondecode(data.azurerm_key_vault_secret.azure_creds[0].value)["dbname"]
    server_name = try(var.azure.server_name, local.system_name)
    sslmode     = try(var.azure.sslmode, "require")
    superuser   = try(var.azure.superuser, false)
    } : local.azure_enabled ? {
    host        = data.azurerm_postgresql_flexible_server.this[0].fqdn
    port        = 5432
    username    = try(var.azure.admin_username, "adminuser")
    password    = try(var.azure.admin_password, "")
    db_name     = try(var.azure.db_name, "postgres")
    server_name = try(var.azure.server_name, local.system_name)
    sslmode     = try(var.azure.sslmode, "require")
    superuser   = try(var.azure.superuser, false)
    } : local.hoop_connect ? {
    host        = "127.0.0.1"
    port        = try(var.hoop.port, 5433)
    username    = try(var.hoop.username, "noop")
    password    = try(var.hoop.password, "noop")
    db_name     = try(var.hoop.db_name, "postgres")
    server_name = try(var.hoop.server_name, "")
    sslmode     = try(var.hoop.default_sslmode, "disable")
    superuser   = try(var.hoop.superuser, false)
    } : {
    host        = try(var.direct.host, "")
    port        = try(var.direct.port, 5432)
    username    = try(var.direct.username, "")
    password    = try(var.direct.password, "")
    db_name     = try(var.direct.db_name, "postgres")
    server_name = try(var.direct.server_name, "")
    sslmode     = try(var.direct.sslmode, "require")
    superuser   = try(var.direct.superuser, false)
  }
}

data "azurerm_key_vault" "credentials" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name
}

data "azurerm_key_vault_secret" "azure_creds" {
  count        = local.from_secret_enabled ? 1 : 0
  name         = var.azure.secret_name
  key_vault_id = data.azurerm_key_vault.credentials.id
}

data "azurerm_postgresql_flexible_server" "this" {
  count               = local.azure_enabled && !local.from_secret_enabled ? 1 : 0
  name                = var.azure.server_name
  resource_group_name = try(var.azure.resource_group_name, "")
}
