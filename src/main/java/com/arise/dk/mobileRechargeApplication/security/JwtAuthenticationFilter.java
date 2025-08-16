package com.arise.dk.mobileRechargeApplication.security;

import java.io.IOException;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import com.arise.dk.mobileRechargeApplication.model.User;
import com.arise.dk.mobileRechargeApplication.repository.RevokedTokenRepository;
import com.arise.dk.mobileRechargeApplication.repository.UserRepository;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
	@Autowired
	private JwtUtil jwtUtil;

	@Autowired
	private UserRepository userRepository;

	@Autowired
	private RevokedTokenRepository revokedTokenRepository;

	@Override
	protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
			throws ServletException, IOException {

		String token = request.getHeader("Authorization");

		// Check if the Authorization header contains a Bearer token
		if (token != null && token.startsWith("Bearer ")) {
			token = token.substring(7); // Remove "Bearer " prefix

			// Check if the token is expired
			if (jwtUtil.isTokenExpired(token)) {
				System.out.println("Token expired");

				response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
				response.getWriter().write("Invalid or expired token.");
				return;
			}

			// Check if the token has been revoked
			if (revokedTokenRepository.findById(token).isPresent()) {
				response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
				response.getWriter().write("Token has been revoked.");
				return;
			}

			// Get the username and role from the token
			String username = jwtUtil.getUsernameFromToken(token);
			String role = jwtUtil.getRoleFromToken(token);
			
	

			Optional<User> user;

			 if (username.matches("\\d+")) {
				  user = userRepository.findByUserPhonenumber(username);
					
			 }
			 else {
				 user = userRepository.findByUsername(username);

			 }			

			if (user.isPresent()) {
				System.out.println("username1 " +username);

				// Create an authority using the role directly from the enum
				List<SimpleGrantedAuthority> authorities = Collections.singletonList(new SimpleGrantedAuthority(role));

				// Create an Authentication object and set it in the SecurityContext
				SecurityContextHolder.getContext()
						.setAuthentication(new UsernamePasswordAuthenticationToken(username, null, authorities));

				// Log the authorities for debugging
			}
		}

		// Continue the filter chain
		chain.doFilter(request, response);
	}

    
}
