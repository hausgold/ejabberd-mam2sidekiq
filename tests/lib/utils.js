const moment = require('moment');
const colors = require('colors');
const format = require('./xml-format');
const startAt = new moment();

module.exports = (config) => {
  // Presave some defaults
  const origMatch = `${config.match}`;
  var stanzas = {};
  var matchers = 0;

  // Setup some defaults
  config.errors = [];
  config.matchCallback = null;

  const utils = {
    isRelevant: (xml, direction) => {
      // if (direction == 'response') console.log(xml);

      // In case config says log all, everything is related
      if (!config.skipUnrelated) { return true; }

      // Stop further stanzas when we already had this one before
      if (stanzas[config.match]) { return false; }

      // Try multiple matches based on the given data type
      match = false;
      if (typeof config.match == 'string' && ~xml.indexOf(config.match)) {
        match = true;
      }
      if (config.match instanceof RegExp && config.match.test(xml)) {
        match = true;
      }

      // We have a match, so we save it
      if (match) {
        // Except we are on the default matcher again
        if (config.match !== origMatch) {
          stanzas[config.match] = true;
        }

        // In case we have a matching stanza, save it's id
        utils.saveId(xml);

        // Run hooks if there are any
        if (config.matchCallback) {
          config.matchCallback(xml, direction);
        }

        return true;
      }

      return false;
    },

    saveId: (xml) => {
      let match = xml.match(/<stanza-id .* id=['"]([^'"]+)/);
      if (match && match[1]) {
        config.match = match[1];
        config.lastStanzaId = match[1];

        // console.log('------');
        // console.log(config.match);
        // console.log(xml);
      }
    },

    config: () => config,

    restoreMatcher: () => {
      config.match = origMatch;
      config.matchCallback = null;
      matchers++;
    },

    setMatcher: (match, callback = null) => {
      stanzas = {};
      config.match = match;
      config.matchCallback = callback;
      matchers++;
    },

    setMatcherFake: () => {
      matchers++;
    },

    setMatcherCallback: (callback) => {
      config.matchCallback = callback;
    },

    log: (str, multiple = true, level = 2) => {
      if (!config.debug) {
        multiple = false;
        level = 1;
      }

      let pre = Array(level + 1).join('#');

      if (multiple === true) {
        console.log(`${pre}\n${pre} ${str}\n${pre}`);
      } else {
        console.log(`${pre} ${str}`);
      }
    },

    logError: (message, xml, meta = null) => {
      config.errors.push({
        message: message,
        xml: xml,
        meta: meta
      });
      utils.log('> ' + `${message} (#${config.errors.length})`.red);
    },

    errors: () => {
      if (!config.errors.length) { return; }

      console.log('#');
      utils.log('Error details'.red);
      config.errors.forEach((err, idx) => {
        console.log('#');
        utils.log(`#${++idx} ${err.message}`.red);
        if (err.xml) {
          console.log('#');
          console.log(format(err.xml, '#   '));
          console.log('#');
        }
        if (err.meta) {
          utils.log(`  ${err.meta}`);
          console.log('#');
        }
      });
    },

    stats: () => {
      const endAt = new moment();
      const duration = moment.duration(endAt.diff(startAt));
      const seconds = new String(duration.as('seconds'));
      const bad = config.errors.length;
      var good = matchers - config.errors.length;

      if (good < 0) { good = 0; }

      utils.log([
        'Statistics: ' +
        `${matchers} test cases`.magenta,
        `${good} successful`.green,
        `${bad} failed`.red
      ].join(', '));
      utils.log('Finished in ' + `${seconds}s`.green);
    },

    isoMinute: () => {
      return moment().toISOString().split(':').slice(0, 2).join(':');
    },

    isoHour: () => {
      return moment().toISOString().split(':').slice(0, 1).join(':');
    },

    exit: () => {
      utils.errors();
      utils.stats();
      setTimeout(() => {
        let code = (!config.errors.length) ? 0 : 1;
        process.exit(code);
      }, 200);
    },

    escapeXml: (xml) => {
      let entityMap = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&apos;',
        '/': '&#x2F;',
        '`': '&#x60;',
        '=': '&#x3D;'
      };

      return String(xml).replace(/[&<>"'`=\/]/g, function (s) {
        return entityMap[s];
      });
    }
  };

  return utils;
};
