package com.arise.dk.mobileRechargeApplication.service;

import com.razorpay.RazorpayClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import java.util.Map;

@Service
public class PaymentVerificationService {

    @Value("${razorpay.key.id}")
    private String razorpayKey;

    @Value("${razorpay.key.secret}")
    private String razorpaySecret;

    public boolean verifyPayment(Map<String, String> paymentData) {
        try {
            RazorpayClient client = new RazorpayClient(razorpayKey, razorpaySecret);
            String paymentId = paymentData.get("razorpay_payment_id");
            client.payments.fetch(paymentId); // If it exists, payment is successful
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}

