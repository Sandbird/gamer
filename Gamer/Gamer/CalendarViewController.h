//
//  CalendarViewController.h
//  Gamer
//
//  Created by Caio Mello on 1/2/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Kal/Kal.h>

@interface CalendarViewController : UIViewController <KalDataSource, KalViewDelegate, UITableViewDataSource, UITableViewDelegate>

@end
