_ = require 'underscore'
async = require 'async'

Modulator = require 'Modulator'

File = require './File'

class DirectoryRoute extends Modulator.Route.DefaultRoute
  Config: ->
    super()

    @Add 'get', '/:id', (req, res) ->
      Directory.ListChild req.directory.id, (err, dirs) ->
        return res.status(500).send err if err?

        dir = req.directory.ToJSON()
        dir.child = _(dirs).invoke 'ToJSON'
        res.status(200).send dir

    @Add 'post', (req, res) ->
      Directory.Deserialize req.body, (err, result) ->
        return res.status(500).send(err) if err?

        result.Save (err) ->
          return res.status(500).send(err) if err?

          res.status(200).send result.ToJSON()


class Directory extends Modulator.Resource 'directory', DirectoryRoute

  @ListChild: (id, done) =>
    @ListBy 'parent_id', id, (err, dirs) =>
      return done err if err?

      File.ListBy 'parent_id', id, (err, files) ->
        return done err if err?

        for file in files
          file.file = true

        done null, _(dirs).extend files

Directory.Init()

module.exports = Directory
