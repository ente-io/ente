package top.kikt.imagescanner.permission;

import android.annotation.TargetApi;
import android.app.Activity;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.text.Spannable;
import android.text.SpannableStringBuilder;
import android.text.style.ForegroundColorSpan;

import java.util.ArrayList;
import java.util.List;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.core.app.ActivityCompat;

import org.jetbrains.annotations.NotNull;

import top.kikt.imagescanner.util.LogUtils;

/**
 * Created by Administrator on 2017/2/19.
 */

public final class PermissionsUtils {

  /**
   * 需要申请权限的Activity
   */
  private Activity mActivity;

  /**
   * 需要申请的权限的List
   */
  private List<String> needToRequestPermissionsList = new ArrayList<>();

  /**
   * 拒绝授权的权限的List
   */
  private List<String> deniedPermissionsList = new ArrayList<>();

  /**
   * 允许的权限List
   */
  private List<String> grantedPermissionsList = new ArrayList<>();

  /**
   * 某次进行权限申请的requestCode
   */
  private int requestCode;

  /**
   * 授权监听回调
   */
  private PermissionsListener mPermissionsListener;

  /**
   * 未授权的权限的提示字符串的List
   */
  private List<String> tipList;

  /**
   * 被拒绝的权限的提示字符串List
   */
  private List<String> deniedTipsList;

  public PermissionsUtils() {
  }

  /**
   * 设置是哪一个Activity进行权限操作
   *
   * @param activity 哪一个Activity进行权限操作
   * @return 返回 {@link PermissionsUtils} 自身，进行链式调用
   */
  public PermissionsUtils withActivity(Activity activity) {
    this.mActivity = activity;
    return this;
  }

  /**
   * 进行权限申请，不带拒绝弹框提示
   *
   * @param requestCode 指定该次申请的requestCode
   * @param permissions 要申请的权限数组
   * @return 返回 {@link PermissionsUtils} 自身，进行链式调用
   */
  public PermissionsUtils getPermissions(Activity activity, int requestCode, List<String> permissions) {
    return getPermissionsWithTips(activity, requestCode, null, permissions.toArray(new String[0]));
  }

  /**
   * 进行权限申请，带拒绝弹框提示
   *
   * @param activity    告诉工具是Activity申请权限还是Fragment申请权限
   * @param requestCode 指定该次申请的requestCode
   * @param tips        要申请的权限的被拒绝后的提示的数组
   * @param permissions 要申请的权限数组
   * @return 返回 {@link PermissionsUtils} 自身，进行链式调用
   */
  @TargetApi(23)
  private PermissionsUtils getPermissionsWithTips(Activity activity, int requestCode, String[] tips, String... permissions) {
    if (mActivity == null) {
      throw new NullPointerException("获取权限的Activity不存在");
    }
    this.requestCode = requestCode;
    if (!checkPermissions(tips, permissions)) {
      // 通过上面的checkPermissions，可以知道能得到进入到这里面的都是6.0的机子
      ActivityCompat.requestPermissions(mActivity
              , needToRequestPermissionsList.toArray(new String[needToRequestPermissionsList.size()])
              , requestCode);
      for (int i = 0; i < needToRequestPermissionsList.size(); i++) {
        LogUtils.info("需要申请的权限列表" + needToRequestPermissionsList.get(i));
      }
    } else if (mPermissionsListener != null) mPermissionsListener.onGranted();
    return this;
  }

  /**
   * 检查所需权限是否已获取
   *
   * @param permissions 所需权限数组
   * @return 是否全部已获取
   */
  private boolean checkPermissions(String[] tips, String... permissions) {
    if (Build.VERSION.SDK_INT >= 23) {
      resetStatus();
//            if (!needToRequestPermissionsList.isEmpty())
//                needToRequestPermissionsList.clear();
      if (tips != null) {
        if (tips.length != permissions.length) {
          throw new IndexOutOfBoundsException("传入的提示数组和需要申请的权限数组长度不一致");
        }
        if (this.tipList == null)
          this.tipList = new ArrayList<>();
//                else
//                    this.tipList.clear();
      }
      for (int i = 0; i < permissions.length; i++) {
        // 检查权限
        if (mActivity.checkSelfPermission(permissions[i]) == PackageManager.PERMISSION_DENIED) {
          needToRequestPermissionsList.add(permissions[i]);
          if (tips != null)
            tipList.add(tips[i]);
        }
      }
      // 全部权限获取成功返回true，否则返回false
      return needToRequestPermissionsList.isEmpty();
    } else {
      return true;
    }
  }

  /**
   * 处理申请权限返回
   * 由于某些rom对权限进行了处理，第一次选择了拒绝，则不会出现第二次询问（或者没有不再询问），故拒绝就回调onDenied
   *
   * @param requestCode  对应申请权限时的code
   * @param permissions  申请的权限数组
   * @param grantResults 是否申请到权限数组
   * @return 返回 {@link PermissionsUtils} 自身，进行链式调用
   */
  public PermissionsUtils dealResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
    if (requestCode == this.requestCode) {
//            if (!deniedPermissionsList.isEmpty())
//                deniedPermissionsList.clear();
//            if (deniedTipsList != null && !deniedTipsList.isEmpty())
//                deniedTipsList.clear();

//            for (String permission : permissions) {
//                if (ActivityCompat.checkSelfPermission(mActivity,permission)== PackageManager.PERMISSION_DENIED){
//                    deniedPermissionsList.add(permission);
//                }
//            }

      for (int i = 0; i < permissions.length; i++) {
        LogUtils.info("返回权限列表" + permissions[i]);
        if (grantResults[i] == PackageManager.PERMISSION_DENIED) {
          deniedPermissionsList.add(permissions[i]);
          if (tipList != null && deniedTipsList == null) {
            deniedTipsList = new ArrayList<>();
          }
          if (deniedTipsList != null && tipList != null && tipList.size() > 0)
            deniedTipsList.add(tipList.get(i));
        } else if (grantResults[i] == PackageManager.PERMISSION_GRANTED) {
          grantedPermissionsList.add(permissions[i]);
        }
      }
      if (!deniedPermissionsList.isEmpty()) {
        if (tipList != null && tipList.size() > 0) {
          showDialog();
        }
        // 回调用户拒绝监听
        mPermissionsListener.onDenied(deniedPermissionsList, grantedPermissionsList);
      } else {
        // 回调用户同意监听
        mPermissionsListener.onGranted();
      }
    }
    return this;
  }

  /**
   * 恢复状态
   */
  private void resetStatus() {
    if (deniedPermissionsList != null) deniedPermissionsList.clear();
    if (deniedTipsList != null) deniedTipsList.clear();
    if (needToRequestPermissionsList != null) needToRequestPermissionsList.clear();
    if (tipList != null) tipList.clear();
  }

  /**
   * 显示被拒绝的权限列表和对应的提示列表的dialog
   */
  private void showDialog() {
    new AlertDialog.Builder(mActivity)
            .setTitle(dealStringWithColor())
            .setPositiveButton("去设置", new DialogInterface.OnClickListener() {
              @Override
              public void onClick(DialogInterface dialog, int which) {
                getAppDetailSettingIntent(mActivity);
                dialog.dismiss();
              }
            })
            .setNegativeButton("取消", new DialogInterface.OnClickListener() {
              @Override
              public void onClick(DialogInterface dialog, int which) {
                dialog.dismiss();
              }
            })
            .create()
            .show();
  }

  /**
   * 列表有颜色
   */
  private CharSequence dealStringWithColor() {
    SpannableStringBuilder builder = new SpannableStringBuilder();
    int start = 0;
    for (int i = 0; i < deniedPermissionsList.size(); i++) {
      String temp = deniedPermissionsList.get(i).split("\\.")[2];
      builder.append(temp);
      ForegroundColorSpan foregroundColorSpan = new ForegroundColorSpan(Color.parseColor("#37ADA4"));
      builder.setSpan(foregroundColorSpan, start, start + temp.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
      builder.append("：");
      builder.append(deniedTipsList.get(i));
      start = start + temp.length() + 2 + deniedTipsList.get(i).length();
      if (i != deniedPermissionsList.size() - 1)
        builder.append("\n");
    }
    return builder;
  }

  /**
   * 跳转到应用的设置界面
   *
   * @param context 上下文
   */
  public void getAppDetailSettingIntent(Context context) {
    Intent localIntent = new Intent();
    localIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    localIntent.setAction("android.settings.APPLICATION_DETAILS_SETTINGS");
    localIntent.setData(Uri.fromParts("package", context.getPackageName(), null));
    context.startActivity(localIntent);
  }

  /**
   * 获取申请权限的回调监听器
   *
   * @return 监听器
   */
  public PermissionsListener getPermissionsListener() {
    return mPermissionsListener;
  }

  /**
   * 设置申请权限的回调监听器
   *
   * @param permissionsListener 监听器
   * @return 返回 {@link PermissionsUtils} 自身，进行链式调用
   */
  public PermissionsUtils setPermissionsListener(PermissionsListener permissionsListener) {
    this.mPermissionsListener = permissionsListener;
    return this;
  }

}