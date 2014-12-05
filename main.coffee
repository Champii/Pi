_ = require 'underscore'
async = require 'async'
fs = require 'fs'
path = require 'path'
coffeeMiddleware = require 'coffee-middleware'
Modulator = require './Modulator'

Resources = require './server/resources'
Routes = require './server/routes'
Socket = require './server/socket/socket'

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

Resources.mount()

Routes.mount app

Socket.init Modulator.server
