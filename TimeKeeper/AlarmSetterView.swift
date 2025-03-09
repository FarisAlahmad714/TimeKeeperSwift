import SwiftUI

struct AlarmSetterView: View {
    @EnvironmentObject var viewModel: AlarmViewModel
    @State private var selectedTime: Date = Date()
    @State private var isDragging: Bool = false
    @State private var showAlarmsView: Bool = false
    @State private var sunOpacity: Double = 0.5
    @State private var moonOpacity: Double = 0.5
    
    private let calendar = Calendar.current
    private let startOfDay = Calendar.current.startOfDay(for: Date())
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    private var totalMinutesInDay: Int {
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return calendar.dateComponents([.minute], from: startOfDay, to: endOfDay).minute!
    }
    
    private var backgroundColors: [Color] {
        let hour = calendar.component(.hour, from: selectedTime)
        switch hour {
        case 0..<6: return [.black, .blue.opacity(0.5)]
        case 6..<12: return [.purple.opacity(0.7), .orange.opacity(0.5)]
        case 12..<18: return [.blue.opacity(0.8), .cyan.opacity(0.5)]
        case 18..<21: return [.orange, .red.opacity(0.7)]
        default: return [.black, .blue.opacity(0.5)]
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: backgroundColors, startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                CloudView()
                BirdView()
                
                IslandView()
                
                GaugeView(selectedTime: selectedTime, totalMinutesInDay: totalMinutesInDay)
                
                VStack(spacing: 30) {
                    Text(timeFormatter.string(from: selectedTime))
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                    
                    GeometryReader { geometry in
                        let width = geometry.size.width
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 20)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 30, height: 30)
                                .offset(x: sliderOffset(width: width))
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            isDragging = true
                                            let newMinutes = max(0, min(Double(totalMinutesInDay - 1), (value.location.x / width) * Double(totalMinutesInDay)))
                                            selectedTime = calendar.date(byAdding: .minute, value: Int(newMinutes), to: startOfDay)!
                                        }
                                        .onEnded { _ in isDragging = false }
                                )
                        }
                    }
                    .frame(height: 40)
                    .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        Button("Set Alarm") {
                            viewModel.alarmTime = selectedTime
                            viewModel.activeModal = .choice
                            showAlarmsView = true
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(10)
                        
                        Button("View Alarms") {
                            showAlarmsView = true
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(10)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAlarmsView) {
                AlarmsView()
            }
            .onChange(of: selectedTime) { newTime in
                let hour = calendar.component(.hour, from: newTime)
                switch hour {
                case 6..<12:
                    sunOpacity = 1.0
                    moonOpacity = 0.0
                case 18..<21:
                    sunOpacity = 0.5
                    moonOpacity = 0.5
                case 21..<24, 0..<6:
                    sunOpacity = 0.0
                    moonOpacity = 1.0
                default:
                    sunOpacity = 0.5
                    moonOpacity = 0.5
                }
            }
        }
    }
    
    private func sliderOffset(width: CGFloat) -> CGFloat {
        let minuteWidth = width / Double(totalMinutesInDay)
        let minutesSinceMidnight = calendar.dateComponents([.minute], from: startOfDay, to: selectedTime).minute!
        return CGFloat(minutesSinceMidnight) * minuteWidth - width / 2
    }
}
