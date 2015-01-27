Nodulator = require 'nodulator'
Socket = require 'nodulator-socket'
Assets = require 'nodulator-assets'
Angular = require 'nodulator-angular'
Account = require 'nodulator-account'
Server = require './server'

Nodulator.Use Socket
Nodulator.Use Assets
Nodulator.Use Angular
Nodulator.Use Account

# Nodulator.Config
#   dbType: 'Mongo'
#   dbAuth:
#     database: 'pi'
#     user: 'pi'
#     pass: 'pi'

Server.Init()
Nodulator.Run()
