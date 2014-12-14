class AuthDirective extends Modulator.Directive 'auth', '$window', '$http', 'userService'

  userService: userService
  state: 'login'
  ident:
    login: ''
    pass: ''

  Auth = ->
    @$http.post('/api/1/clients/login', @ident)
      .success ->
        @$window.location.href = '/'
      .error (data) ->
        @error = data
        setTimeout ->
          @$apply ->
            @error = ''
        , 10000

  Signup = ->
    @$post('/api/1/clients', @ident)
      .success ->
        @Auth()
      .error (data) ->
        @error = data
        setTimeout ->
          @$apply ->
            @error = ''
        , 10000

  Toggle = ->
    if @state is 'login'
      @state = 'signup'
    else if @state is 'signup'
      @state = 'login'

  OtherState = ->
    if @state is 'login'
      'Signup'
    else if @state is 'signup'
      'Login'

AuthDirective.Init()
