//
//  LoginView.swift
//  Atenea
//
//  Login screen with email/phone and social auth options
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Binding var isLoggedIn: Bool
    @State private var emailOrPhone: String = ""
    @State private var agreedToTerms: Bool = false
    @State private var showingHelp: Bool = false
    @State private var showingRegister: Bool = false

    // Check if continue button should be enabled
    private var canContinue: Bool {
        !emailOrPhone.isEmpty && agreedToTerms
    }

    var body: some View {
        ZStack {
            // Background with slight blur effect
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with help and close buttons
                HStack {
                    Spacer()

                    Button(action: {
                        showingHelp = true
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                    }
                    .accessibilityLabel(LocalizedString("login.help"))

                    Button(action: {
                        // Skip login for now
                        isLoggedIn = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                    }
                    .padding(.leading, 16)
                    .accessibilityLabel(LocalizedString("login.close"))
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedString("login.welcome"))
                                .font(.system(size: 28, weight: .regular))
                                .foregroundColor(.black)

                            Text(LocalizedString("login.appName"))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)
                        }
                        .padding(.top, 30)

                        // Email or Phone input
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedString("login.emailOrPhone"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)

                            TextField(LocalizedString("login.emailPlaceholder"), text: $emailOrPhone)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 16))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                )
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                        }
                        .padding(.top, 8)

                        // Terms of service checkbox
                        HStack(alignment: .top, spacing: 12) {
                            Button(action: {
                                agreedToTerms.toggle()
                            }) {
                                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 20))
                                    .foregroundColor(agreedToTerms ? Color(hex: "#0072CE") : .gray)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizedString("login.terms"))
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                +
                                Text(" ")
                                +
                                Text(LocalizedString("login.termsLink"))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "#0072CE"))
                                +
                                Text(" ")
                                +
                                Text(LocalizedString("login.and"))
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                +
                                Text(" ")
                                +
                                Text(LocalizedString("login.privacyLink"))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "#0072CE"))
                            }
                        }
                        .padding(.top, 8)

                        // Continue button
                        Button(action: {
                            handleEmailLogin()
                        }) {
                            Text(LocalizedString("login.continue"))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(canContinue ? .white : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(canContinue ? Color.gray : Color.gray.opacity(0.3))
                                )
                        }
                        .disabled(!canContinue)
                        .padding(.top, 8)

                        // Divider with "or"
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)

                            Text(LocalizedString("login.or"))
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 12)

                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 16)

                        // Continue with Google
                        Button(action: {
                            handleGoogleLogin()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "globe")
                                    .font(.system(size: 20))
                                    .foregroundColor(.black)

                                Text(LocalizedString("login.continueWithGoogle"))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                            )
                        }

                        // Continue with Apple
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                handleAppleLogin(result: result)
                            }
                        )
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 50)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )

                        // Sign Up Link
                        HStack(spacing: 4) {
                            Text(LocalizedString("login.noAccount"))
                                .font(.system(size: 14))
                                .foregroundColor(.gray)

                            Button(action: {
                                showingRegister = true
                            }) {
                                Text(LocalizedString("login.signUp"))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(hex: "#0072CE"))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showingRegister) {
            RegisterView(isLoggedIn: $isLoggedIn)
                .environmentObject(languageManager)
        }
        .alert("Help", isPresented: $showingHelp) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Need help logging in? Contact support@atenea.com")
        }
    }

    // MARK: - Login Handlers

    private func handleEmailLogin() {
        // TODO: Implement email/phone authentication
        print("📧 Login with email/phone: \(emailOrPhone)")

        // For now, just log in
        withAnimation {
            isLoggedIn = true
        }
    }

    private func handleGoogleLogin() {
        // TODO: Implement Google Sign In
        print("🔵 Login with Google")

        // For now, just log in
        withAnimation {
            isLoggedIn = true
        }
    }

    private func handleAppleLogin(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userIdentifier = appleIDCredential.user
                let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email

                print("🍎 Login with Apple successful")
                print("   User ID: \(userIdentifier)")
                if let email = email {
                    print("   Email: \(email)")
                }
                if let fullName = fullName {
                    print("   Name: \(fullName.givenName ?? "") \(fullName.familyName ?? "")")
                }

                // Save user info and log in
                withAnimation {
                    isLoggedIn = true
                }
            }

        case .failure(let error):
            print("❌ Apple Sign In failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview
#Preview {
    LoginView(isLoggedIn: .constant(false))
        .environmentObject(LanguageManager.shared)
}
