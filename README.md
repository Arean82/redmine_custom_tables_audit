# 🧾 Redmine Custom Tables Audit Plugin

### Audit and log all **Custom Tables** changes directly into Redmine’s issue history

---

## 📘 Overview

The **Redmine Custom Tables Audit** plugin extends the
[`custom_tables`](https://github.com/frywer/custom_tables) plugin by automatically logging any
**create / update / delete** actions performed on *Custom Table records*.

These changes are recorded in the **issue journal (history tab)**, making Redmine’s activity trail complete and transparent.

---

## ✨ Features

* 🧩 **Observer-based** — clean integration without altering core or plugin models
* 🕓 Automatically adds `created_by` and `created_at` columns to Custom Table records
* 🧍 Tracks **who created** a record and **when**
* 🧾 Logs all **field-level changes** in the issue’s journal:

  ```
  Custom Table Change:
  Changed field_x: "Old Value" → "New Value"
  Changed field_y: "Yes" → "No"
  ```
* ⚙️ Fully **configurable** from Redmine’s Admin → Plugins → Configure
* 🔒 Works only for users with appropriate permissions (via Redmine journal system)
* 🌐 Localization-ready (English included)

---

## 🧱 Requirements

| Component | Version                                                            |
| --------- | ------------------------------------------------------------------ |
| Redmine   | 5.0+                                                               |
| Ruby      | 2.7+                                                               |
| Plugin    | [Custom Tables by frywer](https://github.com/frywer/custom_tables) |

---

## 🧰 Installation

1. Clone or copy the plugin into Redmine’s `plugins/` directory:

   ```bash
   cd /path/to/redmine/plugins
   git clone https://github.com/Arean82/redmine_custom_tables_audit.git
   ```

2. Run the plugin migrations:

   ```bash
   bundle exec rake redmine:plugins:migrate NAME=redmine_custom_tables_audit RAILS_ENV=production
   ```

3. Restart Redmine (or Passenger / Apache / Puma):

   ```bash
   touch /path/to/redmine/tmp/restart.txt
   ```

---

## ⚙️ Configuration

1. Go to **Administration → Plugins**
2. Find **Custom Tables Audit**
3. Click **Configure**

You’ll see a page like this:

```
[✔] Enable Audit Logging
Future Options (Coming Soon):
Configure which custom tables and fields to audit.
```

### Settings Stored

| Setting                | Description                                  |
| ---------------------- | -------------------------------------------- |
| `enable_audit_logging` | Enables or disables journal logging globally |

---

## 🗃️ Database Changes

The plugin automatically adds two columns to the Custom Tables records table:

| Column       | Type     | Description                            |
| ------------ | -------- | -------------------------------------- |
| `created_by` | integer  | User ID of creator (`User.current.id`) |
| `created_at` | datetime | Timestamp of creation                  |

These are added via a migration (`001_add_audit_columns_to_custom_table_records.rb`).

---

## 🧠 How It Works

* The plugin registers an **ActiveRecord observer** for the model `CustomTables::Record`.
* On each `create`, `update`, or `destroy` event:

  * It collects all changed fields.
  * It creates a **journal entry** in the associated Redmine issue (`Issue` model).
  * Journal entries are visible in the **History** tab.

Example entry:

```
Custom Table Change:
Changed severity: "Low" → "High"
Changed probability: "2" → "4"
```

---

## 🧩 File Structure

```
redmine_custom_tables_audit/
├── init.rb
├── app/
│   ├── observers/
│   │   └── custom_table_record_observer.rb
│   ├── controllers/
│   │   └── audit_settings_controller.rb
│   └── views/
│       └── audit_settings/
│           └── index.html.erb
├── lib/
│   └── custom_tables_audit/
│       └── hooks.rb
├── config/
│   ├── locales/en.yml
│   └── routes.rb
└── db/
    └── migrate/
        └── 001_add_audit_columns_to_custom_table_records.rb
```

---

## 🌍 Localization (Default: English)

`config/locales/en.yml`

```yaml
en:
  custom_tables_audit:
    log_prefix: "Custom Table Change:"
    settings_updated: "Custom Tables Audit settings saved successfully!"
  audit_settings:
    title: "Custom Tables Audit Configuration"
  notice_successful_update: "Settings were successfully updated."
```

---

## 🧑‍💻 Development Notes

* Based on **Rails Observers** for decoupled logging
* Compatible with Redmine core `Journal` model
* Uses `Setting.plugin_redmine_custom_tables_audit` for configuration
* Designed for extension (you can add more configurable features later)

---

## 🧩 Future Enhancements (planned)

* Select which **custom tables** to audit
* Choose **specific fields** to log
* Role-based logging (exclude admins)
* Optional email notifications for high-impact changes

---

## 🧹 Uninstallation

To remove the plugin:

```bash
bundle exec rake redmine:plugins:migrate NAME=redmine_custom_tables_audit VERSION=0 RAILS_ENV=production
rm -rf plugins/redmine_custom_tables_audit
```

Restart Redmine.

---

## 🧑‍🏭 Author & License

**Author:** Arean Narrayan
**License:** MIT
**Compatibility:** Redmine 5.0+

