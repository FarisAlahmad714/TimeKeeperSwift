//
//  LanguageSettings.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 4/1/25.
//


// Models/LanguageSettings.swift
import Foundation
import RealmSwift

class LanguageSettings: Object {
    @Persisted(primaryKey: true) var id: String = "languageSettings"
    @Persisted var languageCode: String = "en"
    
    static func getSettings() -> LanguageSettings {
        let realm = try! Realm()
        if let settings = realm.object(ofType: LanguageSettings.self, forPrimaryKey: "languageSettings") {
            return settings
        } else {
            let settings = LanguageSettings()
            try! realm.write {
                realm.add(settings)
            }
            return settings
        }
    }
    
    static func updateLanguage(code: String) {
        let realm = try! Realm()
        let settings = getSettings()
        try! realm.write {
            settings.languageCode = code
        }
    }
}