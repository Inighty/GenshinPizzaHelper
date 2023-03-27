//
//  ENCharacterLoc.swift
//  
//
//  Created by Bill Haku on 2023/3/27.
//

import Foundation

struct ENCharacterLoc: Codable {
    // MARK: Internal

    struct LocDict: Codable {
        // MARK: Lifecycle

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: LocKey.self)

            var contentDict = [String: String]()
            for key in container.allKeys {
                if let model = try? container.decode(String.self, forKey: key) {
                    contentDict[key.stringValue] = model
                }
            }
            self.content = contentDict
        }

        // MARK: Internal

        struct LocKey: CodingKey {
            // MARK: Lifecycle

            init?(stringValue: String) {
                self.stringValue = stringValue
            }

            init?(intValue: Int) {
                self.stringValue = "\(intValue)"
                self.intValue = intValue
            }

            // MARK: Internal

            var stringValue: String
            var intValue: Int?
        }

        var content: [String: String]
    }

    var en: LocDict
    var ru: LocDict
    var vi: LocDict
    var th: LocDict
    var pt: LocDict
    var ko: LocDict
    var ja: LocDict
    var id: LocDict
    var fr: LocDict
    var es: LocDict
    var de: LocDict
    var zh_tw: LocDict
    var zh_cn: LocDict

    func getLocalizedDictionary() -> [String: String] {
        switch Bundle.main.preferredLocalizations.first {
        case "zh-Hans":
            return zh_cn.content
        case "zh-Hant", "zh-HK":
            return zh_tw.content
        case "en":
            return en.content
        case "ja":
            return ja.content
        case "fr":
            return fr.content
        case "ru":
            return ru.content
        case "vi":
            return vi.content
        default:
            return en.content
        }
    }

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case en, ru, vi, th, pt, ko, ja, id, fr, es, de
        case zh_tw = "zh-TW"
        case zh_cn = "zh-CN"
    }
}
