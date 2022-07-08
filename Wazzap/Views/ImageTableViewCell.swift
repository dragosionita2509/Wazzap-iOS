//
//  ImageTableViewCell.swift
//  Wazzap
//
//  Created by Awais Jutt on 26/06/2022.
//

import UIKit

class ImageTableViewCell: UITableViewCell {

    @IBOutlet weak var messageBubble: UIView!
    @IBOutlet weak var chatImageView: UIImageView!
    
    @IBOutlet weak var rightImageView: UIImageView!
    @IBOutlet weak var leftImageView: UIImageView!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        messageBubble.layer.cornerRadius = messageBubble.frame.size.height / 5
    }
    
}
