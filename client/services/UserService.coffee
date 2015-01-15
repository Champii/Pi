class UserService extends Nodulator.Service 'user', '$http', '$window', 'socket'

  current: null

  Init: ->
    if __user.id?
      @current = __user

  Logout: =>
    @$http.post('/api/1/clients/logout')
      .success (data) =>
        @$window.location.href = '/'

  Get: (field) ->
    if __user.id? and __user[field]?
      return __user[field]
    undefined


UserService.Init()
