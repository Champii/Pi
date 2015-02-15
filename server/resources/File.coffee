_ = require 'underscore'
fs = require 'fs'
mime = require 'mime'
path = require 'path'
zlib = require 'zlib'
multipartMiddleware = require('connect-multiparty')()

Nodulator = require 'nodulator'

Settings = require 'settings'
config = new Settings(require '../../settings/config')

ccFS = require '../storage/ccFS'

class FileRoute extends Nodulator.Route
  Config: ->

    @Post multipartMiddleware, (req, res) ->
      toSave =
        parent_id: parseInt req.body.parent_id, 10
        name: req.files.file.name
        client_id: parseInt req.body.client_id, 10
        percentage: 0
        storeLevel: 4
        idxStoreLevel: 0
        size: req.files.file.size
        piSize: 0
        uncompressSize: 0
        isIndexed: false
        maxLevel: false
      File.Deserialize toSave, (err, file) ->
        return res.status(500).send err if err?

        file.Save (err) ->
          return res.status(500).send err if err?

          ccFS.GetHash fs.readFileSync(req.files.file.path), (err, hash) =>
            return res.status(500).send err if err?

            fs.writeFileSync config.hashsPath + file.client_id + '/' + file.id, hash.idx

            file.uncompressSize = hash.size
            file.piSize = hash.idx.length

            file.Save (err) ->
              return res.status(500).send err if err?

              res.status(200).send file

    @Get '/:id', (req, res) ->
      File.Fetch req.params.id, (err, file) ->
        return res.status(500).send err if err?

        mimetype = mime.lookup(file.name);

        res.setHeader('Content-disposition', 'attachment; filename=' + file.name);
        res.setHeader('Content-type', mimetype);
        ccFS.GetFile
          idx: fs.readFileSync config.hashsPath + file.client_id + '/' + file.id
          size: file.uncompressSize
        , (err, file) =>
          return res.status(500).send err if err?

          res.status(200).write(file, 'binary')
          res.end()

    @Put '/:id', (req, res) ->
      File.Fetch req.params.id, (err, file) ->
        return res.status(500).send err if err?

        _(file).extend req.body

        file.Save (err) ->
          return res.status(500).send err if err?

          res.status(200).send file.ToJSON()

class File extends Nodulator.Resource 'file', FileRoute

  ToJSON: ->
    _(super()).extend
      percentage: Math.floor @percentage

File.Init()

module.exports = File
FileCluster = require './FileCluster'
