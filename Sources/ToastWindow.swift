import AppKit

final class ToastWindow {
    private var window: NSWindow?
    private var hideWork: DispatchWorkItem?

    func show(_ message: String) {
        DispatchQueue.main.async { [self] in
            hideWork?.cancel()
            window?.close()

            let label = NSTextField(labelWithString: message)
            label.font = .systemFont(ofSize: 16, weight: .medium)
            label.textColor = .white
            label.alignment = .center
            label.sizeToFit()

            let padding: CGFloat = 24
            let width = label.frame.width + padding * 2
            let height: CGFloat = 44

            guard let screen = NSScreen.main else { return }
            let x = screen.frame.midX - width / 2
            let y = screen.frame.height * 0.2

            let panel = NSPanel(
                contentRect: NSRect(x: x, y: y, width: width, height: height),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.level = .floating
            panel.hasShadow = true
            panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
            panel.isMovableByWindowBackground = false

            let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
            container.wantsLayer = true
            container.layer?.backgroundColor = NSColor(white: 0.15, alpha: 0.92).cgColor
            container.layer?.cornerRadius = 10

            label.frame = NSRect(x: padding, y: (height - label.frame.height) / 2, width: label.frame.width, height: label.frame.height)
            container.addSubview(label)
            panel.contentView = container
            panel.orderFrontRegardless()

            self.window = panel

            let work = DispatchWorkItem { [weak self] in
                self?.window?.close()
                self?.window = nil
            }
            self.hideWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
        }
    }
}
