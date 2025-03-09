import SwiftUI

struct AlarmSetterView: View {
    @EnvironmentObject var viewModel: AlarmViewModel
    @State private var selectedTime: Date = Date()
    @State private var isDragging = false
    @State private var showAlarmsView = false
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    private var minutesSinceMidnight: Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: selectedTime)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return Double(hour * 60 + minute)
    }
    
    private var backgroundGradient: LinearGradient {
        let hour = Calendar.current.component(.hour, from: selectedTime)
        let colors: [Color]
        
        switch hour {
        case 6..<12:
            colors = [Color.blue.opacity(0.8), Color.yellow.opacity(0.3)]
        case 12..<18:
            colors = [Color.blue, Color.yellow.opacity(0.5)]
        case 18..<21:
            colors = [Color.orange, Color.purple.opacity(0.7)]
        case 21..<24, 0..<6:
            colors = [Color.black, Color.blue.opacity(0.5)]
        default:
            colors = [Color.pink.opacity(0.7), Color.blue.opacity(0.5)]
        }
        
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                    .edgesIgnoringSafeArea(.all)
                    .animation(.easeInOut(duration: 1.0), value: Calendar.current.component(.hour, from: selectedTime))
                
                VStack(spacing: 40) {
                    Text(timeFormatter.string(from: selectedTime))
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    GeometryReader { geometry in
                        let width = geometry.size.width
                        let totalMinutesInDay = 24.0 * 60.0
                        let minuteWidth = width / totalMinutesInDay
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 20)
                                .overlay(
                                    HStack(spacing: 0) {
                                        ForEach(0..<24) { hour in
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.5))
                                                .frame(width: 1, height: hour % 6 == 0 ? 30 : 15)
                                                .offset(x: CGFloat(hour * 60) * minuteWidth)
                                        }
                                    }
                                )
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 30, height: 30)
                                .offset(x: CGFloat(minutesSinceMidnight) * minuteWidth - width / 2)
                                .animation(.spring(), value: minutesSinceMidnight)
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isDragging = true
                                    let dragX = value.location.x
                                    let newMinutes = max(0, min(totalMinutesInDay - 1, (dragX / width) * totalMinutesInDay))
                                    updateTime(minutes: Int(newMinutes))
                                }
                                .onEnded { _ in
                                    isDragging = false
                                }
                        )
                    }
                    .frame(height: 40)
                    .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            viewModel.alarmTime = selectedTime
                            viewModel.alarmDate = Calendar.current.startOfDay(for: Date())
                            print("Setting activeModal to .choice with alarmTime: \(viewModel.alarmTime)")
                            viewModel.activeModal = .choice
                            showAlarmsView = true // Present AlarmsView to handle the modal
                        }) {
                            Text("Set Alarm")
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
                                .cornerRadius(10)
                                .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        
                        Button(action: {
                            showAlarmsView = true
                        }) {
                            Text("View Alarms")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.5))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAlarmsView) {
                AlarmsView()
            }
        }
    }
    
    private func updateTime(minutes: Int) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        if let newTime = calendar.date(byAdding: .minute, value: minutes, to: startOfDay) {
            selectedTime = newTime
        }
    }
}

struct AlarmSetterView_Previews: PreviewProvider {
    static var previews: some View {
        AlarmSetterView()
            .environmentObject(AlarmViewModel())
            .preferredColorScheme(.dark)
    }
}
