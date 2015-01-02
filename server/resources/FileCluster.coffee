_ = require 'underscore'
fs = require 'fs'
async = require 'async'

Nodulator = require 'nodulator'

Settings = require 'settings'
config = new Settings(require '../../settings/config')

piFS = require '../storage'

fileChunkSize = 50000

class FileClusterRoute extends Nodulator.Route
  Config: ->
    super()

    Nodulator.ExtendBeforeRun =>
      @All '/:id*', (req, res, next) =>
        FileCluster.Fetch req.params.id, (err, fileCluster) ->
          return res.status(500).send err if err?

          req.fileCluster = fileCluster
          next()

      # Body empty means first call so no results
      @Put '/:id/found', (req, res) =>

        filePart = req.fileCluster.clients[req.user.id].filePart

        part = []
        if filePart isnt -1
          part = JSON.parse fs.readFileSync req.fileCluster.filePath + '_' + filePart

          added = 0
          for i, v of req.body.res
            if part[i] is -1
              part[i] = v
              added++

          if added
            File.Fetch req.fileCluster.fileId, (err, file) ->
              return console.error err if err?

              file.percentage += added / (file.size * file.storeLevel)

              file.Save (err) ->
                return console.error err if err?

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
          req.fileCluster.piProcessed.push req.fileCluster.clients[req.user.id].piGlobalPart
          delete req.fileCluster.clients[req.user.id]
          req.fileCluster.Save (err) ->
            res.status(500).send {status: 'changeCluster'}
          return

        req.fileCluster.clients[req.user.id].filePart = filePart

        #####

        #####

        fileFd = fs.openSync req.fileCluster.filePath, 'r'
        buff = new Buffer fileChunkSize
        read = fs.readSync fileFd, buff, 0, fileChunkSize, filePart * fileChunkSize
        fs.closeSync fileFd

        req.fileCluster.Save (err) ->
          return res.status(500).send err if err?

          test = piFS.BufferToArray8 buff
          r = []
          for i in test by req.fileCluster.storeLevel
            t = 0
            for j in [0...req.fileCluster.storeLevel]
              t += test[i + j] * Math.pow(255, j)
            r.push t

          res.status(200).send r

        # reward
        # get next buffer
        # emit change

      @Get '/:id/pi', (req, res) =>
        FileCluster.Fetch req.params.id, (err, fileCluster) ->
          return res.status(500).send err if err?

          piGlobalPart = _(fileCluster.clients).find((item) -> item.userId is req.user.id).piGlobalPart
          piFile = Math.floor((piGlobalPart * fileChunkSize) / config.piFileSlice)

          piFd = fs.openSync config.piPath + piFile, 'r'
          buff = new Buffer config.piFileSlice
          partInFile = (piGlobalPart - ((config.piPartSize / (piGlobalPart + 1)) * piFile))

          fs.readSync piFd, buff, 0, config.piFileSlice, partInFile * config.piFileSlice
          fs.closeSync piFd

          # test = piFS.BufferToArray8 buff
          # r = []
          # for i in test by 4
          #   t = 0
          #   for j in [0...4]
          #     t += test[i + j] * Math.pow(255, j)
          #   r.push t

          # console.log 'TEST', r, test


          res.status(200).send piFS.BufferToArray8 buff
          # res.status(200).send r

      @Post (req, res) =>
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
        if fileCluster.piProcessed.length and pi in fileCluster.piProcessed
          pi = _(fileCluster.piProcessed).max() + 1
      else if fileCluster.piProcessed.length
        pi = _(fileCluster.piProcessed).max() + 1
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
      piProcessed: []
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


# FileCluster model :
# id
# fileId
# filePath
# clients: {'clientId': ...}
# currentBufferIdx
# storeLevel

File = require './File'
