import SwiftUI

struct TimerView: View {
    @EnvironmentObject var viewModel: TimerViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Timer View")
                    .font(.title)
                
                Button(viewModel.isRunning ? "Stop" : "Start") {
                    if viewModel.isRunning {
                        viewModel.stopTimer()
                    } else {
                        viewModel.startTimer()
                    }
                }
                .padding()
                .background(viewModel.isRunning ? Color.red : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .navigationTitle("Timer")
        }
    }
}