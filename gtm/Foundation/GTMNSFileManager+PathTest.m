//
//  GTMNSFileManager+PathTest.m
//
//  Copyright 2006-2008 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not
//  use this file except in compliance with the License.  You may obtain a copy
//  of the License at
// 
//  http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
//  License for the specific language governing permissions and limitations under
//  the License.
//

#import "GTMSenTestCase.h"
#import "GTMNSFileManager+Path.h"

@interface GTMNSFileManager_PathTest : GTMTestCase {
  NSString *baseDir_;
}
@end
  
@implementation GTMNSFileManager_PathTest

- (void)setUp {
  // make a directory to scribble in
  baseDir_ =
    [[NSTemporaryDirectory()
      stringByAppendingPathComponent:@"GTMNSFileManager_PathTest"] retain];
  if (baseDir_) {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:baseDir_] &&
        ![fm createDirectoryAtPath:baseDir_ attributes:nil]) {
      // COV_NF_START
      // if the dir exists or we failed to create it, drop the baseDir_
      [baseDir_ release];
      baseDir_ = nil;
      // COV_NF_END
    }
  }
}

- (void)tearDown {
  if (baseDir_) {
    // clean up our directory
    NSFileManager *fm = [NSFileManager defaultManager];
#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_5
    NSError *error = nil;
    [fm removeItemAtPath:baseDir_ error:&error];
    STAssertNil(error,
                @"Unable to delete %@: %@", baseDir_, [error description]);
#else
    [fm removeFileAtPath:baseDir_ handler:nil];
#endif    

    [baseDir_ release];
    baseDir_ = nil;
  }
}

#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5

- (void)testCreateFullPathToDirectoryAttributes {
  STAssertNotNil(baseDir_, @"setUp failed");

  NSString *testPath =
    [baseDir_ stringByAppendingPathComponent:@"/foo/bar/baz"];
  STAssertNotNil(testPath, nil);
  NSFileManager *fm = [NSFileManager defaultManager];
  
  STAssertFalse([fm fileExistsAtPath:testPath],
                @"You must delete '%@' before running this test", testPath);
  
  STAssertFalse([fm gtm_createFullPathToDirectory:nil attributes:nil],
                @"didn't fail on nil input");

  STAssertTrue([fm gtm_createFullPathToDirectory:testPath attributes:nil],
               @"Failed to create nested testPath");
  STAssertTrue([fm gtm_createFullPathToDirectory:testPath attributes:nil],
               @"Failed to succeed on second create of testPath");
  
  NSString *pathToFail = [@"/etc" stringByAppendingPathComponent:testPath];
  STAssertFalse([fm gtm_createFullPathToDirectory:pathToFail attributes:nil],
                @"We were allowed to create a dir in '/etc'?!");
  
  STAssertFalse([fm gtm_createFullPathToDirectory:nil attributes:nil],
                @"Should have failed when passed (nil)");
}

#endif // MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5

- (void)testfilePathsWithExtensionsInDirectory {
  STAssertNotNil(baseDir_, @"setUp failed");
  
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString *bogusPath = @"/some/place/that/does/not/exist";

  // --------------------------------------------------------------------------
  // test fail cases first
  
  // single
  STAssertNil([fm gtm_filePathsWithExtension:nil inDirectory:nil],
              @"shouldn't have gotten anything for nil dir");
  STAssertNil([fm gtm_filePathsWithExtension:@"txt" inDirectory:nil],
              @"shouldn't have gotten anything for nil dir");
  STAssertNil([fm gtm_filePathsWithExtension:@"txt" inDirectory:bogusPath],
              @"shouldn't have gotten anything for a bogus dir");
  // array
  STAssertNil([fm gtm_filePathsWithExtensions:nil inDirectory:nil],
              @"shouldn't have gotten anything for nil dir");
  STAssertNil([fm gtm_filePathsWithExtensions:[NSArray array] inDirectory:nil],
              @"shouldn't have gotten anything for nil dir");
  STAssertNil([fm gtm_filePathsWithExtensions:[NSArray arrayWithObject:@"txt"]
                                  inDirectory:nil],
              @"shouldn't have gotten anything for nil dir");
  STAssertNil([fm gtm_filePathsWithExtensions:[NSArray arrayWithObject:@"txt"]
                                  inDirectory:bogusPath],
              @"shouldn't have gotten anything for a bogus dir");
  
  // --------------------------------------------------------------------------
  // create some test data
  
  NSString *testDirs[] = {
    @"", @"/foo",  // mave a subdir to make sure we don't match w/in it
  };
  NSString *testFiles[] = {
    @"a.txt", @"b.txt", @"c.rtf", @"d.m",
  };
  
  for (size_t i = 0; i < sizeof(testDirs) / sizeof(NSString*); i++) {
    NSString *testDir = nil;
    if ([testDirs[i] length]) {
      testDir = [baseDir_ stringByAppendingPathComponent:testDirs[i]];
      STAssertTrue([fm createDirectoryAtPath:testDir attributes:nil], nil);
    } else {
      testDir = baseDir_;
    }
    for (size_t j = 0; j < sizeof(testFiles) / sizeof(NSString*); j++) {
      NSString *testFile = [testDir stringByAppendingPathComponent:testFiles[j]];
      STAssertTrue([@"test" writeToFile:testFile atomically:YES], nil);
    }
  }
  
  // build set of the top level items
  NSMutableArray *allFiles = [NSMutableArray array];
  for (size_t i = 0; i < sizeof(testDirs) / sizeof(NSString*); i++) {
    if ([testDirs[i] length]) {
      NSString *testDir = [baseDir_ stringByAppendingPathComponent:testDirs[i]];
      [allFiles addObject:testDir];
    }
  }
  for (size_t j = 0; j < sizeof(testFiles) / sizeof(NSString*); j++) {
    NSString *testFile = [baseDir_ stringByAppendingPathComponent:testFiles[j]];
    [allFiles addObject:testFile];
  }

  NSArray *matches = nil;
  NSArray *expectedMatches = nil;
  NSArray *extensions = nil;
  
  // NOTE: we do all compares w/ sets so order doesn't matter

  // --------------------------------------------------------------------------
  // test match all

  // single
  matches = [fm gtm_filePathsWithExtension:nil inDirectory:baseDir_];
  STAssertEqualObjects([NSSet setWithArray:matches],
                       [NSSet setWithArray:allFiles],
                       @"didn't get all files for nil extension");
  matches = [fm gtm_filePathsWithExtension:@"" inDirectory:baseDir_];
  STAssertEqualObjects([NSSet setWithArray:matches],
                       [NSSet setWithArray:allFiles],
                       @"didn't get all files for nil extension");
  // array
  matches = [fm gtm_filePathsWithExtensions:nil inDirectory:baseDir_];
  STAssertEqualObjects([NSSet setWithArray:matches],
                       [NSSet setWithArray:allFiles],
                       @"didn't get all files for nil extension");
  matches = [fm gtm_filePathsWithExtensions:[NSArray array]
                                inDirectory:baseDir_];
  STAssertEqualObjects([NSSet setWithArray:matches],
                       [NSSet setWithArray:allFiles],
                       @"didn't get all files for nil extension");
  
  // --------------------------------------------------------------------------
  // test match something

  // single
  extensions = [NSArray arrayWithObject:@"txt"];
  matches = [fm gtm_filePathsWithExtension:@"txt" inDirectory:baseDir_];
  expectedMatches = [allFiles pathsMatchingExtensions:extensions];
  STAssertEqualObjects([NSSet setWithArray:matches],
                       [NSSet setWithArray:expectedMatches],
                       @"didn't get expected files");
  // array
  matches = [fm gtm_filePathsWithExtensions:extensions inDirectory:baseDir_];
  expectedMatches = [allFiles pathsMatchingExtensions:extensions];
  STAssertEqualObjects([NSSet setWithArray:matches],
                       [NSSet setWithArray:expectedMatches],
                       @"didn't get expected files");
  extensions = [NSArray arrayWithObjects:@"txt", @"rtf", @"xyz", nil];
  matches = [fm gtm_filePathsWithExtensions:extensions inDirectory:baseDir_];
  expectedMatches = [allFiles pathsMatchingExtensions:extensions];
  STAssertEqualObjects([NSSet setWithArray:matches],
                       [NSSet setWithArray:expectedMatches],
                       @"didn't get expected files");
  
  // --------------------------------------------------------------------------
  // test match nothing
  
  // single
  extensions = [NSArray arrayWithObject:@"xyz"];
  matches = [fm gtm_filePathsWithExtension:@"xyz" inDirectory:baseDir_];
  expectedMatches = [allFiles pathsMatchingExtensions:extensions];
  STAssertEqualObjects([NSSet setWithArray:matches],
                       [NSSet setWithArray:expectedMatches],
                       @"didn't get expected files");
  // array
  matches = [fm gtm_filePathsWithExtensions:extensions inDirectory:baseDir_];
  expectedMatches = [allFiles pathsMatchingExtensions:extensions];
  STAssertEqualObjects([NSSet setWithArray:matches],
                       [NSSet setWithArray:expectedMatches],
                       @"didn't get expected files");
  
  // --------------------------------------------------------------------------
  // test match an empty dir
  
  // create the empty dir
  NSString *emptyDir = [baseDir_ stringByAppendingPathComponent:@"emptyDir"];
  STAssertTrue([fm createDirectoryAtPath:emptyDir attributes:nil], nil);
    
  // single
  matches = [fm gtm_filePathsWithExtension:@"txt" inDirectory:emptyDir];
  STAssertEqualObjects([NSSet setWithArray:matches], [NSSet set],
                       @"expected empty dir");
  // array
  matches = [fm gtm_filePathsWithExtensions:[NSArray arrayWithObject:@"txt"]
                                inDirectory:emptyDir];
  STAssertEqualObjects([NSSet setWithArray:matches], [NSSet set],
                       @"expected empty dir");

}

@end
