"use strict";

var React = require('react-native');

var {
  NativeAppEventEmitter,
  NativeModules: {
    RNPusherClient,
  }
} = React;

var Channels = require('./Channels');

var PusherWillConnect = "Pusher.WillConnect",
    PusherDidConnect = "Pusher.DidConnect",
    PusherDidDisconnectWithError = "Pusher.DidDisconnectWithError",
    PusherFailedWithError = "Pusher.FailedWithError",
    PusherWillAutomaticallyReconnect = "Pusher.WillAutomaticallyReconnect";

var noop = () => {};

class Client {
  constructor(apiKey) {
    this.socketId = null;
    this.connected = false;
    this.channels = new Channels();

    this._setupEventListeners();

    RNPusherClient.connect(apiKey);
  }

  subscribe(name) {
    var channel = this.channels.add(name);
    channel.subscribe();

    return channel;
  }

  unsubscribe(name) {
    this.channels.remove(name);

    return this;
  }

  channel(name) {
    var channel = this.rooms.channel(name);
    if (!channel) {
      channel = this.subscribe(name);
    }

    return channel;
  }

  onWillConnect() {
    // noop
  }

  onDidConnect(socketId) {
    this.socketId = socketId;
    this.connected = true;
  }

  onDidDisconnectWithError(error) {
    this.socketId = null;
    this.connected = false;
  }

  onFailedWithError(error) {
    this.connected = false;
  }

  _setupEventListeners() {
    NativeAppEventEmitter.addListener(PusherWillConnect, this.onWillConnect.bind(this));
    NativeAppEventEmitter.addListener(PusherDidConnect, this.onDidConnect.bind(this));
    NativeAppEventEmitter.addListener(PusherDidDisconnectWithError, this.onDidDisconnectWithError.bind(this));
    NativeAppEventEmitter.addListener(PusherFailedWithError, this.onFailedWithError.bind(this));
  }

}


module.exports = Client;
