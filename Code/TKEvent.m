//
//  TKEvent.m
//  TransitionKit
//
//  Created by Blake Watters on 3/17/13.
//  Copyright (c) 2013 Blake Watters. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "TKEvent.h"
#import "TKState.h"

static NSString *TKDescribeStates(NSArray *states)
{
    if (! [states count]) return @"any state";
    
    NSMutableString *description = [NSMutableString string];
    [states enumerateObjectsUsingBlock:^(TKState *state, NSUInteger idx, BOOL *stop) {
        NSString *separator = @"";
        if (idx < [states count] - 1) separator = (idx == [states count] - 2) ? @" and " : @", ";
        [description appendFormat:@"'%@'%@", state.name, separator];
    }];
    return description;
}


@interface TKEvent ()
@property (nonatomic, copy, readwrite) NSString *name;
/** Maps destination state (key) to source states (value). */
@property (nonatomic, copy, readwrite) NSDictionary *destinationToSourceMap;
@property (nonatomic, copy) BOOL (^shouldFireEventBlock)(TKEvent *, TKTransition *);
@property (nonatomic, copy) void (^willFireEventBlock)(TKEvent *, TKTransition *);
@property (nonatomic, copy) void (^didFireEventBlock)(TKEvent *, TKTransition *);
@end

@implementation TKEvent

+ (instancetype)eventWithName:(NSString *)name transitioningFromStates:(NSArray *)sourceStates toState:(TKState *)destinationState
{
    if (! [name length]) [NSException raise:NSInvalidArgumentException format:@"The event name cannot be blank."];
    if (!destinationState) [NSException raise:NSInvalidArgumentException format:@"The destination state cannot be nil."];
    TKEvent *event = [self new];
    event.name = name;
    [event addTransitionFromStates:sourceStates toState:destinationState];
    return event;
}

- (void)addTransitionFromStates:(NSArray *)sourceStates toState:(TKState *)destinationState
{
    if (!destinationState) [NSException raise:NSInvalidArgumentException format:@"The destination state cannot be nil."];

    // make sure the source -> destination transition is not yet added
    if ([self.destinationStates containsObject:destinationState])
    {
        NSArray *existingSourceStates = [self.destinationToSourceMap objectForKey:destinationState];
        for (TKState *state in sourceStates)
        {
            if ([existingSourceStates containsObject:state]) [NSException raise:NSInvalidArgumentException format:@"The transition %@ -> %@ is already defined for event %@.", state.name, destinationState.name, self.name];
        }
    }

    // make sure the source states are disjunct with the already defined source states
    for (TKState *state in sourceStates)
    {
        if (! [state isKindOfClass:[TKState class]])  [NSException raise:NSInvalidArgumentException format:@"Expected a `TKState` object, instead got a `%@` (%@)", [state class], state];
        for (TKState *srcState in self.sourceStates)
        {
            if ([srcState.name isEqualToString:state.name]) [NSException raise:NSInvalidArgumentException format:@"A source state named `%@` is already registered for the event %@", state.name, self.name];
        }
    }

    NSMutableDictionary *intermediateMap = [NSMutableDictionary dictionaryWithDictionary:self.destinationToSourceMap];
    if (!sourceStates)
    {
        if ([self.sourceStates containsObject:[NSNull null]]) [NSException raise:NSInvalidArgumentException format:@"There is already an unconditional source state (nil) registered for event %@", self.name];
        [intermediateMap setObject:[NSNull null] forKey:destinationState];
    }
    else
    {
        // if the destination state exists, add sources to the existing destination
        NSArray *existingSourceStates = [intermediateMap objectForKey:destinationState];
        NSMutableArray *joinedSourceStates = [NSMutableArray arrayWithArray:existingSourceStates];
        [joinedSourceStates addObjectsFromArray:sourceStates];
        [intermediateMap setObject:[NSArray arrayWithArray:joinedSourceStates] forKey:destinationState];
    }
    self.destinationToSourceMap = intermediateMap;
}

- (NSArray *)sourceStates
{
    NSMutableArray *sourceStates = [[NSMutableArray alloc] init];
    for (TKState *state in self.destinationStates)
    {
        NSArray *states = [self.destinationToSourceMap objectForKey:state];
        if ([[NSNull null] isEqual: states])
        {
            [sourceStates addObject:[NSNull null]];
        }
        else
        {
            [sourceStates addObjectsFromArray:states];
        }
    }
    if (1 == sourceStates.count && [[NSNull null] isEqual:sourceStates.firstObject]) return nil;
    return [NSArray arrayWithArray:sourceStates];
}

- (NSArray *)destinationStates
{
    return [self.destinationToSourceMap allKeys];
}

- (TKState *)destinationStateForSourceState:(TKState *)sourceState
{
    __block TKState *destinationState = nil;
    [self.destinationToSourceMap enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSArray *sourceStates = (NSArray *) obj;
        if ([sourceStates containsObject:sourceState])
        {
            destinationState = (TKState *)key;
            *stop = YES;
        }
    }];
    return destinationState;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p '%@' transitions from %@ to %@>", NSStringFromClass([self class]), self, self.name, TKDescribeStates(self.sourceStates), TKDescribeStates(self.destinationStates)];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    if (!self) {
        return nil;
    }
    
    self.name = [aDecoder decodeObjectForKey:@"name"];
    NSData *encodedDictData = [aDecoder decodeObjectForKey:@"destinationToSourceMapData"];
    self.destinationToSourceMap = [NSKeyedUnarchiver unarchiveObjectWithData:encodedDictData];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:@"name"];

    NSData *encodedDictData = [NSKeyedArchiver archivedDataWithRootObject:self.destinationToSourceMap];
    [aCoder encodeObject:encodedDictData forKey:@"destinationToSourceMapData"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    TKEvent *copiedEvent = [[[self class] allocWithZone:zone] init];
    copiedEvent.name = self.name;
    copiedEvent.destinationToSourceMap = self.destinationToSourceMap;
    copiedEvent.shouldFireEventBlock = self.shouldFireEventBlock;
    copiedEvent.willFireEventBlock = self.willFireEventBlock;
    copiedEvent.didFireEventBlock = self.didFireEventBlock;
    return copiedEvent;
}

@end
