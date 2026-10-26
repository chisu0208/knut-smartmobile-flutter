package kr.ac.ut.mobile;

import F.A;
import F.H;
import F.c0;
import android.app.Dialog;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.util.TypedValue;
import android.view.View;
import android.view.WindowManager;
import android.widget.Toast;
import androidx.appcompat.app.c;
import h2.e;
import java.util.Locale;
import p069x.g;

public abstract class a extends c {

    String f7830A = "allytte";

    protected Context f7831s;

    protected Dialog f7832t;

    protected Dialog f7833u;

    String f7834v;

    String f7835w;

    String f7836x;

    String f7837y;

    String f7838z;

    class C0092a implements A {
        C0092a() {
        }

        @Override // F.A
        public c0 a(View view, c0 c0Var) {
            g gVarF = c0Var.f(c0.l.b());
            view.setPadding(gVarF.f9368a, gVarF.f9369b, gVarF.f9370c, gVarF.f9371d);
            return c0Var;
        }
    }

    public void M() {
        Dialog dialog = this.f7833u;
        if (dialog != null) {
            dialog.dismiss();
        }
    }

    public int N(Context context, int i3) {
        return (int) TypedValue.applyDimension(1, i3, context.getResources().getDisplayMetrics());
    }

    public String O() {
        try {
            return getPackageManager().getPackageInfo(getPackageName(), 0).versionName;
        } catch (PackageManager.NameNotFoundException e3) {
            e3.printStackTrace();
            return "";
        }
    }

    public void P() {
        try {
            this.f7834v = R("device", "device_token");
            this.f7835w = R("device", "push_token");
        } catch (Exception e3) {
            e3.printStackTrace();
        }
    }

    public NetworkInfo Q() {
        ConnectivityManager connectivityManager = (ConnectivityManager) getSystemService("connectivity");
        if (connectivityManager != null) {
            return connectivityManager.getActiveNetworkInfo();
        }
        return null;
    }

    public String R(String str, String str2) {
        return getSharedPreferences(str, 0).getString(str2, "");
    }

    public void S() {
        if (this.f7833u.isShowing()) {
            this.f7833u.hide();
        }
    }

    public void T() {
        if (this.f7833u == null) {
            Dialog dialog = new Dialog(this, android.R.style.Theme.Translucent.NoTitleBar);
            this.f7833u = dialog;
            dialog.setContentView(e.f7391g);
            this.f7833u.setCancelable(true);
            this.f7833u.setCanceledOnTouchOutside(true);
        }
    }

    public boolean U() {
        NetworkInfo networkInfoQ = Q();
        return networkInfoQ != null && networkInfoQ.isConnected() && (networkInfoQ.getType() == 1 || networkInfoQ.getType() == 0);
    }

    public WindowManager.LayoutParams V(Dialog dialog) {
        DisplayMetrics displayMetrics = new DisplayMetrics();
        WindowManager windowManager = (WindowManager) getSystemService("window");
        if (windowManager == null) {
            throw new AssertionError();
        }
        windowManager.getDefaultDisplay().getMetrics(displayMetrics);
        WindowManager.LayoutParams layoutParams = new WindowManager.LayoutParams();
        layoutParams.copyFrom(dialog.getWindow().getAttributes());
        layoutParams.width = displayMetrics.widthPixels - ((int) (displayMetrics.density * 70.0f));
        layoutParams.height = -2;
        layoutParams.flags = 2;
        layoutParams.dimAmount = 0.5f;
        return layoutParams;
    }

    public void W() {
        Locale locale = Locale.US;
        Configuration configuration = new Configuration();
        configuration.locale = locale;
        getResources().updateConfiguration(configuration, getResources().getDisplayMetrics());
    }

    public void X() {
        Locale locale = Locale.KOREA;
        Configuration configuration = new Configuration();
        configuration.locale = locale;
        getResources().updateConfiguration(configuration, getResources().getDisplayMetrics());
    }

    public void Y(String str) {
        if (str == null || str.length() == 0) {
            X();
        }
        if (str == null || !str.equals("ut")) {
            W();
        } else {
            X();
        }
    }

    public void Z(String str, String str2, String str3) {
        SharedPreferences.Editor editorEdit = getSharedPreferences(str, 0).edit();
        editorEdit.putString(str2, str3);
        editorEdit.apply();
    }

    void a0() {
        H.w0(findViewById(android.R.id.content), new C0092a());
        getWindow().getDecorView().setSystemUiVisibility(8192);
    }

    public void b0() {
        if (this.f7833u.isShowing()) {
            return;
        }
        this.f7833u.show();
    }

    public void c0(String str) {
        Toast.makeText(this, str, 0).show();
    }

    @Override // androidx.fragment.app.e, androidx.activity.ComponentActivity, p060u.e, android.app.Activity
    protected void onCreate(Bundle bundle) {
        super.onCreate(bundle);
        a0();
    }
}
