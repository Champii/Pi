_ = require 'underscore'
socket = require 'socket.io'
passportSocketIO = require("passport.socketio");

cookieParser = require('cookie-parser')

bus = require '../bus'

sockets = []

exports.init = (server, store, passport) ->
  io = socket.listen server

  onAuthorizeSuccess = (data, accept) ->
    accept(null, true);

  onAuthorizeFail = (data, message, error, accept) ->
    return accept new Error message if error

    accept(null, false);

  io.use passportSocketIO.authorize
    passport:       passport
    cookieParser:   cookieParser
    key:            'pi'
    secret:         'pi'
    store:          store
    success:        onAuthorizeSuccess
    fail:           onAuthorizeFail

  io.sockets.on 'connection', (socket) ->

    # console.log socket.request
    socket.join 'client-' + socket.request.user.id

    socket.once 'disconnect', () ->


  bus.on 'updateFile', (file) ->
    emitClient file.client_id, 'updateFile', file

  emitClient = (clientId, args...) ->
    io.sockets.in('client-' + clientId).emit.apply io.sockets.in('client-' + clientId), args
