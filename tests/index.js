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

    // // A second message increases the counter
    test.message,
    test.jobs('default', { amount: 2 }),
    test.job('default', { class: 'SomeWorker' }),
    test.job('default', { source: 'xmpp-mam' }),
    test.job('default', { body: /id=['"]{{stanza-id}}['"]/ }),
    test.job('default', { body: /<body>.*{{message}}/ }),
    test.job('default', { body: /type=['"]groupchat['"]/ }),
    test.job('default', { body: /to=['"]test@conference[^'"]+['"]/ }),
    test.job('default', { body: /from=['"]admin@[^'"]+['"]/ }),

    test.job('default', { body: /<from jid=['"]admin@[^'"]+['"]/ }),
    test.job('default', { body: /b8346717-6e04-4e52-8799-cb5dce7858df/ }),
    test.job('default', { body: /<FN>Admin Mustermann/ }),

    test.job('default', { body: /<to jid=['"]bob@[^'"]+['"]/ }),
    test.job('default', { body: /1e7f3f82-047b-4eba-9a78-d6b81e4d3647/ }),
    test.job('default', { body: /<FN>Bob Mustermann/ }),

    test.job('default', { body: /<to jid=['"]alice@[^'"]+['"]/ }),
    test.job('default', { body: /fc20e9f2-b223-4a75-ab37-365068d5b52c/ }),
    test.job('default', { body: /<FN>Alice Mustermann/ }),

    test.job('default', { body: /<to jid=['"]admin@[^'"]+['"]/ }),
    test.job('default', { body: /b8346717-6e04-4e52-8799-cb5dce7858df/ }),
    test.job('default', { body: /<FN>Admin Mustermann/ }),

    // After a direct message increases the counter
    test.directMessage('bob'),
    test.jobs('default', { amount: 3 }),
    test.job('default', { class: 'SomeWorker' }),
    test.job('default', { source: 'xmpp-mam' }),
    test.job('default', { body: /<body>.*{{message}}/ }),
    test.job('default', { body: /type=['"]chat['"]/ }),
    test.job('default', { body: /to=['"]bob@[^'"]+['"]/ }),
    test.job('default', { body: /from=['"]admin@[^'"]+['"]/ }),

    test.job('default', { body: /<from jid=['"]admin@[^'"]+['"]/ }),
    test.job('default', { body: /b8346717-6e04-4e52-8799-cb5dce7858df/ }),
    test.job('default', { body: /<FN>Admin Mustermann/ }),

    test.job('default', { body: /<to jid=['"]bob@[^'"]+['"]/ }),
    test.job('default', { body: /1e7f3f82-047b-4eba-9a78-d6b81e4d3647/ }),
    test.job('default', { body: /<FN>Bob Mustermann/ }),

    // After a direct message increases the counter
    test.directMessage('alice'),
    test.jobs('default', { amount: 4 }),
    test.job('default', { body: /alice@/ }),
  ], utils.exit);
});
