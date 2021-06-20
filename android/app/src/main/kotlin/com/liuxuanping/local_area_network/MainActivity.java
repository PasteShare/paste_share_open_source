package com.liuxuanping.local_area_network;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.annotation.VisibleForTesting;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleOwner;
import androidx.lifecycle.LifecycleRegistry;

import com.liuxuanping.local_area_network.MainActivityLaunchConfigs;

import io.flutter.Log;
import io.flutter.embedding.android.DrawableSplashScreen;
import io.flutter.embedding.android.ExclusiveAppComponent;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterFragment;
import io.flutter.embedding.android.FlutterSurfaceView;
import io.flutter.embedding.android.FlutterTextureView;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.android.RenderMode;
import io.flutter.embedding.android.SplashScreen;
import io.flutter.embedding.android.TransparencyMode;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterShellArgs;
import io.flutter.embedding.engine.plugins.activity.ActivityControlSurface;
import io.flutter.embedding.engine.plugins.util.GeneratedPluginRegister;
import io.flutter.plugin.platform.PlatformPlugin;

import static android.content.Intent.FLAG_ACTIVITY_NEW_TASK;
import static com.liuxuanping.local_area_network.MainActivityLaunchConfigs.DART_ENTRYPOINT_META_DATA_KEY;
import static com.liuxuanping.local_area_network.MainActivityLaunchConfigs.DEFAULT_BACKGROUND_MODE;
import static com.liuxuanping.local_area_network.MainActivityLaunchConfigs.DEFAULT_DART_ENTRYPOINT;
import static com.liuxuanping.local_area_network.MainActivityLaunchConfigs.DEFAULT_INITIAL_ROUTE;
import static com.liuxuanping.local_area_network.MainActivityLaunchConfigs.EXTRA_BACKGROUND_MODE;
import static com.liuxuanping.local_area_network.MainActivityLaunchConfigs.EXTRA_CACHED_ENGINE_ID;
import static com.liuxuanping.local_area_network.MainActivityLaunchConfigs.EXTRA_DESTROY_ENGINE_WITH_ACTIVITY;
import static com.liuxuanping.local_area_network.MainActivityLaunchConfigs.EXTRA_ENABLE_STATE_RESTORATION;
import static com.liuxuanping.local_area_network.MainActivityLaunchConfigs.EXTRA_INITIAL_ROUTE;
import static com.liuxuanping.local_area_network.MainActivityLaunchConfigs.HANDLE_DEEPLINKING_META_DATA_KEY;
import static com.liuxuanping.local_area_network.MainActivityLaunchConfigs.INITIAL_ROUTE_META_DATA_KEY;
import static com.liuxuanping.local_area_network.MainActivityLaunchConfigs.NORMAL_THEME_META_DATA_KEY;
import static com.liuxuanping.local_area_network.MainActivityLaunchConfigs.SPLASH_SCREEN_META_DATA_KEY;

public class MainActivity  extends Activity
        implements MainActivityAndFragmentDelegate.Host, LifecycleOwner {
  private static final String TAG = "FlutterActivity";

  /**
   * Creates an {@link Intent} that launches a {@code FlutterActivity}, which creates a {@link
   * FlutterEngine} that executes a {@code main()} Dart entrypoint, and displays the "/" route as
   * Flutter's initial route.
   *
   * <p>Consider using the {@link #withCachedEngine(String)} {@link Intent} builder to control when
   * the {@link FlutterEngine} should be created in your application.
   */
  @NonNull
  public static Intent createDefaultIntent(@NonNull Context launchContext) {
    return withNewEngine().build(launchContext);
  }

  /**
   * Creates an {@link FlutterActivity.NewEngineIntentBuilder}, which can be used to configure an {@link Intent} to
   * launch a {@code FlutterActivity} that internally creates a new {@link FlutterEngine} using the
   * desired Dart entrypoint, initial route, etc.
   */
  @NonNull
  public static FlutterActivity.NewEngineIntentBuilder withNewEngine() {
    return new FlutterActivity.NewEngineIntentBuilder(FlutterActivity.class);
  }

  /**
   * Builder to create an {@code Intent} that launches a {@code FlutterActivity} with a new {@link
   * FlutterEngine} and the desired configuration.
   */
  public static class NewEngineIntentBuilder {
    private final Class<? extends FlutterActivity> activityClass;
    private String initialRoute = DEFAULT_INITIAL_ROUTE;
    private String backgroundMode = DEFAULT_BACKGROUND_MODE;

    /**
     * Constructor that allows this {@code NewEngineIntentBuilder} to be used by subclasses of
     * {@code FlutterActivity}.
     *
     * <p>Subclasses of {@code FlutterActivity} should provide their own static version of {@link
     * #withNewEngine()}, which returns an instance of {@code NewEngineIntentBuilder} constructed
     * with a {@code Class} reference to the {@code FlutterActivity} subclass, e.g.:
     *
     * <p>{@code return new NewEngineIntentBuilder(MyFlutterActivity.class); }
     */
    public NewEngineIntentBuilder(@NonNull Class<? extends FlutterActivity> activityClass) {
      this.activityClass = activityClass;
    }

    /**
     * The initial route that a Flutter app will render in this {@link FlutterFragment}, defaults to
     * "/".
     */
    @NonNull
    public NewEngineIntentBuilder initialRoute(@NonNull String initialRoute) {
      this.initialRoute = initialRoute;
      return this;
    }

    @NonNull
    public NewEngineIntentBuilder backgroundMode(@NonNull MainActivityLaunchConfigs.BackgroundMode backgroundMode) {
      this.backgroundMode = backgroundMode.name();
      return this;
    }

    /**
     * Creates and returns an {@link Intent} that will launch a {@code FlutterActivity} with the
     * desired configuration.
     */
    @NonNull
    public Intent build(@NonNull Context context) {
      return new Intent(context, activityClass)
              .putExtra(EXTRA_INITIAL_ROUTE, initialRoute)
              .putExtra(EXTRA_BACKGROUND_MODE, backgroundMode)
              .putExtra(EXTRA_DESTROY_ENGINE_WITH_ACTIVITY, true);
    }
  }

  /**
   * Creates a {@link FlutterActivity.CachedEngineIntentBuilder}, which can be used to configure an {@link Intent}
   * to launch a {@code FlutterActivity} that internally uses an existing {@link FlutterEngine} that
   * is cached in {@link io.flutter.embedding.engine.FlutterEngineCache}.
   */
  public static FlutterActivity.CachedEngineIntentBuilder withCachedEngine(@NonNull String cachedEngineId) {
    return new FlutterActivity.CachedEngineIntentBuilder(FlutterActivity.class, cachedEngineId);
  }

  /**
   * Builder to create an {@code Intent} that launches a {@code FlutterActivity} with an existing
   * {@link FlutterEngine} that is cached in {@link io.flutter.embedding.engine.FlutterEngineCache}.
   */
  public static class CachedEngineIntentBuilder {
    private final Class<? extends FlutterActivity> activityClass;
    private final String cachedEngineId;
    private boolean destroyEngineWithActivity = false;
    private String backgroundMode = DEFAULT_BACKGROUND_MODE;

    public CachedEngineIntentBuilder(
            @NonNull Class<? extends FlutterActivity> activityClass, @NonNull String engineId) {
      this.activityClass = activityClass;
      this.cachedEngineId = engineId;
    }

    /**
     * Returns true if the cached {@link FlutterEngine} should be destroyed and removed from the
     * cache when this {@code FlutterActivity} is destroyed.
     *
     * <p>The default value is {@code false}.
     */
    public CachedEngineIntentBuilder destroyEngineWithActivity(boolean destroyEngineWithActivity) {
      this.destroyEngineWithActivity = destroyEngineWithActivity;
      return this;
    }

    @NonNull
    public CachedEngineIntentBuilder backgroundMode(@NonNull MainActivityLaunchConfigs.BackgroundMode backgroundMode) {
      this.backgroundMode = backgroundMode.name();
      return this;
    }

    /**
     * Creates and returns an {@link Intent} that will launch a {@code FlutterActivity} with the
     * desired configuration.
     */
    @NonNull
    public Intent build(@NonNull Context context) {
      return new Intent(context, activityClass)
              .putExtra(EXTRA_CACHED_ENGINE_ID, cachedEngineId)
              .putExtra(EXTRA_DESTROY_ENGINE_WITH_ACTIVITY, destroyEngineWithActivity)
              .putExtra(EXTRA_BACKGROUND_MODE, backgroundMode);
    }
  }

  // Delegate that runs all lifecycle and OS hook logic that is common between
  // FlutterActivity and FlutterFragment. See the MainActivityAndFragmentDelegate
  // implementation for details about why it exists.
  @VisibleForTesting
  protected MainActivityAndFragmentDelegate delegate;

  @NonNull private LifecycleRegistry lifecycle;

  public MainActivity() {
    lifecycle = new LifecycleRegistry(this);
  }

  /**
   * This method exists so that JVM tests can ensure that a delegate exists without putting this
   * Activity through any lifecycle events, because JVM tests cannot handle executing any lifecycle
   * methods, at the time of writing this.
   *
   * <p>The testing infrastructure should be upgraded to make FlutterActivity tests easy to write
   * while exercising real lifecycle methods. At such a time, this method should be removed.
   */
  // TODO(mattcarroll): remove this when tests allow for it
  // (https://github.com/flutter/flutter/issues/43798)
  @VisibleForTesting
  /* package */ void setDelegate(@NonNull MainActivityAndFragmentDelegate delegate) {
    this.delegate = delegate;
  }

  @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP_MR1)
  @Override
  protected void onCreate(@Nullable Bundle savedInstanceState) {
    if (getIntent().getIntExtra("org.chromium.chrome.extra.TASK_ID", -1) == getTaskId()) {
      this.finish();
      getIntent().addFlags(FLAG_ACTIVITY_NEW_TASK);
      this.startActivity(getIntent());
    }
    switchLaunchThemeForNormalTheme();

    super.onCreate(savedInstanceState);

    delegate = new MainActivityAndFragmentDelegate(this);
    delegate.onAttach(this);
    delegate.onRestoreInstanceState(savedInstanceState);

    lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_CREATE);

    configureWindowForTransparency();
    setContentView(createFlutterView());
//    configureStatusBarForFullscreenFlutterExperience();
  }

  /**
   * Switches themes for this {@code Activity} from the theme used to launch this {@code Activity}
   * to a "normal theme" that is intended for regular {@code Activity} operation.
   *
   * <p>This behavior is offered so that a "launch screen" can be displayed while the application
   * initially loads. To utilize this behavior in an app, do the following:
   *
   * <ol>
   *   <li>Create 2 different themes in style.xml: one theme for the launch screen and one theme for
   *       normal display.
   *   <li>In the launch screen theme, set the "windowBackground" property to a {@code Drawable} of
   *       your choice.
   *   <li>In the normal theme, customize however you'd like.
   *   <li>In the AndroidManifest.xml, set the theme of your {@code FlutterActivity} to your launch
   *       theme.
   *   <li>Add a {@code <meta-data>} property to your {@code FlutterActivity} with a name of
   *       "io.flutter.embedding.android.NormalTheme" and set the resource to your normal theme,
   *       e.g., {@code android:resource="@style/MyNormalTheme}.
   * </ol>
   *
   * With the above settings, your launch theme will be used when loading the app, and then the
   * theme will be switched to your normal theme once the app has initialized.
   *
   * <p>Do not change aspects of system chrome between a launch theme and normal theme. Either
   * define both themes to be fullscreen or not, and define both themes to display the same status
   * bar and navigation bar settings. If you wish to adjust system chrome once your Flutter app
   * renders, use platform channels to instruct Android to do so at the appropriate time. This will
   * avoid any jarring visual changes during app startup.
   */
  private void switchLaunchThemeForNormalTheme() {
    try {
      Bundle metaData = getMetaData();
      if (metaData != null) {
        int normalThemeRID = metaData.getInt(NORMAL_THEME_META_DATA_KEY, -1);
        if (normalThemeRID != -1) {
          setTheme(normalThemeRID);
        }
      } else {
        Log.v(TAG, "Using the launch theme as normal theme.");
      }
    } catch (PackageManager.NameNotFoundException exception) {
      Log.e(
              TAG,
              "Could not read meta-data for FlutterActivity. Using the launch theme as normal theme.");
    }
  }

  @Nullable
  @Override
  public SplashScreen provideSplashScreen() {
    Drawable manifestSplashDrawable = getSplashScreenFromManifest();
    if (manifestSplashDrawable != null) {
      return new DrawableSplashScreen(manifestSplashDrawable);
    } else {
      return null;
    }
  }

  @Nullable
  @SuppressWarnings("deprecation")
  private Drawable getSplashScreenFromManifest() {
    try {
      Bundle metaData = getMetaData();
      int splashScreenId = metaData != null ? metaData.getInt(SPLASH_SCREEN_META_DATA_KEY) : 0;
      return splashScreenId != 0
              ? Build.VERSION.SDK_INT > Build.VERSION_CODES.LOLLIPOP
              ? getResources().getDrawable(splashScreenId, getTheme())
              : getResources().getDrawable(splashScreenId)
              : null;
    } catch (PackageManager.NameNotFoundException e) {
      // This is never expected to happen.
      return null;
    }
  }

  private void configureWindowForTransparency() {
    MainActivityLaunchConfigs.BackgroundMode backgroundMode = getBackgroundMode();
    if (backgroundMode == MainActivityLaunchConfigs.BackgroundMode.transparent) {
      getWindow().setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
    }
  }

  @NonNull
  private View createFlutterView() {
    return delegate.onCreateView(
            null /* inflater */, null /* container */, null /* savedInstanceState */);
  }

  private void configureStatusBarForFullscreenFlutterExperience() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      Window window = getWindow();
      window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
      window.setStatusBarColor(0x40000000);
      window.getDecorView().setSystemUiVisibility(PlatformPlugin.DEFAULT_SYSTEM_UI);
    }
  }

  @Override
  protected void onStart() {
    super.onStart();
    lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_START);
    delegate.onStart();
  }

  @Override
  protected void onResume() {
    super.onResume();
    lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_RESUME);
    delegate.onResume();
  }

  @Override
  public void onPostResume() {
    super.onPostResume();
    delegate.onPostResume();
  }

  @Override
  protected void onPause() {
    super.onPause();
    delegate.onPause();
    lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_PAUSE);
  }

  @Override
  protected void onStop() {
    super.onStop();
    if (stillAttachedForEvent("onStop")) {
      delegate.onStop();
    }
    lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_STOP);
  }

  @Override
  protected void onSaveInstanceState(Bundle outState) {
    super.onSaveInstanceState(outState);
    if (stillAttachedForEvent("onSaveInstanceState")) {
      delegate.onSaveInstanceState(outState);
    }
  }

  /**
   * Irreversibly release this activity's control of the {@link FlutterEngine} and its
   * subcomponents.
   *
   * <p>Calling will disconnect this activity's view from the Flutter renderer, disconnect this
   * activity from plugins' {@link ActivityControlSurface}, and stop system channel messages from
   * this activity.
   *
   * <p>After calling, this activity should be disposed immediately and not be re-used.
   */
  private void release() {
    delegate.onDestroyView();
    delegate.onDetach();
    delegate.release();
    delegate = null;
  }

  @Override
  public void detachFromFlutterEngine() {
    Log.v(
            TAG,
            "FlutterActivity "
                    + this
                    + " connection to the engine "
                    + getFlutterEngine()
                    + " evicted by another attaching activity");
    release();
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    if (stillAttachedForEvent("onDestroy")) {
      release();
    }
    lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_DESTROY);
  }

  @Override
  protected void onActivityResult(int requestCode, int resultCode, Intent data) {
    if (stillAttachedForEvent("onActivityResult")) {
      delegate.onActivityResult(requestCode, resultCode, data);
    }
  }

  @Override
  protected void onNewIntent(@NonNull Intent intent) {
    // TODO(mattcarroll): change G3 lint rule that forces us to call super
    super.onNewIntent(intent);
    if (stillAttachedForEvent("onNewIntent")) {
      delegate.onNewIntent(intent);
    }
  }

  @Override
  public void onBackPressed() {
    if (stillAttachedForEvent("onBackPressed")) {
      delegate.onBackPressed();
    }
  }

  @Override
  public void onRequestPermissionsResult(
          int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
    if (stillAttachedForEvent("onRequestPermissionsResult")) {
      delegate.onRequestPermissionsResult(requestCode, permissions, grantResults);
    }
  }

  @Override
  public void onUserLeaveHint() {
    if (stillAttachedForEvent("onUserLeaveHint")) {
      delegate.onUserLeaveHint();
    }
  }

  @Override
  public void onTrimMemory(int level) {
    super.onTrimMemory(level);
    if (stillAttachedForEvent("onTrimMemory")) {
      delegate.onTrimMemory(level);
    }
  }

  /**
   * {@link MainActivityAndFragmentDelegate.Host} method that is used by {@link
   * MainActivityAndFragmentDelegate} to obtain a {@code Context} reference as needed.
   */
  @Override
  @NonNull
  public Context getContext() {
    return this;
  }

  /**
   * {@link MainActivityAndFragmentDelegate.Host} method that is used by {@link
   * MainActivityAndFragmentDelegate} to obtain an {@code Activity} reference as needed. This
   * reference is used by the delegate to instantiate a {@link FlutterView}, a {@link
   * PlatformPlugin}, and to determine if the {@code Activity} is changing configurations.
   */
  @Override
  @NonNull
  public Activity getActivity() {
    return this;
  }

  /**
   * {@link MainActivityAndFragmentDelegate.Host} method that is used by {@link
   * MainActivityAndFragmentDelegate} to obtain a {@code Lifecycle} reference as needed. This
   * reference is used by the delegate to provide Flutter plugins with access to lifecycle events.
   */
  @Override
  @NonNull
  public Lifecycle getLifecycle() {
    return lifecycle;
  }

  /**
   * {@link MainActivityAndFragmentDelegate.Host} method that is used by {@link
   * MainActivityAndFragmentDelegate} to obtain Flutter shell arguments when initializing
   * Flutter.
   */
  @NonNull
  @Override
  public FlutterShellArgs getFlutterShellArgs() {
    return FlutterShellArgs.fromIntent(getIntent());
  }

  /**
   * Returns the ID of a statically cached {@link FlutterEngine} to use within this {@code
   * FlutterActivity}, or {@code null} if this {@code FlutterActivity} does not want to use a cached
   * {@link FlutterEngine}.
   */
  @Override
  @Nullable
  public String getCachedEngineId() {
    return getIntent().getStringExtra(EXTRA_CACHED_ENGINE_ID);
  }

  /**
   * Returns false if the {@link FlutterEngine} backing this {@code FlutterActivity} should outlive
   * this {@code FlutterActivity}, or true to be destroyed when the {@code FlutterActivity} is
   * destroyed.
   *
   * <p>The default value is {@code true} in cases where {@code FlutterActivity} created its own
   * {@link FlutterEngine}, and {@code false} in cases where a cached {@link FlutterEngine} was
   * provided.
   */
  @Override
  public boolean shouldDestroyEngineWithHost() {
    boolean explicitDestructionRequested =
            getIntent().getBooleanExtra(EXTRA_DESTROY_ENGINE_WITH_ACTIVITY, false);
    if (getCachedEngineId() != null || delegate.isFlutterEngineFromHost()) {
      // Only destroy a cached engine if explicitly requested by app developer.
      return explicitDestructionRequested;
    } else {
      // If this Activity created the FlutterEngine, destroy it by default unless
      // explicitly requested not to.
      return getIntent().getBooleanExtra(EXTRA_DESTROY_ENGINE_WITH_ACTIVITY, true);
    }
  }

  @NonNull
  public String getDartEntrypointFunctionName() {
    try {
      Bundle metaData = getMetaData();
      String desiredDartEntrypoint =
              metaData != null ? metaData.getString(DART_ENTRYPOINT_META_DATA_KEY) : null;
      return desiredDartEntrypoint != null ? desiredDartEntrypoint : DEFAULT_DART_ENTRYPOINT;
    } catch (PackageManager.NameNotFoundException e) {
      return DEFAULT_DART_ENTRYPOINT;
    }
  }

  public String getInitialRoute() {
    if (getIntent().hasExtra(EXTRA_INITIAL_ROUTE)) {
      return getIntent().getStringExtra(EXTRA_INITIAL_ROUTE);
    }

    try {
      Bundle metaData = getMetaData();
      String desiredInitialRoute =
              metaData != null ? metaData.getString(INITIAL_ROUTE_META_DATA_KEY) : null;
      return desiredInitialRoute;
    } catch (PackageManager.NameNotFoundException e) {
      return null;
    }
  }

  @NonNull
  public String getAppBundlePath() {
    // If this Activity was launched from tooling, and the incoming Intent contains
    // a custom app bundle path, return that path.
    // TODO(mattcarroll): determine if we should have an explicit FlutterTestActivity instead of
    // conflating.
    if (isDebuggable() && Intent.ACTION_RUN.equals(getIntent().getAction())) {
      String appBundlePath = getIntent().getDataString();
      if (appBundlePath != null) {
        return appBundlePath;
      }
    }

    return null;
  }

  /**
   * Returns true if Flutter is running in "debug mode", and false otherwise.
   *
   * <p>Debug mode allows Flutter to operate with hot reload and hot restart. Release mode does not.
   */
  private boolean isDebuggable() {
    return (getApplicationInfo().flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0;
  }

  /**
   * {@link MainActivityAndFragmentDelegate.Host} method that is used by {@link
   * MainActivityAndFragmentDelegate} to obtain the desired {@link RenderMode} that should be
   * used when instantiating a {@link FlutterView}.
   */
  @NonNull
  @Override
  public RenderMode getRenderMode() {
    return getBackgroundMode() == MainActivityLaunchConfigs.BackgroundMode.opaque ? RenderMode.surface : RenderMode.texture;
  }

  /**
   * {@link MainActivityAndFragmentDelegate.Host} method that is used by {@link
   * MainActivityAndFragmentDelegate} to obtain the desired {@link TransparencyMode} that should
   * be used when instantiating a {@link FlutterView}.
   */
  @NonNull
  @Override
  public TransparencyMode getTransparencyMode() {
    return getBackgroundMode() == MainActivityLaunchConfigs.BackgroundMode.opaque
            ? TransparencyMode.opaque
            : TransparencyMode.transparent;
  }

  @NonNull
  protected MainActivityLaunchConfigs.BackgroundMode getBackgroundMode() {
    if (getIntent().hasExtra(EXTRA_BACKGROUND_MODE)) {
      return MainActivityLaunchConfigs.BackgroundMode.valueOf(getIntent().getStringExtra(EXTRA_BACKGROUND_MODE));
    } else {
      return MainActivityLaunchConfigs.BackgroundMode.opaque;
    }
  }

  /**
   * Hook for subclasses to easily provide a custom {@link FlutterEngine}.
   *
   * <p>This hook is where a cached {@link FlutterEngine} should be provided, if a cached {@link
   * FlutterEngine} is desired.
   */
  @Nullable
  @Override
  public FlutterEngine provideFlutterEngine(@NonNull Context context) {
    // No-op. Hook for subclasses.
    return null;
  }

  /**
   * Hook for subclasses to obtain a reference to the {@link FlutterEngine} that is owned by this
   * {@code FlutterActivity}.
   */
  @Nullable
  protected FlutterEngine getFlutterEngine() {
    return delegate.getFlutterEngine();
  }

  /** Retrieves the meta data specified in the AndroidManifest.xml. */
  @Nullable
  protected Bundle getMetaData() throws PackageManager.NameNotFoundException {
    ActivityInfo activityInfo =
            getPackageManager().getActivityInfo(getComponentName(), PackageManager.GET_META_DATA);
    return activityInfo.metaData;
  }

  @Nullable
  @Override
  public PlatformPlugin providePlatformPlugin(
          @Nullable Activity activity, @NonNull FlutterEngine flutterEngine) {
    return new PlatformPlugin(getActivity(), flutterEngine.getPlatformChannel(), this);
  }

  /**
   * Hook for subclasses to easily configure a {@code FlutterEngine}.
   *
   * <p>This method is called after {@link #provideFlutterEngine(Context)}.
   *
   * <p>All plugins listed in the app's pubspec are registered in the base implementation of this
   * method. To avoid automatic plugin registration, override this method without invoking super().
   * To keep automatic plugin registration and further configure the flutterEngine, override this
   * method, invoke super(), and then configure the flutterEngine as desired.
   */
  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    GeneratedPluginRegister.registerGeneratedPlugins(flutterEngine);
  }

  /**
   * Hook for the host to cleanup references that were established in {@link
   * #configureFlutterEngine(FlutterEngine)} before the host is destroyed or detached.
   *
   * <p>This method is called in {@link #onDestroy()}.
   */
  @Override
  public void cleanUpFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    // No-op. Hook for subclasses.
  }

  /**
   * Hook for subclasses to control whether or not the {@link FlutterFragment} within this {@code
   * Activity} automatically attaches its {@link FlutterEngine} to this {@code Activity}.
   *
   * <p>This property is controlled with a protected method instead of an {@code Intent} argument
   * because the only situation where changing this value would help, is a situation in which {@code
   * FlutterActivity} is being subclassed to utilize a custom and/or cached {@link FlutterEngine}.
   *
   * <p>Defaults to {@code true}.
   *
   * <p>Control surfaces are used to provide Android resources and lifecycle events to plugins that
   * are attached to the {@link FlutterEngine}. If {@code shouldAttachEngineToActivity} is true then
   * this {@code FlutterActivity} will connect its {@link FlutterEngine} to itself, along with any
   * plugins that are registered with that {@link FlutterEngine}. This allows plugins to access the
   * {@code Activity}, as well as receive {@code Activity}-specific calls, e.g., {@link
   * Activity#onNewIntent(Intent)}. If {@code shouldAttachEngineToActivity} is false, then this
   * {@code FlutterActivity} will not automatically manage the connection between its {@link
   * FlutterEngine} and itself. In this case, plugins will not be offered a reference to an {@code
   * Activity} or its OS hooks.
   *
   * <p>Returning false from this method does not preclude a {@link FlutterEngine} from being
   * attaching to a {@code FlutterActivity} - it just prevents the attachment from happening
   * automatically. A developer can choose to subclass {@code FlutterActivity} and then invoke
   * {@link ActivityControlSurface#attachToActivity(ExclusiveAppComponent, Lifecycle)} and {@link
   * ActivityControlSurface#detachFromActivity()} at the desired times.
   *
   * <p>One reason that a developer might choose to manually manage the relationship between the
   * {@code Activity} and {@link FlutterEngine} is if the developer wants to move the {@link
   * FlutterEngine} somewhere else. For example, a developer might want the {@link FlutterEngine} to
   * outlive this {@code FlutterActivity} so that it can be used later in a different {@code
   * Activity}. To accomplish this, the {@link FlutterEngine} may need to be disconnected from this
   * {@code FluttterActivity} at an unusual time, preventing this {@code FlutterActivity} from
   * correctly managing the relationship between the {@link FlutterEngine} and itself.
   */
  @Override
  public boolean shouldAttachEngineToActivity() {
    return true;
  }

  @Override
  public boolean shouldHandleDeeplinking() {
    try {
      Bundle metaData = getMetaData();
      boolean shouldHandleDeeplinking =
              metaData != null ? metaData.getBoolean(HANDLE_DEEPLINKING_META_DATA_KEY) : false;
      return shouldHandleDeeplinking;
    } catch (PackageManager.NameNotFoundException e) {
      return false;
    }
  }

  @Override
  public void onFlutterSurfaceViewCreated(@NonNull FlutterSurfaceView flutterSurfaceView) {
    // Hook for subclasses.
  }

  @Override
  public void onFlutterTextureViewCreated(@NonNull FlutterTextureView flutterTextureView) {
    // Hook for subclasses.
  }

  @Override
  public void onFlutterUiDisplayed() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      reportFullyDrawn();
    }
  }

  @Override
  public void onFlutterUiNoLongerDisplayed() {
    // no-op
  }

  @Override
  public boolean shouldRestoreAndSaveState() {
    if (getIntent().hasExtra(EXTRA_ENABLE_STATE_RESTORATION)) {
      return getIntent().getBooleanExtra(EXTRA_ENABLE_STATE_RESTORATION, false);
    }
    if (getCachedEngineId() != null) {
      // Prevent overwriting the existing state in a cached engine with restoration state.
      return false;
    }
    return true;
  }

  @Override
  public boolean popSystemNavigator() {
    // Hook for subclass. No-op if returns false.
    return false;
  }

  private boolean stillAttachedForEvent(String event) {
    if (delegate == null) {
      Log.v(TAG, "FlutterActivity " + hashCode() + " " + event + " called after release.");
      return false;
    }
    return true;
  }
}
