##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

output "users" {
  description = "Map of managed PostgreSQL users with their Key Vault credential secret names."
  value = merge(
    { for k, v in azurerm_key_vault_secret.owner_credentials : k => { secret_name = v.name, username = jsondecode(v.value).username } },
    { for k, v in azurerm_key_vault_secret.user_credentials : k => { secret_name = v.name, username = jsondecode(v.value).username } }
  )
}

output "databases" {
  description = "Map of managed PostgreSQL databases."
  value       = { for k, v in postgresql_database.this : k => { name = v.name } }
}
