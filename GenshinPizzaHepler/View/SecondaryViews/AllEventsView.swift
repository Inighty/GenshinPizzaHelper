//
//  AllEventsView.swift
//  GenshinPizzaHepler
//
//  Created by Bill Haku on 2022/9/19.
//

import SwiftUI

//@available (iOS 15, *)
struct AllEventsView: View {
    @Binding var eventContents: [EventModel]
    typealias IntervalDate = (month: Int?, day: Int?, hour: Int?, minute: Int?, second: Int?)
    @State var expandCards: Bool = false
    @State var currentCard: EventModel?
    @State var showDetailTransaction: Bool = false
    @Namespace var animation

    var body: some View {
        ScrollView {
            VStack {
                ForEach(eventContents, id:\.id) { content in
                    NavigationLink(destination: eventDetail(event: content)) {
                        CardView(content: content)
                    }
                }
            }
        }
        .navigationTitle("当前活动")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: CARD VIEW
    @ViewBuilder
    func CardView(content: EventModel) -> some View {
        VStack {
            ZStack {
                HStack {
                    Spacer()
                    Text("\(getLocalizedContent(content.name))")
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .font(.caption)
                }
                WebImage(urlStr: getLocalizedContent(content.banner))
                    .scaledToFill()
                    .cornerRadius(20)
                    .padding(.horizontal)
                VStack {
                    Spacer()
                    HStack {
                        HStack(spacing: 2) {
                            Image(systemName: "hourglass.circle")
                                .font(.caption)
                            Group {
                                if getRemainDays(content.endAt) == nil {
                                    Text("Error")
                                }
                                else if getRemainDays(content.endAt)!.day! > 0 {
                                    Text("剩余 \(getRemainDays(content.endAt)!.day!)天")
                                }
                                else {
                                    Text("剩余 \(getRemainDays(content.endAt)!.hour!)小时")
                                }
                            }
                            .padding(.trailing, 2)
                            .font(.caption)
                        }
                        .padding(2)
                        .opacityMaterial()
                        Spacer()
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    func eventDetail(event: EventModel) -> some View {
        HTMLStringView(htmlContent: generateHTMLString(banner: getLocalizedContent(event.banner), nameFull: getLocalizedContent(event.nameFull), description: getLocalizedContent(event.description)))
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(getLocalizedContent(event.name))
    }

    func getIndex(Card: EventModel)-> Int {
        return eventContents.firstIndex { currentCard in
            return currentCard.id == Card.id
        } ?? 0
    }

    func generateHTMLString(banner: String, nameFull: String, description: String) -> String {
        let format = "<head><style> img{ max-width: 100%; }</style> <meta charset=\"UTF-8\"> <meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\">  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"> <link rel=\"stylesheet\" href=\"http://zhuaiyuwen.xyz/static/event.css\">  <title>Document</title> </head>"
        let descriptionHTML = "<div class=\"testTable default-table margin-bottom-fix p-2 font-light leading-relaxed lg:p-4\">" + "<p><strong>\(nameFull)</strong></p><hr />" + description + "</div>"
        return format + "<body><img src=\"\(banner)\" alt=\"Event Banner\">" + descriptionHTML + "</body>"
    }

    func getLocalizedContent(_ content: EventModel.MultiLanguageContents) -> String {
        let locale = Locale.current.languageCode
        switch locale {
        case "zh":
            return content.CHS
        case "en":
            return content.EN
        case "ja":
            return content.JP
        default:
            return content.EN
        }
    }

    func getRemainDays(_ endAt: String) -> IntervalDate? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let endDate = dateFormatter.date(from: endAt)
        guard let endDate = endDate else {
            return nil
        }
        let interval = endDate - Date()
        return interval
    }
}

private extension View {
    func opacityMaterial() -> some View {
        if #available(iOS 15.0, *) {
            return self.background(.thinMaterial, in: Capsule())
        } else {
            return self.background(Color(UIColor.systemBackground).opacity(0.8).clipShape(Capsule()))
        }
    }
}