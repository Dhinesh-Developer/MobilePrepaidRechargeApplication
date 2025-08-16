package com.arise.dk.mobileRechargeApplication.controller;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import com.arise.dk.mobileRechargeApplication.service.EmailService;
import com.arise.dk.mobileRechargeApplication.service.PaymentService;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "http://127.0.0.1:5500")
public class PaymentController {

	@Autowired
    private EmailService emailService; 
	
    @Autowired
    private PaymentService paymentService;

	@PreAuthorize("hasAuthority('CUSTOMER')")
    @PostMapping("/customer/payments/create")
    public String createOrder(@RequestParam int amount) {
        try {
            return paymentService.createOrder(amount);
        } catch (Exception e) {
            return "Error creating order: " + e.getMessage();
        }
    }
	
	@PreAuthorize("hasAuthority('CUSTOMER')")
	@GetMapping("/customer/getPaymentDetails")
	public ResponseEntity<Map<String, Object>> getPaymentDetails(@RequestParam String payment_id) {
	    try {
	        String razorpayKey = "rzp_test_HohQOoI3083uX1";
	        String razorpaySecret = "OLHWis91Bf3XdBSn2ee4PWgV";
	        
	        String url = "https://api.razorpay.com/v1/payments/" + payment_id;

	        HttpHeaders headers = new HttpHeaders();
	        headers.setBasicAuth(razorpayKey, razorpaySecret);
	        
	        HttpEntity<String> request = new HttpEntity<>(headers);
	        RestTemplate restTemplate = new RestTemplate();
	        ResponseEntity<Map> response = restTemplate.exchange(url, HttpMethod.GET, request, Map.class);

	        Map<String, Object> responseBody = response.getBody();
	        Map<String, Object> result = new HashMap<>();
	        result.put("method", responseBody.get("method"));
	        
	        return ResponseEntity.ok(result);
	    } catch (Exception e) {
	        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Collections.singletonMap("error", "Error fetching payment details."));
	    }
	    
	    
	}
	
	@PreAuthorize("hasAuthority('CUSTOMER')")
	@PostMapping("/customer/success/sendEmail")
    public ResponseEntity<String> handlePaymentSuccess(@RequestBody Map<String, Object> payload) {
        try {
            String paymentId = (String) payload.get("razorpay_payment_id");
            String email = (String) payload.get("email");
            String name = (String) payload.get("name");
            double amount = Double.parseDouble(payload.get("amount").toString()); 

            emailService.sendPaymentSuccessEmail(email, name, paymentId, amount);
            return ResponseEntity.ok("Payment success email sent.");
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Error processing payment.");
        }
    }
	
	@PreAuthorize("hasAuthority('ADMIN')")
	@PostMapping("/admin/notify/sendEmail")
    public ResponseEntity<String> handleNotification(@RequestBody Map<String, Object> payload) {
        try {
            String email = (String) payload.get("email");
            String name = (String) payload.get("name");

            // Send Email Notification
            emailService.sendNotification(email, name);
            return ResponseEntity.ok("Payment success email sent.");
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Error processing payment.");
        }
    }

}
