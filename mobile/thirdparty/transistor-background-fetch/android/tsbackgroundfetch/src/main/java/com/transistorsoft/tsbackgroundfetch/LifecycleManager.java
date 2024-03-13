package com.transistorsoft.tsbackgroundfetch;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.lifecycle.DefaultLifecycleObserver;
import androidx.lifecycle.LifecycleOwner;
import androidx.lifecycle.ProcessLifecycleOwner;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Component for managing app life-cycle changes, including headless-mode.
 */
public class LifecycleManager implements DefaultLifecycleObserver, Runnable {
    private static LifecycleManager sInstance;

    public static LifecycleManager getInstance() {
        if (sInstance == null) {
            sInstance = getInstanceSynchronized();
        }
        return sInstance;
    }

    private static synchronized LifecycleManager getInstanceSynchronized() {
        if (sInstance == null) sInstance = new LifecycleManager();
        return sInstance;
    }

    private final List<OnHeadlessChangeCallback> mHeadlessChangeCallbacks = new ArrayList<>();
    private final List<OnStateChangeCallback> mStateChangeCallbacks = new ArrayList<>();
    private final Handler mHandler;
    private Runnable mHeadlessChangeEvent;

    private final AtomicBoolean mIsBackground   = new AtomicBoolean(true);
    private final AtomicBoolean mIsHeadless     = new AtomicBoolean(true);
    private final AtomicBoolean mStarted        = new AtomicBoolean(false);
    private final AtomicBoolean mPaused         = new AtomicBoolean(false);

    private LifecycleManager() {
        mHandler    = new Handler(Looper.getMainLooper());
        onHeadlessChange(isHeadless -> {
            if (isHeadless) {
                Log.d(BackgroundFetch.TAG, "☯️  HeadlessMode? " + isHeadless);
            }
        });
    }

    /**
     * Temporarily disable responding to pause/resume events.  This was placed here for handling TSLocationManagerActivity events
     * whose presentation causes onPause / onResume events that we don't want to react to.
     */
    public void pause() {
        mPaused.set(true);
    }

    /**
     * Re-engage responding to pause/resume events.
     */
    public void resume() {
        mPaused.set(false);
    }
    /**
     * Are we in the background?
     * @return boolean
     */
    public boolean isBackground() {
        return mIsBackground.get();
    }
    /**
     * Are we headless
     * @return boolean
     */
    public boolean isHeadless() {
        return mIsHeadless.get();
    }
    /**
     * Explicitly state that we are headless.  Probably called when MainActivity is known to have been destroyed.
     * @param value boolean
     */
    public void setHeadless(boolean value) {
        mIsHeadless.set(value);
        if (mIsHeadless.get()) {
            Log.d(BackgroundFetch.TAG,"☯️  HeadlessMode? " + mIsHeadless);
        }
        if (mHeadlessChangeEvent != null) {
            mHandler.removeCallbacks(mHeadlessChangeEvent);
            mStarted.set(true);
            fireHeadlessChangeListeners();
        }
    }
    /**
     * Register Headless-mode change listener.
     */
    public void onHeadlessChange(OnHeadlessChangeCallback callback) {
        if (mStarted.get()) {
            callback.onChange(mIsHeadless.get());
            return;
        }
        synchronized (mHeadlessChangeCallbacks) {
            mHeadlessChangeCallbacks.add(callback);
        }
    }
    /**
     * Register pause/resume listener.
     */
    public void onStateChange(OnStateChangeCallback callback) {
        synchronized (mStateChangeCallbacks) {
            mStateChangeCallbacks.add(callback);
        }
    }

    /**
     * Regiser the LifecycleObserver
     */
    @Override
    public void run() {
        ProcessLifecycleOwner.get().getLifecycle().addObserver(this);
    }

    @Override
    public void onCreate(@NonNull LifecycleOwner owner) {
        Log.d(BackgroundFetch.TAG,"☯️  onCreate");
        // If this 50ms Timer fires before onStart, we are headless
        mHeadlessChangeEvent = new Runnable() {
            @Override public void run() {
                mStarted.set(true);
                fireHeadlessChangeListeners();
            }
        };

        mHandler.postDelayed(mHeadlessChangeEvent, 50);
        mIsHeadless.set(true);
        mIsBackground.set(true);
    }

    @Override
    public void onStart(@NonNull LifecycleOwner owner) {
        Log.d(BackgroundFetch.TAG, "☯️  onStart");
        // Cancel StateChange Timer.
        if (mPaused.get()) {
            return;
        }
        if (mHeadlessChangeEvent != null) {
            mHandler.removeCallbacks(mHeadlessChangeEvent);
        }

        mStarted.set(true);
        mIsHeadless.set(false);
        mIsBackground.set(false);

        // Fire listeners.
        fireHeadlessChangeListeners();
    }

    @Override
    public void onDestroy(@NonNull LifecycleOwner owner) {
        Log.d(BackgroundFetch.TAG, "☯️  onDestroy");
        mIsBackground.set(true);
        mIsHeadless.set(true);
    }

    @Override
    public void onStop(@NonNull LifecycleOwner owner) {
        Log.d(BackgroundFetch.TAG, "☯️  onStop");
        if (mPaused.compareAndSet(true, false)) {
            return;
        }
        mIsBackground.set(true);

    }

    @Override
    public void onPause(@NonNull LifecycleOwner owner) {
        Log.d(BackgroundFetch.TAG, "☯️  onPause");
        mIsBackground.set(true);
        fireStateChangeListeners(false);
    }

    @Override
    public void onResume(@NonNull LifecycleOwner owner) {
        Log.d(BackgroundFetch.TAG, "☯️  onResume");
        if (mPaused.get()) {
            return;
        }
        mIsBackground.set(false);
        mIsHeadless.set(false);
        fireStateChangeListeners(true);
    }

    /// Fire pause/resume change listeners
    private void fireStateChangeListeners(boolean isForeground) {
        synchronized (mStateChangeCallbacks) {
            for (OnStateChangeCallback callback : mStateChangeCallbacks) {
                callback.onChange(isForeground);
            }
        }
    }

    /// Fire headless mode change listeners.
    private void fireHeadlessChangeListeners() {
        if (mHeadlessChangeEvent != null) {
            mHandler.removeCallbacks(mHeadlessChangeEvent);
            mHeadlessChangeEvent = null;
        }
        synchronized (mHeadlessChangeCallbacks) {
            for (OnHeadlessChangeCallback callback : mHeadlessChangeCallbacks) {
                callback.onChange(mIsHeadless.get());
            }
            mHeadlessChangeCallbacks.clear();
        }
    }

    public interface OnHeadlessChangeCallback {
        void onChange(boolean isHeadless);
    }

    public interface OnStateChangeCallback {
        void onChange(boolean isForeground);
    }
}
