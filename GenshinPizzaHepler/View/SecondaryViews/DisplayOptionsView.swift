//
//  DisplayOptionsView.swift
//  GenshinPizzaHepler
//
//  Created by ShikiSuen on 2023/3/29.
//  界面偏好设置页面。

import Combine
import Defaults
import GIPizzaKit
import HBMihoyoAPI
import SwiftUI

// MARK: - DisplayOptionsView

struct DisplayOptionsView: View {
    // MARK: Internal

    var body: some View {
        Group {
            mainView()
                .alert(
                    "settings.display.prompt.customizingNameForKunikuzushi",
                    isPresented: $isCustomizedNameForWandererAlertShow,
                    actions: {
                        TextField("settings.display.customizedNameForKunikuzushi", text: $customizedNameForWanderer)
                            .onReceive(Just(customizedNameForWanderer)) { _ in limitText(20) }
                        Button("sys.done") {
                            isCustomizedNameForWandererAlertShow.toggle()
                        }
                    }
                )
        }
        .navigationBarTitle("settings.display.title", displayMode: .inline)
    }

    // Function to keep text length in limits
    func limitText(_ upper: Int) {
        if customizedNameForWanderer.count > upper {
            customizedNameForWanderer = String(customizedNameForWanderer.prefix(upper))
        }
    }

    @ViewBuilder
    func mainView() -> some View {
        List {
            Section {
                Toggle(isOn: $restoreTabOnLaunching) {
                    Text("setting.uirelated.restoreTabOnLaunching")
                }
                Picker("settings.display.appBackgroundNameCardID", selection: $appBackgroundNameCardID) {
                    ForEach(NameCard.allLegalCases, id: \.rawValue) { card in
                        Label {
                            Text(card.localized)
                        } icon: {
                            GeometryReader { g in
                                Image(card.fileName)
                                    .resizable()
                                    .scaledToFill()
                                    .offset(x: -g.size.width)
                            }
                            .clipShape(Circle())
                            .frame(width: 30, height: 30)
                        }.tag(card)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section {
                Toggle(isOn: $animateOnCallingCharacterShowcase) {
                    Text("settings.display.animateOnCallingCharacterShowcase.title")
                }
            }

            if Locale.isUILanguagePanChinese {
                Section {
                    Toggle(isOn: $forceCharacterWeaponNameFixed) {
                        Text("settings.display.chineseKanjiCorrection.title")
                    }
                } footer: {
                    Text(
                        "settings.display.chineseKanjiCorrection.description"
                    )
                }
            }

            Section {
                Toggle(isOn: $showRarityAndLevelForArtifacts) {
                    Text("settings.display.showArtifactRarityAndLevel")
                }
                Toggle(isOn: $artifactRatingOptions.bind(.enabled, animate: true)) {
                    Text("settings.display.artifactRatingOptions")
                }
                if artifactRatingOptions.contains(.enabled) {
                    Toggle(isOn: $artifactRatingOptions.bind(.considerMainProps)) {
                        Text("settings.display.artifactRatingOptions.considerMainProps")
                    }
                    Toggle(isOn: $artifactRatingOptions.bind(.considerHyperbloomElectroRoles)) {
                        Text("settings.display.artifactRatingOptions.considerHyperBloomElectroRoles")
                    }
                }
            }

            Section {
                Toggle(isOn: $useActualCharacterNames.animation()) {
                    Text("settings.display.useActualCharacterNames")
                }

                if !useActualCharacterNames {
                    if #unavailable(iOS 16) {
                        HStack {
                            Text("settings.display.customizingNameForKunikuzushi")
                            Spacer()
                            TextField("流浪者".localized, text: $customizedNameForWanderer)
                                .multilineTextAlignment(.trailing)
                        }
                    } else {
                        HStack {
                            Text("settings.display.customizingNameForKunikuzushi")
                            Spacer()
                            Button(customizedNameForWanderer == "" ? "流浪者".localized : customizedNameForWanderer) {
                                isCustomizedNameForWandererAlertShow.toggle()
                            }
                        }
                    }
                }
            }

            if ThisDevice.notchType != .none || OS.type != .iPhoneOS {
                Section {
                    Toggle(isOn: $adaptiveSpacingInCharacterView) {
                        Text("settings.display.autoLineSpacingForEASV")
                    }
                } footer: {
                    Text(
                        "settings.display.autoLineSpacingForEASV.onlyWorksWithNotchedPhones"
                    )
                }
            }

            Section {
                Toggle(isOn: $cutShouldersForSmallAvatarPhotos) {
                    Text("settings.display.cutShouldersForSmallPhotos")
                }
            }

            Section {
                Toggle(isOn: $useGuestGachaEvaluator) {
                    Text("settings.uiRelated.useGuestGachaEvaluator")
                }
            }
        }
    }

    // MARK: Private

    @Default(.useGuestGachaEvaluator)
    private var useGuestGachaEvaluator: Bool

    @ObservedObject
    private var viewModel: MoreViewCacheViewModel = .init()

    @State
    private var isCustomizedNameForWandererAlertShow: Bool = false

    @Default(.restoreTabOnLaunching)
    private var restoreTabOnLaunching: Bool
    @Default(.adaptiveSpacingInCharacterView)
    private var adaptiveSpacingInCharacterView: Bool
    @Default(.showRarityAndLevelForArtifacts)
    private var showRarityAndLevelForArtifacts: Bool
    @Default(.artifactRatingOptions)
    private var artifactRatingOptions: ArtifactRatingOptions
    @Default(.forceCharacterWeaponNameFixed)
    private var forceCharacterWeaponNameFixed: Bool
    @Default(.useActualCharacterNames)
    private var useActualCharacterNames: Bool
    @Default(.customizedNameForWanderer)
    private var customizedNameForWanderer: String
    @Default(.cutShouldersForSmallAvatarPhotos)
    private var cutShouldersForSmallAvatarPhotos: Bool
    @Default(.appBackgroundNameCardID)
    private var appBackgroundNameCardID: NameCard
    @Default(.animateOnCallingCharacterShowcase)
    private var animateOnCallingCharacterShowcase: Bool
}
