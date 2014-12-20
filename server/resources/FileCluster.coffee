_ = require 'underscore'
fs = require 'fs'
async = require 'async'

Nodulator = require 'nodulator'

Settings = require 'settings'
config = new Settings(require '../../settings/config')

piFS = require '../storage'

fileChunkSize = 5000

class FileClusterRoute extends Nodulator.Route
  Config: ->
    super()

    Nodulator.ExtendRunProcess =>
      @Add 'all', '/:id*', (req, res, next) =>
        FileCluster.Fetch req.params.id, (err, fileCluster) ->
          return res.status(500).send err if err?

          req.fileCluster = fileCluster
          next()

      # Body empty means first call so no results
      @Add 'put', '/:id/found', (req, res) =>
        console.log 'FOUND, ', req.body

        filePart = req.fileCluster.clients[req.user.id].filePart

        part = []
        if filePart isnt -1
          part = JSON.parse fs.readFileSync req.fileCluster.filePath + '_' + filePart

          for i, v of req.body.res
            if part[i] is -1
              console.log 'Found part : ', v, 'at', i
              part[i] = v

          console.log _(part).contains -1, part
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
          # else
          #   # We have more part to process

        console.log 'Processed', req.fileCluster.clients[req.user.id].processed
        filePart = _(req.fileCluster.parts).find (item) -> not _(req.fileCluster.clients[req.user.id].processed).contains item
        console.log 'FilePart', filePart
        if not filePart?
          console.log 'CHANGING CLUSTER'
          req.fileCluster.piProcessed.push req.fileCluster.clients[req.user.id].piGlobalPart
          delete req.fileCluster.clients[req.user.id]
          req.fileCluster.Save (err) ->
            #Ask to change cluster
            res.status(500).send {status: 'changeCluster'}
          return

        req.fileCluster.clients[req.user.id].filePart = filePart

        #####

        #####

        fileFd = fs.openSync req.fileCluster.filePath, 'r'
        buff = new Buffer fileChunkSize
        read = fs.readSync fileFd, buff, 0, fileChunkSize, filePart * fileChunkSize
        fs.closeSync fileFd

        # buff = JSON.parse fs.readFileSync req.fileCluster.filePath + '_' + filePart

        req.fileCluster.Save (err) ->
          return res.status(500).send err if err?

          # console.log 'buff', buff
          res.status(200).send piFS.BufferToArray8 buff.slice(0, req.fileCluster.fileSize)

        # reward
        # get next buffer
        # emit change

      @Add 'get', '/:id/pi', (req, res) =>
        # console.log 'GetPi', req.params
        FileCluster.Fetch req.params.id, (err, fileCluster) ->
          return res.status(500).send err if err?

          console.log fileCluster
          piGlobalPart = _(fileCluster.clients).find((item) -> item.userId is req.user.id).piGlobalPart
          piFile = Math.floor((piGlobalPart * fileChunkSize) / config.piFileSlice)
          # console.log 'piFile', piFile
          # console.log 'piGlobalPart', piGlobalPart
          piFd = fs.openSync config.piPath + piFile, 'r'
          buff = new Buffer config.piFileSlice
          partInFile = (piGlobalPart - ((config.piPartSize / (piGlobalPart + 1)) * piFile))
          # console.log 'partInFile', partInFile
          fs.readSync piFd, buff, 0, config.piFileSlice, partInFile * config.piFileSlice
          fs.closeSync piFd
          # pi = fs.readFileSync config.piPath + piGlobalPart
          res.status(200).send piFS.BufferToArray8 buff

      @Add 'post', (req, res) =>
        console.log 'GetFileCluster'
        FileCluster.NewClient req.user, (err, fileCluster) =>
          return res.status(500).send err if err?

          res.status(200).send fileCluster.ToJSON()

      Nodulator.app.get '/worker', (req, res) ->
        console.log 'User', req.user
        # return res.status(403).end() if not req.user?

        # console.log res.locals
        # Nodulator.nangulator.InjectViews()
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

#      fileCluster = fileClusters[0]
      if not fileClusters.length
        return done {err: 'no clusters'}

      fileCluster = _(fileClusters).reduce (item, memo) ->
        if item.clients.length < memo
          item.clients.length
        else
          memo

      if not fileCluster?
        return done {err: 'no clusters'}

      pi = 0
      if fileCluster.clients.length
        pi = _(fileCluster.clients).reduce (item, memo) ->
          if item.piGlobalPart >= memo
            item.piGlobalPart + 1
          else
            memo
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
        console.log 'FILECLUSTER', fileCluster
        done null, fileCluster

  @NewFile: (fileId, filePath, fileSize, done) ->
    toSave =
      fileId: fileId
      filePath: filePath
      fileSize: fileSize
      parts: []
      piProcessed: []
      clients: {}
      currentBufferIdx: 0
      storeLevel: 4

    for i in [0...fileSize / fileChunkSize]
      arr = []
      for j in [0...fileChunkSize]
        arr.push -1
      fs.writeFileSync filePath + '_' + i, JSON.stringify arr
      toSave.parts.push i

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
