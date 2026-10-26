package kr.ac.ut.mobile;

import android.app.Dialog;
import android.app.DownloadManager;
import android.app.PendingIntent;
import android.content.ActivityNotFoundException;
import android.content.DialogInterface;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.Point;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.location.Location;
import android.location.LocationManager;
import android.net.Uri;
import android.nfc.NdefMessage;
import android.nfc.NfcAdapter;
import android.nfc.NfcManager;
import android.nfc.Tag;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Message;
import android.os.Parcelable;
import android.os.Process;
import android.os.RemoteException;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Display;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.webkit.ConsoleMessage;
import android.webkit.CookieManager;
import android.webkit.DownloadListener;
import android.webkit.JavascriptInterface;
import android.webkit.JsResult;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;
import androidx.constraintlayout.widget.ConstraintLayout;
import h2.c;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.PrintStream;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.URISyntaxException;
import java.net.URL;
import java.net.URLDecoder;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import kr.ac.ut.util.RoundedWebView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import p060u.AbstractC0296a;
import p063v.b;

public class MainActivity extends a implements View.OnClickListener, SensorEventListener, j2.f {

    static String f7667X0 = "MainActivity";

    public static FrameLayout f7668Y0;

    private float[] f7669A0;

    private float[] f7671B0;

    private float[] f7673C0;

    private float[] f7675D0;

    private GradientDrawable f7677E0;

    private GradientDrawable f7679F0;

    private GradientDrawable f7681G0;

    private SensorManager f7683H0;

    RelativeLayout f7684I;

    private Sensor f7685I0;

    LinearLayout f7686J;

    private Sensor f7687J0;

    LinearLayout f7688K;

    private float f7689K0;

    LinearLayout f7690L;

    private float f7691L0;

    WebView f7692M;

    private float f7693M0;

    RelativeLayout f7694N;

    float[] f7695N0;

    RelativeLayout f7696O;

    float[] f7697O0;

    LinearLayout f7698P;

    j2.j f7699P0;

    LinearLayout f7700Q;

    LinearLayout f7702R;

    private ValueCallback f7703R0;

    LinearLayout f7704S;

    j2.p f7705S0;

    LinearLayout f7706T;

    LinearLayout f7708U;

    long f7709U0;

    LinearLayout f7710V;

    JSONArray f7711V0;

    LinearLayout f7712W;

    RoundedWebView f7714X;

    WebView f7715Y;

    WebView f7716Z;

    LinearLayout f7719c0;

    LinearLayout f7720d0;

    Bitmap f7721e0;

    String f7722f0;

    String f7723g0;

    Animation f7725i0;

    Animation f7726j0;

    Animation f7727k0;

    Animation f7728l0;

    Animation f7729m0;

    Animation f7730n0;

    Animation f7731o0;

    Animation f7732p0;

    int f7733q0;

    int f7734r0;

    private SensorManager f7735s0;

    private Sensor f7736t0;

    private long f7737u0;

    private int f7738v0;

    private NfcAdapter f7739w0;

    private PendingIntent f7740x0;

    private GradientDrawable f7741y0;

    private GradientDrawable f7742z0;

    boolean f7670B = false;

    String f7672C = null;

    String f7674D = null;

    boolean f7676E = true;

    boolean f7678F = false;

    int f7680G = 100;

    int f7682H = 110;

    boolean f7717a0 = false;

    boolean f7718b0 = false;

    boolean f7724h0 = false;

    private List f7701Q0 = new ArrayList();

    String f7707T0 = null;

    String f7713W0 = "";

    private class A implements Animation.AnimationListener {
        private A() {
        }

        @Override // android.view.animation.Animation.AnimationListener
        public void onAnimationEnd(Animation animation) {
            Log.d(MainActivity.f7667X0, "right_Listner==>" + MainActivity.this.f7670B);
            MainActivity mainActivity = MainActivity.this;
            if (!mainActivity.f7670B) {
                mainActivity.f7670B = true;
                return;
            }
            mainActivity.f7694N.setVisibility(4);
            MainActivity.this.f7708U.clearAnimation();
            MainActivity.this.f7670B = false;
        }

        @Override // android.view.animation.Animation.AnimationListener
        public void onAnimationRepeat(Animation animation) {
        }

        @Override // android.view.animation.Animation.AnimationListener
        public void onAnimationStart(Animation animation) {
        }

        /* synthetic */ A(MainActivity mainActivity, k kVar) {
            this();
        }
    }

    public class B extends AsyncTask {

        private String f7744a;

        private String f7745b;

        private Void[] f7746c;

        public B(String str, String str2) {
            this.f7744a = str;
            this.f7745b = str2;
        }

        @Override // android.os.AsyncTask
        public String doInBackground(Void... voidArr) {
            this.f7746c = voidArr;
            return new i2.a().a(this.f7744a, MainActivity.this.O(), MainActivity.this.f7834v);
        }

        @Override // android.os.AsyncTask
        public void onPostExecute(String str) {
            super.onPostExecute(str);
            MainActivity.this.x0(str);
        }
    }

    private class C extends AsyncTask {

        private String f7748a;

        private String f7749b;

        public C(String str, String str2) {
            this.f7748a = str;
            this.f7749b = str2;
        }

        @Override // android.os.AsyncTask
        public Void doInBackground(String... strArr) {
            StringBuilder sb = new StringBuilder();
            sb.append(MainActivity.this.getFilesDir());
            String str = File.separator;
            sb.append(str);
            sb.append(MainActivity.this.f7830A);
            String string = sb.toString();
            File file = new File(string);
            if (!file.exists()) {
                file.mkdir();
            }
            String str2 = string + str + "intro.png";
            try {
                HttpURLConnection httpURLConnection = (HttpURLConnection) new URL(this.f7749b).openConnection();
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
            super.onPostExecute(r3);
        }
    }

    class RunnableC0257a implements Runnable {

        final /* synthetic */ JSONObject f7751a;

        RunnableC0257a(JSONObject jSONObject) {
            this.f7751a = jSONObject;
        }

        @Override // java.lang.Runnable
        public void run() {
            String str;
            String str2;
            String str3;
            String string;
            String string2;
            String string3;
            boolean z2;
            JSONObject jSONObject;
            String str4;
            boolean z3;
            boolean z4;
            String str5;
            MainActivity mainActivity = MainActivity.this;
            mainActivity.f7676E = false;
            mainActivity.f7670B = false;
            mainActivity.Z0();
            try {
                JSONObject jSONObject2 = this.f7751a.getJSONObject("config");
                jSONObject2.getString("show");
                String string4 = jSONObject2.getString("align");
                String string5 = jSONObject2.getString("url");
                Log.d(MainActivity.f7667X0, "translateInRightAnim==>" + MainActivity.this.f7670B);
                String string6 = !jSONObject2.isNull("header") ? jSONObject2.getString("header") : "null";
                String string7 = !jSONObject2.isNull("footer") ? jSONObject2.getString("footer") : "null";
                if (jSONObject2.isNull("setting") || jSONObject2.getJSONObject("setting").isNull("gesture")) {
                    MainActivity.this.f7724h0 = true;
                } else {
                    MainActivity.this.f7724h0 = jSONObject2.getJSONObject("setting").getBoolean("gesture");
                }
                MainActivity.this.f7672C = string4;
                if (string4.equals("left")) {
                    MainActivity.this.f7694N.setGravity(3);
                    ViewGroup.LayoutParams layoutParams = MainActivity.this.f7708U.getLayoutParams();
                    MainActivity mainActivity2 = MainActivity.this;
                    str = "left";
                    str2 = "footer";
                    layoutParams.width = (int) (((double) mainActivity2.f7733q0) * 0.8d);
                    layoutParams.height = -1;
                    mainActivity2.f7708U.setLayoutParams(layoutParams);
                    MainActivity mainActivity3 = MainActivity.this;
                    if (!mainActivity3.f7670B) {
                        mainActivity3.f7694N.setVisibility(0);
                        MainActivity mainActivity4 = MainActivity.this;
                        mainActivity4.f7694N.startAnimation(mainActivity4.f7727k0);
                    }
                    str3 = "right";
                } else {
                    str = "left";
                    str2 = "footer";
                    if (!string4.equals("right")) {
                        str3 = "right";
                        if (string4.equals("center")) {
                            MainActivity.this.f7694N.setGravity(17);
                            ViewGroup.LayoutParams layoutParams2 = MainActivity.this.f7708U.getLayoutParams();
                            MainActivity mainActivity5 = MainActivity.this;
                            layoutParams2.width = (int) (((double) mainActivity5.f7733q0) * 0.8d);
                            layoutParams2.height = (int) (((double) mainActivity5.f7734r0) * 0.8d);
                            mainActivity5.f7708U.setLayoutParams(layoutParams2);
                            MainActivity mainActivity6 = MainActivity.this;
                            mainActivity6.f7670B = true;
                            mainActivity6.f7694N.clearAnimation();
                            MainActivity.this.f7694N.setVisibility(0);
                        } else if (string4.equals("full")) {
                            MainActivity.this.f7694N.setGravity(17);
                            ViewGroup.LayoutParams layoutParams3 = MainActivity.this.f7708U.getLayoutParams();
                            layoutParams3.width = -1;
                            layoutParams3.height = -1;
                            MainActivity.this.f7708U.setLayoutParams(layoutParams3);
                            MainActivity mainActivity7 = MainActivity.this;
                            mainActivity7.f7670B = true;
                            mainActivity7.f7694N.clearAnimation();
                            MainActivity.this.f7694N.setVisibility(0);
                        } else if (string4.equals("top")) {
                            MainActivity.this.f7694N.setGravity(49);
                            ViewGroup.LayoutParams layoutParams4 = MainActivity.this.f7708U.getLayoutParams();
                            layoutParams4.width = -1;
                            MainActivity mainActivity8 = MainActivity.this;
                            layoutParams4.height = (int) (((double) mainActivity8.f7734r0) * 0.8d);
                            mainActivity8.f7708U.setLayoutParams(layoutParams4);
                            MainActivity mainActivity9 = MainActivity.this;
                            if (!mainActivity9.f7670B) {
                                mainActivity9.f7694N.setVisibility(0);
                                MainActivity mainActivity10 = MainActivity.this;
                                mainActivity10.f7708U.startAnimation(mainActivity10.f7725i0);
                            }
                        } else if (string4.equals("bottom")) {
                            MainActivity.this.f7694N.setGravity(81);
                            ViewGroup.LayoutParams layoutParams5 = MainActivity.this.f7708U.getLayoutParams();
                            layoutParams5.width = -1;
                            MainActivity mainActivity11 = MainActivity.this;
                            layoutParams5.height = (int) (((double) mainActivity11.f7734r0) * 0.8d);
                            mainActivity11.f7708U.setLayoutParams(layoutParams5);
                            MainActivity mainActivity12 = MainActivity.this;
                            if (!mainActivity12.f7670B) {
                                mainActivity12.f7694N.setVisibility(0);
                                MainActivity mainActivity13 = MainActivity.this;
                                mainActivity13.f7708U.startAnimation(mainActivity13.f7726j0);
                            }
                        }
                        MainActivity.this.f7696O.setVisibility(8);
                        if (jSONObject2.isNull("header")) {
                            MainActivity.this.i1(string4, string6, string7, false);
                        } else {
                            string = jSONObject2.getJSONObject("header").getString("bgImage");
                            string2 = jSONObject2.getJSONObject("header").getString("bgColor");
                            string3 = jSONObject2.getJSONObject("header").getString("border");
                            if (string2.equals("null")) {
                                MainActivity.this.f7677E0.setColor(Color.parseColor("#ffffff"));
                            } else {
                                if (string2.equals("transparent")) {
                                    MainActivity.this.f7677E0.setColor(Color.parseColor("#00000000"));
                                    z2 = true;
                                } else {
                                    MainActivity.this.f7677E0.setColor(Color.parseColor(string2));
                                }
                                MainActivity.this.i1(string4, string6, string7, z2);
                                if (!string.equals("null")) {
                                    MainActivity.this.g1(string);
                                }
                                if (string3.equals("null")) {
                                    MainActivity.this.f7677E0.setStroke(0, Color.parseColor("#ffffff"));
                                } else {
                                    MainActivity mainActivity14 = MainActivity.this;
                                    MainActivity.this.f7677E0.setStroke(mainActivity14.N(mainActivity14.f7831s, Integer.parseInt(string3)), Color.parseColor("#000000"));
                                }
                                if (string4.equals("full")) {
                                    MainActivity.this.f7710V.setVisibility(0);
                                    MainActivity.this.f7712W.setVisibility(8);
                                    MainActivity mainActivity15 = MainActivity.this;
                                    mainActivity15.f7704S.setBackground(mainActivity15.getDrawable(c.f7357b));
                                } else {
                                    MainActivity.this.f7710V.setVisibility(8);
                                    MainActivity.this.f7712W.setVisibility(8);
                                    MainActivity mainActivity16 = MainActivity.this;
                                    mainActivity16.f7704S.setBackgroundColor(mainActivity16.getColor(android.R.color.transparent));
                                }
                                jSONObject = jSONObject2.getJSONObject("header").getJSONObject("menu");
                                str4 = str;
                                if (!jSONObject.isNull(str4) || jSONObject.getJSONArray(str4).length() <= 0) {
                                    MainActivity.this.f7702R.setVisibility(8);
                                    z3 = false;
                                } else {
                                    MainActivity.this.f7702R.setVisibility(0);
                                    MainActivity.this.f7702R.removeAllViewsInLayout();
                                    MainActivity mainActivity17 = MainActivity.this;
                                    mainActivity17.I0(mainActivity17.f7702R, jSONObject.getJSONArray(str4), "popup_left");
                                    z3 = true;
                                }
                                if (!jSONObject.isNull("center") || jSONObject.getJSONArray("center").length() <= 0) {
                                    MainActivity.this.f7704S.setVisibility(8);
                                } else {
                                    MainActivity.this.f7704S.setVisibility(0);
                                    MainActivity.this.f7704S.removeAllViewsInLayout();
                                    if (string4.equals("full")) {
                                        MainActivity mainActivity18 = MainActivity.this;
                                        mainActivity18.I0(mainActivity18.f7704S, jSONObject.getJSONArray("center"), "popup_full");
                                    } else {
                                        MainActivity mainActivity19 = MainActivity.this;
                                        mainActivity19.I0(mainActivity19.f7704S, jSONObject.getJSONArray("center"), "popup_center");
                                    }
                                    z3 = true;
                                }
                                if (!jSONObject.isNull(str3) || jSONObject.getJSONArray(str3).length() <= 0) {
                                    MainActivity.this.f7706T.setVisibility(8);
                                    z4 = z3;
                                } else {
                                    MainActivity.this.f7706T.setVisibility(0);
                                    MainActivity.this.f7706T.removeAllViewsInLayout();
                                    MainActivity mainActivity20 = MainActivity.this;
                                    mainActivity20.I0(mainActivity20.f7706T, jSONObject.getJSONArray(str3), "popup_right");
                                    z4 = true;
                                }
                                if (z4) {
                                    MainActivity.this.f7696O.setVisibility(0);
                                }
                            }
                            z2 = false;
                            MainActivity.this.i1(string4, string6, string7, z2);
                            if (!string.equals("null")) {
                                MainActivity.this.g1(string);
                            }
                            if (string3.equals("null")) {
                                MainActivity.this.f7677E0.setStroke(0, Color.parseColor("#ffffff"));
                            } else {
                                MainActivity mainActivity110 = MainActivity.this;
                                MainActivity.this.f7677E0.setStroke(mainActivity110.N(mainActivity110.f7831s, Integer.parseInt(string3)), Color.parseColor("#000000"));
                            }
                            if (string4.equals("full")) {
                                MainActivity.this.f7710V.setVisibility(0);
                                MainActivity.this.f7712W.setVisibility(8);
                                MainActivity mainActivity111 = MainActivity.this;
                                mainActivity111.f7704S.setBackground(mainActivity111.getDrawable(c.f7357b));
                            } else {
                                MainActivity.this.f7710V.setVisibility(8);
                                MainActivity.this.f7712W.setVisibility(8);
                                MainActivity mainActivity112 = MainActivity.this;
                                mainActivity112.f7704S.setBackgroundColor(mainActivity112.getColor(android.R.color.transparent));
                            }
                            jSONObject = jSONObject2.getJSONObject("header").getJSONObject("menu");
                            str4 = str;
                            if (jSONObject.isNull(str4)) {
                                MainActivity.this.f7702R.setVisibility(8);
                                z3 = false;
                            } else {
                                MainActivity.this.f7702R.setVisibility(8);
                                z3 = false;
                            }
                            if (jSONObject.isNull("center")) {
                                MainActivity.this.f7704S.setVisibility(8);
                            } else {
                                MainActivity.this.f7704S.setVisibility(8);
                            }
                            if (jSONObject.isNull(str3)) {
                                MainActivity.this.f7706T.setVisibility(8);
                                z4 = z3;
                            } else {
                                MainActivity.this.f7706T.setVisibility(8);
                                z4 = z3;
                            }
                            if (z4) {
                                MainActivity.this.f7696O.setVisibility(0);
                            }
                        }
                        str5 = str2;
                        if (jSONObject2.isNull(str5)) {
                            MainActivity.this.f7700Q.setVisibility(8);
                        } else {
                            MainActivity.this.f7700Q.setVisibility(0);
                            MainActivity.this.L0(jSONObject2.getJSONObject(str5));
                        }
                        Log.d(MainActivity.f7667X0, "createWebviewPopup url 호출==>>>> " + string5);
                        MainActivity.this.f7714X.loadUrl("javascript:document.clear();document.open();document.close();");
                        MainActivity.this.c1(string5);
                    }
                    MainActivity.this.f7694N.setGravity(5);
                    ViewGroup.LayoutParams layoutParams6 = MainActivity.this.f7708U.getLayoutParams();
                    MainActivity mainActivity21 = MainActivity.this;
                    str3 = "right";
                    layoutParams6.width = (int) (((double) mainActivity21.f7733q0) * 0.8d);
                    layoutParams6.height = -1;
                    mainActivity21.f7708U.setLayoutParams(layoutParams6);
                    MainActivity mainActivity22 = MainActivity.this;
                    if (!mainActivity22.f7670B) {
                        mainActivity22.f7694N.setVisibility(0);
                        MainActivity mainActivity23 = MainActivity.this;
                        mainActivity23.f7708U.startAnimation(mainActivity23.f7728l0);
                    }
                }
                MainActivity.this.f7696O.setVisibility(8);
                if (jSONObject2.isNull("header")) {
                    MainActivity.this.i1(string4, string6, string7, false);
                } else {
                    string = jSONObject2.getJSONObject("header").getString("bgImage");
                    string2 = jSONObject2.getJSONObject("header").getString("bgColor");
                    string3 = jSONObject2.getJSONObject("header").getString("border");
                    if (string2.equals("null")) {
                        MainActivity.this.f7677E0.setColor(Color.parseColor("#ffffff"));
                    } else {
                        if (string2.equals("transparent")) {
                            MainActivity.this.f7677E0.setColor(Color.parseColor("#00000000"));
                            z2 = true;
                        } else {
                            MainActivity.this.f7677E0.setColor(Color.parseColor(string2));
                        }
                        MainActivity.this.i1(string4, string6, string7, z2);
                        if (!string.equals("null")) {
                            MainActivity.this.g1(string);
                        }
                        if (string3.equals("null")) {
                            MainActivity.this.f7677E0.setStroke(0, Color.parseColor("#ffffff"));
                        } else {
                            MainActivity mainActivity113 = MainActivity.this;
                            MainActivity.this.f7677E0.setStroke(mainActivity113.N(mainActivity113.f7831s, Integer.parseInt(string3)), Color.parseColor("#000000"));
                        }
                        if (string4.equals("full")) {
                            MainActivity.this.f7710V.setVisibility(0);
                            MainActivity.this.f7712W.setVisibility(8);
                            MainActivity mainActivity114 = MainActivity.this;
                            mainActivity114.f7704S.setBackground(mainActivity114.getDrawable(c.f7357b));
                        } else {
                            MainActivity.this.f7710V.setVisibility(8);
                            MainActivity.this.f7712W.setVisibility(8);
                            MainActivity mainActivity115 = MainActivity.this;
                            mainActivity115.f7704S.setBackgroundColor(mainActivity115.getColor(android.R.color.transparent));
                        }
                        jSONObject = jSONObject2.getJSONObject("header").getJSONObject("menu");
                        str4 = str;
                        if (jSONObject.isNull(str4)) {
                            MainActivity.this.f7702R.setVisibility(8);
                            z3 = false;
                        } else {
                            MainActivity.this.f7702R.setVisibility(8);
                            z3 = false;
                        }
                        if (jSONObject.isNull("center")) {
                            MainActivity.this.f7704S.setVisibility(8);
                        } else {
                            MainActivity.this.f7704S.setVisibility(8);
                        }
                        if (jSONObject.isNull(str3)) {
                            MainActivity.this.f7706T.setVisibility(8);
                            z4 = z3;
                        } else {
                            MainActivity.this.f7706T.setVisibility(8);
                            z4 = z3;
                        }
                        if (z4) {
                            MainActivity.this.f7696O.setVisibility(0);
                        }
                    }
                    z2 = false;
                    MainActivity.this.i1(string4, string6, string7, z2);
                    if (!string.equals("null")) {
                        MainActivity.this.g1(string);
                    }
                    if (string3.equals("null")) {
                        MainActivity.this.f7677E0.setStroke(0, Color.parseColor("#ffffff"));
                    } else {
                        MainActivity mainActivity116 = MainActivity.this;
                        MainActivity.this.f7677E0.setStroke(mainActivity116.N(mainActivity116.f7831s, Integer.parseInt(string3)), Color.parseColor("#000000"));
                    }
                    if (string4.equals("full")) {
                        MainActivity.this.f7710V.setVisibility(0);
                        MainActivity.this.f7712W.setVisibility(8);
                        MainActivity mainActivity117 = MainActivity.this;
                        mainActivity117.f7704S.setBackground(mainActivity117.getDrawable(c.f7357b));
                    } else {
                        MainActivity.this.f7710V.setVisibility(8);
                        MainActivity.this.f7712W.setVisibility(8);
                        MainActivity mainActivity118 = MainActivity.this;
                        mainActivity118.f7704S.setBackgroundColor(mainActivity118.getColor(android.R.color.transparent));
                    }
                    jSONObject = jSONObject2.getJSONObject("header").getJSONObject("menu");
                    str4 = str;
                    if (jSONObject.isNull(str4)) {
                        MainActivity.this.f7702R.setVisibility(8);
                        z3 = false;
                    } else {
                        MainActivity.this.f7702R.setVisibility(8);
                        z3 = false;
                    }
                    if (jSONObject.isNull("center")) {
                        MainActivity.this.f7704S.setVisibility(8);
                    } else {
                        MainActivity.this.f7704S.setVisibility(8);
                    }
                    if (jSONObject.isNull(str3)) {
                        MainActivity.this.f7706T.setVisibility(8);
                        z4 = z3;
                    } else {
                        MainActivity.this.f7706T.setVisibility(8);
                        z4 = z3;
                    }
                    if (z4) {
                        MainActivity.this.f7696O.setVisibility(0);
                    }
                }
                str5 = str2;
                if (jSONObject2.isNull(str5)) {
                    MainActivity.this.f7700Q.setVisibility(8);
                } else {
                    MainActivity.this.f7700Q.setVisibility(0);
                    MainActivity.this.L0(jSONObject2.getJSONObject(str5));
                }
                Log.d(MainActivity.f7667X0, "createWebviewPopup url 호출==>>>> " + string5);
                MainActivity.this.f7714X.loadUrl("javascript:document.clear();document.open();document.close();");
                MainActivity.this.c1(string5);
            } catch (Exception e3) {
                e3.printStackTrace();
            }
        }
    }

    class ViewOnClickListenerC0258b implements View.OnClickListener {

        final /* synthetic */ JSONObject f7753b;

        final /* synthetic */ String f7754c;

        ViewOnClickListenerC0258b(JSONObject jSONObject, String str) {
            this.f7753b = jSONObject;
            this.f7754c = str;
        }

        @Override // android.view.View.OnClickListener
        public void onClick(View view) {
            MainActivity.this.x0(this.f7753b.toString());
            if (this.f7754c.equals("dialog")) {
                MainActivity.this.f7832t.cancel();
            }
        }
    }

    class RunnableC0259c implements Runnable {
        RunnableC0259c() {
        }

        @Override // java.lang.Runnable
        public void run() {
            byte b3;
            Log.d(MainActivity.f7667X0, "closePopupWebview===>" + MainActivity.this.f7672C);
            MainActivity mainActivity = MainActivity.this;
            if (!mainActivity.f7670B) {
                mainActivity.f7694N.setVisibility(8);
                return;
            }
            switch (mainActivity.f7672C) {
                case "bottom":
                    b3 = 3;
                    break;
                case "center":
                    b3 = 5;
                    break;
                case "top":
                    b3 = 2;
                    break;
                case "full":
                    b3 = 4;
                    break;
                case "left":
                    b3 = 0;
                    break;
                case "right":
                    b3 = 1;
                    break;
                default:
                    b3 = -1;
                    break;
            }
            if (b3 == 0) {
                MainActivity mainActivity2 = MainActivity.this;
                mainActivity2.f7708U.startAnimation(mainActivity2.f7731o0);
                return;
            }
            if (b3 == 1) {
                MainActivity mainActivity3 = MainActivity.this;
                mainActivity3.f7708U.startAnimation(mainActivity3.f7732p0);
            } else if (b3 == 2) {
                MainActivity mainActivity4 = MainActivity.this;
                mainActivity4.f7708U.startAnimation(mainActivity4.f7729m0);
            } else if (b3 != 3) {
                MainActivity.this.f7694N.setVisibility(8);
                MainActivity.this.f7670B = false;
            } else {
                MainActivity mainActivity5 = MainActivity.this;
                mainActivity5.f7708U.startAnimation(mainActivity5.f7730n0);
            }
        }
    }

    class d extends Thread {

        final /* synthetic */ String f7757a;

        d(String str) {
            this.f7757a = str;
        }

        @Override // java.lang.Thread, java.lang.Runnable
        public void run() {
            try {
                HttpURLConnection httpURLConnection = (HttpURLConnection) new URL(this.f7757a).openConnection();
                httpURLConnection.setDoInput(true);
                httpURLConnection.connect();
                InputStream inputStream = httpURLConnection.getInputStream();
                MainActivity.this.f7721e0 = BitmapFactory.decodeStream(inputStream);
            } catch (Exception e3) {
                e3.printStackTrace();
            }
        }
    }

    class e extends Thread {

        final /* synthetic */ String f7759a;

        e(String str) {
            this.f7759a = str;
        }

        @Override // java.lang.Thread, java.lang.Runnable
        public void run() {
            try {
                HttpURLConnection httpURLConnection = (HttpURLConnection) new URL(this.f7759a).openConnection();
                httpURLConnection.setDoInput(true);
                httpURLConnection.connect();
                InputStream inputStream = httpURLConnection.getInputStream();
                MainActivity.this.f7721e0 = BitmapFactory.decodeStream(inputStream);
            } catch (Exception e3) {
                e3.printStackTrace();
            }
        }
    }

    class f extends WebChromeClient {

        class a implements DialogInterface.OnClickListener {

            final /* synthetic */ JsResult f7762b;

            a(JsResult jsResult) {
                this.f7762b = jsResult;
            }

            @Override // android.content.DialogInterface.OnClickListener
            public void onClick(DialogInterface dialogInterface, int i3) {
                this.f7762b.confirm();
            }
        }

        class b implements DialogInterface.OnClickListener {

            final /* synthetic */ JsResult f7764b;

            b(JsResult jsResult) {
                this.f7764b = jsResult;
            }

            @Override // android.content.DialogInterface.OnClickListener
            public void onClick(DialogInterface dialogInterface, int i3) {
                this.f7764b.cancel();
            }
        }

        class c implements DialogInterface.OnClickListener {

            final /* synthetic */ JsResult f7766b;

            c(JsResult jsResult) {
                this.f7766b = jsResult;
            }

            @Override // android.content.DialogInterface.OnClickListener
            public void onClick(DialogInterface dialogInterface, int i3) {
                this.f7766b.confirm();
            }
        }

        f() {
        }

        @Override // android.webkit.WebChromeClient
        public boolean onJsAlert(WebView webView, String str, String str2, JsResult jsResult) {
            new androidx.appcompat.app.b.a(webView.getContext()).m("").g(str2).j(android.R.string.ok, new a(jsResult)).d(false).a().show();
            return true;
        }

        @Override // android.webkit.WebChromeClient
        public boolean onJsConfirm(WebView webView, String str, String str2, JsResult jsResult) {
            new androidx.appcompat.app.b.a(webView.getContext()).m("").g(str2).j(android.R.string.ok, new c(jsResult)).h(android.R.string.cancel, new b(jsResult)).a().show();
            return true;
        }
    }

    class g extends WebChromeClient {
        g() {
        }

        @Override // android.webkit.WebChromeClient
        public boolean onConsoleMessage(ConsoleMessage consoleMessage) {
            Log.d(MainActivity.f7667X0, consoleMessage.message() + '\n' + consoleMessage.messageLevel() + '\n' + consoleMessage.sourceId());
            return super.onConsoleMessage(consoleMessage);
        }
    }

    class h {
        h() {
        }

        @JavascriptInterface
        public void addressSave(String str) {
            Intent intent = new Intent("android.intent.action.INSERT");
            intent.setType("vnd.android.cursor.dir/raw_contact");
            intent.putExtra("phone", str).putExtra("phone_type", 3);
            MainActivity.this.startActivity(intent);
        }

        @JavascriptInterface
        public void allytteCommandHandler(String str) {
            Log.d(MainActivity.f7667X0, "Keyword is ====>" + str);
            MainActivity.this.x0(str);
        }
    }

    class i extends WebViewClient {
        i() {
        }

        @Override // android.webkit.WebViewClient
        public void onPageFinished(WebView webView, String str) {
            super.onPageFinished(webView, str);
            MainActivity.this.S();
        }

        @Override // android.webkit.WebViewClient
        public void onPageStarted(WebView webView, String str, Bitmap bitmap) {
            super.onPageStarted(webView, str, bitmap);
            MainActivity.this.b0();
        }

        @Override // android.webkit.WebViewClient
        public boolean shouldOverrideUrlLoading(WebView webView, String str) {
            Intent intent = new Intent("android.intent.action.VIEW", Uri.parse(str));
            intent.addCategory("android.intent.category.BROWSABLE");
            intent.putExtra("com.android.browser.application_id", MainActivity.this.getPackageName());
            if (str.startsWith("sms:")) {
                MainActivity.this.startActivity(new Intent("android.intent.action.SENDTO", Uri.parse(str)));
                return true;
            }
            if (str.startsWith("tel:")) {
                MainActivity.this.startActivity(new Intent("android.intent.action.DIAL", Uri.parse(str)));
                return true;
            }
            if (!str.startsWith("mailto:")) {
                return super.shouldOverrideUrlLoading(webView, str);
            }
            MainActivity.this.startActivity(new Intent("android.intent.action.SENDTO", Uri.parse(str)));
            return true;
        }
    }

    class j implements DownloadListener {
        j() {
        }

        @Override // android.webkit.DownloadListener
        public void onDownloadStart(String str, String str2, String str3, String str4, long j3) {
            try {
                DownloadManager.Request request = new DownloadManager.Request(Uri.parse(str));
                DownloadManager downloadManager = (DownloadManager) MainActivity.this.getSystemService("download");
                String[] strArrSplit = URLDecoder.decode(str3, "UTF-8").replace("attachment; filename=", "").split("=");
                String strReplace = strArrSplit[strArrSplit.length - 1].replace("\"", "").replaceAll("\\p{Z}", "_").replace(";", "");
                request.setMimeType(str4);
                request.addRequestHeader("cookie", CookieManager.getInstance().getCookie(str));
                request.addRequestHeader("User-Agent", str2);
                request.setDescription("Downloading File");
                request.setAllowedOverMetered(true);
                request.setAllowedOverRoaming(true);
                request.setTitle(strReplace);
                if (Build.VERSION.SDK_INT >= 24) {
                    request.setRequiresCharging(false);
                }
                request.allowScanningByMediaScanner();
                request.setAllowedOverMetered(true);
                request.setNotificationVisibility(1);
                request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, strReplace);
                downloadManager.enqueue(request);
                Toast.makeText(MainActivity.this.getApplicationContext(), "파일이 다운로드됩니다.", 1).show();
            } catch (Exception unused) {
                if (b.a(MainActivity.this, "android.permission.WRITE_EXTERNAL_STORAGE") != 0) {
                    if (AbstractC0296a.k(MainActivity.this, "android.permission.WRITE_EXTERNAL_STORAGE")) {
                        Toast.makeText(MainActivity.this.getBaseContext(), "다운로드를 위해\n권한이 필요합니다.", 1).show();
                        AbstractC0296a.j(MainActivity.this, new String[]{"android.permission.WRITE_EXTERNAL_STORAGE"}, 1004);
                    } else {
                        Toast.makeText(MainActivity.this.getBaseContext(), "다운로드를 위해\n권한이 필요합니다.", 1).show();
                        AbstractC0296a.j(MainActivity.this, new String[]{"android.permission.WRITE_EXTERNAL_STORAGE"}, 1004);
                    }
                }
            }
        }
    }

    class k implements View.OnTouchListener {
        k() {
        }

        @Override // android.view.View.OnTouchListener
        public boolean onTouch(View view, MotionEvent motionEvent) {
            return true;
        }
    }

    class l extends WebChromeClient {

        class a implements DialogInterface.OnClickListener {

            final /* synthetic */ JsResult f7774b;

            a(JsResult jsResult) {
                this.f7774b = jsResult;
            }

            @Override // android.content.DialogInterface.OnClickListener
            public void onClick(DialogInterface dialogInterface, int i3) {
                this.f7774b.confirm();
            }
        }

        class b implements DialogInterface.OnKeyListener {

            final /* synthetic */ JsResult f7776b;

            b(JsResult jsResult) {
                this.f7776b = jsResult;
            }

            @Override // android.content.DialogInterface.OnKeyListener
            public boolean onKey(DialogInterface dialogInterface, int i3, KeyEvent keyEvent) {
                if (i3 == 4) {
                    Log.d(MainActivity.f7667X0, "alert====>33333");
                    this.f7776b.confirm();
                }
                return true;
            }
        }

        class c implements DialogInterface.OnClickListener {

            final /* synthetic */ JsResult f7778b;

            c(JsResult jsResult) {
                this.f7778b = jsResult;
            }

            @Override // android.content.DialogInterface.OnClickListener
            public void onClick(DialogInterface dialogInterface, int i3) {
                this.f7778b.cancel();
            }
        }

        class d implements DialogInterface.OnClickListener {

            final /* synthetic */ JsResult f7780b;

            d(JsResult jsResult) {
                this.f7780b = jsResult;
            }

            @Override // android.content.DialogInterface.OnClickListener
            public void onClick(DialogInterface dialogInterface, int i3) {
                this.f7780b.confirm();
            }
        }

        class e implements DownloadListener {
            e() {
            }

            @Override // android.webkit.DownloadListener
            public void onDownloadStart(String str, String str2, String str3, String str4, long j3) {
                try {
                    DownloadManager.Request request = new DownloadManager.Request(Uri.parse(str));
                    DownloadManager downloadManager = (DownloadManager) MainActivity.this.getSystemService("download");
                    String[] strArrSplit = URLDecoder.decode(str3, "UTF-8").replace("attachment; filename=", "").split("=");
                    String strReplace = strArrSplit[strArrSplit.length - 1].replace("\"", "").replaceAll("\\p{Z}", "_").replace(";", "");
                    request.setMimeType(str4);
                    request.addRequestHeader("cookie", CookieManager.getInstance().getCookie(str));
                    request.addRequestHeader("User-Agent", str2);
                    request.setDescription("Downloading File");
                    request.setAllowedOverMetered(true);
                    request.setAllowedOverRoaming(true);
                    request.setTitle(strReplace);
                    if (Build.VERSION.SDK_INT >= 24) {
                        request.setRequiresCharging(false);
                    }
                    request.allowScanningByMediaScanner();
                    request.setAllowedOverMetered(true);
                    request.setNotificationVisibility(1);
                    request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, strReplace);
                    downloadManager.enqueue(request);
                    Toast.makeText(MainActivity.this.getApplicationContext(), "파일이 다운로드됩니다.", 1).show();
                } catch (Exception unused) {
                    if (p063v.b.a(MainActivity.this, "android.permission.WRITE_EXTERNAL_STORAGE") != 0) {
                        if (AbstractC0296a.k(MainActivity.this, "android.permission.WRITE_EXTERNAL_STORAGE")) {
                            Toast.makeText(MainActivity.this.getBaseContext(), "다운로드를 위해\n권한이 필요합니다.", 1).show();
                            AbstractC0296a.j(MainActivity.this, new String[]{"android.permission.WRITE_EXTERNAL_STORAGE"}, 1004);
                        } else {
                            Toast.makeText(MainActivity.this.getBaseContext(), "다운로드를 위해\n권한이 필요합니다.", 1).show();
                            AbstractC0296a.j(MainActivity.this, new String[]{"android.permission.WRITE_EXTERNAL_STORAGE"}, 1004);
                        }
                    }
                }
            }
        }

        class f extends WebChromeClient {

            class a implements DialogInterface.OnClickListener {

                final /* synthetic */ JsResult f7784b;

                a(JsResult jsResult) {
                    this.f7784b = jsResult;
                }

                @Override // android.content.DialogInterface.OnClickListener
                public void onClick(DialogInterface dialogInterface, int i3) {
                    this.f7784b.confirm();
                }
            }

            class b implements DialogInterface.OnKeyListener {

                final /* synthetic */ JsResult f7786b;

                b(JsResult jsResult) {
                    this.f7786b = jsResult;
                }

                @Override // android.content.DialogInterface.OnKeyListener
                public boolean onKey(DialogInterface dialogInterface, int i3, KeyEvent keyEvent) {
                    if (i3 == 4) {
                        Log.d(MainActivity.f7667X0, "alert====>33333");
                        this.f7786b.confirm();
                    }
                    return true;
                }
            }

            class c implements DialogInterface.OnClickListener {

                final /* synthetic */ JsResult f7788b;

                c(JsResult jsResult) {
                    this.f7788b = jsResult;
                }

                @Override // android.content.DialogInterface.OnClickListener
                public void onClick(DialogInterface dialogInterface, int i3) {
                    this.f7788b.cancel();
                }
            }

            class d implements DialogInterface.OnClickListener {

                final /* synthetic */ JsResult f7790b;

                d(JsResult jsResult) {
                    this.f7790b = jsResult;
                }

                @Override // android.content.DialogInterface.OnClickListener
                public void onClick(DialogInterface dialogInterface, int i3) {
                    this.f7790b.confirm();
                }
            }

            class e implements DownloadListener {
                e() {
                }

                @Override // android.webkit.DownloadListener
                public void onDownloadStart(String str, String str2, String str3, String str4, long j3) {
                    try {
                        DownloadManager.Request request = new DownloadManager.Request(Uri.parse(str));
                        DownloadManager downloadManager = (DownloadManager) MainActivity.this.getSystemService("download");
                        String[] strArrSplit = URLDecoder.decode(str3, "UTF-8").replace("attachment; filename=", "").split("=");
                        String strReplace = strArrSplit[strArrSplit.length - 1].replace("\"", "").replaceAll("\\p{Z}", "_").replace(";", "");
                        request.setMimeType(str4);
                        request.addRequestHeader("cookie", CookieManager.getInstance().getCookie(str));
                        request.addRequestHeader("User-Agent", str2);
                        request.setDescription("Downloading File");
                        request.setAllowedOverMetered(true);
                        request.setAllowedOverRoaming(true);
                        request.setTitle(strReplace);
                        if (Build.VERSION.SDK_INT >= 24) {
                            request.setRequiresCharging(false);
                        }
                        request.allowScanningByMediaScanner();
                        request.setAllowedOverMetered(true);
                        request.setNotificationVisibility(1);
                        request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, strReplace);
                        downloadManager.enqueue(request);
                        Toast.makeText(MainActivity.this.getApplicationContext(), "파일이 다운로드됩니다.", 1).show();
                    } catch (Exception unused) {
                        if (p063v.b.a(MainActivity.this, "android.permission.WRITE_EXTERNAL_STORAGE") != 0) {
                            if (AbstractC0296a.k(MainActivity.this, "android.permission.WRITE_EXTERNAL_STORAGE")) {
                                Toast.makeText(MainActivity.this.getBaseContext(), "다운로드를 위해\n권한이 필요합니다.", 1).show();
                                AbstractC0296a.j(MainActivity.this, new String[]{"android.permission.WRITE_EXTERNAL_STORAGE"}, 1004);
                            } else {
                                Toast.makeText(MainActivity.this.getBaseContext(), "다운로드를 위해\n권한이 필요합니다.", 1).show();
                                AbstractC0296a.j(MainActivity.this, new String[]{"android.permission.WRITE_EXTERNAL_STORAGE"}, 1004);
                            }
                        }
                    }
                }
            }

            class C0091f extends WebChromeClient {

                class a implements DialogInterface.OnClickListener {

                    final /* synthetic */ JsResult f7794b;

                    a(JsResult jsResult) {
                        this.f7794b = jsResult;
                    }

                    @Override // android.content.DialogInterface.OnClickListener
                    public void onClick(DialogInterface dialogInterface, int i3) {
                        this.f7794b.confirm();
                    }
                }

                class b implements DialogInterface.OnKeyListener {

                    final /* synthetic */ JsResult f7796b;

                    b(JsResult jsResult) {
                        this.f7796b = jsResult;
                    }

                    @Override // android.content.DialogInterface.OnKeyListener
                    public boolean onKey(DialogInterface dialogInterface, int i3, KeyEvent keyEvent) {
                        if (i3 == 4) {
                            Log.d(MainActivity.f7667X0, "alert====>33333");
                            this.f7796b.confirm();
                        }
                        return true;
                    }
                }

                class c implements DialogInterface.OnClickListener {

                    final /* synthetic */ JsResult f7798b;

                    c(JsResult jsResult) {
                        this.f7798b = jsResult;
                    }

                    @Override // android.content.DialogInterface.OnClickListener
                    public void onClick(DialogInterface dialogInterface, int i3) {
                        this.f7798b.cancel();
                    }
                }

                class d implements DialogInterface.OnClickListener {

                    final /* synthetic */ JsResult f7800b;

                    d(JsResult jsResult) {
                        this.f7800b = jsResult;
                    }

                    @Override // android.content.DialogInterface.OnClickListener
                    public void onClick(DialogInterface dialogInterface, int i3) {
                        this.f7800b.confirm();
                    }
                }

                C0091f() {
                }

                @Override // android.webkit.WebChromeClient
                public void onCloseWindow(WebView webView) {
                    Log.d("확인", "onCreateWindow===>onCloseWindow");
                    MainActivity.f7668Y0.removeView(webView);
                    webView.destroy();
                }

                @Override // android.webkit.WebChromeClient
                public boolean onJsAlert(WebView webView, String str, String str2, JsResult jsResult) {
                    MainActivity.this.S();
                    new androidx.appcompat.app.b.a(MainActivity.this.f7831s).m("").g(str2).i(new b(jsResult)).j(android.R.string.ok, new a(jsResult)).d(false).a().show();
                    return true;
                }

                @Override // android.webkit.WebChromeClient
                public boolean onJsConfirm(WebView webView, String str, String str2, JsResult jsResult) {
                    new androidx.appcompat.app.b.a(MainActivity.this.f7831s).m("").g(str2).j(android.R.string.ok, new d(jsResult)).h(android.R.string.cancel, new c(jsResult)).a().show();
                    return true;
                }
            }

            class g extends WebViewClient {
                g() {
                }

                @Override // android.webkit.WebViewClient
                public void onPageFinished(WebView webView, String str) {
                    super.onPageFinished(webView, str);
                    Log.d(MainActivity.f7667X0, "onCreateWindow===>onPageFinished==>2==>" + str);
                    MainActivity.this.S();
                }

                @Override // android.webkit.WebViewClient
                public void onPageStarted(WebView webView, String str, Bitmap bitmap) {
                    super.onPageStarted(webView, str, bitmap);
                    Log.d(MainActivity.f7667X0, "onCreateWindow===>onPageStarted==>2==>" + str);
                    MainActivity.this.b0();
                }

                @Override // android.webkit.WebViewClient
                public boolean shouldOverrideUrlLoading(WebView webView, String str) {
                    Log.d(MainActivity.f7667X0, "onCreateWindow===>shouldOverrideUrlLoading===>2==>" + str);
                    return false;
                }
            }

            f() {
            }

            @Override // android.webkit.WebChromeClient
            public void onCloseWindow(WebView webView) {
                Log.d("확인", "(webview)onCreateWindow===>onCloseWindow");
                MainActivity.this.f7717a0 = false;
                MainActivity.f7668Y0.removeView(webView);
                MainActivity.this.A0();
            }

            @Override // android.webkit.WebChromeClient
            public boolean onCreateWindow(WebView webView, boolean z2, boolean z3, Message message) {
                MainActivity.this.f7718b0 = true;
                Log.d(MainActivity.f7667X0, "onCreateWindow===>start22222");
                MainActivity.this.f7716Z = new WebView(MainActivity.this.getApplicationContext());
                MainActivity.this.f7716Z.getSettings().setJavaScriptEnabled(true);
                MainActivity.this.f7716Z.getSettings().setDomStorageEnabled(true);
                MainActivity.this.f7716Z.getSettings().setJavaScriptCanOpenWindowsAutomatically(true);
                MainActivity.this.f7716Z.getSettings().setSupportMultipleWindows(true);
                MainActivity.this.f7716Z.getSettings().setAllowFileAccess(true);
                MainActivity.this.f7716Z.getSettings().setAllowContentAccess(true);
                MainActivity.this.f7716Z.getSettings().setAllowFileAccessFromFileURLs(true);
                MainActivity.this.f7716Z.getSettings().setAllowUniversalAccessFromFileURLs(true);
                MainActivity.this.f7716Z.getSettings().setTextZoom(85);
                MainActivity.this.f7716Z.setDownloadListener(new e());
                MainActivity.this.f7716Z.setWebChromeClient(new C0091f());
                MainActivity.this.f7716Z.setWebViewClient(new g());
                MainActivity.this.f7716Z.setLayoutParams(new ConstraintLayout.b(-1, -1));
                MainActivity.f7668Y0.addView(MainActivity.this.f7716Z);
                ((WebView.WebViewTransport) message.obj).setWebView(MainActivity.this.f7716Z);
                message.sendToTarget();
                return true;
            }

            @Override // android.webkit.WebChromeClient
            public boolean onJsAlert(WebView webView, String str, String str2, JsResult jsResult) {
                MainActivity.this.S();
                new androidx.appcompat.app.b.a(MainActivity.this.f7831s).m("").g(str2).i(new b(jsResult)).j(android.R.string.ok, new a(jsResult)).d(false).a().show();
                return true;
            }

            @Override // android.webkit.WebChromeClient
            public boolean onJsConfirm(WebView webView, String str, String str2, JsResult jsResult) {
                new androidx.appcompat.app.b.a(MainActivity.this.f7831s).m("").g(str2).j(android.R.string.ok, new d(jsResult)).h(android.R.string.cancel, new c(jsResult)).a().show();
                return true;
            }

            @Override // android.webkit.WebChromeClient
            public boolean onShowFileChooser(WebView webView, ValueCallback valueCallback, WebChromeClient.FileChooserParams fileChooserParams) {
                MainActivity.this.c0("파일 선택창을 선택하였습니다.");
                MainActivity.this.f7703R0 = valueCallback;
                Intent intent = new Intent("android.intent.action.GET_CONTENT");
                intent.putExtra("android.intent.extra.ALLOW_MULTIPLE", true);
                intent.addCategory("android.intent.category.OPENABLE");
                intent.setType("*/*");
                MainActivity.this.startActivityForResult(Intent.createChooser(intent, "Select Picture"), 1);
                return true;
            }
        }

        class g extends WebViewClient {
            g() {
            }

            @Override // android.webkit.WebViewClient
            public void onPageFinished(WebView webView, String str) {
                super.onPageFinished(webView, str);
                Log.d(MainActivity.f7667X0, "onCreateWindow===>onPageFinished==>1==>" + str);
                if (str.equals("https://tis.ut.ac.kr/main.do")) {
                    MainActivity.this.y0();
                }
                MainActivity.this.S();
            }

            @Override // android.webkit.WebViewClient
            public void onPageStarted(WebView webView, String str, Bitmap bitmap) {
                super.onPageStarted(webView, str, bitmap);
                Log.d(MainActivity.f7667X0, "onCreateWindow===>onPageStarted==>1==>" + str);
                MainActivity.this.b0();
            }

            @Override // android.webkit.WebViewClient
            public boolean shouldOverrideUrlLoading(WebView webView, String str) {
                Log.d(MainActivity.f7667X0, "(Webview)onCreateWindow===>shouldOverrideUrlLoading===>1==>" + str);
                return false;
            }
        }

        l() {
        }

        @Override // android.webkit.WebChromeClient
        public boolean onCreateWindow(WebView webView, boolean z2, boolean z3, Message message) {
            MainActivity.this.f7717a0 = true;
            Log.d(MainActivity.f7667X0, "onCreateWindow===>start");
            MainActivity.this.f7715Y = new WebView(MainActivity.this.getApplicationContext());
            MainActivity.this.f7715Y.getSettings().setJavaScriptEnabled(true);
            MainActivity.this.f7715Y.getSettings().setDomStorageEnabled(true);
            MainActivity.this.f7715Y.getSettings().setJavaScriptCanOpenWindowsAutomatically(true);
            MainActivity.this.f7715Y.getSettings().setSupportMultipleWindows(true);
            MainActivity.this.f7715Y.getSettings().setAllowFileAccess(true);
            MainActivity.this.f7715Y.getSettings().setAllowContentAccess(true);
            MainActivity.this.f7715Y.getSettings().setAllowFileAccessFromFileURLs(true);
            MainActivity.this.f7715Y.getSettings().setAllowUniversalAccessFromFileURLs(true);
            MainActivity.this.f7715Y.getSettings().setTextZoom(85);
            MainActivity.this.f7715Y.setDownloadListener(new e());
            MainActivity.this.f7715Y.setWebChromeClient(new f());
            MainActivity.this.f7715Y.setWebViewClient(new g());
            MainActivity.this.f7715Y.setLayoutParams(new ConstraintLayout.b(-1, -1));
            MainActivity.f7668Y0.addView(MainActivity.this.f7715Y);
            ((WebView.WebViewTransport) message.obj).setWebView(MainActivity.this.f7715Y);
            message.sendToTarget();
            return true;
        }

        @Override // android.webkit.WebChromeClient
        public boolean onJsAlert(WebView webView, String str, String str2, JsResult jsResult) {
            MainActivity.this.S();
            new androidx.appcompat.app.b.a(MainActivity.this.f7831s).m("").g(str2).i(new b(jsResult)).j(android.R.string.ok, new a(jsResult)).d(false).a().show();
            return true;
        }

        @Override // android.webkit.WebChromeClient
        public boolean onJsConfirm(WebView webView, String str, String str2, JsResult jsResult) {
            new androidx.appcompat.app.b.a(MainActivity.this.f7831s).m("").g(str2).j(android.R.string.ok, new d(jsResult)).h(android.R.string.cancel, new c(jsResult)).a().show();
            return true;
        }

        @Override // android.webkit.WebChromeClient
        public boolean onShowFileChooser(WebView webView, ValueCallback valueCallback, WebChromeClient.FileChooserParams fileChooserParams) {
            MainActivity.this.c0("파일 선택창을 선택하였습니다.");
            MainActivity.this.f7703R0 = valueCallback;
            Intent intent = new Intent("android.intent.action.GET_CONTENT");
            intent.putExtra("android.intent.extra.ALLOW_MULTIPLE", true);
            intent.addCategory("android.intent.category.OPENABLE");
            intent.setType("*/*");
            MainActivity.this.startActivityForResult(Intent.createChooser(intent, "Select Picture"), 1);
            return true;
        }
    }

    class m {
        m() {
        }

        @JavascriptInterface
        public void addressSave(String str) {
            Intent intent = new Intent("android.intent.action.INSERT");
            intent.setType("vnd.android.cursor.dir/raw_contact");
            intent.putExtra("phone", str).putExtra("phone_type", 3);
            MainActivity.this.startActivity(intent);
        }

        @JavascriptInterface
        public void allytteCommandHandler(String str) {
            Log.d(MainActivity.f7667X0, "Keyword is ====>" + str);
            MainActivity.this.x0(str);
        }
    }

    class n extends WebViewClient {
        n() {
        }

        @Override // android.webkit.WebViewClient
        public void onPageFinished(WebView webView, String str) {
            super.onPageFinished(webView, str);
            Log.d(MainActivity.f7667X0, "(Webview)onCreateWindow==>onPageFinished");
            MainActivity.this.S();
        }

        @Override // android.webkit.WebViewClient
        public void onPageStarted(WebView webView, String str, Bitmap bitmap) {
            super.onPageStarted(webView, str, bitmap);
            Log.d(MainActivity.f7667X0, "(Webview)onCreateWindow==>onPageStarted");
            MainActivity.this.b0();
        }

        @Override // android.webkit.WebViewClient
        public boolean shouldOverrideUrlLoading(WebView webView, String str) {
            Intent uri;
            Log.d(MainActivity.f7667X0, "(Webview)onCreateWindow==>shouldOverrideUrlLoading");
            if (str.startsWith("intent://")) {
                try {
                    try {
                        uri = Intent.parseUri(str, 1);
                        if (uri != null) {
                            try {
                                MainActivity.this.startActivity(uri);
                            } catch (ActivityNotFoundException unused) {
                                String str2 = uri.getPackage();
                                if (!str2.equals("")) {
                                    MainActivity.this.startActivity(new Intent("android.intent.action.VIEW", Uri.parse("market://details?id=" + str2)));
                                }
                            }
                        }
                    } catch (URISyntaxException unused2) {
                    }
                } catch (ActivityNotFoundException unused3) {
                    uri = null;
                }
                return true;
            }
            if (str.startsWith("https://play.google.com/store/apps/details?id=") || str.startsWith("market://details?id=")) {
                String queryParameter = Uri.parse(str).getQueryParameter("id");
                if (queryParameter != null && !queryParameter.equals("")) {
                    MainActivity.this.startActivity(new Intent("android.intent.action.VIEW", Uri.parse("market://details?id=" + queryParameter)));
                }
                return true;
            }
            if (str.startsWith("sms:")) {
                MainActivity.this.startActivity(new Intent("android.intent.action.SENDTO", Uri.parse(str)));
                return true;
            }
            if (str.startsWith("tel:")) {
                MainActivity.this.startActivity(new Intent("android.intent.action.DIAL", Uri.parse(str)));
                return true;
            }
            if (!str.startsWith("mailto:")) {
                return super.shouldOverrideUrlLoading(webView, str);
            }
            MainActivity.this.startActivity(new Intent("android.intent.action.SENDTO", Uri.parse(str)));
            return true;
        }
    }

    class o implements DialogInterface.OnClickListener {
        o() {
        }

        @Override // android.content.DialogInterface.OnClickListener
        public void onClick(DialogInterface dialogInterface, int i3) {
            MainActivity.this.d0();
        }
    }

    class p implements j2.o {
        p() {
        }

        @Override // j2.o
        public void a(Collection collection, j2.p pVar) {
            if (collection.size() > 0) {
                Iterator it = collection.iterator();
                while (it.hasNext()) {
                    MainActivity.this.f7701Q0.add((j2.e) it.next());
                }
            }
            Log.d(MainActivity.f7667X0, "Beacon count=1111=====>" + collection.size());
        }
    }

    class q implements View.OnClickListener {
        q() {
        }

        @Override // android.view.View.OnClickListener
        public void onClick(View view) {
            MainActivity.this.f7832t.cancel();
        }
    }

    class r implements View.OnClickListener {
        r() {
        }

        @Override // android.view.View.OnClickListener
        public void onClick(View view) {
            MainActivity.this.f7832t.cancel();
        }
    }

    class s implements Runnable {
        s() {
        }

        @Override // java.lang.Runnable
        public void run() {
            NfcAdapter defaultAdapter = ((NfcManager) MainActivity.this.f7831s.getSystemService("nfc")).getDefaultAdapter();
            if (defaultAdapter != null && defaultAdapter.isEnabled()) {
                MainActivity.this.K0();
            } else {
                MainActivity mainActivity = MainActivity.this;
                mainActivity.Q0(mainActivity.getString(h2.f.f7393b));
            }
        }
    }

    class t implements Runnable {
        t() {
        }

        @Override // java.lang.Runnable
        public void run() {
            MainActivity.this.z0();
        }
    }

    class u implements Runnable {

        final /* synthetic */ String f7812a;

        final /* synthetic */ Map f7813b;

        u(String str, Map map) {
            this.f7812a = str;
            this.f7813b = map;
        }

        @Override // java.lang.Runnable
        public void run() {
            MainActivity.this.f7714X.loadUrl(this.f7812a, this.f7813b);
        }
    }

    class v implements Runnable {

        final /* synthetic */ String f7815a;

        final /* synthetic */ Map f7816b;

        v(String str, Map map) {
            this.f7815a = str;
            this.f7816b = map;
        }

        @Override // java.lang.Runnable
        public void run() {
            MainActivity.this.f7692M.loadUrl(this.f7815a, this.f7816b);
        }
    }

    class w implements Runnable {

        final /* synthetic */ JSONObject f7818a;

        w(JSONObject jSONObject) {
            this.f7818a = jSONObject;
        }

        @Override // java.lang.Runnable
        public void run() {
            MainActivity mainActivity = MainActivity.this;
            mainActivity.f7676E = true;
            if (mainActivity.f7670B) {
                mainActivity.A0();
            }
            MainActivity.this.f7694N.clearAnimation();
            try {
                JSONObject jSONObject = this.f7818a.getJSONObject("config");
                jSONObject.getString("show");
                jSONObject.getString("align");
                String string = jSONObject.getString("url");
                if (jSONObject.isNull("setting") || jSONObject.getJSONObject("setting").isNull("gesture")) {
                    MainActivity.this.f7724h0 = true;
                } else {
                    MainActivity.this.f7724h0 = jSONObject.getJSONObject("setting").getBoolean("gesture");
                }
                Log.d(MainActivity.f7667X0, "gesture_ok1111==>" + MainActivity.this.f7724h0);
                if (jSONObject.isNull("header")) {
                    MainActivity.this.f7684I.setVisibility(8);
                } else {
                    MainActivity.this.f7684I.setVisibility(0);
                    String string2 = jSONObject.getJSONObject("header").getString("bgImage");
                    String string3 = jSONObject.getJSONObject("header").getString("bgColor");
                    String string4 = jSONObject.getJSONObject("header").getString("border");
                    if (string3.equals("null")) {
                        MainActivity.this.f7741y0.setColor(Color.parseColor("#ffffff"));
                    } else if (string3.equals("transparent")) {
                        MainActivity.this.f7741y0.setColor(Color.parseColor("#00000000"));
                    } else {
                        MainActivity.this.f7741y0.setColor(Color.parseColor(string3));
                    }
                    if (!string2.equals("null")) {
                        MainActivity.this.g1(string2);
                    }
                    if (string4.equals("null")) {
                        MainActivity.this.f7741y0.setStroke(0, Color.parseColor("#ffffff"));
                    } else {
                        MainActivity mainActivity2 = MainActivity.this;
                        MainActivity.this.f7741y0.setStroke(mainActivity2.N(mainActivity2.f7831s, Integer.parseInt(string4)), Color.parseColor("#000000"));
                    }
                    MainActivity.this.f7684I.setVisibility(0);
                    JSONObject jSONObject2 = jSONObject.getJSONObject("header").getJSONObject("menu");
                    if (jSONObject2.isNull("left")) {
                        MainActivity.this.f7686J.setVisibility(8);
                    } else {
                        MainActivity.this.f7686J.setVisibility(0);
                        MainActivity.this.f7686J.removeAllViewsInLayout();
                        if (jSONObject2.getJSONObject("left") instanceof JSONObject) {
                            MainActivity mainActivity3 = MainActivity.this;
                            mainActivity3.J0(mainActivity3.f7686J, jSONObject2.getJSONObject("left"), "main_left");
                        } else {
                            MainActivity mainActivity4 = MainActivity.this;
                            mainActivity4.I0(mainActivity4.f7686J, jSONObject2.getJSONArray("left"), "main_left");
                        }
                    }
                    if (jSONObject2.isNull("center")) {
                        MainActivity.this.f7688K.setVisibility(8);
                    } else {
                        MainActivity.this.f7688K.setVisibility(0);
                        MainActivity.this.f7688K.removeAllViewsInLayout();
                        if (jSONObject2.getJSONObject("center") instanceof JSONObject) {
                            MainActivity mainActivity5 = MainActivity.this;
                            mainActivity5.J0(mainActivity5.f7688K, jSONObject2.getJSONObject("center"), "main_center");
                        } else {
                            MainActivity mainActivity6 = MainActivity.this;
                            mainActivity6.I0(mainActivity6.f7688K, jSONObject2.getJSONArray("center"), "main_center");
                        }
                    }
                    if (jSONObject2.isNull("right")) {
                        MainActivity.this.f7690L.setVisibility(8);
                    } else {
                        MainActivity.this.f7690L.setVisibility(0);
                        MainActivity.this.f7690L.removeAllViewsInLayout();
                        if (jSONObject2.getJSONObject("right") instanceof JSONObject) {
                            MainActivity mainActivity7 = MainActivity.this;
                            mainActivity7.J0(mainActivity7.f7690L, jSONObject2.getJSONObject("right"), "main_right");
                        } else {
                            MainActivity mainActivity8 = MainActivity.this;
                            mainActivity8.I0(mainActivity8.f7690L, jSONObject2.getJSONArray("right"), "main_right");
                        }
                    }
                }
                if (jSONObject.isNull("footer")) {
                    MainActivity.this.f7719c0.setVisibility(8);
                    MainActivity.this.f7720d0.setVisibility(8);
                } else {
                    MainActivity.this.f7719c0.setVisibility(0);
                    MainActivity.this.f7720d0.setVisibility(0);
                    MainActivity.this.H0(jSONObject.getJSONObject("footer"));
                }
                MainActivity.this.B0(string);
            } catch (Exception e3) {
                e3.printStackTrace();
            }
        }
    }

    private class x implements Animation.AnimationListener {
        private x() {
        }

        @Override // android.view.animation.Animation.AnimationListener
        public void onAnimationEnd(Animation animation) {
            Log.d(MainActivity.f7667X0, "right_Listner==>" + MainActivity.this.f7670B);
            MainActivity mainActivity = MainActivity.this;
            if (!mainActivity.f7670B) {
                mainActivity.f7670B = true;
                return;
            }
            mainActivity.f7694N.setVisibility(4);
            MainActivity.this.f7708U.clearAnimation();
            MainActivity.this.f7670B = false;
        }

        @Override // android.view.animation.Animation.AnimationListener
        public void onAnimationRepeat(Animation animation) {
        }

        @Override // android.view.animation.Animation.AnimationListener
        public void onAnimationStart(Animation animation) {
        }

        /* synthetic */ x(MainActivity mainActivity, k kVar) {
            this();
        }
    }

    private class y implements Animation.AnimationListener {
        private y() {
        }

        @Override // android.view.animation.Animation.AnimationListener
        public void onAnimationEnd(Animation animation) {
            MainActivity.this.R("device", "webview");
            Log.d(MainActivity.f7667X0, "left_Listner" + MainActivity.this.f7670B);
            MainActivity mainActivity = MainActivity.this;
            if (!mainActivity.f7670B) {
                mainActivity.f7670B = true;
                return;
            }
            mainActivity.f7694N.setVisibility(4);
            MainActivity.this.f7708U.clearAnimation();
            MainActivity.this.f7670B = false;
        }

        @Override // android.view.animation.Animation.AnimationListener
        public void onAnimationRepeat(Animation animation) {
        }

        @Override // android.view.animation.Animation.AnimationListener
        public void onAnimationStart(Animation animation) {
        }

        /* synthetic */ y(MainActivity mainActivity, k kVar) {
            this();
        }
    }

    private class z implements Animation.AnimationListener {
        private z() {
        }

        @Override // android.view.animation.Animation.AnimationListener
        public void onAnimationEnd(Animation animation) {
            Log.d(MainActivity.f7667X0, "right_Listner111==>" + MainActivity.this.f7670B);
            MainActivity mainActivity = MainActivity.this;
            if (mainActivity.f7670B) {
                mainActivity.f7694N.setVisibility(4);
                MainActivity.this.f7708U.clearAnimation();
                MainActivity.this.f7670B = false;
            } else if (mainActivity.R("device", "webview").equals("main")) {
                MainActivity.this.f7670B = false;
            } else {
                MainActivity.this.f7670B = true;
            }
        }

        @Override // android.view.animation.Animation.AnimationListener
        public void onAnimationRepeat(Animation animation) {
        }

        @Override // android.view.animation.Animation.AnimationListener
        public void onAnimationStart(Animation animation) {
        }

        /* synthetic */ z(MainActivity mainActivity, k kVar) {
            this();
        }
    }

    public void A0() {
        Z("device", "webview", "main");
        runOnUiThread(new RunnableC0259c());
    }

    public void B0(String str) {
        HashMap map = new HashMap();
        map.put("User-Agent", "allytte " + O());
        map.put("allytte-device-token", this.f7834v);
        map.put("allytte-device-platform", "android");
        Log.d(f7667X0, "extraHeaders==>>>> " + str + ">>>>" + map.toString());
        if (R("device", "webview").equals("popup")) {
            this.f7714X.post(new u(str, map));
        } else {
            this.f7692M.post(new v(str, map));
        }
    }

    private void C0(JSONObject jSONObject) {
        try {
            Dialog dialog = this.f7832t;
            if (dialog != null) {
                dialog.cancel();
            }
            Dialog dialog2 = this.f7832t;
            if (dialog2 != null) {
                dialog2.cancel();
            }
            String string = jSONObject.getJSONObject("config").getString("message");
            View viewInflate = LayoutInflater.from(this.f7831s).inflate(h2.e.f7388d, (ViewGroup) null);
            ((TextView) viewInflate.findViewById(h2.d.f7382x)).setText(string);
            ((Button) viewInflate.findViewById(h2.d.f7360b)).setOnClickListener(new r());
            Dialog dialog3 = new Dialog(this.f7831s, h2.g.f7396a);
            this.f7832t = dialog3;
            dialog3.setContentView(viewInflate);
            this.f7832t.setCancelable(false);
            this.f7832t.setCanceledOnTouchOutside(false);
            this.f7832t.getWindow().setAttributes(V(this.f7832t));
            this.f7832t.show();
        } catch (Exception e3) {
            e3.printStackTrace();
        }
    }

    private void D0(JSONObject jSONObject) {
        try {
            A0();
            startActivity(new Intent("android.intent.action.VIEW", Uri.parse(jSONObject.getJSONObject("config").getString("url"))));
        } catch (Exception e3) {
            e3.printStackTrace();
        }
    }

    private Button E0(String str, JSONObject jSONObject) {
        byte b3;
        Log.d(f7667X0, "createButton===>loc==>" + str + "===>" + jSONObject.toString());
        Button button = new Button(this);
        button.setLayoutParams(new ViewGroup.LayoutParams(-2, -2));
        try {
            String string = !jSONObject.isNull("icon") ? jSONObject.getString("icon") : "null";
            String string2 = !jSONObject.isNull("name") ? jSONObject.getString("name") : "null";
            String string3 = !jSONObject.isNull("align") ? jSONObject.getString("align") : "null";
            String string4 = !jSONObject.isNull("color") ? jSONObject.getString("color") : "null";
            if (string.equals("null")) {
                button.setBackgroundColor(Color.parseColor("#00ff0000"));
            } else {
                switch (string3.hashCode()) {
                    case -1383228885:
                        if (!string3.equals("bottom")) {
                            b3 = -1;
                        } else {
                            b3 = 4;
                        }
                        break;
                    case 115029:
                        if (!string3.equals("top")) {
                            b3 = -1;
                        } else {
                            b3 = 2;
                        }
                        break;
                    case 3317767:
                        if (!string3.equals("left")) {
                            b3 = -1;
                        } else {
                            b3 = 1;
                        }
                        break;
                    case 3392903:
                        if (!string3.equals("null")) {
                            b3 = -1;
                        } else {
                            b3 = 0;
                        }
                        break;
                    case 108511772:
                        if (!string3.equals("right")) {
                            b3 = -1;
                        } else {
                            b3 = 3;
                        }
                        break;
                    default:
                        b3 = -1;
                        break;
                }
                if (b3 == 0) {
                    button.setBackground(P0(string));
                } else if (b3 == 1) {
                    button.setCompoundDrawables(P0(string), null, null, null);
                    button.setPadding(N(this, 30), 0, 0, 0);
                } else if (b3 == 2) {
                    button.setCompoundDrawables(null, P0(string), null, null);
                    button.setPadding(0, N(this, 30), 0, 0);
                } else if (b3 == 3) {
                    button.setCompoundDrawables(null, null, P0(string), null);
                    button.setPadding(0, 0, N(this, 30), 0);
                } else if (b3 == 4) {
                    button.setCompoundDrawables(null, null, null, P0(string));
                    button.setPadding(0, 0, 0, N(this, 30));
                }
            }
            if (!string2.equals("null")) {
                button.setText(string2);
                button.setTextSize(14.0f);
            }
            if (!string4.equals("null")) {
                button.setTextColor(Color.parseColor(string4));
            } else if (str.equals("popup_full")) {
                button.setTextColor(Color.parseColor("#ffffff"));
            } else {
                button.setTextColor(Color.parseColor("#000000"));
            }
            if (!jSONObject.isNull("action")) {
                jSONObject.getJSONArray("action").getJSONObject(0);
                button.setOnClickListener(new ViewOnClickListenerC0258b(jSONObject, str));
            }
        } catch (Exception e3) {
            e3.printStackTrace();
        }
        return button;
    }

    private void F0(JSONObject jSONObject) {
        try {
            JSONObject jSONObject2 = jSONObject.getJSONObject("config");
            String string = jSONObject2.getString("type");
            JSONObject jSONObject3 = jSONObject2.getJSONObject("json");
            if (string.equals("global")) {
                String string2 = jSONObject3.getString("type");
                JSONObject jSONObject4 = jSONObject3.getJSONObject("config");
                if (string2.equals("splash")) {
                    String string3 = jSONObject4.getString("url");
                    Z("device", "splash_url", string3);
                    U0(string3);
                }
            }
        } catch (Exception e3) {
            e3.printStackTrace();
        }
    }

    public void H0(JSONObject jSONObject) {
        Log.d(f7667X0, "createFooter==>>>> " + jSONObject.toString());
        this.f7676E = false;
        try {
            this.f7719c0.removeAllViewsInLayout();
            String string = jSONObject.getString("bgImage");
            String string2 = jSONObject.getString("bgColor");
            String string3 = jSONObject.getString("border");
            JSONArray jSONArray = jSONObject.getJSONArray("menu");
            if (string2.equals("null")) {
                this.f7742z0.setColor(Color.parseColor("#ffffff"));
            } else if (string2.equals("transparent")) {
                this.f7742z0.setColor(Color.parseColor("#00000000"));
            } else {
                this.f7742z0.setColor(Color.parseColor(string2));
            }
            if (!string.equals("null")) {
                g1(string);
            }
            if (string3.equals("null")) {
                this.f7742z0.setStroke(0, Color.parseColor("#ffffff"));
            } else {
                this.f7742z0.setStroke(N(this.f7831s, Integer.parseInt(string3)), Color.parseColor("#000000"));
            }
            for (int i3 = 0; i3 < jSONArray.length(); i3++) {
                JSONObject jSONObject2 = jSONArray.getJSONObject(i3);
                LinearLayout linearLayout = new LinearLayout(this.f7831s);
                linearLayout.setLayoutParams(new LinearLayout.LayoutParams(0, -2, 1.0f));
                linearLayout.setGravity(17);
                int i4 = this.f7682H;
                linearLayout.addView(d1(i4, i4, E0("main", jSONObject2)));
                Log.d(f7667X0, "createbutton==>>>> " + i3);
                this.f7719c0.addView(linearLayout);
            }
        } catch (Exception e3) {
            e3.printStackTrace();
        }
    }

    public void I0(LinearLayout linearLayout, JSONArray jSONArray, String str) throws JSONException {
        Log.d(f7667X0, "createMenu 호출2==>>>> ");
        for (int i3 = 0; i3 < jSONArray.length(); i3++) {
            JSONObject jSONObject = jSONArray.getJSONObject(i3);
            if ((!jSONObject.isNull("icon") ? jSONObject.getString("icon") : "null").equals("null")) {
                linearLayout.addView(E0(str, jSONObject));
            } else {
                int i4 = this.f7680G;
                linearLayout.addView(d1(i4, i4, E0(str, jSONObject)));
            }
        }
    }

    public void J0(LinearLayout linearLayout, JSONObject jSONObject, String str) {
        Log.d(f7667X0, "createMenu 호출==>>>> " + jSONObject.toString());
        if ((!jSONObject.isNull("icon") ? jSONObject.getString("icon") : "null").equals("null")) {
            linearLayout.addView(E0(str, jSONObject));
        } else {
            int i3 = this.f7680G;
            linearLayout.addView(d1(i3, i3, E0(str, jSONObject)));
        }
    }

    public void K0() {
        Dialog dialog = this.f7832t;
        if (dialog != null) {
            dialog.cancel();
        }
        View viewInflate = LayoutInflater.from(this.f7831s).inflate(h2.e.f7390f, (ViewGroup) null);
        ((Button) viewInflate.findViewById(h2.d.f7359a)).setOnClickListener(new q());
        Dialog dialog2 = new Dialog(this.f7831s, h2.g.f7396a);
        this.f7832t = dialog2;
        dialog2.setContentView(viewInflate);
        this.f7832t.setCancelable(false);
        this.f7832t.setCanceledOnTouchOutside(false);
        this.f7832t.getWindow().setAttributes(V(this.f7832t));
        this.f7832t.show();
    }

    public void L0(JSONObject jSONObject) {
        Log.d(f7667X0, "create popup Footer==>>>> " + jSONObject.toString());
        try {
            this.f7700Q.removeAllViewsInLayout();
            String string = jSONObject.getString("bgImage");
            String string2 = jSONObject.getString("bgColor");
            String string3 = jSONObject.getString("border");
            JSONArray jSONArray = jSONObject.getJSONArray("menu");
            if (string2.equals("null")) {
                this.f7681G0.setColor(Color.parseColor("#ffffff"));
            } else if (string2.equals("transparent")) {
                this.f7681G0.setColor(Color.parseColor("#00000000"));
            } else {
                this.f7681G0.setColor(Color.parseColor(string2));
            }
            if (!string.equals("null")) {
                g1(string);
            }
            if (string3.equals("null")) {
                this.f7681G0.setStroke(0, Color.parseColor("#ffffff"));
            } else {
                this.f7681G0.setStroke(N(this.f7831s, Integer.parseInt(string3)), Color.parseColor("#000000"));
            }
            for (int i3 = 0; i3 < jSONArray.length(); i3++) {
                JSONObject jSONObject2 = jSONArray.getJSONObject(i3);
                LinearLayout linearLayout = new LinearLayout(this.f7831s);
                int i4 = this.f7682H;
                linearLayout.setLayoutParams(new LinearLayout.LayoutParams(i4, i4));
                linearLayout.addView(E0("popup", jSONObject2));
                LinearLayout linearLayout2 = new LinearLayout(this.f7831s);
                linearLayout2.setLayoutParams(new LinearLayout.LayoutParams(0, -2, 1.0f));
                linearLayout2.setGravity(17);
                linearLayout2.addView(linearLayout);
                Log.d(f7667X0, "createbutton==>>>> " + i3);
                this.f7700Q.addView(linearLayout2);
            }
        } catch (Exception e3) {
            e3.printStackTrace();
        }
    }

    private void M0(JSONObject jSONObject) {
        Log.d(f7667X0, "createWebviewMain==>>>> >>>>" + this.f7670B);
        runOnUiThread(new w(jSONObject));
    }

    private void N0(JSONObject jSONObject) {
        Log.d(f7667X0, "createWebviewPopup==>>>> ");
        runOnUiThread(new RunnableC0257a(jSONObject));
    }

    private void O0(String str) {
        Log.d(f7667X0, "dataRequest===>" + str);
        new B(str, this.f7837y).execute(new Void[0]);
    }

    private Drawable P0(String str) {
        d dVar = new d(str);
        dVar.start();
        try {
            dVar.join();
            return new BitmapDrawable(getResources(), this.f7721e0);
        } catch (Exception e3) {
            e3.printStackTrace();
            return null;
        }
    }

    public void Q0(String str) {
        x0(String.format("{\"action\":[{\"command\":\"alert\",\"config\":{\"message\":\"%s\"}}]}", str));
    }

    private void R0(String str) {
        String str2 = "https://mobile.ut.ac.kr//service/api/device/nfc?value=" + str;
        String str3 = this.f7722f0;
        if (str3 != null && str3.length() > 0) {
            str2 = this.f7722f0 + str;
        }
        O0(str2);
    }

    private void S0() {
        if (this.f7724h0) {
            O0("https://mobile.ut.ac.kr//service/api/device/gesture/shake?value=");
        }
    }

    private void T0() {
        AbstractC0296a.h(this);
    }

    private int V0() {
        DisplayMetrics displayMetrics = new DisplayMetrics();
        getWindowManager().getDefaultDisplay().getMetrics(displayMetrics);
        int i3 = displayMetrics.widthPixels;
        int i4 = displayMetrics.heightPixels;
        DisplayMetrics displayMetrics2 = new DisplayMetrics();
        ((WindowManager) this.f7831s.getSystemService("window")).getDefaultDisplay().getMetrics(displayMetrics2);
        int i5 = displayMetrics2.densityDpi;
        PrintStream printStream = System.out;
        printStream.println("density : " + i5);
        float f3 = displayMetrics.density;
        int i6 = (int) (((float) i3) / f3);
        int i7 = (int) (((float) i4) / f3);
        printStream.println("dipWidth(dp) : " + i6 + ", deviceWidth(px) : " + i3);
        printStream.println("dipheight(dp) : " + i7 + ", deviceHeight(px) : " + i4);
        return i7;
    }

    private void W0(JSONObject jSONObject) {
        double latitude;
        double altitude;
        double latitude2;
        double altitude2;
        try {
            String string = jSONObject.getJSONObject("config").getString("url");
            LocationManager locationManager = (LocationManager) getSystemService("location");
            double longitude = 0.0d;
            if (b.a(getApplicationContext(), "android.permission.ACCESS_FINE_LOCATION") != 0) {
                AbstractC0296a.j(this, new String[]{"android.permission.ACCESS_FINE_LOCATION"}, 0);
                latitude2 = 0.0d;
                altitude2 = 0.0d;
            } else {
                Location lastKnownLocation = locationManager.getLastKnownLocation("network");
                if (lastKnownLocation != null) {
                    lastKnownLocation.getProvider();
                    longitude = lastKnownLocation.getLongitude();
                    latitude = lastKnownLocation.getLatitude();
                    altitude = lastKnownLocation.getAltitude();
                } else {
                    latitude = 0.0d;
                    altitude = 0.0d;
                }
                Location lastKnownLocation2 = locationManager.getLastKnownLocation("gps");
                if (lastKnownLocation2 != null) {
                    lastKnownLocation2.getProvider();
                    longitude = lastKnownLocation2.getLongitude();
                    latitude2 = lastKnownLocation2.getLatitude();
                    altitude2 = lastKnownLocation2.getAltitude();
                } else {
                    latitude2 = latitude;
                    altitude2 = altitude;
                }
            }
            O0(String.format(string + "&latitude=%s&longitude=%s&altitude=%s&azimuth=%s", Double.valueOf(longitude), Double.valueOf(latitude2), Double.valueOf(altitude2), Float.valueOf(this.f7689K0)));
        } catch (Exception e3) {
            e3.printStackTrace();
        }
    }

    private void X0() {
        this.f7692M = new WebView(this.f7831s);
        WebView webView = (WebView) findViewById(h2.d.f7369k);
        this.f7692M = webView;
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setMixedContentMode(0);
        settings.setTextZoom(85);
        settings.setDomStorageEnabled(true);
        settings.setDatabaseEnabled(true);
        this.f7692M.setScrollBarStyle(33554432);
        this.f7692M.setScrollbarFadingEnabled(true);
        this.f7692M.setLayerType(2, null);
        WebView.setWebContentsDebuggingEnabled(true);
        this.f7692M.setWebChromeClient(new f());
        this.f7692M.setWebChromeClient(new g());
        this.f7692M.addJavascriptInterface(new h(), "allytteAndroid");
        this.f7692M.setWebViewClient(new i());
    }

    private void Y0(String str) {
        P();
        String str2 = this.f7834v;
        if (str2 == null || str2.length() == 0) {
            String upperCase = UUID.randomUUID().toString().toUpperCase();
            this.f7834v = upperCase;
            Z("device", "device_token", upperCase);
        }
        x0(str);
    }

    public void Z0() {
        FrameLayout frameLayout = f7668Y0;
        if (frameLayout != null) {
            frameLayout.removeView(this.f7714X);
        }
        RoundedWebView roundedWebView = new RoundedWebView(this.f7831s);
        this.f7714X = roundedWebView;
        roundedWebView.setLayoutParams(new ConstraintLayout.b(-1, -1));
        f7668Y0.addView(this.f7714X);
        WebView.setWebContentsDebuggingEnabled(true);
        this.f7714X.setLayerType(2, null);
        WebSettings settings = this.f7714X.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setMixedContentMode(0);
        settings.setUseWideViewPort(false);
        settings.setJavaScriptCanOpenWindowsAutomatically(true);
        settings.setSupportMultipleWindows(true);
        settings.setTextZoom(85);
        settings.setDomStorageEnabled(true);
        settings.setDatabaseEnabled(true);
        this.f7714X.setDownloadListener(new j());
        this.f7714X.setWebChromeClient(new l());
        this.f7714X.addJavascriptInterface(new m(), "allytteAndroid");
        this.f7714X.setWebViewClient(new n());
    }

    private boolean a1(String str) {
        Intent launchIntentForPackage = this.f7831s.getPackageManager().getLaunchIntentForPackage(str);
        if (launchIntentForPackage == null) {
            return false;
        }
        launchIntentForPackage.addFlags(268435456);
        startActivity(launchIntentForPackage);
        return true;
    }

    private void b1() {
        runOnUiThread(new s());
    }

    public void c1(String str) {
        if (!U()) {
            Q0(getString(h2.f.f7394c));
            return;
        }
        HashMap map = new HashMap();
        map.put("User-Agent", "allytte " + O());
        map.put("allytte-device-token", this.f7834v);
        map.put("allytte-device-platform", "android");
        Log.d(f7667X0, "menu extraHeaders==>>>> " + str + ">>>>" + map.toString());
        this.f7678F = true;
        this.f7714X.loadUrl(str, map);
        this.f7714X.invalidate();
    }

    private LinearLayout d1(int i3, int i4, Button button) {
        LinearLayout linearLayout = new LinearLayout(this.f7831s);
        linearLayout.setLayoutParams(new LinearLayout.LayoutParams(i3, i4));
        linearLayout.addView(button);
        return linearLayout;
    }

    private void e1(JSONObject jSONObject) {
        try {
            JSONObject jSONObject2 = jSONObject.getJSONObject("config");
            String string = jSONObject2.getString("url");
            this.f7711V0 = jSONObject2.getJSONArray("uuid");
            if (string.contains("?")) {
                this.f7723g0 = string + "&uuid=";
            } else {
                this.f7723g0 = string + "?uuid=";
            }
        } catch (Exception e3) {
            e3.printStackTrace();
        }
        this.f7699P0.h(this);
        new Handler().postDelayed(new t(), 5000L);
    }

    private void f1(JSONObject jSONObject) {
        try {
            String string = jSONObject.getJSONObject("config").getString("url");
            if (string.contains("?")) {
                this.f7723g0 = string + "&value=";
            } else {
                this.f7723g0 = string + "?value=";
            }
            G1.a aVar = new G1.a(this);
            aVar.k(ZxingActivity.class);
            aVar.l(true);
            aVar.j(false);
            aVar.f();
        } catch (Exception e3) {
            e3.printStackTrace();
        }
    }

    public void g1(String str) {
        e eVar = new e(str);
        eVar.start();
        try {
            eVar.join();
            this.f7684I.setBackground(new BitmapDrawable(getResources(), this.f7721e0));
        } catch (Exception e3) {
            e3.printStackTrace();
        }
    }

    private void h1(JSONObject jSONObject) {
        b1();
        try {
            String string = jSONObject.getJSONObject("config").getString("url");
            if (string.contains("?")) {
                this.f7722f0 = string + "&value=";
            } else {
                this.f7722f0 = string + "?value=";
            }
            Log.d(f7667X0, "comm_nfc_url===>" + this.f7722f0);
        } catch (Exception e3) {
            e3.printStackTrace();
        }
    }

    public void i1(String str, String str2, String str3, boolean z2) {
        this.f7677E0.setCornerRadii(this.f7669A0);
        this.f7698P.setPadding(0, 0, 0, 0);
        str.hashCode();
        switch (str) {
            case "bottom":
                if (!str2.equals("null") || !str3.equals("null")) {
                    if (!str2.equals("null") && str3.equals("null")) {
                        this.f7677E0.setCornerRadii(this.f7669A0);
                        if (!z2) {
                            this.f7714X.d(false, false, false, false);
                        } else {
                            this.f7714X.d(true, true, false, false);
                        }
                    } else if (str2.equals("null") && !str3.equals("null")) {
                        this.f7714X.d(true, true, false, false);
                        this.f7681G0.setCornerRadii(this.f7675D0);
                    } else {
                        this.f7677E0.setCornerRadii(this.f7669A0);
                        this.f7681G0.setCornerRadii(this.f7675D0);
                        if (!z2) {
                            this.f7714X.d(false, false, false, false);
                        } else {
                            this.f7714X.d(true, true, false, false);
                        }
                    }
                    break;
                } else {
                    this.f7714X.d(true, true, false, false);
                    break;
                }
                break;
            case "center":
                if (!str2.equals("null") || !str3.equals("null")) {
                    if (!str2.equals("null") && str3.equals("null")) {
                        this.f7677E0.setCornerRadii(this.f7669A0);
                        if (!z2) {
                            this.f7714X.d(false, false, true, true);
                        } else {
                            this.f7714X.d(true, true, true, true);
                        }
                    } else if (str2.equals("null") && !str3.equals("null")) {
                        this.f7698P.setPadding(0, N(this, 30), 0, 0);
                        this.f7681G0.setCornerRadii(this.f7671B0);
                    } else {
                        this.f7677E0.setCornerRadii(this.f7669A0);
                        this.f7681G0.setCornerRadii(this.f7671B0);
                        if (!z2) {
                            this.f7714X.d(false, false, false, false);
                        } else {
                            this.f7714X.d(true, true, false, false);
                        }
                    }
                    break;
                } else {
                    this.f7714X.d(true, true, true, true);
                    break;
                }
                break;
            case "top":
                if (!str2.equals("null") || !str3.equals("null")) {
                    if (!str2.equals("null")) {
                        this.f7677E0.setCornerRadii(this.f7675D0);
                        this.f7714X.d(false, false, true, true);
                    } else {
                        this.f7681G0.setCornerRadii(this.f7671B0);
                    }
                    break;
                } else {
                    this.f7714X.d(false, false, true, true);
                    break;
                }
                break;
            default:
                this.f7677E0.setCornerRadii(this.f7675D0);
                this.f7714X.d(false, false, false, false);
                this.f7681G0.setCornerRadii(this.f7675D0);
                break;
        }
    }

    private void k1(JSONObject jSONObject) {
        try {
            JSONObject jSONObject2 = jSONObject.getJSONObject("config");
            String string = jSONObject2.getString("storeUrl");
            if (a1(jSONObject2.getString("contentUrl"))) {
                return;
            }
            startActivity(new Intent("android.intent.action.VIEW", Uri.parse(string)));
        } catch (Exception e3) {
            e3.printStackTrace();
        }
    }

    public static String l1(byte[] bArr) {
        StringBuilder sb = new StringBuilder();
        for (int i3 = 0; i3 < bArr.length; i3++) {
            sb.append("0123456789ABCDEF".charAt((bArr[i3] >> 4) & 15));
            sb.append("0123456789ABCDEF".charAt(bArr[i3] & 15));
        }
        return sb.toString();
    }

    private void m1(JSONObject jSONObject) {
        try {
            O0(jSONObject.getJSONObject("config").getString("url"));
        } catch (Exception e3) {
            e3.printStackTrace();
        }
    }

    public void x0(String str) {
        String strReplace = str;
        if (strReplace == null || str.length() == 0) {
            return;
        }
        if (str.length() > 0) {
            strReplace = strReplace.replace("https://www.allytte.com", "https://mobile.ut.ac.kr/");
        }
        if (strReplace != null && strReplace.length() > 0) {
            strReplace = strReplace.replace("http://allytte.com", "https://mobile.ut.ac.kr/");
        }
        Log.d(f7667X0, "allytteCommand====+++====>>>> " + strReplace);
        try {
            JSONArray jSONArray = new JSONObject(strReplace).getJSONArray("action");
            for (int i3 = 0; i3 < jSONArray.length(); i3++) {
                JSONObject jSONObject = jSONArray.getJSONObject(i3);
                byte b3 = -1;
                switch (jSONObject.getString("command")) {
                    case "webview":
                        String string = jSONObject.getJSONObject("config").getString("show");
                        int iHashCode = string.hashCode();
                        if (iHashCode != -1361636432) {
                            if (iHashCode != 3343801) {
                                if (iHashCode == 106852524 && string.equals("popup")) {
                                    b3 = 1;
                                }
                            } else if (string.equals("main")) {
                                b3 = 0;
                            }
                        } else if (string.equals("change")) {
                            b3 = 2;
                        }
                        if (b3 == 0) {
                            M0(jSONObject);
                            Z("device", "webview", "main");
                            break;
                        } else {
                            if (b3 == 1) {
                                N0(jSONObject);
                                Z("device", "webview", "popup");
                            } else if (b3 != 2) {
                                Log.d(f7667X0, "처리안된 webview==>>>> " + strReplace);
                            } else {
                                B0(jSONObject.getJSONObject("config").getString("url"));
                            }
                            break;
                        }
                        break;
                    case "alert":
                        C0(jSONObject);
                        break;
                    case "dialog":
                        G0(jSONObject);
                        break;
                    case "function":
                        switch (jSONObject.getJSONObject("config").getString("function")) {
                            case "qrcode":
                                f1(jSONObject);
                                break;
                            case "gps":
                                W0(jSONObject);
                                break;
                            case "nfc":
                                h1(jSONObject);
                                break;
                            case "beacone":
                                e1(jSONObject);
                                break;
                            case "back":
                                y0();
                                break;
                            case "close":
                                A0();
                                break;
                            case "exit":
                                T0();
                                break;
                            case "url":
                                m1(jSONObject);
                                break;
                            default:
                                Log.d(f7667X0, "처리안된 Function==>>>> " + strReplace);
                                break;
                        }
                        break;
                    case "browser":
                        D0(jSONObject);
                        break;
                    case "app":
                        k1(jSONObject);
                        break;
                    case "data":
                        F0(jSONObject);
                        break;
                    default:
                        Log.d(f7667X0, "처리안된 command==>>>> " + strReplace);
                        break;
                }
            }
        } catch (Exception e3) {
            e3.printStackTrace();
        }
    }

    public void y0() {
        if (this.f7718b0) {
            if (this.f7716Z.canGoBack()) {
                this.f7716Z.goBack();
                Log.d(f7667X0, "backPress222===>pw goback()");
                return;
            } else {
                Log.d(f7667X0, "backPress===>window.close();");
                this.f7716Z.loadUrl("javascript:window.close();");
                this.f7718b0 = false;
                return;
            }
        }
        if (this.f7717a0) {
            if (this.f7715Y.canGoBack()) {
                this.f7715Y.goBack();
                Log.d(f7667X0, "backPress===>pw goback()");
                return;
            } else {
                Log.d(f7667X0, "backPress===>window.close();");
                this.f7715Y.loadUrl("javascript:window.close();");
                this.f7717a0 = false;
                return;
            }
        }
        if (this.f7676E) {
            if (this.f7692M.canGoBack()) {
                this.f7692M.goBack();
                return;
            } else if (System.currentTimeMillis() <= this.f7709U0 + 2000) {
                d0();
                return;
            } else {
                this.f7709U0 = System.currentTimeMillis();
                Toast.makeText(this, getString(h2.f.f7392a), 0).show();
                return;
            }
        }
        Log.d(f7667X0, "backPress===>popup" + this.f7717a0);
        if (this.f7714X.canGoBack()) {
            this.f7714X.goBack();
            Log.d(f7667X0, "backPress===>popup_webview.canGoBack()");
        } else {
            Log.d(f7667X0, "backPress===>closePopupWebview()");
            A0();
            this.f7676E = true;
        }
    }

    public void z0() {
        Log.d(f7667X0, "beacon count===>" + this.f7701Q0.size());
        String str = null;
        String str2 = null;
        String str3 = null;
        for (int i3 = 0; i3 < this.f7711V0.length(); i3++) {
            try {
                String string = this.f7711V0.getString(i3);
                for (j2.e eVar : this.f7701Q0) {
                    String string2 = eVar.k().toString();
                    String string3 = eVar.l().toString();
                    String string4 = eVar.m().toString();
                    if (string.equals(string2)) {
                        Log.d(f7667X0, "uuid ===>" + string + "<>" + string2 + "====>" + string3);
                        str2 = string4;
                        str = string2;
                        str3 = string3;
                    }
                }
            } catch (JSONException e3) {
                e3.printStackTrace();
            }
        }
        O0(this.f7723g0 + str + "&major=" + str3 + "&major=" + str2);
        try {
            this.f7699P0.X(this.f7705S0);
        } catch (RemoteException e4) {
            e4.printStackTrace();
        }
        this.f7699P0.Z(this);
        this.f7701Q0.clear();
    }

    public void G0(JSONObject jSONObject) {
        try {
            Dialog dialog = this.f7832t;
            if (dialog != null) {
                dialog.cancel();
            }
            JSONObject jSONObject2 = jSONObject.getJSONObject("config");
            if (!jSONObject2.isNull("title")) {
                jSONObject2.getString("title");
            }
            if (!jSONObject2.isNull("icon")) {
                jSONObject2.getString("icon");
            }
            String string = jSONObject2.isNull("message") ? "null" : jSONObject2.getString("message");
            View viewInflate = LayoutInflater.from(this.f7831s).inflate(h2.e.f7389e, (ViewGroup) null);
            LinearLayout linearLayout = (LinearLayout) viewInflate.findViewById(h2.d.f7361c);
            ((TextView) viewInflate.findViewById(h2.d.f7382x)).setText(string);
            JSONArray jSONArray = jSONObject2.getJSONArray("button");
            for (int i3 = 0; i3 < jSONArray.length(); i3++) {
                JSONObject jSONObject3 = jSONArray.getJSONObject(i3);
                LinearLayout linearLayout2 = new LinearLayout(this.f7831s);
                int i4 = this.f7682H;
                linearLayout2.setLayoutParams(new LinearLayout.LayoutParams(i4, i4));
                linearLayout2.addView(E0("dialog", jSONObject3));
                LinearLayout linearLayout3 = new LinearLayout(this.f7831s);
                linearLayout3.setLayoutParams(new LinearLayout.LayoutParams(0, -2, 1.0f));
                linearLayout3.setGravity(17);
                linearLayout3.addView(linearLayout2);
                Log.d(f7667X0, "createbutton==>>>> " + i3);
                linearLayout.addView(linearLayout3);
            }
            Dialog dialog2 = new Dialog(this.f7831s, h2.g.f7396a);
            this.f7832t = dialog2;
            dialog2.setContentView(viewInflate);
            this.f7832t.setCancelable(false);
            this.f7832t.setCanceledOnTouchOutside(false);
            this.f7832t.getWindow().setAttributes(V(this.f7832t));
            this.f7832t.show();
        } catch (Exception e3) {
            e3.printStackTrace();
        }
    }

    public void U0(String str) {
        new C("png", str).execute(new String[0]);
    }

    public void d0() {
        finish();
        System.exit(0);
        Process.killProcess(Process.myPid());
    }

    @Override // j2.n
    public void h() {
        this.f7705S0 = new j2.p("nearMeScanning", null, null, null);
        this.f7699P0.e(new p());
        try {
            this.f7699P0.W(this.f7705S0);
        } catch (RemoteException e3) {
            e3.printStackTrace();
        }
    }

    public void j1() {
        androidx.appcompat.app.b.a aVar = new androidx.appcompat.app.b.a(this);
        aVar.m("").g("루팅된 기기는 사용할 수 없습니다.");
        aVar.d(false);
        aVar.k("OK", new o());
        aVar.a().show();
    }

    @Override // android.hardware.SensorEventListener
    public void onAccuracyChanged(Sensor sensor, int i3) {
    }

    @Override // androidx.fragment.app.e, androidx.activity.ComponentActivity, android.app.Activity
    protected void onActivityResult(int i3, int i4, Intent intent) {
        G1.b bVarH = G1.a.h(i3, i4, intent);
        if (bVarH != null) {
            if (bVarH.a() == null) {
                Toast.makeText(this, "Cancelled", 1).show();
                return;
            }
            O0(this.f7723g0 + bVarH.a());
            return;
        }
        super.onActivityResult(i3, i4, intent);
        if (i4 == -1 && i3 == 1) {
            if (intent.getClipData() == null) {
                if (intent.getData() != null) {
                    this.f7703R0.onReceiveValue(new Uri[]{intent.getData()});
                }
            } else {
                int itemCount = intent.getClipData().getItemCount();
                Uri[] uriArr = new Uri[itemCount];
                for (int i5 = 0; i5 < itemCount; i5++) {
                    uriArr[i5] = intent.getClipData().getItemAt(i5).getUri();
                }
                this.f7703R0.onReceiveValue(uriArr);
            }
        }
    }

    @Override // androidx.activity.ComponentActivity, android.app.Activity
    public void onBackPressed() {
        y0();
    }

    @Override // android.view.View.OnClickListener
    public void onClick(View view) {
        if (view.getId() == h2.d.f7370l) {
            A0();
        }
    }

    @Override // kr.ac.ut.mobile.a, androidx.fragment.app.e, androidx.activity.ComponentActivity, p060u.e, android.app.Activity
    protected void onCreate(Bundle bundle) {
        super.onCreate(bundle);
        String language = Locale.getDefault().getLanguage();
        this.f7838z = language;
        Y(language);
        Log.d(f7667X0, "sp_language" + this.f7838z);
        setContentView(h2.e.f7387c);
        T();
        this.f7831s = this;
        Z("device", "webview", "main");
        this.f7684I = (RelativeLayout) findViewById(h2.d.f7368j);
        this.f7686J = (LinearLayout) findViewById(h2.d.f7365g);
        this.f7688K = (LinearLayout) findViewById(h2.d.f7363e);
        this.f7690L = (LinearLayout) findViewById(h2.d.f7376r);
        this.f7686J = (LinearLayout) findViewById(h2.d.f7365g);
        this.f7688K = (LinearLayout) findViewById(h2.d.f7363e);
        this.f7690L = (LinearLayout) findViewById(h2.d.f7376r);
        X0();
        this.f7720d0 = (LinearLayout) findViewById(h2.d.f7366h);
        this.f7719c0 = (LinearLayout) findViewById(h2.d.f7367i);
        this.f7700Q = (LinearLayout) findViewById(h2.d.f7373o);
        RelativeLayout relativeLayout = (RelativeLayout) findViewById(h2.d.f7370l);
        this.f7694N = relativeLayout;
        relativeLayout.setOnClickListener(this);
        this.f7708U = (LinearLayout) findViewById(h2.d.f7372n);
        this.f7696O = (RelativeLayout) findViewById(h2.d.f7374p);
        this.f7698P = (LinearLayout) findViewById(h2.d.f7371m);
        this.f7702R = (LinearLayout) findViewById(h2.d.f7380v);
        this.f7704S = (LinearLayout) findViewById(h2.d.f7377s);
        this.f7706T = (LinearLayout) findViewById(h2.d.f7381w);
        this.f7710V = (LinearLayout) findViewById(h2.d.f7379u);
        this.f7712W = (LinearLayout) findViewById(h2.d.f7378t);
        this.f7696O.setOnTouchListener(new k());
        if (V0() >= 750) {
            this.f7680G = 80;
            this.f7682H = 90;
        }
        this.f7714X = (RoundedWebView) findViewById(h2.d.f7375q);
        this.f7715Y = (WebView) findViewById(h2.d.f7375q);
        this.f7716Z = (WebView) findViewById(h2.d.f7375q);
        f7668Y0 = (FrameLayout) findViewById(h2.d.f7383y);
        Z0();
        this.f7727k0 = AnimationUtils.loadAnimation(this, h2.b.f7349b);
        this.f7731o0 = AnimationUtils.loadAnimation(this, h2.b.f7353f);
        this.f7728l0 = AnimationUtils.loadAnimation(this, h2.b.f7350c);
        this.f7732p0 = AnimationUtils.loadAnimation(this, h2.b.f7354g);
        this.f7725i0 = AnimationUtils.loadAnimation(this, h2.b.f7351d);
        this.f7729m0 = AnimationUtils.loadAnimation(this, h2.b.f7355h);
        this.f7726j0 = AnimationUtils.loadAnimation(this, h2.b.f7348a);
        this.f7730n0 = AnimationUtils.loadAnimation(this, h2.b.f7352e);
        k kVar = null;
        y yVar = new y(this, kVar);
        this.f7727k0.setAnimationListener(yVar);
        this.f7731o0.setAnimationListener(yVar);
        z zVar = new z(this, kVar);
        this.f7728l0.setAnimationListener(zVar);
        this.f7732p0.setAnimationListener(zVar);
        A a3 = new A(this, kVar);
        this.f7725i0.setAnimationListener(a3);
        this.f7729m0.setAnimationListener(a3);
        x xVar = new x(this, kVar);
        this.f7726j0.setAnimationListener(xVar);
        this.f7730n0.setAnimationListener(xVar);
        Display defaultDisplay = getWindowManager().getDefaultDisplay();
        Point point = new Point();
        defaultDisplay.getSize(point);
        this.f7733q0 = point.x;
        this.f7734r0 = point.y;
        Dialog dialog = new Dialog(this);
        this.f7833u = dialog;
        dialog.setContentView(h2.e.f7391g);
        Window window = this.f7833u.getWindow();
        Objects.requireNonNull(window);
        window.setBackgroundDrawable(new ColorDrawable(0));
        this.f7833u.getWindow().clearFlags(2);
        this.f7833u.setCancelable(false);
        this.f7833u.setCanceledOnTouchOutside(false);
        this.f7741y0 = (GradientDrawable) this.f7684I.getBackground();
        this.f7742z0 = (GradientDrawable) this.f7719c0.getBackground();
        this.f7677E0 = (GradientDrawable) this.f7696O.getBackground();
        this.f7679F0 = (GradientDrawable) this.f7698P.getBackground();
        this.f7681G0 = (GradientDrawable) this.f7700Q.getBackground();
        NfcAdapter defaultAdapter = NfcAdapter.getDefaultAdapter(this);
        this.f7739w0 = defaultAdapter;
        if (defaultAdapter == null) {
            Toast.makeText(getApplicationContext(), "NFC를 지원하지 않는 단말기입니다.", 0).show();
        }
        this.f7740x0 = PendingIntent.getActivity(this, 0, new Intent(this, getClass()).addFlags(536870912), 33554432);
        SensorManager sensorManager = (SensorManager) getSystemService("sensor");
        this.f7735s0 = sensorManager;
        this.f7736t0 = sensorManager.getDefaultSensor(1);
        SensorManager sensorManager2 = (SensorManager) getSystemService("sensor");
        this.f7683H0 = sensorManager2;
        this.f7685I0 = sensorManager2.getDefaultSensor(1);
        this.f7687J0 = this.f7683H0.getDefaultSensor(2);
        this.f7669A0 = new float[]{N(this, 30), N(this, 30), N(this, 30), N(this, 30), 0.0f, 0.0f, 0.0f, 0.0f};
        this.f7671B0 = new float[]{0.0f, 0.0f, 0.0f, 0.0f, N(this, 30), N(this, 30), N(this, 30), N(this, 30)};
        this.f7673C0 = new float[]{N(this, 30), N(this, 30), N(this, 30), N(this, 30), N(this, 30), N(this, 30), N(this, 30), N(this, 30)};
        this.f7675D0 = new float[]{0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f};
        Y0(getIntent().getStringExtra("screen_info"));
        j2.j jVarY = j2.j.y(this);
        this.f7699P0 = jVarY;
        jVarY.p().add(new j2.k().s("m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24"));
        try {
            Runtime.getRuntime().exec("su");
            j1();
        } catch (Exception unused) {
            Log.d("test", "rooting X");
        }
    }

    @Override // androidx.appcompat.app.c, androidx.fragment.app.e, android.app.Activity
    protected void onDestroy() {
        super.onDestroy();
        this.f7699P0.Z(this);
        M();
    }

    @Override // androidx.fragment.app.e, android.app.Activity
    protected void onNewIntent(Intent intent) {
        String str;
        UnsupportedEncodingException e3;
        super.onNewIntent(intent);
        String stringExtra = intent.getStringExtra("screen_info");
        if (stringExtra != null && stringExtra.length() > 0) {
            Y0(stringExtra);
            return;
        }
        Parcelable[] parcelableArrayExtra = intent.getParcelableArrayExtra("android.nfc.extra.NDEF_MESSAGES");
        Tag tag = (Tag) intent.getParcelableExtra("android.nfc.extra.TAG");
        if (tag == null) {
            return;
        }
        String[] strArrSplit = l1(tag.getId()).split(" ");
        String str2 = "";
        if (strArrSplit != null) {
            for (int length = strArrSplit.length - 1; length >= 0; length--) {
                str2 = str2 + strArrSplit[length];
            }
        }
        this.f7713W0 = str2;
        String strTrim = null;
        if (parcelableArrayExtra != null) {
            NdefMessage[] ndefMessageArr = new NdefMessage[parcelableArrayExtra.length];
            for (int i3 = 0; i3 < parcelableArrayExtra.length; i3++) {
                ndefMessageArr[i3] = (NdefMessage) parcelableArrayExtra[i3];
            }
            NdefMessage ndefMessage = ndefMessageArr[0];
            try {
                new String(ndefMessage.getRecords()[0].getPayload(), "utf-8");
                new String(ndefMessage.getRecords()[1].getPayload(), "utf-8");
                str = new String(ndefMessage.getRecords()[2].getPayload(), "utf-8");
                try {
                    int iIndexOf = str.indexOf(115);
                    strTrim = iIndexOf != -1 ? str.substring(iIndexOf).trim() : str;
                } catch (UnsupportedEncodingException e4) {
                    e3 = e4;
                    e3.printStackTrace();
                }
            } catch (UnsupportedEncodingException e5) {
                str = null;
                e3 = e5;
            }
        }
        if (strTrim == null || strTrim.length() <= 0) {
            return;
        }
        R0(strTrim);
    }

    @Override // androidx.fragment.app.e, android.app.Activity
    protected void onPause() {
        super.onPause();
        this.f7735s0.unregisterListener(this);
        this.f7683H0.unregisterListener(this);
        NfcAdapter nfcAdapter = this.f7739w0;
        if (nfcAdapter != null) {
            nfcAdapter.disableForegroundDispatch(this);
        }
    }

    @Override // androidx.fragment.app.e, android.app.Activity
    protected void onResume() {
        super.onResume();
        this.f7735s0.registerListener(this, this.f7736t0, 3);
        this.f7683H0.registerListener(this, this.f7685I0, 3);
        this.f7683H0.registerListener(this, this.f7687J0, 3);
        NfcAdapter nfcAdapter = this.f7739w0;
        if (nfcAdapter != null) {
            nfcAdapter.enableForegroundDispatch(this, this.f7740x0, null, null);
        }
    }

    @Override // android.hardware.SensorEventListener
    public void onSensorChanged(SensorEvent sensorEvent) {
        float[] fArr;
        if (sensorEvent.sensor.getType() == 1) {
            float[] fArr2 = sensorEvent.values;
            float f3 = fArr2[0] / 9.80665f;
            float f4 = fArr2[1] / 9.80665f;
            float f5 = fArr2[2] / 9.80665f;
            if (((float) Math.sqrt(Float.valueOf((f3 * f3) + (f4 * f4) + (f5 * f5)).doubleValue())) > 2.7f) {
                long jCurrentTimeMillis = System.currentTimeMillis();
                if (this.f7737u0 + 500 > jCurrentTimeMillis) {
                    return;
                }
                this.f7737u0 = jCurrentTimeMillis;
                this.f7738v0++;
                Log.d(f7667X0, "Shake Count ===>" + this.f7738v0);
                S0();
            }
            if (sensorEvent.sensor.getType() == 1) {
                this.f7695N0 = sensorEvent.values;
            }
            if (sensorEvent.sensor.getType() == 2) {
                this.f7697O0 = sensorEvent.values;
            }
            float[] fArr3 = this.f7695N0;
            if (fArr3 == null || (fArr = this.f7697O0) == null) {
                return;
            }
            float[] fArr4 = new float[9];
            if (SensorManager.getRotationMatrix(fArr4, new float[9], fArr3, fArr)) {
                float[] fArr5 = new float[3];
                SensorManager.getOrientation(fArr4, fArr5);
                this.f7689K0 = (float) Math.toDegrees(fArr5[0]);
                this.f7691L0 = (float) Math.toDegrees(fArr5[1]);
                this.f7693M0 = (float) Math.toDegrees(fArr5[2]);
            }
        }
    }

    @Override // androidx.appcompat.app.c, androidx.fragment.app.e, android.app.Activity
    protected void onStart() {
        super.onStart();
    }
}
