//
//  RNPusherClient.m
//  RNPusherClient
//
//  Created by Dan Horrigan on 9/14/15.
//  Copyright (c) 2015 Tackk. All rights reserved.
//


#import <Pusher/Pusher.h>
#import "RNPusherClient.h"
#import "RCTBridgeModule.h"
#import "RCTEventDispatcher.h"

NSString *const PusherNewEvent = @"Pusher.NewEvent";
NSString *const PusherWillConnect = @"Pusher.WillConnect";
NSString *const PusherDidConnect = @"Pusher.DidConnect";
NSString *const PusherDidDisconnectWithError = @"Pusher.DidDisconnectWithError";
NSString *const PusherFailedWithError = @"Pusher.FailedWithError";
NSString *const PusherWillAutomaticallyReconnect = @"Pusher.WillAutomaticallyReconnect";
NSString *const PusherWillAuthorizeChannel = @"Pusher.WillAuthorizeChannel";
NSString *const PusherAuthorizationPayloadFromResponseData = @"Pusher.AuthorizationPayloadFromResponseData";
NSString *const PusherDidSubscribeToChannel = @"Pusher.DidSubscribeToChannel";
NSString *const PusherDidUnsubscribeFromChannel = @"Pusher.DidUnsubscribeFromChannel";
NSString *const PusherDidFailToSubscribeToChannel = @"Pusher.DidFailToSubscribeToChannel";
NSString *const PusherDidReceiveErrorEvent = @"Pusher.DidReceiveErrorEvent";


@implementation RNPusherClient
{
  PTPusher *_client;
  NSString *_socketId;
}

RCT_EXPORT_MODULE();

@synthesize bridge = _bridge;


/**
 Connect to Pusher.
 
 @param apiKey The Pusher API key to connect with.
 */
RCT_EXPORT_METHOD(connect:(NSString *)apiKey)
{
  _client = [PTPusher pusherWithKey:apiKey delegate:self encrypted:YES];
  [_client connect];
}


/**
 Disconnect from Pusher.
 */
RCT_EXPORT_METHOD(disconnect)
{
  [_client disconnect];
}


/**
 Subscribe to a channel.
 
 @param channelName The channel to subscribe to.
 */
RCT_EXPORT_METHOD(subscribe:(NSString *)channelName)
{
  PTPusherChannel *channel = [_client channelNamed:channelName];

  if (! channel) {
    [_client subscribeToChannelNamed:channelName];
  }
}


/**
 Unsubscribe from a channel.
 
 @param channelName The channel to unsubscribe from.
 */
RCT_EXPORT_METHOD(unsubscribe:(NSString *)channelName)
{
  PTPusherChannel *channel = [_client channelNamed:channelName];
  
  if (channel) {
    [channel unsubscribe];
  }
}


/**
 Bind to an event in a channel.
 
 @param channelName The channel to bind the event on.
 @param eventName The name of the event to bind to.
 */
RCT_EXPORT_METHOD(bind:(NSString *)channelName withEventName:(NSString *)eventName)
{
  PTPusherChannel *channel = [_client channelNamed:channelName];

  if (channel) {
    // TODO: keep track of the binding
    [channel bindToEventNamed:eventName handleWithBlock:^(PTPusherEvent *channelEvent) {
      [self.bridge.eventDispatcher sendAppEventWithName:PusherNewEvent
                                                   body:@{@"name": channelEvent.name, @"data": channelEvent.data}];
    }];
  }
}


/**
 Unbind an event from the channel.
 
 @param channelName The channel to unbind the event from.
 @param eventName The name of the event to unbind.
 */
RCT_EXPORT_METHOD(unbind:(NSString *)channelName withEventName:(NSString *)eventName)
{
  PTPusherChannel *channel = [_client channelNamed:channelName];
  
  if (channel) {
    // TODO: remove the binding
  }
}


// Pusher Delegate Methods

/**
 Notifies the delegate that the PTPusher instance is about to connect to the Pusher service.
 
 @param pusher The PTPusher instance that is connecting.
 @param connection The connection for the pusher instance.
 @return NO to abort the connection attempt.
 */
- (BOOL)pusher:(PTPusher *)pusher connectionWillConnect:(PTPusherConnection *)connection
{
  [self.bridge.eventDispatcher sendAppEventWithName:PusherWillConnect body:nil];

  return YES;
}


/**
 Notifies the delegate that the PTPusher instance has connected to the Pusher service successfully.
 
 @param pusher The PTPusher instance that has connected.
 @param connection The connection for the pusher instance.
 */
- (void)pusher:(PTPusher *)pusher connectionDidConnect:(PTPusherConnection *)connection
{
  [self.bridge.eventDispatcher sendAppEventWithName:PusherDidConnect
                                               body:connection.socketID];
}


/**
 Notifies the delegate that the PTPusher instance has disconnected from the Pusher service.
 
 Clients should check the value of the willAttemptReconnect parameter before trying to reconnect manually.
 In most cases, the client will try and automatically reconnect, depending on the error code returned by
 the Pusher service.
 
 If willAttemptReconnect is YES, clients can expect a pusher:connectionWillReconnect:afterDelay: message
 immediately following this one. Clients can return NO from that delegate method to cancel the automatic
 reconnection attempt.
 
 If the client has disconnected due to a fatal Pusher error (as indicated by the error code),
 willAttemptReconnect will be NO and the error domain will be `PTPusherFatalErrorDomain`.
 
 @param pusher The PTPusher instance that has connected.
 @param connection The connection for the pusher instance.
 @param error If the connection disconnected abnormally, error will be non-nil.
 @param willAttemptReconnect YES if the client will try and reconnect automatically.
 */
- (void)pusher:(PTPusher *)pusher connection:(PTPusherConnection *)connection didDisconnectWithError:(NSError *)error willAttemptReconnect:(BOOL)willAttemptReconnect
{
  // Have to send an object as the event body, so we turn the BOOL into an NSNumber
  NSNumber *willReconnect = [NSNumber numberWithBool:willAttemptReconnect];

  [self.bridge.eventDispatcher sendAppEventWithName:PusherDidDisconnectWithError body:willReconnect];
}


/**
 Notifies the delegate that the PTPusher instance failed to connect to the Pusher service.
 
 In the case of connection failures, the client will *not* attempt to reconnect automatically.
 Instead, clients should implement this method and check the error code and manually reconnect
 the client if it makes sense to do so.
 
 @param pusher The PTPusher instance that has connected.
 @param connection The connection for the pusher instance.
 @param error The connection error.
 */
- (void)pusher:(PTPusher *)pusher connection:(PTPusherConnection *)connection failedWithError:(NSError *)error
{
  [self.bridge.eventDispatcher sendAppEventWithName:PusherDidDisconnectWithError body:@{
    @"code": [NSNumber numberWithLong:error.code],
    @"error": error.localizedDescription,
    @"userInfo": error.userInfo,
  }];
}


/**
 Notifies the delegate that the PTPusher instance will attempt to automatically reconnect.
 
 You may wish to use this method to keep track of the number of automatic reconnection attempts and abort after a fixed number.
 
 @param pusher The PTPusher instance that has connected.
 @param connection The connection for the pusher instance.
 @return NO if you do not want the client to attempt an automatic reconnection.
 */
- (BOOL)pusher:(PTPusher *)pusher connectionWillAutomaticallyReconnect:(PTPusherConnection *)connection afterDelay:(NSTimeInterval)delay
{
  NSNumber *delaySeconds = [NSNumber numberWithDouble:delay];

  [self.bridge.eventDispatcher sendAppEventWithName:PusherWillAutomaticallyReconnect body:delaySeconds];
  
  return YES;
}


/**
 Notifies the delegate of the request that will be used to authorize access to a channel.
 
 When using the Pusher Javascript client, authorization typically relies on an existing session cookie
 on the server; when the Javascript client makes an AJAX POST to the server, the server can return
 the user's credentials based on their current session.
 
 When using libPusher, there will likely be no existing server-side session; authorization will
 need to happen by some other means (e.g. an authorization token or HTTP basic auth).
 
 By implementing this delegate method, you will be able to set any credentials as necessary by
 modifying the request as required (such as setting POST parameters or headers).
 
 @param pusher The PTPusher instance that is requesting authorization
 @param channel The channel that requires authorizing
 @param request A mutable URL request that will be POSTed to the configured `authorizationURL`
 */
- (void)pusher:(PTPusher *)pusher willAuthorizeChannel:(PTPusherChannel *)channel withRequest:(NSMutableURLRequest *)request
{
  [self.bridge.eventDispatcher sendAppEventWithName:PusherWillAuthorizeChannel body:nil];
}


/**
 Allows the delegate to return authorization data in the format required by Pusher from a
 non-standard respnse.
 
 When using a remote server to authorize access to a private channel, the server is expected to
 return an authorization payload in a specific format which is then sent to Pusher when connecting
 to a private channel.
 
 Sometimes, a server might return a non-standard response, for example, the auth data may be a sub-set
 of some bigger response.
 
 If implemented, Pusher will call this method with the response data returned from the authorization
 URL and will use whatever dictionary is returned instead.
 */
 - (NSDictionary *)pusher:(PTPusher *)pusher authorizationPayloadFromResponseData:(NSDictionary *)responseData
{
  [self.bridge.eventDispatcher sendAppEventWithName:PusherAuthorizationPayloadFromResponseData body:responseData];
  
  return responseData;
}


/**
 Notifies the delegate that the PTPusher instance has subscribed to the specified channel.
 
 This method will be called after any channel authorization has taken place and when a subscribe event has been received.
 
 @param pusher The PTPusher instance that has connected.
 @param channel The channel that was subscribed to.
 */
- (void)pusher:(PTPusher *)pusher didSubscribeToChannel:(PTPusherChannel *)channel
{
  [self.bridge.eventDispatcher sendAppEventWithName:PusherDidSubscribeToChannel body:channel.name];
}


/**
 Notifies the delegate that the PTPusher instance has unsubscribed from the specified channel.
 
 This method will be called immediately after unsubscribing from a channel.
 
 @param pusher The PTPusher instance that has connected.
 @param channel The channel that was unsubscribed from.
 */
- (void)pusher:(PTPusher *)pusher didUnsubscribeFromChannel:(PTPusherChannel *)channel
{
  [self.bridge.eventDispatcher sendAppEventWithName:PusherDidUnsubscribeFromChannel body:channel.name];
}


/**
 Notifies the delegate that the PTPusher instance failed to subscribe to the specified channel.
 
 The most common reason for subscribing failing is authorization failing for private/presence channels.
 
 @param pusher The PTPusher instance that has connected.
 @param channel The channel that was subscribed to.
 @param error The error returned when attempting to subscribe.
 */
- (void)pusher:(PTPusher *)pusher didFailToSubscribeToChannel:(PTPusherChannel *)channel withError:(NSError *)error
{
  [self.bridge.eventDispatcher sendAppEventWithName:PusherDidFailToSubscribeToChannel body:@{
    @"code": [NSNumber numberWithLong:error.code],
    @"error": error.localizedDescription,
    @"userInfo": error.userInfo,
  }];
}


/**
 Notifies the delegate that an error event has been received.
 
 If a client is binding to all events, either through the client or using NSNotificationCentre, they will also
 receive notification of this event like any other.
 
 @param pusher The PTPusher instance that received the event.
 @param errorEvent The error event.
 */
- (void)pusher:(PTPusher *)pusher didReceiveErrorEvent:(PTPusherErrorEvent *)errorEvent
{
  [self.bridge.eventDispatcher sendAppEventWithName:PusherDidReceiveErrorEvent body:@{
    @"code": [NSNumber numberWithLong:errorEvent.code],
    @"error": errorEvent.message,
  }];
}

@end
