Nodulator = require 'nodulator'
Assets = require 'nodulator-assets'
Angular = require 'nodulator-angular'
Server = require './server'

Nodulator.Use Assets
Nodulator.Use Angular

Server.Init()
Nodulator.Run()
