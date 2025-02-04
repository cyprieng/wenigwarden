//
//  Constants.swift
//  wenigwarden
//
//  Created by Cyprien Guillemot on 07/01/2025.
//
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleMenu = Self("toggleMenu")
}

/// Bitwarden host types
enum BitwardenHost: String {
    case eu // swiftlint:disable:this identifier_name
    case com
    case selfHosted
}

/// Cipher types
enum CipherType: Int, Encodable {
    case login = 1
    case note = 2
    case creditCard = 3
    case identity = 4
    case sshKey = 5
}
