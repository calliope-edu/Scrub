//
//  PreferencesView.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/18.
//

import SwiftUI

struct PreferencesView: View {
    
    @ObservedObject var preferences: Preferences
    
    var body: some View {
        Form {
            Section(header: Text("Initial URL")) {
                Button(action: {
                    closeKeyboard()
                    preferences.initialUrl = .homeUrl
                }) {
                    HStack {
                        Text("Home URL").foregroundColor(.black)
                        Spacer()
                        if preferences.initialUrl == .homeUrl {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                Button(action: {
                    closeKeyboard()
                    preferences.initialUrl = .lastUrl
                }) {
                    HStack {
                        Text("Last Visited URL").foregroundColor(.black)
                        Spacer()
                        if preferences.initialUrl == .lastUrl {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            Section(header: Text("Home URL")) {
                Button(action: {
                    closeKeyboard()
                    preferences.homeUrl = .scratchHome
                }) {
                    HStack {
                        Text("Scratch Home").foregroundColor(.black)
                        Spacer()
                        if preferences.homeUrl == .scratchHome {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                Button(action: {
                    closeKeyboard()
                    preferences.homeUrl = .custom
                }) {
                    VStack {
                        HStack {
                            Text("Custom").foregroundColor(.black)
                            Spacer()
                            if preferences.homeUrl == .custom {
                                Image(systemName: "checkmark")
                            }
                        }
                        TextField("https://", text: $preferences.customUrl, onCommit: {
                            preferences.homeUrl = .custom
                        })
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    }
                }
                Button(action: {
                    closeKeyboard()
                    preferences.homeUrl = .documentsFolder
                }) {
                    HStack {
                        Text("Local Documents Folder").foregroundColor(.black)
                        Spacer()
                        if preferences.homeUrl == .documentsFolder {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            Section {
                HStack {
                    Text("Version:")
                    Spacer()
                    Text(versionString())
                }
            }
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

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView(preferences: Preferences())
    }
}
