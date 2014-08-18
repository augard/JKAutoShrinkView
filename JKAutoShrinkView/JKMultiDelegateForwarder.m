//
//  JKMultiDelegateProxy.m
//  JKAutoShrinkViewDemo
//
//  Created by Jackie CHEUNG on 14-1-15.
//  Copyright (c) 2014年 Jackie. All rights reserved.
//

#import "JKMultiDelegateForwarder.h"


@interface JKValue : NSValue

@property (nonatomic, weak) id weakObjectValue;

@end

@implementation JKValue

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.weakObjectValue forKey:@"weak"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self setWeakObjectValue:[aDecoder decodeObjectForKey:@"weak"]];
    }
    return self;
}

+ (NSValue *)valueWithNonretainedObject:(id)anObject
{
    JKValue *value = [[JKValue alloc] init];
    [value setWeakObjectValue:anObject];
    return value;
}

- (id) nonretainedObjectValue
{
    return [self weakObjectValue];
}

- (void *)pointerValue
{
    return nil;
}

- (BOOL)isEqualToValue:(NSValue *)value
{
    return [self.weakObjectValue isEqual:value];
}

@end

@interface JKMultiDelegateForwarder ()
@property (nonatomic, copy) NSArray *forwardingDelegates;
@end

@implementation JKMultiDelegateForwarder
@synthesize forwardingDelegates = _forwardingDelegates;
#pragma mark -
- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector{
    NSMethodSignature *signature;
    for (id delegate in self.forwardingDelegates){
        signature = [delegate methodSignatureForSelector:selector];
        if (signature){
            break;
        }
    }
	return signature;
}

- (void)forwardInvocation:(NSInvocation *)invocation{
    NSString *returnType = [NSString stringWithCString:invocation.methodSignature.methodReturnType encoding:NSUTF8StringEncoding];
    BOOL voidReturnType = [returnType isEqualToString:@"v"];
    
    for (id delegate in self.forwardingDelegates){
        if ([delegate respondsToSelector:invocation.selector]){
            [invocation invokeWithTarget:delegate];
            if (!voidReturnType){
                return;
            }
        }
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector{
    for (id delegate in self.forwardingDelegates){
        if ([delegate respondsToSelector:aSelector]){
            if ([delegate isKindOfClass:[UITextField class]] && [[UITextField class] instancesRespondToSelector:aSelector]){
                continue;
            }
            return YES;
        }
    }
    return NO;
}

#pragma mark - 
- (NSArray *)forwardingDelegates{
    NSMutableArray *delegatesBuilder = [NSMutableArray arrayWithCapacity:[_forwardingDelegates count]];
    for (NSValue *delegateValue in _forwardingDelegates){
        id value = [delegateValue nonretainedObjectValue];
        if (value) {
            [delegatesBuilder addObject:value];
        }
    }
    return [delegatesBuilder copy];
}

- (void)setForwardingDelegates:(NSArray *)forwardingDelegates{
    NSMutableArray *delegatesUnretainedBuilder = [NSMutableArray array];
    for (id delegate in forwardingDelegates){
        [delegatesUnretainedBuilder addObject:[JKValue valueWithNonretainedObject:delegate]];
    }
    _forwardingDelegates = [delegatesUnretainedBuilder copy];
}


#pragma mark -
- (void)addForwardingDelegate:(id)delegate{
    if(delegate) self.forwardingDelegates = [self.forwardingDelegates arrayByAddingObject:delegate];
}

- (void)removeForwardingDelegate:(id)delegate{
    NSMutableArray *forwardingDelegates = [NSMutableArray arrayWithArray:self.forwardingDelegates];
    [forwardingDelegates removeObject:delegate];
    self.forwardingDelegates = forwardingDelegates;
}

@end
