package com.rezuku.pk.ui

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

private val DarkColors = darkColorScheme(
    primary = Color(0xFF9BB5FF),
    onPrimary = Color(0xFF002C75),
    secondary = Color(0xFFBEC7DC),
    background = Color(0xFF111418),
    surface = Color(0xFF111418),
)

private val LightColors = lightColorScheme(
    primary = Color(0xFF3F51B5),
    onPrimary = Color.White,
    secondary = Color(0xFF5C5F77),
    background = Color(0xFFFBFBFE),
    surface = Color(0xFFFBFBFE),
)

/**
 * Compose theme for the combined app.
 *
 * Picks dynamic colours on Android 12+ when available, falling back to the
 * static M3 defaults (which were originally Material indigo from the Shizuku
 * theme and a purple/blue Material You palette from Canta).
 */
@Composable
fun RezukuTheme(
    useDarkTheme: Boolean = isSystemInDarkTheme(),
    useDynamicColour: Boolean = true,
    content: @Composable () -> Unit,
) {
    val colours = when {
        useDynamicColour && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val ctx = LocalContext.current
            if (useDarkTheme) dynamicDarkColorScheme(ctx) else dynamicLightColorScheme(ctx)
        }
        useDarkTheme -> DarkColors
        else -> LightColors
    }
    MaterialTheme(colorScheme = colours, content = content)
}
