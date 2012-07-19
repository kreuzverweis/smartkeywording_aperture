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

@interface KVProposalRequest : KVRequest {
@private
    NSSet *keywords;
}

/**
 * A set of NSStrings, which represent the keywords used for generating proposals
 **/
@property(readwrite, retain) NSSet *keywords;

@end