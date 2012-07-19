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


#import "ApertureInterfaceSQLite.h"


@implementation ApertureInterfaceSQLite

NSString *libraryFile = @"/Database/Library.apdb";
sqlite3 *database;
Boolean initialized = false;

- (void) initDbConnectionWithLibraryPath:(NSString*) libraryPath {
	NSString *dbLocation = [libraryPath stringByAppendingString:libraryFile];
  //  NSLog(@"connectString: %@", libraryPath);
	if (initialized) {
		[self resetDbConnection];
	}
    int result = sqlite3_open_v2([dbLocation UTF8String], &database, SQLITE_OPEN_READONLY, NULL);
	if(result != SQLITE_OK) {
		NSLog(@"Error occurred in ApertureInterface: %i", result);
		NSLog(@"could not open Library: %@", dbLocation);
        initialized = false;
	} else {
	  initialized = true;
    }
}

- (void) resetDbConnection {
	sqlite3_close(database);
	initialized = false;
}	

- (void) applicationShouldTerminate:(NSObject*) sender {
	[self resetDbConnection];
}

- (NSCountedSet *) getExistingTagsForTag:(NSString*)name {
	NSCountedSet* countedSet = [NSCountedSet setWithCapacity:1];
	if (initialized) {
	NSString* sqlStatement = [NSString stringWithFormat:@"SELECT kw2.name, COUNT(kw1.name) AS useCount FROM "
						 "RKKeyword as kw1 "
						 "JOIN RKKeywordForVersion as kwv1 ON kw1.modelId = kwv1.keywordId "
						 "JOIN RKKeywordForVersion as kwv2 ON kwv1.versionId = kwv2.versionId "
						 "JOIN RKKeyword as kw2 ON kwv2.keywordId = kw2.modelId "
							  "WHERE kw1.name = '%s' GROUP BY kw2.name ORDER BY useCount DESC", [name UTF8String]];
		sqlite3_stmt *compiledStatement;
		if(sqlite3_prepare_v2(database, [sqlStatement UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK) {
			while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
				NSString *resultName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 0)];
				[countedSet addObject:resultName];
			}
		}
		sqlite3_finalize(compiledStatement);
	}
	return countedSet;
}


@end
