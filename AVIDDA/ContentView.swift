//
//  ContentView.swift
//  AVIDDA
//
//  Created by Cindy Zheng on 4/28/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var model = FrameHandler()
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                if model.isRecording {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                        
                        Text("REC")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.4))
                    .cornerRadius(20)
                    .padding(.top, 8)
                    .padding(.leading, 8)
                }
                
                // Camera feed
                FrameView(image: model.frame)
                    .frame(maxWidth: .infinity, maxHeight: 600)
                    .background(Color.gray)
                    .cornerRadius(8)
                    .padding()
                
            }.padding(.top, 20)
            
            
            
            VStack {
                Spacer()
                
                Button(action: {
                    model.toggleRecording()
                }) {
                    Text(model.isRecording ? "Stop Recording" : "Start Recording")
                        .padding()
                        .background(model.isRecording ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .opacity(1)
                }.frame(maxWidth: .infinity)
                
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}

