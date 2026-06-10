import SwiftUI

struct SettingsView: View {
    let settings: AppSettings
    let store: HistoryStore
    let onHotKeyChanged: () -> Void

    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var accessibilityOK = PasteService.accessibilityGranted

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section("Окно истории") {
                HStack {
                    Text("Хоткей вызова")
                    Spacer()
                    HotKeyRecorder(settings: settings, onChange: onHotKeyChanged)
                        .frame(width: 150, height: 28)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Размер истории")
                        Spacer()
                        Text("\(settings.maxHistory)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(settings.maxHistory) },
                            set: { settings.maxHistory = Int($0); store.enforceLimit() }
                        ),
                        in: 1...100,
                        step: 1
                    )
                }
            }

            Section("Поведение") {
                Toggle("Авто-вставка после выбора", isOn: $settings.autoPaste)
                Toggle("Запуск при входе в систему", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, value in
                        LaunchAtLogin.set(value)
                    }
            }

            Section("Фичи") {
                Toggle("Поиск по истории", isOn: $settings.searchEnabled)
                Toggle("Избранное (закрепление)", isOn: $settings.pinEnabled)
                Toggle("Вставка без формата (⌥↵)", isOn: $settings.plainPasteEnabled)
                Toggle("Пропускать пароли", isOn: $settings.skipPasswords)
            }

            Section("Доступ") {
                HStack(spacing: 8) {
                    Image(systemName: accessibilityOK ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(accessibilityOK ? .green : .orange)
                    Text(accessibilityOK
                         ? "Accessibility разрешён"
                         : "Нужен Accessibility для авто-вставки")
                        .font(.system(size: 12))
                    Spacer()
                    if !accessibilityOK {
                        Button("Разрешить") { PasteService.requestAccessibility() }
                    }
                }
            }

            Section {
                Button("Очистить историю", role: .destructive) {
                    store.clear()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 560)
        .onAppear {
            accessibilityOK = PasteService.accessibilityGranted
            launchAtLogin = LaunchAtLogin.isEnabled
        }
    }
}
