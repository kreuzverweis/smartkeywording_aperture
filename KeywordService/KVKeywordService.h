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

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "KVCompletionRequest.h"
#import "KVProposalRequest.h"
#import "KVRequest.h"
#import "RequestDelegate.h"

/**
 * Interface to the Kreuzverweis webservice
 * OAuth authentication has two parts: 
 * 1) The application authenticates itself. Request a developer key at http://kreuzverweis.com/developer
 * 2) The user authenticates himself. He must supply a token/secret pair generated at http://kreuzverweis.com/selfservice
 * If credentials are wrong, all requests will result in an InvalidCredentialsError
 **/

@interface KVKeywordService : NSObject<NSURLConnectionDelegate> {
@private
    NSString *oAuthClientToken;
    NSString *oAuthClientSecret;
    NSString *oAuthUserId;
    double defaultTimeout;
    unsigned long defaultMaxResults;
    double defaultWaitInterval; 
    NSString *defaultLanguage;
    
    NSMutableDictionary *requestForURLConnectionHash;
    NSMutableDictionary *dataForURLConnectionHash;
    
    NSString *bearer;
}

/** 
 * UserID should be generated
 **/
 @property(readwrite, retain) NSString * oAuthUserId;
- (NSString *) createUser;
- (NSString *) createUserWithError: (NSError**) err;
 

/**
 * Application specific needed for Authentication. 
 * Must be generated on the Kreuzverweis Website and identifies the application
 **/
@property(readwrite, retain) NSString * oAuthClientToken;
@property(readwrite, retain) NSString * oAuthClientSecret;

/**
 * for convenience: Override defaults here and use factory methods to
 * avoid setting values for each request. If you do nothing, the default 
 * language will be set to the user's preferred language.
 **/
@property(readwrite, assign) double defaultTimeout;
@property(readwrite, assign) unsigned long defaultMaxResults;
@property(readwrite, assign) double defaultWaitInterval; 
@property(readwrite, retain) NSString *defaultLanguage;


- (KVCompletionRequest *) CompletionRequestWithPrefix: (NSString *)prefix andDelegate: (NSObject<KVRequestDelegate> *) delegate;
- (KVProposalRequest *) ProposalRequestWithKeywords: (NSArray *)keywords andDelegate: (NSObject<KVRequestDelegate> *) delegate;

/**
 * Request Autocompletion proposals or completions. Result is a ranked list of Strings.
 **/
- (void) sendRequest: (KVRequest *)request;

@end
