// Copyright 2012 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//

#import "RootViewController.h"
#import <ArcGIS/ArcGIS.h>
#import "PortalExplorer.h"
#import "LoginViewController.h"
#import "LoadingView.h"

#define kLoginViewController @"LoginViewController"

//contants for layers

#define ItemId_DefaultMap @"c63e861ae3c945aa9752fcb8d9431e1e"


@interface RootViewController()<AGSMapViewLayerDelegate, AGSWebMapDelegate,AGSMapViewTouchDelegate, UIAlertViewDelegate, AGSPopupsContainerDelegate,AGSCalloutDelegate, PortalExplorerDelegate, LoginViewControllerDelegate, AGSLayerCalloutDelegate>

//map view to open the webmap in
@property (nonatomic, strong) IBOutlet AGSMapView *mapView;

//webmap that needs to be opened. 
@property (nonatomic, strong) AGSWebMap *webMap;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) AGSPopupsContainerViewController *popupVC;

/*Portal Explorer is the object that is used to connect to a portal or organization and access its contents. 
 It has various delegate methods that the root view controller must implement.  
  Make sure to open the PE in a nav controller
  */
@property (nonatomic, strong) PortalExplorer *portalExplorer;

//login view
@property (nonatomic, strong) LoginViewController *loginVC;

//loading view
@property (nonatomic, strong) LoadingView *loadingView;

//popover for ipad
@property (nonatomic, strong) UIPopoverController* popOver;

//opens the default webmap into the mapview
- (void)openDefaultWebMap;

@end

@implementation RootViewController


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// set the delegate for the map view
	self.mapView.layerDelegate = self;
//     AGSLayerCalloutDelegate
//	self.mapView.
	//open default web map so we have something to see when the sample starts up
	[self openDefaultWebMap];
    
    
    self.mapView.callout.delegate = self;
    self.mapView.touchDelegate = self;
    //instantiate the portal explorer and assign the delegate, if not done already
    if(!self.portalExplorer){
        self.portalExplorer = [[PortalExplorer alloc] initWithURL:[NSURL URLWithString: @"http://www.arcgis.com"] credential:nil];
        self.portalExplorer.delegate = self;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    //we're not releasing the portal explorer because a user may have signed in and we don't want to lose that information

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark AGSWebMapDelegate

- (void)webMapDidLoad:(AGSWebMap *)webMap {
    self.webMap.delegate=self;
	//open webmap in mapview
	[self.webMap openIntoMapView:self.mapView];
}

#pragma mark - AGSMapViewTouchDelegate methods

- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features{
    
    
    AGSGeometryEngine *geometryEngine = [AGSGeometryEngine defaultGeometryEngine];
    AGSPolygon *buffer = [geometryEngine bufferGeometry:mappoint byDistance:(10 *mapView.resolution)];
    BOOL willFetch = [self.webMap fetchPopupsForExtent:buffer.envelope];
    if(!willFetch){
        NSLog(@"Sorry, try again");
    }else{
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.mapView.callout.customView = self.activityIndicator;
        [self.activityIndicator startAnimating];
        [self.mapView.callout showCalloutAt:mappoint screenOffset:CGPointZero animated:YES];
    }
    self.popupVC = nil;
    
}

#pragma mark - AGSCallout methods

- (void) didClickAccessoryButtonForCallout:(AGSCallout *) 	callout {
    
    NSLog(@"callout.title=%@  callout.mapLocation=%@",callout.title,callout.mapLocation);
    callout.accessoryButtonHidden=YES;
    callout.titleColor=[UIColor redColor];
    //callout.
    if(!self.popupVC){
        //Create a popupsContainer view controller with the popups
        self.popupVC = [[AGSPopupsContainerViewController alloc] initWithPopups:nil usingNavigationControllerStack:false];
        self.popupVC.style = AGSPopupsContainerStyleBlack;
        self.popupVC.delegate = self;
    }//else{
//        [self.popupVC showAdditionalPopups:popups];
//    }
    [self presentViewController:self.popupVC animated:YES completion:nil];
}

- (BOOL) showCalloutAtPoint:		(AGSPoint *) 	mapPoint
                 forFeature:		(id< AGSFeature >) 	feature
                      layer:		(AGSLayer< AGSHitTestable > *) 	layer
                   animated:		(BOOL) 	animated 
{
    
}

#pragma mark - AGSWebMapDelegate methods
- (void) didOpenWebMap:(AGSWebMap *)webMap intoMapView:(AGSMapView *)mapView {
    if(![webMap hasPopupsDefined]){
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@""
                                                     message:@"This webmap does not have any popups"
                                                    delegate:self
                                           cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [av show];
    }
}

- (void) webMap:(AGSWebMap *)webMap didFailToLoadWithError:(NSError *)error {
    
    // If the web map failed to load report an error
    NSLog(@"Error while loading webMap: %@",[error localizedDescription]);
    
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error"
                                                 message:@"Failed to load the webmap"
                                                delegate:self
                                       cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [av show];
}




-(void)didFailToLoadLayer:(NSString*)layerTitle url:(NSURL*)url baseLayer:(BOOL)baseLayer withError:(NSError*)error{
    
    NSLog(@"Error while loading layer: %@",[error localizedDescription]);
    
    // If we have an error loading the layer report an error
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error"
                                                 message:[NSString stringWithFormat:@"The layer %@ cannot be displayed",layerTitle]
                                                delegate:self
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
    
    [av show];
    
    
    
    // skip loading this layer
    [self.webMap continueOpenAndSkipCurrentLayer];
    
}

- (void)webMap:(AGSWebMap *)webMap
didFetchPopups:(NSArray *)popups
     forExtent:(AGSEnvelope *)extent{
    // If we've found one or more popups
    if (popups.count > 0) {
        
        if(!self.popupVC){
            //Create a popupsContainer view controller with the popups
            self.popupVC = [[AGSPopupsContainerViewController alloc] initWithPopups:popups usingNavigationControllerStack:false];
            self.popupVC.style = AGSPopupsContainerStyleBlack;
            self.popupVC.delegate = self;
        }else{
            [self.popupVC showAdditionalPopups:popups];
        }
        
        // For iPad, display popup view controller in the callout
        if ([[AGSDevice currentDevice] isIPad]) {
            
            self.mapView.callout.customView = self.popupVC.view;
            
            //set the modal presentation options for subsequent popup view transitions
            self.popupVC.modalPresenter =  self.view.window.rootViewController;
            self.popupVC.modalPresentationStyle = UIModalPresentationFormSheet;
            
            
            // Start the activity indicator in the upper right corner of the
            // popupsContainer view controller while we wait for the query results
            self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            UIBarButtonItem *blankButton = [[UIBarButtonItem alloc] initWithCustomView:(UIView*)self.activityIndicator];
            self.popupVC.actionButton = blankButton;
            [self.activityIndicator startAnimating];
        }
        else {
            //For iphone, display summary info in the callout
            self.mapView.callout.title = [NSString stringWithFormat:@"%lu Results", (unsigned long)self.popupVC.popups.count];
            self.mapView.callout.accessoryButtonHidden = NO;
            self.mapView.callout.detail = @"loading more...";
            self.mapView.callout.customView = nil;
        }
        
    }
}

- (void) webMap:(AGSWebMap *)webMap didFinishFetchingPopupsForExtent:(AGSEnvelope *)extent{
    if(self.popupVC){
        if ([[AGSDevice currentDevice] isIPad]){
            [self.activityIndicator stopAnimating];
            self.popupVC.actionButton = self.popupVC.defaultActionButton;
        }
        else {
            self.mapView.callout.detail = @"";
        }
        
    }else{
        [self.activityIndicator stopAnimating];
        self.mapView.callout.customView = nil;
        self.mapView.callout.accessoryButtonHidden = YES;
        self.mapView.callout.title = @"No Results";
        self.mapView.callout.detail = @"";
        
    }
}



#pragma mark - AGSPopupsContainerDelegate methods
- (void)popupsContainerDidFinishViewingPopups:(id<AGSPopupsContainer>)popupsContainer {
    
    //cancel any outstanding requests
    [self.webMap cancelFetchPopups];
    
    // If we are on iPad dismiss the callout
    if ([[AGSDevice currentDevice] isIPad])
        self.mapView.callout.hidden = YES;
    else
        //dismiss the modal viewcontroller for iPhone
        [self dismissViewControllerAnimated:YES completion:nil];
    
}


#pragma mark - AGSPopupsContainerDelegate edit methods

-(void)popupsContainer:(id<AGSPopupsContainer>)popupsContainer
   readyToEditGeometry:(AGSGeometry*)geometry
              forPopup:(AGSPopup*)popup {
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Not Implemented"
                                                 message:@"This sample only demonstrates how to display popups. It does not implement editing or deleting features. Please refer to the Feature Layer Editing Sample instead."
                                                delegate:self
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
    
    [av show];
    
    
}

- (void) popupsContainer:(id<AGSPopupsContainer>)popupsContainer
didFinishEditingForPopup:(AGSPopup *)popup {
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Not Implemented"
                                                 message:@"This sample only demonstrates how to display popups. It does not implement editing or deleting features. Please refer to the Feature Layer Editing Sample instead."
                                                delegate:self
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
    
    [av show];
}

- (void) popupsContainer:(id< AGSPopupsContainer >)popupsContainer
   wantsToDeleteForPopup:(AGSPopup *) popup {
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Not Implemented"
                                                 message:@"This sample only demonstrates how to display popups. It does not allow you to edit or delete features. Please refer to the Feature Layer Editing Sample instead."
                                                delegate:self
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
    
    [av show];
    
}




#pragma mark PortalExplorerDelegate

- (void)portalExplorer:(PortalExplorer *)portalExplorer didLoadPortal:(AGSPortal *)portal
{
    //if the login view is currently shown, it means that the user is logging in and
    // the portal explorer was updated with the user's credential. 
    //We have to remove the  login view. 
    if(self.loginVC)
    {
        [self.loadingView removeView];
        [self.loginVC dismissViewControllerAnimated:YES completion:nil];
        self.loginVC = nil;
    }
    
    //remove the loading view. 
    if(self.loadingView)
        [self.loadingView removeView];
    
}

- (void)portalExplorer:(PortalExplorer *)portalExplorer didFailToLoadPortalWithError:(NSError *)error
{
    
    //remove the loading view. 
    if(self.loadingView)
        [self.loadingView removeView];
    
    //show the error message if the portal fails to load.
    NSString *err = [NSString stringWithFormat:@"%@",error];	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed to connect to portal"
													message:err
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
    
    
}

- (void)portalExplorer:(PortalExplorer *)portalExplorer didRequestSignInForPortal:(AGSPortal *)portal
{
    //This means a user is trying to log in 
    //show the login view  
    
    if(!self.loginVC){
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle mainBundle]];
        self.loginVC = [storyboard instantiateViewControllerWithIdentifier:kLoginViewController];
        self.loginVC.delegate = self;
    }
    
    if([[AGSDevice currentDevice] isIPad]){
        
        self.loginVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        self.loginVC.modalPresentationStyle = UIModalPresentationFormSheet;
        [self.popOver.contentViewController presentViewController:self.loginVC animated:YES completion:nil];
        
    }else{
        [self.portalExplorer presentViewController:self.loginVC animated:YES completion:nil];
    }
    
}

- (void)portalExplorer:(PortalExplorer *)portalExplorer didRequestSignOutFromPortal:(AGSPortal *)portal
{
    //This means a user signed out 
    
    //show the loading view while signing out. 
    self.loadingView = [LoadingView loadingViewInView:self.portalExplorer.view withText:@"Logging Out..."]; 
    
    //update the portal explorer with the nil credential as the user is signing out. 
    [self.portalExplorer updatePortalWithCredential:nil];
}

- (void)portalExplorer:(PortalExplorer *)portalExplorer didSelectPortalItem:(AGSPortalItem *)portalItem
{
    //open the webmap with the portal item as specified
	self.webMap = [AGSWebMap webMapWithPortalItem:portalItem];
	self.webMap.delegate = self;
	self.webMap.zoomToDefaultExtentOnOpen = YES;
    //self.webMap.queries;
    //dismiss the PE
    if([[AGSDevice currentDevice]isIPad]){
        [self.popOver dismissPopoverAnimated:YES];
    }else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }

}

- (void)portalExplorerWantsToHide:(PortalExplorer *)portalExplorer{
    //dismiss the PE
    if([[AGSDevice currentDevice]isIPad]){
        [self.popOver dismissPopoverAnimated:YES];
    }else{
       [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark LoginViewControllerDelegate

- (void)userDidProvideCredential:(AGSCredential *)credential
{
    //show the loading view 
    self.loadingView = [LoadingView loadingViewInView:self.loginVC.view withText:@"Logging In..."]; 
    
    //update the portal explorer with the credential provided by the user. 
    [self.portalExplorer updatePortalWithCredential:credential];
    
}

- (void)userDidCancelLogin
{
    //remove the loading view
    [self.loadingView removeView];
    
    //dismiss the login view. 
    [self.portalExplorer dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Helper

//open default webmap
- (void)openDefaultWebMap {
    
    //open the webmap
	self.webMap = [AGSWebMap webMapWithItemId:ItemId_DefaultMap credential:nil];
    
    //set the webmap delegate to self
	self.webMap.delegate = self;
    
    //zoom to default extent
	self.webMap.zoomToDefaultExtentOnOpen = YES;
}

- (IBAction)showPortalExplorer:(id)sender
{
    if([[AGSDevice currentDevice] isIPad]){ //ipad
        
        if(!self.popOver){ //we dont' have a popover view controller, so let's create one
            
            //We must use a nav controller for the portal explorer so that we have ability to navigate back/forth
            UINavigationController *portalExplorerNavController = 
            [[UINavigationController alloc] initWithRootViewController:self.portalExplorer];    
            portalExplorerNavController.navigationBar.barStyle = UIBarStyleDefault;
            
            
            self.popOver= [[UIPopoverController alloc]
                                    initWithContentViewController:portalExplorerNavController] ;
            [self.popOver setPopoverContentSize:CGSizeMake(320, 480)];
        }
        
        if([self.popOver isPopoverVisible]){
            //let's hide the popover because it is already visible
            [self.popOver dismissPopoverAnimated:YES];
        }else{
            //let's show the popover
        	[self.popOver presentPopoverFromBarButtonItem:sender 
                                 permittedArrowDirections:UIPopoverArrowDirectionUp
                                                 animated:YES ];
            
        }
    }else{ //iphone
        
        //We must use a nav controller for the portal explorer so that we have ability to navigate back/forth
        UINavigationController *portalExplorerNavController = 
        [[UINavigationController alloc] initWithRootViewController:self.portalExplorer];    
        portalExplorerNavController.navigationBar.barStyle = UIBarStyleDefault;
        
        //Present modally for iphone
        [self presentViewController:portalExplorerNavController animated:YES completion:nil];
    }
}

@end
