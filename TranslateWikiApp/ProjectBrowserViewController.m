//
//  ProjectBrowserViewController.m
//  TranslateWikiApp
//
//  Created by Or Sagi on 30/3/13.
//  Copyright (c) 2013 translatewiki.net. All rights reserved.
//

#import "ProjectBrowserViewController.h"

@interface ProjectBrowserViewController ()

@end

@implementation ProjectBrowserViewController

@synthesize mySearchBar;
@synthesize LangTable;
@synthesize filteredArr;
@synthesize filteredRec;
@synthesize srcArr;
@synthesize recentProj;
@synthesize isFiltered;
@synthesize didChange;
@synthesize dstProjLabel;
@synthesize dstProjID;
@synthesize originalSrc;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.title = @"Project Browser";
    isFiltered = NO;
    didChange = NO;
    
    srcArr = [[NSMutableArray alloc] initWithArray:originalSrc];
    
    LoadUserDefaults();
    recentProj = [[NSMutableArray alloc] initWithArray:getUserDefaultskey(RECENT_PROJ_key)];
    
    //filter the duplicate
    NSMutableIndexSet *discardedItems = [NSMutableIndexSet indexSet];
    NSUInteger index = 0;
    for(NSDictionary * p1 in srcArr){
        for(NSDictionary * p2 in recentProj){
            if (p1[@"label"] && [p1[@"label"] isEqualToString:p2[@"label"]])
                [discardedItems addIndex:index];
        }
        index++;
    }
    [srcArr removeObjectsAtIndexes:discardedItems];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (didChange && ![[self.navigationController viewControllers] containsObject:self])
    {
        PrefsViewController *ViewController = (PrefsViewController *)[self.navigationController topViewController];
        ViewController.didChange = YES;
        ViewController.projTextField.text = dstProjLabel;
        ViewController.selectedProjCode =  dstProjID;
        NSDictionary *dst = [[NSDictionary alloc] initWithObjectsAndKeys: dstProjLabel ,@"label", dstProjID, @"id" , nil];
        
        //update recent projects data
        NSMutableArray * updatedRecentProj = [[NSMutableArray alloc] init];
        [updatedRecentProj addObject:dst];  //insert selected project to be first in the queue
        for(int i=0; i<recentProj.count && i<MAX_RECENT_PROJ-1; i++)
        {
            if (![dstProjLabel isEqualToString:recentProj[i][@"label"]]) //avoid duplicates
                [updatedRecentProj addObject:recentProj[i]];
        }
        LoadUserDefaults();
        setUserDefaultskey(updatedRecentProj, RECENT_PROJ_key); //store updated recent projects data
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2; //one section for recents, one for all the others
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            if (isFiltered)
                return [filteredRec count];
            else
                return [recentProj count];
            break;
        default:
            if (isFiltered)
                return [filteredArr count];
            else
                return [srcArr count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * identifier;
    UITableViewCell *cell;
    switch (indexPath.section) {
        case 0:
            identifier=@"rec";
            cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
            if (isFiltered)
                cell.textLabel.text = filteredRec[indexPath.row][@"label"];
            else
                cell.textLabel.text = recentProj[indexPath.row][@"label"];
            break;
        default:
            identifier=@"b";
            cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath]; 
            if (isFiltered)
                cell.textLabel.text = filteredArr[indexPath.row][@"label"];
            else
                cell.textLabel.text = srcArr[indexPath.row][@"label"];
    }
    
    return cell;
}

#pragma mark - Table view daelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    didChange = YES;
    switch (indexPath.section) {
        case 0:
            dstProjLabel = (isFiltered?filteredRec[indexPath.row][@"label"]:recentProj[indexPath.row][@"label"]);
            dstProjID = (isFiltered?filteredRec[indexPath.row][@"id"]:recentProj[indexPath.row][@"id"]);
            break;
        default:
            dstProjLabel = (isFiltered?filteredArr[indexPath.row][@"label"]:srcArr[indexPath.row][@"label"]);
            dstProjID = (isFiltered?filteredArr[indexPath.row][@"id"]:srcArr[indexPath.row][@"id"]);
            break;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 30;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
   return (indexPath.section == 0); //we allow "editing mode" only for the recent projects section
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        if(isFiltered)
        {
            NSMutableArray * temp = [[NSMutableArray alloc] initWithArray:recentProj];
            [recentProj removeAllObjects];
            NSString * label = [filteredRec objectAtIndex:indexPath.row][@"label"];
            for(NSDictionary * pr in temp)
            {
                if (![label isEqualToString:pr[@"label"]])
                    [recentProj addObject:pr];
            }
        }
        else
        {
            [recentProj removeObjectAtIndex:indexPath.row];
        }
       srcArr = [[NSMutableArray alloc] initWithArray:originalSrc]; 
        //filter the duplicate
        NSMutableIndexSet *discardedItems = [NSMutableIndexSet indexSet];
        NSUInteger index = 0;
        for(NSDictionary * p1 in srcArr){
            for(NSDictionary * p2 in recentProj){
                if ([p1[@"label"] isEqualToString:p2[@"label"]])
                    [discardedItems addIndex:index];
            }
            index++;
        }
        [srcArr removeObjectsAtIndexes:discardedItems];
        if (mySearchBar.text) [self searchBar:mySearchBar textDidChange:mySearchBar.text];
        [tableView reloadData];
        LoadUserDefaults();
        setUserDefaultskey(recentProj, RECENT_PROJ_key); //store updated
    }
}

#pragma mark - search bar methods

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    
    if(searchText.length==0)
    {
        isFiltered = NO;
    }
    else
    {
        isFiltered = YES;
    }
    filteredRec = [[NSMutableArray alloc] init];
    filteredArr = [[NSMutableArray alloc] init];
    
    //fast enumeration
    for (NSDictionary * projName in recentProj)
    {
        NSRange projRange = [projName[@"label"] rangeOfString:searchText options:NSCaseInsensitiveSearch];
        if (projRange.location != NSNotFound)
        {
            [filteredRec addObject:projName];
        }
    }
    for (NSDictionary * projName in srcArr)
    {
        NSRange projRange = [projName[@"label"] rangeOfString:searchText options:NSCaseInsensitiveSearch];
        if (projRange.location != NSNotFound)
        {
            [filteredArr addObject:projName];
        }
    }
    [LangTable reloadData];
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [mySearchBar resignFirstResponder];
}

@end
