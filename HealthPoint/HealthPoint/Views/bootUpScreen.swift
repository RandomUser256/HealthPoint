//
//  startScreen.swift
//  HealthPoint
//
//  Created by CETYS Universidad  on 15/04/26.
//
import SwiftUI

struct bootUpScreen: View {
    let isDataReady: Bool
    let loadingMessage: String
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(Color(.foreground).opacity(0.4))
                            .frame(width: 124, height: 124)
                            .overlay(
                                Circle()
                                    .stroke(Color(.universalAccent), lineWidth: 2)
                            )

                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 52, weight: .semibold))
                            .foregroundStyle(.green)
                    }

                    VStack(spacing: 8) {
                        Text("HealthPoint")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.universalAccent)

                        Text("Consulta farmacéutica personalizada")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                }

                VStack(spacing: 14) {
                    Button(action: onContinue) {
                        HStack(spacing: 10) {
                            if !isDataReady {
                                ProgressView()
                                    .tint(.green)
                            }

                            Text(isDataReady ? "Continuar" : "Cargando datos…")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(.foreground).opacity(isDataReady ? 0.4 : 0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color(.universalAccent), lineWidth: 1.5)
                                )
                        )
                    }
                    .disabled(!isDataReady)
                    .buttonStyle(.plain)
                    .foregroundStyle(isDataReady ? .universalAccent : .secondary)

                    Text(loadingMessage)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)

                Spacer()

                Text("CETYS Universidad")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 18)
                    .padding(.horizontal, 24)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

#Preview {
    bootUpScreen(
        isDataReady: false,
        loadingMessage: "Verificando la base local de medicamentos…",
        onContinue: {}
    )
}
