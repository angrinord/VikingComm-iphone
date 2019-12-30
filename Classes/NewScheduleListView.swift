//
//  ScheduleListView.swift
//  linphone
//
//  Created by Anthony Angrimson on 5/22/19.
//

import UIKit

protocol NewScheduleListView: UIViewController, UICompositeViewDelegate  {
    static var isEditMode: Bool{get set}
}

class NewScheduleListViewImpl: UIViewController, NewScheduleListView{
    init(){
        super.init(nibName: "NewScheduleListView", bundle:Bundle.main)
    }
    @IBOutlet var tableController: UITableViewController!
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    static var isEditMode: Bool = false
    
    static var compositeDescription: UICompositeViewDescription = UICompositeViewDescription()
    
    static func compositeViewDescription() -> UICompositeViewDescription {
        compositeDescription =  UICompositeViewDescription(self, statusBar: StatusBarView.self, tabBar: TabBarView.self, sideMenu: SideMenuView.self, fullscreen: false, isLeftFragment: false, fragmentWith: nil)
        return compositeDescription;
    }
    
    func compositeViewDescription() -> UICompositeViewDescription! {
        return NewScheduleListViewImpl.compositeViewDescription();
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if(tableController.isEditing){
            tableController.isEditing = false
        }
        PhoneMainView.instance().changeCurrentView(NewScheduleListViewImpl.compositeViewDescription())

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.view = nil
    }

}
