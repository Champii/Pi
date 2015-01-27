_ = require 'underscore'
fs = require 'fs'
async = require 'async'

Nodulator = require 'nodulator'

Settings = require 'settings'
config = new Settings(require '../../settings/config')

piFS = require '../storage'

ccFS = require '../storage/ccFS'

fileChunkSize = 50000

Client = require './Client'

class FileClusterRoute extends Nodulator.Route
  Config: ->
    super()

    Nodulator.ExtendBeforeRun =>
      @All '*', (req, res, next) =>
        return res.status(500).send {err: 'Bad idents'} if not req.query.username? or not req.query.password?

        Client.FetchByLogin req.query.username, (err, client) =>
          return res.status(500).send {err: 'Bad idents'} if err? or client.pass isnt req.query.password

          req.user = client
          next()

      @All '/:id*', (req, res, next) =>
        FileCluster.Fetch req.params.id, (err, fileCluster) ->
          return res.status(500).send err if err?

          req.fileCluster = fileCluster
          next()

      # Get file part to test
      @Get '/:id/file', (req, res) =>
        return res.status(500).send {err: 'No user'} if not req.fileCluster.clients[req.user.id]

        filePart = req.fileCluster.clients[req.user.id].filePart

        part = []
        if filePart isnt -1
          part = JSON.parse fs.readFileSync req.fileCluster.filePath + '_' + filePart

          if _(part).contains -1
            fs.writeFileSync req.fileCluster.filePath + '_' + filePart, JSON.stringify part
            req.fileCluster.clients[req.user.id].processed.push filePart
          else
            req.fileCluster.parts.splice req.fileCluster.parts.indexOf(filePart), 1

          if not req.fileCluster.parts.length and _(req.fileCluster.clients).chain().pluck('filePart').every((item) -> item is -1).value()
            1
            console.log '(not implemented) Assemble file !'
            # Assemble file and delete every parts
            # Emit signal to disconnect clients and delete fileCluster

        filePart = _(req.fileCluster.parts).find (item) -> not _(req.fileCluster.clients[req.user.id].processed).contains item
        if not filePart?
          req.fileCluster.ccProcessed.push req.fileCluster.clients[req.user.id].piGlobalPart
          delete req.fileCluster.clients[req.user.id]
          req.fileCluster.Save (err) ->
            res.status(500).send {status: 'changeCluster'}
          return

        req.fileCluster.clients[req.user.id].filePart = filePart

        fileFd = fs.openSync req.fileCluster.filePath, 'r'
        size = _([fileChunkSize, req.fileCluster.fileSize]).min()
        buff = new Buffer size
        read = fs.readSync fileFd, buff, 0, size, filePart * fileChunkSize
        fs.closeSync fileFd

        res.status(200).send buff

      @Put '/:id/found', (req, res) =>

        filePart = req.fileCluster.clients[req.user.id].filePart

        console.log 'WHHATTTTTT'
        part = []
        if filePart isnt -1
          part = JSON.parse fs.readFileSync req.fileCluster.filePath + '_' + filePart

          added = 0

          if part[req.body.idx] is -1
            part[req.body.idx] = req.body.value
            added++

          if added
            File.Fetch req.fileCluster.fileId, (err, file) ->
              return console.error err if err?

              file.percentage += added / (file.size * file.storeLevel)

              file.Save (err) ->
                return console.error err if err?

                res.sendStatus(200)

          else
            res.status(500).send {err: 'No part added'}
        else
          res.sendStatus(200)

        # reward
        # get next buffer
        # emit change

      #New Client
      @Get (req, res) =>
        FileCluster.NewClient req.user, (err, fileCluster) =>
          return res.status(500).send err if err?

          res.status(200).send fileCluster.ToJSON()

    Nodulator.ExtendAfterRun ->
      Nodulator.app.get '/worker', (req, res) ->
        return res.status(403).end() if not req.user?

        res.render 'worker',
          user: req.user

class FileCluster extends Nodulator.Resource 'filecluster', FileClusterRoute

  constructor: (blob) ->
    super blob
    @clients = JSON.parse @clients if typeof @clients is 'string'

  Serialize: ->
    _(super()).extend
      clients: JSON.stringify @clients

  @NewClient: (user, done) ->
    FileCluster.List (err, fileClusters) ->
      return done err if err?

      if not fileClusters.length
        return done {err: 'no clusters'}

      fileCluster = _(fileClusters).min (item) -> _(item.clients).size()

      if not fileCluster? of fileCluster is Infinity
        return done {err: 'no clusters'}

      pi = 0
      if _(fileCluster.clients).keys().length
        pi = _(fileCluster.clients).chain().pluck('piGlobalPart').max().value() + 1
        if fileCluster.ccProcessed.length and pi in fileCluster.ccProcessed
          pi = _(fileCluster.ccProcessed).max() + 1
      else if fileCluster.ccProcessed.length
        pi = _(fileCluster.ccProcessed).max() + 1
      else
        pi = 0

      fileCluster.clients[user.id] =
        userId: user.id
        piGlobalPart: pi
        filePart: -1
        processed: []

      fileCluster.Save (err) ->
        return done err if err?

        done null, fileCluster

  @NewFile: (fileId, filePath, fileSize, done) ->
    toSave =
      fileId: fileId
      filePath: filePath
      fileSize: fileSize
      parts: []
      ccProcessed: []
      clients: {}
      storeLevel: 4
      percentage: 0

    for i in [0...fileSize / fileChunkSize]
      arr = []
      for j in [0...fileChunkSize]
        arr.push -1
      toSave.parts.push i
      do (i) ->
        fs.open filePath + '_' + i, 'r', (err, fd) ->
          if not err?
            return fs.closeSync fd

          fs.writeFileSync filePath + '_' + i, JSON.stringify arr

    FileCluster.Deserialize toSave, (err, fileCluster) ->
      return done err if err?

      fileCluster.Save (err) ->
        return done err if err?

        done null, fileCluster


FileCluster.Init()

module.exports = FileCluster




File = require './File'
