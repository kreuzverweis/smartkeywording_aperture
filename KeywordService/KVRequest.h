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

#import <Foundation/Foundation.h>
#import "RequestDelegate.h"

extern double const KVDefaultTimeout;
unsigned long const KVDefaultMaxResults;
extern double const KVDefaultWaitInterval;

extern NSString * const BaseURL;
extern NSString * const CompletionPath;
extern NSString * const ProposalPath;

@interface KVRequest : NSObject {
@private
    double timeout;
    unsigned long maxResults;
    double waitInterval; 
    NSString *language;
    NSObject<KVRequestDelegate> *delegate;
}

/**
 * Time in ms after which this request will time out.
 * If a request times out, the delegates' receiveError selector
 * will be called.
 **/
@property(readwrite, assign) double timeout;

/**
 * Maximum number entries in result list
 **/
@property(readwrite, assign) unsigned long maxResults;

/**
 * Minimum interval before a new completion request is sent. Adjust to typing speed of user if necessary.
 **/
@property(readwrite, assign) double waitInterval; 

/**
 * Language of labels in results
 **/
@property(readwrite, retain) NSString *language;

/**
 * Delegate receiving results and errors for this request
 **/
@property(readwrite, assign) NSObject<KVRequestDelegate> *delegate;

- (NSString *) queryString;

@end
