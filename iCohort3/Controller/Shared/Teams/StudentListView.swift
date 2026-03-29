import SwiftUI
import Combine
// MARK: - ViewModel

@MainActor
final class StudentListViewModel: ObservableObject {
    @Published var students: [SupabaseManager.StudentProfileCompleteRow] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func load(excluding myPersonId: String) async {
        if isLoading { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetched = try await SupabaseManager.shared.fetchInvitableStudents(excludingPersonIdString: myPersonId)
            students = fetched
        } catch {
            students = []
            errorMessage = error.localizedDescription
        }
    }

    func sendRequest(
        fromId: String,
        fromName: String,
        toId: String,
        toName: String
    ) async -> String? {
        do {
            try await SupabaseManager.shared.sendTeamMemberRequest(
                fromId: fromId,
                fromName: fromName,
                toId: toId,
                toName: toName
            )
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}

// MARK: - Screen

struct StudentListView: View {

    // ✅ REQUIRED: pass these from TeamViewController
    let myPersonId: String
    let myName: String

    // Optional callback to refresh previous screen
    var onRequestSent: (() -> Void)? = nil

    @StateObject private var vm = StudentListViewModel()
    @State private var searchText: String = ""
    @State private var sendingToPersonId: String? = nil

    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false

    @State private var didInitialLoad: Bool = false

    private var filtered: [SupabaseManager.StudentProfileCompleteRow] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return vm.students }
        return vm.students.filter {
            $0.displayName.lowercased().contains(q) ||
            ($0.department ?? "").lowercased().contains(q) ||
            ($0.regNo ?? "").lowercased().contains(q)
        }
    }

    var body: some View {
        List {
            if vm.isLoading && vm.students.isEmpty {
                loadingRow
            } else if let msg = vm.errorMessage, vm.students.isEmpty {
                errorSection(msg: msg)
            } else if filtered.isEmpty {
                emptySection
            } else {
                ForEach(filtered) { student in
                    StudentRowView(
                        student: student,
                        isSending: sendingToPersonId == student.personId
                    ) {
                        Task { await handleTap(student) }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Students")
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .task {
            // ✅ Load only once on first appearance
            if !didInitialLoad {
                didInitialLoad = true
                await vm.load(excluding: myPersonId)
            }
        }
        .refreshable {
            await vm.load(excluding: myPersonId)
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private var loadingRow: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Loading students…")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private func errorSection(msg: String) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Label("Couldn’t load students", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)

                Text(msg)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button("Try Again") {
                    Task { await vm.load(excluding: myPersonId) }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 8)
        }
    }

    private var emptySection: some View {
        Section {
            VStack(spacing: 10) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)

                Text("No students found")
                    .font(.headline)

                Text("Only students with is_profile_complete = true appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }

    private func handleTap(_ student: SupabaseManager.StudentProfileCompleteRow) async {
        if sendingToPersonId != nil { return } // prevent double taps
        sendingToPersonId = student.personId
        defer { sendingToPersonId = nil }

        // ✅ UUID validation (kept, but clearer message)
        if UUID(uuidString: myPersonId) == nil {
            alertTitle = "Invalid Session"
            alertMessage = "Your person_id is not a valid UUID. Please login again."
            showAlert = true
            return
        }

        if UUID(uuidString: student.personId) == nil {
            alertTitle = "Invalid Student"
            alertMessage = "Selected student's person_id is not a valid UUID."
            showAlert = true
            return
        }

        let toName = student.displayName

        if let err = await vm.sendRequest(
            fromId: myPersonId,
            fromName: myName,
            toId: student.personId,
            toName: toName
        ) {
            alertTitle = "Error"
            alertMessage = err
            showAlert = true
            return
        }

        alertTitle = "Request Sent"
        alertMessage = "Request sent to \(toName)."
        showAlert = true

        onRequestSent?()
    }
}

// MARK: - Row

struct StudentRowView: View {
    let student: SupabaseManager.StudentProfileCompleteRow
    let isSending: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                avatar

                VStack(alignment: .leading, spacing: 4) {
                    Text(student.displayName)
                        .font(.headline)
                        .lineLimit(1)

                    if let dept = student.department, !dept.isEmpty {
                        Text(dept)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if isSending {
                    ProgressView()
                } else {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private var avatar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary)

            Image(systemName: "person.fill")
                .foregroundStyle(.secondary)
        }
        .frame(width: 44, height: 44)
    }
}
