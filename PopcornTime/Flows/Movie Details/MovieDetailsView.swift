//
//  DetailView.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 19.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import PopcornKit
import Kingfisher

struct MovieDetailsView: View {
    let theme = Theme()
    
    @StateObject var viewModel: MovieDetailsViewModel
    @State var error: Error?
    
    var movie: Movie {
        return viewModel.movie
    }
    @Namespace var section1
    
    var body: some View {
            ZStack {
                backgroundImage()
                ScrollViewReader { scroll in
                    ScrollView {
                        VStack {
                            Text(movie.title)
                                .font(theme.titleFont)
                                .padding(.bottom, 50)
                                .padding(.top, 200)
                                .padding(.leading, -theme.leftSectionLeading)
                                
                            HStack(alignment: .top, spacing: 40) {
                                leftSection
                                rightSection(scroll: scroll)
                                Spacer()
                            }
                            .padding(.leading, 10)
                            #if os(iOS)
                            actionButtons(scroll: nil)
                                .padding(.top, 10)
                            #endif
                        }
                        .padding(.leading, theme.leftSectionLeading)
                        .frame(idealHeight: theme.section1Height)
                        
                        .id(section1)
                        #if os(tvOS)
                        .focusSection()
                        #endif
                        
                        VStack {
                            if movie.related.count > 0 {
                                alsoWatchedSection
                                    #if os(tvOS)
                                    .focusSection()
                                    #endif
                            }
                            if movie.actors.count > 0 {
                                ActorsCrewView(persons: movie.actors + movie.crew)
                                #if os(tvOS)
                                .focusSection()
                                #endif
                            }
                        }
                        #if os(tvOS)
                        .padding([.bottom, .top], 30)
                        #else
                        .padding([.bottom], 30)
                        #endif
                        .background(Color.init(white: 1, opacity: 0.3))
                        .padding(.top, 50)
                    }
                }
                if let error = error ?? viewModel.error {
                    BannerView(error: error)
                        .padding([.top, .trailing], 60)
                        .transition(.move(edge: .top))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                self.error = nil
                            }
                        }
                }
            }.onAppear {
                viewModel.playSongTheme()
                viewModel.load()
                viewModel.trailerModel.error = $error // bind error for displaying
            }.onDisappear {
                viewModel.stopTheme()
            }
        .ignoresSafeArea()
    }
    
    func backgroundImage() -> some View {
        Color.clear
            .background(
                KFImage(viewModel.backgroundUrl)
                    .resizable()
                    .loadImmediately()
                    .aspectRatio(contentMode: .fill)
                    .padding(0)
            )
            .overlay(
                Color(white: 0, opacity: theme.backgroundOpacity))
            .clipped()
    }
    
    @ViewBuilder
    var leftSection: some View {
        VStack(alignment: .trailing, spacing: 40) {
            if let genre = movie.genres.first?.localizedCapitalized.localized {
                sectionText(title: "Genre".localized.localizedUppercase, description: [genre])
            }
            
            let directors = movie.crew.filter({$0.roleType == .director}).prefix(5).compactMap{String($0.name)}
            if directors.count > 0,
               let isSingular = directors.count == 1 {
                sectionText(title: (isSingular ? "Director".localized.localizedUppercase : "Directors".localized.localizedUppercase), description: directors)
            }
            
            let showActorsCount = max(6 - directors.count, 1)
            let actors = movie.actors.prefix(showActorsCount).compactMap{ String($0.name) }
            if !actors.isEmpty {
                sectionText(title: "Starring".localized.localizedUppercase, description: actors)
            }
            
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .frame(width: theme.leftSectionWidth)
    }
    
    @ViewBuilder
    func rightSection(scroll: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 50) {
            infoText
            ratings()
            Color.clear
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(movie.summary)
                        awards()
                    }
                }
            #if os(tvOS)
                .frame(width: 920)
            #endif
            #if os(tvOS) || os(macOS)
            actionButtons(scroll: scroll)
            #endif
        }
    }
    
    @ViewBuilder
    func actionButtons(scroll: ScrollViewProxy?) -> some View {
        HStack(spacing: 24) {
            TrailerButton(viewModel: viewModel.trailerModel)
            PlayButton(media: movie)
            watchlistButton
            watchedButton
            DownloadButton(viewModel: viewModel.downloadModel)
        }
        .buttonStyle(TVButtonStyle(onFocus: {
            withAnimation {
                scroll?.scrollTo(section1, anchor: .top)
            }
        }))
    }
    
    var infoText: some View {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.hour, .minute]
        let runtime = formatter.string(from: TimeInterval(movie.runtime) * 60)
        let year = movie.year
        
        let items = [Text([runtime, year].compactMap({$0}).joined(separator: "\t"))]
        + ([movie.certification, "HD", "CC"]).filter{ !$0.isEmpty }.map {
                Text(Image($0).renderingMode(.template))
            }
        return HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 25) {
            ForEach(0..<items.count) { item in
                items[item]
            }
            
            StarRatingView(rating: movie.rating / 20)
                .frame(width: theme.starSize.width, height: theme.starSize.height)
                .padding(.top, theme.starOffset)
        }
    }
    
    @ViewBuilder
    func sectionText(title: String, description: [String]) -> some View {
        VStack(alignment: .trailing) {
            Text(title)
                .font(.system(size: theme.leftSectionTitle, weight: .bold))
                .foregroundColor(.appLightGray)
            ForEach(description, id: \.self) { item in
                Text(item)
            }
            .font(.system(size: theme.leftSectionTitleContent, weight: .medium))
            .foregroundColor(.appGray)
        }
    }
    

    
    var seasonsButton: some View {
        return Button(action: {
            
        }, label: {
            VStack {
                VisualEffectBlur() {
                    Image("Seasons")
                }.cornerRadius(6)
                Text("Series")
            }
        })
        .frame(width: theme.buttonWidth, height: theme.buttonHeight)
    }
    
    var watchlistButton: some View {
        return Button(action: {
            viewModel.movie.isAddedToWatchlist.toggle()
            print(#function, viewModel.movie.isAddedToWatchlist)
        }, label: {
            VStack {
                VisualEffectBlur() {
                    movie.isAddedToWatchlist ? Image("Remove") : Image("Add")
                }
                Text("Watchlist")
            }
        })
        .frame(width: theme.buttonWidth, height: theme.buttonHeight)
    }
    
    var watchedButton: some View {
        return Button(action: {
            viewModel.movie.isWatched.toggle()
            print(#function, viewModel.movie.isWatched)
        }, label: {
            VStack {
                VisualEffectBlur() {
                    movie.isWatched ? Image("Watched On") : Image("Watched Off")
                }
                Text("Watched")
            }
        })
        .frame(width: theme.buttonWidth, height: theme.buttonHeight)
    }
    
    var alsoWatchedSection: some View {
        VStack (alignment: .leading) {
            Text("Viewers Also Watched")
                .font(.callout)
                .foregroundColor(.appSecondary)
                .padding(.leading, theme.watchedSection.spacing)
                .padding(.top, 14)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .center, spacing: theme.watchedSection.spacing) {
                    Spacer(minLength: theme.watchedSection.spacing)
                    ForEach(movie.related, id: \.self) { movie in
                        NavigationLink(
                            destination: MovieDetailsView(viewModel: MovieDetailsViewModel(movie: movie)),
                            label: {
                                MovieView(movie: movie, lineLimit: 1)
                                    .frame(width: theme.watchedSection.cellWidth)
                            })
                            .buttonStyle(PlainNavigationLinkButtonStyle())
                    }
                }
                #if os(tvOS)
                .padding([.top, .bottom], 30) // on focus zoom will not be clipped
                #endif
            }
        }
        .frame(height: theme.watchedSection.height)
        .padding(0)
        .background(
            Color(white: 0, opacity: 0.3)
                .padding([.bottom], -10)
            #if os(tvOS)
                .padding([.top], -30)
            #endif
        )
    }
    
    @ViewBuilder
    func awards() -> some View {
        if let awards = movie.ratings?.awards {
            Text("Awards: " + awards)
                .font(.caption)
        }
    }
    
    @ViewBuilder
    func ratings() -> some View {
        if let ratings = movie.ratings {
            HStack(spacing: 25) {
                if let metascore = ratings.metascore {
                    ratingItem(image: "metacritic", value: metascore)
                }
                if let imdb = ratings.imdbRating {
                    ratingItem(image: "imdb", value: imdb)
                }
                if let rotten = ratings.rottenTomatoes {
                    ratingItem(image: "rotten-tomatoes", value: rotten)
                }
            }
            .font(.caption)
            .lineLimit(1)
        }
    }
    
    func ratingItem(image: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: theme.ratingHeight)
            Text(value)
            #if os(macOS)
                .font(.title2)
            #endif
        }
    }
}

extension MovieDetailsView {
    struct Theme {
        let buttonWidth: CGFloat = value(tvOS: 142, macOS: 100)
        let buttonHeight: CGFloat = value(tvOS: 115, macOS: 81)
        let leftSectionTitle: CGFloat = value(tvOS: 24, macOS: 16)
        let leftSectionTitleContent: CGFloat = value(tvOS: 31, macOS: 18)
        let leftSectionWidth: CGFloat = value(tvOS: 340, macOS: 200)
        let leftSectionLeading: CGFloat = value(tvOS: 100, macOS: 30)
        let starSize: CGSize = value(tvOS: CGSize(width: 220, height: 40), macOS: CGSize(width: 110, height: 20))
        let starOffset: CGFloat = value(tvOS: -8, macOS: -4)
        let ratingHeight: CGFloat = value(tvOS: 32, macOS: 24)
        let watchedSection: (height: CGFloat, cellWidth: CGFloat, spacing: CGFloat)
            = (height: value(tvOS: 450, macOS: 240),
               cellWidth: value(tvOS: 220, macOS: 150),
               spacing: value(tvOS: 90, macOS: 40))
        let backgroundOpacity = value(tvOS: 0.3, macOS: 0.5)
        let titleFont: Font = Font.system(size: value(tvOS: 76, macOS: 50), weight: .medium)
        let section1Height: CGFloat = value(tvOS: 960, macOS: 710)
    }
}

struct MovieDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MovieDetailsView(viewModel: viewModel())
            #if os(tvOS)
                .previewLayout(.fixed(width: 2000, height: 1800))
            #endif
            
            MovieDetailsView(viewModel: errorViewModel())
                .previewDisplayName("Error")
            
            MovieDetailsView(viewModel: loadingViewModel())
                .previewDisplayName("Loading")
        }
        .preferredColorScheme(.dark)
//        .previewInterfaceOrientation(.landscapeLeft)
    }
    
    static func viewModel() -> MovieDetailsViewModel {
        let viewModel = MovieDetailsViewModel(movie: Movie.dummy())
        viewModel.didLoad = true
        return viewModel
    }
    
    static func loadingViewModel() -> MovieDetailsViewModel {
        let movie = Movie.dummiesFromJSON()[0]
        let viewModel = MovieDetailsViewModel(movie: movie)
        viewModel.isLoading = true
        return viewModel
    }
    
    static func errorViewModel() -> MovieDetailsViewModel {
        let viewModel = MovieDetailsViewModel(movie: Movie.dummy())
        let error = NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "This is an error text example"])
        viewModel.error = error
        viewModel.didLoad = true
        return viewModel
    }
}
