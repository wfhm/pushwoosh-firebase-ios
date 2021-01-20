//
//  AppDelegate.m
//  demoapp
//
//  Created by Vitaliy Romanychev on 18.12.2020.
//

#import "AppDelegate.h"
#import <Firebase/Firebase.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import <Pushwoosh/Pushwoosh.h>

@interface AppDelegate () <UNUserNotificationCenterDelegate, PWMessagingDelegate, FIRMessagingDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [FIRApp configure];
  [FIRMessaging messaging].delegate = self;
  [Pushwoosh sharedInstance].delegate = self;
  //register for push notifications!
  [[Pushwoosh sharedInstance] registerForPushNotifications];
    
if ([UNUserNotificationCenter class] != nil) {
  // iOS 10 or later
  // For iOS 10 display notification (sent via APNS)
  [UNUserNotificationCenter currentNotificationCenter].delegate = self;
  UNAuthorizationOptions authOptions = UNAuthorizationOptionAlert |
      UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
  [[UNUserNotificationCenter currentNotificationCenter]
      requestAuthorizationWithOptions:authOptions
      completionHandler:^(BOOL granted, NSError * _Nullable error) {
        // ...
      }];
} else {
  // iOS 10 notifications aren't available; fall back to iOS 8-9 notifications.
  UIUserNotificationType allNotificationTypes =
  (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
  UIUserNotificationSettings *settings =
  [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
  [application registerUserNotificationSettings:settings];
}

[application registerForRemoteNotifications];

  return YES;
}

- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[Pushwoosh sharedInstance] handlePushRegistration:deviceToken];
}

//handle token receiving error
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [[Pushwoosh sharedInstance] handlePushRegistrationFailure:error];
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}

#pragma mark - FIRMessaging methods

- (void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)fcmToken {
    NSLog(@"FCM registration token: %@", fcmToken);
    // Notify about received token.
    NSDictionary *dataDict = [NSDictionary dictionaryWithObject:fcmToken forKey:@"token"];
    [[NSNotificationCenter defaultCenter] postNotificationName:
     @"FCMToken" object:nil userInfo:dataDict];
    // TODO: If necessary send token to application server.
    // Note: This callback is fired at each app startup and whenever a new token is generated.
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
  // If you are receiving a notification message while your app is in the background,
  // this callback will not be fired till the user taps on the notification launching the application.
  // TODO: Handle data of notification

  // With swizzling disabled you must let Messaging know about the message, for Analytics
   [[FIRMessaging messaging] appDidReceiveMessage:userInfo];
   [[Pushwoosh sharedInstance] handlePushReceived:userInfo];

  // Print full message.
  NSLog(@"%@", userInfo);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
  NSDictionary *userInfo = notification.request.content.userInfo;

  // With swizzling disabled you must let Messaging know about the message, for Analytics
  [[FIRMessaging messaging] appDidReceiveMessage:userInfo];
  [[[Pushwoosh sharedInstance] notificationCenterDelegateProxy] userNotificationCenter:center willPresentNotification:notification withCompletionHandler:completionHandler];

  // Print full message.
  NSLog(@"%@", userInfo);

  // Change this to your preferred presentation option
  completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionAlert);
}

// Handle notification messages after display notification is tapped by the user.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void(^)(void))completionHandler {
  NSDictionary *userInfo = response.notification.request.content.userInfo;
  // With swizzling disabled you must let Messaging know about the message, for Analytics
  [[FIRMessaging messaging] appDidReceiveMessage:userInfo];
  [[[Pushwoosh sharedInstance] notificationCenterDelegateProxy] userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];

  // Print full message.
  NSLog(@"%@", userInfo);

  completionHandler();
}

#pragma mark Pushwoosh methods

//this event is fired when the push gets received
- (void)pushwoosh:(Pushwoosh *)pushwoosh onMessageReceived:(PWMessage *)message {
    NSLog(@"onMessageReceived: %@", message.payload);
}

//this event is fired when user taps the notification
- (void)pushwoosh:(Pushwoosh *)pushwoosh onMessageOpened:(PWMessage *)message {
    NSLog(@"onMessageOpened: %@", message.payload);
}

@end
