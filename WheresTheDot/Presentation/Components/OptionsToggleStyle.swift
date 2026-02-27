//
//  OptionsToggleStyle.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 16/02/26.
//

import Foundation
import SwiftUI

struct OptionsToggleStyle: ToggleStyle {
    enum ButtonType {
        case circle
        case square
    }
    
    let style: ButtonType
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        Button{
            configuration.isOn.toggle()
        } label: {
            Label {
                configuration.label
            } icon: {
                if !configuration.isOn {
                    Image(systemName: "square")
                } else {
                    Image(systemName: "checkmark.square")
                }
            }
        }.buttonStyle(.plain)
        .saturation(isEnabled ? 1 : 0)
    }
}

struct GlassToggleView: View {
    @State private var isEnabled = false

    var body: some View {
        VStack {
            Toggle("Glass Toggle", isOn: $isEnabled)
                .padding()
                .toggleStyle(.switch)
                .glassEffect()
                .padding()
                
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.3)) // Background to see the glass effect
    }
}

#Preview {
    @Previewable @State var isOn = false
    VStack {
        GlassToggleView()
    }.background(Color.black)
}
