class AuthDirective extends Nodulator.Directive 'auth', '$window', '$http', '$timeout', 'userService'

  state: 'login'
  ident:
    login: ''
    pass: ''

  Auth: ->
    @$http.post('/api/1/clients/login', @ident)
      .success =>
        @$window.location.href = '/'
      .error (data) =>
        @error = data
        @$timeout =>
          @$apply =>
            @error = ''
        , 5000

  Signup: ->
    @$http.post('/api/1/clients', @ident)
      .success =>
        @Auth()
      .error (data) =>
        @error = data
        @$timeout =>
          @$apply =>
            @error = ''
        , 5000

  Toggle: =>
    if do @StateIsLogin
      @state = 'signup'
    else if do @StateIsSignUp
      @state = 'login'
    @ident.login = @ident.pass = ''

  StateIsLogin: =>
    @state is "login"

  StateIsSignUp: =>
    @state is "signup"

AuthDirective.Init()
