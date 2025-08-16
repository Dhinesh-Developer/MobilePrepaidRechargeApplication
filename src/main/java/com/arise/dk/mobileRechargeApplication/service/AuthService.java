//package com.techm.mobileprepaidrechargesystem.service;
//
//import com.techm.mobileprepaidrechargesystem.security.JwtUtil;
//import com.techm.mobileprepaidrechargesystem.repository.UserRepository;
//import org.springframework.http.ResponseEntity;
//import org.springframework.security.crypto.password.PasswordEncoder;
//import org.springframework.stereotype.Service;
//
//import java.util.Map;
//
//@Service
//public class AuthService {
//
//    private final UserRepository userRepository;
//    private final JwtUtil jwtUtil;
//    private final PasswordEncoder passwordEncoder;
//
//    public AuthService(UserRepository userRepository, JwtUtil jwtUtil, PasswordEncoder passwordEncoder) {
//        this.userRepository = userRepository;
//        this.jwtUtil = jwtUtil;
//        this.passwordEncoder = passwordEncoder;
//    }
//
//    public ResponseEntity<?> adminLogin(String username, String password) {
//        var user = userRepository.findByUsername(username);
//        if (user.isPresent() && passwordEncoder.matches(password, user.get().getPassword())) {
//            String token = jwtUtil.generateToken(username, "ROLE_ADMIN");
//            return ResponseEntity.ok(Map.of("token", token));
//        }
//        return ResponseEntity.status(401).body("Invalid credentials");
//    }
//
//    public ResponseEntity<?> userLogin(String phoneNumber, String otp) {
//        var user = userRepository.findByUserPhonenumber(phoneNumber);
//        if (user.isPresent() && otp.equals("123456")) { // Simulated OTP validation
//            String token = jwtUtil.generateToken(phoneNumber, "ROLE_USER");
//            return ResponseEntity.ok(Map.of("token", token));
//        }
//        return ResponseEntity.status(401).body("Invalid OTP");
//    }
//}
