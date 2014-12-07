pi.service 'userService', [
  '$http'
  '$window'
  'socket'
  ($http, $window, socket) ->

    @current = null

    if __user.id?
      @current = __user

    @logout = ->
      $http.post('/api/1/clients/logout')
        .success (data) ->
          $window.location.href = '/'

    @
]
