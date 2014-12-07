pi.directive 'piAuth', [
  '$window'
  '$http'
  'userService'
  ($window, $http, userService) ->
    return {

      restrict: 'E'

      templateUrl: 'auth-tpl'

      link: (scope, element, attrs) ->
        scope.userService = userService
        scope.state = 'login'
        scope.ident =
          login: ''
          pass: ''

        scope.auth = ->
          $http.post('/api/1/clients/login', scope.ident)
            .success ->
              $window.location.href = '/'
            .error (data) ->
              console.log data
              scope.error = data
              setTimeout ->
                scope.$apply ->
                  scope.error = ''
              , 10000

        scope.signup = ->
          $http.post('/api/1/clients', scope.ident)
            .success ->
              scope.auth()
              # $window.location.href = '/'
            .error (data) ->
              scope.error = data
              setTimeout ->
                scope.$apply ->
                  scope.error = ''
              , 10000

        scope.toggle = ->
          if scope.state is 'login'
            scope.state = 'signup'
          else if scope.state is 'signup'
            scope.state = 'login'

        scope.otherState = ->
          if scope.state is 'login'
            'Signup'
          else if scope.state is 'signup'
            'Login'

    }

]
