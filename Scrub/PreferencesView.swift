//
//  PreferencesView.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/18.
//

import SwiftUI

struct PreferencesView: View {
    
    @EnvironmentObject private var preferences: Preferences
    
    private var isCentered: Bool = false
    
    var body: some View {
        Form {
            // Calliope mini Info
            Section(header: HStack {
                Label("Programmiere deinen Calliope mini mit Scratch!", systemImage: "info.circle.fill")
            }.font(.headline)) {
                VStack(spacing: 20) {
                    Label {
                        Text("Verbinde deinen Calliope mini mit dem iPad (dafür benötigst du die Calliope mini App).")
                    } icon: {
                        Image("num_01")
                            .resizable()
                            .frame(width: 30  , height: 30)
                    }
                    
                    Button(action: {
                        if let url = URL(string: "https://apps.apple.com/de/app/calliope-mini/id1309545545") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(decorative: "green_matrix")
                            .resizable()
                            .dynamicTypeSize(.xSmall)
                            .frame(width: 60, height: 60)
                            .aspectRatio(contentMode: .fit)
                    }
                    
                    Label {
                        Text("Übertrage das Scratch Startprogramm, um deinen Calliope mini programmierbar zu machen.")
                    } icon: {
                        Image("num_02")
                            .resizable()
                            .frame(width: 30  , height: 30)
                    }
                    
                    Button("Upload") {
                        if let url = URL(string: "https://apps.apple.com/de/app/calliope-mini/id1309545545") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .frame(width: 200 , height: 60)
                    .font(.title)
                    .foregroundColor(.white)
                    .background(Color(red: 0.273, green: 0.873, blue: 0.432))
                    .cornerRadius(10)
                    
                    Label {
                        Text("Nun kannst du mit der Calliope mini Blocks App auf den Calliope mini programmieren.")
                    } icon: {
                        Image("num_03")
                            .resizable()
                            .frame(width: 30  , height: 30)
                    }
                    Image(decorative: "app_icon_transparent")
                        .resizable()
                        .dynamicTypeSize(.xSmall)
                        .frame(width: 120  , height: 120)
                        .aspectRatio(contentMode: .fit)
                }.padding(10).buttonStyle(BorderlessButtonStyle())
            }.disabled(preferences.isHomeLocked)
            
            
            // Home
            Section(header: HStack {
                Label("Home", systemImage: "house")
            }.font(.headline)) {
                Button {
                    closeKeyboard()
                    preferences.home = .scratchHome
                } label: {
                    CheckmarkText(title: Text("Start"), checked: preferences.home == .scratchHome)
                }
                Button {
                    closeKeyboard()
                    preferences.home = .scratchEditor
                } label: {
                    CheckmarkText(title: Text("Editor (Erstelle neues Projekt)"), checked: preferences.home == .scratchEditor)
                }
                Button {
                    closeKeyboard()
                    preferences.home = .customUrl
                } label: {
                    VStack {
                        CheckmarkText(title: Text("Eigne URL"), checked: preferences.home == .customUrl)
                        URLTextField(text: $preferences.customUrl, disabled: preferences.isCustomUrlLocked, onEditingChanged: { isEditing in
                            if isEditing {
                                preferences.home = .customUrl
                            }
                        })
                    }
                }
                Button {
                    closeKeyboard()
                    preferences.home = .documentsFolder
                } label: {
                    CheckmarkText(title: Text("Speicherort auswählen"), checked: preferences.home == .documentsFolder)
                }
            }.disabled(preferences.isHomeLocked)
            
            // Version
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(versionString())
                }
            }
            
            // Footer
            Section(footer: Text("Scratch is a project of the Scratch Foundation, in collaboration with the Lifelong Kindergarten Group at the MIT Media Lab. It is available for free at https://scratch.mit.edu.")) {}
        }
    }
    
    private func versionString() -> String {
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            return "\(version) (\(build))"
        }
        return ""
    }
    
    private func closeKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private struct LockImage: View {
    
    var body: some View {
        Image(symbol: .lockFill).foregroundColor(.red)
    }
}

private struct CheckmarkText: View {
    
    let title: Text
    let checked: Bool
    
    var body: some View {
        HStack {
            title.foregroundColor(.primary)
            Spacer()
            if checked {
                Image(symbol: .checkmark)
            }
        }
    }
}

private struct URLTextField: View {
    
    @Binding var text: String
    let disabled: Bool
    let onEditingChanged: (Bool) -> Void
    
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            if disabled {
                LockImage()
            }
            
            TextField("https://", text: $text, onEditingChanged: { isEditing in
                self.isEditing = isEditing
                onEditingChanged(isEditing)
            })
            .foregroundColor(.secondary)
            .keyboardType(.URL)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .disabled(disabled)
            
            if isEditing && !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(symbol: .xmarkCircleFill)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

private struct WebLink: View {
    
    let title: Text
    let destination: URL
    
    var body: some View {
        Link(destination: destination) {
            HStack {
                title
                Spacer()
                Image(symbol: .globe)
            }
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
            .environmentObject(Preferences())
    }
}
