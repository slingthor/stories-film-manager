import SwiftUI

struct ShotVariantView: View {
    @StateObject private var variantManager = ShotVariantManager()
    @State private var selectedShotId: String = "59a"
    @State private var showingComparison = false
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Shot Variants")
                        .font(.title2)
                        .bold()
                    
                    if let variants = variantManager.variants[selectedShotId] {
                        Text("\(variants.count) variants found")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Menu("Select Shot") {
                    ForEach(Array(variantManager.variants.keys.sorted()), id: \.self) { shotId in
                        Button(shotId) {
                            selectedShotId = shotId
                        }
                    }
                }
                .menuStyle(.borderlessButton)
            }
            .padding()
            
            if let variants = variantManager.variants[selectedShotId] {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(variants) { variant in
                            VariantCard(
                                variant: variant,
                                isSelected: variantManager.selectedVariants[selectedShotId] == variant.variantName,
                                onSelect: {
                                    variantManager.selectVariant(for: selectedShotId, variantName: variant.variantName)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                HStack {
                    Button("Compare Variants") {
                        showingComparison = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    if let selected = variantManager.getSelectedVariant(for: selectedShotId) {
                        Text("Selected: \(selected.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding()
            } else {
                Spacer()
                Text("No variants found for shot \(selectedShotId)")
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .sheet(isPresented: $showingComparison) {
            ComparisonView(
                shotId: selectedShotId,
                comparisonText: variantManager.compareVariants(for: selectedShotId)
            )
        }
    }
}

struct VariantCard: View {
    let variant: ShotVariant
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(variant.displayName)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    Label("\(variant.duration)s", systemImage: "timer")
                        .font(.caption)
                    
                    Spacer()
                    
                    Text(variant.narrativeFunction)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            } else {
                Button("Select") {
                    onSelect()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

struct ComparisonView: View {
    let shotId: String
    let comparisonText: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            HStack {
                Text("Shot \(shotId) Variants Comparison")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            
            ScrollView {
                Text(comparisonText)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: 600, height: 500)
    }
}