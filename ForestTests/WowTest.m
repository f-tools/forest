//
//  WowTest.m
//  Forest
//

#import <XCTest/XCTest.h>
#import "LocalTest.h"

@interface WowTest : XCTestCase

@end

@implementation WowTest

- (void)setUp
{

    
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    LocalTest* test = [[LocalTest alloc] init];
    //[test beginTest];
    //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
    
    XCTAssertTrue(YES, @"wefw");
    XCTAssertTrue(@"wapejo", @"oawef");
    XCTAssertEqual(@"af", @"af", @"awefawf");
}

@end
