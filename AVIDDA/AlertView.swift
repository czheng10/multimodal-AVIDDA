//
//  AlertView.swift
//  AVIDDA
//
//  Created by Cindy Zheng on 5/3/25.
//

import SwiftUI

struct AlertView: View {
    @Binding var isPresented: Bool
    var dismissAction: () -> Void
    
    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("🚨 Drowsiness Detected 🚨")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Our system has detected signs of drowsiness. Please pull over until you are fully alert.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        dismissAction()
                    }) {
                        Text("I'm alert now")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.6))
                            .cornerRadius(10)
                    }
                }
                .padding()
                .frame(width: 300)
                .background(Color.red.opacity(0.6))
                .cornerRadius(15)
                .shadow(radius: 10)
                
            }
            .transition(.opacity)
            .zIndex(1)
        }
    }
}
