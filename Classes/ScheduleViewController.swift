//
//  ScheduleViewController.swift
//  linphone
//
//  Created by Anthony Angrimson on 6/21/19.
//

import UIKit

class ScheduleViewController: UICheckBoxTableView {
    
    var schedules: [ScheduleCreateViewImpl.Schedule] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do{
            schedules = try ScheduleCreateViewImpl.deserializeSchedules()
            for (index, schedule) in schedules.enumerated(){
                self.tableView.register(UIScheduleCell.self, forCellReuseIdentifier: "cell")
            }
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell")
            print(cell)
        }
        catch{ }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schedules.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? UIScheduleCell
        if cell == nil {
            cell = UIScheduleCell.init(style: .default, reuseIdentifier: "cell")
        }
        cell?.t1_Label?.text = "test 1"
        cell?.t2_Label?.text = "test 2"
        cell?.days_Label?.text = "test 3"

        return cell!
    }
}
