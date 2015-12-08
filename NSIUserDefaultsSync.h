//
//  NSIUserDefaultsSync.h
//  NSIHackySack
//
//  Created by Michael Yau on 12/8/15.
//  Copyright © 2015 Michael Yau. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const NSIUserDefaultsSyncWillUpdateRemoteDefaults;
extern NSString * const NSIUserDefaultsSyncDidUpdateRemoteDefaults;
extern NSString * const NSIUserDefaultsSyncWillUpdateLocalDefaults;
extern NSString * const NSIUserDefaultsSyncDidUpdateLocalDefaults;

@interface NSIUserDefaultsSync : NSObject

+ (void)start;

//If there are no included prefixes, then it will save all keys except the excluded prefixes.
//If there are included prefixes and excludedPrefixes, excludedPrefixes take priority.
//Example: included: @[@"cow"] excluded: @[@"cows"] keys changed: @[@"cowl", @"cow", @"cows", @"cowboy"];
//Result: @[@"cowl", @"cow", @"cowboy"] get synced
+ (void)startWithIncludedPrefixes:(NSArray *)includedPrefixes excludedPrefixes:(NSArray *)excludedPrefixes;

@end
