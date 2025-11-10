//
//  AnnouncementsViewController.swift
//  iCohort3
//
//  Created by user@51 on 08/11/25.
//

import UIKit

class AnnouncementsViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!

    private var announcements: [Announcement] = [] {
           didSet { updateUI() }
       }

       // MARK: - Search UI Elements
       private var filteredAnnouncements: [Announcement] = []
       private var searchContainer: UIView!
       private var searchField: UITextField!
       private var searchVisible = false
       private let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
       private let closeButton = UIButton(type: .system)
       private var searchContainerTopConstraint: NSLayoutConstraint!

       override func viewDidLoad() {
           super.viewDidLoad()
        
           setupViews()
           setupTableView()
           setupSearchUI()

           announcements = []

           DispatchQueue.main.asyncAfter(deadline: .now() + 5) { self.addSample() }
           navigationController?.isNavigationBarHidden = true
       }

       private func setupViews() {
           searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
           searchButton.tintColor = .label
       }

       private func setupTableView() {
           tableView.dataSource = self
           tableView.delegate = self
           let nib = UINib(nibName: "AnnouncementTableViewCell", bundle: nil)
           tableView.register(nib, forCellReuseIdentifier: "AnnouncementCell")
           tableView.rowHeight = UITableView.automaticDimension
           tableView.tableFooterView = UIView()
       }

       // MARK: - Setup Search Container
       private func setupSearchUI() {
           searchContainer = UIView()
           searchField = UITextField()

           // Container
           searchContainer.translatesAutoresizingMaskIntoConstraints = false
           searchContainer.backgroundColor = UIColor.white
           searchContainer.layer.cornerRadius = 20
           searchContainer.clipsToBounds = true
           searchContainer.alpha = 0
           searchContainer.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
           view.addSubview(searchContainer)
           view.bringSubviewToFront(searchButton) 

           // Icon
           searchIcon.tintColor = .systemGray
           searchIcon.translatesAutoresizingMaskIntoConstraints = false
           searchContainer.addSubview(searchIcon)

           // Search field
           searchField.placeholder = "Search"
           searchField.borderStyle = .none
           searchField.translatesAutoresizingMaskIntoConstraints = false
           searchField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
           searchContainer.addSubview(searchField)

           // Close button
           let closeImage = UIImage(systemName: "xmark.circle.fill")
           closeButton.setImage(closeImage, for: .normal)
           closeButton.tintColor = .systemGray
           closeButton.translatesAutoresizingMaskIntoConstraints = false
           closeButton.addTarget(self, action: #selector(hideSearchField), for: .touchUpInside)
           searchContainer.addSubview(closeButton)

           // Constraints - Align with search button's Y position
           searchContainerTopConstraint = searchContainer.centerYAnchor.constraint(equalTo: searchButton.centerYAnchor)

           NSLayoutConstraint.activate([
               searchContainerTopConstraint,
               searchContainer.trailingAnchor.constraint(equalTo: searchButton.trailingAnchor),
               searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
               searchContainer.heightAnchor.constraint(equalToConstant: 45),

               searchIcon.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 12),
               searchIcon.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
               searchIcon.widthAnchor.constraint(equalToConstant: 20),
               searchIcon.heightAnchor.constraint(equalToConstant: 20),

               closeButton.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -12),
               closeButton.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
               closeButton.widthAnchor.constraint(equalToConstant: 24),
               closeButton.heightAnchor.constraint(equalToConstant: 24),

               searchField.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 8),
               searchField.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
               searchField.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor)
           ])
           
           view.layoutIfNeeded()
       }


    // MARK: - Actions
    @IBAction func searchButtonTapped(_ sender: UIButton) {
        if searchVisible {
                    hideSearchField()
                } else {
                    showSearchField()
                }
            }
    
    private func showSearchField() {
                searchVisible = true
                
                // Magical expansion animation from the search button
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                    self.searchContainer.alpha = 1
                    self.searchContainer.transform = .identity
                    self.searchButton.alpha = 0
                }, completion: { _ in
                    self.searchButton.isHidden = true
                    self.searchField.becomeFirstResponder()
                })
            }

            @objc private func hideSearchField() {
                searchVisible = false
                searchField.resignFirstResponder()
                
                // Show search button before starting animation
                searchButton.isHidden = false
                
                // Magical collapse animation back to the search button
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
                    self.searchContainer.alpha = 0
                    self.searchContainer.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                    self.searchButton.alpha = 1
                }, completion: { _ in
                    self.searchField.text = ""
                    self.filteredAnnouncements.removeAll()
                    self.tableView.reloadData()
                })
            }

            @objc private func searchTextChanged(_ textField: UITextField) {
                guard let text = textField.text?.lowercased(), !text.isEmpty else {
                    filteredAnnouncements = []
                    tableView.reloadData()
                    return
                }

                filteredAnnouncements = announcements.filter {
                    $0.title.lowercased().contains(text) ||
                    $0.body.lowercased().contains(text) ||
                    ($0.tag?.lowercased().contains(text) ?? false) ||
                    $0.author.lowercased().contains(text)
                }
                tableView.reloadData()
            }

            private func updateUI() {
                let empty = announcements.isEmpty
                placeholderLabel.isHidden = !empty
                tableView.isHidden = empty
                searchButton.isHidden = false
                if !empty { tableView.reloadData() }
            }

            // Sample data for testing
    func addSample() {
        let a = Announcement(
            id: UUID(),
            title: "DEI Workshop",
            body: "The Workshop will be conducted in Bel 5 floor for the next two days",
            tag: "Event",
            createdAt: Date(),
            author: "Arshad Sheikh"
        )
        
        let b = Announcement(
            id: UUID(),
            title: "Hackathon 2025",
            body: "Join the upcoming Hackathon 2025! Register your team before November 15th to participate.",
            tag: "Competition",
            createdAt: Date(),
            author: "Lakshy Pandey"
        )
        
        announcements.insert(a, at: 0)
        announcements.insert(b, at: 0)
    }

        }

        // MARK: - Table data source
        extension AnnouncementsViewController: UITableViewDataSource, UITableViewDelegate {
            
            func numberOfSections(in tableView: UITableView) -> Int {
                return 1
            }

            func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return filteredAnnouncements.isEmpty ? announcements.count : filteredAnnouncements.count
            }

            func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "AnnouncementCell", for: indexPath) as? AnnouncementCell else {
                    return UITableViewCell()
                }

                let announcement = filteredAnnouncements.isEmpty ? announcements[indexPath.row] : filteredAnnouncements[indexPath.row]
                cell.configure(with: announcement)
                cell.selectionStyle = .none
                return cell
            }

            func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                tableView.deselectRow(at: indexPath, animated: true)
            }

            func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
                return UITableView.automaticDimension
            }
        }

