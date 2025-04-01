import SwiftUI
import Kingfisher
import FirebaseAnalytics

struct WorldClockView: View {
    @EnvironmentObject var viewModel: WorldClockViewModel
    @State private var draggedClock: WorldClock?
    @State private var editingClock: WorldClock?
    @State private var showingEditModal = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    VStack(spacing: 5) {
                        Text("World Clock")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Make the world your canvas")
                            .font(.system(size: 18, weight: .light, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 20)
                    
                    Button(action: {
                        viewModel.showAddClockModal = true
                        Analytics.logEvent("WorldClock_add_clock_tapped", parameters: [:])
                        let impactMed = UIImpactFeedbackGenerator(style: .medium)
                        impactMed.impactOccurred()
                    }) {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(size: 18))
                            Text("Add Clock")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 25)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(red: 0.9, green: 0.2, blue: 0.3), Color(red: 1.0, green: 0.4, blue: 0.1)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(30)
                    }
                    .padding(.horizontal)
                    
                    clockCanvasView
                        .frame(maxHeight: .infinity)
                }
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showAddClockModal) {
                AddClockView()
            }
            .sheet(isPresented: $showingEditModal) {
                if let clockToEdit = editingClock {
                    EditClockView(clock: clockToEdit)
                }
            }
            .onAppear {
                Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                    AnalyticsParameterScreenName: "World Clock",
                    AnalyticsParameterScreenClass: "WorldClockView"
                ])
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var clockCanvasView: some View {
        ScrollView {
            ZStack {
                Rectangle()
                    .fill(Color(red: 0.08, green: 0.08, blue: 0.1))
                    .cornerRadius(15)
                
                if viewModel.clocks.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "globe")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("No clocks added yet")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("Tap 'Add Clock' to get started")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding()
                }
                
                ForEach(viewModel.clocks) { clock in
                    CleanClockNodeView(
                        clock: clock,
                        time: viewModel.timeForTimezone(clock.timezone),
                        date: viewModel.dateForTimezone(clock.timezone),
                        position: clock.position
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                draggedClock = clock
                                viewModel.updateClockPosition(clock, position: value.location)
                                Analytics.logEvent("WorldClock_clock_dragged", parameters: [
                                    "clock_id": clock.id,
                                    "location": timezoneLocation(from: clock.timezone) ?? "Unknown"
                                ])
                            }
                            .onEnded { _ in
                                draggedClock = nil
                            }
                    )
                    .contextMenu {
                        Button(action: {
                            editingClock = clock
                            showingEditModal = true
                            Analytics.logEvent("WorldClock_open_edit_clock", parameters: [
                                "clock_id": clock.id,
                                "timezone": clock.timezone
                            ])
                        }) {
                            Label("Edit Timezone", systemImage: "pencil")
                        }
                        
                        Button(action: {
                            if let index = viewModel.clocks.firstIndex(where: { $0.id == clock.id }) {
                                viewModel.deleteClock(at: IndexSet(integer: index))
                                Analytics.logEvent("WorldClock_clock_deleted", parameters: [
                                    "clock_id": clock.id,
                                    "timezone": clock.timezone
                                ])
                            }
                        }) {
                            Label("Delete", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .frame(width: UIScreen.main.bounds.width - 20)
            .frame(height: min(CGFloat(viewModel.clocks.count) * 180, UIScreen.main.bounds.height * 0.8))
            .padding(10)
        }
        .padding(.horizontal, 0)
    }
    
    private func timezoneLocation(from identifier: String) -> String? {
        let parts = identifier.split(separator: "/")
        guard !parts.isEmpty, parts.count > 1 else { return nil }
        let locationPart = parts.last?.replacingOccurrences(of: "_", with: " ") ?? identifier
        return locationPart
    }
}

struct CleanClockNodeView: View {
    let clock: WorldClock
    let time: String
    let date: String
    let position: CGPoint
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.2, green: 0.2, blue: 0.25),
                            Color(red: 0.1, green: 0.1, blue: 0.15)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 150, height: 150)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            if let imageURL = clock.imageURL {
                KFImage(imageURL)
                    .placeholder {
                        ProgressView()
                            .frame(width: 150, height: 150)
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
            }
            
            Circle()
                .fill(Color.black.opacity(0.3))
                .frame(width: 150, height: 150)
            
            VStack(spacing: 1) {
                Text(timezoneName(from: clock.timezone))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                
                Text(time)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(date)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .position(position)
    }
    
    private func timezoneName(from identifier: String) -> String {
        identifier.split(separator: "/").last?.replacingOccurrences(of: "_", with: " ") ?? identifier
    }
}

struct AddClockView: View {
    @EnvironmentObject var viewModel: WorldClockViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedTimezone = TimeZone.current.identifier
    @State private var searchText = ""
    
    var filteredTimezones: [String] {
        if searchText.isEmpty {
            return TimeZone.knownTimeZoneIdentifiers
        } else {
            return TimeZone.knownTimeZoneIdentifiers.filter {
                timezoneName(from: $0).lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("Add Clock")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    VStack(spacing: 15) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .padding(.leading, 12)
                            
                            TextField("Search Timezones", text: $searchText)
                                .foregroundColor(.white)
                                .padding(.vertical, 14)
                                .onChange(of: searchText) { newValue in
                                    if !filteredTimezones.contains(selectedTimezone) && !filteredTimezones.isEmpty {
                                        selectedTimezone = filteredTimezones.first!
                                    }
                                }
                        }
                        .background(Color(red: 0.15, green: 0.15, blue: 0.2))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        ScrollView {
                            VStack(spacing: 6) {
                                ForEach(filteredTimezones, id: \.self) { timezone in
                                    Button(action: {
                                        selectedTimezone = timezone
                                    }) {
                                        HStack {
                                            Text(timezoneName(from: timezone))
                                                .font(.system(size: 16, design: .rounded))
                                                .foregroundColor(selectedTimezone == timezone ? Color(red: 1.0, green: 0.4, blue: 0.3) : .white)
                                                .padding(.vertical, 12)
                                                .padding(.horizontal)
                                            
                                            Spacer()
                                            
                                            if selectedTimezone == timezone {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.3))
                                            }
                                        }
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 300)
                    }
                    .padding()
                    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            dismiss()
                            Analytics.logEvent("WorldClock_add_clock_cancel_tapped", parameters: [:])
                        }) {
                            Text("Cancel")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(20)
                        }
                        
                        Button(action: {
                            viewModel.addClock(timezone: selectedTimezone)
                            dismiss()
                            Analytics.logEvent("WorldClock_clock_added", parameters: [
                                "timezone": selectedTimezone,
                                "location": timezoneLocation(from: selectedTimezone) ?? "Unknown"
                            ])
                        }) {
                            Text("Add Clock")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(red: 0.9, green: 0.2, blue: 0.3), Color(red: 1.0, green: 0.4, blue: 0.1)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                        }
                        .disabled(viewModel.clocks.contains(where: { $0.timezone == selectedTimezone }))
                        .opacity(viewModel.clocks.contains(where: { $0.timezone == selectedTimezone }) ? 0.5 : 1.0)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func timezoneLocation(from identifier: String) -> String? {
        let parts = identifier.split(separator: "/")
        guard !parts.isEmpty, parts.count > 1 else { return nil }
        let locationPart = parts.last?.replacingOccurrences(of: "_", with: " ") ?? identifier
        return locationPart
    }
    
    private func timezoneName(from identifier: String) -> String {
        identifier.split(separator: "/").last?.replacingOccurrences(of: "_", with: " ") ?? identifier
    }
}

struct EditClockView: View {
    @EnvironmentObject var viewModel: WorldClockViewModel
    @Environment(\.dismiss) var dismiss
    let clock: WorldClock
    @State private var selectedTimezone: String
    @State private var searchText = ""
    
    init(clock: WorldClock) {
        self.clock = clock
        self._selectedTimezone = State(initialValue: clock.timezone)
    }
    
    var filteredTimezones: [String] {
        if searchText.isEmpty {
            return TimeZone.knownTimeZoneIdentifiers
        } else {
            return TimeZone.knownTimeZoneIdentifiers.filter {
                timezoneName(from: $0).lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("Edit Clock")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    VStack(spacing: 15) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .padding(.leading, 12)
                            
                            TextField("Search Timezones", text: $searchText)
                                .foregroundColor(.white)
                                .padding(.vertical, 14)
                                .onChange(of: searchText) { newValue in
                                    if !filteredTimezones.contains(selectedTimezone) && !filteredTimezones.isEmpty {
                                        selectedTimezone = filteredTimezones.first!
                                    }
                                }
                        }
                        .background(Color(red: 0.15, green: 0.15, blue: 0.2))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        ScrollView {
                            VStack(spacing: 6) {
                                ForEach(filteredTimezones, id: \.self) { timezone in
                                    Button(action: {
                                        selectedTimezone = timezone
                                    }) {
                                        HStack {
                                            Text(timezoneName(from: timezone))
                                                .font(.system(size: 16, design: .rounded))
                                                .foregroundColor(selectedTimezone == timezone ? Color(red: 0.3, green: 0.6, blue: 1.0) : .white)
                                                .padding(.vertical, 12)
                                                .padding(.horizontal)
                                            
                                            Spacer()
                                            
                                            if selectedTimezone == timezone {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(Color(red: 0.3, green: 0.6, blue: 1.0))
                                            }
                                        }
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 300)
                    }
                    .padding()
                    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            dismiss()
                            Analytics.logEvent("WorldClock_edit_clock_cancel_tapped", parameters: [:])
                        }) {
                            Text("Cancel")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(20)
                        }
                        
                        Button(action: {
                            viewModel.updateClockTimezone(id: clock.id, newTimezone: selectedTimezone)
                            dismiss()
                            Analytics.logEvent("WorldClock_clock_updated", parameters: [
                                "clock_id": clock.id,
                                "old_timezone": clock.timezone,
                                "new_timezone": selectedTimezone
                            ])
                        }) {
                            Text("Update Clock")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(red: 0.3, green: 0.6, blue: 1.0), Color(red: 0.5, green: 0.3, blue: 0.9)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                        }
                        .disabled(viewModel.clocks.contains(where: { $0.timezone == selectedTimezone && $0.id != clock.id }))
                        .opacity(viewModel.clocks.contains(where: { $0.timezone == selectedTimezone && $0.id != clock.id }) ? 0.5 : 1.0)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func timezoneLocation(from identifier: String) -> String? {
        let parts = identifier.split(separator: "/")
        guard !parts.isEmpty, parts.count > 1 else { return nil }
        let locationPart = parts.last?.replacingOccurrences(of: "_", with: " ") ?? identifier
        return locationPart
    }
    
    private func timezoneName(from identifier: String) -> String {
        identifier.split(separator: "/").last?.replacingOccurrences(of: "_", with: " ") ?? identifier
    }
}
