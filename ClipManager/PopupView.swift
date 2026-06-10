import SwiftUI

struct PopupView: View {
    let model: PopupModel
    var tick: Int = 0

    var body: some View {
        @Bindable var settings = model.settings
        @Bindable var model = model
        VStack(spacing: 0) {
            header(settings: settings)
            Divider()
            if model.settings.searchEnabled {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Поиск…", text: $model.query)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                Divider()
            }
            content
        }
        .frame(minWidth: 280, minHeight: 220)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .clipShape(.rect(cornerRadius: 16))
    }

    private func header(settings: AppSettings) -> some View {
        HStack(spacing: 8) {
            Text("Буфер обмена")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
            toggleButton("magnifyingglass", on: settings.searchEnabled, help: "Поиск") {
                settings.searchEnabled.toggle()
            }
            toggleButton("pin", on: settings.pinEnabled, help: "Избранное") {
                settings.pinEnabled.toggle()
            }
            toggleButton("textformat", on: settings.plainPasteEnabled, help: "Вставка без формата (⌥↵)") {
                settings.plainPasteEnabled.toggle()
            }
            toggleButton("key", on: settings.skipPasswords, help: "Пропускать пароли") {
                settings.skipPasswords.toggle()
            }
            Button {
                model.onOpenSettings()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 12))
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color.secondary)
            }
            .buttonStyle(.glass)
            .help("Настройки (лимит истории и др.)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
    }

    private func toggleButton(_ symbol: String, on: Bool, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12))
                .frame(width: 24, height: 24)
                .foregroundStyle(on ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.glass)
        .help(help)
    }

    @ViewBuilder
    private var content: some View {
        let items = model.filtered
        if items.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "tray")
                    .font(.system(size: 28))
                    .foregroundStyle(.tertiary)
                Text(model.query.isEmpty ? "История пуста" : "Ничего не найдено")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                            RowView(
                                item: item,
                                selected: idx == model.selectedIndex,
                                pinEnabled: model.settings.pinEnabled,
                                plainEnabled: model.settings.plainPasteEnabled,
                                onChoose: { model.onChoose(item, false) },
                                onChoosePlain: { model.onChoose(item, true) },
                                onPin: { model.store.togglePin(item.id) },
                                onDelete: { model.store.remove(item.id) }
                            )
                            .id(idx)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                model.selectedIndex = idx
                                model.onChoose(item, false)
                            }
                        }
                    }
                    .padding(6)
                }
                .onChange(of: model.selectedIndex) { _, newValue in
                    withAnimation(.easeOut(duration: 0.12)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
    }
}

private struct RowView: View {
    let item: ClipboardItem
    let selected: Bool
    let pinEnabled: Bool
    let plainEnabled: Bool
    let onChoose: () -> Void
    let onChoosePlain: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            icon
                .frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.previewText)
                    .lineLimit(2)
                    .font(.system(size: 13))
                Text(item.createdAt, format: .relative(presentation: .numeric))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(selected ? Color.accentColor.opacity(0.25) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contextMenu {
            Button("Вставить", action: onChoose)
            if plainEnabled, item.kind == .rtf {
                Button("Вставить без формата", action: onChoosePlain)
            }
            if pinEnabled {
                Button(item.isPinned ? "Открепить" : "Закрепить", action: onPin)
            }
            Divider()
            Button("Удалить", role: .destructive, action: onDelete)
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch item.kind {
        case .image:
            if let name = item.blobFileName,
               let nsImage = NSImage(contentsOf: Storage.blobURL(name)) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            } else {
                symbol("photo")
            }
        case .file:
            symbol("doc")
        case .rtf:
            symbol("doc.richtext")
        case .text:
            symbol("text.alignleft")
        }
    }

    private func symbol(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 16))
            .foregroundStyle(.secondary)
            .frame(width: 30, height: 30)
    }
}
