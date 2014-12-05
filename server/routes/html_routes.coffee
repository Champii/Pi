bus = require '../bus'

exports.mount = (app) ->

  app.get '/favicon.ico', (req, res) ->
    res.status(200).end()

  app.get '*', (req, res) ->

    res.render 'index',
      user: {id: req.userId}


    # user = {}
    # if req.user?
    #   user = req.user

    # res.render 'index',
    #   user: user

