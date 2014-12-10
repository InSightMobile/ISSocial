//
// 

#import "ISSFeedConsolidation.h"
#import "SocialConnector.h"

// TODO: Optimization needed

@implementation ISSFeedConsolidation
{

    NSMutableArray *_consolidatedContent;
}

- (SObject *)loadDataWithConnector:(SocialConnector *)connector params:(SObject *)params operation:(SEL)operation sortingKey:(NSString *)key ascending:(BOOL)ascending completion:(SObjectCompletionBlock)completion
{
    self.sorkKey = key;
    self.ascending = ascending;

    return [connector performSelector:operation withObject:params withObject:^(SObject *result) {
        self.dataSource = result;
        // consolidate data

        [self consolidateContent:result];

        completion(result);
    }];
}

- (void)consolidateContent:(SObject *)result
{
    NSArray *descriptors = @[[NSSortDescriptor sortDescriptorWithKey:_sorkKey ascending:_ascending]];
    NSComparisonResult ordering = _ascending ? NSOrderedDescending : NSOrderedAscending;

    if (result.subObjects.count == 0) {
        _consolidatedContent = nil;
        return;
    }
    if (result.subObjects.count == 1) {
        _consolidatedContent =
                [[[result.subObjects[0] subObjects] sortedArrayUsingDescriptors:descriptors] mutableCopy];
        return;
    }

    id extremeValue = nil;

    NSMutableArray *sortedData = [NSMutableArray arrayWithCapacity:result.subObjects.count];
    //NSMutableArray *reducedData = [NSMutableArray arrayWithCapacity:result.subObjects.count];

    NSMutableArray *resultData = [NSMutableArray array];

    // sort data and find final value

    for (SObject *object in result.subObjects) {

        if (object.subObjects.count == 0) {
            [sortedData addObject:@[]];
            continue;
        }

        NSArray *sorted = [[object subObjects] sortedArrayUsingDescriptors:descriptors];

        [sortedData addObject:sorted];

        // consider final value only if pagable
        if (object.isPagable.boolValue) {

            id lastValue = [sorted.lastObject valueForKey:_sorkKey];

            if (extremeValue) {
                if ([extremeValue respondsToSelector:@selector(compare:)]) {
                    NSComparisonResult res = [extremeValue compare:lastValue];

                    if (res == ordering) {
                        extremeValue = lastValue;
                    }
                }
            }
            else {
                extremeValue = lastValue;
            }
        }

        NSLog(@"extremeValue = %@", extremeValue);
    }


    if (!extremeValue) {
        // if completly non pagable content
        for (id data in sortedData) {
            [resultData addObjectsFromArray:data];
        }
    }
    else {
        // reduce data up to final value

        for (int j = 0; j < result.subObjects.count; j++) {
            NSArray *data = sortedData[j];

            int index = [data indexOfObject:extremeValue inSortedRange:NSMakeRange(0, data.count)
                                    options:NSBinarySearchingInsertionIndex usingComparator:^(id obj1, id obj2) {
                        return [obj2 compare:[obj1 valueForKey:_sorkKey]];
                    }];

            NSArray *reduced = [data subarrayWithRange:NSMakeRange(0, index)];

            //[reducedData addObject:reduced];

            [resultData addObjectsFromArray:reduced];
        }
    }

    [resultData sortUsingDescriptors:descriptors];
    _consolidatedContent = resultData;
}

- (SObject *)loadDataMoreContentWithCompletion:(SObjectCompletionBlock)completion
{
    [_dataSource combinedLoadNextPageWithCompletion:^(SObject *result) {
        self.dataSource = result;
        [self consolidateContent:result];
        completion(result);
    }];
    return nil;
}

- (NSArray *)consolidatedContent
{

    return _consolidatedContent;
}


@end