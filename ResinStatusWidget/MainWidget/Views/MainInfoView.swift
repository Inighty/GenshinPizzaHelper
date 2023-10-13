//
//  MainInfoView.swift
//  ResinStatusWidgetExtension
//
//  Created by Bill Haku on 2022/8/6.
//  Widget树脂部分布局

import AppIntents
import Foundation
import HBMihoyoAPI
import SFSafeSymbols
import SwiftUI

// MARK: - MainInfo

struct MainInfo: View {
    let userData: UserData
    let viewConfig: WidgetViewConfiguration
    let accountName: String?
    let accountNameTest = "settings.account.myAccount"

    var condensedResin: Int { userData.resinInfo.currentResin / 40 }

    var body: some View {
        let transformerCompleted: Bool = userData.transformerInfo
            .isComplete && userData.transformerInfo.obtained && viewConfig
            .showTransformer
        let expeditionCompleted: Bool = viewConfig.expeditionViewConfig
            .noticeExpeditionWhenAllCompleted ? userData.expeditionInfo
            .allCompleted : userData.expeditionInfo.anyCompleted
        let weeklyBossesNotice: Bool = (
            viewConfig
                .weeklyBossesShowingMethod != .neverShow
        ) && !userData
            .weeklyBossesInfo.isComplete && Calendar.current
            .isDateInWeekend(Date())
        let dailyTaskNotice: Bool = !userData.dailyTaskInfo
            .isTaskRewardReceived &&
            (
                userData.dailyTaskInfo.finishedTaskNum == userData.dailyTaskInfo
                    .totalTaskNum
            )

        // 需要马上上号
        let needToLoginImediately: Bool = (
            userData.resinInfo
                .isFull ||
                (
                    userData.homeCoinInfo.isFull && userData.homeCoinInfo
                        .maxHomeCoin != 300
                ) || expeditionCompleted || transformerCompleted ||
                dailyTaskNotice
        )
        // 可以晚些再上号，包括每日任务和周本
        let needToLoginSoon: Bool = !userData.dailyTaskInfo
            .isTaskRewardReceived || weeklyBossesNotice

        VStack(alignment: .leading, spacing: 0) {
            if let accountName = accountName {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Image(systemSymbol: .personFill)
                    Text(accountName)
                        .allowsTightening(true)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .font(.footnote)
                .foregroundColor(Color("textColor3"))
                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(userData.resinInfo.currentResin)")
                    .font(.system(size: 50, design: .rounded))
                    .fontWeight(.medium)
                    .minimumScaleFactor(0.1)
                    .foregroundColor(Color("textColor3"))
                    .shadow(radius: 1)
                Image("树脂")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 30)
                    .alignmentGuide(.firstTextBaseline) { context in
                        context[.bottom] - 0.17 * context.height
                    }
                    .shadow(radius: 0.8)
            }
            Spacer()
            HStack {
                if #available(iOS 17, *) {
                    Button(intent: WidgetRefreshIntent()) {
                        Image(systemSymbol: .arrowClockwiseCircle)
                            .font(.title3)
                            .foregroundColor(Color("textColor3"))
                            .clipShape(.circle)
                    }
                    .buttonStyle(.plain)
                } else {
                    if needToLoginImediately {
                        if needToLoginSoon {
                            Image("exclamationmark.circle.questionmark")
                                .foregroundColor(Color("textColor3"))
                                .font(.title3)
                        } else {
                            Image(systemSymbol: .exclamationmarkCircle)
                                .foregroundColor(Color("textColor3"))
                                .font(.title3)
                        }
                    } else if needToLoginSoon {
                        Image("hourglass.circle.questionmark")
                            .foregroundColor(Color("textColor3"))
                            .font(.title3)
                    } else {
                        Image("hourglass.circle")
                            .foregroundColor(Color("textColor3"))
                            .font(.title3)
                    }
                }
                RecoveryTimeText(resinInfo: userData.resinInfo)
            }
        }
    }
}

// MARK: - MainInfoSimplified

struct MainInfoSimplified: View {
    let userData: SimplifiedUserData
    let viewConfig: WidgetViewConfiguration
    let accountName: String?
    let accountNameTest = "settings.account.myAccount"

    var condensedResin: Int { userData.resinInfo.currentResin / 40 }

    var body: some View {
        let expeditionCompleted: Bool = viewConfig.expeditionViewConfig
            .noticeExpeditionWhenAllCompleted ? userData.expeditionInfo
            .allCompleted : userData.expeditionInfo.anyCompleted
        let dailyTaskNotice: Bool = !userData.dailyTaskInfo
            .isTaskRewardReceived &&
            (
                userData.dailyTaskInfo.finishedTaskNum == userData.dailyTaskInfo
                    .totalTaskNum
            )

        // 需要马上上号
        let needToLoginImediately: Bool = (
            userData.resinInfo.isFull || userData
                .homeCoinInfo.isFull || expeditionCompleted || dailyTaskNotice
        )
        // 可以晚些再上号，包括每日任务和周本
        let needToLoginSoon: Bool = !userData.dailyTaskInfo.isTaskRewardReceived

        VStack(alignment: .leading, spacing: 0) {
            if let accountName = accountName {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Image(systemSymbol: .personFill)
                    Text(accountName)
                        .allowsTightening(true)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .font(.footnote)
                .foregroundColor(Color("textColor3"))
                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(userData.resinInfo.currentResin)")
                    .font(.system(size: 50, design: .rounded))
                    .fontWeight(.medium)
                    .minimumScaleFactor(0.1)
                    .foregroundColor(Color("textColor3"))
                    .shadow(radius: 1)
                Image("树脂")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 30)
                    .alignmentGuide(.firstTextBaseline) { context in
                        context[.bottom] - 0.17 * context.height
                    }
                    .shadow(radius: 0.8)
            }
            Spacer()
            HStack {
                if #available(iOS 17, *) {
                    Button(intent: WidgetRefreshIntent()) {
                        Image(systemSymbol: .arrowClockwiseCircle)
                            .font(.title3)
                            .foregroundColor(Color("textColor3"))
                            .clipShape(.circle)
                    }
                    .buttonStyle(.plain)
                } else {
                    if needToLoginImediately {
                        if needToLoginSoon {
                            Image("exclamationmark.circle.questionmark")
                                .foregroundColor(Color("textColor3"))
                                .font(.title3)
                        } else {
                            Image(systemSymbol: .exclamationmarkCircle)
                                .foregroundColor(Color("textColor3"))
                                .font(.title3)
                        }
                    } else if needToLoginSoon {
                        Image("hourglass.circle.questionmark")
                            .foregroundColor(Color("textColor3"))
                            .font(.title3)
                    } else {
                        Image("hourglass.circle")
                            .foregroundColor(Color("textColor3"))
                            .font(.title3)
                    }
                }
                RecoveryTimeText(resinInfo: userData.resinInfo)
            }
        }
    }
}

// MARK: - WidgetRefreshIntent

@available(iOSApplicationExtension 16, iOS 16, *)
struct WidgetRefreshIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh"

    func perform() async throws -> some IntentResult {
        .result()
    }
}
