##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

provider "postgresql" {
  host            = local.psql.host
  port            = local.psql.port
  username        = local.psql.username
  password        = local.psql.password
  database        = local.psql.db_name
  sslmode         = local.psql.sslmode
  connect_timeout = 15
  superuser       = local.psql.superuser
}
