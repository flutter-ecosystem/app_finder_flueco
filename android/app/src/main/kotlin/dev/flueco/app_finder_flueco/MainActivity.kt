package dev.flueco.app_finder_flueco

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            when (call.method) {
                "getInstalledApps" -> getInstalledApps(result)
                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName.isNullOrBlank()) {
                        result.error("missing_package", "packageName is required", null)
                    } else {
                        launchApp(packageName, result)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getInstalledApps(result: MethodChannel.Result) {
        executor.execute {
            try {
                val packageManager = applicationContext.packageManager
                val launchIntent =
                        Intent(Intent.ACTION_MAIN, null).apply {
                            addCategory(Intent.CATEGORY_LAUNCHER)
                        }

                val activities =
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            packageManager.queryIntentActivities(
                                    launchIntent,
                                    PackageManager.ResolveInfoFlags.of(0)
                            )
                        } else {
                            @Suppress("DEPRECATION")
                            packageManager.queryIntentActivities(launchIntent, 0)
                        }

                val packageNames =
                        activities
                                .mapNotNull { it.activityInfo?.packageName }
                                .toSet()
                                .toMutableList()

                val installedPackages =
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            packageManager.getInstalledApplications(
                                    PackageManager.ApplicationInfoFlags.of(0)
                            )
                        } else {
                            @Suppress("DEPRECATION")
                            packageManager.getInstalledApplications(0)
                        }

                val appsFromPackages =
                        installedPackages
                                .asSequence()
                                .filter { appInfo ->
                                    val packageName = appInfo.packageName
                                    packageName in packageNames || packageManager.getLaunchIntentForPackage(packageName) != null
                                }
                                .mapNotNull { appInfo ->
                                    val packageName = appInfo.packageName
                                    val launchableIntent = packageManager.getLaunchIntentForPackage(packageName)
                                    if (launchableIntent == null) {
                                        return@mapNotNull null
                                    }

                                    val applicationInfo = getApplicationInfo(packageManager, packageName)
                                            ?: return@mapNotNull null

                                    mapOf(
                                            "name" to
                                                    applicationInfo
                                                            .loadLabel(packageManager)
                                                            .toString(),
                                            "packageName" to packageName,
                                            "category" to categoryName(applicationInfo),
                                            "isSystemApp" to isSystemApp(applicationInfo),
                                            "icon" to
                                                    drawableToPngBytes(
                                                            applicationInfo.loadIcon(packageManager)
                                                    ),
                                            "launchActivity" to
                                                    (launchableIntent.component?.className ?: "")
                                    )
                                }
                                .toList()

                val apps =
                        activities
                                .mapNotNull { resolveInfo ->
                                    val packageName =
                                            resolveInfo.activityInfo?.packageName
                                                    ?: return@mapNotNull null
                                    val applicationInfo =
                                            getApplicationInfo(packageManager, packageName)
                                                    ?: return@mapNotNull null
                                    val launchableIntent =
                                            packageManager.getLaunchIntentForPackage(packageName)
                                                    ?: return@mapNotNull null

                                    mapOf(
                                            "name" to
                                                    applicationInfo
                                                            .loadLabel(packageManager)
                                                            .toString(),
                                            "packageName" to packageName,
                                            "category" to categoryName(applicationInfo),
                                            "isSystemApp" to isSystemApp(applicationInfo),
                                            "icon" to
                                                    drawableToPngBytes(
                                                            applicationInfo.loadIcon(packageManager)
                                                    ),
                                            "launchActivity" to
                                                    (launchableIntent.component?.className ?: "")
                                    )
                                }
                                .distinctBy { it["packageName"] as String }
                                .sortedBy { (it["name"] as String).lowercase() }

                mainHandler.post { result.success(apps) }
            } catch (t: Throwable) {
                mainHandler.post {
                    result.error("installed_apps_error", t.message, t.stackTraceToString())
                }
            }
        }
    }

    private fun launchApp(packageName: String, result: MethodChannel.Result) {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        if (intent == null) {
            result.error("not_launchable", "No launch intent found for $packageName", null)
            return
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        result.success(true)
    }

    private fun getApplicationInfo(
            packageManager: PackageManager,
            packageName: String
    ): ApplicationInfo? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getApplicationInfo(
                        packageName,
                        PackageManager.ApplicationInfoFlags.of(0)
                )
            } else {
                @Suppress("DEPRECATION") packageManager.getApplicationInfo(packageName, 0)
            }
        } catch (_: PackageManager.NameNotFoundException) {
            null
        }
    }

    private fun isSystemApp(info: ApplicationInfo): Boolean {
        return (info.flags and ApplicationInfo.FLAG_SYSTEM) != 0 ||
                (info.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
    }

    private fun categoryName(info: ApplicationInfo): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return "undefined"
        return when (info.category) {
            ApplicationInfo.CATEGORY_GAME -> "game"
            ApplicationInfo.CATEGORY_AUDIO -> "audio"
            ApplicationInfo.CATEGORY_VIDEO -> "video"
            ApplicationInfo.CATEGORY_IMAGE -> "image"
            ApplicationInfo.CATEGORY_SOCIAL -> "social"
            ApplicationInfo.CATEGORY_NEWS -> "news"
            ApplicationInfo.CATEGORY_MAPS -> "maps"
            ApplicationInfo.CATEGORY_PRODUCTIVITY -> "productivity"
            else -> "undefined"
        }
    }

    private fun drawableToPngBytes(drawable: Drawable): ByteArray {
        val bitmap =
                when (drawable) {
                    is BitmapDrawable -> drawable.bitmap
                    else -> {
                        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
                        val height =
                                if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
                        Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).also { bitmap ->
                            val canvas = Canvas(bitmap)
                            drawable.setBounds(0, 0, canvas.width, canvas.height)
                            drawable.draw(canvas)
                        }
                    }
                }

        return ByteArrayOutputStream().use { stream ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        }
    }

    companion object {
        private const val CHANNEL = "app_finder_flueco/installed_apps"
    }
}
