Sentry = require('@sentry/electron')
# levels: fatal, error, warning, info, debug, error

Sentry.init
  dsn:              'https://ac78f87fac094b808180f86ad8867f61@sentry.io/1519364'
  debug:            ENV.NODE_ENV == 'development'
  release:          ENV.npm_package_version
  environment:      ENV.NODE_ENV
  attachStacktrace: true

Sentry.configureScope (scope)->
  scope.setTag 'TV_ID', ENV.TV_ID
  scope.setUser id: ENV.TV_ID

module.exports = Sentry
