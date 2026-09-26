# Gradle-плагин Flutter включает R8 в release сам, даже когда в build.gradle.kts
# минификации не видно. flutter_local_notifications хранит кэш уведомлений через
# Gson, а Gson без generic-сигнатур падает с "TypeToken must be created with a
# type argument" на каждом show(). У клиента show() зовётся для пуша, пришедшего
# при открытом приложении, — без правил ниже такой пуш в release молча не
# показывается. Правила те же, что в приложении охраны (там это глушило сирену).
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class com.dexterous.flutterlocalnotifications.** { *; }
