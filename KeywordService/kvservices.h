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

#import "KVKeywordService.h"
#import "RequestDelegate.h"
#import "KVRequest.h"
#import "KVProposalRequest.h"
#import "KVCompletionRequest.h"


/*
 
//// Example code: 

// initialize Keyword Service
KVKeywordService *service = [[KVKeywordService alloc] init];

// identify the user
[service setOAuthAccessSecret:@"8614b9d2627245e1b867e51c108661fc"];
[service setOAuthAccessToken:@"f29c047e8fdd4e86b970824446098231"];

// identify the application
[service setOAuthConsumerSecret:@"8614b9d2627245e1b867e51c108661fc"];
[service setOAuthConsumerToken:@"f29c047e8fdd4e86b970824446098231"];

// generate a request for keyword proposals
ProposalRequest *request = [service ProposalRequestWithKeywords:[NSArray arrayWithObject:@"Brooklyn Bridge"] 
                                                    andDelegate:self];
// send the request
KVKeywordService *[service sendRequest:request];


// results are received asynchronously
- (void) receiveProposals:(NSArray *)proposals forRequest:(ProposalRequest *)request {
    for (NSString *proposal in proposals) {
        NSLog(@"received proposal: %@", proposal);
    }
}

// errors are received asynchronously
- (void)requestFailed:(Request *)request WithError:(NSError *)errorCode
{
    NSLog(@"request failed with error %ld", [errorCode code]);
}

*/