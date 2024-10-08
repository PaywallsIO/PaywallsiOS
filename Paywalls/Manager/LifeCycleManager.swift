import Foundation
import UIKit

protocol LifeCycleManagerProtocol {
    func register()
    func applicationWillResignActive()
    func applicationDidBecomeActive()
}

final class LifeCycleManager: LifeCycleManagerProtocol {
    private let logger: LoggerProtocol
    private let dataSyncManager: DataSyncManagerProtocol
    private let sessionManager: SessionManagerProtocol
    private let eventRepository: EventsRepositoryProtocol
    private let notificationCenter: NotificationCenter

    init(
        logger: LoggerProtocol,
        dataSyncManager: DataSyncManagerProtocol,
        sessionManager: SessionManagerProtocol,
        eventRepository: EventsRepositoryProtocol,
        notificationCenter: NotificationCenter = NotificationCenter.default
    ) {
        self.logger = logger
        self.dataSyncManager = dataSyncManager
        self.sessionManager = sessionManager
        self.eventRepository = eventRepository
        self.notificationCenter = notificationCenter
    }

    @objc func applicationWillResignActive() {
        logger.info("Application will resign active")
        sessionManager.pauseSession()
        dataSyncManager.stopTimer()
        dataSyncManager.preformSync()
    }

    @objc func applicationWillTerminate() {
        logger.info("Application will terminate")
        dataSyncManager.stopTimer()
        dataSyncManager.preformSync()
    }

    @objc func applicationDidBecomeActive() {
        logger.info("Application did become active")
        sessionManager.rotateSessionIdIfRequired()
        dataSyncManager.startTimer()
    }

    func register() {
        notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(applicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
}
