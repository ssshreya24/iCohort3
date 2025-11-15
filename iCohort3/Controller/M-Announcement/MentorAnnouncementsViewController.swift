//
//  MentorAnnouncementsViewController.swift
//  iCohort3
//

import UIKit

class MentorAnnouncementsViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!

    private var announcements: [Announcement] = [] {
        didSet { updateUI() }
    }

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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.addSample() }

        navigationController?.isNavigationBarHidden = true
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = [.top, .bottom]
    }

    private func setupViews() {
        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.tintColor = .label
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        // Correct XIB name + reuse identifier
        let nib = UINib(nibName: "MentorAnnouncementTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "MentorAnnouncementCell")

        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()
    }

    // MARK: Search UI
    private func setupSearchUI() {

        searchContainer = UIView()
        searchField = UITextField()

        searchContainer.translatesAutoresizingMaskIntoConstraints = false
        searchContainer.backgroundColor = .white
        searchContainer.layer.cornerRadius = 20
        searchContainer.alpha = 0
        searchContainer.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)

        view.addSubview(searchContainer)
        view.bringSubviewToFront(searchButton)

        searchIcon.tintColor = .systemGray
        searchIcon.translatesAutoresizingMaskIntoConstraints = false
        searchContainer.addSubview(searchIcon)

        searchField.placeholder = "Search"
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        searchContainer.addSubview(searchField)

        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .systemGray
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(hideSearchField), for: .touchUpInside)
        searchContainer.addSubview(closeButton)

        searchContainerTopConstraint = searchContainer.centerYAnchor.constraint(equalTo: searchButton.centerYAnchor)

        NSLayoutConstraint.activate([
            searchContainerTopConstraint,
            searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchContainer.trailingAnchor.constraint(equalTo: searchButton.trailingAnchor),
            searchContainer.heightAnchor.constraint(equalToConstant: 45),

            searchIcon.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 12),
            searchIcon.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -12),
            closeButton.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),

            searchField.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 8),
            searchField.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            searchField.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor)
        ])
    }

    // MARK: Actions
    @IBAction func searchButtonTapped(_ sender: UIButton) {
        searchVisible ? hideSearchField() : showSearchField()
    }

    private func showSearchField() {
        searchVisible = true
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut,
            animations: {
                self.searchContainer.alpha = 1
                self.searchContainer.transform = .identity
                self.searchButton.alpha = 0
        }) { _ in
            self.searchButton.isHidden = true
            self.searchField.becomeFirstResponder()
        }
    }

    @objc private func hideSearchField() {
        searchVisible = false
        searchField.resignFirstResponder()
        searchButton.isHidden = false

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: .curveEaseIn,
            animations: {
                self.searchContainer.alpha = 0
                self.searchContainer.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                self.searchButton.alpha = 1
        }) { _ in
            self.searchField.text = ""
            self.filteredAnnouncements.removeAll()
            self.tableView.reloadData()
        }
    }

    @objc private func searchTextChanged(_ field: UITextField) {
        guard let txt = field.text?.lowercased(), !txt.isEmpty else {
            filteredAnnouncements.removeAll()
            tableView.reloadData()
            return
        }

        filteredAnnouncements = announcements.filter {
            $0.title.lowercased().contains(txt) ||
            $0.body.lowercased().contains(txt) ||
            ($0.tag?.lowercased().contains(txt) ?? false) ||
            $0.author.lowercased().contains(txt)
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

    // MARK: Sample Data
    func addSample() {
        announcements.insert(
            Announcement(
                id: UUID(),
                title: "Mentor Sync Session",
                body: "Weekly sync meeting for all mentors tomorrow.",
                tag: "Meeting",
                createdAt: Date(),
                author: "Program Lead"
            ),
            at: 0
        )
    }
}

// MARK: - Table Data Source
extension MentorAnnouncementsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredAnnouncements.isEmpty ? announcements.count : filteredAnnouncements.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "MentorAnnouncementCell",
            for: indexPath
        ) as? MentorAnnouncementTableViewCell else {
            return UITableViewCell()
        }

        let obj = filteredAnnouncements.isEmpty ? announcements[indexPath.row] : filteredAnnouncements[indexPath.row]
        cell.configure(with: obj)
        cell.selectionStyle = .none
        return cell
    }
}
