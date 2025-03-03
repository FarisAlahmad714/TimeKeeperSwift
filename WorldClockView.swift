///
//  WorldClockView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//

import SwiftUI

struct WorldClockView: View {
    @EnvironmentObject var viewModel: WorldClockViewModel
    @State private var draggedClock: WorldClock?
    @State private var editingClock: WorldClock? // For editing an existing clock
    @State private var showingEditModal = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                VStack(spacing: 20) {
                    // Header
                    Text("World Clock")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Add Clock Button
                    Button(action: {
                        viewModel.showAddClockModal = true
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
                    
                    // Node-like Clocks
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
                                        }
                                        .onEnded { _ in
                                            draggedClock = nil
                                        }
                                )
                                .contextMenu {
                                    Button(action: {
                                        editingClock = clock
                                        showingEditModal = true
                                    }) {
                                        Label("Edit Timezone", systemImage: "pencil")
                                    }
                                    
                                    Button(action: {
                                        if let index = viewModel.clocks.firstIndex(where: { $0.id == clock.id }) {
                                            viewModel.deleteClock(at: IndexSet(integer: index))
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
        }
    }
    
    private func timezoneName(from identifier: String) -> String {
        identifier.split(separator: "/").last?.replacingOccurrences(of: "_", with: " ") ?? identifier
    }
}

struct ClockNodeView: View {
    let clock: WorldClock
    let time: String
    let date: String
    let position: CGPoint
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 120, height: 120)
                .shadow(color: Color.white.opacity(0.3), radius: 5, x: 0, y: 3)
            
            VStack(spacing: 5) {
                Text(timezoneName(from: clock.timezone))
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(time)
                    .font(.title2)
                    .foregroundColor(.red)
                
                Text(date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
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
                    // Header
                    Text("Add Clock")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Timezone Picker Card
                    VStack(spacing: 15) {
                        // Search Bar
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
                                // Ensure selectedTimezone is valid after filtering
                                if !filteredTimezones.contains(selectedTimezone) && !filteredTimezones.isEmpty {
                                    selectedTimezone = filteredTimezones.first!
                                }
                            }
                        
                        // Timezone Picker (Using List instead of Wheel)
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
                        .frame(maxHeight: 300) // Limit height to avoid taking up too much space
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // Action Buttons
                    HStack(spacing: 20) {
                        Button(action: {
                            dismiss()
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
        }
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
                    // Header
                    Text("Edit Clock")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Timezone Picker Card
                    VStack(spacing: 15) {
                        // Search Bar
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
                        
                        // Timezone Picker
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
                    
                    // Action Buttons
                    HStack(spacing: 20) {
                        Button(action: {
                            dismiss()
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
                            if let index = viewModel.clocks.firstIndex(where: { $0.id == clock.id }) {
                                let updatedPosition = viewModel.clocks[index].position
                                viewModel.clocks[index] = WorldClock(timezone: selectedTimezone, position: updatedPosition)
                                viewModel.saveClocks()
                            }
                            dismiss()
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
        }
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
