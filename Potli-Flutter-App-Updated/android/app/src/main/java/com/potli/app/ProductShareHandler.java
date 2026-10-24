package com.potli.app;

import android.app.Activity;
import android.content.Intent;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/** Uses Android's native Share Sheet without any third-party packages. */
public final class ProductShareHandler {
    private ProductShareHandler() {}

    public static void share(Activity activity, MethodCall call,
                             MethodChannel.Result result) {
        String name = call.argument("name");
        String price = call.argument("price");
        String website = call.argument("website");

        if (name == null || name.trim().isEmpty() ||
            price == null || price.trim().isEmpty() ||
            website == null || !website.startsWith("https://")) {
            result.error("INVALID_PRODUCT", "Missing or invalid product details", null);
            return;
        }

        String message = name + "\nPrice: " + price +
                "\nShop Potli: " + website;

        try {
            Intent sendIntent = new Intent(Intent.ACTION_SEND);
            sendIntent.setType("text/plain");
            sendIntent.putExtra(Intent.EXTRA_TEXT, message);
            Intent chooser = Intent.createChooser(sendIntent, "Share Potli product");
            activity.startActivity(chooser);
            // True means the Share Sheet opened, not that a recipient received it.
            result.success(true);
        } catch (Exception e) {
            result.error("SHARE_FAILED", "Could not open Android Share Sheet", null);
        }
    }
}
