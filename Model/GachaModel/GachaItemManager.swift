//
//  GachaItemManager.swift
//  GenshinPizzaHepler
//
//  Created by 戴藏龙 on 2023/3/28.
//

import CoreData
import Foundation

public class GachaModelManager {
    // MARK: Lifecycle

    private init() {
        let containerURL = FileManager.default
            .containerURL(
                forSecurityApplicationGroupIdentifier: "group.GenshinPizzaHelper"
            )!
        let storeURL = containerURL
            .appendingPathComponent("PizzaGachaLog.splite")

        self
            .container =
            NSPersistentCloudKitContainer(name: "PizzaGachaLog")
        let description = container.persistentStoreDescriptions.first!
        description.url = storeURL

        description
            .cloudKitContainerOptions =
            .init(containerIdentifier: "iCloud.com.Canglong.PizzaGachaLog")
        description.setOption(
            true as NSNumber,
            forKey: "NSPersistentStoreRemoteChangeNotificationOptionKey"
        )

        container.loadPersistentStores { _, error in
            if let error = error {
                print("ERROR LOADING CORE DATA. \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext
            .mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        container.viewContext.refreshAllObjects()
    }

    // MARK: Internal

    static let shared: GachaModelManager = .init()

    var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        container.persistentStoreCoordinator
    }

    func fetchAll() -> [GachaItem] {
        container.viewContext.refreshAllObjects()
        let request = GachaItemMO.fetchRequest()
        do {
            let gachaItemMOs = try container.viewContext.fetch(request)
            return gachaItemMOs.map { item in
                item.toGachaItem()
            }
        } catch {
            print("ERROR FETCHING CONFIGURATION. \(error.localizedDescription)")
            return []
        }
    }

    func checkIDAndUIDExists(uid: String, id: String) -> Bool {
        let request = GachaItemMO.fetchRequest()
        let predicate = NSPredicate(format: "(id = %@) AND (uid = %@)", id, uid)
        request.predicate = predicate

        do {
            let gachaItemMOs = try container.viewContext.fetch(request)
            return !gachaItemMOs.isEmpty
        } catch {
            print("ERROR FETCHING CONFIGURATION. \(error.localizedDescription)")
            return true
        }
    }

    func addRecordItems(
        _ items: [GachaItem_FM],
        isNew: @escaping ((Bool) -> ())
    ) {
        container.viewContext.perform { [self] in
            items.forEach { item in
                self.addRecordItem(item, isNew: isNew)
            }
            save()
        }
    }

    func addRecordItem(_ item: GachaItem_FM, isNew: @escaping ((Bool) -> ())) {
        if !checkIDAndUIDExists(uid: item.uid, id: item.id) {
            _ = item.toGachaItemMO(context: container.viewContext)
            isNew(true)
        } else {
            isNew(false)
        }
    }

    func save() {
        do {
            try container.viewContext.save()
        } catch {
            print("ERROR SAVING. \(error.localizedDescription)")
        }
    }

    func deleteAllRecord() {
        let fetchRequest = GachaItemMO.fetchRequest()
        do {
            let models = try container.viewContext.fetch(fetchRequest)
            models.forEach { item in
                container.viewContext.delete(item)
            }
            try container.viewContext.save()
        } catch {
            print(error)
        }
    }

    func cleanDuplicatedItems() -> Int {
        var deletedItemCount = 0
        container.viewContext.refreshAllObjects()
        let request = GachaItemMO.fetchRequest()
        do {
            let items = try container.viewContext.fetch(request)
            Dictionary(grouping: items) { item in
                item.id! + item.uid!
            }.forEach { _, items in
                if items.count > 1 {
                    items[1...].forEach { item in
                        container.viewContext.delete(item)
                        deletedItemCount += 1
                    }
                }
            }
            try container.viewContext.save()
            return deletedItemCount
        } catch {
            print(error.localizedDescription)
            return deletedItemCount
        }
    }

    /// 删除数据，并返回删除的数据条数
    func deleteData(for uid: String, startDate: Date, endData: Date) -> Int {
        container.viewContext.refreshAllObjects()
        let request = GachaItemMO.fetchRequest()
        let predicate = NSPredicate(
            format: "(uid = %@) AND (time >= %@) AND (time <= %@)",
            uid,
            startDate as NSDate,
            endData as NSDate
        )
        request.predicate = predicate
        do {
            let items = try container.viewContext.fetch(request)
            items.forEach { item in
                container.viewContext.delete(item)
            }
            try container.viewContext.save()
            return items.count
        } catch {
            print(error.localizedDescription)
            return 0
        }
    }

    // MARK: Private

    private let container: NSPersistentCloudKitContainer
    private let queue = DispatchQueue(
        label: "com.GenshinPizzaHepler.SaveGacha",
        qos: .background
    )
}