# kotlinx.serialization ships its own R8 rules; keep the serialisable data model explicitly.
-keep,includedescriptorclasses class ai.biniam.sbfexamprep.data.**$$serializer { *; }
-keepclassmembers class ai.biniam.sbfexamprep.data.** {
    *** Companion;
    kotlinx.serialization.KSerializer serializer(...);
}
