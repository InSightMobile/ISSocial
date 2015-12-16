//
// Created by yar on 19.12.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "NSArray+ISSAsyncBlocks.h"
#import <objc/runtime.h>
#import "SObject.h"
#import "SocialConnectorOperation.h"
#import "SocialConnector.h"


@interface SObject ()

@property(nonatomic, readwrite) SObjectState state;

@end

@implementation SObject {

}

@dynamic error, operation;

- (void)dealloc {
    if (self.objectId) {
        [_referencingDictionary removeObjectForKey:self.objectId];
    }
}

- (id)initWithHandler:(id)handler {
    self = [super init];
    if (self) {
        self.handler = handler;
        self.state = SObjectStateSuccess;
    }
    return self;
}

- (id)initWithHandler:(SocialConnector *)handler state:(SObjectState)state {
    self = [super init];
    if (self) {
        self.handler = handler;
        self.state = state;
    }
    return self;
}

+ (id)objectWithHandler:(SocialConnector *)handler state:(SObjectState)state {
    return [[self alloc] initWithHandler:handler state:state];
}

+ (id)objectWithHandler:(SocialConnector *)handler {
    return [[self alloc] initWithHandler:handler];
}

+ (SObject *)successful {
    SObject *obj = [[SObject alloc] init];
    obj.state = SObjectStateSuccess;
    return obj;
}

+ (SObject *)failed {
    SObject *obj = [[SObject alloc] init];
    obj.state = SObjectStateFailed;
    return obj;
}

+ (SObject *)error:(NSError *)error {
    NSLog(@"error = %@", error);

    SObject *obj = [[SObject alloc] init];
    obj.state = SObjectStateFailed;
    obj.error = error;
    return obj;
}

- (BOOL)isFailed {
    return _state == SObjectStateFailed || _state == SObjectStateUnsupported;
}

- (BOOL)isSuccessful {
    return !self.isFailed;
}

- (BOOL)isProcessing {
    return _state == SObjectStateProcessing;
}


+ (SObject *)successful:(SObjectCompletionBlock)completion {
    if (completion) {
        completion([self successful]);
        return nil;
    }
    else {
        return [self successful];
    }
}

+ (SObject *)failed:(SObjectCompletionBlock)completion {
    if (completion) {
        completion([self failed]);
        return nil;
    }
    else {
        return [self failed];
    }
}

+ (SObject *)error:(NSError *)error completion:(SObjectCompletionBlock)completion {
    if (completion) {
        completion([self error:error]);
        return nil;
    }
    else {
        return [self error:error];
    }
}

- (void)addSubObject:(SObject *)subObject {
    if (!subObject) {
        return;
    }

    if (!_subObjects) {
        self.subObjects = [NSMutableArray array];
    }
    [_subObjects addObject:subObject];
}

- (void)complete:(SObjectCompletionBlock)completion {
    if (completion) {
        completion(self);
    }
}

- (id)objectForKeyedSubscript:(id)key {
    if ([key isKindOfClass:[NSString class]]) {
        return [self valueForKey:key];
    }
    return self.data[key];
}

- (void)setObject:(id)object forKeyedSubscript:(id)key {
    if ([key isKindOfClass:[NSString class]]) {
        [self setValue:object forKey:key];
        return;
    }

    if (!self.data) {
        self.data = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    self.data[key] = object;
}

- (id)copyWithZone:(NSZone *)zone {
    SObject *copy = [[SObject alloc] initWithHandler:self.handler];
    copy.data = [[self data] mutableCopyWithZone:zone];
    copy.state = self.state;
    copy.subObjects = [self.subObjects mutableCopyWithZone:zone];
    copy.pagingSelector = self.pagingSelector;
    copy.deletionSelector = self.deletionSelector;
    copy.objectId = self.objectId;
    return copy;
}

- (NSUInteger)count {
    return self.data.count;
}

- (id)objectForKey:(id)key {
    return [self.data objectForKey:key];
}

- (NSArray *)allKeys {
    return [self.data allKeys];
}

- (void)setObjectId:(NSString *)objectId {
    if (_objectId && ![objectId isEqualToString:_objectId]) {
        [_referencingDictionary removeObjectForKey:self.objectId];
    }
    _objectId = objectId;
}

- (void)addSubObjects:(NSArray *)array {
    if (!_subObjects) {
        self.subObjects = [NSMutableArray arrayWithArray:array];
    }
    else {
        [_subObjects addObjectsFromArray:array];
    }
}

id dynamicGetterIMP(SObject *self, SEL _cmd) {

    NSString *name = NSStringFromSelector(_cmd);

    return [self.data objectForKey:NSStringFromSelector(_cmd)];
}

void dynamicSetterIMP(SObject *self, SEL _cmd, id object) {

    NSString *sel = NSStringFromSelector(_cmd);
    sel = [sel substringWithRange:NSMakeRange(3, sel.length - 4)];
    sel =
            [sel stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[sel substringToIndex:1] lowercaseString]];

    if (!self.data) {
        self.data = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    if (object) {
        [self.data setObject:object forKey:sel];
    }
    else {
        [self.data removeObjectForKey:sel];
    }
}

+ (BOOL)resolveInstanceMethod:(SEL)aSEL {
    NSString *name = NSStringFromSelector(aSEL);

    BOOL upper = NO;
    if (name.length > 3) {
        upper = [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[name characterAtIndex:3]];
    }

    if ([name hasSuffix:@":"]) {
        if (upper && [name hasPrefix:@"set"]) {
            class_addMethod([self class], aSEL, (IMP) dynamicSetterIMP, "v@:@");
            return YES;
        }
    }
    else {
        if (!(upper && [name hasPrefix:@"get"])) {
            class_addMethod([self class], aSEL, (IMP) dynamicGetterIMP, "@@:");
            return YES;
        }
    }
    return [super resolveInstanceMethod:aSEL];
}

- (id)valueForKey:(NSString *)key {
    id obj = [_data objectForKey:key];
    if (obj) {
        return obj;
    }

    return [super valueForKey:key];
}

+ (SObject *)objectCollectionWithHandler:(id)handler {

    SObject *object = [[self alloc] initWithHandler:handler];
    object.subObjects = [NSMutableArray arrayWithCapacity:4];
    return object;
}

+ (id)object {
    return [[self alloc] init];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_data forKey:@"data"];
    [coder encodeObject:_subObjects forKey:@"subObjets"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        _data = [coder decodeObjectForKey:@"data"];
        _subObjects = [coder decodeObjectForKey:@"subObjets"];
    }
    return self;
}

+ (id)objectWithState:(SObjectState)state {
    SObject *object = [[SObject alloc] init];
    object.state = state;
    return object;
}



- (NSString *)description {
    if (_data.count) {
        return _data.description;
    }
    else if (_subObjects.count) {
        return _subObjects.description;
    }
    return @"SObject: empty";
}


/*- (NSString *)debugDescription {
    if (_data.count) {
        return _data.debugDescription;
    }
    else if (_subObjects.count) {
        return _subObjects.debugDescription;
    }
    return @"SObject: empty";
}*/

/*
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained[])buffer count:(NSUInteger)len {
    if (_data.count) {
        return [_data countByEnumeratingWithState:state objects:buffer count:len];
    }
    else {
        return [_subObjects countByEnumeratingWithState:state objects:buffer count:len];
    }
}
*/


- (void)cancelOperation {
    SocialConnectorOperation *operation = self.operation;
    [operation cancel];
    self.operation = nil;
}

- (id)copyWithHandler:(id)handler {

    SObject *res = [self copy];
    res.handler = handler;
    res.operation = nil;
    return res;
}

- (SObject *)loadNextPageWithCompletion:(SObjectCompletionBlock)completion {
    if (!self.handler || !self.pagingSelector) {
        completion([SObject failed]);
        return [SObject failed];
    }
    return [self.handler performSelector:self.pagingSelector withObject:self withObject:completion];
}

- (BOOL)isDeletable {
    return self.canDelete.boolValue && self.handler && self.deletionSelector;
}

- (SObject *)deleteObject:(SObjectCompletionBlock)completion {
    if (!self.isDeletable) {
        completion([SObject failed]);
        return [SObject failed];
    }
    return [self.handler performSelector:self.deletionSelector withObject:self withObject:completion];
}


- (void)combinedLoadNextPageWithCompletion:(SObjectCompletionBlock)completion {
    SObject *result = [self copy];
    [result.subObjects removeAllObjects];

    [self.subObjects asyncEach:^(id object, ISArrayAsyncEachResultBlock next) {
        [object loadNextPageWithCompletion:^(SObject *updated) {
            [result addSubObject:updated];
            next(nil);
        }];
    }              comletition:^(NSError *errorOrNil) {
        completion(result);
    }];
}

- (void)fireUpdateNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kSObjectDidUpdated object:self];
}


- (NSMutableArray *)combinedSubobjectsSortedBy:(NSString *)key ascending:(BOOL)ascending {
    NSMutableArray *array = [NSMutableArray array];

    for (SObject *subObject in self.subObjects) {
        [array addObjectsFromArray:subObject.subObjects];
    }

    [array sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:key ascending:ascending]]];

    return array;
}


@end