package com.transistorsoft.tsbackgroundfetch;

import android.app.job.JobInfo;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;
import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Created by chris on 2018-01-11.
 */

public class BackgroundFetchConfig {
    private Builder config;

    private static final int MINIMUM_FETCH_INTERVAL = 1;
    private static final int DEFAULT_FETCH_INTERVAL = 15;

    public static final String FIELD_TASK_ID = "taskId";
    public static final String FIELD_MINIMUM_FETCH_INTERVAL = "minimumFetchInterval";
    public static final String FIELD_START_ON_BOOT = "startOnBoot";
    public static final String FIELD_REQUIRED_NETWORK_TYPE = "requiredNetworkType";
    public static final String FIELD_REQUIRES_BATTERY_NOT_LOW = "requiresBatteryNotLow";
    public static final String FIELD_REQUIRES_CHARGING = "requiresCharging";
    public static final String FIELD_REQUIRES_DEVICE_IDLE = "requiresDeviceIdle";
    public static final String FIELD_REQUIRES_STORAGE_NOT_LOW = "requiresStorageNotLow";
    public static final String FIELD_STOP_ON_TERMINATE = "stopOnTerminate";
    public static final String FIELD_JOB_SERVICE = "jobService";
    public static final String FIELD_FORCE_ALARM_MANAGER = "forceAlarmManager";
    public static final String FIELD_PERIODIC = "periodic";
    public static final String FIELD_DELAY = "delay";
    public static final String FIELD_IS_FETCH_TASK = "isFetchTask";

    public static class Builder {
        private String taskId;
        private int minimumFetchInterval           = DEFAULT_FETCH_INTERVAL;
        private long delay                  = -1;
        private boolean periodic            = false;
        private boolean forceAlarmManager   = false;
        private boolean stopOnTerminate     = true;
        private boolean startOnBoot         = false;
        private int requiredNetworkType     = 0;
        private boolean requiresBatteryNotLow   = false;
        private boolean requiresCharging    = false;
        private boolean requiresDeviceIdle  = false;
        private boolean requiresStorageNotLow = false;
        private boolean isFetchTask         = false;

        private String jobService           = null;

        public Builder setTaskId(String taskId) {
            this.taskId = taskId;
            return this;
        }

        public Builder setIsFetchTask(boolean value) {
            this.isFetchTask = value;
            return this;
        }

        public Builder setMinimumFetchInterval(int fetchInterval) {
            if (fetchInterval >= MINIMUM_FETCH_INTERVAL) {
                this.minimumFetchInterval = fetchInterval;
            }
            return this;
        }

        public Builder setStopOnTerminate(boolean stopOnTerminate) {
            this.stopOnTerminate = stopOnTerminate;
            return this;
        }

        public Builder setStartOnBoot(boolean startOnBoot) {
            this.startOnBoot = startOnBoot;
            return this;
        }

        public Builder setRequiredNetworkType(int networkType) {

            if (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                if (
                    (networkType != JobInfo.NETWORK_TYPE_ANY) &&
                    (networkType != JobInfo.NETWORK_TYPE_CELLULAR) &&
                    (networkType != JobInfo.NETWORK_TYPE_NONE) &&
                    (networkType != JobInfo.NETWORK_TYPE_NOT_ROAMING) &&
                    (networkType != JobInfo.NETWORK_TYPE_UNMETERED)
                ) {
                    Log.e(BackgroundFetch.TAG, "[ERROR] Invalid " + FIELD_REQUIRED_NETWORK_TYPE + ": " + networkType + "; Defaulting to NETWORK_TYPE_NONE");
                    networkType = JobInfo.NETWORK_TYPE_NONE;
                }
                this.requiredNetworkType = networkType;
            }
            return this;
        }

        public Builder setRequiresBatteryNotLow(boolean value) {
            this.requiresBatteryNotLow = value;
            return this;
        }

        public Builder setRequiresCharging(boolean value) {
            this.requiresCharging = value;
            return this;
        }

        public Builder setRequiresDeviceIdle(boolean value) {
            this.requiresDeviceIdle = value;
            return this;
        }

        public Builder setRequiresStorageNotLow(boolean value) {
            this.requiresStorageNotLow = value;
            return this;
        }

        public Builder setJobService(String className) {
            this.jobService = className;
            return this;
        }

        public Builder setForceAlarmManager(boolean value) {
            this.forceAlarmManager = value;
            return this;
        }

        public Builder setPeriodic(boolean value) {
            this.periodic = value;
            return this;
        }

        public Builder setDelay(long value) {
            this.delay = value;
            return this;
        }

        public BackgroundFetchConfig build() {
            return new BackgroundFetchConfig(this);
        }

        public BackgroundFetchConfig load(Context context, String taskId) {
            SharedPreferences preferences = context.getSharedPreferences(BackgroundFetch.TAG + ":" + taskId, 0);
            if (preferences.contains(FIELD_TASK_ID)) {
                setTaskId(preferences.getString(FIELD_TASK_ID, taskId));
            }
            if (preferences.contains(FIELD_IS_FETCH_TASK)) {
                setIsFetchTask(preferences.getBoolean(FIELD_IS_FETCH_TASK, isFetchTask));
            }
            if (preferences.contains(FIELD_MINIMUM_FETCH_INTERVAL)) {
                setMinimumFetchInterval(preferences.getInt(FIELD_MINIMUM_FETCH_INTERVAL, minimumFetchInterval));
            }
            if (preferences.contains(FIELD_STOP_ON_TERMINATE)) {
                setStopOnTerminate(preferences.getBoolean(FIELD_STOP_ON_TERMINATE, stopOnTerminate));
            }
            if (preferences.contains(FIELD_REQUIRED_NETWORK_TYPE)) {
                setRequiredNetworkType(preferences.getInt(FIELD_REQUIRED_NETWORK_TYPE, requiredNetworkType));
            }
            if (preferences.contains(FIELD_REQUIRES_BATTERY_NOT_LOW)) {
                setRequiresBatteryNotLow(preferences.getBoolean(FIELD_REQUIRES_BATTERY_NOT_LOW, requiresBatteryNotLow));
            }
            if (preferences.contains(FIELD_REQUIRES_CHARGING)) {
                setRequiresCharging(preferences.getBoolean(FIELD_REQUIRES_CHARGING, requiresCharging));
            }
            if (preferences.contains(FIELD_REQUIRES_DEVICE_IDLE)) {
                setRequiresDeviceIdle(preferences.getBoolean(FIELD_REQUIRES_DEVICE_IDLE, requiresDeviceIdle));
            }
            if (preferences.contains(FIELD_REQUIRES_STORAGE_NOT_LOW)) {
                setRequiresStorageNotLow(preferences.getBoolean(FIELD_REQUIRES_STORAGE_NOT_LOW, requiresStorageNotLow));
            }
            if (preferences.contains(FIELD_START_ON_BOOT)) {
                setStartOnBoot(preferences.getBoolean(FIELD_START_ON_BOOT, startOnBoot));
            }
            if (preferences.contains(FIELD_JOB_SERVICE)) {
                setJobService(preferences.getString(FIELD_JOB_SERVICE, null));
            }
            if (preferences.contains(FIELD_FORCE_ALARM_MANAGER)) {
                setForceAlarmManager(preferences.getBoolean(FIELD_FORCE_ALARM_MANAGER, forceAlarmManager));
            }
            if (preferences.contains(FIELD_PERIODIC)) {
                setPeriodic(preferences.getBoolean(FIELD_PERIODIC, periodic));
            }
            if (preferences.contains(FIELD_DELAY)) {
                setDelay(preferences.getLong(FIELD_DELAY, delay));
            }
            return new BackgroundFetchConfig(this);
        }
    }

    private BackgroundFetchConfig(Builder builder) {
        config = builder;
        // Validate config
        if (config.jobService == null) {
            if (!config.stopOnTerminate) {
                Log.w(BackgroundFetch.TAG, "- Configuration error:  In order to use stopOnTerminate: false, you must set enableHeadless: true");
                config.setStopOnTerminate(true);
            }
            if (config.startOnBoot) {
                Log.w(BackgroundFetch.TAG, "- Configuration error:  In order to use startOnBoot: true, you must enableHeadless: true");
                config.setStartOnBoot(false);
            }
        }
    }

    void save(Context context) {
        SharedPreferences preferences = context.getSharedPreferences(BackgroundFetch.TAG, 0);
        Set<String> taskIds = preferences.getStringSet("tasks", new HashSet<String>());
        if (taskIds == null) {
            taskIds = new HashSet<>();
        }
        if (!taskIds.contains(config.taskId)) {
            Set<String> newIds = new HashSet<>(taskIds);
            newIds.add(config.taskId);

            SharedPreferences.Editor editor = preferences.edit();
            editor.putStringSet("tasks", newIds);
            editor.apply();
        }

        SharedPreferences.Editor editor = context.getSharedPreferences(BackgroundFetch.TAG + ":" + config.taskId, 0).edit();

        editor.putString(FIELD_TASK_ID, config.taskId);
        editor.putBoolean(FIELD_IS_FETCH_TASK, config.isFetchTask);
        editor.putInt(FIELD_MINIMUM_FETCH_INTERVAL, config.minimumFetchInterval);
        editor.putBoolean(FIELD_STOP_ON_TERMINATE, config.stopOnTerminate);
        editor.putBoolean(FIELD_START_ON_BOOT, config.startOnBoot);
        editor.putInt(FIELD_REQUIRED_NETWORK_TYPE, config.requiredNetworkType);
        editor.putBoolean(FIELD_REQUIRES_BATTERY_NOT_LOW, config.requiresBatteryNotLow);
        editor.putBoolean(FIELD_REQUIRES_CHARGING, config.requiresCharging);
        editor.putBoolean(FIELD_REQUIRES_DEVICE_IDLE, config.requiresDeviceIdle);
        editor.putBoolean(FIELD_REQUIRES_STORAGE_NOT_LOW, config.requiresStorageNotLow);
        editor.putString(FIELD_JOB_SERVICE, config.jobService);
        editor.putBoolean(FIELD_FORCE_ALARM_MANAGER, config.forceAlarmManager);
        editor.putBoolean(FIELD_PERIODIC, config.periodic);
        editor.putLong(FIELD_DELAY, config.delay);

        editor.apply();
    }

    void destroy(Context context) {
        SharedPreferences preferences = context.getSharedPreferences(BackgroundFetch.TAG, 0);
        Set<String> taskIds = preferences.getStringSet("tasks", new HashSet<String>());
        if (taskIds == null) {
            taskIds = new HashSet<>();
        }
        if (taskIds.contains(config.taskId)) {
            Set<String> newIds = new HashSet<>(taskIds);
            newIds.remove(config.taskId);
            SharedPreferences.Editor editor = preferences.edit();
            editor.putStringSet("tasks", newIds);
            editor.apply();
        }
        if (!config.isFetchTask) {
            SharedPreferences.Editor editor = context.getSharedPreferences(BackgroundFetch.TAG + ":" + config.taskId, 0).edit();
            editor.clear();
            editor.apply();
        }
    }

    static int FETCH_JOB_ID = 999;

    boolean isFetchTask() {
        return config.isFetchTask;
    }

    public String getTaskId() { return config.taskId; }
    public int getMinimumFetchInterval() {
        return config.minimumFetchInterval;
    }

    public int getRequiredNetworkType() { return config.requiredNetworkType; }
    public boolean getRequiresBatteryNotLow() { return config.requiresBatteryNotLow; }
    public boolean getRequiresCharging() { return config.requiresCharging; }
    public boolean getRequiresDeviceIdle() { return config.requiresDeviceIdle; }
    public boolean getRequiresStorageNotLow() { return config.requiresStorageNotLow; }
    public boolean getStopOnTerminate() {
        return config.stopOnTerminate;
    }
    public boolean getStartOnBoot() {
        return config.startOnBoot;
    }

    public String getJobService() { return config.jobService; }

    public boolean getForceAlarmManager() {
        return config.forceAlarmManager;
    }

    public boolean getPeriodic() {
        return config.periodic || isFetchTask();
    }

    public long getDelay() {
        return config.delay;
    }

    int getJobId() {
        if (config.forceAlarmManager) {
            return 0;
        } else {
            return (isFetchTask()) ? FETCH_JOB_ID : config.taskId.hashCode();
        }
    }

    public String toString() {
        JSONObject output = new JSONObject();
        try {
            output.put(FIELD_TASK_ID, config.taskId);
            output.put(FIELD_IS_FETCH_TASK, config.isFetchTask);
            output.put(FIELD_MINIMUM_FETCH_INTERVAL, config.minimumFetchInterval);
            output.put(FIELD_STOP_ON_TERMINATE, config.stopOnTerminate);
            output.put(FIELD_REQUIRED_NETWORK_TYPE, config.requiredNetworkType);
            output.put(FIELD_REQUIRES_BATTERY_NOT_LOW, config.requiresBatteryNotLow);
            output.put(FIELD_REQUIRES_CHARGING, config.requiresCharging);
            output.put(FIELD_REQUIRES_DEVICE_IDLE, config.requiresDeviceIdle);
            output.put(FIELD_REQUIRES_STORAGE_NOT_LOW, config.requiresStorageNotLow);
            output.put(FIELD_START_ON_BOOT, config.startOnBoot);
            output.put(FIELD_JOB_SERVICE, config.jobService);
            output.put(FIELD_FORCE_ALARM_MANAGER, config.forceAlarmManager);
            output.put(FIELD_PERIODIC, getPeriodic());
            output.put(FIELD_DELAY, config.delay);

            return output.toString(2);
        } catch (JSONException e) {
            e.printStackTrace();
            return output.toString();
        }
    }

    static void load(final Context context, final OnLoadCallback callback) {
        BackgroundFetch.getThreadPool().execute(new Runnable() {
            @Override
            public void run() {
                final List<BackgroundFetchConfig> result = new ArrayList<>();

                SharedPreferences preferences = context.getSharedPreferences(BackgroundFetch.TAG, 0);
                Set<String> taskIds = preferences.getStringSet("tasks", new HashSet<String>());

                if (taskIds != null) {
                    for (String taskId : taskIds) {
                        result.add(new BackgroundFetchConfig.Builder().load(context, taskId));
                    }
                }
                BackgroundFetch.getUiHandler().post(new Runnable() {
                    @Override public void run() {
                        callback.onLoad(result);
                    }
                });
            }
        });
    }

    interface OnLoadCallback {
        void onLoad(List<BackgroundFetchConfig>config);
    }
}
