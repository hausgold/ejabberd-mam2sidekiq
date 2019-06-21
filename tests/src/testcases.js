const faker = require('faker');
const setupClient = require('./client');

module.exports = (client, utils) => {
  // Setup a reference shortcut
  var config = client.config;

  // Default message matcher
  const msgMatcher = (msg) => new RegExp(`<stanza-id .*${msg}`, 'g');

  // Setup the stanza validator
  const validator = require('./stanza-validator')(utils);

  // Setup the Redis client
  const redis = require('redis').createClient(config.redis);
  // Otherwise the client would hang as long as the
  redis.unref();

  // Detect if we are running on CI or not
  const ci = process.env.CI != undefined;

  // Configure a timeout for the message responses
  const messageTimeout = (ci) ? 6000 : 3000;

  return {
    // Send message to room
    message: (callback) => {
      // Wait for the XMPP client
      setTimeout(() => {
        client.joinRoom(
          config.room,
          // Nickname
          'Admin Mustermann (b8346717-6e04-4e52-8799-cb5dce7858df)'
        );

        setTimeout(() => {
          utils.log('Send a new message to ' + config.room.blue);
          let message = faker.hacker.phrase();
          let callbacked = false;
          let safeMessage = utils.escapeXml(message);

          utils.config().lastMessage = safeMessage;
          utils.setMatcher(msgMatcher(safeMessage), (xml, direction) => {
            if (callbacked) { return; }
            callbacked = true;

            // Check the input message
            validator.message(config.room)(xml, direction);
            // Continue
            setTimeout(() => callback(), 200);
          });

          setTimeout(() => {
            client.sendMessage({
              to: config.room,
              body: message,
              type: 'groupchat'
            });
          }, 200);
        }, 200);
      }, 200);
    },

    // Send a direct chat message
    directMessage: (to) => {
      return (callback) => {
        to = `${to}@${config.hostname}`;
        utils.log('Send a new message to ' + to.blue);

        setTimeout(() => {
          let message = faker.hacker.phrase();
          utils.config().lastMessage = utils.escapeXml(message);
          client.sendMessage({
            to: to,
            body: message
          });
          setTimeout(callback, messageTimeout);
        }, 200);
      };
    },

    // Ask for all jobs on the queue (count)
    jobs: (queue, expected) => {
      return (callback) => {
        utils.setMatcherFake();
        utils.log('Ask for the number of jobs on the ' +
                  queue.blue + ' '.reset + 'queue');
        utils.log('  Check for ' + expected.amount.toString().blue + ' jobs');
        redis.llen(`queue:${queue}`, function(err, length) {
          if (err) { return callback(err); }

          validator.jobsEqual(length, expected.amount);
          callback();
        });
      };
    },

    // Ask for the last Sidekiq job on the queue
    job: (queue, expected) => {
      return (callback) => {
        utils.setMatcherFake();
        utils.log('Ask for the last job on the ' +
                  queue.blue + ' '.reset + 'queue');
        key = Object.keys(expected)[0];
        utils.log('  Check ' + key.blue + ' for ' +
                  expected[key].toString().blue);

        redis.lrange(`queue:${queue}`, 0, 0, function(err, jobs) {
          if (err) { return callback(err); }

          validator.jobsAtLeast(jobs.length, 1);
          let job = jobs[0];

          // No job, nothing to check against
          if (!job) { return callback(); }

          // Decode the job data
          job = JSON.parse(job);

          if (expected.class) {
            validator.jobsEqual(job.class, expected.class);
          }

          if (expected.source) {
            validator.sourceEqual(job.args[1], expected.source);
          }

          if (expected.body) {
            body = expected.body.toString().replace(/^\/|\/$/g, '');

            if (~body.indexOf('{{message}}')) {
              body = body.replace('{{message}}', utils.config().lastMessage);
              expected.body = new RegExp(body);
            }

            if (~body.indexOf('{{stanza-id}}')) {
              body = body.replace('{{stanza-id}}', utils.config().lastStanzaId);
              expected.body = new RegExp(body);
            }

            validator.bodyContains(job.args[0], expected.body);
          }

          // console.log(utils.config().lastMessage);
          // console.log(utils.config().lastStanzaId);
          // console.log(job);

          callback();
        });
      };
    }
  };
};
