import DefaultBackend
import Foundation
import SwiftCrossUI

#if canImport(SwiftBundlerRuntime)
    import SwiftBundlerRuntime
#endif

enum SubjectArea {
    case science
    case humanities
}

enum ScienceSubject {
    case physics
    case chemistry
}

enum HumanitiesSubject {
    case english
    case history
}

enum Columns {
    case two
    case three
}

class SplitAppState: Observable {
    @Observed var selectedArea: SubjectArea?
    @Observed var selectedDetail: Any?
    @Observed var columns: Columns = .two
}

struct ContentView: View {
    var state = SplitAppState()

    var body: some View {
        switch state.columns {
            case .two:
                doubleColumn
            case .three:
                tripleColumn
        }
    }

    /// Example view for a two column NavigationSplitView
    var doubleColumn: some View {
        NavigationSplitView {
            VStack {
                Button("Science") { state.selectedArea = .science }
                Button("Humanities") { state.selectedArea = .humanities }
                Spacer()
                Button("Switch to 3 column example") { state.columns = .three }
            }.padding(10)
        } detail: {
            VStack {
                switch state.selectedArea {
                    case .science:
                        Text("Science")
                    case .humanities:
                        Text("Humanities")
                    case nil:
                        Text("Select an area")
                }
            }.padding(10)
        }
    }

    /// Example view for a three column NavigationSplitView
    var tripleColumn: some View {
        NavigationSplitView {
            VStack {
                Button("Science") { state.selectedArea = .science }
                Button("Humanities") { state.selectedArea = .humanities }
                Spacer()
                Button("Switch to 2 column example") { state.columns = .two }
            }.padding(10)
        } content: {
            VStack {
                switch state.selectedArea {
                    case .science:
                        Text("Choose a science subject")
                            .padding(.bottom, 10)
                        Button("Physics") { state.selectedDetail = ScienceSubject.physics }
                        Button("Chemistry") { state.selectedDetail = ScienceSubject.chemistry }
                    case .humanities:
                        Text("Choose a humanities subject")
                            .padding(.bottom, 10)
                        Button("English") { state.selectedDetail = HumanitiesSubject.english }
                        Button("History") { state.selectedDetail = HumanitiesSubject.history }
                    case nil:
                        Text("Select an area")
                }
            }
            .padding(10)
            .frame(minWidth: 190)
        } detail: {
            VStack {
                switch state.selectedDetail {
                    case let subject as ScienceSubject:
                        switch subject {
                            case .physics:
                                Text("Physics is applied maths")
                            case .chemistry:
                                Text("Chemistry is applied physics")
                        }
                    case let subject as HumanitiesSubject:
                        switch subject {
                            case .english:
                                Text("I don't like essays")
                            case .history:
                                Text("Don't repeat it")
                        }
                    default:
                        Text("Select a subject")
                }
            }
            .padding(10)
        }
    }
}

@main
@HotReloadable
struct SplitApp: App {
    var body: some Scene {
        WindowGroup("Split") {
            #hotReloadable {
                ContentView()
            }
        }
        .defaultSize(width: 600, height: 250)
    }
}
