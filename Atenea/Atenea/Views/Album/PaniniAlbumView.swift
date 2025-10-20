//  PaniniAlbumView.swift
//  Atenea
//
//  Created by Claude on 10/15/25.
//

import SwiftUI
import PDFKit
import UIKit

// MARK: - Vista Principal del Álbum Panini con Efecto de Libro Real
struct PaniniAlbumView: View {
    @Binding var isPresented: Bool
    var initialPage: Int = 0  // 🎯 Página inicial (0 = primera página)
    var shouldAnimateToPage: Bool = false  // 🎬 Si debe animar el paso de páginas
    @State private var currentPage: Int = 0
    @State private var pdfDocument: PDFDocument?
    @State private var totalPages: Int = 0
    @State private var showPageIndicator = true
    @State private var hasSetInitialPage = false  // Flag para evitar set múltiples
    @State private var pageViewController: UIPageViewController?

    var body: some View {
        ZStack {
            // Fondo con textura de madera para dar sensación de libro
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.15, blue: 0.1),
                    Color(red: 0.15, green: 0.1, blue: 0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header minimalista con botón de cerrar y contador de páginas
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            isPresented = false
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 44, height: 44)
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }

                    Spacer()

                    // Indicador de página con estilo libro
                    if showPageIndicator && totalPages > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.4))

                            Text("\(currentPage + 1) / \(totalPages)")
                                .font(.system(size: 16, weight: .semibold, design: .serif))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    }

                    Spacer()

                    // Espacio simétrico
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 60)
                .padding(.bottom, 12)

                // Visor de páginas con efecto de libro
                if let document = pdfDocument, totalPages > 0 {
                    BookPageViewController(
                        document: document,
                        currentPage: $currentPage,
                        totalPages: totalPages
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 10)
                    .padding(.horizontal, 16) // Ajusta el padding para que se vea mejor
                    .padding(.bottom, 10)
                } else {
                    // Loading indicator con estilo elegante
                    VStack(spacing: 24) {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 100, height: 100)

                            ProgressView()
                                .scaleEffect(1.8)
                                .tint(Color(red: 0.9, green: 0.7, blue: 0.4))
                        }

                        VStack(spacing: 8) {
                            Text("Abriendo Álbum")
                                .font(.system(size: 22, weight: .semibold, design: .serif))
                                .foregroundColor(.white)

                            Text("Preparando las páginas...")
                                .font(.system(size: 16, weight: .regular, design: .serif))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                    }
                }

                // Hint sutil para deslizar
                if totalPages > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.draw.fill")
                            .font(.system(size: 14))

                        Text("Desliza para voltear páginas")
                            .font(.system(size: 14, weight: .medium, design: .serif))
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 20)
                    .padding(.top, 10)
                }
            }
        }
        .onAppear {
            loadPDF()
            // 🎯 Establecer página inicial
            if initialPage > 0 && !hasSetInitialPage {
                hasSetInitialPage = true

                if shouldAnimateToPage {
                    // 🎬 Animar desde página 1 hasta la página objetivo
                    print("🎬 [ALBUM] Animando desde página 1 hasta página \(initialPage + 1)")
                    currentPage = 0
                    // Esperar un frame para que el UIPageViewController esté listo
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        animateToPage(initialPage)
                    }
                } else {
                    // Salto directo sin animación
                    currentPage = initialPage
                    print("📖 [ALBUM] Abriendo directamente en página: \(initialPage + 1)")
                }
            }
        }
    }

    // MARK: - Función para animar el paso de páginas
    private func animateToPage(_ targetPage: Int) {
        guard currentPage < targetPage else { return }

        // Pasar a la siguiente página con animación
        currentPage += 1

        // Si aún no llegamos al objetivo, continuar después de un delay
        if currentPage < targetPage {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                animateToPage(targetPage)
            }
        } else {
            print("✅ [ALBUM] Animación completada - Página \(currentPage + 1)")
        }
    }

    // MARK: - Cargar PDF
    private func loadPDF() {
        // Busca el PDF en el bundle principal
        if let pdfURL = Bundle.main.url(forResource: "albumFIFA", withExtension: "pdf"),
           let document = PDFDocument(url: pdfURL) {
            self.pdfDocument = document
            self.totalPages = document.pageCount
            print("✅ PDF cargado exitosamente: \(totalPages) páginas")
        } else {
            print("❌ Error: No se pudo cargar 'albumFIFA.pdf'. Verifica que el archivo esté en tu proyecto y agregado al target correcto.")
        }
    }
}

// MARK: - BookPageViewController con efecto de libro real
struct BookPageViewController: UIViewControllerRepresentable {
    let document: PDFDocument
    @Binding var currentPage: Int
    let totalPages: Int

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .pageCurl, // ✨ Efecto de voltear páginas como libro real
            navigationOrientation: .horizontal,
            options: nil
        )

        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator

        // Configurar la página inicial (por defecto 0, o la especificada)
        let initialPageIndex = max(0, min(currentPage, totalPages - 1))
        if let initialViewController = context.coordinator.viewControllerAtIndex(initialPageIndex) {
            pageViewController.setViewControllers(
                [initialViewController],
                direction: .forward,
                animated: false
            )
            print("📖 [ALBUM] Página inicial configurada: \(initialPageIndex + 1)")
        }

        return pageViewController
    }

    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        // Actualizar si cambia la página actual externamente
        guard let currentViewController = pageViewController.viewControllers?.first as? PDFPageViewController,
              currentViewController.pageIndex != currentPage else {
            return
        }

        if let newViewController = context.coordinator.viewControllerAtIndex(currentPage) {
            let direction: UIPageViewController.NavigationDirection = newViewController.pageIndex > currentViewController.pageIndex ? .forward : .reverse
            pageViewController.setViewControllers(
                [newViewController],
                direction: direction,
                animated: true
            )
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, document: document, totalPages: totalPages)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: BookPageViewController
        let document: PDFDocument
        let totalPages: Int

        init(_ parent: BookPageViewController, document: PDFDocument, totalPages: Int) {
            self.parent = parent
            self.document = document
            self.totalPages = totalPages
        }

        func viewControllerAtIndex(_ index: Int) -> PDFPageViewController? {
            guard index >= 0 && index < totalPages, let page = document.page(at: index) else {
                return nil
            }
            return PDFPageViewController(page: page, pageIndex: index)
        }

        // MARK: - UIPageViewControllerDataSource
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let pdfVC = viewController as? PDFPageViewController else { return nil }
            let index = pdfVC.pageIndex - 1
            return viewControllerAtIndex(index)
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let pdfVC = viewController as? PDFPageViewController else { return nil }
            let index = pdfVC.pageIndex + 1
            return viewControllerAtIndex(index)
        }

        // MARK: - UIPageViewControllerDelegate
        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            if completed, let currentViewController = pageViewController.viewControllers?.first as? PDFPageViewController {
                parent.currentPage = currentViewController.pageIndex
            }
        }
    }
}

// MARK: - PDFPageViewController (UIKit) - ✅ SECCIÓN CORREGIDA
class PDFPageViewController: UIViewController {
    let page: PDFPage
    let pageIndex: Int
    private var pdfView: PDFView!

    init(page: PDFPage, pageIndex: Int) {
        self.page = page
        self.pageIndex = pageIndex
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Configurar PDFView
        pdfView = PDFView()
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pdfView)

        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // 2. Crear un documento temporal con una sola página
        let document = PDFDocument()
        document.insert(page, at: 0)
        pdfView.document = document

        // 3. Configuración de visualización
        pdfView.displayMode = .singlePage
        pdfView.displayBox = .cropBox // Usa el contenido real de la página, no los márgenes
        pdfView.backgroundColor = .clear // El fondo lo controla el PageViewController
        
        // ¡IMPORTANTE! Habilitar auto-escalado es el primer paso.
        pdfView.autoScales = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // ✨ ESTA ES LA CLAVE ✨
        // Este es el lugar correcto para ajustar el zoom, porque la vista ya tiene su tamaño final.
        
        // 1. Calcula el factor de escala necesario para que la página quepa perfectamente.
        let scale = pdfView.scaleFactorForSizeToFit
        
        // 2. Aplica ese factor de escala a la vista.
        pdfView.scaleFactor = scale
        
        // 3. Bloquea el zoom estableciendo el mínimo y el máximo al mismo valor de ajuste.
        pdfView.minScaleFactor = scale
        pdfView.maxScaleFactor = scale
    }
}

// MARK: - Preview
#Preview {
    PaniniAlbumView(isPresented: .constant(true))
}
