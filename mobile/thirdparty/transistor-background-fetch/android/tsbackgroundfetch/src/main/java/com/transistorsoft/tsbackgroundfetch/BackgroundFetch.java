package com.transistorsoft.tsbackgroundfetch;

import android.annotation.TargetApi;
import android.app.ActivityManager;

import android.content.Context;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;

import android.util.Log;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Created by chris on 2018-01-11.
 */

public class BackgroundFetch {
    public static final String TAG = "TSBackgroundFetch";

    public static final String ACTION_CONFIGURE = "configure";
    public static final String ACTION_START     = "start";
    public static final String ACTION_STOP      = "stop";
    public static final String ACTION_FINISH    = "finish";
    public static final String ACTION_STATUS    = "status";
    public static final String ACTION_FORCE_RELOAD = TAG + "-forceReload";

    public static final String EVENT_FETCH      = ".event.BACKGROUND_FETCH";

    public static final int STATUS_AVAILABLE = 2;

    private static BackgroundFetch mInstance = null;

    private static ExecutorService sThreadPool;

    private static Handler uiHandler;

    @SuppressWarnings({"WeakerAccess"})
    public static Handler getUiHandler() {
        if (uiHandler == null) {
            uiHandler = new Handler(Looper.getMainLooper());
        }
        return uiHandler;
    }

    @SuppressWarnings({"WeakerAccess"})
    public static ExecutorService getThreadPool() {
        if (sThreadPool == null) {
            sThreadPool = Executors.newCachedThreadPool();
        }
        return sThreadPool;
    }

    @SuppressWarnings({"WeakerAccess"})
    public static BackgroundFetch getInstance(Context context) {
        if (mInstance == null) {
            mInstance = getInstanceSynchronized(context.getApplicationContext());
        }
        return mInstance;
    }

    private static synchronized BackgroundFetch getInstanceSynchronized(Context context) {
        if (mInstance == null) mInstance = new BackgroundFetch(context.getApplicationContext());
        return mInstance;
    }

    private Context mContext;
    private BackgroundFetch.Callback mFetchCallback;

    private final Map<String, BackgroundFetchConfig> mConfig = new HashMap<>();

    private BackgroundFetch(Context context) {
        mContext = context;
    }

    @SuppressWarnings({"unused"})
    public void configure(BackgroundFetchConfig config, BackgroundFetch.Callback callback) {
        Log.d(TAG, "- " + ACTION_CONFIGURE);
        mFetchCallback = callback;

        synchronized (mConfig) {
            mConfig.put(config.getTaskId(), config);
        }
        start(config.getTaskId());
    }

    void onBoot() {
        BackgroundFetchConfig.load(mContext, new BackgroundFetchConfig.OnLoadCallback() {
            @Override public void onLoad(List<BackgroundFetchConfig> result) {
                for (BackgroundFetchConfig config : result) {
                    if (!config.getStartOnBoot() || config.getStopOnTerminate()) {
                        config.destroy(mContext);
                        continue;
                    }
                    synchronized (mConfig) {
                        mConfig.put(config.getTaskId(), config);
                    }
                    if ((android.os.Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP_MR1) || config.getForceAlarmManager()) {
                        if (config.isFetchTask()) {
                            start(config.getTaskId());
                        } else {
                            scheduleTask(config);
                        }
                    }
                }
            }
        });
    }

    @SuppressWarnings({"WeakerAccess"})
    @TargetApi(21)
    public void start(String fetchTaskId) {
        Log.d(TAG, "- " + ACTION_START);

        BGTask task = BGTask.getTask(fetchTaskId);
        if (task != null) {
            Log.e(TAG, "[" + TAG + " start] Task " + fetchTaskId + " already registered");
            return;
        }
        registerTask(fetchTaskId);
    }

    @SuppressWarnings({"WeakerAccess"})
    public void stop(String taskId) {
        String msg = "- " + ACTION_STOP;
        if (taskId != null) {
            msg += ": " + taskId;
        }
        Log.d(TAG, msg);

        if (taskId == null) {
            synchronized (mConfig) {
                for (BackgroundFetchConfig config : mConfig.values()) {
                    BGTask task = BGTask.getTask(config.getTaskId());
                    if (task != null) {
                        task.finish();
                        BGTask.removeTask(config.getTaskId());
                    }
                    BGTask.cancel(mContext, config.getTaskId(), config.getJobId());
                    config.destroy(mContext);
                }
                BGTask.clear();
            }
        } else {
            BGTask task = BGTask.getTask(taskId);
            if (task != null) {
                task.finish();
                BGTask.removeTask(task.getTaskId());
            }
            BackgroundFetchConfig config = getConfig(taskId);
            if (config != null) {
                config.destroy(mContext);
                BGTask.cancel(mContext, config.getTaskId(), config.getJobId());
            }
        }
    }

    @SuppressWarnings({"WeakerAccess"})
    public void scheduleTask(BackgroundFetchConfig config) {
        synchronized (mConfig) {
            if (mConfig.containsKey(config.getTaskId())) {
                // This BackgroundFetchConfig already exists?  Should we halt any existing Job/Alarm here?
            }
            config.save(mContext);
            mConfig.put(config.getTaskId(), config);
        }
        String taskId = config.getTaskId();
        registerTask(taskId);
    }

    @SuppressWarnings({"WeakerAccess"})
    public void finish(String taskId) {
        Log.d(TAG, "- " + ACTION_FINISH + ": " + taskId);

        BGTask task = BGTask.getTask(taskId);
        if (task != null) {
            task.finish();
        }

        BackgroundFetchConfig config = getConfig(taskId);

        if ((config != null) && !config.getPeriodic()) {
            config.destroy(mContext);
            synchronized (mConfig) {
                mConfig.remove(taskId);
            }
        }
    }

    public int status() {
        return STATUS_AVAILABLE;
    }

    BackgroundFetch.Callback getFetchCallback() {
        return mFetchCallback;
    }

    void onFetch(final BGTask task) {
        BGTask.addTask(task);
        Log.d(TAG, "- Background Fetch event received: " + task.getTaskId());
        synchronized (mConfig) {
            if (mConfig.isEmpty()) {
                BackgroundFetchConfig.load(mContext, new BackgroundFetchConfig.OnLoadCallback() {
                    @Override
                    public void onLoad(List<BackgroundFetchConfig> result) {
                        synchronized (mConfig) {
                            for (BackgroundFetchConfig config : result) {
                                mConfig.put(config.getTaskId(), config);
                            }
                        }
                        doFetch(task);
                    }
                });

                return;
            }
        }
        doFetch(task);
    }

    private void registerTask(String taskId) {
        Log.d(TAG, "- registerTask: " + taskId);

        BackgroundFetchConfig config = getConfig(taskId);

        if (config == null) {
            Log.e(TAG, "- registerTask failed to find BackgroundFetchConfig for taskId " + taskId);
            return;
        }
        config.save(mContext);

        BGTask.schedule(mContext, config);
    }

    private void doFetch(BGTask task) {
        BackgroundFetchConfig config = getConfig(task.getTaskId());

        if (config == null) {
            BGTask.cancel(mContext, task.getTaskId(), task.getJobId());
            return;
        }

        if (isMainActivityActive()) {
            if (mFetchCallback != null) {
                mFetchCallback.onFetch(task.getTaskId());
            }
        } else if (config.getStopOnTerminate()) {
            Log.d(TAG, "- Stopping on terminate");
            stop(task.getTaskId());
        } else if (config.getJobService() != null) {
            try {
                task.fireHeadlessEvent(mContext, config);
            } catch (BGTask.Error e) {
                Log.e(TAG, "Headless task error: " + e.getMessage());
                e.printStackTrace();
            }
        } else {
            // {stopOnTerminate: false, forceReload: false} with no Headless JobService??  Don't know what else to do here but stop
            Log.w(TAG, "- BackgroundFetch event has occurred while app is terminated but there's no jobService configured to handle the event.  BackgroundFetch will terminate.");
            finish(task.getTaskId());
            stop(task.getTaskId());
        }
    }

    @SuppressWarnings({"WeakerAccess", "deprecation"})
    public Boolean isMainActivityActive() {
        Boolean isActive = false;

        if (mContext == null || mFetchCallback == null) {
            return false;
        }
        ActivityManager activityManager = (ActivityManager) mContext.getSystemService(Context.ACTIVITY_SERVICE);
        try {
            List<ActivityManager.RunningTaskInfo> tasks = activityManager.getRunningTasks(Integer.MAX_VALUE);
            for (ActivityManager.RunningTaskInfo task : tasks) {
                if (mContext.getPackageName().equalsIgnoreCase(task.baseActivity.getPackageName())) {
                    isActive = true;
                    break;
                }
            }
        } catch (java.lang.SecurityException e) {
            Log.w(TAG, "TSBackgroundFetch attempted to determine if MainActivity is active but was stopped due to a missing permission.  Please add the permission 'android.permission.GET_TASKS' to your AndroidManifest.  See Installation steps for more information");
            throw e;
        }
        return isActive;
    }

    BackgroundFetchConfig getConfig(String taskId) {
        synchronized (mConfig) {
            return (mConfig.containsKey(taskId)) ? mConfig.get(taskId) : null;
        }
    }

    /**
     * @interface BackgroundFetch.Callback
     */
    public interface Callback {
        void onFetch(String taskId);
        void onTimeout(String taskId);
    }
}
