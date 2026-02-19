
/// Defines the supported ad types for AdGeist SDK.
/// Publishers must use these predefined values when configuring ads.
public enum AdType: String {
	/// Banner ads - Small rectangular ads typically displayed at the top or bottom of the screen
	case BANNER = "banner"

	/// Display ads - Standard display advertisements
	case DISPLAY = "display"

	/// Companion ads - Ads displayed alongside other content
	/// Requires minimum 320x320 dimensions
	case COMPANION = "companion"
}
