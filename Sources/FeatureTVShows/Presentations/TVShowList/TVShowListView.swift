//
//  TVShowListView.swift
//  FeatureTVShows
//
//  Created by zeekands on 04/07/25.
//


import SwiftUI
import SharedDomain // Untuk TVShowEntity, AppRoute, AppTab
import SharedUI     // Untuk LoadingIndicator, ErrorView, PosterImageView, ItemGridCell

@MainActor
public struct TVShowListView: View {
  @StateObject private var viewModel: TVShowListViewModel
  
  public init(viewModel: TVShowListViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }
  
  public var body: some View {
    Group {
      if viewModel.isLoading {
        LoadingIndicator()
      } else if let errorMessage = viewModel.errorMessage {
        ErrorView(message: errorMessage, retryAction: viewModel.retryLoadTVShows)
      } else if viewModel.tvShows.isEmpty {
        ContentUnavailableView("No TV Shows Found", systemImage: "tv.fill")
      } else {
        tvShowGrid
      }
    }
    .navigationTitle("TV Shows")
    .toolbar {
      // Contoh: Tombol Search di Navigation Bar
      ToolbarItem(placement: .navigationBarTrailing) {
        Button {
          viewModel.presentGlobalSearch()
        } label: {
          Image(systemName: "magnifyingglass")
        }
      }
    }
    .onAppear {
      Task { await viewModel.loadTVShows() }
    }
    
  }
  
  // MARK: - TV Show Grid View
  private var tvShowGrid: some View {
    ScrollView {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
        ForEach(viewModel.tvShows) { tvShow in
          TVShowGridItemView(tvShow: tvShow)
            .onTapGesture {
              viewModel.navigateToTVShowDetail(tvShowId: tvShow.id)
            }
            .contextMenu { // Contoh Context Menu untuk favorit
              Button {
                Task { await viewModel.toggleFavorite(tvShow: tvShow) }
              } label: {
                Label(tvShow.isFavorite ? "Unfavorite" : "Favorite", systemImage: tvShow.isFavorite ? "star.slash.fill" : "star.fill")
              }
            }
        }
      }
      .padding()
    }
  }
}

public struct TVShowGridItemView: View {
  public let tvShow: TVShowEntity
  
  public init(tvShow: TVShowEntity) {
    self.tvShow = tvShow
  }
  
  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      PosterImageView(imagePath: tvShow.posterPath, imageType: .poster)
        .frame(height: 220)
        .cornerRadius(12)
        .shadow(radius: 5)
      
      Text(tvShow.name) // Untuk TV Show, gunakan `name`
        .font(.headline)
        .lineLimit(2)
        .multilineTextAlignment(.leading)
      
      HStack {
        Image(systemName: "star.fill")
          .foregroundColor(.yellow)
        Text(String(format: "%.1f", tvShow.voteAverage ?? 0.0))
          .font(.caption)
          .foregroundColor(.textSecondary)
        Spacer()
        if tvShow.isFavorite {
          Image(systemName: "heart.fill")
            .foregroundColor(.red)
        }
      }
    }
    .padding(.bottom, 8)
  }
}
