//
//  TVShowDetailView.swift
//  FeatureTVShows
//
//  Created by zeekands on 04/07/25.
//


import SwiftUI
import SharedDomain // Untuk TVShowEntity
import SharedUI     // Untuk LoadingIndicator, ErrorView, PosterImageView

public struct TVShowDetailView: View {
    @StateObject private var viewModel: TVShowDetailViewModel

    public init(viewModel: TVShowDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingIndicator()
            } else if let errorMessage = viewModel.errorMessage {
                ErrorView(message: errorMessage, retryAction: viewModel.retryLoadTVShowDetail)
            } else if let tvShow = viewModel.tvShow {
                tvShowDetailContent(tvShow: tvShow)
            } else {
                ContentUnavailableView("TV Show Not Found", systemImage: "tv.slash.fill")
            }
        }
        .navigationTitle(viewModel.tvShow?.name ?? "TV Show Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let tvShow = viewModel.tvShow {
                    Button(action: {
                        Task { await viewModel.toggleFavorite() }
                    }) {
                        Image(systemName: tvShow.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(tvShow.isFavorite ? .red : .gray)
                    }
                }
            }
        }
        .onAppear {
            Task { await viewModel.loadTVShowDetail() }
        }
    }

    // MARK: - TV Show Detail Content
    private func tvShowDetailContent(tvShow: TVShowEntity) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Poster dan Backdrop
                ZStack(alignment: .bottomLeading) {
                    PosterImageView(imagePath: tvShow.backdropPath, imageType: .backdrop)
                        .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 250)
                        .clipped()
                    
                    PosterImageView(imagePath: tvShow.posterPath, imageType: .poster)
                        .frame(width: 120, height: 180)
                        .cornerRadius(10)
                        .shadow(radius: 8)
                        .padding(.leading)
                        .offset(y: 60) // Mengangkat poster di atas backdrop
                }
                .frame(maxHeight: 250) // Batasi tinggi ZStack
                .padding(.bottom, 60) // Padding untuk poster yang offset

                // Judul dan Info Utama
                VStack(alignment: .leading, spacing: 8) {
                    Text(tvShow.name) // Untuk TV Show, gunakan `name`
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", tvShow.voteAverage ?? 0.0))
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        
                        if let firstAirDate = tvShow.firstAirDate {
                            Text("(\(firstAirDate.formatted(date: .numeric, time: .omitted)))")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                        
                        // Genres
                        if !tvShow.genres.isEmpty {
                            Text(tvShow.genres.map { $0.name }.joined(separator: ", "))
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    Text(tvShow.overview ?? "No overview available.")
                        .font(.body)
                        .foregroundColor(.textPrimary)
                        .padding(.top, 10)
                }
                .padding(.horizontal)
            }
        }
    }
}
