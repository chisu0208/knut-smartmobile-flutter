package kr.ac.ut.mobile;

import android.graphics.Color;
import android.os.Bundle;
import android.text.SpannableStringBuilder;
import android.text.style.ForegroundColorSpan;
import android.util.Log;
import android.view.View;
import android.widget.ImageButton;
import android.widget.TextView;
import com.journeyapps.barcodescanner.CaptureActivity;
import com.journeyapps.barcodescanner.DecoratedBarcodeView;
import com.journeyapps.barcodescanner.b;
import h2.d;
import h2.e;
import h2.f;

public class ZxingActivity extends CaptureActivity {

    protected final String f7823d = "CustomScannerActivity";

    private b f7824e;

    private DecoratedBarcodeView f7825f;

    private ImageButton f7826g;

    private Boolean f7827h;

    private TextView f7828i;

    class a implements View.OnClickListener {
        a() {
        }

        @Override // android.view.View.OnClickListener
        public void onClick(View view) {
            ZxingActivity.this.finish();
        }
    }

    @Override // com.journeyapps.barcodescanner.CaptureActivity, android.app.Activity
    protected void onCreate(Bundle bundle) {
        int i3;
        super.onCreate(bundle);
        setContentView(e.f7385a);
        this.f7827h = Boolean.TRUE;
        this.f7828i = (TextView) findViewById(d.f7358A);
        String string = getString(f.f7395d);
        int iIndexOf = string.indexOf("QR코드");
        Log.d("aaa", "QR코드 start index ===> " + iIndexOf);
        if (iIndexOf > -1) {
            i3 = iIndexOf + 4;
        } else {
            iIndexOf = string.indexOf("QR Code");
            Log.d("aaa", "QR Code start index ===> " + iIndexOf);
            i3 = iIndexOf > -1 ? iIndexOf + 6 : 0;
        }
        SpannableStringBuilder spannableStringBuilder = new SpannableStringBuilder(string);
        spannableStringBuilder.setSpan(new ForegroundColorSpan(Color.parseColor("#03DAC5")), iIndexOf, i3, 33);
        this.f7828i.setText(spannableStringBuilder);
        ImageButton imageButton = (ImageButton) findViewById(d.f7362d);
        this.f7826g = imageButton;
        imageButton.setOnClickListener(new a());
        this.f7825f = (DecoratedBarcodeView) findViewById(d.f7384z);
        b bVar = new b(this, this.f7825f);
        this.f7824e = bVar;
        bVar.l(getIntent(), bundle);
        this.f7824e.h();
    }

    @Override // com.journeyapps.barcodescanner.CaptureActivity, android.app.Activity
    protected void onDestroy() {
        super.onDestroy();
        this.f7824e.n();
    }

    @Override // com.journeyapps.barcodescanner.CaptureActivity, android.app.Activity
    protected void onPause() {
        super.onPause();
        this.f7824e.o();
    }

    @Override // com.journeyapps.barcodescanner.CaptureActivity, android.app.Activity
    protected void onResume() {
        super.onResume();
        this.f7824e.q();
    }

    @Override // com.journeyapps.barcodescanner.CaptureActivity, android.app.Activity
    protected void onSaveInstanceState(Bundle bundle) {
        super.onSaveInstanceState(bundle);
        this.f7824e.r(bundle);
    }
}
