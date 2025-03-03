import SwiftUI

struct TimerView: View {
    @EnvironmentObject var viewModel: TimerViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Timer")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        TimerHistoryView(viewModel: viewModel)
                        
                        TimerCountdownView(viewModel: viewModel)
                        
                        if !viewModel.isRunning {
                            TimerInputView(viewModel: viewModel)
                        }
                        
                        TimerControlsView(viewModel: viewModel)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct TimerHistoryView: View {
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        if !viewModel.timerHistory.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("History")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(.top)
                
                ForEach(viewModel.timerHistory) { item in
                    HistoryItemRow(item: item, viewModel: viewModel)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct HistoryItemRow: View {
    let item: TimerHistoryItem
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        HStack {
            Text(item.label)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(item.title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Button(action: {
                if let index = viewModel.timerHistory.firstIndex(where: { $0.id == item.id }) {
                    viewModel.timerHistory.remove(at: index)
                    viewModel.saveHistory()
                }
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(.leading, 8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                if let index = viewModel.timerHistory.firstIndex(where: { $0.id == item.id }) {
                    viewModel.timerHistory.remove(at: index)
                    viewModel.saveHistory()
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct TimerCountdownView: View {
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                .frame(width: 200, height: 200)
            
            Circle()
                .trim(from: 0, to: viewModel.isRunning ? CGFloat(viewModel.remainingTime / viewModel.initialDuration) : 0)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.red, Color.orange]),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: viewModel.remainingTime)
            
            Text(viewModel.formattedTime(viewModel.isRunning ? viewModel.remainingTime : TimeInterval(viewModel.hours * 3600 + viewModel.minutes * 60 + viewModel.seconds)))
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(.red)
        }
        .padding()
        .opacity(viewModel.showAnimation ? 1.0 : 0.8)
        .scaleEffect(viewModel.showAnimation ? 1.0 : 0.9)
        .animation(.spring(), value: viewModel.showAnimation)
    }
}

struct TimerInputView: View {
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            TextField("Label", text: $viewModel.label)
                .foregroundColor(.white)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
            
            HStack(spacing: 10) {
                Picker("Hours", selection: $viewModel.hours) {
                    ForEach(0..<24) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(width: 100)
                .clipped()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                
                Picker("Minutes", selection: $viewModel.minutes) {
                    ForEach(0..<60) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(width: 100)
                .clipped()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                
                Picker("Seconds", selection: $viewModel.seconds) {
                    ForEach(0..<60) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(width: 100)
                .clipped()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }
}

struct TimerControlsView: View {
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: {
                if viewModel.isRunning {
                    viewModel.stopTimer()
                } else {
                    viewModel.startTimer()
                }
            }) {
                Text(viewModel.isRunning ? "Stop" : "Start")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: viewModel.isRunning ? [Color.red, Color.orange] : [Color.green, Color.cyan]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(50)
                    .shadow(color: (viewModel.isRunning ? Color.red : Color.green).opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .disabled(!viewModel.isRunning && viewModel.hours == 0 && viewModel.minutes == 0 && viewModel.seconds == 0)
            .opacity(!viewModel.isRunning && viewModel.hours == 0 && viewModel.minutes == 0 && viewModel.seconds == 0 ? 0.5 : 1.0)
            
            Button(action: {
                viewModel.resetTimer()
            }) {
                Text("Reset")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.red, Color.orange]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(50)
                    .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .disabled(viewModel.isRunning || (viewModel.hours == 0 && viewModel.minutes == 0 && viewModel.seconds == 0))
            .opacity(viewModel.isRunning || (viewModel.hours == 0 && viewModel.minutes == 0 && viewModel.seconds == 0) ? 0.5 : 1.0)
        }
        .padding(.horizontal)
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView()
            .environmentObject(TimerViewModel())
            .preferredColorScheme(.dark)
    }
}
