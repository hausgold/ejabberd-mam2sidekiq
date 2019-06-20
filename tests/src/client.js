const xmpp = require('stanza.io');
const colors = require('colors');

const installMiddleware = require('./stanza-middleware');
const setupUtils = require('../lib/utils');

module.exports = (config, callback) => {
  // Setup a new XMPP client
  const client = xmpp.createClient(config);
  const utils = setupUtils(client.config);

  // Install all the nifty handlers to that thing
  installMiddleware(client);

  // Call the user given function when we have a connection
  client.on('session:started', () => {
    client.sendPresence();
    client.enableCarbons();
    setTimeout(() => {
      callback && callback(client, utils);
    }, 500);
  });

  // Connect the new client
  client.connect();
};
