//
//  OPDSGroupTableViewCell.swift
//  r2-testapp-swift
//
//  Created by Geoffrey Bugniot on 24/04/2018.
//  Copyright © 2018 Readium. All rights reserved.
//

import UIKit
import R2Shared
import Kingfisher

class OPDSGroupTableViewCell: UITableViewCell {

    var group: Group?
    weak var opdsRootTableViewController: OPDSRootTableViewController?
    weak var collectionView: UICollectionView?
    
    enum GeneralScreenOrientation: String {
        case landscape
        case portrait
    }
    
    static let iPadLayoutNumberPerRow:[GeneralScreenOrientation: Int] = [.portrait: 4, .landscape: 5]
    static let iPhoneLayoutNumberPerRow:[GeneralScreenOrientation: Int] = [.portrait: 3, .landscape: 4]
    
    lazy var layoutNumberPerRow:[UIUserInterfaceIdiom:[GeneralScreenOrientation: Int]] = [
        .pad : iPadLayoutNumberPerRow,
        .phone : iPhoneLayoutNumberPerRow
    ]
    
    fileprivate var previousScreenOrientation: GeneralScreenOrientation?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        collectionView?.setContentOffset(.zero, animated: false)
        collectionView?.reloadData()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView?.collectionViewLayout.invalidateLayout()
    }

}

extension OPDSGroupTableViewCell: UICollectionViewDataSource {
    
    // MARK: - Collection view data source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return group?.publications.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        self.collectionView = collectionView
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "opdsPublicationCollectionViewCell",
                                                      for: indexPath) as! OPDSGroupCollectionViewCell
        
        if let publication = group?.publications[indexPath.row] {
            
            cell.accessibilityLabel = publication.metadata.title
            
            let titleTextView = OPDSPlaceholderListView(frame: cell.frame,
                                                        title: publication.metadata.title,
                                                        author: publication.metadata.authors.map({$0.name ?? ""}).joined(separator: ", "))
            
            var coverURL: URL?
            if publication.coverLink != nil {
                coverURL = publication.uriTo(link: publication.coverLink)
            } else if publication.images.count > 0 {
                coverURL = URL(string: publication.images[0].absoluteHref!)
            }
            
            if let coverURL = coverURL {
                cell.imageView.kf.setImage(with: coverURL,
                                           placeholder: titleTextView,
                                           options: [.transition(ImageTransition.fade(0.5))],
                                           progressBlock: nil,
                                           completionHandler: nil)
            }
            
            cell.titleLabel.text = publication.metadata.title
            cell.authorLabel.text = publication.metadata.authors.map({$0.name ?? ""}).joined(separator: ", ")
            
        }
        
        return cell
    }
    
}

extension OPDSGroupTableViewCell: UICollectionViewDelegateFlowLayout {
    
    // MARK: - Collection view delegate
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let idiom = { () -> UIUserInterfaceIdiom in
            let tempIdion = UIDevice.current.userInterfaceIdiom
            return (tempIdion != .pad) ? .phone:.pad // ignnore carplay and others
        } ()
        
        let orientation = { () -> GeneralScreenOrientation in
            let deviceOrientation = UIDevice.current.orientation
            
            switch deviceOrientation {
            case .unknown, .portrait, .portraitUpsideDown:
                return GeneralScreenOrientation.portrait
            case .landscapeLeft, .landscapeRight:
                return GeneralScreenOrientation.landscape
            case .faceUp, .faceDown:
                return previousScreenOrientation ?? .portrait
            }
        } ()
        
        previousScreenOrientation = orientation
        
        guard let deviceLayoutNumberPerRow = layoutNumberPerRow[idiom] else {return CGSize(width: 0, height: 0)}
        guard let numberPerRow = deviceLayoutNumberPerRow[orientation] else {return CGSize(width: 0, height: 0)}
        
        let minimumSpacing: CGFloat = 5.0
        let labelHeight: CGFloat = 50.0
        let coverRatio: CGFloat = 1.5
        
        let itemWidth = (collectionView.frame.width / CGFloat(numberPerRow)) - (CGFloat(minimumSpacing) * CGFloat(numberPerRow)) - minimumSpacing
        let itemHeight = (itemWidth * coverRatio) + labelHeight
        
        return CGSize(width: itemWidth, height: itemHeight)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let publication = group?.publications[indexPath.row] {
            let opdsStoryboard = UIStoryboard(name: "OPDS", bundle: nil)
            let opdsPublicationInfoViewController =
                opdsStoryboard.instantiateViewController(withIdentifier: "opdsPublicationInfoViewController") as? OPDSPublicationInfoViewController
            if let opdsPublicationInfoViewController = opdsPublicationInfoViewController {
                opdsPublicationInfoViewController.publication = publication
                opdsRootTableViewController?.navigationController?.pushViewController(opdsPublicationInfoViewController, animated: true)
            }
        }
    }
    
}
