//
//  NSIUserDefaultsSync.m
//  NSIHackySack
//
//  Created by Michael Yau on 12/8/15.
//  Copyright © 2015 Michael Yau. All rights reserved.
//

#import "NSIUserDefaultsSync.h"

NSString * const NSIUserDefaultsSyncWillUpdateRemoteDefaults = @"com.nsirlconnection.nsiuserdefaultssync.remote.will.update";
NSString * const NSIUserDefaultsSyncDidUpdateRemoteDefaults = @"com.nsirlconnection.nsiuserdefaultssync.remote.did.update";
NSString * const NSIUserDefaultsSyncWillUpdateLocalDefaults = @"com.nsirlconnection.nsiuserdefaultssync.local.will.update";
NSString * const NSIUserDefaultsSyncDidUpdateLocalDefaults = @"com.nsirlconnection.nsiuserdefaultssync.local.did.update";

static NSArray *_includedPrefixes = nil;
static NSArray *_excludedPrefixes = nil;
static BOOL _isSubscribedToLocalChanges = NO;
static BOOL _isSubscribedToRemoteChanges = NO;

@implementation NSIUserDefaultsSync

+ (void)updateRemoteUserDefaults {
    [[NSNotificationCenter defaultCenter] postNotificationName:NSIUserDefaultsSyncWillUpdateRemoteDefaults object:nil];
    
    NSArray *includedPrefixes = [_includedPrefixes copy];
    NSArray *excludedPrefixes = [_excludedPrefixes copy];
    
    NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        BOOL keyIsValid = YES;
        if (includedPrefixes != nil && [includedPrefixes count] > 0) {
            keyIsValid = NO;
            for (NSString *includedPrefix in includedPrefixes) {
                if ([key hasPrefix:includedPrefix]) {
                    keyIsValid = YES;
                    break;
                }
            }
        }
        if (excludedPrefixes != nil && [excludedPrefixes count] > 0 && keyIsValid) {
            for (NSString *excludedPrefix in excludedPrefixes) {
                if ([key hasPrefix:excludedPrefix]) {
                    keyIsValid = NO;
                    break;
                }
            }
        }
        if (keyIsValid) {
            [[NSUbiquitousKeyValueStore defaultStore] setObject:obj forKey:key];
        }
    }];
    
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NSIUserDefaultsSyncDidUpdateRemoteDefaults object:nil];
}

+ (void)updateLocalUserDefaults:(NSNotification *)notification {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NSIUserDefaultsSyncWillUpdateLocalDefaults object:nil];
    
    [self unsubscribeFromLocalChanges];
    NSArray *includedPrefixes = [_includedPrefixes copy];
    NSArray *excludedPrefixes = [_excludedPrefixes copy];
    
    NSArray *changedKeys = [[notification userInfo] objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
    NSDictionary *dictionary = [[[NSUbiquitousKeyValueStore defaultStore] dictionaryRepresentation] dictionaryWithValuesForKeys:changedKeys];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        BOOL keyIsValid = YES;
        if (includedPrefixes != nil && [includedPrefixes count] > 0) {
            keyIsValid = NO;
            for (NSString *includedPrefix in includedPrefixes) {
                if ([key hasPrefix:includedPrefix]) {
                    keyIsValid = YES;
                    break;
                }
            }
        }
        if (excludedPrefixes != nil && [excludedPrefixes count] > 0 && keyIsValid) {
            for (NSString *excludedPrefix in excludedPrefixes) {
                if ([key hasPrefix:excludedPrefix]) {
                    keyIsValid = NO;
                    break;
                }
            }
        }
        if (keyIsValid) {
            [[NSUserDefaults standardUserDefaults] setObject:obj forKey:key];
        }
    }];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self subscribeToLocalChanges];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSIUserDefaultsSyncDidUpdateLocalDefaults object:nil];

}

+ (void)subscribeToRemoteChanges {
    if (_isSubscribedToRemoteChanges) {
        return;
    }
    _isSubscribedToRemoteChanges = ({
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateLocalUserDefaults:)
                                                     name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                   object:nil];
        YES;
    });
}

+ (void)unsubscribeFromRemoteChanges {
    _isSubscribedToRemoteChanges = ({
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                      object:nil];
        NO;
    });
}

+ (void)subscribeToLocalChanges {
    if (_isSubscribedToLocalChanges) {
        return;
    }
    _isSubscribedToLocalChanges = ({
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateRemoteUserDefaults)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];
        YES;
    });
}

+ (void)unsubscribeFromLocalChanges {
    _isSubscribedToLocalChanges = ({
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSUserDefaultsDidChangeNotification
                                                      object:nil];
        NO;
    });
}

+ (void)startWithIncludedPrefixes:(NSArray *)includedPrefixes excludedPrefixes:(NSArray *)excludedPrefixes {
    if (![NSUbiquitousKeyValueStore defaultStore]) {
        return;
    }
    _includedPrefixes = includedPrefixes;
    _excludedPrefixes = excludedPrefixes;
    [self subscribeToRemoteChanges];
    [self subscribeToLocalChanges];
}

+ (void)start {
    [self startWithIncludedPrefixes:nil excludedPrefixes:nil];
}

+ (void)stop {
    [self unsubscribeFromLocalChanges];
    [self unsubscribeFromRemoteChanges];
}

@end
