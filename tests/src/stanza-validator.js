module.exports = (utils) => {
  const json = (obj) => JSON.stringify(obj);

  const match = (xml, regex, message) => {
    if (regex.constructor !== RegExp) {
      regex = new RegExp(regex);
    }

    if (!regex.test(xml)) {
      utils.logError(message, xml, `Match failed for ${regex}`);
    }
  };

  const matchMissing = (xml, regex, message) => {
    if (regex.constructor !== RegExp) {
      regex = new RegExp(regex);
    }

    if (regex.test(xml)) {
      utils.logError(message, xml, `Match for ${regex}`);
    }
  };

  return {
    jobsEqual: (actual, expected) => {
      if (actual != expected) {
        utils.logError(
          `${json(actual)} jobs found, expected to find ${json(expected)}`
        );
      }
    },
    jobsAtLeast: (actual, expected) => {
      if (actual < expected) {
        utils.logError(
          `${json(actual)} jobs found, ` +
          `expected to find at least ${json(expected)}`
        );
      }
    },
    jobClass: (actual, expected) => {
      if (actual != expected) {
        utils.logError(
          `Job class is ${json(actual)}, should be ${json(expected)}`
        );
      }
    },
    sourceEqual: (actual, expected) => {
      if (actual != expected) {
        utils.logError(
          `Source argument is ${json(actual)}, should be ${json(expected)}`
        );
      }
    },
    bodyContains: (actual, expected) => {
      var good = false;

      if (expected.constructor === RegExp && expected.test(actual)) {
        good = true;
      } else if (actual == expected) {
        good = true;
      }

      if (!good) {
        utils.logError(`Body match failed for ${expected}`, actual);
      }
    },
    contains: match,
    missing: matchMissing,
    message: (room) => {
      return (xml, direction) => {
        if (direction !== 'response') { return; }
        const contains = (regex, message) => match(xml, regex, message);
        const missing = (regex, message) => matchMissing(xml, regex, message);

        contains(
          `<message .* from=['"]${room}/admin['"] .*<body>.*</body></message>`,
          `Message response for ${room} failed.`
        );
      };
    }
  };
};
