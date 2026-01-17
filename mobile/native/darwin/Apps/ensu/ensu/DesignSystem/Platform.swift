import SwiftUI

#if canImport(UIKit)
import UIKit

typealias PlatformKeyboardType = UIKeyboardType
typealias PlatformTextContentType = UITextContentType
typealias PlatformTextInputAutocapitalization = TextInputAutocapitalization
#else

enum PlatformKeyboardType {
    case `default`
    case emailAddress
    case numberPad
    case URL
}

enum PlatformTextContentType {
    case emailAddress
    case password
}

enum PlatformTextInputAutocapitalization {
    case never
    case words
    case sentences
    case characters
}
#endif

extension View {
    @ViewBuilder
    func platformKeyboardType(_ type: PlatformKeyboardType) -> some View {
        #if canImport(UIKit)
        self.keyboardType(type)
        #else
        self
        #endif
    }

    @ViewBuilder
    func platformTextContentType(_ type: PlatformTextContentType?) -> some View {
        #if canImport(UIKit)
        if let type {
            self.textContentType(type)
        } else {
            self
        }
        #else
        self
        #endif
    }

    @ViewBuilder
    func platformTextInputAutocapitalization(_ style: PlatformTextInputAutocapitalization) -> some View {
        #if canImport(UIKit)
        self.textInputAutocapitalization(style)
        #else
        self
        #endif
    }

    @ViewBuilder
    func platformTextFieldStyle() -> some View {
        #if os(macOS)
        self.textFieldStyle(.plain)
        #else
        self
        #endif
    }

    @ViewBuilder
    func platformNavigationBarStyle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(EnsuColor.backgroundBase, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        #else
        self
        #endif
    }

    @ViewBuilder
    func platformBackButtonHidden(_ hidden: Bool) -> some View {
        #if os(iOS)
        self.navigationBarBackButtonHidden(hidden)
        #else
        self
        #endif
    }

    @ViewBuilder
    func platformFullScreenCover<Content: View>(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) -> some View {
        #if os(iOS)
        self.fullScreenCover(isPresented: isPresented, onDismiss: onDismiss, content: content)
        #else
        self.sheet(isPresented: isPresented, onDismiss: onDismiss, content: content)
        #endif
    }
}
