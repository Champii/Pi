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

Server.Init()
Nodulator.Run()
