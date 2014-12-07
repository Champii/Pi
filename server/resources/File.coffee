_ = require 'underscore'
fs = require 'fs'
mime = require 'mime'
path = require 'path'

bus = require '../bus'

Modulator = require '../../Modulator'
multipart = require('connect-multiparty');
multipartMiddleware = multipart();
File = require './File'

piFS = require '../storage'

getHash = (file, path) ->
  timer = setInterval ->
    piFS.GetPercentage file.id, (err, percentage) ->
      return console.error err if err?

      if percentage isnt file.percentage
        file.percentage = percentage
        file.Save (err) ->
          return if err?

          bus.emit 'updateFile', file
  , 10000

  piFS.GetHash file, path, (err, hash) ->
    if err? and err is 'Error not found'
      file.storeLevel--
      file.percentage = 100
      file.Save (err) ->
        bus.emit 'updateFile', file if not err?
      return console.error err if err?

    clearInterval timer

    file.percentage = 100
    file.hash = hash

    file.Save (err) ->
      return console.error err if err?

      bus.emit 'updateFile', file

class FileRoute extends Modulator.Route
  Config: ->

    @Add 'post', '', multipartMiddleware, (req, res) ->
      toSave =
        parent_id: req.body.parent_id
        name: req.files.file.name
        client_id: req.body.client_id
        percentage: 0
        storeLevel: 1
        size: req.files.file.size
      File.Deserialize toSave, (err, file) ->
        return res.status(500).send err if err?

        file.Save (err) ->
          return res.status(500).send err if err?

          res.status(200).send file

          getHash file, req.files.file.path

    @Add 'get', '/:id', (req, res) ->
      File.Fetch req.params.id, (err, file) ->
        return res.status(500).send err if err?

        mimetype = mime.lookup(file.name);

        res.setHeader('Content-disposition', 'attachment; filename=' + file.name);
        res.setHeader('Content-type', mimetype);
        f = piFS.GetFile JSON.parse file.hash
        res.status(200).write(f, 'binary').end()

    @Add 'put', '/:id', (req, res) ->
      File.Fetch req.params.id, (err, file) ->
        return res.status(500).send err if err?

        if req.body.storeLevel isnt file.storeLevel
          fs.writeFileSync '/tmp/' + file.name, piFS.GetFile JSON.parse file.hash
          file.storeLevel = req.body.storeLevel
          file.percentage = 0
          getHash file, '/tmp/' + file.name

        _(file).extend req.body

        file.Save (err) ->
          return res.status(500).send err if err?

          res.status(200).send file.ToJSON()

class File extends Modulator.Resource 'file', FileRoute

  ToJSON: ->
    res = @Serialize()
    delete res.hash
    res


File.Init()

module.exports = File
