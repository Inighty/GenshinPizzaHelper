// (c) 2022 and onwards Pizza Studio (GPL v3.0 License).
// ====================
// This code is released under the GPL v3.0 License (SPDX-License-Identifier: GPL-3.0)

import Combine
import Defaults
import Foundation
import GachaMetaDB
import GachaMetaGeneratorModule
import HoYoKit

#if !os(watchOS)
// Swift 5 预设情况下不允许 SPM 的间接 import。
// Swift 6 允许，所以回头换 Swift 6 的时候得修改这个地方。
public typealias GachaMetaDBExposed = GachaMetaDB

// MARK: - GachaMetaDB.Sputnik

extension GachaMetaDB {
    public enum Sputnik {}

    /// 拿传入的简体中文翻译「是否在库」来检查资料库是否过期。
    public func checkIfExpired(againstTranslation names: Set<String>) -> Bool {
        !names.subtracting(Set<String>(GachaMetaDBExposed.shared.reversedDB.keys)).isEmpty
    }
}

extension GachaMetaDB {
    public static let shared = SharedDBSet()

    public class SharedDBSet: ObservableObject {
        // MARK: Lifecycle

        public init() {
            cancellables.append(
                Defaults.publisher(.localGachaMetaDBReversed).sink { _ in
                    self.reversedDB = Defaults[.localGachaMetaDBReversed]
                }
            )
            cancellables.append(
                Defaults.publisher(.localGachaMetaDB).sink { _ in
                    self.mainDB = Defaults[.localGachaMetaDB]
                }
            )
        }

        // MARK: Public

        @Published
        public var reversedDB = Defaults[.localGachaMetaDBReversed]
        @Published
        public var mainDB = Defaults[.localGachaMetaDB]

        public func reverseQuery(for name: String) -> Int? {
            reversedDB[name]
        }

        // MARK: Private

        private var cancellables: [AnyCancellable] = []
    }
}

extension GachaMetaDB.Sputnik {
    @MainActor
    public static func updateLocalGachaMetaDB() async throws {
        do {
            let newDB = try await fetchPreCompiledData()
            Defaults[.localGachaMetaDB] = newDB
            Defaults[.localGachaMetaDBReversed] = newDB.generateHotReverseQueryDict(for: "zh-cn") ?? [:]
        } catch {
            throw GachaMetaDB.GMDBError.resultFetchFailure(subError: error)
        }
    }

    static func fetchPreCompiledData(
        from serverType: Region = .mainlandChina
    ) async throws
        -> GachaMetaDB {
        var dataToParse = Data([])
        do {
            let (data, _) = try await URLSession.shared.data(
                for: URLRequest(url: serverType.gachaMetaDBRemoteURL)
            )
            dataToParse = data
        } catch {
            print(error.localizedDescription)
            print("// [GachaMetaDB.fetchPreCompiledData] Attempt using alternative JSON server source.")
            do {
                let (data, _) = try await URLSession.shared.data(
                    for: URLRequest(url: serverType.gmdbServerViceVersa.gachaMetaDBRemoteURL)
                )
                dataToParse = data
                // 如果这次成功的话，就自动修改偏好设定、今后就用这个资料源。
                let successMsg = "// [GachaMetaDB.fetchPreCompiledData] 2nd attempt succeeded."
                print(successMsg)
            } catch {
                print("// [GachaMetaDB.fetchPreCompiledData] Final attempt failed:")
                print(error.localizedDescription)
                throw error
            }
        }
        let requestResult = try JSONDecoder().decode(GachaMetaDB.self, from: dataToParse)
        return requestResult
    }
}

// MARK: - GachaMetaDB.GMDBError

extension GachaMetaDB {
    public enum GMDBError: Error, LocalizedError {
        case emptyFetchResult
        case resultFetchFailure(subError: Error)
        case databaseExpired

        // MARK: Public

        public var errorDescription: String? {
            switch self {
            case .emptyFetchResult:
                return "GachaMetaDBError.EmptyFetchResult".localized
            case let .resultFetchFailure(subError):
                return "GachaMetaDBError.ResultFetchFailed".localized + ": \(subError.localizedDescription)"
            case .databaseExpired:
                return "GachaMetaDBError.DatabaseExpired".localized
            }
        }
    }
}

extension Region {
    fileprivate var gmdbServerViceVersa: Self {
        switch self {
        case .mainlandChina: return .global
        case .global: return .mainlandChina
        }
    }

    public var gachaMetaDBRemoteURL: URL {
        var urlStr = ""
        switch self {
        case .mainlandChina:
            urlStr += #"https://gitlink.org.cn/attachments/entries/get_file?download_url="#
            urlStr += #"https://www.gitlink.org.cn/api/ShikiSuen/GachaMetaGenerator/raw/"#
            urlStr += #"Sources%2FGachaMetaDB%2FResources%2FOUTPUT-GI.json?ref=main"#
        case .global:
            urlStr += #"https://raw.githubusercontent.com/pizza-studio/"#
            urlStr += #"GachaMetaGenerator/main/Sources/GachaMetaDB/Resources/OUTPUT-GI.json"#
        }
        return URL(string: urlStr)!
    }
}
#endif
