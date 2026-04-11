{ pkgs, features, inputs, ... }:

let
  withUI = builtins.elem "ui" features;
in
if !withUI then {} else {
  imports = [
    inputs.plasma-manager.homeModules.plasma-manager
    ./ui-settings.nix
  ];

  # overrideConfig = false means only declared keys are managed.
  # Changes made via the Plasma UI to non-declared keys persist across
  # `env-load` runs. Declared keys are rewritten on every rebuild.
  programs.plasma.overrideConfig = false;

  # Panels are hand-written because rc2nix does not capture
  # `plasma-org.kde.plasma.desktop-appletsrc`. If you add, remove or
  # reorder widgets through the Plasma UI, mirror the change here.
  # See `env-load user ui-update` for the list of things that still
  # require manual review after a UI change.
  programs.plasma.panels = [
    # Top panel: activity switcher, window title, app menu, spacer,
    # systray, pager, clock, quick-launch, memos browser, shutdown.
    {
      location = "top";
      height = 44;
      widgets = [
        {
          name = "org.kde.plasma.showActivityManager";
          config.General.showActivityName = false;
        }
        {
          name = "org.kde.windowtitle";
          config = {
            Appearance = {
              customSize = 20;
              isBold = true;
              lastSpace = 5;
              lengthKind = 2;
              midSpace = 3;
              visible = false;
            };
            Behavior = {
              filterByScreen = true;
              showTooltip = false;
            };
          };
        }
        "org.kde.plasma.appmenu"
        "org.kde.plasma.panelspacer"
        "org.kde.plasma.marginsseparator"
        {
          systemTray.items = {
            showAll = false;
            shown = [
              "org.kde.plasma.volume"
              "org.kde.plasma.bluetooth"
              "org.kde.plasma.brightness"
              "org.kde.kdeconnect"
              "org.kde.plasma.networkmanagement"
              "org.kde.plasma.battery"
              "com.github.korapp.cloudflare-warp"
              "org.kde.plasma.weather"
            ];
            hidden = [
              "org.kde.plasma.addons.katesessions"
              "org.kde.merkuro.contact.applet"
              "org.kde.plasma.diskquota"
            ];
          };
        }
        {
          name = "org.kde.plasma.pager";
          config.General = {
            currentDesktopSelected = "ShowDesktop";
            wrapPage = true;
          };
        }
        "org.kde.plasma.marginsseparator"
        {
          name = "org.kde.plasma.digitalclock";
          config.Appearance = {
            dateFormat = "custom";
            displayTimezoneFormat = "UTCOffset";
            enabledCalendarPlugins = "astronomicalevents,holidaysevents,pimevents";
            showWeekNumbers = true;
          };
        }
        "org.kde.plasma.marginsseparator"
        {
          name = "org.kde.plasma.quicklaunch";
          config.General.launcherUrls =
            "file:///home/rafael/.local/share/applications/ome-manager-path/share/applications/com.github.ryonakano.reco.desktop";
        }
        {
          name = "org.kde.plasma.webbrowser";
          config.General = {
            defaultUrl = "https://auth.memos.redeoliveira.com/login?redirect_uri=http%3A%2F%2Fmemos.redeoliveira.com%2F";
            favIcon = "https://memos.redeoliveira.com/.client/favicon.png";
            icon = "application-menu";
            privateBrowsing = false;
            url = "https://memos.redeoliveira.com/Index/Oliveiras/Home/Automation/Parâmetros de Casa";
            useDefaultUrl = true;
            useFavIcon = false;
          };
        }
        {
          name = "org.kde.plasma.shutdownorswitch";
          config.General = {
            showFullName = true;
            showNewSession = true;
            showSuspend = true;
            showSuspendThenHibernate = true;
            showUsers = true;
          };
        }
        "org.kde.plasma.marginsseparator"
      ];
    }

    # Left dock: icons-only task manager.
    # Per-activity launchers (the `[activity-uuid]` prefix syntax) cannot
    # be expressed declaratively — pin apps via the Plasma UI after first
    # login. They persist across rebuilds because overrideConfig = false.
    {
      location = "left";
      height = 44;
      widgets = [
        {
          name = "org.kde.plasma.icontasks";
          config.General = {
            fill = false;
            groupingStrategy = 0;
            iconSpacing = 3;
            indicateAudioStreams = false;
            tooltipControls = false;
          };
        }
      ];
    }
  ];
}
