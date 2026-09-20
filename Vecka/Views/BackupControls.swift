import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct PlannerBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

/// Backup and restore remain available regardless of purchase status.
struct BackupControls: View {
    let container: ModelContainer?
    var onRecover: ((PlannerBackup) throws -> Void)? = nil
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    @State private var document: PlannerBackupDocument?
    @State private var exporting = false
    @State private var importing = false
    @State private var pendingBackup: PlannerBackup?
    @State private var confirmRestore = false
    @State private var showMessage = false
    @State private var message = ""

    var body: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
            JohoPill(text: "BACKUP & RECOVERY", style: .whiteOnBlack, size: .small)
            Text("Keep a copy of your entries, contacts, holidays, clocks and countdowns. Backup files include private information and photos; choose a trusted location.")
                .font(JohoFont.bodySmall)
                .foregroundStyle(colors.secondary)
            if let container {
                Button("Export backup") {
                    do {
                        document = PlannerBackupDocument(data: try PlannerBackupService.encode(context: container.mainContext))
                        exporting = true
                    } catch { report(error.localizedDescription) }
                }
                .font(JohoFont.bodySmallBold)
                .johoTouchTarget()
            }
            Button("Restore backup") { importing = true }
                .font(JohoFont.bodySmallBold)
                .johoTouchTarget()
        }
        .foregroundStyle(colors.primary)
        .padding(JohoDimensions.spacingLG)
        .background(colors.surface)
        .johoBordered()
        .fileExporter(isPresented: $exporting, document: document, contentType: .json,
                      defaultFilename: "Onsen-Planner-Backup") { result in
            switch result {
            case .success: report("Your backup was exported successfully.")
            case .failure(let error): report(error.localizedDescription)
            }
            document = nil
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do {
                pendingBackup = try PlannerBackupService.read(result.get())
                confirmRestore = true
            } catch { report(error.localizedDescription) }
        }
        .confirmationDialog("Restore this backup?", isPresented: $confirmRestore, titleVisibility: .visible) {
            Button("Restore missing records") {
                guard let backup = pendingBackup else { return }
                do {
                    if let container {
                        try container.mainContext.save()
                        let count = try PlannerBackupService.restore(backup, into: container)
                        report("Restore completed. Added \(count) records and merged countdowns. Existing entries were kept.")
                    } else {
                        try onRecover?(backup)
                    }
                    pendingBackup = nil
                } catch { report(error.localizedDescription) }
            }
            Button("Cancel", role: .cancel) { pendingBackup = nil }
        } message: {
            Text(container == nil
                 ? "This creates a separate planner. The original files remain on your device."
                 : "Missing records will be added. Existing records will not be replaced or deleted. Appearance settings are unchanged.")
        }
        .alert("Backup & recovery", isPresented: $showMessage) {
            Button("OK", role: .cancel) { }
        } message: { Text(message) }
    }

    private func report(_ text: String) {
        message = text
        showMessage = true
    }
}

struct StorageRecoveryView: View {
    let persistence: AppPersistence
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: JohoDimensions.spacingLG) {
                Text("Your planner")
                    .font(JohoFont.headline)
                if let error = persistence.errorMessage {
                    Text(error).font(JohoFont.body)
                    Button("Retry opening planner") { persistence.open() }
                        .font(JohoFont.bodySmallBold)
                        .johoTouchTarget()
                        .disabled(persistence.isOpening)
                    BackupControls(container: nil, onRecover: persistence.recover)
                } else {
                    ProgressView("Opening saved planner…")
                        .font(JohoFont.body)
                }
            }
            .padding(JohoDimensions.spacingLG)
        }
        .foregroundStyle(colors.primary)
        .background(colors.canvas)
    }
}
