// Generated by CoffeeScript 1.7.1
(function() {
  var bus;

  bus = require('../bus');

  exports.mount = function(app) {
    app.get('/favicon.ico', function(req, res) {
      return res.status(200).end();
    });
    return app.get('*', function(req, res) {
      var rend, u;
      u = {
        user: {}
      };
      rend = 'auth';
      if (req.user != null) {
        u.user = req.user;
        rend = 'index';
      }
      return res.render(rend, u);
    });
  };

}).call(this);
