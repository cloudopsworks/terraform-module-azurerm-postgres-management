##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

resource "random_password" "user" {
  for_each         = { for k, v in var.users : k => v if !try(v.create_owner, true) }
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  keepers = {
    rotation = var.password_rotation_period
    reset    = var.force_reset
  }
}

resource "postgresql_role" "user" {
  for_each = { for k, v in var.users : k => v if !try(v.create_owner, true) }
  name     = try(each.value.username, each.key)
  login    = true
  password = random_password.user[each.key].result
  inherit  = true
  roles    = try(each.value.role, null) != null ? [each.value.role] : []
}

resource "postgresql_grant" "user_readwrite" {
  for_each = {
    for item in flatten([
      for k, v in var.users : [
        for db in try(v.databases, []) : {
          key        = "${k}-${db}-rw"
          username   = try(v.username, k)
          database   = db
          privileges = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]
        }
      ] if !try(v.create_owner, true) && try(v.access, "readwrite") == "readwrite"
    ]) : item.key => item
  }
  database    = each.value.database
  role        = each.value.username
  schema      = "public"
  object_type = "table"
  privileges  = each.value.privileges
  depends_on  = [postgresql_role.user, postgresql_database.this]
}

resource "postgresql_grant" "user_readonly" {
  for_each = {
    for item in flatten([
      for k, v in var.users : [
        for db in try(v.databases, []) : {
          key      = "${k}-${db}-ro"
          username = try(v.username, k)
          database = db
        }
      ] if !try(v.create_owner, true) && try(v.access, "readwrite") == "readonly"
    ]) : item.key => item
  }
  database    = each.value.database
  role        = each.value.username
  schema      = "public"
  object_type = "table"
  privileges  = ["SELECT"]
  depends_on  = [postgresql_role.user, postgresql_database.this]
}
