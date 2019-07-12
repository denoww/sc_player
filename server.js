require('coffeescript').register();
require('./env');
require('sc-node-tools');

global.homePath = (process.env.HOME || process.env.HOMEPATH || process.env.USERPROFILE) + '/'
global.configPath = global.homePath + '.config/sc-player/'

// servers
console.log('STARTING SERVERS...');
require('./app/classes/download');
require('./app/classes/logs')();
require('./app/classes/grade')();
require('./app/classes/feeds')();
require('./app/servers/web')();
require('./application');

process.env['ELECTRON_DISABLE_SECURITY_WARNINGS'] = 'true';