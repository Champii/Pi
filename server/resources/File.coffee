_ = require 'underscore'
fs = require 'fs'
mime = require 'mime'
path = require 'path'


Modulator = require '../../Modulator'
multipart = require('connect-multiparty');
multipartMiddleware = multipart();
File = require './File'

Settings = require 'settings'
config = new Settings(require '../../settings/config')

piFS = require '../storage'

getHash = (f, srcPath, destPath) ->
  timer = setInterval ->
    piFS.GetPercentage destPath + '_tmp', (err, percentage) ->
      return console.error err if err?

      if percentage.length < 4 and percentage isnt f.percentage
        File.Fetch f.id, (err, f) ->
          return console.error err if err?

          f.percentage = percentage
          f.Save (err) ->
            return console.error err if err?

            Modulator.bus.emit 'updateFile', f
  , 5000

  error = (e) ->
    clearInterval timer
    console.error e
    File.Fetch f.id, (error, file) ->
      file.percentage = 100
      file.maxLevel = true
      file.Save (err) ->
        Modulator.bus.emit 'updateFile', file if not err?
    e

  callback = (err, hash) ->
    console.log 'HASH', err, hash
    File.Fetch f.id, (e, file) ->
      return error e if e?

      if err? and err is 'Error not found'
        if file.isIndexed or file.storeLevel < 5
          return error err
        else
          file.isIndexed = true
          file.idxStoreLevel = 0
          file.percentage = 0
          file.Save (err) ->
            Modulator.bus.emit 'updateFile', file if not err?
            # fs.writeFileSync srcPath, piFS.Array32ToBuffer file.hash
            fs.writeFileSync srcPath, fs.readFileSync destPath
            getHash file, srcPath, destPath

        clearInterval timer
        return console.error err if err?
      else if err?
        clearInterval timer
        return console.error err if err?


      if file.isIndexed
        file.idxStoreLevel++
      else
        file.storeLevel++

      file.percentage = 100
      file.piSize = hash.length * 4
      # console.log hash
      fs.writeFileSync destPath, piFS.Array32ToBuffer hash

      file.Save (err) ->
        return error err if err?

        Modulator.bus.emit 'updateFile', file

        clearInterval timer
        getHash file, srcPath, destPath

  if f.isIndexed
    piFS.GetHash srcPath, destPath, f.idxStoreLevel + 1, callback
  else
    piFS.GetHash srcPath, destPath, f.storeLevel + 1, callback

getFile = (file) ->
  res = null
  if file.isIndexed
    res = piFS.GetFile file.GetHash(), file.idxStoreLevel
    hash = piFS.BufferToArray32 res
    res = piFS.GetFile hash, file.storeLevel
  else
    res = piFS.GetFile file.GetHash(), file.storeLevel

  res

class FileRoute extends Modulator.Route
  Config: ->

    # @Add 'post', '', (req, res) ->
    #   console.log 'trololo'
    @Add 'post', '', multipartMiddleware, (req, res) ->
      console.log 'Pas glop'
      toSave =
        parent_id: req.body.parent_id
        name: req.files.file.name
        client_id: req.body.client_id
        percentage: 0
        storeLevel: 1
        idxStoreLevel: 0
        size: req.files.file.size
        piSize: 0
        isIndexed: false
        maxLevel: false
      File.Deserialize toSave, (err, file) ->
        return res.status(500).send err if err?

        file.Save (err) ->
          return res.status(500).send err if err?

          res.status(200).send file
          getHash file, req.files.file.path, config.hashsPath + file.client_id + '/' + file.id

    @Add 'get', '/:id', (req, res) ->
      File.Fetch req.params.id, (err, file) ->
        return res.status(500).send err if err?

        mimetype = mime.lookup(file.name);

        res.setHeader('Content-disposition', 'attachment; filename=' + file.name);
        res.setHeader('Content-type', mimetype);
        res.status(200).write(getFile(file), 'binary')
        res.end()

    @Add 'put', '/:id', (req, res) ->
      File.Fetch req.params.id, (err, file) ->
        return res.status(500).send err if err?

        _(file).extend req.body

        file.Save (err) ->
          return res.status(500).send err if err?

          res.status(200).send file.ToJSON()

class File extends Modulator.Resource 'file', FileRoute

  GetHash: ->
    if @storeLevel
      piFS.BufferToArray32 fs.readFileSync config.hashsPath + @client_id + '/' + @id
    else
      false


File.Init()

module.exports = File
