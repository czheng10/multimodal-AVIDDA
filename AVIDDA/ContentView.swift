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
        VStack {
            Text("AVIDDA")
                .fontWeight(.bold)
                .font(.system(size: 20))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 20)
            
            HStack {
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
                } else {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 12, height: 12)
                        
                        Text("REC")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.clear)
                    }
                    .padding(8)
                    .background(Color.clear)
                    .cornerRadius(20)
                }
                Spacer()
            }
            .padding(.leading, 32)
            
            FrameView(image: model.frame)
                .frame(maxWidth: .infinity, maxHeight: 550)
                .aspectRatio(contentMode: .fit)
                .background(Color.gray)
                .cornerRadius(20)
                .padding(20)
            
            Button(action: {
                model.toggleRecording()
            }) {
                Text(model.isRecording ? "Stop Recording" : "Start Recording")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(model.isRecording ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    ContentView()
}

