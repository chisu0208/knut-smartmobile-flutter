package i2;

import android.util.Log;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.SSLSession;
import org.json.JSONException;
import org.json.JSONObject;

public class a {

    static final HostnameVerifier f7471c = new C0087a();

    String f7472a = "RequestHttpURLConnection";

    boolean f7473b;

    class C0087a implements HostnameVerifier {
        C0087a() {
        }

        @Override // javax.net.ssl.HostnameVerifier
        public boolean verify(String str, SSLSession sSLSession) {
            return true;
        }
    }

  0x0117: PHI (r1v8 java.net.HttpURLConnection) = 
  (r1v5 java.net.HttpURLConnection)
  (r1v6 java.net.HttpURLConnection)
  (r1v7 java.net.HttpURLConnection)
  (r1v9 java.net.HttpURLConnection)
 binds: [B:37:0x0115, B:41:0x0120, B:44:0x0126, B:46:0x012a] A[DONT_GENERATE, DONT_INLINE]] */
    public String a(String str, String str2, String str3) throws Throwable {
        HttpURLConnection httpURLConnection;
        HttpURLConnection httpURLConnection2;
        BufferedReader bufferedReader;
        HttpURLConnection httpURLConnection3 = null;
        try {
            try {
                httpURLConnection = (HttpURLConnection) new URL(str).openConnection();
                try {
                    httpURLConnection.setRequestProperty("User-Agent", "allytte " + str2);
                    httpURLConnection.setRequestProperty("allytte-device-token", str3);
                    httpURLConnection.setRequestProperty("allytte-device-platform", "android");
                    httpURLConnection.setRequestMethod("POST");
                    httpURLConnection.setConnectTimeout(3000);
                    httpURLConnection.setDoOutput(true);
                    httpURLConnection.setDoInput(true);
                    OutputStream outputStream = httpURLConnection.getOutputStream();
                    outputStream.flush();
                    outputStream.close();
                    Log.d(this.f7472a, "_url===>" + str2 + "<><>" + str3 + str);
                    if (httpURLConnection.getResponseCode() == 200) {
                        this.f7473b = true;
                        bufferedReader = new BufferedReader(new InputStreamReader(httpURLConnection.getInputStream(), "UTF-8"));
                    } else {
                        this.f7473b = false;
                        bufferedReader = new BufferedReader(new InputStreamReader(httpURLConnection.getErrorStream(), "UTF-8"));
                        Log.d(this.f7472a, "연결 요청 실패===>" + httpURLConnection.getResponseCode());
                    }
                    String str4 = "";
                    while (true) {
                        String line = bufferedReader.readLine();
                        if (line == null) {
                            JSONObject jSONObject = new JSONObject(str4);
                            jSONObject.put("urlConnResult", httpURLConnection.getResponseCode());
                            String string = jSONObject.toString();
                            Log.d(this.f7472a, "setUserPermissions5===>" + string);
                            httpURLConnection.disconnect();
                            return string;
                        }
                        str4 = str4 + line;
                    }
                } catch (MalformedURLException e3) {
                    e = e3;
                    e.printStackTrace();
                    if (httpURLConnection != null) {
                        httpURLConnection.disconnect();
                    }
                    return null;
                } catch (IOException e4) {
                    e = e4;
                    e.printStackTrace();
                    if (httpURLConnection != null) {
                        httpURLConnection.disconnect();
                    }
                    return null;
                } catch (JSONException e5) {
                    e = e5;
                    e.printStackTrace();
                    if (httpURLConnection != null) {
                        httpURLConnection.disconnect();
                    }
                    return null;
                } catch (Exception e6) {
                    e = e6;
                    e.printStackTrace();
                    if (httpURLConnection != null) {
                        httpURLConnection.disconnect();
                    }
                    return null;
                }
            } catch (Throwable th) {
                th = th;
                httpURLConnection3 = httpURLConnection2;
                if (httpURLConnection3 != null) {
                    httpURLConnection3.disconnect();
                }
                throw th;
            }
        } catch (MalformedURLException e7) {
            e = e7;
            httpURLConnection = null;
        } catch (IOException e8) {
            e = e8;
            httpURLConnection = null;
        } catch (JSONException e9) {
            e = e9;
            httpURLConnection = null;
        } catch (Exception e10) {
            e = e10;
            httpURLConnection = null;
        } catch (Throwable th2) {
            th = th2;
            if (httpURLConnection3 != null) {
                httpURLConnection3.disconnect();
            }
            throw th;
        }
    }
}
