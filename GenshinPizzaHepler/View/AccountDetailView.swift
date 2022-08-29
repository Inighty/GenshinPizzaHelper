//
//  AccountDetailView.swift
//  GenshinPizzaHepler
//
//  Created by Bill Haku on 2022/8/7.
//

import SwiftUI

struct AccountDetailView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    @Binding var account: Account
    
    var bindingName: Binding<String> {
        Binding($account.config.name)!
    }
    var bindingUid: Binding<String> {
        Binding($account.config.uid)!
    }
    var bindingCookie: Binding<String> {
        Binding($account.config.cookie)!
    }
    var bindingServer: Binding<Server> {
        Binding(projectedValue: $account.config.server)
    }
    
    var name: String {
        account.config.name!
    }
    var uid: String {
        account.config.uid!
    }
    var cookie: String {
        account.config.cookie!
    }
    var server: Server {
        account.config.server
    }

    @State private var isPresentingConfirm: Bool = false
    @State private var isSheetShow: Bool = false
    
    @State private var isWebShown: Bool = false

    @State private var connectStatus: ConnectStatus = .unknown
    
    var body: some View {
        List {
            Button("重新登录米游社帐号") { isWebShown.toggle() }
            Section(header: Text("帐号配置")) {
                NavigationLink(destination: TextFieldEditorView(title: "帐号名".localized, note: "你可以自定义显示在小组件上的帐号名称".localized, content: bindingName)) {
                    InfoPreviewer(title: "帐号名", content: name)
                }
                NavigationLink(destination: TextFieldEditorView(title: "UID", content: bindingUid, keyboardType: .numberPad)) {
                    InfoPreviewer(title: "UID", content: uid)
                }
                NavigationLink(destination: TextEditorView(title: "Cookie", content: bindingCookie, showPasteButton: true)) {
                    Text("Cookie")
                }
                Picker("服务器", selection: $account.config.server) {
                    ForEach(Server.allCases, id: \.self) { server in
                        Text(server.rawValue)
                            .tag(server)
                    }
                }
            }
            TestSectionView(connectStatus: $connectStatus, uid: bindingUid, cookie: bindingCookie, server: bindingServer)
        }
        .navigationBarTitle("帐号信息", displayMode: .inline)
        .onDisappear {
            viewModel.saveAccount()
        }
        .sheet(isPresented: $isSheetShow) {
            NavigationView {
                WebBroswerView(url: "http://zhuaiyuwen.xyz/static/donate.html")
                    .navigationTitle("支持我们")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $isWebShown) {
            GetCookieWebView(isShown: $isWebShown, cookie: bindingCookie, region: server.region)
        }
        .onAppear {
            connectStatus = .testing
        }
    }
}
