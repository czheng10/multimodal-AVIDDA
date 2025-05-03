//
//  ContentView.swift
//  AVIDDA
//
//  Created by Cindy Zheng on 4/28/25.
//

import SwiftUI
import WebKit
import AVFoundation
import AudioToolbox

struct GIFView: UIViewRepresentable {
    let gifName: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        guard let url = Bundle.main.url(forResource: gifName, withExtension: "gif") else {
            print("Error: Could not find GIF file named \(gifName).gif")
            return webView
        }
        
        do {
            let data = try Data(contentsOf: url)
            webView.load(
                data,
                mimeType: "image/gif",
                characterEncodingName: "UTF-8",
                baseURL: url.deletingLastPathComponent()
            )
        } catch {
            print("Error loading GIF data: \(error.localizedDescription)")
        }
        
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.reload()
    }
}

struct ContentView: View {
    @StateObject private var model = FrameHandler()
    @State private var showGIFError = false
    @State private var blink = 0.6
    
    var body: some View {
        ZStack {
            VStack {
                Text("AVIDDA")
                    .fontWeight(.bold)
                    .font(.system(size: 20))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
                
                HStack {
                    
                    Group {
                        if model.isRecording {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 12, height: 12)
                                
                                Text("REC")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(8)
                            .background(Color.gray.opacity(0.4))
                            .cornerRadius(20)
                        } else {
                            VStack{
                                Text("Please turn up your audio for proper alerts.")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .opacity(blink)
                                    .onAppear {
                                        withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
                                            blink = 1.0
                                        }
                                    }
                                Text("Click Start Recording to begin detection")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .opacity(blink)
                                    .onAppear {
                                        withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
                                            blink = 1.0
                                        }
                                    }
                                }
                        }
                    }
                    .frame(height: 32)
                    .padding(.leading, 8)
                    Spacer()
                }
                .padding(.leading, 32)
                .padding(.top, 5)
                
                ZStack {
                    if let _ = UIImage(named: "map.gif") {
                        GIFView(gifName: "map")
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 300, height: 570)
                            .background(Color.clear)
                            .cornerRadius(20)
                            .padding(.trailing, 50)
                        
                    } else {
                        Color.clear
                            .frame(width: 300, height: 600)
                            .cornerRadius(20)
                            .onAppear {
                                showGIFError = true
                            }
                    }
                    
                    FrameView(image: model.frame)
                        .frame(maxHeight: 400)
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(15)
                        .padding(.trailing, 30)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.top, 180)
                    
                    AlertView(isPresented: $model.showAlert) {
                        model.dismissAlert()
                    }

                }
                
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
                .padding(.bottom, 20)
            }
        }
    }
}

#Preview {
    ContentView()
}

