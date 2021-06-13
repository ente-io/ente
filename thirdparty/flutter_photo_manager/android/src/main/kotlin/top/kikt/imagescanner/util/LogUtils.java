package top.kikt.imagescanner.util;
/// create 2019-07-16 by cai


import android.annotation.SuppressLint;
import android.database.Cursor;
import android.util.Log;

@SuppressLint("LongLogTag")
public class LogUtils {

  public static final String TAG = "PhotoManagerPluginLogger";

  public static boolean isLog = false;


  public static void info(Object object) {
    if (!isLog) {
      return;
    }
    String msg;
    if (object == null) {
      msg = "null";
    } else {
      msg = object.toString();
    }
    Log.i(TAG, msg);
  }

  public static void debug(Object object) {
    if (!isLog) {
      return;
    }
    String msg;
    if (object == null) {
      msg = "null";
    } else {
      msg = object.toString();
    }
    Log.d(TAG, msg);
  }

  public static void error(Object object, Throwable error) {
    if (!isLog) {
      return;
    }
    String msg;
    if (object == null) {
      msg = "null";
    } else {
      msg = object.toString();
    }
    Log.e(TAG, msg, error);
  }

  public static void error(Object object) {
    if (!isLog) {
      return;
    }
    String msg;
    if (object == null) {
      msg = "null";
    } else {
      msg = object.toString();
    }
    Log.e(TAG, msg);
  }

  public static void logCursor(Cursor cursor) {
    logCursor(cursor, "_id");
  }

  public static void logCursor(Cursor cursor, String idKey) {
    if (cursor == null) {
      debug("The cursor is null");
      return;
    }
    debug("The cursor row: " + cursor.getCount());
    cursor.moveToPosition(-1);
    while (cursor.moveToNext()) {
      StringBuilder stringBuilder = new StringBuilder();

      int idIndex = cursor.getColumnIndex(idKey);
      if (idIndex != -1) {
        String idValue = cursor.getString(idIndex);
        stringBuilder.append("\nid: ")
            .append(idValue)
            .append("\n");
      }

      for (String columnName : cursor.getColumnNames()) {
        String value = null;
        int columnIndex = cursor.getColumnIndex(columnName);
        try {
          value = cursor.getString(columnIndex);
        } catch (Exception e) {
          e.printStackTrace();
          byte[] blob = cursor.getBlob(columnIndex);
          value = "blob(" + blob.length + ")";
        }
        if (!columnName.equalsIgnoreCase(idKey)) {
          stringBuilder.append("|--")
              .append(columnName)
              .append(" : ")
              .append(value)
              .append("\n");

        }

      }

      debug(stringBuilder);
    }
    cursor.moveToPosition(-1);
  }
}
