//
//  UIScheduleCell.swift
//  linphone
//
//  Created by Anthony Angrimson on 6/20/19.
//

import UIKit

class UIScheduleCell: UITableViewCell {
    @IBOutlet var t1_Label: UILabel?
    @IBOutlet var t2_Label: UILabel?
    @IBOutlet var days_Label: UILabel?
    @IBOutlet var snooze_Icon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
