_ = require 'underscore'
async = require 'async'
fs = require 'fs'
path = require 'path'
coffeeMiddleware = require 'coffee-middleware'
Modulator = require './Modulator'

bus = require './server/bus'
Resources = require './server/resources'
Routes = require './server/routes'
Sockets = require './server/socket/socket'
Processors = require './server/processors'
expressSession = require 'express-session'
RedisStore = require('connect-redis')(expressSession)


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

sessionStore = new RedisStore
  host: 'localhost'

app.use expressSession
  key: 'pi'
  secret: 'pi'
  store: sessionStore
  resave: true
  saveUninitialized: true


app.set 'views', path.resolve piRoot, 'public/views'
app.engine '.jade', require('jade').__express
app.set 'view engine', 'jade'

Resources.mount()

Routes.mount app

Sockets.init Modulator.server, sessionStore, Modulator.passport

Processors.init()


# #TESTS
# fs = require 'fs'
# PiFS = require './server/storage'

# piFS = new PiFS

# console.time 'hash'
# hash = piFS.GetHash 'test.txt'
# console.timeEnd 'hash'

# if hash?
#   console.log 'Got Hash !', hash.idx.length

#   console.time 'file'
#   file = piFS.GetFile hash
#   console.timeEnd 'file'
#   if file?
#     console.log 'Got File !', file.length
#     fs.writeFile './test2.txt', file
#   else
#     console.error 'Cannot get file from hash'
# else
#   console.error 'Cant get Hash'
# # console.log 'file', file
