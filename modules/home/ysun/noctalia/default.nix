{ inputs, ... }:

{ config, lib, ... }:

{
  imports = [ inputs.noctalia.homeModules.default ];

  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    programs.noctalia-shell = {
      enable = true;

      settings = {
        appLauncher = {
          autoPasteClipboard = false;
          clipboardWatchImageCommand = "wl-paste --type image --watch cliphist store";
          clipboardWatchTextCommand = "wl-paste --type text --watch cliphist store";
          clipboardWrapText = true;
          customLaunchPrefix = "";
          customLaunchPrefixEnabled = false;
          density = "comfortable";
          enableClipPreview = true;
          enableClipboardChips = true;
          enableClipboardHistory = true;
          enableClipboardSmartIcons = true;
          enableSessionSearch = true;
          enableSettingsSearch = true;
          enableWindowsSearch = true;
          iconMode = "tabler";
          ignoreMouseInput = false;
          overviewLayer = true;
          pinnedApps = [ ];
          position = "center";
          screenshotAnnotationTool = "";
          showCategories = true;
          showIconBackground = false;
          sortByMostUsed = true;
          terminalCommand = "alacritty -e";
          viewMode = "list";
        };
        audio = {
          mprisBlacklist = [ ];
          preferredPlayer = "";
          spectrumFrameRate = 30;
          spectrumMirrored = true;
          visualizerType = "wave";
          volumeFeedback = false;
          volumeFeedbackSoundFile = "";
          volumeOverdrive = true;
          volumeStep = 5;
        };
        bar = {
          autoHideDelay = 500;
          autoShowDelay = 150;
          backgroundOpacity = 1;
          barType = "simple";
          capsuleColorKey = "none";
          capsuleOpacity = 1;
          contentPadding = 2;
          density = "comfortable";
          displayMode = "always_visible";
          enableExclusionZoneInset = true;
          fontScale = 1.4;
          frameRadius = 12;
          frameThickness = 8;
          hideOnOverview = false;
          marginHorizontal = 4;
          marginVertical = 4;
          middleClickAction = "none";
          middleClickCommand = "";
          middleClickFollowMouse = false;
          monitors = [ ];
          mouseWheelAction = "none";
          mouseWheelWrap = true;
          outerCorners = true;
          position = "top";
          reverseScroll = false;
          rightClickAction = "none";
          rightClickCommand = "";
          rightClickFollowMouse = true;
          screenOverrides = [
            {
              enabled = false;
              name = "DP-4";
            }
          ];
          showCapsule = false;
          showOnWorkspaceSwitch = true;
          showOutline = false;
          useSeparateOpacity = false;
          widgetSpacing = 6;
          widgets = {
            center = [ ];
            left = [
              {
                characterCount = 2;
                colorizeIcons = false;
                emptyColor = "primary";
                enableScrollWheel = false;
                focusedColor = "primary";
                followFocusedScreen = false;
                fontWeight = "bold";
                groupedBorderOpacity = 1;
                hideUnoccupied = false;
                iconScale = 0.8;
                id = "Workspace";
                labelMode = "index";
                occupiedColor = "primary";
                pillSize = 0.85;
                showApplications = false;
                showApplicationsHover = false;
                showBadge = true;
                showLabelsOnlyWhenOccupied = false;
                unfocusedIconsOpacity = 1;
              }
            ];
            right = [
              {
                compactMode = true;
                diskPath = "/";
                iconColor = "none";
                id = "SystemMonitor";
                showCpuCores = false;
                showCpuFreq = false;
                showCpuTemp = false;
                showCpuUsage = true;
                showDiskAvailable = false;
                showDiskUsage = false;
                showDiskUsageAsPercent = false;
                showGpuTemp = false;
                showLoadAverage = false;
                showMemoryAsPercent = true;
                showMemoryUsage = true;
                showNetworkStats = true;
                showSwapUsage = false;
                textColor = "none";
                useMonospaceFont = true;
                usePadding = false;
              }
              {
                deviceNativePath = "__default__";
                displayMode = "icon-always";
                hideIfIdle = false;
                hideIfNotDetected = false;
                id = "Battery";
                showNoctaliaPerformance = false;
                showPowerProfiles = false;
              }
              {
                colorizeDistroLogo = false;
                colorizeSystemIcon = "none";
                customIconPath = "";
                enableColorization = false;
                icon = "adjustments";
                id = "ControlCenter";
                useDistroLogo = false;
              }
              {
                clockColor = "none";
                customFont = "Sans Serif";
                formatHorizontal = "ddd MMM d HH:mm:ss";
                formatVertical = "";
                id = "Clock";
                tooltipFormat = "";
                useCustomFont = false;
              }
              {
                hideWhenZero = true;
                hideWhenZeroUnread = true;
                iconColor = "none";
                id = "NotificationHistory";
                showUnreadBadge = true;
                unreadBadgeColor = "primary";
              }
            ];
          };
        };
        brightness = {
          backlightDeviceMappings = [ ];
          brightnessStep = 5;
          enableDdcSupport = true;
          enforceMinimum = false;
        };
        calendar = {
          cards = [
            {
              enabled = true;
              id = "calendar-header-card";
            }
            {
              enabled = true;
              id = "calendar-month-card";
            }
            {
              enabled = true;
              id = "weather-card";
            }
          ];
        };
        colorSchemes = {
          darkMode = true;
          generationMethod = "tonal-spot";
          manualSunrise = "06:30";
          manualSunset = "18:30";
          monitorForColors = "";
          predefinedScheme = "Nord";
          schedulingMode = "off";
          syncGsettings = true;
          useWallpaperColors = false;
        };
        controlCenter = {
          cards = [
            {
              enabled = true;
              id = "profile-card";
            }
            {
              enabled = true;
              id = "shortcuts-card";
            }
            {
              enabled = true;
              id = "audio-card";
            }
            {
              enabled = true;
              id = "brightness-card";
            }
            {
              enabled = true;
              id = "media-sysmon-card";
            }
            {
              enabled = true;
              id = "weather-card";
            }
          ];
          diskPath = "/";
          position = "top_right";
          shortcuts = {
            left = [
              { id = "Network"; }
              { id = "Bluetooth"; }
              { id = "WallpaperSelector"; }
            ];
            right = [
              { id = "Notifications"; }
              { id = "KeepAwake"; }
              { id = "NightLight"; }
            ];
          };
        };
        desktopWidgets = {
          enabled = false;
          gridSnap = false;
          gridSnapScale = false;
          monitorWidgets = [
            {
              name = "DP-4";
              widgets = [
                {
                  clockColor = "none";
                  clockStyle = "digital";
                  customFont = "";
                  format = "HH:mm\\nd MMMM yyyy";
                  id = "Clock";
                  roundedCorners = true;
                  showBackground = true;
                  useCustomFont = false;
                  x = 50;
                  y = 50;
                }
              ];
            }
          ];
          overviewEnabled = true;
        };
        dock = {
          animationSpeed = 1;
          backgroundOpacity = 1;
          colorizeIcons = true;
          deadOpacity = 0.6;
          displayMode = "auto_hide";
          dockType = "attached";
          enabled = false;
          floatingRatio = 1;
          groupApps = true;
          groupClickAction = "cycle";
          groupContextMenuMode = "extended";
          groupIndicatorStyle = "dots";
          inactiveIndicators = true;
          indicatorColor = "primary";
          indicatorOpacity = 0.6;
          indicatorThickness = 3;
          launcherIcon = "";
          launcherIconColor = "none";
          launcherPosition = "end";
          launcherUseDistroLogo = false;
          monitors = [ ];
          onlySameOutput = true;
          pinnedApps = [ ];
          pinnedStatic = true;
          position = "bottom";
          showDockIndicator = false;
          showLauncherIcon = false;
          sitOnFrame = false;
          size = 1;
        };
        general = {
          allowPanelsOnScreenWithoutBar = true;
          allowPasswordWithFprintd = true;
          animationDisabled = false;
          animationSpeed = 1;
          autoStartAuth = true;
          avatarImage = lib.blueprint.users.ysun.meta.profilePicture;
          boxRadiusRatio = 1;
          clockFormat = "hh\\nmm";
          clockStyle = "digital";
          compactLockScreen = false;
          dimmerOpacity = 0;
          enableBlurBehind = true;
          enableLockScreenCountdown = true;
          enableLockScreenMediaControls = true;
          enableShadows = true;
          forceBlackScreenCorners = false;
          iRadiusRatio = 1;
          keybinds = {
            keyDown = [ "Down" ];
            keyEnter = [
              "Return"
              "Enter"
            ];
            keyEscape = [ "Esc" ];
            keyLeft = [ "Left" ];
            keyRemove = [ "Del" ];
            keyRight = [ "Right" ];
            keyUp = [ "Up" ];
          };
          language = "";
          lockOnSuspend = true;
          lockScreenAnimations = true;
          lockScreenBlur = 0;
          lockScreenCountdownDuration = 10000;
          lockScreenMonitors = [ ];
          lockScreenTint = 0;
          passwordChars = false;
          radiusRatio = 1;
          reverseScroll = false;
          scaleRatio = 1;
          screenRadiusRatio = 1;
          shadowDirection = "bottom";
          shadowOffsetX = 0;
          shadowOffsetY = 3;
          showChangelogOnStartup = false;
          showHibernateOnLockScreen = false;
          showScreenCorners = false;
          showSessionButtonsOnLockScreen = false;
          smoothScrollEnabled = true;
          telemetryEnabled = false;
        };
        hooks = {
          colorGeneration = "";
          darkModeChange = "";
          enabled = false;
          performanceModeDisabled = "";
          performanceModeEnabled = "";
          screenLock = "";
          screenUnlock = "";
          session = "";
          startup = "";
          wallpaperChange = "";
        };
        idle = {
          customCommands = "[]";
          enabled = true;
          fadeDuration = 5;
          lockCommand = "";
          lockTimeout = 300;
          resumeLockCommand = "";
          resumeScreenOffCommand = "";
          resumeSuspendCommand = "";
          screenOffCommand = "";
          screenOffTimeout = 3600;
          suspendCommand = "";
          suspendTimeout = 86400;
        };
        location = {
          analogClockInCalendar = false;
          firstDayOfWeek = 1;
          hideWeatherCityName = false;
          hideWeatherTimezone = false;
          name = "Grenoble, France";
          showCalendarEvents = true;
          showCalendarWeather = true;
          showWeekNumberInCalendar = false;
          use12hourFormat = false;
          useFahrenheit = false;
          weatherEnabled = true;
          weatherShowEffects = false;
        };
        network = {
          airplaneModeEnabled = false;
          bluetoothAutoConnect = true;
          bluetoothDetailsViewMode = "grid";
          bluetoothHideUnnamedDevices = true;
          bluetoothRssiPollIntervalMs = 60000;
          bluetoothRssiPollingEnabled = false;
          disableDiscoverability = true;
          networkPanelView = "wifi";
          wifiDetailsViewMode = "grid";
        };
        nightLight = {
          autoSchedule = true;
          dayTemp = "6500";
          enabled = false;
          forced = false;
          manualSunrise = "06:30";
          manualSunset = "18:30";
          nightTemp = "4000";
        };
        noctaliaPerformance = {
          disableDesktopWidgets = true;
          disableWallpaper = true;
        };
        notifications = {
          backgroundOpacity = 1;
          clearDismissed = true;
          criticalUrgencyDuration = 15;
          density = "default";
          enableBatteryToast = true;
          enableKeyboardLayoutToast = true;
          enableMarkdown = true;
          enableMediaToast = true;
          enabled = true;
          location = "top_right";
          lowUrgencyDuration = 3;
          monitors = [ ];
          normalUrgencyDuration = 8;
          overlayLayer = true;
          respectExpireTimeout = false;
          saveToHistory = {
            critical = true;
            low = true;
            normal = true;
          };
          sounds = {
            criticalSoundFile = "";
            enabled = false;
            excludedApps = "discord,firefox,chrome,chromium,edge";
            lowSoundFile = "";
            normalSoundFile = "";
            separateSounds = false;
            volume = 0.5;
          };
        };
        osd = {
          autoHideMs = 2000;
          backgroundOpacity = 1;
          enabled = true;
          enabledTypes = [
            0
            1
            2
            3
          ];
          location = "top_right";
          monitors = [ ];
          overlayLayer = true;
        };
        plugins = {
          autoUpdate = false;
          notifyUpdates = false;
        };
        sessionMenu = {
          countdownDuration = 10000;
          enableCountdown = true;
          largeButtonsLayout = "grid";
          largeButtonsStyle = true;
          position = "center";
          powerOptions = [
            {
              action = "lock";
              command = "";
              countdownEnabled = true;
              enabled = true;
              keybind = "1";
            }
            {
              action = "suspend";
              command = "";
              countdownEnabled = true;
              enabled = true;
              keybind = "2";
            }
            {
              action = "hibernate";
              command = "";
              countdownEnabled = true;
              enabled = true;
              keybind = "3";
            }
            {
              action = "reboot";
              command = "";
              countdownEnabled = true;
              enabled = true;
              keybind = "4";
            }
            {
              action = "logout";
              command = "";
              countdownEnabled = true;
              enabled = true;
              keybind = "5";
            }
            {
              action = "shutdown";
              command = "";
              countdownEnabled = true;
              enabled = true;
              keybind = "6";
            }
            {
              action = "rebootToUefi";
              command = "";
              countdownEnabled = true;
              enabled = false;
              keybind = "";
            }
            {
              action = "userspaceReboot";
              command = "";
              countdownEnabled = true;
              enabled = false;
              keybind = "";
            }
          ];
          showHeader = true;
          showKeybinds = true;
        };
        settingsVersion = 59;
        systemMonitor = {
          batteryCriticalThreshold = 5;
          batteryWarningThreshold = 20;
          cpuCriticalThreshold = 90;
          cpuWarningThreshold = 80;
          criticalColor = "";
          diskAvailCriticalThreshold = 10;
          diskAvailWarningThreshold = 20;
          diskCriticalThreshold = 90;
          diskWarningThreshold = 80;
          enableDgpuMonitoring = false;
          externalMonitor = "resources || missioncenter || jdsystemmonitor || corestats || system-monitoring-center || gnome-system-monitor || plasma-systemmonitor || mate-system-monitor || ukui-system-monitor || deepin-system-monitor || pantheon-system-monitor";
          gpuCriticalThreshold = 90;
          gpuWarningThreshold = 80;
          memCriticalThreshold = 90;
          memWarningThreshold = 80;
          swapCriticalThreshold = 90;
          swapWarningThreshold = 80;
          tempCriticalThreshold = 90;
          tempWarningThreshold = 80;
          useCustomColors = false;
          warningColor = "";
        };
        templates = {
          activeTemplates = [ ];
          enableUserTheming = false;
        };
        ui = {
          boxBorderEnabled = false;
          fontDefault = "Sans Serif";
          fontDefaultScale = 1;
          fontFixed = "monospace";
          fontFixedScale = 1;
          panelBackgroundOpacity = 0.75;
          panelsAttachedToBar = true;
          scrollbarAlwaysVisible = true;
          settingsPanelMode = "window";
          settingsPanelSideBarCardStyle = false;
          tooltipsEnabled = true;
          translucentWidgets = false;
        };
        wallpaper = {
          automationEnabled = false;
          directory = lib.blueprint.users.ysun.meta.wallpapersDir;
          enableMultiMonitorDirectories = false;
          enabled = true;
          favorites = [ ];
          fillColor = "#000000";
          fillMode = "crop";
          hideWallpaperFilenames = false;
          monitorDirectories = [ ];
          overviewBlur = 0.4;
          overviewEnabled = false;
          overviewTint = 0.6;
          panelPosition = "follow_bar";
          randomIntervalSec = 300;
          setWallpaperOnAllMonitors = true;
          showHiddenFiles = false;
          skipStartupTransition = true;
          solidColor = "#1a1a2e";
          sortOrder = "name";
          transitionDuration = 1500;
          transitionEdgeSmoothness = 0.05;
          transitionType = [ ];
          useOriginalImages = true;
          useSolidColor = false;
          useWallhaven = false;
          viewMode = "single";
          wallhavenApiKey = "";
          wallhavenCategories = "111";
          wallhavenOrder = "desc";
          wallhavenPurity = "100";
          wallhavenQuery = "";
          wallhavenRatios = "";
          wallhavenResolutionHeight = "";
          wallhavenResolutionMode = "atleast";
          wallhavenResolutionWidth = "";
          wallhavenSorting = "relevance";
          wallpaperChangeMode = "random";
        };
      };
    };
  };
}
