//
//  LocalizedString.swift
//  Atenea
//
//  Centralized localization helper for the app
//

import Foundation

/// Helper function for localized strings with dynamic language support
/// Usage: LocalizedString("key") or L("key")
func LocalizedString(_ key: String, comment: String = "") -> String {
    return LanguageManager.shared.localizedString(key, comment: comment)
}

/// Short alias for LocalizedString
func L(_ key: String, comment: String = "") -> String {
    return LocalizedString(key, comment: comment)
}

/// Localization Keys - Use this enum for type-safe localization
enum LocalizationKey {
    // MARK: - Main Tabs
    static let map = "tab.map"
    static let community = "tab.community"
    static let album = "tab.album"

    // MARK: - Common Actions
    static let start = "action.start"
    static let next = "action.next"
    static let skip = "action.skip"
    static let cancel = "action.cancel"
    static let save = "action.save"
    static let delete = "action.delete"
    static let update = "action.update"
    static let retry = "action.retry"
    static let confirm = "action.confirm"
    static let accept = "action.accept"
    static let openSettings = "action.openSettings"

    // MARK: - Status Messages
    static let loading = "status.loading"
    static let loadingPosts = "status.loadingPosts"
    static let error = "status.error"
    static let errorLoadingPosts = "status.errorLoadingPosts"
    static let noPostsAvailable = "status.noPostsAvailable"
    static let confirmed = "status.confirmed"
    static let pending = "status.pending"
    static let cancelled = "status.cancelled"
    static let waiting = "status.waiting"

    // MARK: - Onboarding
    static let onboardingTitle = "onboarding.title"
    static let onboardingSubtitle = "onboarding.subtitle"
    static let onboardingVenues = "onboarding.venues"
    static let onboardingScanner = "onboarding.scanner"
    static let onboardingAlbum = "onboarding.album"

    // MARK: - Tutorial
    static let tutorialWelcome = "tutorial.welcome"
    static let tutorialWelcomeDesc = "tutorial.welcomeDesc"
    static let tutorialMenu = "tutorial.menu"
    static let tutorialMenuDesc = "tutorial.menuDesc"
    static let tutorialSearch = "tutorial.search"
    static let tutorialSearchDesc = "tutorial.searchDesc"
    static let tutorialCommunity = "tutorial.community"
    static let tutorialCommunityDesc = "tutorial.communityDesc"
    static let tutorialAlbum = "tutorial.album"
    static let tutorialAlbumDesc = "tutorial.albumDesc"

    // MARK: - Community
    static let filterAll = "community.filter.all"
    static let filterWorldCup = "community.filter.worldCup"
    static let filterTrending = "community.filter.trending"

    // MARK: - Album
    static let stickers = "album.stickers"
    static let of = "album.of"
    static let completed = "album.completed"
    static let newBadge = "album.new"

    // MARK: - Menu
    static let mainMenu = "menu.main"
    static let navigation = "menu.navigation"
    static let venueMap = "menu.venueMap"
    static let myLocation = "menu.myLocation"
    static let worldCup = "menu.worldCup"
    static let calendar = "menu.calendar"
    static let matches = "menu.matches"
    static let favorites = "menu.favorites"
    static let transport = "menu.transport"
    static let transportModes = "menu.transportModes"
    static let routes = "menu.routes"
    static let others = "menu.others"
    static let ar = "menu.ar"
    static let scanPlayers = "menu.scanPlayers"
    static let information = "menu.information"
    static let settings = "menu.settings"
    static let version = "menu.version"
    static let cameraPermission = "menu.cameraPermission"
    static let cameraPermissionDesc = "menu.cameraPermissionDesc"

    // MARK: - Profile
    static let menu = "profile.menu"
    static let mapType = "profile.mapType"
    static let language = "profile.language"
    static let claudeAPI = "profile.claudeAPI"
    static let configured = "profile.configured"
    static let notConfigured = "profile.notConfigured"
    static let scheduleMatch = "profile.scheduleMatch"
    static let selectVenue = "profile.selectVenue"
    static let selectVenueDesc = "profile.selectVenueDesc"
    static let seats = "profile.seats"
    static let dateTime = "profile.dateTime"
    static let status = "profile.status"
    static let confirmReservation = "profile.confirmReservation"
    static let reservationConfirmed = "profile.reservationConfirmed"
    static let yourMatchAt = "profile.yourMatchAt"
    static let seatsPlaceholder = "profile.seatsPlaceholder"
    static let capacity = "profile.capacity"

    // MARK: - Login
    static let loginWelcome = "login.welcome"
    static let loginAppName = "login.appName"
    static let loginEmailOrPhone = "login.emailOrPhone"
    static let loginEmailPlaceholder = "login.emailPlaceholder"
    static let loginTerms = "login.terms"
    static let loginTermsLink = "login.termsLink"
    static let loginAnd = "login.and"
    static let loginPrivacyLink = "login.privacyLink"
    static let loginContinue = "login.continue"
    static let loginOr = "login.or"
    static let loginContinueWithGoogle = "login.continueWithGoogle"
    static let loginContinueWithApple = "login.continueWithApple"
    static let loginHelp = "login.help"
    static let loginClose = "login.close"
    static let loginNoAccount = "login.noAccount"
    static let loginSignUp = "login.signUp"

    // MARK: - Registration
    static let registerTitle = "register.title"
    static let registerSubtitle = "register.subtitle"
    static let registerName = "register.name"
    static let registerNamePlaceholder = "register.namePlaceholder"
    static let registerAge = "register.age"
    static let registerAgePlaceholder = "register.agePlaceholder"
    static let registerOrigin = "register.origin"
    static let registerOriginPlaceholder = "register.originPlaceholder"
    static let registerEmail = "register.email"
    static let registerEmailPlaceholder = "register.emailPlaceholder"
    static let registerPhone = "register.phone"
    static let registerPhonePlaceholder = "register.phonePlaceholder"
    static let registerCreateAccount = "register.createAccount"
    static let registerAlreadyHaveAccount = "register.alreadyHaveAccount"
    static let registerSignIn = "register.signIn"
}
