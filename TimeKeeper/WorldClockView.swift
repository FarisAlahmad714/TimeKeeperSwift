//
//  WorldClockView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//

import SwiftUI

struct WorldClockView: View {
    @EnvironmentObject var viewModel: WorldClockViewModel
    @State private var searchText = ""
    @State private var draggedClock: WorldClock?
    
    var filteredClocks: [WorldClock] {
        if searchText.isEmpty {
            return viewModel.clocks
        } else {
            return viewModel.clocks.filter {
                timezoneName(from: $0.timezone).lowercased().contains(searchText.lowercased())
            }
        }
    }
    
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
                            ForEach(filteredClocks) { clock in
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
    @State private var selectedTimezone = TimeZone.current.identifier
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        Text("Add Clock")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        // Timezone Picker Card
                        VStack(spacing: 15) {
                            Picker("Timezone", selection: $selectedTimezone) {
                                ForEach(TimeZone.knownTimeZoneIdentifiers, id: \.self) { timezone in
                                    Text(timezone.split(separator: "/").last?.replacingOccurrences(of: "_", with: " ") ?? timezone)
                                        .tag(timezone)
                                }
                            }
                            .pickerStyle(.wheel)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        // Action Buttons
                        HStack(spacing: 20) {
                            Button(action: {
                                viewModel.showAddClockModal = false
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
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct WorldClockView_Previews: PreviewProvider {
    static var previews: some View {
        WorldClockView()
            .environmentObject(WorldClockViewModel())
            .preferredColorScheme(.dark)
    }
}
