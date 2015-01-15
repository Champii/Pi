class PiCtrl extends Nodulator.Controller 'PiCtrl', '$scope', '$location', 'userService'

  Init: ->
    # Scope functions
    @$scope.GetUsername = @GetUsername
    @$scope.SignOut = @SignOut

  GetUsername: =>
    @userService.Get "login"

  SignOut: =>
    do @userService.Logout

PiCtrl.Init()