import config from require "lapis.config"

config "development", ->

config {"production", "development"}, ->
  port 80
  num_workers 4
  lua_code_cache "on"
  logging false
  redis ->
    host "127.0.0.1"
    port 6379
