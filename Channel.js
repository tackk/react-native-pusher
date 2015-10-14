'use strict';

var React = require('react-native');
var {
  NativeAppEventEmitter,
  NativeModules: {
    RNPusherClient,
  }
} = React;

class Channel {
  constructor(name) {
    this.name = name;
    this.subscribed = false;
    this._callbacks = {};

    this.subscription = NativeAppEventEmitter.addListener('Pusher.NewEvent', this.handleEvent.bind(this));
  }

  handleEvent(event) {
    if (! this.subscribed) {
      return this;
    }

    // Only listen for this channel
    if (event.channel !== this.name) {
      return this;
    }

    var callbacks = this._callbacks[event.name];
    if (callbacks && callbacks.length > 0) {
      for (var i = 0; i < callbacks.length; i++) {
        callbacks[i](event.data);
      }
    }

    return this;
  }

  subscribe() {
    if (this.subscribed) {
      return this;
    }

    RNPusherClient.subscribe(this.name);

    this.subscribed = true;

    return this;
  }

  unsubscribe() {
    if (!this.subscribed) {
      return this;
    }

    if (this.subscription && this.subscription.remove) {
      this.subscription.remove();
    }

    RNPusherClient.unsubscribe(this.name);

    this.subscribed = false;

    return this;
  }

  bind(event, callback) {
    if (! this._callbacks.hasOwnProperty(event)) {
      this._callbacks[event] = [];
      RNPusherClient.bind(this.name, event);
    }

    this._callbacks[event].push(callback);

    return this;
  }

  unbind(event, callback) {
    if (! this._callbacks.hasOwnProperty(event)) {
      return this;
    }

    this._callbacks[event] = this._callbacks[event].filter((binding) => {
      return (binding !== callback);
    });

    if (!this._callbacks[event].length) {
      delete this._callbacks[event];
    }

    RNPusherClient.unbind(this.name, event);

    return this;
  }

  // trigger(event, data) {
  //   noop (for now)
  // }
}

module.exports