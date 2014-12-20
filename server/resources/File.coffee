_ = require 'underscore'
fs = require 'fs'
mime = require 'mime'
path = require 'path'
zlib = require 'zlib'
multipartMiddleware = require('connect-multiparty')()

Nodulator = require 'nodulator'

File = require './File'

Settings = require 'settings'
config = new Settings(require '../../settings/config')

piFS = require '../storage'

FileCluster = require './FileCluster'

getFile = (file) ->
  res = null
  if file.isIndexed
    res = piFS.GetFile file.GetHash(), file.idxStoreLevel
    hash = piFS.BufferToArray32 res
    res = piFS.GetFile hash, file.storeLevel
  else
    res = piFS.GetFile file.GetHash(), file.storeLevel

  res

class FileRoute extends Nodulator.Route
  Config: ->

    @Add 'post', '', multipartMiddleware, (req, res) ->
      toSave =
        parent_id: parseInt req.body.parent_id, 10
        name: req.files.file.name
        client_id: parseInt req.body.client_id, 10
        percentage: 0
        storeLevel: 2
        idxStoreLevel: 0
        size: req.files.file.size
        piSize: 0
        isIndexed: false
        maxLevel: false
      File.Deserialize toSave, (err, file) ->
        return res.status(500).send err if err?

        file.Save (err) ->
          return res.status(500).send err if err?

          console.log 'Original file size', file.size
          zlib.gzip fs.readFileSync(req.files.file.path), (err, compressed) ->
            return res.status(500).send err if err?

            console.log 'Compressed file size', compressed

            fs.writeFileSync req.files.file.path, compressed

            FileCluster.NewFile file.id, req.files.file.path, compressed.length, (err) ->
              return res.status(500).send err if err?
              console.log 'lol'

              res.status(200).send file

            # Nodulator.bus.emit 'calc_hash', file, req.files.file.path, config.hashsPath + file.client_id + '/' + file.id

    @Add 'get', '/:id', (req, res) ->
      File.Fetch req.params.id, (err, file) ->
        return res.status(500).send err if err?

        mimetype = mime.lookup(file.name);

        res.setHeader('Content-disposition', 'attachment; filename=' + file.name);
        res.setHeader('Content-type', mimetype);
        zlib.gunzip getFile(file), (err, f) ->
          return res.status(500).send err if err?

          res.status(200).write(f, 'binary')
          res.end()

    @Add 'put', '/:id', (req, res) ->
      File.Fetch req.params.id, (err, file) ->
        return res.status(500).send err if err?

        _(file).extend req.body

        file.Save (err) ->
          return res.status(500).send err if err?

          res.status(200).send file.ToJSON()

class File extends Nodulator.Resource 'file', FileRoute

  GetHash: ->
    if @storeLevel
      piFS.BufferToArray32 fs.readFileSync config.hashsPath + @client_id + '/' + @id
    else
      false

File.Init()

module.exports = File
