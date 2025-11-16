//
//  JoinTeamsrViewController.swift
//  iCohort3
//
//  Created by user@0 on 17/11/25.
//

import UIKit
// MARK: - Model

struct JoinableTeam {
    let adminName: String
    let avatar: UIImage?
    let teamNumber: String
    let members: [String]
}


class JoinTeamsViewController: UIViewController {

        @IBOutlet weak var collectionView: UICollectionView!

        // MARK: - Outlets
        @IBOutlet weak var titleLabel: UILabel!

        @IBOutlet weak var closeButton: UIButton!    // hook up the "X" button if you have one

        // MARK: - Data

        // Demo data – replace with API / real data later
        private var joinableTeams: [JoinableTeam] = [
            .init(adminName: "Ananya",avatar: UIImage(systemName: "person.circle"), teamNumber: "3", members: ["Rahul", "Meera", "Karthik"]),
            .init(adminName: "Rahul",avatar: UIImage(systemName: "person.circle"),  teamNumber: "5", members: ["Ananya", "Nisha"]),
            .init(adminName: "Meera",avatar: UIImage(systemName: "person.circle"),  teamNumber: "7", members: ["Ishaan", "Karthik"])
        ]

        // MARK: - Lifecycle

        override func viewDidLoad() {
            super.viewDidLoad()
            setupTitle()
            setupCollectionView()
        }

        // MARK: - Setup

        private func setupTitle() {
            // Sheet title at the top
            titleLabel.text = "Join Team"
        }

        private func setupCollectionView() {
            collectionView.dataSource = self
            collectionView.delegate   = self
            collectionView.backgroundColor = .clear

            collectionView.collectionViewLayout = makeLayout()

            // Reuse the same cell used on Create Team page
            collectionView.register(
                UINib(nibName: "RequestItemCell", bundle: nil),
                forCellWithReuseIdentifier: "RequestItemCell"
            )
        }

        private func makeLayout() -> UICollectionViewCompositionalLayout {
            UICollectionViewCompositionalLayout { _, _ in
                let item = NSCollectionLayoutItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .estimated(72))
                )

                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .estimated(72)),
                    subitems: [item]
                )

                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 8
                section.contentInsets = .init(top: 16, leading: 16, bottom: 32, trailing: 16)
                return section
            }
        }

        // MARK: - Actions

        @IBAction func closeTapped(_ sender: UIButton) {
            dismiss(animated: true)
        }
    }

    // MARK: - Collection View

    extension JoinTeamsViewController: UICollectionViewDataSource, UICollectionViewDelegate {

        func collectionView(_ collectionView: UICollectionView,
                            numberOfItemsInSection section: Int) -> Int {
            return joinableTeams.count
        }

        func collectionView(_ collectionView: UICollectionView,
                            cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "RequestItemCell",
                for: indexPath
            ) as! RequestItemCell

            let team = joinableTeams[indexPath.item]

            cell.configureForJoin(
                adminName: team.adminName,
                avatar: team.avatar,
                teamNumber: team.teamNumber,
                members: team.members
            ) {
                print("Join tapped for Team \(team.teamNumber) by admin \(team.adminName)")
                // TODO: fire your join-team API here, then maybe dismiss or show a toast
            }

            return cell
        }
    }
