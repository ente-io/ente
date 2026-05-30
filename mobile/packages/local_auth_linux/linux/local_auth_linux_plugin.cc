#include "include/local_auth_linux/local_auth_linux_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <pwd.h>
#include <security/pam_appl.h>
#include <string.h>
#include <unistd.h>

#include <cstdlib>
#include <cstring>

#define LOCAL_AUTH_LINUX_PLUGIN(obj)                                      \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), local_auth_linux_plugin_get_type(), \
                              LocalAuthLinuxPlugin))

static constexpr const char* kChannelName = "ente.io/local_auth_linux";
static constexpr const char* kDefaultPamService = "login";
static constexpr const char* kPamServiceEnv = "ENTE_LOCAL_AUTH_PAM_SERVICE";

struct _LocalAuthLinuxPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(LocalAuthLinuxPlugin, local_auth_linux_plugin,
              g_object_get_type())

struct _LocalAuthLinuxPluginClass {
  GObjectClass parent_class;
};

struct PamConversationData {
  const gchar* title;
  const gchar* reason;
  const gchar* cancel_button;
  gboolean cancelled;
};

static const gchar* string_or_default(const gchar* value,
                                      const gchar* fallback) {
  return value != nullptr && value[0] != '\0' ? value : fallback;
}

static const char* pam_service_name() {
  const char* service_name = std::getenv(kPamServiceEnv);
  return service_name != nullptr && service_name[0] != '\0' ? service_name
                                                            : kDefaultPamService;
}

static const char* current_user_name() {
  passwd* user = getpwuid(getuid());
  return user != nullptr ? user->pw_name : nullptr;
}

static FlMethodResponse* error_response(const gchar* code,
                                        const gchar* message) {
  return FL_METHOD_RESPONSE(
      fl_method_error_response_new(code, message, nullptr));
}

static const gchar* value_lookup_string(FlValue* map, const gchar* key) {
  if (map == nullptr || fl_value_get_type(map) != FL_VALUE_TYPE_MAP) {
    return nullptr;
  }
  g_autoptr(FlValue) lookup_key = fl_value_new_string(key);
  FlValue* value = fl_value_lookup(map, lookup_key);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_STRING) {
    return nullptr;
  }
  return fl_value_get_string(value);
}

static gchar* show_prompt_dialog(PamConversationData* data,
                                 const char* message,
                                 gboolean secret) {
  GtkWidget* dialog = gtk_dialog_new_with_buttons(
      string_or_default(data->title, "Authentication required"), nullptr,
      GTK_DIALOG_MODAL, string_or_default(data->cancel_button, "Cancel"),
      GTK_RESPONSE_CANCEL, "OK", GTK_RESPONSE_OK, nullptr);

  gtk_window_set_keep_above(GTK_WINDOW(dialog), TRUE);
  gtk_dialog_set_default_response(GTK_DIALOG(dialog), GTK_RESPONSE_OK);

  GtkWidget* content_area = gtk_dialog_get_content_area(GTK_DIALOG(dialog));
  gtk_container_set_border_width(GTK_CONTAINER(content_area), 16);

  const gchar* reason = string_or_default(data->reason, "");
  if (reason[0] != '\0') {
    GtkWidget* reason_label = gtk_label_new(reason);
    gtk_label_set_line_wrap(GTK_LABEL(reason_label), TRUE);
    gtk_label_set_xalign(GTK_LABEL(reason_label), 0.0);
    gtk_box_pack_start(GTK_BOX(content_area), reason_label, FALSE, FALSE, 8);
  }

  GtkWidget* message_label =
      gtk_label_new(string_or_default(message, "Password"));
  gtk_label_set_line_wrap(GTK_LABEL(message_label), TRUE);
  gtk_label_set_xalign(GTK_LABEL(message_label), 0.0);
  gtk_box_pack_start(GTK_BOX(content_area), message_label, FALSE, FALSE, 8);

  GtkWidget* entry = gtk_entry_new();
  gtk_entry_set_visibility(GTK_ENTRY(entry), !secret);
  gtk_entry_set_activates_default(GTK_ENTRY(entry), TRUE);
  gtk_box_pack_start(GTK_BOX(content_area), entry, FALSE, FALSE, 0);

  gtk_widget_show_all(dialog);
  gint response = gtk_dialog_run(GTK_DIALOG(dialog));
  gchar* result = nullptr;
  if (response == GTK_RESPONSE_OK) {
    result = g_strdup(gtk_entry_get_text(GTK_ENTRY(entry)));
  } else {
    data->cancelled = TRUE;
  }

  gtk_widget_destroy(dialog);
  while (gtk_events_pending()) {
    gtk_main_iteration();
  }
  return result;
}

static void show_message_dialog(PamConversationData* data,
                                const char* message,
                                GtkMessageType type) {
  GtkWidget* dialog = gtk_message_dialog_new(
      nullptr, GTK_DIALOG_MODAL, type, GTK_BUTTONS_OK, "%s",
      string_or_default(message, ""));
  gtk_window_set_title(GTK_WINDOW(dialog),
                       string_or_default(data->title, "Authentication"));
  gtk_window_set_keep_above(GTK_WINDOW(dialog), TRUE);
  gtk_dialog_run(GTK_DIALOG(dialog));
  gtk_widget_destroy(dialog);
  while (gtk_events_pending()) {
    gtk_main_iteration();
  }
}

static void free_pam_responses(pam_response* responses, int count) {
  if (responses == nullptr) {
    return;
  }
  for (int i = 0; i < count; i++) {
    std::free(responses[i].resp);
  }
  std::free(responses);
}

static int pam_conversation(int num_msg,
                            const struct pam_message** msg,
                            struct pam_response** resp,
                            void* appdata_ptr) {
  if (num_msg <= 0 || msg == nullptr || resp == nullptr ||
      appdata_ptr == nullptr) {
    return PAM_CONV_ERR;
  }

  PamConversationData* data =
      static_cast<PamConversationData*>(appdata_ptr);
  pam_response* responses =
      static_cast<pam_response*>(std::calloc(num_msg, sizeof(pam_response)));
  if (responses == nullptr) {
    return PAM_BUF_ERR;
  }

  for (int i = 0; i < num_msg; i++) {
    const char* message = msg[i]->msg != nullptr ? msg[i]->msg : "";
    switch (msg[i]->msg_style) {
      case PAM_PROMPT_ECHO_ON:
      case PAM_PROMPT_ECHO_OFF: {
        g_autofree gchar* answer =
            show_prompt_dialog(data, message,
                               msg[i]->msg_style == PAM_PROMPT_ECHO_OFF);
        if (data->cancelled || answer == nullptr) {
          free_pam_responses(responses, i);
          return PAM_CONV_ERR;
        }
        responses[i].resp = strdup(answer);
        if (responses[i].resp == nullptr) {
          free_pam_responses(responses, i);
          return PAM_BUF_ERR;
        }
        break;
      }
      case PAM_TEXT_INFO:
        show_message_dialog(data, message, GTK_MESSAGE_INFO);
        break;
      case PAM_ERROR_MSG:
        show_message_dialog(data, message, GTK_MESSAGE_ERROR);
        break;
      default:
        free_pam_responses(responses, i);
        return PAM_CONV_ERR;
    }
  }

  *resp = responses;
  return PAM_SUCCESS;
}

static gboolean can_authenticate_with_pam() {
  const char* user_name = current_user_name();
  if (user_name == nullptr) {
    return FALSE;
  }

  pam_handle_t* pam_handle = nullptr;
  pam_conv conversation = {nullptr, nullptr};
  int status =
      pam_start(pam_service_name(), user_name, &conversation, &pam_handle);
  if (pam_handle != nullptr) {
    pam_end(pam_handle, status);
  }
  return status == PAM_SUCCESS;
}

static gboolean authenticate_with_pam(const gchar* reason,
                                      gchar** error_code,
                                      gchar** error_message,
                                      gboolean* authentication_failed) {
  if (gdk_display_get_default() == nullptr) {
    *error_code = g_strdup("ui_unavailable");
    *error_message = g_strdup("No GTK display is available.");
    return FALSE;
  }

  const char* user_name = current_user_name();
  if (user_name == nullptr) {
    *error_code = g_strdup("unsupported_runtime");
    *error_message = g_strdup("Unable to determine the current user.");
    return FALSE;
  }

  PamConversationData conversation_data = {
      "Authentication required",
      string_or_default(reason, "Authenticate with your system password."),
      "Cancel", FALSE};
  pam_conv conversation = {pam_conversation, &conversation_data};
  pam_handle_t* pam_handle = nullptr;

  int status =
      pam_start(pam_service_name(), user_name, &conversation, &pam_handle);
  if (status != PAM_SUCCESS) {
    *error_code = g_strdup("pam_unavailable");
    *error_message = g_strdup(pam_strerror(pam_handle, status));
    if (pam_handle != nullptr) {
      pam_end(pam_handle, status);
    }
    return FALSE;
  }

  status = pam_authenticate(pam_handle, 0);
  if (status == PAM_SUCCESS) {
    status = pam_acct_mgmt(pam_handle, 0);
  }

  g_autofree gchar* pam_message = g_strdup(pam_strerror(pam_handle, status));
  pam_end(pam_handle, status);

  if (status == PAM_SUCCESS) {
    return TRUE;
  }

  if (conversation_data.cancelled) {
    *error_code = g_strdup("authentication_canceled");
    *error_message = g_strdup("Authentication was canceled.");
  } else if (status == PAM_AUTH_ERR || status == PAM_USER_UNKNOWN ||
             status == PAM_MAXTRIES) {
    *authentication_failed = TRUE;
    *error_message =
        g_strdup(string_or_default(pam_message, "Authentication failed."));
  } else if (status == PAM_ACCT_EXPIRED || status == PAM_PERM_DENIED ||
             status == PAM_NEW_AUTHTOK_REQD) {
    *error_code = g_strdup("account_unavailable");
    *error_message =
        g_strdup(string_or_default(pam_message, "Account is unavailable."));
  } else {
    *error_code = g_strdup("pam_error");
    *error_message =
        g_strdup(string_or_default(pam_message, "PAM authentication failed."));
  }
  return FALSE;
}

static void local_auth_linux_plugin_handle_method_call(
    LocalAuthLinuxPlugin* self,
    FlMethodCall* method_call) {
  (void)self;
  g_autoptr(FlMethodResponse) response = nullptr;
  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "isDeviceSupported") == 0) {
    g_autoptr(FlValue) result =
        fl_value_new_bool(can_authenticate_with_pam());
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "authenticate") == 0) {
    FlValue* arguments = fl_method_call_get_args(method_call);
    const gchar* reason = value_lookup_string(arguments, "localizedReason");
    g_autofree gchar* error_code = nullptr;
    g_autofree gchar* error_message = nullptr;
    gboolean authentication_failed = FALSE;

    if (authenticate_with_pam(reason, &error_code, &error_message,
                              &authentication_failed)) {
      g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    } else if (authentication_failed) {
      g_autoptr(FlValue) result = fl_value_new_bool(FALSE);
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    } else {
      response = error_response(
          string_or_default(error_code, "pam_error"),
          string_or_default(error_message, "Authentication failed."));
    }
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void local_auth_linux_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(local_auth_linux_plugin_parent_class)->dispose(object);
}

static void local_auth_linux_plugin_class_init(
    LocalAuthLinuxPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = local_auth_linux_plugin_dispose;
}

static void local_auth_linux_plugin_init(LocalAuthLinuxPlugin* self) {
  (void)self;
}

static void method_call_cb(FlMethodChannel* channel,
                           FlMethodCall* method_call,
                           gpointer user_data) {
  (void)channel;
  LocalAuthLinuxPlugin* plugin = LOCAL_AUTH_LINUX_PLUGIN(user_data);
  local_auth_linux_plugin_handle_method_call(plugin, method_call);
}

void local_auth_linux_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  LocalAuthLinuxPlugin* plugin = LOCAL_AUTH_LINUX_PLUGIN(
      g_object_new(local_auth_linux_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar), kChannelName,
      FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
