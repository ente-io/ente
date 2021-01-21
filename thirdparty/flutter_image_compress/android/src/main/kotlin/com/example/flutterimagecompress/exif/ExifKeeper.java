package com.example.flutterimagecompress.exif;
/// create 2019-07-02 by cai

import android.content.Context;
import android.util.Log;

import org.apache.commons.io.IOUtils;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

import androidx.exifinterface.media.ExifInterface;

public class ExifKeeper {

  private static List<String> attributes =
      Arrays.asList(
          "FNumber",
          "ExposureTime",
          "ISOSpeedRatings",
          "GPSAltitude",
          "GPSAltitudeRef",
          "FocalLength",
          "GPSDateStamp",
          "WhiteBalance",
          "GPSProcessingMethod",
          "GPSTimeStamp",
          "DateTime",
          "Flash",
          "GPSLatitude",
          "GPSLatitudeRef",
          "GPSLongitude",
          "GPSLongitudeRef",
          "Make",
          "Model");

  private ExifInterface oldExif;

  public ExifKeeper(ExifInterface oldExif) {
    this.oldExif = oldExif;
  }

  public ExifKeeper(String filePath) throws IOException {
    this.oldExif = new ExifInterface(filePath);
  }

  public ExifKeeper(byte[] buf) throws IOException {
    this.oldExif = new ExifInterface(new ByteArrayInputStream(buf));
  }

  private static void copyExif(ExifInterface oldExif, ExifInterface newExif) {
    for (String attribute : attributes) {
      setIfNotNull(oldExif, newExif, attribute);
    }
    try {
      newExif.saveAttributes();
    } catch (IOException e) {
    }
  }

  private static void setIfNotNull(ExifInterface oldExif, ExifInterface newExif, String property) {
    if (oldExif.getAttribute(property) != null) {
      newExif.setAttribute(property, oldExif.getAttribute(property));
    }
  }

  public ByteArrayOutputStream writeToOutputStream(Context context, ByteArrayOutputStream outputStream) {
    FileOutputStream fileOutputStream = null;
    FileInputStream fileInputStream = null;
    try {
      String uuid = UUID.randomUUID().toString();
      File file = new File(context.getCacheDir(), uuid + ".jpg");
      fileOutputStream = new FileOutputStream(file);
      IOUtils.write(outputStream.toByteArray(), fileOutputStream);
      fileOutputStream.close();

      ExifInterface newExif = new ExifInterface(file.getAbsolutePath());

      copyExif(oldExif, newExif);

      newExif.saveAttributes();
      fileOutputStream.close();

      ByteArrayOutputStream newStream = new ByteArrayOutputStream();
      fileInputStream = new FileInputStream(file);

      IOUtils.copy(fileInputStream, newStream);
      fileInputStream.close();
      return newStream;

    } catch (Exception ex) {
      Log.e("ExifDataCopier", "Error preserving Exif data on selected image: " + ex);
    }

    if (fileInputStream != null) {
      try {
        fileInputStream.close();
      } catch (IOException e) {
        e.printStackTrace();
      }
    }

    if (fileOutputStream != null) {
      try {
         fileOutputStream.close();
      } catch (IOException e) {
         e.printStackTrace();
      }
    }

    return outputStream;
 }

  public void copyExifToFile(File file) {
    try {
      ExifInterface newExif = new ExifInterface(file.getAbsolutePath());
      copyExif(oldExif, newExif);
      newExif.saveAttributes();
    } catch (IOException e) {
      return;
    }

  }
}
