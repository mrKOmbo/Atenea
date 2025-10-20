//
//  TransportSelectionView.swift
//  Atenea
//
//  Created by Emilio Cruz Vargas on 10/10/25.
//

import SwiftUI

struct TransportSelectionView: View {
    @Binding var isPresented: Bool
    @State private var selectedTransport: TransportType?
    @State private var searchText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                // Indicador de arrastre
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Transportes")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Ciudad de México")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))

            Divider()

            // Campo de búsqueda
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Buscar transporte", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // ScrollView horizontal de transportes
            ScrollView {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(filteredTransports) { transport in
                            TransportSelectionCard(
                                transport: transport,
                                isSelected: selectedTransport == transport
                            ) {
                                selectedTransport = transport
                                // Aquí puedes agregar la acción al seleccionar
                                print("Seleccionado: \(transport.rawValue)")
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }

                Spacer()
            }
        }
        .background(Color(.systemGroupedBackground))
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    // Filtrar transportes basados en el texto de búsqueda
    var filteredTransports: [TransportType] {
        if searchText.isEmpty {
            return TransportType.allCases
        } else {
            return TransportType.allCases.filter { transport in
                transport.rawValue.localizedCaseInsensitiveContains(searchText) ||
                transport.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// Tarjeta de transporte horizontal
private struct TransportSelectionCard: View {
    let transport: TransportType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Ícono
                ZStack {
                    Circle()
                        .fill(transport.color.opacity(0.15))
                        .frame(width: 70, height: 70)

                    Image(systemName: transport.icon)
                        .font(.system(size: 32))
                        .foregroundColor(transport.color)
                }

                // Nombre del transporte
                VStack(spacing: 4) {
                    Text(transport.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    // Indicador de selección
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(transport.color)
                    }
                }
            }
            .frame(width: 120)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? transport.color : Color.clear, lineWidth: 2.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TransportSelectionView(isPresented: .constant(true))
}
