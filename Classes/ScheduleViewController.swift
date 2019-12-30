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
            tableView.register(UIScheduleCell.self, forCellReuseIdentifier: "cell")
            tableView.accessibilityIdentifier = "Schedule table"
            tableView.delegate = self
            tableView.dataSource = self
            schedules = try ScheduleCreateViewImpl.deserializeSchedules()
        }
        catch{ }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schedules.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UIScheduleCell
        print("tableView called")
        print(indexPath.count)
        print(cell.debugDescription)
        let test = UILabel.init()
        test.text = "test"
        cell.t1_Label = test
        cell.t2_Label = test
        cell.days_Label = test
        return cell
    }

}
