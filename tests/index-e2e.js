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

    // Send a message to a MUC
    test.message,

    // Send second message to a direct chat
    test.directMessage('alice'),
  ], utils.exit);
});
