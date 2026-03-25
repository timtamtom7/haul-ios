import SwiftUI
import PDFKit

struct PrintChecklistView: View {
    let trip: Trip
    let items: [PackingItem]
    let packedCount: Int
    let totalCount: Int

    private var groupedItems: [String: [PackingItem]] {
        Dictionary(grouping: items, by: { $0.category })
    }

    private var sortedCategories: [String] {
        let order = ["CLOTHES", "TOILETRIES", "ELECTRONICS", "DOCUMENTS", "GEAR", "MISC"]
        return groupedItems.keys.sorted { a, b in
            let indexA = order.firstIndex(of: a) ?? Int.max
            let indexB = order.firstIndex(of: b) ?? Int.max
            return indexA < indexB
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .center, spacing: 8) {
                Text("📦 \(trip.name)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                Text(trip.displayDateRange)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Text("Packing Checklist · \(packedCount)/\(totalCount) packed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 20)

            Divider()

            // Items by category
            ForEach(sortedCategories, id: \.self) { category in
                if let catItems = groupedItems[category] {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.top, 16)
                            .padding(.bottom, 4)

                        ForEach(catItems) { item in
                            HStack(spacing: 10) {
                                if item.isPacked {
                                    Text("☑")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(hex: "5d8c5d"))
                                } else {
                                    Text("☐")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                }
                                Text(item.name)
                                    .font(.system(size: 14))
                                    .foregroundColor(item.isPacked ? .gray : .black)
                                    .strikethrough(item.isPacked)
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 40)

            Divider()

            HStack {
                Text("Created with Haul ✦")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                Spacer()
                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            .padding(.top, 16)
        }
        .padding(24)
    }

    func generatePDF() -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            context.beginPage()

            let printView = PrintChecklistView(trip: trip, items: items, packedCount: packedCount, totalCount: totalCount)
            let controller = UIHostingController(rootView: printView)
            controller.view.bounds = CGRect(origin: .zero, size: CGSize(width: 540, height: 720))
            controller.view.layoutIfNeeded()

            let imageRenderer = UIGraphicsImageRenderer(size: controller.view.bounds.size)
            let image = imageRenderer.image { ctx in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }

            image.draw(in: CGRect(origin: .zero, size: pageRect.size))
        }
        return data
    }
}

struct PrintPreviewView: View {
    let trip: Trip
    let items: [PackingItem]
    @Environment(\.dismiss) var dismiss
    @State private var pdfData: Data?

    private var packedCount: Int {
        items.filter { $0.isPacked }.count
    }

    private var totalCount: Int {
        items.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "f5f3ef")
                    .ignoresSafeArea()

                if let data = pdfData {
                    PDFKitView(data: data)
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    ProgressView("Preparing checklist...")
                }
            }
            .navigationTitle("Print Checklist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "c4956a"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if pdfData != nil {
                        ShareLink(item: pdfData!, preview: SharePreview("Packing List for \(trip.name)", image: Image(systemName: "doc.fill"))) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(Color(hex: "c4956a"))
                        }
                    }
                }
            }
            .onAppear {
                generatePDF()
            }
        }
    }

    private func generatePDF() {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let pdf = renderer.pdfData { context in
            context.beginPage()

            let contentView = PrintChecklistContent(
                trip: trip,
                items: items,
                packedCount: packedCount,
                totalCount: totalCount
            )
            let hostingController = UIHostingController(rootView: contentView)
            hostingController.view.frame = CGRect(x: 36, y: 36, width: 540, height: 720)
            hostingController.view.layoutIfNeeded()

            let imageRenderer = UIGraphicsImageRenderer(size: hostingController.view.bounds.size)
            let image = imageRenderer.image { ctx in
                hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
            }

            image.draw(in: CGRect(origin: .zero, size: pageRect.size))
        }
        pdfData = pdf
    }
}

struct PrintChecklistContent: View {
    let trip: Trip
    let items: [PackingItem]
    let packedCount: Int
    let totalCount: Int

    private var groupedItems: [String: [PackingItem]] {
        Dictionary(grouping: items, by: { $0.category })
    }

    private var sortedCategories: [String] {
        let order = ["CLOTHES", "TOILETRIES", "ELECTRONICS", "DOCUMENTS", "GEAR", "MISC"]
        return groupedItems.keys.sorted { a, b in
            let indexA = order.firstIndex(of: a) ?? Int.max
            let indexB = order.firstIndex(of: b) ?? Int.max
            return indexA < indexB
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .center, spacing: 8) {
                Text("📦 \(trip.name)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                Text(trip.displayDateRange)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Text("Packing Checklist · \(packedCount)/\(totalCount) packed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 20)

            Divider()

            ForEach(sortedCategories, id: \.self) { category in
                if let catItems = groupedItems[category] {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.top, 16)
                            .padding(.bottom, 4)

                        ForEach(catItems) { item in
                            HStack(spacing: 10) {
                                Text(item.isPacked ? "☑" : "☐")
                                    .font(.system(size: 16))
                                    .foregroundColor(item.isPacked ? Color(hex: "5d8c5d") : .gray)
                                Text(item.name)
                                    .font(.system(size: 14))
                                    .foregroundColor(item.isPacked ? .gray : .black)
                                    .strikethrough(item.isPacked)
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 40)

            Divider()

            HStack {
                Text("Created with Haul ✦")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                Spacer()
                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            .padding(.top, 16)
        }
        .padding(24)
    }
}

struct PDFKitView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = PDFDocument(data: data)
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}
