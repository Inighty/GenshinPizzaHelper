//
//  UIGFModel.swift
//  GenshinPizzaHepler
//
//  Created by 戴藏龙 on 2023/4/2.
//

import CoreData
import Defaults
import Foundation
import GIPizzaKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - UIGFv4

// 原披助手现阶段引入的 UIGFv4 不会考虑对任何来自除了原神以外的游戏的资料处理。
// 出于实作成本等原因，目前原披助手仅处理被 UIGF 认定为 required 的字段。
// 你们可能会在穹披助手的源码仓库看到除了星穹铁道以外的游戏的资料结构，
// 但穹披助手也只会处理星穹铁道的资料而已。
// Ref: https://uigf.org/zh/standards/uigf.html

public struct UIGFv4: Codable, Hashable, Sendable {
    // MARK: Lifecycle

    public init(
        info: Info,
        giProfiles: [ProfileGI]? = []
    ) {
        self.info = info
        self.giProfiles = giProfiles
    }

    // MARK: Public

    public enum CodingKeys: String, CodingKey {
        case giProfiles = "hk4e"
        case info
    }

    public var giProfiles: [ProfileGI]?
    public var info: Info
}

// MARK: UIGFv4.Info

extension UIGFv4 {
    public struct Info: Codable, Hashable, Sendable {
        // MARK: Lifecycle

        public init(exportApp: String, exportAppVersion: String, exportTimestamp: String, version: String) {
            self.exportApp = exportApp
            self.exportAppVersion = exportAppVersion
            self.exportTimestamp = exportTimestamp
            self.version = version
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.exportApp = try container.decode(String.self, forKey: .exportApp)
            self.exportAppVersion = try container.decode(String.self, forKey: .exportAppVersion)
            self.version = try container.decode(String.self, forKey: .version)
            if let x = try? container.decode(String.self, forKey: .exportTimestamp) {
                self.exportTimestamp = x
            } else if let x = try? container.decode(Int.self, forKey: .exportTimestamp) {
                self.exportTimestamp = x.description
            } else if let x = try? container.decode(Double.self, forKey: .exportTimestamp) {
                self.exportTimestamp = x.description
            } else {
                self.exportTimestamp = "YJSNPI" // 摆烂值，反正这里不解析。
            }
        }

        // MARK: Public

        public enum CodingKeys: String, CodingKey {
            case exportApp = "export_app"
            case exportAppVersion = "export_app_version"
            case exportTimestamp = "export_timestamp"
            case version
        }

        /// 导出档案的 App 名称
        public let exportApp: String
        /// 导出档案的 App 版本
        public let exportAppVersion: String
        /// 导出档案的时间戳，秒级
        public let exportTimestamp: String
        /// 导出档案的 UIGF 版本号，格式为 'v{major}.{minor}'，如 v4.0
        public let version: String
    }
}

// MARK: UIGFv4.ProfileGI

public typealias UIGFGachaItem = UIGFv4.ProfileGI.GachaItemGI
public typealias UIGFGachaProfile = UIGFv4.ProfileGI

// MARK: - UIGFv4.ProfileGI

extension UIGFv4 {
    /// 备注：阉割版本，仅保留被 UIGF 定义为 required 的字段。
    public struct ProfileGI: Codable, Hashable, Sendable {
        // MARK: Lifecycle

        public init(lang: GachaLanguageCode? = nil, list: [GachaItemGI], timezone: Int?, uid: String) {
            self.lang = lang
            self.list = list
            self.timezone = timezone ?? GachaItem.getServerTimeZoneDelta(uid)
            self.uid = uid
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.list = try container.decode([GachaItemGI].self, forKey: .list)
            self.lang = try container.decode(GachaLanguageCode.self, forKey: .lang)
            self.timezone = try container.decode(Int.self, forKey: .timezone)

            if let x = try? container.decode(String.self, forKey: .uid) {
                self.uid = x
            } else if let x = try? container.decode(Int.self, forKey: .uid) {
                self.uid = x.description
            } else {
                throw DecodingError.typeMismatch(
                    String.self,
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Type for UID shall be either String or Integer."
                    )
                )
            }

            /// Check whether GachaItemDB is expired.
            if GachaMetaDBExposed.shared.mainDB.checkIfExpired(against: Set<String>(list.map(\.id))) {
                defer {
                    Task.detached { @MainActor in
                        try? await GachaMetaDBExposed.Sputnik.updateLocalGachaMetaDB()
                    }
                }
                throw GachaMetaDBExposed.GMDBError.databaseExpired
            }
        }

        // MARK: Public

        public struct GachaItemGI: Codable, Hashable, Sendable {
            // MARK: Lifecycle

            public init(
                count: String?,
                gachaType: GachaTypeGI,
                id: String,
                itemID: String,
                itemType: String?,
                name: String?,
                rankType: String?,
                time: String,
                uigfGachaType: UIGFGachaTypeGI
            ) {
                self.count = count
                self.gachaType = gachaType
                self.id = id
                self.itemID = itemID
                self.itemType = itemType
                self.name = name
                self.rankType = rankType
                self.time = time
                self.uigfGachaType = uigfGachaType
            }

            public init(from decoder: any Decoder) throws {
                let container: KeyedDecodingContainer<UIGFv4.ProfileGI.GachaItemGI.CodingKeys> = try decoder
                    .container(keyedBy: UIGFv4.ProfileGI.GachaItemGI.CodingKeys.self)
                self.count = try container.decodeIfPresent(
                    String.self,
                    forKey: UIGFv4.ProfileGI.GachaItemGI.CodingKeys.count
                )
                self.gachaType = try container.decode(
                    UIGFv4.ProfileGI.GachaItemGI.GachaTypeGI.self,
                    forKey: UIGFv4.ProfileGI.GachaItemGI.CodingKeys.gachaType
                )
                self.id = try container.decode(String.self, forKey: UIGFv4.ProfileGI.GachaItemGI.CodingKeys.id)
                if id.isEmpty {
                    throw DecodingError.dataCorrupted(
                        .init(
                            codingPath: [CodingKeys.id],
                            debugDescription: """
                            itemID shall not be empty. // itemID 不得是空值。 // itemID は必ず有効な値しか処理できません。
                            """
                        )
                    )
                }
                self.itemID = try container.decode(String.self, forKey: UIGFv4.ProfileGI.GachaItemGI.CodingKeys.itemID)
                self.itemType = try container.decodeIfPresent(
                    String.self,
                    forKey: UIGFv4.ProfileGI.GachaItemGI.CodingKeys.itemType
                )
                self.name = try container.decodeIfPresent(
                    String.self,
                    forKey: UIGFv4.ProfileGI.GachaItemGI.CodingKeys.name
                )
                self.rankType = try container.decodeIfPresent(
                    String.self,
                    forKey: UIGFv4.ProfileGI.GachaItemGI.CodingKeys.rankType
                )
                self.time = try container.decode(String.self, forKey: UIGFv4.ProfileGI.GachaItemGI.CodingKeys.time)
                self.uigfGachaType = try container.decode(
                    UIGFv4.ProfileGI.GachaItemGI.UIGFGachaTypeGI.self,
                    forKey: UIGFv4.ProfileGI.GachaItemGI.CodingKeys.uigfGachaType
                )
            }

            // MARK: Public

            public enum CodingKeys: String, CodingKey {
                case count
                case gachaType = "gacha_type"
                case id
                case itemID = "item_id"
                case itemType = "item_type"
                case name
                case rankType = "rank_type"
                case time
                case uigfGachaType = "uigf_gacha_type"
            }

            /// 卡池类型，API返回
            public enum GachaTypeGI: String, Codable, Hashable, Sendable {
                case beginnersWish = "100"
                case standardWish = "200"
                case characterEvent1 = "301"
                case weaponEvent = "302"
                case characterEvent2 = "400"
                case chronicledWish = "500"

                // MARK: Public

                public var uigfGachaType: UIGFGachaTypeGI {
                    switch self {
                    case .beginnersWish: return .beginnersWish
                    case .standardWish: return .standardWish
                    case .characterEvent1, .characterEvent2: return .characterEvent
                    case .weaponEvent: return .weaponEvent
                    case .chronicledWish: return .chronicledWish
                    }
                }
            }

            /// UIGF 卡池类型，用于区分卡池类型不同，但卡池保底计算相同的物品
            public enum UIGFGachaTypeGI: String, Codable, Hashable, Sendable {
                case beginnersWish = "100"
                case standardWish = "200"
                case characterEvent = "301"
                case weaponEvent = "302"
                case chronicledWish = "500"
            }

            /// 物品个数，一般为1，API返回
            public var count: String?
            /// 卡池类型，API返回
            public var gachaType: GachaTypeGI
            /// 记录内部 ID, API返回
            public var id: String
            /// 物品的内部 ID
            public var itemID: String
            /// 物品类型, API返回
            public var itemType: String?
            /// 物品名称, API返回
            public var name: String?
            /// 物品等级, API返回
            public var rankType: String?
            /// 获取物品的本地时间，与 timezone 一起计算出物品的准确获取时间，API返回
            public var time: String
            /// UIGF 卡池类型，用于区分卡池类型不同，但卡池保底计算相同的物品
            public var uigfGachaType: UIGFGachaTypeGI
        }

        /// 语言代码
        public var lang: GachaLanguageCode?
        public var list: [GachaItemGI]
        /// 时区偏移
        public var timezone: Int
        /// UID
        public var uid: String
    }
}

// MARK: - Extensions

extension UIGFv4 {
    public typealias DataEntry = ProfileGI.GachaItemGI // 注意这个地方是否与所属 App 一致。

    public enum SupportedHoYoGames: String {
        case genshinImpact = "GI"
    }

    public init() {
        self.info = .init()
        self.giProfiles = []
    }

    public var defaultFileNameStem: String {
        let dateFormatter = DateFormatter.forUIGFFileName
        return "\(Self.initials)\(dateFormatter.string(from: info.maybeDateExported ?? Date()))"
    }

    private static let initials = "UIGFv4_"

    public func getFileNameStem(
        uid: String? = nil,
        for game: SupportedHoYoGames? = .genshinImpact
    )
        -> String {
        var stack = Self.initials
        if let game { stack += "\(game.rawValue)_" }
        if let uid { stack += "\(uid)_" }
        return defaultFileNameStem.replacingOccurrences(of: Self.initials, with: stack)
    }

    public var asDocument: Document {
        .init(model: self)
    }
}

extension UIGFv4.Info {
    // MARK: Lifecycle

    public init() {
        self.exportApp = "PizzaHelper4GI"
        let shortVer = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        self.exportAppVersion = shortVer ?? "1.14.514"
        self.exportTimestamp = Int(Date.now.timeIntervalSince1970).description
        self.version = "v4.0"
    }

    public var maybeDateExported: Date? {
        guard let exportTimestamp = Double(exportTimestamp) else { return nil }
        return .init(timeIntervalSince1970: Double(exportTimestamp))
    }
}

// MARK: - UIGFv4.Document

extension UIGFv4 {
    public struct Document: FileDocument {
        // MARK: Lifecycle

        public init(configuration: ReadConfiguration) throws {
            self.model = try JSONDecoder()
                .decode(
                    UIGFv4.self,
                    from: configuration.file.regularFileContents!
                )
        }

        public init(model: UIGFv4) {
            self.model = model
        }

        // MARK: Public

        public static var readableContentTypes: [UTType] = [.json]

        public let model: UIGFv4

        public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let dateFormatter = DateFormatter()
            dateFormatter.locale = .init(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            encoder.dateEncodingStrategy = .formatted(dateFormatter)
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let data = try encoder.encode(model)
            return FileWrapper(regularFileWithContents: data)
        }
    }
}

extension DateFormatter {
    public static func forUIGFEntry(
        timeZoneDelta: Int
    )
        -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmm"
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = .init(secondsFromGMT: timeZoneDelta * 3600)
        return dateFormatter
    }

    public static var forUIGFFileName: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmm"
        dateFormatter.locale = .init(identifier: "en_US_POSIX")
        return dateFormatter
    }
}

extension Date {
    public func asUIGFDate(
        timeZoneDelta: Int
    )
        -> String {
        DateFormatter.forUIGFEntry(timeZoneDelta: timeZoneDelta).string(from: self)
    }
}

extension UIGFGachaItem {
    public mutating func editId(_ newId: String) {
        id = newId
    }

    public func toGachaItemMO(
        context: NSManagedObjectContext,
        uid: String,
        profile: UIGFGachaProfile
    )
        -> GachaItemMO {
        let model = GachaItemMO(context: context)
        model.uid = uid
        model.itemId = itemID
        model.gachaType = Int16(gachaType.rawValue) ?? 0
        model.count = Int16(count ?? "1") ?? 1

        let timeTyped: Date? = DateFormatter.forUIGFEntry(
            timeZoneDelta: profile.timezone
        ).date(from: time)

        model.time = timeTyped
        model.name = name
        model.lang = GachaLanguageCode.zhHans.rawValue
        if let itemType = itemType {
            model.itemType = GachaItemType(rawString: itemType).cnRaw
        } else {
            model.itemType = GachaItemType(itemIdStr: itemID).cnRaw
        }
        // Sabotaged.
        model.rankType = Int16(rankType ?? "4") ?? 4
        model.id = id
        return model
    }
}

extension GachaItemMO {
    // Lazy 变数，仅会在用到的时候载入。
    private static let enkaCNDB = EnkaGI.EnkaDB(locTag: "zh-cn")!

    func toUIGFGachaItem(_ languageCode: GachaLanguageCode) -> UIGFGachaItem {
        let timeZoneDelta: Int = GachaItem.getServerTimeZoneDelta(uid!.description)
        let theItemID = itemId!
        let newName = Self.enkaCNDB.queryLocalizedNameForChar(
            id: theItemID, officialNameOnly: true
        ) {
            self.name!
        }
        let gachaTypeNew = UIGFGachaItem.GachaTypeGI(
            rawValue: gachaType.description
        )!
        let newItem = UIGFGachaItem(
            count: count.description,
            gachaType: gachaTypeNew,
            id: id!,
            itemID: theItemID,
            itemType: itemType,
            name: newName,
            rankType: rankType.description,
            time: time!.asUIGFDate(timeZoneDelta: timeZoneDelta),
            uigfGachaType: gachaTypeNew.uigfGachaType
        )
        return newItem
    }
}
