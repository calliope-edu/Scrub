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
                Text("Before you get started:")
            }.font(.headline)) {
                VStack(alignment: .leading, spacing: 25 ) {
                    Text("Prepare your Calliope mini so that you can program it with Scratch. You will also need the Calliope mini app.")
                    
                    // 1. Bullet Point
                    Label {
                        Text("Open the **Calliope mini app** on your iPad.")
                    } icon: {
                        Image("num_01")
                            .resizable()
                            .frame(width: 30  , height: 30)
                    }
            
                    HStack(alignment: .center) {
                        Button(action: {
                            if let url = URL(string: "https://apps.apple.com/de/app/calliope-mini/id1309545545") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Image(decorative: "step_1")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 450)
                        }.multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity)
                
                    // 2. Bullet Point
                    Label {
                        Text("**Connect** your Calliope mini to the iPad.")
                    } icon: {
                        Image("num_02")
                            .resizable()
                            .frame(width: 30  , height: 30)
                    }
                    HStack(alignment: .center) {
                        Image(decorative: "step_2")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 450)
                    }.frame(maxWidth: .infinity)
                    
                    // 3. Bullet Point
                    Label {
                        VStack() {
                            Text("Transfer the **Scratch start program** from the Calliope mini app to your Calliope mini.")
                            HStack(alignment: .center) {
                                Image(decorative: "step_3")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 400)
                            }.frame(maxWidth: .infinity)
                            Text("Select the Calliope mini Blocks Editor under Editors and Programmes.")
                        }
                    } icon: {
                        Image("num_03")
                            .resizable()
                            .frame(width: 30  , height: 30)
                    }
                
                    // 4. Bullet point
                    Label {
                        Text("A **5-digit name** appears on the LED matrix. You can use this name to select your Calliope mini in the **Calliope mini Blocks Editor**.")
                    } icon: {
                        Image("num_04")
                            .resizable()
                            .frame(width: 30  , height: 30)
                    }
                    HStack(alignment: .center) {
                        Image(decorative: "step_4")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 450)
                    }.frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                    
                    // 5. Bullet point
                    Label {
                        Text("Open the **Calliope mini Blocks app** and **connect** your Calliope mini. You are now ready to start programming your Calliope mini with Scratch!")
                    } icon: {
                        Image("num_05")
                            .resizable()
                            .frame(width: 30  , height: 30)
                    }
                    HStack(alignment: .center) {
                        Image(decorative: "step_5")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 450)
                    }.frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                    HStack(alignment: .center) {
                        Button(action: {
                            if let url = URL(string: "https://calliope.cc/en/coding/editors/calliope-mini-blocks-scratch-coding") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("Watch the video!").foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                        }
                    }.frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                    
                    
                }.padding(10).buttonStyle(BorderlessButtonStyle()).padding(.horizontal, 20)
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
                    CheckmarkText(title: Text("Editor (Create new project)"), checked: preferences.home == .scratchEditor)
                }
                Button {
                    closeKeyboard()
                    preferences.home = .customUrl
                } label: {
                    VStack {
                        CheckmarkText(title: Text("Own URL"), checked: preferences.home == .customUrl)
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
                    CheckmarkText(title: Text("Choose storage location"), checked: preferences.home == .documentsFolder)
                }
            }.disabled(preferences.isHomeLocked)
            
            Section(header: HStack {
                Label("Licenses and Sources", systemImage: "newspaper")
            }.font(.headline)) {
                HStack {
                    Text("Scrub")
                    Spacer()
                    Text("Copyright \u{00A9} 2021, Shinichiro Oba")
                }
                HStack {
                    Text("GitHub Repository")
                    Spacer()
                    Link("calliope-edu", destination: URL(string: "https://github.com/calliope-edu/Scrub")!)
                }
            }
            
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
