//
//  Enum_CharacterAsset_SwiftUIImpl.swift
//  GenshinPizzaHepler
//
//  Created by ShikiSuen on 2023/10/5.
//

import Defaults
import GIPizzaKit
import SwiftUI

extension CharacterAsset {
    /// 显示角色的扑克牌尺寸肖像，以身份证素材裁切而成。
    @ViewBuilder
    public func cardIcon(
        _ size: CGFloat,
        costume: CostumeAsset? = nil,
        namecard givenNameCard: NameCard? = nil
    )
        -> some View {
        let costume = costume ?? Self.costumeMap[self]
        EnkaWebIcon(iconString: costume?.frontPhotoFileName ?? frontPhotoFileName)
            .scaledToFill()
            .frame(width: size * 0.74, height: size)
            .clipped()
            .scaledToFit()
            .background(
                EnkaWebIcon(
                    iconString: givenNameCard?.fileName ?? namecard.fileName
                )
                .scaledToFill()
                .offset(x: size / -3)
            )
            .clipShape(RoundedRectangle(cornerRadius: size / 10))
            .contentShape(RoundedRectangle(cornerRadius: size / 10))
            .compositingGroup()
    }

    /// 显示带有背景的角色肖像。
    /// - Parameters:
    ///   - size: 尺寸。
    ///   - cutType: 决定裁切到哪个身体部位。
    /// - Returns: SwiftUI "some View"
    @ViewBuilder
    public func decoratedIcon(
        _ size: CGFloat,
        cutTo cutType: DecoratedIconCutType = .shoulder,
        costume: CostumeAsset? = nil,
        namecard givenNameCard: NameCard? = nil,
        roundRect: Bool = false
    )
        -> some View {
        let costume = costume ?? Self.costumeMap[self]
        // 由于 Lava 强烈反对针对证件照的脸裁切与头裁切，
        // 所以不预设启用该功能。
        let cutType = !Defaults[.cutShouldersForSmallAvatarPhotos] ? .shoulder : cutType
        let ratio = 179.649 / 1024
        let cornerSize = CGSize(width: ratio * size, height: ratio * size)
        let roundCornerSize = CGSize(width: size / 2, height: size / 2)
        EnkaWebIcon(iconString: costume?.frontPhotoFileName ?? frontPhotoFileName)
            .scaledToFill()
            .frame(width: size * cutType.rawValue, height: size * cutType.rawValue)
            .clipped()
            .scaledToFit()
            .offset(y: cutType.shiftedAmount(containerSize: size))
            .background(
                ZStack {
                    EnkaWebIcon(
                        iconString: givenNameCard?.fileName ?? namecard.fileName
                    )
                    .scaledToFill()
                    .offset(x: size / -3)
                }
            )
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerSize: roundRect ? cornerSize : roundCornerSize))
            .contentShape(RoundedRectangle(cornerSize: roundRect ? cornerSize : roundCornerSize))
            .compositingGroup()
    }
}
