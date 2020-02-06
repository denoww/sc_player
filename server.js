require('coffeescript').register();
require('./env');
require('sc-node-tools');

global.homePath = (process.env.HOME || process.env.USERPROFILE || process.env.HOMEPATH) + '/';
global.configPath = global.homePath + '.config/sc_player/';

// servers
require('./app/classes/logs')();
require('./app/classes/versions_control')();
require('./app/classes/download');
require('./app/classes/grade')();
require('./app/classes/feeds')();
require('./app/servers/web')();
require('./application');

process.env['ELECTRON_DISABLE_SECURITY_WARNINGS'] = 'true';
process.env['ELECTRON_ENABLE_STACK_DUMPING'] = 'true';
