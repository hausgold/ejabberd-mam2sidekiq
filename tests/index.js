#!/usr/bin/env node

const async = require('async');

// Setup a new client and run the test suite
require('./src/client')(require('./config'), (client, utils) => {

  // Get the seeds and test cases available
  const seeds = require('./src/seeds')(client);
  const test = require('./src/testcases')(client, utils);

  // Run each test case, sequentially
  async.waterfall([
    seeds,

    // Initial state
    test.jobs('default', { amount: 0 }),

    // After a message the initial state changes
    test.message,
    test.jobs('default', { amount: 1 }),

    // A second message increases the counter
    test.message,
    test.jobs('default', { amount: 2 }),
    test.job('default', { class: 'SomeWorker' }),
    test.job('default', { source: 'xmpp-mam' }),
    test.job('default', { body: /type=['"]groupchat['"]/ }),
    test.job('default', { body: /to=['"]test@conference[^'"]+['"]/ }),
    test.job('default', { body: /from=['"]admin@[^'"]+['"]/ }),
    test.job('default', { body: /id=['"]{{stanza-id}}['"]/ }),
    test.job('default', { body: /<body>.*{{message}}/ }),

    // After a direct message increases the counter
    test.directMessage('bob'),
    test.jobs('default', { amount: 3 }),
    test.job('default', { class: 'SomeWorker' }),
    test.job('default', { source: 'xmpp-mam' }),
    test.job('default', { body: /type=['"]chat['"]/ }),
    test.job('default', { body: /to=['"]bob@[^'"]+['"]/ }),
    test.job('default', { body: /from=['"]admin@[^'"]+['"]/ }),
    test.job('default', { body: /<body>.*{{message}}/ }),

    // After a direct message increases the counter
    test.directMessage('alice'),
    test.jobs('default', { amount: 4 }),
    test.job('default', { body: /alice@/ }),
  ], utils.exit);
});
