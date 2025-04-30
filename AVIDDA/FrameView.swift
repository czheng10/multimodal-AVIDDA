//
//  FrameView.swift
//  AVIDDA
//
//  Created by Cindy Zheng on 4/28/25.
//

import SwiftUI

struct FrameView: View {
    var image: CGImage?
    private let label = Text("frame")
    
    var body: some View {
        if let image = image {
            Image(image, scale:1.0, orientation: .up, label: label)
        }
        else {
            Color.white
        }
    }
}

#Preview {
    FrameView()
}
