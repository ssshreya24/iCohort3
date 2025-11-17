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

    // true ⇒ "Requests Send ↑", false ⇒ "Requests Received ↓"
    private var showingSent: Bool = true

    // Demo data – replace with real data later
    private var sentTeams: [JoinableTeam] = [
        .init(adminName: "Ananya",
              avatar: UIImage(systemName: "person.circle"),
              teamNumber: "3",
              members: ["Rahul", "Meera", "Karthik"]),
        .init(adminName: "Rahul",
              avatar: UIImage(systemName: "person.circle"),
              teamNumber: "5",
              members: ["Ananya", "Nisha"])
    ]

    private var receivedTeams: [JoinableTeam] = [
        .init(adminName: "Meera",
              avatar: UIImage(systemName: "person.circle"),
              teamNumber: "7",
              members: ["Ishaan", "Karthik"])
    ]

    private func currentTeams() -> [JoinableTeam] {
        return showingSent ? sentTeams : receivedTeams
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTitle()
        setupCollectionView()
    }

    // MARK: - Setup

    private func setupTitle() {
        titleLabel.text = "Join Team"
    }

    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate   = self
        collectionView.backgroundColor = .clear

        collectionView.collectionViewLayout = makeLayout()

        // Top toggle cell
        collectionView.register(
            UINib(nibName: "RequestSwitcherCell", bundle: nil),
            forCellWithReuseIdentifier: "RequestSwitcherCell"
        )

        // Team row cell (same as create-team page)
        collectionView.register(
            UINib(nibName: "RequestItemCell", bundle: nil),
            forCellWithReuseIdentifier: "RequestItemCell"
        )
    }

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, _ in
            if sectionIndex == 0 {
                // Section 0: the toggle
                let item = NSCollectionLayoutItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .estimated(44))
                )

                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .estimated(44)),
                    subitems: [item]
                )

                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = .init(top: 16, leading: 16, bottom: 8, trailing: 16)
                return section
            } else {
                // Section 1: team list
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
                section.contentInsets = .init(top: 8, leading: 16, bottom: 32, trailing: 16)
                return section
            }
        }
    }

        // MARK: - Actions

        @IBAction func closeTapped(_ sender: UIButton) {
            dismiss(animated: true)
        }
    }

extension JoinTeamsViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // 0: toggle, 1: team list
        return 2
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1                 // only the RequestSwitcherCell
        } else {
            return currentTeams().count
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if indexPath.section == 0 {
            // Top toggle
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "RequestSwitcherCell",
                for: indexPath
            ) as! RequestSwitcherCell

            cell.configure(showingSent: showingSent) { [weak self] isSent in
                guard let self = self else { return }
                self.showingSent = isSent
                self.collectionView.reloadSections(IndexSet(integer: 1))
            }
            return cell
        } else {
            // Team rows
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "RequestItemCell",
                for: indexPath
            ) as! RequestItemCell

            let team = currentTeams()[indexPath.item]

            cell.configureForJoin(
                adminName: team.adminName,
                avatar: team.avatar,
                teamNumber: team.teamNumber,
                members: team.members
            ) {
                print("Join tapped for Team \(team.teamNumber) by admin \(team.adminName)")
                // TODO: call join-team API, show confirmation, etc.
            }

            return cell
        }
    }
}
