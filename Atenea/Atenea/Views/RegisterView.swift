//
//  RegisterView.swift
//  Atenea
//
//  Registration screen with user information form
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var languageManager: LanguageManager
    @Binding var isLoggedIn: Bool

    @State private var fullName: String = ""
    @State private var age: String = ""
    @State private var selectedCountry: String = "Mexico"
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var showingCountryPicker: Bool = false

    // List of World Cup 2026 host countries and other popular countries
    let countries = [
        "Mexico",
        "United States",
        "Canada",
        "Argentina",
        "Brazil",
        "Spain",
        "Germany",
        "France",
        "Italy",
        "England",
        "Portugal",
        "Netherlands",
        "Belgium",
        "Uruguay",
        "Colombia",
        "Chile",
        "Peru",
        "Ecuador",
        "Japan",
        "South Korea",
        "Australia",
        "Morocco",
        "Nigeria",
        "Ghana",
        "Senegal",
        "Other"
    ].sorted()

    // Check if all required fields are filled
    private var canCreateAccount: Bool {
        !fullName.isEmpty &&
        !age.isEmpty &&
        !email.isEmpty &&
        !phoneNumber.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.white
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedString("register.title"))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.black)

                            Text(LocalizedString("register.subtitle"))
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)

                        // Full Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedString("register.name"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)

                            TextField(LocalizedString("register.namePlaceholder"), text: $fullName)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 16))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                )
                                .autocapitalization(.words)
                        }

                        // Age Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedString("register.age"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)

                            TextField(LocalizedString("register.agePlaceholder"), text: $age)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 16))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                )
                                .keyboardType(.numberPad)
                        }

                        // Place of Origin Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedString("register.origin"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)

                            Button(action: {
                                showingCountryPicker = true
                            }) {
                                HStack {
                                    Text(selectedCountry)
                                        .font(.system(size: 16))
                                        .foregroundColor(.black)

                                    Spacer()

                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                )
                            }
                        }

                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedString("register.email"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)

                            TextField(LocalizedString("register.emailPlaceholder"), text: $email)
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

                        // Phone Number Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedString("register.phone"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)

                            TextField(LocalizedString("register.phonePlaceholder"), text: $phoneNumber)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 16))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                )
                                .keyboardType(.phonePad)
                        }

                        // Create Account Button
                        Button(action: {
                            handleRegistration()
                        }) {
                            Text(LocalizedString("register.createAccount"))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "#0072CE"),
                                            Color(hex: "#00A651")
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .opacity(canCreateAccount ? 1.0 : 0.5)
                                )
                                .cornerRadius(12)
                                .shadow(
                                    color: canCreateAccount ? Color(hex: "#0072CE").opacity(0.3) : Color.clear,
                                    radius: 8,
                                    x: 0,
                                    y: 4
                                )
                        }
                        .disabled(!canCreateAccount)
                        .padding(.top, 8)

                        // Sign In Link
                        HStack(spacing: 4) {
                            Text(LocalizedString("register.alreadyHaveAccount"))
                                .font(.system(size: 14))
                                .foregroundColor(.gray)

                            Button(action: {
                                dismiss()
                            }) {
                                Text(LocalizedString("register.signIn"))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "#0072CE"))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                    }
                }
            }
            .sheet(isPresented: $showingCountryPicker) {
                CountryPickerView(
                    selectedCountry: $selectedCountry,
                    countries: countries,
                    onCountrySelected: { country in
                        // Change app language when country is selected
                        let languageCode = LanguageManager.languageForCountry(country)
                        languageManager.setLanguage(languageCode)
                    }
                )
                .environmentObject(languageManager)
            }
        }
    }

    // MARK: - Registration Handler

    private func handleRegistration() {
        // TODO: Implement registration with backend
        print("📝 Creating account:")
        print("   Name: \(fullName)")
        print("   Age: \(age)")
        print("   Country: \(selectedCountry)")
        print("   Email: \(email)")
        print("   Phone: \(phoneNumber)")

        // For now, just log in
        withAnimation {
            isLoggedIn = true
        }
    }
}

// MARK: - Country Picker View

struct CountryPickerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var languageManager: LanguageManager
    @Binding var selectedCountry: String
    let countries: [String]
    let onCountrySelected: (String) -> Void
    @State private var searchText: String = ""

    var filteredCountries: [String] {
        if searchText.isEmpty {
            return countries
        } else {
            return countries.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCountries, id: \.self) { country in
                    Button(action: {
                        selectedCountry = country
                        onCountrySelected(country)
                        dismiss()
                    }) {
                        HStack {
                            Text(country)
                                .font(.system(size: 16))
                                .foregroundColor(.black)

                            Spacer()

                            if country == selectedCountry {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(hex: "#0072CE"))
                            }
                        }
                    }
                }
            }
            .navigationTitle(LocalizedString("register.origin"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search countries")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedString("action.cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RegisterView(isLoggedIn: .constant(false))
        .environmentObject(LanguageManager.shared)
}
