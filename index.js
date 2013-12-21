if (process.env.NODE_ENV === 'development') {
    console.log("Using auth plugin /src/index.coffee");
    require('coffee-script');
    module.exports = require('./src/index.coffee');
} else {
    console.log('Using auth plugin /lib');
    module.exports = require('./lib');
}
