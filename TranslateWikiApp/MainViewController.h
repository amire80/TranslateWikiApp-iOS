//
//  MainViewController.h
//  TranslateWikiApp
//
//  Created by Or Sagi on 8/1/13.
//  Copyright (c) 2013 translatewiki.net. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TranslationMessageDataController.h"
#import "TranslationMessage.h"
#import "ProofreadViewController.h"
#import "PrefsViewController.h"
#import "TWUser.h"
#import "TWapi.h"
#import "KeychainItemWrapper.h"


@class TranslationMessageDataController;
@class TWUser;

@interface MainViewController : UIViewController<UITableViewDataSource>{
    NSManagedObjectContext *managedObjectContext;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *PushMessages;
@property (nonatomic, retain) TranslationMessageDataController * dataController;
@property (retain, nonatomic) TWapi *api;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

-(void)addMessagesTuple;
@end
