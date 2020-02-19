// my configuration of firefox browser.
// in order to change config place this file to
// ~/Library/Application Support/Firefox/Profiles/pq7czh2u.dev-edition-default

// turn off default "Pocket" extension
user_pref("extensions.pocket.api", "");
user_pref("extensions.pocket.enabled", false);
user_pref("extensions.pocket.site", "");
user_pref("extensions.pocket.oAuthConsumerKey", "");

// turn off default "WebRTC" extension
user_pref("media.peerconnection.enabled", false);
user_pref("media.peerconnection.ice.default_address_only", true);
user_pref("media.peerconnection.ice.no_host", true);
user_pref("media.peerconnection.ice.relay_only", true);
user_pref("media.peerconnection.ice.tcp", false);
user_pref("media.peerconnection.identity.enabled", false);
user_pref("media.peerconnection.turn.disable", true);
user_pref("media.peerconnection.use_document_iceservers", false);
user_pref("media.peerconnection.video.enabled", false);
user_pref("media.peerconnection.default_iceservers", "[]");

// turn off geo-location access
user_pref("geo.enabled", false);
user_pref("geo.provider.ms-windows-location", false);
user_pref("geo.wifi.uri", "");

// turn off browser usage statistic and different metrics
// async requests used for analytics
user_pref("beacon.enabled", false);
user_pref("browser.send_pings", false);
user_pref("browser.send_pings.require_same_host", false);

// benchmarks metrics
user_pref("dom.enable_performance", false);
user_pref("dom.enable_performance_observer", false);
user_pref("dom.enable_performance_navigation_timing", false);
user_pref("browser.slowStartup.notificationDisabled", false);
user_pref("network.predictor.enabled", false);
user_pref("network.predictor.enable-hover-on-ssl", false);
user_pref("network.prefetch-next", false);
user_pref("network.http.speculative-parallel-limit", 0);

// installed add-ons info
user_pref("extensions.getAddons.cache.enabled", false);

// turn off devices access
user_pref("device.sensors.enabled", false);
user_pref("device.sensors.orientation.enabled", false);
user_pref("device.sensors.motion.enabled", false);
user_pref("device.sensors.proximity.enabled", false);
user_pref("device.sensors.ambientLight.enabled", false);

// stop fingerprinting
user_pref("dom.webaudio.enabled", false);
user_pref("privacy.resistFingerprinting", true);

// block net connection info
user_pref("dom.netinfo.enabled", false);
user_pref("dom.network.enabled", false);

// turn off device usage and media translation
// (camers, micro, gamepads, speech recognition etc)
user_pref("dom.gamepad.enabled", false);
user_pref("dom.gamepad.non_standard_events.enabled", false);
user_pref("dom.imagecapture.enabled", false);
user_pref("dom.presentation.discoverable", false);
user_pref("dom.presentation.discovery.enabled", false);
user_pref("dom.presentation.enabled", false);
user_pref("dom.presentation.tcp_server.debug", false);
user_pref("media.getusermedia.aec_enabled", false);
user_pref("media.getusermedia.audiocapture.enabled", false);
user_pref("media.getusermedia.browser.enabled", false);
user_pref("media.getusermedia.noise_enabled", false);
user_pref("media.getusermedia.screensharing.enabled", false);
user_pref("media.navigator.enabled", false);
user_pref("media.navigator.video.enabled", false);
user_pref("media.navigator.permission.disabled", true);
user_pref("media.video_stats.enabled", false);
user_pref("dom.battery.enabled", false);
user_pref("dom.vibrator.enabled", false);
user_pref("dom.vr.require-gesture", false);
user_pref("dom.vr.poseprediction.enabled", false);
user_pref("dom.vr.openvr.enabled", false);
user_pref("dom.vr.oculus.enabled", false);
user_pref("dom.vr.oculus.invisible.enabled", false);
user_pref("dom.vr.enabled", false);
user_pref("dom.vr.test.enabled", false);
user_pref("dom.vr.puppet.enabled", false);
user_pref("dom.vr.osvr.enabled", false);
user_pref("dom.vr.external.enabled", false);
user_pref("dom.vr.autoactivate.enabled", false);
user_pref("media.webspeech.synth.enabled", false);
user_pref("media.webspeech.test.enable", false);
user_pref("media.webspeech.synth.force_global_queue", false);
user_pref("media.webspeech.recognition.force_enable", false);
user_pref("media.webspeech.recognition.enable", false);

//turn off telemetry
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.bhrPing.enabled", false);
user_pref("toolkit.telemetry.cachedClientID", "");
user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);
user_pref("toolkit.telemetry.hybridContent.enabled", false);
user_pref("toolkit.telemetry.newProfilePing.enabled", false);
user_pref("toolkit.telemetry.previousBuildID", "");
user_pref("toolkit.telemetry.reportingpolicy.firstRun", false);
user_pref("toolkit.telemetry.server", "");
user_pref("toolkit.telemetry.server_owner", "");
user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.updatePing.enabled", false);
user_pref("datareporting.healthreport.infoURL", "");
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.policy.firstRunURL", "");
user_pref("browser.tabs.crashReporting.sendReport", false);
user_pref("browser.tabs.crashReporting.email", false);
user_pref("browser.tabs.crashReporting.emailMe", false);
user_pref("breakpad.reportURL", "");
user_pref("security.ssl.errorReporting.automatic", false);
user_pref("toolkit.crashreporter.infoURL", "");
user_pref("network.allow-experiments", false);
user_pref("dom.ipc.plugins.reportCrashUR", false);
user_pref("dom.ipc.plugins.flash.subprocess.crashreporter.enabled", false);

// cofigure search info without location reference
user_pref("browser.search.geoSpecificDefaults", false);
user_pref("browser.search.geoSpecificDefaults.url", "");
user_pref("browser.search.geoip.url", "");
user_pref("browser.search.region", "US");
user_pref("browser.search.suggest.enabled", false);
user_pref("browser.search.update", false);

// turn off push notifications
user_pref("dom.push.enabled", false);
user_pref("dom.push.connection.enabled", false);
user_pref("dom.push.serverURL", "");

// turn off possible DNS leaks over IPv6,
// disable proactive DNS
// configure DoH (DNS over HTTPS)
user_pref("network.dns.disablePrefetch", true);
user_pref("network.dns.disableIPv6", true);
user_pref("network.security.esni.enabled", true);
user_pref("network.trr.mode", 2);
user_pref("network.trr.uri", "https://cloudflare-dns.com/dns-query");

// turn off redirections
user_pref("network.captive-portal-service.enabled", false);
user_pref("network.captive-portal-service.maxInterval", 0);
user_pref("captivedetect.canonicalURL", "");

// turn off data dump to Google servers
user_pref("browser.safebrowsing.allowOverride", false);
user_pref("browser.safebrowsing.blockedURIs.enabled", false);
user_pref("browser.safebrowsing.downloads.enabled", false);
user_pref("browser.safebrowsing.downloads.remote.block_dangerous", false);
user_pref("browser.safebrowsing.downloads.remote.block_dangerous_host", false);
user_pref("browser.safebrowsing.downloads.remote.block_potentially_unwanted", false);
user_pref("browser.safebrowsing.downloads.remote.block_uncommon", false);
user_pref("browser.safebrowsing.downloads.remote.enabled", false);
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
user_pref("browser.safebrowsing.downloads.remote.url", "");
user_pref("browser.safebrowsing.provider.google.advisoryName", "");
user_pref("browser.safebrowsing.provider.google.advisoryURL", "");
user_pref("browser.safebrowsing.provider.google.gethashURL", "");
user_pref("browser.safebrowsing.provider.google.reportMalwareMistakeURL", "");
user_pref("browser.safebrowsing.provider.google.reportPhishMistakeURL", "");
user_pref("browser.safebrowsing.provider.google.reportURL", "");
user_pref("browser.safebrowsing.provider.google.updateURL", "");
user_pref("browser.safebrowsing.provider.google4.advisoryName", "");
user_pref("browser.safebrowsing.provider.google4.advisoryURL", "");
user_pref("browser.safebrowsing.provider.google4.dataSharingURL", "");
user_pref("browser.safebrowsing.provider.google4.gethashURL", "");
user_pref("browser.safebrowsing.provider.google4.reportMalwareMistakeURL", "");

// turn off DRM
user_pref("browser.eme.ui.enabled", false);
user_pref("media.eme.enabled", false);
