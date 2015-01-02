_ = require 'underscore'
async = require 'async'

Nodulator = require 'nodulator'

File = require './File'

class DirectoryRoute extends Nodulator.Route.DefaultRoute
  Config: ->
    super()

    @Get '/:id', (req, res) ->
      Directory.ListChild req.directory.id, (err, dirs) ->
        return res.status(500).send err if err?

        dir = req.directory.ToJSON()
        dir.child = _(dirs).invoke 'ToJSON'
        res.status(200).send dir

    @Post (req, res) ->
      Directory.Deserialize req.body, (err, result) ->
        return res.status(500).send(err) if err?

        result.Save (err) ->
          return res.status(500).send(err) if err?

          res.status(200).send result.ToJSON()


class Directory extends Nodulator.Resource 'directory', DirectoryRoute

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
