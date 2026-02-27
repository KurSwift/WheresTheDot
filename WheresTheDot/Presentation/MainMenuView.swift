//
//  MainMenuView.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation
import SwiftUI
internal import Combine

@MainActor
final class MainMenuViewModel: ObservableObject {
    @Published var selectedMode: GameMode = .classic
}

struct MainMenuView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm = MainMenuViewModel()

    var body: some View {
        ZStack {
            NeonGridBackground()
            VStack {
                AnimatedDotsView()
                Spacer()
            }.opacity(0.5)
            VStack {
                header
                menuButtons
                Spacer()
                footer
            }
        }
    }

    private var header: some View {
        Image("AppTitle")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }

    private var menuButtons: some View {
        VStack(alignment: .leading) {
            Button {
                appState.startGame(mode: .classic)
            } label: {
                HStack(spacing: 0) {
                    Text("Classic Mode")
                                        .bold()
                                        .padding()
                    Image(systemName: "infinity")
                        .bold()
                        .padding()
                }
                
            }
            .buttonStyle(DottoButtonStyle(kind: .classic))
            .padding(10)
            
            Button {
                appState.startGame(mode: .arcade)
            } label: {
                Text("Arcade Mode")
                    .bold()
                    .padding()
            }
            .buttonStyle(DottoButtonStyle(kind: .arcade))
            .padding(10)
            
            Button {
                vm.selectedMode = .timed
            } label: {
                Text("Time Attack")
                    .bold()
                    .padding()
            }
            .buttonStyle(DottoButtonStyle(kind: .timeAttack))
            .padding(10)
            
            Button {
                appState.openSettings()
            } label: {
                Text("Options")
                    .bold()
                    .padding()
            }
            .buttonStyle(DottoButtonStyle(kind: .options))
            .padding(10)
        }
        .padding(.top, 8)
    }

    private var footer: some View {
        Text("SKLabs")
            .font(.footnote)
            .foregroundStyle(Color.white)
    }

    private func modeDescription(_ mode: GameMode) -> LocalizedStringResource {
        switch mode {
        case .classic:
            return LocalizedStringResource(stringLiteral: "No timer. Focus on accuracy.")
        case .timed:
            return LocalizedStringResource(stringLiteral: "Limited time to choose the new dot.")
        case .daily:
            return LocalizedStringResource(stringLiteral: "One attempt per day with a fixed seed.")
        case .arcade:
            return LocalizedStringResource(stringLiteral: "Level up!")
        }
    }
}

#Preview {
    MainMenuView()
}
