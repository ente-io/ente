import SwiftUI

#if canImport(RiveRuntime)
import RiveRuntime

struct EnsuBrandIllustration: View {
    var width: CGFloat = 92
    var height: CGFloat = 42
    var animated: Bool = true
    var outroTrigger: Bool = false
    var outroInputName: String = "outro"
    var clipsContent: Bool = true

    @StateObject private var riveViewModel = RiveViewModel(
        fileName: "ensu",
        fit: .contain,
        alignment: .centerLeft,
        autoPlay: true
    )
    @State private var lastOutroTrigger = false
    @State private var resolvedOutroInputName: String?
    @State private var primaryStateMachineName: String?
    @State private var primaryAnimationName: String?

    @ViewBuilder
    private var riveContent: some View {
        if clipsContent {
            riveViewModel
                .view()
                .frame(width: width, height: height, alignment: .topLeading)
                .clipped()
                .mask(
                    Rectangle()
                        .frame(width: width, height: height, alignment: .topLeading)
                )
        } else {
            riveViewModel
                .view()
                .frame(width: width, height: height, alignment: .topLeading)
        }
    }

    var body: some View {
        riveContent
            .onAppear {
                discoverPlaybackTargets()

                if animated {
                    restorePrimaryPlayback()
                } else {
                    riveViewModel.pause()
                }

                if outroTrigger {
                    fireOutro()
                    lastOutroTrigger = true
                } else {
                    lastOutroTrigger = false
                }
            }
            .onChange(of: animated) { value in
                if value {
                    restorePrimaryPlayback()
                    if outroTrigger {
                        fireOutro()
                    }
                } else {
                    riveViewModel.pause()
                }
            }
            .onChange(of: outroTrigger) { value in
                if value && !lastOutroTrigger {
                    fireOutro()
                } else if !value {
                    restorePrimaryPlayback()
                }
                lastOutroTrigger = value
            }
            .accessibilityLabel("Ensu")
    }

    private func discoverPlaybackTargets() {
        let stateMachines = riveViewModel.riveModel?.artboard?.stateMachineNames() ?? []
        let animations = riveViewModel.riveModel?.artboard?.animationNames() ?? []

        if riveViewModel.riveModel?.stateMachine == nil,
           let fallbackStateMachineName = stateMachines.first {
            try? riveViewModel.configureModel(stateMachineName: fallbackStateMachineName)
        }

        if primaryStateMachineName == nil {
            primaryStateMachineName = riveViewModel.riveModel?.stateMachine?.name() ?? stateMachines.first
        }
        if primaryAnimationName == nil {
            primaryAnimationName = riveViewModel.riveModel?.animation?.name() ?? animations.first
        }

        if let discoveredOutro = riveViewModel.riveModel?.stateMachine?.inputNames().first(where: {
            $0.lowercased().contains("outro")
        }) {
            resolvedOutroInputName = discoveredOutro
        } else if resolvedOutroInputName == nil {
            resolvedOutroInputName = outroInputName
        }
    }

    private func restorePrimaryPlayback() {
        if let stateMachine = primaryStateMachineName {
            try? riveViewModel.configureModel(stateMachineName: stateMachine)
        } else if let animation = primaryAnimationName {
            try? riveViewModel.configureModel(animationName: animation)
        }
        resetOutroInputValue()
        if animated {
            riveViewModel.play()
        }
    }

    private func fireOutro() {
        discoverPlaybackTargets()

        let inputName: String = {
            let availableInputs = riveViewModel.riveModel?.stateMachine?.inputNames() ?? []
            if let resolvedOutroInputName,
               availableInputs.contains(resolvedOutroInputName) {
                return resolvedOutroInputName
            }
            if let match = availableInputs.first(where: { $0.lowercased() == outroInputName.lowercased() }) {
                return match
            }
            if let match = availableInputs.first(where: { $0.lowercased().contains("outro") }) {
                return match
            }
            return resolvedOutroInputName ?? outroInputName
        }()

        if let boolInput = riveViewModel.boolInput(named: inputName) {
            boolInput.setValue(true)
            riveViewModel.play()
            return
        }

        if let numberInput = riveViewModel.numberInput(named: inputName) {
            numberInput.setValue(1)
            riveViewModel.play()
            return
        }

        riveViewModel.triggerInput(inputName)
        riveViewModel.play()
    }

    private func resetOutroInputValue() {
        let inputName = resolvedOutroInputName ?? outroInputName
        if let boolInput = riveViewModel.boolInput(named: inputName) {
            boolInput.setValue(false)
            return
        }
        if let numberInput = riveViewModel.numberInput(named: inputName) {
            numberInput.setValue(0)
        }
    }
}

#else

struct EnsuBrandIllustration: View {
    var width: CGFloat = 92
    var height: CGFloat = 42
    var animated: Bool = true
    var outroTrigger: Bool = false
    var outroInputName: String = "outro"
    var clipsContent: Bool = true

    @State private var isAnimating = false

    var body: some View {
        let activePhase = animated ? isAnimating : true

        Image("EnsuLogoForeground")
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height, alignment: .leading)
            .scaleEffect(activePhase ? 1 : 0.94)
            .opacity(activePhase ? 1 : 0.84)
            .animation(
                animated ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true) : nil,
                value: isAnimating
            )
            .onAppear {
                guard animated else { return }
                isAnimating = true
            }
            .onDisappear {
                isAnimating = false
            }
            .accessibilityLabel("Ensu")
    }
}

#endif
