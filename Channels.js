'use strict';

var Channel = require('./Channel');

class Channels {
  constructor() {
    this.channels = {};
  }

  add(name) {
    if (! this.channels[name]) {
      this.channels[name] = new Channel(name);
    }
    return this.channels[name];
  }

  remove(name) {
    if (this.channels.hasOwnProperty(name)) {
      var channel = this.channels[name];
      delete this.channels[name];

      return channel;
    }

    return false;
  }

  find(name) {
    return this.channels[name];
  }
}

module.exports = Channels;
