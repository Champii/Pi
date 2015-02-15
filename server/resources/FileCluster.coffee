_ = require 'underscore'
fs = require 'fs'
async = require 'async'

Nodulator = require 'nodulator'

Settings = require 'settings'
config = new Settings(require '../../settings/config')

piFS = require '../storage'

ccFS = require '../storage/ccFS'

fileChunkSize = 5000

numberChunkSize = 5000000

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

        filePart = _(req.fileCluster.parts).find (item) -> not _(req.fileCluster.clients[req.user.id].processed).contains item
        console.log 'filePart2', req.fileCluster
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

        req.fileCluster.Save (err) ->
          return res.status(500).send err if err?

          piGlobalPart = _(req.fileCluster.clients).find((item) -> item.userId is req.user.id).piGlobalPart
          # piFile = Math.floor((piGlobalPart * fileChunkSize) / numberChunkSize)

          res.status(200).send
            fileBuffer: buff
            piIdx: piGlobalPart * numberChunkSize

      @Put '/:id/found', (req, res) =>

        filePart = req.fileCluster.clients[req.user.id].filePart
        console.log 'filePart3', req.fileCluster

        part = JSON.parse fs.readFileSync req.fileCluster.filePath + '_' + filePart
        if filePart is -1
          return console.error {err: 'No parts for this user'}

        added = 0
        for i, v of req.body.idxs
          console.log 'PART i = ', part[i]
          if part[i] is -1 or part[i] is null
            part[i] = v
            added++
        console.log 'added ?', added, part, req.body.idxs

        if added
          File.Fetch req.fileCluster.fileId, (err, file) ->
            return console.error err if err?

            file.percentage += Math.floor(added / (req.fileCluster.fileSize / file.storeLevel) * 100)
            console.log 'File', file

            file.Save (err) ->
              return console.error err if err?

          fs.writeFileSync req.fileCluster.filePath + '_' + filePart, JSON.stringify part
          if _(part).contains -1
            req.fileCluster.clients[req.user.id].processed.push filePart
            console.log 'Not full part !', req.fileCluster
          else
            req.fileCluster.parts.splice req.fileCluster.parts.indexOf(filePart), 1
            console.log 'Part full !', req.fileCluster

          if not req.fileCluster.parts.length #and _(req.fileCluster.clients).chain().pluck('filePart').every((item) -> item is -1).value()
            nbParts = req.fileCluster.fileSize / fileChunkSize
            if req.fileCluster.fileSize < fileChunkSize
              nbParts = 1

            fs.writeFileSync config.hashsPath + req.user.id + '/' + req.fileCluster.fileId, ''
            for i in [0...nbParts]
              file = fs.readFileSync req.fileCluster.filePath + '_' + i
              fs.appendFileSync config.hashsPath + req.user.id + '/' + req.fileCluster.fileId, file
              fs.unlinkSync req.fileCluster.filePath + '_' + i

            req.fileCluster.Delete (err) ->
              return res.status(500).send err if err?

            res.sendStatus(200)

            return

            # Emit signal to disconnect clients

        req.fileCluster.Save (err) ->
          return res.status(500).send err if err?

          console.log req.fileCluster, req.fileCluster.clients
          res.sendStatus(200)

      #New Client
      @Get (req, res) =>
        FileCluster.NewClient req.user, (err, fileCluster) =>
          return res.status(500).send err if err?

          console.log 'New Client', fileCluster
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
      if fileCluster.ccProcessed.length and _(fileCluster.clients).chain().pluck('piGlobalPart').min().value() isnt _(fileCluster.ccProcessed).max() + 1
        pi = _(fileCluster.ccProcessed).max() + 1
      else if _(fileCluster.clients).chain().pluck('piGlobalPart').value().length
        pi = _(fileCluster.clients).chain().pluck('piGlobalPart').max().value() + 1
      else
        pi = 0

      console.log 'Pi ?', pi
      # if _(fileCluster.clients).keys().length
      #   pi = _(fileCluster.clients).chain().pluck('piGlobalPart').max().value() + 1
      #   console.log 'Found pi', pi
      #   if fileCluster.ccProcessed.length and pi in fileCluster.ccProcessed
      #     pi = _(fileCluster.ccProcessed).max() + 1
      #     console.log 'Found pi2', pi
      # else if fileCluster.ccProcessed.length
      #   pi = _(fileCluster.ccProcessed).max() + 1
      #   console.log 'Found pi3', pi
      # else
      #   pi = 0
      #   console.log 'Found pi4', pi

      fileCluster.clients[user.id] =
        userId: user.id
        piGlobalPart: pi
        filePart: -1
        processed: []
        lastActivity: new Date().getTime()

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

    chunkSize = fileChunkSize
    if fileSize < fileChunkSize
      chunkSize = fileSize

    for i in [0...fileSize / fileChunkSize]
      arr = []
      for j in [0...Math.floor(chunkSize / toSave.storeLevel)]
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
