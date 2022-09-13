//
//  AccountBasicInfosView.swift
//  GenshinPizzaHepler
//
//  Created by Bill Haku on 2022/9/13.
//

import SwiftUI

struct AccountBasicInfosView: View {
    @Binding var basicAccountInfo: BasicInfos?

    var body: some View {
        if let basicAccountInfo = basicAccountInfo {
            Section (header: Text("基本信息")) {
                HStack {
                    VStack(spacing: 3) {
                        InfoPreviewer(title: "活跃天数", content: "\(basicAccountInfo.stats.activeDayNumber)", contentStyle: .capsule)
                        InfoPreviewer(title: "获得角色", content: "\(basicAccountInfo.stats.avatarNumber)", contentStyle: .capsule)
                        InfoPreviewer(title: "深境螺旋", content: basicAccountInfo.stats.spiralAbyss, contentStyle: .capsule)
                        InfoPreviewer(title: "普通宝箱", content: "\(basicAccountInfo.stats.commonChestNumber)", contentStyle: .capsule)
                        InfoPreviewer(title: "珍贵宝箱", content: "\(basicAccountInfo.stats.preciousChestNumber)", contentStyle: .capsule)
                        InfoPreviewer(title: "风神瞳", content: "\(basicAccountInfo.stats.anemoculusNumber)", contentStyle: .capsule)
                        InfoPreviewer(title: "雷神瞳", content: "\(basicAccountInfo.stats.electroculusNumber)", contentStyle: .capsule)
                    }
                    VStack(spacing: 3) {
                        InfoPreviewer(title: "成就达成", content: "\(basicAccountInfo.stats.achievementNumber)", contentStyle: .capsule)
                        InfoPreviewer(title: "解锁锚点", content: "\(basicAccountInfo.stats.wayPointNumber)", contentStyle: .capsule)
                        InfoPreviewer(title: "解锁秘境", content: "\(basicAccountInfo.stats.domainNumber)", contentStyle: .capsule)
                        InfoPreviewer(title: "精致宝箱", content: "\(basicAccountInfo.stats.exquisiteChestNumber)", contentStyle: .capsule)
                        InfoPreviewer(title: "华丽宝箱", content: "\(basicAccountInfo.stats.preciousChestNumber)", contentStyle: .capsule)
                        InfoPreviewer(title: "岩神瞳", content: "\(basicAccountInfo.stats.geoculusNumber)", contentStyle: .capsule)
                        InfoPreviewer(title: "草神瞳", content: "\(basicAccountInfo.stats.dendroculusNumber)", contentStyle: .capsule)
                    }
                }
            }
            Section (header: Text("世界探索")) {
                ForEach(basicAccountInfo.worldExplorations.reversed(), id: \.id) { worldData in
                    WorldExplorationsView(data: worldData)
                }
            }
        } else {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
        }
    }
}

private struct WorldExplorationsView: View {
    var data: BasicInfos.WorldExploration

    var body: some View {
        HStack {
            WebImage(urlStr: data.icon)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading) {
                Text(data.name)
                Text(calculatePercentage(value: Double(data.explorationPercentage) / Double(1000)))
            }
            Spacer()
        }
    }

    func calculatePercentage(value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter.string(from: value as NSNumber) ?? "Error"
    }
}
