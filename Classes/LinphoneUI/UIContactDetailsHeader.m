/* UIContactDetailsHeader.m
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
 *  GNU Library General Public License for more details.                
 *                                                                      
 *  You should have received a copy of the GNU General Public License   
 *  along with this program; if not, write to the Free Software         
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */ 

#import "UIContactDetailsHeader.h"
#import "Utils.h"
#import "UIEditableTableViewCell.h"
#import "FastAddressBook.h"
#import "UILinphone.h"
#import "PhoneMainView.h"

@implementation UIContactDetailsHeader

@synthesize avatarImage;
@synthesize addressLabel;
@synthesize contact;
@synthesize normalView;
@synthesize editView;
@synthesize tableView;
@synthesize contactDetailsDelegate;

#pragma mark - Lifecycle Functions

- (void)initUIContactDetailsHeader {
    propertyList = [[NSArray alloc] initWithObjects:
                    [NSNumber numberWithInt:kABPersonFirstNameProperty],
                    [NSNumber numberWithInt:kABPersonLastNameProperty], nil];
    editing = FALSE;
}

- (id)init {
    self = [super init];
    if(self != nil) {
        [self initUIContactDetailsHeader];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self != nil) {
        [self initUIContactDetailsHeader];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self != nil) {
        [self initUIContactDetailsHeader];
    }
    return self;
}

- (void)dealloc {
    [avatarImage release];
    [addressLabel release];
    [normalView release];
    [editView release];
    [tableView release];
    
    [propertyList release];
    
    [super dealloc];
}


#pragma mark - ViewController Functions

- (void)viewDidLoad {
    [super viewDidLoad];
    [tableView setBackgroundColor:[UIColor clearColor]]; // Can't do it in Xib: issue with ios4
    [tableView setBackgroundView:nil]; // Can't do it in Xib: issue with ios4
    [normalView setAlpha:1.0f];
    [editView setAlpha:0.0f];
    [tableView setEditing:TRUE animated:false];
}


#pragma mark - Propery Functions

- (void)setContact:(ABRecordRef)acontact {
    contact = acontact;
    [self update];
}


#pragma mark -

- (BOOL)isValid {
    for (int i = 0; i < [propertyList count]; ++i) {
        UIEditableTableViewCell *cell = (UIEditableTableViewCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if([cell.detailTextField.text length] > 0)
            return true;
    }
    return false;
}

- (void)update {
    if(contact == NULL) {
        [LinphoneLogger logc:LinphoneLoggerWarning format:"Cannot update contact details header: null contact"];
        return;
    }
    
    // Avatar image
    {
        UIImage *image = [FastAddressBook getContactImage:contact thumbnail:true];
        if(image == nil) {
            image = [UIImage imageNamed:@"avatar_unknown_small.png"];
        }
        [avatarImage setImage:image];
    }
    
    // Contact label
    {
        [addressLabel setText:[FastAddressBook getContactDisplayName:contact]];
    }
    
    [tableView reloadData];
}

+ (CGFloat)height:(BOOL)editing {
    if(editing) {
        return 130.0f;
    } else {
        return 80.0f;
    }
}

+ (BOOL)findAndResignFirstResponder:(UIView*)view {
    if (view.isFirstResponder) {
        [view resignFirstResponder];
        return YES;     
    }
    for (UIView *subView in view.subviews) {
        if ([UIContactDetailsHeader findAndResignFirstResponder:subView])
            return YES;
    }
    return NO;
}

- (void)setEditing:(BOOL)aediting animated:(BOOL)animated {
    editing = aediting;
    // Resign keyboard
    if(!editing) {
        [UIContactDetailsHeader findAndResignFirstResponder:[self tableView]];
        [self update];
    } 
    if(animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.3];
    }
    if(editing) {
        [editView setAlpha:1.0f];
        [normalView setAlpha:0.0f];
    } else {
        [editView setAlpha:0.0f];
        [normalView setAlpha:1.0f]; 
    }
    if(animated) {
        [UIView commitAnimations];
    }
}

- (void)setEditing:(BOOL)aediting {
    [self setEditing:aediting animated:FALSE];
}

- (BOOL)isEditing {
    return editing;
}

- (void)updateModification {
    [contactDetailsDelegate onModification:nil];
}

+ (NSString*)localizeLabel:(NSString*)str {
    CFStringRef lLocalizedLabel = ABAddressBookCopyLocalizedLabel((CFStringRef) str);
    NSString * retStr = [NSString stringWithString:(NSString*) lLocalizedLabel];
    CFRelease(lLocalizedLabel);
    return retStr;
}

#pragma mark - UITableViewDataSource Functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [propertyList count];
}

- (UITableViewCell *)tableView:(UITableView *)atableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *kCellId = @"ContactDetailsHeaderCell";
    UIEditableTableViewCell *cell = [atableView dequeueReusableCellWithIdentifier:kCellId];
    if (cell == nil) {  
        cell = [[[UIEditableTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:kCellId] autorelease];
        [cell.detailTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        [cell.detailTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
        [cell.detailTextField setKeyboardType:UIKeyboardTypeDefault];
    }
   
    ABPropertyID property = [[propertyList objectAtIndex:[indexPath row]] intValue];
    if(property == kABPersonFirstNameProperty) {
        [cell.detailTextField setPlaceholder:NSLocalizedString(@"First name", nil)];
    } else if (property == kABPersonLastNameProperty) {
        [cell.detailTextField setPlaceholder:NSLocalizedString(@"Last name", nil)];
    }
    [cell.detailTextField setKeyboardType:UIKeyboardTypeDefault];
    if(contact) {
        CFStringRef lValue = ABRecordCopyValue(contact, property);
        if(lValue != NULL) {
            [cell.detailTextLabel setText:(NSString*)lValue];
            [cell.detailTextField setText:(NSString*)lValue];
            CFRelease(lValue);
        } else {
            [cell.detailTextLabel setText:@""];
            [cell.detailTextField setText:@""];
        }
    }
    [cell.detailTextField setDelegate:self];
    
    return cell;
}


#pragma mark - Action Functions

- (IBAction)onAvatarClick:(id)event {
    if(self.isEditing) {
        [ImagePickerViewController promptSelectSource:^(UIImagePickerControllerSourceType type) {
            ImagePickerViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[ImagePickerViewController compositeViewDescription] push:TRUE], ImagePickerViewController);
            if(controller != nil) {
                controller.sourceType = type;
                
                // Displays a control that allows the user to choose picture or
                // movie capture, if both are available:
                controller.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:type];
                
                // Hides the controls for moving & scaling pictures, or for
                // trimming movies. To instead show the controls, use YES.
                controller.allowsEditing = NO;
                controller.imagePickerDelegate = self;
            }
        }];
    }
}


#pragma mark - ContactDetailsImagePickerDelegate Functions

- (void)imagePickerDelegateImage:(UIImage*)image info:(NSDictionary *)info{
    NSError* error = NULL;
    if(!ABPersonRemoveImageData(contact, (CFErrorRef*)error)) {
        [LinphoneLogger log:LinphoneLoggerLog format:@"Can't add entry: %@", [error localizedDescription]];
    }
    NSData *dataRef = UIImagePNGRepresentation(image); 
    CFDataRef cfdata = CFDataCreate(NULL,[dataRef bytes], [dataRef length]);
                                    
    if(!ABPersonSetImageData(contact, cfdata, (CFErrorRef*)error)) {
        [LinphoneLogger log:LinphoneLoggerLog format:@"Can't add entry: %@", [error localizedDescription]];
    }
    
    CFRelease(cfdata);
    
    [self update];
}


#pragma mark - UITableViewDelegate Functions

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}


#pragma mark - UITextFieldDelegate Functions

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if(contactDetailsDelegate != nil) {
        [self performSelector:@selector(updateModification) withObject:nil afterDelay:0];
    }
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    UIView *view = [textField superview]; 
    // Find TableViewCell
    if(view != nil && ![view isKindOfClass:[UIEditableTableViewCell class]]) view = [view superview];
    if(view != nil) {
        UIEditableTableViewCell *cell = (UIEditableTableViewCell*)view;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        ABPropertyID property = [[propertyList objectAtIndex:[indexPath row]] intValue];
        [cell.detailTextLabel setText:[textField text]];
        NSError* error = NULL;
        ABRecordSetValue(contact, property, [textField text], (CFErrorRef*)&error);
        if (error != NULL) {
            [LinphoneLogger log:LinphoneLoggerError format:@"Error when saving property %i in contact %p: Fail(%@)", property, contact, [error localizedDescription]];
        } 
    } else {
        [LinphoneLogger logc:LinphoneLoggerWarning format:"Not valid UIEditableTableViewCell"];
    }
    if(contactDetailsDelegate != nil) {
        [self performSelector:@selector(updateModification) withObject:nil afterDelay:0];
    }
    return TRUE;
}

@end
