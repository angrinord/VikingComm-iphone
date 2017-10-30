/* ChatRoomViewController.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "ChatConversationView.h"
#import "PhoneMainView.h"
#import "Utils.h"
#import "FileTransferDelegate.h"
#import "UIChatBubbleTextCell.h"

@implementation ChatConversationView

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle mainBundle]];
	if (self != nil) {
		scrollOnGrowingEnabled = TRUE;
		_chatRoom = NULL;
		imageQualities = [[OrderedDictionary alloc]
			initWithObjectsAndKeys:[NSNumber numberWithFloat:0.9], NSLocalizedString(@"Maximum", nil),
								   [NSNumber numberWithFloat:0.5], NSLocalizedString(@"Average", nil),
								   [NSNumber numberWithFloat:0.0], NSLocalizedString(@"Minimum", nil), nil];
		composingVisible = TRUE;
	}
	return self;
}

- (void)dealloc {
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:self.class
															  statusBar:StatusBarView.class
																 tabBar:TabBarView.class
															   sideMenu:SideMenuView.class
															 fullscreen:false
														 isLeftFragment:NO
														   fragmentWith:ChatsListView.class];
	}
	return compositeDescription;
}

- (UICompositeViewDescription *)compositeViewDescription {
	return self.class.compositeViewDescription;
}

#pragma mark - ViewController Functions

- (void)viewDidLoad {
	[super viewDidLoad];

	// if we use fragments, remove back button
	if (IPAD) {
		_backButton.hidden = YES;
		_backButton.alpha = 0;
	}

	_messageField.minNumberOfLines = 1;
	_messageField.maxNumberOfLines = IPAD ? 10 : 3;
	_messageField.delegate = self;
	_messageField.font = [UIFont systemFontOfSize:18.0f];
	_messageField.contentInset = UIEdgeInsetsMake(-15, 0, 0, 0);
	//	_messageField.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 10);
	[_tableController setChatRoomDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(applicationWillEnterForeground:)
											   name:UIApplicationDidBecomeActiveNotification
											 object:nil];
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(keyboardWillShow:)
											   name:UIKeyboardWillShowNotification
											 object:nil];
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(keyboardWillHide:)
											   name:UIKeyboardWillHideNotification
											 object:nil];
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(textReceivedEvent:)
											   name:kLinphoneMessageReceived
											 object:nil];
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(onMessageChange:)
											   name:UITextViewTextDidChangeNotification
											 object:nil];
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(textComposeEvent:)
											   name:kLinphoneTextComposeEvent
											 object:nil];
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(callUpdateEvent:)
											   name:kLinphoneCallUpdate
											 object:nil];

	[self updateSuperposedButtons];
	
	if (_tableController.isEditing) {
		[_tableController setEditing:NO];
	}
	[[_tableController tableView] reloadData];

	BOOL fileSharingEnabled = linphone_core_get_file_transfer_server(LC) != NULL;
	[_pictureButton setEnabled:fileSharingEnabled];

	[self callUpdateEvent:nil];
	PhoneMainView.instance.currentRoom = self.chatRoom;
	if (linphone_chat_room_get_subject(_chatRoom))
		_addressLabel.text = [NSString stringWithUTF8String:linphone_chat_room_get_subject(_chatRoom)];

	if (!linphone_chat_room_can_handle_participants(_chatRoom)) {
		_particpantsLabel.hidden = TRUE;
	} else {
		_particpantsLabel.hidden = FALSE;
		bctbx_list_t *participants = linphone_chat_room_get_participants(_chatRoom);
		_particpantsLabel.text = @"";
		while (participants) {
			LinphoneParticipant *participant = (LinphoneParticipant *)participants->data;
			if (![_particpantsLabel.text isEqualToString:@""])
				_particpantsLabel.text = [_particpantsLabel.text stringByAppendingString:@", "];

			_particpantsLabel.text = [_particpantsLabel.text stringByAppendingString:[NSString stringWithUTF8String:linphone_address_get_display_name(linphone_participant_get_address(participant))
																					  ? linphone_address_get_display_name(linphone_participant_get_address(participant))
																				      : linphone_address_get_username(linphone_participant_get_address(participant))]];
			participants = participants->next;
		}
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	[_messageField resignFirstResponder];

	[self setComposingVisible:FALSE withDelay:0]; // will hide the "user is composing.." message

	[NSNotificationCenter.defaultCenter removeObserver:self];
	PhoneMainView.instance.currentRoom = NULL;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	// force offset recomputing
	[_messageField refreshHeight];
	composingVisible = !composingVisible;
	[self setComposingVisible:!composingVisible withDelay:0];
	[self updateSuperposedButtons];
	[_tableController scrollToBottom:true];
}

#pragma mark -

- (void)setChatRoom:(LinphoneChatRoom *)chatRoom {

	_chatRoom = chatRoom;
	[_messageField setText:@""];
	[_tableController setChatRoom:_chatRoom];

	if (_chatRoom != NULL) {
		_chatView.hidden = NO;
		[self update];
		linphone_chat_room_mark_as_read(_chatRoom);
		[self setComposingVisible:linphone_chat_room_is_remote_composing(_chatRoom) withDelay:0];
		TabBarView *tab = (TabBarView *)[PhoneMainView.instance.mainViewController
			getCachedController:NSStringFromClass(TabBarView.class)];
		[tab update:YES];
		[PhoneMainView.instance updateApplicationBadgeNumber];
	} else {
		_chatView.hidden = YES;
	}
}

- (void)applicationWillEnterForeground:(NSNotification *)notif {
	if (_chatRoom != nil) {
		linphone_chat_room_mark_as_read(_chatRoom);
		TabBarView *tab = (TabBarView *)[PhoneMainView.instance.mainViewController
			getCachedController:NSStringFromClass(TabBarView.class)];
		[tab update:YES];
		[PhoneMainView.instance updateApplicationBadgeNumber];
	}
}

- (void)callUpdateEvent:(NSNotification *)notif {
	[_backToCallButton update];
}

- (void)markAsRead {
	linphone_chat_room_mark_as_read(_chatRoom);
	if (IPAD) {
		if (IPAD) {
			ChatsListView *listView = VIEW(ChatsListView);
			[listView.tableController markCellAsRead:_chatRoom];
		}
	}
}

- (void)update {
	if (_chatRoom == NULL) {
		LOGW(@"Cannot update chat room header: null contact");
		return;
	}

	const LinphoneAddress *addr = linphone_chat_room_get_peer_address(_chatRoom);
	if (addr == NULL) {
		[PhoneMainView.instance popCurrentView];
		UIAlertController *errView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Invalid SIP address", nil)
																		 message:NSLocalizedString(@"Either configure a SIP proxy server from settings prior to send a "
																								   @"message or use a valid SIP address (I.E sip:john@example.net)",
																								   nil)
																  preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Continue", nil)
																style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * action) {}];
		
		[errView addAction:defaultAction];
		[self presentViewController:errView animated:YES completion:nil];
		return;
	}
	[ContactDisplay setDisplayNameLabel:_addressLabel forAddress:addr];
	_addressLabel.accessibilityValue = _addressLabel.text;
	_composeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ is composing...", nil), _addressLabel.text];
}

- (BOOL)sendMessage:(NSString *)message withExterlBodyUrl:(NSURL *)externalUrl withInternalURL:(NSURL *)internalUrl {
	if (_chatRoom == NULL) {
		LOGW(@"Cannot send message: No chatroom");
		return FALSE;
	}

	LinphoneChatMessage *msg = linphone_chat_room_create_message(_chatRoom, [message UTF8String]);
	if (externalUrl) {
		linphone_chat_message_set_external_body_url(msg, [[externalUrl absoluteString] UTF8String]);
	}

	if (internalUrl) {
		// internal url is saved in the appdata for display and later save
		[LinphoneManager setValueInMessageAppData:[internalUrl absoluteString] forKey:@"localimage" inMessage:msg];
	}

	// we must ref & unref message because in case of error, it will be destroy otherwise
	linphone_chat_room_send_chat_message(_chatRoom, linphone_chat_message_ref(msg));
	[_tableController addChatEntry:msg];
	linphone_chat_message_unref(msg);

	[_tableController scrollToBottom:true];

	if (linphone_core_lime_enabled(LC) == LinphoneLimeMandatory && !linphone_chat_room_lime_available(_chatRoom)) {
		[LinphoneManager.instance alertLIME:_chatRoom];
	}

	return TRUE;
}

- (void)saveAndSend:(UIImage *)image url:(NSURL *)url withQuality:(float)quality{
	// photo from Camera, must be saved first
	if (url == nil) {
		[LinphoneManager.instance.photoLibrary
			writeImageToSavedPhotosAlbum:image.CGImage
							 orientation:(ALAssetOrientation)[image imageOrientation]
						 completionBlock:^(NSURL *assetURL, NSError *error) {
						   if (error) {
							   LOGE(@"Cannot save image data downloaded [%@]", [error localizedDescription]);
							   
							   UIAlertController *errView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Transfer error", nil)
																								message:NSLocalizedString(@"Cannot write image to photo library",
																														  nil)
																						 preferredStyle:UIAlertControllerStyleAlert];
							   
							   UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK"
																					   style:UIAlertActionStyleDefault
																					 handler:^(UIAlertAction * action) {}];
							   
							   [errView addAction:defaultAction];
							   [self presentViewController:errView animated:YES completion:nil];
						   } else {
							   LOGI(@"Image saved to [%@]", [assetURL absoluteString]);
							   [self startImageUpload:image url:assetURL withQuality:quality];
						   }
						 }];
	} else {
		[self startImageUpload:image url:url withQuality:quality];
	}
}

- (void)chooseImageQuality:(UIImage *)image url:(NSURL *)url {
	DTActionSheet *sheet = [[DTActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose the image size", nil)];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
	  for (NSString *key in [imageQualities allKeys]) {
		  NSNumber *quality = [imageQualities objectForKey:key];
		  NSData *data = UIImageJPEGRepresentation(image, [quality floatValue]);
		  NSNumber *size = [NSNumber numberWithInteger:[data length]];
		  NSString *text = [NSString stringWithFormat:@"%@ (%@)", key, [size toHumanReadableSize]];
		  [sheet addButtonWithTitle:text
							  block:^() {
								[self saveAndSend:image url:url withQuality:[quality floatValue]];
							  }];
	  }
	  [sheet addCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) block:nil];
	  dispatch_async(dispatch_get_main_queue(), ^{
		[sheet showInView:PhoneMainView.instance.view];
	  });
	});
}

- (void)setComposingVisible:(BOOL)visible withDelay:(CGFloat)delay {

	if (composingVisible == visible)
		return;

	CGRect keyboardFrame = [_messageView frame];
	CGRect newComposingFrame = [_composeIndicatorView frame];
	CGRect newTableFrame = [_tableController.tableView frame];

	if (visible) {
		// pull up the composing frame and shrink the table view
		newTableFrame.size.height -= newComposingFrame.size.height;
		newComposingFrame.origin.y = keyboardFrame.origin.y - newComposingFrame.size.height;
	} else {
		// pull down the composing frame and widen the tableview
		newTableFrame.size.height += newComposingFrame.size.height;
		newComposingFrame.origin.y = keyboardFrame.origin.y;
	}
	composingVisible = visible;
	[UIView animateWithDuration:delay
		animations:^{
		  _tableController.tableView.frame = newTableFrame;
		  _composeIndicatorView.frame = newComposingFrame;
		}
		completion:^(BOOL finished) {
		  [_tableController scrollToBottom:TRUE];
		  _composeIndicatorView.hidden = !visible;
		}];
}

- (void)updateSuperposedButtons {
	[_backToCallButton update];
	_infoButton.hidden = !linphone_chat_room_can_handle_participants(_chatRoom) || !_backToCallButton.hidden;
	_callButton.hidden = !_backToCallButton.hidden && !_infoButton.hidden;
}

#pragma mark - Event Functions

- (void)textReceivedEvent:(NSNotification *)notif {
	LinphoneAddress *from = [[[notif userInfo] objectForKey:@"from_address"] pointerValue];
	LinphoneChatRoom *room = [[notif.userInfo objectForKey:@"room"] pointerValue];
	LinphoneChatMessage *chat = [[notif.userInfo objectForKey:@"message"] pointerValue];

	if (from == NULL || chat == NULL) {
		return;
	}

	char *fromStr = linphone_address_as_string_uri_only(from);
	const LinphoneAddress *cr_from = linphone_chat_room_get_peer_address(_chatRoom);
	char *cr_from_string = linphone_address_as_string_uri_only(cr_from);

	if (fromStr && cr_from_string) {
		if (strcasecmp(cr_from_string, fromStr) == 0) {
			if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
				linphone_chat_room_mark_as_read(room);
			}
			[NSNotificationCenter.defaultCenter postNotificationName:kLinphoneMessageReceived object:self];
			[_tableController addChatEntry:chat];
			[self setComposingVisible:FALSE withDelay:0];
			[_tableController scrollToLastUnread:TRUE];
		}
	}
	ms_free(fromStr);
	ms_free(cr_from_string);
}

- (void)textComposeEvent:(NSNotification *)notif {
	LinphoneChatRoom *room = [[[notif userInfo] objectForKey:@"room"] pointerValue];
	if (room && room == _chatRoom) {
		BOOL composing = linphone_chat_room_is_remote_composing(room);
		[self setComposingVisible:composing withDelay:0.3];
	}
}

#pragma mark - UITextFieldDelegate Functions

- (BOOL)growingTextViewShouldBeginEditing:(HPGrowingTextView *)growingTextView {
	if (_tableController.isEditing) {
		[_tableController setEditing:NO];
	}
	[_listTapGestureRecognizer setEnabled:TRUE];
	return TRUE;
}

- (BOOL)growingTextViewShouldEndEditing:(HPGrowingTextView *)growingTextView {
	[_listTapGestureRecognizer setEnabled:FALSE];
	return TRUE;
}

- (void)growingTextChanged:(HPGrowingTextView *)growingTextView text:(NSString *)text {
	if ([text length] > 0 && _chatRoom)
		linphone_chat_room_compose(_chatRoom);
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height {
	int diff = height - growingTextView.bounds.size.height;

	if (diff != 0) {
		CGRect messageRect = [_messageView frame];
		messageRect.origin.y -= diff;
		messageRect.size.height += diff;
		[_messageView setFrame:messageRect];

		// Always stay at bottom
		if (scrollOnGrowingEnabled) {
			CGRect tableFrame = [_tableController.view frame];
			CGPoint contentPt = [_tableController.tableView contentOffset];
			contentPt.y += diff;
			if (contentPt.y + tableFrame.size.height > _tableController.tableView.contentSize.height)
				contentPt.y += diff;
			[_tableController.tableView setContentOffset:contentPt animated:FALSE];
		}

		CGRect tableRect = [_tableController.view frame];
		tableRect.size.height -= diff;
		[_tableController.view setFrame:tableRect];

		// if we're showing the compose message, update it position
		if (![_composeLabel isHidden]) {
			CGRect frame = [_composeLabel frame];
			frame.origin.y -= diff;
			[_composeLabel setFrame:frame];
		}
	}
}

#pragma mark - Action Functions

- (IBAction)onBackClick:(id)event {
	[_tableController setChatRoom:NULL];
	[PhoneMainView.instance popToView:ChatsListView.compositeViewDescription];
}

- (IBAction)onEditClick:(id)event {
	[_tableController setEditing:![_tableController isEditing] animated:TRUE];
	[_messageField resignFirstResponder];
}

- (IBAction)onSendClick:(id)event {
	if ([self sendMessage:[_messageField text] withExterlBodyUrl:nil withInternalURL:nil]) {
		scrollOnGrowingEnabled = FALSE;
		[_messageField setText:@""];
		scrollOnGrowingEnabled = TRUE;
		[self onMessageChange:nil];
	}
}

- (IBAction)onListTap:(id)sender {
	[_messageField resignFirstResponder];
}

- (IBAction)onDeleteClick:(id)sender {
	LOGI(@"onDeleteClick");
	NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"Do you want to delete selected messages?", nil)];
	[UIConfirmationDialog ShowWithMessage:msg
		cancelMessage:nil
		confirmMessage:nil
		onCancelClick:^() {
		  [self onEditionChangeClick:nil];
		}
		onConfirmationClick:^() {
		  [_tableController removeSelectionUsing:nil];
		  [_tableController loadData];
		  [self onEditionChangeClick:nil];
		}];
}

- (IBAction)onEditionChangeClick:(id)sender {
	_backButton.hidden = _tableController.isEditing;
	[self updateSuperposedButtons];
}

- (IBAction)onCallClick:(id)sender {
	[LinphoneManager.instance call:linphone_chat_room_get_peer_address(_chatRoom)];
}

- (IBAction)onListSwipe:(id)sender {
	[self onBackClick:sender];
}

- (IBAction)onMessageChange:(id)sender {
	if ([[_messageField text] length] > 0) {
		[_sendButton setEnabled:TRUE];
	} else {
		[_sendButton setEnabled:FALSE];
	}
}

- (IBAction)onPictureClick:(id)event {
	[_messageField resignFirstResponder];
	[ImagePickerView SelectImageFromDevice:self atPosition:_pictureButton inView:self.view];
}

- (IBAction)onInfoClick:(id)sender {
	NSMutableDictionary *contactsDict = [[NSMutableDictionary alloc] init];
	NSMutableArray *admins = [[NSMutableArray alloc] init];
	bctbx_list_t *participants = linphone_chat_room_get_participants(_chatRoom);
	while (participants) {
		LinphoneParticipant *participant = (LinphoneParticipant *)participants->data;
		NSString *name = [NSString stringWithUTF8String:linphone_address_get_display_name(linphone_participant_get_address(participant))
						  ? linphone_address_get_display_name(linphone_participant_get_address(participant))
					      : linphone_address_get_username(linphone_participant_get_address(participant))];
		NSString *uri = [NSString stringWithUTF8String:linphone_address_as_string_uri_only(linphone_participant_get_address(participant))];
		[contactsDict setObject:name forKey:uri];

		if(linphone_participant_is_admin(participant))
		   [admins addObject:uri];
		participants = participants->next;
	}
	ChatConversationInfoView *view = VIEW(ChatConversationInfoView);
	view.contacts = contactsDict;
	view.create = FALSE;
	view.admins = admins;
	[PhoneMainView.instance changeCurrentView:view.compositeViewDescription];
}

#pragma mark ChatRoomDelegate

- (BOOL)startImageUpload:(UIImage *)image url:(NSURL *)url withQuality:(float)quality {
	FileTransferDelegate *fileTransfer = [[FileTransferDelegate alloc] init];
	[fileTransfer upload:image withURL:url forChatRoom:_chatRoom withQuality:quality];
	[_tableController addChatEntry:linphone_chat_message_ref(fileTransfer.message)];
	[_tableController scrollToBottom:true];
	return TRUE;
}

- (void)resendChat:(NSString *)message withExternalUrl:(NSString *)url {
	[self sendMessage:message withExterlBodyUrl:[NSURL URLWithString:url] withInternalURL:nil];
}

#pragma mark ImagePickerDelegate

- (void)imagePickerDelegateImage:(UIImage *)image info:(NSDictionary *)info {
	// When getting image from the camera, it may be 90° rotated due to orientation
	// (image.imageOrientation = UIImageOrientationRight). Just rotate it to be face up.
	if (image.imageOrientation != UIImageOrientationUp) {
		UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale);
		[image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
		image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
	}

	// Dismiss popover on iPad
	if (IPAD) {
		[VIEW(ImagePickerView).popoverController dismissPopoverAnimated:TRUE];
	}

	NSURL *url = [info valueForKey:UIImagePickerControllerReferenceURL];
	[self chooseImageQuality:image url:url];
}

- (void)tableViewIsScrolling {
	// if user is scrolling in table view, we should hide the keyboard
	if ([_messageField isFirstResponder]) {
		[_messageField resignFirstResponder];
	}
}

#pragma mark - Keyboard Event Functions

- (void)keyboardWillHide:(NSNotification *)notif {
	NSTimeInterval duration = [[[notif userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	[UIView animateWithDuration:duration
		delay:0
		options:UIViewAnimationOptionBeginFromCurrentState
		animations:^{
		  CGFloat composeIndicatorCompensation = composingVisible ? _composeIndicatorView.frame.size.height : 0.0f;

		  //						  Show TabBar and status bar and also top bar

		  // somehow, it breaks rotation if we put that in the block above when rotating portrait -> landscape
		  //						 if (!UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
		  [PhoneMainView.instance hideTabBar:NO];
		  //						 }
		  [PhoneMainView.instance hideStatusBar:NO];
		  [PhoneMainView.instance fullScreen:NO];
		  _topBar.alpha = 1.0;

		  // Resize chat view
		  {
			  CGRect chatFrame = [_chatView frame];
			  chatFrame.origin.y = _topBar.frame.origin.y + _topBar.frame.size.height;
			  chatFrame.size.height = [[self view] frame].size.height - chatFrame.origin.y;
			  [_chatView setFrame:chatFrame];
		  }

		  // Resize & Move table view
		  {
			  CGRect tableFrame = [_tableController.view frame];
			  tableFrame.size.height =
				  [_messageView frame].origin.y - tableFrame.origin.y - composeIndicatorCompensation;
			  [_tableController.view setFrame:tableFrame];

			  // Scroll to bottom
			  NSInteger lastSection = [_tableController.tableView numberOfSections] - 1;
			  if (lastSection >= 0) {
				  NSInteger lastRow = [_tableController.tableView numberOfRowsInSection:lastSection] - 1;
				  if (lastRow >= 0) {
					  [_tableController.tableView
						  scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:lastRow inSection:lastSection]
								atScrollPosition:UITableViewScrollPositionBottom
										animated:FALSE];
				  }
			  }
		  }
		}
		completion:^(BOOL finished){

		}];
}

- (void)keyboardWillShow:(NSNotification *)notif {
	NSTimeInterval duration = [[[notif userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

	[UIView animateWithDuration:duration
		delay:0
		options:UIViewAnimationOptionBeginFromCurrentState
		animations:^{
		  CGFloat composeIndicatorCompensation = composingVisible ? _composeIndicatorView.frame.size.height : 0.0f;

		  CGRect endFrame = [[[notif userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

		  if (([[UIDevice currentDevice].systemVersion floatValue] < 8) &&
			  UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
			  int width = endFrame.size.height;
			  endFrame.size.height = endFrame.size.width;
			  endFrame.size.width = width;
		  }

		  // Hide TabBar and status bar and also top bar
		  [PhoneMainView.instance hideTabBar:YES];
		  [PhoneMainView.instance hideStatusBar:YES];
		  [PhoneMainView.instance fullScreen:YES];
		  _topBar.alpha = 0.0;

		  // Resize chat view
		  {
			  CGRect viewFrame = [[self view] frame];
			  CGRect rect = PhoneMainView.instance.view.bounds;
			  CGPoint pos = {viewFrame.size.width, viewFrame.size.height};
			  CGPoint gPos =
				  [self.view convertPoint:pos
								   toView:[UIApplication sharedApplication]
											  .keyWindow.rootViewController.view]; // Bypass IOS bug on landscape mode
			  float diff = (rect.size.height - gPos.y - endFrame.size.height);
			  if (diff > 0)
				  diff = 0;
			  CGRect chatFrame = [_chatView frame];
			  chatFrame.origin.y = 0;
			  chatFrame.size.height = viewFrame.size.height - chatFrame.origin.y + diff;
			  [_chatView setFrame:chatFrame];
		  }

		  // Resize & Move table view
		  {
			  CGRect tableFrame = _tableController.view.frame;
			  tableFrame.size.height =
				  [_messageView frame].origin.y - tableFrame.origin.y - composeIndicatorCompensation;
			  [_tableController.view setFrame:tableFrame];
		  }

		  // Scroll
		  NSInteger lastSection = [_tableController.tableView numberOfSections] - 1;
		  if (lastSection >= 0) {
			  NSInteger lastRow = [_tableController.tableView numberOfRowsInSection:lastSection] - 1;
			  if (lastRow >= 0) {
				  [_tableController.tableView
					  scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:lastRow inSection:lastSection]
							atScrollPosition:UITableViewScrollPositionBottom
									animated:FALSE];
			  }
		  }
		}
		completion:^(BOOL finished){
		}];
}

@end
