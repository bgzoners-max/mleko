# Pravila za R8/ProGuard za release build (isMinifyEnabled = true).
# Flutter i Firebase plugini sami isporučuju consumer ProGuard pravila; ovde
# čuvamo naš AndroidManifest entrypoint i potiskujemo benigna upozorenja za
# compile-only / opciono referencirane biblioteke.

-keep class com.mleko.mleko.** { *; }

-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animal_sniffer.**

