import SwiftUI

struct AlarmsView: View {
    @EnvironmentObject var viewModel: AlarmViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Alarms View")
                    .font(.title)
                
                Button("Add Alarm") {
                    viewModel.showChoiceModal = true
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .navigationTitle("Alarms")
        }
    }
}