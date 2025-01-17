//
//  MenuBar.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 6/27/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import UIKit

class MenuBar: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    // MARK: - UI Components
    
    lazy var tabsCollectionView: UICollectionView = {
        
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        
        return collectionView
    }()
    
    let horizontalUnderlineBarView: UIView = {
        
        let horizontalBarView = UIView()
        horizontalBarView.backgroundColor = LIGHT_BLUE_COLOR
        horizontalBarView.translatesAutoresizingMaskIntoConstraints = false
        
        return horizontalBarView
    }()
    
    // MARK: - Global Variables
    
    var mainController: MainController?
    
    let cellId = "menuBarCell"
    let cellIconImageNames = ["ic_room_white", "ic_forum_white"]
    
    // MARK: - View Configuration
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Change the background color of the bar.
        backgroundColor = DARK_BLUE_COLOR
        
        // Add the UI components to the view.
        addSubview(tabsCollectionView)
        addSubview(horizontalUnderlineBarView)
        
        // Set up the constraints for the UI components.
        setUpCollectionView()
        setUpHorizontalUnderlineBarView()
        
        // Register the custom MenuCell class for the collection view cells.
        tabsCollectionView.register(MenuCell.self, forCellWithReuseIdentifier: cellId)
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpCollectionView() {
        
        // Add X, Y, width, and height constraints to the tabsCollectionView.
        tabsCollectionView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        tabsCollectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        tabsCollectionView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        tabsCollectionView.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    // This needs to be declared here so we can change them with when the user selects another tab in the menuBar.
    var horizontalUnderlineBarViewLeftAnchor: NSLayoutConstraint?
    
    func setUpHorizontalUnderlineBarView() {
        
        // Add X, Y, width, and height constraints to the horizontalUnderlineBarView.
        horizontalUnderlineBarViewLeftAnchor = horizontalUnderlineBarView.leftAnchor.constraint(equalTo: self.leftAnchor)
        horizontalUnderlineBarViewLeftAnchor?.isActive = true
        horizontalUnderlineBarView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        horizontalUnderlineBarView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1/2).isActive = true
        horizontalUnderlineBarView.heightAnchor.constraint(equalToConstant: 4).isActive = true
    }
    
    // MARK: - Collection View Functions
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: frame.width/2, height: frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        // Spacing between each cell needs to be reduced to zero.
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! MenuCell
        
        // Set the icon image of the cell to the corresponding image name.
        cell.iconImageView.image = UIImage(named: "\(cellIconImageNames[indexPath.row])")
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // Slide the horizontalUnderlineBar and the collectionView in MainController to the tab selected.
        // The horizontalUnderlineBar is manipulated in MainController.
        mainController?.scrollToMenu(index: indexPath.item)
    }
}
