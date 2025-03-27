//
//  WorldClockView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//
import SwiftUI
import Kingfisher
import FirebaseAnalytics // Add Firebase import

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
                    // Updated title section with subtitle
                    VStack(spacing: 5) {
                        Text("World Clock")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        Text("Make the world your canvas")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Button(action: {
                        viewModel.showAddClockModal = true
                        // Analytics: Track tapping the "Add Clock" button
                        Analytics.logEvent("WorldClock_add_clock_tapped", parameters: [:])
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Clock")
                        }
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
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    ScrollView {
                        ZStack {
                            ForEach(viewModel.clocks) { clock in
                                ClockNodeView(
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
                                            // Analytics: Track dragging a clock (logged on change for continuous tracking)
                                            Analytics.logEvent("WorldClock_clock_dragged", parameters: [
                                                "clock_id": clock.id,
                                                "x_position": value.location.x,
                                                "y_position": value.location.y,
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
                                        // Analytics: Track opening the edit modal
                                        Analytics.logEvent("WorldClock_open_edit_clock", parameters: [
                                            "clock_id": clock.id,
                                            "timezone": clock.timezone,
                                            "location": timezoneLocation(from: clock.timezone) ?? "Unknown"
                                        ])
                                    }) {
                                        Label("Edit Timezone", systemImage: "pencil")
                                    }
                                    
                                    Button(action: {
                                        if let index = viewModel.clocks.firstIndex(where: { $0.id == clock.id }) {
                                            viewModel.deleteClock(at: IndexSet(integer: index))
                                            // Analytics: Track deleting a clock
                                            Analytics.logEvent("WorldClock_clock_deleted", parameters: [
                                                "clock_id": clock.id,
                                                "timezone": clock.timezone,
                                                "location": timezoneLocation(from: clock.timezone) ?? "Unknown"
                                            ])
                                        }
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        .frame(minHeight: 400)
                        .padding()
                    }
                    
                    Spacer()
                }
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
                // Analytics: Track screen view for WorldClockView
                Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                    AnalyticsParameterScreenName: "World Clock",
                    AnalyticsParameterScreenClass: "WorldClockView"
                ])
            }
        }
    }
    
    // Helper function to extract location from timezone identifier
    private func timezoneLocation(from identifier: String) -> String? {
        let parts = identifier.split(separator: "/")
        guard !parts.isEmpty, parts.count > 1 else { return nil }
        let locationPart = parts.last?.replacingOccurrences(of: "_", with: " ") ?? identifier
        return locationPart
    }
}

struct ClockNodeView: View {
    let clock: WorldClock
    let time: String
    let date: String
    let position: CGPoint
    
    var body: some View {
        ZStack {
            // Image or placeholder circle
            if let imageURL = clock.imageURL {
                KFImage(imageURL)
                    .placeholder {
                        ProgressView()
                            .frame(width: 180, height: 180)
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 180, height: 180)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 180, height: 180)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
            }
            
            // Text with semi-transparent background
            VStack(spacing: 2) {
                Text(timezoneName(from: clock.timezone))
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Text(time)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(date)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.5))
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
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    VStack(spacing: 15) {
                        TextField("Search Timezones", text: $searchText)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                            .padding(.horizontal)
                            .onChange(of: searchText) { newValue in
                                if !filteredTimezones.contains(selectedTimezone) && !filteredTimezones.isEmpty {
                                    selectedTimezone = filteredTimezones.first!
                                }
                            }
                        
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(filteredTimezones, id: \.self) { timezone in
                                    Button(action: {
                                        selectedTimezone = timezone
                                    }) {
                                        HStack {
                                            Text(timezoneName(from: timezone))
                                                .foregroundColor(selectedTimezone == timezone ? .red : .white)
                                                .padding(.vertical, 8)
                                                .padding(.horizontal)
                                            Spacer()
                                            if selectedTimezone == timezone {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.red)
                                            }
                                        }
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 300)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            dismiss()
                            // Analytics: Track canceling the add clock action
                            Analytics.logEvent("WorldClock_add_clock_cancel_tapped", parameters: [:])
                        }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.5))
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            viewModel.addClock(timezone: selectedTimezone)
                            dismiss()
                            // Analytics: Track adding a new clock with location
                            Analytics.logEvent("WorldClock_clock_added", parameters: [
                                "timezone": selectedTimezone,
                                "location": timezoneLocation(from: selectedTimezone) ?? "Unknown"
                            ])
                        }) {
                            Text("Add Clock")
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
                        .disabled(viewModel.clocks.contains(where: { $0.timezone == selectedTimezone }))
                        .opacity(viewModel.clocks.contains(where: { $0.timezone == selectedTimezone }) ? 0.5 : 1.0)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Analytics: Track screen view for AddClockView
                Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                    AnalyticsParameterScreenName: "Add Clock",
                    AnalyticsParameterScreenClass: "AddClockView"
                ])
            }
        }
    }
    
    // Helper function to extract location from timezone identifier
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
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    VStack(spacing: 15) {
                        TextField("Search Timezones", text: $searchText)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                            .padding(.horizontal)
                            .onChange(of: searchText) { newValue in
                                if !filteredTimezones.contains(selectedTimezone) && !filteredTimezones.isEmpty {
                                    selectedTimezone = filteredTimezones.first!
                                }
                            }
                        
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(filteredTimezones, id: \.self) { timezone in
                                    Button(action: {
                                        selectedTimezone = timezone
                                    }) {
                                        HStack {
                                            Text(timezoneName(from: timezone))
                                                .foregroundColor(selectedTimezone == timezone ? .red : .white)
                                                .padding(.vertical, 8)
                                                .padding(.horizontal)
                                            Spacer()
                                            if selectedTimezone == timezone {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.red)
                                            }
                                        }
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 300)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            dismiss()
                            // Analytics: Track canceling the edit clock action
                            Analytics.logEvent("WorldClock_edit_clock_cancel_tapped", parameters: [:])
                        }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.5))
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            viewModel.updateClockTimezone(id: clock.id, newTimezone: selectedTimezone)
                            dismiss()
                            // Analytics: Track updating a clock's timezone with location
                            Analytics.logEvent("WorldClock_clock_updated", parameters: [
                                "clock_id": clock.id,
                                "old_timezone": clock.timezone,
                                "new_timezone": selectedTimezone,
                                "old_location": timezoneLocation(from: clock.timezone) ?? "Unknown",
                                "new_location": timezoneLocation(from: selectedTimezone) ?? "Unknown"
                            ])
                        }) {
                            Text("Update Clock")
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
                        .disabled(viewModel.clocks.contains(where: { $0.timezone == selectedTimezone && $0.id != clock.id }))
                        .opacity(viewModel.clocks.contains(where: { $0.timezone == selectedTimezone && $0.id != clock.id }) ? 0.5 : 1.0)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Analytics: Track screen view for EditClockView
                Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                    AnalyticsParameterScreenName: "Edit Clock",
                    AnalyticsParameterScreenClass: "EditClockView"
                ])
            }
        }
    }
    
    // Helper function to extract location from timezone identifier
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

struct WorldClockView_Previews: PreviewProvider {
    static var previews: some View {
        WorldClockView()
            .environmentObject(WorldClockViewModel())
            .preferredColorScheme(.dark)
    }
}
