global.homePath = (process.env.HOME || process.env.HOMEPATH || process.env.USERPROFILE) + '/'
global.configPath = global.homePath + '.config/sc_player/'

require('sc-node-tools')
require('../app/classes/logs')()
require('../app/classes/feeds')()
global.feeds.deleteOldImages()
