// --------------------------------------------------------------------------
//  Copyright 2013 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

@interface ECDebugViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate> 

@property (nonatomic, retain) UINavigationController* navController;

- (void)pushViewController:(UIViewController *)controller;

@end
