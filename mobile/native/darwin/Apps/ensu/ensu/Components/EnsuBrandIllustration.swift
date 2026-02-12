import SwiftUI

#if canImport(RiveRuntime)
import RiveRuntime

struct EnsuBrandIllustration: View {
    var width: CGFloat = 92
    var height: CGFloat = 42
    var animated: Bool = true
    var outroTrigger: Bool = false
    var outroInputName: String = "outro"

    @StateObject private var riveViewModel = RiveViewModel(
        fileName: "ensu",
        fit: .contain,
        alignment: .centerLeft,
        autoPlay: true
    )
    @State private var lastOutroTrigger = false
    @State private var resolvedOutroInputName: String?

    var body: some View {
        riveViewModel
            .view()
            .frame(width: width, height: height, alignment: .leading)
            .onAppear {
                if riveViewModel.riveModel?.stateMachine == nil,
                   let fallbackStateMachineName = riveViewModel.riveModel?.artboard?.stateMachineNames().first {
                    try? riveViewModel.configureModel(stateMachineName: fallbackStateMachineName)
                }

                if let discoveredOutro = riveViewModel.riveModel?.stateMachine?.inputNames().first(where: {
                    $0.lowercased().contains("outro")
                }) {
                    resolvedOutroInputName = discoveredOutro
                } else if resolvedOutroInputName == nil {
                    resolvedOutroInputName = outroInputName
                }

                if animated {
                    riveViewModel.play()
                } else {
                    riveViewModel.pause()
                }

                resetOutroInputValue()

                if outroTrigger {
                    fireOutro()
                    lastOutroTrigger = true
                } else {
                    lastOutroTrigger = false
                }
            }
            .onChange(of: animated) { value in
                if value {
                    riveViewModel.play()
                    resetOutroInputValue()
                } else {
                    riveViewModel.pause()
                }
            }
            .onChange(of: outroTrigger) { value in
                if value && !lastOutroTrigger {
                    fireOutro()
                } else if !value {
                    resetOutroInputValue()
                }
                lastOutroTrigger = value
            }
            .accessibilityLabel("Ensu")
    }

    private func fireOutro() {
        let inputName = resolvedOutroInputName ?? outroInputName
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
