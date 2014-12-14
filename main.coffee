_ = require 'underscore'
async = require 'async'
fs = require 'fs'
path = require 'path'
coffeeMiddleware = require 'coffee-middleware'
Modulator = require './Modulator'

# Resources = require './server/resources'
Routes = require './server/routes'
# Sockets = require './server/sockets'
Server = require './server'
# expressSession = require 'express-session'
# RedisStore = require('connect-redis')(expressSession)


app = Modulator.app

MakeAssetsList = ->
  assets = {}

  assetsCoffee = require './settings/assets.json'
  assetsLib = require './settings/assets-lib.json'
  assetsCss = require './settings/assets-css.json'

  assets['/js/pi.min.js'] = assetsLib.concat assetsCoffee
  assets['/css/pi.min.css'] = assetsCss
  assets

piRoot = path.resolve __dirname, '.'

app.use coffeeMiddleware
  src: path.resolve piRoot, 'public'
  # compress: true
  prefix: 'js'
  bare: true
  force: true

app.use require('connect-cachify').setup MakeAssetsList(),
  root: path.join piRoot, 'public'
  production: false

app.use Modulator.express.static path.resolve piRoot, 'public'

app.set 'views', path.resolve piRoot, 'public/views'
app.engine '.jade', require('jade').__express
app.set 'view engine', 'jade'

# Resources.Init()

Server.Init()
Routes.mount app
# Sockets.Init()

  # bus.on 'updateFile', (file) ->
  #   emitClient file.client_id, 'updateFile', file

  # emitClient = (clientId, args...) ->
  #   io.sockets.in('client-' + clientId).emit.apply io.sockets.in('client-' + clientId), args
