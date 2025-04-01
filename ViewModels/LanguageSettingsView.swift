//
//  LanguageSettingsView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 4/1/25.
//


// Views/LanguageSettingsView.swift
import SwiftUI

struct LanguageSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedLanguage: String
    
    let languages = [
        "en": "English",
        "ar": "العربية (Arabic)",
        "zh": "中文 (Chinese)",
        "hi": "हिन्दी (Hindi)",
        "ru": "Русский (Russian)",
        "pt": "Português (Portuguese)",
        "ja": "日本語 (Japanese)",
        "fr": "Français (French)"
    ]
    
    init() {
        _selectedLanguage = State(initialValue: LanguageManager.shared.currentLanguage)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(languages.sorted(by: { $0.value < $1.value }), id: \.key) { key, name in
                    Button(action: {
                        selectedLanguage = key
                        LanguageManager.shared.setLanguage(key)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(name)
                            Spacer()
                            if selectedLanguage == key {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("language".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .environment(\.layoutDirection, selectedLanguage == "ar" ? .rightToLeft : .leftToRight)
    }
}