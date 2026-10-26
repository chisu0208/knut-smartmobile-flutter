package kr.ac.ut.service;

import android.nfc.cardemulation.HostApduService;
import android.os.Bundle;
import android.util.Base64;
import android.util.Log;
import java.util.Arrays;

public class CardHostApduService extends HostApduService {

    private static final byte[] f7840b = {0, -92, 4, 0};

    private static final byte[] f7841c = {-16, 83, 77, 65, 82, 84, 68, 71, 85, 71, 49, 50, 50, 50};

    private static final byte[] f7842d = {110, 0};

    private static final byte[] f7843e = {106, -126};

    private static final byte[] f7844f = {109, 0};

    private static final byte[] f7845g = {106, -122};

    private static final byte[] f7846h = {106, -125};

    private static final byte[] f7847i = {103, 0};

    private static final byte[] f7848j = {-112, 0};

    private static final byte[] f7849k = {-16, 83, 85, 78, 76, 73, 78, 85, 78, 73, 86};

    private static final byte[] f7850l = {1, 0};

    private static final byte[] f7851m = "0001".getBytes();

    private boolean a(byte[] bArr) {
        int i3 = bArr[4] & 255;
        byte[] bArrCopyOfRange = Arrays.copyOfRange(bArr, 0, 4);
        byte[] bArrCopyOfRange2 = Arrays.copyOfRange(bArr, 5, i3 + 5);
        if (!Arrays.equals(bArrCopyOfRange, f7840b)) {
            Log.d("HCES", "checkApplicationSelectCommand header wrong");
            return false;
        }
        byte[] bArr2 = f7841c;
        if (i3 != bArr2.length) {
            Log.d("HCES", "checkApplicationSelectCommand aid length wrong");
            return false;
        }
        if (Arrays.equals(bArrCopyOfRange2, bArr2)) {
            return true;
        }
        Log.d("HCES", "checkApplicationSelectCommand aid wrong");
        return false;
    }

    private byte[] c(byte[] bArr) {
        byte b3 = bArr[3];
        if (4 != ((byte) (b3 & 4))) {
            Log.d("HCES", "getStudentMessage SW_INVALID_P1_P2");
            return f7845g;
        }
        if (8 != ((byte) (b3 & 8))) {
            Log.d("HCES", "getStudentMessage SW_FILE_NOT_FOUND");
            return f7843e;
        }
        if (bArr[4] != 0) {
            Log.d("HCES", "getStudentMessage SW_WRONG_LENGTH");
            return f7847i;
        }
        String upperCase = b("device", "USER_ID").toUpperCase();
        String strB = b("device", "USER_TYPE");
        if (upperCase == null || upperCase.isEmpty()) {
            Log.d("HCES", "getStudentMessage id empty");
            return f7843e;
        }
        byte[] bytes = upperCase.getBytes();
        byte[] bArr2 = new byte[13];
        if (bytes.length < 13) {
            System.arraycopy(bytes, 0, bArr2, 0, bytes.length);
            for (int length = bytes.length; length < 13; length++) {
                bArr2[length] = 0;
            }
        }
        byte[] bytes2 = strB.getBytes();
        String strB2 = b("device", "CARD_COUNT");
        Log.d("cardCount", strB2);
        if (strB2 == null || strB2.isEmpty()) {
            Log.d("HCES", "getStudentMessage cardCount empty");
            return f7843e;
        }
        String str = new String(Base64.decode(strB2, 0));
        if (str.length() < 2) {
            str = "0" + str;
        }
        byte[] bytes3 = str.getBytes();
        String strB3 = b("device", "SITE_ID");
        Log.d("siteId", strB3);
        if (strB3 == null || strB3.isEmpty()) {
            Log.d("HCES", "getStudentMessage siteId empty");
            return f7843e;
        }
        byte[] bytes4 = strB3.getBytes();
        int length2 = 27 + bytes3.length + bytes2.length + bytes4.length;
        byte[] bArr3 = f7851m;
        byte[] bArr4 = new byte[length2 + bArr3.length];
        bArr4[0] = 112;
        bArr4[1] = (byte) (23 + bytes3.length + bytes2.length + bytes4.length + bArr3.length);
        bArr4[2] = 90;
        bArr4[3] = (byte) (bytes3.length + 13 + bytes2.length + 2);
        System.arraycopy(bArr2, 0, bArr4, 4, 13);
        bArr4[17] = 91;
        System.arraycopy(bytes3, 0, bArr4, 18, bytes3.length);
        int length3 = bytes3.length;
        bArr4[18 + length3] = 92;
        int i3 = length3 + 19;
        System.arraycopy(bytes2, 0, bArr4, i3, bytes2.length);
        int length4 = i3 + bytes2.length;
        bArr4[length4] = -33;
        bArr4[length4 + 1] = 1;
        bArr4[length4 + 2] = (byte) bytes4.length;
        int i4 = length4 + 3;
        System.arraycopy(bytes4, 0, bArr4, i4, bytes4.length);
        int length5 = i4 + bytes4.length;
        bArr4[length5] = -33;
        bArr4[length5 + 1] = 2;
        bArr4[length5 + 2] = (byte) bArr3.length;
        int i5 = length5 + 3;
        System.arraycopy(bArr3, 0, bArr4, i5, bArr3.length);
        int length6 = i5 + bArr3.length;
        bArr4[length6] = -112;
        bArr4[length6 + 1] = 0;
        return bArr4;
    }

    private byte[] d() {
        byte[] bArr = f7841c;
        int length = bArr.length + 13;
        byte[] bArr2 = f7849k;
        int length2 = length + bArr2.length;
        byte[] bArr3 = f7850l;
        byte[] bArr4 = new byte[length2 + bArr3.length];
        bArr4[0] = 111;
        bArr4[1] = (byte) (bArr.length + 9 + bArr2.length + bArr3.length);
        bArr4[2] = -124;
        bArr4[3] = (byte) bArr.length;
        System.arraycopy(bArr, 0, bArr4, 4, bArr.length);
        int length3 = bArr.length;
        bArr4[4 + length3] = -91;
        bArr4[length3 + 5] = (byte) (bArr2.length + 5 + bArr3.length);
        bArr4[length3 + 6] = 80;
        bArr4[length3 + 7] = (byte) bArr2.length;
        int i3 = length3 + 8;
        System.arraycopy(bArr2, 0, bArr4, i3, bArr2.length);
        int length4 = i3 + bArr2.length;
        bArr4[length4] = -97;
        bArr4[length4 + 1] = 8;
        bArr4[length4 + 2] = (byte) bArr3.length;
        int i4 = length4 + 3;
        System.arraycopy(bArr3, 0, bArr4, i4, bArr3.length);
        int length5 = i4 + bArr3.length;
        bArr4[length5] = -112;
        bArr4[length5 + 1] = 0;
        return bArr4;
    }

    public String b(String str, String str2) {
        return getSharedPreferences(str, 0).getString(str2, "");
    }

    @Override // android.app.Service
    public void onCreate() {
        super.onCreate();
    }

    @Override // android.nfc.cardemulation.HostApduService
    public void onDeactivated(int i3) {
        Log.d("HCES", "MyHostApduService onDeactivated:" + i3);
    }

    @Override // android.app.Service
    public void onDestroy() {
        super.onDestroy();
    }

    @Override // android.nfc.cardemulation.HostApduService
    public byte[] processCommandApdu(byte[] bArr, Bundle bundle) {
        if (a(bArr)) {
            Log.d("HCES", "processCommandApdu Application selected");
            return d();
        }
        if (-112 != bArr[0]) {
            return f7842d;
        }
        return -78 == bArr[1] ? c(bArr) : f7844f;
    }
}
