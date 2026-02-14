import SwiftUI
import WidgetKit

// MARK: - Navy Background ViewModifier
struct NavyBackground: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [AppConfig.Colors.navyCenter, AppConfig.Colors.navyEdge]),
                center: .center,
                startRadius: 100,
                endRadius: 600
            )
            .ignoresSafeArea()
            content
        }
    }
}

extension View {
    func navyBackground() -> some View { modifier(NavyBackground()) }
}

// MARK: - Card Background
struct CardBackground: View {
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [AppConfig.Colors.navyCenter, AppConfig.Colors.navyEdge]),
                center: .center,
                startRadius: 100,
                endRadius: 600
            )
            AppConfig.Colors.cardOverlay
        }
    }
}

// MARK: - Delete Gradient
struct DeleteGradient: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [AppConfig.Colors.deleteBurgundyLight, AppConfig.Colors.deleteBurgundyDark]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Quote Divider
struct QuoteDivider: View {
    var body: some View {
        Rectangle()
            .fill(AppConfig.Colors.divider)
            .frame(width: 40, height: 1)
    }
}

// MARK: - Field Background
struct FieldBackground: View {
    let focused: Bool
    let cornerRadius: CGFloat

    init(focused: Bool, cornerRadius: CGFloat = 8) {
        self.focused = focused
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(AppConfig.Colors.fieldFill)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        focused ? AppConfig.Colors.fieldFocused : AppConfig.Colors.fieldBorder,
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(AppConfig.Colors.textTertiary)

            TextField("", text: $text,
                      prompt: Text("Szukaj cytatu lub autora...")
                        .foregroundColor(AppConfig.Colors.textMuted)
                        .font(.system(size: 14, weight: .light)))
                .font(.system(size: 14, weight: .light))
                .foregroundColor(AppConfig.Colors.textPrimary)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppConfig.Colors.textTertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppConfig.Colors.searchFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(AppConfig.Colors.searchBorder, lineWidth: 1)
                )
        )
    }
}

// MARK: - Quote Row
struct QuoteRow: View {
    let quote: QuoteEntity
    @Binding var dragOffset: CGFloat
    let onDelete: () -> Void
    let onTap: () -> Void

    var body: some View {
        
        Color.clear
            .frame(height: AppConfig.Layout.cardHeight + AppConfig.Layout.cardSpacing)
            .overlay(alignment: .top) {
                GeometryReader { geometry in
                    ZStack {
                        // Delete button w tle - widoczny dopiero po przekroczeniu progu
                        HStack {
                            Spacer()
                            Button(action: onDelete) {
                                ZStack {
                                    DeleteGradient()
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 22, weight: .light))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(width: AppConfig.Layout.deleteWidth, height: geometry.size.height)
                            .opacity(min(1, max(0, (-dragOffset - 5) / 80)))
                        }

                        // Karta cytatu na wierzchu
                        VStack(spacing: 24) {
                            Text(quote.text ?? "")
                                .font(.system(size: 18, weight: .regular, design: .serif))
                                .foregroundColor(AppConfig.Colors.textPrimary)
                                .lineLimit(3)
                                .lineSpacing(6)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppConfig.Layout.cardPaddingH)

                            QuoteDivider()

                            Text(quote.author ?? "")
                                .font(.system(size: 13, weight: .light))
                                .tracking(2.0)
                                .foregroundColor(AppConfig.Colors.textSecondary)
                                .textCase(.uppercase)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, AppConfig.Layout.cardPaddingV)
                        .background(CardBackground())
                        .offset(x: dragOffset)
                        .gesture(
                            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                                .onChanged { value in
                                    // Tylko poziomy swipe - ignoruj pionowy
                                    let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                                    guard isHorizontal && value.translation.width < 0 else { return }
                                    dragOffset = max(value.translation.width, -AppConfig.Layout.deleteWidth)
                                }
                                .onEnded { value in
                                    let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                                    withAnimation(AppConfig.springAnimation) {
                                        if isHorizontal && value.translation.width < -AppConfig.Layout.swipeThreshold {
                                            dragOffset = -AppConfig.Layout.deleteWidth
                                        } else {
                                            dragOffset = 0
                                        }
                                    }
                                }
                        )
                        .onTapGesture {
                            if dragOffset < -20 {
                                withAnimation(AppConfig.springAnimation) { dragOffset = 0 }
                            } else {
                                onTap()
                            }
                        }
                    }
                }
                .frame(height: AppConfig.Layout.cardHeight)
            }
    }
}

// MARK: - Quote Form (Add + Edit)
struct QuoteFormView: View {
    enum Mode {
        case add
        case edit(QuoteEntity)

        var title: String {
            switch self {
            case .add:  return "Nowy cytat"
            case .edit: return "Edytuj cytat"
            }
        }
    }

    let mode: Mode
    @ObservedObject var quoteStore: QuoteStore
    @Environment(\.dismiss) var dismiss

    @State private var quoteText: String
    @State private var author: String
    @FocusState private var focusedField: Field?

    enum Field { case quote, author }

    init(mode: Mode, quoteStore: QuoteStore) {
        self.mode = mode
        self.quoteStore = quoteStore
        switch mode {
        case .add:
            _quoteText = State(initialValue: "")
            _author    = State(initialValue: "")
        case .edit(let entity):
            _quoteText = State(initialValue: entity.text ?? "")
            _author    = State(initialValue: entity.author ?? "")
        }
    }

    var isValid: Bool { !quoteText.isEmpty && !author.isEmpty }

    var body: some View {
        
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    
                    Color.clear.frame(height: 60)

                    formSection(label: "CYTAT") {
                        ZStack {
                            FieldBackground(focused: focusedField == .quote)
                                .frame(height: 220)

                            if quoteText.isEmpty {
                                Text("Dotknij aby dodać cytat...")
                                    .font(.system(size: 20, weight: .regular, design: .serif))
                                    .foregroundColor(AppConfig.Colors.textMuted)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                    .allowsHitTesting(false)
                            }

                            TextEditor(text: $quoteText)
                                .font(.system(size: 20, weight: .regular, design: .serif))
                                .foregroundColor(AppConfig.Colors.textPrimary)
                                .lineSpacing(8)
                                .frame(minHeight: 200)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 16)
                                .focused($focusedField, equals: .quote)
                        }
                        .frame(height: 220)
                    }

                    Color.clear.frame(height: 60)
                    QuoteDivider()
                    Color.clear.frame(height: 60)

                    formSection(label: "AUTOR") {
                        ZStack {
                            FieldBackground(focused: focusedField == .author, cornerRadius: 6)
                                .frame(height: 50)

                            TextField("", text: $author,
                                      prompt: Text("Dotknij aby dodać autora...")
                                        .foregroundColor(AppConfig.Colors.textMuted))
                                .font(.system(size: 14, weight: .light))
                                .tracking(2.0)
                                .foregroundColor(AppConfig.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .textCase(.uppercase)
                                .focused($focusedField, equals: .author)
                                .padding(.horizontal, 20)
                        }
                    }

                    Color.clear.frame(height: 100)
                }
            }
            .navyBackground()
            .preferredColorScheme(.dark)
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Anuluj") { dismiss() }
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(AppConfig.Colors.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Zapisz", action: save)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isValid ? AppConfig.Colors.textPrimary : AppConfig.Colors.textMuted)
                        .disabled(!isValid)
                }
            }
        }
    }

    @ViewBuilder
    private func formSection<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 16) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .tracking(3.0)
                .foregroundColor(AppConfig.Colors.textTertiary)
            content()
        }
        .padding(.horizontal, 40)
    }

    private func save() {
        switch mode {
        case .add:
            quoteStore.addQuote(text: quoteText, author: author)
        case .edit(let entity):
            quoteStore.updateQuote(entity, text: quoteText, author: author)
        }
        dismiss()
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var quoteStore = QuoteStore()
    @State private var showingAddQuote  = false
    @State private var dragOffsets: [UUID: CGFloat] = [:]
    @State private var selectedQuote: QuoteEntity?
    @State private var navigateToDetail = false

    var body: some View {
        NavigationView {
            ZStack {
                NavigationLink(
                    destination: Group {
                        if let q = selectedQuote {
                            QuoteDetailView(quote: q, quoteStore: quoteStore)
                        }
                    },
                    isActive: $navigateToDetail
                ) { EmptyView() }
                .hidden()

                VStack(spacing: 0) {
                    SearchBar(text: $quoteStore.searchText)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            Color.clear.frame(height: 20)

                            ForEach(quoteStore.quotes) { quote in
                                QuoteRow(
                                    quote: quote,
                                    dragOffset: Binding(
                                        get: { dragOffsets[quote.safeID] ?? 0 },
                                        set: { dragOffsets[quote.safeID] = $0 }
                                    ),
                                    onDelete: {
                                        withAnimation(AppConfig.springAnimation) {
                                            quoteStore.deleteQuote(quote)
                                            dragOffsets[quote.safeID] = nil
                                        }
                                    },
                                    onTap: {
                                        selectedQuote = quote
                                        navigateToDetail = true
                                    }
                                )
                            }

                            Color.clear.frame(height: 40)
                        }
                    }
                    .scrollDismissesKeyboard(.immediately)
                }
            }
            .navyBackground()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: refreshWidget) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20, weight: .thin))
                            .foregroundColor(AppConfig.Colors.textTertiary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Text("CYTATY")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(3.0)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                        Text("—")
                            .font(.system(size: 11, weight: .ultraLight))
                            .foregroundColor(AppConfig.Colors.textMuted)
                        Text("\(quoteStore.quotes.count)")
                            .font(.system(size: 11, weight: .light))
                            .tracking(1.0)
                            .foregroundColor(AppConfig.Colors.textTertiary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddQuote = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .thin))
                            .foregroundColor(AppConfig.Colors.textTertiary)
                    }
                }
            }
            .preferredColorScheme(.dark)
            .accentColor(AppConfig.Colors.textSecondary)
            .sheet(isPresented: $showingAddQuote) {
                QuoteFormView(mode: .add, quoteStore: quoteStore)
            }
            .onReceive(NotificationCenter.default.publisher(for: .quotesSearchChanged)) { _ in
                dragOffsets.removeAll()
            }
        }
    }

    private func refreshWidget() {
        AppConfig.defaults?.removeObject(forKey: AppConfig.Keys.pinnedQuoteID)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Quote Detail View
struct QuoteDetailView: View {
    let quote: QuoteEntity
    @ObservedObject var quoteStore: QuoteStore
    @Environment(\.dismiss) var dismiss

    @State private var showingEditSheet = false
    @State private var showingToast     = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Color.clear.frame(height: 80)

                Text(quote.text ?? "")
                    .font(.system(size: 22, weight: .regular, design: .serif))
                    .foregroundColor(AppConfig.Colors.textPrimary)
                    .lineSpacing(10)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .fixedSize(horizontal: false, vertical: true)

                Color.clear.frame(height: 48)
                QuoteDivider()
                Color.clear.frame(height: 48)

                Text(quote.author ?? "")
                    .font(.system(size: 13, weight: .light))
                    .tracking(2.5)
                    .foregroundColor(AppConfig.Colors.textSecondary)
                    .textCase(.uppercase)

                VStack(spacing: 8) {
                    Text("DODANO")
                        .font(.system(size: 9, weight: .medium))
                        .tracking(2.0)
                        .foregroundColor(AppConfig.Colors.textFaint)
                    Text(quote.dateAdded ?? Date(), style: .date)
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(AppConfig.Colors.textMuted)
                }
                .padding(.top, 48)

                Color.clear.frame(height: 100)
            }
        }
        .navyBackground()
        .preferredColorScheme(.dark)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Własny przycisk wstecz - bez niebieskiego
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .thin))
                        .foregroundColor(AppConfig.Colors.textSecondary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditSheet = true }) {
                        Label("Edytuj cytat", systemImage: "pencil")
                    }
                    Button(action: pinToWidget) {
                        Label("Ustaw w widgecie", systemImage: "rectangle.stack.badge.plus")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(AppConfig.Colors.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            QuoteFormView(mode: .edit(quote), quoteStore: quoteStore)
        }
        // 4. Toast zamiast alert
        .overlay(alignment: .bottom) {
            if showingToast {
                ToastView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 48)
            }
        }
        .animation(AppConfig.springAnimation, value: showingToast)
    }

    private func pinToWidget() {
        AppConfig.defaults?.set(quote.safeID.uuidString, forKey: AppConfig.Keys.pinnedQuoteID)
        WidgetCenter.shared.reloadAllTimelines()
        showToast()
    }

    private func showToast() {
        showingToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            showingToast = false
        }
    }
}


// MARK: - Toast View
struct ToastView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppConfig.Colors.textPrimary)

            Text("Ustawiono w widgecie")
                .font(.system(size: 13, weight: .light))
                .tracking(0.5)
                .foregroundColor(AppConfig.Colors.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
                .overlay(
                    Capsule()
                        .strokeBorder(AppConfig.Colors.divider, lineWidth: 1)
                )
        )
    }
}
