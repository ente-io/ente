package top.kikt.imagescanner.thumb;

import android.graphics.drawable.Drawable;

import com.bumptech.glide.request.Request;
import com.bumptech.glide.request.target.SizeReadyCallback;
import com.bumptech.glide.request.target.Target;
import com.bumptech.glide.util.Util;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

/**
 * Created by debuggerx on 18-9-27 下午1:40
 */
public abstract class CustomTarget<T> implements Target<T> {
    private final int width;
    private final int height;
    @Nullable
    private Request request;

    /**
     * Creates a new {@link CustomTarget} that will attempt to load the resource in its original size.
     *
     * <p>This constructor can cause very memory inefficient loads if the resource is large and can
     * cause OOMs. It's provided as a convenience for when you'd like to specify dimensions with
     * {@link com.bumptech.glide.request.RequestOptions#override(int)}. In all other cases, prefer
     * {@link #CustomTarget(int, int)}.
     */
    public CustomTarget() {
        this(Target.SIZE_ORIGINAL, Target.SIZE_ORIGINAL);
    }

    /**
     * Creates a new {@code CustomTarget} that will return the given {@code width} and {@link @code}
     * as the requested size (unless overridden by
     * {@link com.bumptech.glide.request.RequestOptions#override(int)} in the request).
     *
     * @param width  The requested width (>= 0, or == Target.SIZE_ORIGINAL).
     * @param height The requested height (>= 0, or == Target.SIZE_ORIGINAL).
     */
    CustomTarget(int width, int height) {
        if (!Util.isValidDimensions(width, height)) {
            throw new IllegalArgumentException(
                    "Width and height must both be > 0 or Target#SIZE_ORIGINAL, but given" + " width: "
                            + width + " and height: " + height);
        }
        this.width = width;
        this.height = height;
    }

    @Override
    public void onStart() {
        // Intentionally empty, this can be optionally implemented by subclasses.
    }

    @Override
    public void onStop() {
        // Intentionally empty, this can be optionally implemented by subclasses.
    }

    @Override
    public void onDestroy() {
        // Intentionally empty, this can be optionally implemented by subclasses.
    }

    @Override
    public void onLoadStarted(@Nullable Drawable placeholder) {
        // Intentionally empty, this can be optionally implemented by subclasses.
    }

    @Override
    public void onLoadFailed(@Nullable Drawable errorDrawable) {
        // Intentionally empty, this can be optionally implemented by subclasses.
    }

    @Override
    public final void getSize(@NonNull SizeReadyCallback cb) {
        cb.onSizeReady(width, height);
    }

    @Override
    public final void removeCallback(@NonNull SizeReadyCallback cb) {
        // Do nothing, this class does not retain SizeReadyCallbacks.
    }

    @Override
    public final void setRequest(@Nullable Request request) {
        this.request = request;
    }

    @Nullable
    @Override
    public final Request getRequest() {
        return request;
    }
}