//
//  ScheduleListView.swift
//  linphone
//
//  Created by Anthony Angrimson on 5/22/19.
//

import UIKit


protocol ScheduleCreateView: UIViewController, UICompositeViewDelegate  {
}

class ScheduleCreateViewImpl: UIViewController, ScheduleCreateView {
    @IBOutlet var createButton: UIButton!
    @IBOutlet var toolbar: UIView!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var firstTimePicker: UIDatePicker!
    @IBOutlet var secondTimePicker: UIDatePicker!
    @IBOutlet var dayButtons: Array<UIButton>!
    init(){
        super.init(nibName: "ScheduleCreateView", bundle:Bundle.main)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static var compositeDescription: UICompositeViewDescription = UICompositeViewDescription()
    
    static func compositeViewDescription() -> UICompositeViewDescription {
        compositeDescription =  UICompositeViewDescription(self, statusBar: StatusBarView.self, tabBar: TabBarView.self, sideMenu: SideMenuView.self, fullscreen: false, isLeftFragment: false, fragmentWith: nil)
        return compositeDescription;
    }
    
    func compositeViewDescription() -> UICompositeViewDescription! {
        return ScheduleCreateViewImpl.compositeViewDescription();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let index = Calendar.current.component(.weekday, from: Date()) // this returns an Int
        dayButtons[index].isSelected = true
        //Calendar.current.weekdaySymbols[index - 1] // subtract 1 since the index starts at 1
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PhoneMainView.instance().changeCurrentView(ScheduleCreateViewImpl.compositeViewDescription())
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.view = nil
    }
    
    //MARK: buttonClicked Functions
    @IBAction func onBackClicked(_ sender: Any) {
        PhoneMainView.instance()?.changeCurrentView(ScheduleListViewImpl.compositeDescription)
    }
    
    @IBAction func onDayButtonClick(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
    
    @IBAction func onCreateClicked(_ sender: Any) {
        let days = [dayButtons[0].isSelected, dayButtons[1].isSelected, dayButtons[2].isSelected, dayButtons[3].isSelected, dayButtons[4].isSelected, dayButtons[5].isSelected, dayButtons[6].isSelected]
        do{
            let schedule = try Schedule(picker1: firstTimePicker, picker2: secondTimePicker, dayArr: days)
            var schedules: [Schedule]
            do{
                schedules = try ScheduleCreateViewImpl.deserializeSchedules()
            }
            catch { schedules = []}
            for otherSchedule in schedules{
                if(schedule.conflicts(otherSchedule: otherSchedule)){
                    throw NSError()
                }
            }
            schedules.append(schedule)
            try ScheduleCreateViewImpl.serializeSchedules(schedules: schedules)
            PhoneMainView.instance()?.changeCurrentView(ScheduleListViewImpl.compositeDescription)
        }
        catch{
            //TODO Error Message
        }
        //1. Pull days and times from UI elements and attempt to create Schedule Object
        //2. Check Schedule Object against Existing Schedules
        //3. Add Schedule Object to Collection
    }
    
    //MARK: Schedule Class
    class Schedule: NSObject, Codable{
        private enum CodingKeys: String, CodingKey {case interval; case days}
        var interval: ScheduleInterval
        var days: [BooleanLiteralType]
        
        convenience init(picker1: UIDatePicker,picker2: UIDatePicker,dayArr: [BooleanLiteralType]) throws{
            var t1 = Calendar.current.dateComponents([.hour, .minute], from: picker1.date)
            var t2 = Calendar.current.dateComponents([.hour, .minute], from: picker2.date)
            try self.init(h1:t1.hour!, m1:t1.minute!, h2:t2.hour!, m2:t2.minute!, dayArr: dayArr)
        }
        init(h1: Int,m1: Int,h2: Int,m2: Int,dayArr: [BooleanLiteralType]) throws{
            if(h1>h2||(h1==h2&&m1>m2)){
                throw NSError()
            }
            interval = ScheduleInterval(h1: h1,m1: m1,h2: h2,m2: m2)
            days = dayArr
        }
        required init(from decoder:Decoder) throws{
            let container = try decoder.container(keyedBy: CodingKeys.self)
            interval = try container.decode(ScheduleInterval.self, forKey: .interval)
            days = try container.decode([BooleanLiteralType].self, forKey: .days)
        }
        func encode(to encoder:Encoder) throws{
            var container = encoder.container(keyedBy: CodingKeys.self);
            try container.encode(interval, forKey: .interval)
            try container.encode(days, forKey: .days)
        }
        func conflicts(otherSchedule: Schedule)->Bool{
            for (index,day) in days.enumerated(){
                if(day&&otherSchedule.days[index]){
                    if(interval.overlaps(otherInterval: otherSchedule.interval)){
                        return true
                    }
                }
            }
            return false
        }
    }
    
    //MARK: ScheduleInterval Class
    class ScheduleInterval: Codable{
        var start = (0,0)
        var end = (0,0)
        private enum CodingKeys: String, CodingKey {case h1;case m1;case h2;case m2}
        
        init(h1: Int,m1: Int,h2: Int, m2: Int) {
            start = (h1,m1)
            end = (h2,m2)
        }
        required init(from decoder:Decoder) throws{
            let container = try decoder.container(keyedBy: CodingKeys.self)
            start = (try container.decode(Int.self, forKey: .h1),try container.decode(Int.self, forKey: .m1))
            end = (try container.decode(Int.self, forKey: .h2),try container.decode(Int.self, forKey: .m2))
        }
        func encode(to encoder:Encoder) throws{
            var container = encoder.container(keyedBy: CodingKeys.self);
            try container.encode(start.0, forKey: .h1)
            try container.encode(start.1, forKey: .m1)
            try container.encode(end.0, forKey: .h2)
            try container.encode(end.1, forKey: .m2)
        }
        func overlaps(otherInterval: ScheduleInterval)->Bool{
            let startTime = Double(start.0)+Double(start.1)/60.0
            let endTime = Double(end.0)+Double(end.1)/60.0
            let otherStartTime = Double(otherInterval.start.0)+Double(otherInterval.start.1)/60.0
            let otherEndTime = Double(otherInterval.end.0)+Double(otherInterval.end.1)/60.0
            let startBetween = (startTime >= otherStartTime) && (startTime <= otherEndTime)
            let endBetween = (endTime >= otherStartTime) && (endTime <= otherEndTime)
            let otherStartBetween = (otherStartTime >= startTime) && (otherStartTime <= endTime)
            return startBetween||endBetween||otherStartBetween
        }
    }
    
    //MARK: serializeSchedule Functions
    static func serializeSchedules(schedules: Array<Schedule>) throws{
        let file = "schedules.obj"
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(file)
            let encoder = JSONEncoder()
            let data = try encoder.encode(schedules)
            try data.write(to: fileURL)
        }
    }
    static func deserializeSchedules()throws ->Array<Schedule>{
        let file = "schedules.obj"
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(file)
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            let result = try JSONDecoder().decode([Schedule].self, from: data)
            return result
        }
        return []
    }
}
