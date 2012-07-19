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

#import "KVProposalRequest.h"

@implementation KVProposalRequest

@synthesize keywords;

- (NSString *) queryString {
    if (keywords && [keywords count] > 0) {
        NSString* keywordsString = ProposalPath;
        NSString* separator = @"";
        for (NSString* keyword in keywords) {
            keywordsString = [[keywordsString stringByAppendingString:separator] stringByAppendingString:[keyword stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            separator = @",";
        } 
        return keywordsString;
    } else {
        return nil;
    }
}

@end
