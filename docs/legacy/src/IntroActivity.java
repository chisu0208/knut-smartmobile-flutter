package kr.ac.ut.mobile;

import android.content.DialogInterface;
import android.content.Intent;
import android.content.res.AssetManager;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.widget.ImageView;
import h2.d;
import h2.e;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Locale;
import java.util.UUID;
import p060u.AbstractC0296a;

public class IntroActivity extends kr.ac.ut.mobile.a {

    static String f7656D = "IntroActivity";

    ImageView f7657B;

    String f7658C = null;

    class a implements DialogInterface.OnClickListener {
        a() {
        }

        @Override // android.content.DialogInterface.OnClickListener
        public void onClick(DialogInterface dialogInterface, int i3) {
            Intent intent = new Intent();
            intent.setAction("android.settings.APPLICATION_DETAILS_SETTINGS");
            intent.addCategory("android.intent.category.DEFAULT");
            intent.setData(Uri.parse("package:" + IntroActivity.this.getPackageName()));
            IntroActivity.this.startActivity(intent);
            IntroActivity.this.finish();
        }
    }

    public class b extends AsyncTask {

        private String f7660a;

        private String f7661b;

        private Void[] f7662c;

        public b(String str, String str2) {
            this.f7660a = str;
            this.f7661b = str2;
        }

        @Override // android.os.AsyncTask
        public String doInBackground(Void... voidArr) {
            this.f7662c = voidArr;
            return new i2.a().a(this.f7660a, IntroActivity.this.O(), IntroActivity.this.f7834v);
        }

        @Override // android.os.AsyncTask
        public void onPostExecute(String str) {
            Log.d("POST", "post=======>" + str);
            super.onPostExecute(str);
            IntroActivity.this.f0(str);
        }
    }

    private class c extends AsyncTask {

        private String f7664a;

        private String f7665b;

        public c(String str, String str2) {
            this.f7664a = str;
            this.f7665b = str2;
        }

        @Override // android.os.AsyncTask
        public Void doInBackground(String... strArr) {
            StringBuilder sb = new StringBuilder();
            sb.append(IntroActivity.this.getFilesDir());
            String str = File.separator;
            sb.append(str);
            sb.append(IntroActivity.this.f7830A);
            String string = sb.toString();
            File file = new File(string);
            if (!file.exists()) {
                file.mkdir();
            }
            String str2 = string + str + "intro.png";
            try {
                HttpURLConnection httpURLConnection = (HttpURLConnection) new URL(this.f7665b).openConnection();
                byte[] bArr = new byte[httpURLConnection.getContentLength()];
                InputStream inputStream = httpURLConnection.getInputStream();
                FileOutputStream fileOutputStream = new FileOutputStream(new File(str2));
                while (true) {
                    int i3 = inputStream.read(bArr);
                    if (i3 <= 0) {
                        inputStream.close();
                        fileOutputStream.close();
                        httpURLConnection.disconnect();
                        return null;
                    }
                    fileOutputStream.write(bArr, 0, i3);
                }
            } catch (Exception e3) {
                e3.printStackTrace();
                return null;
            }
        }

        @Override // android.os.AsyncTask
        public void onPostExecute(Void r3) {
            IntroActivity.this.l0();
            super.onPostExecute(r3);
        }
    }

    public void f0(String str) {
        Log.d(f7656D, "intro allytteCommand==>>>> " + str);
        this.f7658C = null;
        Intent intent = new Intent(this, (Class<?>) MainActivity.class);
        intent.putExtra("screen_info", str);
        startActivity(intent);
        finish();
    }

    private boolean g0() {
        StringBuilder sb = new StringBuilder();
        sb.append(getFilesDir());
        String str = File.separator;
        sb.append(str);
        sb.append(this.f7830A);
        sb.append(str);
        sb.append("intro.png");
        return new File(sb.toString()).exists();
    }

    private void i0(String str) {
        Log.d(f7656D, "dataRequest===>" + str);
        new b(str, this.f7837y).execute(new Void[0]);
    }

    private boolean k0(String[] strArr) {
        boolean z2 = true;
        for (String str : strArr) {
            if (p063v.b.a(this, str) != 0) {
                z2 = false;
            }
        }
        return z2;
    }

    public void l0() {
        P();
        String str = this.f7834v;
        if (str == null || str.length() == 0) {
            String upperCase = UUID.randomUUID().toString().toUpperCase();
            this.f7834v = upperCase;
            Z("device", "device_token", upperCase);
        }
        String str2 = String.format("?devicePlatform=%s&modelName=%s&deviceToken=%s&osVersion=%s&osLang=%s&osName=%s&appVersion=%s&pushToken=%s&siteId=0", "android", Build.MODEL, this.f7834v, Integer.valueOf(Build.VERSION.SDK_INT), Locale.getDefault().getLanguage(), Build.VERSION.RELEASE, O(), this.f7835w);
        String str3 = this.f7658C;
        if (str3 == null) {
            this.f7836x = "https://mobile.ut.ac.kr//service/api/device/save" + str2;
        } else {
            this.f7836x = str3;
        }
        Log.d(f7656D, "full_url  ==>>>> " + this.f7836x);
        i0(this.f7836x);
    }

    private void m0() {
        StringBuilder sb = new StringBuilder();
        sb.append(getFilesDir());
        String str = File.separator;
        sb.append(str);
        sb.append(this.f7830A);
        sb.append(str);
        sb.append("intro.png");
        File file = new File(sb.toString());
        Log.d(f7656D, "destPath22222222222========================================>" + getFilesDir() + str + this.f7830A + str + "intro.png");
        if (file.exists()) {
            this.f7657B.setImageBitmap(BitmapFactory.decodeFile(file.getAbsolutePath()));
        }
    }

    public void h0(String str) {
        AssetManager assets = getAssets();
        try {
            StringBuilder sb = new StringBuilder();
            sb.append(getFilesDir());
            String str2 = File.separator;
            sb.append(str2);
            sb.append(this.f7830A);
            String string = sb.toString();
            File file = new File(string);
            if (!file.exists()) {
                file.mkdir();
            }
            String str3 = string + str2 + "intro.png";
            Log.d(f7656D, "srcFile','destFile===>" + str + "---" + str3);
            InputStream inputStreamOpen = assets.open(str);
            FileOutputStream fileOutputStream = new FileOutputStream(str3);
            byte[] bArr = new byte[1024];
            while (true) {
                int i3 = inputStreamOpen.read(bArr);
                if (i3 == -1) {
                    inputStreamOpen.close();
                    fileOutputStream.flush();
                    fileOutputStream.close();
                    return;
                }
                fileOutputStream.write(bArr, 0, i3);
            }
        } catch (IOException e3) {
            e3.printStackTrace();
        }
    }

    public void j0(String str) {
        new c("png", str).execute(new String[0]);
    }

    public void n0() {
        String[] strArr = {"android.permission.READ_PHONE_STATE", "android.permission.WRITE_EXTERNAL_STORAGE", "android.permission.READ_EXTERNAL_STORAGE", "android.permission.CALL_PHONE", "android.permission.CAMERA", "android.permission.ACCESS_COARSE_LOCATION"};
        String[] strArr2 = {"android.permission.READ_PHONE_NUMBERS", "android.permission.WRITE_EXTERNAL_STORAGE", "android.permission.READ_EXTERNAL_STORAGE", "android.permission.CALL_PHONE", "android.permission.CAMERA", "android.permission.ACCESS_COARSE_LOCATION"};
        String[] strArr3 = {"android.permission.READ_PHONE_NUMBERS", "android.permission.CALL_PHONE", "android.permission.CAMERA", "android.permission.ACCESS_COARSE_LOCATION", "android.permission.POST_NOTIFICATIONS", "android.permission.NEARBY_WIFI_DEVICES"};
        String[] strArr4 = {"android.permission.READ_PHONE_NUMBERS", "android.permission.CALL_PHONE", "android.permission.CAMERA", "android.permission.ACCESS_COARSE_LOCATION", "android.permission.POST_NOTIFICATIONS", "android.permission.NEARBY_WIFI_DEVICES"};
        int i3 = Build.VERSION.SDK_INT;
        if (i3 >= 34) {
            if (!k0(strArr4)) {
                AbstractC0296a.j(this, strArr4, 1);
                return;
            }
            String strR = R("device", "splash_url");
            if (strR == null || strR.length() <= 0) {
                l0();
                return;
            } else {
                j0(strR);
                return;
            }
        }
        if (i3 >= 33) {
            if (!k0(strArr3)) {
                AbstractC0296a.j(this, strArr3, 1);
                return;
            }
            String strR2 = R("device", "splash_url");
            if (strR2 == null || strR2.length() <= 0) {
                l0();
                return;
            } else {
                j0(strR2);
                return;
            }
        }
        if (i3 >= 30) {
            if (!k0(strArr2)) {
                AbstractC0296a.j(this, strArr2, 1);
                return;
            }
            String strR3 = R("device", "splash_url");
            if (strR3 == null || strR3.length() <= 0) {
                l0();
                return;
            } else {
                j0(strR3);
                return;
            }
        }
        if (!k0(strArr)) {
            AbstractC0296a.j(this, strArr, 1);
            return;
        }
        String strR4 = R("device", "splash_url");
        if (strR4 == null || strR4.length() <= 0) {
            l0();
        } else {
            j0(strR4);
        }
    }

    public void o0(String str) {
        androidx.appcompat.app.b.a aVar = new androidx.appcompat.app.b.a(this);
        aVar.m("").g("[" + str + "]권한을 추가해 주세요.");
        aVar.d(false);
        aVar.k("OK", new a());
        aVar.a().show();
    }

    @Override // kr.ac.ut.mobile.a, androidx.fragment.app.e, androidx.activity.ComponentActivity, p060u.e, android.app.Activity
    protected void onCreate(Bundle bundle) {
        super.onCreate(bundle);
        if (!g0()) {
            h0("app_icon_1024.png");
        }
        setContentView(e.f7386b);
        Bundle extras = getIntent().getExtras();
        if (extras != null && extras.getString("push_url") != null && !extras.getString("push_url").equalsIgnoreCase("")) {
            this.f7658C = extras.getString("push_url");
        }
        Log.d(f7656D, "push_url====================>" + this.f7658C);
        this.f7657B = (ImageView) findViewById(d.f7364f);
        m0();
        n0();
    }

    @Override // androidx.fragment.app.e, androidx.activity.ComponentActivity, android.app.Activity
    public void onRequestPermissionsResult(int i3, String[] strArr, int[] iArr) {
        String str;
        super.onRequestPermissionsResult(i3, strArr, iArr);
        if (i3 != 1 || iArr.length <= 0) {
            return;
        }
        String str2 = "";
        for (int i4 = 0; i4 < iArr.length; i4++) {
            Log.d(f7656D, "permissions==>>>> " + strArr[i4] + " 권한: " + iArr[i4]);
            if (iArr[i4] == 0) {
                Log.d(f7656D, "permissions==>>>> " + strArr[i4] + " 동의함.");
            } else {
                Log.d(f7656D, "permissions==>>>> " + strArr[i4] + "거부함.");
                if (strArr[i4].indexOf("PHONE") > 0) {
                    str = "전화";
                } else if (strArr[i4].indexOf("MEDIA") > 0) {
                    str = "사진및동영상,카메라";
                } else if (strArr[i4].indexOf("CAMERA") > 0) {
                    str = "카메라";
                } else if (strArr[i4].indexOf("ACCESS") > 0) {
                    str = "위치";
                } else if (strArr[i4].indexOf("NOTIFICATION") > 0) {
                    str = "알림";
                } else if (strArr[i4].indexOf("NEARBY") > 0) {
                    str = "근처기기";
                } else {
                    str = strArr[i4].indexOf("STORAGE") > 0 ? "파일및미디어" : "기타";
                }
                if (str2.indexOf(str) < 0) {
                    str2 = str2 + "," + str;
                }
            }
        }
        if (str2 == null || str2.length() <= 0) {
            l0();
            return;
        }
        c0("권한이 거부되었습니다. 해당권한을 허용하셔야 합니다.");
        if (Build.VERSION.SDK_INT >= 29) {
            o0(str2.substring(1));
        } else {
            finish();
        }
    }
}
