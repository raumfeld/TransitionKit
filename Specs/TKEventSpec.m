//
//  TKEventSpec.m
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

#import "Kiwi.h"
#import "TKEvent.h"
#import "TKState.h"

SPEC_BEGIN(TKEventSpec)

describe(@"eventWithName:transitioningFromStates:toState:", ^{
    context(@"when the name is `nil`", ^{
        it(@"raises an NSInvalidArgumentException", ^{
            [[theBlock(^{
                [TKEvent eventWithName:nil transitioningFromStates:nil toState:nil];
            }) should] raiseWithName:NSInvalidArgumentException reason:@"The event name cannot be blank."];
        });
    });
    
    context(@"when the name is blank", ^{
        it(@"raises an NSInvalidArgumentException", ^{
            [[theBlock(^{
                [TKEvent eventWithName:@"" transitioningFromStates:nil toState:nil];
            }) should] raiseWithName:NSInvalidArgumentException reason:@"The event name cannot be blank."];
        });
    });
    
    context(@"when the destinationState is `nil`", ^{
        it(@"raises an NSInvalidArgumentException", ^{
            [[theBlock(^{
                [TKEvent eventWithName:@"Name" transitioningFromStates:nil toState:nil];
            }) should] raiseWithName:NSInvalidArgumentException reason:@"The destination state cannot be nil."];
        });
    });
});

describe(@"addTransitionFromStates:toState:", ^{
    context(@"when multiple destinations are added", ^{
        
        __block TKEvent *tkEvent;
        __block TKState *stateA = [TKState stateWithName:@"A"];
        __block TKState *stateB = [TKState stateWithName:@"B"];
        __block TKState *stateC = [TKState stateWithName:@"C"];
        __block TKState *stateX = [TKState stateWithName:@"X"];
        __block TKState *stateZ = [TKState stateWithName:@"Z"];
        beforeEach(^{
            tkEvent = [TKEvent eventWithName:@"MultiEvent" transitioningFromStates:@[stateA, stateB] toState:stateZ];
        });
        
        context(@"when an existing source state is added", ^{
            it(@"raises an NSInvalidArgumentException", ^{
                [[theBlock(^{
                    [tkEvent addTransitionFromStates:@[stateB] toState:stateX];
                }) should] raiseWithName:NSInvalidArgumentException reason:@"A source state named `B` is already registered for the event MultiEvent"];
            });
        });
        context(@"when an existing source and an existing destination state is added", ^{
            it(@"raises an NSInvalidArgumentException", ^{
                [[theBlock(^{
                    [tkEvent addTransitionFromStates:@[stateB] toState:stateZ];
                }) should] raiseWithName:NSInvalidArgumentException reason:@"The transition B -> Z is already defined for event MultiEvent."];
            });
        });
        context(@"when a new source state is added to an existing destination", ^{
            it(@"contains new and old destination states", ^{
                [tkEvent addTransitionFromStates:@[stateC] toState:stateZ];
                
                [[tkEvent.sourceStates should] contain:stateA];
                [[tkEvent.sourceStates should] contain:stateB];
                [[tkEvent.sourceStates should] contain:stateC];
                [[[tkEvent.sourceStates should] have:3] items];

                [[tkEvent.destinationStates should] equal:@[stateZ]];
            });
        });
        context(@"when a new source state is added to an new destination", ^{
            it(@"contains new and old destination states", ^{
                [tkEvent addTransitionFromStates:@[stateC] toState:stateX];
                
                [[tkEvent.sourceStates should] contain:stateA];
                [[tkEvent.sourceStates should] contain:stateB];
                [[tkEvent.sourceStates should] contain:stateC];
                [[[tkEvent.sourceStates should] have:3] items];

                [[tkEvent.destinationStates should] contain:stateX];
                [[tkEvent.destinationStates should] contain:stateZ];
                [[[tkEvent.destinationStates should] have:2] items];
            });
        });
    });
    
    context(@"when nil source states are used", ^{
        
        __block TKState *stateA = [TKState stateWithName:@"A"];
        __block TKState *stateX = [TKState stateWithName:@"X"];
        __block TKState *stateZ = [TKState stateWithName:@"Z"];

        __block TKEvent *tkEvent = [TKEvent eventWithName:@"UnconditionalEvent" transitioningFromStates:nil toState:stateZ];
        
        context(@"when an unique source state is added", ^{
            it(@"contains the new state", ^{
                [tkEvent addTransitionFromStates:@[stateA] toState:stateX];
                
                [[tkEvent.sourceStates should] contain:stateA];
                [[tkEvent.sourceStates should] contain:[NSNull null]];
                [[[tkEvent.sourceStates should] have:2] items];
            });
        });

        context(@"when an second unconditional source state is added", ^{
            it(@"should fail", ^{
                [[theBlock(^{
                    [tkEvent addTransitionFromStates:nil toState:stateX];
                }) should] raiseWithName:NSInvalidArgumentException reason:@"There is already an unconditional source state (nil) registered for event UnconditionalEvent"];
            });
        });
    });
});


context(@"when copied", ^{
});

context(@"when archived", ^{
});

SPEC_END
