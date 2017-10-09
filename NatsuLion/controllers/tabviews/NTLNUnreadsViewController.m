#import "NTLNUnreadsViewController.h"
#import "NTLNFriendsViewController.h"
#import "NTLNMentionsViewController.h"
#import "NTLNDirectMessageViewController.h"

@implementation NTLNUnreadsViewController

@synthesize friendsViewController, replysViewController, directMessageViewController;

- (void)dealloc {
	[friendsViewController release];
	[replysViewController release];
	[directMessageViewController release];
	[super dealloc];
}

- (void)setupNavigationBar {
	// Daniele Salatti 2009-09-05
	//[[self navigationItem] setRightBarButtonItem:[self clearButtonItem]];
	[[self navigationItem] setRightBarButtonItem:[self reloadButtonItem]];
	[self.navigationItem setTitle:@"Unreads"];
//	[super setupPostButton];
}


- (void)viewWillAppear:(BOOL)animated {
	[timeline release];
	timeline = [[NTLNTimeline alloc] initWithDelegate:self 
								  withArchiveFilename:nil];
	timeline.readTracker = YES;

	[timeline appendStatuses:[friendsViewController.timeline unreadStatuses]];
	[timeline appendStatuses:[replysViewController.timeline unreadStatuses]];
	[timeline appendStatuses:[directMessageViewController.timeline unreadStatuses]];
	
	[super viewWillAppear:animated]; //with reload
}

- (void)viewWillDisappear:(BOOL)animated {
	[timeline release];
	timeline = nil;
}

- (BOOL)doReadTrack {
	// Daniele Salatti {daniele.salatti@salatti.net}
	//return FALSE;
	if (!enable_read) return NO;
	CGFloat viewTop = self.tableView.contentOffset.y;
	CGFloat viewBottom = viewTop + self.tableView.frame.size.height;
	
	BOOL updated = NO;
	NSArray *a = [self.tableView visibleCells];
	for (NTLNStatusCell *cell in a) {
		CGFloat t = cell.frame.origin.y + 3.0;
		CGFloat b = cell.frame.origin.y + cell.frame.size.height - 3.0;
		if (viewTop <= t && b <= viewBottom) {
			int c = [cell.status updateReadTrackCounter:readTrackContinueCounter];
			if (c > 5) {
				if ([cell.status markAsRead]) {
					[cell updateBackgroundColor];
					updated = YES;
				}
			}
		}
	}
	
	if (updated) {
		[self updateBadge];
	}
	
	readTrackContinueCounter++;
	return updated;
}

/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.navigationItem setTitle:@"Unreads"];
	[super tableView:tableView didSelectRowAtIndexPath:indexPath];
}
*/

- (void)clearButton:(id)sender {
	[friendsViewController.timeline markAllAsRead];
	[replysViewController.timeline markAllAsRead];
	[directMessageViewController.timeline markAllAsRead];
	[timeline release];
	timeline = nil;
	[super.tableView reloadData];
}


@end
