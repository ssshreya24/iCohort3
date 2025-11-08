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
    

        announcements = [] // empty state

        //DispatchQueue.main.asyncAfter(deadline: .now() + 5) { self.addSample() }
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
        searchContainer.heightAnchor.constraint(lessThanOrEqualToConstant: 50).isActive = true
        searchContainer.clipsToBounds = true
        searchContainer.isHidden = true
        view.addSubview(searchContainer)

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

        // Constraints
        searchContainerTopConstraint = searchContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12)

        NSLayoutConstraint.activate([
            searchContainerTopConstraint,
            searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
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
    }

    // MARK: - Actions
    @IBAction func searchButtonTapped(_ sender: UIButton) {
        searchVisible.toggle()

        UIView.animate(withDuration: 0.3, animations: {
            self.searchContainer.isHidden = !self.searchVisible
            self.searchContainer.alpha = self.searchVisible ? 1 : 0
        }, completion: { _ in
            if self.searchVisible {
                self.searchField.becomeFirstResponder()
            } else {
                self.hideSearchField()
            }
        })
    }

    @objc private func hideSearchField() {
        searchVisible = false
        UIView.animate(withDuration: 0.3) {
            self.searchContainer.isHidden = true
            self.searchField.text = ""
            self.filteredAnnouncements.removeAll()
            self.tableView.reloadData()
        }
        searchField.resignFirstResponder()
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
        titleLabel.isHidden = false
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
        announcements.insert(a, at: 0)
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
        // Make sure to use the same identifier that you set in the XIB
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
        // You can open a detail view here if needed
    }

    // Optional: spacing between cells (padding like in your screenshot)
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
