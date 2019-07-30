global.homePath = (process.env.HOME || process.env.USERPROFILE || process.env.HOMEPATH) + '/'
global.homePath = '/home/pi/' if global.homePath == '/root/'
global.configPath = global.homePath + '.config/sc_player/'

require('sc-node-tools')
require('../app/classes/logs')()
require('../app/classes/feeds')()
global.feeds.deleteOldImages()
