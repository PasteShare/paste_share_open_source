//
//  Generated file. Do not edit.
//

#include "generated_plugin_registrant.h"

#include <receive_sharing_intent/receive_sharing_intent_plugin.h>
#include <url_launcher_windows/url_launcher_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  ReceiveSharingIntentPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ReceiveSharingIntentPlugin"));
  UrlLauncherPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherPlugin"));
}
