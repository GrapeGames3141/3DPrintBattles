package com.tak.printforge.legends.admob;

import android.app.Activity;
import android.os.Build;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowInsets;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;

import com.google.android.gms.ads.AdListener;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MobileAds;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Android v2 native-bottom banner host for the explicit Android review feature.
 * The banner is never attached during loading. Once a current callback loads, this
 * class alone attaches it as a content sibling and moves only the Godot surface.
 */
public final class PrintForgeAdMobBannerPlugin extends GodotPlugin {
    public static final String REVIEW_APP_ID = "ca-app-pub-3940256099942544~3347511713";
    public static final String REVIEW_BANNER_UNIT_ID = "ca-app-pub-3940256099942544/9214589741";
    private static final AtomicBoolean SDK_INITIALIZED = new AtomicBoolean(false);

    private final AtomicLong generation = new AtomicLong(0L);
    private AdView bannerView;
    private AdView pendingBanner;
    private ViewGroup contentRoot;
    private View godotSurface;
    private Margins originalSurfaceMargins;
    private boolean surfaceAdjusted = false;
    private int visibleCreativeHeight = 0;

    private static final class Margins {
        final int left;
        final int top;
        final int right;
        final int bottom;

        Margins(ViewGroup.MarginLayoutParams params) {
            left = params.leftMargin;
            top = params.topMargin;
            right = params.rightMargin;
            bottom = params.bottomMargin;
        }
    }

    public PrintForgeAdMobBannerPlugin(Godot godot) {
        super(godot);
    }

    @NonNull
    @Override
    public String getPluginName() {
        return "PrintForgeAdMobBanner";
    }

    @NonNull
    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new HashSet<>();
        // Diagnostic only. Godot never consumes this as a content reserve.
        signals.add(new SignalInfo("native_banner_height_changed", Integer.class));
        return Collections.unmodifiableSet(signals);
    }

    @UsedByGodot
    public void startReviewBanner(String requestedUnitId) {
        final long token = generation.incrementAndGet();
        runOnUiThread(() -> beginLoading(token, requestedUnitId));
    }

    @UsedByGodot
    public void hideReviewBanner() {
        final long token = generation.incrementAndGet();
        runOnUiThread(() -> collapse(token, true));
    }

    @UsedByGodot
    public int getNativeBannerHeightForDiagnostics() {
        return visibleCreativeHeight;
    }

    private void beginLoading(long token, String requestedUnitId) {
        if (token != generation.get()) return;
        // Superseding a visible ad restores the exact recorded surface before loading.
        removeBannerAndRestore(true);
        final Activity activity = getActivity();
        if (activity == null || activity.isFinishing() || !REVIEW_BANNER_UNIT_ID.equals(requestedUnitId)) {
            collapse(token, true);
            return;
        }
        if (SDK_INITIALIZED.compareAndSet(false, true)) {
            MobileAds.initialize(activity, status -> { });
        }
        final AdView requested = new AdView(activity);
        pendingBanner = requested;
        requested.setAdUnitId(REVIEW_BANNER_UNIT_ID);
        final int widthDp = Math.max(1, Math.round(
                activity.getResources().getDisplayMetrics().widthPixels /
                        activity.getResources().getDisplayMetrics().density));
        requested.setAdSize(AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(activity, widthDp));
        requested.setAdListener(new AdListener() {
            @Override
            public void onAdLoaded() {
                runOnUiThread(() -> attachLoadedBanner(token, requested));
            }

            @Override
            public void onAdFailedToLoad(@NonNull LoadAdError error) {
                runOnUiThread(() -> {
                    if (token == generation.get()) collapse(token, true);
                    else requested.destroy();
                });
            }
        });
        // No native attachment or surface mutation occurs before this async callback.
        requested.loadAd(new AdRequest.Builder().build());
    }

    private void attachLoadedBanner(long token, AdView loadedBanner) {
        if (token != generation.get() || loadedBanner == null || loadedBanner != pendingBanner || getActivity() == null) {
            if (loadedBanner != null) loadedBanner.destroy();
            return;
        }
        final ViewGroup root = getActivity().findViewById(android.R.id.content);
        final View surface = findGodotSurface(root, loadedBanner);
        if (root == null || surface == null || !(surface.getLayoutParams() instanceof ViewGroup.MarginLayoutParams)) {
            loadedBanner.destroy();
            collapse(token, true);
            return;
        }
        // One current-generation UI transaction: retain exact margins, attach the
        // sibling below the Godot surface, then add measured creative + system inset.
        contentRoot = root;
        godotSurface = surface;
        originalSurfaceMargins = new Margins((ViewGroup.MarginLayoutParams) surface.getLayoutParams());
        final int creativeHeight = measuredCreativeHeight(loadedBanner);
        if (creativeHeight <= 0) {
            collapse(token, true);
            return;
        }
        final int systemBottomInset = nativeBottomInset(root);
        FrameLayout.LayoutParams bannerLayout = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL);
        bannerLayout.bottomMargin = systemBottomInset;
        root.addView(loadedBanner, bannerLayout);
        ViewGroup.MarginLayoutParams surfaceLayout = (ViewGroup.MarginLayoutParams) surface.getLayoutParams();
        surfaceLayout.leftMargin = originalSurfaceMargins.left;
        surfaceLayout.topMargin = originalSurfaceMargins.top;
        surfaceLayout.rightMargin = originalSurfaceMargins.right;
        surfaceLayout.bottomMargin = originalSurfaceMargins.bottom + creativeHeight + systemBottomInset;
        surface.setLayoutParams(surfaceLayout);
        bannerView = loadedBanner;
        pendingBanner = null;
        surfaceAdjusted = true;
        visibleCreativeHeight = creativeHeight;
        emitSignal("native_banner_height_changed", visibleCreativeHeight);
    }

    private void collapse(long token, boolean publishDiagnostic) {
        if (token != generation.get()) return;
        removeBannerAndRestore(publishDiagnostic);
    }

    private void removeBannerAndRestore(boolean publishDiagnostic) {
        if (pendingBanner != null && pendingBanner != bannerView) {
            pendingBanner.destroy();
        }
        pendingBanner = null;
        if (bannerView != null) {
            ViewGroup parent = bannerView.getParent() instanceof ViewGroup ? (ViewGroup) bannerView.getParent() : null;
            if (parent != null) parent.removeView(bannerView);
            bannerView.destroy();
            bannerView = null;
        }
        if (surfaceAdjusted && godotSurface != null && originalSurfaceMargins != null
                && godotSurface.getLayoutParams() instanceof ViewGroup.MarginLayoutParams) {
            ViewGroup.MarginLayoutParams surfaceLayout = (ViewGroup.MarginLayoutParams) godotSurface.getLayoutParams();
            surfaceLayout.leftMargin = originalSurfaceMargins.left;
            surfaceLayout.topMargin = originalSurfaceMargins.top;
            surfaceLayout.rightMargin = originalSurfaceMargins.right;
            surfaceLayout.bottomMargin = originalSurfaceMargins.bottom;
            godotSurface.setLayoutParams(surfaceLayout);
        }
        contentRoot = null;
        godotSurface = null;
        originalSurfaceMargins = null;
        surfaceAdjusted = false;
        visibleCreativeHeight = 0;
        if (publishDiagnostic) emitSignal("native_banner_height_changed", 0);
    }

    private int measuredCreativeHeight(AdView view) {
        final int measured = Math.max(view.getHeight(), view.getMeasuredHeight());
        if (measured > 0) return measured;
        final Activity activity = getActivity();
        return activity == null ? 0 : Math.max(0, view.getAdSize().getHeightInPixels(activity));
    }

    private int nativeBottomInset(View root) {
        final WindowInsets insets = root.getRootWindowInsets();
        if (insets == null) return 0;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            return insets.getInsets(WindowInsets.Type.systemBars()).bottom;
        }
        return insets.getSystemWindowInsetBottom();
    }

    private View findGodotSurface(ViewGroup root, View excluded) {
        for (int index = 0; index < root.getChildCount(); index++) {
            View child = root.getChildAt(index);
            if (child != excluded && child != bannerView) return child;
        }
        return null;
    }

    @Override
    public void onMainPause() {
        if (bannerView != null) bannerView.pause();
    }

    @Override
    public void onMainResume() {
        if (bannerView != null) bannerView.resume();
    }

    @Override
    public void onMainDestroy() {
        final long token = generation.incrementAndGet();
        runOnUiThread(() -> collapse(token, true));
    }
}
