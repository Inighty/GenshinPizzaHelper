// (c) 2022 and onwards Pizza Studio (GPL v3.0 License).
// ====================
// This code is released under the GPL v3.0 License (SPDX-License-Identifier: GPL-3.0)

import CoreData
import CoreXLSX
import Defaults
import Foundation
import GIPizzaKit
import NaturalLanguage
import SwiftUI
import UniformTypeIdentifiers

// MARK: - UIGFv2

/// UIGFv2~v3 格式（也就是 GIGF 格式）。
///
/// 原披助手不再提供 UIGFv2~v3 格式（也就是 GIGF 格式）的导出支援，而是仅保留导入的功能。
///
/// 没写明 lang 的一律先侦测语言、且拿简体中文当垫底语言来处理。
///
/// 原披助手不图 GIGF 格式所承载的资料的完美性，GIGF 的所有内容都会被先转换成 UIGFv4 再利用。
///
/// 最终写入 App 自身的 CoreData 资料库的内容一定是简体中文，这个步骤由 UIGFv4 把关。
///
/// Ref: [UIGF](https://uigf.org/zh/standards/uigf.html)
struct UIGFv2: Decodable {
    // MARK: Lifecycle

    public init(info: Info, list: [GIGFGachaItem]) {
        self.info = info
        self.list = list
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.info = try container.decode(UIGFv2.Info.self, forKey: .info)
        self.list = try container.decode([GIGFGachaItem].self, forKey: .list)
        fixItemIDs()
    }

    // MARK: Public

    public let info: Info
    public internal(set) var list: [GIGFGachaItem]

    public var needsItemIDFix: Bool {
        !list.filter { $0.itemID.isEmpty }.isEmpty
    }

    // MARK: Internal

    struct Info: Decodable {
        // MARK: Lifecycle

        init(
            uid: String,
            lang: GachaLanguageCode,
            exportTime: Date? = nil,
            exportTimestamp: Int? = nil,
            exportApp: String? = nil,
            exportAppVersion: String? = nil,
            uigfVersion: String? = nil,
            regionTimeZone: Int? = nil
        ) {
            self.uid = uid
            self.lang = lang
            self.exportTime = exportTime
            self.exportTimestamp = exportTimestamp
            self.exportApp = exportApp
            self.exportAppVersion = exportAppVersion
            self.uigfVersion = uigfVersion
            self.regionTimeZone = regionTimeZone
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.uid = try container.decode(String.self, forKey: .uid)

            let dateFormatter = DateFormatter.Gregorian()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            if let dateString = try container.decodeIfPresent(
                String.self,
                forKey: .exportTime
            ),
                let date = dateFormatter.date(from: dateString) {
                self.exportTime = date
            } else {
                self.exportTime = nil
            }

            self.exportTimestamp = nil
            self.exportApp = try container.decodeIfPresent(
                String.self,
                forKey: .exportApp
            )
            self.exportAppVersion = try container.decodeIfPresent(
                String.self,
                forKey: .exportAppVersion
            )
            self.uigfVersion = try container.decodeIfPresent(
                String.self,
                forKey: .uigfVersion
            )
            self.regionTimeZone = try container.decodeIfPresent(
                Int.self,
                forKey: .regionTimeZone
            )

            self.lang = (try? container.decodeIfPresent(GachaLanguageCode.self, forKey: .lang)) ?? .zhHans
        }

        // MARK: Internal

        enum CodingKeys: String, CodingKey {
            case uid, lang
            case exportTime = "export_time"
            case exportApp = "export_app"
            case exportAppVersion = "export_app_version"
            case uigfVersion = "uigf_version"
            case regionTimeZone = "region_time_zone"
        }

        let uid: String
        var lang: GachaLanguageCode
        let exportTime: Date?
        let exportTimestamp: Int?
        let exportApp: String?
        let exportAppVersion: String?
        let uigfVersion: String?
        let regionTimeZone: Int?
    }

    enum CodingKeys: CodingKey {
        case info
        case list
    }
}

// MARK: - GIGFGachaItem

/// UIGFv2~v3 格式（也就是 GIGF 格式）的 GachaItem。
struct GIGFGachaItem: Decodable {
    // MARK: Lifecycle

    fileprivate init(
        gachaType: UIGFv4.ProfileGI.GachaItemGI.GachaTypeGI,
        itemID: String,
        count: String,
        time: String,
        name: String,
        itemType: String,
        rankType: GachaItem.RankType?,
        id: String,
        uigfGachaType: UIGFv4.ProfileGI.GachaItemGI.UIGFGachaTypeGI
    ) {
        self.gachaType = gachaType
        self.itemID = itemID
        self.count = count
        self.time = time
        self.name = name
        self.itemType = itemType
        self.rankType = rankType
        self.id = id
        self.uigfGachaType = uigfGachaType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let gcTypeStr = try container.decodeIfPresent(String.self, forKey: .gachaType),
           let gcTypeEnum = UIGFv4.ProfileGI.GachaItemGI.GachaTypeGI(rawValue: gcTypeStr) {
            self.gachaType = gcTypeEnum
        } else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: [CodingKeys.gachaType],
                debugDescription: "invalid gacha_type format."
            ))
        }

        self.itemID = try container.decodeIfPresent(String.self, forKey: .itemID) ?? ""
        self.count = try container
            .decodeIfPresent(String.self, forKey: .count) ?? "1"

        let dateFormatter = DateFormatter.Gregorian()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let timeStr = try? container.decode(String.self, forKey: .time),
           dateFormatter.date(from: try container.decode(String.self, forKey: .time)) != nil {
            self.time = timeStr
        } else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: [CodingKeys.time],
                debugDescription: "invalid date format: \(try container.decode(String.self, forKey: .time))"
            ))
        }

        self.name = try container.decode(String.self, forKey: .name)
        if let raw = try container.decodeIfPresent(
            String.self,
            forKey: .itemType
        ) {
            self.itemType = GachaItemType(rawString: raw).cnRaw
        } else {
            self.itemType = GachaItemType.weapon.cnRaw
        }
        if let raw = try container.decodeIfPresent(
            String.self,
            forKey: .rankType
        ),
            let intRaw = Int(raw),
            let type = GachaItem.RankType(rawValue: intRaw) {
            self.rankType = type
        } else {
            self.rankType = nil
        }

        self.id = (try? container.decodeIfPresent(String.self, forKey: .id)) ?? ""
        self.uigfGachaType = gachaType.uigfGachaType
    }

    // MARK: Internal

    enum CodingKeys: String, CodingKey {
        case gachaType = "gacha_type"
        case itemID = "item_id"
        case count
        case time
        case name
        case itemType = "item_type"
        case rankType = "rank_type"
        case id
        case uigfGachaType = "uigf_gacha_type"
    }

    var gachaType: UIGFv4.ProfileGI.GachaItemGI.GachaTypeGI
    var itemID: String
    var count: String
    var time: String
    var name: String
    var itemType: String
    var rankType: GachaItem.RankType?
    var id: String
    var uigfGachaType: UIGFv4.ProfileGI.GachaItemGI.UIGFGachaTypeGI
}

// MARK: - Translator to UIGFv4 Gacha Item

extension UIGFv2 {
    func upgradeTo4thGenerationProfile() -> UIGFv4.ProfileGI {
        // MARK: Info

        var newInfo = UIGFv4.ProfileGI(
            lang: info.lang,
            list: [],
            timezone: info.regionTimeZone ?? GachaItem.getServerTimeZoneDelta(info.uid),
            uid: info.uid
        )

        let mainDB = GachaMetaDBExposed.shared.mainDB
        let revDB = mainDB.generateHotReverseQueryDict(for: info.lang.rawValue) ?? [:]

        list.forEach { v2Item in
            var newItemID = v2Item.itemID
            var newName = v2Item.name
            if newItemID.isEmpty {
                if let newItemIDInt = revDB[v2Item.name] {
                    newItemID = newItemIDInt.description
                }
            }
            if !newItemID.isEmpty {
                newName = GachaMetaDBExposed.shared.mainDB.plainQueryForNames(
                    itemID: newItemID, langID: self.info.lang.rawValue
                ) ?? v2Item.name
            }

            var maybeRankType: String? = v2Item.rankType?.rawValue.description ?? nil
            if maybeRankType == nil, !newItemID.isEmpty,
               let intMaybeRankType = mainDB.plainQueryForRarity(itemID: newItemID) {
                maybeRankType = intMaybeRankType.description
            }

            let v4Item = UIGFv4.ProfileGI.GachaItemGI(
                count: v2Item.count,
                gachaType: v2Item.gachaType,
                id: v2Item.id,
                itemID: newItemID,
                itemType: v2Item.itemType,
                name: newName,
                rankType: maybeRankType,
                time: v2Item.time,
                uigfGachaType: v2Item.gachaType.uigfGachaType
            )
            newInfo.list.append(v4Item)
        }

        return newInfo
    }
}

// MARK: - Language Detection Feature

extension UIGFv2 {
    private static let recognizer = NLLanguageRecognizer()

    private static func guessLanguages(for text: String) -> [GachaLanguageCode] {
        Self.recognizer.processString(text)
        return Self.recognizer.languageHypotheses(withMaximum: 114_514).sorted {
            $0.value > $1.value
        }.compactMap { tag in
            GachaLanguageCode(langTag: tag.key.rawValue)
        }
    }

    private var lingualDataForAnalysis: String {
        var result = Set<String>()
        list.forEach { currentItem in
            result.insert(currentItem.name)
            result.insert(currentItem.itemType)
        }
        return result.joined(separator: "\n")
    }

    public var possibleLanguages: [GachaLanguageCode] {
        Self.guessLanguages(for: lingualDataForAnalysis)
    }

    public var mightHaveWrongLanguageTag: Bool {
        guard !list.isEmpty, let maybeLang = possibleLanguages.first else { return false }
        return maybeLang != info.lang
    }

    public mutating func fixItemIDs(with givenLanguage: GachaLanguageCode? = nil) {
        guard !list.isEmpty, needsItemIDFix else { return }
        var languages = [info.lang]
        if mightHaveWrongLanguageTag, !possibleLanguages.isEmpty {
            languages = possibleLanguages
        }
        if let givenLanguage {
            languages.removeAll { $0 == givenLanguage }
            languages.insert(givenLanguage, at: 0)
        }

        if !languages.contains(.zhHans) {
            languages.append(.zhHans) // 垫底语言。
        }

        let sharedDBSet = GachaMetaDBExposed.shared
        var revDB = [String: Int]()
        let listBackup = list
        languageEnumeration: while !languages.isEmpty, let language = languages.first {
            var languageMismatchDetected = false
            switch language {
            case .zhHans: revDB = sharedDBSet.reversedDB
            default: revDB = language.makeRevDB()
            }

            listItemEnumeration: for listIndex in 0 ..< list.count {
                guard Int(list[listIndex].itemID) == nil else { continue }
                /// 只要没查到结果，就可以认定当前的语言匹配有误。
                guard let newItemID = revDB[list[listIndex].name] else {
                    languageMismatchDetected = true
                    break listItemEnumeration
                }
                list[listIndex].itemID = newItemID.description
            }

            /// 检测无误的话，就退出处理。
            guard languageMismatchDetected else { break languageEnumeration }
            /// 处理语言有误时的情况：将 list 还原成修改前的状态，再测试下一个语言。
            languages.removeFirst()
            if !languages.isEmpty { list = listBackup }
        }
    }
}

extension GachaLanguageCode {
    fileprivate func makeRevDB() -> [String: Int] {
        GachaMetaDBExposed.shared.mainDB.generateHotReverseQueryDict(for: rawValue) ?? [:]
    }
}

// MARK: - UIGFv2 XLSX Parsing

extension XLSXFile {
    enum GIGFExcelError: Error, LocalizedError {
        case errorWithMessage(msg: String)
        case rawDataMissing
        case tableDataMissing

        // MARK: Public

        public var errorDescription: String? {
            switch self {
            case let .errorWithMessage(msg): return msg
            case .rawDataMissing: return "app.gacha.import.fail.rawDataNotExist".localized
            case .tableDataMissing: return "app.gacha.import.fail.dataTableMissingData".localized
            }
        }
    }

    private struct ParsedRow {
        let lang: GachaLanguageCode
        let uid: String
        let item: GIGFGachaItem
    }

    func parseItems() throws -> UIGFv4 {
        let extracted = try parseRawItems()
        var giProfiles = [UIGFv4.ProfileGI]()

        GachaLanguageCode.allCases.forEach { langCode in
            let rows = extracted.filter { $0.lang == langCode }
            guard !rows.isEmpty else { return }
            // UID: Items
            var map = [String: [GIGFGachaItem]]()
            rows.forEach { row in
                map[row.uid, default: []].append(row.item)
            }
            map.forEach { uid, item in
                let info = UIGFv2.Info(
                    uid: uid,
                    lang: langCode,
                    uigfVersion: "v2.2",
                    regionTimeZone: GachaItem.getServerTimeZoneDelta(uid)
                )
                var newFile = UIGFv2(info: info, list: item)
                newFile.fixItemIDs()
                giProfiles.append(newFile.upgradeTo4thGenerationProfile())
            }
        }

        var newMap = [String: [UIGFv4.ProfileGI.GachaItemGI]]()
        for iii in 0 ..< giProfiles.count {
            giProfiles[iii].list.updateLanguage(.zhHans)
            newMap[giProfiles[iii].uid, default: []].append(contentsOf: giProfiles[iii].list)
        }

        let newProfiles: [UIGFv4.ProfileGI] = newMap.map { uid, list in
            .init(lang: .zhHans, list: list, timezone: GachaItem.getServerTimeZoneDelta(uid), uid: uid)
        }

        return UIGFv4(info: .init(), giProfiles: newProfiles)
    }

    private func parseRawItems() throws -> [ParsedRow] {
        let file = self
        let dateFormatter = DateFormatter.Gregorian()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let errRDM = GIGFExcelError.rawDataMissing
        guard let workbook = try file.parseWorkbooks().first else { throw errRDM }
        let pathsAndNames = try file.parseWorksheetPathsAndNames(workbook: workbook)
        guard let (_, path) = pathsAndNames.first(where: { $0.name == "原始数据" }) else { throw errRDM }
        guard let worksheet = try? file.parseWorksheet(at: path) else { throw errRDM }
        guard let sharedStrings = try file.parseSharedStrings() else { throw errRDM }

        let errTDM = GIGFExcelError.tableDataMissing
        guard let rawRows = worksheet.data?.rows else { throw errTDM }
        guard let firstRowCells = rawRows.first?.cells else { throw errTDM }
        let head = firstRowCells.map { $0.stringValue(sharedStrings) }
        let rows = rawRows[1...].map { $0.cells.map { $0.stringValue(sharedStrings) }}
        guard let gachaTypeIndex = head.firstIndex(where: { $0 == "gacha_type" }) else { throw errTDM }
        guard let itemTypeIndex = head.firstIndex(where: { $0 == "item_type" }) else { throw errTDM }
        guard let nameIndex = head.firstIndex(where: { $0 == "name" }) else { throw errTDM }
        guard let uidIndex = head.firstIndex(where: { $0 == "uid" }) else { throw errTDM }
        guard let idIndex = head.firstIndex(where: { $0 == "id" }) else { throw errTDM }

        let itemIdIndex = head.firstIndex(where: { $0 == "item_id" })
        let timeIndex = head.firstIndex(where: { $0 == "time" })
        let langIndex = head.firstIndex(where: { $0 == "lang" })
        let rankTypeIndex = head.firstIndex(where: { $0 == "rank_type" })
        let countIndex = head.firstIndex(where: { $0 == "count" })

        var extracted: [ParsedRow] = []

        rows.forEach { cells in
            guard let id = cells[idIndex] else { return }
            guard let uid = cells[uidIndex] else { return }
            guard let gachaTypeRAW = cells[gachaTypeIndex] else { return }
            guard let itemType = cells[itemTypeIndex] else { return }
            guard let name = cells[nameIndex] else { return }

            guard let gachaType = UIGFv4.ProfileGI.GachaItemGI.GachaTypeGI(
                rawValue: gachaTypeRAW
            ) else { return }

            var itemID = ""
            if let itemIdIndex = itemIdIndex, let itemIdString = cells[itemIdIndex] {
                itemID = itemIdString
            }

            var count = "1"
            if let countIndex = countIndex, let countString = cells[countIndex] {
                count = countString
            }

            /// GIGF XLSX 格式的时间原则上得认为是伺服器时间，
            /// 不存在 JSON 那种在导出时改变时区的可能。
            var time: Date = .distantPast
            let timeZoneDelta = GachaItem.getServerTimeZoneDelta(uid)
            if let timeIndex = timeIndex, let timeString = cells[timeIndex] {
                time = DateFormatter.forUIGFEntry(
                    timeZoneDelta: timeZoneDelta
                ).date(from: timeString) ?? .distantPast
            }

            var lang: GachaLanguageCode = .zhHans
            if let langIndex = langIndex, let langString = cells[langIndex],
               let langCode = GachaLanguageCode(rawValue: langString) {
                lang = langCode
            }

            let rankType: Int
            if let rankTypeIndex = rankTypeIndex,
               let rankTypeString = cells[rankTypeIndex],
               let rankTypeInt = Int(rankTypeString) {
                rankType = rankTypeInt
            } else {
                rankType = 3
            }

            let newItem = GIGFGachaItem(
                gachaType: gachaType,
                itemID: itemID,
                count: count,
                time: time.asUIGFDate(timeZoneDelta: timeZoneDelta),
                name: name,
                itemType: itemType,
                rankType: GachaItem.RankType(rawValue: rankType) ?? .three,
                id: id,
                uigfGachaType: gachaType.uigfGachaType
            )

            let newRow = ParsedRow(lang: lang, uid: uid, item: newItem)
            extracted.append(newRow)
        }

        return extracted
    }
}
