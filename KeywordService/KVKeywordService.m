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

@interface KVKeywordService () {}
- (NSArray *)parseBody:(NSData *)dat error:(NSError **)error;
@end

@implementation KVKeywordService 

double const KVDefaultTimeout       = 5;
unsigned long const KVDefaultMaxResults    = 0;
double const KVDefaultWaitInterval  = 0.3;

NSString * const ClientManagerProtocol = @"https://";
NSString * const ClientManagerHost = @"api-dev.kreuzverweis.com";
NSString * const ClientManagerPort = @"";
NSString * const ClientManagerUser = @"/backoffice/users/";
NSString * const Token = @"/tokens";
NSString * const ClientManagerCreateUser = @"/backoffice/users";
NSString * const ExtractUserIdXPath = @"/user/id";
NSString * const TokenValueXPath = @"/token/value";
NSString * const TokenExpiryXPath = @"/token/expires";

NSString * const KeywordServiceProtocol = @"https://";
NSString * const KeywordServiceHost = @"api-dev.kreuzverweis.com";
NSString * const KeywordServicePort = @"";
NSString * const CompletionPath = @"/keywords/completions/";
NSString * const ProposalPath   = @"/keywords/proposals/";
NSString * const LimitParameter   = @"?limit=";

NSString * const KeywordLabelXPath      = @"/keywords/keyword/label";

NSString * const DefaultsTokenKey = @"accesstoken";
NSString * const DefaultsTokenExpiryKey = @"accesstokenexpiry";

@synthesize defaultLanguage;
@synthesize defaultTimeout;
@synthesize defaultMaxResults;
@synthesize defaultWaitInterval;
@synthesize oAuthClientSecret;
@synthesize oAuthClientToken;
@synthesize oAuthUserId;

/**
 * Factory methods
 **/

- (void) initializeRequest: (KVRequest *)request withDelegate:(NSObject<KVRequestDelegate> *) delegate {
    [request setTimeout: defaultTimeout];
    [request setMaxResults: defaultMaxResults];
    [request setWaitInterval: defaultWaitInterval];
    [request setLanguage: defaultLanguage];
    [request setDelegate:delegate];
}

- (KVCompletionRequest *) CompletionRequestWithPrefix: (NSString *)prefix andDelegate: (NSObject<KVRequestDelegate> *)delegate {
    KVCompletionRequest *request = [[[KVCompletionRequest alloc] init] autorelease];
    [self initializeRequest: request withDelegate: delegate];
    [request setPrefix:prefix];
    return request;
}

- (KVProposalRequest *) ProposalRequestWithKeywords: (NSSet *)keywords andDelegate: (NSObject<KVRequestDelegate> *)delegate {
    KVProposalRequest *request = [[[KVProposalRequest alloc] init] autorelease];
    [self initializeRequest:request withDelegate: delegate];
    [request setKeywords:keywords];
    return request;
}

/**
 * Utilities for creating HTTP requests
 **/

- (NSURLRequest *) clientManagerRequestWithPath: (NSString*) path {
    NSString* host = [ClientManagerProtocol stringByAppendingString:[ClientManagerHost stringByAppendingString:[ClientManagerPort stringByAppendingString:path]]];
    NSString *body = [[[@"client=" stringByAppendingString:oAuthClientToken] stringByAppendingString:@"&secret="] stringByAppendingString:oAuthClientSecret];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: host]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPShouldUsePipelining:YES];
    return request;
}

- (NSURLRequest *) keywordingRequestWithPath: (NSString*) path andToken: (NSString*) token {
    NSString *host = [KeywordServiceProtocol stringByAppendingString:[KeywordServiceHost stringByAppendingString:[KeywordServicePort stringByAppendingString:path]]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: host]];
    [request setHTTPMethod:@"GET"];
    [request setValue: [@"Bearer " stringByAppendingString:token] forHTTPHeaderField: @"Authorization"];
    [request setHTTPShouldUsePipelining:YES];
    return request;
}

/**
 * create users
 **/

// convenience method for use from AppleScript
- (NSString *) createUser {
    NSError* err = nil;
    NSString* user = [self createUserWithError:&err];
    if (err) {
        NSLog(@"Creating a new userId failed. Error Code: %@", err);
        return @"userId";
    } else {
        return user;
    }
}

- (NSString *) createUserWithError: (NSError**) err {
    NSURLRequest *request = [self clientManagerRequestWithPath:ClientManagerCreateUser];
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error: &error];
    if (!error && [response statusCode] < 400 && [data length] > 0) {
        NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyXML error:&error];
        if (!error) {
            NSArray *nodes = [xmlDoc nodesForXPath:ExtractUserIdXPath error:&error];
            if (!error) {
                NSString* result = [[nodes objectAtIndex:0] objectValue];
                [xmlDoc release];
                return result;
            }
        }
        [xmlDoc release];
    } 
    *err = error;
    return nil;  
}

/**
 * authentication 
 **/

- (NSString*) getAccessTokenWithError: (NSError**) err {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString* storedToken = [defaults objectForKey:DefaultsTokenKey];
    if (storedToken) {
        NSDate* expires = [defaults objectForKey:DefaultsTokenExpiryKey];
        if ([[NSDate date] laterDate:expires]) return storedToken;
    }
    NSError* error = nil;
    NSString* token = [self generateAndStoreAccessTokenWithError: &error];
    if (error) {
        *err = error;
        return nil;
    }
    return token;
}

- (NSString*) generateAndStoreAccessTokenWithError: (NSError**) err {
    NSError* error = nil;
    NSDate* expiry = nil;
    NSString* token = [self getTokenWithExpiry:&expiry andError:&error];
    if (error) {
        *err = error;
        return nil;
    }
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:token forKey:DefaultsTokenKey];
    [defaults setValue:expiry forKey:DefaultsTokenExpiryKey];
    return token;
}

- (void) generateTokenAndResendRequest: (KVRequest*) request withKey: (NSNumber*) key {
    NSError *err = nil;
    [self generateAndStoreAccessTokenWithError:&err];
    if (err) {
        [requestForURLConnectionHash removeObjectForKey:key];
        [dataForURLConnectionHash removeObjectForKey:key];
        [[request delegate] requestFailed:request WithError:err];
        [request release];
    } else {
        [self sendRequest: request];
    }
}

- (NSString *) getTokenWithExpiry: (NSDate**) expiry andError: (NSError**) err {
    NSURLRequest *request = [self clientManagerRequestWithPath:[ClientManagerUser stringByAppendingString: [oAuthUserId stringByAppendingString: Token]]];
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error: &error];
    if (error) {
        *err = error;
    } else if ([response statusCode] >= 400) {
        *err = [self nsErrorFromHTTPResponse:response];
    } else {
        if ([data length] == 0) {
            *err = [NSError errorWithDomain:@"com.kreuzverweis" code:-1 userInfo:nil];
        } else {
            NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyXML error:&error];
            if (!error && xmlDoc) {
                NSArray *nodes = [xmlDoc nodesForXPath:TokenValueXPath error:&error];
                if (!error && nodes) {
                    NSString* result = [[nodes objectAtIndex:0] objectValue];
                    nodes = [xmlDoc nodesForXPath:TokenExpiryXPath error:&error]; 
                    if (!error) {
                        NSDate* exp = [NSDate dateWithString:[[nodes objectAtIndex:0] objectValue]];
                        expiry = &exp;
                        [xmlDoc release];
                        return result;
                    }
                }
            }
            [xmlDoc release];
            *err = error;
        }
    } 
    return nil;
}


/**
 * Sending Requests
 **/


- (void) sendRequest: (KVRequest *)request {
    if ([request queryString] && [request delegate]) {
        NSError* err = nil;
        NSString* token = [self getAccessTokenWithError:&err];
        if (err) 
            [request.delegate requestFailed:request WithError:err];
        else {
            NSURLRequest* urlReq = [self keywordingRequestWithPath:[[request queryString]
                                                                    stringByAppendingString:[LimitParameter 
                                                                                             stringByAppendingString:[NSString 
                                                                                                                      stringWithFormat:@"%d", request.maxResults]]] 
                                                          andToken:token];
            NSURLConnection *con = [NSURLConnection connectionWithRequest:urlReq delegate:self];
            [requestForURLConnectionHash setObject:request forKey:[NSNumber numberWithInteger:[con hash]]];
        }
    }
}
/*
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
        if ([challenge.protectionSpace.host isEqualToString: KeywordServiceHost] ||
            [challenge.protectionSpace.host isEqualToString: ClientManagerHost])
            [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}
*/
- (void)connection: (NSURLConnection *)con didReceiveResponse: (NSURLResponse *)response {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if ([httpResponse statusCode] >= 400) {
        NSNumber *key = [NSNumber numberWithInteger:[con hash]];
        KVRequest *request = [requestForURLConnectionHash objectForKey:key];
        if ([httpResponse statusCode] == 401) {
            [self generateTokenAndResendRequest: request withKey: key];
        } else {
            [requestForURLConnectionHash removeObjectForKey:key];
            [dataForURLConnectionHash removeObjectForKey:key];
            [request.delegate requestFailed:request WithError:[self nsErrorFromHTTPResponse:httpResponse]];
        }
    } else {
        [dataForURLConnectionHash setObject:[[[NSMutableData alloc] init] autorelease] forKey:[NSNumber numberWithInteger:[con hash]]];
    }
}

- (void) connection: (NSURLConnection *)con didReceiveData: (NSData *)dat {
    NSMutableData *data = [dataForURLConnectionHash objectForKey:[NSNumber numberWithInteger:[con hash]]];
    if (data != nil) [data appendData:dat];
}
            
- (void) connection: (NSURLConnection *)con didFailWithError:(NSError *)err {
    [con retain];
    [err retain];
    NSNumber *key = [NSNumber numberWithInteger:[con hash]];
    KVRequest *request = [requestForURLConnectionHash objectForKey:key];
    [requestForURLConnectionHash removeObjectForKey:key];
    [[request delegate] requestFailed:request WithError:err];
    [err release];
    [con release];
}
            
- (void) connectionDidFinishLoading: (NSURLConnection *) con {
    [con retain];
    NSNumber *key = [NSNumber numberWithInteger:[con hash]];
    NSMutableData *dat = [dataForURLConnectionHash objectForKey:key];
    if ([dat length] > 0) {
        KVRequest *request = [requestForURLConnectionHash objectForKey:key];
        if (request) {
            [requestForURLConnectionHash removeObjectForKey:key];
            [dataForURLConnectionHash removeObjectForKey:key];
            NSError *err = nil;
            NSArray *result = [self parseBody: dat error: &err];
            if (err) 
                [request.delegate requestFailed:request WithError:err];
            else {    
                if ([result count] > request.maxResults) result = [result subarrayWithRange:NSMakeRange(0, request.maxResults)];
                if ([request isMemberOfClass:[KVCompletionRequest class]]) {
                    [request.delegate receiveCompletions:result forRequest:(KVCompletionRequest*)request];
                } else if ([request isMemberOfClass:[KVProposalRequest class]]) {
                    [request.delegate receiveProposals:result forRequest:(KVProposalRequest*)request];
                } else {
                    [request.delegate requestFailed:request WithError:[NSError errorWithDomain:@"com.kreuzverweis" code:UnknownRequestType userInfo:nil]];
                }
            }
        }
    }
    [key release];
    [con release];
}
                                                    

- (NSArray *)parseBody:(NSData *)dat error:(NSError **)err {
    
    if ([dat length] == 0) return [[[NSArray alloc] init] autorelease];
    
    NSError *error = nil;
    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithData:dat options:NSXMLDocumentTidyXML error:&error];
    if (!error) {
        NSMutableArray *result = [[[NSMutableArray alloc] init] autorelease];
        NSArray *nodes = [xmlDoc nodesForXPath:KeywordLabelXPath error:&error];
        if (!error) {
            for (NSXMLNode *node in nodes) {
               [result addObject:[node objectValue]];
            }
            [xmlDoc release];
            return result;
        }
    }
    *err = error;
    [xmlDoc release];
    return nil;
}

/**
 * Utilities
 **/

- (NSError*) nsErrorFromHTTPResponse: (NSHTTPURLResponse*) httpResponse {
    NSString *description = [NSHTTPURLResponse localizedStringForStatusCode:[httpResponse statusCode]];
    NSError *underlyingError = [[[NSError alloc] initWithDomain:NSURLErrorDomain code:errno userInfo:nil] autorelease];
    NSArray *objArray = [NSArray arrayWithObjects:description, underlyingError, nil];
    NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey, NSUnderlyingErrorKey, nil];
    NSDictionary *eDict = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
    return [NSError errorWithDomain:NSURLErrorDomain code:[httpResponse statusCode] userInfo:eDict];
}


- (id)init
{
    self = [super init];
    if (self) {
        requestForURLConnectionHash = [[NSMutableDictionary alloc] init];
        dataForURLConnectionHash = [[NSMutableDictionary alloc] init];
        bearer = @"";
        
        NSString* prefLanguage = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];        
        [self setDefaultLanguage:prefLanguage];
        [self setDefaultTimeout:KVDefaultTimeout];
        [self setDefaultMaxResults:KVDefaultMaxResults];
        [self setDefaultWaitInterval:KVDefaultWaitInterval];
    }
    return self;
}

- (void)dealloc {
    [requestForURLConnectionHash release];
    [dataForURLConnectionHash release];
    [super dealloc];
}

- (void)finalize
{
    [requestForURLConnectionHash release];
    [dataForURLConnectionHash release];
    [super finalize];
}


@end
