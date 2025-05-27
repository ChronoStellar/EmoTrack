import SwiftUI
import AVFoundation
import CoreML
import Vision

// Main Content View
struct ContentView: View {
    @State private var selectedTab = 0 // Default to Mood View (index 0)
    
    var body: some View {
        NavigationView {
            // Sidebar
            List(selection: $selectedTab) {
                NavigationLink(destination: MoodView()) {
                    Label("Mood", systemImage: "face.smiling")
                }
                .tag(0)
                
                NavigationLink(destination: Text("Journal View")) {
                    Label("Journal", systemImage: "book")
                }
                .tag(1)
                
                NavigationLink(destination: Text("History View")) {
                    Label("History", systemImage: "clock")
                }
                .tag(2)
                
                NavigationLink(destination: Text("Settings View")) {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)
            
            // Default View (shown before any selection)
            Text("Select an option from the sidebar")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
