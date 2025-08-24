//
//  TVShowListViewModel.swift
//  FeatureTVShows
//
//  Created by zeekands on 04/07/25.
//


import Foundation
import SharedDomain // Untuk TVShowEntity, Use Cases, AppNavigatorProtocol
import SharedUI     // Untuk LoadingIndicator, ErrorView
import SwiftUI   

@MainActor
public final class TVShowListViewModel: ObservableObject {
    @Published public var tvShows: [TVShowEntity] = [] // Daftar TV Show yang akan ditampilkan
    @Published public var isLoading: Bool = false // Untuk indikator loading
    @Published public var errorMessage: String? = nil // Untuk menampilkan pesan error

    private let getPopularTVShowsUseCase: GetPopularTVShowsUseCaseProtocol
    private let getTrendingTVShowsUseCase: GetTrendingTVShowsUseCaseProtocol
    private let getTVShowDetailUseCase: GetTVShowDetailUseCaseProtocol // Untuk navigasi
    private let toggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol

    private let appNavigator: AppNavigatorProtocol // Dependensi Navigasi

    public init(
        getPopularTVShowsUseCase: GetPopularTVShowsUseCaseProtocol,
        getTrendingTVShowsUseCase: GetTrendingTVShowsUseCaseProtocol,
        getTVShowDetailUseCase: GetTVShowDetailUseCaseProtocol,
        toggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol,
        appNavigator: AppNavigatorProtocol
    ) {
        self.getPopularTVShowsUseCase = getPopularTVShowsUseCase
        self.getTrendingTVShowsUseCase = getTrendingTVShowsUseCase
        self.getTVShowDetailUseCase = getTVShowDetailUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.appNavigator = appNavigator

        Task { @MainActor in
            await loadTVShows() // Muat TV Show saat ViewModel dibuat
        }
    }


    public func loadTVShows() async {
        guard tvShows.isEmpty || errorMessage != nil else { return } 
        isLoading = true
        errorMessage = nil
        do {
            // Untuk demo, kita ambil keduanya dan gabungkan, atau pilih salah satu
            let popularTVShows = try await getPopularTVShowsUseCase.execute(page: 1)
            let trendingTVShows = try await getTrendingTVShowsUseCase.execute(page: 1)
            self.tvShows = Array(Set(popularTVShows + trendingTVShows)).sorted { $0.name < $1.name } // Gabungkan & hilangkan duplikat
//          self.tvShows = popularTVShows
            // Anda bisa implementasikan paging di sini
        } catch {
            errorMessage = "Failed to load TV Shows: \(error.localizedDescription)"
            print("Error loading TV Shows: \(error)")
        }
        isLoading = false
    }

    public func toggleFavorite(tvShow: TVShowEntity) async {
        do {
            try await toggleFavoriteUseCase.execute(tvShowId: tvShow.id, isFavorite: !tvShow.isFavorite)
            // Perbarui status favorit di daftar lokal tanpa me-reload penuh
            if let index = tvShows.firstIndex(where: { $0.id == tvShow.id }) {
                tvShows[index].isFavorite.toggle()
            }
        } catch {
            errorMessage = "Failed to toggle favorite: \(error.localizedDescription)"
            print("Error toggling favorite: \(error)")
        }
    }

    // MARK: - Navigasi
    public func navigateToTVShowDetail(tvShowId: Int) {
      appNavigator.navigate(to: .tvShowDetail(tvShowId: tvShowId), inTab: .tvShows)
    }

    public func retryLoadTVShows() {
        Task { @MainActor in
            await loadTVShows()
        }
    }
  public func presentGlobalSearch() {
    appNavigator.navigate(to: .search, inTab: .tvShows, hideTabBar: true)
  }
}
