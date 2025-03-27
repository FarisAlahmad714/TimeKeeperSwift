//
//  RealmAlarmInstance.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/25/25.
//

import Foundation
import RealmSwift

// Define Realm models for database storage
class RealmAlarmInstance: Object {
    @Persisted(primaryKey: true) var id: String = ""
    @Persisted var date: Date = Date()
    @Persisted var time: Date = Date()
    @Persisted var desc: String = ""
    @Persisted var repeatInterval: String = ""
    @Persisted(originProperty: "instances") var alarm: LinkingObjects<RealmAlarm>
    
    convenience init(instance: AlarmInstance) {
        self.init()
        self.id = instance.id
        self.date = instance.date
        self.time = instance.time
        self.desc = instance.description
        self.repeatInterval = instance.repeatInterval.rawValue
    }
    
    func toAlarmInstance() -> AlarmInstance {
        return AlarmInstance(
            id: id,
            date: date,
            time: time,
            description: desc,
            repeatInterval: RepeatInterval(rawValue: repeatInterval) ?? .none
        )
    }
}

class RealmAlarm: Object {
    @Persisted(primaryKey: true) var id: String = ""
    @Persisted var name: String = ""
    @Persisted var desc: String = ""
    @Persisted var times: List<Date>
    @Persisted var dates: List<Date>
    @Persisted var status: Bool = false
    @Persisted var ringtone: String = ""
    @Persisted var isCustomRingtone: Bool = false
    @Persisted var customRingtoneURLString: String?
    @Persisted var snooze: Bool = false
    @Persisted var instances: List<RealmAlarmInstance>
    
    override init() {
        times = List<Date>()
        dates = List<Date>()
        instances = List<RealmAlarmInstance>()
        super.init()
    }
    
    convenience init(alarm: Alarm) {
        self.init()
        self.id = alarm.id
        self.name = alarm.name
        self.desc = alarm.description
        
        // Convert arrays to Realm Lists
        self.times.append(objectsIn: alarm.times)
        self.dates.append(objectsIn: alarm.dates)
        
        self.status = alarm.status
        self.ringtone = alarm.ringtone
        self.isCustomRingtone = alarm.isCustomRingtone
        self.customRingtoneURLString = alarm.customRingtoneURL?.absoluteString
        self.snooze = alarm.snooze
        
        // Add instances if they exist
        if let alarmInstances = alarm.instances {
            for instance in alarmInstances {
                let realmInstance = RealmAlarmInstance(instance: instance)
                self.instances.append(realmInstance)
            }
        }
    }
    
    func toAlarm() -> Alarm {
        // Convert to an optional array of AlarmInstance
        let alarmInstances: [AlarmInstance]? = instances.isEmpty ? nil : Array(instances.map { $0.toAlarmInstance() })
        
        var customURL: URL? = nil
        if let urlString = customRingtoneURLString {
            customURL = URL(string: urlString)
        }
        
        return Alarm(
            id: id,
            name: name,
            description: desc,
            times: Array(times),
            dates: Array(dates),
            instances: alarmInstances,  // Now correctly passed as [AlarmInstance]?
            status: status,
            ringtone: ringtone,
            isCustomRingtone: isCustomRingtone,
            customRingtoneURL: customURL,
            snooze: snooze
        )
    }
}
