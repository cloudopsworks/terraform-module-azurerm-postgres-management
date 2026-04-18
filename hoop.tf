##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  hoop_enabled    = try(var.hoop.enabled, false)
  hoop_enterprise = local.hoop_enabled && !try(var.hoop.community, true)

  hoop_users_owner = { for k, v in var.users : k => v if try(v.create_owner, true) }
  hoop_users_user  = { for k, v in var.users : k => v if !try(v.create_owner, true) }
  hoop_all_users   = merge(local.hoop_users_owner, local.hoop_users_user)
}

resource "azurerm_key_vault_secret" "hoop_host" {
  for_each     = local.hoop_enterprise ? local.hoop_all_users : {}
  name         = lower(replace("${local.kv_prefix}-pgsql-${try(each.value.username, each.key)}-hoop-host", "/[^a-zA-Z0-9-]/", "-"))
  value        = local.psql.host
  key_vault_id = data.azurerm_key_vault.credentials.id
  content_type = "text/plain"
  tags         = local.all_tags
}

resource "azurerm_key_vault_secret" "hoop_port" {
  for_each     = local.hoop_enterprise ? local.hoop_all_users : {}
  name         = lower(replace("${local.kv_prefix}-pgsql-${try(each.value.username, each.key)}-hoop-port", "/[^a-zA-Z0-9-]/", "-"))
  value        = tostring(local.psql.port)
  key_vault_id = data.azurerm_key_vault.credentials.id
  content_type = "text/plain"
  tags         = local.all_tags
}

resource "azurerm_key_vault_secret" "hoop_user" {
  for_each     = local.hoop_enterprise ? local.hoop_all_users : {}
  name         = lower(replace("${local.kv_prefix}-pgsql-${try(each.value.username, each.key)}-hoop-user", "/[^a-zA-Z0-9-]/", "-"))
  value        = try(each.value.username, each.key)
  key_vault_id = data.azurerm_key_vault.credentials.id
  content_type = "text/plain"
  tags         = local.all_tags
}

resource "azurerm_key_vault_secret" "hoop_pass" {
  for_each     = local.hoop_enterprise ? local.hoop_all_users : {}
  name         = lower(replace("${local.kv_prefix}-pgsql-${try(each.value.username, each.key)}-hoop-pass", "/[^a-zA-Z0-9-]/", "-"))
  value        = try(var.users[each.key].create_owner, true) ? random_password.owner[each.key].result : random_password.user[each.key].result
  key_vault_id = data.azurerm_key_vault.credentials.id
  content_type = "text/plain"
  tags         = local.all_tags
}

resource "azurerm_key_vault_secret" "hoop_db" {
  for_each     = local.hoop_enterprise ? local.hoop_all_users : {}
  name         = lower(replace("${local.kv_prefix}-pgsql-${try(each.value.username, each.key)}-hoop-db", "/[^a-zA-Z0-9-]/", "-"))
  value        = try(each.value.databases[0], local.psql.db_name)
  key_vault_id = data.azurerm_key_vault.credentials.id
  content_type = "text/plain"
  tags         = local.all_tags
}

output "hoop_connections" {
  description = "Hoop connection definitions for Azure. Enterprise mode only (Key Vault has no sub-key access). Community mode returns null."
  value = local.hoop_enterprise ? {
    for k, v in local.hoop_all_users : "${try(v.username, k)}" => {
      name           = lower(replace("${local.psql.server_name}-pgsql-${try(v.username, k)}", "/[^a-zA-Z0-9-]/", "-"))
      agent_id       = var.hoop.agent_id
      type           = "database"
      subtype        = "postgres"
      tags           = try(var.hoop.tags, {})
      access_control = toset(try(var.hoop.access_control, []))
      access_modes   = { connect = "enabled", exec = "enabled", runbooks = "enabled", schema = "enabled" }
      import         = try(var.hoop.import, false)
      secrets = {
        "envvar:HOST"    = "_envs/azure/${azurerm_key_vault_secret.hoop_host[k].name}"
        "envvar:PORT"    = "_envs/azure/${azurerm_key_vault_secret.hoop_port[k].name}"
        "envvar:USER"    = "_envs/azure/${azurerm_key_vault_secret.hoop_user[k].name}"
        "envvar:PASS"    = "_envs/azure/${azurerm_key_vault_secret.hoop_pass[k].name}"
        "envvar:DB"      = "_envs/azure/${azurerm_key_vault_secret.hoop_db[k].name}"
        "envvar:SSLMODE" = "require"
      }
    }
  } : null

  precondition {
    condition     = !local.hoop_enterprise || try(var.hoop.agent_id, "") != ""
    error_message = "hoop.agent_id must be set when hoop.enabled=true and hoop.community=false."
  }
}
