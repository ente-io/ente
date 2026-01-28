package io.ente.ensu.chat;

import com.agog.mathdisplay.MTMathView;

final class MathViewCompat {
    private MathViewCompat() {
    }

    static void setMathTextAlignment(MTMathView view, MTMathView.MTTextAlignment alignment) {
        view.setTextAlignment(alignment);
    }
}
