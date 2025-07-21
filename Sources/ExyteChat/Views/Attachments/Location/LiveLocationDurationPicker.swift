import SwiftUI

struct LiveLocationDurationPicker: View {
    @Binding var selectedMinutes: Int
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Label("Share Live Location For:", systemImage: "clock")
                .font(.headline)

            Picker("Duration", selection: $selectedMinutes) {
                Text("15 Minutes").tag(15)
                Text("1 Hour").tag(60)
                Text("8 Hours").tag(480)
            }
            .pickerStyle(.wheel)
            .frame(height: 120)

            Button {
                onStart()
            } label: {
                Label("Start Sharing", systemImage: "paperplane.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.large)
            .padding(.top)
        }
    }
}
