; <?php exit; ?> DO NOT REMOVE THIS LINE
; file automatically generated or modified by Matomo; you can manually override the default values in global.ini.php by redefining them in this file.
[database]
host = "${db_host}"
username = "matomo"
password = "${db_password}"
dbname = "matomo"
tables_prefix = "piwik_"

[General]
proxy_client_headers[] = "HTTP_X_FORWARDED_FOR"
salt = "${salt}"
trusted_hosts[] = "${trusted_host}"
assume_secure_protocol=1
datatable_archiving_maximum_rows_actions = 9000
enable_plugins_admin = 0
enable_processing_unique_visitors_year = 1
enable_processing_unique_visitors_range = 1
enable_update_communication = 1
enable_segments_cache = 0
minimum_memory_limit_when_archiving = 1536

[log]
log_writers[] = file
log_level = INFO
logger_file_path = /dev/stdout

[Tracker]
trust_visitors_cookies = 1
visit_standard_length = 5400
scheduled_tasks_min_interval = 0

[Plugins]
Plugins[] = DBStats
Plugins[] = CorePluginsAdmin
Plugins[] = CoreAdminHome
Plugins[] = CoreHome
Plugins[] = WebsiteMeasurable
Plugins[] = IntranetMeasurable
Plugins[] = Diagnostics
Plugins[] = CoreVisualizations
Plugins[] = Proxy
Plugins[] = API
Plugins[] = Widgetize
Plugins[] = Transitions
Plugins[] = LanguagesManager
Plugins[] = Actions
Plugins[] = Dashboard
Plugins[] = MultiSites
Plugins[] = Referrers
Plugins[] = UserLanguage
Plugins[] = DevicesDetection
Plugins[] = Goals
Plugins[] = Ecommerce
Plugins[] = SEO
Plugins[] = Events
Plugins[] = UserCountry
Plugins[] = GeoIp2
Plugins[] = VisitsSummary
Plugins[] = VisitFrequency
Plugins[] = VisitTime
Plugins[] = VisitorInterest
Plugins[] = RssWidget
Plugins[] = Feedback
Plugins[] = Monolog
Plugins[] = Login
Plugins[] = TwoFactorAuth
Plugins[] = UsersManager
Plugins[] = SitesManager
Plugins[] = Installation
Plugins[] = CoreUpdater
Plugins[] = CoreConsole
Plugins[] = ScheduledReports
Plugins[] = UserCountryMap
Plugins[] = Live
Plugins[] = CustomVariables
Plugins[] = PrivacyManager
Plugins[] = ImageGraph
Plugins[] = Annotations
Plugins[] = MobileMessaging
Plugins[] = Overlay
Plugins[] = SegmentEditor
Plugins[] = Insights
Plugins[] = Morpheus
Plugins[] = Contents
Plugins[] = BulkTracking
Plugins[] = Resolution
Plugins[] = DevicePlugins
Plugins[] = Heartbeat
Plugins[] = Intl
Plugins[] = Marketplace
Plugins[] = ProfessionalServices
Plugins[] = UserId
Plugins[] = CustomPiwikJs

