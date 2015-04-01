//
// 



#import "NSString+ValueConvertion.h"


@implementation NSString (ValueConvertion)

- (NSString *)stringByDecodeFromPercentEscapes {
    return (__bridge_transfer NSString *) CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
            (__bridge CFStringRef) self,
            CFSTR(""),
            kCFStringEncodingUTF8);
}

- (NSDictionary *)explodeURLQuery {
    NSArray *arrParameters = [self componentsSeparatedByString:@"&"];
    NSMutableDictionary *dictParameters = [NSMutableDictionary dictionaryWithCapacity:arrParameters.count];

    for (int i = 0; i < [arrParameters count]; i++) {
        NSArray *arrKeyValue = [[arrParameters objectAtIndex:i] componentsSeparatedByString:@"="];
        if ([arrKeyValue count] >= 2) {
            NSMutableString *strKey = [NSMutableString stringWithCapacity:0];
            [strKey setString:[[[arrKeyValue objectAtIndex:0] lowercaseString] stringByDecodeFromPercentEscapes]];
            NSMutableString *strValue = [NSMutableString stringWithCapacity:0];
            [strValue setString:[[[arrKeyValue objectAtIndex:1] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            if (strKey.length > 0) [dictParameters setObject:strValue forKey:strKey];
        }
    }
    return dictParameters;
}

@end