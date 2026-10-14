import SwiftUI

struct RootView: View {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var inactivityManager = InactivityManager()
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if authManager.showSplash {
                    SplashView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                authManager.checkAuthenticationStatus()
                            }
                        }
                } else if authManager.isAuthenticated {
                    DiamaPayHomeView()
                        .environmentObject(authManager)
                        .modifier(InactivityModifier(manager: inactivityManager, authManager: authManager))
                } else {
                    LoginView()
                        .environmentObject(authManager)
                }
            }
            .navigationBarHidden(true)
        }
        .onChange(of: authManager.isAuthenticated) { newValue in
            if !newValue {
                //print("🔄 Redirecting to login - clearing navigation stack")
                // Clear navigation path to go back to root
                navigationPath = NavigationPath()
            }
        }
        .id(authManager.isAuthenticated) // Force view refresh when auth state changes
    }
}
