package com.arise.dk.mobileRechargeApplication.service;


import com.arise.dk.mobileRechargeApplication.model.OtpVerification;
import com.arise.dk.mobileRechargeApplication.repository.OtpVerificationRepository;
import com.twilio.Twilio;
import com.twilio.rest.api.v2010.account.Message;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.Random;

@Service
public class OtpService {

    @Value("${twilio.account_sid}")
    private String accountSid;

    @Value("${twilio.auth_token}")
    private String authToken;

    @Value("${twilio.phone_number}")
    private String fromPhoneNumber;

    private final OtpVerificationRepository otpRepository;

    public OtpService(OtpVerificationRepository otpRepository) {
        this.otpRepository = otpRepository;
    }

    public String generateAndSendOtp(String phoneNumber) {
        // Generate a random 6-digit OTP
        String otp = String.format("%06d", new Random().nextInt(999999));

        // Save OTP to database
        OtpVerification otpVerification = new OtpVerification();
        otpVerification.setPhoneNumber(phoneNumber);
        otpVerification.setOtp(otp);
        otpVerification.setGeneratedTime(LocalDateTime.now());
        otpRepository.save(otpVerification);

        // Initialize Twilio
        Twilio.init(accountSid, authToken);

        // Send OTP via Twilio
        Message.creator(
                new com.twilio.type.PhoneNumber(phoneNumber),
                new com.twilio.type.PhoneNumber(fromPhoneNumber),
                "Your OTP code is: " + otp
        ).create();

        return "OTP sent successfully to " + phoneNumber;
    }

    public boolean verifyOtp(String phoneNumber, String otp) {
        Optional<OtpVerification> otpRecord = otpRepository.findByPhoneNumber("+"+(phoneNumber.trim()));
        if (otpRecord.isPresent()) {
            OtpVerification storedOtp = otpRecord.get();
            // Check if OTP matches and is valid for 5 minutes
            if (storedOtp.getOtp().equals(otp) &&
                storedOtp.getGeneratedTime().isAfter(LocalDateTime.now().minusMinutes(5))) {
                return true;
            }
        }
        return false;
    }
}
