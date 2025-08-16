package com.arise.dk.mobileRechargeApplication.service;

import com.arise.dk.mobileRechargeApplication.model.User;
import com.arise.dk.mobileRechargeApplication.model.User.AccountStatus;
import com.arise.dk.mobileRechargeApplication.repository.UserRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class UserService {
	
	@Autowired
	private BCryptPasswordEncoder passwordEncoder;

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public boolean isUserExistsByPhoneNumber(String phoneNumber) {
        Optional<User> user = userRepository.findByUserPhonenumber(phoneNumber);
        return user.isPresent();
    }
    
    public Optional<User> getUserByPhoneNumber(String phoneNumber) {
        return userRepository.findByUserPhonenumber(phoneNumber);
    }
    
    public User addUser(User user) {
        return userRepository.save(user);
    }
    
    public List<User> getAllUsers(String name) {
    	if(name.equals("All")) {
            return userRepository.findByRoleRoleId(1L); 
    	}
    	else if(name.equals("Active")) {
        	return userRepository.findByRoleRoleId(1L).stream().filter(user -> user.getUserAccountStatus().name().equals("ACTIVE")).toList();
    	}
    	else if(name.equals("Inactive")) {
        	return userRepository.findByRoleRoleId(1L).stream().filter(user -> user.getUserAccountStatus().name().equals("INACTIVE")).toList();
    	}
    	return userRepository.findByRoleRoleId(1L).stream().filter(user -> (user.getUserFname()+user.getUserLname()).toLowerCase().contains(name.toLowerCase())).toList();

    }
    
    public User getUserById(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }
    
    public User updateUser(Long userId, User updatedUser) {
        User existingUser = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        existingUser.setUserFname(updatedUser.getUserFname());
        existingUser.setUserLname(updatedUser.getUserLname());
        existingUser.setUserEmail(updatedUser.getUserEmail());
        existingUser.setUserPhonenumber(updatedUser.getUserPhonenumber());
        existingUser.setUserAlternatePhonenumber(updatedUser.getUserAlternatePhonenumber());
        existingUser.setUserDateOfBirth(updatedUser.getUserDateOfBirth());
        existingUser.setUserAddress(updatedUser.getUserAddress());
        existingUser.setUserDistrict(updatedUser.getUserDistrict());
        existingUser.setUserState(updatedUser.getUserState());
        existingUser.setUserPincode(updatedUser.getUserPincode());

        return userRepository.save(existingUser);
    }

    
    public void deleteUserById(Long userId) {
        if (!userRepository.existsById(userId)) {
            throw new RuntimeException("User not found");
        }
        userRepository.deleteById(userId);
    }

	public List<User> getAllAdminUsers() {
        return userRepository.findByRoleRoleId(2L);

	}
	
	public boolean deactivateUser(Long userId) {
        Optional<User> userOptional = userRepository.findById(userId);
        if (userOptional.isPresent()) {
            User user = userOptional.get();
            user.setUserAccountStatus(AccountStatus.INACTIVE); 
            userRepository.save(user);
            return true;
        }
        return false;
    }

	public User getUserbyUsername(String username) {
        Optional<User> userOptional = userRepository.findByUsername(username);
		return userOptional.get();
	}

	public boolean isValidPassword(long userId , String userPassword) {
		Optional<User> user = userRepository.findById(userId);
		
		if (user.isPresent()) {
			String hashedPassword = user.get().getPassword();
			return passwordEncoder.matches(userPassword, hashedPassword);
		}
		
		return false;
	}


	public boolean changeAdminPassword(long userId, String password) {
		User user = userRepository.findById(userId).get();
		String encodedPassword = passwordEncoder.encode(password); // ✅ Hashing here
	    user.setPassword(encodedPassword);
		userRepository.save(user);
		return true;
	}
	
//	public ResponseEntity<byte[]> changeAndFetchUserImage(Long userId, MultipartFile file) throws IOException {
//        // If the file is not null, store (or update) the image
//        if (file != null) {
//            User user = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("User not found"));
//
//            // Update the user image (it will overwrite the old image)
//            user.setUserImage(file.getBytes());
//            userRepository.save(user);
//        }
//
//        // Fetch updated image from DB
//        Optional<User> userOpt = userRepository.findById(userId);
//        if (userOpt.isPresent() && userOpt.get().getUserImage() != null) {
//            byte[] imageData = userOpt.get().getUserImage();
//            return ResponseEntity.ok().contentType(MediaType.IMAGE_JPEG).body(imageData);  // Return the image data
//        } else {
//            return ResponseEntity.notFound().build();  // Image not found in DB
//        }
//    }

}
