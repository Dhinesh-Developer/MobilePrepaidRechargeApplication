package com.arise.dk.mobileRechargeApplication.controller;

import com.arise.dk.mobileRechargeApplication.exception.ResourceNotFoundException;
import com.arise.dk.mobileRechargeApplication.model.User;
import com.arise.dk.mobileRechargeApplication.repository.UserRepository;
import com.arise.dk.mobileRechargeApplication.service.UserService;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "http://127.0.0.1:5500")
public class UserController {

    private final UserService userService;
    private final UserRepository userRepository;

    public UserController(UserService userService, UserRepository userRepository) {
        this.userService = userService;
        this.userRepository = userRepository;
    }

	@PreAuthorize("hasAuthority('CUSTOMER')")
    @GetMapping("/customer/phonenumbers/{phoneNumber}")
    public ResponseEntity<Boolean> checkUserPhoneNumber(@PathVariable String phoneNumber) {
        boolean exists = userService.isUserExistsByPhoneNumber(phoneNumber);
        return ResponseEntity.ok(exists);
    }
	
	@PreAuthorize("hasAuthority('ADMIN')")
    @GetMapping("/admin/username/{username}")
    public ResponseEntity<User> checkUserUsername(@PathVariable String username) {
        User user = userService.getUserbyUsername(username);
        return new ResponseEntity<>(user, HttpStatus.OK); 
    }

	@PreAuthorize("hasAuthority('CUSTOMER') or hasAuthority('ADMIN')")
    @GetMapping("/both/phone/{phoneNumber}")
    public ResponseEntity<User> getUserByPhoneNumber(@PathVariable String phoneNumber) {
        return userService.getUserByPhoneNumber(phoneNumber)
                .map(ResponseEntity::ok)
                .orElseThrow(() -> new ResourceNotFoundException("User with phone number " + phoneNumber + " not found"));
    }

	@PreAuthorize("hasAuthority('ADMIN')")
    @GetMapping("/admin")
    public List<User> getNonAdminUsers(@RequestParam String name) {
        return userService.getAllUsers(name);
    }
	
	@PreAuthorize("hasAuthority('ADMIN')")
    @GetMapping("/admin/validPassword/{userId}/{oldpassword}")
    public ResponseEntity<String> matchPassword(@PathVariable int userId , @PathVariable String oldpassword) {
        boolean status = userService.isValidPassword(userId , oldpassword);
        if(status) {
        	return ResponseEntity.ok("Password validation successful!");
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Password does not match");
    }

	@PreAuthorize("hasAuthority('ADMIN')")
    @GetMapping("/admin/adminusers")
    public List<User> getAdminUsers() {
        return userService.getAllAdminUsers();
    }

	@PreAuthorize("hasAuthority('ADMIN')")
    @PostMapping("/admin")
    public ResponseEntity<User> addUser(@RequestBody User user) {
        User createdUser = userService.addUser(user);
        return new ResponseEntity<>(createdUser, HttpStatus.CREATED);
    }
	
	@PreAuthorize("hasAuthority('ADMIN')")
    @PostMapping("/admin/changePassword/{userId}")
    public ResponseEntity<String> changePassword(@PathVariable long userId ,@RequestBody User user) {
        Boolean status = userService.changeAdminPassword(userId , user.getPassword());
        if(status) {
        	 return ResponseEntity.ok("Password validation successful!");
        }
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Failed to Update");
    }

	@PreAuthorize("hasAuthority('CUSTOMER') or hasAuthority('ADMIN')")
    @GetMapping("/both/{userId}")
    public ResponseEntity<User> getUserById(@PathVariable Long userId) {
        User user = userService.getUserById(userId);
        if (user == null) {
            throw new ResourceNotFoundException("User with ID " + userId + " not found");
        }
        return new ResponseEntity<>(user, HttpStatus.OK);
    }
	

	@PreAuthorize("hasAuthority('CUSTOMER') or hasAuthority('ADMIN')")
    @PutMapping("/both/{userId}")
    public ResponseEntity<User> updateUser(@PathVariable Long userId, @RequestBody User updatedUser) {
        User existingUser = userService.getUserById(userId);
        if (existingUser == null) {
            throw new ResourceNotFoundException("User with ID " + userId + " not found");
        }
        User updated = userService.updateUser(userId, updatedUser);
        return ResponseEntity.ok(updated);
    }

	@PreAuthorize("hasAuthority('ADMIN')")
    @PatchMapping("/admin/changeStatus/{id}")
    public ResponseEntity<String> deactivateUser(@PathVariable Long id) {
        boolean isUpdated = userService.deactivateUser(id);
        if (!isUpdated) {
            throw new ResourceNotFoundException("User with ID " + id + " not found");
        }
        return ResponseEntity.ok("User status updated to Inactive");
    }
	
//	@PostMapping("/{userId}/image")
//    public ResponseEntity<byte[]> changeUserImage(@PathVariable Long userId,
//                                                  @RequestParam("file") MultipartFile file) {
//        try {
//            return userService.changeAndFetchUserImage(userId, file);
//        } catch (Exception e) {
//            return ResponseEntity.badRequest().body(null);  // Handle any errors
//        }
//    }
}
