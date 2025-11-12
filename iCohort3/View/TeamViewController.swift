//
//  TeamViewController.swift
//  iCohort3
//
//  Created by user@0 on 11/11/25.
//

import UIKit

class TeamViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    enum Section: Int, CaseIterable { case pills, summary, members, requestSwitcher, requests }

        // MARK: - Models
        struct SentRequest {
            let studentName: String
            let avatar: UIImage?
        }

        struct ReceivedRequest {
            let studentName: String
            let teamNumber: String
            let members: [String]
        }

        enum MemberSlot {
            case filled(UIImage)
            case empty
            case addSlot
        }

        // MARK: - Demo Data
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
            .init(studentName: "Ishaan", teamNumber: "7", members: ["Meera", "Karthik", "Nisha"])
        ]

        override func viewDidLoad() {
            super.viewDidLoad()
            setupCollection()
        }

        private func setupCollection() {
            collectionView.dataSource = self
            collectionView.delegate   = self
            collectionView.collectionViewLayout = makeLayout()

            // Register nib-based cells (filenames + reuse IDs must match)
            collectionView.register(UINib(nibName: "PillSwitcherCell", bundle: nil),
                                    forCellWithReuseIdentifier: "PillSwitcherCell")
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
                case .pills:
                    let item  = NSCollectionLayoutItem(
                        layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                          heightDimension: .estimated(56))
                    )
                    let group = NSCollectionLayoutGroup.vertical(
                        layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                          heightDimension: .estimated(56)),
                        subitems: [item]
                    )
                    let s = NSCollectionLayoutSection(group: group)
                    s.contentInsets = .init(top: 16, leading: 16, bottom: 8, trailing: 16)
                    return s

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

    extension TeamViewController: UICollectionViewDataSource, UICollectionViewDelegate {

        func numberOfSections(in _: UICollectionView) -> Int { Section.allCases.count }

        func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            switch Section(rawValue: section)! {
            case .pills: return 1
            case .summary: return 1
            case .members: return 3
            case .requestSwitcher: return 1
            case .requests: return (showingSent ? sentRequests.count : receivedRequests.count)
            }
        }

        func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            switch Section(rawValue: indexPath.section)! {

            case .pills:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: "PillSwitcherCell", for: indexPath) as! PillSwitcherCell
                cell.configure(
                    onCreate: { [weak self] in print("Create Team tapped"); self?.collectionView.performBatchUpdates(nil) },
                    onJoin:   { [weak self] in print("Join Team tapped");   self?.collectionView.performBatchUpdates(nil) }
                )
                return cell

            case .summary:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: "TeamSummaryCell", for: indexPath) as! TeamSummaryCell
                cell.configure(
                    teamName: "Team 9",
                    icon: UIImage(systemName: "person.3.fill")?.withRenderingMode(.alwaysTemplate)
                )
                // Apply your visual style directly to the cell
                cell.teamImageView.tintColor = UIColor(red: 0x77/255.0, green: 0x9C/255.0, blue: 0xB3/255.0, alpha: 1.0)
                cell.circleView.layer.cornerRadius = cell.circleView.frame.height / 2
                cell.circleView.layer.masksToBounds = true
                cell.circleView.backgroundColor = .white
                return cell


            case .members:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: "MemberAvatarCell", for: indexPath) as! MemberAvatarCell
                let slot = members[indexPath.item]
                cell.configure(slot: slot) { [weak self] in
                    print("Add member tapped")
                    self?.collectionView.performBatchUpdates(nil)
                }
                return cell

            case .requestSwitcher:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: "RequestSwitcherCell", for: indexPath) as! RequestSwitcherCell
                cell.configure(showingSent: showingSent) { [weak self] showSent in
                    guard let self = self else { return }
                    self.showingSent = showSent
                    cv.performBatchUpdates({
                        cv.reloadSections(IndexSet(integer: Section.requests.rawValue))
                    })
                }
                return cell

            case .requests:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: "RequestItemCell", for: indexPath) as! RequestItemCell
                if showingSent {
                    let item = sentRequests[indexPath.item]
                    cell.configureForSent(name: item.studentName, avatar: item.avatar) {
                        print("Send Request tapped for \(item.studentName)")
                    }
                } else {
                    let item = receivedRequests[indexPath.item]
                    cell.configureForReceived(name: item.studentName, teamNumber: item.teamNumber, members: item.members)
                }
                return cell
            }
        }
    }
