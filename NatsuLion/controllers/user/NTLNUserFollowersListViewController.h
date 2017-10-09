//
//  NTLNUserFollowersListViewController.h
//  Twisapo
//
//  Created by Daniele Salatti on 10/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTLNTwitterUserClient.h"
#import "NTLNMessage.h"

@interface NTLNUserFollowersListViewController : UITableViewController
<UITableViewDelegate, UITableViewDataSource, NTLNTwitterUserClientDelegate> {
	
	NSArray *users;
	NSString *screenName;
}

@property (readwrite, retain) NSString *screenName;

- (void)iconUpdate:(NSNotification*)sender;

@end

