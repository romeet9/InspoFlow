import SwiftUI

struct ShaderAnimationView: View {
    @State private var startTime = Date()
    
    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSince(startTime)
            
            Rectangle()
                .foregroundStyle(.black)
                .visualEffect { content, proxy in
                    content
                        .colorEffect(
                            ShaderLibrary.warpSpeed(
                                .float2(proxy.size),
                                .float(time)
                            )
                        )
                }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ShaderAnimationView()
}
