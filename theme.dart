<?xml version="1.0" encoding="utf-8"?>
<LinearLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/widget_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:background="@drawable/widget_background"
    android:padding="16dp"
    android:gravity="center_vertical">

    <!-- Date label -->
    <TextView
        android:id="@+id/widget_date"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Today"
        android:textColor="#99FFFFFF"
        android:textSize="11sp"
        android:fontFamily="sans-serif-medium"
        android:letterSpacing="0.05"/>

    <!-- App name -->
    <TextView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="🌊 HabitFlow"
        android:textColor="#FFFFFF"
        android:textSize="14sp"
        android:fontFamily="sans-serif-black"
        android:layout_marginTop="2dp"/>

    <!-- Count: done / total -->
    <TextView
        android:id="@+id/widget_count"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="0 / 0"
        android:textColor="#FFFFFF"
        android:textSize="32sp"
        android:fontFamily="sans-serif-black"
        android:layout_marginTop="8dp"/>

    <!-- Sub label -->
    <TextView
        android:id="@+id/widget_sub"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="No habits today"
        android:textColor="#CCFFFFFF"
        android:textSize="12sp"
        android:fontFamily="sans-serif-medium"/>

    <!-- Progress bar -->
    <ProgressBar
        android:id="@+id/widget_progress"
        style="?android:attr/progressBarStyleHorizontal"
        android:layout_width="match_parent"
        android:layout_height="8dp"
        android:layout_marginTop="10dp"
        android:progressDrawable="@drawable/widget_progress_drawable"
        android:max="100"
        android:progress="0"/>

</LinearLayout>
