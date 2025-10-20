//
//  LookAroundView.swift
//  Atenea
//
//  Created by Claude on 10/13/25.
//

import SwiftUI
import MapKit

struct LookAroundView: View {
    let coordinate: CLLocationCoordinate2D
    let venueName: String
    @Environment(\.dismiss) var dismiss
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var isLoading = true

    var body: some View {
        Group {
            // Solo mostrar Look Around en pantalla completa cuando está disponible
            if let scene = lookAroundScene {
                InteractiveLookAroundUIKit(
                    scene: scene,
                    venueName: venueName,
                    onDismiss: {
                        dismiss()
                    },
                    onClose: {
                        dismiss()
                    }
                )
                .edgesIgnoringSafeArea(.all)
            } else if isLoading {
                // Indicador de carga
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)

                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)

                        Text("Cargando...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            } else {
                // Error - Look Around no disponible
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)

                    VStack(spacing: 20) {
                        Image(systemName: "binoculars.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("Vista no disponible")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Esta ubicación no tiene vista de calle disponible en este momento")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Button(action: { dismiss() }) {
                            Text("Cerrar")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.blue)
                                )
                        }
                        .padding(.top, 20)
                    }
                }
            }
        }
        .task(priority: .userInitiated) {
            await fetchLookAroundScene()
        }
    }

    private func fetchLookAroundScene() async {
        let request = MKLookAroundSceneRequest(coordinate: coordinate)

        do {
            let scene = try await request.scene

            await MainActor.run {
                self.lookAroundScene = scene
                self.isLoading = false
            }
        } catch {
            print("Error al cargar Look Around: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

// Vista interactiva de Look Around con UIKit que maneja el header correctamente
struct InteractiveLookAroundUIKit: UIViewControllerRepresentable {
    let scene: MKLookAroundScene
    let venueName: String
    let onDismiss: () -> Void
    let onClose: () -> Void

    func makeUIViewController(context: Context) -> LookAroundContainerViewController {
        let controller = LookAroundContainerViewController()
        controller.configure(scene: scene, venueName: venueName, onDismiss: onDismiss, onClose: onClose)
        return controller
    }

    func updateUIViewController(_ uiViewController: LookAroundContainerViewController, context: Context) {
        // No need to update
    }
}

// Controlador personalizado que maneja el Look Around y el header en UIKit
class LookAroundContainerViewController: UIViewController {
    private var lookAroundVC: MKLookAroundViewController!
    private var headerView: UIView!
    private var minimizeButton: UIButton!
    private var closeButton: UIButton!
    private var onDismiss: (() -> Void)?
    private var onClose: (() -> Void)?

    func configure(scene: MKLookAroundScene, venueName: String, onDismiss: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.onDismiss = onDismiss
        self.onClose = onClose

        // Configurar el Look Around View Controller
        lookAroundVC = MKLookAroundViewController()
        lookAroundVC.scene = scene
        lookAroundVC.isNavigationEnabled = true
        lookAroundVC.showsRoadLabels = true

        // Agregar como child view controller
        addChild(lookAroundVC)
        view.addSubview(lookAroundVC.view)
        lookAroundVC.view.frame = view.bounds
        lookAroundVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        lookAroundVC.didMove(toParent: self)

        // CRÍTICO: Asegurar que la vista acepta interacción INMEDIATAMENTE
        lookAroundVC.view.isUserInteractionEnabled = true
        lookAroundVC.view.isMultipleTouchEnabled = true

        // Forzar la activación de la vista para que sea interactiva de inmediato
        DispatchQueue.main.async {
            self.lookAroundVC.view.setNeedsLayout()
            self.lookAroundVC.view.layoutIfNeeded()
        }

        // Crear header view con SwiftUI
        setupHeaderView(venueName: venueName)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Asegurar que el Look Around está activo y listo para interacción
        lookAroundVC?.view.becomeFirstResponder()
    }

    private func setupHeaderView(venueName: String) {
        // Contenedor del header
        headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.isUserInteractionEnabled = true // Permitir interacción con botones

        // Stack view para el contenido
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isUserInteractionEnabled = true

        // Botón de minimizar (izquierda arriba)
        minimizeButton = UIButton(type: .system)
        let minimizeConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let minimizeImage = UIImage(systemName: "arrow.down.right.and.arrow.up.left", withConfiguration: minimizeConfig)
        minimizeButton.setImage(minimizeImage, for: .normal)
        minimizeButton.tintColor = .white
        minimizeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        minimizeButton.layer.cornerRadius = 20
        minimizeButton.addTarget(self, action: #selector(minimizeButtonTapped), for: .touchUpInside)
        minimizeButton.translatesAutoresizingMaskIntoConstraints = false

        // Spacer view
        let spacerView = UIView()
        spacerView.isUserInteractionEnabled = false

        // Botón de cerrar (derecha arriba)
        closeButton = UIButton(type: .system)
        let closeConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let closeImage = UIImage(systemName: "xmark", withConfiguration: closeConfig)
        closeButton.setImage(closeImage, for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 20
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        // Agregar al stack view: Minimizar - Spacer - Cerrar
        stackView.addArrangedSubview(minimizeButton)
        stackView.addArrangedSubview(spacerView)
        stackView.addArrangedSubview(closeButton)

        headerView.addSubview(stackView)

        // Asegurar que el Look Around está debajo y el header encima
        view.addSubview(headerView)

        // CRÍTICO: Traer el Look Around al frente excepto en el área del header
        view.bringSubviewToFront(lookAroundVC.view)
        view.bringSubviewToFront(headerView)

        // Layout constraints
        NSLayoutConstraint.activate([
            // Header view
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 100),

            // Stack view
            stackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),

            // Minimize button size
            minimizeButton.widthAnchor.constraint(equalToConstant: 40),
            minimizeButton.heightAnchor.constraint(equalToConstant: 40),

            // Close button size
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc private func minimizeButtonTapped() {
        // Minimizar - volver a vista flotante
        print("⬇️ Botón de minimizar presionado")
        onDismiss?()
    }

    @objc private func closeButtonTapped() {
        // Cerrar completamente
        print("✖️ Botón de cerrar presionado")
        onClose?()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // No hay gradient layer que actualizar
    }
}

#Preview {
    LookAroundView(
        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        venueName: "San Francisco"
    )
}
