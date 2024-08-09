struct InternalEvents {
	/// Sets the the current user
	struct Identify: InternalEvent {
		let action = "$identify"
		let set: [String: PaywallsValueTypeProtocol]?
		let setOnce: [String: PaywallsValueTypeProtocol]?
		let unset: [String]?
		var properties: [String: PaywallsValueTypeProtocol?] {
			[
				"$set": set,
				"$set_once": setOnce,
				"$unset": unset,
			]
		}
	}

	/// PaywallSDK is configured for the first time for the given user
	struct AppInstall: InternalEvent {
		let action = "$app_install"
		let sessionId: String
		var properties: [String: PaywallsValueTypeProtocol?] {
			[
				"session_id": sessionId,
			]
		}
	}

	/// A user session with duration in sconds
	struct Session: InternalEvent {
		let action = "$session"
		let duration: Int
		var properties: [String: PaywallsValueTypeProtocol?] {
			[
				"duration": duration,
			]
		}
	}


}