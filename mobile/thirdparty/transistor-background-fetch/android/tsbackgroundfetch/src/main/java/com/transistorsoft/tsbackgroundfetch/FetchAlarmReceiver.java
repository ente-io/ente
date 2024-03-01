package com.transistorsoft.tsbackgroundfetch;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.PowerManager;
import android.util.Log;

import static android.content.Context.POWER_SERVICE;

/**
 * Created by chris on 2018-01-11.
 */

public class FetchAlarmReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(final Context context, Intent intent) {
        PowerManager powerManager = (PowerManager) context.getSystemService(POWER_SERVICE);
        final PowerManager.WakeLock wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, BackgroundFetch.TAG + "::" + intent.getAction());
        // WakeLock expires in MAX_TIME + 4s buffer.
        wakeLock.acquire((BGTask.MAX_TIME + 4000));

        final String taskId = intent.getAction();

        final FetchJobService.CompletionHandler completionHandler = new FetchJobService.CompletionHandler() {
            @Override
            public void finish() {
                if (wakeLock.isHeld()) {
                    wakeLock.release();
                    Log.d(BackgroundFetch.TAG, "- FetchAlarmReceiver finish");
                }
            }
        };

        BGTask task = new BGTask(context, taskId, completionHandler, 0);

        BackgroundFetch.getInstance(context.getApplicationContext()).onFetch(task);
    }
}
