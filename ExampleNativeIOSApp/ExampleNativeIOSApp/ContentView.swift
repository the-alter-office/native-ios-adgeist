//
//  ContentView.swift
//  ExampleNativeIOSApp
//
//  Created by kishore on 02/05/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @ObservedObject private var viewModel = ContentViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        NavigationSplitView {
              VStack {
                       Text("🥱")
                           .font(.system(size: 80.0))

                       Text("Are You Bored?")
                           .font(.title)

                       Text(viewModel.activityDescription)
                           .padding()

                       Button("Generate Activity") {
                           viewModel.generateActivity()
                       }
                       .buttonStyle(.borderedProminent)
                       .disabled(viewModel.isLoading)
            }.padding()
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
