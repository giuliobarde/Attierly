import Foundation

enum StyleSummaryTemplate {
    static func generate(from profile: UserProfile) -> String {
        var sections: [String] = []

        // Style identity
        let styles = profile.selectedStylesArray
        if !styles.isEmpty {
            if styles.count == 1 {
                sections.append("Your style leans \(styles[0]).")
            } else {
                let allButLast = styles.dropLast().joined(separator: ", ")
                sections.append("Your style blends \(allButLast) and \(styles.last!).")
            }
        }

        // Comfort vs appearance
        if let comfort = profile.comfortVsAppearanceEnum {
            switch comfort {
            case .comfort:
                sections.append("You prioritize comfort over appearance.")
            case .balanced:
                sections.append("You balance comfort and appearance equally.")
            case .appearance:
                sections.append("You lean toward appearance over pure comfort.")
            }
        }

        // Temperature sensitivity
        var tempParts: [String] = []
        if let cold = profile.coldSensitivityEnum {
            switch cold {
            case .high: tempParts.append("highly sensitive to cold")
            case .low: tempParts.append("tolerant of cold")
            case .moderate: break
            }
        }
        if let heat = profile.heatSensitivityEnum {
            switch heat {
            case .high: tempParts.append("highly sensitive to heat")
            case .low: tempParts.append("tolerant of heat")
            case .moderate: break
            }
        }
        if !tempParts.isEmpty {
            sections.append("Temperature-wise, you are \(tempParts.joined(separator: " and ")).")
        }

        // Body temp notes
        if let notes = profile.bodyTempNotes, !notes.trimmingCharacters(in: .whitespaces).isEmpty {
            sections.append("Personal note: \(notes.trimmingCharacters(in: .whitespaces)).")
        }

        // Layering
        if let layering = profile.layeringPreferenceEnum {
            switch layering {
            case .minimal:
                sections.append("You prefer minimal layers.")
            case .happy:
                sections.append("You're happy to layer when needed.")
            case .loves:
                sections.append("You love layering and enjoy building depth in outfits.")
            }
        }

        // Weather dressing
        if let approach = profile.weatherDressingApproachEnum {
            switch approach {
            case .light:
                sections.append("When it comes to weather, you tend to dress light.")
            case .conditions:
                sections.append("You dress practically for the conditions.")
            case .overdress:
                sections.append("You prefer to overdress for warmth rather than risk being cold.")
            }
        }

        if sections.isEmpty {
            return "Complete the style questionnaire above to generate your style summary."
        }

        return sections.joined(separator: " ")
    }
}
