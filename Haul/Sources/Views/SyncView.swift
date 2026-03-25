import SwiftUI

/// R8: Sync view
struct HaulSyncView: View {
    @StateObject private var syncService = HaulSyncService.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("iCloud Sync")
                if syncService.isSyncing {
                    ProgressView()
                } else {
                    Text(syncService.lastSyncText)
                        .foregroundColor(.secondary)
                }
                Button("Sync Now") {
                    Task {
                        try? await syncService.syncAll()
                    }
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding()
            .navigationTitle("Sync")
        }
    }
}
