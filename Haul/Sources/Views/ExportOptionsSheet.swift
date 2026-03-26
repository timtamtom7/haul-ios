import SwiftUI
import os.log

/// R10: Export options sheet — JSON / CSV export for a trip
struct ExportOptionsSheet: View {
    @EnvironmentObject var tripStore: TripStore
    @Environment(\.dismiss) var dismiss
    let trip: Trip

    @State private var selectedFormat: ExportFormat = .json
    @State private var isExporting = false
    @State private var exportedURL: URL?
    @State private var showingShareSheet = false
    @State private var showingError = false
    @State private var errorMessage = ""

    private let logger = Logger(subsystem: "com.haulapp.ios", category: "ExportOptionsSheet")

    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"

        var icon: String {
            switch self {
            case .json: return "curlybraces"
            case .csv: return "tablecells"
            }
        }

        var description: String {
            switch self {
            case .json: return "Full backup with all trip data, items, and bags"
            case .csv: return "Spreadsheet-ready list of all packing items"
            }
        }

        var fileExtension: String {
            switch self {
            case .json: return "json"
            case .csv: return "csv"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HaulTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Trip info header
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(HaulTheme.accent.opacity(0.12))
                                    .frame(width: 52, height: 52)
                                Image(systemName: "square.and.arrow.up.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(HaulTheme.accent)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Export \(trip.name)")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(HaulTheme.textPrimary)

                                let total = tripStore.totalCount(for: trip.id ?? 0)
                                Text("\(total) items · \(trip.displayDateRange)")
                                    .font(.system(size: 13))
                                    .foregroundColor(HaulTheme.textSecondary)
                            }

                            Spacer()
                        }
                        .padding(16)
                        .background(VisualEffectBlur(blurStyle: .systemMaterial))
                        .cornerRadius(16)

                        // Format selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Export Format")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(HaulTheme.textSecondary)
                                .tracking(1)
                                .textCase(.uppercase)

                            ForEach(ExportFormat.allCases, id: \.self) { format in
                                Button {
                                    selectedFormat = format
                                } label: {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            Circle()
                                                .fill(selectedFormat == format ? HaulTheme.accent.opacity(0.15) : HaulTheme.unchecked.opacity(0.3))
                                                .frame(width: 48, height: 48)

                                            Image(systemName: format.icon)
                                                .font(.system(size: 20))
                                                .foregroundColor(selectedFormat == format ? HaulTheme.accent : HaulTheme.textSecondary)
                                        }

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(format.rawValue)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(HaulTheme.textPrimary)

                                            Text(format.description)
                                                .font(.system(size: 12))
                                                .foregroundColor(HaulTheme.textSecondary)
                                                .multilineTextAlignment(.leading)
                                                .lineSpacing(2)
                                        }

                                        Spacer()

                                        // Radio indicator
                                        ZStack {
                                            Circle()
                                                .stroke(selectedFormat == format ? HaulTheme.accent : HaulTheme.unchecked, lineWidth: 2)
                                                .frame(width: 22, height: 22)

                                            if selectedFormat == format {
                                                Circle()
                                                    .fill(HaulTheme.accent)
                                                    .frame(width: 22, height: 22)

                                                Circle()
                                                    .fill(.white)
                                                    .frame(width: 8, height: 8)
                                            }
                                        }
                                    }
                                    .padding(14)
                                    .background(selectedFormat == format ? HaulTheme.accent.opacity(0.05) : HaulTheme.surfaceLight)
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(selectedFormat == format ? HaulTheme.accent.opacity(0.3) : Color.clear, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // What gets exported
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What's included")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(HaulTheme.textSecondary)
                                .tracking(1)
                                .textCase(.uppercase)

                            VStack(spacing: 10) {
                                exportItem(icon: "suitcase.fill", text: "Trip name, dates, and details")
                                exportItem(icon: "list.bullet", text: "All \(tripStore.totalCount(for: trip.id ?? 0)) packing items with categories")
                                exportItem(icon: "suitcase.2.fill", text: "All \(tripStore.currentTripBags.count) bags")
                                if trip.isPast {
                                    exportItem(icon: "star.fill", text: "Trip feedback (if submitted)")
                                }
                            }
                        }
                        .padding(16)
                        .background(VisualEffectBlur(blurStyle: .systemMaterial))
                        .cornerRadius(16)

                        // Export button
                        Button {
                            performExport()
                        } label: {
                            HStack(spacing: 10) {
                                if isExporting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "square.and.arrow.up.fill")
                                }
                                Text(isExporting ? "Exporting..." : "Export \(selectedFormat.rawValue)")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isExporting ? HaulTheme.textSecondary : HaulTheme.checkedGreen)
                            .cornerRadius(12)
                        }
                        .disabled(isExporting)

                        Text("You'll be able to share or save the exported file.")
                            .font(.system(size: 12))
                            .foregroundColor(HaulTheme.textSecondary)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(HaulTheme.textSecondary)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Export failed", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func exportItem(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(HaulTheme.accent)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(HaulTheme.textPrimary)
            Spacer()
        }
    }

    private func performExport() {
        isExporting = true

        let tripId = trip.id ?? 0
        let items = tripStore.getAllItems(for: tripId)
        let bags = tripStore.currentTripBags

        var url: URL?

        switch selectedFormat {
        case .json:
            url = ExportService.shared.exportTripToJSON(trip: trip, items: items, bags: bags)
        case .csv:
            url = ExportService.shared.exportTripToCSV(trip: trip, items: items, bags: bags)
        }

        isExporting = false

        if let url = url {
            exportedURL = url
            showingShareSheet = true
            logger.info("Exported trip '\(trip.name)' as \(self.selectedFormat.rawValue)")
        } else {
            errorMessage = "Couldn't create the export file. Please try again."
            showingError = true
        }
    }
}
