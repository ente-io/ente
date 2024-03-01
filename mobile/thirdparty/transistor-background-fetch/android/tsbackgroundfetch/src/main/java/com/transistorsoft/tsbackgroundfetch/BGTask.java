package com.transistorsoft.tsbackgroundfetch;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.app.job.JobInfo;
import android.app.job.JobScheduler;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.PersistableBundle;
import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

public class BGTask {
    static int MAX_TIME = 60000;

    private static final List<BGTask> mTasks = new ArrayList<>();

    static BGTask getTask(String taskId) {
        synchronized (mTasks) {
            for (BGTask task : mTasks) {
                if (task.hasTaskId(taskId)) return task;
            }
        }
        return null;
    }

    static void addTask(BGTask task) {
        synchronized (mTasks) {
            mTasks.add(task);
        }
    }

    static void removeTask(String taskId) {
        synchronized (mTasks) {
            BGTask found = null;
            for (BGTask task : mTasks) {
                if (task.hasTaskId(taskId)) {
                    found = task;
                    break;
                }
            }
            if (found != null) {
                mTasks.remove(found);
            }
        }
    }

    static void clear() {
        synchronized (mTasks) {
            mTasks.clear();
        }
    }

    private FetchJobService.CompletionHandler mCompletionHandler;
    private String mTaskId;
    private int mJobId;
    private Runnable mTimeoutTask;
    private boolean mTimedout = false;

    BGTask(final Context context, String taskId, FetchJobService.CompletionHandler handler, int jobId) {
        mTaskId = taskId;
        mCompletionHandler = handler;
        mJobId = jobId;

        mTimeoutTask = new Runnable() {
            @Override public void run() {
                onTimeout(context);
            }
        };
        BackgroundFetch.getUiHandler().postDelayed(mTimeoutTask, MAX_TIME);
    }

    public boolean getTimedOut() {
        return mTimedout;
    }

    public String getTaskId() { return mTaskId; }

    int getJobId() { return mJobId; }

    boolean hasTaskId(String taskId) {
        return ((mTaskId != null) && mTaskId.equalsIgnoreCase(taskId));
    }

    void setCompletionHandler(FetchJobService.CompletionHandler handler) {
        mCompletionHandler = handler;
    }

    void finish() {
        if (mCompletionHandler != null) {
            mCompletionHandler.finish();
        }
        if (mTimeoutTask != null) {
            BackgroundFetch.getUiHandler().removeCallbacks(mTimeoutTask);
        }
        mCompletionHandler = null;
        removeTask(mTaskId);
    }

    static void schedule(Context context, BackgroundFetchConfig config) {
        Log.d(BackgroundFetch.TAG, config.toString());

        long interval = (config.isFetchTask()) ? (TimeUnit.MINUTES.toMillis(config.getMinimumFetchInterval())) : config.getDelay();

        if (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && !config.getForceAlarmManager()) {
            // API 21+ uses new JobScheduler API

            JobScheduler jobScheduler = (JobScheduler) context.getSystemService(Context.JOB_SCHEDULER_SERVICE);
            JobInfo.Builder builder = new JobInfo.Builder(config.getJobId(), new ComponentName(context, FetchJobService.class))
                    .setRequiredNetworkType(config.getRequiredNetworkType())
                    .setRequiresDeviceIdle(config.getRequiresDeviceIdle())
                    .setRequiresCharging(config.getRequiresCharging())
                    .setPersisted(config.getStartOnBoot() && !config.getStopOnTerminate());

            if (config.getPeriodic()) {
                if (android.os.Build.VERSION.SDK_INT >= 24) {
                    builder.setPeriodic(interval, interval);
                } else {
                    builder.setPeriodic(interval);
                }
            } else {
                builder.setMinimumLatency(interval);
            }
            PersistableBundle extras = new PersistableBundle();
            extras.putString(BackgroundFetchConfig.FIELD_TASK_ID, config.getTaskId());
            builder.setExtras(extras);

            if (android.os.Build.VERSION.SDK_INT >= 26) {
                builder.setRequiresStorageNotLow(config.getRequiresStorageNotLow());
                builder.setRequiresBatteryNotLow(config.getRequiresBatteryNotLow());
            }
            if (jobScheduler != null) {
                jobScheduler.schedule(builder.build());
            }
        } else {
            // Everyone else get AlarmManager
            AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
            if (alarmManager != null) {
                PendingIntent pi = getAlarmPI(context, config.getTaskId());
                long delay = System.currentTimeMillis() + interval;
                if (config.getPeriodic()) {
                    alarmManager.setRepeating(AlarmManager.RTC_WAKEUP, delay, interval, pi);
                } else {
                    if (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, delay, pi);
                    } else if (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                        alarmManager.setExact(AlarmManager.RTC_WAKEUP, delay, pi);
                    } else {
                        alarmManager.set(AlarmManager.RTC_WAKEUP, delay, pi);
                    }
                }
            }
        }
    }

    void onTimeout(Context context) {
        mTimedout = true;
        Log.d(BackgroundFetch.TAG, "[BGTask] timeout: " + mTaskId);

        BackgroundFetch adapter = BackgroundFetch.getInstance(context);

        if (adapter.isMainActivityActive()) {
            BackgroundFetch.Callback callback = adapter.getFetchCallback();
            if (callback != null) {
                callback.onTimeout(mTaskId);
            }
        } else {
            BackgroundFetchConfig config = adapter.getConfig(mTaskId);
            if (config != null) {
                if (config.getJobService() != null) {
                    fireHeadlessEvent(context, config);
                } else {
                    adapter.finish(mTaskId);
                }
            } else {
                Log.e(BackgroundFetch.TAG, "[BGTask] failed to load config for taskId: " + mTaskId);
                adapter.finish(mTaskId);
            }
        }
    }

    // Fire a headless background-fetch event by reflecting an instance of Config.jobServiceClass.
    // Will attempt to reflect upon two different forms of Headless class:
    // 1:  new HeadlessTask(context, taskId)
    //   or
    // 2:  new HeadlessTask().onFetch(context, taskId);
    //
    void fireHeadlessEvent(Context context, BackgroundFetchConfig config) throws Error {
        try {
            // Get class via reflection.
            Class<?> HeadlessClass = Class.forName(config.getJobService());
            Class[] types = { Context.class, BGTask.class };
            Object[] params = { context, this};
            try {
                // 1:  new HeadlessTask(context, taskId);
                Constructor<?> constructor = HeadlessClass.getDeclaredConstructor(types);
                constructor.newInstance(params);
            } catch (NoSuchMethodException e) {
                // 2:  new HeadlessTask().onFetch(context, taskId);
                Constructor<?> constructor = HeadlessClass.getConstructor();
                Object instance = constructor.newInstance();
                Method onFetch = instance.getClass().getDeclaredMethod("onFetch", types);
                onFetch.invoke(instance, params);
            }
        } catch (ClassNotFoundException e) {
            throw new Error(e.getMessage());
        } catch (NoSuchMethodException e) {
            throw new Error(e.getMessage());
        } catch (IllegalAccessException e) {
            throw new Error(e.getMessage());
        } catch (InstantiationException e) {
            throw new Error(e.getMessage());
        } catch (InvocationTargetException e) {
            throw new Error(e.getMessage());
        }
    }

    static void cancel(Context context, String taskId, int jobId) {
        Log.i(BackgroundFetch.TAG, "- cancel taskId=" + taskId + ", jobId=" + jobId);
        if (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && (jobId != 0)) {
            JobScheduler jobScheduler = (JobScheduler) context.getSystemService(Context.JOB_SCHEDULER_SERVICE);
            if (jobScheduler != null) {
                jobScheduler.cancel(jobId);
            }
        } else {
            AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
            if (alarmManager != null) {
                alarmManager.cancel(BGTask.getAlarmPI(context, taskId));
            }
        }
    }

    static PendingIntent getAlarmPI(Context context, String taskId) {
        Intent intent = new Intent(context, FetchAlarmReceiver.class);
        intent.setAction(taskId);
        return PendingIntent.getBroadcast(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT);
    }

    public String toString() {
        return "[BGTask taskId=" + mTaskId + "]";
    }

    public Map<String, Object> toMap() {
        Map<String, Object> map = new HashMap<>();
        map.put("taskId", mTaskId);
        map.put("timeout", mTimedout);
        return map;
    }

    public JSONObject toJson() {
        JSONObject json = new JSONObject();
        try {
            json.put("taskId", mTaskId);
            json.put("timeout", mTimedout);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return json;
    }

    static class Error extends RuntimeException {
        public Error(String msg) {
            super(msg);
        }
    }
}
