import SwiftUI

struct MenuBarLabel: View {
    @EnvironmentObject var monitor: UsageMonitor
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: monitor.fiveHourStatus.iconName)
                .symbolRenderingMode(.hierarchical)
            
            Text(Formatters.percentage(monitor.fiveHourPercent))
                .font(.caption2)
                .monospacedDigit()
        }
    }
}
