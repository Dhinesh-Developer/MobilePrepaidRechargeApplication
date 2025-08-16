package com.arise.dk.mobileRechargeApplication.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    @Autowired
    private JavaMailSender mailSender;

    public void sendPaymentSuccessEmail(String toEmail, String name, String paymentId, double amount) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(toEmail);
        message.setSubject("Payment Successful - MobiComm Recharge");
        
        String emailBody = "Dear " + name + ",\n\n"
                + "Your payment was successful!\n"
                + "Payment ID: " + paymentId + "\n"
                + "Amount: ₹" + amount + "\n\n"
                + "Thank you for choosing MobiComm Recharge.";

        message.setText(emailBody);
        mailSender.send(message);

        System.out.println("✅ Email sent successfully to: " + toEmail);
    }

	public void sendNotification(String toEmail, String name) {
		// TODO Auto-generated method stub
		SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(toEmail);
        message.setSubject("Alert - MobiComm Recharge");
        
        String emailBody = "Dear " + name + ",\n\n"
                + "Your Plan is Expiring soon , please Recharge to explore the internet\n\n"
                + "Thank you\n\n "
                + " - MobiComm Recharge.";

        message.setText(emailBody);
        mailSender.send(message);

	}
}
