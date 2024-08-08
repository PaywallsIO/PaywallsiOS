struct InternalEvents {
	/// A user session with duration in sconds
	struct Session: InternalEvent {
		let action = "$session"
		let duration: Int
		var properties: [String: PaywallsValueTypeProtocol] {
			[
				"duration": duration,
			]
		}
	}

	/// PaywallSDK is configured for the first time for the given user
	struct AppInstall: InternalEvent {
		let action = "$app_install"
		let sessionId: String
		var properties: [String: PaywallsValueTypeProtocol] {
			[
				"sessionId": sessionId,
			]
		}
	}


}