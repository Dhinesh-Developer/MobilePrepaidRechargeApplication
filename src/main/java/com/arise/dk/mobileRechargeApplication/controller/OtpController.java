package com.arise.dk.mobileRechargeApplication.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import com.arise.dk.mobileRechargeApplication.service.OtpService;
import com.arise.dk.mobileRechargeApplication.exception.InvalidOtpException;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "http://127.0.0.1:5500")
public class OtpController {

    private final OtpService otpService;

    public OtpController(OtpService otpService) {
        this.otpService = otpService;
    }

	@PreAuthorize("hasAuthority('CUSTOMER')")
    @PostMapping("/customer/otp/send")
    public ResponseEntity<String> sendOtp(@RequestParam String phoneNumber) {
		System.out.println(phoneNumber);
        String response = otpService.generateAndSendOtp("+" + (phoneNumber.trim()));
        return ResponseEntity.ok(response);
    }

	@PreAuthorize("hasAuthority('CUSTOMER')") 
    @PostMapping("/customer/otp/verify")
    public ResponseEntity<String> verifyOtp(@RequestParam String phoneNumber, @RequestParam String otp) {
        boolean isValid = otpService.verifyOtp(phoneNumber.trim(), otp);

        if (!isValid) {
            throw new InvalidOtpException("Invalid OTP or OTP Expired!");
        }

        return ResponseEntity.ok("OTP Verified Successfully!");
    }
}
