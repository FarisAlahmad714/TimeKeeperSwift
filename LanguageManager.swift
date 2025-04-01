//
//  LanguageManager.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 4/1/25.
//

import Foundation
import RealmSwift

class LanguageManager {
    static let shared = LanguageManager()
    
    private init() {
        // Initialize with stored language or default to English
        currentLanguage = LanguageSettings.getSettings().languageCode
    }
    
    var currentLanguage: String
    
    // Use NotificationCenter to notify views when language changes
    func setLanguage(_ code: String) {
        currentLanguage = code
        LanguageSettings.updateLanguage(code: code)
        NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
    }
    
    func localizedString(_ key: String) -> String {
        return translations[currentLanguage]?[key] ?? translations["en"]?[key] ?? key
    }
    
    // Dictionary of translations (simple implementation)
    // In a production app, you would use proper localization files
    private let translations: [String: [String: String]] = [
        "en": [
            "settings": "Settings",
            "language": "Language",
            "alarms": "Alarms",
            "world_clock": "World Clock",
            "timekeeper": "TimeKeeper",
            "stopwatch": "Stopwatch",
            "timer": "Timer",
            "add_alarm": "Add Alarm",
            "edit_alarm": "Edit Alarm",
            "delete": "Delete",
            "cancel": "Cancel",
            "save": "Save",
            "done": "Done",
            "snooze": "Snooze",
            "dismiss": "Dismiss",
            "set_alarm": "Set Alarm",
            "ad_banner": "YOUR AD HERE!"
        ],
        "ar": [
            "settings": "الإعدادات",
            "language": "اللغة",
            "alarms": "المنبهات",
            "world_clock": "الساعة العالمية",
            "timekeeper": "حافظ الوقت",
            "stopwatch": "ساعة إيقاف",
            "timer": "مؤقت",
            "add_alarm": "إضافة منبه",
            "edit_alarm": "تعديل المنبه",
            "delete": "حذف",
            "cancel": "إلغاء",
            "save": "حفظ",
            "done": "تم",
            "snooze": "غفوة",
            "dismiss": "إغلاق",
            "set_alarm": "ضبط المنبه",
            "ad_banner": "أعلن هنا!"
        ],
        "zh": [
            "settings": "设置",
            "language": "语言",
            "alarms": "闹钟",
            "world_clock": "世界时钟",
            "timekeeper": "时间管理器",
            "stopwatch": "秒表",
            "timer": "计时器",
            "add_alarm": "添加闹钟",
            "edit_alarm": "编辑闹钟",
            "delete": "删除",
            "cancel": "取消",
            "save": "保存",
            "done": "完成",
            "snooze": "暂停",
            "dismiss": "关闭",
            "set_alarm": "设置闹钟",
            "ad_banner": "在这里刊登广告！"
        ],
        "hi": [
            "settings": "सेटिंग्स",
            "language": "भाषा",
            "alarms": "अलार्म",
            "world_clock": "विश्व घड़ी",
            "timekeeper": "टाइमकीपर",
            "stopwatch": "स्टॉपवॉच",
            "timer": "टाइमर",
            "add_alarm": "अलार्म जोड़ें",
            "edit_alarm": "अलार्म संपादित करें",
            "delete": "हटाएं",
            "cancel": "रद्द करें",
            "save": "सहेजें",
            "done": "पूर्ण",
            "snooze": "स्नूज़",
            "dismiss": "बंद करें",
            "set_alarm": "अलार्म सेट करें",
            "ad_banner": "अपना विज्ञापन यहां दें!"
        ],
        "ru": [
            "settings": "Настройки",
            "language": "Язык",
            "alarms": "Будильники",
            "world_clock": "Мировые часы",
            "timekeeper": "ТаймКипер",
            "stopwatch": "Секундомер",
            "timer": "Таймер",
            "add_alarm": "Добавить будильник",
            "edit_alarm": "Изменить будильник",
            "delete": "Удалить",
            "cancel": "Отмена",
            "save": "Сохранить",
            "done": "Готово",
            "snooze": "Отложить",
            "dismiss": "Закрыть",
            "set_alarm": "Установить будильник",
            "ad_banner": "ВАША РЕКЛАМА ЗДЕСЬ!"
        ],
        "pt": [
            "settings": "Configurações",
            "language": "Idioma",
            "alarms": "Alarmes",
            "world_clock": "Relógio Mundial",
            "timekeeper": "Cronômetro",
            "stopwatch": "Cronômetro",
            "timer": "Temporizador",
            "add_alarm": "Adicionar Alarme",
            "edit_alarm": "Editar Alarme",
            "delete": "Excluir",
            "cancel": "Cancelar",
            "save": "Salvar",
            "done": "Concluído",
            "snooze": "Soneca",
            "dismiss": "Dispensar",
            "set_alarm": "Definir Alarme",
            "ad_banner": "SEU ANÚNCIO AQUI!"
        ],
        "ja": [
            "settings": "設定",
            "language": "言語",
            "alarms": "アラーム",
            "world_clock": "世界時計",
            "timekeeper": "タイムキーパー",
            "stopwatch": "ストップウォッチ",
            "timer": "タイマー",
            "add_alarm": "アラームを追加",
            "edit_alarm": "アラームを編集",
            "delete": "削除",
            "cancel": "キャンセル",
            "save": "保存",
            "done": "完了",
            "snooze": "スヌーズ",
            "dismiss": "消去",
            "set_alarm": "アラームをセット",
            "ad_banner": "広告はこちら！"
        ],
        "fr": [
            "settings": "Paramètres",
            "language": "Langue",
            "alarms": "Alarmes",
            "world_clock": "Horloge Mondiale",
            "timekeeper": "Chronométreur",
            "stopwatch": "Chronomètre",
            "timer": "Minuteur",
            "add_alarm": "Ajouter une Alarme",
            "edit_alarm": "Modifier l'Alarme",
            "delete": "Supprimer",
            "cancel": "Annuler",
            "save": "Enregistrer",
            "done": "Terminé",
            "snooze": "Répéter",
            "dismiss": "Fermer",
            "set_alarm": "Régler l'Alarme",
            "ad_banner": "VOTRE PUB ICI !"
        ]
    ]
}

// Extension to make it easier to use in SwiftUI
extension String {
    var localized: String {
        return LanguageManager.shared.localizedString(self)
    }
}
