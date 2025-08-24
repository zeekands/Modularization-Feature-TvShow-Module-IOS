//
//  TVShowDetailViewModel.swift
//  FeatureTVShows
//
//  Created by zeekands on 04/07/25.
//


import Foundation
import SharedDomain // Untuk TVShowEntity, Use Cases, AppNavigatorProtocol
import SharedUI     // Untuk LoadingIndicator, ErrorView
import SwiftUI      // Untuk ObservableObject

@MainActor
public final class TVShowDetailViewModel: ObservableObject {
    @Published public var tvShow: TVShowEntity? // Detail TV Show yang akan ditampilkan
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil

    private let tvShowId: Int // ID TV Show yang sedang dilihat

    // Dependensi Use Case
    private let getTVShowDetailUseCase: GetTVShowDetailUseCaseProtocol
    private let toggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol
    
    // Dependensi Navigasi
    private let appNavigator: AppNavigatorProtocol

    public init(
        tvShowId: Int,
        getTVShowDetailUseCase: GetTVShowDetailUseCaseProtocol,
        toggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol,
        appNavigator: AppNavigatorProtocol
    ) {
        self.tvShowId = tvShowId
        self.getTVShowDetailUseCase = getTVShowDetailUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.appNavigator = appNavigator

        Task { @MainActor in
            await loadTVShowDetail() // Muat detail TV Show saat ViewModel dibuat
        }
    }

    public func loadTVShowDetail() async {
      
        isLoading = true
        errorMessage = nil
        do {
            self.tvShow = try await getTVShowDetailUseCase.execute(id: tvShowId)
        } catch {
            errorMessage = "Failed to load TV Show details: \(error.localizedDescription)"
            print("Error loading TV Show detail: \(error)")
        }
        isLoading = false
    }

    public func toggleFavorite() async {
        guard var currentTVShow = tvShow else { return }
        do {
            try await toggleFavoriteUseCase.execute(tvShowId: currentTVShow.id, isFavorite: !currentTVShow.isFavorite)
            currentTVShow.isFavorite.toggle() // Perbarui status favorit lokal
            self.tvShow = currentTVShow // Memicu update UI
        } catch {
            errorMessage = "Failed to toggle favorite: \(error.localizedDescription)"
            print("Error toggling favorite: \(error)")
        }
    }

    // MARK: - Navigasi
    public func navigateBack() {
      appNavigator.pop(inTab: .tvShows) // Kembali di stack navigasi tab .tvShows
    }
    
    public func retryLoadTVShowDetail() {
        Task { @MainActor in
            await loadTVShowDetail()
        }
    }
}
