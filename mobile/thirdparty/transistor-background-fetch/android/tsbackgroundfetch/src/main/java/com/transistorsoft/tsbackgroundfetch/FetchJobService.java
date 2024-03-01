package com.transistorsoft.tsbackgroundfetch;

import android.annotation.TargetApi;
import android.app.job.JobParameters;
import android.app.job.JobService;
import android.os.PersistableBundle;
import android.util.Log;

/**
 * Created by chris on 2018-01-11.
 */
@TargetApi(21)
public class FetchJobService extends JobService {
    @Override
    public boolean onStartJob(final JobParameters params) {
        PersistableBundle extras = params.getExtras();
        final String taskId = extras.getString(BackgroundFetchConfig.FIELD_TASK_ID);

        CompletionHandler completionHandler = new CompletionHandler() {
            @Override
            public void finish() {
                Log.d(BackgroundFetch.TAG, "- jobFinished");
                jobFinished(params, false);
            }
        };
        BGTask task = new BGTask(this, taskId, completionHandler, params.getJobId());
        BackgroundFetch.getInstance(getApplicationContext()).onFetch(task);

        return true;
    }

    @Override
    public boolean onStopJob(final JobParameters params) {
        Log.d(BackgroundFetch.TAG, "- onStopJob");

        PersistableBundle extras = params.getExtras();
        final String taskId = extras.getString(BackgroundFetchConfig.FIELD_TASK_ID);

        BGTask task = BGTask.getTask(taskId);
        if (task != null) {
            task.onTimeout(getApplicationContext());
        }
        jobFinished(params, false);
        return true;
    }

    public interface CompletionHandler {
        void finish();
    }
}
