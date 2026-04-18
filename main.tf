##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

resource "postgresql_database" "this" {
  for_each          = var.databases
  name              = try(each.value.name, each.key)
  owner             = try(each.value.owner, local.psql.username)
  lc_collate        = try(each.value.lc_collate, "en_US.UTF-8")
  lc_ctype          = try(each.value.lc_ctype, "en_US.UTF-8")
  connection_limit  = try(each.value.connection_limit, -1)
  allow_connections = true
}

resource "random_password" "owner" {
  for_each         = { for k, v in var.users : k => v if try(v.create_owner, true) }
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  keepers = {
    rotation = var.password_rotation_period
    reset    = var.force_reset
  }
}

resource "postgresql_role" "owner" {
  for_each        = { for k, v in var.users : k => v if try(v.create_owner, true) }
  name            = try(each.value.username, each.key)
  login           = true
  password        = random_password.owner[each.key].result
  create_database = try(each.value.create_db, false)
  create_role     = try(each.value.create_role, false)
  inherit         = true
  roles           = try(each.value.role, null) != null ? [each.value.role] : []
}

resource "postgresql_schema" "this" {
  for_each = {
    for item in flatten([
      for db_key, db in var.databases : [
        for schema in try(db.schemas, []) : {
          key   = "${db_key}-${schema.name}"
          db    = try(db.name, db_key)
          name  = schema.name
          owner = try(schema.owner, local.psql.username)
        }
      ]
    ]) : item.key => item
  }
  name     = each.value.name
  database = each.value.db
  owner    = each.value.owner

  depends_on = [postgresql_database.this]
}
