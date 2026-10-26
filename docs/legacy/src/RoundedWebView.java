package kr.ac.ut.util;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.RectF;
import android.util.AttributeSet;
import android.webkit.WebView;

public class RoundedWebView extends WebView {

    private Context f7852b;

    private int f7853c;

    private int f7854d;

    private int f7855e;

    private boolean f7856f;

    private boolean f7857g;

    private boolean f7858h;

    private boolean f7859i;

    public RoundedWebView(Context context) {
        super(context);
        c(context);
    }

    private Paint a() {
        Paint paint = new Paint();
        paint.setColor(0);
        paint.setStyle(Paint.Style.FILL);
        paint.setAntiAlias(true);
        paint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.CLEAR));
        return paint;
    }

    private int b(Context context, int i3) {
        return (int) (((double) (i3 * context.getResources().getDisplayMetrics().density)) + 0.5d);
    }

    private void c(Context context) {
        this.f7852b = context;
        this.f7856f = true;
        this.f7857g = true;
        this.f7858h = true;
        this.f7859i = true;
    }

    private Path getPath() {
        Path path = new Path();
        float[] fArr = new float[8];
        if (this.f7856f) {
            int i3 = this.f7855e;
            fArr[0] = i3;
            fArr[1] = i3;
        }
        if (this.f7857g) {
            int i4 = this.f7855e;
            fArr[2] = i4;
            fArr[3] = i4;
        }
        if (this.f7858h) {
            int i5 = this.f7855e;
            fArr[4] = i5;
            fArr[5] = i5;
        }
        if (this.f7859i) {
            int i6 = this.f7855e;
            fArr[6] = i6;
            fArr[7] = i6;
        }
        path.addRoundRect(new RectF(0.0f, getScrollY(), this.f7853c, getScrollY() + this.f7854d), fArr, Path.Direction.CW);
        return path;
    }

    public void d(boolean z2, boolean z3, boolean z4, boolean z5) {
        this.f7856f = z2;
        this.f7857g = z3;
        this.f7858h = z4;
        this.f7859i = z5;
        invalidate();
    }

    @Override // android.webkit.WebView, android.view.View
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        Path path = getPath();
        path.setFillType(Path.FillType.INVERSE_WINDING);
        canvas.drawPath(path, a());
    }

    @Override // android.webkit.WebView, android.view.View
    protected void onSizeChanged(int i3, int i4, int i5, int i6) {
        super.onSizeChanged(i3, i4, i5, i6);
        this.f7853c = i3;
        if (this.f7858h) {
            this.f7853c = i3;
        } else {
            this.f7853c = 4000;
        }
        this.f7854d = i4;
        this.f7855e = b(this.f7852b, 15);
    }

    public RoundedWebView(Context context, AttributeSet attributeSet) {
        super(context, attributeSet);
        c(context);
    }
}
