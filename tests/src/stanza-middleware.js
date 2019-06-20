const colors = require('colors');
const format = require('../lib/xml-format');

module.exports = (client) => {
  const utils = require('../lib/utils')(client.config);

  client.on('raw:outgoing', (xml) => {
    // In case we ignore non-relevant stanzas
    if (!utils.isRelevant(xml, 'request')) { return; }

    // Format and log the stanza
    if (client.config.debug) {
      console.log("###\n### Request\n###".magenta);
      console.log(format(xml, '>>> '.magenta));
    }
  });

  client.on('raw:incoming', (xml) => {
    // In case we ignore non-relevant stanzas
    if (!utils.isRelevant(xml, 'response')) { return; }

    // Format and log the stanza
    if (client.config.debug) {
      console.log("###\n### Response\n###".blue);
      console.log(format(xml, '<<< '.blue));
    }
  });
};
