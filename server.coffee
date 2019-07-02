require('./env')
require('sc-node-tools')

# servers
console.log('STARTING SERVERS...')
require('./app/classes/download')
require('./app/classes/grade')()
require('./app/classes/feeds')()
require('./app/classes/logs')()
require('./app/servers/web')()
