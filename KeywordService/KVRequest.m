/*
 
 Copyright 2012 Kreuzverweis Solutions GmbH
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

#import "KVRequest.h"


@implementation KVRequest

@synthesize language;
@synthesize maxResults;
@synthesize timeout;
@synthesize waitInterval;
@synthesize delegate;

- (NSString *) queryString {
    return nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        NSString* prefLanguage = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];        
        [self setLanguage:prefLanguage];
        [self setMaxResults:KVDefaultMaxResults];
        [self setTimeout:KVDefaultTimeout];
        [self setWaitInterval:KVDefaultWaitInterval];
    }
    
    return self;
}

@end
