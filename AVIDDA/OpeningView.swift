//
//  OpeningView.swift
//  AVIDDA
//
//  Created by Cindy Zheng on 5/3/25.
//

import SwiftUI

struct OpeningView: View {
    @State private var currentPage = 0
    @State private var showContentView = false
    
    var body: some View {
        ZStack {
            if showContentView {
                ContentView()
            } else {
                TabView(selection: $currentPage) {
                    // Logo Screen
                    VStack {
                        Spacer()
                        
                        Image("logo") // Your logo asset
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(15)
                            .frame(width: 180, height: 180)
                            .padding(.bottom, 40)
                        
                        Text("Thank you for contributing to a safer driving experience")
                            .font(.title3)
                            .fontWeight(.light)
                            .multilineTextAlignment(.center)
    
                        Spacer()
                        
                        Button(action: {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                currentPage = 1
                            }
                        }) {
                            Text("Continue")
                                .foregroundColor(.gray)
                                .font(.body)
                        }
                        .padding(.bottom, 40)
                    }
                    .tag(0)
                    
                    // Instructions Screen
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Text("For proper detection, please:")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            InstructionRow(
                                icon: "camera.fill",
                                text: "Position phone facing the driver"
                            )
                            
                            InstructionRow(
                                icon: "person.crop.rectangle",
                                text: "Capture the driver from the shoulders up"
                            )
                            
                            InstructionRow(
                                icon: "speaker.wave.3.fill",
                                text: "Turn up device volume"
                            )
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                showContentView = true
                            }
                        }) {
                            Text("Get Started")
                                .foregroundColor(.gray)
                                .font(.body)
                        }
                        .padding(.bottom, 40)
                    }
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .transition(.slide)
            }
        }
    }
}

struct InstructionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    OpeningView()
}
