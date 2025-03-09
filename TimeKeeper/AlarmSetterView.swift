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
    
    private let calendar = Calendar.current
    private let startOfDay: Date = Calendar.current.startOfDay(for: Date())
    
    // Total minutes in the day, accounting for DST
    private var totalMinutesInDay: Int {
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return calendar.dateComponents([.minute], from: startOfDay, to: endOfDay).minute!
    }
    
    // Slider progress (0.0 to 1.0)
    private var sliderProgress: Double {
        let minutesSinceMidnight = calendar.dateComponents([.minute], from: startOfDay, to: selectedTime).minute ?? 0
        return Double(minutesSinceMidnight) / Double(totalMinutesInDay)
    }
    
    // Check if it's night time (for stars)
    private var isNight: Bool {
        let hour = calendar.component(.hour, from: selectedTime)
        return hour >= 21 || hour < 6
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.black.opacity(0.5)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                // Stars during night time
                if isNight {
                    Canvas { context, size in
                        for _ in 0..<50 {
                            let x = CGFloat.random(in: 0...size.width)
                            let y = CGFloat.random(in: 0...size.height)
                            let starSize = CGFloat.random(in: 1...3)
                            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: starSize, height: starSize)), with: .color(.white.opacity(0.7)))
                        }
                    }
                }
                
                // Clouds
                CloudView(speed: 20, yPosition: 50)
                CloudView(speed: 30, yPosition: 100)
                
                // Birds
                BirdView()
                BirdView().offset(y: 30)
                
                // Island
                IslandView()
                    .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 100)
                
                // 90° Right-Angle Shape (replacing GaugeView)
                RightAngleShape(progress: sliderProgress)
                    .stroke(LinearGradient(gradient: Gradient(colors: [Color.orange, Color.blue]), startPoint: .leading, endPoint: .trailing), lineWidth: 5)
                    .frame(width: 200, height: 200)
                    .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
                
                // Time display
                Text(timeFormatter.string(from: selectedTime))
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                    .position(x: UIScreen.main.bounds.width / 2, y: 100)
                
                // Custom slider
                GeometryReader { geometry in
                    let width = geometry.size.width
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 20)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 30, height: 30)
                            .offset(x: (CGFloat(sliderProgress) * width) - width / 2)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        isDragging = true
                                        let dragX = max(0, min(value.location.x, width))
                                        let newMinutes = Int((dragX / width) * Double(totalMinutesInDay))
                                        selectedTime = calendar.date(byAdding: .minute, value: newMinutes, to: startOfDay)!
                                    }
                                    .onEnded { _ in
                                        isDragging = false
                                    }
                            )
                    }
                }
                .frame(height: 40)
                .padding(.horizontal)
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 50)
                
                // Buttons
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.alarmTime = selectedTime
                        viewModel.alarmDate = calendar.startOfDay(for: Date())
                        viewModel.activeModal = .choice
                        showAlarmsView = true
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
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
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
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 150)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAlarmsView) {
                AlarmsView()
            }
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
