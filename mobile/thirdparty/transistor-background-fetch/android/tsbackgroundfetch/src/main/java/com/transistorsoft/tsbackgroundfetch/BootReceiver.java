package com.transistorsoft.tsbackgroundfetch;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

/**
 * Created by chris on 2018-01-15.
 */

public class BootReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(final Context context, Intent intent) {
        String action = intent.getAction();
        Log.d(BackgroundFetch.TAG,  "BootReceiver: " + action);
        BackgroundFetch.getThreadPool().execute(new Runnable() {
            @Override public void run() {
                BackgroundFetch.getInstance(context.getApplicationContext()).onBoot();
            }
        });
    }
}
