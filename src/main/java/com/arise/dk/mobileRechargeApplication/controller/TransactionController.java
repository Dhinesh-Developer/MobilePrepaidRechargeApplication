package com.arise.dk.mobileRechargeApplication.controller;

import com.arise.dk.mobileRechargeApplication.exception.ResourceNotFoundException;
import com.arise.dk.mobileRechargeApplication.model.Transaction;
import com.arise.dk.mobileRechargeApplication.model.User;
import com.arise.dk.mobileRechargeApplication.model.User.AccountStatus;
import com.arise.dk.mobileRechargeApplication.service.TransactionService;
import com.arise.dk.mobileRechargeApplication.service.UserService;

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("api")
@CrossOrigin(origins = "http://127.0.0.1:5500")
public class TransactionController {
    private final UserService userService;
    private final TransactionService transactionService;

    public TransactionController(TransactionService transactionService, UserService userService) {
        this.userService = userService;
        this.transactionService = transactionService;
    }

	@PreAuthorize("hasAuthority('ADMIN')")
    @GetMapping("/admin/transactions")
    public List<Transaction> getAllTransactions(@RequestParam String name , @RequestParam String mode) {
		mode = mode.equals("card") ? "credit_debit_card" : mode;
    	mode = name.equals("Failure") ? "All"  : mode ;

    	List<Transaction> transactions = transactionService.getAllTransactions(name , mode);
    	Collections.reverse(transactions);
    	return transactions;
    }

	@PreAuthorize("hasAuthority('CUSTOMER')")
    @PostMapping("/customer/transactions")
    public ResponseEntity<Transaction> createTransaction(@RequestBody Transaction transaction) {
        long id = transaction.getUser().getUserId();
        
        // Fetch user and check if they exist
        User user = userService.getUserById(id);
        if (user == null) {
            throw new ResourceNotFoundException("User with ID " + id + " not found");
        }

        // Update user account status to ACTIVE
        user.setUserAccountStatus(AccountStatus.ACTIVE);
        userService.updateUser(id, user);

        Transaction savedTransaction = transactionService.createTransaction(transaction);
        return ResponseEntity.ok(savedTransaction);
    }

	@PreAuthorize("hasAuthority('CUSTOMER')")
    @GetMapping("/customer/transactions/user/{userId}")
    public List<Transaction> getTransactionsByUserId(@PathVariable Long userId) {
    	
    	List<Transaction> transactions = transactionService.getTransactionsByUserId(userId);
    	Collections.reverse(transactions);
        return transactions;
        
    }

	@PreAuthorize("hasAuthority('ADMIN')")
    @GetMapping("/admin/transactions/summary")
    public ResponseEntity<Map<String, Object>> getTransactionSummary() {
        Map<String, Object> summary = new HashMap<>();
        summary.put("totalTransactions", transactionService.getTotalTransactions());
        summary.put("successfulTransactions", transactionService.getSuccessfulTransactions());
        summary.put("failedTransactions", transactionService.getFailedTransactions());
        summary.put("totalRevenue", transactionService.getTotalRevenue());

        return ResponseEntity.ok(summary);
    }
    
	@PreAuthorize("hasAuthority('CUSTOMER')")
    @GetMapping("/customer/transactions/{transactionId}")
    public Transaction getTransactionsById(@PathVariable Long transactionId) {
        return transactionService.getTransactionsById(transactionId).get(); 
    }
}
