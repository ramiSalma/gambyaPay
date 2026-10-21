import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var requirePin = UserDefaults.standard.object(forKey: "requirePinForEveryTransaction") as? Bool ?? true
    @State private var showSecurityQuestionInfo = false

    private let blue = Color(hex: "174EA6")
    private let cyan = Color(hex: "087FB3")

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                DiamaPayHeader(title: "Security Settings", headerColor: blue)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        pinRequirementCard
                        securityOptionsCard
                        importantInformationCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 20)
                    .padding(.bottom, 28)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppBottomBar(
                onSponsors: {}, onQR: {}, onLimits: {}, onSettings: {},
                selectedTab: "Settings", onHome: { dismiss() }
            )
        }
        .navigationBarHidden(true)
        .alert("Security question", isPresented: $showSecurityQuestionInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("To update your security question, please contact customer support.")
        }
    }

    private var pinRequirementCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundColor(blue)
                    .frame(width: 40)
                Text("Require PIN for every transaction")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                Toggle("Require PIN for every transaction", isOn: $requirePin)
                    .labelsHidden()
                    .tint(blue)
                    .onChange(of: requirePin) { _, value in
                        UserDefaults.standard.set(value, forKey: "requirePinForEveryTransaction")
                    }
            }

            Text("When disabled, you can complete up to 5 transactions without entering your PIN after the first verification")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.gray)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(cyan)
                    Text("Transactions without PIN")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    Spacer(minLength: 4)
                    Text("0 / 5")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(cyan)
                }
                Text(requirePin
                     ? "A PIN is required for every transaction."
                     : "You can complete 5 more transactions without entering your PIN")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "E5F3FF"))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(cyan, lineWidth: 1.5))
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(blue, lineWidth: 1.5))
        .shadow(color: blue.opacity(0.10), radius: 5, x: 0, y: 3)
    }

    private var securityOptionsCard: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: ChangePinView()) {
                settingsRow(icon: "asterisk", title: "Change PIN")
            }
            .buttonStyle(.plain)

            divider

            Button { showSecurityQuestionInfo = true } label: {
                settingsRow(icon: "questionmark.circle.fill", title: "Change security question")
            }
            .buttonStyle(.plain)

            divider

            NavigationLink(destination: BiometricSettingsView()) {
                HStack(spacing: 16) {
                    Image(systemName: "touchid")
                        .font(.system(size: 25, weight: .regular))
                        .foregroundColor(blue)
                        .frame(width: 40)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Biometric Authentication")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                        Text("Use fingerprint or face unlock")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Capsule()
                        .fill(Color.gray.opacity(0.28))
                        .frame(width: 46, height: 26)
                        .overlay(alignment: UserDataManager.shared.isBiometricEnabled() ? .trailing : .leading) {
                            Circle()
                                .fill(blue)
                                .frame(width: 26, height: 26)
                                .shadow(color: blue.opacity(0.2), radius: 2, y: 1)
                        }
                }
                .padding(.vertical, 22)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(blue, lineWidth: 1.5))
        .shadow(color: blue.opacity(0.10), radius: 5, x: 0, y: 3)
    }

    private var importantInformationCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("Important Information", systemImage: "info.circle.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(cyan)
            informationBullet("Your PIN is required after 5 consecutive transactions or when security settings change")
            informationBullet("Always keep your PIN secure and never share it with anyone")
            informationBullet("The transaction counter resets to 0 each time you enter your PIN")
            informationBullet("You can disable PIN bypass at any time in these settings")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(cyan, lineWidth: 1.5))
        .shadow(color: blue.opacity(0.08), radius: 5, x: 0, y: 3)
    }

    private func settingsRow(icon: String, title: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(blue)
                .frame(width: 40)
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 22)
        .contentShape(Rectangle())
    }

    private var divider: some View {
        Rectangle().fill(Color(hex: "D9D9D9")).frame(height: 1)
    }

    private func informationBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle().fill(cyan).frame(width: 8, height: 8).padding(.top, 6)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "475467"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
