##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

## YAML Input Format
# users:
#   owner:                           # (Required) Key is the logical user name
#     username: "appowner"           # (Required) PostgreSQL role name
#     databases: ["mydb"]            # (Required) List of databases this owner owns
#     create_db: false               # (Optional) Grant CREATEDB. Default: false.
#     create_role: false             # (Optional) Grant CREATEROLE. Default: false.
#   reader:
#     username: "appreader"
#     databases: ["mydb"]
#     role: "readonly"               # (Optional) Grant membership in a named role group
#     hoop:                             # (Optional) Per-user Hoop settings.
#       access_control: []              # (Optional) Access control groups merged with hoop.access_control.
variable "users" {
  description = "Map of PostgreSQL users/roles to create with their database assignments."
  type        = any
  default     = {}
}

## YAML Input Format
# databases:
#   mydb:                            # (Required) Key is the logical database name
#     name: "mydb"                   # (Required) Actual database name
#     owner: "appowner"              # (Optional) Owner role. Default: admin login
#     lc_collate: "en_US.UTF-8"      # (Optional) Collation. Default: "en_US.UTF-8"
#     lc_ctype: "en_US.UTF-8"        # (Optional) Character type. Default: "en_US.UTF-8"
#     connection_limit: -1           # (Optional) Max connections. Default: -1 (unlimited)
#     schemas:                       # (Optional) List of schemas to create in this database
#       - name: "app"
#         owner: "appowner"
variable "databases" {
  description = "Map of PostgreSQL databases to create."
  type        = any
  default     = {}
}

## YAML Input Format
# hoop:
#   enabled: false                   # (Optional) Enable Hoop connection output. Default: false.
#   community: true                  # (Optional) true=null output (no KV sub-key); false=enterprise. Default: true.
#   agent_id: ""                     # (Required when enabled+enterprise) Hoop agent UUID.
#   port: 5433                       # (Optional) Local port for Hoop tunnel mode. Default: 5433.
#   db_name: "postgres"              # (Optional) Database for hoop tunnel connection. Default: "postgres"
#   server_name: ""                  # (Optional) Server name for hoop tunnel mode.
#   import: false                    # (Optional) Import existing Hoop connection. Default: false.
#   tags: {}                         # (Optional) Tags map for Hoop connections.
#   access_control: []               # (Optional) Access control groups.
variable "hoop" {
  description = "Hoop connection configuration. Enterprise mode stores per-field secrets in Key Vault."
  type        = any
  default     = {}
}

## YAML Input Format
# azure:
#   enabled: false                   # (Optional) Connect via Azure PostgreSQL Flexible Server. Default: false.
#   from_secret: false               # (Optional) Read credentials from Key Vault secret. Default: false.
#   secret_name: ""                  # (Required when from_secret=true) Key Vault secret name containing JSON credentials.
#   server_name: ""                  # (Required when enabled+!from_secret) Flexible Server name.
#   resource_group_name: ""          # (Optional) Resource group of the server (required when enabled+!from_secret).
#   admin_username: "adminuser"      # (Optional) Admin username when not from_secret. Default: "adminuser".
#   admin_password: ""               # (Optional) Admin password when not from_secret.
#   db_name: "postgres"              # (Optional) Default database. Default: "postgres".
#   sslmode: "require"               # (Optional) SSL mode. Default: "require".
#   superuser: false                 # (Optional) Use superuser mode. Default: false.
variable "azure" {
  description = "Azure PostgreSQL Flexible Server connection settings. Mutually exclusive with direct/hoop."
  type        = any
  default     = {}
}

## YAML Input Format
# direct:
#   host: ""                         # (Required) PostgreSQL server FQDN or IP.
#   port: 5432                       # (Optional) Port. Default: 5432.
#   username: ""                     # (Required) Admin username.
#   password: ""                     # (Required) Admin password.
#   db_name: "postgres"              # (Optional) Default database. Default: "postgres".
#   server_name: ""                  # (Optional) Logical server name for credential naming.
#   sslmode: "require"               # (Optional) SSL mode. Default: "require".
#   superuser: false                 # (Optional) Superuser mode. Default: false.
variable "direct" {
  description = "Direct PostgreSQL connection settings. Used when azure.enabled=false and hoop.enabled=false."
  type        = any
  default     = {}
}

## YAML Input Format
# password_rotation_period: "30d"   # (Optional) Password rotation period (e.g., "30d", "7d"). Default: "".
variable "password_rotation_period" {
  description = "(Optional) Password rotation period for user credentials (e.g., '30d'). Default: empty (no rotation)."
  type        = string
  default     = ""
}

## YAML Input Format
# force_reset: false                 # (Optional) Force password reset on next apply. Default: false.
variable "force_reset" {
  description = "(Optional) Force password reset for all managed users on next apply. Default: false."
  type        = bool
  default     = false
}

## YAML Input Format
# key_vault_name: "my-keyvault"     # (Required) Azure Key Vault name for storing user credentials and hoop secrets.
variable "key_vault_name" {
  description = "(Required) Name of the existing Azure Key Vault for credential and hoop secret storage."
  type        = string
}

## YAML Input Format
# key_vault_resource_group_name: "rg-shared" # (Required) Resource group of the Key Vault.
variable "key_vault_resource_group_name" {
  description = "(Required) Resource group name of the existing Azure Key Vault."
  type        = string
}
