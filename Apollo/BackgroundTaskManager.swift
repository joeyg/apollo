import Foundation
import BackgroundTasks

enum BackgroundTasksConfig {
    static let refreshIdentifier = "com.github.joeyg.apollo.refresh"
}

final class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    private init() {}

    func registerTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: BackgroundTasksConfig.refreshIdentifier, using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }

    func scheduleAppRefresh(earliest secondsFromNow: TimeInterval = 15 * 60) {
        let request = BGAppRefreshTaskRequest(identifier: BackgroundTasksConfig.refreshIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: secondsFromNow)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            #if DEBUG
            print("Could not schedule app refresh: \(error)")
            #endif
        }
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh() // schedule next

        let operation = RefreshOperation()

        task.expirationHandler = {
            operation.cancel()
        }

        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }

        OperationQueue().addOperation(operation)
    }
}

/// Simple Operation that loads the latest logs from shared defaults.
private final class RefreshOperation: Operation {
    override func main() {
        if isCancelled { return }
        // Load logs from shared defaults. We instantiate a temporary LogStore to reuse its logic.
        let store = LogStore()
        store.load()
    }
}
