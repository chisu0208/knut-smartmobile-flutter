package kr.ac.ut.service;

import android.app.ActivityManager;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.BitmapFactory;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import com.google.firebase.messaging.S;
import h2.c;
import kr.ac.ut.mobile.IntroActivity;
import org.json.JSONObject;
import p037m0.h;

public class FirebaseMessagingService extends com.google.firebase.messaging.FirebaseMessagingService {
    private int w(Context context) {
        return ((ActivityManager) context.getSystemService("activity")).getAppTasks().size();
    }

    private void x(S s2) {
        Log.d("PUSH", "strMSG====>" + new JSONObject(s2.c()).toString());
        String str = (String) s2.c().get("title");
        String str2 = (String) s2.c().get("body");
        String str3 = (String) s2.c().get("url");
        Intent intent = new Intent(this, (Class<?>) IntroActivity.class);
        Bundle bundle = new Bundle();
        bundle.putString("push_url", str3);
        intent.putExtras(bundle);
        PendingIntent activity = PendingIntent.getActivity(this, 0, intent, 1107296256);
        if (Build.VERSION.SDK_INT >= 26) {
            ((NotificationManager) getSystemService("notification")).createNotificationChannel(h.a("20005", "ALLYTTE", 4));
            u.h.e eVar = new u.h.e(this, "20005");
            eVar.k(str).j(str2).u(c.f7356a).o(BitmapFactory.decodeResource(getResources(), c.f7356a)).i(activity).f(true).r(1).l(3);
            ((NotificationManager) getSystemService("notification")).notify(0, eVar.b());
            return;
        }
        ((NotificationManager) getSystemService("notification")).notify(9999, new u.h.e(this, "").u(c.f7356a).k(str).o(BitmapFactory.decodeResource(getResources(), c.f7356a)).j(w(this) + "").f(true).r(1).i(activity).l(3).b());
    }

    @Override // com.google.firebase.messaging.FirebaseMessagingService
    public void r(S s2) {
        if (s2 == null || s2.c().size() <= 0) {
            return;
        }
        x(s2);
    }

    @Override // com.google.firebase.messaging.FirebaseMessagingService
    public void t(String str) {
        Log.d("PUSH", "Refreshed token: " + str);
        SharedPreferences.Editor editorEdit = getSharedPreferences("device", 0).edit();
        editorEdit.putString("push_token", str);
        editorEdit.commit();
    }
}
