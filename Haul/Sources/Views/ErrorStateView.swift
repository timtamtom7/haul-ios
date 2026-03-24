import SwiftUI
import AVFoundation

// MARK: - Error Type
enum HaulError: Equatable {
    case cameraPermissionDenied
    case tripLimitReached(limit: Int)
    case itemSaveFailed
    case photoSaveFailed
    case emptyTrips

    var icon: String {
        switch self {
        case .cameraPermissionDenied: return "camera.fill"
        case .tripLimitReached: return "suitcase.fill"
        case .itemSaveFailed: return "exclamationmark.triangle.fill"
        case .photoSaveFailed: return "photo.fill"
        case .emptyTrips: return "suitcase"
        }
    }

    var title: String {
        switch self {
        case .cameraPermissionDenied: return "Camera access needed"
        case .tripLimitReached: return "Trip limit reached"
        case .itemSaveFailed: return "Couldn't save item"
        case .photoSaveFailed: return "Couldn't save photo"
        case .emptyTrips: return "No trips planned"
        }
    }

    var message: String {
        switch self {
        case .cameraPermissionDenied:
            return "Haul uses your camera to photograph your suitcase. Enable camera access in Settings to continue."
        case .tripLimitReached(let limit):
            return "Your Free plan lets you track \(limit) trips. Upgrade to Pack or Travel for unlimited trips."
        case .itemSaveFailed:
            return "Something went wrong saving that item. Please try again."
        case .photoSaveFailed:
            return "The photo couldn't be saved. Make sure you have enough storage space."
        case .emptyTrips:
            return "Tap the button below to plan your first trip. Your suitcase is waiting."
        }
    }

    var actionLabel: String {
        switch self {
        case .cameraPermissionDenied: return "Open Settings"
        case .tripLimitReached: return "See Plans"
        case .itemSaveFailed: return "Try Again"
        case .photoSaveFailed: return "Try Again"
        case .emptyTrips: return "New Trip"
        }
    }

    var color: Color {
        switch self {
        case .cameraPermissionDenied: return HaulTheme.accent
        case .tripLimitReached: return HaulTheme.accent
        case .itemSaveFailed: return .orange
        case .photoSaveFailed: return .orange
        case .emptyTrips: return HaulTheme.accent
        }
    }
}

// MARK: - Error State View
struct ErrorStateView: View {
    let error: HaulError
    let onAction: () -> Void
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(error.color.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: error.icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(error.color)
            }
            .padding(.bottom, 8)

            // Text
            VStack(spacing: 10) {
                Text(error.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(HaulTheme.textPrimary)

                Text(error.message)
                    .font(.system(size: 15))
                    .foregroundColor(HaulTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 8)
            }

            // Action button
            Button(action: onAction) {
                Text(error.actionLabel)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 13)
                    .background(error.color)
                    .cornerRadius(12)
            }
            .padding(.top, 4)

            // Secondary action (dismiss for some errors)
            if let dismiss = onDismiss {
                Button {
                    dismiss()
                } label: {
                    Text("Dismiss")
                        .font(.system(size: 14))
                        .foregroundColor(HaulTheme.textSecondary)
                }
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Camera Permission View
struct CameraPermissionView: View {
    @ObservedObject var cameraService = CameraService()
    let onPhotoCaptured: (UIImage) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            HaulTheme.background
                .ignoresSafeArea()

            if cameraService.isAuthorized {
                // Show camera
                CameraView { image in
                    onPhotoCaptured(image)
                }
            } else {
                ErrorStateView(
                    error: .cameraPermissionDenied,
                    onAction: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    },
                    onDismiss: onDismiss
                )
            }
        }
        .onAppear {
            cameraService.checkAuthorization()
        }
    }
}

// MARK: - Trip Limit Reached View
struct TripLimitReachedView: View {
    @Binding var isPresented: Bool
    let limit: Int
    let onShowPricing: () -> Void

    var body: some View {
        ZStack {
            HaulTheme.background
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(HaulTheme.accent.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "suitcase.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(HaulTheme.accent)
                }

                VStack(spacing: 12) {
                    Text("Trip limit reached")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(HaulTheme.textPrimary)

                    Text("Your Free plan includes \(limit) trips. You've used them all.")
                        .font(.system(size: 15))
                        .foregroundColor(HaulTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                VStack(spacing: 12) {
                    Button {
                        onShowPricing()
                    } label: {
                        Text("See upgrade options")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(HaulTheme.accent)
                            .cornerRadius(12)
                    }

                    Button {
                        isPresented = false
                    } label: {
                        Text("Maybe later")
                            .font(.system(size: 14))
                            .foregroundColor(HaulTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
    }
}

// MARK: - Item Save Failed View
struct ItemSaveFailedView: View {
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(.orange)
            }

            VStack(spacing: 8) {
                Text("Couldn't save item")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(HaulTheme.textPrimary)

                Text("Something went wrong. Please try again.")
                    .font(.system(size: 14))
                    .foregroundColor(HaulTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Button {
                    onDismiss()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(HaulTheme.textSecondary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(HaulTheme.unchecked.opacity(0.3))
                        .cornerRadius(10)
                }

                Button {
                    onRetry()
                } label: {
                    Text("Try Again")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .cornerRadius(10)
                }
            }
        }
        .padding(24)
        .background(
            VisualEffectBlur(blurStyle: .systemMaterial)
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 40)
    }
}

// MARK: - Photo Save Failed View
struct PhotoSaveFailedView: View {
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: "photo.fill")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(.orange)
            }

            VStack(spacing: 8) {
                Text("Couldn't save photo")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(HaulTheme.textPrimary)

                Text("Make sure you have enough storage space on your device.")
                    .font(.system(size: 14))
                    .foregroundColor(HaulTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            HStack(spacing: 12) {
                Button {
                    onDismiss()
                } label: {
                    Text("Skip Photo")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(HaulTheme.textSecondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(HaulTheme.unchecked.opacity(0.3))
                        .cornerRadius(10)
                }

                Button {
                    onRetry()
                } label: {
                    Text("Try Again")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .cornerRadius(10)
                }
            }
        }
        .padding(24)
        .background(
            VisualEffectBlur(blurStyle: .systemMaterial)
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 40)
    }
}

// MARK: - Empty State (No Trips)
struct EmptyTripsView: View {
    let onNewTrip: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                // Background luggage tag shape
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(HaulTheme.accent.opacity(0.08))
                        .frame(width: 120, height: 120)

                    // Suitcase icon
                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(HaulTheme.accentDark)
                            .frame(width: 24, height: 6)
                            .offset(y: -1)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(HaulTheme.accent)
                            .frame(width: 60, height: 45)
                            .overlay(
                                VStack(spacing: 4) {
                                    ForEach(0..<2, id: \.self) { _ in
                                        RoundedRectangle(cornerRadius: 1.5)
                                            .fill(HaulTheme.accentDark.opacity(0.35))
                                            .frame(width: 36, height: 3)
                                    }
                                }
                            )
                    }
                }
            }
            .padding(.bottom, 8)

            VStack(spacing: 10) {
                Text("No trips planned")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(HaulTheme.textPrimary)

                Text("Ready for your next adventure?\nStart by naming your destination.")
                    .font(.system(size: 15))
                    .foregroundColor(HaulTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button {
                onNewTrip()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 17))
                    Text("New Trip")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(HaulTheme.accent)
                .cornerRadius(12)
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 32)
    }
}
