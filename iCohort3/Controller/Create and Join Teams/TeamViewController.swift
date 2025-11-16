//
//  TeamViewController.swift
//  iCohort3
//
//  Created by user@0 on 11/11/25.
//

import UIKit
enum TeamStartMode {
    case create
    case join
}

class TeamViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
  


        // MARK: - Outlets
        @IBOutlet weak var titleLabel: UILabel!


        // MARK: - Sections
        enum Section: Int, CaseIterable {
            case summary
            case members
            case requestSwitcher
            case requests
        }

        // MARK: - Models

        struct SentRequest {
            let studentName: String
            let avatar: UIImage?
        }

        struct ReceivedRequest {
            let studentName: String
            let avatar: UIImage?
            let teamNumber: String
            let members: [String]
        }

        enum MemberSlot {
            case filled(UIImage)
            case empty
            case addSlot
        }

        // MARK: - Properties

        var startMode: TeamStartMode = .create

        private var showingSent = true

        private var members: [MemberSlot] = [
            .filled(UIImage(systemName: "person.crop.circle.fill")!),
            .addSlot,
            .empty
        ]

        private var sentRequests: [SentRequest] = [
            .init(studentName: "Ananya", avatar: UIImage(systemName: "person.circle")),
            .init(studentName: "Rahul",  avatar: UIImage(systemName: "person.circle"))
        ]

        private var receivedRequests: [ReceivedRequest] = [
            .init(studentName: "Ishaan",avatar: UIImage(systemName: "person.circle"), teamNumber: "7", members: ["Meera", "Karthik", "Nisha"])
        ]

        // MARK: - Lifecycle

        override func viewDidLoad() {
            super.viewDidLoad()
            setupTitle()
            setupCollection()
        }

        // MARK: - Setup

        private func setupTitle() {
            switch startMode {
            case .create:
                titleLabel.text = "Create Team"
            case .join:
                titleLabel.text = "Join Team"
            }
        }

        private func setupCollection() {
            collectionView.dataSource = self
            collectionView.delegate   = self
            collectionView.collectionViewLayout = makeLayout()

            collectionView.register(UINib(nibName: "TeamSummaryCell", bundle: nil),
                                    forCellWithReuseIdentifier: "TeamSummaryCell")
            collectionView.register(UINib(nibName: "MemberAvatarCell", bundle: nil),
                                    forCellWithReuseIdentifier: "MemberAvatarCell")
            collectionView.register(UINib(nibName: "RequestSwitcherCell", bundle: nil),
                                    forCellWithReuseIdentifier: "RequestSwitcherCell")
            collectionView.register(UINib(nibName: "RequestItemCell", bundle: nil),
                                    forCellWithReuseIdentifier: "RequestItemCell")
        }

        private func makeLayout() -> UICollectionViewCompositionalLayout {
            UICollectionViewCompositionalLayout { sectionIndex, _ in
                guard let section = Section(rawValue: sectionIndex) else { return nil }

                switch section {

                case .summary:
                    let item  = NSCollectionLayoutItem(
                        layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                          heightDimension: .estimated(180))
                    )
                    let group = NSCollectionLayoutGroup.vertical(
                        layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                          heightDimension: .estimated(180)),
                        subitems: [item]
                    )
                    let s = NSCollectionLayoutSection(group: group)
                    s.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
                    return s

                case .members:
                    let item = NSCollectionLayoutItem(
                        layoutSize: .init(widthDimension: .fractionalWidth(1/3),
                                          heightDimension: .absolute(72))
                    )
                    item.contentInsets = .init(top: 0, leading: 8, bottom: 0, trailing: 8)

                    let group = NSCollectionLayoutGroup.horizontal(
                        layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                          heightDimension: .absolute(72)),
                        subitems: [item, item, item]
                    )
                    let s = NSCollectionLayoutSection(group: group)
                    s.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
                    return s

                case .requestSwitcher:
                    let item  = NSCollectionLayoutItem(
                        layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                          heightDimension: .estimated(48))
                    )
                    let group = NSCollectionLayoutGroup.vertical(
                        layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                          heightDimension: .estimated(48)),
                        subitems: [item]
                    )
                    let s = NSCollectionLayoutSection(group: group)
                    s.contentInsets = .init(top: 12, leading: 16, bottom: 4, trailing: 16)
                    return s

                case .requests:
                    let item  = NSCollectionLayoutItem(
                        layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                          heightDimension: .estimated(72))
                    )
                    let group = NSCollectionLayoutGroup.vertical(
                        layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                          heightDimension: .estimated(72)),
                        subitems: [item]
                    )
                    let s = NSCollectionLayoutSection(group: group)
                    s.interGroupSpacing = 8
                    s.contentInsets = .init(top: 8, leading: 16, bottom: 32, trailing: 16)
                    return s
                }
            }
        }
    }

    // MARK: - Collection View

extension TeamViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in _: UICollectionView) -> Int {
        Section.allCases.count
    }
    
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .summary:         return 1
        case .members:         return 3
        case .requestSwitcher: return 1
        case .requests:        return (showingSent ? sentRequests.count : receivedRequests.count)
        }
    }
    
    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch Section(rawValue: indexPath.section)! {
            
        case .summary:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: "TeamSummaryCell",
                                              for: indexPath) as! TeamSummaryCell
            cell.configure(
                teamName: "Team 9",
                icon: UIImage(systemName: "person.3.fill")?.withRenderingMode(.alwaysTemplate)
            )
            cell.teamImageView.tintColor = UIColor(
                red: 0x77/255.0,
                green: 0x9C/255.0,
                blue: 0xB3/255.0,
                alpha: 1.0
            )
            cell.circleView.layer.cornerRadius = cell.circleView.frame.height / 2
            cell.circleView.layer.masksToBounds = true
            cell.circleView.backgroundColor = .white
            return cell
            
        case .members:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: "MemberAvatarCell",
                                              for: indexPath) as! MemberAvatarCell
            let slot = members[indexPath.item]
            cell.configure(slot: slot) { [weak self] in
                print("Add member tapped")
                self?.collectionView.performBatchUpdates(nil)
            }
            return cell
            
        case .requestSwitcher:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: "RequestSwitcherCell",
                                              for: indexPath) as! RequestSwitcherCell
            cell.configure(showingSent: showingSent) { [weak self] showSent in
                guard let self = self else { return }
                self.showingSent = showSent
                cv.performBatchUpdates({
                    cv.reloadSections(IndexSet(integer: Section.requests.rawValue))
                })
            }
            return cell
            
        case .requests:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: "RequestItemCell",
                                              for: indexPath) as! RequestItemCell
            if showingSent {
                let item = sentRequests[indexPath.item]
                cell.configureForSent(name: item.studentName, avatar: item.avatar) {
                    print("Send Request tapped for \(item.studentName)")
                }
            } else {
                let item = receivedRequests[indexPath.item]
                cell.configureForReceived(
                    name: item.studentName,
                    avatar: item.avatar) {
                    print("Accept tapped for \(item.studentName)")
                }
            }
                return cell
            }
        }
    }

