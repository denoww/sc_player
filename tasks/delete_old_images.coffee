# global.homePath = (process.env.HOME || process.env.USERPROFILE || process.env.HOMEPATH) + '/'
# global.configPath = global.homePath + '.config/sc_player/'
global.homePath = path.join(__dirname) + '/'
global.configPath = global.homePath

require('sc-node-tools')
require('../app/classes/logs')()
require('../app/classes/feeds')()
global.feeds.deleteOldImages()
