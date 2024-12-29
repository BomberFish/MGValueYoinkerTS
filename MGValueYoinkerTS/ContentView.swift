// bomberfish
// ContentView.swift – MGValueYoinkerTS
// created on 2024-12-28

import SwiftUI

struct ContentView: View {
    @State var valueToYoink: String = ""
    @State var yoinkedValue: String = ""
    @AppStorage("history") var history: [String] = []
    var body: some View {
        VStack {
            Text("mobilegestalt value yoinker")
                .font(.title)
            TextField("Value to yoink", text: $valueToYoink)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            List {
                Section(header: Label("History", systemImage: "clock")) {
                    ForEach(history, id: \.self) { value in
                        Text(value)
                            .onTapGesture {
                                valueToYoink = value
                            }
                            .tag(value)
                    }
                    .onDelete {offsets in
                        withAnimation {
                            history.remove(atOffsets: offsets)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .frame(maxHeight: 200)
            .cornerRadius(16)
            .border(Color.gray)
            
            Button("Yoink") {
                withAnimation {
                    yoinkedValue = yoink(valueToYoink)
                }
            }
            .disabled(valueToYoink.isEmpty)
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            
            TextEditor(text: $yoinkedValue)
                .padding()
                .disabled(true)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(16)
            
        }
        .padding()
        .animation(.default, value: history)
        .animation(.default, value: yoinkedValue)
        .animation(.default, value: valueToYoink)
    }
    
    
    func yoink(_ value: String) -> String {
        if !history.contains(value) {
            history.append(value)
        }
        if let response = MGCopyAnswer(valueToYoink as CFString, nil) {
            return String(describing: response.takeUnretainedValue())
        } else {
            return "nil"
        }
    }
}

extension Array: @retroactive RawRepresentable where Element: Codable {

    public init?(rawValue: String) {
        guard
            let data = rawValue.data(using: .utf8),
            let result = try? JSONDecoder().decode([Element].self, from: data)
        else { return nil }
        self = result
    }

    public var rawValue: String {
        guard
            let data = try? JSONEncoder().encode(self),
            let result = String(data: data, encoding: .utf8)
        else { return "" }
        return result
    }
}

extension Dictionary: @retroactive RawRepresentable where Key: Codable, Value: Codable {

    public init?(rawValue: String) {
        guard
            let data = rawValue.data(using: .utf8),
            let result = try? JSONDecoder().decode([Key: Value].self, from: data)
        else { return nil }
        self = result
    }

    public var rawValue: String {
        guard
            let data = try? JSONEncoder().encode(self),
            let result = String(data: data, encoding: .utf8)
        else { return "{}" }
        return result
    }
}


#Preview {
    ContentView()
}
