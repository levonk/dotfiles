// =====================================================================
// Shared Browser Configuration Settings
// Managed by chezmoi | https://github.com/levonk/dotfiles
//
// Purpose:
//   - Common browser settings that can be shared across different browsers
//   - Privacy and security enhancements
//   - Performance optimizations
//   - Developer-friendly configurations
//
// Compatibility: Firefox, LibreWolf, Chrome-based browsers
// Security: Privacy-focused settings, no sensitive data
// Compliance: See LICENSE and admin/licenses.md
// =====================================================================

// Common privacy and security settings
const SHARED_PRIVACY_SETTINGS = {
    // Disable telemetry and data collection
    "datareporting.healthreport.uploadEnabled": false,
    "datareporting.policy.dataSubmissionEnabled": false,
    "toolkit.telemetry.enabled": false,
    "toolkit.telemetry.unified": false,
    "toolkit.telemetry.server": "",
    
    // Enhanced privacy settings
    "privacy.trackingprotection.enabled": true,
    "privacy.trackingprotection.socialtracking.enabled": true,
    "privacy.donottrackheader.enabled": true,
    "privacy.clearOnShutdown.cookies": false, // Keep cookies for convenience
    "privacy.clearOnShutdown.cache": true,
    "privacy.clearOnShutdown.downloads": true,
    "privacy.clearOnShutdown.formdata": true,
    "privacy.clearOnShutdown.history": false, // Keep history for convenience
    
    // Security enhancements
    "security.tls.version.min": 3, // Require TLS 1.2+
    "security.ssl.require_safe_negotiation": true,
    "security.ssl.treat_unsafe_negotiation_as_broken": true,
    "dom.security.https_only_mode": true,
    "dom.security.https_only_mode_send_http_background_request": false,
    
    // Disable potentially unsafe features
    "javascript.options.asmjs": false,
    "javascript.options.wasm": false,
    "dom.event.clipboardevents.enabled": false,
    "geo.enabled": false,
    "media.navigator.enabled": false,
    "webgl.disabled": false, // Keep WebGL for web development
    
    // Performance optimizations
    "browser.cache.disk.enable": true,
    "browser.cache.memory.enable": true,
    "browser.cache.disk.capacity": 1048576, // 1GB disk cache
    "browser.cache.memory.capacity": 262144, // 256MB memory cache
    "network.http.max-connections": 900,
    "network.http.max-connections-per-server": 30,
    "network.http.max-persistent-connections-per-server": 10,
    
    // Developer-friendly settings
    "devtools.chrome.enabled": true,
    "devtools.debugger.remote-enabled": true,
    "browser.download.useDownloadDir": false, // Always ask where to save
    "browser.tabs.closeWindowWithLastTab": false,
    "browser.urlbar.suggest.searches": true,
    "browser.urlbar.suggest.bookmark": true,
    "browser.urlbar.suggest.history": true,
    "browser.urlbar.suggest.openpage": true
};

// Common extension/addon settings
const SHARED_EXTENSION_SETTINGS = {
    // Allow unsigned extensions in development
    "xpinstall.signatures.required": false,
    "extensions.legacy.enabled": true,
    
    // Extension security
    "extensions.blocklist.enabled": true,
    "extensions.update.enabled": true,
    "extensions.update.autoUpdateDefault": true,
    
    // Content blocking
    "browser.contentblocking.category": "strict",
    "privacy.annotate_channels.strict_list.enabled": true,
    "privacy.partition.network_state": true,
    "privacy.dynamic_firstparty.use_site": true
};

// Media and content settings
const SHARED_MEDIA_SETTINGS = {
    // Enable DRM for streaming services (Netflix, Spotify, etc.)
    "media.eme.enabled": true,
    "media.gmp-widevinecdm.visible": true,
    "media.gmp-widevinecdm.enabled": true,
    "media.gmp-provider.enabled": true,
    
    // Audio/Video enhancements
    "media.autoplay.default": 2, // Block autoplay by default
    "media.autoplay.blocking_policy": 2,
    "media.block-autoplay-until-in-foreground": true,
    
    // Font rendering improvements
    "gfx.font_rendering.cleartype_params.rendering_mode": 5,
    "gfx.font_rendering.cleartype_params.cleartype_level": 100,
    "gfx.font_rendering.cleartype_params.force_gdi_classic_for_families": "",
    "gfx.font_rendering.cleartype_params.force_gdi_classic_max_size": 6,
    "gfx.font_rendering.directwrite.enabled": true
};

// Export settings for use in browser-specific configurations
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        SHARED_PRIVACY_SETTINGS,
        SHARED_EXTENSION_SETTINGS,
        SHARED_MEDIA_SETTINGS
    };
}

// Function to apply settings to Firefox/LibreWolf
function applyFirefoxSettings() {
    const allSettings = {
        ...SHARED_PRIVACY_SETTINGS,
        ...SHARED_EXTENSION_SETTINGS,
        ...SHARED_MEDIA_SETTINGS
    };
    
    for (const [key, value] of Object.entries(allSettings)) {
        if (typeof value === 'boolean') {
            defaultPref(key, value);
        } else if (typeof value === 'number') {
            defaultPref(key, value);
        } else if (typeof value === 'string') {
            defaultPref(key, value);
        }
    }
}

// Function to generate Chrome/Edge settings JSON
function generateChromeSettings() {
    return {
        "homepage": "about:blank",
        "homepage_is_newtabpage": false,
        "browser": {
            "show_home_button": true,
            "check_default_browser": false
        },
        "distribution": {
            "skip_first_run_ui": true,
            "import_bookmarks": false,
            "import_history": false,
            "import_search_engine": false,
            "make_chrome_default": false,
            "make_chrome_default_for_user": false,
            "verbose_logging": false
        },
        "first_run_tabs": ["about:blank"],
        "privacy": {
            "enable_do_not_track": true,
            "safe_browsing_enabled": true,
            "safe_browsing_extended_reporting_enabled": false
        },
        "profile": {
            "default_content_setting_values": {
                "geolocation": 2,
                "notifications": 2,
                "media_stream": 2,
                "plugins": 1,
                "popups": 2,
                "automatic_downloads": 2
            }
        }
    };
}
