//
//  ScheduleListView.swift
//  linphone
//
//  Created by Anthony Angrimson on 5/22/19.
//

import UIKit


protocol ScheduleListView: UIViewController, UICompositeViewDelegate  {
    static var isEditMode: Bool{get set}
}

class ScheduleListViewImpl: UIViewController, ScheduleListView {
    @IBOutlet var addButton: UIButton!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var toolbar: UIView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var tableController: ScheduleViewController! = ScheduleViewController()
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var selectAll: UIButton!
    @IBOutlet var selectedButtonImage: UIImageView!
    init(){
        super.init(nibName: "ScheduleListView", bundle:Bundle.main)
    }
    
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
        return ScheduleListViewImpl.compositeViewDescription();
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableController.tableView.accessibilityIdentifier = "Schedule table"
        tableView.register(UIScheduleCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = tableController
        tableView.dataSource = tableController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if(tableController.isEditing){
            tableController.isEditing = false
        }
        PhoneMainView.instance().changeCurrentView(ScheduleListViewImpl.compositeViewDescription())

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.view = nil
    }
    
    @IBAction func addSchedule(_ sender: Any) {
        PhoneMainView.instance().changeCurrentView(ScheduleCreateViewImpl.compositeViewDescription())
    }
    @IBAction func deleteSchedule(_ sender: Any) {
        if(self.isEditing){
            self.isEditing = false
            addButton.isHidden = false
            cancelButton.isHidden = true
            selectAll.isHidden = true
            self.tableController.setEditing(false, animated:false)
        }
        else{
            self.isEditing = true
            addButton.isHidden = true
            cancelButton.isHidden = false
            selectAll.isHidden = false
            self.tableController.setEditing(true, animated:false)
        }
    }
    
    @IBAction func exitEditMode(_ sender: Any) {
        self.isEditing = false
        addButton.isHidden = false
        cancelButton.isHidden = true
        selectAll.isHidden = true
        self.tableController.setEditing(false, animated:false)
    }
}
