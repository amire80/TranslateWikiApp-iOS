//
//  MainViewController.m
//  TranslateWikiApp
//
//  Created by Or Sagi on 8/1/13.
//  Copyright (c) 2013 translatewiki.net. All rights reserved.
//


#import "MainViewController.h"
#import "LoginViewController.h"


@interface MainViewController ()
{
    

}
@property (weak, nonatomic) IBOutlet UILabel *GreetingMessage;
@property (weak, nonatomic) IBOutlet UITableView *msgTableView;

@end

@implementation MainViewController
@synthesize selectedIndexPath;
@synthesize managedObjectContext;

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showMessage"]) {
        ProofreadViewController *detailViewController = [segue destinationViewController];
        
        detailViewController.msgIndex = [_msgTableView indexPathForSelectedRow].row;
        detailViewController.dataController  = _dataController;
        detailViewController.api = _api;
        detailViewController.managedObjectContext = self.managedObjectContext;
    }
    if ([[segue identifier] isEqualToString:@"showPrefs"]) {
        PrefsViewController *detailViewController = [segue destinationViewController];
        
        detailViewController.api = _api;
        detailViewController.managedObjectContext = self.managedObjectContext;
    }
    if([[segue identifier] isEqualToString:@"gotoLogin"]) {
        LoginViewController *destViewController = [segue destinationViewController];
        destViewController.managedObjectContext=self.managedObjectContext;
    }
}

- (void)viewWillAppear:(BOOL)animated {

    self.GreetingMessage.text = [NSString stringWithFormat:@"Hello, %@!",_api.user.userName];
    
    [super viewWillAppear:animated];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    if (!self.dataController)
        self.dataController = [[TranslationMessageDataController alloc] init];
    
}

-(id)init
{
    self=[super init];
    if(self){
        selectedIndexPath=[NSIndexPath indexPathForRow:0 inSection:0];
        return self;
    }
    return nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)addMessagesTuple
{
    [self.dataController addMessagesTupleUsingApi: _api andObjectContext:self.managedObjectContext];
    [self.msgTableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (!_api.user.isLoggedin)
    {
        [self performSegueWithIdentifier:@"gotoLogin" sender:self];
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
  //  [_msgTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
  //  [self tableView:_msgTableView didSelectRowAtIndexPath:indexPath];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)LogoutButton:(id)sender {
    [_api TWLogoutRequest];
    KeychainItemWrapper * loginKC = [[KeychainItemWrapper alloc] initWithIdentifier:@"translatewikiapplogin" accessGroup:nil];
    [loginKC resetKeychainItem];
}

- (IBAction)clearMessages:(UIButton *)sender {
    
    [self.dataController removeAllObjects];
    [self.msgTableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataController countOfList]+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"myCell";
    static NSString *moreCellIdentifier = @"moreCell";
    NSString *identifier;
    if(indexPath.row<[self.dataController countOfList])
    {
        identifier=CellIdentifier;
        MsgCell * msgCell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        if (!msgCell)
        {
            msgCell = [[MsgCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        }
        msgCell.srcLabel.text = [[self.dataController objectInListAtIndex:indexPath.row] source];
        msgCell.dstLabel.text = [[self.dataController objectInListAtIndex:indexPath.row] translation];
        if ([[self.dataController objectInListAtIndex:indexPath.row] isAccepted])
            [msgCell setAccessoryType:UITableViewCellAccessoryCheckmark];
        else
            [msgCell setAccessoryType:UITableViewCellAccessoryNone];
        return msgCell;
    }
    else
    {
        identifier=moreCellIdentifier;
        UITableViewCell *moreCell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        if (!moreCell)
        {
            moreCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        }
        return moreCell;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row < [tableView numberOfRowsInSection:indexPath.section]-1)
    {
        MsgCell * msgCell;
        if(selectedIndexPath)
        {
            //do deselect precedures
            msgCell = (MsgCell*)[tableView cellForRowAtIndexPath:selectedIndexPath];
            msgCell.acceptBtn.hidden = TRUE;
            msgCell.rejectBtn.hidden = TRUE;
        }
        if (!selectedIndexPath || selectedIndexPath.row != indexPath.row) {
            selectedIndexPath = [indexPath copy];
            msgCell = (MsgCell*)[tableView cellForRowAtIndexPath:indexPath];
            msgCell.acceptBtn.hidden = FALSE;
            msgCell.rejectBtn.hidden = FALSE;
        }else
            selectedIndexPath = nil;
        
        [tableView deselectRowAtIndexPath:tableView.indexPathForSelectedRow animated:YES];
        [tableView beginUpdates];
        [tableView endUpdates];
        
    }else
    {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        // NSInteger previousCount=[tableData count];
        [self addMessagesTuple];
        
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //check if the index actually exists
    if(selectedIndexPath && indexPath.row == selectedIndexPath.row) {
        return 225;
    }else if (indexPath.row<[self.dataController countOfList])
        return 80;
    return 50;
}



- (IBAction)pushAccept:(id)sender
{
    bool success = [_api TWTranslationReviewRequest:[_dataController objectInListAtIndex:selectedIndexPath.row].revision]; //accept this translation via API
    if (success)
    {
        [[_dataController objectInListAtIndex:selectedIndexPath.row] setIsAccepted:YES];
        [[_dataController objectInListAtIndex:selectedIndexPath.row] setAcceptCount:([[_dataController objectInListAtIndex:selectedIndexPath.row] acceptCount]+1)];
    }
    // here we'll take this cell away
}

- (IBAction)pushReject:(id)sender
{
    [[_dataController objectInListAtIndex:selectedIndexPath] setIsAccepted:NO];
    [self coreDataRejectMessage];
    
    [self.dataController removeObjectAtIndex:selectedIndexPath];
    selectedIndexPath = nil;
    //
}

-(void)coreDataRejectMessage{
    RejectedMessage *mess = (RejectedMessage *)[NSEntityDescription insertNewObjectForEntityForName:@"RejectedMessage" inManagedObjectContext:managedObjectContext];
    
    [mess setKey:[[_dataController objectInListAtIndex:selectedIndexPath.row] key]];
    NSNumber* userid=[NSNumber numberWithInteger:[[_api user] userId]];
    [mess setUserid:userid];
    
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
        // Handle the error.
    }
    
}
@end
